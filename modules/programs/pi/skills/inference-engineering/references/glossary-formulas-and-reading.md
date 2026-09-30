# Glossary, formulas, and reading

## Formula sheet

### Latency and throughput

```text
perceived TPS = 1 / ITL_seconds
              = 1000 / ITL_milliseconds
```

`10 ms ITL = 100 TPS`. `2 ms ITL = 500 TPS`.

```text
source-style ASR speed factor = audio duration / processing duration
conventional ASR RTF         = processing duration / audio duration
```

Always state the convention.

### Context and memory

```text
input tokens + reasoning tokens + output tokens <= context-window tokens
```

```text
weight_bytes ~= parameter_count x precision_bits / 8
```

At FP8, 1B parameters need roughly 1 GB for weights only.

```text
minimum_GPU_count ~= ceil(
  (weight_bytes + buffers + activations + required_KV_bytes)
  / usable_VRAM_per_GPU
)
```

This sizing formula is reconstructed from source prose because its figure was missing. Round up to a real node topology and leave operating headroom.

Coarse source rule:

```text
required VRAM >= model weights + at least 50% headroom for KV cache
```

Use more for long context, high batch, and video. Replace the heuristic with model-specific cache math when possible.

### Linear algebra and attention

```text
y = xW + b
```

Some libraries write `y = Wx + b`.

```text
ReLU(x) = max(0, x)
```

```text
D = A x B + C
```

The reconstructed scaled dot-product attention equation is:

```text
Attention(Q, K, V) = softmax(QK^T / sqrt(d_k))V
```

Full attention is `O(N^2)`. Sliding-window attention with window `w` is `O(Nw)`.

### Roofline

```text
machine balance = peak operations/second / peak memory bytes/second
arithmetic intensity = operations / bytes transferred
```

```text
attainable performance <= min(
  peak compute,
  memory bandwidth x arithmetic intensity
)
```

If intensity is below machine balance, bandwidth is the likely limit. If above, compute is likely. Use achieved rates near the ridge point.

Source H100 FP16 dense example:

```text
989 teraFLOPS / 3.35 TB/s ~= 295 FLOPs/byte
```

Precision, dense versus sparse, decimal versus binary units, SKU, and clocks matter.

### Diffusion passes

```text
passes with classifier-free guidance = denoising steps x 2
```

A 50-step run can execute 100 denoiser passes.

Late guidance cutoff source example:

```text
30 guided steps x 2 + 20 unguided steps x 1 = 80 passes
```

This is a 20 percent pass-count reduction versus 100. Validate quality.

### VLM video input

```text
24 frames/s x 4 seconds x 1,000 tokens/HD frame = 96,000 tokens
```

The 1,000-token frame count is a source rule of thumb. Measure the exact processor.

### Cost

Reconstructed API relationship:

```text
API cost
  = input_tokens / 1,000,000 x input_price
  + output_tokens / 1,000,000 x output_price
  + cache-hit, cache-miss, request, or other billed classes
```

Reconstructed dedicated relationship:

```text
infrastructure cost
  ~= sum(instance_count_i x active_hours_i x hourly_price_i)
     + storage + network/egress + supporting systems

total cost of ownership
  = infrastructure cost + engineering build/maintenance cost
```

The original figures were missing. Do not present these as verbatim book formulas.

### Similarity

```text
cosine_similarity(a, b) = (a · b) / (||a|| ||b||)
```

The source asks for at least 99 percent similarity after embedding quantization, alongside retrieval evals. It is a heuristic, not a universal threshold.

### Pipeline network example

```text
5 x (50 ms inter-cluster - 10 ms intra-cluster) = 200 ms
```

The source uses five boundaries. A five-stage pipeline may have four. Count the actual call graph.

## Core glossary

### Product, model, and data

Agent: application that takes actions through tools and often makes several model calls. Budget the full chain.

AI-native application: product whose primary behavior depends on generative models. Its task, media, traffic, economics, and SLO determine serving.

API: structured request and response interface to a service.

Generative AI: models that create text, code, images, audio, video, or other content.

Machine learning: broader predictive and representation-learning methods, including classification and forecasting as well as generative systems.

