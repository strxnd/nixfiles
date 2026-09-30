# Production operations

## Packaging and containerization

A container is a running isolated application. An image creates it. A Dockerfile is the build recipe. A registry stores images. Containers share the host Linux kernel and are lighter than VMs. Here Linux kernel differs from a CUDA kernel.

Image layers:

1. Base image, often an OS or engine image.
2. Added dependencies, source, and configuration.
3. Thin writable runtime layer that disappears with the container.

Use an official release-matched vLLM, SGLang, or other engine image when practical. Build lower only when exact control is worth the dependency work.

### Dependency rules

Inference images must align:

- GPU architecture and driver compatibility.
- CUDA and cuDNN.
- PyTorch, Transformers, Diffusers, and other Python packages.
- Exact inference engine.
- Linux packages such as `ffmpeg` for media.

Rules:

- Keep runtime images small to reduce build, transfer, and startup time.
- Pin exact package versions and the base image digest.
- Pin or mirror system repositories, build tools, and remote artifacts for stronger reproducibility.
- Resolve constraints with `uv`, Poetry, or `pip`, then test the exact built artifact.
- Expect day-zero model support to use nightlies or prereleases. Move to stable releases when ready.
- Scan image and dependency vulnerabilities.
- Prove rebuilds still work when registries or package indexes change.

Do not bake tens or hundreds of billions of parameters into an image by default. Keep weights separate and physically near GPUs unless measurement supports embedding them.

### NVIDIA NIM snapshot

NVIDIA Inference Microservices, NIMs, are vendor-provided containers for selected open models. The source describes:

- Multi-LLM NIM for a model family and GPU architecture.
- Model-specific NIM tuned for one model, GPU layout, and target.

They can be used unchanged, extended, or inspected. Their cost is less configuration control. This is vendor-specific January 2026 material. Verify supported combinations, licensing, contents, and current behavior.

## Autoscaling

Autoscaling balances SLA against idle GPU spend. Kubernetes commonly separates a control plane from worker nodes and runs one or more model replicas per cluster.

Use both signal classes:

- Utilization, including GPU compute, VRAM, CPU, and host memory. It reflects real work but lags demand.
- Traffic, including request count, concurrency, queued work, tokens, media duration, or open streams. It can lead utilization.

Request count alone is weak. A few 100K-token uncached prompts can cost more than many short cache hits.

Configure:

1. Minimum replicas.
2. Maximum replicas.
3. Rolling autoscaling window.
4. Scale-down delay.
5. Target concurrency per replica.

Longer scale-down delay protects bursts but pays for idle recovery capacity. Shorter delay saves spend but increases cold-start oscillation.

### Concurrency and batching

- Static batching waits for a fixed batch.
- Dynamic batching starts on full batch or timer.
- Continuous or in-flight batching admits LLM sequences token by token.

Larger batches raise total throughput and usually worsen per-user latency. Benchmark exact model, sequence distribution, hardware, cache behavior, engine, and SLO.

The engine maximum concurrency and autoscaler target must agree. Scale out when active replicas reach safe target. Scale in if many replicas launch half-empty work. Do not copy a target from another model.

For WebSocket services, active connection count is also a scaling signal.

### Cold starts

Measure four stages:

1. GPU procurement and assignment.
2. Container image loading.
3. Weight loading.
4. Engine initialization or compilation.

Improve each:

- Measure provider node-start behavior and negotiate a startup-time objective in reserved-capacity or infrastructure contracts when cold-start SLOs depend on it.
- Maintain a warm node pool where justified.
- Strip images.
- Quantize weights when quality allows.
- Store weights in the same datacenter and load at GB/s for very large models.
- Avoid Hugging Face or distant object-store egress on the startup path when it limits bandwidth or adds cost.
- Cache compiled engines.

The source characterizes vLLM and SGLang startup as quick, while TensorRT-LLM and optimized PyTorch may compile for minutes. This is time-sensitive.

Compiled artifacts are environment-specific. Key them by GPU type, CUDA, framework, engine, kernels, and dependencies. Do not restore across a mismatched stack.

