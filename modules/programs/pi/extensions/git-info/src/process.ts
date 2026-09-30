import { spawn, type ChildProcess } from "node:child_process";
import { Context, Effect, Layer } from "effect";

const MAX_STREAM_CHARS = 10 * 1_024 * 1_024;
const TRUNCATED_MARKER = "\n[command output truncated]\n";

function appendBounded(current: string, chunk: string) {
  if (current.endsWith(TRUNCATED_MARKER)) return current;
  if (current.length + chunk.length <= MAX_STREAM_CHARS) return current + chunk;
  const remaining = Math.max(0, MAX_STREAM_CHARS - current.length);
  return `${current}${chunk.slice(0, remaining)}${TRUNCATED_MARKER}`;
}

export interface CommandResult {
  code: number;
  stderr: string;
  stdout: string;
}

interface CommandRunnerShape {
  run(
    command: string,
    args: string[],
    cwd: string,
    timeout: number,
  ): Effect.Effect<CommandResult>;
}

export class CommandRunner extends Context.Service<
  CommandRunner,
  CommandRunnerShape
>()("git-info/CommandRunner") {}

function appendCommandFailure(stderr: string, command: string, error: Error) {
  const failure = `Failed to run ${command}: ${error.message}`;
  return stderr ? `${stderr.trimEnd()}\n${failure}` : failure;
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : String(error);
}

/**
 * Spawn a command, capture bounded stdout/stderr, and resolve when the process
 * closes. On abort or timeout the process tree is killed and the result
 * reports exit code -1 (matching the previous timeout behavior).
 */
function runChild(
  command: string,
  args: string[],
  cwd: string,
  timeoutMs: number,
  signal: AbortSignal | undefined,
): Promise<CommandResult> {
  return new Promise((resolve) => {
    let child: ChildProcess | undefined;
    let stderr = "";
    let stdout = "";
    let settled = false;
    let timer: ReturnType<typeof setTimeout> | undefined;

    const finish = (result: CommandResult) => {
      if (settled) return;
      settled = true;
      signal?.removeEventListener("abort", onAbort);
      if (timer) clearTimeout(timer);
      resolve(result);
    };

    const onAbort = () => child?.kill("SIGKILL");
    signal?.addEventListener("abort", onAbort, { once: true });

    try {
      child = spawn(command, args, {
        cwd,
        stdio: ["ignore", "pipe", "pipe"],
      });
    } catch (error) {
      finish({
        code: 1,
        stderr: appendCommandFailure(
          "",
          command,
          new Error(errorMessage(error)),
        ),
        stdout: "",
      });
      return;
    }

    child.on("error", (error) =>
      finish({
        code: 1,
        stderr: appendCommandFailure(stderr, command, error),
        stdout,
      }),
    );
    child.on("close", (code) => finish({ code: code ?? -1, stderr, stdout }));
    child.stdout?.on("data", (chunk: Buffer) => {
      stdout = appendBounded(stdout, chunk.toString("utf8"));
    });
    child.stderr?.on("data", (chunk: Buffer) => {
      stderr = appendBounded(stderr, chunk.toString("utf8"));
    });

    timer = setTimeout(() => child?.kill("SIGKILL"), timeoutMs);
    timer.unref?.();
  });
}

export const CommandRunnerLive = Layer.effect(
  CommandRunner,
  Effect.sync(() =>
    CommandRunner.of({
      run: (command, args, cwd, timeout) =>
        Effect.tryPromise({
          try: (signal) => runChild(command, args, cwd, timeout, signal),
          catch: (error) =>
            ({
              code: 1,
              stderr: appendCommandFailure(
                "",
                command,
                new Error(errorMessage(error)),
              ),
              stdout: "",
            }) satisfies CommandResult,
        }).pipe(Effect.catch((fallback) => Effect.succeed(fallback))),
    }),
  ),
);

export const runCommand = (
  command: string,
  args: string[],
  cwd: string,
  timeout: number,
) =>
  Effect.gen(function* () {
    const commands = yield* CommandRunner;
    return yield* commands.run(command, args, cwd, timeout);
  });
