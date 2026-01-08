#!/bin/bash
# Script to extract .cert.out file paths from make-books-err.txt

INPUT_FILE="${1:-make-books-err.txt}"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File '$INPUT_FILE' not found" >&2
    exit 1
fi

# Extract .cert paths from error lines and convert to .cert.out
grep -oP '(?<=: )[^ ]+\.cert(?=\] Error)' "$INPUT_FILE" | sed 's/\.cert$/.cert.out/'