Readiness means the first successful representative response, not process start. Include weight paging, compilation, and first-request warm-up.

### Scale to zero

Scale to zero requires:

- Cold start acceptable to the user or scheduler.
- Durable queueing until readiness.

Good fits are development, predictable business-hours tools, and periodic offline jobs. It is poor for unscheduled low-volume interactive work. If scale to zero is required to afford dedicated GPUs for an interactive app, use a pay-per-token API until traffic justifies dedication.

### Independently scale components

Compound systems have stages with different hardware and demand. Scale VAD, ASR, LLM, TTS, OCR, embedding, or VAE stages independently.

Keep tightly coupled stages in one cluster when possible. Source example:

```text
intra-cluster message = 10 ms
inter-cluster message = 50 ms
5 x (50 - 10) ms = 200 ms
```

The source says this consumes 20 percent of a one-second SLA. A five-stage pipeline may have four boundaries rather than five. Validate the call graph.

## Routing, balancing, and queues

A router chooses a destination. A load balancer distributes pressure among valid destinations. Real systems can use several stages.

Equal request counts do not equal equal work. One 10,000-token request can make an otherwise balanced replica hot.

Route with:

- Estimated input and output work.
- Prefix and cache tier locality.
- LoRA residency.
- Queue age and current active work.
- Region, capacity, health, and residency rules.

Cache or adapter locality is valuable only if it beats queue and transfer cost.

### Queue behavior

FIFO is a baseline. Priority queues can protect paid or critical traffic during overload.

Production queues need:

- Bounded depth or wait time.
- Queue age and depth metrics.
- Overload response.
- Cancellation propagation.
- Idempotency and retry policy.
- Priority fairness.
- Durable behavior where jobs outlive clients.

Register ready replicas immediately. Dispatch queued work to new capacity up to its concurrency limit. Do not leave requests on old replicas while new ones idle.

## Multi-cloud and global capacity

Independent clusters are not a global scheduler. A stronger design treats compatible provider and regional pools as one bin-packing inventory.

Benefits:

- More capacity options.
- Regional and provider redundancy.
- Lower client network delay.
- Data-residency placement.

Architecture:

- Global control plane deploys models, consumes events, and makes placement and broad scaling decisions.
- Regional workload planes serve traffic, scale locally, and report state.

A workload plane must continue serving if the global control plane or another plane fails.

### Procurement portfolio

Source provider categories:

- Hyperscalers such as AWS and GCP.
- GPU neoclouds such as CoreWeave and Nebius.
- Resellers such as SF Compute Company.

Names and market position are snapshots.

Purchase modes:

- Reserved capacity for baseline over months or years at discount.
- On-demand for peaks within quota at higher price.
- Spot for interruptible work with short reclaim notice.

A common portfolio covers baseline with reservations and bursts with on-demand or spot. Derive the mix from interruption rate, startup time, queue tolerance, availability, support, quota, region, and cluster size.

Scarce current-generation inventory may require multiple vendors and long contracts. Verify actual quota, node count, topology, start time, reclaim behavior, and SLA.

### Geo-aware routing

Prefer the nearest healthy compliant region with capacity. A queued local request may lose to immediate service nearby, but long-distance routing should not become normal.

The source uses a rough one-way rule of 5 ms per time zone and estimates New York to San Francisco at 15 ms. It omits route, peering, TLS, congestion, and geography. Measure actual paths.

## Reliability

Assume GPUs and nodes fail.

The source cites a Llama 3 training run with 16,000 GPUs over 54 days and 419 unexpected interruptions, roughly one failure per 50,000 GPU-hours. An eight-GPU node exceeds 70,000 GPU-hours per year. This is training evidence used as a reliability illustration, not a serving failure-rate guarantee.

Node response:

1. Detect and record the GPU error.
2. Treat the whole node as suspect.
3. Cordon it against new placement.
4. Reschedule or cycle workloads.
5. Repair and validate before return.

Cloud maintenance and provider outages require protection above the node.

### Multi-site patterns