Foundation model: broadly pretrained model used directly or adapted.

Open-weight model: model with downloadable weights. The license may impose restrictions.

Closed model: model with unavailable weights, usually consumed through a product or API.

Shared inference: pooled provider service billed by use.

Dedicated inference: reserved or owned capacity for a deployment.

Fine-tuning: updates a pretrained model for a task or domain.

Distillation: trains a smaller student on a teacher's probability distribution, transferring behavior and errors.

Pretraining: broad large-scale training that creates a base checkpoint.

Inference: model execution to produce outputs, especially as a service.

Online inference: work with a waiting user and tight tail latency.

Offline inference: asynchronous batch work optimized for completion deadline, throughput, and cost.

Local or edge inference: execution on the user's device.

RAG: retrieves context and adds it to generation.

Eval: systematic quality test. Product evals mirror real tasks.

Intelligence benchmark: broad correctness test such as MMLU.

Elo: pairwise preference score. It is directional, not a complete product measure.

Goodhart's Law: once a metric becomes a direct target, it often stops representing the original goal.

Structured output: generation constrained token by token to a schema.

Tool calling: model selection of a supplied function and structured arguments.

LoRA: low-rank weight adaptation that can be swapped onto a base model.

### Transformer and language mechanics

Transformer: sequence architecture built around attention.

LLM: text-generating language model.

GPT: generative pretrained transformer family name associated with OpenAI and often used informally for similar models.

Causal language model: decoder that predicts the next token using only earlier context.

Encoder: maps raw input into an internal representation.

Decoder: emits output from an internal representation.

Hidden state: intermediate layer representation.

Activation: nonlinear function such as ReLU, SiLU, Swish, or SwiGLU.

Attention: query, key, value computation that relates sequence elements.

Attention head: one parallel attention calculation inside a layer.

Cross-attention: queries from one sequence attend to keys and values from another.

Softmax: normalizes scores into probabilities.

RoPE: rotary positional encoding. It can extend context behavior but does not remove cache or attention cost.

Input sequence, ISL: tokens processed during prefill and their count.

Output sequence, OSL: generated tokens and their count.

Context window: maximum combined input, reasoning, and output token budget.

Chat template: model-specific role and separator serialization.

Token: integer ID for a text chunk or another learned unit. The source gives about four English tokens per three words.

Tokenizer: deterministic mapping between raw text and token IDs.

Vocabulary: complete token set, often over 100,000 entries in the source snapshot.

Logit: unnormalized score for a vocabulary token.

Sampling: token selection from logits through greedy, temperature, top-k, top-p, or constraints.

Temperature: controls distribution sharpness. Source examples are 0.1 for low variation and 1.5 for higher variation.

Logit bias: adjustment or blocking of token scores before selection.

Autoregressive generation: emits one token repeatedly from prior context.

Prefill: usually compute-bound processing of input that creates KV state.

Decode: usually bandwidth-bound token generation, one token per ordinary pass.

KV cache: stored attention keys and values for earlier tokens.

Prefix caching: cross-request reuse of exact initial token-state blocks.

Chunked prefill: schedules a long input in chunks so it does not monopolize the engine.

PagedAttention: page-based KV allocation that reduces fragmentation.

FlashAttention, commonly abbreviated FA: fused, tiled attention implementations that reduce high-bandwidth-memory traffic. FA2, FA3, and FA4 refer to FlashAttention 2, 3, and 4.

Feed-forward network, FFN or MLP: transformer sublayer built mainly from linear transforms and nonlinear activation.

Language-model head, LM head or `LMHead`: final projection from hidden state to vocabulary logits.

Multi-latent attention, MLA: attention method that works through a lower-dimensional latent representation.

Mixture of Experts, MoE: sparse feed-forward architecture that routes each token to selected experts.

### Media and speech

Vision-language model, VLM: consumes text plus image or video and emits text.

Omni model: accepts and produces several media types.

Embedding model: maps input to a fixed-size semantic vector.

Vector similarity: closeness measure such as cosine similarity.

Vector database: stores and searches embedding vectors.

Matryoshka representation: embedding organized so a truncated prefix retains useful information.

