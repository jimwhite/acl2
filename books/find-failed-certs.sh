#!/bin/bash
# Script to extract .cert.out file paths from make-books.stderr.log

# Extract .cert paths from error lines and convert to full .cert.out paths
grep -oP '(?<=: )[^ ]+\.cert(?=\] Error)' - | sed "s/\.cert$/.cert.out/"
