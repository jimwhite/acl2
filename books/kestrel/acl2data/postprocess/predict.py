"""
Inference script for ACL2 Proof Fixing Model

Loads the trained models and predicts what action fixes a failed proof,
given a checkpoint (the failing proof state).

Use from Python:
    from predict import Acl2ProofFixer
    fixer = Acl2ProofFixer("./models")
    predictions = fixer.predict(checkpoint_seq, goal_str, checkpoint_type)

CLI usage:
    # Predict from a JSON checkpoint file
    python predict.py ./models --checkpoint-file failed_checkpoint.json

    # Interactive REPL
    python predict.py ./models --interactive
"""

import sys
import json
import argparse
import logging
import pickle
from pathlib import Path
from collections import Counter

import numpy as np

from train_model import (
    ActionTypeModel, PerTypeModel, FrequencyBaseline,
    features_from_item, PER_TYPE_CLASSIFIERS,
)

DEFAULT_TOP_K_ACTION_TYPE = 3
DEFAULT_TOP_K_ACTION_OBJ = 5


class Acl2ProofFixer:
    """Loads trained models and predicts proof fixes."""

    def __init__(self, model_dir):
        model_dir = Path(model_dir)
        self.type_model = ActionTypeModel.load(model_dir / "action_type_model.pkl")
        self.per_type_models = {}
        for p in model_dir.glob("pertype_*.pkl"):
            pt = PerTypeModel.load(p)
            self.per_type_models[pt.action_type] = pt
        # Load frequency baselines
        with open(model_dir / "frequency_baselines.pkl", "rb") as f:
            freq_data = pickle.load(f)
        self.freq_models = {}
        for at, counts_dict in freq_data.items():
            fb = FrequencyBaseline()
            fb.counts = Counter(counts_dict)
            self.freq_models[at] = fb
        # Load training summary
        with open(model_dir / "training_summary.json") as f:
            self.summary = json.load(f)
        self._model_dir = model_dir

    def predict(self, checkpoint_seq, goal_str, checkpoint_type="top",
                top_k_type=DEFAULT_TOP_K_ACTION_TYPE,
                top_k_obj=DEFAULT_TOP_K_ACTION_OBJ):
        """
        Predict the top-N proof fixes for a failed checkpoint.

        Args:
            checkpoint_seq: list of tokens from the checkpoint (as produced
                            by convert_acl2data.py's checkpoint-sequence)
            goal_str: string form of the goal theorem
            checkpoint_type: "top" or "induction"
            top_k_type: number of action-type predictions to return
            top_k_obj: number of action-obj predictions per type

        Returns:
            list of dicts, sorted by confidence:
            [
                {"action_type": "use-lemma",
                 "action_obj": "CDR-CONS",
                 "rank": 1, "source": "model"},
                ...
            ]
        """
        # Build the same feature representation as training
        item = {
            "input": {
                "checkpoint-sequence": checkpoint_seq,
                "checkpoint-type": checkpoint_type,
            },
            "metadata": {"goal-str": goal_str},
        }
        features = features_from_item(item)

        # Stage 1: predict action types
        pred_types = self.type_model.predict_one(features, top_k=top_k_type)

        # Stage 2: for each predicted type, predict action-obj
        results = []
        rank = 1
        for at in pred_types:
            if at in self.per_type_models:
                model = self.per_type_models[at]
                if model._fitted:
                    pred_objs = model.predict_one(features, top_k=top_k_obj)
                    for obj in pred_objs:
                        results.append({
                            "action_type": at,
                            "action_obj": obj,
                            "rank": rank,
                            "source": "model",
                        })
                        rank += 1
                    continue
            # Fall back to frequency baseline
            if at in self.freq_models:
                for obj in self.freq_models[at].predict_top(k=top_k_obj):
                    results.append({
                        "action_type": at,
                        "action_obj": obj,
                        "rank": rank,
                        "source": "frequency",
                    })
                    rank += 1

        return results

    def predict_from_checkpoint(self, checkpoint, top_k_type=3, top_k_obj=5):
        """
        Convenience: predict from a checkpoint dict (as found in .mli files).

        Args:
            checkpoint: dict with "input.checkpoint-sequence" and "metadata.goal-str"
        """
        ck_seq = checkpoint.get("input", {}).get("checkpoint-sequence", [])
        goal_str = checkpoint.get("metadata", {}).get("goal-str", "")
        ck_type = checkpoint.get("input", {}).get("checkpoint-type", "top")
        return self.predict(ck_seq, goal_str, ck_type, top_k_type, top_k_obj)

    def format_for_acl2(self, predictions):
        """
        Format predictions as ACL2 hint syntax.

        Returns a list of hint strings that could be used in ACL2.

        Example output:
            [':use (LEN CDR-CONS)',
             ':in-theory (enable BINARY-APPEND)',
             ...]
        """
        hints = []
        for p in predictions:
            at = p["action_type"]
            obj = p["action_obj"]
            if at == "use-lemma":
                hints.append(f":use {obj}")
            elif at == "add-enable-hint":
                hints.append(f":in-theory (enable {obj})")
            elif at == "add-disable-hint":
                hints.append(f":in-theory (disable {obj})")
            elif at == "add-expand-hint":
                hints.append(f":expand {obj}")
            elif at == "add-induct-hint":
                hints.append(f":induct {obj}")
            elif at == "add-by-hint":
                hints.append(f":by {obj}")
            elif at == "add-use-hint":
                hints.append(f":use {obj}")
            elif at == "add-cases-hint":
                hints.append(f":cases {obj}")
            elif at == "add-do-not-hint":
                hints.append(f":do-not {obj}")
            elif at == "add-nonlinearp-hint":
                hints.append(f":nonlinearp t")
            elif at == "add-hyp":
                hints.append(f";; add hypothesis: {obj}")
            elif at == "add-library":
                hints.append(f";; include-book {obj}")
        return hints

    def print_predictions(self, predictions, acl2_format=False):
        """Pretty-print predictions."""
        for p in predictions:
            source_tag = "" if p["source"] == "model" else " [freq]"
            print(f"  #{p['rank']}: {p['action_type']} {p['action_obj']}{source_tag}")
        if acl2_format:
            print()
            print("ACL2 hints:")
            for h in self.format_for_acl2(predictions):
                print(f"  {h}")