ASR: speech-to-text system.

Voice activity detection, VAD: lightweight detection and segmentation of speech intervals.

Diarization: identifies speaker intervals using segmentation, embeddings, and clustering.

Neural audio codec: encodes audio as tokens and decodes tokens to waveform.

SNAC: source-named fast audio decoder used with TTS token streams.

Iterative denoising: repeated refinement of latent noise into media.

Latent space: compressed representation used by image and video denoisers.

VAE: encodes pixels to latent state in training workflows and decodes latent state to pixels in inference.

Classifier-free guidance: combines prompt-conditioned and unconditioned denoiser passes.

Few-step image model: system producing output in eight or fewer denoising steps, trading quality for speed.

Latent consistency: predicts a target latent directly and may refine it two to four times.

ControlNet: auxiliary image control using structure such as edges or shape.

ComfyUI: graph-style image pipeline builder.

### GPU execution

GPU: massively parallel processor used for model training and inference.

CPU: general-purpose processor used for preprocessing, scheduling, networking, and orchestration.

CUDA: NVIDIA's GPU programming platform.

CUDA driver: low-level interface for hardware, memory, and execution.

CUDA runtime: developer API for launch and memory operations.

CUDA kernel: function executed in parallel on a GPU. It differs from the Linux kernel.

CUDA graph: captured repeated DAG of GPU work.

Thread: smallest scheduled GPU work unit in this simplified account.

Streaming multiprocessor, SM: GPU block containing compute units and local cache.

CUDA Core: scalar arithmetic unit.

Tensor Core: mixed-precision matrix multiply-accumulate unit.

Matrix multiply-accumulate, MMA: the core operation that multiplies matrices and accumulates into an output.

Special Function Unit, SFU: hardware for functions such as trigonometry and logarithms.

VRAM: GPU device memory for weights, cache, activations, and buffers.

HBM: high-bandwidth DRAM used as datacenter VRAM.

Bandwidth: bytes or bits moved per second through memory or a link.

FLOPS: floating-point operations per second.

Arithmetic intensity: operations per byte moved.

Machine balance, also called the ops:byte ratio in the source: peak operations per byte of peak memory bandwidth.

Roofline model: compute and bandwidth ceiling model using arithmetic intensity.

Compute-bound: limited primarily by arithmetic throughput.

Bandwidth-bound: limited primarily by data movement.

Capacity-bound: unable to fit required state or concurrency in memory.

Communication-bound: limited by inter-device or inter-node exchange.

BLAS: standard linear-algebra operations.

Matmul: matrix multiplication.

GEMM: general matrix-matrix multiplication.

cuBLAS: NVIDIA CUDA BLAS library.

cuDNN: NVIDIA neural-network primitives.

CUTLASS: NVIDIA C++ kernel templates.

CuTe: tiled tensor template DSL.

DeepGEMM: DeepSeek FP8 GEMM library.

FlashInfer: optimized LLM inference kernels.

Kernel fusion: combines operations to remove intermediate memory traffic and launches.

PyTorch Profiler: operator-level CPU, GPU, and memory profiler.

NSys: NVIDIA Nsight Systems full-system trace tool.

NCU: NVIDIA Nsight Compute kernel profiler.

`torch.compile`: PyTorch graph capture, kernel selection, and fusion path.

OOM: out-of-memory failure during load or execution.

### Precision

Floating-point format: sign, exponent, and mantissa representation such as FP16, FP8, or FP4.

Integer format: fixed-width integer such as INT8 or INT4 with less dynamic range at equal width.

BF16: 16-bit float with wider exponent range than FP16.

Dynamic range: smallest-to-largest magnitude span represented.

Quantization: lower precision for weights, activations, cache, or selected operations.

Weights-only quantization: reduces linear weights while keeping other state native. Usually lower risk and lower gain.

Quantization-aware training, QAT: training under target scales and precision.

Post-training quantization, PTQ: converting a complete checkpoint using calibration.

Scale factor: multiplier mapping low-precision values to a useful range.

Microscaling: local block scales such as MXFP8, MXFP4, and NVFP4. Source MX block size is 32 values.

