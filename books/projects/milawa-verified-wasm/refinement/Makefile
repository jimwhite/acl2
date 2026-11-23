# The Jitawa-shaped refinement tree (J0/J1).
#
#   make ACL2=/path/to/saved_acl2
#
# This tree is certified separately from the main wasm3 archive; see
# ../PLAN-JITAWA.md.

ACL2 ?= ../../../../saved_acl2
CERT_PL ?= ../../../build/cert.pl
BOOKS ?= spec compile bridge machine ops-state ops

all: cert

cert:
	$(CERT_PL) --acl2 $(ACL2) $(BOOKS)

clean:
	rm -f *.cert *.cert.out *.port *.out *.la64fsl *.fasl *.lbin *.o Makefile-tmp workxxx.*

.PHONY: all cert clean
