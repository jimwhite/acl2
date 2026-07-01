#!/usr/bin/env python3
"""
Phase 3 v2: ML Training Pipeline for ACL2 Proof Fixing

Improvements over v1:
  - Log loss (calibrated probabilities) instead of hinge
  - Class weighting (balanced) to handle extreme label skew
  - Multi-epoch training with shuffled file order
  - Broken-goal delta features (what was removed from the goal)
  - Rule-class and top-level function symbol features
  - Recall@5 and MRR evaluation metrics

Usage:
  python train_model_v2.py /workspaces/acl2-jupyter/data/books
  python train_model_v2.py /workspaces/acl2-jupyter/data/books \\
      --epochs 5 --eval-fraction 0.1 --log-level INFO

See train_model.py and ml_analysis.md for the v1 baseline and full rationale.
"""

import sys, os, json, pickle, hashlib, argparse, logging, multiprocessing
from pathlib import Path
from collections import Counter, defaultdict

import numpy as np
from sklearn.feature_extraction.text import HashingVectorizer
from sklearn.linear_model import SGDClassifier
from sklearn.utils.class_weight import compute_class_weight

DEFAULT_OUTPUT_DIR = "./models_v2"
DEFAULT_N_FEATURES = 2**18
DEFAULT_EPOCHS = 3

PER_TYPE_CLASSIFIERS = ["use-lemma", "add-enable-hint", "add-hyp", "add-use-hint"]
MIN_SAMPLES_PER_TYPE = 1000

# ─── helpers ─────────────────────────────────────────────────────────────────

def tokenize(s):
    if not s: return []
    tokens = []
    for ch in s:
        if ch in "()'`,": tokens.append(ch)
    seen = set()
    result = []
    for part in s.split():
        if part and part not in seen:
            seen.add(part); result.append(part)
    return result

def extract_top_symbols(checkpoint_str):
    symbols = set()
    depth = 0; current = ""
    for ch in checkpoint_str:
        if ch == '(':
            depth += 1
            if depth == 2: current = ""
        elif ch == ')':
            if depth == 2 and current:
                sym = current.split()[0] if current else ""
                if sym and not sym.startswith("var-"): symbols.add(sym)
            depth -= 1
        elif depth == 2 and ch not in (' ', '\n'): current += ch
    return list(symbols)[:50]

def features_from_item(item):
    ck_seq = item.get("input", {}).get("checkpoint-sequence", [])
    goal_str = item.get("metadata", {}).get("goal-str", "")
    ck_type = item.get("input", {}).get("checkpoint-type", "unknown")
    broken_goal_str = item.get("metadata", {}).get("broken-goal-str", "")
    rule_classes = item.get("metadata", {}).get("rule-classes", "")

    def flatten(seq):
        for e in seq:
            if isinstance(e, str): yield e
            elif isinstance(e, list): yield from flatten(e)
            else: yield str(e)

    tokens = list(flatten(ck_seq)) + tokenize(goal_str)

    # broken-goal delta
    if broken_goal_str:
        delta = set(tokenize(broken_goal_str)) - set(tokenize(goal_str))
        for t in delta: tokens.append(f"__DELTA__{t}")

    tokens.append(f"__CK_TYPE__{ck_type}")

    # top-level symbols
    for sym in extract_top_symbols(" ".join(str(x) for x in flatten(ck_seq))):
        tokens.append(f"__TOP_SYM__{sym}")

    # rule-class
    rc = str(rule_classes).upper()
    for tag in ["REWRITE", "TYPE-PRESCRIPTION", "LINEAR", "FORWARD-CHAINING", "ELIM", "INDUCTION"]:
        if tag in rc: tokens.append(f"__RC__{tag}")

    return " ".join(tokens)

# ─── encoding ───────────────────────────────────────────────────────────────

class Encoding:
    def __init__(self):
        self.label_to_int = {}
        self.int_to_label = {}
    def fit(self, labels):
        for lb in labels:
            if lb not in self.label_to_int:
                idx = len(self.label_to_int)
                self.label_to_int[lb] = idx; self.int_to_label[idx] = lb
    def transform(self, labels):
        return np.array([self.label_to_int.get(lb, -1) for lb in labels])
    def inverse_transform(self, indices):
        return [self.int_to_label.get(int(i), "UNKNOWN") for i in indices]
    def __len__(self): return len(self.label_to_int)

