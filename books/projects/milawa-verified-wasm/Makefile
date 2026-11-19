# One entry point for the whole project.
#
#   make check            everything: certify the books, check the artifact, run
#                         the example corpus, and fail if any book has drifted
#   make books            just the certification (they make their own order)
#   make examples         just the corpus: recorded answers vs the real .wasm
#   make module-check     just "the pinned store still matches the .wasm"
#   make no-skips         the litmus test: no skip-proofs, no defaxiom, anywhere
#   make clean
#
# The pieces were built one at a time and each has its own Makefile; this file
# exists so that "does the project build" is one command and has one answer, and
# so that the litmus test is not something a person has to remember to run.
#
# WHAT IT NEEDS
#
#   ACL2=/path/to/saved_acl2     (the default is four levels above books/, where
#                                 `make LISP=ccl` leaves it)
#   node                         for the example corpus, which runs the real
#                                .wasm; the books do not need it
#
# The wasm3/ books depend on the pinned wasm-acl2 tree at ../../.. /.wasm-acl2,
# which is cloned rather than vendored and is excluded from `git status`.  Its 26
# generated books must be certified before wasm3/ can be; `make books` says so
# rather than failing obscurely.

ACL2 ?= ../../../../saved_acl2
PROJECT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BOOKDIRS := milawa-lisp machine wasm3
WASM_MARKER := ../../../.wasm-acl2/translate/gen/wasm-3.0/wasm3.cert

.PHONY: all check books examples module-check no-skips complete clean help

all: check

help:
	@sed -n '2,12p' $(PROJECT)/Makefile

check: books module-check examples no-skips complete
	@echo
	@echo "===== summary ====="
	@printf 'books certified:  %s\n' "$$(ls $(PROJECT)/*/*.cert 2>/dev/null | wc -l)"
	@printf 'corpus examples:  %s\n' "$$(ls $(PROJECT)/examples/*.mvm 2>/dev/null | wc -l)"
	@echo "the module and the model agree on every example; the general statement"
	@echo "that they agree for all inputs is L1, which is what the wasm3/ books"
	@echo "are building.  See SUMMARY.md for exactly what is proved."

# Certification, in the order the books need.  Each directory drives cert.pl
# itself, because cert.pl reads the include-book forms and gets the order right
# while a hand-written list does not.
books:
	@if [ ! -f $(PROJECT)/$(WASM_MARKER) ]; then \
	  echo "wasm3/ needs the WASM 3.0 semantics first:"; \
	  echo "  cd $(PROJECT)/../../../.wasm-acl2/translate && make gen SPEC=3.0 ACL2=$(abspath $(ACL2))"; \
	  echo "  cd gen/wasm-3.0 && $(PROJECT)/../../build/cert.pl --acl2 $(abspath $(ACL2)) -j 4 wasm3"; \
	  exit 1; \
	fi
	@for d in $(BOOKDIRS); do \
	  echo "--- $$d"; \
	  $(MAKE) -s -C $(PROJECT)/$$d ACL2=$(abspath $(ACL2)) || exit 1; \
	done

# The corpus.  Two claims per example, deliberately separate: the artifact gives
# this answer (tested here), and the model gives the same answer (proved in
# machine/examples.lisp).
examples:
	@echo "--- example corpus (artifact)"
	@python3 $(PROJECT)/harness/examples.py --check

# The pinned store must still be the artifact's.  This is what catches a .wasm
# rebuilt without regenerating wasm3/state.lisp, which would otherwise leave the
# proofs about a module that no longer exists.
module-check:
	@echo "--- artifact vs pinned module"
	@$(MAKE) -s -C $(PROJECT)/wasm3 module-check

# No book may contain skip-proofs or defaxiom.  Comments are stripped first, so a
# comment saying "no skip-proofs here" does not count as one.
no-skips:
	@echo "--- litmus: no skip-proofs, no defaxiom"
	@if sed 's/;.*//' $(PROJECT)/*/*.lisp | grep -n -i 'skip-proofs\|defaxiom'; then \
	  echo "a book contains skip-proofs or defaxiom"; exit 1; \
	else echo "none in $$(ls $(PROJECT)/*/*.lisp | wc -l) book(s)"; fi

# Every .lisp in a book directory must have a .cert next to it.  This exists
# because it caught a real bug: wasm3/Makefile's BOOKS line had silently lost the
# three newest books to a bad string replacement, so a fresh checkout certified 23
# of 26 and nothing complained.  The summary below counts certificates, and a count
# cannot tell "all of them" from "the ones we remembered to list".
complete:
	@echo "--- every book has a certificate"
	@missing=0; for f in $(PROJECT)/*/*.lisp; do \
	  if [ ! -f "$${f%.lisp}.cert" ]; then echo "MISSING CERT: $$f"; missing=1; fi; \
	done; \
	if [ $$missing -ne 0 ]; then exit 1; fi; \
	echo "$$(ls $(PROJECT)/*/*.lisp | wc -l) books, all certified"

clean:
	@for d in $(BOOKDIRS); do $(MAKE) -s -C $(PROJECT)/$$d clean; done
