"""
Tocopo Decoder with Copy Mechanism

Implements the Tocopo decoder from:
  Tarlow et al. (2020) "Learning to Fix Build Errors with Graph2Diff"
  Chen et al. (2021) "PLUR: A Unifying, Graph-Based View of Program
  Learning, Understanding, and Repair"

Adapted for ACL2 theorem proving per Thompson (2023).

The decoder generates output elements autoregressively. At each step,
it can:
  1. Generate a token from the vocabulary
  2. Copy a node label from the input graph
  3. Point to a specific node in the input graph (not used for ACL2)

The copy mechanism is crucial: it allows the model to copy symbols
from the input (checkpoint/broken theorem) directly into the output,
even if they were never seen during training.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F


class TocopoDecoder(nn.Module):
    """Tocopo decoder with copy mechanism.

    Args:
        hidden_dim: embedding dimension
        vocab_size: output token vocabulary size
        num_heads: attention heads (default 8)
        num_layers: decoder layers (default 4)
        dropout: dropout rate
        max_output_len: maximum output sequence length (default 256)
    """

    def __init__(self, hidden_dim: int, vocab_size: int,
                 num_heads: int = 8, num_layers: int = 4,
                 dropout: float = 0.1, max_output_len: int = 256):
        super().__init__()
        self.hidden_dim = hidden_dim
        self.vocab_size = vocab_size
        self.max_output_len = max_output_len

        # Token embedding (for previously generated tokens)
        self.token_embed = nn.Embedding(vocab_size, hidden_dim)

        # Positional encoding
        self.pos_embed = nn.Embedding(max_output_len, hidden_dim)

        # Decoder transformer layers
        decoder_layer = nn.TransformerDecoderLayer(
            d_model=hidden_dim, nhead=num_heads,
            dim_feedforward=hidden_dim * 4,
            dropout=dropout, batch_first=True)
        self.transformer = nn.TransformerDecoder(
            decoder_layer, num_layers=num_layers)

        # Output heads
        # 1. Token generation head
        self.token_head = nn.Linear(hidden_dim, vocab_size)
        # 2. Copy head (binary: copy or not)
        self.copy_head = nn.Linear(hidden_dim, 1)
        # 3. Pointer head (point to input node index)
        self.pointer_head = nn.Linear(hidden_dim, hidden_dim)

        self.dropout = dropout

    def forward(self, encoder_output, tgt_tokens, copy_candidates_mask,
                edge_index=None, encoder_node_labels=None,
                src_key_padding_mask=None):
        """
        Args:
            encoder_output: (batch, max_nodes, hidden_dim) — padded uniform
            tgt_tokens: (batch, seq_len) token ids (shifted right)
            copy_candidates_mask: (batch, max_nodes) bool, True=copyable
            src_key_padding_mask: (batch, max_nodes) bool, True=ignore
        """
        batch_size, seq_len = tgt_tokens.shape
        device = tgt_tokens.device
        memory = encoder_output  # already (B, N, H)

        # Token + positional embedding
        tok_emb = self.token_embed(tgt_tokens)  # (B, S, H)
        positions = torch.arange(seq_len, device=device).unsqueeze(0)
        pos_emb = self.pos_embed(positions)  # (1, S, H)
        tgt_emb = tok_emb + pos_emb
        tgt_emb = F.dropout(tgt_emb, p=self.dropout, training=self.training)

        # Causal mask (no look-ahead)
        causal_mask = nn.Transformer.generate_square_subsequent_mask(
            seq_len, device=device)

        # Decoder transformer — memory_key_padding_mask ignores dummy nodes
        decoded = self.transformer(
            tgt_emb, memory,
            tgt_mask=causal_mask,
            memory_key_padding_mask=src_key_padding_mask,
        )  # (B, S, H)

        # Token logits
        token_logits = self.token_head(decoded)  # (B, S, V)

        # Copy logits
        copy_logits = self.copy_head(decoded)  # (B, S, 1)

        # Pointer logits: attention over input nodes
        pointer_flat = self.pointer_head(decoded)  # (B, S, H)
        pointer_logits = torch.bmm(
            pointer_flat,
            memory.transpose(1, 2))  # (B, S, N)

        # Mask non-copyable nodes
        if copy_candidates_mask is not None:
            cm = copy_candidates_mask.unsqueeze(1)  # (B, 1, N)
            pointer_logits = pointer_logits.masked_fill(
                cm == 0, float("-inf"))

        return {
            "token_logits": token_logits,
            "copy_logits": copy_logits,
            "pointer_logits": pointer_logits,
        }

    def generate(self, encoder_output, copy_candidates_mask,
                 start_token=1, end_token=2, max_len=None,
                 temperature=1.0, encoder_node_labels=None):
        """Greedy/autoregressive generation.

        Args:
            encoder_output: (1, max_nodes, H)
            copy_candidates_mask: (1, max_nodes) bool mask
            start_token: sos token id
            end_token: eos token id
            max_len: max generation length
            temperature: sampling temperature (1.0 = greedy)

        Returns:
            list of (token_id, is_copy, copy_node_idx) tuples
        """
        if max_len is None:
            max_len = self.max_output_len

        device = encoder_output.device
        batch_size = 1
        max_nodes = encoder_output.size(1)

        output = []
        # Start with sos token
        current_tokens = torch.tensor([[start_token]], device=device)

        for step in range(max_len):
            # Forward pass
            result = self.forward(
                encoder_output, current_tokens,
                copy_candidates_mask)

            # Get last step predictions
            tk = result["token_logits"][:, -1, :] / temperature  # (1, V)
            cp = result["copy_logits"][:, -1, :]  # (1, 1)
            pt = result["pointer_logits"][:, -1, :]  # (1, N)

            # Composite probability: copy vs generate
            tk_probs = F.softmax(tk, dim=-1)
            cp_prob = torch.sigmoid(cp)  # (1, 1)
            pt_probs = F.softmax(pt, dim=-1)  # (1, N)

            # Decision: generate token or copy
            if temperature == 1.0:
                # Greedy
                max_tk_val, max_tk_idx = tk_probs.max(dim=-1)
                max_pt_val, max_pt_idx = pt_probs.max(dim=-1)

                if cp_prob.item() > 0.5 and max_pt_val.item() > max_tk_val.item():
                    # Copy
                    next_token = -1  # special copy token
                    copy_idx = max_pt_idx.item()
                    output.append((next_token, True, copy_idx))
                else:
                    next_token = max_tk_idx.item()
                    output.append((next_token, False, -1))
                    if next_token == end_token:
                        break
            else:
                # Sampling
                if torch.rand(1).item() < cp_prob.item():
                    # Sample a node to copy
                    pt_sampled = torch.multinomial(pt_probs.squeeze(0), 1)
                    output.append((-1, True, pt_sampled.item()))
                else:
                    tk_sampled = torch.multinomial(tk_probs.squeeze(0), 1)
                    tok_id = tk_sampled.item()
                    output.append((tok_id, False, -1))
                    if tok_id == end_token:
                        break

            # Append to current tokens
            next_ids = torch.tensor(
                [[next_token if next_token >= 0 else 0]], device=device)
            current_tokens = torch.cat([current_tokens, next_ids], dim=1)

        return output
