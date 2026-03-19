# Rei

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

## Database

Uses the shared PostgreSQL service. Connection string is set automatically via `REI_PG_CONNECTION_STRING` in the shell environment.

### Initial setup

After first `darwin-rebuild switch`:

```bash
rei-db-setup
cd ~/Keikaku/bokuno/rei-project/rei-production
PGHOST=~/.rei/db PGDATABASE=rei just run-migrations
```

### Migrations

After pulling rei updates that include new migrations:

```bash
cd ~/Keikaku/bokuno/rei-project/rei-production
just run-migrations
```
