---
id: 3
slug: add-local-named-web-proxy
title: "Add local named web proxy"
kind: exec-plan
created_at: 2026-06-07T20:38:14Z
intention: intention_01kthxpa1zenksaywzsffwzce6
---

# Add local named web proxy

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.


## Purpose / Big Picture

After this change the local web tools in this dotfiles repo have stable browser names instead of memorized numeric ports. A user can run one normal `darwin-rebuild switch --flake .#SungkyungM1X`, let launchd start the services, and then open:

```text
http://mina.localhost/
http://reiko.localhost/
http://logs.localhost/select/vmui/
http://traces.localhost/select/vmui/
```

The implementation uses Caddy as a small reverse proxy. A reverse proxy is a local HTTP server that receives browser requests for a public-facing name, then forwards each request to the actual loopback service. Here Caddy listens on privileged port `80` and forwards to existing local services on `127.0.0.1`: Mina on `8765`, Reiko on `8770`, VictoriaLogs on `9428`, and VictoriaTraces on `10428`. Mina and Reiko also get launchd agents so their web UIs are available without manually running `mina web --global` or `reiko web`.


## Progress

- [x] (2026-06-07) Update `flake.nix` so the Mina wrapper links `share/` (in addition to `bin/`), matching the Reiko wrapper. Done — wrapper now binds `src=` and links both `bin` and `share`; verified the realized `pkgs.mina` has `share -> .../mina-cli-0.1.0.0/share` (which contains `mina-ui`).
- [x] (2026-06-07) Add a per-user Mina launchd agent in `home/mina.nix` that runs `mina web --global --host 127.0.0.1 --port 8765 --no-open`. Done — `launchd.agents.mina-web` (Label `com.shinzui.mina-web`); verified generated wrapper invokes the exact command.
- [x] (2026-06-07) Add a per-user Reiko launchd agent in `home/reiko.nix` that runs `reiko web --host 127.0.0.1 --port 8770 --no-open`. Done — `launchd.agents.reiko-web` (Label `com.shinzui.reiko-web`); verified generated wrapper invokes the exact command.
- [x] (2026-06-07) Add a nix-darwin Caddy LaunchDaemon module, import it from `darwin/default.nix`, and configure `mina.localhost`, `reiko.localhost`, `logs.localhost`, and `traces.localhost`. Done — `darwin/local-web-proxy.nix` defines `launchd.daemons."shinzui-local-web-proxy"`; verified generated Caddyfile and daemon plist `ProgramArguments`.
- [x] (2026-06-07) Run Nix evaluation/build validation. Done — `nix build .#darwinConfigurations.SungkyungM1X.system` exits 0 and realizes `darwin-system-26.05`.
- [ ] Rebuild the machine profile and verify all four named URLs with `curl`. (Requires `sudo darwin-rebuild switch`; pending user-driven apply.)


## Surprises & Discoveries

- 2026-06-07 (plan validation): The upstream Mina package **does** ship its built UI at `share/mina-ui`. Verified by resolving the wrapper's `bin` symlink to `/nix/store/...-mina-cli-0.1.0.0` and listing `share/mina-ui` there. However, the `flake.nix` wrapper (`mina = prev.runCommand "mina" ...`) links only `bin`, not `share`. `mina web` resolves installed assets via `installedDistCandidates` in `mina-cli/src/Mina/CLI/Web.hs`, which checks `<prefix>/share/mina-ui` where `<prefix>` is derived from the executable path. Linking `share/` into the wrapper (like Reiko already does) makes this robust regardless of how `getExecutablePath` treats the symlinked `bin`. This turns the first Progress item from a conditional check into a definite edit.
- 2026-06-07 (plan validation): macOS resolves `*.localhost` natively. `dscacheutil -q host -a name mina.localhost` returns `::1` and `127.0.0.1`, and `socket.getaddrinfo('mina.localhost', 80)` returns `::1`. This confirms the decision to skip `/etc/hosts` / `networking.hosts` entries. Note: resolution prefers IPv6 (`::1`) first. A Caddy `http://name.localhost { ... }` site binds port `80` on all interfaces (v4 and v6) and matches on the `Host` header, so `::1`-first resolution is handled — no IPv4/IPv6 mismatch is expected.
- 2026-06-07 (plan validation): Confirmed default ports from source — Mina `value 8765` in `mina-cli/src/Mina/CLI/Web.hs:251`, Reiko `value 8770` in `reiko-cli/src/Reiko/Cli/Web.hs:164`. Confirmed `mina web` flags `--host/--port/--dist/--no-open/--global` and `reiko web` flags `--host/--port/--dist/--no-open` (Reiko has no `--global`). Confirmed `flake.nix` import list, `darwin/default.nix` import list, and that `pkgs.caddy` is already installed via `home/default.nix:118`.


