export class TokenSpeedTracker {
  private totalOutputTokens = 0;
  private totalStreamDurationMs = 0;
  private requestStartedAt: number | undefined;
  private streamStartedAt: number | undefined;
  private latestTimeToFirstTokenMs: number | undefined;
  private readonly now: () => number;

  constructor(now = () => performance.now()) {
    this.now = now;
  }

  reset() {
    this.totalOutputTokens = 0;
    this.totalStreamDurationMs = 0;
    this.requestStartedAt = undefined;
    this.streamStartedAt = undefined;
    this.latestTimeToFirstTokenMs = undefined;
  }

  startRequest() {
    this.requestStartedAt = this.now();
    this.streamStartedAt = undefined;
    this.latestTimeToFirstTokenMs = undefined;
  }

  startStream() {
    const timestamp = this.now();
    this.requestStartedAt ??= timestamp;
    this.streamStartedAt ??= timestamp;
  }

  addDelta(delta: string) {
    if (!delta || this.latestTimeToFirstTokenMs !== undefined) return;

    const timestamp = this.now();
    this.requestStartedAt ??= timestamp;
    this.streamStartedAt ??= timestamp;
    this.latestTimeToFirstTokenMs = Math.max(
      0,
      timestamp - this.requestStartedAt,
    );
  }

  finish(outputTokens: number) {
    if (this.streamStartedAt === undefined) return;

    const duration = Math.max(0, this.now() - this.streamStartedAt);
    if (Number.isFinite(outputTokens) && outputTokens >= 0 && duration > 0) {
      this.totalOutputTokens += outputTokens;
      this.totalStreamDurationMs += duration;
    }
    this.streamStartedAt = undefined;
  }

  tokensPerSecond() {
    if (this.totalOutputTokens <= 0 || this.totalStreamDurationMs <= 0) {
      return null;
    }

    return this.totalOutputTokens / (this.totalStreamDurationMs / 1000);
  }

  timeToFirstTokenMs() {
    return this.latestTimeToFirstTokenMs ?? null;
  }
}

export function formatTokenSpeed(tokensPerSecond: number | null) {
  if (tokensPerSecond === null || !Number.isFinite(tokensPerSecond)) {
    return "—— tok/s";
  }

  return `${tokensPerSecond.toFixed(1)} tok/s`;
}

export function formatTimeToFirstToken(milliseconds: number | null) {
  if (milliseconds === null || !Number.isFinite(milliseconds)) {
    return "TTFT ——";
  }

  if (milliseconds < 1000) return `TTFT ${Math.round(milliseconds)}ms`;
  return `TTFT ${(milliseconds / 1000).toFixed(2)}s`;
}
