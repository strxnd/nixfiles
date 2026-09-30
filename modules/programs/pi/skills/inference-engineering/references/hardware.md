# Hardware

## Snapshot warning

All accelerator generations, specifications, prices, release dates, roadmaps, cloud offerings, and market comparisons in this file reflect the book's January 2026 source snapshot. They include vendor claims. Before implementation or procurement, check current official specifications, driver and engine support, cloud inventory, quota, full instance topology, delivered collective bandwidth, price, and production benchmarks.

Cloud GPUs are the normal starting point because access and scale are flexible. On-premises and air-gapped systems remain relevant for sustained large demand, government, and regulated enterprise work.

Accelerators also differ by deployment class:

- Datacenter GPUs, such as the source-era B200, target rack service with standardized power, cooling, networking, and multi-GPU chassis topology.
- Workstation GPUs, such as the source-era RTX Pro 6000, target professional local systems.
- Consumer GPUs, such as the source-era RTX 5090, target personal systems and trade datacenter features for price and local availability.

These examples and product boundaries are January 2026 snapshots. Production scale normally favors datacenter parts because the surrounding node and fabric matter as much as the chip.

## Bottleneck-first selection

Classify the workload before choosing a chip:

| Workload | Typical first limit | Selection focus |
|---|---|---|
| LLM prefill | Compute | Dense Tensor Core FLOPS at deployed precision |
| LLM decode at low or medium batch | VRAM bandwidth | Achieved bandwidth and bytes per token |
| Large weights or long context | Capacity | Usable VRAM after weights, buffers, and KV headroom |
| Small models | Utilization | Cost per request on a smaller GPU or MIG partition |
| Multi-GPU model execution | Communication | NVLink/NVSwitch in-node, measured fabric across nodes |
| Image and video denoising | Compute, then capacity | Dense low-precision compute, attention kernels, memory |
| Host KV or LoRA offload | CPU-to-GPU link | Host memory and C2C or PCIe bandwidth |
| Local inference | Capacity, bandwidth, thermals | Minimum supported device and sustained behavior |

Never compare sparse peak on one GPU with dense peak on another. Compare the same precision and sparsity assumption. Peak specifications do not predict service speed.

## GPU execution model

CPUs favor complex sequential work. GPUs keep many simple independent threads in flight for matrix and vector operations. A large GPU can keep tens to hundreds of thousands of threads in flight, subject to the exact SKU, kernel occupancy, register use, shared memory, and scheduler limits.

A GPU contains streaming multiprocessors, SMs. An SM includes:

- CUDA Cores for scalar arithmetic.
- Tensor Cores for matrix and vector operations.
- Special Function Units for functions such as `sin`, `cos`, and `log`, including softmax support.

Matrix multiply and accumulate is:

```text
D = A x B + C
```

Use Tensor Core throughput for neural inference comparisons. Datacenter chips report teraFLOPS, `10^12`, or petaFLOPS, `10^15`.

### Dense, sparse, and precision claims

NVIDIA's `2:4` structured sparsity lets compatible Tensor Cores skip two zeros in every group of four. Sparse peak is often twice dense peak. Ordinary inference is dense unless the model and runtime deliberately use this exact pattern.

A source rule of thumb is:

```text
halving numeric precision approximately doubles peak FLOPS
```

Thus 1 PFLOPS at 16-bit may become about 2 PFLOPS at 8-bit. Packing, scales, unsupported operations, other bottlenecks, and quality constraints prevent a guaranteed 2x service gain.

## Memory hierarchy

GPU-local VRAM is high-bandwidth DRAM, commonly HBM3, HBM3e, or source-roadmap HBM4 in datacenter parts. On-chip SRAM is smaller and faster.

The source describes:

- L0 instruction cache local to a Tensor Core.
- L1 or shared memory local to an SM.
- L2 shared across SMs.

H100 source figures are 256 KB L1 per SM and 50 MB total L2.

Capacity and bandwidth are separate:

- Capacity determines whether weights, activations, buffers, and KV state fit.
- Bandwidth determines how fast bytes can move between VRAM and compute.

A coarse source provisioning rule is:

```text
required VRAM >= model weights + at least 50% headroom for KV cache
```

Interpret this as weights plus at least half the weight footprint or substantial free capacity, then replace it with actual cache sizing. Long contexts, high batches, video, and runtime workspaces need more. If weights barely fit, runtime can slow or OOM.

## NVIDIA architecture snapshot

The architecture letter is more informative than the product number. H100 succeeded A100 across generations. H200 is a larger Hopper product than H100. B200 later superseded H200. Numbering does not stay consistent across generations.

The source says new generations arrive every one to two years and that teams often use the latest three to five generations. Verify current product status.

