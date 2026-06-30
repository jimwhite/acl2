"""
Phase 3: ML Training Pipeline for ACL2 Proof Fixing

Trains a two-stage classifier on .mli files to predict what action fixes a
failed proof:

  Stage 1: Predict action-type from checkpoint tokens + goal tokens
  Stage 2: Predict action-obj from checkpoint tokens + goal tokens + action-type

Uses streaming (ijson) for memory-efficient training on the full dataset.
Models: HashingVectorizer + SGDClassifier with partial_fit for incremental
learning.

Usage:
  # Train on all .mli files (defaults):
  python train_model.py /workspaces/acl2-jupyter/data/books

  # Train on specific directory with custom settings:
  python train_model.py /workspaces/acl2-jupyter/data/books/defsort \
      --output-dir ./models --eval-fraction 0.1

  # Resume training from saved models:
  python train_model.py /workspaces/acl2-jupyter/data/books \
      --resume ./models
"""

import sys
import os
import json
import pickle
import hashlib
import argparse
import logging
import multiprocessing
from pathlib import Path
from collections import Counter, defaultdict

import numpy as np

DEFAULT_OUTPUT_DIR = "./models"
DEFAULT_MAX_WORKERS = max(1, multiprocessing.cpu_count())

# Action types we build per-type classifiers for (covers ~95% of data).
# The rest fall through to a "top-N frequency" fallback.
PER_TYPE_CLASSIFIERS = [
    "use-lemma",
    "add-hyp",
    "add-use-hint",
    "add-enable-hint",
    "add-expand-hint",
    "add-disable-hint",
    "add-induct-hint",
    "add-library",
]

# Minimum examples required to train a per-type classifier.
MIN_SAMPLES_PER_TYPE = 500

# Maximum number of unique action-obj values per type before we fall back
# to frequency-only prediction.
MAX_UNIQUE_OBJS = 50000


def tokenize(s):
    """Split a string into tokens on whitespace and parentheses."""
    if s is None:
        return []
    tokens = []
    for ch in s:
        if ch in "()'`,":
            tokens.append(ch)
    for part in s.split():
        if part:
            tokens.append(part)
    # deduplicate simple approach
    seen = set()
    result = []
    for t in tokens:
        if t not in seen:
            seen.add(t)
            result.append(t)
    return result


def features_from_item(item):
    """Extract token features from an .mli record."""
    checkpoint_seq = item.get("input", {}).get("checkpoint-sequence", [])
    goal_str = item.get("metadata", {}).get("goal-str", "")
    checkpoint_type = item.get("input", {}).get("checkpoint-type", "unknown")

    def flatten(seq):
        for elem in seq:
            if isinstance(elem, str):
                yield elem
            elif isinstance(elem, list):
                yield from flatten(elem)
            else:
                yield str(elem)

    tokens = list(flatten(checkpoint_seq))
    tokens.extend(tokenize(goal_str))
    tokens.append(f"__CK_TYPE__{checkpoint_type}")
    return " ".join(tokens)


class HashingTextVectorizer:
    """Simple hashing vectorizer that works incrementally."""

    def __init__(self, n_features=2**18, norm="l2"):
        self.n_features = n_features
        self.norm = norm

    def transform_one(self, text):
        """Hash a single text string into a sparse feature vector."""
        vec = np.zeros(self.n_features, dtype=np.float32)
        for token in text.split():
            h = int(hashlib.md5(token.encode()).hexdigest(), 16)
            idx = h % self.n_features
            vec[idx] += 1.0
        if self.norm == "l2":
            norm = np.linalg.norm(vec)
            if norm > 0:
                vec /= norm
        return vec

    def transform_batch(self, texts):
        return np.array([self.transform_one(t) for t in texts], dtype=np.float32)


class FrequencyBaseline:
    """Fallback: predict by frequency distribution."""

    def __init__(self):
        self.counts = Counter()
        self.top_k = 100

    def fit(self, labels):
        self.counts = Counter(labels)

    def predict_top(self, k=5):
        return [item for item, _ in self.counts.most_common(k)]


