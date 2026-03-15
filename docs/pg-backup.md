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
