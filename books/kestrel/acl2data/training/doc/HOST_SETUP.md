# Host Setup & Training Guide

How to train Graph2Tocopo on the Mac Studio with GPU acceleration.

## Prerequisites

- Mac Studio with Apple Silicon (MPS GPU) or NVIDIA GPU (CUDA)
- Python 3.10+
- ACL2 community books `.mli` dataset at `/path/to/data/books/`
- This repository synced to the host

## 1. Install

```bash
cd /path/to/acl2-jupyter/context/acl2/books/kestrel/acl2data
python3.12 -m venv .venv
source .venv/bin/activate
pip install -e training/
```

## 2. Verify

```bash
python training/test_model.py
# Expected: "All tests passed!" in <1 second
```

Check GPU availability:
```bash
python -c "import torch; print(f'GPU available: {torch.cuda.is_available() or torch.backends.mps.is_available()}')"
```

## 3. Smoke Test (small data)

```bash
python training/train.py \
    --data-dir /path/to/data/books \
    --output-dir ./models_v5 \
    --max-items 10000 \
    --epochs 3 \
    --batch-size 8 \
    --hidden-dim 256
```

This should run in minutes and produce checkpoints in `./models_v5/`.

## 4. Full Training

```bash
python training/train.py \
    --data-dir /path/to/data/books \
    --output-dir ./models_v5 \
    --epochs 20 \
    --batch-size 8 \
    --hidden-dim 256 \
    --encoder-type ggnn \
    --num-workers 8
```

Expected: ~2 days on T4-class GPU (per thesis). Best model saved as
`./models_v5/best_model.pt`.

Key training flags:

| Flag | Default | Purpose |
|------|---------|---------|
| `--data-dir` | — | Path to `.mli` files (required) |
| `--output-dir` | `./models_v5` | Checkpoint directory |
| `--hidden-dim` | 256 | Embedding dimension |
| `--batch-size` | 8 | Per-GPU batch size |
| `--epochs` | 20 | Training epochs |
| `--lr` | 1e-4 | Learning rate (Adam) |
| `--max-nodes` | 512 | Max graph nodes (truncation) |
| `--eval-frac` | 0.05 | Fraction for validation (book-level split) |
| `--encoder-type` | `ggnn` | `ggnn` or `great` |
| `--num-workers` | 2 | DataLoader workers |
| `--max-items` | None | Cap data size for testing |
| `--exclude` | `kestrel/helpers` | Directories to skip |

## 5. Start Advice Server

```bash
python -m training.server \
    --model ./models_v5/best_model.pt \
    --port 8765
```

Then in ACL2: after a failed proof attempt, call `(advice)` to get
model recommendations.

## Expected Results (from thesis)

| Metric | Graph2Tocopo (GGNN) |
|--------|---------------------|
| Top-1 accuracy | 38.4% |
| Top action-type accuracy | 46.12% |
| Theorems fixed (10 queries) | ~20% |