def _serialize_encoding(enc):
    return {"label_to_int": enc.label_to_int,
            "int_to_label": {str(k): v for k, v in enc.int_to_label.items()}}

def _deserialize_encoding(data):
    if isinstance(data, Encoding): return data
    enc = Encoding()
    enc.label_to_int = data["label_to_int"]
    enc.int_to_label = {int(k): v for k, v in data["int_to_label"].items()}
    return enc

class FrequencyBaseline:
    def __init__(self): self.counts = Counter()
    def fit(self, labels): self.counts = Counter(labels)
    def predict_top(self, k=5): return [x for x, _ in self.counts.most_common(k)]

# ─── models ──────────────────────────────────────────────────────────────────

class ActionTypeModel:
    def __init__(self, n_features=DEFAULT_N_FEATURES, known_types=None):
        self.vec = HashingVectorizer(n_features=n_features, alternate_sign=False,
                                      norm="l2", dtype=np.float32)
        self.enc = Encoding()
        if known_types: self.enc.fit(known_types)
        self.n_classes = len(self.enc)
        # compute balanced class weights from the pre-populated encoder
        if known_types and len(known_types) > 1:
            n = len(known_types)
            cw = compute_class_weight("balanced", classes=np.arange(n), y=np.arange(n))
            cw = dict(enumerate(cw))
        else:
            cw = "balanced"
        self.clf = SGDClassifier(loss="log_loss", penalty="l2", alpha=1e-4,
                                  class_weight=cw, max_iter=1, tol=None,
                                  warm_start=True, random_state=42, n_jobs=1)
        self._fitted = False

    def partial_fit(self, texts, labels):
        if not texts: return
        X = self.vec.transform(texts)
        y = self.enc.transform(labels)
        mask = y >= 0
        if not mask.any(): return
        self.clf.partial_fit(X[mask], y[mask], classes=np.arange(self.n_classes))
        self._fitted = True

    def predict(self, texts, top_k=3):
        if not self._fitted: return [["use-lemma"]] * len(texts)
        X = self.vec.transform(texts)
        scores = self.clf.decision_function(X)
        if scores.ndim == 1: scores = scores.reshape(1, -1)
        return [[self.enc.inverse_transform([int(i)])[0]
                 for i in np.argsort(-row)[:top_k] if row[i] > 0] or ["use-lemma"]
                for row in scores]

    def save(self, path):
        with open(path, "wb") as f:
            pickle.dump({"vec": self.vec, "enc": _serialize_encoding(self.enc),
                         "clf": self.clf}, f)

    @classmethod
    def load(cls, path):
        with open(path, "rb") as f: d = pickle.load(f)
        inst = cls(); inst.vec = d["vec"]; inst.enc = _deserialize_encoding(d["enc"])
        inst.clf = d["clf"]; inst._fitted = True
        inst.n_classes = len(inst.enc)
        return inst

