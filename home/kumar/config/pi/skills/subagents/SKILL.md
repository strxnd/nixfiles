---
name: subagents
description: invoke this skill when the user asks you to use subagents
---

# Subagents

Each subagent is headless, has its own context window, cannot see the parent conversation, cannot ask the user, and cannot spawn subagents or workflows. Give every child a self-contained prompt with paths, constraints, and the expected report.

## Pi Harness

**Harness:** `pi`
**Prompt nicknames:** “pi”, “pi agent”, “pi subagent”
**Best default:** Use when the user does not request another harness. It inherits the parent model and thinking level when `model` or `reasoning_effort` is omitted.

Pi can use any model shown by `pi --list-models`. Prefer `provider/model-id`; a bare model id only works when unambiguous. Common picks in this environment:

| Model                            | Recommended effort |
| -------------------------------- | ------------------ |
| inherited parent model (default) | inherited          |
| `local-spark/deepseek-v4-flash-vision-exp` | `max`              |
| `vllm-local/qwen3.8-27b`         | `max`             |
| `openai-codex/gpt-5.6-terra`     | `high`             |
| `openai-codex/gpt-5.6-sol`       | `high`             |

**Thinking budgets:** `off`, `low`, `high`, `max`. The default parent model (`local-spark/GLM-5.3-Flash-EXL3`) supports only these levels (`minimal`/`medium`/`xhigh` are unmapped). The openai-codex models support `low` and `xhigh`.

Prefer the free local models (`local-spark`, `vllm-local`) for ordinary delegation; reserve the paid `openai-codex` models for tasks where the local model is insufficient.

## Codex Harness

**Harness:** `codex`
**Prompt nicknames:** “codex”, “Codex CLI”, “codex agent”, “codex subagent”
**Best default:** let Codex use its own configured default model; pass `gpt-5.6-sol` only when the user asks for it.

Codex CLI is installed and authenticated on this machine. `reasoning_effort` maps to the model's nearest supported effort; `off`/`minimal` become `minimal`, `max` becomes the highest supported.

## Claude Harness

**Harness:** `claude`
**Not available on this machine** — the Claude Code CLI is not installed. Do not use `agent: "claude"`; if the user wants a Claude run, tell them Claude Code is not installed.

## Spawn and Manage

Call `subagent_spawn` with a complete `prompt`, short `name`, chosen `harness`, and optional `working_dir`, `model`, and `reasoning_effort`. At most four subagents run concurrently.

- `subagent_check({ id })`: peek without blocking.
- `subagent_list()`: list all runs.
- `subagent_wait({ ids })`: block only when results are required to proceed.
- `subagent_cancel({ ids })`: stop runs while preserving partial transcripts.
- `/subagents`: inspect or take over a run interactively.

Results return automatically. After spawning, continue useful parent work instead of immediately waiting.
