# Foundations and models

## Source boundary

This reference paraphrases chapters 0 through 2 of *Inference Engineering* by Philip Kiely, Baseten Books, 2026. The source was completed in January 2026. Market, model, availability, and cost statements are snapshots. Check model licenses and current official sources.

## The inference stack

Training learns weights. Inference runs trained models to produce outputs, especially in production. Generative inference needs more GPU, runtime, distributed-systems, and product work than classic CPU-hosted predictive models.

Three layers must work together:

- The runtime runs one model efficiently on one GPU-backed instance. Its main controls are batching, caching, precision, speculation, kernels, and model parallelism.
- Infrastructure adds replicas, autoscaling, queues, routing, regions, providers, and failure handling.
- Tooling exposes enough control to tune and debug the service while automating repeated infrastructure work.

Do not optimize one layer in isolation. A kernel cannot repair queueing. A global scheduler cannot repair an inefficient engine. A managed platform that hides required controls can block diagnosis.

## Open, closed, shared, and dedicated

A closed model exposes an API or product but not its weights. An open-weight model publishes weights, but the license may still restrict commercial or other use. Read the exact license.

Open versus closed and shared versus dedicated are separate choices. A provider may offer dedicated access to a closed model. Open weights make self-managed dedicated deployment possible.

The source reports more than two million Hugging Face models, about 25x the count five years earlier, and dates broad open-versus-closed capability parity to DeepSeek V3 and R1 in December 2024. It says open releases can match a closed frontier within weeks or months. These are time-sensitive market claims without supporting methodology in the extract. They do not change the need for product evals.

Shared service:

- Low setup and operating work.
- Consumption pricing and no customer-managed model cold start.
- Provider controls rate limits, behavior, runtime, quality updates, and much of availability.
- Spend usually rises linearly with usage.

Dedicated service:

- Reserved or owned GPU capacity, paid mostly by time or capital cost.
- Control over model, latency, uptime design, topology, and orchestration.
- Minimum spend, utilization risk, engineering scope, and on-call burden.

Move to dedicated service for a current measured need:

1. At measured volume and utilization, GPU-hour TCO beats consumption pricing.
2. A fine-tune, custom model, latency limit, or uptime design needs deployment control.
3. A multi-model pipeline needs co-location or tighter orchestration.

Do not self-host for forecast scale alone. Before product-market fit, a strong paid API usually protects scarce engineering time. The source claims dedicated open inference can be 80 percent cheaper at scale and contrasts roughly 99 percent shared-provider availability with possible 99.99 percent dedicated availability. These are unverified source claims, not defaults. Utilization, engineering, redundancy, hardware price, and traffic shape determine actual cost and uptime.

At low and moderate scale, focus on replica scaling and startup. The source says access to capacity becomes a main concern at roughly a few hundred GPUs. At larger scale, regions and providers become separate pools unless a global scheduler can place work across them. Multi-region operation can add capacity, fault isolation, lower network delay, and residency options, but also adds routing, governance, consistency, and observability work.

## Workload definition

Optimization needs a target. Define the best acceptable system in terms of quality, latency, throughput, cost, reliability, and hard policy constraints. Maximizing one metric is not a design.

Record:

- Exact model requirement or acceptable family.
- Input transport, chat template, sampling parameters, schema, streaming behavior, stop behavior, and useful output form.
- User-action-to-result latency budget and percentile objective.
- Aggregate throughput or completion deadline.
- Cost per request, active user, hour, job, or month.
- Request concurrency, arrival pattern, ISL and OSL distributions, media dimensions and durations, prefix overlap, and peaks.
- Availability, failure domains, region, sovereignty, privacy, and regulatory requirements.

A vertical application should constrain model families, lengths, output schemas, regions, concurrency, and pipeline stages when the product allows it. General-purpose serving is normally justified only for a model provider serving diverse customers or a broad internal inference platform.

### Workload patterns

