# ACL2 Build2 System

A native ACL2/Common Lisp replacement for the Perl-based cert.pl build system.

## Design Philosophy

Following ACL2 principles, this system:

1. **Maximizes verified code**: Application logic is written in ACL2's logic
   mode with theorems proving correctness properties.

2. **Minimizes unverified code**: Raw Common Lisp is used only for OS interaction
   (file I/O, timestamps, subprocesses) that cannot be done in pure ACL2.

3. **Reuses existing libraries**: Leverages proven ACL2 infrastructure:
   - `centaur/depgraph` for dependency graph algorithms
   - `std/strings` for string manipulation
   - `std/io` for file I/O primitives
   - `oslib` for OS utilities

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Pure ACL2 (Verified)                    │
├────────────────────────────────────────────────────────────┤
│  types.lisp    - Data structures (cert-params, certinfo)  │
│  scan.lisp     - Dependency scanner with theorems         │
│  depgraph.lisp - Build order via centaur/depgraph         │
│  certify.lisp  - Certification logic with soundness proof │
└────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────┐
│                 Raw Lisp (OS Interaction)                  │
├────────────────────────────────────────────────────────────┤
│  io-raw.lsp    - File timestamps, subprocess execution    │
└────────────────────────────────────────────────────────────┘
```

## Artifacts

To allow side-by-side testing with cert.pl, this system produces:
- `.cert2` files instead of `.cert`
- `.pcert02` / `.pcert12` instead of `.pcert0` / `.pcert1`
- `.acl2x2` instead of `.acl2x`
- `.port2` instead of `.port`

## Key Theorems

The system proves several important properties:

- **Scanner correctness**: `scan-lines-produces-valid-events`
  The scanner only produces well-formed event structures.

- **Build order validity**: `compute-build-order-valid`
  When toposort succeeds, the result is a valid topological ordering.

- **Rebuild soundness**: `book-needs-cert-sound`
  If we say a book doesn't need certification, its cert file exists
  and all dependencies are satisfied.

## Files

| File | Purpose | Mode |
|------|---------|------|
| `package.lsp` | Package definition | ACL2 |
| `types.lisp` | Data structures | ACL2 (verified) |
| `scan.lisp` | Dependency scanner | ACL2 (verified) |
| `depgraph.lisp` | Dependency graph | ACL2 (verified) |
| `certify.lisp` | Certification logic | ACL2 (verified) |
| `io-raw.lsp` | OS interaction | Raw CL |
| `top.lisp` | Main entry | ACL2 |
| `cert2` | Shell wrapper | Bash |

## Usage

```bash
# Certify a single book
./cert2 mybook.lisp

# Certify with parallelism
./cert2 -j 4 book1.lisp book2.lisp

# Show dependencies (dry run)
./cert2 -n mybook.lisp
```

### Generate HTML Documentation

Generate browsable HTML documentation with syntax highlighting and cross-references.
By default, output goes to the `docs/` directory (suitable for GitHub Pages).

```bash
cd $ACL2_SYSTEM_BOOKS

# Generate HTML for ACL2 source files (axioms.lisp, etc.)
build2/cert2 --raw $ACL2_HOME

# Generate HTML for all certified books  
build2/cert2 --html-only .

# Use a custom output directory
build2/cert2 --raw $ACL2_HOME --output-dir /path/to/output
build2/cert2 --html-only . --output-dir /path/to/output
```

The output directory will contain:
- `.html` files with syntax highlighting and hyperlinked symbols
- `.lisp` source files (copied for reference)
- Preserved directory structure matching the source layout

## Status

**Phase 1**: Core certification system
- [x] Data structures with defaggregate
- [x] Dependency scanner with theorems
- [x] Build ordering via centaur/depgraph
- [x] Certification logic with soundness proof
- [x] Raw Lisp I/O layer
- [ ] Integration testing
- [ ] Shell wrapper

**Phase 2**: Advanced features
- [ ] Provisional certification (pcert)
- [ ] Two-pass certification (acl2x)
- [ ] ifdef/ifndef handling
- [ ] Custom images

**Not in scope** (Phase 1):
- External tools (C compilers, etc.)
- Makefile dependencies

- [ ] Certification driver

Phase 2: Advanced features (planned)
- [ ] Provisional certification (pcert)
- [ ] Two-pass certification (acl2x)
- [ ] Cache persistence
