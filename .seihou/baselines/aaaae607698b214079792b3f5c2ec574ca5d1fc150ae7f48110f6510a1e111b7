import { readFileSync } from "node:fs";

// Shared by both initializers and record-provenance; never infer identity from
// configuration defaults, another session, or a parent agent's model.
export const modelOptions = {
  model: { type: "string" },
  harness: { type: "string" },
  "codex-session-file": { type: "string" },
  "codex-session-id": { type: "string" },
  "claude-session-file": { type: "string" },
  "claude-session-id": { type: "string" },
  "claude-agent-id": { type: "string" },
  "allow-unknown": { type: "boolean", default: false },
  "unknown-reason": { type: "string" },
} as const;

export const modelHelp = `  --model <id>            Exact runtime model ID (or use a session file below).
  --harness <name>        Harness name, e.g. claude-code or codex-cli.
  --codex-session-file <path>
                          Read the latest turn's model from this exact JSONL file.
  --codex-session-id <id> Expected session ID; defaults to CODEX_THREAD_ID, then
                          CODEX_SESSION_ID. Must identify the current agent.
  --claude-session-file <path>
                          Read the current turn's model from a Claude Code JSONL file.
  --claude-session-id <id> Required expected Claude Code session ID.
  --claude-agent-id <id>   Required for a Claude subagent's own transcript.
  --allow-unknown         Permit --model unknown only after discovery fails.
  --unknown-reason <text> Required with --allow-unknown; saved in the entry's note.`;

type ModelArgs = {
  model?: string;
  harness?: string;
  "codex-session-file"?: string;
  "codex-session-id"?: string;
  "claude-session-file"?: string;
  "claude-session-id"?: string;
  "claude-agent-id"?: string;
  "allow-unknown"?: boolean;
  "unknown-reason"?: string;
};

function* records(contents: string) {
  for (const line of contents.split("\n")) {
    if (!line.trim()) continue;
    // Fail closed on malformed/incomplete records instead of reusing an older
    // turn's model. Do not include log content in diagnostics.
    let record;
    try {
      record = JSON.parse(line);
    } catch {
      throw new Error("Session file contains an invalid JSON record; retry after the write completes");
    }
    yield record;
  }
}

function exactModel(model: unknown, source: string): string {
  if (typeof model !== "string" || !model.trim() || model.trim().toLowerCase() === "unknown" || model.trim().startsWith("<")) {
    throw new Error(`${source} has no exact model ID; do not reuse an earlier turn`);
  }
  return model.trim();
}

export function codexModel(contents: string, expectedId: string): string {
  let sessionId: string | undefined;
  let sawSession = false;
  let latestModel: unknown;
  for (const record of records(contents)) {
    if (record?.type === "session_meta") {
      if (sawSession) throw new Error("Codex session file has multiple session_meta records");
      sawSession = true;
      sessionId = record.payload?.id;
    }
    if (record?.type === "turn_context") latestModel = record.payload?.model;
  }
  if (!expectedId.trim() || sessionId !== expectedId) {
    throw new Error("Codex session_meta.id does not match the expected current-agent session ID");
  }
  return exactModel(latestModel, "The latest Codex turn_context");
}

export function claudeModel(contents: string, expectedId: string, agentId?: string): string {
  let latestModel: unknown;
  for (const record of records(contents)) {
    if (record?.type !== "assistant" && record?.type !== "user") continue;
    if (!expectedId.trim() || record.sessionId !== expectedId) {
      throw new Error("Claude transcript sessionId does not match the expected session ID");
    }
    if (agentId ? record.agentId !== agentId : record.agentId != null || record.isSidechain === true) {
      throw new Error("Claude transcript agent identity mismatch; select this agent's own transcript and --claude-agent-id for subagents");
    }
    if (record.type === "assistant") latestModel = record.message?.model;
    else {
      const content = record.message?.content;
      const toolResult = Array.isArray(content) && content.length > 0 && content.every((item) => item?.type === "tool_result");
      // A new user prompt may start a turn after /model; tool results continue
      // the existing assistant turn. Never carry an old model across a prompt.
      if (!toolResult) latestModel = undefined;
    }
  }
  return exactModel(latestModel, "The current Claude assistant turn");
}

export function resolveModel(args: ModelArgs, env = process.env) {
  let model = args.model?.trim();
  let harness = args.harness?.trim() || undefined;
  const codexFile = args["codex-session-file"];
  const claudeFile = args["claude-session-file"];
  if (codexFile !== undefined && claudeFile !== undefined) throw new Error("Choose one harness's session file, not both");
  if (codexFile === undefined && args["codex-session-id"] !== undefined) throw new Error("--codex-session-id requires --codex-session-file");
  if (claudeFile === undefined && (args["claude-session-id"] !== undefined || args["claude-agent-id"] !== undefined)) {
    throw new Error("--claude-session-id and --claude-agent-id require --claude-session-file");
  }
  const sessionFile = codexFile ?? claudeFile;
  if (sessionFile !== undefined) {
    if (!sessionFile.trim()) throw new Error("Session file path must not be empty");
    if (args.model !== undefined) throw new Error("Choose --model or a session file, not both");
    const expectedHarness = codexFile !== undefined ? "codex-cli" : "claude-code";
    if (harness && harness !== expectedHarness) throw new Error(`Session file requires harness ${expectedHarness}`);
    const sessionId = codexFile !== undefined
      ? args["codex-session-id"] ?? env.CODEX_THREAD_ID ?? env.CODEX_SESSION_ID
      : args["claude-session-id"];
    if (!sessionId?.trim()) throw new Error("Session discovery requires the current agent's session ID");
    if (args["claude-agent-id"] !== undefined && !args["claude-agent-id"].trim()) throw new Error("--claude-agent-id must not be empty");
    let contents: string;
    try {
      contents = readFileSync(sessionFile, "utf8");
    } catch {
      throw new Error("Cannot read session file; check the selected path and access permissions");
    }
    model = codexFile !== undefined ? codexModel(contents, sessionId) : claudeModel(contents, sessionId, args["claude-agent-id"]);
    harness = expectedHarness;
  }
  if (!model) throw new Error("--model or a session file is required; follow PROVENANCE.md before using unknown");
  const reason = args["unknown-reason"]?.trim();
  let note: string | undefined;
  if (model.toLowerCase() === "unknown") {
    if (!args["allow-unknown"] || !reason) {
      throw new Error("unknown requires --allow-unknown and --unknown-reason after runtime model discovery fails (see PROVENANCE.md)");
    }
    if (/[\r\n]/.test(reason)) throw new Error("--unknown-reason must be one line");
    model = "unknown";
    note = `Model discovery unavailable: ${reason}`;
  } else if (args["allow-unknown"] || args["unknown-reason"] !== undefined) {
    throw new Error("--allow-unknown and --unknown-reason apply only to --model unknown");
  }
  return { model, harness, note };
}
