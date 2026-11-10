# Moving the Rei/Mori runtime from Sungkyung to Yujin

Operator runbook for
[ExecPlan 8](plans/8-move-the-primary-rei-and-mori-runtime-from-sungkyung-to-yujin.md),
which moves every PostgreSQL-backed service, PostgreSQL's scheduled backups,
and the shared support services from Sungkyung to Yujin. The plan explains
why each step exists and lists the data-safety invariants. This page lists the
commands. If a step seems to need breaking an invariant, stop and ask.

Keep database contents, role exports, and detailed evidence out of Git, in
mode-0700 directories. Record only status, counts, timings, and redacted
discrepancies in the plan.

## The cutover phase

One value in [hosts/rei-mori-cutover-phase.nix](../hosts/rei-mori-cutover-phase.nix)
decides each host's runtime, backup, support-service, and client settings.
[home/rei-mori-cutover.nix](../home/rei-mori-cutover.nix) maps it:

| Phase | Sungkyung (source) | Yujin (destination) |
| --- | --- | --- |
| `preparation` | runtime owner, backups, support services | client of Sungkyung: tunnel, Git ingest, remote `rei` |
| `stopped` | nothing | support services only |
| `validation` | client of Yujin, with web and support forwards | owner at stage validation (mori-serve, rei-api, mina-web, reiko-web only), backups, support services |
| `active` | as in validation | owner at stage active, backups, support services |

A phase change in Git changes nothing until a machine is built and switched,
and each machine takes the phase it was switched with. Before every switch,
check the phase you are about to deploy:

```bash
cd /Users/shinzui/.config/dotfiles.nix
python3 bin/check-rei-mori-owner.py --all-phases     # every phase's placement
python3 bin/check-rei-mori-owner.py --expect SungkyungM1X --expect-backups SungkyungM1X --expect-support both
python3 bin/check-rei-mori-owner.py --phase stopped --expect none --expect-backups none --expect-support yujin
python3 bin/check-rei-mori-owner.py --phase validation --expect yujin --expect-backups yujin --expect-support yujin
```

The checker evaluates declarations only. It cannot see a stale generation or a
manually started process, so every stage below also verifies the live machine.

To switch a machine, build into `./result` on that machine and activate it:

```bash
./bin/build.sh <SungkyungM1X|yujin>
sudo ./bin/darwin-rebuild.sh <SungkyungM1X|yujin>
```

## Tools

- `bin/rei-mori-migration.py` collects and verifies evidence and never writes
  to a database: its sessions run with `default_transaction_read_only=on`.
  `inventory` and `fingerprint` need an explicit `--socket` and `--role`, and
  write to an `--out` file that must not exist, inside a mode-0700 directory.
  Pass `--expect-system-identifier` (or `--expect-data-directory`) so the wrong
  socket is refused rather than measured. `compare` exits 1 on any difference,
  `conflicts` exits 1 if a database already exists, `manifest` seals a bundle,
  and `verify-bundle` exits 4 for an unsealed or interrupted bundle.
- `pg18 <tool>` runs the server's own PostgreSQL 18 tools. Use it for every
  export, restore, and scratch cluster; bare `pg_dump` on PATH is version 17.
