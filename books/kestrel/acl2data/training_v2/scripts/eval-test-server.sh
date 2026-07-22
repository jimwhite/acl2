#!/usr/bin/env bash
# eval-test-server.sh — Run evaluation using the test server (ground-truth .mli data).
#
# Builds a pre-built index from .mli files (parallel), then starts the test
# server which loads the index and returns exact ground-truth tocopos.
#
# Usage:
#   bash training_v2/scripts/eval-test-server.sh

set -e
cd "$(dirname "$0")/../.."

unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY

MLI_DIR="${MLI_DIR:-/workspaces/acl2-jupyter/data/books}"
PORT=8765
OUTPUT="${OUTPUT:-eval-output-test-server.txt}"
SERVER_LOG="${SERVER_LOG:-/tmp/test-server.log}"
EVAL_SCRIPT="${EVAL_SCRIPT:-training_v2/eval-val.lisp}"
INDEX_FILE="${INDEX_FILE:-test_index.json}"
WORKERS="${WORKERS:-8}"

echo "=== Test Server Evaluation (Ground Truth: .mli data) ===" | tee "$OUTPUT"
echo "MLI dir: $MLI_DIR" | tee -a "$OUTPUT"
echo "Index: $INDEX_FILE" | tee -a "$OUTPUT"
echo "Output: $OUTPUT" | tee -a "$OUTPUT"
echo "" | tee -a "$OUTPUT"

source /workspaces/acl2-jupyter/.venv/bin/activate

# ── Step 1: Build the index (if not already built) ──────────────────────────

if [ -f "$INDEX_FILE" ]; then
    echo "Index already exists: $INDEX_FILE ($(du -h "$INDEX_FILE" | cut -f1))" | tee -a "$OUTPUT"
else
    echo "Building index from .mli files (parallel, $WORKERS workers)..." | tee -a "$OUTPUT"
    python -m training_v2.build_test_index \
        --mli-dir "$MLI_DIR" \
        --output "$INDEX_FILE" \
        --workers "$WORKERS" 2>&1 | tee -a "$OUTPUT"
    echo "Index built: $INDEX_FILE ($(du -h "$INDEX_FILE" | cut -f1))" | tee -a "$OUTPUT"
fi

# ── Step 2: Start the test server ───────────────────────────────────────────

fuser -k $PORT/tcp 2>/dev/null || true
sleep 1

echo "" | tee -a "$OUTPUT"
echo "Starting test advice server..." | tee -a "$OUTPUT"

python -m training_v2.test_server \
    --index "$INDEX_FILE" \
    --port "$PORT" \
    --log-level INFO \
    > "$SERVER_LOG" 2>&1 &
SERVER_PID=$!
echo "Server PID: $SERVER_PID" | tee -a "$OUTPUT"

echo "Waiting for server to be ready..." | tee -a "$OUTPUT"
for i in $(seq 1 600); do
    if curl -s -X POST "http://127.0.0.1:$PORT/" -d "n=1&broken-theorem=test" > /dev/null 2>&1; then
        echo "Server is ready." | tee -a "$OUTPUT"
        break
    fi
    if ! kill -0 $SERVER_PID 2>/dev/null; then
        echo "ERROR: Server died. Check $SERVER_LOG" | tee -a "$OUTPUT"
        tail -20 "$SERVER_LOG"
        exit 1
    fi
    sleep 2
done

echo "" | tee -a "$OUTPUT"
echo "Running ACL2 evaluation (script=$EVAL_SCRIPT)..." | tee -a "$OUTPUT"

acl2 < "$EVAL_SCRIPT" 2>&1 | tee -a "$OUTPUT"

echo "" | tee -a "$OUTPUT"
echo "=== Results ===" | tee -a "$OUTPUT"
grep "GRAPH2TOCOPO:.*success" "$OUTPUT" | tail -5 | tee -a "$OUTPUT"
grep -A4 "Combined results" "$OUTPUT" | tail -6 | tee -a "$OUTPUT"
echo "=== Done ===" | tee -a "$OUTPUT"

kill $SERVER_PID 2>/dev/null || true
echo "Done. Output: $OUTPUT  Server log: $SERVER_LOG"
