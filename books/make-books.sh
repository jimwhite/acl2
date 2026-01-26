#!/bin/bash

export ACL2_CERTIFY_OPTS="-k -j `nproc`"
export ACL2_CERTIFY_TARGETS="all"

#TODO: Put outputs in subdir with timestamp

make ACL2=${ACL2_HOME}/saved_acl2 ${ACL2_CERTIFY_OPTS} ${ACL2_CERTIFY_TARGETS} \
       >make-books.stdout.log 2> >(tee make-books.stderr.log >&2)

# find * -type f -name "*.cert.out" | tar -czvf make-books-cert-out.tar.gz -T -
./find-failed-certs.sh <make-books.stderr.log | tar -czvf make-books-cert-out.tar.gz -T -
