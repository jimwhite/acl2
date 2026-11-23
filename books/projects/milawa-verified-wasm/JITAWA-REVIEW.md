# Jitawa review: the shape to copy

Copyright (C) 2026 Kookamara LLC.  License: (An MIT/X11-style license)

Reviewed 2026-11-23, from the papers and sources in `jitawa-docs/` and
`/home/vscode/HOL/examples/theorem-prover/`.

## 1. The result

Jitawa is two proofs, not one:

1. **`lisp-runtime`**: a verified Lisp read-eval-print loop.  The runtime
   parses s-expressions from ASCII input, evaluates them (compiling functions
   just in time), prints results, and can abort with an error.  The top theorem
   is a machine-code Hoare triple: if the input is one for which the
   specification terminates, the machine either raises an error or reaches a
   final state described by the specification.
2. **`milawa-prover`**: Milawa's logic is formalized and proved sound; the
   kernel's Lisp source is proved faithful to that logic; and the two results
   are composed at the input `MILAWA_CORE_TEXT ++ input`.

The paper's sentence is the composition: when Milawa's kernel is run on the
verified runtime, it can only print theorem statements that are true in the
logic.

## 2. The Lisp runtime layers

| Layer | Jitawa source | What it proves |
|---|---|---|
| Spec | `lisp-runtime/spec/lisp_semanticsScript.sml` | `term`/`func` syntax, `sexp2term`, big-step `R_ev`/`R_evl`/`R_ap`, and `R_exec` for the read-eval-print loop.  `R_ev_T_11`/`R_ap_T_11` give determinism. |
| Compiler + bytecode | `lisp-runtime/bytecode/lisp_compilerScript.sml`, `lisp_alt_semanticsScript.sml` | An untrusted compiler from `term` to `bc_inst_type`; a relational bytecode semantics `BC_ev`; `BC_REFINES`; the theorem `BC_ev_thm`. |
| Machine code | `lisp-runtime/implementation/lisp_bytecode_stepScript.sml`, `lisp_correctnessScript.sml` | Bytecode is bytes of x86 code; `iSTEP` is one machine step and `iSTEP^*` its reflexive-transitive closure.  `zBYTECODE_EVAL_THM` says a bytecode program reaches the state `BC_ev` describes. |
| Runtime top | `lisp-runtime/implementation/lisp_correctnessScript.sml` | `READ_EVAL_PRINT_LOOP_THM` and `jitawa_correctness_thm`: a Hoare triple from `initstate input` to either `zERROR_MESSAGE` or `R_exec`. |
| Parser/printer | `lisp-runtime/parse/lisp_parseScript.sml`, `lisp_sexpScript.sml` | The parser is part of the runtime specification, not a shim: `next_sexp` reads one expression at a time and the printing function is the inverse on the specified forms. |

`BC_ev_thm` is the compiler-correctness theorem.  It is stated relationally:

> if `BC_ev T (exp,a,q,bc)` returns `(code,a2,p,bc2)`, then the machine's
> `iSTEP^*` relation takes the initial bytecode configuration to the
> corresponding configuration.

There is no step count in that statement.  `iSTEP^*` is a closure, and
`BC_REFINES` relates the source and bytecode states.  The compiler is an
untrusted HOL function; the theorem is the guarantee.

`READ_EVAL_PRINT_LOOP_THM` is also relational/partial-correctness:

> if `R_exec (input,fns,output)` returns `(output2,ok2)`, and the initial
> bytecode/runtime invariant holds, then the machine code either reports an
> error or reaches a final state with `ok2` and output `output2`.

`jitawa_correctness_thm` composes the init code with the loop and weakens the
postcondition to
`zERROR_MESSAGE ex \/ (exists result. cond (R_exec (input,FEMPTY,"") (result,T)) * final state)`.

## 3. The Milawa layers

| Layer | Jitawa source | What it proves |
|---|---|---|
| Logic | `milawa-prover/milawa_logicScript.sml`, `milawa_defsScript.sml`, `milawa_ordinalScript.sml` | Milawa syntax, semantics, inference rules, `context_ok`; soundness of the rules, including the ordinal induction rule. |
| Kernel source | `milawa-prover/milawa_coreScript.sml`, `milawa_initScript.sml` | The actual `core.lisp` is parsed into the logic; the initial event state is built. |
| Deep-to-shallow | `milawa-prover/milawa_execScript.sml` | `M_ev ==> MR_ev ==> R_ev`: Milawa-Lisp evaluation is related to the runtime's Lisp evaluation.  `MR_ev_thm` is the certificate theorem. |
| Checker | `milawa-prover/milawa_proofpScript.sml` | `proofp` is faithful to the inference rules: an accepted appeal has a `logic.proofp`-provable conclusion. |
| Invariant | `milawa-prover/milawa_defsScript.sml`, `milawa_proofpScript.sml` | The kernel's state invariant: logical context, theorem list, arity table, current checker, runtime function table. |
| Top | `milawa-prover/soundness-thm/milawa_soundnessScript.sml` | `milawa_soundness_thm`: composes the kernel invariant with `jitawa_correctness_thm` at `input = MILAWA_CORE_TEXT ++ rest`; every printed `THEOREM` line is semantically true. |

