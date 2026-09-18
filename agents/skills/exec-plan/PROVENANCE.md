# Runtime model discovery

Before creating, revising, or reviewing a plan, resolve the exact model identifier
for the agent that did the work. A missing identifier in your prompt is not evidence
that runtime metadata is unavailable. Both planning skills use this procedure and
the same `provenance-model.ts` helper.

1. Use an exact model identifier explicitly reported by the current agent's runtime
   context, if available. Pass it with `--model` and the known `--harness`.
2. For Codex, if the identifier is not exposed directly, check the current agent's
   session metadata. Locate the session file by its exact `CODEX_THREAD_ID` (or
   `CODEX_SESSION_ID`) within the harness's sessions directory, normally
   `$CODEX_HOME/sessions` or `$HOME/.codex/sessions` when `CODEX_HOME` is unset. Scope
   filename searches to that directory and ID; do not search unrelated logs or dump
   conversation contents. Pass the selected file with `--codex-session-file` instead
   of `--model`. The helper checks `session_meta.id` against the current session ID
   and reads the latest `turn_context.model`, automatically recording `codex-cli`.
   Use `--codex-session-id` only when the actual current agent's ID is known but is
   not correctly exposed in the environment (for example in a delegated harness).
3. For Claude Code, prefer an exact ID from current runtime context. Otherwise use
   `--claude-session-file <transcript_path> --claude-session-id <session_id>` from
   the current session's harness metadata. Claude Code's [hook inputs](https://code.claude.com/docs/en/hooks#common-input-fields)
   expose these paths and IDs; use already-available metadata, without installing
   hooks or changing configuration just for provenance. If locating a file is
   necessary, scope the filename search to the current project's transcript directory
   under `$HOME/.claude/projects` (or the configured Claude directory) and known ID.
   Never choose a session just because its file is newest. The helper checks
   `sessionId` and reads `message.model` from the current turn's latest assistant
   record, recording `claude-code`. It refuses an earlier turn's model if a new
   user prompt has no assistant response yet. For a subagent, select its own
   `agent_transcript_path` and also pass `--claude-agent-id <agent_id>`; a parent's
   transcript is not evidence of a child's model. Do not use `ANTHROPIC_MODEL` as
   runtime evidence: it [does not track in-session model switches](https://code.claude.com/docs/en/hooks).
4. For other harnesses, check their available current-agent runtime metadata. Do not
   guess from configuration defaults, model family names, an earlier turn, another
   session, or the coordinating agent's identity. Each drafting agent resolves its
   own identity. Recheck after a model switch; if another model subsequently changes
   the same plan, append its own entry despite the usual once-per-session rule.
5. Only when these checks cannot supply an exact identifier, use
   `--model unknown --allow-unknown --unknown-reason "<checks attempted and why unavailable>"`.
   The helper records the reason in the entry's `note`. Tell the user about the
   unresolved attribution; never silently omit provenance or invent an identifier.

All three writing scripts accept the same identity options. For example, from the
installed exec-plan skill directory:

```bash
bun init-plan.ts --title "Add queue support" \
  --codex-session-file /path/to/current-session.jsonl
bun record-provenance.ts revision --plan /path/to/plan.md --mode update \
  --codex-session-file /path/to/current-session.jsonl --note "Refresh compatibility scope"
bun init-plan.ts --title "Add queue support" \
  --claude-session-file /path/to/current-transcript.jsonl --claude-session-id <current-session-id>
```

The JSONL fields are best-effort adapters for observed Codex and Claude Code formats, not a
stable API guarantee. Missing, unreadable, malformed, mismatched, or unsupported
metadata fails before writing a plan. Retry discovery or use the explicit,
documented unknown fallback; never reuse a stale model when the latest turn lacks
one. The helper does not search logs automatically or print conversation content.

For historical corrections, inspect metadata for the turn that actually authored
the work and pass that verified model explicitly. The latest-turn adapter is only
for current work. Append a corrective entry explaining the evidence; preserve the
original entry rather than rewriting history.
