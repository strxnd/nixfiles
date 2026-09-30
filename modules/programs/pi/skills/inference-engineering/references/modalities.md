# Modalities

## Shared execution patterns

A modality is the accepted input type and produced output type. Common categories include:

| Input | Output | Category |
|---|---|---|
| Text plus image or video | Text | Vision-language |
| Text, image, or video | Vector | Embedding |
| Voice audio | Text | ASR or transcription |
| Text | Voice audio | TTS |
| Text | Music | Music generation |
| Voice audio | Voice audio | Speech-to-speech |
| Text or image | 3D model | Generative CAD |
| Text or image | Image or video | Media generation or editing |
| Image or video | Text | Captioning |
| Image or video | Mask | Segmentation |

Most systems use one of two patterns:

- Autoregressive token generation for LLM and VLM text, ASR decoders, TTS audio tokens, and related transformer work.
- Iterative latent denoising for most image and video generators.

Use output-specific metrics. A single audio token is not useful to a listener. Measure first byte or first phrase. Include preprocessing, postprocessing, and pipeline transfers in end-to-end results.

Model, engine, hardware, and performance claims in this file are January 2026 source snapshots. Verify current official documentation and inventory.

## Vision-language models

A VLM combines a large LLM with a smaller vision encoder that patches and embeds media into visual tokens. Parameter count understates runtime complexity because vision encoders and media preprocessing vary.

The source's Mistral Large 3 example pairs a 2B vision encoder with a 673B LLM. Treat model names and sizes as snapshots. vLLM and SGLang are source-era broad VLM engine choices.

A high-resolution image adds roughly 1,000 visual tokens in the source rule of thumb. During prefill:

1. Decode and preprocess media.
2. Patch, embed, and tokenize it.
3. Process visual and text tokens.
4. Build KV state.

Text decode then resembles an LLM, though some architectures use special attention for visual tokens.

Applicable methods:

- Downsample media before tokenization when detail allows.
- Quantize KV state after VLM task evals.
- Use EAGLE or a compatible speculator for text decode.
- Cache image-derived prefixes for repeated or multi-turn queries.
- Use TP for lower latency and VRAM.
- Disaggregate expensive media-heavy prefill at sufficient scale.
- Scale OCR, PDF extraction, ASR, and other preprocessors separately.

A high-resolution representation may use about 4x the visual tokens of a lower-resolution one. One image may fit unchanged. Multiple images and video usually require reduction. Evaluate detail-sensitive tasks at every resolution.

### Video input

Video carries temporal motion and sometimes audio. A model trained on clips often needs the full short clip in one call. Many VLMs cannot consume the audio track, so transcribe it and add the transcript.

Source arithmetic:

```text
24 frames/s x 4 seconds x 1,000 tokens/frame = 96,000 visual tokens
```

This is nearly 100,000 tokens before downsampling. Reduce frame rate and resolution. After encoding, long context and KV state dominate. Prefix caching, offload, quantization, and efficient attention become important.

### Omni models and specialist pipelines

An omni model accepts and produces several media types. Joint representation can help cross-media tasks, but small specialists can be faster and more accurate in one domain. A dedicated OCR model may beat a VLM's built-in text recognition.

Treat a VLM product as a pipeline. Profile and independently scale PDF parsing, OCR, audio transcription, image decoding, video sampling, and VLM execution. A fast main model can wait on slow preprocessing.

### VLM checklist

- [ ] Count visual tokens at every resolution and frame rate.
- [ ] Include media decode, OCR, and ASR in latency.
- [ ] Test detail-sensitive quality after downsampling.
- [ ] Measure post-cache ISL, KV occupancy, and prefix hit.
- [ ] Verify exact visual encoder and engine support.
- [ ] Keep short clips intact when temporal understanding requires it.
- [ ] Handle audio separately if the VLM cannot consume it.
- [ ] Scale pipeline stages independently.

## Embedding models

Embedding models map variable-length content to fixed-size vectors. Similarity supports RAG, memory, retrieval, search, and recommendations.

Separate traffic classes:

