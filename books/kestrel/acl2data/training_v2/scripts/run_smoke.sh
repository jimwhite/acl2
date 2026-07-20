#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Graph2Tocopo v2: Smoke Test
#
# Preprocesses 10K .mli items with global padding, then trains 10K steps.
# All paths baked in — run from acl2data/.
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/../.."   # cd to acl2data/

MLI_DIR="${MLI_DIR:-../../../../../data/books}"
PREPROC_DIR="${PREPROC_DIR:-../../../../../data/preprocessed_v2_smoke}"
OUTPUT_DIR="${OUTPUT_DIR:-./models_v6_smoke}"

echo "=== Graph2Tocopo v2 Smoke Test ==="
echo "MLI dir:      $MLI_DIR"
echo "Preproc dir:  $PREPROC_DIR"
echo "Output dir:   $OUTPUT_DIR"
echo ""

source training/.venv/bin/activate 2>/dev/null || source training_v2/.venv/bin/activate

echo "1. Installing package..."
uv pip install -q -e training_v2/ 2>/dev/null || pip install -q -e training_v2/

echo ""
echo "2. Preprocessing 10K items (global padding)..."
python training_v2/preprocess.py \
    --data-dir "$MLI_DIR" \
    --output-dir "$PREPROC_DIR" \
    --max-items 10000 \
    --max-workers 4

echo ""
echo "3. Training 10K steps..."
python training_v2/train.py \
    --data-dir "$PREPROC_DIR" \
    --output-dir "$OUTPUT_DIR" \
    --steps 1000 \
    --batch-size 8 \
    --valid-steps 500

    python training_v2/train.py \
    --data-dir /path/to/preprocessed_v3 \
    --output-dir ./models_v7 \
    --steps 1000 --batch-size 8 --valid-steps 500

echo ""
echo "=== Smoke test complete ==="
echo "Best model: $OUTPUT_DIR/best_model.pt"
