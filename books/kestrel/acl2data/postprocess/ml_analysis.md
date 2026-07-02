# ML Approaches for Contextual ACL2 Proof Action Prioritization

## The Core Problem

The current two-stage SGDClassifier achieves 67% on Stage 1 (action-type) but only 6.3% on Stage 2 (action-obj) — worse than the 12.3% frequency baseline. This is a classic symptom of **extreme label imbalance overwhelming a linear model**: `CDR-CONS` alone is ~4% of all `use-lemma` labels, so a model with no class weighting learns to predict the head distribution rather than to discriminate using context. The good news from the per-type breakdown is that the model already learns *something* meaningful — 9.1% vs 4.3% frequency for `use-lemma` — confirming the input features carry signal. The task is to extract that signal properly.

The problem structure is worth naming precisely: given a checkpoint s-expression and goal string, predict a ranked list of (action-type, action-obj) pairs where the correct answer is usually a rare lemma. This is a **contextual ranking problem over a large, power-law-distributed label set**, not a flat multiclass classification problem. Framing it correctly drives every subsequent model choice.

***

## Why the Current Approach Underperforms

**SGDClassifier with hinge loss** is a linear SVM trained online. For a label space with ~70,000 distinct action objects:

1. **Hinge loss doesn't produce calibrated probabilities.** You can't extract a meaningful ranked score — you only get a hard prediction. Using `predict_proba` on an SGD hinge model requires Platt scaling, which is unreliable at this imbalance ratio.
2. **A single-pass stream trains each class with very few positive examples.** A lemma that appears 20 times in 4.7M records contributes almost no gradient before being forgotten by subsequent updates.
3. **HashingVectorizer treats every token independently.** The checkpoint `(NOT (NATP VAR-0))` and `(NOT (NATP VAR-1))` produce different hash buckets despite being structurally identical after normalisation. Bag-of-tokens loses compositional structure.
4. **The per-type sub-model sees massively imbalanced binary problems.** For the `use-lemma` sub-model, `CDR-CONS` vs everything else is ~4% positive — a linear model with default weights ignores it.[1]

***

## Recommended Approach: Two-Stage Retrieval + Reranking

The most robust fix, requiring the least architectural change, is to reframe Stage 2 as a **retrieval-then-rerank** problem rather than a classification problem. This is the architecture that consistently wins in analogous settings (code completion, API prediction, theorem hint suggestion).[2][3]

### Stage 1 — Keep and Improve Action-Type Classifier

67% accuracy is usable. To push it higher:

- Switch loss to `log` (logistic regression) instead of `hinge`. This produces calibrated probabilities so you can emit ranked action-types, not just the argmax.
- Add **class weights**: `class_weight = total / (n_classes × count_per_class)`. In scikit-learn this is `class_weight='balanced'` or an explicit dict. This is the single highest-ROI change for any imbalanced SGD model.[4]
- Use **multiple passes** (3–5 epochs) over the data with shuffled streaming rather than a single pass. ijson streaming makes this straightforward; just re-iterate the file list.

### Stage 2 — Replace Classification with Bi-Encoder Retrieval

Instead of predicting action-obj as a class, embed the checkpoint into a vector space and retrieve the nearest training examples. The action-obj of the retrieved examples is your ranked candidate list.

**How to build it:**

1. **Encode each training record** as a dense vector. The `checkpoint-sequence` token list is your query; the `action-obj` is the label.
2. **Train a bi-encoder** (two small transformer towers, or even a fine-tuned `sentence-transformers` model) with contrastive/triplet loss: pull similar checkpoints (same correct action-obj) together, push dissimilar ones apart.[5]
3. **At inference**, embed the live checkpoint and retrieve the top-K nearest neighbors from an ANN index (FAISS or `usearch`). The action-obj values of the neighbors, weighted by distance, form your ranked list.

The critical advantage: rare lemmas are handled naturally. If a checkpoint is structurally similar to a handful of training cases that all needed `ASSOC-EQUAL`, the retrieval surface those cases even if `ASSOC-EQUAL` appears in only 50 records. A classifier can never do this — it assigns zero probability mass to labels it has rarely seen.

**Contrastive training recipe for this dataset:**

