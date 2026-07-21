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

MLI_DIR="../../../../../data/books"
PREPROC_DIR="../../../../../data/preprocessed_v4"
OUTPUT_DIR="./models_v7"

echo "=== Graph2Tocopo v2 Full Training ==="
echo "MLI dir:      $MLI_DIR"
echo "Preproc dir:  $PREPROC_DIR"
echo "Output dir:   $OUTPUT_DIR"
echo ""

source /workspaces/acl2-jupyter/.venv/bin/activate

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


python training_v2/train.py \
    --data-dir "$PREPROC_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --steps 1000 \
    --batch-size 8 \
    --valid-steps 500

python training_v2/train.py \
    --data-dir "$PREPROC_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --steps 50000 --batch-size 8 \
    --valid-steps 5000 --log-steps 1000 --checkpoint-steps 10000


python training_v2/evaluate.py \
    --data-dir "$PREPROC_DIR" \
    --model "$OUTPUT_DIR/best_model.pt" \
    --max-items 100


echo ""
echo "3. Training 200K steps..."
python training_v2/train.py \
    --data-dir "$PREPROC_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --steps 200000 --batch-size 8 \
    --valid-steps 5000 --log-steps 1000 --checkpoint-steps 10000



python training_v2/evaluate.py \
    --data-dir "$PREPROC_DIR" \
    --model "$OUTPUT_DIR/best_model.pt" \
    --max-items 100



python training_v2/gen-eval-tests.py \
    --preproc-dir "$PREPROC_DIR" \
    --max-books 10

echo ""
echo "=== Training complete ==="
echo "Best model: $OUTPUT_DIR/best_model.pt"
