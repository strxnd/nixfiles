import assert from "node:assert/strict";
import test from "node:test";
import {
  formatTimeToFirstToken,
  formatTokenSpeed,
  TokenSpeedTracker,
} from "./src/token-speed.ts";

test("measures exact output throughput across model steps without tool time", () => {
  let now = 0;
  const tracker = new TokenSpeedTracker(() => now);

  tracker.startRequest();
  now = 1000;
  tracker.startStream();
  now = 1200;
  tracker.addDelta("first output");
  now = 3000;
  tracker.finish(20);

  now = 10_000;
  tracker.startRequest();
  now = 12_000;
  tracker.startStream();
  now = 12_500;
  tracker.addDelta("second output");
  now = 15_000;
  tracker.finish(30);

  assert.equal(tracker.tokensPerSecond(), 10);
  assert.equal(tracker.timeToFirstTokenMs(), 2500);
});

test("does not report throughput before exact provider usage is available", () => {
  let now = 0;
  const tracker = new TokenSpeedTracker(() => now);

  tracker.startRequest();
  now = 500;
  tracker.startStream();
  now = 1000;
  tracker.addDelta("streaming output");

  assert.equal(tracker.tokensPerSecond(), null);
});

test("omits a step whose stream duration is unavailable", () => {
  const tracker = new TokenSpeedTracker(() => 100);

  tracker.finish(20);

  assert.equal(tracker.tokensPerSecond(), null);
});

test("measures TTFT from provider request to first output", () => {
  let now = 100;
  const tracker = new TokenSpeedTracker(() => now);

  tracker.startRequest();
  now = 850;
  tracker.addDelta("hello");

  assert.equal(tracker.timeToFirstTokenMs(), 750);
});

test("reset drops the previous turn", () => {
  let now = 0;
  const tracker = new TokenSpeedTracker(() => now);

  tracker.startRequest();
  tracker.startStream();
  now = 1000;
  tracker.addDelta("output");
  tracker.finish(10);
  tracker.reset();

  assert.equal(tracker.tokensPerSecond(), null);
  assert.equal(tracker.timeToFirstTokenMs(), null);
});

test("formats speed, TTFT, and unavailable values", () => {
  assert.equal(formatTokenSpeed(38.46), "38.5 tok/s");
  assert.equal(formatTokenSpeed(null), "—— tok/s");
  assert.equal(formatTokenSpeed(Number.POSITIVE_INFINITY), "—— tok/s");
  assert.equal(formatTimeToFirstToken(742.4), "TTFT 742ms");
  assert.equal(formatTimeToFirstToken(1542), "TTFT 1.54s");
  assert.equal(formatTimeToFirstToken(null), "TTFT ——");
});