def main():
    parser = argparse.ArgumentParser(
        description="Predict ACL2 proof fixes using trained models.")
    parser.add_argument("model_dir", help="Path to trained models directory")
    parser.add_argument("--checkpoint-file", default=None,
                        help="JSON file with checkpoint to predict for")
    parser.add_argument("--checkpoint-seq", default=None,
                        help="Checkpoint sequence as JSON string, e.g. '[\"(\",\"NOT\",...]'")
    parser.add_argument("--goal-str", default="",
                        help="Goal theorem string")
    parser.add_argument("--interactive", action="store_true",
                        help="Start interactive REPL")
    parser.add_argument("--acl2-format", action="store_true",
                        help="Output hints in ACL2 syntax")
    parser.add_argument("--top-k-type", type=int, default=DEFAULT_TOP_K_ACTION_TYPE)
    parser.add_argument("--top-k-obj", type=int, default=DEFAULT_TOP_K_ACTION_OBJ)
    args = parser.parse_args()

    fixer = Acl2ProofFixer(args.model_dir)

    if args.interactive:
        print("ACL2 Proof Fixer — Interactive Mode")
        print(f"Model: {args.model_dir}")
        print(f"Types: {fixer.summary.get('action_types_trained', [])}")
        print("Enter checkpoint-sequence as JSON array, or 'quit'")
        print("Example: [\"(\", \"NOT\", \"NATP\", \"var-0\", \")\"]")
        print()
        while True:
            try:
                line = input("checkpoint-seq> ").strip()
                if line.lower() in ("quit", "exit", "q"):
                    break
                if not line:
                    continue
                ck_seq = json.loads(line)
                goal_str = input("goal-str (optional)> ").strip()
                ck_type = input("type [top]> ").strip() or "top"
            except (EOFError, KeyboardInterrupt):
                break
            except json.JSONDecodeError as e:
                print(f"Invalid JSON: {e}")
                continue
            preds = fixer.predict(
                ck_seq, goal_str, ck_type,
                top_k_type=args.top_k_type, top_k_obj=args.top_k_obj
            )
            fixer.print_predictions(preds, acl2_format=args.acl2_format)
            print()

    elif args.checkpoint_file:
        with open(args.checkpoint_file) as f:
            checkpoint = json.load(f)
        preds = fixer.predict_from_checkpoint(
            checkpoint,
            top_k_type=args.top_k_type, top_k_obj=args.top_k_obj
        )
        fixer.print_predictions(preds, acl2_format=args.acl2_format)

    elif args.checkpoint_seq:
        ck_seq = json.loads(args.checkpoint_seq)
        preds = fixer.predict(
            ck_seq, args.goal_str, "top",
            top_k_type=args.top_k_type, top_k_obj=args.top_k_obj
        )
        fixer.print_predictions(preds, acl2_format=args.acl2_format)

    else:
        print(f"Acl2ProofFixer loaded from {args.model_dir}")
        print(f"  Action types: {fixer.summary.get('action_types_trained', [])}")
        print(f"  Train samples: {fixer.summary.get('total_train_samples', '?')}")
        print(f"  Eval samples:  {fixer.summary.get('total_eval_samples', '?')}")
        print()
        print("Usage modes:")
        print("  --interactive         Start interactive prediction REPL")
        print("  --checkpoint-file F   Predict from JSON checkpoint file")
        print("  --checkpoint-seq '...' Predict from checkpoint sequence string")
        print("  --acl2-format         Output predictions as ACL2 hints")


if __name__ == "__main__":
    main()
