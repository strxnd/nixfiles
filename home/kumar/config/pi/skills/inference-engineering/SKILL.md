---
name: inference-engineering
description: Plan, benchmark, diagnose, optimize, deploy, and operate production inference for LLMs, VLMs, embeddings, ASR, TTS, image generation, and video generation. Use for workload and SLO definition, model and accelerator selection, engine comparison, profiling, quantization, speculative decoding, caching, parallelism, prefill-decode disaggregation, autoscaling, reliability, security, cost analysis, client protocols, or inference incidents.
metadata:
  source: "Inference Engineering by Philip Kiely, Baseten Books, 2026"
  version: "1.1.0"
---

# Inference engineering

## Source and scope

This skill combines both local inference-engineering skill syntheses built from *Inference Engineering* by Philip Kiely, Baseten Books, 2026.

| Metadata | Value |
|---|---|
| Source work | *Inference Engineering* |
| Author | Philip Kiely |
| Publisher and year | Baseten Books, 2026 |
| Source completion | January 2026 |
| Coverage | Preface, chapters 0 through 7, appendices A and B |
| Synthesis basis | Four complete chapter-group digests plus the prior local inference-engineering skill |
| Extraction limit | Several figure equations and diagrams were absent and are marked when reconstructed |

Treat model availability, engine support, accelerator specifications, prices, performance rankings, project maturity, and vendor roadmaps as January 2026 snapshots. Before implementation or procurement, check current official documentation, release notes, compatibility matrices, licenses, cloud inventory, delivered topology, and workload benchmarks. Tables that report vendor products or software comparisons preserve source-era claims for planning, not endorsements. Baseten and NVIDIA product claims are vendor-specific unless independently measured.

Some source equations were reconstructed because figures were absent from the text extraction. The references mark those cases and known inconsistencies. Do not quote a reconstructed formula as verbatim book text.

## How to use this skill

1. Read this file first.
2. Load only the references needed for the task.
3. Ask for missing workload facts one question at a time. Do not send a questionnaire unless the user asks for one.
4. State assumptions when evidence is unavailable. Separate measurements, estimates, source-era claims, and vendor claims.
5. Prefer the simplest system that meets the measured quality, latency, throughput, reliability, compliance, and cost limits.

## Reference map

- [Foundations and models](references/foundations-and-models.md): product constraints, shared versus dedicated service, model selection, evals, fine-tuning, distillation, transformer and diffusion mechanics, attention, MoE, and roofline diagnosis.
- [Measurement and benchmarking](references/measurement-and-benchmarking.md): metric definitions, workload capture, load tests, profiling, experimental design, quality checks, and benchmark reports.
- [Hardware](references/hardware.md): GPU compute, memory, topology, NVIDIA source snapshots, alternative accelerators, MIG, instance selection, and local inference.
- [Software and engines](references/software-and-engines.md): CUDA, kernels, PyTorch, formats, runtimes, vLLM, SGLang, TensorRT-LLM, Dynamo, and selection rules.
- [Optimization techniques](references/optimization-techniques.md): quantization, speculation, prefix and tiered caching, long context, parallelism, and prefill-decode disaggregation.
- [Modalities](references/modalities.md): VLM, embedding, ASR, diarization, TTS, speech-to-speech, image, and video serving.
- [Production operations](references/production-operations.md): packaging, autoscaling, queues, routing, multi-cloud, reliability, security, testing, rollout, cost, observability, incidents, and clients.
- [Glossary, formulas, and reading](references/glossary-formulas-and-reading.md): compact definitions, formula sheet, source caveats, and further reading.

All links are one level below this file. Do not infer current support from these references. Verify it.

## Non-negotiable principles

- Start with the product task and its hard constraints. Then select the smallest model that passes product evals. Only then tune serving.
- Keep a capable shared API until a measured scale, specialization, uptime, or orchestration need justifies dedicated inference.
- Optimize end-to-end user experience, not a kernel or one headline metric. Report inference-only and client-to-result measurements separately.
- Distinguish per-user decode rate from fleet throughput. Label `TPS` as perceived TPS or total TPS.
- Report distributions and tails. At minimum include a central percentile and P90 or P99 where the SLO requires it.
- Treat prefill as probably compute-bound, low-to-medium-batch decode as probably memory-bandwidth-bound, and image or video denoising as probably compute-bound. Profile before acting.
- Preserve quality. Quantization and approximate algorithms require baseline and product evals. Correct speculative verification should preserve the target distribution.
- Change one variable at a time, then benchmark the final combination. Optimizations interact and gains are not additive.
- Size memory for weights, buffers, activations, and useful cache headroom. A model that barely loads is not deployable.
- Match parallelism to physical links. Keep communication-heavy collectives inside a high-bandwidth node when possible.
- Separate online and offline pools, or independently scale pipeline stages, when their latency and batching needs conflict.
- Include idle capacity, failover, canaries, storage, transfer, support systems, engineering, and on-call work in total cost.
- Treat compliance and data residency as placement and routing constraints. A provider certificate does not make the full application compliant.
- Use current official sources before buying hardware or committing to an engine. Benchmark the exact model, precision, instance, topology, software versions, and traffic shape.

