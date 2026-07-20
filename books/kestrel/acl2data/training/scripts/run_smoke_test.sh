#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Graph2Tocopo: Smoke Test
#
# Preprocesses 10K .mli items, then trains 3 epochs on GPU.
# All paths baked in — just run from acl2data/.
#
# Usage:
#   bash training/scripts/run_smoke_test.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/../.."   # cd to acl2data/

MLI_DIR="${MLI_DIR:-../../../../../data/books}"
PREPROC_DIR="${PREPROC_DIR:-../../../../../data/preprocessed_smoke}"
OUTPUT_DIR="${OUTPUT_DIR:-./models_v5_smoke}"

echo "=== Graph2Tocopo Smoke Test ==="
echo "MLI dir:      $MLI_DIR"
echo "Preproc dir:  $PREPROC_DIR"
echo "Output dir:   $OUTPUT_DIR"
echo ""

source training/.venv/bin/activate

echo "1. Installing package..."
uv pip install -q -e training/

echo "2. Running unit tests..."
python training/test_model.py

echo ""
echo "3. Preprocessing 10K items..."
python training/preprocess.py \
    --data-dir "$MLI_DIR" \
    --output-dir "$PREPROC_DIR" \
    --max-workers 4

echo ""
echo "4. Training 3 epochs..."
python training/train.py \
    --data-dir "$PREPROC_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --max-items 10000 \
    --epochs 3 \
    --batch-size 8 \
    --hidden-dim 256 \
    --num-workers 4

echo ""
echo "=== Smoke test complete ==="
echo "Best model: $OUTPUT_DIR/best_model.pt"