- Backfills index millions of records. Optimize batch throughput and durable queues.
- Interactive lookups need low tail latency.

Use separate deployments when both have enough volume. One batching policy cannot serve both well.

### Architecture and vectors

Source-era families:

- BERT-style encoder-only models, usually under 1B parameters, useful for simple low-latency classification and embeddings.
- LLM-backed embedding models, generally 8B or less in the source, with stronger capabilities. The source calls Qwen 3 Embed 8B a near-upper-range example. Verify the exact product name, spelling, parameter count, license, and current engine support.

Embeddings contain hundreds to thousands of values. More dimensions preserve more information but increase vector storage, retrieval bandwidth, and similarity cost. The source says dimensions do not materially change model inference time.

Matryoshka representations put important information early so vectors can be truncated with less quality loss. Test the quality versus database cost frontier.

Vectors from different models normally occupy incompatible semantic spaces even at the same dimension. Do not compare or mix them without an explicit migration design.

### Serving

Source runtimes include vLLM, SGLang, Infinity, and Hugging Face TEI. The source claims TensorRT-LLM gives the best performance for supported LLM-backed embedding models through XQA attention, fusion, and less memory traffic. Its high-performance pipeline also places parallel tokenization and a front-end batch manager before the engine. Treat this as one architecture to benchmark, not a universal best stack. The claim is time-sensitive and vendor-adjacent.

FP8 weight quantization can help, but small models may be more sensitive. Check:

```text
cosine_similarity(original_vector, quantized_vector)
```

The source asks for at least 99 percent similarity, plus task-level retrieval or ranking evals. This is not a universal pass threshold.

Prefix caching and prefill-decode disaggregation do not apply because embeddings process all input in parallel and have no autoregressive decode. Small models rarely benefit from model parallelism. Scale horizontally, normally one replica per GPU or suitable partition.

Embedding service can use large batches. An API call can contain dozens or hundreds of inputs, and a GPU can process several requests concurrently. Use dynamic batching and durable queues. Keep interactive queue delay bounded.

### Embedding checklist

- [ ] Separate backfill and interactive demand.
- [ ] Measure vector latency, throughput, batch, and tail queueing.
- [ ] Test dimension truncation on retrieval quality and storage cost.
- [ ] Never mix embeddings from incompatible model spaces silently.
- [ ] Validate quantization with cosine and downstream ranking.
- [ ] Prefer horizontal scaling over model parallelism.
- [ ] Do not add LLM-only cache or disaggregation mechanisms.

## Automatic speech recognition

ASR maps voice audio to text. Whisper is the main source example. Its largest listed model is 1.55B parameters. The source recommends Whisper 3 Large or Turbo for most latency budgets rather than a smaller quality compromise. Model names are snapshots.

Whisper is encoder-decoder:

- Encoder converts a log-Mel spectrogram to audio features.
- Autoregressive transformer decoder emits text and consumes most inference time.

The source uses TensorRT-LLM for in-flight batching, C++ runtime, and optimized decoder kernels. Small model size makes H100 or newer MIG partitions practical.

### Real-time ASR

For dictation or voice agents, measure one chunk's conversational round trip. The source target is 200 ms, roughly human reaction time.

Use:

- Persistent WebSocket for audio input and transcript output.
- Lightweight VAD to split a continuous stream into speech chunks.
- Concurrent streams with safe engine batching.
- Stream affinity so sequential chunks stay on one GPU when possible.
- Previous transcript as the next chunk's prefix to improve recognition.

Whisper still processes discrete chunks. VAD and orchestration can dominate after model optimization.

### Long-file ASR

Whisper accepts up to 30-second chunks in the source. Long files need a pipeline:

1. Run VAD on separate capacity to remove silence and split at meaningful speech boundaries. Fixed cuts can split words.
2. Transcribe chunks in parallel across GPUs or MIGs.
3. Use in-flight batching within each worker.
4. Merge by timestamp.

Use source-style speed factor:

```text
audio duration / processing duration
```

Throughput rises roughly linearly with workers until VAD, merge, storage, network, or scheduling becomes the limit.

