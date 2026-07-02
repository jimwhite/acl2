Some recommendations by Gemini:

## Tokenized Encoder-Decoder Sequence-to-Sequence (S2S)

Instead of ranking choices, use an LLM or sequence-to-sequence transformer to explicitly predict the repair action conditioned on the checkpoint and compiler data. ([arXiv 2602.02990](https://arxiv.org/pdf/2602.02990))

[Failed Theorem Formula] + [ACL2 Checkpoint Output] ──> [Transformer Decoder] ──> Predicted Repair: (ADD-HYPOTHESIS 'X) or (INJECT-HINT 'Y)
* **Why it works**: Standard ranking models cannot synthesize new things (like a missing hypothesis variant). An encoder-decoder model treats the ablation dataset as a translation problem: translating broken environments into repaired abstract syntax.
* **Implementation**:
   1. Serialize your ablation tuples into clean text strings: Input: `"Theorem: <thm> | Checkpoint: <clause>"`
   2. Set the target text as the piece that was removed during your ablation: Target: `"Action: <Remove_Hint / Remove_Lemma> | Payload: <exact code/hint name>"`
   3. Fine-tune a compact, code-specialized model (e.g., DeepSeek-Coder, StarCoder, or a 4B–7B Llama variant) using Supervised Fine-Tuning (SFT).
   4. At inference time, use Beam Search or Nucleus Sampling to generate the top $K$ candidate solutions, and let ACL2 validate them in parallel. ([CalPoly thesis](https://digitalcommons.calpoly.edu/cgi/viewcontent.cgi?article=4332&context=theses), [arXiv 2602.02990](https://arxiv.org/pdf/2602.02990), [NeurIPS 2025](https://papers.neurips.cc/paper_files/paper/2025/file/3b77109ad4dd4ba82d07cacd4b24207e-Paper-Conference.pdf))
---

## Goal-Conditioned REINFORCE / GRPO (RL Alignment)

If you want to optimize a model using your dataset, bypass ranking completely and use Reinforcement Learning from Compiler Feedback (RLCF). ([arXiv 2602.02990](https://arxiv.org/pdf/2602.02990), [arXiv 2602.02990v2](https://arxiv.org/abs/2602.02990))
* **Why it works**: You have the ultimate reward function—the ACL2 compiler itself. A proof either passes (Reward = 1) or fails (Reward = 0). ([arXiv 2606.06133](https://arxiv.org/html/2606.06133v2))
* **Implementation**:
   1. Initialize your model using the SFT weights from S2S.
   2. For a given ablated proof from your dataset, sample multiple repair trajectories from the model.
   3. Pipe these attempts directly into an ACL2 background instance.
   4. Use Group Relative Policy Optimization (GRPO) or PPO to update the model weights. The model is penalized if it generates syntactically invalid hints or fails the proof, and heavily rewarded if it discovers the original ablated component (or an entirely alternative path that closes the checkpoint). ([NeurIPS 2025](https://papers.neurips.cc/paper_files/paper/2025/file/3b77109ad4dd4ba82d07cacd4b24207e-Paper-Conference.pdf), [arXiv 2606.06133](https://arxiv.org/html/2606.06133v2))
---
