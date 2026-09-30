# Optimization techniques

## Interaction rule

Quantization, speculation, caching, batching, parallelism, and disaggregation compete for compute and memory. Tune a balanced configuration. A larger batch can consume the idle compute speculation needs. KV quantization can make offload and disaggregation transfers cheaper. Test each method alone, then the final combination.

## Quantization

Post-training quantization reduces weights or runtime values from native BF16 or FP16. Some models are trained at 8 or 4 bits.

Why it helps:

- Compute-bound prefill can use higher low-precision Tensor Core throughput.
- Bandwidth-bound decode moves fewer bytes for weights and cache.
- Smaller weights load faster and leave more VRAM for batches, KV state, prefix cache, or speculation.
- Smaller KV blocks transfer and offload faster.

A precision step does not produce a literal 2x service gain because packing, unpacking, scales, conversions, and other bottlenecks remain. The source gives a practical LLM gain of 30 to 50 percent for one precision step. Treat this as workload-dependent.

Quantization can improve TTFT, ITL, throughput, memory, startup, and cost. It is the main technique here that can directly degrade answer quality.

### Formats

| Format | Source-era hardware note | Use |
|---|---|---|
| FP64 | Fermi | Scientific computing, not inference |
| FP32 | Kepler | Rare for inference |
| FP16 | Pascal | Common native precision |
| BF16 | Ampere | Common native precision, wider exponent than FP16 |
| FP8 | Hopper | General low-precision production choice |
| MXFP8 | Blackwell source table | Block microscaling |
| INT8 | Pascal | Narrower dynamic range than float |
| FP6 | Blackwell experimental | Experimental in source, AMD adoption mentioned |
| FP4 | Blackwell | Aggressive low precision |
| MXFP4 | Blackwell | Block microscaling |
| NVFP4 | Blackwell | NVIDIA proprietary dual-scale FP4 |
| INT4 | Turing | Aggressive integer format |

Main production choices are 16, 8, and 4 bits. Verify exact accelerator and kernel support. A later source section associates MXFP8 with Hopper and Blackwell, while the format table ties MX formats to Blackwell. Do not assume support.

Floating point has sign, exponent, and mantissa. FP8 E4M3 has one sign bit, four exponent bits, and three mantissa bits. The exponent gives more dynamic range than an equal-width integer. Outliers make dynamic range important.

An 8-bit representation has 256 bit patterns. A 16-bit one has 65,536. Precision alone does not describe distribution or scale behavior.

### Scale granularity

| Scope | Benefit | Cost or risk |
|---|---|---|
| Tensor | Minimal metadata and scaling work | One outlier can reduce resolution for all values |
| Channel | Better local range | More scales and compute |
| Block | Best local outlier handling | Most metadata and scale work |

Source microscaling details:

- MXFP8 and MXFP4 use a block scale per 32 values.
- NVFP4 uses blocks of 16 plus a 32-bit global scale.

Small-block scales consume some memory and compute. Blackwell Tensor Cores are said to absorb part of the scaling cost.

GGUF is common for aggressive local quantization. Dynamic local formats may leave sensitive layers native while pushing others toward integer representations averaging as low as 1.58 bits. Use floating-point formats for quality-sensitive production unless evals support a more aggressive choice.

The source's default quality-speed recommendation is FP8 or MXFP8. FP4, especially NVFP4, is less forgiving. Verify current support and product quality.

### QAT and PTQ

Quantization-aware training, QAT, learns weights and scales under target precision. Post-training quantization, PTQ, converts a finished checkpoint using selected scales and representative calibration data.

Operators of existing checkpoints usually control only PTQ. Source-era QAT examples are GPT-OSS in MXFP4 and Kimi K2 Thinking in INT4. Verify model formats and releases. The source names NVIDIA TensorRT Model Optimizer, ModelOpt, as a leading open-source PTQ tool supporting pruning, distillation, and sparsity and exporting to source-era vLLM, SGLang, and TensorRT-LLM. This is a vendor claim and support changes.

PTQ decisions:

1. Which weights, activations, cache, or attention operations to reduce.
2. Which format and scale scope preserve required range.

Sensitivity from lower to higher risk:

1. Linear weights.
2. Intermediate activations. Activation functions themselves are too small to matter much.
3. KV cache, because every later token reads it.
4. Attention math, especially softmax.

