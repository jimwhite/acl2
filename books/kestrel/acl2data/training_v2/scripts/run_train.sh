#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Graph2Tocopo v2: Full Training (PLUR-style)
#
# 1. Preprocess all .mli → global-padded .pt tensors (multicore)
# 2. Train 50K steps on GPU
#
# Skips preprocess if data already exists.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/../.."   # cd to acl2data/

MLI_DIR="${MLI_DIR:-../../../../../data/books}"
PREPROC_DIR="${PREPROC_DIR:-../../../../../data/preprocessed_v2}"
OUTPUT_DIR="${OUTPUT_DIR:-./models_v6}"

echo "=== Graph2Tocopo v2 Full Training ==="
echo "MLI dir:      $MLI_DIR"
echo "Preproc dir:  $PREPROC_DIR"
echo "Output dir:   $OUTPUT_DIR"
echo ""

source training/.venv/bin/activate 2>/dev/null || source training_v2/.venv/bin/activate

echo "1. Installing package..."
uv pip install -q -e training_v2/ 2>/dev/null || pip install -q -e training_v2/

echo ""
if [ -f "$PREPROC_DIR/manifest.json" ]; then
    echo "2. Preprocessed data found — skipping preprocess."
else
    echo "2. Preprocessing (global padding, this may take a while)..."
    python training_v2/preprocess.py \
        --data-dir "$MLI_DIR" \
        --output-dir "$PREPROC_DIR" \
        --max-workers 16
fi

echo ""
echo "3. Training 50K steps..."
python training_v2/train.py \
    --data-dir "$PREPROC_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --steps 50000 \
    --batch-size 8 \
    --hidden-dim 128 \
    --num-workers 8 \
    --valid-steps 5000 \
    --log-steps 1000 \
    --checkpoint-steps 10000

echo ""
echo "=== Training complete ==="
echo "Best model: $OUTPUT_DIR/best_model.pt"