NVFP4: NVIDIA FP4 with block size 16 and an added global scale.

### Parallelism and topology

Model parallelism: divides one model request across devices.

Tensor Parallelism, TP: shards operations within every layer and uses frequent all-reduce.

Expert Parallelism, EP: places complete MoE experts on devices and routes tokens.

Pipeline Parallelism, PP: assigns sequential layer groups to stages.

Context Parallelism, CP: replicates weights and divides sequence or latent attention context.

Ring attention: CP method that circulates partial attention results.

GPU node: commonly an eight-GPU chassis linked through NVLink and NVSwitch.

Multi-node inference: one replica crosses nodes, normally through InfiniBand or a provider fabric.

NVLink: direct high-bandwidth NVIDIA GPU link.

NVSwitch: all-to-all switching over NVLink in a node.

InfiniBand: high-bandwidth node fabric, still much slower than local VRAM and in-node links.

PCIe GPU: standard card form factor with ordinary host and device links.

SXM GPU: socketed high-power form factor with stronger connectivity in source products.

MIG: hardware partitioning into up to eight memory and seven compute slices on source-listed GPUs.

### Engines and software

Inference engine: runtime implementing scheduling, batching, cache, quantization, speculation, and parallelism.

vLLM: broad model and hardware engine with strong defaults.

SGLang: modular engine with source-era MoE and diffusion focus.

TensorRT: NVIDIA optimized inference runtime.

TensorRT-LLM: NVIDIA LLM engine with TensorRT V0 and PyTorch-based V1 lines in the source.

Triton Inference Server: NVIDIA production server with several backends.

NVIDIA Dynamo: distributed engine orchestrator for cache routing, disaggregation, and multi-node work.

NIM: NVIDIA prebuilt inference container.

ONNX: portable weight and execution-graph representation.

Safetensors: non-executable memory-mappable tensor file format.

Transformers and Diffusers: Hugging Face reference libraries.

Docker: container image and runtime ecosystem.

### Serving and operations

Batch: work processed together.

Dynamic batching: starts when full or timeout expires.

Continuous or in-flight batching: admits and interleaves LLM sequences at token granularity.

Cache-aware routing: chooses a replica by KV or LoRA locality as well as load.

Disaggregation: separate prefill and decode worker pools.

Speculative decoding: drafts tokens and verifies them with the target.

EAGLE: learned auxiliary draft network using target hidden states.

Medusa: added decoder heads that propose future tokens.

N-gram speculation: prompt-derived suffix proposals, strong for code.

Lookahead Decoding: creates n-gram candidates online.

Instance: cloud allocation with GPU, CPU, RAM, storage, network, and interconnect.

Autoscaling: adjusts replicas to traffic and resource pressure.

Cold start: procurement through first successful representative response.

Queue: holds work while replicas are saturated or starting.

Scale to zero: removes every replica during idle periods.

Load test: high-volume synthetic or replayed test of latency, throughput, queueing, and scaling.

Jitter traffic: randomized arrivals and request shapes.

Shadow traffic: copied production requests sent to a candidate without serving its output.

Baseline: unchanged quality and performance reference.

Blue-green: duplicate full environment and one-step cutover.

Canary: incremental live traffic ramp with rollback.

SLA: contractual service promise.

SLO: internal service target.

Hyperscaler: broad cloud provider.

Neocloud: GPU-specialist cloud provider.

Multi-cloud control plane: global placement and scaling coordinator.

Workload plane: regional serving cluster.

Active-active: several sites serve concurrently.

Active-passive: hot standby takes traffic after cutover.

Data sovereignty: legal restriction on processing or storage location.

WebSocket: bidirectional connection suited to real-time unstructured chunks.

gRPC: schema-first bidirectional RPC suited to service calls.

### Metrics

Throughput: aggregate work per unit time, such as total tokens per second or jobs per hour.

TTFB: elapsed time to the first response byte, often used for audio.

TTFT: elapsed time to the first generated text token.

ITL: time between generated tokens.

Perceived TPS: one user's streamed output rate, equal to the inverse of ITL.

Total TPS: all tokens emitted by the service per second.

