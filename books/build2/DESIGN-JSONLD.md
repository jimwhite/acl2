# JSON-LD World Externalization Design

## Overview

This document describes the design for externalizing ACL2 world state as JSON-LD,
enabling Semantic Web queries, inference, and integration with ACL2-Jupyter.

## Goals

1. **Executable Representation**: Capture ACL2 semantics in a form that supports
   execution, not just documentation.

2. **Dual Representation**: Store both:
   - Raw S-expression strings for CL execution
   - Structured RDF for queries and inference on ACL2 forms

3. **Delta-based Output**: Emit per-form annotations that can be attached to
   source text (for HTML RDFa) or notebook cell metadata (for Jupyter).

4. **Custom ACL2 Vocabulary**: Define `@context` with ACL2-specific terms that
   preserve semantic relationships between definitions.

## Design Principles

### 1. TDD (Theorem Driven Development)
Each function implementing JSON-LD externalization must have corresponding
`defthm` or `thm` forms verifying required behavior:
- Well-formedness of output structures
- Preservation of semantic information
- Correct symbol reference tracking

### 2. Separation of Concerns
- `jsonld-vocab.lisp` - Vocabulary definitions and context
- `jsonld-serialize.lisp` - Form-to-JSON-LD conversion
- `jsonld-tests.lisp` - Test theorems and examples

### 3. Integration Points
- `cert2.lsp` (raw CL) - HTML generation with embedded RDFa
- Future: ACL2-Jupyter kernel (separate repo) - Cell metadata

## Custom ACL2 Vocabulary

### Namespace
```
@prefix acl2: <https://www.cs.utexas.edu/users/moore/acl2/vocab#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
```

### Classes (Types)

| Class | Description |
|-------|-------------|
| `acl2:Defun` | Function definition |
| `acl2:Defthm` | Theorem definition |
| `acl2:Defmacro` | Macro definition |
| `acl2:Defconst` | Constant definition |
| `acl2:Defaxiom` | Axiom definition |
| `acl2:Encapsulate` | Encapsulation block |
| `acl2:MutualRecursion` | Mutual recursion block |
| `acl2:IncludeBook` | Book inclusion |
| `acl2:InTheory` | Theory manipulation |
| `acl2:Event` | Generic ACL2 event |

### Properties

#### Common Properties
| Property | Domain | Range | Description |
|----------|--------|-------|-------------|
| `acl2:name` | Event | xsd:string | Defined symbol name |
| `acl2:sourceForm` | Event | xsd:string | Original S-expression as string |
| `acl2:absoluteEventNumber` | Event | xsd:integer | World position |
| `acl2:symbolClass` | Event | xsd:string | :program, :ideal, :common-lisp-compliant |
| `acl2:references` | Event | Event* | Symbols used in definition |
| `acl2:referencedBy` | Event | Event* | Definitions that use this |

#### Function Properties (from renew-name/overwrite)
| Property | Range | Description |
|----------|-------|-------------|
| `acl2:formals` | xsd:string | Formal parameter list (S-expr string) |
| `acl2:body` | xsd:string | Function body (S-expr string) |
| `acl2:guard` | xsd:string | Guard expression |
| `acl2:stobjs-in` | xsd:string | Input stobjs |
| `acl2:stobjs-out` | xsd:string | Output stobjs |
| `acl2:recursivep` | xsd:boolean | Is recursive |
| `acl2:type-prescriptions` | xsd:string | Type prescription rules |
| `acl2:constrainedp` | xsd:boolean | Is constrained (encapsulate) |

#### Theorem Properties
| Property | Range | Description |
|----------|-------|-------------|
| `acl2:term` | xsd:string | Theorem statement (S-expr string) |
| `acl2:hints` | xsd:string | Proof hints |
| `acl2:ruleClasses` | xsd:string | Rule class specification |
| `acl2:instructions` | xsd:string | Proof-builder instructions |

## Data Structures

### JSON-LD Form Object
```lisp
;; ACL2 aggregate for JSON-LD form representation
(defaggregate jsonld-form
  ((id stringp)           ; @id - unique identifier
   (type stringp)         ; @type - acl2:Defun, etc.
   (name stringp)         ; acl2:name
   (source-form stringp)  ; acl2:sourceForm - original S-expr
   (properties alistp)    ; Additional type-specific properties
   (references string-listp)) ; List of referenced symbol names
  :tag :jsonld-form)
```

### Context Object
```json
{
  "@context": {
    "@vocab": "https://www.cs.utexas.edu/users/moore/acl2/vocab#",
    "xsd": "http://www.w3.org/2001/XMLSchema#",
    "name": {"@type": "xsd:string"},
    "sourceForm": {"@type": "xsd:string"},
    "references": {"@type": "@id"},
    "referencedBy": {"@type": "@id"}
  }
}
```

## Implementation Plan

### Phase 1: Core Serialization (jsonld-vocab.lisp)

1. Define vocabulary constants
2. Create `jsonld-form` aggregate
3. Implement `form-to-jsonld` for basic form types:
   - `defun`/`defund` → `acl2:Defun`
   - `defthm`/`defthmd` → `acl2:Defthm`
   - `defmacro` → `acl2:Defmacro`
   - `defconst` → `acl2:Defconst`

