# One entry point for the whole project.
#
#   make check            everything: certify the books, check the artifact, run
#                         the example corpus, and fail if any book has drifted
#   make books            just the certification (they make their own order)
#   make examples         just the corpus: recorded answers vs the real .wasm
#   make module-check     just "the pinned store still matches the .wasm"
#   make generated-check  the generated books still match their sources
#   make engine           certify the wasm-acl2 engine books (once per pin)
#   make no-skips         the litmus test: no skip-proofs, no defaxiom, anywhere
#   make lint             parentheses and formatting, read the way ACL2 reads them
#   make experiment FILE=... [BOOK=...] [DIR=wasm3]
#                         run a scratch ACL2 script with a timeout and a summary
#   make walk             ask the semantics what each step of the frozen path is
#   make poc              the smallest Milawa-Lisp expressions, end to end:
#                         spec -> compiler -> bytecode machine -> host loop
#   make refinement       the Jitawa-shaped tree (J0 spec + J1 compiler)
#   make milawa-check     the milawa-on-jitawa 100-event demo on the model
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
# The wasm3/ books depend on the pinned wasm-acl2 tree at wasm-acl2/, a git
# submodule of this project (pinned commit 1ce59e0, engine-plan2) covered by
# the project's cert_pl_exclude.  Its 26 generated semantics books, and the
# engine books wasm3/engine.lisp includes, must be certified before wasm3/
# can be; `make books` says so rather than failing obscurely (`make engine`
# certifies the engine books once per pin).

ACL2 ?= ../../../../saved_acl2
PROJECT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BOOKDIRS := milawa-lisp machine wasm3
# The project's own books.  Do not use */*.lisp: wasm-acl2/ is a submodule and
# its root books are not ours to certify in this tree.
PROJECT_BOOKS := $(PROJECT)/milawa-lisp/*.lisp $(PROJECT)/machine/*.lisp $(PROJECT)/wasm3/*.lisp
PROJECT_CERTS := $(PROJECT)/milawa-lisp/*.cert $(PROJECT)/machine/*.cert $(PROJECT)/wasm3/*.cert
WASM_MARKER := wasm-acl2/translate/gen/wasm-3.0/wasm3.cert
ENGINE_MARKER := wasm-acl2/engine/rules/context.cert

.PHONY: all check books engine examples module-check no-skips lint generated-check experiment walk poc refinement complete clean help

all: check

help:
	@sed -n '2,18p' $(PROJECT)/Makefile

check: lint generated-check books module-check examples no-skips complete
	@echo
	@echo "===== summary ====="
	@printf 'books certified:  %s\n' "$$(ls $(PROJECT_CERTS) 2>/dev/null | wc -l)"
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
	  echo "  cd $(PROJECT)/wasm-acl2/translate && make gen SPEC=3.0 ACL2=$(abspath $(ACL2))"; \
	  echo "  cd gen/wasm-3.0 && $(PROJECT)/../../build/cert.pl --acl2 $(abspath $(ACL2)) -j 4 wasm3"; \
	  exit 1; \
	fi
	@if [ ! -f $(PROJECT)/$(ENGINE_MARKER) ]; then \
	  echo "wasm3/ needs the wasm-acl2 engine books (engine-plan2):"; \
	  echo "  make engine"; \
	  exit 1; \
	fi
	@for d in $(BOOKDIRS); do \
	  echo "--- $$d"; \
	  $(MAKE) -s -C $(PROJECT)/$$d ACL2=$(abspath $(ACL2)) || exit 1; \
	done

# The engine books wasm3/engine.lisp includes.  These live in the pinned
# submodule; certify them once per pin.  `make books` checks the marker.
engine:
	cd $(PROJECT)/wasm-acl2/engine && \
	  $(PROJECT)/../../build/cert.pl --acl2 $(abspath $(ACL2)) -j 4 portcullis rules/context

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
	@if sed 's/;.*//' $(PROJECT_BOOKS) | grep -n -i 'skip-proofs\|defaxiom'; then \
	  echo "a book contains skip-proofs or defaxiom"; exit 1; \
	else echo "none in $$(ls $(PROJECT_BOOKS) | wc -l) book(s)"; fi