- Agents fan one action into several calls. Budget the whole chain, parallel work, retries, tool calls, and cumulative cost.
- Retrieval chat needs low TTFT, but retrieval and network delay consume the same end-to-end budget.
- Voice and translation need low conversational loop latency across VAD, ASR, model, TTS, and transport.
- Media generation needs an explicit quality versus completion-time point.
- Search has offline corpus preparation and online query paths.
- Recommendations need stable tail latency under volume.
- IDE completion needs a useful chunk at typing speed. Token-at-a-time streaming may not fit the interface.
- Moderation often values throughput and unit cost more than interactive speed.

Online work has a waiting user, so optimize request and tail latency. Offline work has a deadline, so use larger batches and optimize jobs or tokens per hour. If one model has meaningful online and offline volume, use separate pools. Real-time transcription and back-catalog transcription should not share one scheduler policy.

Consumer traffic often has tighter marginal cost and less predictable spikes. Business traffic often has better margins, predictable demand, and stricter uptime or latency in a revenue path. These are tendencies, not substitutes for measured requirements.

Security, privacy, sovereignty, and regulatory review must include every infrastructure provider and every stored intermediate. They are pre-deployment architecture inputs, not a runtime toggle.

### Workload worksheet

- [ ] Online, offline, or both.
- [ ] Streamed output or useful only when complete.
- [ ] Input and output distributions, including tails and maxima.
- [ ] Reasoning-token budget, context window, and `max_tokens` policy.
- [ ] Request schema, chat template, tool definitions, stop conditions, and structured-output requirements.
- [ ] TTFT, ITL or perceived TPS, total completion, and P50/P90/P95/P99 targets.
- [ ] Total TPS, concurrent streams, images/hour, audio hours/hour, or jobs/hour target.
- [ ] Cost unit and budget.
- [ ] Availability objective and acceptable failure domains.
- [ ] Geographic, privacy, retention, contractual, and regulatory restrictions.
- [ ] Daily and weekly demand cycles, bursts, and launch or campaign spikes.

## Model selection and evaluation

Holding runtime and hardware constant, fewer parameters usually reduce latency and cost. Model choice often has more impact than a later serving trick.

Selection workflow:

1. Shortlist candidates with public benchmarks, exact license, architecture support, context needs, and current availability.
2. Build product evals from real data, especially the hardest required cases.
3. Inspect individual outputs and aggregate scores.
4. Investigate disagreement between scores and domain judgment.
5. Select the smallest model that clears the quality threshold.
6. Prefer a popular, well-supported architecture when quality is close. Existing kernels, quantization paths, and engine support have operational value.
7. Lock the baseline before numerical or behavioral optimization.

A small model is not always enough. Broad or difficult tasks may still need a frontier model. Use capability thresholds, not leaderboard rank. A model that trails overall can be commercially sufficient for one task.

Public tests such as MMLU, SWE-bench, GSM8K, HumanEval, or pairwise Elo help shortlist. They cannot replace product evals because tests saturate, labs optimize for them, and Goodhart's Law weakens targeted measures. Use existing eval tools unless a concrete need requires a custom framework.

### Fine-tuning and distillation

Fine-tuning adapts pretrained weights using domain or task data. It keeps the structural architecture. A few-billion-parameter text-to-SQL model can match a much larger coding model on a narrow SQL task if data and evals are strong. Do not extrapolate this to broad tasks.

Distillation trains a student on a teacher's probability distribution. Fine-tuning on teacher-generated input-output pairs is synthetic-data training, not full distillation. Distillation transfers teacher behavior, including errors and bias. It is useful when only a large capable model exists and smaller access paths are needed. The source says it is less common in deployed systems than ordinary fine-tuning.

DeepSeek R1 is the source example. The 671B teacher had Llama and Qwen based distilled variants with lower benchmark performance. Reusing popular architectures inherited engine and kernel support. Treat names and scores as January 2026 context.

### Eval guardrails