- `bin/pg-offsite-guard.py` (through `pg-backup-offsite-sync` and
  `pg-backup-offsite-adopt`) keeps one cluster per offsite mirror. See
  [pg-backup.md](pg-backup.md#offsite-mirror).

Every test runs from the repository root:

```bash
python3 bin/test-rei-mori-owner.py
python3 bin/test-rei-mori-migration.py      # PostgreSQL cases need pg18 on PATH or PG18_BIN
python3 bin/test-rei-ssh-dispatch.py
python3 bin/test-pg-offsite-guard.py
```

## Private evidence directory

On each machine:

```bash
umask 077
export EVIDENCE="$HOME/.local/state/rei-mori-move-evidence"
mkdir -p -m 700 "$EVIDENCE"
export PROD_SOCKET="$HOME/.local/state/postgresql"
pg18 pg_controldata -D "$HOME/.local/share/postgresql/data" | grep 'system identifier'
```

Record each machine's system identifier privately. Sungkyung's and Yujin's
differ, which is what lets the helper refuse a wrong socket.

## Preparation (milestones 1 and 2)

Inventory each cluster:

```bash
python3 bin/rei-mori-migration.py inventory --socket "$PROD_SOCKET" --role source \
  --expect-system-identifier <this machine's identifier> \
  --out "$EVIDENCE/inventory-$(hostname -s)-$(date +%Y%m%dT%H%M%S).json"
```

Take the inventory on Sungkyung twice, at least a day apart, and compare each
retained-not-migrated database's `xact_commit` and `xact_rollback`. A rising
count means something uses it, which blocks the freeze until the user decides.

After deploying the preparation revision to Sungkyung, adopt its existing
offsite mirror, which milestone 1 verified by checksum. Until then its sync
refuses:

```bash
pg-backup-offsite-adopt --verified          # with aki-2023 attached to Sungkyung
```

Yujin's backup agents are absent from the preparation revision. Confirm after
its switch:

```bash
launchctl list | grep -E 'pg-backup' || echo 'no pg-backup agents loaded'
```

### Sungkyung-to-Yujin keys

Create the client keys on Sungkyung and enroll only their public halves on
Yujin. Never copy private keys between machines.

```bash
# On Sungkyung
ssh-keygen -t ed25519 -N '' -C sungkyung-yujin-client -f ~/.ssh/id_ed25519_yujin_client
ssh-keygen -t ed25519 -N '' -C sungkyung-yujin-rei -f ~/.ssh/id_ed25519_yujin_rei
ssh-keygen -F 100.105.45.104 || echo 'verify Yujin host key over a trusted channel first'
```

On Yujin, append to `~/.ssh/authorized_keys`, substituting the public keys and
Sungkyung's verified tailnet address:

```text
from="100.66.155.64",restrict,port-forwarding,permitopen="127.0.0.1:8780",permitopen="127.0.0.1:8775",permitopen="127.0.0.1:9091",permitopen="127.0.0.1:80",permitopen="127.0.0.1:9428",permitopen="127.0.0.1:10428",permitopen="127.0.0.1:16686",permitopen="127.0.0.1:8080",permitopen="127.0.0.1:8081",permitopen="127.0.0.1:8082",permitopen="127.0.0.1:9092",permitopen="127.0.0.1:9644",command="/usr/bin/false" ssh-ed25519 <tunnel key> sungkyung-yujin-client
from="100.66.155.64",restrict,pty,command="/Users/shinzui/.local/libexec/rei-ssh-dispatch" ssh-ed25519 <rei key> sungkyung-yujin-rei
```

`permitopen` limits TCP forwards only. It does not constrain Unix socket
forwards, so the tunnel key can reach any socket the shinzui user can, which
includes PostgreSQL with trust authentication. Treat the key as same-user
database access. `~/.local/libexec/rei-ssh-dispatch` refuses until the host is
the runtime owner, and then runs the owner's managed Rei by absolute path.

## Rehearsal on Yujin (milestone 3)

Use a scratch cluster with its own directory and socket, TCP off:

```bash
umask 077
export REHEARSAL_ROOT="$HOME/.local/state/rei-mori-rehearsal-<tag>"
mkdir -m 700 "$REHEARSAL_ROOT" "$REHEARSAL_ROOT/socket"
pg18 initdb --auth=trust --no-locale --encoding=UTF8 -D "$REHEARSAL_ROOT/data"
pg18 pg_ctl -D "$REHEARSAL_ROOT/data" -l "$REHEARSAL_ROOT/server.log" \
  -o "-k $REHEARSAL_ROOT/socket -c listen_addresses='' -c archive_mode=off" -w start
python3 bin/rei-mori-migration.py conflicts --socket "$REHEARSAL_ROOT/socket" --role rehearsal \
  --expect-data-directory "$REHEARSAL_ROOT/data" rei mori mori_rei_app notion_hub
```

The globals export holds two roles. shinzui already exists as each cluster's
bootstrap superuser, so reviewed-globals.sql creates only message_store:

```sql
CREATE ROLE message_store;
ALTER ROLE message_store WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
```

Restore with the commands in the plan's Concrete Steps, then fingerprint the
restore and a second restore of the same archives, and compare them:

```bash
python3 bin/rei-mori-migration.py fingerprint --socket "$REHEARSAL_ROOT/socket" --role rehearsal \
  --expect-data-directory "$REHEARSAL_ROOT/data" --label restore-1 \
  --out "$EVIDENCE/rehearsal-restore-1.json" rei mori mori_rei_app notion_hub
python3 bin/rei-mori-migration.py compare "$EVIDENCE/rehearsal-restore-1.json" "$EVIDENCE/rehearsal-restore-2.json"
```

The 2026-11-10 rehearsal measured about 20 s to export, 15 s to transfer, 17 s
to restore, and 10 to 20 s to fingerprint each side, so the data path takes a
few minutes. Freezing writers, the checks, and the per-service proofs set the
length of the window.

For the pg_rman proof, run `pg_rman validate` on the catalog and then
`pg_rman restore --hard-copy` into an empty directory. `--check` cannot be
used there: it reads `pg_control` in the target and fails on an empty one.

## Maintenance window (milestones 4 to 8)

The window starts only after the user has agreed to it in the session.

1. Freeze writers as the plan's milestone 4 lists. On Sungkyung run
   `redpanda-down`, set the phase to `stopped`, and switch Sungkyung, then
   Yujin (which drops its old tunnel and ingest). Verify on Sungkyung that no
   runtime, support, or backup label is loaded and nothing listens on 80,
   9428, 10428, 16686, 8080, 8081, 8082, 9092, or 9644.
2. Fingerprint the four databases and Mina's store before and after the
   export, into the bundle:

   ```bash
   python3 bin/rei-mori-migration.py fingerprint --socket "$PROD_SOCKET" --role source \
     --expect-system-identifier <Sungkyung's identifier> --label before \
     --out "$MIGRATION_ROOT/fingerprint-before.json" rei mori mori_rei_app notion_hub
   python3 bin/rei-mori-migration.py sqlite --db "$MIGRATION_ROOT/mina.db" --role backup \
     --out "$MIGRATION_ROOT/mina-backup.json"
   python3 bin/rei-mori-migration.py compare "$MIGRATION_ROOT/fingerprint-before.json" \
     "$MIGRATION_ROOT/fingerprint-after.json"
   python3 bin/rei-mori-migration.py manifest --root "$MIGRATION_ROOT" --label final
   python3 bin/rei-mori-migration.py verify-bundle --root "$MIGRATION_ROOT"
   ```

   Take Sungkyung's final physical backup with `PG_BACKUP_ALLOW_INACTIVE=1
   pg-backup full`, then fence the source databases and Mina's store as the
   plan describes.
3. On Yujin, verify each transferred bundle copy with `verify-bundle`, check
   `conflicts` against the production socket, restore, and compare the
   restored fingerprint with the source's `fingerprint-after.json`, passing
   `--ignore-allow-connections` only for the fence setting.
4. Set the phase to `validation` and switch Yujin only. Move Yujin's own
   backups as milestone 6 describes, then switch Sungkyung to the same phase,
   which starts its outgoing tunnels.
5. Set the phase to `active` and switch Yujin, with ingress still paused.
   Prove each service as milestone 8 describes, then reopen ingress.

## Rollback

Before Yujin takes any write: stop Yujin's runtime, restore Sungkyung's
`ALLOW_CONNECTIONS` settings and Mina file modes, set the phase back to
`preparation`, and switch Sungkyung, then Yujin. Sungkyung's frozen catalog,
WAL archive, and old mirror are untouched, so its backups resume against its
own chain. After Yujin has taken writes, follow the plan's Idempotence and
Recovery section instead; a phase change alone does not move data back.