## Decision Log

Record every decision made while working on the plan.

- Decision: Use Caddy rather than Portless for the named local web layer.
  Rationale: The services in scope have fixed local ports or can be pinned with command-line flags. Portless solves a harder dynamic-port problem by wrapping child processes and maintaining a route registry, but this dotfiles change only needs stable hostnames that proxy to known loopback ports. Caddy is already installed in `home/default.nix`, has a compact `reverse_proxy` directive, and fits a static declarative Nix module.
  Date: 2026-06-07
- Decision: Start with plain HTTP on port `80`, not HTTPS on `443`.
  Rationale: Clean names without `:port` require a privileged listener either way. Plain HTTP avoids local CA trust, certificate storage, and browser trust edge cases for `.localhost` names. The services are bound to loopback and are local-only. HTTPS can be added later by extending the Caddy module if there is a concrete need.
  Date: 2026-06-07
- Decision: Use `.localhost` hostnames and do not add `/etc/hosts` entries.
  Rationale: `.localhost` names are intended for loopback use and avoid choosing a custom TLD such as `.test`. Plan validation confirmed macOS already resolves `*.localhost` to `::1`/`127.0.0.1` via `dscacheutil` and `getaddrinfo` (see Surprises & Discoveries), so no DNS wiring is required for the first implementation. The `networking.hosts` fallback in Idempotence and Recovery is retained only as a contingency if resolution behaves differently on the target machine at switch time.
  Date: 2026-06-07
- Decision: Run Caddy as a nix-darwin `launchd.daemon`, while Mina and Reiko run as Home Manager `launchd.agents`.
  Rationale: Caddy must bind port `80`, which is privileged on macOS and belongs in the system layer. Mina and Reiko are user tools that read user configuration and should run in the user launchd domain, matching existing modules such as `home/victorialogs.nix`, `home/victoriatraces.nix`, and `home/mori-rei-app.nix`.
  Date: 2026-06-07


## Outcomes & Retrospective

(To be filled during and after implementation.)


## Context and Orientation

This repository is a Nix flake that configures macOS through nix-darwin and Home Manager. The system-level nix-darwin module is `darwin/default.nix`. Per-user Home Manager modules live under `home/` and are imported by `home/default.nix`.

The existing service pattern is visible in `home/victorialogs.nix`, `home/victoriatraces.nix`, and `home/mori-rei-app.nix`. Each module builds a wrapper script with `pkgs.writeShellScript`, creates log directories with a Home Manager activation hook, and declares one or more `launchd.agents.<name>` entries. A launchd agent is a per-user background process managed by macOS launchd. Its generated plist lands in `~/Library/LaunchAgents/`, and it runs in the user launchd domain shown by `launchctl print gui/$(id -u)/<label>`.

The system-level launchd daemon pattern is visible in `darwin/bootstrap.nix`, which declares `launchd.daemons."limit.maxfiles"`. A launchd daemon is a system background process. It can bind privileged ports such as `80` and `443`, unlike a normal per-user process. The Caddy proxy in this plan should use this system daemon pattern.

The target backend services are:

Mina web UI: `mina web` is documented in the Mina project as a local web server. In `/Users/shinzui/Keikaku/bokuno/mina/README.md`, `mina web` accepts `--host`, `--port`, `--no-open`, and `--global`. The default port is `8765` in `mina-cli/src/Mina/CLI/Web.hs`. The desired service command is:

```bash
mina web --global --host 127.0.0.1 --port 8765 --no-open
```

Reiko web UI: mori registry lookup reports `shinzui/reiko` at `/Users/shinzui/Keikaku/bokuno/rei-project/reiko`. Its source file `reiko-cli/src/Reiko/Cli/Web.hs` defines `reiko web` with `--host`, `--port`, `--dist`, and `--no-open`. Its parser default port is `8770`. The desired service command is:

```bash
reiko web --host 127.0.0.1 --port 8770 --no-open
```

VictoriaLogs: `home/victorialogs.nix` runs VictoriaLogs on port `9428` with `-httpListenAddr=":9428"`. Its browser UI is already used through `http://localhost:9428/select/vmui/`. Caddy should proxy `logs.localhost` to `127.0.0.1:9428`.

VictoriaTraces: `home/victoriatraces.nix` runs VictoriaTraces on port `10428` with `-httpListenAddr=":10428"`. Its browser UI is already used through `http://localhost:10428/select/vmui/`. Caddy should proxy `traces.localhost` to `127.0.0.1:10428`. The same module also runs a Jaeger UI nginx proxy on `127.0.0.1:16686`, but this plan does not create a named `jaeger.localhost` route because the requested set is Mina, logs, traces, and Reiko.

The package overlay in `flake.nix` wraps `pkgs.reiko` to expose `bin/` and `share/`, with a comment explaining that `share/reiko-ui` is needed so `reiko web` can find the built SPA assets. The same file wraps `pkgs.mina` to expose only `bin/`. Plan validation confirmed the upstream Mina package ships `share/mina-ui`, and `mina web` looks for `<prefix>/share/mina-ui` (via `installedDistCandidates` in `mina-cli/src/Mina/CLI/Web.hs`). Therefore the Mina wrapper must be updated to also link `share/`, mirroring the Reiko wrapper, so `mina web` can run outside the Mina source checkout. This is no longer a conditional check — it is a required edit.


## Plan of Work

Milestone 1 establishes reliable backend services for the two web UIs that are not already launchd-managed. Edit `home/mina.nix` to define a log directory, a wrapper script, a Home Manager activation hook, and a `launchd.agents.mina-web` entry. The wrapper should timestamp stdout and stderr like the existing service wrappers and then execute `${pkgs.mina}/bin/mina web --global --host 127.0.0.1 --port 8765 --no-open`. Also edit `flake.nix` at the `mina = prev.runCommand "mina"` wrapper (around line 277): the upstream Mina package ships `share/mina-ui` (confirmed during validation), so link `share` into the wrapper output alongside `bin` so the launchd-launched binary can find its installed UI. Edit `home/reiko.nix` with the same pattern for `reiko web --host 127.0.0.1 --port 8770 --no-open`. At the end of this milestone, Home Manager should generate two new user launchd plists and the commands should be visible in those plists.

Milestone 2 adds the named proxy. Create `darwin/local-web-proxy.nix`. This module should define a `pkgs.writeText` Caddyfile and a `launchd.daemons."shinzui-local-web-proxy"` service that runs:

```bash
caddy run --config <generated-caddyfile> --adapter caddyfile
```

The Caddyfile should listen on HTTP port `80` and contain four host blocks:

```caddyfile
http://mina.localhost {
  reverse_proxy 127.0.0.1:8765
}

http://reiko.localhost {
  reverse_proxy 127.0.0.1:8770
}

http://logs.localhost {
  reverse_proxy 127.0.0.1:9428
}

http://traces.localhost {
  reverse_proxy 127.0.0.1:10428
}
```

Import `./local-web-proxy.nix` from `darwin/default.nix` next to the other nix-darwin modules. At the end of this milestone, `nix build .#darwinConfigurations.SungkyungM1X.system` should evaluate the Caddyfile and daemon plist.

Milestone 3 validates the full system after a rebuild. Run the darwin switch. Confirm Caddy is loaded in the system launchd domain, confirm Mina and Reiko are loaded in the user domain, and make HTTP requests through each named host. At the end of this milestone, `curl -I http://mina.localhost/`, `curl -I http://reiko.localhost/`, `curl -I http://logs.localhost/select/vmui/`, and `curl -I http://traces.localhost/select/vmui/` should all return successful HTTP statuses from Caddy-proxied backends. If the `.localhost` names fail DNS resolution, add explicit host entries in the same nix-darwin module and rerun the build; see Idempotence and Recovery.


## Concrete Steps

Work from the dotfiles repository:

```bash
cd /Users/shinzui/Keikaku/dotfiles.nix
```