Input, output, early, and late layers may need native precision because they influence final behavior more directly. Cache errors compound through later tokens. Attention errors feed later attention over long sequences.

Conservative pattern:

- FP8 or MXFP8 on selected linear weights and activations.
- Optional FP8 KV after long-context testing.
- Native precision for softmax and sensitive attention.
- Restore first and last layers when needed.

Larger models may tolerate quantization better because behavior is distributed over more parameters. This is a tendency, not permission to skip evals.

### Quantization validation

Use all three for LLMs:

1. Perplexity, where higher is worse.
2. Relevant broad benchmarks.
3. Product evals over real domains and lengths.

Keep prompts, templates, sampling, seeds where available, and scoring fixed. Accept a "no perceptible loss" candidate only when deltas fall inside normal run noise and no critical slice regresses.

If quality drops:

- Move FP4 to FP8.
- Restore sensitive layers.
- Quantize weights only.
- Use channel or block scales.
- Improve calibration data.
- Keep KV or the whole model native.

Measure TTFT, ITL, total TPS, VRAM, load time, and cost. Nominal FLOPS do not predict the gain.

### Quantization rollout

- [ ] Record original perplexity, public tests, and product evals.
- [ ] Start with FP8 or MXFP8 for quality-sensitive production.
- [ ] Quantize linear weights first, then activations.
- [ ] Preserve first, last, input, or output layers when sensitive.
- [ ] Add KV quantization only after long and multi-turn tests.
- [ ] Keep softmax native unless a modality-specific method and eval support otherwise.
- [ ] Use representative PTQ calibration.
- [ ] Account for scale metadata and compute.
- [ ] Require quality deltas inside normal noise.
- [ ] Verify current format, engine, and hardware support.

## Speculative decoding

Ordinary autoregressive decode emits one token per target forward pass. At low or moderate batch, weight reads leave compute underused. Speculation spends spare compute on candidates and verifies several in a target pass.

General sequence:

1. A speculator proposes draft tokens.
2. The target validates them against its own distribution.
3. It accepts the valid prefix and produces one additional target token.

If `N` drafts are accepted, the target pass advances `N + 1` tokens. Rejection truncates the draft at the first wrong token.

Performance depends on draft cost, length, and acceptance. Longer proposals permit more progress but cost more, and later draft positions are less likely to match. Higher temperature reduces predictability. Acceptance varies by domain.

Speculation improves ITL and perceived TPS, not TTFT. It works best at low batch with spare compute. High batch makes verification compete with normal decode. Dynamically disable it when compute saturates. Lower user latency may reduce aggregate throughput and increase cost.

Correct target verification should preserve the target distribution. Validate engine behavior.

### Draft-target

A small draft LLM proposes tokens and a full target verifies. A same-family draft helps tokenizer and behavior alignment. Source rule: draft model at least 10x smaller by parameter count. Fine-tuning or distillation can improve acceptance.

Use it for quick general setup without custom training. Costs include draft weights, activations, KV state, draft prefill, and two-model orchestration. Separate models can require CPU coordination, although TensorRT-LLM can manage both in the source snapshot.

### Medusa

Medusa fine-tunes two to four extra decoder heads onto the target. The ordinary head emits the next token and extra heads propose later positions. It removes a full second model but still has limited proposal length and acceptance. The source says it was uncommon in production and mainly preceded EAGLE.

### EAGLE

EAGLE trains a purpose-built auxiliary network using target hidden states, often from early, middle, and late layers. The source describes:

- Usually under 1B parameters.
- Up to eight proposed tokens.
- Common implementation with one speculative sequence.
- Attachment to the target PyTorch module to avoid CPU round trips.
- Better results with more training data.

Use EAGLE as the source's general recommendation when the team can train and maintain the head. The source names a TensorRT-LLM post-training EAGLE creation path. Check the installed TensorRT-LLM major version and current workflow rather than assuming that tooling is unchanged. EAGLE still targets low-batch latency and can lower fleet throughput.

### N-gram speculation

Build a prompt-derived dictionary from token prefixes to observed suffixes. During decode, look up current generated context, propose a stored suffix, and verify it.

- No learned model.
- Proposals can exceed ten tokens.
- Cheap drafting.
- High acceptance when output repeats input.
- Strong fit for code completion and revision.