Parallel chunks cannot all use previous transcript context. Postprocessing and retries can recover quality.

### Whisper repetition recovery

Detect likely hallucination loops with abnormal compression ratio and words per minute. For a suspicious chunk:

1. Retry at higher temperature to escape the repetitive loop.
2. If needed, re-segment the audio or local region into smaller chunks.

Higher temperature is counterintuitive and specific to breaking repetitive decode loops. It is not a general anti-hallucination rule.

### Diarization

Diarization identifies speaker intervals through segmentation, speaker embeddings, and clustering. It is a classic multi-model pipeline, not Whisper token generation. The source names pyannote audio, PyTorch, and Torch compilation.

The source says optimized diarization can take at least twice as long as transcription for the same file. Capacity-plan and measure it separately.

### ASR checklist

- [ ] State the RTF convention.
- [ ] Measure complete chunk round trip for real-time service.
- [ ] Use VAD and persistent WebSockets.
- [ ] Keep stream chunks on one worker where possible.
- [ ] Use previous transcript as context when sequential quality matters.
- [ ] For long files, split at speech boundaries and parallelize.
- [ ] Detect repetition with compression and WPM.
- [ ] Use high-temperature retry only for a detected loop.
- [ ] Re-chunk failed regions.
- [ ] Scale diarization separately.

## Text-to-speech

Modern source-era open TTS models can be fine-tuned LLMs. Orpheus derives from Llama 3.2 3B, near the large end of the source class. The vocabulary adds tens of thousands of audio tokens. Serving has two stages:

1. An autoregressive token model generates codec tokens.
2. An audio decoder converts them to waveform.

The decoder can become the bottleneck. The source suggests PyTorch, compilation on the target GPU, and dynamic batching with a 15 ms timeout. It says in-flight batching is not available for this decoder. Verify current stack.

Small size makes H100 MIG practical. The source uses FP8 weights and KV and TensorRT-LLM in-flight batching for the token model. ASR in the same discussion remains FP16.

### Metrics and targets

- TTFB is time to first audio byte.
- First sentence or meaningful phrase better captures useful playback.
- Audio-token TPS measures autoregressive decode.
- Stable concurrent real-time streams determines useful capacity.

The source cites Orpheus TTFB as low as 150 ms on one H100. Treat this as a workload-specific source claim.

Real-time playback needs roughly 80 to 100 tokens/s depending on codec. Once each stream exceeds real-time speed, more per-user TPS has no product value. Use the margin for more streams or lower cost.

### Streaming TTS

Use WebSockets to stream audio. Load test the safe active stream count, then align token-model batch and per-replica WebSocket cap to it. This prevents unstable queue growth.

The source example combines TensorRT-LLM, FP8, and a compiled SNAC decoder. Verify support and alternatives.

TTS is rarely a batch workload. For bulk document-to-audio, split long text because the source says quality can degrade after roughly 30 seconds of generated audio.

### Speech-to-speech

The common cascade is:

```text
audio -> VAD/ASR -> LLM with context -> TTS -> audio
```

A direct speech-to-speech model joins audio input, reasoning, and output around one model. The source cites OpenAI `gpt-realtime` and claims no commercially viable open equivalent at publication, while closed direct systems were less capable and more expensive than cascades. These are time-sensitive market comparisons.

### TTS checklist

- [ ] Measure token model and waveform decoder separately.
- [ ] Report TTFB and first meaningful phrase.
- [ ] Reach 80 to 100 audio tokens/s, then optimize concurrency and cost.
- [ ] Compile decoder on production GPU.
- [ ] Test the source's 15 ms dynamic-batch starting point.
- [ ] Align batch and WebSocket cap with measured streams.
- [ ] Split output near 30 seconds when quality degrades.
- [ ] Compare a direct speech model with a cascade on current quality, latency, and cost.

## Image generation

Most image generators are iterative latent denoising pipelines. Tooling was less mature than LLM serving in the source. SGLang Diffusion and vLLM Omni were new, while PyTorch and TensorRT were common.

