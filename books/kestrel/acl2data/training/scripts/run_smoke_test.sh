#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Graph2Tocopo: Smoke Test
#
# Runs a quick training run on a subset of data to verify the pipeline
# works end-to-end before launching full training.
#
# Usage:
#   bash training/scripts/run_smoke_test.sh
#
# The DATA_DIR path should point to the .mli directory (community books).
# Override with:  DATA_DIR=/my/path bash training/scripts/run_smoke_test.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/../.."   # cd to acl2data/

DATA_DIR="${DATA_DIR:-../../../../../data/books}"
OUTPUT_DIR="${OUTPUT_DIR:-./models_v5_smoke}"

echo "=== Graph2Tocopo Smoke Test ==="
echo "Data dir:   $DATA_DIR"
echo "Output dir: $OUTPUT_DIR"
echo ""

source training/.venv/bin/activate

echo "1. Installing package..."
pip install -q -e training/

echo "2. Running unit tests..."
python training/test_model.py

echo ""
echo "3. Smoke training (10K items, 3 epochs)..."
python training/train.py \
    --data-dir "$DATA_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --max-items 10000 \
    --epochs 3 \
    --batch-size 8 \
    --hidden-dim 256 \
    --num-workers 4

echo ""
echo "=== Smoke test complete ==="
echo "Checkpoint: $OUTPUT_DIR/best_model.pt"