First inspect the current status so unrelated changes are not mixed into the implementation:

```bash
git status --short
```

Expected output may include this plan file. If there are unrelated user changes, leave them alone.

Inspect the Mina and Reiko package wrappers:

```bash
sed -n '255,300p' flake.nix
cat home/mina.nix
cat home/reiko.nix
```

Note: `home/mina.nix` and `home/reiko.nix` are currently minimal (each takes `{ pkgs, ... }` and only declares `home.packages` plus a zsh-completions entry). The edits below replace each file with the full service-wrapper shape while preserving the completions logic, and switch the function signature to `{ config, pkgs, lib, ... }`.

Update the Mina wrapper in `flake.nix` to link `share` alongside `bin`. The current wrapper (around line 277) is:

```nix
mina = prev.runCommand "mina" {} ''
  mkdir -p $out
  ln -s ${inputs.mina.packages.${prev.stdenv.hostPlatform.system}.default}/bin $out/bin
'';
```

Change it to bind the package to a `src` variable and link both `bin` and `share`, mirroring the Reiko wrapper:

```nix
mina = prev.runCommand "mina" {} ''
  mkdir -p $out
  src=${inputs.mina.packages.${prev.stdenv.hostPlatform.system}.default}
  ln -s $src/bin $out/bin
  ln -s $src/share $out/share
'';
```

Edit `home/mina.nix` so it follows this shape, preserving the existing completions logic:

```nix
{ config, pkgs, lib, ... }:

let
  logDir = "${config.home.homeDirectory}/.mina/logs";
  mina-zsh-completions = pkgs.runCommand "mina-zsh-completions" { } ''
    ${pkgs.mina}/bin/mina completions zsh > $out
  '';
  mina-web-wrapper = pkgs.writeShellScript "mina-web" ''
    set -euo pipefail
    mkdir -p "${logDir}"
    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)
    exec ${pkgs.mina}/bin/mina web --global --host 127.0.0.1 --port 8765 --no-open
  '';
in
{
  home.packages = [
    pkgs.mina
  ];

  home.file.".zfunc/_mina".source = mina-zsh-completions;

  home.activation.mina-log-dir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${logDir}"
  '';

  launchd.agents.mina-web = {
    enable = true;
    config = {
      Label = "com.shinzui.mina-web";
      ProgramArguments = [ "${mina-web-wrapper}" ];
      RunAtLoad = true;
      KeepAlive = true;
      ExitTimeOut = 15;
      StandardOutPath = "${logDir}/web.stdout.log";
      StandardErrorPath = "${logDir}/web.stderr.log";
    };
  };
}
```

If Mina's generated plist changes during a rebuild, Home Manager may need the same stop-and-wait activation hook used in `home/mori.nix` and `home/mori-rei-app.nix`. Add it if launchd reports bootstrap errors during switch.

Edit `home/reiko.nix` similarly, using `~/.reiko/logs`, `com.shinzui.reiko-web`, and:

```bash
exec ${pkgs.reiko}/bin/reiko web --host 127.0.0.1 --port 8770 --no-open
```

Create `darwin/local-web-proxy.nix` with a system daemon. Use this as the intended structure:

```nix
{ pkgs, ... }:

let
  caddyfile = pkgs.writeText "local-web-proxy.Caddyfile" ''
    http://mina.localhost {
      reverse_proxy 127.0.0.1:8765
    }

    http://reiko.localhost {
      reverse_proxy 127.0.0.1:8770
    }

    http://logs.localhost {
      reverse_proxy 127.0.0.1:9428
    }

    http://traces.localhost {
      reverse_proxy 127.0.0.1:10428
    }
  '';
in
{
  environment.systemPackages = [ pkgs.caddy ];

  launchd.daemons."shinzui-local-web-proxy" = {
    serviceConfig = {
      Label = "shinzui.local-web-proxy";
      ProgramArguments = [
        "${pkgs.caddy}/bin/caddy"
        "run"
        "--config"
        "${caddyfile}"
        "--adapter"
        "caddyfile"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/var/log/shinzui-local-web-proxy.stdout.log";
      StandardErrorPath = "/var/log/shinzui-local-web-proxy.stderr.log";
    };
  };
}
```

Add the module to `darwin/default.nix`:

```nix
imports = [
  ./bootstrap.nix
  ./homebrew.nix
  ./secrets.nix
  ./mac-defaults.nix
  ./gcp-nix-builder.nix
  ./local-web-proxy.nix
];
```

Validate before switching:

```bash
nix flake check
nix build .#darwinConfigurations.SungkyungM1X.system
```

If `nix flake check` is too broad or slow for the current machine, at minimum run the `nix build` command above. A successful build exits with status 0 and prints no final error.

Apply the configuration:

```bash
sudo darwin-rebuild switch --flake .#SungkyungM1X
```

After the switch, check launchd:

```bash
sudo launchctl print system/shinzui.local-web-proxy | head -40
launchctl print "gui/$(id -u)/com.shinzui.mina-web" | head -40
launchctl print "gui/$(id -u)/com.shinzui.reiko-web" | head -40
```

Each command should include `state = running` once the service is healthy.


## Validation and Acceptance

The build-level acceptance is:

```bash
cd /Users/shinzui/Keikaku/dotfiles.nix
nix build .#darwinConfigurations.SungkyungM1X.system
```

The command exits 0.

The runtime acceptance is:

```bash
curl -fsSI http://mina.localhost/ | sed -n '1,5p'
curl -fsSI http://reiko.localhost/ | sed -n '1,5p'
curl -fsSI http://logs.localhost/select/vmui/ | sed -n '1,5p'
curl -fsSI http://traces.localhost/select/vmui/ | sed -n '1,5p'
```

Each command should print an HTTP status line such as:

```text
HTTP/1.1 200 OK
```

Some single-page applications may return `302` or another successful redirect for a path. That is acceptable if following the redirect with `curl -fsSL` returns HTML.

Also verify the backend services directly to separate proxy failures from backend failures:

```bash
curl -fsSI http://127.0.0.1:8765/ | sed -n '1,5p'
curl -fsSI http://127.0.0.1:8770/ | sed -n '1,5p'
curl -fsS http://127.0.0.1:9428/health
curl -fsS http://127.0.0.1:10428/health
```

The VictoriaLogs and VictoriaTraces health endpoints should print:

```text
OK
```

Finally, open the browser URLs manually:

```bash
open http://mina.localhost/
open http://reiko.localhost/
open http://logs.localhost/select/vmui/
open http://traces.localhost/select/vmui/
```

Mina should show the global project picker or global-mode UI. Reiko should show the Reiko viewer. Logs should show the VictoriaLogs VMUI. Traces should show the VictoriaTraces VMUI.


## Idempotence and Recovery

The Nix edits are declarative and safe to rebuild repeatedly. Re-running `nix build .#darwinConfigurations.SungkyungM1X.system` only builds a new system closure. Re-running `sudo darwin-rebuild switch --flake .#SungkyungM1X` reapplies the launchd daemon and agents.

If Caddy fails because port `80` is already in use, find the owner:

```bash
sudo lsof -nP -iTCP:80 -sTCP:LISTEN
```

If the owner is an old manual Caddy process, stop it. If another important service owns port `80`, change the Caddy daemon to listen on `8080`, update the URLs in this plan to include `:8080`, and record the decision in the Decision Log.

Validation confirmed macOS resolves `*.localhost` natively (`dscacheutil -q host -a name mina.localhost` returns `::1`/`127.0.0.1`), so the fallback below should not be needed. If, on the target machine at switch time, `.localhost` names still fail to resolve, add a fallback to `darwin/local-web-proxy.nix`:

```nix
networking.hosts = {
  "127.0.0.1" = [
    "mina.localhost"
    "reiko.localhost"
    "logs.localhost"
    "traces.localhost"
  ];
};
```

Use `lib.mkAfter` around the list if this repo already manages the same `networking.hosts."127.0.0.1"` entry by the time this plan is implemented. Then rebuild and retry the curl commands.

Caddy run as a root LaunchDaemon has no `HOME`, so it falls back to a system data directory for its admin autosave config and may emit a warning about persisting config. This is harmless for a static `--config` Caddyfile. If Caddy logs an error (not just a warning) about being unable to write its data directory, add `EnvironmentVariables = { HOME = "/var/root"; XDG_DATA_HOME = "/var/lib/caddy"; };` to the daemon `serviceConfig` and rebuild. Check `/var/log/shinzui-local-web-proxy.stderr.log` first to confirm whether this is actually occurring before adding the workaround.

