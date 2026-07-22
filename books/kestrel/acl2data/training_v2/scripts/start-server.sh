#!/usr/bin/env bash
# start-server.sh — Start the model advice server on the host.
#
# Run this on macOS (host), then run eval-model-parallel.sh from the
# VS Code terminal (which is inside the container).
#
# Usage:
#   bash training_v2/scripts/start-server.sh
#
# Env vars:
#   MODEL  — model checkpoint (default: ./models_v7/best_model.pt)
#   VOCAB  — vocab.json (default: ../../../../../data/preprocessed_v4/vocab.json)
#   RUNES  — runes JSON (default: postprocess/runes-acl2data.json)
#   PORT   — HTTP port (default: 8765)

set -e
cd "$(dirname "$0")/../.."

MODEL="${MODEL:-./models_v7/best_model.pt}"
VOCAB="${VOCAB:-../../../../../data/preprocessed_v4/vocab.json}"
RUNES="${RUNES:-postprocess/runes-acl2data.json}"
PORT="${PORT:-8765}"

echo "=== Model Advice Server ==="
echo "Model: $MODEL"
echo "Vocab: $VOCAB"
echo "Runes: $RUNES"
echo "Port:  $PORT"
echo ""

lsof -ti :$PORT | xargs kill -9 2>/dev/null || true
sleep 1

python -m training_v2.server_v2 \
    --model "$MODEL" \
    --vocab "$VOCAB" \
    --runes "$RUNES" \
    --port "$PORT" \
    > /tmp/model-server.log 2>&1 &
PID=$!

echo "Server PID: $PID"
echo "Log: /tmp/model-server.log"
echo ""
echo "Waiting for server to be ready..."

for i in $(seq 1 30); do
    if curl -s -o /dev/null -w "%{http_code}" -X POST "http://127.0.0.1:$PORT/" \
        -d "n=1&broken-theorem=TEST" 2>/dev/null | grep -q 200; then
        echo "Server ready (port $PORT, PID $PID)"
        echo ""
        echo "Now run in VS Code terminal:"
        echo "  cd books/kestrel/acl2data"
        echo "  bash training_v2/scripts/eval-model-parallel.sh"
        exit 0
    fi
    if ! kill -0 $PID 2>/dev/null; then
        echo "FATAL: Server died"
        tail -20 /tmp/model-server.log
        exit 1
    fi
    sleep 2
done

echo "FATAL: Server did not become ready"
exit 1
