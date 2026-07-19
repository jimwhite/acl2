#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Graph2Tocopo: Advice Server
#
# Starts the HTTP server that ACL2's (advice) tool queries for proof fix
# recommendations.
#
# Usage:
#   bash training/scripts/run_server.sh
#
# Override model path or port:
#   MODEL=./models_v5/best_model.pt PORT=9999 bash training/scripts/run_server.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/../.."   # cd to acl2data/

MODEL="${MODEL:-./models_v5/best_model.pt}"
PORT="${PORT:-8765}"

echo "=== Graph2Tocopo Advice Server ==="
echo "Model: $MODEL"
echo "Port:  $PORT"
echo ""

if [ ! -f "$MODEL" ]; then
    echo "ERROR: Model not found at $MODEL"
    echo "Run training first: bash training/scripts/run_train.sh"
    exit 1
fi

source ../../../../../.venv/bin/activate 2>/dev/null || source .venv/bin/activate

python -m training.server \
    --model "$MODEL" \
    --port "$PORT"