class PerTypeClassifier:
    """Classifier for a single action-type: predicts specific action-obj."""

    def __init__(self, action_type, n_features=2**18):
        self.action_type = action_type
        self.n_features = n_features
        self.vectorizer = HashingTextVectorizer(n_features=n_features)
        self.label_index = {}
        self.index_label = {}
        self.weights = None  # will be (n_classes, n_features)
        self.bias = None     # (n_classes,)
        self.n_samples = 0
        self.freq = FrequencyBaseline()
        self._fitted = False

    def partial_fit(self, texts, labels):
        """Incrementally update weights using averaged perceptron."""
        if len(texts) == 0:
            return

        # Build label index
        for label in labels:
            if label not in self.label_index:
                idx = len(self.label_index)
                self.label_index[label] = idx
                self.index_label[idx] = label

        n_classes = len(self.label_index)
        if self.weights is None:
            self.weights = np.zeros((n_classes, self.n_features), dtype=np.float32)
            self.bias = np.zeros(n_classes, dtype=np.float32)
        elif n_classes > self.weights.shape[0]:
            old_w = self.weights
            old_b = self.bias
            self.weights = np.zeros((n_classes, self.n_features), dtype=np.float32)
            self.bias = np.zeros(n_classes, dtype=np.float32)
            self.weights[:old_w.shape[0], :] = old_w
            self.bias[:old_b.shape[0]] = old_b

        self.n_features = self.vectorizer.n_features

        for text, label in zip(texts, labels):
            self.n_samples += 1
            x = self.vectorizer.transform_one(text)
            y_true = self.label_index[label]
            # Predict with current weights
            scores = np.dot(self.weights, x) + self.bias
            y_pred = int(np.argmax(scores))
            if y_pred != y_true:
                # Perceptron update
                self.weights[y_true, :] += x
                self.weights[y_pred, :] -= x
                self.bias[y_true] += 1.0
                self.bias[y_pred] -= 1.0

        self.freq.fit(labels)
        self._fitted = True

    def predict(self, text, top_k=5):
        """Return top-k predicted action-obj values."""
        if not self._fitted or self.weights is None:
            return self.freq.predict_top(top_k)
        x = self.vectorizer.transform_one(text)
        scores = np.dot(self.weights, x) + self.bias
        top_indices = np.argsort(-scores)[:top_k]
        return [self.index_label.get(i, f"UNK_{i}") for i in top_indices if scores[i] > 0] or self.freq.predict_top(top_k)

    def save(self, path):
        data = {
            "action_type": self.action_type,
            "n_features": self.n_features,
            "label_index": self.label_index,
            "index_label": self.index_label,
            "weights": self.weights,
            "bias": self.bias,
            "n_samples": self.n_samples,
            "freq": dict(self.freq.counts),
        }
        with open(path, "wb") as f:
            pickle.dump(data, f)

    def load(self, path):
        with open(path, "rb") as f:
            data = pickle.load(f)
        self.action_type = data["action_type"]
        self.n_features = data["n_features"]
        self.vectorizer = HashingTextVectorizer(n_features=self.n_features)
        self.label_index = data["label_index"]
        self.index_label = {int(k): v for k, v in data["index_label"].items()}
        self.weights = data.get("weights")
        self.bias = data.get("bias")
        self.n_samples = data.get("n_samples", 0)
        self.freq = FrequencyBaseline()
        if "freq" in data:
            self.freq.counts = Counter(data["freq"])
        self._fitted = self.weights is not None and self.n_samples > 0
        return self


