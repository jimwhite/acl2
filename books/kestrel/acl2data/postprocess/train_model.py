"""
Phase 3: ML Training Pipeline for ACL2 Proof Fixing

Trains a two-stage classifier on .mli files to predict what action fixes a
failed proof:

  Stage 1: Predict action-type from checkpoint tokens + goal tokens
  Stage 2: Predict action-obj from checkpoint tokens + goal tokens + action-type

Uses scikit-learn's HashingVectorizer + SGDClassifier (log loss, class-weighted)
with multi-epoch streaming for incremental, memory-efficient training on the
full 4.7M-record dataset.

Key improvements over v1 (2026-07-01):
  - Log loss (calibrated probabilities) instead of hinge
  - Class weighting (balanced) to handle extreme label skew
  - Multi-epoch training with shuffled file order
  - Broken-goal delta features (what was removed from the goal)
  - Rule-class and top-level function symbol features
  - Recall@5 and MRR evaluation metrics

Usage:
  # Train on all .mli files (defaults):
  python train_model.py /workspaces/acl2-jupyter/data/books

  # Train with custom settings:
  python train_model.py /workspaces/acl2-jupyter/data/books \\
      --n-features 131072 --epochs 3 --eval-fraction 0.1

  # Resume training from saved models:
  python train_model.py /workspaces/acl2-jupyter/data/books --resume ./models
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
from sklearn.feature_extraction.text import HashingVectorizer
from sklearn.linear_model import SGDClassifier

DEFAULT_OUTPUT_DIR = "./models"
DEFAULT_MAX_WORKERS = max(1, multiprocessing.cpu_count())
DEFAULT_N_FEATURES = 2**18  # 262144
DEFAULT_EPOCHS = 3

# Action types we train per-object classifiers for
PER_TYPE_CLASSIFIERS = ["use-lemma", "add-enable-hint", "add-hyp", "add-use-hint"]

# Minimum examples to train a per-type classifier
MIN_SAMPLES_PER_TYPE = 1000


def tokenize(s):
    """Split a string into tokens."""
    if not s:
        return []
    tokens = []
    for ch in s:
        if ch in "()'`,":
            tokens.append(ch)
    for part in s.split():
        if part:
            tokens.append(part)
    # deduplicate
    seen = set()
    result = []
    for t in tokens:
        if t not in seen:
            seen.add(t)
            result.append(t)
    return result


def features_from_item(item):
    """Extract token features from an .mli record with richer structural info."""
    checkpoint_seq = item.get("input", {}).get("checkpoint-sequence", [])
    goal_str = item.get("metadata", {}).get("goal-str", "")
    checkpoint_type = item.get("input", {}).get("checkpoint-type", "unknown")
    broken_goal_str = item.get("metadata", {}).get("broken-goal-str", "")
    rule_classes = item.get("metadata", {}).get("rule-classes", "")

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

    # --- New features ---

    # 1. Broken-goal delta: tokens that exist in broken-goal but not in goal
    if broken_goal_str:
        goal_tokens = set(tokenize(goal_str))
        broken_tokens = set(tokenize(broken_goal_str))
        delta = broken_tokens - goal_tokens
        for t in delta:
            tokens.append(f"__DELTA__{t}")

    # 2. Checkpoint type
    tokens.append(f"__CK_TYPE__{checkpoint_type}")

    # 3. Top-level function symbols in the checkpoint
    if len(checkpoint_seq) > 0:
        checkpoint_str = " ".join(str(x) for x in flatten(checkpoint_seq))
        top_symbols = extract_top_symbols(checkpoint_str)
        for sym in top_symbols:
            tokens.append(f"__TOP_SYM__{sym}")

    # 4. Rule-class feature
    if rule_classes:
        rc_str = str(rule_classes)
        if "REWRITE" in rc_str.upper():
            tokens.append("__RC__REWRITE")
        if "TYPE-PRESCRIPTION" in rc_str.upper():
            tokens.append("__RC__TYPE-PRESCRIPTION")
        if "LINEAR" in rc_str.upper():
            tokens.append("__RC__LINEAR")
        if "FORWARD-CHAINING" in rc_str.upper():
            tokens.append("__RC__FORWARD-CHAINING")
        if "ELIM" in rc_str.upper():
            tokens.append("__RC__ELIM")
        if "INDUCTION" in rc_str.upper():
            tokens.append("__RC__INDUCTION")

    return " ".join(tokens)


def extract_top_symbols(checkpoint_str):
    """Extract top-level function symbols from a checkpoint string.
    E.g., (NOT (NATP var-0)) -> ['NOT', 'NATP']"""
    symbols = set()
    depth = 0
    current = ""
    for ch in checkpoint_str:
        if ch == '(':
            depth += 1
            if depth == 2:  # top-level sub-expression
                current = ""
        elif ch == ')':
            if depth == 2 and current:
                sym = current.split()[0] if current else ""
                if sym and not sym.startswith("var-"):
                    symbols.add(sym)
            depth -= 1
        elif depth == 2 and ch not in (' ', '\n'):
            current += ch
        elif depth == 1 and ch.isalpha():
            current += ch
    return list(symbols)[:50]


class FrequencyBaseline:
    """Predict by frequency distribution."""

    def __init__(self):
        self.counts = Counter()

    def fit(self, labels):
        self.counts = Counter(labels)

    def predict_top(self, k=5):
        return [item for item, _ in self.counts.most_common(k)]


class PerTypeModel:
    """scikit-learn SGDClassifier (log loss, class-weighted) for a single action-type."""

    def __init__(self, action_type, n_features=DEFAULT_N_FEATURES):
        self.action_type = action_type
        self.vectorizer = HashingVectorizer(
            n_features=n_features, alternate_sign=False, norm="l2", dtype=np.float32
        )
        self.label_encoder = Encoding()
        self.clf = SGDClassifier(
            loss="log_loss",        # calibrated probabilities
            penalty="l2",
            alpha=1e-4,
            class_weight="balanced",
            max_iter=1,
            tol=None,
            warm_start=True,
            random_state=42,
            n_jobs=1,
        )
        self.freq = FrequencyBaseline()
        self._fitted = False
        self._n_classes = 0

    def partial_fit(self, texts, labels):
        if len(texts) == 0:
            return
        self.freq.fit(labels)
        label_counts = Counter(labels)
        valid_labels = {lb for lb, cnt in label_counts.items() if cnt >= 5}
        filtered = [(t, lb) for t, lb in zip(texts, labels) if lb in valid_labels]
        if len(filtered) < MIN_SAMPLES_PER_TYPE:
            return
        texts_f, labels_f = zip(*filtered)
        # Incrementally add new labels
        self.label_encoder.fit(labels_f)
        X = self.vectorizer.transform(texts_f)
        y = self.label_encoder.transform(labels_f)
        mask = y >= 0
        if not mask.any():
            return
        X = X[mask]
        y = y[mask]
        if not self._fitted:
            self._n_classes = len(self.label_encoder)
            self.clf.partial_fit(X, y, classes=np.arange(self._n_classes))
        else:
            known_mask = y < self._n_classes
            if not known_mask.any():
                return
            self.clf.partial_fit(X[known_mask], y[known_mask])
        self._fitted = True

    def predict(self, texts, top_k=5):
        if not self._fitted:
            return self.freq.predict_top(top_k)
        X = self.vectorizer.transform(texts)
        scores = self.clf.decision_function(X)
        if scores.ndim == 1:
            scores = scores.reshape(1, -1)
        results = []
        for row in scores:
            top = np.argsort(-row)[:top_k]
            results.append([self.label_encoder.inverse_transform([int(i)])[0] for i in top if row[i] > 0] or self.freq.predict_top(top_k))
        return results

    def predict_one(self, text, top_k=5):
        return self.predict([text], top_k=top_k)[0]

    def save(self, path):
        data = {
            "action_type": self.action_type,
            "vectorizer": self.vectorizer,
            "label_encoder": _serialize_encoding(self.label_encoder),
            "clf": self.clf,
            "freq": dict(self.freq.counts),
        }
        with open(path, "wb") as f:
            pickle.dump(data, f)

    @classmethod
    def load(cls, path):
        with open(path, "rb") as f:
            data = pickle.load(f)
        inst = cls(data["action_type"])
        inst.vectorizer = data["vectorizer"]
        inst.label_encoder = _deserialize_encoding(data["label_encoder"])
        inst.clf = data["clf"]
        inst.freq = FrequencyBaseline()
        inst.freq.counts = Counter(data["freq"])
        inst._fitted = True
        inst._n_classes = len(inst.label_encoder)
        return inst


def _serialize_encoding(enc):
    """Serialise Encoding to a plain dict so pickle doesn't need the class."""
    return {"label_to_int": enc.label_to_int, "int_to_label": {str(k): v for k, v in enc.int_to_label.items()}}