Latency percentile: distribution point such as P50, P90, P95, or P99. P99 leaves one request in one hundred slower.

Real-time factor, RTF: speech speed ratio whose direction varies by source. State the numerator.

## NVIDIA product glossary snapshot

All items below are vendor-specific and time-sensitive.

- Ampere: source-era older architecture including A100.
- Ada Lovelace: graphics-oriented generation including L4 and L40, without NVLink in source products.
- Hopper: H100 and H200 generation with FP8 and asynchronous programming.
- Blackwell: B200 and B300 generation with FP4 and microscaling.
- Rubin: announced 2026 generation with HBM4 and CPX.
- Feynman: announced post-Rubin generation with few public details.
- B200: source says 192 GB, 8 TB/s, and about 5 PFLOPS FP8.
- B300: source says 288 GB, 8 TB/s, and about 5 PFLOPS FP8.
- Grace: ARM CPU linked to Hopper or Blackwell GPU through NVLink C2C.
- Vera: announced Grace successor.
- GH200: Grace CPU and H200 GPU.
- GB200: Grace CPU and B200 GPU.
- NVL72: source rack with 72 GPUs and 36 CPUs.

Verify exact directionality, aggregation, SKU, software support, and inventory.

## Further reading

### Books

- Chip Huyen, *AI Engineering: Building Applications with Foundation Models*, 2025.
- Sebastian Raschka, *Build a Large Language Model From Scratch*, 2024.
- Chris Fregly, *AI Systems Performance Engineering*, 2025.
- Goodfellow, Bengio, and Courville, *Deep Learning*, 2016.
- Francois Chollet, *Deep Learning with Python*, second edition, 2021.
- Kleppmann, *Designing Data-Intensive Applications*, 2017.
- Beyer et al., *Site Reliability Engineering*, 2017.
- Hwu, Kirk, and El Hajj, *Programming Massively Parallel Processors*, 2022.
- Sanders and Kandrot, *CUDA by Example*, source lists 2025.

### Architecture and modalities

- Vaswani et al., "Attention Is All You Need," 2017.
- Devlin et al., BERT, 2019.
- Dao et al., FlashAttention, 2022; Dao, FlashAttention-2, 2023; Shah et al., FlashAttention-3, 2024; FlashAttention-4 repository, source lists 2025.
- Ho et al., "Denoising Diffusion Probabilistic Models," 2020.
- Peebles and Xie, DiT, 2022.
- Ho et al., Imagen Video, 2022; Ho et al., Video Diffusion Models, 2022.
- Brown et al., "Language Models Are Few-Shot Learners," 2020.
- Rombach et al., latent diffusion, 2021.
- Podell et al., SDXL, 2023.
- Zhang et al., ControlNet, 2023.
- Radford et al., CLIP, 2021; Radford et al., Whisper, 2022.
- Li et al., BLIP-2, 2023; Liu et al., Visual Instruction Tuning, 2023.
- Reimers and Gurevych, Sentence-BERT, 2019.
- Kusupati et al., Matryoshka Representation Learning, 2022.
- Shazeer et al., sparse MoE, 2017.
- Beltagy et al., Longformer, 2020; Kitaev et al., Reformer, 2020.
- Su et al., RoFormer, 2021; Press, Smith, and Lewis, ALiBi, 2021.
- Gu and Dao, Mamba, 2023.
- Kirillov et al., Segment Anything, 2023.
- Grattafiori et al., Llama 3, 2024.

### Optimization research

- Leviathan et al., speculative decoding, 2022.
- Cai et al., Medusa, 2024.
- Li et al., EAGLE, 2024; EAGLE-2, 2024; EAGLE-3, 2025.
- Fu et al., Lookahead Decoding, 2024.
- Kwon et al., PagedAttention, 2023.
- Yao et al., CacheBlend, 2024; LMCache; Cache-DIT.
- Mitra et al., pragmatic inference disaggregation, 2025.
- Lin et al., Ring Attention, 2023.
- Zhang et al., SageAttention, 2024.
- Ye et al., FlashInfer, 2025.
- Frantar, GPTQ, 2022; Dettmers et al., LLM.int8, 2022; SmoothQuant; Han, AWQ; Frantar and Alistarh, SparseGPT, 2023.
- Sauer et al., Adversarial Diffusion Distillation, 2023.
- Luo, latent consistency models, 2023.
- TeaCache and Cache-DIT for diffusion caching.
- NVIDIA Megatron-LM material for sequence and Context Parallelism.
- Shoeybi et al., Megatron-LM, 2019.
- Huang et al., SpecVLM, source lists 2025.

