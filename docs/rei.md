# Rei

Sungkyung is the current sole runtime host. Keep the Yujin runtime stopped until
the separate [host cutover](rei-mori-cutover.md); runtime setup, migrations and
restart commands below apply to the active host.

Event-driven task processing system. Configured in `home/rei.nix`.

## Architecture

Two launchd agents run as background services:

- **rei-subscription** — runs `rei subscription run all`, listens for events and updates read models
- **rei-worker** — runs `rei worker all`, processes queued tasks

PostgreSQL is provided by the shared system service (unix socket, no TCP). Both wrapper scripts wait for postgres to be ready before starting.

## Services

Both agents start on login (`RunAtLoad`) and restart on crash (`KeepAlive`, `ExitTimeOut = 30`). On `darwin-rebuild switch`, a pre-activation hook stops both agents and waits for their processes to fully exit (by PID) before home-manager re-registers them.

### Status

```bash
just status-rei
```

### Restart

```bash
launchctl kickstart -k gui/$(id -u)/com.shinzui.rei-subscription
launchctl kickstart -k gui/$(id -u)/com.shinzui.rei-worker
```

## Logs

All logs are in `~/.rei/logs/`:

```bash
# Subscription logs
tail -f ~/.rei/logs/subscription.stderr.log

# Worker logs
tail -f ~/.rei/logs/worker.stderr.log
```

## Global CLI and API credentials

Everyday commands execute through the local API at `http://127.0.0.1:8775`.
The installed `rei` wrapper reads the owner token privately from the existing
agenix token map. An explicit token takes precedence; the wrapper loads the local
token only for the configured local API URL. A remote caller must provide its own
API URL and credential. Operator commands retain the explicit PostgreSQL socket.

The shared wrapper in `home/rei-cli-env.nix` also supplies the CLI used by the
`mori://shinzui/mina` and `mori://shinzui/reiko` integrations. The former selects
its existing `agent:mina` credential. The API grants only the owner credential
named `claude-code` and `codex` foreground recorder profiles; the provider stays
on the caller. Secrets are read at process startup and are never Nix inputs.

`workstation.reiMori.projectOutcomeWrites` stays false by default. Enable it on
the active host only after compatible readers, migrations and shared outcome-ID
reconstruction are verified. Runtime host ownership remains governed by
[the host cutover procedure](rei-mori-cutover.md).

## Database and coordinated rollouts

The active global database uses the socket `/Users/shinzui/.local/state/postgresql`
and database `rei`. Development shells select a different database, so migration
and operator commands must name the intended target explicitly.

The current coordinated rollout is tracked by
`mori://shinzui/rei/plans/289-audit-and-roll-out-the-current-rei-cohort-to-the-global-database`.
Its source, backup, reconstruction, reader and delivery gates belong to
`mori://shinzui/rei/okf/adrs/concepts/ADR-31`. Do not deploy a new Core/catalog by
replacing only the CLI or by applying SQL without a production-restore rehearsal.
The embedded `mori://shinzui/mori-rei-app` runtime must move with Core.
