# Mori

Project identity & automation system. Configured in `home/mori.nix`.

## Architecture

Two launchd agents run as background services:

- **mori-postgres** — dedicated PostgreSQL instance at `~/.mori/db` (unix socket, no TCP)
- **mori-automate** — runs `mori automate daemon`, which starts all event subscriptions and the scheduled action worker

The automate daemon handles all read model projections via subscriptions. CLI commands (`mori register`, `mori registry list`, etc.) write events to the event store and query the read model — they never do inline projection.

## Services

Both services start on login (`RunAtLoad`) and restart on crash (`KeepAlive`). On `darwin-rebuild switch`, plists are regenerated with updated store paths and launchd reloads them automatically.

### Status

```bash
launchctl list | grep mori
```

### Restart

```bash
# Restart automate daemon
launchctl kickstart -k gui/$(id -u)/com.shinzui.mori-automate

# Restart postgres
launchctl kickstart -k gui/$(id -u)/com.shinzui.mori-postgres
```

## Logs

All logs are in `~/.mori/logs/`:

```bash
# Subscription & automation logs
tail -f ~/.mori/logs/automate.stderr.log

# PostgreSQL logs
tail -f ~/.mori/logs/postgres.stderr.log
```

## Database

PostgreSQL data lives at `~/.mori/data`, connects via unix socket at `~/.mori/db`.

Connection string is set automatically via `MORI_PG_CONNECTION_STRING` in the shell environment.

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