Active-active runs several serving sites. It costs more but gives low failover time and continuously exercises all sites.

Active-passive holds a ready standby. It may cost less but needs tested cutover, enough warm capacity, and configuration freshness.

The goal is to redirect a cluster, region, or provider failure without a large latency jump. Failover capacity must absorb load, not merely accept routes.

Test:

- GPU and full node failure.
- Cluster loss.
- Region and provider loss.
- Global control-plane loss.
- Object store and registry loss.
- Quota exhaustion.
- Post-failover P99 and residency.

## Security and compliance

Protect:

- Prompts, media, intermediate state, and outputs.
- Proprietary or fine-tuned weights and adapters.
- GPU infrastructure and access to model capability.

Data minimization is the simplest control. Do not retain prompts or outputs without a documented need, approved use, and retention period.

Apply:

- Encryption in transit and at rest.
- Container hardening and vulnerability scanning.
- Network segmentation and explicit egress.
- Least-privilege identity, secrets, and operator access.
- Tenant and workload isolation.
- Audit logs for deployment and configuration changes.
- Third-party penetration tests.

Provider certifications such as SOC 2 Type II or HIPAA scope do not make the application compliant. Verify contracts, services, regions, logs, backups, shadow traffic, webhooks, and failover paths.

Enforce data residency in routing. The source example keeps Canadian work in Toronto-area capacity and US work in New York-area capacity. Actual legal obligations require specialists.

## Testing and release

Test the complete serving path after replica tuning.

Methods:

- Manual synthetic smoke checks.
- Load tests for throughput, queueing, scaling, and tails.
- Shadow traffic for realistic behavior without serving candidate output.

Sample shadow traffic and use a shorter focused load test to control cost, but cover daily and weekly cycles and outlier shapes.

### Blue-green and canary

Blue-green creates a full second environment, switches all traffic, and retains the old one for rollback. It is clean but doubles capacity during rollout. A 100-GPU service needs another 100 GPUs.

Canary uses smaller extra capacity:

1. Build and make candidate ready.
2. Pre-scale for the first traffic share.
3. Route a small percentage.
4. Compare quality, errors, stability, tails, queueing, and resource pressure.
5. Revert on failure.
6. Raise share in stages to 100 percent.

A no-traffic canary sits near minimum replicas. Pre-scale before each ramp or users queue while reactive scaling catches up.

Rollback includes routing, schema, client compatibility, state, and cache effects. Do not destroy rollback capacity until stability is proven.

## Cost estimation

### API cost

The cost formula is reconstructed because the source figure was missing:

```text
API cost = input cost + output cost + other billed request/cache classes

input cost = input_tokens / 1,000,000 x input price per million
output cost = output_tokens / 1,000,000 x output price per million
```

Separate cached and uncached input if pricing differs. Include volume discounts and contracts.

### Dedicated cost

Reconstructed relationship:

```text
dedicated infrastructure cost
  ~= sum(instance_count_i x active_hours_i x hourly_price_i)
     + storage
     + network and egress
     + support infrastructure

total cost of ownership
  = infrastructure cost
    + engineering build and maintenance cost
```

The source figures were absent, so do not cite these as verbatim formulas.

Dedicated cost depends on batch and latency policy, traffic shape, idle time, ISL/OSL tails, cache behavior, headroom, and redundancy. Input and output work differ. Compare total API spend with total dedicated TCO rather than forcing a naive blended token rate.

Rules:

- Use at least one week to smooth daily variation, preferably several demand cycles.
- Add engineering and on-call labor.
- Add idle SLA headroom, failover, canary capacity, storage, transfer, control systems, monitoring, and support.
- Compare equal quality, SLO, availability, geography, security, and retention.
- Run sensitivity for traffic, utilization, lengths, spot interruptions, and GPU price.
- Do not publish a GPU-derived per-token cost without assumptions.

## Observability

Integrate inference with existing traces, logs, metrics, alerts, and incident tools. Do not create an isolated dashboard.

Monitor:

- Request volume by model and deployment.
- ISL, OSL, media dimensions, and duration.
- 2XX, 4XX, 5XX, cancellation, timeout, and OOM.
- TTFT, ITL, perceived TPS, completion, and end-to-end P50/P90/P99.
- Serving, starting, pending, and unhealthy replicas.
- CPU, host RAM, GPU compute, VRAM, storage, network, and collectives.
- Queue depth and age.
- Cold-start stage times.
- Prefix hit rate by reused tokens and tier.
- LoRA routing and residency.
- Speculation acceptance.
- Streaming connection count and failures.
- Spot interruptions and hardware errors.
- Regional placement and failover state.

Interpret metrics together. Longer prompts can raise latency without higher request count. Keep server logs and deployment or configuration audit logs in the same investigation. Source examples include Grafana, Datadog, PagerDuty, and Sentry.

## Client code and protocols

End-to-end performance includes caller, network, protocol, and server. The source calls OpenAI's SDK a common compatible interface and also names LangChain, Vercel AI SDK, LiteLLM, and LlamaIndex. Verify overhead and current behavior.

### Connection reuse

Session establishment can cost dozens of milliseconds. Reuse DNS results where appropriate, TLS sessions, HTTP connections, and connection pools. Established SDKs may do this. Custom media clients must implement it deliberately.

Do not assume reuse from an SDK name. Test repeated calls and inspect connection traces to confirm session reuse, TLS resumption, pooling, idle timeouts, and reconnect behavior for the selected SDK and transport.

Measure from the user process, including DNS, TLS, upload, queue, and transfer.

### Asynchronous jobs

Use asynchronous execution for document processing, corpus embeddings, long media generation, and other throughput work:

1. Client submits work and a webhook or polling destination.
2. Server acknowledges.
3. Durable backend queue runs it.
4. Server posts or exposes the result.

Synchronous requests often time out after minutes. Asynchronous job limits can extend to hours.

Production async clients need:

- Webhook authentication.
- Retry with duplicate-safe delivery.
- Job status.
- Cancellation and expiry.
- Idempotency key.
- Result retention and access policy.

### Streaming protocols

HTTP response streaming is enough for text output in many cases.

WebSocket:

- Lightweight bidirectional stream.
- Good for unstructured real-time audio chunks.
- Server parses messages.
- Each replica has a configured connection cap.

gRPC:

- Bidirectional schema-first service protocol.
- Good for structured service-to-service calls.
- Validation reduces custom parsing.
- The source describes it as slightly slower than WebSocket, which is workload-dependent.

Choose by browser support, schema, flow control, message size, connection lifetime, observability, and load-balancer support. Test idle timeouts and backpressure.

## Production readiness checklist

### Artifacts

- [ ] Use a proven base image or document why not.
- [ ] Pin image digest, dependencies, CUDA stack, and build inputs.
- [ ] Match model, engine, driver, and GPU.
- [ ] Remove build-only dependencies and scan vulnerabilities.
- [ ] Replace prereleases with stable builds when possible.
- [ ] Keep large weights separate and near GPUs.
- [ ] Cache compiled engines by exact environment.
- [ ] Prove rebuild and registry recovery.

### Capacity and scaling

- [ ] Benchmark concurrency for real ISL, OSL, cache, LoRA, and media.
- [ ] Align engine limit and scaler target.
- [ ] Set min, max, window, and scale-down delay.
- [ ] Use traffic and utilization signals.
- [ ] Measure each cold-start stage.
- [ ] Define readiness by representative inference.
- [ ] Test queue registration and immediate dispatch.
- [ ] Bound age, depth, priority, cancellation, and overload.
- [ ] Use scale to zero only for suitable work.
- [ ] Scale pipeline stages independently.

### Routing and clients

- [ ] Balance estimated work, not count.
- [ ] Test cache-aware and LoRA-aware routing.
- [ ] Trade locality against queue and geographic delay.
- [ ] Reuse client sessions and verify pooling and TLS resumption with traces.
- [ ] Measure full client-to-result latency.
- [ ] Match protocol to text or bidirectional media.
- [ ] Scale on connections for streams.
- [ ] Verify load-balancer long-lived connection support.