The deep-to-shallow step is important.  Jitawa does not prove the 2,000-line
kernel directly as a deep embedding.  It uses the proof-producing translation
of `lisp_extract`/`lisp_synthesis` to get shallow HOL functions, proves the
kernel invariant over those, and keeps the certificate theorem that connects
each shallow function to the deep evaluation relation.  The kernel source text
is parsed by the verified parser, and `milawa_coreScript` turns the ASCII into
the logic constant.

## 4. What Jitawa does *not* prove

- **No exact step counts at the top.**  The top theorem has a `terminates`
  precondition and an error disjunct.  It does not say how many machine steps
  a run takes, nor that the runtime is fast enough.  The papers report
  performance separately.
- **No total correctness.**  If the input does not terminate under the
  specification, the theorem does not promise a result; the implementation may
  also abort with an error for resource limits.
- **No proof that the C wrapper or the OS is correct.**  `fgets`/`fputs` and
  malloc are assumptions, stated as Hoare triples for the external calls.
- **No proof-producing compiler from source to machine code in the style of a
  verified compiler pass.**  The bytecode instructions are bytes of machine
  code, and each byte sequence has a Hoare triple; the compiler is an
  untrusted function whose output is related to the source by `BC_ev_thm`.
- **No proof that Milawa's social soundness argument is mechanically complete**
  beyond the formalized logic and kernel correspondence.  The paper is explicit
  about the remaining assumptions.

## 5. Why our K1 step counts were the wrong target

Our K1 slice tried to prove a theorem of the form

```
machine-run (clock (gen x)) initial = value-state
```

with an exact `clock`.  That is a stronger statement than Jitawa's, and it is
the wrong shape for the plan:

- Jitawa's `iSTEP^*`/`BC_ev` are relations.  The top theorem does not need a
  clock, and the compiler theorem does not produce one.
- An exact clock forces a proof of `machine-run` additivity and of every
  intermediate state; that proof is large, brittle, and irrelevant to the
  correctness sentence.
- Exact clocks are only useful for performance or for a concrete machine
  simulation.  They belong in a separate timing/regression layer, if anywhere.
- The artifact can be generated by a compiler whose correctness is stated
  relationally.  We do not need to prove a closed-form number of steps.

The right K1/L1 statement is relational: if the source evaluation relation
returns, the generated bytecode/WASM run reaches a state satisfying the
refinement relation.  The top statement is a Hoare-style partial-correctness
theorem with a termination premise and an error disjunct.

## 6. What this means for our ACL2/WASM plan

Jitawa replaces HOL4 by ACL2 and x86-64 by WASM/W3T; everything else should be
copied structurally:

1. **Spec first.**  Define the Lisp runtime specification: `term` syntax,
   `R_ev`/`R_ap`/`R_exec`, the parser, the printer, and the I/O streams.  Use
   a relational big-step semantics.  Determinism is a separate theorem.
2. **Compiler and bytecode.**  Define a relational bytecode semantics
   `BC_ev` with a refinement invariant.  Prove one compiler theorem:
   `R_ev` returning implies `BC_ev` reaches a related state.  No clocks.
3. **Machine/WASM.**  Generate W3T code (or a bytecode image) from the
   compiler.  Prove a relational simulation: a `W3T::STEP^*` run from the
   initial configuration reaches the bytecode state described by `BC_ev`.
   The machine-code layer can use Hoare triples (ACL2 state relations) or a
   functional `run` relation; it must not depend on a hand-written module.
4. **Top runtime.**  Compose the parser, evaluator, compiler, machine and
   printer into the `READ_EVAL_PRINT_LOOP_THM` analogue:
   `{init * terminates} code {error \/ R_exec result}`.
5. **Milawa logic and kernel.**  Reuse the sibling ACL2 Milawa checker/
   soundness proof.  Parse the actual `core.lisp`; prove the deep-to-shallow
   correspondence (or a shallow ACL2 embedding with a certificate theorem);
   prove the kernel invariant; compose at `MILAWA_CORE_TEXT ++ input`.
6. **Top sentence.**  The Jitawa sentence with ACL2 in place of HOL4 and WASM
   in place of x86-64.

## 7. Immediate consequences for this tree

- The exact-clock `k1-arith` book is evidence for the generated instruction
  layer (the engine step lemmas and closed runs), but it is **not** the K1/L1
  shape.  Keep it as a small regression, do not extend it as the top proof.
- `top-host.lisp`, `ops-*`, `wasm/milawa-verified.wat`, `wasm/milawa-ops.wat`
  and the per-opcode/`ops` path remain archive.
- The new L-track starts from a relational Lisp spec and a relational bytecode
  compiler theorem.  The new M-track reuses the Milawa formalization rather
  than re-proving the kernel.
