#!/usr/bin/env python3
"""
Phase 3 v3: LightGBM LambdaRank for Stage 2 (action-obj ranking)

Replaces the linear SGDClassifier in Stage 2 with LightGBM LambdaRank,
which directly optimizes NDCG — the metric that matters for ranking.

Architecture:
  Stage 1: SGDClassifier (log-loss, class-weighted) — same as v2, 67% accurate
  Stage 2: LightGBM LambdaRank per action-type, ranking candidate action-obj
           values for a given checkpoint.

Training:
  For each training record, we generate a candidate group:
    1 correct action-obj (relevance=1) + K random negatives (relevance=0).
  Features for each candidate: HashingVectorizer of checkpoint tokens +
  goal tokens, concatenated with a hash of the candidate action-obj name.
  LambdaRank learns to rank the correct candidate above negatives.

Inference:
  Stage 1 predicts action-type.  Stage 2 takes the top-N most frequent
  action-obj values for that type, scores each with the LambdaRank model,
  and returns the top-K ranked candidates.

Usage:
  python train_model_v3.py /workspaces/acl2-jupyter/data/books

See ml_analysis.md for the full rationale.
"""

import sys, os, json, pickle, hashlib, argparse, logging
from pathlib import Path
from collections import Counter, defaultdict

import numpy as np
from scipy.sparse import vstack, csr_matrix
from sklearn.feature_extraction.text import HashingVectorizer
from sklearn.linear_model import SGDClassifier

DEFAULT_OUTPUT_DIR = "./models_v3"
DEFAULT_N_FEATURES = 2**18
DEFAULT_NEGATIVES = 9         # 1 + 9 = 10 candidates per query group
DEFAULT_MAX_QUERIES = 50000   # per action-type, 0 = all
DEFAULT_NUM_ROUNDS = 100      # boosting rounds for LambdaRank
PER_TYPE_CLASSIFIERS = ["use-lemma", "add-enable-hint", "add-hyp", "add-use-hint"]
MIN_CANDIDATES = 20          # need at least this many distinct action-objs

# ─── helpers ─────────────────────────────────────────────────────────────────

def tokenize(s):
    if not s: return []
    tokens = []
    for ch in s:
        if ch in "()'`,": tokens.append(ch)
    seen = set(); result = []
    for part in s.split():
        if part and part not in seen: seen.add(part); result.append(part)
    return result

def flatten_seq(seq):
    for e in seq:
        if isinstance(e, str): yield e
        elif isinstance(e, list): yield from flatten_seq(e)
        else: yield str(e)

def features_from_item(item):
    ck_seq = item.get("input", {}).get("checkpoint-sequence", [])
    goal_str = item.get("metadata", {}).get("goal-str", "")
    ck_type = item.get("input", {}).get("checkpoint-type", "unknown")
    tokens = list(flatten_seq(ck_seq)) + tokenize(goal_str)
    tokens.append(f"__CK_TYPE__{ck_type}")
    return " ".join(tokens)

class FrequencyBaseline:
    def __init__(self): self.counts = Counter()
    def fit(self, labels): self.counts = Counter(labels)
    def predict_top(self, k=5): return [x for x, _ in self.counts.most_common(k)]

# ─── encoding (from v2) ─────────────────────────────────────────────────────

class Encoding:
    def __init__(self):
        self.label_to_int = {}; self.int_to_label = {}
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

# ─── Stage 1: ActionTypeModel (same as v2) ──────────────────────────────────

class ActionTypeModel:
    def __init__(self, n_features=DEFAULT_N_FEATURES, known_types=None):
        self.vec = HashingVectorizer(n_features=n_features, alternate_sign=False,
                                      norm="l2", dtype=np.float32)
        self.enc = Encoding()
        if known_types: self.enc.fit(known_types)
        self.n_classes = len(self.enc)
        from sklearn.utils.class_weight import compute_class_weight
        if known_types and len(known_types) > 1:
            n = len(known_types)
            cw = dict(enumerate(compute_class_weight("balanced", classes=np.arange(n), y=np.arange(n))))
        else:
            cw = "balanced"
        self.clf = SGDClassifier(loss="log_loss", penalty="l2", alpha=1e-4,
                                  class_weight=cw, max_iter=1, tol=None,
                                  warm_start=True, random_state=42, n_jobs=1)
        self._fitted = False

    def partial_fit(self, texts, labels):
        if not texts: return
        X = self.vec.transform(texts); y = self.enc.transform(labels)
        mask = y >= 0
        if mask.any(): self.clf.partial_fit(X[mask], y[mask], classes=np.arange(self.n_classes))
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
            pickle.dump({"vec": self.vec, "enc": _serialize_encoding(self.enc), "clf": self.clf}, f)

    @classmethod
    def load(cls, path):
        with open(path, "rb") as f: d = pickle.load(f)
        inst = cls(); inst.vec = d["vec"]; inst.enc = _deserialize_encoding(d["enc"])
        inst.clf = d["clf"]; inst._fitted = True; inst.n_classes = len(inst.enc)
        return inst

