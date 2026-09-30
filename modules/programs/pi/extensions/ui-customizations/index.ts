import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createFooter } from "./src/footer.ts";
import { TokenSpeedTracker } from "./src/token-speed.ts";

export default function (pi: ExtensionAPI) {
  const speed = new TokenSpeedTracker();

  pi.on("session_start", (_event, ctx) => {
    speed.reset();
    if (ctx.mode !== "tui") return;

    ctx.ui.setFooter((tui, theme, footerData) =>
      createFooter(ctx, theme, footerData, speed, () => tui.requestRender()),
    );
  });

  pi.on("agent_start", () => {
    speed.reset();
  });

  pi.on("before_provider_request", () => {
    speed.startRequest();
  });

  pi.on("message_start", (event) => {
    if (event.message.role === "assistant") speed.startStream();
  });

  pi.on("message_update", (event) => {
    const streamEvent = event.assistantMessageEvent;
    if (
      streamEvent.type === "text_delta" ||
      streamEvent.type === "thinking_delta" ||
      streamEvent.type === "toolcall_delta"
    ) {
      speed.addDelta(streamEvent.delta);
    }
  });

  pi.on("message_end", (event) => {
    if (event.message.role === "assistant") {
      speed.finish(event.message.usage.output);
    }
  });
}
