# Books that depend on the pinned wasm-acl2 tree.
#
#   make ACL2=/path/to/saved_acl2
#
# These are listed in ../cert_pl_exclude, so a community certification run skips
# them; they are certified here, by hand, with the pin in place.

ACL2 ?= ../../../../saved_acl2
CERT_PL ?= ../../../build/cert.pl
BOOKS ?= subst bytes module state decode l1 memory numerics abs size symbolic instructions reads frames context literals engine-flat engine calls returns head chain-flat-own chain chain-label-generic chain-body generic-position search links frozen running dispatch load fetch dispatch-tests halt abort oob const const-tail const-join const-branch const-callee const-steps const-front const-fetch poc

all: cert

cert:
	$(CERT_PL) --acl2 $(ACL2) $(BOOKS)

# The PoC: one Milawa-Lisp expression, from MILAWA-EVAL through the model to
# four exported STEP calls on the artifact.  The summary is a real evaluation
# of the same run the book proves about, not a remembered sentence.
poc:
	$(CERT_PL) --acl2 $(ACL2) poc
	@ACL2="$(abspath $(ACL2))" ../harness/acl2.sh --dir wasm3 --book poc \
	  --script ../harness/poc.lsp --log /tmp/acl2-wasm3-poc.log
	@echo "--- poc summary"
	@grep -A 9 '(:TERM' /tmp/acl2-wasm3-poc.log

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

.PHONY: all cert poc bytes module module-check clean
