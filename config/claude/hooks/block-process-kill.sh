#!/bin/sh
# PreToolUse hook for Bash: refuse commands that kill processes by name.
#
# pkill and killall match by name or command line, so a loose pattern kills
# unrelated processes. On 2026-11-13, `pkill -f "fake" -n` (BSD pkill reads the
# trailing -n as a second pattern) killed every terminal shell in every Rex
# session. Agents must kill the PID they started instead.
#
# Exit 2 blocks the tool call and shows stderr to Claude.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || cmd=$input
else
  cmd=$input
fi

if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]_-])(pkill|killall)([^[:alnum:]_-]|$)'; then
  cat >&2 <<'EOF'
Blocked: pkill and killall are not allowed. They match processes by name or
command line and can kill the user's terminals, editors, and other agents.
(On macOS, `pkill -f "x" -n` reads -n as a second pattern and kills every shell.)

Stop only the process you started:
  - save its PID when you start it:  cmd & echo $! > pidfile ; later: kill "$(cat pidfile)"
  - or, for a server on a port, check `lsof -i tcp:PORT` is yours, then:
      kill $(lsof -ti tcp:PORT -sTCP:LISTEN)
  - or use the project's stop command (just process-down, docker compose down, ...)
If you only meant to search text for the word, write it as p[k]ill.
EOF
  exit 2
fi

exit 0