**Required Theorems:**
```lisp
(defthm form-to-jsonld-returns-jsonld-form
  (implies (consp form)
           (jsonld-form-p (form-to-jsonld form))))

(defthm form-to-jsonld-preserves-name
  (implies (and (consp form)
                (get-form-name form))
           (equal (jsonld-form->name (form-to-jsonld form))
                  (symbol-name (get-form-name form)))))
```

### Phase 2: Reference Tracking (jsonld-serialize.lisp)

1. Implement `collect-symbol-references` (reuse/adapt from cert2.lsp)
2. Build bidirectional reference graph
3. Generate `references` and `referencedBy` links

**Required Theorems:**
```lisp
(defthm references-are-strings
  (implies (jsonld-form-p jf)
           (string-listp (jsonld-form->references jf))))

(defthm collect-symbols-complete
  (implies (and (symbolp sym)
                (occurs-in-form sym form))
           (member-equal (symbol-name sym)
                         (collect-symbol-references form))))
```

### Phase 3: Output Generation

1. Emit JSON-LD as string (for cert2.lsp to embed in HTML)
2. Generate `.jsonld` sidecar files
3. Add RDFa attributes to HTML output

**Required Theorems:**
```lisp
(defthm jsonld-to-string-produces-valid-json
  (implies (jsonld-form-p jf)
           (valid-json-string-p (jsonld-to-string jf))))
```

### Phase 4: Integration with cert2.lsp

1. Call ACL2 JSON-LD functions from raw CL
2. Embed JSON-LD in HTML as `<script type="application/ld+json">`
3. Add RDFa `vocab`, `typeof`, `property` attributes

## File Structure

```
build2/
├── jsonld-vocab.lisp       # Vocabulary definitions, constants
├── jsonld-serialize.lisp   # Form-to-JSON-LD conversion
├── jsonld-tests.lisp       # Test theorems
├── jsonld.cert.acl2        # Certification config
├── acl2-vocab.jsonld       # External context file
└── cert2.lsp               # (existing) - add JSON-LD emission
```

## Example Output

### Input (defun)
```lisp
(defun append (x y)
  (declare (xargs :guard (true-listp x)))
  (if (endp x)
      y
      (cons (car x) (append (cdr x) y))))
```

### Output (JSON-LD)
```json
{
  "@context": "acl2-vocab.jsonld",
  "@type": "acl2:Defun",
  "@id": "axioms#append",
  "acl2:name": "APPEND",
  "acl2:sourceForm": "(defun append (x y) ...)",
  "acl2:formals": "(X Y)",
  "acl2:guard": "(true-listp x)",
  "acl2:body": "(if (endp x) y (cons (car x) (append (cdr x) y)))",
  "acl2:recursivep": true,
  "acl2:references": ["#endp", "#cons", "#car", "#cdr"]
}
```

### Input (defthm)
```lisp
(defthm append-assoc
  (equal (append (append x y) z)
         (append x (append y z))))
```

### Output (JSON-LD)
```json
{
  "@context": "acl2-vocab.jsonld",
  "@type": "acl2:Defthm",
  "@id": "books/std/lists/append#append-assoc",
  "acl2:name": "APPEND-ASSOC",
  "acl2:sourceForm": "(defthm append-assoc ...)",
  "acl2:term": "(equal (append (append x y) z) (append x (append y z)))",
  "acl2:references": ["axioms#append", "axioms#equal"]
}
```

## Testing Strategy

### Unit Tests (jsonld-tests.lisp)
Each serialization function has corresponding theorems:

```lisp
;; Well-formedness
(defthm defun-to-jsonld-well-formed
  (implies (defun-form-p form)
           (jsonld-form-p (defun-to-jsonld form))))

;; Property preservation
(defthm defun-formals-preserved
  (implies (defun-form-p form)
           (equal (cdr (assoc-equal "acl2:formals" 
                                    (jsonld-form->properties 
                                     (defun-to-jsonld form))))
                  (form-to-string (defun-formals form)))))

;; Reference completeness
(defthm all-body-symbols-in-references
  (implies (and (defun-form-p form)
                (symbolp sym)
                (member-equal sym (collect-symbols (defun-body form))))
           (member-equal (symbol-name sym)
                         (jsonld-form->references 
                          (defun-to-jsonld form)))))
```

### Integration Tests
Test round-trip: ACL2 form → JSON-LD → can be queried with SPARQL patterns.

## Future Work

1. **ACL2-Jupyter Integration**: Emit JSON-LD to cell metadata (separate repo)
2. **SPARQL Endpoint**: Enable queries across certified book corpus  
3. **Inference Rules**: Define OWL axioms for ACL2 semantics
4. **Proof Reconstruction**: Use JSON-LD to replay/verify proofs

## References

- [JSON-LD 1.1 Specification](https://www.w3.org/TR/json-ld11/)
- [RDFa in HTML](https://www.w3.org/TR/rdfa-primer/)
- [ACL2 World Structure](history-management.lisp) - `renew-name/overwrite`
- [Schema.org SoftwareSourceCode](https://schema.org/SoftwareSourceCode)
