# Measurement and benchmarking

## Measurement starts with the service objective

A benchmark is useful only when its workload and metrics predict production behavior. Lock the quality bar and product constraints before comparing engines or optimizations.

Separate:

- Latency seen by one request.
- Aggregate service throughput.
- Quality.
- Cost and utilization.
- Reliability under load and failure.

Higher batching can raise throughput and lower unit cost while worsening queueing and user latency. Quantization can improve all performance dimensions while lowering quality. Report the trade, not one winning number.

## Core latency and throughput metrics

### Text generation

Time to first token, TTFT, is elapsed time until the first streamed output token reaches the observer. Prefill is usually its largest model-runtime component.

Inter-token latency, ITL, is the time between consecutive output tokens. Perceived TPS is the output-token rate seen by one user after the first token:

```text
perceived TPS = 1 / ITL_seconds
              = 1000 / ITL_milliseconds
```

Examples:

```text
10 ms ITL = 100 perceived TPS
2 ms ITL  = 500 perceived TPS
```

Total TPS is all output tokens completed per second by the service. It is throughput, not responsiveness. Never report unqualified `TPS`.

A streamed first token is useful for chat, but not necessarily for tool calls, structured responses, or completions that need a whole chunk. Measure total response latency when output has no value until complete.

### Other output types

Choose a useful user-visible milestone:

- VLM text output: TTFT, ITL, completion time, plus media preprocessing.
- Embedding: complete vector latency and vectors or inputs per second.
- ASR stream: transcript chunk latency or conversational round trip.
- Long ASR: audio duration divided by processing time, or its reciprocal, with the convention stated.
- TTS: time to first byte, first word, first sentence or phrase, audio-token TPS, and streams at real-time speed.
- Image: complete image latency, images per hour, pass count, and quality at a named resolution.
- Video: complete clip latency, generated seconds per wall-clock second, jobs per node-hour, and temporal quality.

The book uses ASR `RTF` as a speedup:

```text
source-style RTF = audio duration / processing duration
```

Thus one hour in 30 minutes is `2x`. Many ASR sources define conventional real-time factor as processing duration divided by audio duration, where lower is better. Always name the convention. The source describes one hour in under four seconds as about 1000x. Exactly four seconds is 900x; 1000x needs 3.6 seconds.

### Percentiles

Inference latency is usually right-skewed. Means hide slow requests.

- P50 is the median. Half of requests are slower.
- P90 leaves one in ten slower.
- P95 leaves one in twenty slower.
- P99 leaves one in one hundred slower.

Track a central percentile and the tail required by the SLO. Tune P90 and P99 as reliability metrics. A source example is `P90 TTFT = 350 ms`, which illustrates format, not a target.

### Runtime and end-to-end views

Inference-only latency covers model execution on the accelerator. End-to-end latency also includes client work, DNS, connection setup, TLS, upload, routing, queueing, serialization, preprocessing, startup, postprocessing, and response transfer.

Use both:

- Runtime metrics isolate model and engine work.
- End-to-end metrics represent user experience.
- Good runtime with poor end-to-end results points to infrastructure or client work.

For streaming clients, measure from the user's process. A TLS handshake can take dozens of milliseconds. In a 300 ms P95 budget, it may consume at least 10 percent.

## Quality metrics

Performance work starts with an immutable quality baseline.

### LLM and VLM

- Product-specific task score and hard-case slices.
- Individual output inspection.
- Perplexity for expected text sequences. Higher is worse.
- Relevant public capability tests such as MMLU, SWE-bench, GSM8K, or HumanEval.
- Schema validity, tool-call correctness, stop behavior, and long-context retrieval.
- VLM detail and task accuracy at each tested image resolution or video sampling rate.

### Embeddings

Compare original and changed vectors:

```text
cosine_similarity(a, b) = (a · b) / (||a|| ||b||)
```

The source asks for at least 99 percent similarity after quantization and notes that 100 percent means the same normalized direction. This is a confidence heuristic, not a universal acceptance bar. Also rerun retrieval, ranking, recommendation, or MTEB-like task evals because small vector changes can reorder close results.

### Speech

- ASR word error or product task accuracy.
- Recognition quality with and without previous-chunk context.
- Compression ratio and words per minute to detect repetitive Whisper hallucinations.
- Diarization speaker segmentation and clustering quality.
- TTS voice quality, intelligibility, first-phrase latency, and quality after long generation.

### Images and video

Automated VLM judges are directional and may disagree with people. Human pairwise preference over many outputs is more credible for final decisions. Include prompt adherence, artifacts, faces, hands, text rendering, and image editing as the product requires.

For video, inspect motion, temporal consistency, physics, prompt adherence, and artifacts over the entire clip. A good frame does not validate a video.

## Workload capture

Traffic shadowing is the preferred input when privacy and policy allow it:

```text
copy production request -> candidate deployment
keep original response path unchanged
measure candidate without serving its output
```

Shadow traffic captures real lengths, content, parameters, cache locality, concurrency, and arrivals. Sample it if full duplication is too costly. Record the sample rate and privacy handling.

When shadowing is unavailable, reproduce:

| Dimension | Why it changes results |
|---|---|
| ISL and post-cache ISL | Prefill, TTFT, memory, and disaggregation decisions |
| OSL or media duration | Decode or generation duration and cache growth |
| Concurrency | Batch formation and saturation |
| Arrival pattern and jitter | Queueing, scaler response, and tails |
| Prompt or media content | Prefix hits, speculation acceptance, and preprocessing |
| Temperature and reasoning settings | Output length and speculation behavior |
| Cache-hit rate and tier | Saved prefill versus transfer delay |
| LoRA distribution | Adapter locality and memory movement |
| Protocol and client location | Network and connection overhead |
| Daily and weekly cycles | Minimum capacity and scale-down safety |

Uniform traffic and one fixed sequence length make attractive but misleading charts. Include outliers and long uncached inputs.

## Reproducible benchmark setup

Pin and report:

- Model ID, revision, license, architecture, tokenizer, and chat template.
- Weights, native precision, quantization recipe, calibration data, and KV precision.
- Engine, major version, configuration, container digest, framework, CUDA, cuDNN, driver, and kernel plugins.
- GPU exact SKU and form factor, count, partition, clocks where relevant, node topology, interconnect, host CPU and RAM, storage, and network.
- Parallelism layout, cache allocation, offload tiers, speculation method, and disaggregation ratio.
- Client implementation, location, connection reuse, protocol, timeout, and traffic generator.
- Workload distributions, arrivals, cache state, warm-up, number of requests, repeats, and eval data.

For hardware specifications, state precision, dense or sparse assumption, directionality, per-device or aggregate basis, and bits versus bytes.

## Experiment procedure

1. Define pass/fail criteria before running candidates.
2. Establish a stable baseline.
3. Warm compiled graphs, kernels, caches, and connection pools consistently for steady-state tests.
4. Measure cold start separately from warm service.
5. Send enough requests to stabilize percentile estimates.
6. Repeat runs if noise remains and report spread, not only an average.
7. Hold the generator and workload fixed.
8. Change one server variable at a time.
9. If studying workload sensitivity, change one workload variable at a time.
10. Sweep batch size and concurrency to map the latency-throughput frontier.
11. Test each optimization alone.
12. Test the final combination because interactions are not additive.
13. Rerun quality gates after every numerical or behavioral change.
14. Confirm the result from the client and full service.
15. Record failed experiments and environment details.

Interaction example: speculative decoding uses spare decode compute. Large batches consume that compute. Either can help alone while their combination helps less or hurts.

### Minimum performance report

For text or VLM text output, include:

- TTFT P50/P90/P95/P99.
- ITL P50/P90/P99 and perceived TPS.
- Total completion P50/P90/P99.
- Aggregate input and output TPS.
- Queue time and age.
- 2XX, 4XX, 5XX, cancellation, timeout, and OOM counts.
- CPU, host RAM, GPU compute, VRAM, storage, network, and collective utilization.
- Cache hit rate by tokens and tier.
- Speculation acceptance by candidate position where used.
- Cold-start stage times and first representative response.
- Quality score and critical slices.
- Cost assumptions and measured instance utilization.

Adapt output and quality fields for other modalities.

## Load testing

Useful source-listed tools:

- SGLang Genai-bench for framework-neutral model server benchmarking and dashboards.
- NVIDIA GenAI-Perf for client-side latency and throughput under varied traffic.
- Locust for general load generation and large simulated user counts.

Tool support and behavior change. Verify current versions and methodology.

Load tests should include:

- Steady demand, jittered demand, and bursts.
- Daily and weekly peaks.
- Warm and cold replicas.
- Short cached and long uncached work.
- Representative output lengths and cancellations.
- Autoscaler scale-out and scale-in.
- Queue bounds and overload behavior.
- Quota or capacity exhaustion.
- Node, region, or provider failure when applicable.
- New-replica registration and immediate queue dispatch.
- Streaming connection limits and load-balancer timeouts.

A short test at a quiet hour does not prove production capacity.

## Profiling

Benchmarking says what happened. Profiling attributes time and resources.

Skip deep profiling when a mature engine meets the objective and configuration-level comparisons answer the question. Profile when:

- Building custom PyTorch serving.
- Working on an unsupported or new architecture.
- Contributing to an engine.
- Optimizing a less mature media workload.
- Investigating a regression or unexplained bottleneck.

Tools:

| Tool | Use |
|---|---|
| PyTorch Profiler | CPU/GPU time and memory by operation or step |
| NVIDIA Nsight Systems, NSys | Full CPU/GPU timeline, multi-GPU work, transfers, collectives, and idle gaps |
| NVIDIA Nsight Compute, NCU | Detailed counters for one CUDA kernel |

TensorFlow and TensorRT also have profilers.

Profiling loop:

1. Start from a failed service objective.
2. Attribute queue, host, kernels, memory movement, communication, and idle gaps.
3. Optimize the largest measured cost.
4. For a hot kernel, determine achieved compute, bandwidth, occupancy, launch overhead, and data movement.
5. Select or write a kernel only when evidence supports it.
6. Re-run the end-to-end benchmark.
7. Rerun numerical and product quality checks.

A faster activation kernel that leaves queueing unchanged is not a production win.

## Bottleneck attribution worksheet

### High TTFT

Split:

- Client connection and upload.
- Queue delay.
- Tokenization and media preprocessing.
- Prefix lookup and cache fetch.
- Prefill compute.
- First-byte transfer.

Compare TTFT against post-prefix-cache ISL. Long unique prompts with high GPU compute suggest prefill. Repeated prompts with low cache hits suggest prompt layout or routing. High queue with starting replicas suggests scaling or cold start.

### High ITL or low perceived TPS

Inspect:

- Batch size and active sequences.
- Weight and KV bytes per step.
- Memory bandwidth achieved.
- GPU compute saturation.
- Speculation acceptance and verification cost.
- TP collective time.
- Growing context and cache offload.

Low-to-medium batch and low compute often indicate bandwidth. High batch and high compute indicate that batching or verification moved decode toward compute saturation.

### Low aggregate throughput

Inspect underbatching, continuous scheduler occupancy, queue policy, CPU preprocessing, model copies, MoE expert imbalance, communication, and per-replica concurrency. A low-latency configuration may deliberately sacrifice throughput.

### OOM

Record weights, buffers, activations, KV precision, cache allocation, ISL/OSL tails, concurrent sequences, fragmentation, and offload behavior. Separate load-time OOM from runtime-state growth.

### Multi-GPU inefficiency

Use NSys or collective telemetry. Attribute time to all-reduce, all-to-all, activation transfer, pipeline bubbles, or ring attention. Verify whether traffic crosses NVLink, PCIe, or an inter-node fabric. Test horizontal replicas as the control.

## Quality-preserving experimental rules

Quantization:

- Calibrate PTQ with representative domains and sequence shapes.
- Compare perplexity, relevant public tests, and product evals.
- Keep output-critical layers and sensitive attention at higher precision when needed.
- Accept only deltas inside ordinary run noise for a no-loss target.

Speculation:

- Correct target verification should preserve the target distribution.
- Compare output distributions and exact engine settings.
- Log acceptance by position, domain, and temperature.

Caching:

- Exact prefix caching should preserve output.
- Non-prefix reuse needs positional correction and selective recomputation. Treat it as correctness-sensitive.

Kernels and compilation:

- Compare numerics after fusion, new formats, and plugin changes.
- Compile and benchmark on the production architecture.
- Do not restore an engine built for a different GPU or software stack.

Media shortcuts:

- Evaluate few-step image models, late guidance cutoff, diffusion caching, lower frame rate, downsampling, and attention quantization on representative prompt and content slices.
- Include temporal video checks.

## Benchmark result table template

| Field | Baseline | Candidate | Delta | Pass/fail |
|---|---:|---:|---:|---|
| Quality score and critical slice | | | | |
| TTFT or first-useful output P50 | | | | |
| TTFT or first-useful output P99 | | | | |
| ITL P50/P99 or generation time | | | | |
| End-to-end completion P50/P99 | | | | |
| Aggregate throughput | | | | |
| Queue age P99 | | | | |
| Error/OOM/cancellation rate | | | | |
| GPU compute and VRAM | | | | |
| Network/collective/storage | | | | |
| Cache hit and speculation acceptance | | | | |
| Cold start to representative response | | | | |
| Cost over measured period | | | | |

## Audit checklist

- [ ] The benchmark matches real ISL, OSL, content, media shape, arrivals, cache, LoRA, and protocol.
- [ ] Quality and critical slices are locked before tuning.
- [ ] Model, engine, image, hardware, topology, and client are exact and reproducible.
- [ ] Cold and warm paths are separate.
- [ ] Enough requests support the reported tails.
- [ ] Perceived TPS and total TPS are distinct.
- [ ] Queueing and end-to-end time appear beside engine time.
- [ ] Concurrency and batch are swept.
- [ ] One variable changes at a time, then the final combination is tested.
- [ ] Failures, autoscaling, and overload are included.
- [ ] Cost compares like-for-like quality, SLA, geography, retention, and redundancy.
- [ ] Source-era or vendor claims are not presented as measured results.
