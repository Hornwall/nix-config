import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawn } from "node:child_process";

// Reports session status to `agent-run hook pi <event>` for the Quickshell Agents widget.

function report(event: string, cwd: string, message = ""): void {
  try {
    const child = spawn("agent-run", ["hook", "pi", event], { stdio: ["pipe", "ignore", "ignore"] });
    child.on("error", () => {});
    child.stdin.on("error", () => {});
    child.stdin.end(JSON.stringify({ session_id: String(process.pid), pid: process.pid, cwd, message }));
  } catch {
    // The widget is optional; never disturb the agent.
  }
}

function lastAssistantText(messages: unknown[]): string {
  for (const message of [...messages].reverse() as any[]) {
    if (message?.role !== "assistant") continue;
    const content = typeof message.content === "string" ? [{ type: "text", text: message.content }] : message.content ?? [];
    const text = content.filter((part: any) => part?.type === "text").map((part: any) => part.text).join("\n");
    if (text.trim()) return text;
  }
  return "";
}

export default function (pi: ExtensionAPI) {
  let lastMessage = "";

  pi.on("session_start", (_event, ctx) => report("session_start", ctx.cwd));
  pi.on("agent_start", (_event, ctx) => report("agent_start", ctx.cwd));
  pi.on("agent_end", (event) => {
    lastMessage = lastAssistantText(event.messages);
  });
  pi.on("agent_settled", (event, ctx) => report("agent_settled", ctx.cwd, event.aborted ? "Aborted" : lastMessage));
  pi.on("ui_prompt_start", (event, ctx) => report("ui_prompt_start", ctx.cwd, event.title ?? "Waiting for your answer"));
  pi.on("ui_prompt_end", (_event, ctx) => report("ui_prompt_end", ctx.cwd));
  pi.on("session_shutdown", (_event, ctx) => report("session_shutdown", ctx.cwd));
}