- Use real prompts, outputs, domain slices, and realistic lengths.
- Keep generation parameters, templates, seeds where supported, and scoring procedures fixed.
- Preserve the original baseline artifact and raw examples.
- Rerun after quantization, approximate attention, model conversion, new kernels with numerical changes, or altered decoding behavior.
- A score change should be no larger than ordinary nondeterministic run noise for a "no perceptible loss" target.
- Do not let aggregate scores hide regression on a critical slice.

## Neural model basics

A node multiplies inputs by weights, adds bias, and emits a value. A linear layer is conventionally:

```text
y = xW + b
```

Libraries may orient vectors as `y = Wx + b`. Stacking only linear transforms collapses algebraically, for example `(xW1)W2 = x(W1W2)`. Nonlinear activations prevent that collapse. ReLU is:

```text
ReLU(x) = max(0, x)
```

Other examples are SiLU, Swish, and SwiGLU. Not all activations simply zero negative values.

An encoder maps raw input to an internal representation. A decoder generates output from a representation. Generative LLMs are usually decoder-only. BERT-style embedding models are encoder-only. Whisper encodes audio and decodes text. Image and video systems combine several neural components.

Transformers use attention to model relationships in sequences. Two broad generation patterns are:

- Autoregression, which predicts one next token repeatedly.
- Iterative denoising, which repeatedly refines latent noise into media.

## LLM request mechanics

### Tokens and context

A tokenizer maps text chunks to integer IDs. It is a deterministic segmentation and lookup procedure, not neural inference. Vocabularies are model-specific and often exceed 100,000 entries in the source snapshot. Better tokenization can reduce token count and therefore decode steps and cost.

A request may contain input, generated reasoning, and final output:

```text
input tokens + reasoning tokens + output tokens <= context-window tokens
```

`max_tokens` may impose a lower output limit. The source gives an approximate English ratio of four tokens to three words for the Llama 3 tokenizer family. Treat it as family-specific and measure with the actual tokenizer.

Use the exact tokenizer and chat template expected by training. Small differences in role serialization, separators, tool definitions, and markers can change quality, tool calls, stopping, and cache overlap.

### Prefill and decode

1. Serialize with the chat template and tokenize.
2. Prefill processes all input positions, creates attention state, and builds the KV cache.
3. Ordinary decode emits one token per target-model forward pass.
4. The new token extends the sequence and cache.

Prefill usually drives TTFT and is compute-bound. Decode usually drives ITL and perceived TPS and is bandwidth-bound at low-to-medium batch. These are profiling hypotheses, not laws.

### Logits, sampling, and constraints

The LM head produces one logit per vocabulary token. Softmax normally converts logits to probabilities.

- Temperature changes distribution sharpness. Lower is less variable.
- Top-k retains the `k` most probable tokens.
- Top-p retains the smallest high-probability set whose cumulative mass reaches `p`.
- Engines commonly map temperature 0 to greedy selection, but implementation details differ.
- Top-k 1 is greedy.

Structured generation must constrain valid tokens at each decode step. Repairing text after generation is not equivalent. Generation stops on a stop token, `max_tokens`, or the context limit.

## Transformer structure

A causal language model normally has:

1. An embedding layer from token IDs to vectors.
2. Many transformer blocks.
3. A language-model head, commonly called the LM head or `LMHead`, from hidden state to vocabulary logits.

A transformer block has attention, a feed-forward network, normalization, and activation. Feed-forward networks commonly appear as `FFN` or `MLP` in configs, traces, engine logs, and kernel names. Feed-forward linear layers usually hold most weights. Attention often holds the next largest share and can be the harder serving operation. Do not assume it always dominates, especially for feed-forward-heavy and MoE models.

Hugging Face `config.json` identifies architecture and dimensions. One architecture can have several sizes, instruction variants, and LoRA or full fine-tunes. Runtime work often transfers across a family, but check custom code and exact shapes.

`Qwen3MoeForCausalLM`, for example, identifies the Qwen family, version 3, MoE structure, and causal next-token objective.

## Attention and KV state

Scaled dot-product attention is reconstructed from the missing source figure:

```text
Attention(Q, K, V) = softmax(QK^T / sqrt(d_k))V
```