```python
# Positive pair: two records with the same action-obj
# Hard negative: records with the same action-type but different action-obj
# (structurally similar proofs that needed different lemmas)

from sentence_transformers import SentenceTransformer, losses, InputExample
from torch.utils.data import DataLoader

# Convert checkpoint-sequence to a string
def seq_to_str(seq): return " ".join(seq)

# Build triplets: (anchor_ck, positive_ck, hard_neg_ck)
# Anchor and positive share action-obj; hard-neg shares action-type only
train_examples = build_triplets(mli_records)  # group by action-obj

model = SentenceTransformer("microsoft/codebert-base")  # or a small BERT

train_loss = losses.TripletLoss(model)
# Or MultipleNegativesRankingLoss for faster convergence with in-batch negatives
train_loss = losses.MultipleNegativesRankingLoss(model)

dataloader = DataLoader(train_examples, shuffle=True, batch_size=64)
model.fit(train_objectives=[(dataloader, train_loss)], epochs=3)

# Build FAISS index over all training records
embeddings = model.encode([seq_to_str(r['input']['checkpoint-sequence'])
                           for r in all_records])
import faiss
index = faiss.IndexFlatIP(embeddings.shape[1])  # inner product = cosine after L2-norm
faiss.normalize_L2(embeddings)
index.add(embeddings)
```

### Stage 2 — Alternative: LightGBM with Explicit Rank-Aware Training

If you want to stay within the scikit-learn/gradient-boosted-tree world, LightGBM with **`objective='lambdarank'`** is the right model. LambdaRank directly optimises NDCG — the metric you actually care about (is the correct lemma in the top 5?) — rather than classification accuracy.[6][7]

```python
import lightgbm as lgb

# Encode checkpoint as feature vector (n-gram hash or TF-IDF)
# Build query groups: all candidates for a given checkpoint form one group
# Label: 1 if candidate == ground-truth action-obj, 0 otherwise
# (Optional: label by reciprocal rank if you have multiple valid fixes)

train_data = lgb.Dataset(X_train, label=y_train, group=query_groups)
params = {
    'objective': 'lambdarank',
    'metric': 'ndcg',
    'ndcg_eval_at': [1, 3, 5, 10],
    'learning_rate': 0.05,
    'num_leaves': 127,
    'min_data_in_leaf': 20,  # critical for rare labels
    'is_unbalance': True,
}
model = lgb.train(params, train_data, num_boost_round=500)
```

The candidate generation step (what to rank) is: for a given checkpoint, take all `action-obj` values that appear with the predicted `action-type` from Stage 1, weighted by corpus frequency. You rank these candidates, not the full label space.

**LightGBM with `is_unbalance=True`** also handles the label-skew problem better than SGDClassifier because gradient boosted trees build residual correctors that can focus on minority-class errors in later rounds.[8][6]

***

## Input Feature Engineering

The current features are flat token hashes from `checkpoint-sequence`. These improvements are ordered by implementation effort:

### Quick wins (days)

**1. Goal-string differentiation.** The current model uses `goal-str` as a feature, but `checkpoint-structure` (the parsed and variable-normalised s-expression) is richer. Add features for:
- Top-level function symbols in the checkpoint (e.g., `BINARY-APPEND`, `NATP`)
- Depth of the deepest subterm
- Whether the checkpoint contains `NOT` at top level (negated goals behave differently)
- Whether the goal and checkpoint are identical (no progress was made)

**2. Broken-goal features.** The `metadata.broken-goal-str` field shows what was removed. The delta between the original goal and broken goal is highly predictive: if `BINARY-APPEND` was removed from the hypothesis, the model should weight `BINARY-APPEND`-enabling fixes heavily.

**3. Rule-class feature.** Whether the theorem's `:rule-classes` is `:rewrite`, `:type-prescription`, `:forward-chaining` etc. strongly conditions which fixes are applicable.

**4. Action-obj candidate frequency as a feature** (for the reranker). Explicitly include the log-frequency of the candidate `action-obj` in the training corpus as an input feature to the reranker. This lets the model learn *when* to defer to the frequency baseline and when to override it with context.

### Structural features (weeks)