It can beat EAGLE in copy-heavy code workloads. Reject it when input-output overlap is low.

### Lookahead decoding

Lookahead generates n-grams online to populate candidates. It generalizes beyond repeated input but spends more compute. Use it only when there is spare compute and prompt-derived n-grams are weak.

### Speculation rollout

- [ ] Confirm decode, not prefill, is the problem.
- [ ] Measure compute headroom at target batches.
- [ ] Log acceptance by position, task, and temperature.
- [ ] Optimize accepted prefix per draft and verification cost, not maximum draft length.
- [ ] Disable speculation dynamically at compute saturation.
- [ ] For draft-target, begin with a same-family model at least 10x smaller.
- [ ] Include draft weights, activations, prefill, and KV in capacity.
- [ ] Prefer EAGLE for general work when training is practical.
- [ ] Prefer n-grams for code and edit-heavy traffic.
- [ ] Compare ITL gain with total throughput and cost loss.
- [ ] Confirm target-equivalent output behavior.

## KV and prefix caching

Every practical autoregressive engine caches keys and values within a request. Cross-request prefix caching reuses state when a new prompt begins with exactly the same token sequence.

A prefix hit skips corresponding prefill, lowering TTFT, compute, and cost. Common repeated prefixes include long system prompts, tools, RAG context, codebases, documents, and multi-turn conversation history.

A hit stops at the first differing token. Matching tokens after divergence cannot reuse autoregressive state. Place stable context first and novel values as late as semantics permit. Canonicalize chat templates and serialization.

Non-prefix reuse is more complex because positions and intervening context change. The source names CacheBlend and LMCache as tools for position correction and selective recomputation. Treat arbitrary reuse as correctness-sensitive and verify current implementation.

### Storage tiers

Source hierarchy:

| Tier | Storage | Approximate GPU path | Approximate capacity | Use |
|---|---|---:|---:|---|
| G1 | GPU VRAM | TB/s | Tens to hundreds of GB | Active and hottest blocks |
| G2 | Host RAM | Tens to hundreds of GB/s | Hundreds of GB to TB | Warm overflow |
| G3 | Local SSD | 5 to 10 GB/s | TB | Cold local blocks |
| G4 | Network SSD | GB/s | Tens of TB | Durable or cluster-wide cold state |

Grace or GB200 host links can improve G2 transfer. NVIDIA Dynamo KVBM is the source's block movement API. Verify current status.

Example allocation from the source: a B200 with 180 GB usable VRAM has 100 GB used by weights and buffers. Of 80 GB left, assigning 80 percent gives 64 GB KV space. The source associates this with a TensorRT-LLM setting named `kv_cache_percent`. The key and semantics may differ across TensorRT-LLM V0, V1, and later versions. This is an allocation example, not a universal setting.

Use recency and frequency policy. Keep hot blocks in fast tiers. A remote fetch counts as useful only if promotion latency beats recompute within the SLO.

### Cache-aware routing

Least-loaded routing can destroy locality. Prefer a replica holding the conversation, codebase, document, system prompt, or LoRA unless its queue delay costs more than a cache fetch or recompute.

A global G4 cache preserves blocks across autoscaling and node replacement, but does not make all hits equal. A G1 hit remains much faster. Score load and tier together.

Measure cache hit in reused tokens, not request count.

### Long context

Context becomes operationally long when KV state affects capacity or speed. The source says this may begin around 32K, 64K, or 128K tokens depending on model, engine, hardware, and traffic. Benchmark these points and the true maximum.

RoPE can extend model capability but does not remove serving cost. Standard attention's cache burden grows linearly with sequence length in this serving account, while full prefill attention can be quadratic.

Tools:

- FlashAttention reduces attention memory traffic.
- PagedAttention uses fixed blocks to reduce fragmentation and duplicate allocation.
- Chunked prefill splits large prompts and schedules chunks alongside decode to avoid monopolization.
- KV quantization and tiered offload reduce resident bytes.
- Model parallelism adds memory when one device cannot fit weights plus cache.
- Sliding-window, compressed, sparse, or other model-specific attention reduces context work only when architecture and training support it.

### Cache rollout