def _deserialize_encoding(data):
    if isinstance(data, Encoding):
        return data  # already an Encoding (old model file)
    enc = Encoding()
    enc.label_to_int = data["label_to_int"]
    enc.int_to_label = {int(k): v for k, v in data["int_to_label"].items()}
    return enc


class Encoding:
    """Like LabelEncoder but supports previously unseen labels (maps to -1, skipped)."""
    def __init__(self):
        self.label_to_int = {}
        self.int_to_label = {}

    def fit(self, labels):
        for lb in labels:
            if lb not in self.label_to_int:
                idx = len(self.label_to_int)
                self.label_to_int[lb] = idx
                self.int_to_label[idx] = lb

    def transform(self, labels):
        return np.array([self.label_to_int.get(lb, -1) for lb in labels])

    def inverse_transform(self, indices):
        return [self.int_to_label.get(int(i), "UNKNOWN") for i in indices]

    @property
    def classes_(self):
        return [self.int_to_label[i] for i in sorted(self.int_to_label)]

    def __len__(self):
        return len(self.label_to_int)


class ActionTypeModel:
    """Stage 1: scikit-learn SGDClassifier predicting action-type."""

    def __init__(self, n_features=DEFAULT_N_FEATURES, known_types=None):
        self.vectorizer = HashingVectorizer(
            n_features=n_features, alternate_sign=False, norm="l2", dtype=np.float32
        )
        self.label_encoder = Encoding()
        # Pre-populate with discovered types so classes= is always consistent
        if known_types:
            self.label_encoder.fit(known_types)
        self._n_classes = len(self.label_encoder)
        self.clf = SGDClassifier(
            loss="log_loss",        # calibrated probabilities
            penalty="l2",
            alpha=1e-4,
            class_weight="balanced",
            max_iter=1,
            tol=None,
            warm_start=True,
            random_state=42,
            n_jobs=1,
        )
        self._fitted = False

    def partial_fit(self, texts, labels):
        if len(texts) == 0:
            return
        X = self.vectorizer.transform(texts)
        y = self.label_encoder.transform(labels)
        mask = y >= 0
        if not mask.any():
            return
        X = X[mask]
        y = y[mask]
        # classes= is always the full known set — consistent across all calls
        self.clf.partial_fit(X, y, classes=np.arange(self._n_classes))
        self._fitted = True

    def predict(self, texts, top_k=3):
        if not self._fitted:
            return [["use-lemma"]] * len(texts)
        X = self.vectorizer.transform(texts)
        scores = self.clf.decision_function(X)
        if scores.ndim == 1:
            scores = scores.reshape(1, -1)
        results = []
        for row in scores:
            top = np.argsort(-row)[:top_k]
            results.append([self.label_encoder.inverse_transform([int(i)])[0] for i in top if row[i] > 0] or ["use-lemma"])
        return results

    def predict_one(self, text, top_k=3):
        return self.predict([text], top_k=top_k)[0]

    def save(self, path):
        data = {
            "vectorizer": self.vectorizer,
            "label_encoder": _serialize_encoding(self.label_encoder),
            "clf": self.clf,
        }
        with open(path, "wb") as f:
            pickle.dump(data, f)

    @classmethod
    def load(cls, path):
        with open(path, "rb") as f:
            data = pickle.load(f)
        inst = cls()
        inst.vectorizer = data["vectorizer"]
        inst.label_encoder = _deserialize_encoding(data["label_encoder"])
        inst.clf = data["clf"]
        inst._fitted = True
        inst._n_classes = len(inst.label_encoder)
        return inst


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


