---
id: 1
slug: centralize-launchd-app-logs-in-victorialogs-with-a-ui
title: "Centralize launchd app logs in VictoriaLogs with a UI"
kind: exec-plan
created_at: 2026-05-07T14:05:57Z
intention: "intention_01kr1bv8q5e7p857be98v9wv2r"
---

# Centralize launchd app logs in VictoriaLogs with a UI

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

This document is maintained in accordance with `.claude/skills/exec-plan/PLANS.md`.


## Purpose / Big Picture

The user runs six long-running background daemons under macOS launchd, all configured
through home-manager modules in this repository: `mori automate`, `rei worker`,
`rei subscription`, `mori-rei-app`, `notion-hub-subscription`, and `postgres`. Each
daemon writes its standard output and standard error to per-app text files under
`~/.<app>/logs/*.log` (for example, `~/.rei/logs/worker.stderr.log`). Lines are already
prefixed with an ISO-8601 timestamp by piping the wrapper script through the `ts`
utility from `pkgs.moreutils` (see `docs/plans/timestamped-app-logs.md`).

When something goes wrong the user has to `tail -f ~/.<app>/logs/*.log` for each daemon,
mentally interleave the streams, and grep across files. There is no single place to ask
"show me everything from the last 15 minutes that contains the word 'panic'" or "show
all output from `mori-automate` and `rei-worker` between 09:00 and 09:05 UTC".