# ─── Stage 2: LightGBM LambdaRank ────────────────────────────────────────────

class LambdaRankModel:
    """LightGBM LambdaRank for a single action-type."""

    def __init__(self, action_type, action_obj_freqs, n_features=DEFAULT_N_FEATURES,
                 n_negatives=DEFAULT_NEGATIVES):
        self.action_type = action_type
        self.action_obj_freqs = action_obj_freqs  # Counter of action_obj -> count
        self.n_negatives = n_negatives
        self.vec = HashingVectorizer(n_features=n_features, alternate_sign=False,
                                      norm="l2", dtype=np.float32)
        self.model = None
        self.top_candidates = [x for x, _ in action_obj_freqs.most_common(200)]
        self._fitted = False

    def build_training_data(self, records, max_queries=0):
        """Build LambdaRank training data from .mli-style records.

        Each record becomes a query group with 1 positive + n_negatives negative
        candidates.  Returns (X_sparse, y, groups).
        """
        import lightgbm as lgb

        # collect all distinct action-objs for negative sampling
        all_objs = list(self.action_obj_freqs.keys())
        if not all_objs or len(all_objs) < 2: return None, None, None
        all_objs_arr = np.array(all_objs, dtype=object)

        rng = np.random.RandomState(42)
        texts = []; labels = []; groups = []

        for rec in records:
            ao = rec["action_obj"]
            feats = rec["features"]

            # positive candidate
            texts.append(feats + " __CANDIDATE__ " + ao)
            labels.append(1)

            # negative candidates: sample from all_objs, skip the positive
            n_needed = self.n_negatives
            negs = []
            while len(negs) < n_needed:
                candidates = rng.choice(all_objs_arr, n_needed, replace=False)
                negs.extend(o for o in candidates if str(o) != ao)
            negs = negs[:n_needed]
            for neg in negs:
                texts.append(feats + " __CANDIDATE__ " + str(neg))
                labels.append(0)

            groups.append(n_needed + 1)

            if max_queries and len(groups) >= max_queries:
                break

        if not texts: return None, None, None

        X = self.vec.transform(texts)
        y = np.array(labels, dtype=np.float32)
        return X, y, groups

    def fit(self, records, max_queries=0):
        """Train LambdaRank model."""
        import lightgbm as lgb

        X, y, groups = self.build_training_data(records, max_queries)
        if X is None:
            logging.warning(f"  {self.action_type}: no training data, skipping")
            return

        # Convert sparse to LightGBM Dataset
        # LightGBM handles sparse matrices natively
        train_data = lgb.Dataset(X, label=y, group=groups)
        # Disable feature names from sparse matrix to avoid warning
        train_data.feature_names = None

        params = {
            "objective": "lambdarank",
            "metric": "ndcg",
            "ndcg_eval_at": [1, 3, 5],
            "boosting_type": "gbdt",
            "num_leaves": 255,
            "min_data_in_leaf": 20,
            "learning_rate": 0.05,
            "feature_fraction": 0.8,
            "bagging_fraction": 0.8,
            "bagging_freq": 5,
            "verbose": -1,
            "num_threads": os.cpu_count() or 4,
            "seed": 42,
        }

        logging.info(f"  {self.action_type}: training LambdaRank on {len(groups)} queries, {len(y)} candidates "
                      f"({DEFAULT_NUM_ROUNDS} rounds)")

        # progress callback
        callbacks = []
        if logging.getLogger().isEnabledFor(logging.INFO):
            def _log_progress(env):
                if env.iteration % 20 == 0 or env.iteration == env.end_iteration - 1:
                    try:
                        logging.info(f"    round {env.iteration+1}/{env.end_iteration} "
                                     f"ndcg@1={env.evaluation_result_list[0][2]:.4f}")
                    except Exception:
                        pass
            callbacks.append(_log_progress)

        self.model = lgb.train(params, train_data, num_boost_round=DEFAULT_NUM_ROUNDS,
                               callbacks=callbacks)
        self._fitted = True

    def predict(self, query_features, top_k=5):
        """Rank candidates for a query (checkpoint features string)."""
        if not self._fitted or self.model is None:
            return self.top_candidates[:top_k]

        # create candidate feature vectors
        candidate_texts = [query_features + " __CANDIDATE__ " + c
                          for c in self.top_candidates]
        X = self.vec.transform(candidate_texts)

        scores = self.model.predict(X)
        ranked_idx = np.argsort(-scores)[:top_k]
        return [self.top_candidates[i] for i in ranked_idx]

    def save(self, path):
        model_bytes = None
        if self.model is not None:
            model_bytes = self.model.model_to_string()
        data = {
            "action_type": self.action_type,
            "vec": self.vec,
            "action_obj_freqs": dict(self.action_obj_freqs),
            "n_negatives": self.n_negatives,
            "top_candidates": self.top_candidates,
            "model_bytes": model_bytes,
        }
        with open(path, "wb") as f:
            pickle.dump(data, f)

    @classmethod
    def load(cls, path):
        import lightgbm as lgb
        with open(path, "rb") as f: d = pickle.load(f)
        inst = cls(d["action_type"], Counter(d["action_obj_freqs"]),
                    n_negatives=d["n_negatives"])
        inst.vec = d["vec"]
        inst.top_candidates = d["top_candidates"]
        if d["model_bytes"]:
            inst.model = lgb.Booster(model_str=d["model_bytes"])
            inst._fitted = True
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

