#!/bin/sh

set -e

rm -f *.events
# Proof files live in Proofs/<level>/<book>/, so remove and recreate each level
# directory rather than deleting only its files.  Keep the directories
# themselves, since the build writes into them.
for level in utilities logic level2 level3 level4 level5 level6 level7 level8 \
             level9 level10 level11 user
do
    rm -rf "$level"
    mkdir -p "$level"
done
rm -f milawa-proofs.*