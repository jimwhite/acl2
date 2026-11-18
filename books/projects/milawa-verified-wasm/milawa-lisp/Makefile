# Build the Milawa-Lisp books.
#
#   make ACL2=/path/to/saved_acl2
#
# The default ACL2 is the one four levels up (books/../saved_acl2), which is
# where a `make LISP=ccl` build of ACL2 leaves it.
#
# This goes through books/build/cert.pl rather than Makefile-generic because the
# books have to be certified in dependency order: demo.lisp includes eval.lisp,
# top.lisp includes everything, and Makefile-generic's default order is
# alphabetical, which certifies demo before eval and fails.  cert.pl reads the
# include-book forms and gets the order right, which is also how the rest of the
# community books are built.

ACL2 ?= ../../../../saved_acl2
CERT_PL ?= ../../../build/cert.pl
BOOKS ?= values eval programs demo metatheory reachability top

all: cert

cert:
	$(CERT_PL) --acl2 $(ACL2) $(BOOKS)

clean:
	rm -f *.cert *.cert.out *.port *.out *.la64fsl *.fasl *.lbin *.o \
	      Makefile-tmp workxxx.*

.PHONY: all cert clean
