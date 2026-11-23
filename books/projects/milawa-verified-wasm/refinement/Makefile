# The Jitawa-shaped refinement tree (J0/J1).
#
#   make ACL2=/path/to/saved_acl2
#
# This tree is certified separately from the main wasm3 archive; see
# ../PLAN-JITAWA.md.

ACL2 ?= ../../../../saved_acl2
CERT_PL ?= ../../../build/cert.pl
BOOKS ?= spec compile bridge machine ops-state ops ops-w3t ops-add ops-add-label ops-sub-body ops-sub-label ops-lt-body ops-lt-label ops-ifz-body ops-ifz-label ops-dispatch-block ops-jmp ops-label ops-dispatch ops-dispatch-rest ops-dispatch-tail ops-dispatch-gen ops-dispatch-skips ops-dispatch-true ops-return-label ops-return-suffix ops-trace-0 ops-frame-0 ops-frame-6 ops-frame-8 ops-frame-gen ops-trace-gen ops-skip-1 ops-tail-1 ops-trace-1

all: cert

cert:
	$(CERT_PL) --acl2 $(ACL2) $(BOOKS)

clean:
	rm -f *.cert *.cert.out *.port *.out *.la64fsl *.fasl *.lbin *.o Makefile-tmp workxxx.*

.PHONY: all cert clean
