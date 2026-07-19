"""
Graph construction utilities for ACL2 proof data.

Converts .mli records into graph representations as described in
Thompson (2023) "Deep Learning Recommendations for the ACL2
Interactive Theorem Prover".

Key design from the thesis (Section 5.3):
- Each ACL2 expression → tree → graph with subtokenization
- Node types: token, subtoken, root
- Edge types: tok2tok, tok2sub, sub2sub + reverse edges
- Subtokenization: split on dashes (e.g., functional-inversion-of-minus
  → [functional, -inversion, -of, -minus])
"""

import json
import logging
from collections import defaultdict

logger = logging.getLogger(__name__)

# ── subtokenisation ──────────────────────────────────────────────────────────

def subtokenize(symbol: str) -> list:
    """Split ACL2 symbol on dashes into subtokens.

    >>> subtokenize("functional-inversion-of-minus")
    ['functional', '-inversion', '-of', '-minus']
    """
    if not symbol:
        return []
    parts = symbol.split("-")
    result = []
    for i, p in enumerate(parts):
        if p == "":
            continue
        if i == 0:
            result.append(p)
        else:
            result.append("-" + p)
    return result


# ── graph construction ───────────────────────────────────────────────────────

class GraphBuilder:
    """Builds graph input for GGNN encoder from .mli records."""

    def __init__(self, max_nodes: int = 512, max_subtoken_vocab: int = 50000):
        self.max_nodes = max_nodes
        self.max_subtoken_vocab = max_subtoken_vocab
        self.subtoken_to_id: dict = {}
        self.next_subtoken_id = 0

    def _get_subtoken_id(self, st: str) -> int:
        if st not in self.subtoken_to_id:
            if self.next_subtoken_id < self.max_subtoken_vocab:
                self.subtoken_to_id[st] = self.next_subtoken_id
                self.next_subtoken_id += 1
        return self.subtoken_to_id.get(st, self.next_subtoken_id)

    def _expr_to_graph(self, expr, parent_node_idx: int,
                       nodes: list, edges: list):
        """Convert a single ACL2 expression (list tree) into graph nodes + edges.

        Args:
            expr: list-tree or string (leaf)
            parent_node_idx: index of parent TOKEN node (-1 if root)
            nodes: accumulated list of (type, label) tuples
            edges: accumulated list of (src, dst, edge_type) tuples

        Returns:
            int: index of the created TOKEN node
        """
        if self.max_nodes and len(nodes) >= self.max_nodes:
            return -1

        # Create TOKEN node
        token_idx = len(nodes)
        nodes.append(("token", "token"))
        if parent_node_idx >= 0:
            edges.append((parent_node_idx, token_idx, "tok2tok"))
            edges.append((token_idx, parent_node_idx, "rev_tok2tok"))

        if isinstance(expr, list):
            # Function application: children are arguments
            if len(expr) > 0:
                for child in expr:
                    self._expr_to_graph(child, token_idx, nodes, edges)
        elif isinstance(expr, str):
            # Leaf: add subtoken chain
            subtokens = subtokenize(expr)
            prev_sub = -1
            for st in subtokens:
                if self.max_nodes and len(nodes) >= self.max_nodes:
                    break
                st_id = self._get_subtoken_id(st)
                sub_idx = len(nodes)
                nodes.append(("subtoken", st))
                # tok2sub edge
                edges.append((token_idx, sub_idx, "tok2sub"))
                edges.append((sub_idx, token_idx, "rev_tok2sub"))
                # sub2sub sequential edge
                if prev_sub >= 0:
                    edges.append((prev_sub, sub_idx, "sub2sub"))
                    edges.append((sub_idx, prev_sub, "rev_sub2sub"))
                prev_sub = sub_idx
        return token_idx

    def build_graph(self, item: dict, max_nodes: int = None) -> dict:
        """Build full input graph from an .mli record.

        Args:
            item: .mli record dict with checkpoint-sequence, goal-str, etc.
            max_nodes: override max_nodes

        Returns:
            dict with keys: node_types, node_labels, edge_index, edge_types,
                            subtoken_ids, node_token_indices
        """
        if max_nodes is None:
            max_nodes = self.max_nodes

        nodes = []  # list of (type_str, label_str)
        edges = []  # list of (src, dst, edge_type_str)

        # Create ROOT node (type="root", label="root")
        root_idx = len(nodes)
        nodes.append(("root", "root"))

        # Get checkpoint expressions
        ck_seq = item.get("input", {}).get("checkpoint-sequence", [])
        # Get the broken theorem (goal-str)
        goal_str = item.get("metadata", {}).get("goal-str", "")

        # Build subgraphs for each checkpoint expression
        for expr in ck_seq:
            tok_idx = self._expr_to_graph(expr, -1, nodes, edges)
            if tok_idx >= 0:
                # root → checkpoint expression edges
                edges.append((root_idx, tok_idx, "root2expr"))
                edges.append((tok_idx, root_idx, "expr2root"))

        # If we have room, also include the broken goal
        if goal_str and len(nodes) < max_nodes * 0.9:
            try:
                goal_parsed = self._parse_s_expr(goal_str)
                if goal_parsed is not None:
                    tok_idx = self._expr_to_graph(
                        goal_parsed, -1, nodes, edges)
                    if tok_idx >= 0:
                        edges.append((root_idx, tok_idx, "root2expr"))
                        edges.append((tok_idx, root_idx, "expr2root"))
            except Exception:
                pass  # best-effort

        # Truncate to max_nodes
        if len(nodes) > max_nodes:
            nodes = nodes[:max_nodes]
            edges = [e for e in edges
                     if e[0] < max_nodes and e[1] < max_nodes]

        # Build output format
        edge_type_map = {}
        next_etyp = 0
        edge_index = [[], []]
        edge_types = []

        for src, dst, etyp in edges:
            if src >= len(nodes) or dst >= len(nodes):
                continue
            if etyp not in edge_type_map:
                edge_type_map[etyp] = next_etyp
                next_etyp += 1
            edge_index[0].append(src)
            edge_index[1].append(dst)
            edge_types.append(edge_type_map[etyp])

        # node_token_indices: primary TOKEN nodes (for copy mechanism)
        node_token_indices = [i for i, (nt, _) in enumerate(nodes)
                              if nt == "token"]

        # subtoken_ids: for subtoken nodes
        subtoken_ids = []
        for nt, label in nodes:
            if nt == "subtoken":
                subtoken_ids.append(self._get_subtoken_id(label))
            else:
                subtoken_ids.append(-1)

        # copy_candidates: indices of TOKEN nodes whose labels can be copied
        copy_candidates = node_token_indices

        return {
            "node_types": [nt for nt, _ in nodes],
            "node_labels": [lb for _, lb in nodes],
            "edge_index": edge_index,
            "edge_types": edge_types,
            "num_edge_types": next_etyp,
            "subtoken_ids": subtoken_ids,
            "copy_candidates": copy_candidates,
            "num_nodes": len(nodes),
        }

    @staticmethod
    def _parse_s_expr(s: str):
        """Quick S-expression parser for broken goal strings."""
        import re
        s = s.strip()
        if not s or s.startswith("(") and s.endswith(")"):
            # Try to parse nested
            try:
                return GraphBuilder._parse_sexpr_rec(s)
            except Exception:
                return s
        return s

    @staticmethod
    def _parse_sexpr_rec(s: str):
        """Recursive S-expression reader."""
        s = s.strip()
        if not s.startswith("("):
            # symbol
            if s == "":
                return "NIL"
            return s.split()[0] if " " in s else s
        # consume '('
        i = 1
        result = []
        while i < len(s):
            if s[i] == ")":
                return result
            if s[i] == "(":
                # find matching ')'
                depth = 1
                j = i + 1
                while j < len(s) and depth > 0:
                    if s[j] == "(":
                        depth += 1
                    elif s[j] == ")":
                        depth -= 1
                    j += 1
                sub = GraphBuilder._parse_sexpr_rec(s[i:j])
                result.append(sub)
                i = j
            elif s[i] in " \n\t":
                i += 1
            else:
                # read symbol
                j = i
                while j < len(s) and s[j] not in "() \n\t":
                    j += 1
                result.append(s[i:j])
                i = j
        return result


