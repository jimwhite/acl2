"""
Graph2Tocopo Model for ACL2 Proof Fixing

Full encoder-decoder model:
  - GGNN encoder: creates node embeddings from the input graph
    (broken theorem + checkpoints)
  - Tocopo decoder: autoregressively generates fix sequence
    with copy mechanism

Based on Thompson (2023) thesis and:
  - Chen et al. (2021) "PLUR: A Unifying, Graph-Based View of
    Program Learning, Understanding, and Repair"
  - Allamanis et al. (2018) "Learning to Represent Programs with Graphs"
"""

import torch
import torch.nn as nn
import torch.nn.functional as F

from .ggnn_encoder import GGNNEncoder, GREATEncoder
from .tocopo_decoder import TocopoDecoder


class Graph2Tocopo(nn.Module):
    """Graph2Tocopo: GGNN encoder + Tocopo decoder for ACL2 proof fixing.

    Args:
        hidden_dim: embedding dimension (default 256)
        vocab_size: target token vocabulary size
        num_edge_types: number of distinct edge types
        num_node_types: number of node types (3: token, subtoken, root)
        subtoken_vocab_size: max subtoken vocabulary size
        num_timesteps: T for GGNN message passing
        num_decoder_layers: transformer decoder layers
        num_heads: attention heads
        dropout: dropout rate
        max_output_len: maximum output sequence length
    """

    def __init__(self, hidden_dim: int = 256, vocab_size: int = 50000,
                 num_edge_types: int = 10, num_node_types: int = 3,
                 subtoken_vocab_size: int = 50000,
                 num_timesteps: int = 8,
                 num_decoder_layers: int = 4,
                 num_heads: int = 8,
                 dropout: float = 0.1,
                 max_output_len: int = 256,
                 encoder_type: str = "ggnn"):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.vocab_size = vocab_size
        self.max_output_len = max_output_len

        # Encoder
        if encoder_type == "ggnn":
            self.encoder = GGNNEncoder(
                hidden_dim=hidden_dim,
                num_edge_types=num_edge_types,
                num_timesteps=num_timesteps,
                dropout=dropout,
                num_node_types=num_node_types,
                subtoken_vocab_size=subtoken_vocab_size,
            )
        else:
            self.encoder = GREATEncoder(
                hidden_dim=hidden_dim,
                num_edge_types=num_edge_types,
                dropout=dropout,
                num_node_types=num_node_types,
                subtoken_vocab_size=subtoken_vocab_size,
            )

        # Decoder
        self.decoder = TocopoDecoder(
            hidden_dim=hidden_dim,
            vocab_size=vocab_size,
            num_heads=num_heads,
            num_layers=num_decoder_layers,
            dropout=dropout,
            max_output_len=max_output_len,
        )

    def forward(self, batch):
        """
        Args:
            batch: dict with keys:
                - node_types: (total_nodes,) LongTensor
                - subtoken_ids: (total_nodes,) LongTensor
                - edge_index: (2, total_edges) LongTensor
                - edge_types: (total_edges,) LongTensor
                - num_nodes: list of node counts per graph
                - tgt_tokens: (B, S) LongTensor (shifted right)
                - copy_mask: (B, max_nodes) bool tensor

        Returns:
            dict with:
                - token_logits: (B, S, V)
                - copy_logits: (B, S, 1)
                - pointer_logits: (B, S, max_nodes)
        """
        # Encode
        node_embeddings = self.encoder(
            batch["node_types"],
            batch["subtoken_ids"],
            batch["edge_index"],
            batch["edge_types"],
            batch["num_nodes"],
        )

        # Decode
        decoder_out = self.decoder(
            node_embeddings,
            batch["tgt_tokens"],
            batch["copy_mask"],
        )

        return decoder_out

    def generate(self, batch, temperature=1.0, max_len=None):
        """Generate a fix recommendation from a single example.

        Args:
            batch: dict with graph data (batch_size=1)
            temperature: sampling temperature
            max_len: max output length

        Returns:
            list of (token_id, is_copy, copy_node_idx)
        """
        device = next(self.parameters()).device

        node_embeddings = self.encoder(
            batch["node_types"],
            batch["subtoken_ids"],
            batch["edge_index"],
            batch["edge_types"],
            batch["num_nodes"],
        )

        # Reshape to (1, N, H)
        max_nodes = node_embeddings.size(0)
        memory = node_embeddings.unsqueeze(0)  # (1, N, H)
        copy_mask = batch["copy_mask"].unsqueeze(0)  # (1, N)

        return self.decoder.generate(
            memory, copy_mask,
            temperature=temperature, max_len=max_len,
        )


def compute_loss(model_output, tgt_tokens, pad_idx=0,
                 copy_weight=0.5, gen_weight=0.5):
    """Compute Graph2Tocopo loss.

    Combines token generation loss, copy loss, and pointer loss.

    Args:
        model_output: dict from model.forward()
        tgt_tokens: (B, S) target token ids
        pad_idx: padding token index

    Returns:
        (total_loss, token_loss, copy_loss, pointer_loss)
    """
    # Token generation loss (where target is not padding)
    token_logits = model_output["token_logits"]  # (B, S, V)
    gen_loss = F.cross_entropy(
        token_logits.reshape(-1, token_logits.size(-1)),
        tgt_tokens.reshape(-1),
        ignore_index=pad_idx,
    )

    # Copy loss: we use a simplified approach where
    # copy_target is 1 if the target token could be copied from input
    # For now, use a placeholder loss
    copy_logits = model_output["copy_logits"]
    copy_loss = torch.tensor(0.0, device=token_logits.device)

    # Pointer loss: placeholder for now (full implementation
    # requires tracking which node each target token points to)
    pointer_loss = torch.tensor(0.0, device=token_logits.device)

    # Combined loss
    total_loss = gen_weight * gen_loss + copy_weight * (copy_loss + pointer_loss)

    return total_loss, gen_loss, copy_loss, pointer_loss
