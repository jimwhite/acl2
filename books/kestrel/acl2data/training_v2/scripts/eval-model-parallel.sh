#!/usr/bin/env bash
# eval-model-parallel.sh — Evaluate model advice server on validation set
# using N concurrent ACL2 processes.
#
# Usage:
#   bash training_v2/scripts/eval-model-parallel.sh
#
# Env vars:
#   MODEL       — path to model checkpoint (default: ./models_v7/best_model.pt)
#   VOCAB       — path to vocab.json (default: ../../../../../data/preprocessed_v4/vocab.json)
#   RUNES       — path to runes JSON for book_map resolution
#   PORT        — HTTP port for model server (default: 8765)
#   BATCHES     — number of concurrent ACL2 processes (default: 8)
#   OUTPUT_DIR  — directory for output logs (default: eval-outputs-parallel)

set -e
cd "$(dirname "$0")/../.."

unset http_proxy HTTP_PROXY https_proxy HTTPS_PROXY

# ── Configuration ───────────────────────────────────────────────────────────

MODEL="${MODEL:-./models_v7/best_model.pt}"
VOCAB="${VOCAB:-../../../../../data/preprocessed_v4/vocab.json}"
RUNES="${RUNES:-}"
PORT="${PORT:-8765}"
BATCHES="${BATCHES:-8}"
OUTPUT_DIR="${OUTPUT_DIR:-eval-outputs-parallel}"

source /workspaces/acl2-jupyter/.venv/bin/activate

echo "=== Model Advice Server — Parallel Validation Eval ==="
echo "Model:    $MODEL"
echo "Vocab:    $VOCAB"
echo "Port:     $PORT"
echo "Batches:  $BATCHES"
echo "Output:   $OUTPUT_DIR/"
echo ""

# ── Step 1: Start the model server ──────────────────────────────────────────

fuser -k $PORT/tcp 2>/dev/null || true
sleep 1

RUNES_ARG=""
if [ -n "$RUNES" ]; then
    RUNES_ARG="--runes $RUNES"
fi

echo "Starting model advice server..."
python -m training_v2.server_v2 \
    --model "$MODEL" \
    --vocab "$VOCAB" \
    $RUNES_ARG \
    --port "$PORT" \
    > /tmp/model-server-parallel.log 2>&1 &
SERVER_PID=$!
echo "  PID: $SERVER_PID"

# Wait for server to be ready
echo "Waiting for server to be ready (timeout 120s)..."
READY=0
for i in $(seq 1 60); do
    if curl -s -X POST "http://127.0.0.1:$PORT/" \
        -d "n=1&broken-theorem=(DEFTHM%20TEST%20X)" > /dev/null 2>&1; then
        echo "  Server ready after $((i * 2))s"
        READY=1
        break
    fi
    if ! kill -0 $SERVER_PID 2>/dev/null; then
        echo "FATAL: Server died. Check /tmp/model-server-parallel.log"
        tail -30 /tmp/model-server-parallel.log
        exit 1
    fi
    sleep 2
done

if [ "$READY" -eq 0 ]; then
    echo "FATAL: Server did not become ready within 120s"
    kill $SERVER_PID 2>/dev/null || true
    tail -30 /tmp/model-server-parallel.log
    exit 1
fi

# ── Step 2: Generate batch Lisp files ───────────────────────────────────────

mkdir -p "$OUTPUT_DIR"

echo ""
echo "Generating batch eval scripts..."
python -m training_v2.scripts.gen_batch_evals \
    --batches "$BATCHES" \
    --port "$PORT" \
    --output-dir "$OUTPUT_DIR"

# ── Step 3: Run all batches in parallel ─────────────────────────────────────

echo ""
echo "Starting $BATCHES ACL2 processes..."

PIDS=()
for batch_file in "$OUTPUT_DIR"/eval-batch-*.lisp; do
    batch_name=$(basename "$batch_file" .lisp)
    batch_log="$OUTPUT_DIR/$batch_name.log"
    echo "  Starting: $batch_name (log: $batch_log)"

    acl2 < "$batch_file" > "$batch_log" 2>&1 &
    PIDS+=($!)
done

echo ""
echo "All ${#PIDS[@]} batches running (PIDs: ${PIDS[*]})"
echo "Waiting for completion (this may take hours)..."
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
    # Extract per-result GRAPH2TOCOPO lines
    while IFS= read -r line; do
        # Match: (:GRAPH2TOCOPO N SUCCESSES ...)
        if [[ "$line" =~ :GRAPH2TOCOPO\ +([0-9]+)\ +([0-9]+) ]]; then
            recs="${BASH_REMATCH[1]}"
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
echo "Server log: /tmp/model-server-parallel.log"
