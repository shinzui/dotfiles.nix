# Local Services

Everything this machine runs in the background, defined declaratively in this
repo and wired up on `darwin-rebuild switch`. They are per-user **launchd
agents** (`gui/$(id -u)/com.shinzui.*`), including the web proxy — macOS does
not reserve ports below 1024, so an unprivileged agent binds `:80` fine.

One exception to the naming rule: Apple Container's own API server registers
itself as `com.apple.container.apiserver` in the `user/$(id -u)` domain, not
`gui/$(id -u)`. See the Redpanda section.

All services start on login (`RunAtLoad`) and restart on crash (`KeepAlive`,
except the cron-style ones). On `darwin-rebuild switch`, each module's
pre-activation hook stops the old agent and waits for it to exit by PID before
home-manager re-registers it — but only when the plist actually changed.

## Friendly URLs (Caddy proxy)

Instead of memorizing ports, named hosts forward to loopback services. Caddy
routes on the **first label** of the `Host` header rather than on a fixed site
address, so the domain suffix is irrelevant — `mina.<anything>` reaches mina.
It's plain HTTP on `:80`, so there's no local CA to trust.

| URL | Target | Service |
| --- | --- | --- |
| http://logs.localhost | `127.0.0.1:9428` | VictoriaLogs (UI at `/select/vmui/`) |
| http://traces.localhost | `127.0.0.1:10428` | VictoriaTraces (UI at `/select/vmui/`) |
| http://jaeger.localhost | `127.0.0.1:16686` | Jaeger UI |
| http://mina.localhost | `127.0.0.1:8765` | mina web |
| http://reiko.localhost | `127.0.0.1:8770` | reiko web |
| http://redpanda.localhost | `127.0.0.1:8080` | Redpanda Console |

On this machine the `.localhost` suffix needs no `/etc/hosts` wiring — macOS
resolves `*.localhost` to loopback natively. An unrecognized first label gets a
404 naming the host Caddy saw, rather than falling through to a default service.

Routes are generated from a `name -> port` attrset in `home/local-web-proxy.nix`
(Caddy, user agent `com.shinzui.local-web-proxy`, on port 80); adding a service
is one line in that attrset.

### From another device on the LAN

Caddy binds `0.0.0.0:80`, so every route above is *already* reachable from the
network — only the name has to change. `.localhost` can never work off-machine:
RFC 6761 pins `*.localhost` to the client's own loopback, so a phone asking for
`mina.localhost` resolves to itself, and no DNS wiring can change that. Swap in
a suffix that real DNS answers with this Mac's LAN address:

| Suffix | Example | Client setup |
| --- | --- | --- |
| [sslip.io](https://sslip.io) | `mina.192-168-1-115.sslip.io` | none — public DNS reflects the IP encoded in the name |
| Router static DNS | `mina.home.arpa` | none, once the record and a DHCP reservation exist |
| `/etc/hosts` | `mina.lan` | per device; not possible on iOS |

sslip.io is the quickest to try and needs nothing configured anywhere, at the
cost of two caveats: it needs working internet DNS, and the address is baked
into the name, so a new DHCP lease breaks every URL. Router-level DNS plus a
DHCP reservation for this Mac is the stable version. Use `.home.arpa` (RFC 8375),
`.lan`, or `.internal` for those records — **not** `.local`, which collides with
mDNS.

```bash
ipconfig getifaddr en0                      # this Mac's current LAN address
dig +short mina.192-168-1-115.sslip.io      # should echo that same address back
```

If the `dig` comes back empty, the router is likely applying DNS rebinding
protection, which drops public DNS answers pointing at private IPs and breaks
sslip.io specifically; use router DNS or `/etc/hosts` instead. If the name
resolves but the connection hangs, check the macOS application firewall — it is
currently off, and enabling it would block Caddy until it's allowed explicitly.

**None of these UIs have authentication.** VictoriaLogs, VictoriaTraces, Jaeger,
and the Redpanda Console are all unauthenticated, and LAN reachability means any
device on the network — guest devices included, unless the Wi-Fi isolates them.
To pin one back to this machine, replace its first-label matcher in
`home/local-web-proxy.nix` with an explicit host list:

```
@jaeger host jaeger.localhost
```

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

### Redpanda — `home/redpanda.nix`

A single-broker Kafka-compatible cluster plus its web console, running as **Apple
Container** containers rather than in Colima. Colima is not needed and does not
have to be running. Data lives on a named container volume (`redpanda-0-data`)
and survives restarts.

- **redpanda** (`com.shinzui.redpanda`) — a one-shot agent that runs
  `redpanda-up` at login and exits; the containers themselves are supervised by
  Apple Container. Unlike the long-running services above it uses
  `KeepAlive = { SuccessfulExit = false; }`, so a failed bring-up is retried and
  a successful one is not restarted in a loop.

| Endpoint | Address |
| --- | --- |
| Kafka API | `127.0.0.1:9092` |
| Admin API | `127.0.0.1:9644` |
| Schema Registry | `127.0.0.1:8081` |
| HTTP Proxy | `127.0.0.1:8082` |
| Console | http://redpanda.localhost (`127.0.0.1:8080`) |

`rpk` reaches it from any directory with no flags via the `local` profile in
`~/Library/Application Support/rpk/rpk.yaml`, created by an activation hook in
`home/redpanda.nix`.

Status: `just status-redpanda` · Logs: `just logs-redpanda` · Full runbook:
[`redpanda.md`](redpanda.md).

The module comes from a separate flake (`github:shinzui/redpanda-container`),
registered in `flake-modules/modules.nix`. Apple Container itself is packaged in
`derivations/apple-container.nix` and its service is kept running by
`home/apple-container.nix`.

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
just status-redpanda       # containers + broker readiness
just restart-mori          # / restart-victorialogs / restart-victoriatraces / ...
just logs-rei              # / logs-mori / logs-notion-hub / logs-victoriatraces / ...
just logs-redpanda         # broker logs; logs-redpanda-agent for the login output
```

Manual launchctl, for anything without a recipe:

```bash
launchctl print     gui/$(id -u)/com.shinzui.<label>   # inspect
launchctl kickstart -k gui/$(id -u)/com.shinzui.<label> # restart
```

The web proxy (Caddy) is a per-user agent like everything else:

```bash
launchctl print gui/$(id -u)/com.shinzui.local-web-proxy
tail -f ~/.local/state/local-web-proxy/*.log
```

Apple Container's API server is the one service not registered by home-manager,
and it lives in a different launchd domain — `user/`, not `gui/`:

```bash
launchctl print user/$(id -u)/com.apple.container.apiserver
container system status          # simpler: exits 0 when healthy
container system stop && container system start   # the fix when it wedges
```
