#!/usr/bin/env bash
# eval-model-host.sh — Run model advice server on host, ACL2 eval in container.
#
# This is the NORMAL way to run eval. The Python server runs on the
# macOS/Linux host, and ACL2 runs inside the Docker dev container,
# connecting via host.docker.internal.
#
# Usage:
#   bash training_v2/scripts/eval-model-host.sh
#
# Env vars:
#   MODEL        — model checkpoint (default: ./models_v7/best_model.pt)
#   VOCAB        — vocab.json path (default: ../../../../../data/preprocessed_v4/vocab.json)
#   RUNES        — runes JSON (default: postprocess/runes-acl2data.json)
#   CONTAINER    — Docker container name (default: auto-detected)
#   PORT         — HTTP port (default: 8765)
#   BATCHES      — concurrent ACL2 processes (default: 8)
#   OUTPUT_DIR   — output dir (default: eval-outputs-parallel)

set -e
cd "$(dirname "$0")/../.."

unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY

# ── Configuration ───────────────────────────────────────────────────────────

MODEL="${MODEL:-./models_v7/best_model.pt}"
VOCAB="${VOCAB:-../../../../../data/preprocessed_v4/vocab.json}"
RUNES="${RUNES:-postprocess/runes-acl2data.json}"
PORT="${PORT:-8765}"
BATCHES="${BATCHES:-8}"
OUTPUT_DIR="${OUTPUT_DIR:-eval-outputs-parallel}"

# Auto-detect container name if not set
if [ -z "$CONTAINER" ]; then
    # Try common dev container names
    for name in acl2-jupyter-dev acl2-jupyter_devcontainer acl2-jupyter; do
        if docker inspect "$name" >/dev/null 2>&1; then
            CONTAINER="$name"
            break
        fi
    done
    if [ -z "$CONTAINER" ]; then
        echo "ERROR: Could not auto-detect container name."
        echo "  Set CONTAINER env var to your Docker container name."
        echo "  Try: docker ps --format '{{.Names}}'"
        exit 1
    fi
fi

# ACL2 reaches server on host via host.docker.internal
SERVER_URL="http://host.docker.internal:$PORT/"
ACL2_CMD="docker exec -i $CONTAINER acl2"

# ── Check prerequisites ─────────────────────────────────────────────────────

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
    echo "ERROR: Container '$CONTAINER' not found or not running."
    echo "  Try: docker ps"
    exit 1
fi

echo "=== Model Advice Server (Host) + ACL2 Eval (Container) ==="
echo "Model:      $MODEL"
echo "Vocab:      $VOCAB"
echo "Runes:      $RUNES"
echo "Port:       $PORT"
echo "Container:  $CONTAINER"
echo "Server URL: $SERVER_URL"
echo "Batches:    $BATCHES"
echo "Output:     $OUTPUT_DIR/"
echo ""

# ── Step 1: Start the model server on host ──────────────────────────────────

# Kill anything already on our port
lsof -ti :$PORT | xargs kill -9 2>/dev/null || true
sleep 1

echo "Starting model advice server on host..."
python -m training_v2.server_v2 \
    --model "$MODEL" \
    --vocab "$VOCAB" \
    --runes "$RUNES" \
    --port "$PORT" \
    > /tmp/model-server-host.log 2>&1 &
SERVER_PID=$!
echo "  PID: $SERVER_PID (log: /tmp/model-server-host.log)"

# Wait for server to be ready
echo "Waiting for server to be ready (timeout 120s)..."
READY=0
for i in $(seq 1 60); do
    RESP=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://127.0.0.1:$PORT/" \
        -d "n=1&broken-theorem=(DEFTHM%20TEST%20X)" 2>/dev/null || echo "000")
    if [ "$RESP" = "200" ]; then
        echo "  Server ready after $((i * 2))s (HTTP $RESP)"
        READY=1
        break
    fi
    if ! kill -0 $SERVER_PID 2>/dev/null; then
        echo "FATAL: Server died. Last log:"
        tail -30 /tmp/model-server-host.log
        exit 1
    fi
    if [ $((i % 15)) -eq 0 ]; then
        echo "  Still waiting... ($((i * 2))s, HTTP $RESP)"
    fi
    sleep 2
done

if [ "$READY" -eq 0 ]; then
    echo "FATAL: Server did not become ready within 120s"
    kill $SERVER_PID 2>/dev/null || true
    tail -30 /tmp/model-server-host.log
    exit 1
fi

