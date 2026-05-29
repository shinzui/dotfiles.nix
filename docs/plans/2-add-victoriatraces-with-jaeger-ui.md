---
id: 2
slug: add-victoriatraces-with-jaeger-ui
title: "Add VictoriaTraces with Jaeger UI"
kind: exec-plan
created_at: 2026-05-29T22:10:15Z
---

# Add VictoriaTraces with Jaeger UI

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.


## Purpose / Big Picture

This repository already runs local logs through VictoriaLogs, but it does not provide a
local place to ingest and inspect distributed traces. A distributed trace is a tree of
timed spans that shows how one request moved through one or more programs. A span is one
timed operation inside that tree, such as "handle HTTP request" or "run SQL query".

After this change, the user can run a local VictoriaTraces server under launchd,
send OpenTelemetry trace data to `http://localhost:10428/insert/opentelemetry/v1/traces`,
and inspect stored traces in two browser UIs. The VictoriaTraces built-in UI will be at
`http://localhost:10428/select/vmui/`. A local Jaeger UI frontend will be at
`http://localhost:16686/`, with its `/api` requests proxied to VictoriaTraces's
Jaeger-compatible query API under `/select/jaeger/api`.

The observable result is not merely a package in `home.packages`. The acceptance target
is that `launchctl` shows both launchd agents running, `/health` returns `OK`, a small
OTLP trace fixture can be ingested, `GET /select/jaeger/api/services` returns the fixture
service name, and the Jaeger UI can load in a browser without a separate Jaeger backend.


## Progress

Use a checklist to summarize granular steps. Every stopping point must be documented here,
even if it requires splitting a partially completed task into two ("done" vs. "remaining").
This section must always reflect the actual current state of the work.

- [x] Milestone 1 - Spike the available packages and frontend build. _(2026-05-29)_
  - [x] Re-ran the `mori` dependency checks from the plan; this repo has no `mori.dhall`, and the registry has no `victoriatracing` or `jaeger` projects.
  - [x] Re-ran nix package checks; `nixpkgs#victoriatraces.version` is `0.8.0`, `meta.mainProgram` is `victoria-traces`, and neither `nixpkgs#jaeger` nor `nixpkgs#jaeger-ui` exists.
  - [x] Confirmed Jaeger UI tag `v2.18.0` exists at commit `460dd20d8b1bcfdf3c43912f930a883c6e10140d`; its package requires Node `>=24.6.0`, and this nixpkgs exposes Node `24.14.0`.
- [x] Milestone 2 - Add a local Jaeger UI static asset derivation. _(2026-05-29)_
  - [x] Added initial `derivations/jaeger-ui/default.nix` pinned to Jaeger UI `v2.18.0` with the prefetched source hash.
  - [x] Replaced the temporary `npmDepsHash = lib.fakeHash` with the hash printed by the first `nix build .#jaeger-ui`: `sha256-pAnzsJNmmLmzpJhv0whIdDc+NSuswlsOpd2RhCVWSvs=`.
  - [x] Verified `nix build .#jaeger-ui` succeeds and `result/share/jaeger-ui/index.html` exists.
- [x] Milestone 3 - Add the `home/victoriatraces.nix` launchd module. _(2026-05-29)_
  - [x] Added initial `home/victoriatraces.nix` with VictoriaTraces and Jaeger UI nginx launchd agents.
  - [x] Imported `./victoriatraces.nix` from `home/default.nix` immediately after `./victorialogs.nix`.
- [x] Milestone 4 - Add Justfile recipes and runbook comments. _(2026-05-29)_
  - [x] Added `traces-ui`, `traces-vmui`, `status-victoriatraces`, `restart-victoriatraces`, and `logs-victoriatraces` recipes.
  - [x] Added endpoint comments at the bottom of `home/victoriatraces.nix`.
