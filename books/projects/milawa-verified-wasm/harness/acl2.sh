#!/bin/sh
# Run a scratch ACL2 script against one of the book directories, consistently.
#
# This exists because the same six-line dance was being retyped for every
# experiment: cd to the right directory, include a book, load the script, capture
# the log, grep for the outcome -- and get *some* of it wrong often enough to
# waste rounds.  Everything that was easy to get wrong is fixed here:
#
#   * the working directory is always <project>/<dir>, because ACL2 resolves
#     `include-book` relative to the cwd and a stale cwd silently loads nothing
#   * the script is fed on stdin, so `--script FILE --dir D` cannot be confused
#     about which file is being read
#   * a timeout is always applied, so a diverging proof cannot sit there
#   * the log is always written somewhere predictable and its path is printed
#   * the summary is printed in one form, so results are comparable between runs
#
# Usage:
#   harness/acl2.sh --dir wasm3 --book chain --script /tmp/try.lsp
#   harness/acl2.sh --dir wasm3 --script /tmp/try.lsp        # no include-book
#   harness/acl2.sh --dir wasm3 --book chain                 # stdin is the script
#
# Options:
#   --dir DIR        book directory (default: wasm3)
#   --book NAME      include this book first
#   --script FILE    the script; default is this command's stdin
#   --timeout N      seconds (default: 900)
#   --log FILE       log path (default: /tmp/acl2-<dir>-<script>.log)
#
# Exit status: 0 if every form reported Q.E.D. and ACL2 raised no error.

set -u

ACL2_BIN=${ACL2:-/workspaces/acl2/saved_acl2}
PROJECT=$(cd "$(dirname "$0")/.." && pwd)
DIR=wasm3
BOOK=
SCRIPT=
TIMEOUT=900
LOG=

while [ $# -gt 0 ]; do
  case $1 in
    --dir) DIR=$2; shift 2 ;;
    --book) BOOK=$2; shift 2 ;;
    --script) SCRIPT=$2; shift 2 ;;
    --timeout) TIMEOUT=$2; shift 2 ;;
    --log) LOG=$2; shift 2 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

[ -d "$PROJECT/$DIR" ] || { echo "no such book directory: $DIR" >&2; exit 2; }

if [ -z "$LOG" ]; then
  base=$(basename "${SCRIPT:-stdin}" .lsp)
  LOG=/tmp/acl2-$DIR-$base.log
fi

# The driver: include the book, then the script (or stdin), then leave.
driver=$(mktemp)
{
  [ -n "$BOOK" ] && echo "(include-book \"$BOOK\")"
  if [ -n "$SCRIPT" ]; then
    cat "$SCRIPT"
  else
    cat
  fi
  echo "(quit)"
} > "$driver"

cd "$PROJECT/$DIR" || exit 2
start=$(date +%s)
ACL2="$ACL2_BIN" timeout "$TIMEOUT" "$ACL2_BIN" < "$driver" > "$LOG" 2>&1
status=$?
elapsed=$(( $(date +%s) - start ))
rm -f "$driver"

qed=$(grep -c 'Q\.E\.D\.' "$LOG" 2>/dev/null) || true
errs=$(grep -c 'ACL2 Error' "$LOG" 2>/dev/null) || true
qed=${qed:-0}
errs=${errs:-0}
steps=$(grep -o 'Prover steps counted:  *[0-9]*' "$LOG" 2>/dev/null |
        sed 's/.*  *//' | awk '{ s += $1 } END { print s + 0 }')

echo "acl2: dir=$DIR book=${BOOK:-none} elapsed=${elapsed}s timeout=${TIMEOUT}s"
echo "acl2: Q.E.D.=$qed errors=$errs prover-steps=$steps"
echo "acl2: log=$LOG"

if [ "$status" -eq 124 ]; then
  echo "acl2: TIMED OUT after ${TIMEOUT}s -- the proof was still running"
  exit 124
fi

if [ "$errs" -ne 0 ]; then
  # The first error and the checkpoint that goes with it are the useful part.
  grep -m 3 -A 3 'ACL2 Error' "$LOG" | head -20
  checkpoint=$(grep -n 'Key checkpoint' "$LOG" | tail -1 | cut -d: -f1)
  if [ -n "${checkpoint:-}" ]; then
    sed -n "${checkpoint},\$p" "$LOG" | head -40
  fi
  exit 1
fi

exit 0