| Architecture | Source-era products | Source characterization |
|---|---|---|
| Turing | T4 | Low-traffic or legacy |
| Ampere | A10, A100 | Lower-cost or legacy |
| Ada Lovelace | L4, L40 | Small-model and graphics-oriented inference |
| Hopper | H100, H200 | FP8, high bandwidth, mature support |
| Blackwell | B200, B300 | Source-era high end |
| Rubin | Announced 2026 | Roadmap with HBM4 and CPX |
| Feynman | Announced 2028 | Roadmap with sparse detail |

### Hopper

Source specifications:

| GPU | Dense FP8 | VRAM | Bandwidth |
|---|---:|---:|---:|
| H100 | 1,979 teraFLOPS | 80 GB | 3.35 TB/s |
| H200 | 1,979 teraFLOPS | 141 GB | 4.8 TB/s |

Hopper first shipped with H100 in March 2022. It added FP8 Tensor Cores, dynamic-programming instructions, asynchronous data movement and execution, thread-block clusters, distributed shared memory, and other kernel controls. FP8 has twice FP16 peak Tensor Core speed and half the bytes, but not twice end-to-end service speed. FlashAttention 3 uses Hopper-specific asynchronous behavior.

The source treats H100 and H200 as a mature balance of speed and kernel support. Choose H200 over H100 when capacity or low-batch decode bandwidth matters, since listed FP8 compute is equal.

### Ada Lovelace

Source specifications:

| GPU | Dense FP8 | VRAM | Bandwidth |
|---|---:|---:|---:|
| L4 | 242 teraFLOPS | 24 GB | 300 GB/s |
| L40 | 362 teraFLOPS | 48 GB | 864 GB/s |

Lovelace lacks NVLink. L4 can fit small models, embeddings, and vision cheaply. The source argues that L40 can be a poor general-inference choice when an H100 MIG slice offers similar memory with more compute and bandwidth. Validate current price and partition availability. Avoid Lovelace for tightly coupled multi-GPU execution.

### Blackwell

Source specifications:

| GPU | Dense FP8 | VRAM | Bandwidth |
|---|---:|---:|---:|
| B200 | about 5 petaFLOPS | 192 GB | up to 8 TB/s |
| B300 | about 5 petaFLOPS | 288 GB | up to 8 TB/s |

The source dates B200 to November 2024, followed by B300, and describes B100 as uncommon for inference. Blackwell adds FP4 and microscaling formats `MXFP8`, `MXFP4`, and `NVFP4`, plus expanded asynchronous pipelines. FlashAttention 4 targets this hardware.

The source calls B200 and B300 the preferred high-end choices for large LLMs and compute-heavy video. It also says software and tuned kernels had only recently matured. Verify framework, driver, CUDA, kernel, format, availability, and price.

### Rubin and Feynman roadmap

The source presents Rubin as a planned 2026 generation:

- HBM4 for more bandwidth, useful for decode.
- A separate Rubin CPX chip for compute-bound prefill.
- Rack-scale use with Vera CPUs.

It lists Feynman for 2028 with few details. These are vendor roadmap claims. Do not procure on roadmaps. Benchmark shipped hardware and allow roughly a year for ecosystem tuning after a new architecture, per the source's caution.

### Grace and Vera CPUs

Grace ARM CPUs pair with GPUs in GH200 and GB200. NVLink Chip-to-Chip is listed at up to 900 GB/s bidirectional between CPU and GPU memory, several times ordinary PCIe in the source.

This matters when large host memory holds LoRA adapters or KV state. Faster retrieval lowers host-offload stalls. Vera is the announced Grace successor for Rubin. Product pairings are roadmap information.

## Full instance selection

A cloud instance contains more than GPUs:

- Host CPUs for preprocessing, scheduling, networking, and orchestration.
- Host RAM for CPU work and offloaded state.
- Storage for images, weights, and artifacts.
- Network for clients, object storage, and the datacenter.
- Intra-node and inter-node links.

The same GPU can perform differently across provider designs. Confirm the complete instance.

Form factor matters. A100 has PCIe and SXM variants. The source says SXM has about 5 percent more memory bandwidth and is common for inference. Check actual SKU.

### Multi-GPU instances

Use multiple GPUs when weights plus runtime state do not fit, or when lower latency or more throughput pays for parallel execution. Common allocations are 2, 4, and 8 GPUs. A standard high-end node has eight GPUs.

Source link figures:

| Boundary | Technology | Source maximum |
|---|---|---:|
| GPU-to-GPU, Hopper node | NVLink with NVSwitch | up to 900 GB/s |
| GPU-to-GPU, Blackwell node | NVLink with NVSwitch | up to 1,800 GB/s |
| Node-to-node | InfiniBand | 400 Gb/s per NIC |
| Node-to-node | Ethernet | 100 Gb/s per NIC |