# ── vocabulary ───────────────────────────────────────────────────────────────

class FixVocab:
    """Vocabulary for target fix sequences (action_class + action_object)."""

    def __init__(self):
        self.token_to_id = {
            "<pad>": 0,
            "<sos>": 1,   # start of sequence
            "<eos>": 2,   # end of sequence
            "<unk>": 3,
        }
        self.id_to_token = {v: k for k, v in self.token_to_id.items()}
        self.next_id = 4

    def add_token(self, token: str) -> int:
        if token not in self.token_to_id:
            self.token_to_id[token] = self.next_id
            self.id_to_token[self.next_id] = token
            self.next_id += 1
        return self.token_to_id[token]

    def encode(self, tokens: list) -> list:
        return [self.token_to_id.get(t, self.token_to_id["<unk>"])
                for t in tokens]

    def decode(self, ids: list) -> list:
        return [self.id_to_token.get(i, "<unk>") for i in ids]

    def __len__(self):
        return len(self.token_to_id)

    @property
    def pad_idx(self):
        return 0

    @property
    def sos_idx(self):
        return 1

    @property
    def eos_idx(self):
        return 2

    @property
    def unk_idx(self):
        return 3


# ── target sequence construction ─────────────────────────────────────────────

def build_target_sequence(item: dict) -> list:
    """Build the target output token sequence from .mli record.

    Format: [action_class_subtokens..., action_object_subtokens...]

    Example:
      :hint-setting-alist (:enable factorial)
      → [":hint", "-setting", "-alist", " (", ":enable", " ", "factorial", ")"]
    """
    action_type = item.get("output", {}).get("action-type", "")
    action_obj = item.get("output", {}).get("action-obj", "")

    # Serialize action_obj to string
    if isinstance(action_obj, list):
        action_obj = " ".join(str(x) for x in action_obj)
    action_obj = str(action_obj)

    # Build full fix string
    fix_str = f"{action_type} {action_obj}"

    # Subtokenize similar to input: split on parens/whitespace, then split on dashes
    tokens = []
    i = 0
    n = len(fix_str)
    while i < n:
        c = fix_str[i]
        if c in " \t\n":
            # Skip whitespace between symbols (not meaningful as a token here)
            i += 1
        elif c in "()":
            # Gather consecutive parens+whitespace into one token
            start = i
            while i < n and fix_str[i] in "() \t\n":
                i += 1
            tokens.append(fix_str[start:i])
        else:
            # Symbol: read until delimiter, then subtokenize on dashes
            start = i
            while i < n and fix_str[i] not in "() \t\n":
                i += 1
            symbol = fix_str[start:i]
            if symbol:
                tokens.extend(subtokenize(symbol))

    # Add <sos> and <eos>
    return ["<sos>"] + tokens + ["<eos>"]


# ── action type labels ──────────────────────────────────────────────────────

ACTION_TYPES = [
    "use-lemma",
    "add-hyp",
    "add-enable-hint",
    "add-disable-hint",
    "add-use-hint",
    "add-by-hint",
    "add-expand-hint",
    "add-do-not-hint",
    "add-nonlinearp-hint",
    "add-induct-hint",
    "add-cases-hint",
    "add-library",
    "exact-hints",
]

# Prefixes for each action type (used to condition the decoder)
ACTION_PREFIXES = {
    "use-lemma": "use-lemma",
    "add-hyp": "add-hyp",
    "add-enable-hint": "add-enable-hint",
    "add-disable-hint": "add-disable-hint",
    "add-use-hint": "add-use-hint",
    "add-by-hint": "add-by-hint",
    "add-expand-hint": "add-expand-hint",
    "add-do-not-hint": "add-do-not-hint",
    "add-nonlinearp-hint": "add-nonlinearp-hint",
    "add-induct-hint": "add-induct-hint",
    "add-cases-hint": "add-cases-hint",
    "add-library": "add-library",
    "exact-hints": "exact-hints",
}
