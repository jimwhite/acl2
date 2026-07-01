#!/usr/bin/env python3
"""Migrate model files from old Encoding-as-pickle to new dict-based format."""
import sys, pickle, json
from pathlib import Path
from collections import Counter

# Must import these so pickle can deserialize the old model files
sys.path.insert(0, "/home/acl2/books/kestrel/acl2data/postprocess")

# Explicitly import Encoding so pickle can find it
from train_model import (
    Encoding, _serialize_encoding, _deserialize_encoding,
    ActionTypeModel, PerTypeModel, FrequencyBaseline,
)

model_dir = Path("/workspaces/acl2-jupyter/data/models")

for p in sorted(model_dir.glob("*.pkl")):
    print(f"Migrating {p.name} ...")
    with open(p, "rb") as f:
        data = pickle.load(f)

    # Convert Embedded Encoding objects to dicts
    def convert_encoding(obj):
        if isinstance(obj, Encoding):
            return _serialize_encoding(obj)
        if isinstance(obj, dict):
            return {k: convert_encoding(v) for k, v in obj.items()}
        return obj

    data = convert_encoding(data)
    with open(p, "wb") as f:
        pickle.dump(data, f)
    print("  OK")

print("Migration complete!")
