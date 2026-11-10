# PostgreSQL Backup (pg_rman)

Online backup and point-in-time recovery for the shared PostgreSQL instance. Configured in `home/postgresql.nix` using [pg_rman](https://github.com/ossc-db/pg_rman) (custom derivation in `derivations/pg_rman.nix`).

## Prerequisites

WAL archiving is enabled automatically in `postgresql.conf` by the home-manager activation script:

- `wal_level = replica`
- `archive_mode = on`
- `archive_command = 'cp %p ~/.local/share/postgresql/archivelog/%f'`

After first enabling, PostgreSQL must be restarted for these settings to take effect.

## Backup ownership

Exactly one host owns scheduled backups, chosen by
`services.postgresql.backups.enable` (default `false`). During the Rei/Mori
host move, `home/rei-mori-cutover.nix` sets it from the shared cutover phase:
Sungkyung owns backups in `preparation`, neither host does in `stopped`, and
Yujin does in `validation` and `active`. The owner runs two agents:

- `com.shinzui.pg-backup`, daily at 03:00, runs `pg-backup-scheduled`. It takes
  a full backup when `~/.local/state/postgresql/last-full-backup` is missing or
  older than 6.5 days and an incremental otherwise, then runs
  `pg-backup-offsite-sync`.
- `com.shinzui.pg-backup-offsite-sync` runs the offsite sync on every volume
  mount, so a backup taken while the drive was unplugged is copied when it is
  attached again.

On every other host `pg-backup`, `pg-backup-offsite-sync`, and
`pg-backup-purge` refuse to run. Every `pg-backup` run applies retention, so a
stray run on a host whose chain has been frozen would age that chain out. For
one deliberate, recorded run, such as Sungkyung's final full backup during the
move, set the override:

```bash
PG_BACKUP_ALLOW_INACTIVE=1 pg-backup full
```

Check the declared owner with
`python3 bin/check-rei-mori-owner.py --expect <host> --expect-backups <host|none>`.

A pg_rman catalog is a byte-level copy of one specific cluster. It cannot
recover a different cluster, so a host that takes over backups starts its own
chain with a full backup. Never copy one host's catalog onto another.

## Offsite mirror

`pg-backup-offsite-sync` mirrors the catalog to
`services.postgresql.backups.offsiteDirectory` on the external drive
`/Volumes/aki-2023` with `rsync --delete`, which replaces whatever the
destination holds. Each cluster therefore has its own sibling directory, never
one nested inside another's:

| Host | Mirror |
|------|--------|
| Sungkyung | `/Volumes/aki-2023/postgresql-backups` |
| Yujin | `/Volumes/aki-2023/postgresql-backups-yujin` |

Before each sync, `bin/pg-offsite-guard.py` compares the cluster's system
identifier (from `pg_controldata`) with the destination's
`.postgresql-cluster-id` marker. It creates the marker in a missing or empty
destination, passes when the marker matches, and refuses when the marker
differs or when a non-empty destination has none. rsync excludes the marker so
`--delete` keeps it.

A mirror written before the guard existed has no marker, so the sync refuses
until it is adopted. Adopt only after verifying that the mirror holds this
cluster's chain, for example with a checksum dry run:

```bash
rsync -anc --delete ~/.local/share/postgresql/backups/ /Volumes/aki-2023/postgresql-backups/ \
  | grep -v '^\./$' | wc -l      # expect 0
pg-backup-offsite-adopt --verified
```

The sync exits 0 when the drive is not mounted ("not mounted; skipping offsite
sync"), so check its log and the mirror's newest backup rather than the exit
status.

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

### `pg18 <tool> [arguments...]`

Run a tool from the server's own PostgreSQL 18 build. The `psql`, `pg_dump`,
and `initdb` on PATH are an older major version: `pg_dump` refuses a newer
server and an older `initdb` builds a cluster this server cannot open. Use
`pg18 pg_dump`, `pg18 pg_restore`, `pg18 initdb`, and `pg18 pg_ctl` for exports,
restores, and scratch clusters.

## Paths

| Path | Description |
|------|-------------|
| `~/.local/share/postgresql/backups` | Backup catalog |
| `~/.local/share/postgresql/archivelog` | WAL archive |
| `~/.local/share/postgresql/data` | PostgreSQL data directory |

## Troubleshooting

### Reset backup catalog

If the catalog gets corrupted or you want to start fresh, and only on the host
that owns backups. Never do this to a chain that has been frozen as a rollback
copy, such as Sungkyung's after the Rei/Mori move:

```bash
rm -rf ~/.local/share/postgresql/backups/*
pg-backup full
```

### PostgreSQL not starting after enabling archiving

Restart the launchd agent after a `darwin-rebuild switch`:

```bash
launchctl kickstart -k gui/$(id -u)/com.shinzui.postgresql
```
