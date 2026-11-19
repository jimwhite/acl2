# Build the MVM books.
#
#   make ACL2=/path/to/saved_acl2
#
# Uses cert.pl for dependency order, as milawa-lisp/Makefile does and for the
# same reason.

ACL2 ?= ../../../../saved_acl2
CERT_PL ?= ../../../build/cert.pl
BOOKS ?= mvm mvm-tests examples top

all: cert

cert:
	$(CERT_PL) --acl2 $(ACL2) $(BOOKS)

clean:
	rm -f *.cert *.cert.out *.port *.out *.la64fsl *.fasl *.lbin *.o \
	      Makefile-tmp workxxx.*

.PHONY: all cert clean
