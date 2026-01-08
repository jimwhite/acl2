#!/bin/bash
# Script to extract .cert.out file paths from make-books-err.txt

INPUT_FILE="${1:-make-books-err.txt}"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File '$INPUT_FILE' not found" >&2
    exit 1
fi

# Get the directory of the input file
INPUT_DIR="$(cd "$(dirname "$INPUT_FILE")" && pwd)"

# Extract .cert paths from error lines and convert to full .cert.out paths
grep -oP '(?<=: )[^ ]+\.cert(?=\] Error)' "$INPUT_FILE" | sed "s|^|$INPUT_DIR/|; s/\.cert$/.cert.out/"
