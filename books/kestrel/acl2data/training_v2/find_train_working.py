"""
Find training-set items where model's Top-1 matches ground truth,
then cross-reference with .mli source to find the original book.
Only training-set books are guaranteed to have hinted theorems.

Usage:
  python training_v2/find_train_working.py \
      --data-dir /workspaces/acl2-jupyter/data/preprocessed_v4 \
      --model ./models_v7/best_model.pt \
      --max-items 2000
"""

import sys, json, argparse, logging
from pathlib import Path
from collections import defaultdict

import torch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training_v2.dense_model import DenseGraph2Tocopo
from training_v2.train import FixedDataset


def detokenize(tokens, id_to_token):
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

    with open(preproc_dir / "vocab.json") as f:
        vocab_data = json.load(f)
    id_to_token = {int(v): k for k, v in vocab_data["token_to_id"].items()}
    num_edge_types = vocab_data["num_edge_types"]

    with open(preproc_dir / "manifest.json") as f:
        manifest = json.load(f)

    ckpt = torch.load(args.model, map_location=device, weights_only=False)
    model = DenseGraph2Tocopo(
        hidden_dim=128,
        num_edge_types=num_edge_types,
        vocab_size=len(vocab_data["token_to_id"]),
    ).to(device)
    model.load_state_dict(ckpt["model_state"])
    model.eval()

    # Use TRAIN set — guaranteed to have hinted theorems
    dataset = FixedDataset(manifest["train"], str(preproc_dir),
                           num_edge_types=num_edge_types)

    n = min(len(dataset), args.max_items)
    print(f"Evaluating {n} training items...")

    correct_by_book = defaultdict(list)
    total = 0

    for idx in range(n):
        item = dataset[idx]
        total += 1

        node_types = item["node_types"].unsqueeze(0).to(device)
        subtoken_ids = item["subtoken_ids"].unsqueeze(0).to(device)
        edges = item["edges"].unsqueeze(0).to(device)
        copy_mask = item["copy_mask"].unsqueeze(0).to(device)

        gt_ids = item["tgt_ids"].tolist()
        gt_clean = [t for t in gt_ids if t > 1]

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
                pred_ids = [tid for tid, _, _, _ in gen_out]
            except Exception:
                continue

        if pred_ids == gt_clean:
            pred_tokens = [id_to_token.get(t, f"<{t}>") for t in pred_ids if t > 0]
            pred_str = detokenize(pred_tokens, id_to_token)

            # Figure out which book this item came from
            for pt_path, n_items, offset in dataset.index:
                if idx < offset + n_items:
                    rel_path = str(pt_path.relative_to(preproc_dir))
                    parts = Path(rel_path).parts
                    stem = Path(rel_path).stem
                    if stem.endswith("__acl2data"):
                        book = str(Path(*parts[1:-1]) / stem[:-len("__acl2data")]) + ".lisp"
                    else:
                        book = rel_path
                    local_idx = idx - offset
                    correct_by_book[book].append((local_idx, pred_str))
                    break

    print(f"\n{len(correct_by_book)} books with {sum(len(v) for v in correct_by_book.values())} correct out of {total}")

    # Show top books
    sorted_books = sorted(correct_by_book.items(), key=lambda x: -len(x[1]))
    print("\nTop books (train set, with correct predictions):")
    for book, items in sorted_books[:15]:
        print(f"  {len(items):4d} correct  {book}")
        for local_idx, pred in items[:2]:
            print(f"           [{local_idx}] {pred}")

    # Generate eval form for top books
    print("\n; === Eval form for top training books ===\n")
    print("(eval-models-on-books")
    print("  '(")
    for book, items in sorted_books[:10]:
        print(f'    ("{book}" . :all)')
    print("    )")
    print('  "/home/acl2/books"')
    print("  10 t nil nil nil")
    print("  (help::make-model-info-alist :all (w state))")
    print(f"  40 :goal-partial 0 {min(10, len(sorted_books))} nil 1 state)")


if __name__ == "__main__":
    main()