- Queries are representations to update.
- Keys provide matchable context.
- Values provide information mixed by attention weights.
- Self-attention derives all three from one sequence.
- Cross-attention derives queries from one sequence and keys and values from another.
- Causal masking hides future positions.
- Multi-head attention runs several learned attention operations in parallel.

Naive full-sequence attention uses quadratic time and space in sequence length. During autoregressive decode, the KV cache stores prior keys and values. A new token computes only new state and reads cached history. Per-token work still grows roughly with current context, and generating a long full sequence is not strictly linear in total cost.

KV lifecycle:

- Build during prefill.
- Read and append during decode.
- Store in VRAM by default.
- Consume substantial capacity and bandwidth for long context or high concurrency.

Prefix caching reuses KV blocks between requests with exact shared token prefixes. PagedAttention changes allocation, not asymptotic work. FlashAttention changes implementation and memory traffic while preserving attention semantics within normal numerical precision.

### Attention alternatives

- Sliding-window attention restricts each position to `w` earlier tokens, changing `O(N^2)` to `O(Nw)`. The source gives `8K` to `32K` as a common window range.
- Linear attention approximates softmax attention with linear-time work.
- Compressed attention summarizes old context while keeping recent context detailed.
- Multi-latent attention works in a lower-dimensional latent representation.
- Gated attention is named in the source but not defined precisely enough for implementation.
- Mamba uses selective recurrent state updates with linear sequence scaling. Hybrid systems mix state-space and transformer blocks. The source names NVIDIA Nemotron 3 Nano as a January 2026 hybrid example. Verify its current architecture and engine support.

Nearby context often matters more, but long-range retrieval, code, and documents can depend on distant tokens. Training and inference must use compatible attention behavior. Prefer lossless kernels before inference-only approximation.

## Mixture of experts

MoE replaces one dense feed-forward transform with many expert transforms and a router. Only selected experts run for each token at each MoE layer. Total parameters can far exceed active parameters per token.

Source example, Qwen3-235B-A22B:

- 235B total parameters.
- Roughly 22B active parameters.
- 128 experts.
- Eight selected experts at each of 94 layers per generated token.

"Active per request" is imprecise because routing changes by token and layer.

Serving consequences:

- Single-token compute may resemble a smaller dense model if all weights fit.
- All expert weights still consume storage and normally accelerator memory.
- A batch may activate most experts across its tokens, reducing sparse savings.
- Expert parallelism places complete experts on devices and routes tokens.
- Placement, replication of hot experts, communication, and load balance matter.

Source rules of thumb say MoE is common above 100B total parameters, appears as low as 20B to 30B, and dense designs are often efficient below 32B, especially below 8B. Narrow task models may gain little from experts. These are starting points, not boundaries.

## Diffusion mechanics

An image pipeline usually contains:

1. A text encoder for prompt conditioning.
2. A denoiser that repeatedly refines latent noise.
3. A VAE that decodes the final latent into pixels.

LoRA adapters and ControlNets can alter style, quality, edges, shapes, or colors. Tools such as ComfyUI compose these stages. Profile components and transfers separately.

Latent processing reduces positions. A `128 x 128` latent has `1/64`, or about 1.56 percent, as many spatial positions as a `1024 x 1024` image. This omits channels and is not a byte formula.

Conventional models often use 30 to 50 denoising steps. Classifier-free guidance may run conditioned and unconditioned passes:

```text
forward passes = denoising steps x 2
```

Fifty guided steps can mean 100 denoiser passes. A guidance scale near 4 is a source-era rough default. Prompt, negative prompt, step count, guidance, resolution, and aspect ratio all affect quality and runtime.

Diffusion transformers process latent patches. Newer systems use larger language or vision-language text encoders, larger denoisers, and more complex pipelines. Few-step systems use eight or fewer steps and can cut generation time by a source-reported 80 to 90 percent, with visible quality loss. Latent consistency commonly predicts the target latent in two to four refinements. Distillation is another path.