NVSwitch provides all-to-all coordination over NVLink. InfiniBand and Ethernet figures use gigabits, while NVLink uses gigabytes. Normalize units, direction, NIC count, rails, oversubscription, protocol efficiency, and aggregate versus per-link claims. Measure collectives on the rented instance. Providers may use proprietary fabrics or restrict InfiniBand to certain instances.

Keep all-reduce-heavy TP inside one node. Cross-node communication is roughly an order of magnitude slower as a topology rule, even before exact unit normalization.

NVIDIA acquired Mellanox, the InfiniBand vendor, in 2019.

### Rack-scale systems

The source lists:

- `GB200 NVL72` with 72 Blackwell GPUs and 36 Grace CPUs.
- `Vera Rubin NVL 144 CPX` as a planned successor with Vera, Rubin, and CPX.

Verify names, configuration, availability, and topology. Parallelism and disaggregation must respect link tiers.

## Multi-instance GPU

MIG partitions a supported physical GPU in hardware. Source-listed support includes A100, H100, H200, and B200. Verify exact SKU and profile support.

A compatible GPU can expose up to seven compute partitions. H100 has eight memory slices and seven compute slices. The source says:

- SXM H100 has 132 SMs.
- Seven equal compute slices leave some SMs unused.
- A three-compute-slice profile has about `3/7` of compute.
- It can receive 40 GB, half of H100 VRAM.
- It also receives about half the associated CPU, RAM, storage, and network resources in the cited cloud setup.

A 3B TTS model such as Orpheus can use MIG more efficiently than a whole H100. For small ASR or TTS models, benchmark two partitioned replicas against one full-GPU replica rather than assuming either layout wins. Compare utilization, batch behavior, tail latency, and every partitioned host, storage, and network resource. A partition is a bundle of limits, not only a fraction of GPU compute.

## Hardware matrix

| Need | Source-era first candidates | Main caveat |
|---|---|---|
| Mature high-end default | H100 | 80 GB and 3.35 TB/s may limit model or cache |
| More decode bandwidth and capacity at equal listed FP8 compute | H200 | Price and inventory must justify it |
| Largest LLM or video | B200/B300 | Newer software dependencies and source-era maturity |
| Small model or embedding | L4 or MIG | Compare full cost and utilization |
| Tight multi-GPU | Hopper or Blackwell NVLink node | Do not cross nodes without measuring |
| Host-offload-heavy | Grace superchip | Benefit requires actual host-device traffic |
| Future prefill specialization | Rubin CPX | Roadmap only in source |

### Capacity example

At FP8, one billion parameters take roughly 1 GB for weights:

```text
weight_bytes ~= parameters x precision_bits / 8
```

A 671B model therefore needs about 671 GB before buffers and KV state. Four source-era B200s provide about 720 GB and technically fit weights, but leave too little headroom. The source recommends an eight-B200 node for practical DeepSeek-V3.1 service. Model name and recommendation are snapshots. The lasting rule is to size operational state, not weights alone.

## Alternative datacenter accelerators

The source lists the following January 2026 vendor landscape:

| Company | Product | Claimed angle |
|---|---|---|
| AMD | MI350 | Datacenter GPU on AMD software |
| AWS | Inferentia, Trainium | AWS-integrated inference and training chips |
| Cerebras | WSE-3 | Wafer scale and high memory bandwidth |
| Etched | Sohu | Transformer-specific ASIC |
| Furiosa | RNGD | Power-efficient tensor contractions |
| Google | TPU | Google AI ASIC |
| Groq | LPU | SRAM-based high-bandwidth language processing |
| Qualcomm | Cloud AI 100 Ultra | Power-efficient accelerator made from mobile-GPU designs |
| SambaNova | RDU | Reconfigurable dataflow and large memory |

These are vendor positioning statements, not independent results. Alternatives commonly target bandwidth, power efficiency, or cloud integration. Adoption costs include compiler and model coverage, operations, manufacturing availability, capacity, cloud lock-in, and porting.

Compare the full workload and stack:

- Quality and exact model support.
- End-to-end and tail latency.
- Throughput and performance per watt.
- Compiler, kernels, engine, debugging, and monitoring.
- Available regions and cluster size.
- Migration and operating work.

NVIDIA's main barriers to replacement in the source are CUDA software depth, difficult manufacturing, and deployment distribution. Current status may differ.

## Local inference

Local, edge, client-side, or on-device inference runs on user hardware.

Benefits:

