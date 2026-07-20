"""
Dense GGNN + Tocopo — batched operations, no sparse conversion.

Matches PLUR's approach: all operations are dense tensor contractions
via torch.einsum.  Input edges are (B, E, N, N) dense adjacency.
No Python loops for edge index construction — pure GPU tensor ops.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class DenseGGNN(nn.Module):
    """GGNN with dense batched operations (PLUR-style).

    Args:
        hidden_dim: 128 (PLUR default)
        num_edge_types: from data
        num_timesteps: 8 (message passing rounds)
        dropout: 0.1
    """

    def __init__(self, hidden_dim=128, num_edge_types=10, num_timesteps=8,
                 dropout=0.1, num_node_types=3, subtoken_vocab_size=50000):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.num_edge_types = num_edge_types
        self.num_timesteps = num_timesteps

        # Node type + subtoken → initial embedding
        self.node_type_embed = nn.Embedding(num_node_types, hidden_dim)
        self.subtoken_embed = nn.Embedding(subtoken_vocab_size, hidden_dim)
        self.init_proj = nn.Linear(hidden_dim * 2, hidden_dim)

        # Per-edge-type kernels: (E, H, H)
        # PLUR: edge_kernels = jax.random.normal / sqrt(hidden_dim)
        self.edge_kernels = nn.Parameter(
            torch.randn(num_edge_types, hidden_dim, hidden_dim)
            / (hidden_dim ** 0.5))
        self.edge_biases = nn.Parameter(
            torch.randn(num_edge_types, hidden_dim) * 1e-5)

        # GRU cell for node updates
        self.gru = nn.GRUCell(hidden_dim, hidden_dim)

        # Layer norms (num_steps + 1)
        self.layer_norms = nn.ModuleList([
            nn.LayerNorm(hidden_dim) for _ in range(num_timesteps + 1)])

        self.dropout = dropout

    def forward(self, node_types, subtoken_ids, edges, node_mask=None):
        """
        Args:
            node_types: (B, N) int
            subtoken_ids: (B, N) int (-1 for non-subtoken)
            edges: (B, E, N, N) float — dense adjacency per edge type
            node_mask: (B, N) bool — True for padding, optional

        Returns:
            node_hiddens: (B, N, H)
        """
        B, N = node_types.shape
        device = node_types.device

        # Initial embeddings
        nt_emb = self.node_type_embed(node_types)  # (B, N, H)
        st_emb = torch.zeros(B, N, self.hidden_dim, device=device)
        mask = subtoken_ids >= 0
        if mask.any():
            st_emb[mask] = self.subtoken_embed(subtoken_ids[mask])
        h = F.relu(self.init_proj(torch.cat([nt_emb, st_emb], dim=-1)))
        h = F.dropout(h, p=self.dropout, training=self.training)

        # Pre-loop layer norm
        h = self.layer_norms[0](h)

        for t in range(self.num_timesteps):
            # Dense message passing — PLUR-style einsum
            # edges: (B, E, N, N), kernels: (E, H, H), h: (B, N, H)
            # → messages: (B, N, H)
            #   messages[b,n,h] = sum_{e,m} edges[b,e,m,n] * (h[b,m] @ kernel[e])
            messages = torch.einsum(
                'bemv,ehi,bmh->bvi', edges, self.edge_kernels, h)

            # Bias: sum over incoming edge counts per edge type
            # incoming[b,v,e] = sum_{m} edges[b,e,m,v]
            incoming = torch.einsum('bemv->bev', edges)  # (B, E, N)
            bias = torch.einsum('bev,eh->bvh', incoming, self.edge_biases)
            messages = messages + bias

            # GRU update
            h = self.gru(messages.reshape(-1, self.hidden_dim),
                         h.reshape(-1, self.hidden_dim))
            h = h.view(B, N, self.hidden_dim)
            h = self.layer_norms[t + 1](h)

        # Zero out padding nodes
        if node_mask is not None:
            h = h * (~node_mask.unsqueeze(-1))

        return h


class DenseGraph2Tocopo(nn.Module):
    """Complete Graph2Tocopo with dense GGNN + Tocopo decoder.

    Args:
        hidden_dim: 128
        num_edge_types: from vocab
        vocab_size: output vocab
        num_timesteps: 8
        num_decoder_layers: 4
        num_heads: 1 (PLUR default)
        dropout: 0.1
    """

    def __init__(self, hidden_dim=128, num_edge_types=10, vocab_size=50000,
                 num_timesteps=8, num_decoder_layers=4, num_heads=1,
                 dropout=0.1):
        super().__init__()
        self.encoder = DenseGGNN(
            hidden_dim=hidden_dim, num_edge_types=num_edge_types,
            num_timesteps=num_timesteps, dropout=dropout)

        from training.tocopo_decoder import TocopoDecoder
        self.decoder = TocopoDecoder(
            hidden_dim=hidden_dim, vocab_size=vocab_size,
            num_heads=num_heads, num_layers=num_decoder_layers,
            dropout=dropout, max_output_len=256)

    def forward(self, batch):
        """
        batch: {
          node_types: (B, N), subtoken_ids: (B, N),
          edges: (B, E, N, N), copy_mask: (B, N),
          tgt_ids: (B, S)
        }
        """
        B, N = batch["node_types"].shape
        device = batch["node_types"].device

        # Build node mask (True = padding)
        node_mask = (batch["node_types"] == 0) & (batch["subtoken_ids"] < 0)

        # Encode
        node_emb = self.encoder(
            batch["node_types"], batch["subtoken_ids"],
            batch["edges"], node_mask=node_mask)  # (B, N, H)

        # Decode
        tgt_in = batch["tgt_ids"][:, :-1]
        src_mask = node_mask  # (B, N) — True = padding, ignore in cross-attn
        dec_out = self.decoder(node_emb, tgt_in, batch["copy_mask"],
                               src_key_padding_mask=src_mask)

        return dec_out
