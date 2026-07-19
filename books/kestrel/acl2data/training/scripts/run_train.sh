#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Graph2Tocopo: Full Training
#
# Trains the GGNN + Tocopo decoder model on the full ACL2 community books
# dataset.  Equivalent to the training run in Thompson (2023) thesis (~2 days).
#
# Usage:
#   bash training/scripts/run_train.sh
#
# Override data path:
#   DATA_DIR=/my/path bash training/scripts/run_train.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/../.."   # cd to acl2data/

DATA_DIR="${DATA_DIR:-../data/books}"
OUTPUT_DIR="${OUTPUT_DIR:-./models_v5}"

echo "=== Graph2Tocopo Full Training ==="
echo "Data dir:   $DATA_DIR"
echo "Output dir: $OUTPUT_DIR"
echo ""

source training/.venv/bin/activate

echo "1. Installing package..."
pip install -q -e training/

echo "2. Running unit tests..."
python training/test_model.py

echo ""
echo "3. Full training..."
python training/train.py \
    --data-dir "$DATA_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --epochs 20 \
    --batch-size 8 \
    --hidden-dim 256 \
    --encoder-type ggnn \
    --num-workers 8

echo ""
echo "=== Training complete ==="
echo "Best model: $OUTPUT_DIR/best_model.pt"
echo ""
echo "To start the advice server:"
echo "  bash training/scripts/run_server.sh"
