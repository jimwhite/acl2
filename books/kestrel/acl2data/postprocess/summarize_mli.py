import sys
import os.path
import pathlib
import json
import argparse
import re
import logging
import multiprocessing
import ijson
from concurrent.futures import ProcessPoolExecutor, as_completed
from collections import Counter

DEFAULT_MAX_WORKERS = max(1, multiprocessing.cpu_count())

def make_hashable(obj):
    """Convert action-obj to a hashable string key for counting."""
    if isinstance(obj, str):
        return obj
    if isinstance(obj, list):
        return json.dumps(obj, separators=(',', ':'))
    return str(obj)

def process_one_mli(mli_path):
    """Stream-read a single .mli file (can be many GB) using ijson.
    Returns a dict of action_type -> Counter of action_obj."""
    counts = {}
    try:
        with open(mli_path, 'rb') as f:
            parser = ijson.parse(f)
            in_output = False
            in_action_type = False
            in_action_obj = False
            current_type = None
            current_obj = None
            for prefix, event, value in parser:
                # e.g. prefix='item.output.action-type', event='string', value='use-lemma'
                if event == 'map_key' and prefix.endswith('.output'):
                    if value == 'action-type':
                        in_action_type = True
                        in_action_obj = False
                    elif value == 'action-obj':
                        in_action_type = False
                        in_action_obj = True
                    else:
                        in_action_type = False
                        in_action_obj = False
                elif event == 'end_map' and prefix == 'item.output':
                    in_action_type = False
                    in_action_obj = False
                elif in_action_type and event == 'string':
                    current_type = value
                    in_action_type = False
                elif in_action_obj and isinstance(value, str):
                    current_obj = value
                    in_action_obj = False
                elif in_action_obj and event == 'start_array':
                    # action-obj is a list, e.g. [":SYSTEM",".","\"std/basic/defs.lisp\""]
                    current_obj = _read_list_value(parser, prefix)
                    in_action_obj = False

                if current_type is not None and current_obj is not None:
                    if current_type not in counts:
                        counts[current_type] = Counter()
                    counts[current_type][current_obj] += 1
                    current_type = None
                    current_obj = None
    except Exception as e:
        logging.warning(f"Skipping {mli_path}: {e}")
    return counts

def _read_list_value(parser, prefix):
    """Accumulate tokens from a JSON array into a string representation."""
    parts = []
    depth = 0
    for pfx, evt, val in parser:
        if pfx == prefix and evt == 'end_array':
            break
        if evt == 'start_array':
            depth += 1
            parts.append('[')
        elif evt == 'end_array':
            depth -= 1
            parts.append(']')
        elif evt == 'string':
            parts.append(json.dumps(val, separators=(',', ':')))
        elif evt in ('number', 'boolean', 'null'):
            parts.append(str(val).lower() if evt in ('boolean', 'null') else str(val))
        elif evt == 'map_key':
            parts.append(json.dumps(val, separators=(',', ':')))
    return json.dumps(parts, separators=(',', ':')) if parts else '[]'

def merge_counts(target, source):
    """Merge source counters into target dict of Counters."""
    for action_type, counter in source.items():
        if action_type not in target:
            target[action_type] = Counter()
        target[action_type].update(counter)
    return target

def walk_mli_files(root_dir):
    """Yield all .mli file paths under root_dir (recursive)."""
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for fn in filenames:
            if fn.endswith('.mli'):
                yield os.path.join(dirpath, fn)

def print_data(data):
    for key in sorted(data.keys()):
        count = sum(data[key].values())
        print(key, count)
        objects = sorted(data[key].items(), key=lambda x: -x[1])
        for obj, cnt in objects[:5]:
            print("    ", obj, cnt)

def process_file(fname, data):
    if os.path.isdir(fname):
        logging.info(">>> " + fname)
        for filename in sorted(os.listdir(fname)):
            if filename.startswith('.'):
                continue
            f = os.path.join(fname, filename)
            process_file(f, data)
        return data

    if not str(pathlib.Path(fname)).endswith("mli"):
        return data

    logging.info("> " + fname)
    with open(fname, encoding='latin-1') as f:
        content = json.load(f)
        for item in content:
            action_type = item["output"]["action-type"]
            action_obj = make_hashable(item["output"]["action-obj"])
            if action_type not in data:
                data[action_type] = {}
            if action_obj not in data[action_type]:
                data[action_type][action_obj] = 0
            data[action_type][action_obj] += 1
    return data

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Summarize action types and objects across .mli files.")
    parser.add_argument("inputs", nargs="*", default=["acl2data"],
                        help="Directories containing .mli files to summarize")
    parser.add_argument("-j", "--workers", type=int, default=DEFAULT_MAX_WORKERS,
                        help=f"Number of parallel workers (default: {DEFAULT_MAX_WORKERS}, use 1 for serial)")
    parser.add_argument("--log-level", default="DEBUG", choices=["DEBUG", "INFO", "WARNING", "ERROR"],
                        help="Logging level (default: DEBUG)")
    args = parser.parse_args()

    logging.basicConfig(level=getattr(logging, args.log_level))

    for root_dir in args.inputs:
        logging.info(f"Scanning {root_dir} ...")
        mli_files = list(walk_mli_files(root_dir))
        total = len(mli_files)
        logging.info(f"  {total} .mli files found, max_workers={args.workers}")

        all_counts = {}
        if args.workers == 1:
            completed = 0
            for mli_path in mli_files:
                completed += 1
                counts = process_one_mli(mli_path)
                merge_counts(all_counts, counts)
                logging.info(f"> {mli_path} [{completed}/{total}]")
        else:
            completed = 0
            with ProcessPoolExecutor(max_workers=args.workers) as executor:
                futures = {executor.submit(process_one_mli, p): p for p in mli_files}
                for future in as_completed(futures):
                    completed += 1
                    mli_path = futures[future]
                    try:
                        counts = future.result()
                    except Exception as e:
                        logging.warning(f"> {mli_path} EXECUTOR ERROR: {e}")
                        continue
                    merge_counts(all_counts, counts)
                    if completed % 500 == 0 or completed == total:
                        logging.info(f"> [{completed}/{total}]")

        print(f"\n=== Summary for {root_dir} ===")
        print_data(all_counts)
