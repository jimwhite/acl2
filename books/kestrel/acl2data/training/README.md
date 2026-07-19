# Graph2Tocopo Training

> **Quick start for host:** `pip install -e training/ && python training/test_model.py`
> See [Host Setup](#host-setup-macos-gpu) below for full GPU training.

Reimplementation of the **Graph2Tocopo** model with **GGNN encoder**
from Kyle Thompson's 2023 thesis:
*"Deep Learning Recommendations for the ACL2 Interactive Theorem Prover"*.

## Architecture

```
┌─────────────────────────────────────────────────┐
│               INPUT GRAPH                        │
│  Broken theorem + checkpoints → tree → graph    │
│  Node types: token, subtoken, root              │
│  Edge types: tok2tok, tok2sub, sub2sub + rev    │
│  Subtokenization: split on dashes               │
└──────────────────┬──────────────────────────────┘
                   │
          ┌────────▼────────┐
          │   GGNN Encoder   │  ← Message-passing over T timesteps
          │  (GRU updates)   │    Node embeddings encode structure
          └────────┬────────┘
                   │
          ┌────────▼────────┐
          │ Tocopo Decoder   │  ← Autoregressive with COPY mechanism
          │  (Transformer)   │    Can copy symbols from input graph
          └────────┬────────┘
                   │
          ┌────────▼────────┐
          │  OUTPUT FIX      │
          │ [:hint -setting  │
          │  -alist (:enable │
          │  factorial)]     │
          └──────────────────┘
```

### Key Design Decisions (from thesis)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Encoder | GGNN | 38.4% Top-1 vs 26.98% for GREAT |
| Copy mechanism | Yes | Graph2Tocopo vs Graph2To: 38.4% vs 27.57% |
| Subtokenization | Split on dashes | 38.4% vs 36.27% for BPE |
| Edge types | 6 directed + 2 root | tok2tok, tok2sub, sub2sub + reverses + root2expr |
| Split strategy | Book-level hash | Prevents data leakage from related lemmas |

### Thesis Results (Graph2Tocopo GGNN)

| Metric | Score |
|--------|-------|
| Top-1 accuracy | 38.4% |
| Top action-type accuracy | 46.12% |
| Theorems fixed (10 queries) | ~20% |
| Training time | ~2 days on Tesla T4 |

## Directory Structure

```
training/
├── __init__.py              # Package exports
├── pyproject.toml           # Dependencies + entry points
├── data_utils.py            # Graph construction, vocab, subtokenization
├── ggnn_encoder.py          # GGNN + GREAT encoder implementations
├── tocopopo_decoder.py      # Tocopo decoder with copy mechanism
├── graph2tocopo_model.py    # Full encoder-decoder model
├── train.py                 # Training script (for GPU host)
├── server.py                # HTTP advice server (for ACL2)
└── test_model.py            # CPU-friendly unit tests
```

## Development (devcontainer)

Tests run on CPU — no GPU needed:

```bash
cd /workspaces/acl2-jupyter/context/acl2/books/kestrel/acl2data
source training/.venv/bin/activate

# Install (editable mode — needed once after dependency changes)
pip install -e training/

# Run tests
python training/test_model.py
```

Expected output: all 5 tests pass in under 10 seconds.

## Training (MacOS Host — uses GPU)

Training requires GPU (MPS on Apple Silicon, CUDA on NVIDIA):

```bash
# On the Mac Studio host, first ensure the venv is set up:
cd /path/to/acl2data
python -m venv .venv
source .venv/bin/activate
pip install -e training/

# Quick test with limited data:
python training/train.py \
    --data-dir /path/to/data/books \
    --output-dir ./models_v5 \
    --max-items 10000 \
    --epochs 5 \
    --batch-size 8 \
    --hidden-dim 256

# Full training (equivalent to thesis):
python training/train.py \
    --data-dir /path/to/data/books \
    --output-dir ./models_v5 \
    --epochs 20 \
    --batch-size 8 \
    --hidden-dim 256 \
    --encoder-type ggnn
```

Model checkpoints are saved to `--output-dir` (default: `./models_v5`).
The best model (by action-type accuracy) is `best_model.pt`.

## Serving (Advice Tool)

Start the HTTP server that ACL2 queries:

```bash
python -m training.server \
    --model ./models_v5/best_model.pt \
    --port 8765
```

ACL2 users then call `(advice)` after a failed proof attempt to get
recommendations.

## Dependencies

All declared in `training/pyproject.toml`:

- `torch>=2.0.0` — model training and inference
- `numpy` — numerical operations
- `scipy` — sparse matrix support
- `scikit-learn` — evaluation metrics
- `ijson` — streaming .mli file parsing
- `tqdm` — progress bars

Install with: `pip install -e training/`

## Learnings

1. **Pyproject.toml is the single source of truth** for dependencies.
   No separate requirements.txt needed.

2. **Tests in devcontainer are CPU-only and fast.**  Real training needs
   the host for GPU access.  Use `--max-items` to limit data for testing.

3. **Book-level split prevents data leakage.**  The thesis splits by
   hashing the book directory, so lemmas from the same book are never
   split between train and eval.

4. **Subtokens from dashes beat BPE.**  ACL2 symbols use dashes like
   Java uses camelCase.  `functional-inversion-of-minus` splits naturally
   to `[functional, -inversion, -of, -minus]`.

5. **Copy mechanism is critical.**  ~11 percentage point accuracy gain
   over sequence-only models.  Many ACL2 fixes involve enabling rules
   that appear verbatim in the checkpoint.

6. **The advice tool tries each recommendation independently.**
   It does not stack recommendations — queries the model up to 10 times
   per broken theorem, rotating through checkpoints.

## References

- Thompson, K. (2023). "Deep Learning Recommendations for the ACL2
  Interactive Theorem Prover."  MS Thesis, Cal Poly.
- Allamanis, M., Brockschmidt, M., & Khademi, M. (2018). "Learning to
  Represent Programs with Graphs."  ICLR 2018.
- Chen, Z., et al. (2021). "PLUR: A Unifying, Graph-Based View of
  Program Learning, Understanding, and Repair."  NeurIPS 2021.
- Tarlow, D., et al. (2020). "Learning to Fix Build Errors with
  Graph2Diff."  NeurIPS 2020.