- Removes network round trip.
- Works offline and through server outages.
- Can keep user data on device.
- Shifts datacenter compute cost away from the developer.

Constraints:

- Much less compute and bandwidth.
- Cooling and battery limit sustained work.
- Fragmented devices, drivers, operating systems, and runtimes.
- Support and testing cost.

Design for the median older device, not a developer flagship. Keep a cloud fallback where requests exceed local capacity.

### Desktop snapshot

Source comparison:

| System | Memory | Bandwidth | Approximate full-system cost |
|---|---:|---:|---:|
| RTX 5090 | 32 GB | 1,792 GB/s | $5,000 |
| Apple M3 Ultra | 512 GB unified | 819 GB/s | $10,000 |

The discrete GPU is faster for a model that fits. Apple unified memory fits much larger quantized models at lower bandwidth. Prices and product status are snapshots.

The source says `Ollama` and `llama.cpp` can run aggressively quantized models over 100B parameters on high-end personal systems, while `ComfyUI` is popular for local image pipelines. `WebLLM` and browser standards target wider access. Verify current capabilities. Low-end systems such as Chromebooks may not provide useful generative inference.

MoE reduces active compute but not total weight storage or placement.

### Mobile snapshot

Source tooling:

- Android: Google AI Edge SDK and ML Kit GenAI APIs with Gemini Nano and Gemma.
- iOS: Apple Foundation Models and Core ML.

The source says premium phones struggle above 1B to 2B parameters. Treat this as a January 2026 limit. Small transcription, TTS, translation, and narrow fine-tuned models are better candidates. Use a hybrid design for larger work.

### Local checklist

- [ ] Define minimum supported hardware and operating systems.
- [ ] Measure load time, memory, latency, sustained thermal throttling, battery, and quality.
- [ ] Decide whether capacity or bandwidth controls the workload.
- [ ] Test every chip, browser, driver, and runtime combination in support scope.
- [ ] Quantize only to the product quality threshold.
- [ ] Use local execution for measured privacy, offline, cost, or network value.
- [ ] Provide fallback and clear data-handling behavior.

## Hardware procurement checklist

- [ ] Classify compute, bandwidth, capacity, communication, host, storage, or network limit.
- [ ] Compare dense Tensor Core throughput at deployed precision.
- [ ] Do not use 2:4 sparse peak unless the model and runtime do.
- [ ] Estimate weights, buffers, activations, and cache. Reserve at least the source's coarse 50 percent KV headroom, then refine from workload.
- [ ] Increase headroom for long context, large batches, and video.
- [ ] Check bandwidth separately from capacity and FLOPS.
- [ ] Confirm architecture, exact SKU, form factor, and memory configuration.
- [ ] Check CPU, RAM, storage throughput, network, and weight-loading path.
- [ ] Confirm NVLink/NVSwitch, PCIe, fabric, NIC count, topology, and placement guarantees.
- [ ] Normalize `GB/s` and `Gb/s` and measure collectives.
- [ ] Keep communication-heavy work inside an eight-GPU node when possible.
- [ ] Compare L4 and MIG profiles for small models.
- [ ] Validate the full MIG resource bundle.
- [ ] Consider Grace only for measured offload traffic.
- [ ] Benchmark new architectures with the exact production stack and allow for software maturity.
- [ ] Compare alternatives on delivered performance, power, software, capacity, migration, and TCO.
- [ ] Verify current official documentation and inventory before signing or buying.

## Multi-GPU checklist

- [ ] Find the minimum GPU count that fits weights plus runtime state.
- [ ] Map every parallel method to each physical link crossed.
- [ ] Estimate communication per token or denoising step.
- [ ] Keep frequent all-reduce on NVLink.
- [ ] Avoid Lovelace for tightly coupled execution because the source says it lacks NVLink.
- [ ] Treat cross-node fabric as a slower tier.
- [ ] Load test final node count and topology.
- [ ] Stop adding GPUs when communication or queueing erases the gain.
- [ ] Compare per-request parallelism with the same GPUs as independent replicas.

## Source caveats

- NVIDIA names, specifications, release chronology, roadmaps, architecture support, and link maxima are vendor-specific and time-sensitive.
- Peak rates may be bidirectional, aggregate, sparse, or tied to one format. Normalize before comparison.
- The source's 100 Gb/s Ethernet ceiling and cloud fabric descriptions can age quickly.
- `MXFP8` support is associated with Blackwell in the hardware chapter, while a later video section suggests Hopper support. Verify the exact format, kernel, and accelerator.
- The glossary associates GH200 and GB200 with systems "like NVL72," but NVL72 is normally Blackwell-associated. Verify product language.
- Hardware prices and desktop comparisons are snapshots.
