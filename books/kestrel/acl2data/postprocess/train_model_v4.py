#!/usr/bin/env python3
"""
Phase 3 v4: k-NN Retrieval for ACL2 Proof Action Prediction

Literature-backed approach: for a failed checkpoint, retrieve the K most
similar past checkpoints from the training corpus and return their actions
as ranked suggestions.  No classifier training — just embedding + FAISS
indexing + similarity search.

References:
  - Blaauwbroek et al. (ICML 2024): Tactician's online k-NN beats GNN
  - ENIGMA/MizAR: LightGBM binary relevance, but k-NN is the simpler baseline
    that already outperforms offline-trained models for rare labels

Architecture:
  1. HashingVectorizer (262K-dim sparse) on checkpoint + goal tokens
  2. TruncatedSVD → 128-dim dense embeddings
  3. FAISS IndexIVFFlat for approximate nearest neighbor search
  4. Query: embed checkpoint → search FAISS → aggregate action-obj votes
     weighted by cosine similarity

Usage:
  python train_model_v4.py /workspaces/acl2-jupyter/data/books
  python train_model_v4.py /workspaces/acl2-jupyter/data/books \\
      --n-components 256 --n-neighbors 50
"""

import sys, os, json, pickle, hashlib, argparse, logging
from pathlib import Path
from collections import Counter, defaultdict

import numpy as np
from scipy.sparse import vstack
from sklearn.feature_extraction.text import HashingVectorizer
from sklearn.decomposition import TruncatedSVD
from sklearn.preprocessing import normalize

DEFAULT_OUTPUT_DIR = "./models_v4"
DEFAULT_N_FEATURES = 2**18
DEFAULT_N_COMPONENTS = 128      # SVD output dimension
DEFAULT_N_NEIGHBORS = 50        # K for k-NN
DEFAULT_SVD_SAMPLE = 500000     # records to fit SVD on
DEFAULT_NLIST = 200             # FAISS IVF clusters

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

# ─── embedding ──────────────────────────────────────────────────────────────

class CheckpointEmbedder:
    """HashingVectorizer → TruncatedSVD → L2-normalized dense embeddings."""

    def __init__(self, n_features=DEFAULT_N_FEATURES, n_components=DEFAULT_N_COMPONENTS):
        self.hasher = HashingVectorizer(n_features=n_features, alternate_sign=False,
                                         norm=None, dtype=np.float32)
        self.svd = None
        self.n_components = n_components
        self._fitted = False

    def fit_svd(self, texts, sample_size=DEFAULT_SVD_SAMPLE):
        """Fit TruncatedSVD on a sample of the hashed vectors."""
        if len(texts) > sample_size:
            idx = np.random.RandomState(42).choice(len(texts), sample_size, replace=False)
            texts = [texts[i] for i in idx]
        logging.info(f"  fitting SVD on {len(texts)} samples ...")
        X_sample = self.hasher.transform(texts)
        self.svd = TruncatedSVD(n_components=self.n_components, random_state=42)
        self.svd.fit(X_sample)
        self._fitted = True

    def transform(self, texts):
        """Hash → SVD → normalize."""
        X = self.hasher.transform(texts)
        if self.svd is not None:
            X = self.svd.transform(X)
        normalize(X, norm="l2", copy=False)
        return X.astype(np.float32)

    def save(self, path):
        with open(path, "wb") as f:
            pickle.dump({"hasher": self.hasher, "svd": self.svd,
                         "n_components": self.n_components}, f)

    @classmethod
    def load(cls, path):
        with open(path, "rb") as f: d = pickle.load(f)
        inst = cls(n_components=d["n_components"])
        inst.hasher = d["hasher"]; inst.svd = d["svd"]
        inst._fitted = inst.svd is not None
        return inst

# ─── index ───────────────────────────────────────────────────────────────────