Choose a few-step model for interactive work only after product image evals.

### Video structure

Video models are often three to five times larger than image models and process 10 to 100 times more latent information, according to the source. They commonly use around 50 steps.

Modern systems represent the complete clip as `X,Y,T` latent state. Frames attend to one another and update together. This improves temporal consistency but makes attention expensive. Framewise generation lets early errors compound.

Common source-era behavior:

- Fixed frame count per request.
- Clips of a few seconds.
- Several seconds of inference per second of output.
- Batch size 1 occupying an eight-GPU node.

These are January 2026 observations. Benchmark current models.

Autoregressive and hybrid video research tries to reduce global attention without returning to unstable independent frame generation. The source names Self Forcing but provides no implementation detail. The same dimensional framing extends from video `X,Y,T` to 3D `X,Y,Z`, world models, and generative CAD. Treat these as research directions, not serving recipes.

## Bottleneck diagnosis with the roofline model

The main GPU resources are compute throughput and memory bandwidth. An ideal kernel uses both, but most saturate one.

Machine balance:

```text
machine balance = peak operations/second / peak memory bytes/second
```

Arithmetic intensity:

```text
arithmetic intensity = arithmetic operations / bytes transferred
```

Roofline bound:

```text
attainable performance <= min(
  peak compute,
  memory bandwidth x arithmetic intensity
)
```

If workload intensity is above machine balance, compute is the likely limit. Below it, bandwidth is likely. Near the ridge point, use achieved rather than advertised rates.

Source example for H100 FP16 dense peak:

```text
989 teraFLOPS / 3.35 TB/s ~= 295 FLOPs/byte
```

Precision, sparsity, SKU, units, clocks, and achieved rates matter. Spec sheets often use decimal TB while memory calculations may use binary MiB.

The source's attention example uses `d = 128`, `N = 4096`, and FP16 values. Each full `4096 x 4096` score or probability matrix occupies about 32 MiB. The source reports 62 FLOPs/byte, below the quoted 295 FLOPs/byte H100 crossover. Its exact operation accounting was in missing figures. It also calls the calculation decode while using full `N x d` queries and `N x N` score matrices. Cached one-token decode normally has one query position. Treat the matrix footprint as full-sequence attention anatomy and the reported intensity only as an illustration, not a validated decode derivation.

### Practical classifications

- Prefill processes many positions in matrix-matrix work and reuses weights. It is usually compute-bound.
- Decode repeatedly reads weights and growing KV state for small-batch or matrix-vector work. It is usually bandwidth-bound.
- Batching decode raises arithmetic intensity by sharing loaded weights, improving fleet throughput while potentially hurting per-request latency.
- Image and video denoisers process large latent states in parallel on every step. They are usually compute-bound after avoidable memory inefficiency is removed.

Diagnosis procedure:

1. Split tokenization, queue, prefill or encoder, decode or denoising, postprocessing, and network.
2. Profile the expensive phase on production hardware.
3. Measure or estimate arithmetic intensity and compare it with datatype-specific machine balance.
4. For compute limits, reduce operations or steps, improve Tensor Core use, fuse, or use more compute.
5. For bandwidth limits, reduce bytes, improve layout and cache use, quantize when quality allows, or batch enough to reuse weights.
6. For capacity limits, reduce state, improve paging, offload, or add memory.
7. For communication limits, change parallel layout or topology.
8. Reprofile and confirm the user-visible result.

## Architecture and model checks

- [ ] Read `config.json` and model card.
- [ ] Confirm exact architecture, tokenizer, template, attention type, positional encoding, and custom code.
- [ ] Confirm context accounting includes input, reasoning, and output.
- [ ] Confirm engine support for quantization, structured output, sampling, stop behavior, and selected hardware.
- [ ] Check that sliding-window, compressed, latent, state-space, or hybrid inference matches training.
- [ ] Profile MoE expert routing and balance under real batches.
- [ ] Treat architecture-family optimization reuse as provisional until exact shapes and variants pass tests.