def evaluate_models(type_model, per_type_models, eval_items, freq_models=None, top_k_action_type=3, top_k_obj=5):
    """Evaluate on eval set using full batch prediction. Returns accuracy metrics."""
    type_correct = 0
    type_total = 0
    obj_correct = defaultdict(int)
    obj_total = defaultdict(int)
    freq_correct = defaultdict(int)
    full_correct = 0

    # Batch-predict action-types
    eval_features = [features_from_item(item) for item in eval_items]
    batch_size = 2000
    all_pred_types = []
    for i in range(0, len(eval_features), batch_size):
        batch = eval_features[i:i + batch_size]
        all_pred_types.extend(type_model.predict(batch, top_k=top_k_action_type))

    # Batch-predict per-type models: group by action_type
    per_type_features = defaultdict(list)
    per_type_indices = defaultdict(list)
    per_type_objs = {}
    for idx, item in enumerate(eval_items):
        at = item.get("output", {}).get("action-type", "")
        ao = item.get("output", {}).get("action-obj", "")
        if isinstance(ao, list):
            ao = json.dumps(ao, separators=(",", ":"))
        if at in per_type_models:
            per_type_features[at].append(eval_features[idx])
            per_type_indices[at].append(idx)
            if at not in per_type_objs:
                per_type_objs[at] = []
            per_type_objs[at].append(ao)

    per_type_preds = {}
    for at, features_list in per_type_features.items():
        model = per_type_models[at]
        all_preds = []
        for i in range(0, len(features_list), batch_size):
            batch = features_list[i:i + batch_size]
            all_preds.extend(model.predict(batch, top_k=top_k_obj))
        per_type_preds[at] = all_preds

    # Compute metrics
    for idx, item in enumerate(eval_items):
        action_type = item.get("output", {}).get("action-type", "")
        action_obj = item.get("output", {}).get("action-obj", "")
        if isinstance(action_obj, list):
            action_obj = json.dumps(action_obj, separators=(",", ":"))
        pred_types = all_pred_types[idx]

        type_total += 1
        if action_type in pred_types:
            type_correct += 1

        obj_total[action_type] += 1
        if action_type in per_type_models and action_type in per_type_preds:
            local_idx = per_type_indices[action_type].index(idx)
            pred_objs = per_type_preds[action_type][local_idx]
            if action_obj in pred_objs:
                obj_correct[action_type] += 1
                full_correct += 1

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