class KNNIndex:
    """FAISS index over checkpoint embeddings, mapping to action records."""

    def __init__(self):
        self.index = None
        self.records = []          # list of (action_type, action_obj) tuples
        self._fitted = False

    def build(self, embeddings, records):
        """Build FAISS IVF index."""
        import faiss
        n = len(embeddings)
        d = embeddings.shape[1]
        nlist = min(DEFAULT_NLIST, int(np.sqrt(n)))

        quantizer = faiss.IndexFlatIP(d)
        self.index = faiss.IndexIVFFlat(quantizer, d, nlist, faiss.METRIC_INNER_PRODUCT)

        logging.info(f"  training FAISS index on {n} vectors, d={d}, nlist={nlist} ...")
        self.index.train(embeddings)
        self.index.add(embeddings)
        self.index.nprobe = 16
        self.records = list(records)
        self._fitted = True

    def search(self, query_embeddings, k=DEFAULT_N_NEIGHBORS):
        """Return (distances, indices) for each query."""
        if not self._fitted: return None, None
        return self.index.search(query_embeddings, k)

    def predict(self, query_embeddings, k=DEFAULT_N_NEIGHBORS):
        """Return ranked list of (action_type, action_obj, score) per query."""
        if not self._fitted:
            return [[] for _ in range(len(query_embeddings))]
        distances, indices = self.search(query_embeddings, k)
        results = []
        for dists, idxs in zip(distances, indices):
            # aggregate votes weighted by cosine similarity
            votes = Counter()
            for d, i in zip(dists, idxs):
                if i < 0: break
                at, ao = self.records[i]
                votes[(at, ao)] += float(d)  # inner product = cosine for normalized vectors
            ranked = sorted(votes.items(), key=lambda x: -x[1])
            results.append([{"action_type": at, "action_obj": ao, "score": s}
                           for (at, ao), s in ranked])
        return results

    def save(self, path):
        import faiss
        faiss.write_index(self.index, str(path) + ".faiss")
        with open(str(path) + ".records", "wb") as f:
            pickle.dump(self.records, f)

    @classmethod
    def load(cls, path):
        import faiss
        inst = cls()
        inst.index = faiss.read_index(str(path) + ".faiss")
        inst.index.nprobe = 16
        with open(str(path) + ".records", "rb") as f:
            inst.records = pickle.load(f)
        inst._fitted = True
        return inst

# ─── streaming ───────────────────────────────────────────────────────────────

def stream_mli_items(root_dir, eval_frac=0.05, book_level_split=True, exclude_dirs=None):
    """Stream .mli records.  If book_level_split, entire book directories
    are assigned to train or eval (avoids data leakage from related lemmas)."""
    import ijson
    root = Path(root_dir)
    if exclude_dirs is None:
        exclude_dirs = set()
    for mli_path in sorted(root.rglob("*.mli")):
        # Skip excluded directories
        try:
            rel = mli_path.relative_to(root)
        except ValueError:
            continue
        parts = rel.parts
        excluded = False
        for exc in exclude_dirs:
            exc_parts = tuple(exc.strip('/').split('/'))
            if parts[:len(exc_parts)] == exc_parts:
                excluded = True
                break
        if excluded:
            continue
        if book_level_split:
            # Hash the book directory (relative to root), not the file
            rel = mli_path.relative_to(root)
            # Book = everything up to the first subdirectory
            book_key = str(rel.parent) if str(rel.parent) != '.' else str(rel.stem)
            split_hash = hashlib.md5(book_key.encode()).hexdigest()
        else:
            split_hash = hashlib.md5(str(mli_path).encode()).hexdigest()
        is_eval = int(split_hash, 16) % 1000 < int(eval_frac * 1000)
        try:
            with open(mli_path, "rb") as f:
                for item in ijson.items(f, "item"):
                    yield is_eval, item
        except Exception as e:
            logging.warning(f"Skipping {mli_path}: {e}")

# ─── evaluation ──────────────────────────────────────────────────────────────

def evaluate_knn(index, embedder, eval_items, top_k=5):
    """Evaluate k-NN retrieval on eval set."""
    logging.info(f"  embedding {len(eval_items)} eval items ...")
    eval_features = [features_from_item(it) for it in eval_items]
    eval_embeddings = embedder.transform(eval_features)

    logging.info(f"  searching ...")
    all_preds = index.predict(eval_embeddings, k=DEFAULT_N_NEIGHBORS)

    # also compute frequency baseline
    freq_counts = Counter()
    for it in eval_items:
        ao = it.get("output", {}).get("action-obj", "")
        if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))
        at = it.get("output", {}).get("action-type", "")
        freq_counts[(at, ao)] += 1

    freq_action_counts = Counter()
    for (at, ao), c in freq_counts.items():
        freq_action_counts[at] += c

    freq_top = {}
    for at in freq_action_counts:
        items = [(ao, c) for (a, ao), c in freq_counts.items() if a == at]
        freq_top[at] = [ao for ao, _ in sorted(items, key=lambda x: -x[1])[:top_k]]

    # compute metrics
    recall5 = defaultdict(int); recall10 = defaultdict(int)
    mrr_sum = defaultdict(float); total = defaultdict(int)
    freq_r5 = defaultdict(int)

    for idx, item in enumerate(eval_items):
        at = item.get("output", {}).get("action-type", "")
        ao = item.get("output", {}).get("action-obj", "")
        if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))
        total[at] += 1

        # k-NN predictions
        preds = all_preds[idx]
        pred_aos = [p["action_obj"] for p in preds[:top_k] if p["action_type"] == at]
        if not pred_aos:
            pred_aos = [p["action_obj"] for p in preds[:top_k]]  # any type

        if ao in pred_aos[:5]: recall5[at] += 1
        if ao in pred_aos[:10]: recall10[at] += 1
        try: mrr_sum[at] += 1.0 / (pred_aos.index(ao) + 1)
        except ValueError: pass

        # frequency baseline
        if at in freq_top and ao in freq_top[at]:
            freq_r5[at] += 1

    total_n = sum(total.values())
    results = {
        "recall5": sum(recall5.values()) / max(total_n, 1),
        "recall10": sum(recall10.values()) / max(total_n, 1),
        "mrr": sum(mrr_sum.values()) / max(total_n, 1),
        "freq_r5": sum(freq_r5.values()) / max(total_n, 1),
        "total": total_n,
    }
    for at in sorted(total.keys()):
        n = total[at]
        results[f"r5_{at}"] = recall5[at] / max(n, 1)
        results[f"r10_{at}"] = recall10[at] / max(n, 1)
        results[f"mrr_{at}"] = mrr_sum[at] / max(n, 1)
        results[f"freq_r5_{at}"] = freq_r5[at] / max(n, 1)
        results[f"n_{at}"] = n
    return results

