; The PoC's display, run by `make poc` after the book certifies.
;
; POC-SUMMARY evaluates the same four calls the book proves about and prints
; what the artifact, the model, and MILAWA-EVAL say.  It is deliberately a
; computation rather than a sentence: if the artifact pin or the model drifts,
; the numbers here change.

(value-triple (poc-summary))
