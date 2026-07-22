# Graph2Tocopo Development Notes

## Architecture

Three stages:
1. **Preprocessing** (`preprocess.py`): .mli files → padded .pt tensors (graphs, targets, vocab)
2. **Training** (`train.py`): DenseGGNN encoder + TocopoDecoder with copy mechanism
3. **Serving** (`server_v2.py`): HTTP server — builds graphs from ACL2 checkpoint clauses, runs model inference

Plus the **test server** (`test_server.py`): oracle baseline returning ground-truth tocopos from .mli data via theorem-name lookup.

## Test Server (Ground Truth Oracle)

- `build_test_index.py`: Parallel index builder using `imap_unordered` (not `pool.map` — crashes with BrokenPipeError on large datasets). 8 workers, 100s for 5,692 .mli files → 447,146 theorems. Saves as ~239MB JSON.
- `test_server.py`: Loads pre-built index (2s), serves HTTP. Extracts theorem name from `broken-theorem` S-expression, does dictionary lookup, returns matching tocopos with confidence=1.0.
- `eval-test-server.sh`: Builds index once (if needed), starts server, runs ACL2 eval.

**Key difference from model**: Test server uses ONLY theorem name (ignores checkpoint clauses). It's a memorization baseline — cannot generalize to unseen theorems.

## Results Comparison

| Metric | Model (500K steps) | Test Server (ground truth) |
|--------|-------------------|---------------------------|
| GRAPH2TOCOPO success | 11% (2/19) | 89% (17/19) |
| Top-1 token accuracy | 25.5% | N/A (lookup) |
| ActionType accuracy | 82.4% | N/A (lookup) |

## Pipeline Consistency

Graph construction is IDENTICAL between training (`preprocess.py`) and inference (`server_v2.py`):
- Both call `GraphBuilder.build_graph(item)`
- Both use `copy_mask=True` for SUBTOKEN nodes (correct)
- Both encode `node_labels` as vocab IDs with `<unk>` fallback
- Target tokenization/detokenization round-trip is correct

**BUG in v1 preprocess**: `training/preprocess.py` set `copy_mask=True` for TOKEN nodes (all labeled `"token"`), disabling the copy mechanism. v2 preprocess fixed this (SUBTOKEN nodes get copy_mask).

**DEAD CODE**: `data_utils.py` returns `copy_candidates` (TOKEN node indices) but this field is never read — actual `copy_mask` is built from `node_types` independently.

## Why Model Performs Poorly

1. **Model generates mostly NIL objects**: The model's GRAPH2TOCOPO recommendations are predominantly `:ADD-LIBRARY with NIL`, `:USE-LEMMA with NIL` etc. These fail in ACL2 with "Bad book map" or "ill-formed" errors.

2. **Copy mechanism may not be learning well**: The model needs to copy lemma names from graph subtoken nodes into generated tocopos. If the copy mechanism isn't trained effectively, the model defaults to NIL.

3. **Task is inherently hard**: The test server succeeds by memoizing theorem→fix mappings. The model must reason from graph structure alone — a much harder task.

4. **Kyle's reference**: Top-1=38.4% token accuracy vs our 25.5%, suggesting architecture or training data differences.

## Concurrency Learnings

- `multiprocessing.Pool.map()` crashes with `BrokenPipeError` when serializing large result sets through pipes
- Solution: Use `imap_unordered` with chunking — results stream back one file at a time
- Always separate CPU-intensive indexing from HTTP serving
- Pre-build index as JSON, server just loads it (2s startup)
