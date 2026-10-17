---
id: 8
slug: move-the-primary-rei-and-mori-runtime-from-sungkyung-to-yujin
title: "Move the primary Rei and Mori runtime from Sungkyung to Yujin"
kind: exec-plan
created_at: 2026-10-17T03:57:38Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-17T03:57:38Z
---

# Move the primary Rei and Mori runtime from Sungkyung to Yujin

This ExecPlan is a living document. Keep Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective current during implementation. Creating this plan does not execute the migration.


## Purpose / Big Picture


Make Yujin the authoritative workstation for Rei, Mori, Reiko, Mina, and Caddy. Existing intentions, notes, event history, automation progress, webhook delivery records, Mina tracking/Obeya data, and Reiko archives must survive. On Yujin the tools and browser names work locally. Sungkyung becomes a client: it opens the SSH connection to Yujin and accesses Yujin's services through private local forwards.

Success means existing records survive a verified restore, a controlled new write is visible from both machines, workers resume from preserved positions, and Sungkyung cannot write its old production databases. Schedule a maintenance window after a timed rehearsal; measure the duration rather than promising zero downtime. Preserve original data and independent backups throughout.


## Progress


- [ ] Inventory both physical machines, versions, databases, workspace files, repositories, ingress, and pending work.
- [ ] Implement and verify staged ownership, Caddy ownership, reverse client configuration, and evidence tooling without moving the active runtime.
- [ ] Rehearse PostgreSQL/SQLite restoration on Yujin in isolation; record timing and recovery proof.
- [ ] Freeze writes, stop and verify Sungkyung, create final exports, and fence its old databases.
- [ ] Restore and compare final data on Yujin; establish its own Mori identity and repository locations.
- [ ] Validate Yujin, reverse Sungkyung's client connection, and resume workers and ingress.
- [ ] Prove restart persistence, establish independent Yujin backups, and update runbooks/ADRs.


## Surprises & Discoveries


(None recorded during implementation yet. Research findings and unresolved live checks are described below.)


## Decision Log


2026-10-16: Move the complete existing runtime group, including its webhook bridge and Notion Hub subscription. The configured databases rei, mori, mori_rei_app, and notion_hub move together because integration state affects correctness. Discover any additional production store or alternate connection before freezing the inventory.

2026-10-16: Use complete PostgreSQL logical exports and SQLite's backup API, followed by restoration and comparison. Preserve source data and destination conflicts. Do not copy a live PostgreSQL data directory, reconstruct stores through replay, reset checkpoints, or combine this host move with application/schema upgrades.

2026-10-16: Add an owner validation stage before enabling background workers. Both hosts are disabled during final export/import. Yujin's APIs/UI then start without automations or healing, allowing path and browser verification before side effects resume.

2026-10-16: Move Caddy to Yujin and forward Sungkyung's loopback port 80 to Yujin's loopback port 80, preserving names such as mina.localhost. Preserve Mori/Rei route restrictions.

2026-10-16: Preserve Yujin's distinct SSH, Tailscale, and Mori identities. Repository registration can add Yujin's locations; copying Sungkyung's host-id is forbidden. Keep the selected existing application versions and lockfile during migration.


## Outcomes & Retrospective


(To be filled during implementation. No service has been stopped, database exported/imported, tunnel changed, or host activated by authoring this plan.)


## Context and Orientation


The repository root is /Users/shinzui/.config/dotfiles.nix on both machines. Full Nix configuration names are SungkyungM1X and yujin; computer names are sungkyung and yujin. A Nix build produces an installable generation; a switch activates it and can start services immediately. Run launchctl as the logged-in shinzui user in that machine's gui domain, not under sudo. Only the nix-darwin switch needs sudo. These user agents need a GUI login.

hosts/sungkyung/home.nix currently sets workstation.reiMori.enable = true. hosts/yujin/home.nix sets it false and adds sungkyung-client-tunnel plus a high-priority remote rei executable. That tunnel connects to Sungkyung at 100.66.155.64, using separate SSH keys for forwarding and Rei execution. It forwards a private PostgreSQL Unix socket, Mori 8780 to local 18780, and worker metrics 9091 to local 19091. Discover Yujin's actual tailnet address; do not reuse the source address.

home/rei-mori-runtime.nix disables mori-automate, mori-serve, mori-rei-app, rei-api, rei-worker, rei-worker-kiroku, rei-subscription, rei-worker-git-sync, rei-watchdog, notion-hub-subscription, mina-web, and reiko-web on inactive hosts. The legacy rei-subscription and rei-worker-git-sync are deliberately disabled even on the owner; keep them disabled. home/rei-doctor.nix prevents inactive-host healing. bin/check-rei-mori-owner.py checks declarations, not running generations or manual processes. bin/test-rei-mori-owner.py tests this guard.