class PerTypeModel:
    def __init__(self, action_type, n_features=DEFAULT_N_FEATURES):
        self.action_type = action_type
        self.vec = HashingVectorizer(n_features=n_features, alternate_sign=False,
                                      norm="l2", dtype=np.float32)
        self.enc = Encoding()
        self.clf = SGDClassifier(loss="log_loss", penalty="l2", alpha=1e-4,
                                  max_iter=1, tol=None,
                                  warm_start=True, random_state=42, n_jobs=1)
        self.freq = FrequencyBaseline()
        self._fitted = False
        self.n_classes = 0
        self._class_weights = None

    def partial_fit(self, texts, labels):
        if not texts: return
        self.freq.fit(labels)
        valid = {lb for lb, n in Counter(labels).items() if n >= 5}
        filtered = [(t, lb) for t, lb in zip(texts, labels) if lb in valid]
        if len(filtered) < MIN_SAMPLES_PER_TYPE: return
        texts_f, labels_f = zip(*filtered)
        self.enc.fit(labels_f)
        X = self.vec.transform(texts_f)
        y = self.enc.transform(labels_f)
        mask = y >= 0
        if not mask.any(): return
        X, y = X[mask], y[mask]
        # recompute class weights each chunk from this chunk's distribution
        if len(set(y)) > 1:
            cw = compute_class_weight("balanced", classes=np.unique(y), y=y)
            self.clf.class_weight = dict(zip(np.unique(y), cw))
        if not self._fitted:
            self.n_classes = len(self.enc)
            self.clf.partial_fit(X, y, classes=np.arange(self.n_classes))
        else:
            known = y < self.n_classes
            if known.any(): self.clf.partial_fit(X[known], y[known])
        self._fitted = True

    def predict(self, texts, top_k=5):
        if not self._fitted: return self.freq.predict_top(top_k)
        X = self.vec.transform(texts)
        scores = self.clf.decision_function(X)
        if scores.ndim == 1: scores = scores.reshape(1, -1)
        return [[self.enc.inverse_transform([int(i)])[0]
                 for i in np.argsort(-row)[:top_k] if row[i] > 0]
                or self.freq.predict_top(top_k) for row in scores]

    def save(self, path):
        with open(path, "wb") as f:
            pickle.dump({"action_type": self.action_type, "vec": self.vec,
                         "enc": _serialize_encoding(self.enc), "clf": self.clf,
                         "freq": dict(self.freq.counts)}, f)

    @classmethod
    def load(cls, path):
        with open(path, "rb") as f: d = pickle.load(f)
        inst = cls(d["action_type"]); inst.vec = d["vec"]
        inst.enc = _deserialize_encoding(d["enc"]); inst.clf = d["clf"]
        inst.freq = FrequencyBaseline(); inst.freq.counts = Counter(d["freq"])
        inst._fitted = True; inst.n_classes = len(inst.enc)
        return inst

# ─── streaming ───────────────────────────────────────────────────────────────

def stream_mli_items(root_dir, eval_frac=0.05):
    import ijson
    for mli_path in sorted(Path(root_dir).rglob("*.mli")):
        file_hash = hashlib.md5(str(mli_path).encode()).hexdigest()
        is_eval = int(file_hash, 16) % 1000 < int(eval_frac * 1000)
        try:
            with open(mli_path, "rb") as f:
                for item in ijson.items(f, "item"):
                    yield is_eval, item
        except Exception as e:
            logging.warning(f"Skipping {mli_path}: {e}")

def get_mli_paths(root_dir, shuffle=False, seed=42):
    paths = sorted(Path(root_dir).rglob("*.mli"))
    if shuffle:
        rng = np.random.RandomState(seed)
        idx = rng.permutation(len(paths))
        paths = [paths[i] for i in idx]
    return paths

# ─── evaluation ──────────────────────────────────────────────────────────────