# Parentheses and formatting.  This counts parentheses the way ACL2's reader
# does -- skipping `;` comments, `#| ... |#` blocks, `"..."` strings and `|...|`
# escaped symbols -- and says so when a file is balanced for ACL2 but not for a
# naive reader, which is what an editor reports when it ignores comment context.
# It exists because an editor claimed `wasm3/chain.lisp` was unbalanced and the
# file was fine: a generated file with thousands of parentheses in literals is
# exactly the case a reader without comment context gets wrong.
lint:
	@echo "--- lint (parentheses the way ACL2 reads them)"
	@python3 $(PROJECT)/harness/lint_lisp.py

# The generated books must still match the sources they are generated from.
# module-check covers module.lisp/state.lisp; these are the rest.  A stale
# generated book certifies fine, which is exactly why this is a build check.
generated-check:
	@echo "--- generated books vs their sources"
	@python3 $(PROJECT)/harness/gen_bytes.py --check
	@python3 $(PROJECT)/harness/gen_chain.py --check
	@python3 $(PROJECT)/harness/examples.py --gen-lisp --check

# Run a scratch ACL2 script against a book directory, with the timeout, working
# directory, log path and summary all handled the same way every time.
#
#   make experiment FILE=/tmp/try.lsp BOOK=chain
#   make experiment FILE=/tmp/try.lsp DIR=machine BOOK=mvm TIMEOUT=1800
#
# Without BOOK the script is expected to do its own include-book.
FILE ?=
experiment:
	@if [ -z "$(FILE)" ]; then echo "usage: make experiment FILE=<script.lsp> [BOOK=<book>] [DIR=<dir>]"; exit 2; fi
	@ACL2=$(abspath $(ACL2)) $(PROJECT)/harness/acl2.sh \
	  --dir $(or $(DIR),wasm3) --book "$(BOOK)" --script "$(FILE)" --timeout $(or $(TIMEOUT),900)

# Ask the semantics what the next few steps are.  `step` is a logic function, so
# on a concrete configuration ACL2 will just compute it: this prints the shape of
# every step from the configuration a call leaves behind, which is the
# specification of each chain lemma rather than a guess.  STEPS=12 to go further,
# VALUE=1 to run a different branch.
STEPS ?= 9
VALUE ?= 3
walk:
	@python3 $(PROJECT)/harness/walk.py --steps $(STEPS) --value $(VALUE)

# The smallest Milawa-Lisp expression, proved end to end: MILAWA-EVAL gives 3,
# MVM-RUN gives the same answer in four steps, and four calls to the artifact's
# exported STEP reach a configuration whose observations are that MVM state.
poc:
	@$(MAKE) -s -C $(PROJECT)/refinement ACL2=$(abspath $(ACL2)) poc

milawa-check:
	@$(MAKE) -s -C $(PROJECT)/refinement ACL2=$(abspath $(ACL2)) milawa-check

# The Jitawa-shaped tree (J0 spec + J1 compiler correctness).  It is certified
# separately from the wasm3 archive; see refinement/README.md and
# PLAN-JITAWA.md.
refinement:
	@$(MAKE) -s -C $(PROJECT)/refinement ACL2=$(abspath $(ACL2))

# Every .lisp in a book directory must have a .cert next to it.  This exists
# because it caught a real bug: wasm3/Makefile's BOOKS line had silently lost the
# three newest books to a bad string replacement, so a fresh checkout certified 23
# of 26 and nothing complained.  The summary below counts certificates, and a count
# cannot tell "all of them" from "the ones we remembered to list".
complete:
	@echo "--- every book has a certificate"
	@missing=0; for f in $(PROJECT_BOOKS); do \
	  if [ ! -f "$${f%.lisp}.cert" ]; then echo "MISSING CERT: $$f"; missing=1; fi; \
	done; \
	if [ $$missing -ne 0 ]; then exit 1; fi; \
	echo "$$(ls $(PROJECT_BOOKS) | wc -l) books, all certified"

clean:
	@for d in $(BOOKDIRS); do $(MAKE) -s -C $(PROJECT)/$$d clean; done
