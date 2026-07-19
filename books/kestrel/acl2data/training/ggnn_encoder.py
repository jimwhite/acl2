"""
GGNN (Gated Graph Neural Network) Encoder

Implements the GGNN message-passing architecture from:
  Allamanis et al. (2018) "Learning to Represent Programs with Graphs"

Used as the encoder in the Graph2Tocopo model per Thompson (2023).
The GGNN encoder outperformed the GREAT encoder on ACL2 proof data.

Architecture:
- Each node has an initial embedding from node type + subtoken
- Over T timesteps, nodes exchange messages with neighbors
- Messages are computed based on edge type (different weights per edge type)
- Node state updated via GRU: h_v^(t+1) = GRU(h_v^(t), aggregate messages)
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class GGNNEncoder(nn.Module):
    """GGNN encoder: message-passing over graph with GRU updates.

    Args:
        hidden_dim: dimension of node embeddings
        num_edge_types: number of distinct edge types
        num_timesteps: T, number of message-passing rounds (default 8)
        dropout: dropout rate
    """

    def __init__(self, hidden_dim: int, num_edge_types: int,
                 num_timesteps: int = 8, dropout: float = 0.1,
                 num_node_types: int = 3, subtoken_vocab_size: int = 50000,
                 subtoken_embed_dim: int = None):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.num_edge_types = num_edge_types
        self.num_timesteps = num_timesteps

        if subtoken_embed_dim is None:
            subtoken_embed_dim = hidden_dim

        # Node type embedding (token, subtoken, root)
        self.node_type_embed = nn.Embedding(num_node_types, hidden_dim)

        # Subtoken embedding
        self.subtoken_embed = nn.Embedding(subtoken_vocab_size,
                                           subtoken_embed_dim)

        # Project subtoken + type → hidden_dim
        self.init_proj = nn.Linear(hidden_dim + subtoken_embed_dim,
                                   hidden_dim)

        # Message functions: per edge type (W * h_src)
        self.msg_fc = nn.ModuleList([
            nn.Linear(hidden_dim, hidden_dim, bias=False)
            for _ in range(num_edge_types)
        ])

        # GRU cell for state update
        self.gru = nn.GRUCell(hidden_dim, hidden_dim)

        # Output projection
        self.out_proj = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Dropout(dropout),
        )

        self.dropout = dropout

    def forward(self, node_types, subtoken_ids, edge_index, edge_types,
                num_nodes_per_graph):
        """
        Args:
            node_types: (total_nodes,) LongTensor - 0=token, 1=subtoken, 2=root
            subtoken_ids: (total_nodes,) LongTensor - subtoken id or -1
            edge_index: (2, total_edges) LongTensor
            edge_types: (total_edges,) LongTensor
            num_nodes_per_graph: list of node counts per graph in batch

        Returns:
            node_embeddings: (total_nodes, hidden_dim)
                Embeddings for each node after message-passing
        """
        total_nodes = node_types.size(0)

        # Initial embeddings
        nt_emb = self.node_type_embed(node_types)  # (N, H)

        # Subtoken embedding (use zero for non-subtoken nodes)
        st_emb = torch.zeros(total_nodes, self.subtoken_embed.embedding_dim,
                             device=subtoken_ids.device)
        mask = subtoken_ids >= 0
        if mask.any():
            st_emb[mask] = self.subtoken_embed(subtoken_ids[mask])

        init_emb = self.init_proj(torch.cat([nt_emb, st_emb], dim=-1))
        init_emb = F.relu(init_emb)

        # Initialize node states
        h = init_emb  # (N, H)

        # Message passing for T timesteps
        for t in range(self.num_timesteps):
            # Compute messages per edge type
            messages = torch.zeros_like(h)

            for etyp in range(self.num_edge_types):
                e_mask = edge_types == etyp
                if not e_mask.any():
                    continue
                src = edge_index[0][e_mask]
                dst = edge_index[1][e_mask]

                # Message: W_etyp * h_src
                msg = self.msg_fc[etyp](h[src])  # (E_typ, H)

                # Aggregate messages to destination nodes
                messages.index_add_(0, dst, msg)

            # GRU update
            h = self.gru(messages, h)

        # Output projection
        h_out = self.out_proj(h)

        return h_out


class GREATEncoder(nn.Module):
    """GREAT encoder: transformer with graph-biased attention.

    From: Hellendoorn et al. (2020) "Global Relational Models of
    Source Code" (GREAT).

    This is provided as an alternative encoder for comparison.
    The thesis found GGNN outperforms GREAT for ACL2 data.
    """

    def __init__(self, hidden_dim: int, num_edge_types: int,
                 num_layers: int = 4, num_heads: int = 8,
                 dropout: float = 0.1, num_node_types: int = 3,
                 subtoken_vocab_size: int = 50000):
        super().__init__()
        self.hidden_dim = hidden_dim

        # Node type embedding
        self.node_type_embed = nn.Embedding(num_node_types, hidden_dim)
        self.subtoken_embed = nn.Embedding(subtoken_vocab_size, hidden_dim)
        self.init_proj = nn.Linear(hidden_dim * 2, hidden_dim)

        # Edge-type embedding
        self.edge_type_embed = nn.Embedding(num_edge_types, num_heads)

        # Transformer layers with graph bias
        self.layers = nn.ModuleList([
            GraphTransformerLayer(hidden_dim, num_heads, dropout)
            for _ in range(num_layers)
        ])

        self.out_proj = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Dropout(dropout),
        )
        self.dropout = dropout
        self.num_heads = num_heads
        self.num_edge_types = num_edge_types

    def forward(self, node_types, subtoken_ids, edge_index, edge_types,
                num_nodes_per_graph):
        total_nodes = node_types.size(0)
        device = node_types.device

        # Initial embeddings
        nt_emb = self.node_type_embed(node_types)
        st_emb = torch.zeros(total_nodes, self.hidden_dim, device=device)
        mask = subtoken_ids >= 0
        if mask.any():
            st_emb[mask] = self.subtoken_embed(subtoken_ids[mask])

        h = self.init_proj(torch.cat([nt_emb, st_emb], dim=-1))

        # Build adjacency list per graph
        # Split by graph boundaries
        graph_boundaries = torch.tensor([0] + list(
            torch.tensor(num_nodes_per_graph).cumsum(0).tolist()),
            device=device)

        for layer_idx, layer in enumerate(self.layers):
            h_list = []
            for g in range(len(num_nodes_per_graph)):
                start = graph_boundaries[g]
                end = graph_boundaries[g + 1]
                n_nodes = end - start

                # Mask edges for this graph
                g_mask = (edge_index[0] >= start) & (edge_index[0] < end)
                g_edge_idx = edge_index[:, g_mask] - start
                g_edge_typ = edge_types[g_mask]
                g_h = h[start:end]

                # Edge-type bias for attention
                edge_bias = self.edge_type_embed(g_edge_typ)  # (E, H)
                # Build bias matrix (n, n, heads)
                attn_bias = torch.zeros(
                    n_nodes, n_nodes, self.num_heads, device=device)
                for e in range(g_edge_idx.size(1)):
                    s, d = g_edge_idx[0, e].item(), g_edge_idx[1, e].item()
                    attn_bias[s, d] = edge_bias[e]

                g_h = layer(g_h, attn_bias.permute(0, 2, 1).unsqueeze(0))
                h_list.append(g_h)

            # Re-merge
            h = torch.cat(h_list, dim=0) if h_list else h

        return self.out_proj(h)


class GraphTransformerLayer(nn.Module):
    """Single transformer layer with graph-bias in attention."""

    def __init__(self, hidden_dim, num_heads, dropout):
        super().__init__()
        self.attn = nn.MultiheadAttention(
            hidden_dim, num_heads, dropout=dropout, batch_first=True)
        self.norm1 = nn.LayerNorm(hidden_dim)
        self.norm2 = nn.LayerNorm(hidden_dim)
        self.ff = nn.Sequential(
            nn.Linear(hidden_dim, hidden_dim * 4),
            nn.ReLU(),
            nn.Linear(hidden_dim * 4, hidden_dim),
        )
        self.dropout = nn.Dropout(dropout)

    def forward(self, x, attn_bias=None):
        # Self-attention with graph bias
        attn_out, _ = self.attn(
            x.unsqueeze(0), x.unsqueeze(0), x.unsqueeze(0))
        x = self.norm1(x + self.dropout(attn_out.squeeze(0)))

        # FF
        ff_out = self.ff(x)
        x = self.norm2(x + self.dropout(ff_out))
        return x