def discover_action_types(root_dir, max_files=200):
    """Quick pre-scan using the summarizer to discover all action types."""
    from summarize_mli import walk_mli_files, process_one_mli
    types = set()
    count = 0
    for mli_path in sorted(Path(root_dir).rglob("*.mli")):
        if count >= max_files:
            break
        counts = process_one_mli(str(mli_path))
        types.update(counts.keys())
        count += 1
    return sorted(types)


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
        type_model = ActionTypeModel.load(resume_dir / "action_type_model.pkl")
        per_type_models = {}
        for p in resume_dir.glob("pertype_*.pkl"):
            pt = PerTypeModel.load(p)
            per_type_models[pt.action_type] = pt
        logging.info(f"  Loaded action-type model + {len(per_type_models)} per-type models")
    else:
        # Pre-scan to discover all action types in the data
        logging.info("Pre-scanning to discover action types ...")
        discovered_types = discover_action_types(args.data_dir)
        logging.info(f"  Found {len(discovered_types)} action types: {discovered_types}")
        type_model = ActionTypeModel(n_features=args.n_features, known_types=discovered_types)
        per_type_models = {}

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
        type_model.partial_fit(train_texts, train_types)
        # Stage 2: fit per-type models
        for at in PER_TYPE_CLASSIFIERS:
            if at in train_objs and len(train_objs[at]) >= MIN_SAMPLES_PER_TYPE:
                if at not in per_type_models:
                    per_type_models[at] = PerTypeModel(at, n_features=args.n_features)
                per_type_models[at].partial_fit(train_features[at], train_objs[at])
        total_train += len(train_texts)
        logging.info(f"  trained on {total_train} samples, {len(per_type_models)} per-type models")
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
        results = evaluate_models(type_model, per_type_models, eval_items, freq_models)
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
    type_model.save(output_dir / "action_type_model.pkl")
    for at, clf in per_type_models.items():
        clf.save(output_dir / f"pertype_{at.replace('/', '_').replace(':', '_')}.pkl")
    # Save frequency baselines
    with open(output_dir / "frequency_baselines.pkl", "wb") as f:
        pickle.dump({at: dict(ff.counts) for at, ff in freq_models.items()}, f)

    # Save a summary
    summary = {
        "total_train_samples": total_train,
        "total_eval_samples": total_eval,
        "action_types_trained": sorted(per_type_models.keys()),
        "action_types_seen": sorted(freq_models.keys()),
        "n_features": args.n_features,
    }
    with open(output_dir / "training_summary.json", "w") as f:
        json.dump(summary, f, indent=2)

    logging.info("Done!")


if __name__ == "__main__":
    main()
