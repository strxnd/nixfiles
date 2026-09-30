# Software and engines

## Snapshot warning

Engine rankings, model and hardware support, version prevalence, project governance, maturity, and vendor relationships reflect January 2026. Before implementation, read current official documentation, release notes, compatibility tables, open issues, licenses, and container tags. Benchmark exact versions. NVIDIA product descriptions are vendor-specific.

## Abstraction ladder

Choose the lowest layer that gives needed control:

1. CUDA controls GPU computation and memory.
2. PyTorch and related frameworks provide tensor graphs, compilation, and custom-kernel escape hatches.
3. Inference engines package batching, caching, quantization, speculation, and parallelism.
4. Distributed systems such as NVIDIA Dynamo coordinate engines across replicas and nodes.

Most production work belongs at levels 3 and 4. Move lower only for unsupported architectures or measured hot operations.

The source identifies NVIDIA, Hugging Face, Linux Foundation projects, and LMSYS as major contributors. Organizational ownership and ecosystem roles can change.

## CUDA and kernels

CUDA is NVIDIA's proprietary parallel-computing platform and programming model. It is not a language. CUDA C++ normally splits host CPU and device GPU code through `nvcc`.

Main components:

- CUDA kernel: a function executed by many GPU threads.
- CUDA graph: captured DAG of repeated kernels and operations, reducing launch and orchestration overhead.
- CUDA driver: low-level memory and execution interface.
- CUDA runtime: developer API for allocations, transfers, and kernel launches.

GPU optimization maps a stable algorithm onto a specific memory hierarchy, Tensor Core layout, and scheduler. Naive attention can be short code. FlashAttention preserves the result through much larger hardware-aware code.

### Kernel libraries

| Library | Role |
|---|---|
| BLAS | Standard linear-algebra operation interface |
| cuBLAS | NVIDIA BLAS and GEMM implementation |
| cuDNN | NVIDIA neural-network primitives |
| CUTLASS | C++ templates for high-performance CUDA kernels |
| CuTe | Higher-level tiled tensor templates for newer architectures |
| FlashInfer | LLM inference kernels, including attention and fused sampling |

The source links FlashAttention 3 implementation work to CUTLASS and CuTe machinery. Treat that as revision-specific. Check the exact repository, build dependencies, and target architecture before porting or selecting kernels.

GEMM, general matrix-matrix multiplication, dominates linear layers. Start with cuBLAS or a mature engine kernel.

Custom GEMM can help when shapes are fixed or unusual, hardware features are new, or a quantized format needs special handling. `DeepGEMM` is the source's example of DeepSeek FP8 GEMM tuned for Hopper and exact shapes. Its Blackwell support claim is time-sensitive.

### Kernel selection

Kernels can assume a GPU generation, memory bandwidth, Tensor Core layout, dimensions, data type, and ABI. A Hopper kernel may underuse Blackwell. A Blackwell kernel may fail on Hopper.

For every plugin, record:

- Supported compute capabilities and GPU SKUs.
- Precisions and quantization scales.
- Supported matrix and sequence shapes.
- Framework and engine ABI.
- Build flags and container.
- Numerical test.
- Fallback path.

Revalidate after a GPU, driver, CUDA, framework, or engine upgrade.

### Fusion

Two separate kernels may write an intermediate to memory and immediately read it. Fusion removes traffic and launch overhead.

```text
unfused: read -> operation A -> write -> read -> operation B -> write
fused:   read -> operation A+B -> write
```

A common fusion combines matrix multiplication, bias, and activation. It matters most for bandwidth-bound decode. Dependencies can prevent fusion, and large fused kernels cost more to maintain and port. Benchmark full service and numerical output.

Compilers can fuse visible adjacent tensor operations. Opaque plugin kernels block fusion across their boundary. FlashAttention and other complex transformations normally need handwritten kernels.

## PyTorch and compilation

PyTorch is the source's main general framework. It defines arbitrary models, provides `autograd` for training, and exposes high-performance CPU and GPU tensor operations with custom CUDA insertion.

`torch.compile` can specialize a model for a target GPU, select kernels, and fuse visible operations.

Limits:

- It cannot see inside opaque DeepGEMM, FlashAttention, or other plugin kernels.
- LLM runtimes use many plugins, reducing compiler scope.
- Python-specific control flow and data structures may need rewriting into tensor operations.

Use direct PyTorch when an engine lacks the architecture or when implementation control is the requirement. Compile visible chains, preserve proven plugins for hot operations, and cache the compiled artifact. Compile on the same GPU architecture used in production.

The source also lists TensorFlow as a broad platform and JAX as a research-oriented system with fewer legacy features. Popularity comparisons are time-sensitive.

## Model files and runtimes

### Safetensors

Safetensors stores tensor data only:

