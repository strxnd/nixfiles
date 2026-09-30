import { spawn, type ChildProcess } from "node:child_process";
import { createWriteStream } from "node:fs";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  truncateHead,
} from "@earendil-works/pi-coding-agent";
import { Effect } from "effect";
import type { CapturedOutput } from "./output.ts";

const STDERR_MAX_BYTES = 64 * 1024;

interface PreviewState {
  readonly decoder: TextDecoder;
  preview: string;
  totalBytes: number;
  lineBreaks: number;
  trailingLineBreaks: number;
  truncated: boolean;
}

function makePreviewState(): PreviewState {
  return {
    decoder: new TextDecoder(),
    preview: "",
    totalBytes: 0,
    lineBreaks: 0,
    trailingLineBreaks: 0,
    truncated: false,
  };
}

function observeStdout(state: PreviewState, chunk: Uint8Array) {
  state.totalBytes += chunk.byteLength;
  for (const byte of chunk) {
    if (byte === 0x0a) {
      state.lineBreaks++;
      state.trailingLineBreaks++;
    } else {
      state.trailingLineBreaks = 0;
    }
  }

  if (state.truncated) return;
  state.preview += state.decoder.decode(chunk, { stream: true });
  const truncation = truncateHead(state.preview, {
    maxLines: DEFAULT_MAX_LINES,
    maxBytes: DEFAULT_MAX_BYTES,
  });
  if (truncation.truncated) {
    state.preview = truncation.content;
    state.truncated = true;
  }
}

function finishStdout(state: PreviewState, fullOutputPath: string) {
  if (!state.truncated) state.preview += state.decoder.decode();
  const totalBytes = state.totalBytes - state.trailingLineBreaks;
  const lineCount =
    totalBytes === 0 ? 0 : state.lineBreaks - state.trailingLineBreaks + 1;
  return {
    preview: state.preview,
    lineCount,
    totalBytes,
    truncated: state.truncated,
    fullOutputPath: state.truncated ? fullOutputPath : undefined,
  } satisfies CapturedOutput;
}

interface SearchChildResult {
  readonly code: number;
  readonly stderr: string;
  readonly output: CapturedOutput;
}

function runSearchChild(
  options: {
    readonly command: string;
    readonly args: readonly string[];
    readonly cwd: string;
    readonly fullOutputPath: string;
  },
  signal: AbortSignal | undefined,
): Promise<SearchChildResult> {
  const preview = makePreviewState();
  const stderrChunks: Buffer[] = [];
  let stderrBytes = 0;

  return new Promise((resolve, reject) => {
    let child: ChildProcess | undefined;
    let settled = false;
    let lastCode: number | null = null;
    let closed = false;
    let outFinished = false;
    let stderrEnded = false;

    const finish = (value: SearchChildResult, error?: unknown) => {
      if (settled) return;
      settled = true;
      signal?.removeEventListener("abort", onAbort);
      if (error) reject(error);
      else resolve(value);
    };

    const maybeFinish = () => {
      if (closed && outFinished && stderrEnded && !settled) {
        const output = finishStdout(preview, options.fullOutputPath);
        finish({
          code: lastCode ?? -1,
          stderr: Buffer.concat(stderrChunks, stderrBytes).toString("utf8"),
          output,
        });
      }
    };

    const onAbort = () => child?.kill("SIGKILL");
    signal?.addEventListener("abort", onAbort, { once: true });

    let outStream: ReturnType<typeof createWriteStream> | undefined;
    try {
      child = spawn(options.command, [...options.args], {
        cwd: options.cwd,
        stdio: ["ignore", "pipe", "pipe"],
      });
    } catch (error) {
      finish(
        {
          code: 1,
          stderr: String(error),
          output: {
            preview: "",
            lineCount: 0,
            totalBytes: 0,
            truncated: false,
          },
        },
        undefined,
      );
      return;
    }

    outStream = createWriteStream(options.fullOutputPath);
    outStream.on("close", () => {
      outFinished = true;
      maybeFinish();
    });
    outStream.on("error", (error) => {
      finish(
        {
          code: 1,
          stderr: `failed to write output: ${error.message}`,
          output: {
            preview: "",
            lineCount: 0,
            totalBytes: 0,
            truncated: false,
          },
        },
        undefined,
      );
    });

    child.stdout?.on("data", (chunk: Buffer) => {
      observeStdout(preview, chunk);
      if (outStream && !outStream.write(chunk)) child?.stdout?.pause();
    });
    child.stdout?.on("resume", () => outStream?.emit("drain"));
    child.stderr?.on("data", (chunk: Buffer) => {
      if (stderrBytes < STDERR_MAX_BYTES) {
        const remaining = STDERR_MAX_BYTES - stderrBytes;
        const bounded = chunk.subarray(0, remaining);
        stderrChunks.push(Buffer.from(bounded));
        stderrBytes += bounded.byteLength;
      }
    });
    child.stderr?.on("end", () => {
      stderrEnded = true;
      maybeFinish();
    });
    child.on("error", (error) => {
      finish(
        {
          code: 1,
          stderr: `Failed to run ${options.command}: ${error.message}`,
          output: {
            preview: "",
            lineCount: 0,
            totalBytes: 0,
            truncated: false,
          },
        },
        undefined,
      );
    });
    child.on("close", (code) => {
      lastCode = code;
      closed = true;
      outStream?.end();
      maybeFinish();
    });
  });
}

export function executeSearchProcess(options: {
  readonly command: string;
  readonly args: readonly string[];
  readonly cwd: string;
  readonly tempPrefix: string;
}) {
  return Effect.tryPromise({
    try: async (signal) => {
      const directory = await mkdtemp(join(tmpdir(), options.tempPrefix));
      const fullOutputPath = join(directory, "output.txt");
      try {
        const result = await runSearchChild(
          {
            command: options.command,
            args: options.args,
            cwd: options.cwd,
            fullOutputPath,
          },
          signal,
        );
        if (!result.output.truncated) {
          await rm(directory, { recursive: true, force: true }).catch(() => {});
        }
        return result;
      } catch (error) {
        await rm(directory, { recursive: true, force: true }).catch(() => {});
        throw error;
      }
    },
    catch: (error) =>
      ({
        code: 1,
        stderr: error instanceof Error ? error.message : String(error),
        output: { preview: "", lineCount: 0, totalBytes: 0, truncated: false },
      }) satisfies SearchChildResult,
  }).pipe(Effect.catch((fallback) => Effect.succeed(fallback)));
}

export function discardCapturedOutput(output: CapturedOutput) {
  if (!output.fullOutputPath) return Effect.void;
  const directory = dirname(output.fullOutputPath);
  return Effect.tryPromise(() =>
    rm(directory, { recursive: true, force: true }),
  ).pipe(Effect.orDie);
}
