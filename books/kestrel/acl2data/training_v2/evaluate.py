"""
Evaluate trained Graph2Tocopo v2 model — compares to Kyle's thesis metrics.

Metrics (from thesis Section 6.1, Table 6.1):
  Top-1: exact match of generated fix vs ground truth (38.4%)
  ActionType: correct action type prediction (46.12%)

Usage:
  python training_v2/evaluate.py \
      --data-dir /path/to/preprocessed_v2 \
      --model ./models_v6/best_model.pt \
      --max-items 200
"""

import sys, json, argparse, logging
from pathlib import Path

import torch
from tqdm import tqdm

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training_v2.dense_model import DenseGraph2Tocopo
from training_v2.train import FixedDataset, collate_fixed

logger = logging.getLogger(__name__)


def decode_action(pred_tokens, attr_to_id, id_to_token):
    """Decode generated token IDs → (action_type_str, action_obj_str)."""
    id_to_attr = {v: k for k, v in attr_to_id.items()}
    tokens = []
    for tid in pred_tokens:
        if tid <= 0:
            continue
        tok = id_to_token.get(tid, "<unk>")
        if tok in ("<sos>", "<eos>", "<pad>"):
            continue
        tokens.append(tok)

    joined = " ".join(tokens)
    # First token is typically the action type
    action_type = tokens[0] if tokens else ""
    action_obj = joined[len(action_type):].strip() if action_type else joined

    return action_type, action_obj


def evaluate(model, dataset, device, attr_to_id, id_to_token,
             max_items=None, vocab_size=None):
    """Run generation on eval items, compute Top-1 and ActionType accuracy."""
    model.eval()
    correct_top1 = 0
    correct_actype = 0
    total = 0

    iterator = range(min(len(dataset), max_items or len(dataset)))

    for idx in tqdm(iterator, desc="Eval"):
        item = dataset[idx]
        ground_attr_id = item["action_type"]

        # Build single-item batch (B=1)
        node_types = item["node_types"].unsqueeze(0).to(device)
        subtoken_ids = item["subtoken_ids"].unsqueeze(0).to(device)
        edges = item["edges"].unsqueeze(0).to(device)
        tgt = item["tgt_ids"].unsqueeze(0).to(device)
        copy_mask = item["copy_mask"].unsqueeze(0).to(device)

        # Ground truth
        gt_tokens = item["tgt_ids"].tolist()
        gt_clean = [t for t in gt_tokens if t > 1]  # strip <pad> + <sos>

        with torch.no_grad():
            try:
                # Build node mask from num_nodes
                num_n = item.get("num_nodes", torch.tensor(node_types.size(1)))
                positions = torch.arange(node_types.size(1))
                node_mask = (positions >= num_n.item()).unsqueeze(0).to(device)

                # Run encoder with correct mask
                node_emb = model.encoder(
                    node_types, subtoken_ids, edges, node_mask=node_mask)
                # Autoregressive generation through Tocopo decoder
                gen_out = model.decoder.generate(
                    node_emb, copy_mask, temperature=1.0,
                    src_key_padding_mask=node_mask,
                    encoder_node_labels=item.get("node_labels",
                        torch.zeros_like(node_types)).unsqueeze(0).to(device))
                pred_tokens = [tid for tid, _, _ in gen_out]

                pred_at, pred_ao = decode_action(
                    pred_tokens, attr_to_id, id_to_token)
                gt_at, gt_ao = decode_action(
                    gt_clean, attr_to_id, id_to_token)

                if pred_tokens == gt_clean:
                    correct_top1 += 1
                if pred_at == gt_at:
                    correct_actype += 1
                total += 1

            except Exception as e:
                logger.debug(f"  Gen failed at idx {idx}: {e}")
                total += 1

    top1 = correct_top1 / max(total, 1)
    at_acc = correct_actype / max(total, 1)
    logger.info(f"Eval ({total} items): Top-1={top1:.4f} ActionType={at_acc:.4f}")
    return top1, at_acc, total


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--data-dir", required=True,
                   help="Preprocessed directory with manifest.json")
    p.add_argument("--model", required=True,
                   help="Model checkpoint (.pt)")
    p.add_argument("--max-items", type=int, default=200,
                   help="Max eval items")
    p.add_argument("--device", default=None)
    p.add_argument("--log-level", default="INFO")
    args = p.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%H:%M:%S")

    device = torch.device(args.device or (
        "cuda" if torch.cuda.is_available() else
        "mps" if torch.backends.mps.is_available() else "cpu"))
    logger.info(f"Device: {device}")

    preproc_dir = Path(args.data_dir)

    # Load vocab
    with open(preproc_dir / "vocab.json") as f:
        vocab_data = json.load(f)
    token_to_id = vocab_data["token_to_id"]
    attr_to_id = vocab_data["attr_to_id"]
    id_to_token = {v: k for k, v in token_to_id.items()}
    vocab_size = len(token_to_id)
    num_edge_types = vocab_data["num_edge_types"]

    # Load test data
    with open(preproc_dir / "manifest.json") as f:
        manifest = json.load(f)
    test_files = manifest.get("test", manifest.get("val", []))
    logger.info(f"Test files: {len(test_files)}")

    test_ds = FixedDataset(test_files, preproc_dir,
                           num_edge_types=num_edge_types)
    logger.info(f"Test items: {len(test_ds)}")

    # Load model
    logger.info(f"Loading model from {args.model}...")
    ckpt = torch.load(args.model, map_location=device, weights_only=False)
    model = DenseGraph2Tocopo(
        hidden_dim=ckpt.get("args", {}).get("hidden_dim", 128),
        num_edge_types=num_edge_types,
        vocab_size=vocab_size,
    ).to(device)
    model.load_state_dict(ckpt["model_state"])
    model.eval()
    logger.info(f"  Loaded (step {ckpt.get('step', '?')})")

    # Eval
    top1, at_acc, total = evaluate(
        model, test_ds, device, attr_to_id, id_to_token,
        max_items=args.max_items, vocab_size=vocab_size)

    logger.info(f"\nResults ({total} items):")
    logger.info(f"  Top-1 accuracy:    {top1:.4f}  (Kyle: 0.3840)")
    logger.info(f"  ActionType accuracy: {at_acc:.4f}  (Kyle: 0.4612)")


if __name__ == "__main__":
    main()
