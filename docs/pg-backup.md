# PostgreSQL Backup (pg_rman)

Online backup and point-in-time recovery for the shared PostgreSQL instance. Configured in `home/postgresql.nix` using [pg_rman](https://github.com/ossc-db/pg_rman) (custom derivation in `derivations/pg_rman.nix`).

## Prerequisites

WAL archiving is enabled automatically in `postgresql.conf` by the home-manager activation script:

- `wal_level = replica`
- `archive_mode = on`
- `archive_command = 'cp %p ~/.local/share/postgresql/archivelog/%f'`

After first enabling, PostgreSQL must be restarted for these settings to take effect.

## Commands

### `pg-backup [full|incremental]`

Run a backup. Defaults to `full`. Automatically initializes the backup catalog on first run, then validates the backup.

```bash
# Full backup (default)
pg-backup

# Incremental backup (requires a prior full backup)
pg-backup incremental
```

Each run also applies retention (see below), pruning the WAL archive and old
backup generations.

## Retention

`pg-backup` passes `--keep-arclog-days` and `--keep-data-generations` to
`pg_rman`, so the WAL archive and the backup catalog prune themselves on every
run. Override per-invocation with environment variables:

| Variable | Default | Effect |
|----------|---------|--------|
| `PG_KEEP_ARCLOG_DAYS` | `7` | Discard archived WAL older than N days |
| `PG_KEEP_DATA_GENERATIONS` | `3` | Keep N generations of full data backup |

```bash
# Keep 30 days of WAL for this run (costs ~31GB at current write rates)
PG_KEEP_ARCLOG_DAYS=30 pg-backup
```

This matters more than it looks: a full backup copies the entire WAL archive
into itself. With no retention the archive grows without bound and every backup
grows with it — in Aug 2026 a backup was 32GB, of which 30GB was archived WAL
and only 922MB was actual database content.

The 7-day default is sized to this instance's write rate of roughly 1.2GB of WAL
per day. Raising it trades disk for a longer point-in-time recovery window;
measure before picking a bigger number.

### `pg-backup-show`

List all backups in the catalog.

```bash
pg-backup-show
```

### `pg-backup-purge [days]`

Delete backups older than N days (defaults to 7).

```bash
# Delete backups older than 7 days
pg-backup-purge

# Delete backups older than 30 days
pg-backup-purge 30
```

## Paths

| Path | Description |
|------|-------------|
| `~/.local/share/postgresql/backups` | Backup catalog |
| `~/.local/share/postgresql/archivelog` | WAL archive |
| `~/.local/share/postgresql/data` | PostgreSQL data directory |

## Troubleshooting

### Reset backup catalog

If the catalog gets corrupted or you want to start fresh:

```bash
rm -rf ~/.local/share/postgresql/backups/*
pg-backup full
```

### PostgreSQL not starting after enabling archiving

Restart the launchd agent after a `darwin-rebuild switch`:

```bash
launchctl kickstart -k gui/$(id -u)/com.shinzui.postgresql
```
