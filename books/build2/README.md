# ACL2 Build2 System

A native ACL2/Common Lisp replacement for the Perl-based cert.pl build system.

## Overview

This system provides book certification with:
- Automatic dependency scanning
- Parallel builds with proper dependency ordering
- Support for cert_param directives
- Compatible with existing .acl2 customization files

## Artifacts

To allow side-by-side testing with cert.pl, this system produces:
- `.cert2` files instead of `.cert`
- `.pcert02` / `.pcert12` instead of `.pcert0` / `.pcert1`
- `.acl2x2` instead of `.acl2x`
- `.port2` instead of `.port`

## Usage

```bash
# Basic usage - certify a single book
./cert2 mybook.lisp

# Certify multiple books with parallelism
./cert2 -j 4 book1.lisp book2.lisp

# Show dependencies without building
./cert2 -n mybook.lisp
```

## Files

- `cert2` - Main shell entry point
- `cert2.lsp` - ACL2/CL driver script
- `certinfo.lisp` - Data structures for book info
- `scan.lisp` - Dependency scanner
- `depgraph.lisp` - Dependency graph construction and traversal
- `scheduler.lisp` - Parallel build scheduler
- `certify-book2-raw.lsp` - Raw Lisp certification driver

## Status

Phase 1: Basic single-pass certification (in progress)
- [ ] Core data structures
- [ ] Dependency scanning
- [ ] Dependency graph
- [ ] Build scheduler
- [ ] Certification driver

Phase 2: Advanced features (planned)
- [ ] Provisional certification (pcert)
- [ ] Two-pass certification (acl2x)
- [ ] Cache persistence