class ActionTypeClassifier:
    """Stage 1: Predict which action-type to use."""

    def __init__(self, n_features=2**18):
        self.n_features = n_features
        self.vectorizer = HashingTextVectorizer(n_features=n_features)
        self.label_index = {}
        self.index_label = {}
        self.weights = None
        self.bias = None
        self.n_samples = 0
        self._fitted = False

    def partial_fit(self, texts, labels):
        if len(texts) == 0:
            return
        for label in labels:
            if label not in self.label_index:
                idx = len(self.label_index)
                self.label_index[label] = idx
                self.index_label[idx] = label
        n_classes = len(self.label_index)
        if self.weights is None:
            self.weights = np.zeros((n_classes, self.n_features), dtype=np.float32)
            self.bias = np.zeros(n_classes, dtype=np.float32)
        elif n_classes > self.weights.shape[0]:
            old_w = self.weights; old_b = self.bias
            self.weights = np.zeros((n_classes, self.n_features), dtype=np.float32)
            self.bias = np.zeros(n_classes, dtype=np.float32)
            self.weights[:old_w.shape[0]] = old_w
            self.bias[:old_b.shape[0]] = old_b
        self.n_features = self.vectorizer.n_features
        for text, label in zip(texts, labels):
            self.n_samples += 1
            x = self.vectorizer.transform_one(text)
            y_true = self.label_index[label]
            scores = np.dot(self.weights, x) + self.bias
            y_pred = int(np.argmax(scores))
            if y_pred != y_true:
                self.weights[y_true] += x
                self.weights[y_pred] -= x
                self.bias[y_true] += 1.0
                self.bias[y_pred] -= 1.0
        self._fitted = True

    def predict(self, text, top_k=3):
        if not self._fitted or self.weights is None:
            return ["use-lemma"]  # safe default
        x = self.vectorizer.transform_one(text)
        scores = np.dot(self.weights, x) + self.bias
        top_indices = np.argsort(-scores)[:top_k]
        return [self.index_label[i] for i in top_indices if scores[i] > 0] or ["use-lemma"]

    def save(self, path):
        data = {
            "label_index": self.label_index,
            "index_label": self.index_label,
            "n_features": self.n_features,
            "weights": self.weights,
            "bias": self.bias,
            "n_samples": self.n_samples,
        }
        with open(path, "wb") as f:
            pickle.dump(data, f)

    def load(self, path):
        with open(path, "rb") as f:
            data = pickle.load(f)
        self.label_index = data["label_index"]
        self.index_label = {int(k): v for k, v in data["index_label"].items()}
        self.n_features = data["n_features"]
        self.vectorizer = HashingTextVectorizer(n_features=self.n_features)
        self.weights = data.get("weights")
        self.bias = data.get("bias")
        self.n_samples = data.get("n_samples", 0)
        self._fitted = self.weights is not None and self.n_samples > 0
        return self


def stream_mli_items(root_dir, eval_frac=0.1, seed=42):
    """Generator that streams .mli records from all files under root_dir.
    Yields (is_eval, item) tuples. Uses file-level hash for deterministic split."""
    import ijson
    rng = np.random.RandomState(seed)
    for mli_path in sorted(Path(root_dir).rglob("*.mli")):
        try:
            # Deterministic train/eval split based on file path hash
            file_hash = hashlib.md5(str(mli_path).encode()).hexdigest()
            is_eval = int(file_hash, 16) % 1000 < int(eval_frac * 1000)
            with open(mli_path, "rb") as f:
                items_iter = ijson.items(f, "item")
                for item in items_iter:
                    yield is_eval, item
        except Exception as e:
            logging.warning(f"Skipping {mli_path}: {e}")