If Mina or Reiko fails to start because launchd does not have the same environment as an interactive shell, inspect its stderr log:

```bash
tail -100 ~/.mina/logs/web.stderr.log
tail -100 ~/.reiko/logs/web.stderr.log
```

If the error is a missing frontend build for Mina, update the Mina package wrapper in `flake.nix` to link `share/` from the upstream package, matching the Reiko wrapper. If the upstream Mina package does not ship `share/`, set `MINA_WEB_DIST` in the Mina launchd agent to an existing built `mina-ui/dist` path and record that as a temporary workaround.

To roll back the whole feature, remove `./local-web-proxy.nix` from `darwin/default.nix`, remove `darwin/local-web-proxy.nix`, remove the `mina-web` and `reiko-web` launchd agents from `home/mina.nix` and `home/reiko.nix`, then run:

```bash
sudo darwin-rebuild switch --flake .#SungkyungM1X
```


## Interfaces and Dependencies

The external program dependency is Caddy from `pkgs.caddy`. Caddy's `reverse_proxy` directive forwards HTTP requests to loopback upstreams and preserves enough request context for these local apps. The Caddyfile interface required by this plan is host block plus upstream:

```caddyfile
http://name.localhost {
  reverse_proxy 127.0.0.1:PORT
}
```

The nix-darwin interface is `launchd.daemons.<name>.serviceConfig`, used in `darwin/bootstrap.nix`. The new module should be `darwin/local-web-proxy.nix`, imported by `darwin/default.nix`.

The Home Manager interface is `launchd.agents.<name>.config`, used by `home/victorialogs.nix`, `home/victoriatraces.nix`, `home/mori.nix`, `home/rei.nix`, and `home/mori-rei-app.nix`. The Mina web service belongs in `home/mina.nix`; the Reiko web service belongs in `home/reiko.nix`.

The Mina command interface is:

```bash
mina web --global --host 127.0.0.1 --port 8765 --no-open
```

The Reiko command interface is:

```bash
reiko web --host 127.0.0.1 --port 8770 --no-open
```

The existing backend ports are part of the service contract for this plan:

```text
mina.localhost   -> 127.0.0.1:8765
reiko.localhost  -> 127.0.0.1:8770
logs.localhost   -> 127.0.0.1:9428
traces.localhost -> 127.0.0.1:10428
```

No new Haskell, TypeScript, database, or browser UI code is required. This is a dotfiles and launchd wiring change.


## Revision Notes

- 2026-06-07 (validation pass): Validated every concrete claim in the plan against the working tree and dependency sources, and folded the findings back in.
  - Confirmed the upstream Mina package ships `share/mina-ui` and that `mina web` resolves installed UI assets from `<prefix>/share/mina-ui`, while the `flake.nix` Mina wrapper links only `bin/`. Promoted the first Progress item and Milestone 1 from a conditional "check whether..." into a required `flake.nix` edit, and added the exact before/after wrapper snippet to Concrete Steps.
  - Confirmed macOS resolves `*.localhost` natively (`dscacheutil`/`getaddrinfo` → `::1`/`127.0.0.1`). Updated the `.localhost` Decision Log entry and the Idempotence and Recovery note to state the `networking.hosts` fallback is a contingency, not an expected step. Noted IPv6-first (`::1`) resolution and why Caddy's all-interfaces `:80` bind handles it.
  - Confirmed default ports (Mina `8765`, Reiko `8770`) and CLI flags directly from `mina-cli/src/Mina/CLI/Web.hs` and `reiko-cli/src/Reiko/Cli/Web.hs`; confirmed `pkgs.caddy` is already installed (`home/default.nix:118`), and that the `flake.nix` / `darwin/default.nix` import lists match the snippets in the plan.
  - Corrected the inspection commands in Concrete Steps: the `sed` range for `flake.nix` now covers the actual wrapper lines (255–300), and noted that `home/mina.nix` and `home/reiko.nix` are currently minimal `{ pkgs, ... }` modules being replaced wholesale (signature changes to `{ config, pkgs, lib, ... }`).
  - Added a Caddy-as-root-daemon `HOME`/`XDG_DATA_HOME` recovery note for the autosave-config edge case.