**5. S-expression tree encoding.** The `checkpoint-structure` field is already a parsed tree. A Tree-LSTM or recursive neural network over this structure captures which *subterms* are the bottleneck — a checkpoint `(NOT (NATP (CDR X)))` signals something different from `(NOT (NATP X))` even though both contain `NATP`.

**6. Symbol co-occurrence.** Which function symbols appear *together* in the checkpoint? Build a sparse co-occurrence matrix over the training corpus. Two symbols that always co-occur with `CDR-CONS` fixes provide a strong signal even if individually they are ambiguous.

***

## The Hard Negative Problem

The dominant failure mode of a model that falls back to frequency is that **the negatives it trains against are too easy**. For a `use-lemma` record labelled `ASSOC-EQUAL`, the "negative" class is everything else — including `CDR-CONS`, which is structurally nothing like the checkpoint that needs `ASSOC-EQUAL`. The model never learns to discriminate between `CDR-CONS` and `ASSOC-EQUAL` in context because they rarely appear in the same training batch.

**Hard negative mining** fixes this: for each training checkpoint, the hard negatives are other checkpoints that also have `use-lemma` as their action-type (same Stage 1 label) but a *different* action-obj. These are structurally similar failure modes requiring different lemmas — exactly the discrimination the model needs to learn.[9][5]

```python
# Build a hard-negative index: for each action-obj, store the embeddings
# of checkpoints that were fixed by a *different* action-obj of the same type
from collections import defaultdict

by_action_type = defaultdict(list)
for rec in mli_records:
    by_action_type[rec['output']['action-type']].append(rec)

# For each record in use-lemma group, hard negatives = other use-lemma records
# with high checkpoint similarity but different action-obj
# Mine with FAISS: retrieve top-k similar; filter out same action-obj
```

***

## Evaluation Metric Change

Accuracy@1 (what the current eval reports) is the wrong metric for a ranking tool. A proof assistant that ranks the correct lemma at position 3 is nearly as useful as one that ranks it at position 1 — the agent tries the top-5 sequentially. Use:

- **Recall@5 and Recall@10**: is the correct action-obj anywhere in the top 5/10 predictions?
- **MRR (Mean Reciprocal Rank)**: average of 1/rank over the eval set — penalises pushing the right answer further down.
- **NDCG@10**: standard LTR metric, accounts for graded relevance if you have multiple valid fixes.

The current 6.3% accuracy@1 may already correspond to a much higher Recall@10. Measuring this first tells you whether the problem is ranking (model is right but not at position 1) or retrieval (model never surfaces the correct answer).

***

## Practical Upgrade Path

| Step | Change | Expected gain | Effort |
|---|---|---|---|
| 1 | SGD log-loss + `class_weight='balanced'` | Stage 2 accuracy@1 ~2–3× | Hours |
| 2 | Multi-epoch training (3 passes) | +5–10% Stage 1 | Hours |
| 3 | Add broken-goal delta features | Better discrimination for rare labels | Days |
| 4 | LightGBM lambdarank for Stage 2 (per action-type) | Optimises Recall@5 directly | Days |
| 5 | Bi-encoder + FAISS retrieval for Stage 2 | Rare lemma recall substantially improved | 1–2 weeks |
| 6 | Hard negative mining in contrastive training | Reduces head-label dominance | +1 week |
| 7 | Tree-LSTM / small Transformer over `checkpoint-structure` | Structural discrimination | Weeks |

The cheapest intervention with the highest expected ROI is **Step 1 + Step 4**: switch the loss and use LightGBM lambdarank. These stay within the scikit-learn/LightGBM ecosystem you already have, require no architectural change to inference, and directly target the metrics that matter for the agent use case. The bi-encoder path (Step 5) is the right long-term architecture because it naturally handles the rare-label case — but it requires training infrastructure and an ANN index at inference time.

***

## A Note on the Data Distribution

The dataset statistics clarify something important: `use-lemma` is 3.3M of 4.7M records (70%), and within it the label distribution is a heavy power-law. This means any model that predicts `use-lemma` for most inputs and `CDR-CONS` within that bin will look reasonable in aggregate while being useless for the long tail. The metric to track for practical utility is **Recall@10 on the bottom 90% of action-obj frequency** — i.e., everything that isn't in the top-10 most common lemmas. That is the number that tells you whether the model is actually learning context.