- [ ] Milestone 5 - Apply the home-manager configuration and validate ingest plus query.
  - [x] `nix build .#darwinConfigurations.SungkyungM1X.system` succeeded, building the VictoriaTraces wrapper, Jaeger UI nginx wrapper, both launchd plists, and the darwin system closure.
  - [ ] Run `sudo darwin-rebuild switch --flake .#SungkyungM1X`. An attempted run was blocked because sudo required an interactive password prompt; no switch was applied.
  - [x] Manually smoke-tested the same runtime shape with temporary foreground VictoriaTraces and nginx processes on ports `10428` and `16686`.
  - [x] Ingested a smoke OTLP trace into the temporary VictoriaTraces process and confirmed `http://localhost:16686/api/services` returned `codex-smoke`.
  - [ ] Confirm both launchd agents are running after the real darwin switch.


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

- 2026-05-29 - The current flake's `nixpkgs#victoriatraces.version` evaluates to
  `0.8.0`, and `nixpkgs#victoriatraces.meta.mainProgram` evaluates to
  `victoria-traces` on `aarch64-darwin`. `nixpkgs#jaeger` and `nixpkgs#jaeger-ui`
  do not exist; `nix search nixpkgs jaeger --json` only returns Haskell libraries
  named `jaeger-flamegraph` and `opentracing-jaeger`, not a runnable Jaeger query UI.

- 2026-05-29 - `mori show --full` reports `config file not found: mori.dhall` for
  this dotfiles repository. `mori registry search victoriatracing` and
  `mori registry search jaeger` report no registered projects, so there is no local
  dependency source corpus for VictoriaTraces or Jaeger UI beyond the repository and
  Nix flake inputs.

- 2026-05-29 - Jaeger UI `v2.18.0` is a workspace repository with root build script
  `npm run --workspaces build`. The UI package's Vite config sets `build.outDir` to
  `build`, so the static files to install live under `packages/jaeger-ui/build` after
  the build succeeds.

- 2026-05-29 - The full darwin system build succeeded after adding the home-manager
  module. Evidence: `nix build .#darwinConfigurations.SungkyungM1X.system` built
  `com.shinzui.victoriatraces.plist`, `com.shinzui.victoriatraces-jaeger-ui.plist`,
  `victoriatraces-jaeger-ui-nginx.conf`, and `darwin-system-26.05.06648f4`.

- 2026-05-29 - VictoriaTraces's Jaeger services endpoint may return an empty service
  list immediately after ingest, even though `/select/logsql/query` already shows the
  span. Re-querying shortly afterwards returned `{"data":["codex-smoke"],...}` from
  both `http://localhost:10428/select/jaeger/api/services` and the nginx-proxied
  `http://localhost:16686/api/services`.

- 2026-05-29 - The first `sudo darwin-rebuild switch --flake .#SungkyungM1X` attempt
  could not proceed in this session because sudo required an interactive password. The
  build and manual foreground runtime smoke passed, but launchd installation remains
  pending until the switch is run with credentials.


## Decision Log

Record every decision made while working on the plan.

- Decision: Use the official product name VictoriaTraces and binary name
  `victoria-traces`, even though the initial request said "victoriatracing".
  Rationale: The package exposed by nixpkgs is `pkgs.victoriatraces`, its main
  program is `victoria-traces`, and the upstream documentation uses VictoriaTraces.
  Using these names in file paths and labels keeps the implementation aligned with
  the actual executable and avoids inventing a local alias.
  Date: 2026-05-29.

- Decision: Use `pkgs.victoriatraces` for the trace database rather than a custom
  executable download.
  Rationale: The current nixpkgs input already contains `victoriatraces` for
  `aarch64-darwin`, and its metadata says the main program is `victoria-traces`.
  This follows the existing VictoriaLogs pattern in `home/victorialogs.nix`, where
  the server comes from nixpkgs and launchd runs a small wrapper script.
  Date: 2026-05-29.

- Decision: Do not run a full Jaeger backend executable for the UI.
  Rationale: VictoriaTraces already stores traces and implements the Jaeger Query
  Service JSON API. The Jaeger UI integration documented by VictoriaTraces is static
  Jaeger UI assets served by an HTTP server, with `/api` proxied to
  `http://127.0.0.1:10428/select/jaeger/api`. A full Jaeger backend would duplicate
  storage and query responsibilities, and nixpkgs does not currently provide a
  `jaeger` or `jaeger-ui` package in this flake.
  Date: 2026-05-29.

