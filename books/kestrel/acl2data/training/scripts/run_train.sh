#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Graph2Tocopo: Full Training
#
# 1. Preprocess all .mli → .pt tensors (multicore)
# 2. Train 20 epochs on GPU
#
# The preprocess step is skipped if preprocessed data already exists.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/../.."   # cd to acl2data/

MLI_DIR="${MLI_DIR:-../../../../../data/books}"
PREPROC_DIR="${PREPROC_DIR:-../../../../../data/preprocessed}"
OUTPUT_DIR="${OUTPUT_DIR:-./models_v5}"

echo "=== Graph2Tocopo Full Training ==="
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
if [ -f "$PREPROC_DIR/manifest.json" ]; then
    echo "3. Preprocessed data found — skipping preprocess."
else
    echo "3. Preprocessing (this may take a while)..."
    python training/preprocess.py \
        --data-dir "$MLI_DIR" \
        --output-dir "$PREPROC_DIR" \
        --max-workers 16
fi

echo ""
echo "4. Training 20 epochs..."
python training/train.py \
    --data-dir "$PREPROC_DIR" \
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