The source says image generators are typically 10 to 20 times smaller than frontier LLMs and become compute-bound after memory inefficiencies are removed. Verify with profiles.

Quality-speed controls include denoising steps, classifier-free guidance, resolution, aspect ratio, prompt, negative prompt, adapters, and model choice. Human pairwise preference is a stronger final quality test than a VLM judge alone.

The source uses this architecture comparison to show why pipeline growth raises serving cost:

| Component | SDXL, 2023 | Qwen Image, 2025 |
|---|---:|---:|
| Text encoder | CLIP-based | Qwen 2.5 VL, 7B |
| Denoiser | Under 4B | 20B |
| VAE | Single encoding | Dual encoding |

It attributes newer gains in prompt following, detail, faces, hands, text rendering, and image-to-image work partly to full language or vision-language encoders, a roughly 5x larger denoiser in this example, and a more involved pipeline. These are source-era examples, not a current ranking.

Some image research tokenizes output and uses autoregressive or hybrid language-model designs, which can allow variable output lengths. The source names HunyuanImage-3.0. Verify its current architecture and runtime rather than applying diffusion assumptions automatically.

### Kernel optimization order

1. Select an attention kernel. Source recommendation: test FlashAttention 3 on Hopper and FlashAttention 4 on Blackwell rather than accepting a FlashAttention 2 default.
2. Fuse small operations, especially RMSNorm and other normalization.
3. Tune compute-bound GEMM for linear layers. FP8 can expose about 2x peak Tensor Core FLOPS. Test CuTe, CUTLASS, and DeepGEMM.
4. Use `torch.compile` for visible fusion and selected plugins for hot kernels.
5. Cache compiled engines because compilation can take minutes.
6. Compile on the production architecture, for example B200 on B200.

A basic Diffusers example is unlikely to be production-optimized. Profile text encoder, denoiser, VAE, adapters, and transfers.

### Step count and guidance

Conventional high-quality generation often uses 30 to 50 steps. Few-step systems use eight or fewer and can cut source-reported time by 80 to 90 percent with visible quality loss. Latent consistency predicts a target latent and often refines it two to four times. Distillation trains an accelerated model to imitate a slower teacher through methods such as adversarial or progressive distillation. The source says community derivatives of FLUX and Qwen Image used distillation more often than latent consistency. Treat this as a January 2026 snapshot.

Classifier-free guidance normally executes conditioned and unconditioned passes. At 50 steps:

```text
50 steps x 2 = 100 denoiser passes
```

Early steps establish composition and prompt adherence. Later steps add detail. If guidance becomes zero late, skip the prompt-conditioned or redundant guidance pass as the implementation permits.

Source example:

```text
first 30 steps x 2 passes + last 20 x 1 pass = 80 passes
```

This cuts passes 20 percent, from 100 to 80, while the source reports high quality. Validate cutoff per model, sampler, prompt set, resolution, and implementation.

### Image checklist

- [ ] Count actual denoiser passes, not UI-visible steps.
- [ ] Profile every pipeline component and transfer.
- [ ] Benchmark architecture-specific attention kernels.
- [ ] Fuse measured small-operation hot paths.
- [ ] Quantize GEMM only with image quality checks.
- [ ] Cache exact compiled artifacts.
- [ ] Compare 30 to 50 step baseline with few-step model.
- [ ] Test late guidance cutoff.
- [ ] Use broad prompts and human pairwise review.

## Video generation

Video is the most demanding source modality. Current source-era systems usually run around 50 denoising steps over width, height, and time in one latent clip.

A common deployment uses eight GPUs at batch 1 for one video. One job already consumes the node, so batching does not create the familiar text latency-throughput trade. Faster execution improves both throughput and cost.

The source says attention consumes 70 to 80 percent of video compute. Treat this as a profiling hypothesis.

### Kernels, caches, and precision

Benchmark FlashAttention, DeepGEMM, CuTe, CUTLASS, and model-specific kernels on the target GPU.

Video does not use an autoregressive LLM KV cache. It can reuse intermediate denoising work:

- Timestep caching reuses output from selected steps and skips steps.
- Transformer caching reuses hidden states and skips selected layers.

