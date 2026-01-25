# Build2 - ACL2 Certification System Architecture

## Design Principles

### 1. ACL2 Logic for Application Code
All application logic (parsing, dependency analysis, build ordering) is written
in ACL2's logic mode with:
- Guard verification for runtime correctness
- Defthm theorems for functional correctness
- Properties proven about data structures and algorithms

### 2. Raw Lisp Only for OS Interaction
Raw Common Lisp is used minimally, only for operations that require OS interaction:
- Reading file contents from disk
- Getting file timestamps/modification times  
- Spawning subprocesses (ACL2 for certification)
- Creating/deleting files

### 3. Reuse Existing ACL2 Libraries
We leverage proven, existing ACL2 infrastructure:
- `centaur/depgraph` - Dependency graph algorithms (toposort)
- `std/strings` - String manipulation utilities
- `std/io` - File I/O primitives
- `std/util` - defaggregate, define, etc.
- `oslib` - OS utilities (paths, directories, file types)
- `centaur/misc/tshell` - Subprocess execution

## File Structure

```
build2/
├── package.lsp          # Package definition with imports
├── certinfo.lisp        # Data structures (cert-params, certinfo, etc.)
├── scan.lisp            # Dependency scanner (ACL2 logic)
├── depgraph.lisp        # Dependency graph building (uses centaur/depgraph)
├── certify.lisp         # Certification logic (what needs rebuilding)
├── io-raw.lsp           # Raw Lisp for file/process I/O
├── top.lisp             # Main entry point
└── cert2                # Shell script wrapper
```

## Module Responsibilities

### certinfo.lisp (Pure ACL2)
Data structures for certification information:
- `cert-params` - Certification parameters (acl2x, pcert, ansi-only, etc.)
- `book-dep` - A dependency on another book  
- `certinfo` - Complete info about a book's dependencies
- `depdb` - Database mapping books to their certinfo

All structures use `defaggregate` with proper recognizers.

### scan.lisp (Pure ACL2)
Line-by-line scanner that extracts dependency information from source files.
Recognizes forms like:
- `(include-book ...)`
- `(depends-on ...)`  
- `; cert_param: ...`
- `(add-include-book-dir! ...)`
- `(ifdef ...)` / `(ifndef ...)`

Returns structured event data that is processed by depgraph.lisp.

Theorems prove:
- Scanner only produces valid event structures
- Well-formed input produces well-formed output

### depgraph.lisp (Pure ACL2 + centaur/depgraph)
Builds dependency graph from scanned events:
- Resolves include-book paths to canonical paths
- Handles add-include-book-dir! for custom directories
- Merges cert-params from dependencies
- Uses `depgraph:toposort` for build ordering

Theorems prove:
- No circular dependencies implies valid build order
- Build order respects all dependencies

### certify.lisp (Pure ACL2)
Logic for determining certification status:
- Which books need (re)certification
- Timestamp comparison logic
- Certificate file format

Theorems prove:
- Rebuild rules are sound (never skip a needed rebuild)

### io-raw.lsp (Raw Lisp)
Minimal raw Lisp for OS interaction:
- `read-file-lines` - Read file contents
- `file-write-date` - Get file modification time  
- `run-certification` - Spawn ACL2 subprocess
- `file-exists-p` - Check if file exists

These wrap CL/implementation-specific functions with a clean interface
that the ACL2 logic can call via `progn!`/`set-raw-mode`.

### top.lisp (ACL2 + Raw Integration)
Main entry point that:
1. Calls ACL2 logic to compute what needs building
2. Calls raw Lisp to execute the builds
3. Reports results

## Artifacts

Uses `.cert2` extension (instead of `.cert`) to enable side-by-side testing
with the existing Perl-based system.

Related files:
- `book.cert2` - Certificate file
- `book.cert2.out` - Build output log
- `book.port2` - Portcullis dependencies
- `book.pcert02`, `book.pcert12` - Provisional certificates  
- `book.acl2x2` - Two-pass expansion file

## Testing Strategy

Testing uses ACL2's theorem prover:
1. Define properties as `defthm` 
2. Prove invariants about data structures
3. Prove algorithm correctness

Example theorems:
```lisp
;; All events produced by scanner are well-formed
(defthm scan-produces-valid-events
  (implies (stringp line)
           (scan-event-p (parse-scan-line line))))

;; Build order respects dependencies  
(defthm build-order-respects-deps
  (implies (and (depdb-p db)
                (member-equal book1 (book-deps book2 db)))
           (< (position book1 (compute-build-order db))
              (position book2 (compute-build-order db)))))
```

## Phase 1 Scope

Phase 1 covers common cases:
- Standard `include-book` dependencies
- `depends-on` for file dependencies
- `cert_param` directives
- `add-include-book-dir!` handling
- Basic pcert/acl2x workflows

Not included in Phase 1:
- External tool integration (C compilers, etc.)
- Makefile-based dependencies
- Complex portcullis requirements
