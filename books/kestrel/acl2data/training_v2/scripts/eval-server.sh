#!/usr/bin/env bash
# eval-server.sh — Run Graph2Tocopo v2 model evaluation via the advice server.
#
# Usage:
#   bash training_v2/scripts/eval-server.sh
#
# Or custom:
#   MODEL=./models_v7/best_model.pt bash training_v2/scripts/eval-server.sh

set -e
cd "$(dirname "$0")/../.."

unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY

MODEL="${MODEL:-./models_v7/best_model.pt}"
VOCAB="${VOCAB:-../../../../../data/preprocessed_v4/vocab.json}"
PORT=8765
OUTPUT="${OUTPUT:-eval-output.txt}"
SERVER_LOG="${SERVER_LOG:-eval-server.log}"
EVAL_SCRIPT="${EVAL_SCRIPT:-training_v2/eval-graph2tocopo.lisp}"

echo "=== Graph2Tocopo v2 Server Evaluation ===" | tee "$OUTPUT"
echo "Model: $MODEL" | tee -a "$OUTPUT"
echo "Vocab: $VOCAB" | tee -a "$OUTPUT"
echo "Output: $OUTPUT" | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

# Kill any existing server on this port
fuser -k $PORT/tcp 2>/dev/null || true
sleep 1

# Start the server in background
echo "Starting advice server..."
source /workspaces/acl2-jupyter/.venv/bin/activate
python training_v2/server_v2.py \
    --model "$MODEL" \
    --vocab "$VOCAB" \
    --port "$PORT" \
    --log-level WARNING \
    > "$SERVER_LOG" 2>&1 &
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
echo "" | tee -a "$OUTPUT"
echo "Running ACL2 evaluation (script=$EVAL_SCRIPT output→$OUTPUT)..." | tee -a "$OUTPUT"
acl2 --disable-debugger < "$EVAL_SCRIPT" >> "$OUTPUT" 2>&1

echo "" | tee -a "$OUTPUT"
echo "=== Results ===" | tee -a "$OUTPUT"
grep -E "GRAPH2TOCOPO|model.*worked|Done|OVERALL" "$OUTPUT" | tail -20 | tee -a "$OUTPUT"

# Cleanup
kill $SERVER_PID 2>/dev/null || true
echo ""
echo "Done. Output: $OUTPUT  Server log: $SERVER_LOG"
