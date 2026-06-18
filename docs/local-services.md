# Local Services

Everything this machine runs in the background, defined declaratively in this
repo and wired up on `darwin-rebuild switch`. Most are per-user **launchd
agents** (`gui/$(id -u)/com.shinzui.*`); the web proxy is a system **launchd
daemon**.

All services start on login (`RunAtLoad`) and restart on crash (`KeepAlive`,
except the cron-style ones). On `darwin-rebuild switch`, each module's
pre-activation hook stops the old agent and waits for it to exit by PID before
home-manager re-registers it — but only when the plist actually changed.

## Friendly URLs (Caddy proxy)

Instead of memorizing ports, named `*.localhost` hosts forward to loopback
services. macOS resolves `*.localhost` to loopback natively (no `/etc/hosts`),
and it's plain HTTP on `:80` so there's no local CA to trust.

| URL | Target | Service |
| --- | --- | --- |
| http://logs.localhost | `127.0.0.1:9428` | VictoriaLogs (UI at `/select/vmui/`) |
| http://traces.localhost | `127.0.0.1:10428` | VictoriaTraces (UI at `/select/vmui/`) |
| http://jaeger.localhost | `127.0.0.1:16686` | Jaeger UI |
| http://mina.localhost | `127.0.0.1:8765` | mina web |
| http://reiko.localhost | `127.0.0.1:8770` | reiko web |

Defined in `darwin/local-web-proxy.nix` (Caddy, system daemon on port 80).

## Observability

### VictoriaLogs — `home/victorialogs.nix`

Log storage + query engine on `127.0.0.1:9428`. Data in
`~/.local/share/victoria-logs`.

- **victorialogs** — the server.
- **victorialogs-shipper-\<app>-\<stream>** — one tiny tail-and-push agent per
  log stream. Each tails a service's stdout/stderr file and ships new lines to
  VictoriaLogs as ndjson. Covered apps: `rei-worker`, `rei-worker-git-sync`,
  `rei-subscription`, `mori-automate`, `mori-rei-app`, `notion-hub-subscription`,
  `postgresql`.

UI: http://logs.localhost/select/vmui/ · `just logs-ui` · `just logs-query '<LogsQL>'`

### VictoriaTraces + Jaeger — `home/victoriatraces.nix`

Distributed-trace storage on `127.0.0.1:10428` (7-day retention), data in
`~/.local/share/victoria-traces`.

- **victoriatraces** — the server. Ingests OTLP at
  `…:10428/insert/opentelemetry/v1/traces`.
- **victoriatraces-jaeger-ui** — an nginx serving the static Jaeger UI on
  `127.0.0.1:16686`. `/` serves the Jaeger bundle; `/api` proxies to
  VictoriaTraces' Jaeger-compatible API (`…:10428/select/jaeger/api`).

UIs: http://jaeger.localhost (Jaeger) · http://traces.localhost/select/vmui/
(VMUI) · `just traces-ui` / `just traces-vmui`

Apps export traces via OTEL env vars (e.g. `home/rei.nix` sets
`OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:10428/insert/opentelemetry`).

### PostgreSQL — `home/postgresql.nix`

Shared database for every app service. Primary access is via a **unix socket**
(`~/.local/state/postgresql`); each app gets its connection string injected via
`*_PG_CONNECTION_STRING` env vars. Data in `~/.local/share/postgresql`.

- **postgresql** — the server.

Status: `just status-postgres` · Logs: `just logs-postgres` · Backups: see
[`pg-backup.md`](pg-backup.md).

## Application services

| Service | Module | Label | What it does |
| --- | --- | --- | --- |
| rei subscription | `home/rei.nix` | `com.shinzui.rei-subscription` | rei event subscriptions / read models |
| rei worker | `home/rei.nix` | `com.shinzui.rei-worker` | scheduled action worker |
| rei worker (git-sync) | `home/rei.nix` | `com.shinzui.rei-worker-git-sync` | git sync worker |
| rei worker (kiroku) | `home/rei.nix` | `com.shinzui.rei-worker-kiroku` | kiroku worker; metrics on `127.0.0.1:9091` |
| mori automate | `home/mori.nix` | `com.shinzui.mori-automate` | `mori automate daemon`, 10-min ingest interval |
| mori-rei-app | `home/mori-rei-app.nix` | `com.shinzui.mori-rei-app` | webhook receiver (`mori-rei-app serve`) |
| notion-hub | `home/notion-hub.nix` | `com.shinzui.notion-hub-subscription` | Notion subscription/sync |
| rei watchdog | `home/rei-doctor.nix` | `com.shinzui.rei-watchdog` | health check every 5 min (`rei-doctor --heal --notify`); **not** KeepAlive |

See [`rei.md`](rei.md) and [`mori.md`](mori.md) for per-system detail.

## Web UIs

| Service | Module | Label | URL |
| --- | --- | --- | --- |
| mina web | `home/mina.nix` | `com.shinzui.mina-web` | http://mina.localhost (`127.0.0.1:8765`) |
| reiko web | `home/reiko.nix` | `com.shinzui.reiko-web` | http://reiko.localhost (`127.0.0.1:8770`) |

## Operating the services

Common `just` recipes (see `justfile`, grouped by `tools` / `logs` / `traces`):

```bash
just status-tools          # status of mori, mori-rei-app, rei, notion-hub
just status-mori           # / status-rei / status-notion-hub / status-postgres
just status-victorialogs   # / status-victoriatraces
just restart-mori          # / restart-victorialogs / restart-victoriatraces / ...
just logs-rei              # / logs-mori / logs-notion-hub / logs-victoriatraces / ...
```

Manual launchctl, for anything without a recipe:

```bash
launchctl print     gui/$(id -u)/com.shinzui.<label>   # inspect
launchctl kickstart -k gui/$(id -u)/com.shinzui.<label> # restart
```

System web proxy (Caddy) is a daemon, not a per-user agent:

```bash
sudo launchctl print system/shinzui.local-web-proxy
tail -f /var/log/shinzui-local-web-proxy.stderr.log
```