### Reliability and multi-cloud

- [ ] Reserve baseline and define on-demand or spot burst.
- [ ] Confirm inventory, quota, node size, topology, start time, and reclaim notice.
- [ ] Keep workload planes serving during control-plane loss.
- [ ] Test active-active or active-passive cutover.
- [ ] Route by latency, health, capacity, and residency.
- [ ] Cordon suspect GPU nodes and validate before return.
- [ ] Test node, cluster, region, provider, registry, store, and control-plane loss.
- [ ] Ensure failover capacity absorbs full traffic.
- [ ] Measure cutover and post-failover P99.

### Security

- [ ] Document every retained prompt, output, and intermediate.
- [ ] Encrypt in transit and at rest.
- [ ] Restrict network, identity, secret, weight, and operator access.
- [ ] Isolate tenants.
- [ ] Harden and scan containers.
- [ ] Audit deployment and configuration changes.
- [ ] Run independent penetration tests.
- [ ] Verify provider compliance scope and contracts.
- [ ] Enforce residency in normal and failover routes.
- [ ] Keep shadow tests, logs, and webhooks inside policy.

### Release and economics

- [ ] Run smoke, load, and sampled shadow tests.
- [ ] Cover cycles and tail shapes.
- [ ] Prefer canary when duplicate GPU capacity is scarce.
- [ ] Pre-scale each canary stage.
- [ ] Set rollback thresholds for quality, errors, tails, queueing, and pressure.
- [ ] Correlate app traces with inference and audit data.
- [ ] Compare API and dedicated TCO over at least a week.
- [ ] Add headroom, failover, transfer, support systems, and labor.
- [ ] Use authenticated, retry-safe async jobs for long work.

## Incident response

### Triage

- [ ] State symptom, model, region, version, start time, and user impact.
- [ ] Compare request volume, ISL, OSL, media shape, cache hit, and LoRA mix with baseline.
- [ ] Check response and cancellation codes by region and model.
- [ ] Inspect TTFT, ITL, completion, end-to-end tails, and queue age.
- [ ] Check serving, starting, pending, and unhealthy replicas.
- [ ] Check host, GPU, VRAM, network, storage, and collective pressure.
- [ ] Read service logs with recent audit changes.

### Common branches

- Long-prompt latency: check prefill, chunking, routing, and prefix misses.
- Latency with normal GPU use: check connection setup, network, queues, and downstream stages.
- Queue growth: check scaler signals, max replicas, quota, cold start, and ready registration.
- Stuck startup: split procurement, image, weights, compile, and warm-up.
- OOM: check model change, precision, context, batch, KV growth, and concurrency.
- One hot replica: check outlier inputs, stale load state, prefix and adapter affinity.
- Stream failure: check connection caps, scaler, idle timeout, and flow control.
- GPU error: cordon the node, move traffic, cycle pods, and inspect neighboring GPUs.
- Regional outage: invoke tested failover and preserve residency.
- Bad canary: stop ramp and route back before removing rollback capacity.
- Async backlog: check worker throughput, webhooks, retries, duplicates, and expiry.
- Security event: stop unnecessary logging, preserve required evidence, revoke credentials, isolate workloads, and check weight access.

### Recovery

- [ ] Confirm queue drain and all percentile recovery.
- [ ] Confirm traffic is not pinned to degraded or distant capacity.
- [ ] Validate output correctness, not only HTTP success.
- [ ] Keep extra capacity until stable.
- [ ] Record timeline, failed layer, detection gap, and impact.
- [ ] Add a regression load, rollout, or failover test.
- [ ] Update scaler, queues, alerts, runbooks, and capacity contracts.

## Vendor-specific source material

The book's section 7.6 markets Baseten, the author's employer, around low latency, multi-cloud infrastructure, autoscaling, security, developer tooling, and forward-deployed engineering. Customer and growth claims are marketing, not benchmark evidence. This skill does not use them as general guidance. Verify any current offering independently.