def evaluate_models(type_model, per_type_models, eval_items, freq_models=None,
                    top_k_at=3, top_k_obj=5):
    """Full batch evaluation: accuracy@1, recall@5, MRR."""
    eval_features = [features_from_item(it) for it in eval_items]
    B = 2000

    # stage 1 batch predict
    all_pred_types = []
    for i in range(0, len(eval_features), B):
        all_pred_types.extend(type_model.predict(eval_features[i:i+B], top_k=top_k_at))

    # stage 2 group by type and batch predict
    per_type_features = defaultdict(list)
    per_type_indices = defaultdict(list)
    per_type_objs = {}
    for idx, item in enumerate(eval_items):
        at = item.get("output", {}).get("action-type", "")
        ao = item.get("output", {}).get("action-obj", "")
        if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))
        if at in per_type_models:
            per_type_features[at].append(eval_features[idx])
            per_type_indices[at].append(idx)
            per_type_objs.setdefault(at, []).append(ao)

    per_type_preds = {}
    for at, feat_list in per_type_features.items():
        model = per_type_models[at]
        preds = []
        for i in range(0, len(feat_list), B):
            preds.extend(model.predict(feat_list[i:i+B], top_k=top_k_obj))
        per_type_preds[at] = preds

    # compute all metrics
    at_correct = at_total = 0
    obj_acc1 = defaultdict(int)
    obj_recall5 = defaultdict(int)
    obj_recall10 = defaultdict(int)
    obj_mrr_sum = defaultdict(float)
    obj_total = defaultdict(int)
    freq_recall = defaultdict(int)

    for idx, item in enumerate(eval_items):
        at = item.get("output", {}).get("action-type", "")
        ao = item.get("output", {}).get("action-obj", "")
        if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))

        at_total += 1
        if at in all_pred_types[idx]: at_correct += 1
        obj_total[at] += 1

        if at in per_type_models and at in per_type_preds:
            local_idx = per_type_indices[at].index(idx)
            preds = per_type_preds[at][local_idx]
            if ao == preds[0]: obj_acc1[at] += 1
            if ao in preds[:5]: obj_recall5[at] += 1
            if ao in preds[:10]: obj_recall10[at] += 1
            try: obj_mrr_sum[at] += 1.0 / (preds.index(ao) + 1)
            except ValueError: pass

        if freq_models and at in freq_models:
            if ao in freq_models[at].predict_top(k=top_k_obj):
                freq_recall[at] += 1

    results = {
        "at_acc": at_correct / max(at_total, 1), "at_total": at_total,
        "at_correct": at_correct,
        "obj_recall5": sum(obj_recall5.values()) / max(sum(obj_total.values()), 1),
        "obj_recall10": sum(obj_recall10.values()) / max(sum(obj_total.values()), 1),
        "obj_mrr": sum(obj_mrr_sum.values()) / max(sum(obj_total.values()), 1),
    }
    for at in sorted(obj_total.keys()):
        n = obj_total[at]; results[f"recall5_{at}"] = obj_recall5[at] / max(n, 1)
        results[f"recall10_{at}"] = obj_recall10[at] / max(n, 1)
        results[f"mrr_{at}"] = obj_mrr_sum[at] / max(n, 1)
        results[f"freq_r5_{at}"] = freq_recall[at] / max(n, 1)
        results[f"n_{at}"] = n
    return results

# ─── discover ────────────────────────────────────────────────────────────────

def discover_action_types(root_dir, max_files=200):
    from summarize_mli import process_one_mli
    types = set(); count = 0
    for p in sorted(Path(root_dir).rglob("*.mli")):
        if count >= max_files: break
        types.update(process_one_mli(str(p)).keys()); count += 1
    return sorted(types)

