# Books that depend on the pinned wasm-acl2 tree.
#
#   make ACL2=/path/to/saved_acl2
#
# These are listed in ../cert_pl_exclude, so a community certification run skips
# them; they are certified here, by hand, with the pin in place.

ACL2 ?= ../../../../saved_acl2
CERT_PL ?= ../../../build/cert.pl
BOOKS ?= bytes module state decode l1 memory numerics abs size symbolic instructions reads frames context calls returns head chain search links frozen running dispatch load fetch dispatch-tests halt abort oob const const-tail const-branch const-callee const-fetch

all: cert

cert:
	$(CERT_PL) --acl2 $(ACL2) $(BOOKS)

# Regenerate bytes.lisp and module.lisp from the artifact.  Run ../wasm/build.sh
# first; the two must not drift apart, and these are the only things that keep
# them together.  `make module-check` is what a build should run: it fails if the
# checked-in module no longer matches the .wasm.
bytes:
	python3 ../harness/gen_bytes.py

module:
	python3 ../harness/gen_module.py

module-check:
	python3 ../harness/gen_module.py --check

clean:
	rm -f *.cert *.cert.out *.port *.out *.la64fsl *.fasl *.lbin *.o Makefile-tmp workxxx.*

.PHONY: all cert bytes module module-check clean