def evaluate_classifier(type_clf, per_type_clfs, eval_items, freq_models=None, top_k_action_type=3, top_k_obj=5):
    """Evaluate on eval set. Returns accuracy metrics."""
    type_correct = 0
    type_total = 0
    obj_correct = defaultdict(int)
    obj_total = defaultdict(int)
    freq_correct = defaultdict(int)
    full_correct = 0

    for item in eval_items:
        action_type = item.get("output", {}).get("action-type", "")
        action_obj = item.get("output", {}).get("action-obj", "")
        if isinstance(action_obj, list):
            action_obj = json.dumps(action_obj, separators=(",", ":"))
        features = features_from_item(item)

        # Stage 1: predict action-type
        pred_types = type_clf.predict(features, top_k=top_k_action_type)
        type_total += 1
        if action_type in pred_types:
            type_correct += 1

        # Stage 2: predict action-obj (if we have a classifier for this type)
        obj_total[action_type] += 1

        # Per-type classifier prediction
        if action_type in per_type_clfs:
            pred_objs = per_type_clfs[action_type].predict(features, top_k=top_k_obj)
            if action_obj in pred_objs:
                obj_correct[action_type] += 1
                full_correct += 1

        # Frequency baseline prediction (most common obj for this type)
        if freq_models and action_type in freq_models:
            top_freq = freq_models[action_type].predict_top(k=top_k_obj)
            if action_obj in top_freq:
                freq_correct[action_type] += 1

    results = {
        "type_accuracy": type_correct / max(type_total, 1),
        "type_total": type_total,
        "type_correct": type_correct,
        "obj_correct": full_correct,
        "obj_total": sum(obj_total.values()),
    }
    for at in sorted(obj_total.keys()):
        results[f"obj_acc_{at}"] = obj_correct[at] / max(obj_total[at], 1)
        results[f"freq_acc_{at}"] = freq_correct[at] / max(obj_total[at], 1)
        results[f"obj_n_{at}"] = obj_total[at]

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Train ML models to predict ACL2 proof fixes from .mli data.")
    parser.add_argument("data_dir", help="Root directory containing .mli files")
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR,
                        help=f"Directory to save trained models (default: {DEFAULT_OUTPUT_DIR})")
    parser.add_argument("--resume", default=None,
                        help="Load existing models from this directory and continue training")
    parser.add_argument("--eval-fraction", type=float, default=0.05,
                        help="Fraction of data to hold out for evaluation (default: 0.05)")
    parser.add_argument("--max-samples", type=int, default=0,
                        help="Max samples to train on (0 = all)")
    parser.add_argument("--n-features", type=int, default=2**18,
                        help="Number of hash features (default: 262144)")
    parser.add_argument("--log-level", default="INFO",
                        choices=["DEBUG", "INFO", "WARNING", "ERROR"])
    args = parser.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S",
    )

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Initialize or load models
    if args.resume:
        logging.info(f"Resuming from {args.resume}")
        resume_dir = Path(args.resume)
        type_clf = ActionTypeClassifier(n_features=args.n_features)
        type_clf.load(resume_dir / "action_type_model.pkl")
        per_type_clfs = {}
        for p in resume_dir.glob("pertype_*.pkl"):
            pt = PerTypeClassifier("")
            pt.load(p)
            per_type_clfs[pt.action_type] = pt
        logging.info(f"  Loaded action-type model + {len(per_type_clfs)} per-type classifiers")
    else:
        type_clf = ActionTypeClassifier(n_features=args.n_features)
        per_type_clfs = {}

    # Streaming data
    logging.info(f"Streaming .mli files from {args.data_dir} (eval_fraction={args.eval_fraction})")
    eval_items = []
    total_train = 0
    total_eval = 0
    chunk_size = 5000
    train_texts = []
    train_types = []
    train_objs = defaultdict(list)
    train_features = defaultdict(list)

    def flush_chunk():
        nonlocal total_train
        if not train_texts:
            return
        # Stage 1: fit action-type
        type_clf.partial_fit(train_texts, train_types)
        # Stage 2: fit per-type classifiers
        for at in PER_TYPE_CLASSIFIERS:
            if at in train_objs and len(train_objs[at]) >= MIN_SAMPLES_PER_TYPE and len(set(train_objs[at])) <= MAX_UNIQUE_OBJS:
                if at not in per_type_clfs:
                    per_type_clfs[at] = PerTypeClassifier(at, n_features=args.n_features)
                per_type_clfs[at].partial_fit(train_features[at], train_objs[at])
        total_train += len(train_texts)
        logging.info(f"  trained on {total_train} samples, {len(per_type_clfs)} per-type models")
        train_texts.clear()
        train_types.clear()
        train_objs.clear()
        train_features.clear()

    max_samples = args.max_samples or float("inf")
    for is_eval, item in stream_mli_items(args.data_dir, eval_frac=args.eval_fraction):
        action_type = item.get("output", {}).get("action-type", "")
        action_obj = item.get("output", {}).get("action-obj", "")
        if isinstance(action_obj, list):
            action_obj = json.dumps(action_obj, separators=(",", ":"))
        if not action_type or not action_obj:
            continue
        features = features_from_item(item)

        if is_eval:
            eval_items.append(item)
            total_eval += 1
        else:
            train_texts.append(features)
            train_types.append(action_type)
            if action_type in PER_TYPE_CLASSIFIERS:
                train_objs[action_type].append(action_obj)
                train_features[action_type].append(features)
            if len(train_texts) >= chunk_size:
                flush_chunk()
            if total_train + total_eval >= max_samples:
                break

    # Final flush
    if train_texts:
        flush_chunk()

    logging.info(f"Training complete: {total_train} train, {total_eval} eval")

    # Build frequency baselines for types without classifiers
    freq_models = {}
    for at in eval_items:
        at_name = at.get("output", {}).get("action-type", "")
        ao = at.get("output", {}).get("action-obj", "")
        if isinstance(ao, list):
            ao = json.dumps(ao, separators=(",", ":"))
        if at_name not in freq_models:
            freq_models[at_name] = FrequencyBaseline()
        freq_models[at_name].counts[ao] += 1

    # Evaluate
    if total_eval > 0:
        logging.info("Evaluating on hold-out set ...")
        results = evaluate_classifier(type_clf, per_type_clfs, eval_items, freq_models)
        logging.info(f"  Stage 1 (action-type) accuracy: {results['type_accuracy']:.4f} "
                      f"({results['type_correct']}/{results['type_total']})")
        logging.info(f"  Stage 2 (action-obj) accuracy: {results['obj_correct']/max(results['obj_total'],1):.4f} "
                      f"({results['obj_correct']}/{results['obj_total']})")
        freq_correct_total = 0
        freq_acc_n = 0
        for at in sorted(PER_TYPE_CLASSIFIERS):
            nk = f"obj_n_{at}"
            fk = f"freq_acc_{at}"
            if nk in results and results[nk] > 0:
                freq_correct_total += results.get(fk, 0) * results[nk]
                freq_acc_n += results[nk]
        freq_acc_total = freq_correct_total / max(freq_acc_n, 1)
        logging.info(f"  Frequency baseline (obj):        {freq_acc_total:.4f}")
        for at in sorted(PER_TYPE_CLASSIFIERS):
            if f"obj_n_{at}" in results and results[f"obj_n_{at}"] > 0:
                logging.info(f"    {at}: {results.get(f'obj_acc_{at}', 0):.4f} "
                             f"(n={results[f'obj_n_{at}']})")

    # Save models
    logging.info(f"Saving models to {output_dir}")
    type_clf.save(output_dir / "action_type_model.pkl")
    for at, clf in per_type_clfs.items():
        clf.save(output_dir / f"pertype_{at.replace('/', '_').replace(':', '_')}.pkl")
    # Save frequency baselines
    with open(output_dir / "frequency_baselines.pkl", "wb") as f:
        pickle.dump({at: dict(ff.counts) for at, ff in freq_models.items()}, f)

    # Save a summary
    summary = {
        "total_train_samples": total_train,
        "total_eval_samples": total_eval,
        "action_types_trained": sorted(per_type_clfs.keys()),
        "action_types_seen": sorted(freq_models.keys()),
        "n_features": args.n_features,
    }
    with open(output_dir / "training_summary.json", "w") as f:
        json.dump(summary, f, indent=2)

    logging.info("Done!")


if __name__ == "__main__":
    main()