The source's TeaCache citation title appears mismatched with the project's diffusion caching role. Verify title and URL.

### Evaluation

- MMLU, Hendrycks et al., 2021.
- SWE-bench, Jimenez et al., 2024.
- HumanEval, OpenAI repository, 2021.
- GSM8K, Cobbe and Kosaraju, 2021.
- MTEB, Muennighoff et al., 2022.
- Humanity's Last Exam, Phan et al., 2025.
- ARC AGI Prize, source lists 2025.
- Shankar and Husain, *Evals for AI Engineers*, source lists forthcoming 2026.
- Schoeninger, Qwen3 fine-tuning article, 2025.

Use these to shortlist or supplement. Product evals remain the decision criterion.

### Tools and official references

Check current releases and maintainership:

- NVIDIA CUDA C++ Programming Guide and cuBLAS documentation.
- CUTLASS, CuTe, DeepGEMM, FlashInfer.
- NVIDIA Nsight Systems and Nsight Compute.
- PyTorch Performance Tuning Guide and Profiler recipe.
- vLLM, SGLang, TensorRT, TensorRT-LLM, and NVIDIA Dynamo.
- NVIDIA Triton Inference Server.
- Hugging Face Transformers and Diffusers.
- ONNX Runtime.
- BitsAndBytes.
- ComfyUI.
- LMCache.
- Kubernetes documentation.
- NVIDIA H100, Blackwell, and older Tesla architecture papers.
- NVIDIA Grace Hopper, Grace Blackwell, NVLink, NVSwitch, and InfiniBand documentation.
- Modal GPU Glossary.
- SemiAnalysis for independent industry analysis, checked against primary sources.

Vendor documentation is primary for specifications. It does not replace workload benchmarks or independent cost analysis.

### Open-model organizations in the source

DeepSeek, Black Forest Labs FLUX, Google Gemma, Z.ai GLM, OpenAI GPT OSS, Moonshot Kimi, Meta Llama, MiniMax, Mistral, NVIDIA Nemotron, Canopy Labs Orpheus, Alibaba Qwen, Wan, and OpenAI Whisper.

This list is a January 2026 snapshot. Check each exact model's license, weights, model card, and current engine support.

## Source and extraction cautions

- The source is *Inference Engineering* by Philip Kiely, Baseten Books, 2026, completed in January 2026.
- Figures were missing from extracted text. Linear, attention, roofline, capacity, and cost equations marked reconstructed above use surrounding prose and standard notation.
- The source attention arithmetic-intensity example reports 62 FLOPs/byte with full `N x d` queries but calls it decode. Cached one-token decode normally has one query position. Do not reuse its operation count as a validated decode derivation.
- The source phrase that LLMs generate tokens in a single forward pass conflicts with its correct one-token-per-ordinary-pass explanation. Interpret it as one token per pass.
- `128 x 128` latent versus `1024 x 1024` pixels is 1.56 percent by positions and omits channels.
- "Gated attention" lacks enough detail to identify an implementation.
- Rules such as MoE above 100B, dense below 32B, 30 to 50 diffusion steps, guidance near 4, disaggregation above 100M to 1B tokens/day and 100B parameters, 200 ms ASR, 150 ms TTS, 30 to 40 percent video caching, and 70 to 80 percent video attention are starting points.
- Claims about open versus closed model parity, more than two million Hugging Face models, 80 percent cost savings, and 99 versus 99.99 percent availability lack methodology in the extract.
- Engine and hardware claims are January 2026 snapshots. Verify official documentation and actual inventory before implementation or procurement.
- Baseten's closing chapter and blog recommendation are affiliated with the author's employer. Treat claims as vendor marketing unless independently measured.