- It does not deserialize executable Python code.
- Large checkpoints split across files.
- Memory mapping avoids allocating a whole file before access.
- Weights remain separate from architecture.

Use it when the runtime already implements the model graph.

### ONNX

ONNX stores weights and an execution graph. Use it when graph portability matters and all operations export correctly.

Typical paths:

```text
PyTorch -> ONNX -> ONNX Runtime
PyTorch -> supported export -> TensorRT engine
PyTorch -> Torch-TensorRT -> TensorRT
```

ONNX Runtime targets several hardware families. TensorRT targets NVIDIA and mixes proprietary and open components. Complex Python structures or operations may fail export. The source gives DeepSeek V3 Multi-Latent Attention as an example that is difficult to export and may instead receive hand-fused kernels.

For many supported transformers, current practice in the source is safetensors directly into vLLM or TensorRT-LLM. ONNX Runtime remains useful for portable graph execution. TensorRT remains useful for image and video models.

### Reference libraries

Hugging Face `transformers` and `diffusers` are reference and development libraries:

- Architecture implementations.
- `config.json`.
- Model-card input and output examples.
- Weight download and task utilities.
- Local validation and notebooks.

Do not assume a basic model-card example is a production server. Move to a dedicated PyTorch implementation or inference engine.

## Engine capabilities

The source compares vLLM, SGLang, and TensorRT-LLM. All provide continuous batching and source-era support for post-training quantization, speculative decoding, prefix caching, parallelism, and disaggregation. At publication, vLLM Omni and SGLang Diffusion had early image and video generation support, while TensorRT-LLM did not. The separate TensorRT runtime remained useful for image and video. Verify current coverage.

Source snapshot:

| Dimension | vLLM | SGLang | TensorRT-LLM |
|---|---|---|---|
| Performance | Good | Good | Source says best |
| Setup | Easy | Easy | Hard |
| Model coverage | Most | Most | Some |
| Hardware | GPU and TPU | NVIDIA and AMD | NVIDIA only |
| License | Apache 2.0 | Apache 2.0 | Apache 2.0 |

Treat relative performance as a source claim. The useful distinction is breadth versus constraints. More fixed assumptions can unlock higher performance, but only on supported combinations.

### vLLM

Source-era strengths:

- Broad NVIDIA, AMD, Intel GPU, and Google TPU coverage.
- Wide model support, often near release day.
- `vllm serve`, pip package, and official images.
- Multimodal input and output work through vLLM Omni.
- Strong default production server for new or unusual models.

Its broad scope can leave fewer assumptions for hardware-specific optimization.

Use it first when setup speed, new-model support, varied hardware, or multimodal breadth matters. It may also fit smaller or older GPUs where specialized NVIDIA kernels provide less gain.

The source's GitHub-star comparison is popularity, not evidence. vLLM Omni maturity and supported modalities are time-sensitive.

### SGLang

SGLang pairs a fast backend with a flexible frontend and replaceable components. Server startup uses `sglang.launch_server`.

Source-era strengths:

- NVIDIA and AMD.
- Fast model support.
- Collaboration around DeepSeek, Qwen, Kimi, Z AI, and Multi-Latent Attention.
- Large MoE and multi-node throughput tuning, with GB200 NVL72 as the source's concrete rack-scale example.
- SGLang Diffusion for image and video pipelines.

The NVL72 example is time-sensitive and benchmark-dependent. Verify current SGLang support, topology requirements, and measured scaling.

SGLang Diffusion uses a staged pipeline abstraction, diffusion parallelism, scheduler, and optimized kernels.

Use it for large MoE throughput, modular customization, or an engine workflow for diffusion. The source identifies it as xAI's preferred engine. This and vendor-lab collaborations are time-sensitive claims.

### TensorRT-LLM

TensorRT-LLM is NVIDIA's open-source LLM engine. The source positions it as the highest-performance option for expert NVIDIA users on supported models.

Version distinction:

| Version | Source architecture |
|---|---|
| `0.X.Y`, V0 | TensorRT plugin that builds an engine |
| `1.X.Y`, V1 | Standalone PyTorch package without TensorRT dependency |

V1 launched in summer 2025 while V0 remained common. Always identify the major version before using docs or configs.

Source reasons for performance:

- NVIDIA-authored and sometimes closed-source kernels.
- Manual fusion.
- Early Hopper and Blackwell tuning.
- Formats such as NVFP4.
- In-flight batching.

It supports configuration for quantization, speculation, prefix caching, chunked prefill, parallelism, and disaggregation. `trtllm-serve` accepts flags, while V1 uses `config.yaml` for deeper controls. The source recommends official NVIDIA containers.

Use it when:

- The exact architecture has first-class support.
- Hardware is Hopper or newer.
- The measured gain pays for integration and tuning.
- Dynamo integration is part of a large deployment.

