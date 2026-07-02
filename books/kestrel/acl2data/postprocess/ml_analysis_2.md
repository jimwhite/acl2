Now I have a precise picture. Let me give a focused, direct answer.

The literature gives a clear answer here. The strongest reported approach for the specific sub-problem you have — **contextual ranking of proof actions given a checkpoint** — is **online k-nearest neighbor (k-NN) retrieval**, not a trained classifier. This is the consistent finding across Tactician/Coq, ENIGMA/Isabelle, and the Mizar work, and it directly explains why your LambdaRank model collapses to frequency: it's solving the wrong problem formulation. [arxiv](https://arxiv.org/abs/2205.01981)

Here's the direct breakdown:

***

## The Literature Finding: k-NN Beats Trained Models for This Task

The Graph2Tac paper (ICML 2024) benchmarks every practical approach on the same premise-selection/tactic-prediction task you have, and the headline result is striking: **Tactician's online k-NN solver proves 1.72× more theorems than an offline-trained equivalent**, and the k-NN *beats* the GNN at small time budgets. The combination of k-NN + GNN beats any single model, but k-NN is the stronger of the two standalone systems. [proceedings.mlr](https://proceedings.mlr.press/v235/blaauwbroek24a.html)

ENIGMA for Isabelle reaches the same conclusion from the gradient-boosted-tree direction: LightGBM achieves state-of-the-art on premise selection not because of the model architecture, but because the training loop is **iterative** — the model is retrained on each new batch of successful proof attempts, so it learns what's locally relevant in the current corpus rather than the global frequency distribution. MizAR 60 on Mizar confirms this: LightGBM for binary premise classification (is this lemma relevant to this goal?) dramatically outperforms flat multiclass prediction, precisely because it avoids the long-tail problem by treating each candidate lemma as a separate binary question. [wwwlehre.dhbw-stuttgart](http://wwwlehre.dhbw-stuttgart.de/~sschulz/PAPERS/JCGKOPSSU-ITP-2023.pdf)

***

## Why Your Current Formulation Fails

Your LambdaRank model (and the SGD classifier before it) frames the problem as: **given a checkpoint, predict the correct lemma from a universal label set**. The literature is unanimous that this formulation doesn't work at scale because of the exact symptom you observed: `use-lemma` (70% of data, ~50,000+ distinct lemmas) is dominated by high-frequency heads regardless of context. [arxiv](https://arxiv.org/abs/2205.01981)

The winning formulation in every system that works is: **given a checkpoint, retrieve similar past checkpoints and rank their associated actions by similarity**. The model never has to predict a lemma it hasn't seen before — it only needs to judge similarity between the current checkpoint and stored ones.

***

## What to Build: Similarity-Based Online Retrieval

The directly applicable architecture, given your `.mli` data schema and existing infrastructure:

**Step 1 — Embed checkpoints as dense vectors.** The `checkpoint-sequence` token list is your query. Use any of:
- A fine-tuned `sentence-transformers` model (fastest to get working — `all-MiniLM-L6-v2` gives reasonable results on code-like tokens out of the box)
- A character/subword embedding over the normalized ACL2 token vocabulary (aligns better with ACL2's dash-separated identifiers)
- The ENIGMA approach: sparse feature vectors over symbol n-grams (2-grams work well and are extremely fast) [semanticscholar](https://www.semanticscholar.org/paper/LightGBM-Hyperparameter-Optimization-for-Clause-in-Goertzel-Jakubuv/1f21268505a22121559e21b622392394b1e4f89e)

**Step 2 — Index all training records by their checkpoint embedding.** FAISS `IndexFlatIP` (cosine similarity after L2 normalization) over all 4.7M records. With 128-dim embeddings this is ~2.4GB and runs in ~5ms per query on CPU.

**Step 3 — At inference, retrieve top-K most similar past checkpoints and return their `action-type` + `action-obj` as a ranked list.** The score is the cosine similarity, so you get a genuine ranked list rather than a flat classification. Rare lemmas that are contextually appropriate surface because a handful of training records with identical or near-identical checkpoint structure point to them — you never need to predict them from a frequency distribution.

**Step 4 — Apply action-type filtering from Stage 1.** Your existing 67%-accurate Stage 1 classifier is useful here: use it to re-weight retrieved candidates (boost items matching the predicted action-type, suppress others). This gives you a hybrid retrieval + classifier that outperforms either alone. [proceedings.mlr](https://proceedings.mlr.press/v235/blaauwbroek24a.html)

***

## The ENIGMA Binary Classifier Alternative

If you want a trained model rather than pure retrieval, the ENIGMA/MizAR approach is the best-documented winner for the ITP premise selection case: [wwwlehre.dhbw-stuttgart](http://wwwlehre.dhbw-stuttgart.de/~sschulz/PAPERS/JCGKOPSSU-ITP-2023.pdf)

Instead of predicting the single correct lemma from 50,000 options, train **one binary LightGBM classifier per candidate source** (or per action-type bucket), answering: *"Is this specific lemma/hint relevant to this checkpoint?"* Features are: symbol n-gram overlap between checkpoint tokens and the candidate lemma name + known co-occurrence patterns. This sidesteps the long-tail problem entirely — each binary problem is much better balanced, and LightGBM handles the residual imbalance cleanly. [journal.binus.ac](https://journal.binus.ac.id/index.php/EMACS/article/download/13435/5421)

The workflow is:
1. For each `(checkpoint, action-obj)` pair in training data, generate a positive record
2. For each checkpoint, sample negative candidates from the same `action-type` bucket (hard negatives)
3. Train a single LightGBM binary classifier: features = [checkpoint token set, candidate token set, intersection features], label = 1/0
4. At inference, score all candidates from the predicted action-type bucket and return top-K by predicted probability

This is what MizAR uses to achieve state-of-the-art on Mizar with LightGBM, and it's substantially simpler to implement than a bi-encoder. [wwwlehre.dhbw-stuttgart](http://wwwlehre.dhbw-stuttgart.de/~sschulz/PAPERS/JCGKOPSSU-ITP-2023.pdf)

***

## Practical Recommendation

Given that you're already on scikit-learn/LightGBM and have the full `.mli` corpus:

| Approach | Effort | Expected result |
|---|---|---|
| **FAISS k-NN over checkpoint-sequence TF-IDF embeddings** | 1–2 days | Likely beats frequency baseline significantly for rare lemmas; directly analogous to Tactician k-NN [proceedings.mlr](https://proceedings.mlr.press/v235/blaauwbroek24a.html) |
| **LightGBM binary classifier (one model, pairwise features)** | 3–5 days | MizAR approach; well-documented to work on exactly this data distribution [wwwlehre.dhbw-stuttgart](http://wwwlehre.dhbw-stuttgart.de/~sschulz/PAPERS/JCGKOPSSU-ITP-2023.pdf) |
| **Bi-encoder (sentence-transformers fine-tune)** | 1–2 weeks | Strongest long-term architecture, but the k-NN result suggests the simpler version may close most of the gap first |

The k-NN approach should be tried first — it requires zero training, uses your existing data directly, and the literature consistently shows it outperforms offline-trained models on the precisely analogous task. If retrieval quality is limited by the embedding (TF-IDF misses structural similarity), the LightGBM pairwise binary model is the next step. [proceedings.mlr](https://proceedings.mlr.press/v235/blaauwbroek24a.html)