home/postgresql.nix configures PostgreSQL 18, files at ~/.local/share/postgresql/data, and a socket at ~/.local/state/postgresql/.s.PGSQL.5432. TCP listening is disabled. Local authentication is trust, so socket forwarding conveys substantial database authority; keep the client socket inside an owned mode-0700 directory. General PostgreSQL and backup agents are independent of runtime ownership. Physical pg_rman backups are under ~/.local/share/postgresql/backups; WAL archives, PostgreSQL's write-ahead recovery records, are under ~/.local/share/postgresql/archivelog. The scheduled mirror /Volumes/aki-2023/postgresql-backups uses rsync --delete: two independent clusters must never share it.

home/rei.nix uses rei; home/mori.nix uses mori; home/mori-rei-app.nix uses mori_rei_app and also writes Rei; home/notion-hub.nix uses notion_hub. The bridge's database remembers processed webhook deliveries to prevent duplicates. Export entire databases, including events, projections (tables derived from events), subscription progress, queues, timers, migration ledgers, delivery ledgers, and permissions. Pending queue entries are data. Matching only event counts or maximum positions is insufficient.

config/xdg/rei/config.yaml points to /Users/shinzui/Keikaku/rei-workspace/. Transfer the actual workspace, attachments, Git history, and untracked/ignored durable files. A fresh clone lacks local commits, refs, and uncommitted work. Linked Git worktrees depend on a common Git directory; preserve those relationships for automation repositories. Inventory effective configuration rather than assuming every path uses its default.

home/mina.nix runs Mina at 127.0.0.1:8765; home/reiko.nix runs Reiko at 127.0.0.1:8770. Both spawn Rei; Mina also spawns Mori. Their launch-agent environments and PATH must work independently of interactive shells. Current Mina source stores tracking and Obeya data in ~/.local/share/mina/mina.db, subject to XDG_DATA_HOME and MINA_TRACKING_DB overrides. It uses SQLite WAL mode: committed data may still be in a journal beside the database, so copying mina.db alone can lose data. Include effective Mina global/project configuration and durable .mina contents. Current Reiko source keeps archive sidecars and state under ~/.local/share/reiko, subject to XDG_DATA_HOME and reikoDataDir in ~/.config/reiko/config.yaml. Verify these defaults against the deployed binaries.

home/local-web-proxy.nix runs Caddy as com.shinzui.local-web-proxy on port 80, currently independently enabled on both machines. It proxies named local tools. Mori 8780 and Rei API 8775 additionally require a loopback peer; these routes must remain private. Caddy's other routes reach Yujin's local logs/traces/Jaeger/Redpanda and development servers. Historical telemetry and Redpanda data are outside this application migration; verify needed Yujin upstreams and record unavailable optional routes.

Relevant local ADRs are [shared host composition](../adr/1-shared-workstation-modules-and-host-overrides.md) and [private bootstrap/identity](../adr/2-selective-private-workstation-bootstrap.md). They require shared modules with explicit host differences, distinct machine identities, and independent proof of physical readiness. No existing ADR specifies database transfer. Follow [ownership guidance](../rei-mori-cutover.md), [bootstrap prerequisites](../new-machine-bootstrap.md), and [backup configuration](../pg-backup.md) until implementation updates them. The local Mori manifest declares no profiled ADR bundle; preserve the plain Markdown ADR convention.

Dependency discovery used the Mori registry for mori://shinzui/rei, mori://shinzui/mori, mori://shinzui/mina, and mori://shinzui/reiko. Canonical guides are mori://shinzui/mori/docs/user-guide, mori://shinzui/mori/docs/cli-spec, and mori://shinzui/rei/docs/cli-reference. Source evidence additionally comes from mori://shinzui/mina with project-relative mina-core/src/Mina/Tracking/Store.hs and mina-core/src/Mina/Obeya/Store.hs; mori://shinzui/reiko with reiko-core/src/Reiko/Config.hs; and mori://shinzui/mori with mori-cli/src/Mori/Command/Register.hs and mori-core/src/Mori/Host/Identity.hs (artifact-level URIs pending). The latter confirms mori register --path DIR uses the local machine's identity. Verify deployed commands/schemas: local corpus code can differ from installed versions.