- Decision: Serve Jaeger UI with `pkgs.nginx` as a per-user launchd agent on
  `127.0.0.1:16686`.
  Rationale: The VictoriaTraces Jaeger UI documentation gives an nginx configuration
  with exactly the routing shape needed here: serve static assets from a build
  directory and proxy `/api` to VictoriaTraces. Port `16686` is Jaeger's conventional
  UI port and is unprivileged. Binding to `127.0.0.1` keeps the UI local to the
  machine.
  Date: 2026-05-29.


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose.

(To be filled during and after implementation.)

Partial runtime outcome on 2026-05-29: the package and generated darwin system build
successfully, and a temporary foreground smoke test proves the VictoriaTraces plus
Jaeger UI proxy topology works on ports `10428` and `16686`. The real launchd rollout
is still pending because `sudo darwin-rebuild switch --flake .#SungkyungM1X` could not
receive the sudo password in this session.


## Context and Orientation

This repository is a nix-darwin and home-manager configuration. The flake root is
`flake.nix`. The user profile imports home-manager modules through `home/default.nix`.
Long-running local services are defined as per-user launchd agents, which means macOS
starts them in the user's GUI launchd domain instead of as system daemons. The existing
logs service in `home/victorialogs.nix` is the closest pattern for this work.

`home/victorialogs.nix` defines a server wrapper script, creates data and log
directories under `$HOME/.local/share/victoria-logs`, registers
`launchd.agents.victorialogs`, and includes a home-manager activation hook that stops
the old launchd agent before replacing its plist. This is important because launchd can
otherwise keep an old process alive while home-manager tries to register a changed plist,
which produces an I/O error. The VictoriaTraces module should mirror this structure.

`Justfile` already has a `[group: 'logs']` section with recipes such as `logs-ui`,
`status-victorialogs`, `restart-victorialogs`, and `logs-victorialogs`. The trace
recipes should be added near this section so daily observability commands are together.

Custom packages are added in `flake.nix` under the `overlays.my-packages` attribute set.
Existing package examples live under `derivations/`, including
`derivations/defuddle/default.nix` for a fetched JavaScript project and
`derivations/hunk/default.nix` for a package that installs prebuilt artifacts. A new
Jaeger UI derivation should follow this local convention by living under
`derivations/jaeger-ui/default.nix` and being exposed as `pkgs.jaeger-ui` through
`overlays.my-packages`.

VictoriaTraces is a trace database by VictoriaMetrics. It listens on HTTP port `10428`
by default in the docs used for this plan. It accepts OpenTelemetry Protocol trace data
at `/insert/opentelemetry/v1/traces`. OpenTelemetry Protocol, abbreviated OTLP, is the
standard wire format used by OpenTelemetry SDKs and collectors to send telemetry. For
querying, VictoriaTraces has a built-in VMUI at `/select/vmui/` and also implements
Jaeger Query Service JSON APIs under `/select/jaeger/api`. Jaeger UI is a browser
frontend that normally talks to Jaeger's query service via `/api`; in this plan nginx
maps Jaeger UI's `/api` path to VictoriaTraces's `/select/jaeger/api` path.


## Plan of Work

Milestone 1 spikes the package facts and frontend build. Confirm from the current flake
that `pkgs.victoriatraces` builds on `aarch64-darwin`, confirm that no runnable
`jaeger` package exists in nixpkgs, and prove the Jaeger UI source can be built into
static assets with Nix. At the end of the milestone, there should be a known
VictoriaTraces package version, a known Jaeger UI source revision, and a clear path for
the local derivation. Validate with `nix eval`, `nix build`, and a direct check that the
build output contains `index.html`.