- [ ] Put exact stable tokens before novel values.
- [ ] Measure token-level hit rate and first divergence.
- [ ] Route follow-ups toward local hot state.
- [ ] Compare queue delay with each cache tier and recompute.
- [ ] Allocate cache only after weights and buffers.
- [ ] Define eviction and promotion under realistic churn and autoscaling.
- [ ] Benchmark 32K, 64K, 128K, and actual maximum where relevant.
- [ ] Test FlashAttention, PagedAttention, and chunked prefill under mixed load.
- [ ] Treat non-prefix reuse as a quality and correctness change.

## Model parallelism

### Capacity planning

```text
weight_bytes ~= parameter_count x precision_bits / 8
minimum_GPU_count ~= ceil(
  (weight_bytes + buffers + required_KV_bytes) / usable_VRAM_per_GPU
)
```

The equation is reconstructed from source prose because the figure was missing. Round up to available node topology. Do not size weights alone.

DeepSeek-V3.1 source example: 671B FP8 weights are roughly 671 GB. Four B200s at about 720 GB technically fit weights but leave little cache room. The source says KV allocations often consume 80 percent or more of VRAM left after weights. It recommends eight B200s for realistic service. Treat the model and hardware as a snapshot.

Communication is much slower than local VRAM. Match layout to links.

### Parallel methods

| Method | Partition | Main gain | Main cost | Typical use |
|---|---|---|---|---|
| TP | Tensor operations within every layer | Lower per-user latency and pooled VRAM | Frequent all-reduce | Inside one node |
| EP | Complete MoE experts | Aggregate throughput and multi-node scale | Token routing, no direct per-token speedup | MoE |
| PP | Whole layer stages | Cross-node partition | Pipeline bubbles and latency | Dense multi-node |
| CP | Sequence or latent attention context | Makes huge attention state feasible | Replicated weights and coordination | Video, rare long-context LLM |

### Tensor parallelism

TP shards every layer and combines partial outputs through all-reduce before the next layer. NVLink/NVSwitch makes it practical inside one node.

TP can improve one user's TPS because each device reads a shard and computes part of the pass. It helps only when model and sequence work amortize synchronization. Large models often do. Small models can become slower.

TP applies to dense and MoE models. Under TP, each expert itself is sharded. The source names Llama 405B as a dense-model TP example. Treat that model name as a January 2026 example, not as a sizing rule.

### Expert parallelism

EP places complete experts on devices. With 128 experts and EP8, each GPU stores 16. Tokens route to selected expert owners.

EP raises aggregate throughput and can reduce cost per token. It does not inherently shorten one token's expert computation. The small router is replicated. EP avoids TP all-reduce after every sharded layer, so it can cross nodes more efficiently.

Mixed TP and EP can shard dense attention while distributing complete experts.

### Pipeline parallelism

PP puts sequential layer groups on stages and transfers activations. It can partition dense models across nodes, but pipeline steps add latency and idle bubbles. The source table accidentally mentions backward passes, which are training-only. Inference uses forward stages.

### Context parallelism

CP replicates model weights and splits the sequence or latent-context attention. Ring attention passes partial results around GPUs. It is uncommon for ordinary LLM serving but central for huge video latent attention.

### Multi-node layouts

Source recommendations:

- Dense model: TP within node and PP between nodes, for example `TP8PP2` on two eight-GPU nodes.
- MoE: compare `TP8PP2` for lower per-user latency with `EP16` for aggregate throughput.

Unless memory requires more than one node, additional nodes may produce more value as replicas or specialized prefill/decode pools. Cross-node model parallelism must beat those controls on measured cost and SLO.

### Parallelism rollout

- [ ] Calculate weights, buffers, activations, and required cache.
- [ ] Keep TP all-reduce on NVLink/NVSwitch.
- [ ] For dense multi-node, compare TP-in-node plus PP-across-node with replicas.
- [ ] For MoE, compare EP with TP/PP under actual routing and hot-expert distributions.
- [ ] Add GPUs per request only when they beat horizontal scale.
- [ ] Record collective time and delivered fabric bandwidth.
- [ ] Stop when communication erases saved compute or memory time.

## Prefill-decode disaggregation

Prefill is usually compute-bound and controls TTFT. Decode is usually bandwidth-bound and controls ITL. A shared worker can make phases contend.

Disaggregated serving:

1. A prefill worker processes input, builds KV state, and computes the first token.
2. It transfers cache to a decode worker.
3. Decode generates later tokens.

Each pool gets its own engine settings, hardware, and scale. The source notes compute-bound prefill can use lower TP than bandwidth-bound decode.

### Conditional routing

Do not disaggregate every request. Send a request to decode first:

- If its prefix is cached or post-cache ISL is short, decode prefills locally.
- If uncached input is long, route to a prefill worker.

This avoids routing and transfer cost for cheap requests.

### Scale threshold

The source recommends considering disaggregation when nearly all apply:

1. Daily volume is about 100 million to 1 billion tokens or more, depending on model size.
2. The model is at least 100B parameters.
3. Traffic has long, prefill-heavy inputs.

These are January 2026 rules of thumb. Below them, horizontal replicas often win. A code editor serving a near-trillion-parameter model with large varied contexts is the canonical fit.

Short inputs and high prefix-hit traffic weaken the case because decode can prefill cheaply.

### Dynamo source snapshot

Source-listed capabilities:

- Queue on saturated prefill workers.
- Routing by post-cache ISL and prefill queue.
- NIXL KV transfer.
- KV transpose when prefill and decode use different TP.
- Runtime changes to each pool.

Ratios use `xPyD`. `5P3D` means five prefill engines and three decode engines. No one-to-one requirement exists.

New bottlenecks:

- Prefill queue raises TTFT.
- Decode KV space fills under load.
- KV transfer or layout conversion erases gains.

Tune local-prefill threshold, pool ratio, cache precision, offload, and transfer path.

### Disaggregation rollout

- [ ] Confirm model size, volume, and long post-cache ISL approach the stated thresholds.
- [ ] Benchmark against ordinary horizontal replicas.
- [ ] Route short or cache-hit inputs to local decode prefill.
- [ ] Monitor prefill queue age and depth.
- [ ] Monitor KV transfer and transpose time.
- [ ] Monitor decode KV occupancy and each pool's utilization.
- [ ] Adjust `xPyD` ratios with traffic rather than fixing `1P1D`.
- [ ] Quantize or offload KV before decode capacity becomes the limit.
- [ ] Test prefill-worker and decode-worker failures.
- [ ] Verify current Dynamo and engine support.

## Decision table

| Situation | First methods | Reject when |
|---|---|---|
| Repeated long prompts, high TTFT | Prefix caching and cache-aware routing, then tiering | Hit rate is low or fetch loses to recompute |
| Unique long prompts at high scale | FP8, chunked prefill, attention kernel, conditional disaggregation | Small model, low volume, or short post-cache input |
| Low-batch decode latency | EAGLE or other speculation, then TP for large model | Acceptance is low or throughput cost is unacceptable |
| Code completion/revision | N-gram speculation and prefix cache | Output does not resemble input |
| General speculation without training | Same-family draft at least 10x smaller | Extra model cost erases gain |
| General speculation with training | EAGLE | Head maintenance or high-batch traffic |
| Long-context VRAM pressure | FP8 KV, PagedAttention, offload, then GPUs | Quality drops or transfer misses SLO |
| Dense model in one node | TP | All-reduce exceeds saved work |
| MoE throughput | EP or mixed TP/EP | User latency dominates objective |
| Dense model across nodes | TP in-node plus PP across | Worse than replicas |
| MoE across nodes | Compare EP with TP/PP | Worse cost/SLO |
| Small model or moderate traffic | Horizontal replicas | Single-replica latency itself fails |
| Quality cannot move | Lossless kernels, batching, exact cache | Implementation bugs or no measurable gain |

## Final checklist

- [ ] Remove unnecessary tokens, steps, resolution, frames, and calls first.
- [ ] Select the smallest passing model.
- [ ] Fix exact prefix reuse and continuous scheduling.
- [ ] Choose a current engine and lossless kernel path.
- [ ] Tune batch, concurrency, and cache against tails.
- [ ] Quantize conservatively with quality gates.
- [ ] Add speculation only for measured decode headroom.
- [ ] Add parallelism only for fit or measured per-request gain.
- [ ] Add offload and cache tiers only when transfer beats recompute.
- [ ] Add disaggregation only at sufficient scale.
- [ ] Verify source-era software and hardware claims now.