After this change, every line written by these daemons is also pushed in real time into
a local **VictoriaLogs** server — a single Go binary that listens on TCP `9428` and
ships with a built-in web UI for ad-hoc queries. The user opens
`http://localhost:9428/select/vmui/` in any browser and gets a search box that
understands [LogsQL](https://docs.victoriametrics.com/victorialogs/logsql/),
auto-complete on field names, a time-range picker, and live tailing. They can run
queries such as:

    app:rei-worker AND _msg:~"error"
    _stream:{app="mori-automate"} AND _time:5m
    _msg:~"panic" | stats by (app) count()

The existing per-app `*.log` files keep being written exactly as before, so existing
`tail -f` and `just logs-*` workflows are unaffected. VictoriaLogs adds a query layer
on top of those files; it does not replace them.

We deliberately scope this plan to **VictoriaLogs only** (the storage + UI server) and
do not adopt **vlagent** (the companion log-forwarding agent). The reason is captured
in detail in the Decision Log below: vlagent on macOS is essentially a Kubernetes log
collector and an HTTP relay between log shippers and VictoriaLogs. It does not tail
arbitrary files on the host. For a single-machine, single-VictoriaLogs-instance setup
the simpler path is to ship logs straight to VictoriaLogs's HTTP ingestion endpoint;
vlagent only adds value once we have multiple VictoriaLogs instances or a Kubernetes
cluster.


## Progress

Use a checklist to summarize granular steps. Every stopping point must be documented here,
even if it requires splitting a partially completed task into two ("done" vs. "remaining").
This section must always reflect the actual current state of the work.

- [x] Milestone 1 — Spike: confirm `pkgs.victorialogs` builds and the UI loads. _(2026-05-07)_
  - [x] Run `nix run nixpkgs#victorialogs -- -storageDataPath=/tmp/vl-spike -httpListenAddr=:19428 -retentionPeriod=1d` in background. `/health` returned `OK` after ~6s.
  - [x] `GET /select/vmui/` returned HTTP 200 (UI assets reachable).
  - [x] `POST /insert/jsonline` for `{"_msg":"hello from spike",…}` returned HTTP 200; subsequent `query=app:spike` returned the line with `_stream={app="spike",stream="stdout"}` and an ingestion timestamp.
  - [x] Killed `victoria-logs` and removed `/tmp/vl-spike`.
- [x] Milestone 2 — Persistent VictoriaLogs launchd agent under home-manager. _(2026-05-07)_
  - [x] Created `home/victorialogs.nix` defining `launchd.agents.victorialogs`.
  - [x] Wired `./victorialogs.nix` into `home/default.nix`'s `imports` immediately after `./postgresql.nix`.
  - [x] Added `home.activation.victorialogs-stop-agents` mirroring `home/mori.nix`'s bootout pattern.
  - [x] Ran `sudo darwin-rebuild switch --flake .#SungkyungM1X`. `launchctl print gui/501/com.shinzui.victorialogs` reports `state = running`.
  - [x] `curl http://localhost:9428/health` returns `OK`. Smoke-tested ingest+query on the persistent server with `app:smoke` line — round-tripped successfully.
- [x] Milestone 3 — Log shipper that pushes the existing files into VictoriaLogs. _(2026-05-07)_
  - [x] Replaced the original "tee from inside each app's wrapper" approach with a simpler **read-side** shipper: 12 dedicated launchd agents, each running `tail -n0 -F` on one of the existing `*.log` files and POSTing every new line to `/insert/jsonline`. The application launchd agents in `home/mori.nix`, `home/rei.nix`, `home/mori-rei-app.nix`, `home/notion-hub.nix`, and `home/postgresql.nix` are **not** modified — the shippers read the same files those agents already write. (See Decision Log entry on read-side shipping.)
  - [x] Added a `shipper-wrapper` shell script in `home/victorialogs.nix` (takes app/stream/file args). Builds the 12 agents from a single `shippers` list via `lib.listToAttrs`, and derives both the agents and the bootout-set from that list.
  - [x] `sudo darwin-rebuild switch --flake .#SungkyungM1X`. Confirmed `launchctl list | grep com.shinzui.victorialogs | wc -l` reports 13 (1 server + 12 shippers). Test lines appended to 6 different `*.log` files all surface in VictoriaLogs within ~1 second; `_time:5m | stats by (app) count()` reports a non-zero count for every app.
- [x] Milestone 4 — Ergonomics: `Justfile` recipes and a small runbook. _(2026-05-07)_
  - [x] Added `just logs-ui` (opens VLUI), `just logs-query QUERY` (curl + jq), `just status-victorialogs`, `just restart-victorialogs`, and `just logs-victorialogs` under a new `[group: 'logs']`.
  - [x] Bottom of `home/victorialogs.nix` carries a short comment block with useful LogsQL queries (last-5m errors, per-app head, panic detection, etc.).
  - [ ] (skipped) `docs/plans/timestamped-app-logs.md` cross-reference — that plan is already implemented and self-explanatory; no update needed.
- [x] Milestone 5 — Decision review on vlagent. _(2026-05-07)_
  - [x] Re-read this plan's Decision Log entry on vlagent against the implemented setup. The implemented setup is single-machine, single-VictoriaLogs-instance, with shippers POSTing to `localhost:9428`. Adding vlagent would require pairing it with a separate file-tailing shipper (vlagent has no tail-files mode) and forwarding to a same-host VictoriaLogs — extra hop, extra failure modes, no benefit at this scale.
  - [x] Outcome recorded below: **deferred indefinitely**. If the user later runs multiple machines or moves to Kubernetes, open a sibling plan `docs/plans/N-add-vlagent-multi-host-shipping.md`.
- [x] Final commit on `master` with `ExecPlan:` and `Intention:` git trailers.


## Surprises & Discoveries

- 2026-05-07 — Spike confirmed `pkgs.victorialogs` (v1.49.0 in current nixpkgs)
  builds and runs on `aarch64-darwin`. `nix run nixpkgs#victorialogs --` used in
  place of `nix shell --command` (slightly cleaner invocation; same result).
  No surprises in the JSON-stream ingest format — request body and query params
  match the docs in the source tree exactly.

- 2026-05-07 — `jq -Rc` buffers its stdout when piped, even though it emits one
  JSON record per input line. With low-volume daemons that write one line every
  few seconds, lines sit in jq's 4 KiB stdio buffer indefinitely and never
  reach VictoriaLogs. Symptom: writing 200 lines at once delivered ~169; writing
  a single test line delivered nothing for 30+ seconds. Fix: add `--unbuffered`
  to the jq invocation in the shipper. `tail -n0 -F` itself does line-flush
  correctly; the buffer was downstream of tail, not in tail. Plan-of-Work
  shipper snippet updated to include the flag.


## Decision Log

- Decision: Install **`pkgs.victorialogs`** (the server) but **not** `pkgs.vlagent`
  (the companion log-shipper agent) at this time.
  Rationale: Reading the upstream source pulled in by `pkgs.victorialogs.src`
  (`docs/victorialogs/vlagent.md` and `docs/victorialogs/vlagent_common_flags.md` from
  VictoriaLogs v1.49.0), `vlagent` has only two collection modes: (a)
  `-kubernetesCollector`, which discovers and tails container log files under
  `/var/log/containers` on a Kubernetes node, and (b) accept-over-HTTP, where it
  receives logs from external shippers (Filebeat, Fluentbit, Vector, Promtail, syslog,
  Datadog, OpenTelemetry, etc.) and forwards them to one or more `-remoteWrite.url`
  destinations. There is no built-in "tail this list of files" mode. On a macOS host
  with launchd-spawned daemons writing to `~/.<app>/logs/*.log`, vlagent would have to
  be paired with another file shipper just to get data into it, then it would forward
  to a VictoriaLogs that is on the same machine. That extra hop adds buffering,
  failure modes, and a second launchd agent for no benefit. The on-disk
  `-remoteWrite.maxDiskUsagePerURL` buffer that is vlagent's main feature only matters
  when the destination is on a different host with potentially flaky connectivity,
  which is not the case here.
  Date: 2026-05-07.

- Decision: Run VictoriaLogs as a **per-user launchd agent** under home-manager,
  matching the existing pattern used by `home/postgresql.nix` and the application
  daemons.
  Rationale: All other long-running services in this repo are user-level launchd
  agents (`com.shinzui.postgresql`, `com.shinzui.mori-automate`, etc.), not
  system-wide `nix-darwin` `launchd.daemons`. Following the same convention keeps the
  storage path under `$HOME/.local/share`, avoids the privileged-port problem (TCP
  `9428` is well above 1024), and makes activation/teardown match the bootout helper
  we already maintain.
  Date: 2026-05-07.

- Decision: Ship logs into VictoriaLogs via its **JSON-stream endpoint
  `/insert/jsonline`** rather than syslog, Elasticsearch bulk, Loki, or
  OpenTelemetry.
  Rationale: The wrappers already produce timestamped lines; `/insert/jsonline`
  accepts newline-delimited JSON, which we can produce from a tiny `jq -Rc` filter
  (or a shell `printf`) over the existing stream. The Elasticsearch bulk format
  requires a paired `{"create":{}}` line per record; Loki wants gzip-compressed
  protobuf or a more elaborate JSON structure; syslog would require us to keep an
  RFC-3164/5424 framing layer. JSON-stream is the lowest-friction option and is the
  format VictoriaLogs uses internally.
  Date: 2026-05-07.

- Decision: Preserve the existing `~/.<app>/logs/*.log` files unchanged. The shipper
  is **read-side, not write-side**: it `tail -n0 -F`s the existing file from a
  separate launchd agent and pushes lines to VictoriaLogs. The original app's
  wrapper script is left untouched.
  Rationale: The user's `just logs-mori`, `just logs-rei`, etc. recipes all rely on
  `tail -f ~/.<app>/logs/*.log`. Removing those files would break muscle memory and
  would also remove the only durable source of truth if VictoriaLogs is down.
  An earlier design considered modifying each app's wrapper to `tee` into a
  process substitution (running curl) in addition to launchd's stdout file. That
  was rejected during implementation in favour of read-side shipping because:
  (a) it keeps `home/mori.nix`, `home/rei.nix`, `home/mori-rei-app.nix`,
  `home/notion-hub.nix`, and `home/postgresql.nix` unchanged — none of those
  modules need to know about logging infrastructure; (b) shipping a line cannot
  break the app — a curl failure in a tee'd process substitution would not crash
  the wrapper, but a buggy shipper update could still slow it down via pipe
  back-pressure, while a read-side shipper is fully decoupled; (c) restarting
  the shipper does not restart the app. The cost is one extra launchd agent per
  log file (12 in total) — cheap on a single machine.
  Date: 2026-05-07.

- Decision: Use the upstream **default storage path naming and retention** initially:
  `-storageDataPath=$HOME/.local/share/victoria-logs/data` and the upstream default
  retention of 7 days. Users can tune later via flags.
  Rationale: 7 days of personal-host log volume from six daemons is well under 1 GB
  in the typical case and keeps disk pressure off during the spike. We will revisit
  the retention if the storage path grows beyond a few GB after a week of use.
  Date: 2026-05-07.

- Decision: Do not introduce a `darwinModules.victorialogs` system-wide module.
  Rationale: Single-user dotfiles repo; no other user benefits from a system-wide
  module. Future Linux/NixOS users could add `services.victorialogs` upstream NixOS
  module support, but this is out of scope.
  Date: 2026-05-07.


## Outcomes & Retrospective

Implemented end-to-end on 2026-05-07, all five milestones in a single
session. The user can now query every launchd-managed app's logs from a
single browser tab at `http://localhost:9428/select/vmui/`, with the
existing per-file `~/.<app>/logs/*.log` workflow fully preserved.

What worked:

- **Read-side shipping was the right call.** Keeping the application
  modules (`home/mori.nix`, `home/rei.nix`, `home/mori-rei-app.nix`,
  `home/notion-hub.nix`, `home/postgresql.nix`) untouched meant zero
  risk of breaking running daemons during the rollout. Each shipper is
  a stand-alone launchd agent that can crash, restart, or be deleted
  without affecting the app it watches.
- **Single Nix list of shipper specs** (`shippers = [ … ]`) drives both
  the launchd agent generation and the bootout-set in
  `victorialogs-stop-agents`. Adding a new app log later means adding
  one line to that list.
- **`pkgs.victorialogs` v1.49.0** runs cleanly under per-user launchd
  on `aarch64-darwin`. No native dependencies, no special permissions,
  no privileged-port issues (TCP 9428 is unprivileged).

What surprised:

- **`jq -Rc` buffers stdout when piped.** This was the only real
  blocker during implementation — single-line writes never reached
  VictoriaLogs because they sat in jq's stdio buffer. `jq --unbuffered`
  is the fix and is now part of the shipper script.

vlagent decision (M5): **deferred indefinitely**. The implemented
setup is a single VictoriaLogs instance accessed from `localhost`;
vlagent would require pairing it with a separate file shipper for the
same machine, then forwarding to the same machine, which adds buffering
and failure modes for no benefit. If the user later runs multiple
machines or moves to Kubernetes, open
`docs/plans/N-add-vlagent-multi-host-shipping.md` and revisit.

Follow-up ideas (not scheduled):

- Parse the embedded `ts` ISO-8601 prefix from each log line and feed
  it as `_time` instead of using ingest time. Acceptable today because
  ingest happens within ~1s of write, but would matter if the host
  ever falls behind on shipping.
- Batch multiple lines per `curl` POST if a daemon ever floods enough
  to overwhelm the per-line POST loop. Not observed in normal use.


## Context and Orientation

This repository, `~/.config/dotfiles.nix`, is a Nix flake that produces a `nix-darwin`
system configuration and a per-user `home-manager` configuration for the
`SungkyungM1X` host (an Apple Silicon MacBook Pro). The relevant files for this plan
all live under `home/`:

- `home/default.nix` — the home-manager entry point. Imports a list of per-feature
  modules (`./mori.nix`, `./rei.nix`, `./postgresql.nix`, etc.). New modules are
  added by appending to the `imports = [ … ]` list near the top of the file.
- `home/postgresql.nix` — the canonical example of a launchd-managed database server
  in this repo. It defines a `launchd.agents.postgresql` block, a
  `home.activation.postgresql-stop` activation entry that boots out the old plist
  before re-bootstrapping, and a `home.activation.postgresql-init` entry for one-time
  filesystem setup. Our new `home/victorialogs.nix` will follow this exact shape.
- `home/mori.nix`, `home/rei.nix`, `home/mori-rei-app.nix`, `home/notion-hub.nix` —
  one launchd agent per app daemon. Each follows the same recipe: build a
  `pkgs.writeShellScript` wrapper that exports environment variables, waits for
  Postgres, pipes stdout and stderr through `${pkgs.moreutils}/bin/ts
  '%Y-%m-%dT%H:%M:%S%z'`, and finally `exec`s the real binary. Launchd captures the
  wrapper's stdout/stderr to `StandardOutPath` and `StandardErrorPath`.
- `flake.nix` — defines an overlay called `pkgs-unstable` that exposes
  `nixpkgs-unstable` as `pkgs.pkgs-unstable`. We will use the regular `pkgs.victorialogs`
  attr (already present in unstable as of nixpkgs commit pinned in `flake.lock`),
  which provides the `victoria-logs` binary as `mainProgram`.

Define a few terms used below:

- **launchd**: macOS's system-and-session service manager (think systemd).
  `launchctl print gui/$(id -u)/<label>` shows a per-user agent's state. plist files
  for per-user agents live in `~/Library/LaunchAgents`.
- **home-manager `launchd.agents.<name>`**: a Nix attribute set that home-manager
  serializes into one of those plist files at activation time. The serialized plist
  has `Label`, `ProgramArguments`, `RunAtLoad`, `KeepAlive`, `StandardOutPath`,
  `StandardErrorPath`, and `EnvironmentVariables` keys, mapping 1:1 to the launchd
  plist schema documented at `man launchd.plist`.
- **VLUI**: the web UI shipped inside the `victoria-logs` Go binary. Served at
  `/select/vmui/` of the same HTTP port the server listens on. No separate
  process is required.
- **LogsQL**: VictoriaLogs's query language. Filters look like
  `field:value`, `_msg:~"regex"`, time filters look like `_time:5m` (last five
  minutes) or `_time:[2026-05-07,2026-05-08]`, and pipes look like
  `... | stats by (app) count()`. The full reference is shipped in the source tree
  at `docs/victorialogs/logsql.md` (also at
  https://docs.victoriametrics.com/victorialogs/logsql/).
- **`/insert/jsonline`**: VictoriaLogs's HTTP endpoint that accepts newline-delimited
  JSON. Each line is a free-form JSON object; VictoriaLogs picks `_msg`, `_time`, and
  `_stream` fields from the URL parameters `_msg_field`, `_time_field`, and
  `_stream_fields`. If `_time` is missing or `"0"`, VictoriaLogs uses ingest time.
  Documented in `docs/victorialogs/data-ingestion/README.md` of the source.

The existing app log layout — pulled directly from the working tree on
2026-05-07 — is:

    /Users/shinzui/.rei/logs/worker.stdout.log
    /Users/shinzui/.rei/logs/worker.stderr.log
    /Users/shinzui/.rei/logs/subscription.stdout.log
    /Users/shinzui/.rei/logs/subscription.stderr.log
    /Users/shinzui/.mori/logs/automate.stdout.log
    /Users/shinzui/.mori/logs/automate.stderr.log
    /Users/shinzui/.mori/logs/postgres.stdout.log    # legacy, retained
    /Users/shinzui/.mori/logs/postgres.stderr.log    # legacy, retained
    /Users/shinzui/.notion-hub/logs/subscription.stdout.log
    /Users/shinzui/.notion-hub/logs/subscription.stderr.log
    /Users/shinzui/.mori-rei-app/logs/server.stdout.log
    /Users/shinzui/.mori-rei-app/logs/server.stderr.log
    /Users/shinzui/.local/state/postgresql/logs/postgres.stdout.log
    /Users/shinzui/.local/state/postgresql/logs/postgres.stderr.log

Each `app` and stream combination has a single `*.log` file, so the natural
VictoriaLogs `_stream` labels are `{app="<name>", stream="stdout|stderr"}`.


## Plan of Work

Five milestones, each independently verifiable and additive on top of the previous
one. After each milestone the system continues to work — even if the milestone after
it is never started.


### Milestone 1 — Spike: confirm `pkgs.victorialogs` builds and the UI loads

Goal: prove the binary works on `aarch64-darwin`, prove the bundled UI is reachable,
and prove the JSON-stream ingest endpoint accepts a hand-crafted line. No files in
this repository are edited; this is a throwaway, run-once exploration. Result: the
user has seen the VLUI in their browser and has confidence in the rest of the plan.

What will exist at the end: nothing persistent — `/tmp/vl-spike` is deleted at the
end of this milestone. The Surprises & Discoveries section is updated if anything
unexpected was observed.

Acceptance: `curl http://localhost:19428/select/logsql/query -d 'query=*' | jq`
shows the test line we ingested.


### Milestone 2 — Persistent VictoriaLogs launchd agent

Goal: VictoriaLogs runs at boot/login under launchd, listens on TCP `9428`, persists
data under `$HOME/.local/share/victoria-logs/data`, and is restarted cleanly on
`darwin-rebuild switch`.

Work:

1. Create a new file `home/victorialogs.nix`. Pattern after `home/postgresql.nix`.
   The skeleton is:

       { config, pkgs, lib, ... }:

       let
         vl = pkgs.victorialogs;
         dataDir = "${config.home.homeDirectory}/.local/share/victoria-logs/data";
         logDir = "${config.home.homeDirectory}/.local/share/victoria-logs/logs";
         port = 9428;

         victorialogs-wrapper = pkgs.writeShellScript "victorialogs" ''
           set -euo pipefail
           mkdir -p "${dataDir}" "${logDir}"
           exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
           exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)
           exec ${vl}/bin/victoria-logs \
             -storageDataPath="${dataDir}" \
             -httpListenAddr=":${toString port}" \
             -loggerOutput=stderr \
             -retentionPeriod=7d
         '';
       in
       {
         home.packages = [ vl ];

         home.activation.victorialogs-init = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
           run mkdir -p "${dataDir}" "${logDir}"
         '';

         home.activation.victorialogs-stop-agents =
           lib.hm.dag.entryBefore [ "setupLaunchAgents" ] ''
             stop_and_wait() {
               local label="$1"
               local domain="gui/$(id -u)"
               local newPlist="$newGenPath/LaunchAgents/$label.plist"
               local curPlist="$HOME/Library/LaunchAgents/$label.plist"
               if cmp -s "$newPlist" "$curPlist"; then
                 verboseEcho "$label plist unchanged, skipping stop"
                 return
               fi
               if /bin/launchctl print "$domain/$label" &>/dev/null; then
                 local pid
                 pid=$(/bin/launchctl print "$domain/$label" 2>/dev/null \
                       | /usr/bin/grep -m1 'pid =' | /usr/bin/awk '{print $NF}')
                 verboseEcho "Stopping $label (pid ''${pid:-unknown})..."
                 /bin/launchctl bootout "$domain/$label" 2>/dev/null || true
                 if [ -n "$pid" ]; then
                   while kill -0 "$pid" 2>/dev/null; do sleep 1; done
                 fi
               fi
             }
             stop_and_wait "com.shinzui.victorialogs"
           '';

         launchd.agents.victorialogs = {
           enable = true;
           config = {
             Label = "com.shinzui.victorialogs";
             ProgramArguments = [ "${victorialogs-wrapper}" ];
             RunAtLoad = true;
             KeepAlive = true;
             ExitTimeOut = 30;
             StandardOutPath = "${logDir}/victoria-logs.stdout.log";
             StandardErrorPath = "${logDir}/victoria-logs.stderr.log";
           };
         };
       }

   The above is the *target shape*; final formatting follows existing files in
   `home/`.

2. Edit `home/default.nix`. In the `imports = [ … ]` list (currently lines 21–47),
   add `./victorialogs.nix` immediately after `./postgresql.nix` so that the
   read order is "infrastructure first, apps second".

3. `darwin-rebuild switch --flake .`. Verify with the commands listed in the
   Concrete Steps section.

What will exist at the end: a running `com.shinzui.victorialogs` launchd agent, the
`victoria-logs` binary in the user `home.packages`, and a fresh
`$HOME/.local/share/victoria-logs/data` directory.

Acceptance: `curl http://localhost:9428/health` returns `OK`. The page
`http://localhost:9428/select/vmui/` loads VLUI in a browser.


### Milestone 3 — File-tailing log shipper

Goal: every line written to the existing `~/.<app>/logs/*.log` files is also pushed
to VictoriaLogs in real time, labeled with `app=<name>` and `stream=stdout|stderr`,
without breaking the existing files.

Approach: add a small reusable Nix helper to `home/victorialogs.nix` that returns a
`launchd.agents.<name>` configuration which runs `tail -F` on a list of files and
pipes each line through `jq -Rc` into a curl POST to `/insert/jsonline`. We add one
shipper agent per app. The existing app launchd agents are **not modified** in this
milestone — we read the same files they write, so the design stays additive.

Concrete shipper script (lives inside `home/victorialogs.nix`, returned by
`pkgs.writeShellScript`):

    #!/usr/bin/env bash
    # tail-F-and-push: app=$1 stream=$2 file=$3
    set -euo pipefail
    app="$1"; stream="$2"; file="$3"
    until [ -e "$file" ]; do sleep 2; done

    # Wait for VictoriaLogs to be ready before streaming. Avoid losing lines
    # by buffering with a local FIFO if VL is briefly unavailable.
    until curl -fs http://localhost:9428/health >/dev/null 2>&1; do
      sleep 2
    done

    exec ${pkgs.coreutils}/bin/tail -n0 -F "$file" \
      | ${pkgs.jq}/bin/jq -Rc --unbuffered \
          --arg app "$app" --arg stream "$stream" \
          '{_msg: ., _time: "0", app: $app, stream: $stream}' \
      | while IFS= read -r line; do
          # One curl per line is cheap on localhost. Batch later if needed.
          printf '%s\n' "$line" \
            | ${pkgs.curl.bin}/bin/curl -fsS -X POST \
                -H 'Content-Type: application/stream+json' \
                --data-binary @- \
                'http://localhost:9428/insert/jsonline?_stream_fields=app,stream&_msg_field=_msg&_time_field=_time' \
            || true   # never crash the shipper on a transient ingest failure
        done

Notes on this script: `_time: "0"` tells VictoriaLogs to use ingestion time; this is
acceptable because lines arrive within milliseconds of being written. If the user
later wants the embedded `ts` timestamp to be authoritative, replace the `jq` filter
with one that parses the `^[0-9TZ:+-]{25} ` prefix produced by `ts` and feeds it as
`_time`.

In `home/victorialogs.nix`, add a helper:

    mkShipper = { app, stream, file }: {
      enable = true;
      config = {
        Label = "com.shinzui.victorialogs-shipper-${app}-${stream}";
        ProgramArguments = [ shipper-wrapper app stream file ];
        RunAtLoad = true;
        KeepAlive = true;
        ExitTimeOut = 15;
        StandardErrorPath = "${logDir}/shipper.${app}.${stream}.stderr.log";
      };
    };

Then enumerate the agents:

    launchd.agents = lib.mkMerge [
      { victorialogs = { ... }; }
      (lib.mapAttrs' (name: cfg: lib.nameValuePair "victorialogs-shipper-${name}" cfg) (
        let mk = mkShipper; in {
          "rei-worker-stdout"             = mk { app = "rei-worker"; stream = "stdout"; file = "${config.home.homeDirectory}/.rei/logs/worker.stdout.log"; };
          "rei-worker-stderr"             = mk { app = "rei-worker"; stream = "stderr"; file = "${config.home.homeDirectory}/.rei/logs/worker.stderr.log"; };
          "rei-subscription-stdout"       = mk { app = "rei-subscription"; stream = "stdout"; file = "${config.home.homeDirectory}/.rei/logs/subscription.stdout.log"; };
          "rei-subscription-stderr"       = mk { app = "rei-subscription"; stream = "stderr"; file = "${config.home.homeDirectory}/.rei/logs/subscription.stderr.log"; };
          "mori-automate-stdout"          = mk { app = "mori-automate"; stream = "stdout"; file = "${config.home.homeDirectory}/.mori/logs/automate.stdout.log"; };
          "mori-automate-stderr"          = mk { app = "mori-automate"; stream = "stderr"; file = "${config.home.homeDirectory}/.mori/logs/automate.stderr.log"; };
          "mori-rei-app-stdout"           = mk { app = "mori-rei-app"; stream = "stdout"; file = "${config.home.homeDirectory}/.mori-rei-app/logs/server.stdout.log"; };
          "mori-rei-app-stderr"           = mk { app = "mori-rei-app"; stream = "stderr"; file = "${config.home.homeDirectory}/.mori-rei-app/logs/server.stderr.log"; };
          "notion-hub-stdout"             = mk { app = "notion-hub-subscription"; stream = "stdout"; file = "${config.home.homeDirectory}/.notion-hub/logs/subscription.stdout.log"; };
          "notion-hub-stderr"             = mk { app = "notion-hub-subscription"; stream = "stderr"; file = "${config.home.homeDirectory}/.notion-hub/logs/subscription.stderr.log"; };
          "postgresql-stdout"             = mk { app = "postgresql"; stream = "stdout"; file = "${config.home.homeDirectory}/.local/state/postgresql/logs/postgres.stdout.log"; };
          "postgresql-stderr"             = mk { app = "postgresql"; stream = "stderr"; file = "${config.home.homeDirectory}/.local/state/postgresql/logs/postgres.stderr.log"; };
        }
      ))
    ];