Milestone 2 adds a local Jaeger UI derivation. Create
`derivations/jaeger-ui/default.nix` using `buildNpmPackage` and `fetchFromGitHub` for
`jaegertracing/jaeger-ui`. The derivation should run the repository's normal build
script and install the built static files from `packages/jaeger-ui/build` into
`$out/share/jaeger-ui`. Add `jaeger-ui = final.callPackage (self + "/derivations/jaeger-ui") { };`
to `flake.nix` inside `overlays.my-packages`, and add `jaeger-ui = pkgs.jaeger-ui;` to
the `packages` output for each system. If the first build fails because
`npmDepsHash` is fake, replace the fake hash with the hash printed by Nix and rebuild.
At the end of the milestone, `nix build .#jaeger-ui` should produce a result containing
`share/jaeger-ui/index.html`.

Milestone 3 adds `home/victoriatraces.nix`. The module should define:
`vt = pkgs.victoriatraces`; `vtBase = "${config.home.homeDirectory}/.local/share/victoria-traces"`;
`dataDir = "${vtBase}/data"`; `logDir = "${vtBase}/logs"`; `port = 10428`; and
`jaegerPort = 16686`. Add a `victoriatraces-wrapper` script that creates the data and
log directories, timestamps stdout and stderr through `pkgs.moreutils` `ts`, and execs:

    ${vt}/bin/victoria-traces \
      -storageDataPath="${dataDir}" \
      -httpListenAddr=":${toString port}" \
      -loggerOutput=stderr \
      -retentionPeriod=7d

The module should also define an nginx configuration file with `pkgs.writeText`, rooted
at `${pkgs.jaeger-ui}/share/jaeger-ui`, listening on `127.0.0.1:${toString jaegerPort}`,
serving `index.html` for browser routes, and proxying `/api` to
`http://127.0.0.1:${toString port}/select/jaeger/api`. Run nginx in the foreground with
`daemon off;`, using a writable prefix under `${vtBase}/nginx` for pid and temporary
files. Register two launchd agents: `victoriatraces` with label
`com.shinzui.victoriatraces`, and `victoriatraces-jaeger-ui` with label
`com.shinzui.victoriatraces-jaeger-ui`. Add a single activation hook that creates
directories and stops both labels before `setupLaunchAgents` when their plists change.
Import `./victoriatraces.nix` from `home/default.nix` immediately after
`./victorialogs.nix`, so logs and traces are adjacent.

Milestone 4 adds operator ergonomics. In `Justfile`, add recipes under a new
`[group: 'traces']`: `traces-ui` opens `http://localhost:16686/`;
`traces-vmui` opens `http://localhost:10428/select/vmui/`; `status-victoriatraces`
prints the first lines from both launchd agents; `restart-victoriatraces` kickstarts
both launchd agents; and `logs-victoriatraces` tails the VictoriaTraces and nginx log
files under `~/.local/share/victoria-traces/logs`. Add a short comment block at the
bottom of `home/victoriatraces.nix` with the two UI URLs, the OTLP HTTP ingest URL, and
the Jaeger services API URL.

Milestone 5 applies and validates the configuration. Build the package, switch the
darwin configuration, confirm both agents are running, ingest a small trace fixture, and
query VictoriaTraces through both native and Jaeger-compatible APIs. At the end of this
milestone, a browser at `http://localhost:16686/` should load Jaeger UI, the service
drop-down should include the fixture service after ingest, and
`curl http://localhost:10428/health` should return `OK`.


## Concrete Steps

From the repository root, first confirm the current dependency facts:

    cd /Users/shinzui/.config/dotfiles.nix
    mori show --full
    mori registry search victoriatracing
    mori registry search jaeger
    nix eval --raw nixpkgs#victoriatraces.version
    nix eval --raw nixpkgs#victoriatraces.meta.mainProgram
    nix eval --raw nixpkgs#jaeger.version
    nix eval --raw nixpkgs#jaeger-ui.version
    nix search nixpkgs jaeger --json