## End-to-end workflow

### 1. Frame the product decision

Record the task, useful-output milestone, quality threshold, online or offline class, streaming behavior, request schema, context and output limits, latency percentiles, throughput, availability, regions, privacy, compliance, and business cost unit. Include the entire agent or media pipeline, retries, retrieval, transport, and fan-out.

If facts are missing, ask the single question whose answer most changes the design. Continue one question at a time. Use the worksheet in [foundations and models](references/foundations-and-models.md).

### 2. Characterize real traffic

Capture ISL, OSL, media dimensions or duration, concurrency, arrival jitter, daily and weekly cycles, cacheable-prefix fraction, cache-hit tier, LoRA mix, sampling settings, output schema, and client protocol. Record average and tail values. Split interactive and backfill demand.

Prefer privacy-reviewed shadow traffic. Otherwise build a synthetic distribution that reproduces content, sequence shape, arrivals, parameters, and cache behavior.

### 3. Establish model quality

Shortlist with public benchmarks, architecture support, license, and current availability. Run product hard cases and inspect outputs. Select the smallest model that clears the threshold. Test fine-tuning before accepting a much larger general model for a narrow task. Lock model version, tokenizer, chat template, decoding settings, seeds where applicable, and eval baseline.

### 4. Set a baseline

Pin model, weights, precision, engine, container, CUDA stack, GPU SKU, count, topology, client, and traffic generator. Warm the service consistently. Measure quality, TTFT or modality-specific first-useful-output latency, ITL, perceived TPS, completion latency, aggregate throughput, queueing, errors, resource use, memory, and cold-start stages at relevant percentiles.

### 5. Locate the bottleneck

Split client, DNS and connection, upload, routing, queue, preprocessing, prefill or encoder, decode or denoising, postprocessing, and response transfer. Use engine telemetry first. Use PyTorch Profiler for operations, NSys for full CPU/GPU and interconnect timelines, and NCU for one kernel only when configuration-level evidence is insufficient.

Classify the limit as compute, memory bandwidth, memory capacity, communication, host, storage, network, queueing, cold start, or downstream pipeline work. Reclassify after each change.

### 6. Choose hardware and engine

Compare achieved performance at the deployed precision, not unmatched peak claims. Check full instance resources and links. Test at least the easiest viable engine and the likely performance leader. Verify exact architecture, quantization, kernel, modality, structured-output, parallelism, and disaggregation support in current official docs.

### 7. Optimize in measured order

Use the optimization order below. Stop when the service meets its objectives with safety margin. A simpler configuration is easier to reproduce and operate.

### 8. Validate interactions and failure behavior

Run each change against the fixed baseline, then test the combined candidate. Include long uncached inputs, short cached inputs, realistic concurrency, jitter, cold and warm paths, autoscaling, OOM pressure, cancellation, node loss, region loss, and provider loss as applicable. Rerun quality evals after every numerical or behavioral change.

### 9. Package and release

Pin image digest and dependencies. Keep large weights near GPUs. Cache compiled artifacts by exact hardware and software environment. Define readiness as the first successful representative response. Use a pre-scaled canary with automatic rollback thresholds for quality, errors, tails, queueing, and resource pressure.

### 10. Operate and revisit economics

Correlate application traces, inference metrics, logs, audit changes, queue state, scaler behavior, and hardware health. Review API versus dedicated TCO over at least one week and several demand cycles. Revisit model, hardware, engine, and reserved-capacity choices when traffic or official support changes.

## Fast bottleneck map

| Symptom | Likely area | First checks | First experiments |
|---|---|---|---|
| High TTFT, long uncached input | Prefill compute or queue | Post-cache ISL, queue time, GPU compute, attention | Prefix layout, FP8, chunked prefill, attention kernel, then conditional disaggregation at scale |
| High TTFT, repeated input | Cache miss or bad routing | Token-level hit rate, first divergence, cache tier, replica locality | Canonicalize stable prefix, cache-aware routing, larger or tiered cache |
| Good engine time, poor end-to-end time | Infrastructure or client | DNS/TLS, connection reuse, queue, routing, upload, downstream work | Reuse sessions, move service, fix queue or pipeline before kernels |
| Low per-user TPS, low-to-medium batch | Decode bandwidth | ITL, VRAM bandwidth, bytes per token, KV size | FP8 weights or KV, fusion, speculation, TP for a large model |
| Low per-user TPS, high batch | Compute saturation | Batch, GPU compute, speculation verification cost | Reduce batch for latency, disable speculation dynamically, add replicas |
| Low fleet throughput, acceptable latency | Underbatching or poor utilization | Active sequences, GPU utilization, queue pattern | Continuous batching, larger batch, horizontal replicas, EP for MoE |
| OOM after startup | Runtime state | ISL/OSL tails, concurrency, KV occupancy, fragmentation | Lower batch or context, PagedAttention, KV quantization/offload, more VRAM |
| Multi-GPU scaling stalls | Communication | Collective time, topology, NVLink versus node boundary | Keep TP inside node, use EP or PP across nodes, compare replicas |
| Image generation slow | Denoiser compute | Pass count, attention, GEMM, resolution | Better attention kernel, fusion, FP8 GEMM, fewer steps, late guidance cutoff |
| Video generation slow | Attention compute | Attention share, latent size, cache quality, links | Context parallelism, tuned attention, selective precision, timestep or transformer cache |
| ASR stream feels slow | Orchestration or decoder | Chunk latency, VAD, WebSocket path, affinity | Persistent stream, VAD tuning, decoder engine, MIG concurrency |
| TTS starts late | Token model or audio decoder | TTFB, first sentence, decoder queue | FP8 token model, compiled decoder, short dynamic batch, WebSocket |
| Queue grows during spikes | Scaling or cold start | target concurrency, quota, startup stages, registration | Traffic plus utilization scaler, warm capacity, local weights, immediate dispatch |
| One replica is hot | Work-aware routing | ISL, cache and LoRA affinity, stale load state | Route by estimated work and locality, not request count |