Full database archives and separate globals exports were checked against official [pg_dump](https://www.postgresql.org/docs/18/app-pgdump.html), [pg_dumpall](https://www.postgresql.org/docs/18/app-pg-dumpall.html), and [pg_restore](https://www.postgresql.org/docs/18/app-pgrestore.html) references. SQLite's [backup API](https://www.sqlite.org/backup.html) provides the database snapshot, followed by [integrity/foreign-key checks](https://www.sqlite.org/pragma.html). Required operational instructions are embedded below.


## Plan of Work


### Milestone 1: Inventory the real state and implement evidence collection


Create docs/rei-mori-yujin-migration.md as the operator runbook and bin/rei-mori-migration.py as an evidence helper. Keep database contents, credentials, private inventories, and detailed evidence outside Git in mode-0700 directories. Public evidence contains only status, counts, timings, and redacted discrepancies. Do not print token environments, secret SQL rows, or credential-bearing process arguments.

On both physical Macs record hostname, architecture/login, active dotfiles revision/generation, lockfile digest, installed application versions, server/client PostgreSQL versions, socket/data directory, locales, extension versions, free disk space, and actual state paths. Preserve existing user edits, including flake.lock. Align the chosen deployed application/schema versions before the window without implicit upgrades. If new dependency bounds or compatibility work are needed, use Mori to locate source and verify released versions with authoritative registries and upstream tags first.

The helper must inventory all non-template databases, their owners/settings/encoding/locales, roles/memberships, tablespaces, extensions, migration ledgers, large objects, tables/partitions, sequences, and prepared transactions. Identify logical replication, database schedulers, and other writers that can continue without launchd. Any unclassified production store or autonomous writer blocks final export. The four configured databases are the minimum scope, not permission to ignore additional discovered coupled state.

For every selected database collect exact row counts and deterministic content digests of all non-system data, sequence last_value/is_called, schemas, large-object contents, and relevant metadata. One concrete digest method is COPY of canonical JSON rows ordered by their JSON representation, streamed through SHA-256 with fixed timezone/format settings and the same PostgreSQL build. Handle duplicates, bytea, empty tables, and partitions without double-counting. Quote identifiers with PostgreSQL format('%I', ...) and \gexec or an equivalent safe facility; never concatenate unchecked identifiers. Report unsupported objects and extension-owned tables omitted by pg_dump. Supply an owning export or demonstrate reconstructability for such state before proceeding.

Discover actual queue/checkpoint schemas from database catalogs and the deployed owning source. Preserve event IDs and stream membership/versions, durable subscription positions, failed deliveries, queues, leases, timers, outbox/inbox, webhook ledger, and migration history. Before startup these must compare exactly; afterward positions may advance. Inventory in-flight external work: let it finish safely or establish its durable retry/deduplication semantics. An external action with uncertain acknowledgement is a blocker until reconciled.

Inventory the Rei workspace, repository/worktree dependencies, local branches/changes, Mina SQLite overrides/configuration, Reiko state, source/destination path conflicts, secrets readability, and every ingress/automation/webhook route. Determine how to pause and resume each producer. Verify Yujin's tailnet address and SSH host fingerprints over a trusted channel; re-enroll renewable credentials using the bootstrap runbook. Never copy machine identity keys.

Inspect both machines' backup schedules and mounted external volumes immediately. Because the existing offsite path is shared by default, pause Yujin's offsite agent during implementation before it can touch a source catalog. If that destination was already used by both clusters, preserve it and establish which recovery chain remains valid before relying on it. Record its state and do not let another mirror run until distinct destinations are configured.

Acceptance: a complete private transfer manifest, no unclassified store, sufficient measured disk capacity, exact source/destination versions, and a list of writers/ingress/pending effects exist. The evidence helper detects a changed row with unchanged counts, sequence/checkpoint drift, and the wrong socket. Do not create an empty production store as an inventory fix.


### Milestone 2: Prepare staged ownership and reverse client configuration


Extend home/rei-mori-runtime.nix with workstation.reiMori.stage = "validation" | "active", default active. enable = false forces every owned agent off. On the enabled owner, validation permits only mori-serve, rei-api, mina-web, reiko-web, and local-web-proxy. It forces all automations, workers, integrations, and healing off. Active preserves each module's existing enable value; never turn the two legacy workers back on. Add local-web-proxy to the owned agent list so Caddy moves too. In home/rei-doctor.nix allow --heal and watchdog self-bootstrap only when enabled and active; stop the watchdog before other shutdown hooks.

Extend bin/check-rei-mori-owner.py and bin/test-rei-mori-owner.py to validate stage, Caddy, and client tunnel placement. Reject dual owners, workers/healing during validation, runtime/Caddy on an inactive host, a client tunnel on the owner, and a tunnel pointing to its own machine. Preserve --expect none for the stopped interval. Add tests for these hazards.

Extract hosts/yujin/home.nix's client logic into home/rei-mori-client.nix, imported by home/default.nix. Give it explicit enable, target, tunnelIdentityFile, reiIdentityFile, stateDirectory, and forwardWebPort options. Reuse JSON/base64 argv encoding from bin/rei-ssh-dispatch.py; remove source-only wording and install the dispatcher at a stable managed path on the destination. The forced command must use Yujin's local managed Rei/environment and never resolve to another remote wrapper. Preserve argument boundaries, exit status, and interactive terminal behavior; reject malformed/non-string/NUL arguments without evaluating shell text.

Create dedicated Sungkyung-to-Yujin tunnel and Rei keys on Sungkyung and enroll only their public halves on Yujin. Review actual macOS authorized_keys/sshd policy; do not copy private keys. Disable agent/X11 forwarding, use verified known_hosts, BatchMode, StrictHostKeyChecking, IdentitiesOnly, ExitOnForwardFailure, and liveness probes. Preserve TTY permission only where needed for interactive Rei. TCP permitopen restrictions do not constrain arbitrary Unix socket paths; document this trusted same-user database access accurately. Verify available options against actual macOS SSH and the official [client](https://man.openbsd.org/ssh.1) and [server](https://man.openbsd.org/sshd.8) manuals.

Sungkyung's final tunnel forwards ~/.local/state/yujin-clients/postgresql/.s.PGSQL.5432 to Yujin's PostgreSQL socket. Forward local 18780 to destination 8780, 18775 to 8775, and 19091 to 9091, bound only to 127.0.0.1. Forward both 127.0.0.1:80 and [::1]:80 to Yujin 127.0.0.1:80; preflight both bind addresses after stopping source Caddy. Keep PostgreSQL off TCP and all new forward listeners off non-loopback interfaces. Ensure socket directories are owned and mode 0700.

Sungkyung's final shell sets MORI_PG_CONNECTION_STRING and REI_PG_CONNECTION_STRING to the forwarded private socket with user=shinzui connect_timeout=5, MORI_API_URL to http://127.0.0.1:18780, and KIROKU_REMOTE_URL to http://127.0.0.1:19091. Other client endpoint overrides require discovering supported variables first. Yujin loses its old forward agent, high-priority remote Rei package, and remote mkForce environment overrides; it returns to shared local settings. Use fresh shells after switching.

Do not access live SQLite across a network filesystem. Sungkyung's browser reaches Yujin's Mina database through the tunnel; mutable Mina/Reiko CLI operations run in an SSH shell on Yujin in the relevant repository. Document this explicitly so retained source SQLite/files are not used as a second active store.

Deliver preparation changes with Sungkyung still active and Yujin inactive, keeping the existing client direction until the maintenance window. Prepare reviewed stopped, Yujin-validation, and Yujin-active revisions without activating later stages. Reverse forwarding remains off until final restore passes. Test argv encoding with harmless fake executables and shell metacharacters. Build both physical host targets without switching ownership. Acceptance: preparation still declares Sungkyung sole owner; evaluation of validation permits exactly the five web/API agents; tests reject premature workers; both builds pass. Inspect generated configuration through Nix values, never by traversing /nix/store.

In this preparation revision, parameterize the offsite destination in home/postgresql.nix and set Yujin's override to /Volumes/aki-2023/postgresql-backups/yujin. Preserve Sungkyung's existing path and catalog. Install this isolation before any Yujin activation or resumption of backup jobs; backup agents are independent of the runtime flag. Test the selected paths without running a destructive mirror.


### Milestone 3: Rehearse restoration in isolation


Take online rehearsal PostgreSQL exports and a Mina SQLite API backup. Label these REHEARSAL: snapshots of separate databases while writers run are not the final application-consistent bundle. On Yujin restore into a fresh private PostgreSQL cluster with its own directory/socket, TCP listening disabled, canonical database names, no workers, and no external ingress. Keep its normal production runtime disabled.

Review globals.sql privately and prepare reviewed-globals.sql with the required roles, memberships/settings, and valid tablespace paths. Compare existing bootstrap roles such as shinzui; do not apply an unfiltered globals file to an existing cluster or ignore all duplicate-role errors. Resolve conflicts explicitly without altering unrelated destination roles. Check extension libraries exist in the configured destination package and restore any special extension state using the owning procedure. Do not update an extension opportunistically.

Restore each archive with --create --exit-on-error, preserving owners, permissions, and database-level settings. Fingerprint the restored contents and compare them with a second isolated restore of the same archive. Source fingerprints taken while production is live are informative, not an exact snapshot reference; exact source-to-restored comparison is required during the final write freeze. Restore Mina into a separate SQLite file, run integrity_check and foreign_key_check, and compare schema/data. Stage workspace/repository/Reiko/Mina files privately and verify hashes, modes, symlinks, Git state, and worktree dependencies. Time export, transfer, import, and comparison to set the maintenance budget.

Never run production daemons or replay/reset commands against a rehearsal copy. Any CLI/API check that can migrate or write runs only in an isolated clone after inspecting its behavior and preventing external effects. Demonstrate a failed import remains isolated and can be retried into another empty target. Acceptance: all four databases restore with zero errors, repeat-restore fingerprints and SQLite checks pass, files/Git state survive, and the time/space budget fits. Archive listings and transport checksums alone are insufficient.


### Milestone 4: Freeze writes, stop Sungkyung, and produce final exports


Notify the user in the current session that the maintenance window is beginning. Pause external webhook producers/routing and schedulers, close writer terminals/UIs on both machines, stop Yujin's old tunnel, and block other known clients. Record each pause/resume action and pending-delivery handling. Pause backup/offsite jobs where necessary to prevent mutable catalogs and mirror races, preserving their previous state.

Wait for in-flight work to reach the safe points recorded in milestone 1. Switch Sungkyung to the reviewed both-off revision with all client tunnels off. Complete its Mori directory conversion in docs/new-machine-bootstrap.md before switching if needed. Verify watchdog shutdown first, every owned label including Caddy unloaded, processes exited, and manual writers absent. Inspect pg_stat_activity and pg_prepared_xacts; investigate unexpected work rather than terminating unknown sessions.

Create the final immutable bundle: full PostgreSQL archives and globals, before/after database and filesystem fingerprints, SQLite backup, workspace/repository/state payloads, private manifest, and checksums. Require stable source contents across the entire export. If fingerprints differ, find the writer and repeat into a new bundle. Copy only manifest-selected paths; preserve modes/ownership/Git state; do not use rsync --delete against an existing home or checkout. Protect the bundle and transfer it over verified SSH. Independent storage must be encrypted at rest or hold an encrypted bundle addressed to verified recovery recipients; prove decryption without relying solely on Yujin's internal disk.

After final exports and unchanged-state comparison, connect to the source postgres maintenance database and set ALLOW_CONNECTIONS false for each migrated source database. This fence blocks fresh connections even from stale worker generations. Existing sessions are not disconnected: require zero remaining sessions and investigate survivors. Prove new connections fail. Record original settings and reversal commands. Export before fencing so destination archives do not inherit disabled connections. Unrelated source databases remain available. PostgreSQL documents the setting in [ALTER DATABASE](https://www.postgresql.org/docs/18/sql-alterdatabase.html).

Acceptance: both runtimes/clients are off, final source comparisons match, each required payload exists, source migrated databases reject connections, originals remain intact, and two independently stored complete final bundles have verified checksums. One copy must be outside both Macs' internal disks on independently protected storage. Missing or unverified recovery copies block promotion.


### Milestone 5: Restore final state and validate Yujin without workers


Keep Yujin's runtime/client disabled during import. Preserve its existing conflicting databases/files even if believed empty. Rename conflicting databases to unique *_precutover_<tag> names with no connections, disable connections to these retained copies, and do not drop or merge them. If Yujin already has independent production writes, reconcile them before continuing. Restore final roles/settings and canonical database names using the rehearsed procedure.

Compare all four PostgreSQL stores and Mina SQLite before application startup: schemas, digests, sequence states, settings/owners/permissions/extensions, events/membership, checkpoints, queues, timers, ledgers, and large objects. Do not migrate or regenerate to conceal a discrepancy. Install staged filesystem state only after comparing destination conflicts. Prefer identical absolute paths; fix source-only volume references, symlinks, and linked worktrees before workers start. Confirm workspace Git root, attachments, repository checkouts, credential readability, Mina's tracking path, and Reiko's data path.

Keep or mint Yujin's own ~/.config/mori/host-id, protect it with restrictive permissions, and compare privately that it differs from Sungkyung. Do not restore source host-id, Tailscale identity, or SSH private keys. Establish Yujin's host-local repository locations with deployed mori register --path DIR, first proving in rehearsal that it preserves project/repository identities. Registration is a controlled new write after exact restore comparison; record its deltas. Do not re-observe historical Git or reset ingest positions. Verify mori path returns existing Yujin checkouts and all automations use available paths.

Verify Sungkyung remains stopped/fenced. Enable only Yujin at stage validation and switch it. APIs, Mina, Reiko, and Caddy may start; background workers, bridge, Notion consumer, and healing remain off. Keep ingress paused and avoid mutation-capable UI actions except controlled probes. Inspect actual launch-agent environments privately: spawned Rei/Mori must use Yujin's local socket and intended binaries. A startup migration or version/schema mismatch returns to isolated repair.

Acceptance: exact offline comparisons pass before controlled binding writes; source cannot connect; Yujin identity/paths are correct; only validation agents run; APIs are ready; and known source records appear in the UI without empty-list errors.


### Milestone 6: Reverse client access, resume work, and prove durability


Switch Sungkyung to inactive-runtime/reverse-client configuration. Verify source Caddy and old forward agents are absent, and Yujin has no sungkyung-client-tunnel or remote Rei wrapper. Start Sungkyung's yujin-client-tunnel only. Verify fresh shell settings, bound listener addresses, forwarded server/database identity, API readiness, browser routes, and encoded Rei execution. Tunnel failure must fail quickly without falling back to source databases.

Open mina.localhost and reiko.localhost on both machines and inspect the same known tracking item/Obeya/collection/note. Test mori.localhost and rei.localhost readiness via both IPv4 and IPv6 loopback. A second peer's crafted Host-header request to Yujin must not bypass the private Mori/Rei route matchers. PostgreSQL must still have no TCP listener. The forwarded metrics port may be unavailable during validation; test it when the worker starts.

Create a new recovery checkpoint, then move Yujin to active while ingress remains paused. This is the external side-effect boundary: restored timers/queues/automations can execute immediately, before ingress reopens. Pending effects and webhook targets must already be reviewed. Watch subscription positions resume from saved values instead of zero. Keep legacy workers disabled. Verify bridge deduplication with a safely repeatable documented probe or isolated fixture; never blindly replay a real external effect.

Run a uniquely identified controlled Rei write using verified deployed CLI syntax. Observe it through both machines/UI and its expected worker/workspace effect once. Perform one normal Mina tracking/Obeya action and confirm it from both browsers against Yujin's single SQLite store. Validate a Reiko archive operation and sidecar. Record generated IDs privately. Reopen ingress and verify one eligible normal automation produces its expected result once; inspect attempts/deliveries for duplicates.

Before resuming Yujin offsite mirroring, verify its preparation-time host override still selects /Volumes/aki-2023/postgresql-backups/yujin and preserves Sungkyung's prior catalog. Take/validate a fresh Yujin full backup and prove restoration into a separate cluster. Back up Mina SQLite, workspace, and Reiko state separately because pg_rman does not protect those files. Verify scheduled jobs fire; a missing external disk means no offsite copy, even if a sync command exits zero.

Test tunnel recovery after stopping only its process, and login/restart persistence on both Macs. Confirm source fencing survives rebuilding/restarting and Yujin is still sole owner. Retain old data and immutable bundles at least 14 days and until scheduled backups plus recovery proof succeed. Retirement is a separate deliberate action; do not delete old copies automatically. Update docs/rei-mori-cutover.md, docs/local-services.md, docs/pg-backup.md, and bootstrap references. Add a plain Markdown ADR for staged ownership, database fencing, and isolated backup namespaces.

Acceptance: Yujin works independently as primary; Sungkyung reaches the same live records through its outgoing tunnel; controlled writes/effects occur once; reconnect/restart preserves roles; and database plus non-database recovery is proven.


## Concrete Steps


These are future implementation commands, not instructions to execute cutover while authoring this plan. Replace <...> placeholders using milestone-1 discoveries before the maintenance window. Every command using a socket must explicitly select the intended machine/cluster; never trust an inherited PGHOST from a client shell.

Read-only checks on each physical Mac, as shinzui:

```bash
cd /Users/shinzui/.config/dotfiles.nix
hostname
uname -m
id -un
git rev-parse HEAD
shasum -a 256 flake.lock
mori --version
rei --version
mina --version
reiko --version
psql --version
pg_dump --version
df -h /Users/shinzui
psql -X -v ON_ERROR_STOP=1 -h "$HOME/.local/state/postgresql" -p 5432 -U shinzui -d postgres \
  -c 'SHOW server_version;' -c 'SHOW data_directory;' \
  -c "SELECT datname, pg_database_size(oid), datallowconn FROM pg_database WHERE NOT datistemplate ORDER BY datname;"
```

If clients are absent, obtain the configured PostgreSQL package through the flake's package/development environment; never search /nix/store or update PostgreSQL as a shortcut. Missing configured databases must be investigated, not created as empty replacements. Capture detailed output privately.

After implementing preparation, run focused tests and builds from the root:

```bash
python3 bin/test-rei-mori-owner.py
python3 bin/test-rei-mori-migration.py
python3 bin/test-rei-ssh-dispatch.py
python3 bin/check-rei-mori-owner.py --expect SungkyungM1X
./bin/build.sh SungkyungM1X --out-link result-sungkyung
./bin/build.sh yujin --out-link result-yujin
```

The migration and SSH test files are proposed deliverables. Expected results are passing tests, the correct sole owner, and successful builds. At stopped/validation/active revisions, use --expect none or --expect yujin as appropriate. Record exact revision/stage and preserve unrelated user changes.

The activation wrapper uses ./result. Do not activate after only a custom-output-link build. On the matching physical machine, build that reviewed revision into ./result immediately before switching:

```bash
# On Sungkyung for its reviewed stopped or later client revision:
./bin/build.sh SungkyungM1X
sudo ./bin/darwin-rebuild.sh SungkyungM1X

# On Yujin only after final restoration, for validation and then active:
./bin/build.sh yujin
sudo ./bin/darwin-rebuild.sh yujin
```

Set up the isolated rehearsal on Yujin using the same PostgreSQL build:

```bash
umask 077
export REHEARSAL_ROOT="$HOME/.local/state/rei-mori-rehearsal-<unique-tag>"
mkdir -m 700 "$REHEARSAL_ROOT"
mkdir -m 700 "$REHEARSAL_ROOT/socket"
initdb --auth=trust --no-locale --encoding=UTF8 -D "$REHEARSAL_ROOT/data"
pg_ctl -D "$REHEARSAL_ROOT/data" -l "$REHEARSAL_ROOT/server.log" \
  -o "-k $REHEARSAL_ROOT/socket -c listen_addresses=''" -w start
```

Restore canonical database names into this separate cluster with the commands below, after reviewed role/extension preparation. Stop it with pg_ctl -D "$REHEARSAL_ROOT/data" -m fast -w stop. Retain its files until accepted. A startup failure is never permission to fall back to the production socket.

On Sungkyung, after the live freeze gate, create a unique final bundle. The following is a command template; wrap it in fail-fast shell settings in the operator script and record completion only after all evidence passes:

```bash
set -euo pipefail
umask 077
export MIGRATION_ROOT="$HOME/.local/state/rei-mori-move-<unique-tag>"
mkdir -m 700 "$MIGRATION_ROOT"
export MIGRATION_SOCKET="$HOME/.local/state/postgresql"

pg_dumpall -h "$MIGRATION_SOCKET" -p 5432 -U shinzui --globals-only \
  --file="$MIGRATION_ROOT/globals.sql"

for db in rei mori mori_rei_app notion_hub; do
  pg_dump -h "$MIGRATION_SOCKET" -p 5432 -U shinzui \
    --format=custom --verbose --file="$MIGRATION_ROOT/$db.dump" "$db" \
    2>"$MIGRATION_ROOT/$db.dump.log"
  pg_restore --list "$MIGRATION_ROOT/$db.dump" >"$MIGRATION_ROOT/$db.contents.txt"
done
```

Run the helper's fingerprints before and after the loop, and add discovered coupled stores explicitly to the runbook. Inspect warnings privately. Keep immutable archives for retry rather than piping a live export into production. Capture filesystem payloads/checksums from the explicit manifest.

SQLite backup example, substituting the discovered Mina path and preserving WAL consistency:

```bash
export MINA_SOURCE_DB="$HOME/.local/share/mina/mina.db"
python3 - <<'PY'
import os, sqlite3
from pathlib import Path
source = Path(os.environ["MINA_SOURCE_DB"]).resolve(strict=True)
target = Path(os.environ["MIGRATION_ROOT"]) / "mina.db"
if target.exists():
    raise SystemExit("Refusing to replace an existing backup")
with sqlite3.connect(source.as_uri() + "?mode=ro", uri=True) as src:
    with sqlite3.connect(target) as dst:
        src.backup(dst)
        if dst.execute("PRAGMA integrity_check").fetchall() != [("ok",)]:
            raise SystemExit("SQLite integrity check failed")
        if dst.execute("PRAGMA foreign_key_check").fetchall():
            raise SystemExit("SQLite foreign key check failed")
print("PASS: Mina SQLite backup")
PY
```

Transfer the complete database/file/manifest bundle over verified SSH; recompute SHA-256 checksums on Yujin and independent backup storage. Private database contents and role exports never enter Git. Mark completion only after these payloads and unchanged-state comparisons pass.

Fence source databases from the source postgres maintenance database. psql's :"db_name" quotes an identifier safely:

```bash
for db in rei mori mori_rei_app notion_hub; do
  psql -X -v ON_ERROR_STOP=1 -h "$MIGRATION_SOCKET" -p 5432 -U shinzui -d postgres \
    -v db_name="$db" <<'SQL'
ALTER DATABASE :"db_name" ALLOW_CONNECTIONS false;
SQL
done
psql -X -v ON_ERROR_STOP=1 -h "$MIGRATION_SOCKET" -p 5432 -U shinzui -d postgres \
  -c "SELECT datname, datallowconn FROM pg_database WHERE datname IN ('rei','mori','mori_rei_app','notion_hub') ORDER BY datname;" \
  -c "SELECT datname, usename, application_name, state FROM pg_stat_activity WHERE datname IN ('rei','mori','mori_rei_app','notion_hub');"
```

Expect false/f for every selected database and zero remaining sessions. Attempt a new explicit psql connection to each selected database; expect a not-accepting-connections failure. Any survivor blocks promotion; terminate only identified application/migration sessions after review. The rollback counterpart is ALLOW_CONNECTIONS true, only after the other host is stopped/fenced and original values have been checked.

For import, first preserve destination conflicts and prepare reviewed-globals.sql as described in milestones 3 and 5. Use these commands for both rehearsal and final import with their distinct sockets:

```bash
set -euo pipefail
export RESTORE_SOCKET="<explicit destination or rehearsal socket directory>"
export RESTORE_ROOT="<verified transferred bundle directory>"
psql -X -v ON_ERROR_STOP=1 -h "$RESTORE_SOCKET" -p 5432 -U shinzui -d postgres \
  -f "$RESTORE_ROOT/reviewed-globals.sql"
for db in rei mori mori_rei_app notion_hub; do
  pg_restore -h "$RESTORE_SOCKET" -p 5432 -U shinzui --dbname=postgres \
    --create --exit-on-error --verbose "$RESTORE_ROOT/$db.dump" \
    >"$RESTORE_ROOT/$db.restore.log" 2>&1
done
```

Do not use --clean, --no-owner, --no-acl, or ignore-errors to hide conflicts. --create retains database-level metadata and cannot be combined with a single-transaction restore. A failed import may leave a partial database: quarantine it before retrying into an empty target. Never repeat the loop against already-restored production data.

Readiness probes after Yujin validation activation:

```bash
curl -fsS http://127.0.0.1:8780/health/ready
curl -fsS http://127.0.0.1:8775/health/ready
curl -4 -fsS http://mori.localhost/health/ready
curl -4 -fsS http://rei.localhost/health/ready
curl -6 -fsS http://mori.localhost/health/ready
curl -6 -fsS http://rei.localhost/health/ready
curl -fsS http://mina.localhost/ >/dev/null
curl -fsS http://reiko.localhost/ >/dev/null
```

On Sungkyung use ports 18780/18775 for the first two direct probes. Require readiness success and actual known UI records, not HTTP 200 alone. After workers start query http://127.0.0.1:9091/subscriptions on Yujin and port 19091 on Sungkyung; compare with durable checkpoint evidence. Confirm deployed --help before using rei ops stream subscriptions or mori ops stream subscriptions.

From another peer request Yujin port 80 with Host: mori.localhost and Host: rei.localhost; Caddy's local-only matcher should return 404. A firewall denial is private but does not itself test the matcher. Do not open public access just for this check.

Record exact controlled-write CLI syntax from deployed --help and the selected harmless records in the private operator runbook before running probes. Required outcomes are described in milestone 6. Do not invent write commands from memory.


## Validation and Acceptance


Preparation must retain Sungkyung as sole owner. Both-off must prove labels and manual writers stopped. Final exports must be stable across before/after data fingerprints and independently stored/restorable. Before startup, restored data must match schemas, digests, sequence state, ownership/settings/extensions, complete event history/membership, checkpoints, queues/timers, delivery ledgers, and SQLite integrity. Filesystem/Git manifests must match durable content.

Prove known Rei/Mina/Reiko content appears on Yujin, new controlled writes appear from both machines, and resumed automation has its expected effect once. Prove source database refusal separately from the declaration check. Verify listener addresses, IPv4/IPv6 routes, tunnel reconnect and failure without fallback, role persistence after physical restart, and recoverability of Yujin database plus non-database backups.

bin/test-rei-mori-migration.py must cover corrupted/missing payloads, same-count changed content, sequence drift, duplicate rows, partitions, large objects, wrong sockets, destination conflicts, and incomplete/interrupted bundles. bin/test-rei-ssh-dispatch.py must cover malformed payloads and shell metacharacters using harmless fixtures. Ownership tests must reject workers/healing in validation, dual owners, Caddy on an inactive client, and a tunnel on the owner. These checks protect data-loss and split-ownership hazards.

If a physical machine, ingress control, credential, or independent storage is unavailable, record the precise unfinished milestone. A Nix build, loaded label, transport checksum, or HTTP status alone never establishes migration completion.


## Idempotence and Recovery


Use unique directories and explicit cluster/machine identities for every attempt. Inventory/comparison is repeatable. Restore only into empty or quarantined targets; retain failures and the last good bundle. Never discard a live SQLite WAL file or reset/replay ledgers to conceal mismatches.

If preparation/rehearsal fails, keep Sungkyung active and Yujin inactive. If final transfer/import fails, keep both stopped while repairing, or use pre-write rollback. Never activate a source owner generation while Yujin is live.

Before Yujin has made any new database/file write, stop/disable destination runtime and client access, verify no sessions/workers remain, and fence its production databases. Only then restore source ALLOW_CONNECTIONS settings from postgres, select Sungkyung sole owner, and activate it. Restore old Yujin-to-Sungkyung client access from its preserved configuration if needed. Resume source backup schedules only against its own catalog/mirror.

Once Yujin has registered paths, run a controlled write, applied a startup migration, or started workers, treat its state as newer even if ingress is paused. Pause ingress, stop Yujin writers, take a fresh consistent database/file bundle and external-effect inventory, fence Yujin, and restore/compare newer state back to Sungkyung through the same tested process before reactivation. Reconcile effects already performed so restored queues do not repeat them. If correctness cannot be established, keep both stopped and repair Yujin instead of reopening the old snapshot.

Fencing blocks new connections but does not end existing ones. Nix generation rollback does not undo database settings, data writes, or external effects. Retain source originals and protected bundles for the retention window; retirement requires a separate deliberate action after recovery conditions pass.


## Interfaces and Dependencies


workstation.reiMori.enable remains the ownership interface, supplemented by stage = "validation" | "active". Disabled means no owned agents. Validation permits the five named web/API agents only. Active preserves original service enables; healing requires enabled + active. Caddy joins ownership. Bootstrap-arm remains unchanged.

home/rei-mori-client.nix exposes explicit enable, target, tunnelIdentityFile, reiIdentityFile, stateDirectory, and forwardWebPort options. Client enablement or restoration must never implicitly enable a runtime. Final Sungkyung uses this interface and final Yujin disables it. Two loopback port-80 listeners reach Yujin Caddy, private high-port forwards reach API/metrics, and a private Unix socket supports PostgreSQL clients.

The proposed bin/rei-mori-migration.py provides inventory, fingerprint, manifest, and verify-bundle subcommands with required explicit --socket and/or --root plus a machine role for database evidence operations. Define --help, nonzero failure statuses, immutable complete/incomplete bundle markers, and redacted terminal summaries. Use Python's standard library and installed PostgreSQL clients with argument arrays. The helper collects/verifies evidence only; it never stops services, changes schemas, restores databases, overwrites targets, or opens ingress. No new runtime dependency is needed.

home/postgresql.nix gains an offsite-directory option preserving Sungkyung's existing default and using a distinct Yujin child directory. SQLite and files need separate protection. Retain selected deployed application/PostgreSQL versions; dependency/schema upgrades are separate reviewed work.

Record later provenance revisions through agents/skills/exec-plan/record-provenance.ts using verified runtime identity. Commit on the current branch with Conventional Commits and ExecPlan: docs/plans/8-move-the-primary-rei-and-mori-runtime-from-sungkyung-to-yujin.md. No Intention ID was supplied. Durable cross-repository references must use canonical mori:// URIs; repository-local paths may remain relative.


Created 2026-10-16: grounded six migration milestones in existing ownership, four configured PostgreSQL stores, Mina SQLite, Reiko sidecars, reversed client access, and distinct machine identities. All live inventory and migration actions remain future work.