Expected evidence from the research already done on 2026-05-29:

    mori show --full
    Error: config file not found: mori.dhall

    mori registry search victoriatracing
    No projects matching 'victoriatracing'

    mori registry search jaeger
    No projects matching 'jaeger'

    nix eval --raw nixpkgs#victoriatraces.version
    0.8.0

    nix eval --raw nixpkgs#victoriatraces.meta.mainProgram
    victoria-traces

    nix eval --raw nixpkgs#jaeger.version
    error: flake 'flake:nixpkgs' does not provide attribute ...

Create `derivations/jaeger-ui/default.nix`. Start with `npmDepsHash = lib.fakeHash;`
if the correct dependency hash is not yet known. A novice should expect the first
`nix build .#jaeger-ui` to fail and print the real hash. Replace the fake hash with
that printed hash, then rerun:

    cd /Users/shinzui/.config/dotfiles.nix
    nix build .#jaeger-ui
    test -f result/share/jaeger-ui/index.html

Edit `flake.nix`. In `overlays.my-packages`, add the new package beside the other
local derivations:

    jaeger-ui = final.callPackage (self + "/derivations/jaeger-ui") { };

In the per-system `packages` output near `bootstrap-repos = pkgs.bootstrap-repos;`, add:

    jaeger-ui = pkgs.jaeger-ui;

Create `home/victoriatraces.nix` following the structure of `home/victorialogs.nix`.
The file should contain only home-manager declarations for packages, activation hooks,
and launchd agents. It should not modify application wrappers and should not require
root privileges. Add this module to `home/default.nix`:

    imports = [
      ...
      ./postgresql.nix
      ./victorialogs.nix
      ./victoriatraces.nix
      ./mori.nix
      ...
    ];

Edit `Justfile` and add trace recipes near the existing `[group: 'logs']` recipes.
Use the same command style as `status-victorialogs` and `restart-victorialogs`.

Build and apply:

    cd /Users/shinzui/.config/dotfiles.nix
    nix build .#jaeger-ui
    nix build .#darwinConfigurations.SungkyungM1X.system
    sudo darwin-rebuild switch --flake .#SungkyungM1X

After switching, validate the agents:

    launchctl print gui/$(id -u)/com.shinzui.victoriatraces | head -20
    launchctl print gui/$(id -u)/com.shinzui.victoriatraces-jaeger-ui | head -20
    curl -fsS http://localhost:10428/health
    curl -fsS http://localhost:16686/ | head

The expected health response is:

    OK

Create a small OTLP fixture under `/tmp/victoriatraces-smoke.json`. Use a current
nanosecond timestamp for both `startTimeUnixNano` and `endTimeUnixNano`; timestamps
outside the default seven-day retention are rejected. One simple fixture shape is:

    {"resourceSpans":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"codex-smoke"}}]},"scopeSpans":[{"scope":{"name":"codex-smoke"},"spans":[{"traceId":"11111111111111111111111111111111","spanId":"2222222222222222","name":"exec-plan-smoke","kind":1,"startTimeUnixNano":"REPLACE_WITH_NOW_NANOS","endTimeUnixNano":"REPLACE_WITH_NOW_NANOS","attributes":[{"key":"codex.plan","value":{"stringValue":"docs/plans/2-add-victoriatraces-with-jaeger-ui.md"}}],"status":{}}]}]}]}

Send it to VictoriaTraces and query through the Jaeger-compatible API:

    curl -fsS -H 'Content-Type: application/json' \
      --data-binary @/tmp/victoriatraces-smoke.json \
      http://localhost:10428/insert/opentelemetry/v1/traces

    curl -fsS http://localhost:10428/select/jaeger/api/services | jq

The expected services response should include `codex-smoke`.


## Validation and Acceptance

The package validation passes when `nix build .#jaeger-ui` exits successfully and
`result/share/jaeger-ui/index.html` exists. This proves the local Jaeger UI assets can
be built reproducibly through the flake.

The configuration validation passes when:

    nix build .#darwinConfigurations.SungkyungM1X.system

exits successfully. This proves the new derivation, overlay, home-manager module,
nginx configuration, and launchd plist generation all evaluate together.