def discover_action_types(root_dir, max_files=200):
    from summarize_mli import process_one_mli
    types = set(); count = 0
    for p in sorted(Path(root_dir).rglob("*.mli")):
        if count >= max_files: break
        types.update(process_one_mli(str(p)).keys()); count += 1
    return sorted(types)

# ─── evaluation ──────────────────────────────────────────────────────────────

def evaluate_models(type_model, per_type_models, eval_items, freq_models=None,
                    top_k_at=3, top_k_obj=5):
    eval_features = [features_from_item(it) for it in eval_items]
    B = 2000

    # stage 1
    all_pred_types = []
    for i in range(0, len(eval_features), B):
        all_pred_types.extend(type_model.predict(eval_features[i:i+B], top_k=top_k_at))

    # stage 2: group by type and predict
    per_type_feats = defaultdict(list)
    per_type_idx_map = {}  # global_idx -> (action_type, local_idx)
    per_type_objs = {}
    for idx, item in enumerate(eval_items):
        at = item.get("output", {}).get("action-type", "")
        ao = item.get("output", {}).get("action-obj", "")
        if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))
        if at in per_type_models:
            local_idx = len(per_type_feats[at])
            per_type_feats[at].append(eval_features[idx])
            per_type_idx_map[idx] = (at, local_idx)
            per_type_objs.setdefault(at, []).append(ao)

    per_type_preds = {}
    for at, feat_list in per_type_feats.items():
        model = per_type_models[at]
        preds = [model.predict(f, top_k=top_k_obj) for f in feat_list]
        per_type_preds[at] = preds

    at_correct = at_total = 0
    obj_recall5 = defaultdict(int); obj_recall10 = defaultdict(int)
    obj_mrr_sum = defaultdict(float); obj_total = defaultdict(int)
    freq_recall = defaultdict(int)

    for idx, item in enumerate(eval_items):
        at = item.get("output", {}).get("action-type", "")
        ao = item.get("output", {}).get("action-obj", "")
        if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))

        at_total += 1
        if at in all_pred_types[idx]: at_correct += 1
        obj_total[at] += 1

        if at in per_type_models and idx in per_type_idx_map:
            ptype, local_idx = per_type_idx_map[idx]
            preds = per_type_preds[ptype][local_idx]
            if ao in preds[:5]: obj_recall5[at] += 1
            if ao in preds[:10]: obj_recall10[at] += 1
            try: obj_mrr_sum[at] += 1.0 / (preds.index(ao) + 1)
            except ValueError: pass

        if freq_models and at in freq_models:
            if ao in freq_models[at].predict_top(k=top_k_obj):
                freq_recall[at] += 1

    results = {
        "at_acc": at_correct / max(at_total, 1), "at_total": at_total,
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

# ─── main ────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(description="Train LightGBM LambdaRank for ACL2 proof fixes.")
    p.add_argument("data_dir", help="Root .mli directory")
    p.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    p.add_argument("--resume", default=None, help="Resume from model dir")
    p.add_argument("--eval-fraction", type=float, default=0.05)
    p.add_argument("--max-queries", type=int, default=DEFAULT_MAX_QUERIES,
                    help="Max LambdaRank queries to train on (0=all)")
    p.add_argument("--n-features", type=int, default=DEFAULT_N_FEATURES)
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
        for f in rd.glob("lambdarank_*.pkl"):
            m = LambdaRankModel.load(f); per_type_models[m.action_type] = m
        logging.info(f"  Loaded type model + {len(per_type_models)} LambdaRank models")
        skip_phase1 = True
    else:
        discovered = discover_action_types(args.data_dir)
        logging.info(f"Discovered {len(discovered)} action types: {discovered}")
        type_model = ActionTypeModel(n_features=args.n_features, known_types=discovered)
        per_type_models = {}
        skip_phase1 = False

    # ── Phase 1: Train Stage 1 (action-type classifier) ──
    eval_items = []
    total_train = 0; total_eval = 0

    if skip_phase1:
        logging.info("=== Phase 1: SKIPPED (resuming from saved model) ===")
        for is_eval, item in stream_mli_items(args.data_dir, eval_frac=args.eval_fraction):
            if is_eval: eval_items.append(item); total_eval += 1
            else: total_train += 1
        logging.info(f"  collected {total_eval} eval items (train skipped)")
    else:
        logging.info("=== Phase 1: Training action-type classifier ===")
        chunk_size = 5000
        train_texts = []; train_types = []

        def flush_type():
            nonlocal total_train
            if not train_texts: return
            type_model.partial_fit(train_texts, train_types)
            total_train += len(train_texts)
            logging.info(f"  type model: {total_train} samples")
            train_texts.clear(); train_types.clear()

        for is_eval, item in stream_mli_items(args.data_dir, eval_frac=args.eval_fraction):
            at = item.get("output", {}).get("action-type", "")
            if not at: continue
            feats = features_from_item(item)
            if is_eval:
                eval_items.append(item); total_eval += 1
            else:
                train_texts.append(feats); train_types.append(at)
                if len(train_texts) >= chunk_size: flush_type()

        flush_type()
        logging.info(f"Stage 1 done: {total_train} train, {total_eval} eval")
        type_model.save(out / "action_type_model.pkl")
        logging.info(f"  saved action_type_model to {out}")

    # ── Phase 2: Train Stage 2 (LambdaRank per action-type) ──
    logging.info("=== Phase 2: Training LambdaRank models ===")

    # Second pass: collect records per action-type for LambdaRank training
    type_records = defaultdict(list)
    type_freqs = defaultdict(Counter)
    max_queries = args.max_queries

    for is_eval, item in stream_mli_items(args.data_dir, eval_frac=args.eval_fraction):
        if is_eval: continue  # train only
        at = item.get("output", {}).get("action-type", "")
        ao = item.get("output", {}).get("action-obj", "")
        if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))
        if not at or not ao: continue
        if at not in PER_TYPE_CLASSIFIERS: continue
        if max_queries and len(type_records[at]) >= max_queries: continue

        type_freqs[at][ao] += 1
        type_records[at].append({
            "action_obj": ao,
            "features": features_from_item(item),
        })
        if len(type_records[at]) % 50000 == 0:
            logging.info(f"  collected {len(type_records[at])} records for {at}")

    for at in PER_TYPE_CLASSIFIERS:
        if at not in type_records or len(type_records[at]) < MIN_CANDIDATES:
            logging.info(f"  {at}: {len(type_records.get(at, []))} records, skipping (< {MIN_CANDIDATES})")
            continue
        if len(type_freqs[at]) < MIN_CANDIDATES:
            logging.info(f"  {at}: {len(type_freqs[at])} unique objects, skipping (< {MIN_CANDIDATES})")
            continue

        model = LambdaRankModel(at, type_freqs[at], n_features=args.n_features)
        model.fit(type_records[at], max_queries=max_queries)
        per_type_models[at] = model

    # ── Build frequency baselines ──
    freq_models = {}
    for it in eval_items:
        at = it.get("output", {}).get("action-type", "")
        ao = it.get("output", {}).get("action-obj", "")
        if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))
        freq_models.setdefault(at, FrequencyBaseline()).counts[ao] += 1

    # ── Evaluate ──
    if eval_items:
        logging.info(f"=== Evaluating on {len(eval_items)} hold-out samples ===")
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
                             f"(freq R@5={results.get(f'freq_r5_{at}',0):.4f}) "
                             f"n={results[f'n_{at}']}")

    # ── Save ──
    logging.info(f"Saving models to {out}")
    type_model.save(out / "action_type_model.pkl")
    for at, m in per_type_models.items():
        m.save(out / f"lambdarank_{at.replace('/','_').replace(':','_')}.pkl")
    with open(out / "frequency_baselines.pkl", "wb") as f:
        pickle.dump({at: dict(ff.counts) for at, ff in freq_models.items()}, f)
    with open(out / "training_summary.json", "w") as f:
        json.dump({"train_samples": total_train, "eval_samples": total_eval,
                   "action_types_trained": sorted(per_type_models),
                   "max_queries": args.max_queries,
                   "n_features": args.n_features}, f, indent=2)
    logging.info("Done!")

if __name__ == "__main__":
    main()
