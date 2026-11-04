# ECL merge request: widen bytecode operands to 32 bits

Status: branches pushed to the `jimwhite/ecl` fork. **The upstream MR has not
been created yet** (as requested). Created/updated 2026-11-04.

## Branches on the fork

| Branch | Base | Commit | Purpose |
| --- | --- | --- | --- |
| `widen-bytecode-operands` | upstream `develop` | `cb1e2e84` | Branch to use for the upstream MR |
| `widen-bytecode-operands-26.5.5` | tag `26.5.5` | `51b3f4d5` | Optional branch for the 26.5.5 release line |

Fork remote used locally:

```
jimwhite  git@gitlab.com:jimwhite/ecl.git
```

Both branches were pushed with `git push -u jimwhite <branch>` and verified with
`git ls-remote --heads jimwhite 'widen-bytecode-operands*'`.

## MR link

<https://gitlab.com/jimwhite/ecl/-/merge_requests/new?merge_request%5Bsource_branch%5D=widen-bytecode-operands>

Target project: `embeddable-common-lisp/ecl`
Target branch: `develop`

## Suggested title

```text
Widen bytecode operands to 32 bits
```

## Suggested description

```text
ECL stores both opcodes and their operands in an array of cl_opcode, and
jump offsets are limited to MAX_OPARG (0x7FFF).  Machine-generated
functions can contain if/cond chains whose branch distances exceed that
limit; for example, ACL2's executable counterparts for apply$-prim and
ev-fncall-rec-logical are rejected by the bytecodes compiler with "Too
large jump", so they cannot be bytecompiled.

This changes cl_opcode/cl_oparg to int32_t and MAX_OPARG to 0x3FFFFFFF,
and updates the portable-FASL reader and serializer to use
sizeof(cl_opcode) instead of assuming 16-bit entries.  (The serializer
previously copied only code_size bytes, which was already incorrect for
the 16-bit representation.)

Trade-off: the bytecode array doubles in size.  Measured in a built ACL2
image, 6,772 bytecode functions use ~6.95 MB with 32-bit slots versus
~3.47 MB with 16-bit slots (+3.5 MB).  ECL's default compiler is native
C, so this only affects users of ext:install-bytecodes-compiler.

An alternative that keeps 16-bit slots is to add long-jump opcodes whose
operand indexes a 32-bit delta stored in the data/constants vector.  That
avoids the 2x memory cost but requires new VM/assembler cases.  Happy to
implement that instead if preferred.

Testing: built with ECL 26.5.5 and current develop; bytecompiled and ran
a generated function with a 20,000-branch cond; built and initialized
ACL2 with the bytecodes compiler active, with no "Too large jump" and no
special-case exclusions.
```

## Open design questions for maintainers

1. Uniform 32-bit slots (current patch) versus a dedicated long-jump
   encoding. The latter keeps 16-bit slots and stores only overflowing
   deltas in a side table (`data` vector or a new vector), avoiding the 2x
   memory cost but adding new opcodes and VM cases.
2. Whether a configure-time wide-operand option is preferable. Note that
   prebuilt ECL packages would not enable it, so ACL2 would still need a
   runtime fallback.
3. Interaction with current bytecode work on `develop` (flat closures,
   new opcodes). The patch is orthogonal but touches the same shared
   opcode/operand representation.

## Pipeline notes

`.gitlab-ci.yml` only runs on:

```yaml
- if: $CI_COMMIT_BRANCH == "develop"
- if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

Therefore the feature branches have no pipeline until the MR is opened.
Pipeline `3026121596` belongs to the fork's `develop` branch (`858c2997`) and
had zero jobs; it matched the account-verification failure. After account
verification, run it again from:

- <https://gitlab.com/jimwhite/ecl/-/pipelines/3026121596>
- <https://gitlab.com/jimwhite/ecl/-/pipelines/new?ref=develop>

## Validation performed

- Patched ECL 26.5.5 configured with `--prefix=/opt/ecl-26.5.5`, built with
  `make -j16`, installed with `sudo make install`.
- Develop-based branch built in a detached worktree; in-tree binary
  bytecompiled and ran a generated 20,000-branch `cond` function.
- ACL2 built and initialized with the patched ECL using the bytecodes compiler
  during bootstrapping: no "Too large jump" errors and no hardcoded function
  exclusions.
- ACL2 books certified with `cert.pl -j 8`, including `std/lists/append.cert`.
- Clean full `make -k -j 16 basic` in ACL2's `books/` directory: 1486
  certificates, 0 failures, ~48 minutes on 16 cores. This exercises the
  bytecode-compiled bootstrap extensively (every ACL2 invocation starts by
  bytecompiling the sources).

## Rebase note

The 26.5.5 branch patch touches `src/c/read.d`; on `develop`, the bytecode
reader moved to `src/c/reader/rtab_cl.d`. The `develop` branch has the
equivalent change in the new location.

## Next steps

1. Decide the design question: uniform 32-bit operands (current patch) versus a
   long-jump encoding. The ACL2 side works either way; the ACL2 fallback to the
   native compiler remains useful for stock ECL.
2. When the time comes to open the MR, use the link above, target
   `embeddable-common-lisp/ecl:develop`, and check that the fork's account
   verification is complete so the CI pipeline runs. The pipeline only runs on
   `develop` or MR events.
3. Rebase `widen-bytecode-operands` on current `develop` before opening the MR,
   since bytecode/closure work is active there.
4. Add a NEWS/changelog entry if the ECL tree has one, and mention the memory
   trade-off in the MR description (already drafted above).
5. Optional: benchmark bytecoded code (not just memory) with 16-bit versus
   32-bit slots to confirm there is no unexpected slowdown.
