# POC: `(+ 1 2)` end to end

The smallest piece of Milawa-Lisp running on the verified artifact, with the
certified WASM 3.0 semantics in the loop.

```
MILAWA-EVAL  (+ (quote 1) (quote 2))  =  3          milawa-lisp/demo.lisp
      |
      | POC-COMPILE          an ordinary ACL2 function, not a verified compiler
      v
MVM code     (1 1 1 2 2 0)                            CONST 1; CONST 2; ADD; HALT
      |
      | four calls to the module's exported STEP, as the host drives it
      v
W3T          stops at a configuration whose observations are MVM-RUN
```

Run it:

```
$ make poc
...
--- poc summary
 (:TERM (+ '1 '2)
        :PROGRAM (1 1 1 2 2 0)
        :MVM-STATUS 0
        :MVM-RESULT 3
        :MVM-PC 6
        :MVM-STEPS 4
        :MILAWA-RESULT 3
        :ARTIFACT-STOPPED T
        :OBSERVATIONS T)
```

The summary is not a remembered sentence: `poc-summary` evaluates the same four
calls the book proves about, and `make poc` certifies the book first.

## What is proved

`wasm3/poc.lisp` contains five named theorems and the compiler check:

| Theorem | Statement |
|---|---|
| `poc-compile-correct` | `(poc-program *poc-term*) = '(1 1 1 2 2 0)` — the compiler's output is the expected program |
| `poc-add-model` | `(mvm-run (poc-init term) 100)` is status 0, result 3, pc 6, empty stack, four MVM steps |
| `poc-add` | four exported `STEP` calls, threaded through the store each one returns, stop and the stopped configuration's globals and stack words read back as `(mvm-run ...)` |
| `poc-add-each-call` | after each of the four calls the observations are the corresponding `mvm-step` state, so each call is exactly one MVM step |
| `poc-add-refines-milawa` | `(mvm-result ...) = (milawa-result-value (milawa-eval term nil *milawa-demo-program* 10))` |
| `poc-add-artifact-result` | the artifact's result global (global 4) is that same `MILAWA-EVAL` answer |

The path clocks are the ones `wasm3/abs.lisp` measured: CONST 67, ADD 96,
HALT 53 spec steps.  This program spends `67 + 67 + 96 + 53 = 283` spec steps in
four calls; `POC-CALL` checks the clock from both sides (as `MILAWA-STEP-CHECK`
does): `steps/%fuel` at the spent count is NIL, and at one more it reports the
stopped configuration.  The four calls are:

| Call | Instruction | Spent | Fuel |
|---|---|---:|---:|
| 1 | CONST 1 | 67 | 68 |
| 2 | CONST 2 | 67 | 68 |
| 3 | ADD | 96 | 97 |
| 4 | HALT | 53 | 54 |

The four calls use the clocks and the statement shape that `abs.lisp` fixed
(`abs-const-67`, `abs-add-96`, `abs-halt-53`): each is a concrete one-call check,
re-evaluated at the store the previous call returned rather than rebuilt from the
abstract state.  That is what makes `poc-add` a statement about the artifact as a
host drives it.

## What is not proved

This is a **closed instance**, not L1/L2/L3.

- **L1** is still the symbolic theorem: for every well-formed MVM state, one
  exported call reaches `MVM-STEP` at the opcode-determined clock, with the
  abstraction invariant preserved.  Today only the frozen path has a symbolic
  proof (`wasm3/frozen.lisp`); the CONST path has symbolic pieces
  (`const*.lisp`), and ADD/SUB/LT's callee is not chained.
- **L2** is the run level: an `n`-call host loop equals `W3T::STEPS` at the
  summed clocks, for symbolic `n`/state.  The PoC composes four concrete calls
  because the general composition is L2.
- **L3** is the compiler theorem: `MVM-RUN (compile p) = MILAWA-EVAL(p, ...)`
  for all programs.  `poc-compile` is untrusted, exactly as Jitawa's compiler
  is; `poc-compile-correct` checks its output for this one term only.

The point of the PoC is to fix the shape of the finished theorem and make it
runnable now.  When L1/L2 land, `poc-add` becomes an instance of them, and this
file stays as the regression test: if the artifact pin, `mvm-abs`, the
observations, or `MILAWA-EVAL` drifts, one of the ground theorems stops proving.

## Files

| File | Role |
|---|---|
| `wasm3/poc.lisp` | the compiler, the driver, the five theorems, `poc-summary` |
| `examples/add.mvm` | the same program in the corpus, so the artifact is asked and the model is proved to agree |
| `harness/poc.lsp` | the `value-triple` that `make poc` prints |
| `wasm3/Makefile` | `poc` target and the `BOOKS` entry |
| `Makefile` | top-level `make poc` |

The same program is `examples/add.mvm`:

```
words: 1 1  1 2  2  0
expect: halted result=3 steps=4 pc=6
```

The corpus is a test of the artifact (in Node) plus a proof about the model (in
`machine/examples.lisp`).  This book adds the third claim: the certified
semantics itself reaches the model's answer.  Keeping the claims separate is
the project's rule (see `README.md`).

## Why this shape (Jitawa)

Jitawa's `jitawa_correctness_thm` is not a step-count theorem.  It is a Hoare
triple whose postcondition is either an error or a machine state whose output is
what the spec's `R_exec` says, conditional on the spec terminating; determinism
(`R_ev_T_11`, `R_exec_T_11`) and concrete evaluation supply the value.  Its
per-program examples (`'3`, `(cons 5 '(6 7))`) are instances of one symbolic
compiler-correctness lemma (`BC_ev_thm`), not separate proofs.

`poc-add` follows that shape at the level we have: the artifact theorem is an
existential statement ("some stopped configuration whose observations are the
model's answer"), and evaluation fixes the answer.  The analogue of
`BC_ev_thm` is L1, which is the next milestone; the analogue of the per-program
examples is this file.
