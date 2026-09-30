import type { Usage } from "@earendil-works/pi-ai";
import type {
  ExtensionContext,
  ReadonlyFooterDataProvider,
  Theme,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import {
  formatTimeToFirstToken,
  formatTokenSpeed,
  type TokenSpeedTracker,
} from "./token-speed.ts";

interface UsageTotals {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
}

function formatTokens(count: number) {
  if (count < 1000) return count.toString();
  if (count < 10_000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1_000_000) return `${Math.round(count / 1000)}k`;
  if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
  return `${Math.round(count / 1_000_000)}M`;
}

function addUsage(totals: UsageTotals, usage: Usage) {
  totals.input += usage.input;
  totals.output += usage.output;
  totals.cacheRead += usage.cacheRead;
  totals.cacheWrite += usage.cacheWrite;
  totals.cost += usage.cost.total;
}

function collectUsage(ctx: ExtensionContext) {
  const totals: UsageTotals = {
    input: 0,
    output: 0,
    cacheRead: 0,
    cacheWrite: 0,
    cost: 0,
  };
  let latestCacheHitRate: number | undefined;

  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type === "message" && entry.message.role === "assistant") {
      addUsage(totals, entry.message.usage);
      const promptTokens =
        entry.message.usage.input +
        entry.message.usage.cacheRead +
        entry.message.usage.cacheWrite;
      latestCacheHitRate =
        promptTokens > 0
          ? (entry.message.usage.cacheRead / promptTokens) * 100
          : undefined;
      continue;
    }

    if (
      entry.type === "message" &&
      entry.message.role === "toolResult" &&
      entry.message.usage
    ) {
      addUsage(totals, entry.message.usage);
      continue;
    }

    if (
      (entry.type === "branch_summary" || entry.type === "compaction") &&
      entry.usage
    ) {
      addUsage(totals, entry.usage);
    }
  }

  return { totals, latestCacheHitRate };
}

function contextUsage(ctx: ExtensionContext, theme: Theme) {
  const usage = ctx.getContextUsage();
  const contextWindow = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
  const percent = usage?.percent;
  const text = `${percent === null || percent === undefined ? "?" : percent.toFixed(1)}%/${formatTokens(contextWindow)}`;

  if ((percent ?? 0) > 90) return theme.fg("error", text);
  if ((percent ?? 0) > 70) return theme.fg("warning", text);
  return theme.fg("dim", text);
}

function sanitizeStatus(text: string) {
  return text
    .replace(/[\r\n\t]/g, " ")
    .replace(/ +/g, " ")
    .trim();
}

function footerPath(
  ctx: ExtensionContext,
  footerData: ReadonlyFooterDataProvider,
) {
  let path = ctx.sessionManager.getCwd();
  const home = process.env.HOME ?? process.env.USERPROFILE;

  if (home && path === home) {
    path = "~";
  } else if (home && path.startsWith(`${home}/`)) {
    path = `~${path.slice(home.length)}`;
  }

  const branch = footerData.getGitBranch();
  if (branch) path += ` (${branch})`;

  const sessionName = ctx.sessionManager.getSessionName();
  if (sessionName) path += ` • ${sessionName}`;

  return path;
}

function leftStats(
  ctx: ExtensionContext,
  theme: Theme,
  speed: TokenSpeedTracker,
) {
  const { totals, latestCacheHitRate } = collectUsage(ctx);
  const parts: string[] = [];

  if (totals.input)
    parts.push(theme.fg("dim", `↑${formatTokens(totals.input)}`));
  if (totals.output)
    parts.push(theme.fg("dim", `↓${formatTokens(totals.output)}`));
  if (totals.cacheRead)
    parts.push(theme.fg("dim", `R${formatTokens(totals.cacheRead)}`));
  if (totals.cacheWrite)
    parts.push(theme.fg("dim", `W${formatTokens(totals.cacheWrite)}`));
  if (
    (totals.cacheRead > 0 || totals.cacheWrite > 0) &&
    latestCacheHitRate !== undefined
  ) {
    parts.push(theme.fg("dim", `CH${latestCacheHitRate.toFixed(1)}%`));
  }
  if (totals.cost || ctx.model?.provider === "kimi-coding") {
    const subscription = ctx.model?.provider === "kimi-coding" ? " (sub)" : "";
    parts.push(theme.fg("dim", `$${totals.cost.toFixed(3)}${subscription}`));
  }

  parts.push(contextUsage(ctx, theme));
  parts.push(theme.fg("dim", formatTokenSpeed(speed.tokensPerSecond())));
  parts.push(
    theme.fg("dim", formatTimeToFirstToken(speed.timeToFirstTokenMs())),
  );
  return parts.join(" ");
}

function modelStatus(
  ctx: ExtensionContext,
  footerData: ReadonlyFooterDataProvider,
) {
  const modelName = ctx.model?.id ?? "no-model";
  let status = modelName;

  if (ctx.model?.reasoning) {
    status =
      ctx.thinkingLevel === "off"
        ? `${modelName} • thinking off`
        : `${modelName} • ${ctx.thinkingLevel}`;
  }

  if (ctx.model && footerData.getAvailableProviderCount() > 1) {
    return {
      full: `(${ctx.model.provider}) ${status}`,
      compact: status,
    };
  }

  return { full: status, compact: status };
}

function alignStats(left: string, right: string, width: number) {
  let fittedLeft = left;
  let leftWidth = visibleWidth(fittedLeft);

  if (leftWidth > width) {
    fittedLeft = truncateToWidth(fittedLeft, width, "...");
    leftWidth = visibleWidth(fittedLeft);
  }

  const availableRight = width - leftWidth - 2;
  if (availableRight <= 0) return fittedLeft;

  const fittedRight = truncateToWidth(right, availableRight, "");
  const padding = " ".repeat(
    Math.max(0, width - leftWidth - visibleWidth(fittedRight)),
  );
  return fittedLeft + padding + fittedRight;
}

export function createFooter(
  ctx: ExtensionContext,
  theme: Theme,
  footerData: ReadonlyFooterDataProvider,
  speed: TokenSpeedTracker,
  requestRender: () => void,
) {
  const unsubscribe = footerData.onBranchChange(requestRender);

  return {
    dispose: unsubscribe,
    invalidate() {},
    render(width: number) {
      const left = leftStats(ctx, theme, speed);
      const model = modelStatus(ctx, footerData);
      const fullModelFits =
        visibleWidth(left) + 2 + visibleWidth(model.full) <= width;
      const stats = alignStats(
        left,
        theme.fg("dim", fullModelFits ? model.full : model.compact),
        width,
      );
      const path = truncateToWidth(
        theme.fg("dim", footerPath(ctx, footerData)),
        width,
        theme.fg("dim", "..."),
      );
      const lines = [path, stats];
      const statuses = [...footerData.getExtensionStatuses().entries()]
        .sort(([leftKey], [rightKey]) => leftKey.localeCompare(rightKey))
        .map(([, text]) => sanitizeStatus(text));

      if (statuses.length > 0) {
        lines.push(
          truncateToWidth(statuses.join(" "), width, theme.fg("dim", "...")),
        );
      }

      return lines;
    },
  };
}