The runtime validation passes when the following commands all succeed after
`sudo darwin-rebuild switch --flake .#SungkyungM1X`:

    curl -fsS http://localhost:10428/health
    curl -fsS http://localhost:10428/select/vmui/ | head
    curl -fsS http://localhost:16686/ | head
    curl -fsS http://localhost:10428/select/jaeger/api/services | jq

`/health` must return exactly `OK`. The VMUI and Jaeger UI commands must return HTML.
The Jaeger services query must return JSON, and after the smoke fixture is ingested that
JSON must include `codex-smoke`.

The user-facing acceptance check is browser-based. Run:

    just traces-ui

The browser should open `http://localhost:16686/` and display Jaeger UI. Searching for
service `codex-smoke` should reveal the smoke trace after the fixture has been ingested.
Run:

    just traces-vmui

The browser should open `http://localhost:10428/select/vmui/` and display the
VictoriaTraces built-in UI.


## Idempotence and Recovery

All file edits are additive except the import list in `home/default.nix` and the package
sets in `flake.nix`. Re-running `nix build .#jaeger-ui` and
`nix build .#darwinConfigurations.SungkyungM1X.system` is safe. Re-running
`sudo darwin-rebuild switch --flake .#SungkyungM1X` is safe because the activation hook
should stop only the two trace-related launchd labels, and only when their plists change.

If the Jaeger UI derivation fails with an `npmDepsHash` mismatch, copy the hash printed
by Nix into `derivations/jaeger-ui/default.nix` and rerun `nix build .#jaeger-ui`. This
is the normal fixed-output derivation workflow, not a runtime error.

If either launchd agent is registered but not healthy, inspect:

    launchctl print gui/$(id -u)/com.shinzui.victoriatraces
    launchctl print gui/$(id -u)/com.shinzui.victoriatraces-jaeger-ui
    tail -f ~/.local/share/victoria-traces/logs/*.log

If nginx fails because port `16686` is already in use, change `jaegerPort` in
`home/victoriatraces.nix`, update the `Justfile` URLs, rebuild, and record the decision
in this plan's Decision Log. If VictoriaTraces fails because port `10428` is already in
use, do the same for `port`, and also update the nginx proxy target.

To roll back the feature, remove `./victoriatraces.nix` from `home/default.nix`, remove
the trace recipes from `Justfile`, and run `sudo darwin-rebuild switch --flake
.#SungkyungM1X`. The data directory is intentionally left behind at
`~/.local/share/victoria-traces`; delete it manually only if the stored traces are no
longer needed.


## Interfaces and Dependencies

`pkgs.victoriatraces` is the VictoriaTraces package from the current nixpkgs flake
input. Its executable is `${pkgs.victoriatraces}/bin/victoria-traces`. The launchd
agent must expose this through a wrapper generated by `pkgs.writeShellScript` in
`home/victoriatraces.nix`.

`pkgs.jaeger-ui` is the new local derivation to add in
`derivations/jaeger-ui/default.nix`. It must expose static browser assets at
`${pkgs.jaeger-ui}/share/jaeger-ui/index.html`. No executable interface is required for
this package.

`pkgs.nginx` is the local HTTP server for Jaeger UI. It must run in foreground mode
from a generated configuration file, with a writable prefix under
`$HOME/.local/share/victoria-traces/nginx`. Its public interface is
`http://localhost:16686/`; internally it serves static files and proxies `/api` to
`http://127.0.0.1:10428/select/jaeger/api`.

`home/victoriatraces.nix` must define two launchd agents:
`launchd.agents.victoriatraces` with label `com.shinzui.victoriatraces`, and
`launchd.agents.victoriatraces-jaeger-ui` with label
`com.shinzui.victoriatraces-jaeger-ui`. It must also add a
`home.activation.victoriatraces-init` hook and a
`home.activation.victoriatraces-stop-agents` hook.

`Justfile` must expose these user commands: `traces-ui`, `traces-vmui`,
`status-victoriatraces`, `restart-victoriatraces`, and `logs-victoriatraces`.

Every implementation commit made for this plan must include the git trailer:

    ExecPlan: docs/plans/2-add-victoriatraces-with-jaeger-ui.md
