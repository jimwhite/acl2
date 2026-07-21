#!/usr/bin/env bash
# eval-server.sh — Run Graph2Tocopo v2 model evaluation via the advice server.
#
# Prerequisites:
#   1. Trained model at $MODEL_DIR/best_model.pt
#   2. Preprocessed data with vocab.json
#   3. eval-models book certified (cd /home/acl2/books && cert.pl kestrel/helpers/eval-models.lisp)
#
# Usage:
#   cd /home/acl2/books/kestrel/acl2data
#   bash training_v2/scripts/eval-server.sh
#
# Or with custom model:
#   MODEL=./models_v7/best_model.pt VOCAB=/path/to/vocab.json bash training_v2/scripts/eval-server.sh

set -e
cd "$(dirname "$0")/../.."

MODEL="${MODEL:-./models_v7/best_model.pt}"
VOCAB="${VOCAB:-../../../../../data/preprocessed_v4/vocab.json}"
PORT=8765

echo "=== Graph2Tocopo v2 Server Evaluation ==="
echo "Model: $MODEL"
echo "Vocab: $VOCAB"
echo "Port:  $PORT"
echo ""

# Kill any existing server on this port
kill $(lsof -t -i:$PORT) 2>/dev/null || true

# Start the server in background
echo "Starting advice server..."
source training/.venv/bin/activate 2>/dev/null || source training_v2/.venv/bin/activate 2>/dev/null || true
python training_v2/server_v2.py \
    --model "$MODEL" \
    --vocab "$VOCAB" \
    --port "$PORT" &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"

# Wait for server to be ready
for i in $(seq 1 30); do
    if curl -s --connect-timeout 1 "http://127.0.0.1:$PORT/" > /dev/null 2>&1; then
        echo "Server is ready."
        break
    fi
    sleep 1
done

# Run ACL2 evaluation
echo ""
echo "Running ACL2 evaluation..."
acl2 < training_v2/eval-graph2tocopo.lisp

# Cleanup
kill $SERVER_PID 2>/dev/null || true
echo "Done."
