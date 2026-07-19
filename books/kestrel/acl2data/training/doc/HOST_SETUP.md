# Host Setup & Training Guide

How to train Graph2Tocopo on the Mac Studio with GPU acceleration.

## Prerequisites

- Mac Studio with Apple Silicon (MPS GPU) or NVIDIA GPU (CUDA)
- Python 3.10+
- ACL2 community books `.mli` dataset at `data/books/` in the parent workspace
  (`/workspaces/acl2-jupyter/data/books` in devcontainer)
- This repository synced to the host at `context/acl2/` (submodule)

## Quick Start

All paths are baked into the scripts — no manual flags needed:

```bash
cd /path/to/acl2-jupyter/context/acl2/books/kestrel/acl2data
source training/.venv/bin/activate

# 1. Smoke test (10K items, ~5 min)
bash training/scripts/run_smoke_test.sh

# 2. Full training (~2 days on GPU)
bash training/scripts/run_train.sh

# 3. Start advice server
bash training/scripts/run_server.sh
```

Override data path if needed:
```bash
DATA_DIR=/other/path/to/data bash training/scripts/run_train.sh
```

## Manual Install (if scripts can't find venv)

```bash
cd /path/to/acl2data
python3.12 -m venv training/.venv
source training/.venv/bin/activate
pip install -e training/
python training/test_model.py
```

## Verify GPU

```bash
python -c "import torch; print(f'MPS: {torch.backends.mps.is_available()}  CUDA: {torch.cuda.is_available()}')"
```

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `training/scripts/run_smoke_test.sh` | Quick 10K-item test run |
| `training/scripts/run_train.sh` | Full 20-epoch training |
| `training/scripts/run_server.sh` | Start HTTP advice server |

Environment variables (all optional, defaults set):

| Variable | Default | Scripts |
|----------|---------|---------|
| `DATA_DIR` | `../../../../../data/books` | smoke, train |
| `OUTPUT_DIR` | `./models_v5` | smoke, train |
| `MODEL` | `./models_v5/best_model.pt` | server |
| `PORT` | `8765` | server |