# Verify container can reach the server too
echo "Verifying container can reach server..."
if ! docker exec -i "$CONTAINER" curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$SERVER_URL" -d "n=1&broken-theorem=TEST" 2>/dev/null | grep -q 200; then
    echo "WARNING: Container cannot reach $SERVER_URL"
    echo "  Container may not have curl, or host.docker.internal may not resolve."
    echo "  Continuing anyway — ACL2 will use dexador (Lisp HTTP client)."
fi

# ── Step 2: Generate batch Lisp files ───────────────────────────────────────

mkdir -p "$OUTPUT_DIR"

echo ""
echo "Generating batch eval scripts (targeting $SERVER_URL)..."
python -m training_v2.scripts.gen_batch_evals \
    --batches "$BATCHES" \
    --server-url "$SERVER_URL" \
    --output-dir "$OUTPUT_DIR"

# ── Step 3: Run all batches in container (parallel) ─────────────────────────

echo ""
echo "Starting $BATCHES ACL2 processes in container '$CONTAINER'..."

PIDS=()
for batch_file in "$OUTPUT_DIR"/eval-batch-*.lisp; do
    batch_name=$(basename "$batch_file" .lisp)
    batch_log="$OUTPUT_DIR/$batch_name.log"
    echo "  Starting: $batch_name (log: $batch_log)"

    # Pipe the Lisp file into docker exec acl2
    docker exec -i "$CONTAINER" acl2 < "$batch_file" > "$batch_log" 2>&1 &
    PIDS+=($!)
done

echo ""
echo "All ${#PIDS[@]} batches running (PIDs: ${PIDS[*]})"
echo "Waiting for completion (this may take hours)..."
echo "Progress: tail -f $OUTPUT_DIR/eval-batch-01.log"
echo ""

# ── Step 4: Wait for all batches ────────────────────────────────────────────

FAILURES=0
for i in "${!PIDS[@]}"; do
    pid=${PIDS[$i]}
    if wait $pid; then
        echo "  [$((i+1))/${#PIDS[@]}] PID $pid: OK"
    else
        echo "  [$((i+1))/${#PIDS[@]}] PID $pid: FAILED (exit=$?)"
        FAILURES=$((FAILURES + 1))
    fi
done

# ── Step 5: Aggregate results ───────────────────────────────────────────────

echo ""
echo "=== Aggregated Results ==="

TOTAL_SUCCESS=0
TOTAL_ATTEMPTS=0

for log in "$OUTPUT_DIR"/eval-batch-*.log; do
    [ -f "$log" ] || continue
    while IFS= read -r line; do
        if [[ "$line" =~ :GRAPH2TOCOPO\ +([0-9]+)\ +([0-9]+) ]]; then
            successes="${BASH_REMATCH[2]}"
            TOTAL_ATTEMPTS=$((TOTAL_ATTEMPTS + 1))
            if [ "$successes" -gt 0 ]; then
                TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
            fi
        fi
    done < "$log"
done

echo ""
if [ $TOTAL_ATTEMPTS -gt 0 ]; then
    PCT=$(echo "scale=1; $TOTAL_SUCCESS * 100 / $TOTAL_ATTEMPTS" | bc)
    echo "GRAPH2TOCOPO overall: ${TOTAL_SUCCESS}/${TOTAL_ATTEMPTS} = ${PCT}%"
else
    echo "WARNING: No GRAPH2TOCOPO results found"
fi

echo ""
echo "--- Per-batch GRAPH2TOCOPO summaries ---"
for log in "$OUTPUT_DIR"/eval-batch-*.log; do
    [ -f "$log" ] || continue
    batch_name=$(basename "$log" .log)
    final=$(grep -E 'GRAPH2TOCOPO:.*success' "$log" | tail -1 || echo "(no summary)")
    echo "  $batch_name: $final"
done

echo ""
echo "--- OVERALL RESULTS (from last batch log) ---"
LAST_LOG=$(ls -t "$OUTPUT_DIR"/eval-batch-*.log 2>/dev/null | head -1)
if [ -n "$LAST_LOG" ]; then
    grep -A12 "OVERALL RESULTS" "$LAST_LOG" | head -14 || echo "(not found)"
fi

# ── Step 6: Cleanup ─────────────────────────────────────────────────────────

kill $SERVER_PID 2>/dev/null || true
echo ""
echo "=== Done ==="
echo "Outputs: $OUTPUT_DIR/"
echo "Server log: /tmp/model-server-host.log"
