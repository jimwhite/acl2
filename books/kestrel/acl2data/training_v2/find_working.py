"""
Find test-set items where the model's Top-1 prediction matches ground truth.

Outputs the book path, theorem name, and fix for each correct prediction.
These can be fed into eval-models-on-books to verify the model actually
fixes the proof.

Usage:
  python training_v2/find_working.py \
      --data-dir /workspaces/acl2-jupyter/data/preprocessed_v4 \
      --model ./models_v7/best_model.pt \
      --max-items 2000
"""

import sys, json, argparse, logging
from pathlib import Path

import torch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training_v2.dense_model import DenseGraph2Tocopo
from training_v2.train import FixedDataset, collate_fixed

logger = logging.getLogger(__name__)


def detokenize(tokens, id_to_token):
    """Inverse of build_target_sequence: tokens starting with - are concatenated."""
    if not tokens:
        return ""
    result = tokens[0]
    for t in tokens[1:]:
        if t.startswith("-"):
            result += t
        else:
            result += " " + t
    return result


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--data-dir", required=True)
    p.add_argument("--model", required=True)
    p.add_argument("--max-items", type=int, default=2000)
    p.add_argument("--log-level", default="INFO")
    args = p.parse_args()

    logging.basicConfig(level=getattr(logging, args.log_level))

    device = torch.device("cpu")
    preproc_dir = Path(args.data_dir)

    # Load vocab
    with open(preproc_dir / "vocab.json") as f:
        vocab_data = json.load(f)
    id_to_token = {int(v): k for k, v in vocab_data["token_to_id"].items()}
    num_edge_types = vocab_data["num_edge_types"]

    # Load manifest
    with open(preproc_dir / "manifest.json") as f:
        manifest = json.load(f)

    # Load model
    ckpt = torch.load(args.model, map_location=device, weights_only=False)
    model = DenseGraph2Tocopo(
        hidden_dim=128,
        num_edge_types=num_edge_types,
        vocab_size=len(vocab_data["token_to_id"]),
    ).to(device)
    model.load_state_dict(ckpt["model_state"])
    model.eval()

    # Use test set
    dataset = FixedDataset(manifest["test"], str(preproc_dir),
                           num_edge_types=num_edge_types)

    n = min(len(dataset), args.max_items)
    print(f"Evaluating {n} test items...")

    correct = []
    total = 0

    for idx in range(n):
        item = dataset[idx]
        total += 1

        node_types = item["node_types"].unsqueeze(0).to(device)
        subtoken_ids = item["subtoken_ids"].unsqueeze(0).to(device)
        edges = item["edges"].unsqueeze(0).to(device)
        tgt = item["tgt_ids"].unsqueeze(0).to(device)
        copy_mask = item["copy_mask"].unsqueeze(0).to(device)

        gt_ids = item["tgt_ids"].tolist()
        gt_clean = [t for t in gt_ids if t > 1]  # strip <pad> + <sos>

        with torch.no_grad():
            try:
                num_n = item.get("num_nodes", torch.tensor(node_types.size(1)))
                positions = torch.arange(node_types.size(1))
                node_mask = (positions >= num_n.item()).unsqueeze(0).to(device)

                node_emb = model.encoder(
                    node_types, subtoken_ids, edges, node_mask=node_mask)
                gen_out = model.decoder.generate(
                    node_emb, copy_mask, temperature=1.0,
                    src_key_padding_mask=node_mask,
                    encoder_node_labels=item.get("node_labels",
                        torch.zeros_like(node_types)).unsqueeze(0).to(device))
                pred_tokens_ids = [tid for tid, _, _, _ in gen_out]
            except Exception as e:
                continue

        if pred_tokens_ids == gt_clean:
            # Decode both to readable strings
            pred_tokens = [id_to_token.get(t, f"<{t}>") for t in pred_tokens_ids
                           if t > 0]
            gt_tokens = [id_to_token.get(t, f"<{t}>") for t in gt_clean
                         if t > 0]

            pred_str = detokenize(pred_tokens, id_to_token)
            gt_str = detokenize(gt_tokens, id_to_token)

            # Figure out which book this item came from
            # The FixedDataset uses manifest["test"] paths
            item_idx = idx
            for pt_path, n_items, offset in dataset.index:
                if item_idx < offset + n_items:
                    rel_path = str(pt_path.relative_to(preproc_dir))
                    # Convert: test/rtl/rel4/support/fadd__acl2data.pt -> rtl/rel4/support/fadd.lisp
                    parts = Path(rel_path).parts
                    stem = Path(rel_path).stem
                    if stem.endswith("__acl2data"):
                        book = str(Path(*parts[1:-1]) / stem[:-len("__acl2data")]) + ".lisp"
                    else:
                        book = rel_path
                    local_idx = item_idx - offset
                    correct.append((book, local_idx, pred_str, gt_str))
                    break

            if len(correct) % 10 == 0:
                print(f"  Found {len(correct)} correct so far (of {total})...")

    print(f"\n=== Results: {len(correct)} correct out of {total} ({100*len(correct)/total:.1f}%) ===\n")

    # Group by book
    from collections import defaultdict
    by_book = defaultdict(list)
    for book, local_idx, pred, gt in correct:
        by_book[book].append((local_idx, pred, gt))

    print("; Correct predictions by book:")
    for book in sorted(by_book.keys()):
        items = by_book[book]
        print(f';   {book}: {len(items)} correct')
        for local_idx, pred, gt in items[:3]:
            print(f';     [{local_idx}] pred={pred}')
            print(f';           gt={gt}')

    # Generate eval-models-on-books form
    print("\n; === Eval form ===")
    print("(eval-models-on-books")
    print("  '(")
    for book in sorted(by_book.keys()):
        print(f'    ("{book}" . :all)')
    print("    )")
    print('  "/home/acl2/books"')
    print("  10 t nil nil nil")
    print("  (help::make-model-info-alist :all (w state))")
    print("  40 :goal-partial 0 {} nil 1 state)".format(len(by_book)))


if __name__ == "__main__":
    main()
