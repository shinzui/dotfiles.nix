# Mori

Project identity & automation system. Configured in `home/mori.nix`.

## Architecture

One launchd agent runs as a background service:

- **mori-automate** — runs `mori automate daemon`, which starts all event subscriptions and the scheduled action worker

The automate daemon handles all read model projections via subscriptions. CLI commands (`mori register`, `mori registry list`, etc.) write events to the event store and query the read model — they never do inline projection.

PostgreSQL is provided by the shared system service (unix socket, no TCP). The wrapper script waits for postgres to be ready before starting the daemon.

## Services

The agent starts on login (`RunAtLoad`) and restarts on crash (`KeepAlive`). On `darwin-rebuild switch`, a pre-activation hook stops the agent and waits for the process to fully exit (by PID) before home-manager re-registers it.

### Status

```bash
just status-mori
```

### Restart

```bash
launchctl kickstart -k gui/$(id -u)/com.shinzui.mori-automate
```

## Logs

All logs are in `~/.mori/logs/`:

```bash
tail -f ~/.mori/logs/automate.stderr.log
```

## Database

Uses the shared PostgreSQL service. Connection string is set automatically via `MORI_PG_CONNECTION_STRING` in the shell environment.

### Initial setup

After first `darwin-rebuild switch`:

```bash
mori-db-setup
cd ~/Keikaku/bokuno/mori-project/mori
PGHOST=~/.mori/db PGDATABASE=mori just run-migrations
```

### Migrations

After pulling mori updates that include new migrations:

```bash
cd ~/Keikaku/bokuno/mori-project/mori
just run-migrations
```
