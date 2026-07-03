#!/bin/bash
# eval-knn.sh — Run the k-NN model evaluation.
#
# Prerequisites:
#   1. k-NN server running on port 8765:
#        python knn_server.py --index models_v4 --port 8765
#   2. eval-models book certified:
#        (cd /home/acl2/books && cert.pl kestrel/helpers/eval-models.lisp)
#
# Usage:
#   cd /home/acl2/books/kestrel/acl2data/postprocess
#   bash eval-knn.sh

set -e
cd "$(dirname "$0")"

# Unset proxy variables.  The Docker dev container uses a Squid proxy
# that intercepts HTTP traffic to localhost.  dexador (the HTTP library
# used by post-light) does not respect no_proxy correctly.
unset http_proxy
unset HTTP_PROXY
unset https_proxy
unset HTTPS_PROXY

# Verify the server is running.
if ! curl -s http://127.0.0.1:8765/predict > /dev/null 2>&1; then
    # curl gets a 501 or similar if no data posted, which is fine.
    # A connection refused means the server is not running.
    if curl -s --connect-timeout 2 http://127.0.0.1:8765/ > /dev/null 2>&1; then
        echo "Server is running on port 8765."
    else
        echo "ERROR: k-NN server is not running on port 8765."
        echo "Start it: python knn_server.py --index models_v4 --port 8765"
        exit 1
    fi
fi

echo "Running k-NN evaluation..."
echo

exec acl2 < eval-knn.lisp