## Optimization order

1. Remove avoidable product work. Shorten prompts, outputs, media size, frame rate, steps, and pipeline calls without missing quality goals.
2. Choose a smaller or task-tuned model that still passes evals.
3. Use exact prefix reuse, continuous batching, correct scheduling, connection reuse, and co-location. These are often larger wins than custom kernels.
4. Select a current production engine and lossless kernels for the exact architecture and accelerator.
5. Tune batch, concurrency, cache allocation, and autoscaling against tail latency.
6. Apply FP8 or another conservative quantization plan with calibration and quality gates.
7. Add workload-specific methods such as speculation, guidance cutoff, media downsampling, or diffusion caching.
8. Add GPUs with topology-aware TP, EP, PP, or CP only when one-device execution or latency requires it.
9. Add cache tiers, non-prefix reuse, or host offload when measured locality and transfer times justify them.
10. Add prefill-decode disaggregation and global multi-cloud scheduling only at a scale that keeps specialized pools useful.
11. Write or port custom kernels only for a measured hot operation that mature engines do not solve.

## Experiment and quality guardrails

- Preserve an immutable baseline artifact and report exact versions.
- Define pass/fail thresholds before looking at candidate results.
- Use enough requests for stable tails. Repeat noisy runs and report variation.
- Hold traffic and client configuration fixed. Change one system variable at a time.
- Warm compiled graphs and kernels for steady-state tests. Measure cold start separately.
- Sweep concurrency and batch size. One operating point cannot show the latency-throughput frontier.
- Test the final combination because batching, speculation, caching, quantization, and parallelism interact.
- Compare original and changed output on product evals. Add perplexity and public benchmarks for LLM quantization, cosine similarity plus retrieval evals for embeddings, word or task accuracy for ASR, audio quality for TTS, and human pairwise preference or strong task checks for images and video.
- Treat a quantization delta as acceptable only when it is inside ordinary eval noise and no product slice regresses. Restore precision if uncertain.
- Inspect media over time. Single frames cannot validate video motion or temporal consistency.
- Reject a kernel win that does not improve user-visible latency, throughput, reliability, or cost.
- Record failed trials. Negative results prevent repeated work.

## Structured output contract

For a plan, benchmark, diagnosis, design review, or incident analysis, produce these sections. Omit a section only when it plainly does not apply.

1. **Decision and scope**
   - Requested outcome, recommendation, and what remains undecided.
2. **Known workload facts**
   - Model and modality, quality bar, ISL/OSL or media distributions, arrivals, concurrency, streaming, cache and LoRA behavior, SLA/SLO, regions, compliance, and cost unit.
   - Assumptions and the next single question if a blocking fact is missing.
3. **Baseline and evidence**
   - Exact model, precision, engine, image, hardware, topology, client, dataset, traffic shape, warm or cold state, measurements, and confidence.
   - Label source-era claims, current vendor claims, measurements, and estimates separately.
4. **Bottleneck diagnosis**
   - Time and resource breakdown, likely saturated resource, evidence, and competing explanations.
5. **Options**
   - For each option, expected mechanism, quality risk, latency and throughput effect, memory and topology needs, engineering cost, operational risk, and rejection criterion.
6. **Recommended experiment plan**
   - Baseline, one changed variable, matrix or sweep, metrics, quality gates, sample size, failure tests, and rollback rule.
7. **Capacity and cost**
   - Memory sizing, replica or parallel layout, utilization assumptions, headroom, failover, one-week or longer TCO, and sensitivity cases.
8. **Production plan**
   - Packaging, readiness, scaling, queueing, routing, canary, observability, incident response, security, residency, and client protocol.
9. **Verification required**
   - Current official docs, licenses, inventory, quotas, prices, compatibility, and benchmark items to verify before commitment.
10. **Result table**
   - Baseline versus candidates, including quality, TTFT or first-useful output, ITL or generation time, end-to-end percentiles, throughput, errors, memory, utilization, and cost.