The source gives 30 to 40 percent faster generation as a practical range. Quality can range from negligible loss to unusable output. Test motion and full clips.

Quantization mainly accesses faster Tensor Cores, not decode bandwidth. Linear weights dominate stored bytes but can be a small compute share. Attention quantization has greater upside and greater risk.

Attention errors compound through around 50 denoising iterations. This is fewer than thousands of LLM token steps but still material.

Risk controls:

- Use block scales and MXFP8 for outliers where hardware and kernels support it.
- Keep early steps FP16 because they set composition and prompt adherence, then lower later-step precision.
- Keep first and last layers native, quantize middle layers.
- Test a purpose-built kernel such as SageAttention, described by the source as 8-bit attention.

Verify MXFP8 support. The source is inconsistent about Hopper versus Blackwell.

### Context parallelism

Video normally uses CP rather than TP. The model weights can fit and be replicated, while latent attention is too large for one GPU.

Ring attention:

- Each GPU owns part of context.
- It computes partial attention.
- Partial results pass around a ring.

Multi-head attention also has natural parallel work, with usually eight or more heads in the source account.

The VAE decoder takes about 3 to 5 percent of total inference time in the source and can also run across GPUs. Optimize attention first.

The source recommends Blackwell, or Rubin when shipped, for capacity, compute, and microscaling. This is a vendor-era recommendation. Benchmark current inventory and software.

### Video checklist

- [ ] Profile attention share rather than assuming 70 to 80 percent.
- [ ] Measure one full eight-GPU batch-1 job as the baseline where applicable.
- [ ] Compare CP with TP and verify weight replication cost.
- [ ] Measure ring and fabric communication.
- [ ] Benchmark attention kernels on exact model and GPU.
- [ ] Test timestep and transformer caching separately.
- [ ] Validate the source's 30 to 40 percent range on full clips.
- [ ] Quantize by step or layer before quantizing all attention.
- [ ] Check motion, temporal consistency, physics, prompt adherence, and artifacts.
- [ ] Include VAE decode, even though its source share is only 3 to 5 percent.

## Modality optimization matrix

| Modality | Likely bottleneck | Scale pattern | First optimizations | Quality gate |
|---|---|---|---|---|
| VLM | Media prefill and KV | TP or disaggregation for large models | Downsampling, KV FP8, prefix cache, attention, EAGLE | Visual task eval at each resolution |
| Embedding | Batch work or query tail | One GPU or partition per replica | Engine comparison, FP8 weights, large dynamic batches | 99% source cosine heuristic plus retrieval |
| Real-time ASR | Decoder and stream path | MIG and concurrent streams | TensorRT-LLM source path, WebSocket, VAD, affinity | Word/product accuracy |
| Long ASR | Parallel pipeline | GPUs or MIGs | VAD chunks, parallel decode, batching, timestamp merge | Loop detection and retry |
| Diarization | Multi-model pipeline | Independent stage | Compile and stage tuning | Speaker accuracy |
| TTS | Token decode and waveform decoder | MIG and streams | FP8, in-flight token batching, compiled decoder, 15 ms batch | First phrase and audio quality |
| Image | Compute after memory cleanup | One job per setup | Attention, fusion, FP8 GEMM, compile, guidance cutoff | Human preference |
| Video | Attention | Eight-GPU batch 1 and CP | Attention kernels, cache, selective precision, ring | Full temporal evaluation |

## Cross-modality benchmark plan

- [ ] Define first useful output for the user.
- [ ] Separate interactive and backfill pools.
- [ ] Include preprocessing and postprocessing.
- [ ] Scale each pipeline stage independently.
- [ ] Tune VLM frame rate and resolution jointly.
- [ ] Test embedding truncation against retrieval and database cost.
- [ ] Cap speech WebSockets from load-test results.
- [ ] Stop adding long-ASR workers when scaling ceases to be near-linear.
- [ ] Compile image and video artifacts on production hardware.
- [ ] Inspect temporal quality for every video speed method.
- [ ] Recheck all model, engine, and hardware claims in current official sources.
