# GNUmakefile for the Milawa Sources directory.
#
# This builds and runs the standalone proof checker: the "core" images dumped
# from milawa.lsp, replayed against the proofs that the ACL2 build generated in
# Proofs/.  The ACL2 side -- which generates those proofs and the ACL2 images --
# has its own makefile in ACL2/.
#
#   make                       build base.<ext>, then check every level
#   make base                  just build the core image
#   make check                 replay the proofs (resumable: skips any level
#                              whose image already exists)
#   make check-level L=level9  redo a single level
#   make clean                 remove the core image, level images, and logs
#   make clean-proofs          remove the generated proofs
#
# Settings can be overridden on the command line or in the environment, e.g.
#
#   make LISP=sbcl EXT=my-tag
#
# Only SBCL is wired up as a builder here; see README for the other Lisps.

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

# Host Lisp.  ACL2's own GNUmakefile uses the same variable name ("LISP = ccl"),
# so honour it rather than hard-coding an implementation.  The recipe below
# passes SBCL's memory flags, so SBCL is the supported builder.
LISP ?= sbcl
SBCL ?= $(LISP)

# The tag that names the kernel images.  Nothing in Milawa computes this:
# milawa.lsp simply uses whatever IMAGE-EXTENSION is bound to before the load,
# and Jared's examples were free-form names like "ccl-linux64" / "sbcl-win32".
# Derive it from the environment instead, so it cannot claim the wrong platform.
LISPNAME ?= $(notdir $(SBCL))
PLATFORM ?= $(shell uname -s | tr 'A-Z' 'a-z')-$(shell uname -m)
EXT      ?= $(LISPNAME)-$(PLATFORM)
SBCL_DYNAMIC_SPACE ?= 32000
SBCL_CONTROL_STACK ?= 1024

LEVELS ?= utilities logic level2 level3 level4 level5 level6 level7 level8 \
          level9 level10 level11 user

BASE   := base.$(EXT)
IMAGES := $(addsuffix .$(EXT),$(LEVELS))
LOGS   := $(addsuffix .$(EXT).out,$(LEVELS)) final-checks.log

.PHONY: all base check check-level clean clean-proofs help

all: check

base: $(BASE)

# milawa.lsp ends with (save-and-exit "base"), which names its output
# "base." + IMAGE-EXTENSION, so that variable has to be bound before the load.
$(BASE): milawa.lsp
	$(SBCL) --dynamic-space-size $(SBCL_DYNAMIC_SPACE) \
	        --control-stack-size $(SBCL_CONTROL_STACK) \
	        --noinform --non-interactive \
	        --eval '(defconstant image-extension "$(EXT)")' \
	        --load milawa.lsp
	@test -f $@ || { echo "error: $@ was not produced" >&2; exit 1; }

check: $(BASE)
	./final-checks.sh $(LISPNAME) $(EXT) | tee final-checks.log
	@echo
	@echo "All levels checked.  Images written: $(BASE) $(IMAGES)"

# final-checks.sh skips levels whose image already exists, so redisplaying one
# level means dropping its image first.
check-level: $(BASE)
	@test -n "$(L)" || { echo "usage: make check-level L=<level>" >&2; exit 1; }
	rm -f $(L).$(EXT) $(L).$(EXT).out
	./final-checks.sh $(LISPNAME) $(EXT) | tee final-checks.log

clean:
	rm -f $(BASE) $(IMAGES) $(LOGS)

clean-proofs:
	cd Proofs && ./clean-proofs.sh

help:
	@awk 'NR > 1 { if (/^[^#]/) exit; sub(/^# ?/, ""); print }' GNUmakefile