Compare carefully when the model is new, hardware is non-NVIDIA or older, or operating simplicity matters more than the last performance increment.

Version prevalence, feature parity, supported formats, engine build behavior, and rankings change quickly.

## Engine selection process

1. List exact architecture, modalities, custom code, structured output, quantization, speculation, cache, parallelism, disaggregation, and hardware.
2. Check current official support matrices and open issues.
3. Use release-matched official containers for the first test.
4. Benchmark the easiest broad engine.
5. Benchmark the likely performance leader on identical traffic and quality gates.
6. Sweep batch and concurrency.
7. Test each desired optimization and the combined configuration.
8. Include cold start, operational complexity, observability, failure modes, and current maintainership.
9. Choose the simplest engine that meets the SLO and cost target.

Source-era decision matrix:

| Need | First engine to test | Caveat |
|---|---|---|
| New model or broad hardware | vLLM | May trail a narrower stack |
| Large MoE or modular diffusion | SGLang | Fast-moving and tuning-heavy |
| Supported NVIDIA LLM on Hopper/Blackwell | TensorRT-LLM | Harder and narrower |
| Unsupported architecture | PyTorch with compilation | Team owns serving and optimization |
| Portable serialized graph | ONNX Runtime | Export coverage can fail |
| Tuned NVIDIA image/video | TensorRT or current diffusion engine | Verify current model support |

## NVIDIA Dynamo

Dynamo is a distributed serving layer announced in March 2025. It orchestrates vLLM, SGLang, or TensorRT-LLM rather than replacing them.

Source mechanisms:

- Distributed KV reuse and cache-aware routing.
- Separately configured and scaled prefill and decode workers.
- Multi-node model parallelism, including expert parallelism.
- An SLA planner using TTFT and TPS targets.
- Queues for saturated prefill workers.
- Conditional routing by post-prefix-cache ISL and prefill queue size.
- NIXL-based KV transfer.
- KV block transposition when prefill and decode TP layouts differ.
- Runtime changes to prefill and decode worker counts.

Use it when a large model and substantial traffic can keep specialized pools busy, prefix locality is valuable, or one replica needs multi-node EP. Skip it when a standalone engine meets the objective or orchestration overhead exceeds gains.

The source targets foundation-model scale and trillion-parameter examples. Dynamo was new and changing. Verify APIs, planners, backend support, license, maturity, and failure behavior in the installed version.

## Continuous batching and scheduling

All three source engines implement token-granularity continuous batching. TensorRT-LLM calls it in-flight batching.

- Static batching waits for a fixed batch and can delay early arrivals.
- Dynamic batching starts when full or a timer expires.
- Continuous batching admits new work whenever a sequence slot becomes free.

Continuous batching is the normal LLM choice. Batch size remains a latency-throughput control. Engine concurrency limits must align with autoscaler targets.

## Kernel and framework checklist

- [ ] Start with mature libraries and engine defaults.
- [ ] Profile before writing CUDA.
- [ ] Record GPU, precision, shapes, ABI, and fallback for every plugin.
- [ ] Revalidate plugins after architecture or stack changes.
- [ ] Look for write-then-read intermediates.
- [ ] Use compiler fusion for visible simple patterns.
- [ ] Use handwritten fusion only for measured hot paths.
- [ ] Validate numerics after fusion or precision changes.
- [ ] Use `torch.compile` where operations remain visible.
- [ ] Expect plugins to block fusion boundaries.
- [ ] Use safetensors for known graphs and ONNX only for a real portability need.
- [ ] Treat `transformers` and `diffusers` samples as references.

## Engine checklist

- [ ] Verify exact model, architecture, template, custom operators, modality, and output constraints.
- [ ] Verify exact GPU and precision support.
- [ ] Identify TensorRT-LLM V0 versus V1.
- [ ] Check quantization, speculation, prefix cache, chunked prefill, parallelism, and disaggregation.
- [ ] Use exact official image tags or digests and compatible driver.
- [ ] Benchmark viable engines with one workload and quality baseline.
- [ ] Include startup and compile artifacts.
- [ ] Test all optimizations alone and together.
- [ ] Do not use GitHub stars as a performance metric.
- [ ] Add Dynamo only when measured scale supports it.
- [ ] Compare Dynamo overhead with standalone service.

## What to verify now

- Current governance and licenses.
- Supported models, modalities, accelerators, quantization formats, speculation methods, and parallel layouts.
- TensorRT-LLM version architecture and migration path.
- vLLM Omni and SGLang Diffusion maturity.
- Dynamo backend compatibility, planners, and production readiness.
- CUDA, driver, PyTorch, compiler, and kernel compatibility.
- Container digest, CVEs, and day-zero prerelease dependencies.
- Whether vendor-provided performance uses matching quality, traffic, precision, and hardware.