# ─── main ────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser(description="k-NN retrieval for ACL2 proof fixes.")
    p.add_argument("data_dir", help="Root .mli directory")
    p.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR)
    p.add_argument("--resume", default=None)
    p.add_argument("--eval-fraction", type=float, default=0.05)
    p.add_argument("--n-components", type=int, default=DEFAULT_N_COMPONENTS)
    p.add_argument("--n-neighbors", type=int, default=DEFAULT_N_NEIGHBORS)
    p.add_argument("--exclude", nargs="*", default=["kestrel/helpers"],
                   help="Directories to exclude (default: kestrel/helpers)")
    p.add_argument("--log-level", default="INFO",
                   choices=["DEBUG","INFO","WARNING","ERROR"])
    args = p.parse_args()

    logging.basicConfig(level=getattr(logging, args.log_level),
                        format="%(asctime)s [%(levelname)s] %(message)s",
                        datefmt="%H:%M:%S")

    out = Path(args.output_dir); out.mkdir(parents=True, exist_ok=True)

    if args.resume:
        logging.info(f"Loading from {args.resume}")
        embedder = CheckpointEmbedder.load(Path(args.resume) / "embedder.pkl")
        index = KNNIndex.load(Path(args.resume) / "knn_index")
        logging.info("  loaded embedder + index")
    else:
        # ── Pass 1: collect training records ──
        logging.info("Pass 1: collecting training records ...")
        train_texts = []; train_records = []
        eval_items = []; total_eval = 0
        total_train = 0

        for is_eval, item in stream_mli_items(args.data_dir, eval_frac=args.eval_fraction,
                                               exclude_dirs=set(args.exclude)):
            at = item.get("output", {}).get("action-type", "")
            ao = item.get("output", {}).get("action-obj", "")
            if isinstance(ao, list): ao = json.dumps(ao, separators=(",", ":"))
            if not at or not ao: continue
            if is_eval:
                eval_items.append(item); total_eval += 1
            else:
                feats = features_from_item(item)
                train_texts.append(feats)
                train_records.append((at, ao))
                total_train += 1
                if total_train % 500000 == 0:
                    logging.info(f"  collected {total_train} train records")

        logging.info(f"  total: {total_train} train, {total_eval} eval")

        # ── Fit embedder ──
        embedder = CheckpointEmbedder(n_components=args.n_components)
        embedder.fit_svd(train_texts)

        # ── Embed all training records ──
        logging.info("Embedding training records ...")
        B = 50000
        embeddings_chunks = []
        for i in range(0, len(train_texts), B):
            chunk = embedder.transform(train_texts[i:i+B])
            embeddings_chunks.append(chunk)
            if (i // B) % 10 == 0:
                logging.info(f"  embedded {i}/{len(train_texts)}")
        embeddings = np.vstack(embeddings_chunks)
        logging.info(f"  embeddings shape: {embeddings.shape}")

        # ── Build FAISS index ──
        index = KNNIndex()
        index.build(embeddings, train_records)

        # Save
        embedder.save(out / "embedder.pkl")
        index.save(out / "knn_index")
        logging.info(f"Saved to {out}")

    # ── Evaluate ──
    if eval_items:
        import faiss
        results = evaluate_knn(index, embedder, eval_items)
        logging.info(f"=== Evaluation on {results['total']} hold-out samples ===")
        logging.info(f"  Recall@5:  {results['recall5']:.4f}")
        logging.info(f"  Recall@10: {results['recall10']:.4f}")
        logging.info(f"  MRR:       {results['mrr']:.4f}")
        logging.info(f"  Freq R@5:  {results['freq_r5']:.4f}")
        for at in sorted(results.keys()):
            if at.startswith("r5_") and results.get(at, 0) > 0:
                at_name = at[3:]
                n = results.get(f"n_{at_name}", 1)
                logging.info(f"    {at_name}: R@5={results[at]:.4f} "
                             f"R@10={results.get('r10_'+at_name,0):.4f} "
                             f"MRR={results.get('mrr_'+at_name,0):.4f} "
                             f"(freq={results.get('freq_r5_'+at_name,0):.4f}) n={n}")

    logging.info("Done!")

if __name__ == "__main__":
    main()