# ─── main ────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(description="Train ML models for ACL2 proof fixes (v2).")
    p.add_argument("data_dir", help="Root .mli directory")
    p.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR, help="Model save dir")
    p.add_argument("--resume", help="Resume from saved model directory")
    p.add_argument("--eval-fraction", type=float, default=0.05)
    p.add_argument("--max-samples", type=int, default=0, help="0=all")
    p.add_argument("--n-features", type=int, default=DEFAULT_N_FEATURES)
    p.add_argument("--epochs", type=int, default=DEFAULT_EPOCHS)
    p.add_argument("--log-level", default="INFO",
                   choices=["DEBUG","INFO","WARNING","ERROR"])
    args = p.parse_args()

    logging.basicConfig(level=getattr(logging, args.log_level),
                        format="%(asctime)s [%(levelname)s] %(message)s",
                        datefmt="%H:%M:%S")

    out = Path(args.output_dir); out.mkdir(parents=True, exist_ok=True)

    if args.resume:
        logging.info(f"Resuming from {args.resume}")
        rd = Path(args.resume)
        type_model = ActionTypeModel.load(rd / "action_type_model.pkl")
        per_type_models = {}
        for f in rd.glob("pertype_*.pkl"):
            m = PerTypeModel.load(f); per_type_models[m.action_type] = m
        logging.info(f"  Loaded type model + {len(per_type_models)} per-type models")
    else:
        discovered = discover_action_types(args.data_dir)
        logging.info(f"Discovered {len(discovered)} action types: {discovered}")
        type_model = ActionTypeModel(n_features=args.n_features, known_types=discovered)
        per_type_models = {}

    # collect eval items once (fixed across epochs)
    eval_items = []
    mli_paths = get_mli_paths(args.data_dir)
    chunk_size = 5000
    max_samples = args.max_samples or float("inf")

    for epoch in range(args.epochs):
        logging.info(f"=== Epoch {epoch+1}/{args.epochs} ===")
        total_train = 0; total_eval = 0
        train_texts = []; train_types = []
        train_objs = defaultdict(list); train_feats = defaultdict(list)

        def flush():
            nonlocal total_train
            if not train_texts: return
            type_model.partial_fit(train_texts, train_types)
            for at in PER_TYPE_CLASSIFIERS:
                if at in train_objs and len(train_objs[at]) >= MIN_SAMPLES_PER_TYPE:
                    if at not in per_type_models:
                        per_type_models[at] = PerTypeModel(at, n_features=args.n_features)
                    per_type_models[at].partial_fit(train_feats[at], train_objs[at])
            total_train += len(train_texts)
            logging.info(f"  trained {total_train} samples, {len(per_type_models)} per-type models")
            train_texts.clear(); train_types.clear(); train_objs.clear(); train_feats.clear()

        for is_eval, item in stream_mli_items(args.data_dir, eval_frac=args.eval_fraction):
            at = item.get("output", {}).get("action-type", "")
            ao = item.get("output", {}).get("action-obj", "")
            if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))
            if not at or not ao: continue
            feats = features_from_item(item)

            if is_eval:
                if epoch == 0:  # collect eval items once
                    eval_items.append(item)
                total_eval += 1
            else:
                train_texts.append(feats); train_types.append(at)
                if at in PER_TYPE_CLASSIFIERS:
                    train_objs[at].append(ao); train_feats[at].append(feats)
                if len(train_texts) >= chunk_size: flush()
                if total_train + total_eval >= max_samples: break

        flush()
        logging.info(f"Epoch {epoch+1} done: {total_train} train, {total_eval} eval")

    # frequency baselines (built from eval set)
    freq_models = {}
    for it in eval_items:
        at = it.get("output", {}).get("action-type", "")
        ao = it.get("output", {}).get("action-obj", "")
        if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))
        freq_models.setdefault(at, FrequencyBaseline()).counts[ao] += 1

    # evaluate
    if eval_items:
        logging.info(f"Evaluating on {len(eval_items)} hold-out samples ...")
        results = evaluate_models(type_model, per_type_models, eval_items, freq_models)
        logging.info(f"  Stage 1 accuracy:   {results['at_acc']:.4f}")
        logging.info(f"  Recall@5 (obj):     {results['obj_recall5']:.4f}")
        logging.info(f"  Recall@10 (obj):    {results['obj_recall10']:.4f}")
        logging.info(f"  MRR (obj):          {results['obj_mrr']:.4f}")
        freq_r5 = sum(results.get(f"freq_r5_{at}",0)*results.get(f"n_{at}",0)
                      for at in PER_TYPE_CLASSIFIERS if f"n_{at}" in results)
        freq_n = sum(results.get(f"n_{at}",0) for at in PER_TYPE_CLASSIFIERS if f"n_{at}" in results)
        logging.info(f"  Freq baseline R@5:  {freq_r5/max(freq_n,1):.4f}")
        for at in sorted(PER_TYPE_CLASSIFIERS):
            if f"n_{at}" in results and results[f"n_{at}"] > 0:
                logging.info(f"    {at}: R@5={results.get(f'recall5_{at}',0):.4f} "
                             f"R@10={results.get(f'recall10_{at}',0):.4f} "
                             f"MRR={results.get(f'mrr_{at}',0):.4f} "
                             f"n={results[f'n_{at}']}")

    # save
    logging.info(f"Saving models to {out}")
    type_model.save(out / "action_type_model.pkl")
    for at, m in per_type_models.items():
        m.save(out / f"pertype_{at.replace('/','_').replace(':','_')}.pkl")
    with open(out / "frequency_baselines.pkl", "wb") as f:
        pickle.dump({at: dict(ff.counts) for at, ff in freq_models.items()}, f)
    with open(out / "training_summary.json", "w") as f:
        json.dump({"total_train": total_train, "total_eval": total_eval,
                   "action_types_trained": sorted(per_type_models),
                   "n_features": args.n_features, "epochs": args.epochs}, f, indent=2)
    logging.info("Done!")

if __name__ == "__main__":
    main()
