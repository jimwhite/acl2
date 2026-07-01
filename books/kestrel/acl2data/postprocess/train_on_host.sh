#!/bin/bash
# train_on_host.sh — Run training on a Mac Studio or other host with Apple Silicon
#
# This script:
#   1. Sets up a Python venv with the required packages
#   2. Runs the full training pipeline on .mli files
#   3. Saves the trained models
#
# Requirements:
#   - macOS or Linux with Python 3.10+
#   - The .mli files must already exist in the data directory
#     (run convert_acl2data.py first — see README)
#
# Recommended: install uv for fast venv creation:
#   brew install uv    # macOS
#   pip install uv     # any platform

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${DATA_DIR:-/path/to/data/books}"       # CHANGE ME
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/models}"
EVAL_FRACTION="${EVAL_FRACTION:-0.05}"

# Apple Silicon optimizations (automatically used by scikit-learn via Accelerate)
# On M3 Ultra (256GB), we can use very large hash space:
#   --n-features 1048576   (2^20 — 1M features, ~4GB per model weight matrix)
#   --n-features 524288    (2^19 — 512K features, ~2GB)
#   --n-features 262144    (2^18 — 256K features, ~1GB, default)
N_FEATURES="${N_FEATURES:-262144}"

if [ ! -d "$DATA_DIR" ]; then
    echo "ERROR: Data directory not found: $DATA_DIR"
    echo "Set DATA_DIR to the path containing .mli files (e.g., /Volumes/.../data/books)"
    exit 1
fi

# Create venv if needed
VENV_DIR="${SCRIPT_DIR}/.training-venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "=== Creating virtual environment ==="
    python3 -m venv "$VENV_DIR"
fi

# Activate
source "$VENV_DIR/bin/activate"

# Install dependencies
echo "=== Installing dependencies ==="
pip install --quiet scikit-learn ijson numpy

echo ""
echo "=== Training Configuration ==="
echo "  Data:         $DATA_DIR"
echo "  Output:       $OUTPUT_DIR"
echo "  Eval fraction: $EVAL_FRACTION"
echo "  N features:   $N_FEATURES"
echo "  Python:       $(python --version)"
echo "  sklearn:      $(python -c 'import sklearn; print(sklearn.__version__)')"
echo ""

# Run training
echo "=== Starting training ==="
python "$SCRIPT_DIR/train_model.py" \
    --output-dir "$OUTPUT_DIR" \
    --eval-fraction "$EVAL_FRACTION" \
    --n-features "$N_FEATURES" \
    --log-level INFO \
    "$DATA_DIR" 2>&1 | tee train.log

echo ""
echo "=== Done! ==="
echo "Models saved to: $OUTPUT_DIR"
echo "Log saved to: train.log"

# Show model sizes
echo ""
echo "=== Model files ==="
find "$OUTPUT_DIR" -name '*.pkl' -exec ls -lh {} \; 2>/dev/null
echo ""
echo "=== Training summary ==="
cat "$OUTPUT_DIR/training_summary.json" 2>/dev/null | python -m json.tool 2>/dev/null || echo "(summary not found)"
