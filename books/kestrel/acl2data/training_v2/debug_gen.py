"""Debug: print generated vs ground truth for first 5 eval items."""

import sys, json
from pathlib import Path
import torch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training_v2.dense_model import DenseGraph2Tocopo
from training_v2.train import FixedDataset
from training_v2.evaluate import decode_action


def main():
    preproc_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(
        "../../../../../data/preprocessed_v2")
    model_path = Path(sys.argv[2]) if len(sys.argv) > 2 else Path(
        "./models_v6/best_model.pt")

    with open(preproc_dir / "vocab.json") as f:
        vocab_data = json.load(f)
    token_to_id = vocab_data["token_to_id"]
    attr_to_id = vocab_data["attr_to_id"]
    id_to_token = {v: k for k, v in token_to_id.items()}
    id_to_attr = {v: k for k, v in attr_to_id.items()}

    with open(preproc_dir / "manifest.json") as f:
        manifest = json.load(f)
    test_files = manifest.get("test", manifest.get("val", []))

    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    ckpt = torch.load(model_path, map_location=device, weights_only=False)
    model = DenseGraph2Tocopo(
        hidden_dim=ckpt.get("args", {}).get("hidden_dim", 128),
        num_edge_types=vocab_data["num_edge_types"],
        vocab_size=len(token_to_id),
    ).to(device)
    model.load_state_dict(ckpt["model_state"])
    model.eval()

    ds = FixedDataset(test_files, preproc_dir,
                      num_edge_types=vocab_data["num_edge_types"])

    for idx in range(5):
        item = ds[idx]

        # Build batch (B=1)
        nt = item["node_types"].unsqueeze(0).to(device)
        st = item["subtoken_ids"].unsqueeze(0).to(device)
        edges = item["edges"].unsqueeze(0).to(device)
        cm = item["copy_mask"].unsqueeze(0).to(device)
        gt_ids = item["tgt_ids"].tolist()

        num_n = item.get("num_nodes", torch.tensor(nt.size(1)))
        positions = torch.arange(nt.size(1))
        node_mask = (positions >= num_n.item()).unsqueeze(0).to(device)

        with torch.no_grad():
            emb = model.encoder(nt, st, edges, node_mask=node_mask)
            gen = model.decoder.generate(emb, cm, temperature=1.0,
                                         src_key_padding_mask=node_mask,
                                         encoder_node_labels=item.get(
                                             "node_labels",
                                             torch.zeros_like(nt)
                                         ).unsqueeze(0).to(device))

        pred_ids = [tid for tid, _, _ in gen]
        pred_tokens = [id_to_token.get(t, f"<{t}>") for t in pred_ids
                       if t not in (0, 1)]  # skip <pad>, <sos>
        gt_tokens = [id_to_token.get(t, f"<{t}>") for t in gt_ids
                     if t not in (0, 1)]
        pred_clean = [t for t in pred_ids if t not in (0, 1)]
        gt_clean = [t for t in gt_ids if t not in (0, 1)]

        pred_at, pred_ao = decode_action(pred_ids, attr_to_id, id_to_token)
        gt_at, gt_ao = decode_action(gt_ids, attr_to_id, id_to_token)

        print(f"\n--- Item {idx} ---")
        print(f"GT action_type: {gt_at}  (id={attr_to_id.get(gt_at, '?')})")
        print(f"GT tokens: {gt_tokens}")
        print(f"Pred tokens: {pred_tokens}")
        print(f"Pred at={pred_at} ao={pred_ao}")
        print(f"Match: {pred_clean == gt_clean}  at_match: {pred_at == gt_at}")


if __name__ == "__main__":
    main()