The `home.activation.victorialogs-stop-agents` block must also boot out every
shipper label so rebuilds restart them cleanly. Either (a) hardcode the list of
labels or (b) iterate. Hardcoding is the pattern already used by
`home/mori.nix:home.activation.mori-stop-agents` (one `stop_and_wait` per label) —
follow that.

What will exist at the end: 12 new launchd agents named
`com.shinzui.victorialogs-shipper-<app>-<stream>`, each tailing one of the existing
`*.log` files and pushing every line into VictoriaLogs.

Acceptance: after `darwin-rebuild switch`, the following query returns at least one
recent line for every app:

    curl 'http://localhost:9428/select/logsql/query' \
      --data-urlencode 'query=_time:5m | stats by (app) count()' | jq


### Milestone 4 — Ergonomics: Justfile recipes and a runbook

Goal: the user does not have to remember curl one-liners or VLUI URLs. Adds the
following recipes to `Justfile`:

    [group: 'logs']
    logs-ui:
        open http://localhost:9428/select/vmui/

    [group: 'logs']
    logs-query QUERY:
        curl -sS 'http://localhost:9428/select/logsql/query' \
          --data-urlencode "query={{QUERY}}" | jq

    [group: 'logs']
    status-victorialogs:
        launchctl print gui/$(id -u)/com.shinzui.victorialogs 2>&1 | head -20

    [group: 'logs']
    restart-victorialogs:
        launchctl kickstart -k gui/$(id -u)/com.shinzui.victorialogs

    [group: 'logs']
    logs-victorialogs:
        tail -f ~/.local/share/victoria-logs/logs/*.log

Also append a short usage section at the bottom of `home/victorialogs.nix` as a Nix
comment block listing the most useful LogsQL queries (last 5m of errors across all
apps, last 100 lines from one app, panic detection).

Acceptance: `just logs-ui` opens the browser to VLUI; `just logs-query 'app:rei-worker
| head 5'` prints five JSON records.


### Milestone 5 — Decision review on vlagent

Goal: lock in the "do not install vlagent" decision or, if circumstances changed
during implementation, open a new ExecPlan that revisits it.

Work: re-read the Decision Log entry on vlagent against the implemented setup. If
the user starts running multiple machines or moves to Kubernetes, the right next step
is a sibling plan `docs/plans/N-add-vlagent-multi-host-shipping.md`. Otherwise close
this question explicitly in the Outcomes & Retrospective section.

Acceptance: Outcomes & Retrospective explicitly states the vlagent decision and
either links to a follow-up plan or records "deferred indefinitely".


## Concrete Steps

All commands below are run from the repository root,
`/Users/shinzui/.config/dotfiles.nix`, unless noted otherwise.

### Spike (Milestone 1)

Run in a scratch terminal:

    nix run nixpkgs#victorialogs -- \
      -storageDataPath=/tmp/vl-spike \
      -httpListenAddr=:19428 \
      -retentionPeriod=1d &

Expected stderr (truncated to first interesting line):

    info VictoriaLogs has started; ready to accept logs and queries

In a second terminal, ingest one line:

    echo '{"_msg":"hello from spike","_time":"0","app":"spike","stream":"stdout"}' \
      | curl -sS -X POST -H 'Content-Type: application/stream+json' \
        --data-binary @- \
        'http://localhost:19428/insert/jsonline?_stream_fields=app,stream&_msg_field=_msg&_time_field=_time'

Expected: HTTP 200 with empty body. Then:

    curl -sS 'http://localhost:19428/select/logsql/query' \
      --data-urlencode 'query=app:spike' | jq

Expected:

    {
      "_msg": "hello from spike",
      "_stream": "{app=\"spike\",stream=\"stdout\"}",
      "_time": "2026-05-07T...Z",
      "app": "spike",
      "stream": "stdout"
    }

Then open `http://localhost:19428/select/vmui/` in a browser. Type `app:spike` in
the search box. The line shows up. Stop the spike:

    kill %1
    rm -rf /tmp/vl-spike

### Persistent agent (Milestone 2)

After writing `home/victorialogs.nix` and adding the import to `home/default.nix`:

    # Verify nix evaluation succeeds without building
    nix build .#darwinConfigurations.SungkyungM1X.system --dry-run

If that is clean:

    darwin-rebuild switch --flake .

Then:

    launchctl print gui/$(id -u)/com.shinzui.victorialogs | head -20
    curl -sS http://localhost:9428/health
    curl -sS 'http://localhost:9428/select/logsql/query' --data-urlencode 'query=*' | head

Expected `/health` response: `OK`.

### Shippers (Milestone 3)

    darwin-rebuild switch --flake .
    launchctl list | grep victorialogs-shipper | wc -l    # expect 12
    sleep 30   # let lines accrue
    curl -sS 'http://localhost:9428/select/logsql/query' \
      --data-urlencode 'query=_time:5m | stats by (app) count()' | jq

Expected: each app present and a non-zero count.

### Justfile (Milestone 4)

    just logs-ui                                # opens browser
    just logs-query 'app:rei-worker | head 3'   # prints 3 JSON records
    just status-victorialogs                    # head of launchctl print

This section will be updated during implementation with actual transcripts as
evidence.


## Validation and Acceptance

End-to-end acceptance, runnable by a fresh clone after this plan is implemented:

1. `darwin-rebuild switch --flake .` succeeds with no errors.
2. `launchctl list | grep com.shinzui.victorialogs` shows 13 entries (the server
   plus 12 shippers).
3. `curl -sS http://localhost:9428/health` returns `OK`.
4. Triggering a real log line in any app — for example, `just restart-mori` — and
   waiting two seconds, the following query returns the new line:

       curl -sS 'http://localhost:9428/select/logsql/query' \
         --data-urlencode 'query=app:mori-automate AND _time:1m' | jq

5. Opening `http://localhost:9428/select/vmui/` in Safari shows the VLUI; entering
   `_time:5m` returns recent lines from multiple `app=` values.
6. The original `~/.<app>/logs/*.log` files continue to grow and `just logs-mori`,
   `just logs-rei`, etc. still work.

Failure modes the user should know about:

- VictoriaLogs not running: shippers will idle in their `until curl -fs … /health`
  loop and resume once the server returns. No data is lost — `tail -F` keeps the
  position; once the server returns, new lines flow.
- A daemon writing faster than the shipper can curl: every shipper is one
  `tail -F | jq | while read | curl` pipeline. On a quiet personal machine this is
  fine. If a daemon ever floods, batch the `curl` (write a few seconds of lines
  into a temp file and POST in chunks). This is tracked as a future optimization in
  the Decision Log if the user observes back-pressure.


## Idempotence and Recovery

Every step in this plan is idempotent:

- `darwin-rebuild switch --flake .` can be re-run as many times as needed. The
  `home.activation.victorialogs-stop-agents` activation only boots out launchd
  agents whose plist content actually changed (the `cmp -s` guard mirrors the
  existing pattern in `home/mori.nix`).
- `mkdir -p` in the wrapper is safe to call repeatedly.
- VictoriaLogs's `-storageDataPath` directory is rebuilt automatically if it is
  missing; if corrupted, deleting it and restarting recreates a fresh empty store.
  The user loses historical logs but the existing `*.log` files (the source of
  truth) remain.
- The shipper uses `tail -F -n0`, so on shipper restart it picks up only new
  lines, never re-ingesting already-shipped lines.
- Rolling back: `git revert` the relevant commits and `darwin-rebuild switch
  --flake .`. The launchd agents are then booted out and their plists removed by
  home-manager. Disk artifacts left behind: `$HOME/.local/share/victoria-logs` —
  delete manually with `rm -rf`.


## Interfaces and Dependencies

External dependencies introduced by this plan:

- `pkgs.victorialogs` (nixpkgs-unstable, version 1.49.0 at time of writing). Source:
  `pkgs/by-name/vi/victorialogs/package.nix` in nixpkgs-unstable. Provides the
  `victoria-logs` binary as `meta.mainProgram`. License: Apache-2.0.
  `pkgs.victorialogs.meta.platforms` includes `aarch64-darwin`, confirmed via
  `nix eval`.
- `pkgs.jq`, `pkgs.curl`, `pkgs.coreutils`, `pkgs.moreutils` — already present in
  the user's environment, used by the shipper script and the wrapper.

No new flake inputs are required; everything comes from the existing
`nixpkgs-unstable` input pinned in `flake.lock`.

Internal interfaces:

- `home/victorialogs.nix` exports nothing to other home-manager modules. It only
  defines:
    - `home.packages` containing `pkgs.victorialogs`
    - `home.activation.victorialogs-init` and
      `home.activation.victorialogs-stop-agents`
    - `launchd.agents.victorialogs` and 12 shipper agents under
      `launchd.agents.victorialogs-shipper-*`
- The HTTP contract used by the shipper:

      POST http://localhost:9428/insert/jsonline
        ?_stream_fields=app,stream
        &_msg_field=_msg
        &_time_field=_time

  with `Content-Type: application/stream+json` and a body of one or more
  newline-delimited JSON objects shaped `{ "_msg": "...", "_time": "0", "app": "...",
  "stream": "stdout" | "stderr" }`. This matches the contract documented in the
  shipped source at `docs/victorialogs/data-ingestion/README.md` of
  `pkgs.victorialogs.src`.

- The query contract used by `just logs-query`:

      POST http://localhost:9428/select/logsql/query
        body: query=<LogsQL>

  Response is one JSON object per line on the response stream. Documented in
  `docs/victorialogs/querying/_index.md` of `pkgs.victorialogs.src`.

There are no changes to the existing `pkgs.mori`, `pkgs.rei`, `pkgs.mori-rei-app`,
`pkgs.notion-hub`, or `pkgs.postgresql_18` packages. The application launchd
agents in `home/mori.nix`, `home/rei.nix`, `home/mori-rei-app.nix`, and
`home/notion-hub.nix` are **not** modified by this plan; the shipper reads the same
log files those agents already write.
