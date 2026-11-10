---
id: 8
slug: move-the-primary-rei-and-mori-runtime-from-sungkyung-to-yujin
title: "Move every PostgreSQL-backed service, its backups, and the shared support services from Sungkyung to Yujin"
kind: exec-plan
created_at: 2026-10-17T03:57:38Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-17T03:57:38Z
  revisions:
    - model: "claude-opus-5-5"
      harness: "claude-code"
      at: 2026-11-10T13:39:33Z
      mode: "update"
      note: "Reviewed against the repo and Sungkyung; added Mina, Reiko, Notion Hub, and PostgreSQL backup move; fixed offsite path and PG17 tooling defects"
    - model: "claude-opus-5-5"
      harness: "claude-code"
      at: 2026-11-10T21:34:09Z
      mode: "update"
      note: "Added support services (Caddy, VictoriaLogs, VictoriaTraces, Redpanda) and a mori-rei-app proof; data-safety invariants; Yujin backup-agent hazard"
    - model: "claude-opus-5-5"
      harness: "claude-code"
      at: 2026-11-10T21:57:43Z
      mode: "implement"
      note: "Milestone 2 preparation code (cutover phase, staged ownership, support switch, backup ownership, guard, client module, evidence helper) and first inventories"
---

# Move every PostgreSQL-backed service, its backups, and the shared support services from Sungkyung to Yujin

This ExecPlan is a living document. Keep Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective current during implementation. Creating this plan does not execute the migration.


## Purpose / Big Picture


Make Yujin the only workstation that runs anything depending on the shared PostgreSQL server. After this plan the following run on Yujin and nowhere else: Rei (the intention tracker, with its API and workers), Mori (the project registry and its automation daemon), mori-rei-app (the webhook bridge from Mori to Rei), Notion Hub (its database and subscription worker), Mina and Reiko (the two web tools that read Mori and Rei), PostgreSQL's scheduled backups with their external-drive mirror, and the shared support services: Caddy (the proxy behind names such as mina.localhost), VictoriaLogs with its log shippers, VictoriaTraces with its Jaeger UI, and the Redpanda cluster. The support services hold no data this plan has to preserve, but they move with the runtime so that every name and port Sungkyung uses reaches one machine, and never a mix of two. Existing intentions, notes, event history, automation progress, webhook delivery records, Notion Hub tracked pages and conversations, Mina tracking/Obeya data, and Reiko archives must survive. On Yujin the tools and browser names work locally. Sungkyung becomes a client: it opens the SSH connection to Yujin and accesses Yujin's services through private local forwards. It runs no service against its own PostgreSQL; its old cluster stays only as a fenced recovery copy for the retention window.

Success means existing records survive a verified restore, a controlled new write in each of Rei, Mina, Reiko, and Notion Hub is visible from both machines, a controlled commit travels through Mori and mori-rei-app into exactly one Rei action, workers resume from preserved positions, a log line and a trace produced on Sungkyung land in Yujin's VictoriaLogs and VictoriaTraces, Sungkyung's Kafka clients reach Yujin's Redpanda, Yujin's own scheduled backup and offsite mirror have produced a copy that was actually restored, and Sungkyung can neither write its old production databases nor run a competing backup schedule. Schedule a maintenance window after a timed rehearsal; measure the duration rather than promising zero downtime. Preserve original data and independent backups throughout.


## Progress


- [x] (2026-11-10) Review the plan against the working tree and Sungkyung's live state; expand it to every PostgreSQL-dependent service and to the backups. Yujin itself was not inspected.
- [x] (2026-11-10) Extend the scope to the shared support services (Caddy, VictoriaLogs, VictoriaTraces with Jaeger UI, Redpanda) and give mori-rei-app its own proof; read-only check of Yujin's support services, backup agents, and databases.
- [ ] Milestone 1: inventory both physical machines, versions, databases, workspace files, repositories, ingress, and pending work; classify all 19 non-template databases found on Sungkyung.
- [x] (2026-11-10) Milestone 1: get the Notion Hub subscription worker out of its crash loop through mori://shinzui/notion-hub (revision b900d36, deployed to Sungkyung).
- [x] (2026-11-10) Milestone 1: locate the aki-2023 drive and establish which cluster its mirror holds. It holds Sungkyung's chain, verified by checksum after a fresh full backup.
- [x] (2026-11-10) Milestone 1: stop Yujin's com.shinzui.pg-backup and com.shinzui.pg-backup-offsite-sync agents before aki-2023 is attached anywhere. Both were booted out with exit 0, launchctl list shows no pg-backup agent, com.shinzui.postgresql is still running, and aki-2023 was not mounted. This lasts only until Yujin's next switch: any Yujin switch before the milestone 2 preparation revision reloads both agents, so stop them again after such a switch.
- [x] (2026-11-10) Milestone 2: implement and verify staged ownership, support-service ownership, backup ownership, the PostgreSQL 18 tool wrapper, reverse client configuration, and evidence tooling without moving the active runtime. Evidence is in the entries and handoff notes below.
- [x] (2026-11-10) Milestone 1: host, support-service, mori-rei-app, workspace, and repository inventory on both machines (private host-*.txt files). Both run identical application versions (mori 3ba3562, rei 597e041, mina c7ce26d, reiko eb3f9cb, nhub b900d36) and the same flake.lock, so nothing needs aligning. Free disk: Yujin 4.7 TiB, Sungkyung 583 GiB. The bridge summarises through codex (provider openai, transport cli), and codex is logged in on both machines. Its webhook secret is readable on both. Its queue is pgmq commit_batching (interval 3600 s, visibility 300 s), and all 100 listed deliveries were delivered. All 75 observed repositories are present on Yujin. aki-2023 is identified, and the Sungkyung-to-Yujin keys are created and enrolled (2026-11-10). Mina commands that open the tracking store: mina track, mina obeya, mina web, and probably mina docket.
- [x] (2026-11-10) Milestone 1: evidence helper bin/rei-mori-migration.py with tests, and the first read-only inventory of both clusters (19 databases on Sungkyung, 3 on Yujin), stored privately under ~/.local/state/rei-mori-move-evidence on each machine.
- [x] (2026-11-10) Milestone 2: preparation code written and verified by evaluation and tests: the cutover phase (hosts/rei-mori-cutover-phase.nix, home/rei-mori-cutover.nix), workstation.reiMori.stage, workstation.supportServices, services.postgresql.backups with the owner refusal and pg18, bin/pg-offsite-guard.py, home/rei-mori-client.nix, the managed rei-ssh-dispatch, the extended owner checker, and docs/rei-mori-yujin-migration.md. check-rei-mori-owner.py --all-phases passes for all four phases, and the four test files pass (19, 14, 8, and 9 tests). Validation evaluates to exactly mori-serve, rei-api, mina-web, and reiko-web. ./bin/build.sh SungkyungM1X --out-link result-sungkyung and ./bin/build.sh yujin --out-link result-yujin both succeeded on Yujin. Against the pre-change evaluation, the preparation revision changes Sungkyung only in its two backup scripts, and removes Yujin's two backup agents and extends its client tunnel and shell settings.

Yujin switched to the preparation revision (41b23f8) on 2026-11-10: launchctl list shows no pg-backup agent, the tunnel answers with Sungkyung's system identifier 7610654636632884239, Mori 18780 and the new Rei API 18775 forwards return 200, fresh shells carry the tunnelled Notion Hub string, and ~/.local/libexec/rei-ssh-dispatch refuses with exit 2 because Yujin is not the owner.

Sungkyung switched to 41b23f8 on 2026-11-10 with its runtime running (Notion Hub worker runs = 1) and pg18 at PostgreSQL 18.6. rsync -anc found 0 differing entries and an identical pg_rman.ini between its catalog and /Volumes/aki-2023/postgresql-backups, so the mirror was adopted for cluster 7610654636632884239, and the next guarded sync passed and completed. On Yujin, pg-backup and pg-backup-offsite-sync now refuse with exit 1.

The Sungkyung-to-Yujin keys were created on Sungkyung and enrolled on Yujin on 2026-11-10, after confirming that Sungkyung's known_hosts entry for 100.105.45.104 matches Yujin's local ED25519 host key (SHA256:xkgZtYcb2XCWujle5m5XXWwwWBx1KvPCFh3li1LcV0I). Yujin's previous authorized_keys is kept as ~/.ssh/authorized_keys.before-yujin-client-20261110. The tunnel key cannot run a shell, forwards a permitted port (9428 answered OK), and is refused an unlisted one (22). The Rei key reaches only the dispatcher, which refuses while Yujin is not the owner. That completes milestone 2.

Handoff, 2026-11-10: milestone 1 still needs only the second inventory sample on Sungkyung, at least a day after 2026-11-10T13:56Z (rerun the inventory command in docs/rei-mori-yujin-migration.md and compare the 14 retained databases' xact_commit and xact_rollback). Milestone 4 starts the maintenance window and needs the user's explicit go-ahead in the session.
- [x] (2026-11-10) Milestone 3: rehearse PostgreSQL/SQLite restoration and a pg_rman restore on Yujin in isolation; record timing and recovery proof. A REHEARSAL bundle from Sungkyung (rei-mori-rehearsal-export-20261110T142554, sealed, 18 files, 280 MB) verified on Yujin and restored with zero errors into two isolated clusters (rei-mori-rehearsal-r1, -r2) whose fingerprints match exactly. Against the live source only live-write drift differs, and every schema matches. Notion Hub's schemas, tracked pages (14 active, 1 archived), subscriptions, dead letters (0), and 64 migrations match. Mina's restored SQLite matches the live store exactly (101 rows, integrity ok). The workspace survives with Git fsck clean, HEAD 8af9fb7 ahead 1, its untracked and 5 ignored files, and 1689 files. A pg_rman full backup of r1 (1614 MB, 6 s) restored with --hard-copy, and its copy matches r1 exactly. A truncated archive failed into a third cluster, r3, and stayed quarantined there. Timings: export 20 s, SQLite and files 1 s, transfer 15 s, restore 17 s, Yujin fingerprint 10 s, source fingerprint about 20 s.
- [x] (2026-11-10) Milestone 4: freeze writes, stop and verify Sungkyung (runtime and support services), create final exports, take the final physical backup, and fence its old databases and Mina store. The user ordered the move on 2026-11-10 without waiting for the second idle sample. Yujin's ingest and tunnel were booted out, then Sungkyung's Redpanda was stopped with its volume kept, and its watchdog, runtime, support, and backup agents were unloaded. Only com.shinzui.postgresql remained, with no client session, no prepared transaction, and every runtime and support port free. The final bundle rei-mori-move-20261110T143713 (24 files, 280 MB, 57 s) has identical before and after fingerprints, and Mina's backup matches the live store. Three verified copies exist: Sungkyung, Yujin, and /Volumes/aki-2023/rei-mori-move-bundles (FileVault). The final full backup is 2026-11-10 14:38:42 FULL 2921MB OK, then mirrored at 14:40:01. All four databases refuse connections, and Mina's store is mode 444 and refuses writes. Sungkyung was switched to the stopped revision (504c659). Two stray pg-backup runs are described in Surprises & Discoveries.
- [x] (2026-11-10) Milestone 5: restore and compare final data on Yujin; establish its own Mori identity and repository locations; validate Yujin with workers off. No conflicting database existed. message_store was created from the reviewed globals, and the four databases restored in 26 s with fingerprints identical to the frozen source. Mina, the workspace (8af9fb7, fsck clean), and Reiko were installed. Yujin's earlier mina.db and its rei-workspace clone (cec62e2, an ancestor, clean) were kept as *.precutover-20261110, and its last-full-backup stamp was moved aside. The two Mori host IDs differ, and mori path resolves Yujin checkouts. nhub-migrate verify: applied=64 pending=0 unknown=0. At stage validation (1f5eca6), Yujin runs exactly mori-serve, rei-api, mina-web, and reiko-web, and every readiness probe returns 200 over IPv4 and IPv6. Mina lists 266 projects and Reiko 12 collections and 840 intentions, all with zero warnings.
- [ ] Milestone 6: move PostgreSQL backups to Yujin: first full backup, restore proof, new offsite mirror, frozen Sungkyung chain. Done on 2026-11-10: archive_mode on and wal_level replica, a first full backup (2026-11-10 14:56:11 FULL 5641MB OK), and a pg_rman hard-copy restore whose copy matches Yujin's live cluster exactly. Its only differences from milestone 5 are projection-cursor rows in keiro.keiro_projection_group_cursors, advanced by the validation-stage APIs. The old mirror's listing (69698 files) was recorded privately and aki-2023 ejected from Sungkyung. Remaining: attach the drive to Yujin, sync and check the new mirror, and copy the non-database state.
- [ ] Milestone 7: reverse Sungkyung's client connection, including the support-service forwards, and resume workers.
- [ ] Milestone 8: prove Mina, Reiko, Notion Hub, and mori-rei-app on Yujin from both machines, then reopen ingress.
- [ ] Milestone 9: prove restart persistence and update runbooks/ADRs.


## Surprises & Discoveries


The entries up to the support-service measurements come from the 2026-11-10 read-only review. The ones after them were found during implementation.

The PostgreSQL tools on PATH are one major version behind the server. home/default.nix installs postgresql_17 while home/postgresql.nix runs postgresql_18, so the earlier revision's bare pg_dump and initdb commands would fail or build the wrong cluster, because pg_dump refuses a server newer than itself.

```text
psql (PostgreSQL) 17.11
pg_dump (PostgreSQL) 17.11
SHOW server_version -> 18.6
```

The Notion Hub worker is crash-looping. launchd has restarted it more than 15,000 times and the failure was still occurring during the review. Its projection hits the partial unique index idx_tracked_pages_notion_page_id_active (notion_page_id WHERE status <> 'archived'), so its checkpoint cannot pass that event. A restored copy would resume at the same event and fail the same way on Yujin.

```text
com.shinzui.notion-hub-subscription: state = spawn scheduled, runs = 15375, last exit code = 1
ServerError "23505" "duplicate key value violates unique constraint \"idx_tracked_pages_notion_page_id_active\""
tracked_pages: active 12, archived 1
```

Resolved 2026-11-10: the duplicate was two PageTracked events for one Notion page, 19 seconds apart, created because nhub page track checks a read model that had stalled. Revision b900d36 of mori://shinzui/notion-hub leaves out a PageTracked whose Notion page already has a live row. Run first against a clone and then deployed, it brought the worker to a single run with every read model at the newest event in its category. Why the read model stalled on 2026-10-19 is still unexplained.

```text
com.shinzui.notion-hub-subscription: state = running, runs = 1, last exit code = (never exited)
tracked-page-read-model 896, conversation-read-model 723, okf-sync-read-model 874, collection-read-model 716
```

The offsite mirror is stale and its contents are unknown. Sungkyung's last successful sync was on 2026-10-13, every attempt logged since reports the drive missing, and aki-2023 was not mounted during the review. Yujin's unconditional StartOnMount agent would have overwritten the mirror with Yujin's catalog if the drive has been attached there since. Treat the mirror as unverified until milestone 1 inspects it.

```text
=== 2026-10-13T17:56:13-07:00 offsite sync to /Volumes/aki-2023/postgresql-backups ===
Offsite sync complete.
/Volumes/aki-2023 not mounted; skipping offsite sync.   (197 such entries in the log)
```

Resolved 2026-11-10: aki-2023 was reattached to Sungkyung and its on-mount sync replaced the mirror before it could be inspected, so whether Yujin had overwritten it in the meantime is unknown and no longer matters. A fresh full backup was then taken and mirrored, and a checksum comparison found no differences between the catalog and the mirror. The drive must not be attached to Yujin until Yujin's backup agents are stopped.

```text
2026-11-10 06:41:03  2026-11-10 06:42:00  FULL  2870MB     1  OK
rsync -anc --delete catalog/ mirror/ -> 0 differing entries
```

The earlier revision's Yujin offsite path was unsafe. It placed Yujin's mirror at /Volumes/aki-2023/postgresql-backups/yujin, inside the directory Sungkyung mirrors with rsync --delete, so the next Sungkyung sync would have deleted Yujin's mirror.

The Sungkyung cluster holds 14 databases beyond the four configured stores and postgres: mori_rei_app_test, nhub_global_rollout_20261019t162956z, nhub_global_rollout_20261019t163029z, notion_hub_event_import_fresh, notion_hub_keiro_rollout_clone_20260924, notion_hub_migration_clone, notion_hub_migration_fresh, notion_hub_okf_live_20260923, rei_ep272_021_20261015, rei_ep272_021_baseline_20261015, rei_ep272_021_load_20261015, rei_ep272_app_operational_20261015, rei_ep272_global_restore_20261015, and rei_ep272_rollout_20261012. Nothing in this repository names them and none had a session at review time, but one observation does not prove they are idle.

The earlier revision omitted sungkyung-client-ingest, a ten-minute launch agent on Yujin that writes to Sungkyung's Mori database through the tunnel. It must stop for the freeze, and Sungkyung needs a counterpart after the reversal or its local commits stop reaching Mori.

Mina's write-ahead log is about eight times the size of its database, which confirms that copying mina.db alone would lose committed data. Reiko's archive directory is empty, so its first archive during validation creates the first sidecar on either machine.

```text
mina.db       147456 bytes
mina.db-wal  1236032 bytes
~/.local/share/reiko/archives is empty
```

Caddy binds 0.0.0.0:80 today and docs/local-services.md describes reaching tools from other devices through names that encode this Mac's LAN address, so bookmarks and DNS records for those names follow Sungkyung's address and will stop working after the move.

A later read-only check on Yujin, also on 2026-11-10, found that Yujin's own backup agents are loaded and its catalog took a full backup on 2026-11-05. aki-2023 was not attached. Until those agents are stopped, attaching the drive to Yujin would run an on-mount sync with rsync --delete into /Volumes/aki-2023/postgresql-backups, replacing the verified Sungkyung chain with Yujin's. This is the most immediate data-loss hazard in the plan, which is why stopping them is now its own Progress item.

```text
-  0  com.shinzui.pg-backup
-  0  com.shinzui.pg-backup-offsite-sync
~/.local/state/postgresql/last-full-backup  modified 2026-11-05 03:00
/Volumes: Macintosh HD, Recovery
```

Yujin's cluster has none of the four canonical database names, so the final restore needs no rename. It does hold two scratch databases of its own, and Yujin has its own Mina store, which milestone 5 must preserve as a conflict rather than overwrite.

```text
postgres                              7774 kB
rei_ep276_20261108_044829             334 MB
rei_ep276_rebuild_20261108_044829     337 MB
system_identifier                     7696681397435454777
~/.local/share/mina/mina.db           present
```

The support services already run on both machines, because their modules are shared and nothing gates them. Yujin runs com.shinzui.local-web-proxy (Caddy on *:80), com.shinzui.victorialogs with sixteen victorialogs-shipper agents, com.shinzui.victoriatraces, com.shinzui.victoriatraces-jaeger-ui (nginx on 127.0.0.1:16686), and Redpanda's Apple Container cluster (Console on 127.0.0.1:8080). VictoriaLogs and VictoriaTraces listen on every interface (*:9428, *:10428), not just loopback. Because Yujin has been a client, its stores are small. Sungkyung's sizes are a milestone 1 measurement.

```text
~/.local/share/victoria-logs/data     1.1M
~/.local/share/victoria-traces/data   29M
```

The log shippers tail local files and post to localhost:9428. If Sungkyung's shippers kept running after its port 9428 is forwarded to Yujin, they would write Sungkyung's leftover and fenced-cluster log lines into Yujin's VictoriaLogs under the same app names, interleaving two machines in one stream. They must stop with the rest of Sungkyung's support services.

Mori's registration for mori-rei-app points at a host-relative URL, so after the move Mori's deliveries go to whichever machine runs mori-automate, and the registration needs no change. The app's webhook secret is age-encrypted to Yujin's agenix key as well as Sungkyung's (secrets/secrets.nix, with hosts/yujin/default.nix pointing age.identityPaths at ~/.ssh/agenix_ed25519).

```text
app_01knxf3p1aezarprphnkpgsqzj  mori-rei-app  http://localhost:26862/webhook  active  1 (1 changeset)
```


Implementation, 2026-11-10: Yujin's cluster holds only the shinzui role. Sungkyung also has the login role message_store, which owns part of notion_hub, so reviewed-globals.sql must create it on Yujin before any restore with preserved owners.

```text
Sungkyung roles: message_store (login), shinzui (superuser)
Yujin roles:     shinzui (superuser)
```

Implementation, 2026-11-10: neither machine allows sudo without a password, so an agent cannot switch either host. Every switch in this plan is an operator step at that machine's terminal.

Implementation, 2026-11-10: Sungkyung's existing mirror has no .postgresql-cluster-id marker, so once the preparation revision is active there, its offsite sync refuses until pg-backup-offsite-adopt --verified runs. aki-2023 was attached to Sungkyung at the time, so adopt immediately after that switch, after a fresh rsync -anc dry run shows no differences.

Implementation, 2026-11-10: a plain pg-backup on Sungkyung still runs until Sungkyung is switched to the stopped revision, because the non-owner refusal is part of that revision. Unloading the agents does not add it. The agent ran pg-backup full twice on Sungkyung as a "refusal check" before that switch, and both runs started real backups. The first died when its output pipe closed, and the second died when its SSH session ended. Both died while copying files, before pg_rman reaches retention, and left 0-byte RUNNING entries at 14:40:36 and 14:43:55. Every earlier generation is still listed OK, including the full backups of 2026-11-01, 11-08, 11-10 06:41, and the final 11-10 14:38:42. The mirror sync at 14:40:01 ran before either. Per the invariants, the RUNNING entries are not deleted. Never run a pg-backup command as a test: confirm the refusal by inspecting the deployed revision instead.

```text
2026-11-10 14:43:55  1969-12-31 16:00:00  FULL      0B     0  RUNNING
2026-11-10 14:40:36  1969-12-31 16:00:00  FULL      0B     0  RUNNING
2026-11-10 14:38:42  2026-11-10 14:39:33  FULL  2921MB     1  OK
```

Implementation, 2026-11-10: a shell started from a long-lived process keeps the old client endpoints after Yujin's switch. Home Manager's already-sourced guard is inherited, and the client's envExtra refresh left with the client. A fresh terminal gets Yujin's local settings, which env -i HOME=$HOME zsh -lc confirmed. Long-lived terminals and agents on Yujin must be restarted.

Implementation, 2026-11-10: pg_rman restore --check reads pg_control in the target data directory, so it fails on the empty directory that milestone 6's restore proof uses. The rehearsal script did not stop on that failure and went on to restore into the empty scratch directory. That was harmless there but contrary to the plan's rule, so milestone 6 now runs pg_rman validate before restoring and never uses --check.

```text
ERROR: pg_controldata file ".../restore-proof/data/global/pg_control" does not exist
```

Implementation, 2026-11-10: the first fingerprint comparison of a restore against its source reported schema differences in rei, mori, and notion_hub. A few source objects, for example keiro_read.projection_group_status_v1 and schema keiro_read, store an explicit ACL equal to the owner's default ({shinzui=arwdDxtm/shinzui}). pg_dump omits a grant equal to the default, so the restore stores NULL, which grants the same privileges. The helper now compares ACLs through acldefault(), with a regression test, and all four schemas then match line for line.

Implementation, 2026-11-10: the support services on Sungkyung bind more than the plan's port list. mori-rei-app (26862), rei-api (8775), and Rei's metrics (9091) listen on every interface there, not loopback. This does not change the migration, but the LAN guidance in milestone 9 should note it. Sungkyung's Redpanda holds a large number of generated test topics, recorded privately, which by decision stay behind.

Implementation, 2026-11-10: Yujin's Git ingest into Sungkyung's Mori was already failing before this plan touched it. Eight repositories, among them tan/tan-ng-labs, are halted on orphaned checkpoints that need mori automate reset-checkpoint. This plan forbids resetting checkpoints, so the owner must decide on them separately, before the freeze or after the move.

Implementation, 2026-11-10: Yujin already has a ~/.local/share/mina/mina.db (modified 2026-10-16), an older /Users/shinzui/Keikaku/rei-workspace clone at cec62e2, and no ~/.local/share/reiko. Milestone 5 must keep the first two as conflicts, not overwrite them.

Implementation, 2026-11-10: on Sungkyung, every retained-not-migrated database showed xact_commit 0 and xact_rollback 0, and no session. The statistics have no reset time, so they count from the last server start. The helper's inventory itself opens one read-only transaction in each database, so the second sample may show each count up by the number of inventories taken in between, and no more.

```text
session mori 17, session rei 26, session notion_hub 3 (all idle, all migrated databases)
rei_ep272_* / notion_hub_* / nhub_global_rollout_* / mori_rei_app_test: commit 0, rollback 0
replication slots: none; shared_preload_libraries: empty
```


## Decision Log


2026-10-16: Move the complete existing runtime group, including its webhook bridge and Notion Hub subscription. The configured databases rei, mori, mori_rei_app, and notion_hub move together because integration state affects correctness. Discover any additional production store or alternate connection before freezing the inventory.

2026-10-16: Use complete PostgreSQL logical exports and SQLite's backup API, followed by restoration and comparison. Preserve source data and destination conflicts. Do not copy a live PostgreSQL data directory, reconstruct stores through replay, reset checkpoints, or combine this host move with application/schema upgrades.

2026-10-16: Add an owner validation stage before enabling background workers. Both hosts are disabled during final export/import. Yujin's APIs/UI then start without automations or healing, allowing path and browser verification before side effects resume.

2026-10-16: Move Caddy to Yujin and forward Sungkyung's loopback port 80 to Yujin's loopback port 80, preserving names such as mina.localhost. Preserve Mori/Rei route restrictions.

2026-10-16: Preserve Yujin's distinct SSH, Tailscale, and Mori identities. Repository registration can add Yujin's locations; copying Sungkyung's host-id is forbidden. Keep the selected existing application versions and lockfile during migration.

2026-11-10: Define the scope as every service that depends on the shared PostgreSQL server, not only Rei and Mori. That adds Mina, Reiko, and Notion Hub as first-class services with their own acceptance in milestone 8, and PostgreSQL's backups with their own milestone 6. The title changes accordingly; the file name, slug, and id stay stable so existing references and the ExecPlan trailer keep resolving.

2026-11-10: Move backups as a separate ownership with the option services.postgresql.backups.enable, defaulting to off, with exactly one host enabled except during the stopped interval. Runtime ownership and backup ownership change at different moments: Sungkyung's final physical backup happens after its runtime stops, and Yujin's schedule must not run until its restored data has been compared. Yoking them to one flag would get one of those wrong.

2026-11-10: Do not transfer the pg_rman catalog. It holds byte-level copies of Sungkyung's cluster and cannot recover Yujin's logically restored databases, so moving backups means Yujin starts its own chain from a full backup while Sungkyung's final chain freezes in place as the rollback copy. Copying Sungkyung's catalog onto Yujin would produce a catalog that validates and cannot restore.

2026-11-10: Give Yujin's mirror the sibling path /Volumes/aki-2023/postgresql-backups-yujin and add a cluster-identity guard to the sync. A nested path would be deleted by Sungkyung's rsync --delete. The old mirror directory is never reused, because Yujin taking over that path would destroy Sungkyung's chain on its first sync.

2026-11-10: Disable the scheduled backup agents on Yujin in the preparation revision and make pg-backup, pg-backup-offsite-sync, and pg-backup-purge refuse to run on a non-owner unless PG_BACKUP_ALLOW_INACTIVE=1 is set. Sungkyung's final full backup uses that override once. Without the refusal, a stray manual run on Sungkyung applies retention and prunes the frozen chain.

2026-11-10: Do not restore the 14 rollout and scratch databases on Yujin by default. They are rehearsal copies, not services, and leaving them behind satisfies the goal that all services run on Yujin. They stay on Sungkyung, unfenced, and are covered by the final pg_rman full backup. Milestone 1 must confirm each is idle, with notion_hub_okf_live_20260923 examined specifically because of its name, and any that a service uses is promoted to the migration set. The user can overrule this per database in milestone 1.

2026-11-10: Repair the Notion Hub crash loop in its owning project before the freeze, as a precondition rather than during the move. This plan forbids combining a host move with an application or schema change, and a poison event would otherwise make "workers resume from preserved positions" unprovable. Never delete the event, edit the projection by hand, or advance the checkpoint from this plan. Cutting over with the worker still failing requires the user's explicit decision, recorded here, and leaves milestone 8 unfinished.

2026-11-10: Run every export, restore, and rehearsal command through a new pg18 wrapper instead of changing the postgresql_17 tools on PATH, so this migration does not alter interactive shells on either machine.

2026-11-10: Fence Sungkyung's retained Mina store with filesystem permissions after the final SQLite backup. Mina creates a new database when the path is missing, so moving the file away would silently create an empty second store, while read-only permissions make local writes fail loudly.

2026-11-10: Reverse the Git ingest along with the tunnel by moving sungkyung-client-ingest into home/rei-mori-client.nix, so Sungkyung's commits keep reaching Mori after the move.

2026-11-10: Keep Sungkyung's PostgreSQL server running, fenced, for the retention window so its state can be inspected and rollback does not require restarting it. Stopping that server is part of the separate retirement action after retention.

2026-11-10: At the user's request, the shared support services move too: Caddy, VictoriaLogs with its shippers, VictoriaTraces with its Jaeger UI, and Redpanda (the user chose to move Redpanda when asked). They do not depend on PostgreSQL. They move because, once Sungkyung forwards port 80 and the telemetry and Kafka ports to Yujin, any of them still running on Sungkyung would either block a forward or answer a name for the wrong machine. Afterwards each runs only on Yujin, and Sungkyung reaches it on the same port numbers through the tunnel, so the OTEL_EXPORTER_OTLP_ENDPOINT, rpk profile, and bookmarks on Sungkyung keep working unchanged.

2026-11-10: Keep the support services off the PostgreSQL critical path. They get their own switch, workstation.supportServices.enable (default true), and do not join workstation.reiMori.agents. Yujin keeps it true throughout, so preparation does not stop or restart anything on Yujin. Sungkyung turns it off in the stopped revision of milestone 4. No support-service step reads, writes, exports, restores, or fences PostgreSQL data, a pg_rman catalog, the bundle, or the offsite mirror, and a support-service failure is repaired in place. It is never a reason to retry, roll back, or reorder a database step. This supersedes the 2026-10-16 wording that added Caddy to the owned agent list. Caddy still moves to Yujin, through this switch instead, so the validation stage now permits four runtime agents (mori-serve, rei-api, mina-web, reiko-web) while Yujin's support services simply stay running.

2026-11-10: Do not carry telemetry history (user decision). VictoriaLogs and VictoriaTraces keep seven days, and both machines have recorded the same days, so merging partitions would add a maintenance-window step for data nobody has to preserve. Sungkyung's ~/.local/share/victoria-logs and ~/.local/share/victoria-traces stay on disk through the retention window. If an investigation needs them, open them with a temporary instance on a non-conflicting loopback port and a copied data directory.

2026-11-10: Move Redpanda without its topic data. Its data lives in the Apple Container volume redpanda-0-data, outside Nix. On Sungkyung run redpanda-down, which keeps all data, before the stopped switch. Then disable services.redpanda-container on Sungkyung, and keep the volume for the retention window. Never run redpanda-purge or delete the volume from this plan. Nothing in the Rei/Mori/Notion Hub runtime uses Redpanda, so topics left behind on Sungkyung are recorded in milestone 1 and are not migrated.

2026-11-10: Carry the support-service forwards in a second SSH agent, yujin-support-tunnel, separate from the database tunnel. Both use ExitOnForwardFailure, so if the two were one agent, a busy local port such as 9092 held by an ad hoc Kafka would also take down the PostgreSQL, Mori, and Rei forwards.

2026-11-10: Give mori-rei-app its own proof in milestone 8 instead of letting the generic "first automation" stand for it. The bridge depends on things the other proofs miss: the decrypted webhook secret, its summariser CLIs and their logins on Yujin, Mori's project lookup, repository checkouts for plan documents, its commit-batch queue, and its webhook_delivery idempotency table. It is the one service whose double delivery writes duplicate Rei actions.

2026-11-10: The user confirmed that the 14 rollout and scratch databases do not move. This settles the earlier default for all 14, including notion_hub_okf_live_20260923, and removes the option of promoting one into the migration set without asking.

2026-11-10: Fix the Notion Hub crash loop as a direct commit against BUG-4 in mori://shinzui/notion-hub rather than through a new ExecPlan, which milestone 1 had called for. The change is one projection rule with tests and a proof on a clone, and it did not alter the schema, so the deployed version stays stable for the rehearsal.

2026-11-10 (implementation): Replace the planned SSH forwards of 127.0.0.1:80 and [::1]:80 with a private forward 127.0.0.1:18081 to Yujin's port 80, plus a client-side Caddy (com.shinzui.yujin-client-web) on *:80 that answers only 127.0.0.1 and ::1 peers and returns 403 to anyone else. Sungkyung's first client switch failed with "cannot listen to port: 80": macOS lets an unprivileged process bind ports below 1024 only on the wildcard address, and binding 127.0.0.1:80 gives EACCES. A wildcard SSH forward would expose Yujin's private Mori and Rei routes to the LAN, because Yujin's Caddy sees forwarded connections as loopback. The loopback-only proxy keeps the browser names on Sungkyung with the same privacy.

2026-11-10 (implementation): Stop Sungkyung by unloading its agents with launchctl bootout as the user, watchdog first, before the stopped switch. This gave an immediate, verifiable stop without waiting for sudo. The stopped switch then made it durable. Yujin skipped its own stopped switch: its client agents were unloaded directly, and it went straight from preparation to validation after the restore compared clean.

2026-11-10 (implementation): Do not run mori register --path on Yujin. Mori's registered paths are identical on both machines (/Users/shinzui/Keikaku/...), all 75 observed repositories exist on Yujin, and mori-automate's registry refresh re-registers projects under the running host's identity. mori path on Yujin resolves to the existing checkouts.

2026-11-10 (implementation): Represent the reviewed revisions as one shared value, workstation.reiMoriCutover.phase in hosts/rei-mori-cutover-phase.nix (preparation, stopped, validation, active). Each host declares only its role (source or destination) and its client target, and home/rei-mori-cutover.nix derives the runtime, stage, backup, support, and client flags from it. This makes each revision a one-word change that both hosts read identically, and lets check-rei-mori-owner.py evaluate any phase through extendModules (--phase, --all-phases) without editing files. The phase table in docs/rei-mori-yujin-migration.md is the reference.

2026-11-10 (implementation): The client module forwards the Rei API (127.0.0.1:18775 to 8775) in both directions, so Yujin's current tunnel gains that forward at its preparation switch. It also sets all four connection strings, which now gives Yujin's shell Notion Hub and mori-rei-app settings through the tunnel instead of local databases Yujin does not have.

2026-11-10 (implementation): Install the forced command at ~/.local/libexec/rei-ssh-dispatch (home/rei.nix). It sets the owner's local settings itself and runs the managed Rei by absolute path, so neither a login shell nor a high-priority remote rei on PATH can redirect it. On a non-owner it refuses. bin/rei-ssh-dispatch.py keeps working for Sungkyung's existing authorized_keys entry.

2026-11-10 (implementation): Gate the whole redpanda-container module with the support switch. Evaluation showed that disabling it removes only the module's redpanda-container-init and redpanda-container-stop-agents activation steps and the com.shinzui.redpanda agent, and that no activation step in either state mentions purge or volume removal. Its CLIs (redpanda-up and the rest) leave with it, so a rollback re-enables the switch before running redpanda-up.

2026-11-10 (implementation): Set workstation.reiMori.projectOutcomeWrites on both hosts, so Yujin keeps Sungkyung's project-outcome setting when it becomes the owner. On a non-owner it only changes environment values of commands that are not run.


## Outcomes & Retrospective


(To be filled during implementation. No service has been stopped, database exported/imported, tunnel changed, or host activated by authoring this plan. The 2026-11-10 revision ran only read-only inspection on Sungkyung.)


## Context and Orientation


The repository root is /Users/shinzui/.config/dotfiles.nix on both machines. Full Nix configuration names are SungkyungM1X and yujin; computer names are sungkyung and yujin. A Nix build produces an installable generation; a switch activates it and can start services immediately. Run launchctl as the logged-in shinzui user in that machine's gui domain, not under sudo. Only the nix-darwin switch needs sudo. These user agents need a GUI login.

hosts/sungkyung/home.nix currently sets workstation.reiMori.enable = true. hosts/yujin/home.nix sets it false and adds sungkyung-client-tunnel plus a high-priority remote rei executable. That tunnel connects to Sungkyung at 100.66.155.64, using separate SSH keys for forwarding and Rei execution. It forwards a private PostgreSQL Unix socket, Mori 8780 to local 18780, and worker metrics 9091 to local 19091. Discover Yujin's actual tailnet address; do not reuse the source address. The same file also runs sungkyung-client-ingest, a ten-minute launch agent that calls bin/mori-client-ingest.py to record Yujin's local Git commits into Sungkyung's Mori database through that tunnel, so it is a database writer that the freeze must stop. It also re-exports the client endpoints from programs.zsh.envExtra because long-lived shells otherwise keep stale values.

home/rei-mori-runtime.nix disables mori-automate, mori-serve, mori-rei-app, rei-api, rei-worker, rei-worker-kiroku, rei-subscription, rei-worker-git-sync, rei-watchdog, notion-hub-subscription, mina-web, and reiko-web on inactive hosts. The legacy rei-subscription and rei-worker-git-sync are deliberately disabled even on the owner; keep them disabled. home/rei-doctor.nix prevents inactive-host healing. bin/check-rei-mori-owner.py checks declarations, not running generations or manual processes. bin/test-rei-mori-owner.py tests this guard.

home/postgresql.nix configures PostgreSQL 18, files at ~/.local/share/postgresql/data, and a socket at ~/.local/state/postgresql/.s.PGSQL.5432. TCP listening is disabled. Local authentication is trust, so socket forwarding conveys substantial database authority; keep the client socket inside an owned mode-0700 directory. The general PostgreSQL agent is independent of runtime ownership.

Today the backup agents are also independent of runtime ownership and enabled on every host. com.shinzui.pg-backup runs daily at 03:00 through pg-backup-scheduled, which takes a full backup when ~/.local/state/postgresql/last-full-backup is missing or older than 6.5 days and an incremental otherwise, then runs pg-backup-offsite-sync. com.shinzui.pg-backup-offsite-sync also fires on every volume mount. pg_rman is the physical backup tool: its catalog under ~/.local/share/postgresql/backups holds byte-level copies of one specific cluster, and it relies on WAL archives, PostgreSQL's write-ahead recovery records, under ~/.local/share/postgresql/archivelog. A catalog therefore cannot recover a different cluster, and Yujin's logically restored databases are a different cluster. Every pg-backup run also applies retention (seven days of WAL and three full generations), so leaving the schedule running on Sungkyung would age out the chain this plan freezes. The mirror /Volumes/aki-2023/postgresql-backups uses rsync --delete against the whole destination: two independent clusters must never share it, and nothing else may be nested under it. On 2026-11-10 Sungkyung's catalog was 19 GB, its WAL archive 6.7 GB, and its data directory 3.5 GB, with a validated full backup every Sunday. docs/pg-backup.md documents the commands.

home/rei.nix uses rei; home/mori.nix uses mori; home/mori-rei-app.nix uses mori_rei_app and also writes Rei; home/notion-hub.nix uses notion_hub. The bridge's database remembers processed webhook deliveries to prevent duplicates. Export entire databases, including events, projections (tables derived from events), subscription progress, queues, timers, migration ledgers, delivery ledgers, and permissions. Pending queue entries are data. Matching only event counts or maximum positions is insufficient.

Every service that depends on the shared server is one of the following. Rei's workers and API, mori-automate, and mori-serve connect directly. mori-rei-app connects to both mori_rei_app and rei. Mina and Reiko own no PostgreSQL database; mina web spawns mori and rei, reiko web spawns rei, and those child processes read MORI_PG_CONNECTION_STRING and REI_PG_CONNECTION_STRING from the launch agent's environment. Notion Hub (mori://shinzui/notion-hub, module home/notion-hub.nix) owns notion_hub, whose schemas are keiro, kiroku, message_store, pgmigrate, and public. Its worker is com.shinzui.notion-hub-subscription and its CLI nhub reads NOTION_HUB_PG_CONNECTION_STRING from the interactive shell. Before starting, the worker runs notion-hub-migrations verify, which reports applied, pending, and unknown counts. The managed wrapper nhub-migrate hard-codes the local production socket, so it cannot be pointed at a rehearsal cluster. Notion Hub's Notion API token is in ~/.config/nhub/config.kdl, and config/bootstrap/config-policy.json marks nhub and ntn private, owned by the private companion repository, so those files are provisioned through the bootstrap runbook rather than copied in the migration bundle.

The server is PostgreSQL 18, but home/default.nix installs postgresql_17 on PATH, so bare psql, pg_dump, pg_dumpall, pg_restore, initdb, and pg_ctl are version 17. pg_dump refuses to dump a server newer than itself, and a version-17 initdb creates a cluster the deployed server cannot open. Every export, restore, and rehearsal command in this plan therefore goes through the pg18 wrapper added in milestone 2. Read-only psql queries work with either version.

Measured on Sungkyung on 2026-11-10: the only roles beyond PostgreSQL's built-ins are the superuser shinzui and the login role message_store; the installed extensions are btree_gin, pgcrypto, and plpgsql; shared_preload_libraries is empty; and the configured databases total about 2 GB (mori 1427 MB, rei 513 MB, mori_rei_app 26 MB, notion_hub 13 MB). Treat these as starting points for milestone 1, not as its result.

config/xdg/rei/config.yaml points to /Users/shinzui/Keikaku/rei-workspace/. Transfer the actual workspace, attachments, Git history, and untracked/ignored durable files. A fresh clone lacks local commits, refs, and uncommitted work. Linked Git worktrees depend on a common Git directory; preserve those relationships for automation repositories. Inventory effective configuration rather than assuming every path uses its default.

home/mina.nix runs Mina at 127.0.0.1:8765; home/reiko.nix runs Reiko at 127.0.0.1:8770. Both spawn Rei; Mina also spawns Mori. Their launch-agent environments and PATH must work independently of interactive shells. Current Mina source stores tracking and Obeya data in ~/.local/share/mina/mina.db, subject to XDG_DATA_HOME and MINA_TRACKING_DB overrides. It uses SQLite WAL mode: committed data may still be in a journal beside the database, so copying mina.db alone can lose data. Include effective Mina global/project configuration and durable .mina contents. Current Reiko source keeps archive sidecars and state under ~/.local/share/reiko, subject to XDG_DATA_HOME and reikoDataDir in ~/.config/reiko/config.yaml. Verify these defaults against the deployed binaries. Mina creates the directory and database when they are missing, so an absent file produces a silently empty store instead of an error. ~/.mina and ~/.reiko hold only caches and logs on Sungkyung, and Mina's global configuration is a Home Manager link, so the durable Mina state there is the SQLite store plus any .mina contents inside repositories. reiko web turns a failed rei call into a warning and an empty list, as the comment in home/reiko.nix explains, so an empty collection page on Yujin is a failure signal and not evidence of an empty store.

home/local-web-proxy.nix runs Caddy as com.shinzui.local-web-proxy on port 80, currently independently enabled on both machines. It proxies named local tools. Mori 8780 and Rei API 8775 additionally require a loopback peer; these routes must remain private. Caddy's other routes reach the support services below and documentation dev servers on ports 5210 to 5221. After the move Sungkyung's forwards listen only on loopback, so other devices that reach these tools through a name encoding Sungkyung's LAN address must be repointed at Yujin, and a documentation dev server started on Sungkyung is no longer reachable through its named route because that route now resolves on Yujin.

The shared support services are the following, and every one is imported by home/default.nix on both machines with nothing gating it today. home/victorialogs.nix runs com.shinzui.victorialogs on port 9428, keeps data in ~/.local/share/victoria-logs/data with seven-day retention, and generates one com.shinzui.victorialogs-shipper-<app>-<stream> agent per log file. Each shipper waits for its file, then tails it with tail -n0 -F, so it ships only lines written after it starts, and posts each line to localhost:9428. The covered apps are rei-worker, rei-worker-git-sync, rei-subscription, mori-automate, mori-serve, mori-rei-app, notion-hub-subscription, and postgresql. home/victoriatraces.nix runs com.shinzui.victoriatraces on port 10428, with data in ~/.local/share/victoria-traces/data and seven-day retention, plus com.shinzui.victoriatraces-jaeger-ui, an nginx serving the Jaeger UI on 127.0.0.1:16686. Rei (home/rei.nix, in launch agents and the interactive shell) and Mina (home/mina.nix) export OpenTelemetry traces to http://localhost:10428/insert/opentelemetry. home/redpanda.nix turns on the redpanda-container Home Manager module from the redpanda-container flake input (registered in flake-modules/modules.nix; not in the Mori registry, so docs/redpanda.md is the reference). Its com.shinzui.redpanda agent is one-shot: it runs redpanda-up at login and exits. The broker and Console are Apple Container containers that keep running regardless of launchd, with Kafka on 127.0.0.1:9092, Admin API 9644, Schema Registry 8081, HTTP Proxy 8082, and Console 8080. Data lives in the container volume redpanda-0-data. redpanda-down stops the containers and keeps the data, redpanda-purge destroys it, and setting services.redpanda-container.enable = false keeps the volume. rpk comes from Homebrew, and its local profile points at 127.0.0.1. None of these services stores anything this migration must preserve, and none of them touches PostgreSQL except the postgresql log shipper, which only reads log files.

home/mori-rei-app.nix runs com.shinzui.mori-rei-app (mori://shinzui/mori-rei-app, pinned in flake.nix) as mori-rei-app serve. It listens on port 26862 and receives Mori's signed webhooks at the registered URL http://localhost:26862/webhook (app app_01knxf3p1aezarprphnkpgsqzj). Its wrapper waits for the agenix secret age.secrets.mori-rei-app-webhook-secret, then for PostgreSQL, and then runs createdb mori_rei_app, ignoring any error. That is a reason the bridge must not start on Yujin before the final restore: it would create an empty mori_rei_app that the restore's --create then collides with. It writes Rei through REI_PG_CONNECTION_STRING, keeps its idempotency ledger public.webhook_delivery and lifecycle audit in mori_rei_app, and batches commits through a pgmq queue drained hourly by default with a 300-second visibility timeout. It resolves each commit's repository through MORI_API_URL and reads plan documents from that project's checkout, falling back to the intention's local-repo property when the lookup fails. Its summariser shells out to the claude or codex CLI found on the agent's PATH (~/.local/bin, then /opt/homebrew/bin) using that CLI's own login, and quietly falls back to deterministic text when the CLI is missing. The upstream README describes current source, not the pinned revision, so milestone 1 confirms these against the deployed binary.

Relevant local ADRs are [shared host composition](../adr/1-shared-workstation-modules-and-host-overrides.md) and [private bootstrap/identity](../adr/2-selective-private-workstation-bootstrap.md). They require shared modules with explicit host differences, distinct machine identities, and independent proof of physical readiness. No existing ADR specifies database transfer. Follow [ownership guidance](../rei-mori-cutover.md), [bootstrap prerequisites](../new-machine-bootstrap.md), and [backup configuration](../pg-backup.md) until implementation updates them. The local Mori manifest declares no profiled ADR bundle; preserve the plain Markdown ADR convention.

Dependency discovery used the Mori registry for mori://shinzui/rei, mori://shinzui/mori, mori://shinzui/mina, and mori://shinzui/reiko. Canonical guides are mori://shinzui/mori/docs/user-guide, mori://shinzui/mori/docs/cli-spec, and mori://shinzui/rei/docs/cli-reference. Source evidence additionally comes from mori://shinzui/mina with project-relative mina-core/src/Mina/Tracking/Store.hs and mina-core/src/Mina/Obeya/Store.hs; mori://shinzui/reiko with reiko-core/src/Reiko/Config.hs; and mori://shinzui/mori with mori-cli/src/Mori/Command/Register.hs and mori-core/src/Mori/Host/Identity.hs (artifact-level URIs pending). The latter confirms mori register --path DIR uses the local machine's identity. Notion Hub evidence comes from mori://shinzui/notion-hub with project-relative notion-hub-config/src/NotionHub/Config/Runtime.hs and the notion-hub-core kiroku-subscription-runner directory (artifact-level URIs pending). Verify deployed commands/schemas: local corpus code can differ from installed versions.

Full database archives and separate globals exports were checked against official [pg_dump](https://www.postgresql.org/docs/18/app-pgdump.html), [pg_dumpall](https://www.postgresql.org/docs/18/app-pg-dumpall.html), and [pg_restore](https://www.postgresql.org/docs/18/app-pgrestore.html) references. SQLite's [backup API](https://www.sqlite.org/backup.html) provides the database snapshot, followed by [integrity/foreign-key checks](https://www.sqlite.org/pragma.html). Required operational instructions are embedded below.


## Plan of Work


The milestones below elaborate these data-safety invariants. If a step seems to need breaking one, stop and ask the user. Do not work around it.

1. Sungkyung's original data is never modified, apart from the recorded ALLOW_CONNECTIONS fence and Mina file-mode fence, both of which reverse. Nothing on Sungkyung is dropped, deleted, purged, reset, or overwritten during this plan: databases, data directories, the pg_rman catalog, WAL archive, Mina files, telemetry directories, or the Redpanda volume.
2. aki-2023 is attached to a machine only when that machine's backup agents cannot sync to the wrong directory. Yujin's agents must be stopped before the drive is next attached anywhere (milestone 1), and Yujin syncs only to the sibling path guarded by the cluster-identity marker (milestones 2 and 6).
3. The final export happens only after every writer is stopped, and it is accepted only when the before and after fingerprints match. If they differ, find the writer and repeat into a new bundle (milestone 4).
4. No service on Yujin may start against the restored data until the offline comparison of all four databases and Mina's store passes exactly (milestone 5). Background workers and mori-rei-app wait until Yujin's own first backup has been restored and matched (milestone 6).
5. Two complete, checksum-verified bundles exist before promotion, and one of them is outside both Macs' internal disks (milestone 4).
6. Restores go only into empty or quarantined targets. A failed restore is quarantined and retried elsewhere, never repeated over data.
7. Only one host owns the runtime and only one owns backups at any time, and the owner checker proves it at every revision.


### Milestone 1: Inventory the real state and implement evidence collection


Create docs/rei-mori-yujin-migration.md as the operator runbook and bin/rei-mori-migration.py as an evidence helper. Keep database contents, credentials, private inventories, and detailed evidence outside Git in mode-0700 directories. Public evidence contains only status, counts, timings, and redacted discrepancies. Do not print token environments, secret SQL rows, or credential-bearing process arguments.

On both physical Macs record hostname, architecture/login, active dotfiles revision/generation, lockfile digest, installed application versions, server/client PostgreSQL versions, socket/data directory, locales, extension versions, free disk space, and actual state paths. Preserve existing user edits, including flake.lock. Align the chosen deployed application/schema versions before the window without implicit upgrades. If new dependency bounds or compatibility work are needed, use Mori to locate source and verify released versions with authoritative registries and upstream tags first.

The helper must inventory all non-template databases, their owners/settings/encoding/locales, roles/memberships, tablespaces, extensions, migration ledgers, large objects, tables/partitions, sequences, and prepared transactions. Identify logical replication, database schedulers, and other writers that can continue without launchd. Any unclassified production store or autonomous writer blocks final export. The four configured databases are the minimum scope, not permission to ignore additional discovered coupled state.

Classify every database in the private manifest as migrated, retained-not-migrated, or blocker. The expected result is rei, mori, mori_rei_app, and notion_hub as migrated. The 14 rollout and scratch databases listed in Surprises & Discoveries are retained-not-migrated by the user's decision. Confirm no service depends on them by sampling xact_commit and xact_rollback from pg_stat_database twice, at least a day apart, and by checking pg_stat_activity and every launch agent's environment; a cumulative commit count alone says nothing about recent use. A service found using one of them is a blocker to bring to the user, not a reason to add that database to the bundle. Also inspect the postgres maintenance database for user-created objects.

For every selected database collect exact row counts and deterministic content digests of all non-system data, sequence last_value/is_called, schemas, large-object contents, and relevant metadata. One concrete digest method is COPY of canonical JSON rows ordered by their JSON representation, streamed through SHA-256 with fixed timezone/format settings and the same PostgreSQL build. Handle duplicates, bytea, empty tables, and partitions without double-counting. Quote identifiers with PostgreSQL format('%I', ...) and \gexec or an equivalent safe facility; never concatenate unchecked identifiers. Report unsupported objects and extension-owned tables omitted by pg_dump. Supply an owning export or demonstrate reconstructability for such state before proceeding.

Discover actual queue/checkpoint schemas from database catalogs and the deployed owning source. Preserve event IDs and stream membership/versions, durable subscription positions, failed deliveries, queues, leases, timers, outbox/inbox, webhook ledger, and migration history. Before startup these must compare exactly; afterward positions may advance. Inventory in-flight external work: let it finish safely or establish its durable retry/deduplication semantics. An external action with uncertain acknowledgement is a blocker until reconciled.

Inventory the Rei workspace, repository/worktree dependencies, local branches/changes, Mina SQLite overrides/configuration, Reiko state, source/destination path conflicts, secrets readability, and every ingress/automation/webhook route. Determine how to pause and resume each producer. Verify Yujin's tailnet address and SSH host fingerprints over a trusted channel; re-enroll renewable credentials using the bootstrap runbook. Never copy machine identity keys.

Inventory the support services on both machines: loaded labels, listening addresses for ports 80, 9428, 10428, 16686, 8080, 8081, 8082, 9092, and 9644, the size of each telemetry data directory, container ls output, and rpk topic list on Sungkyung, recorded privately so the topics left behind are known. Record which other local processes ever bind those ports on Sungkyung, such as a k3d cluster or a hand-started Kafka, because Sungkyung's support tunnel will need them free. For mori-rei-app, record the deployed revision on both machines. Confirm the deployed binary's port, environment variables, pgmq queue name and database, and summariser provider against its --help and source at that revision. Find which of claude and codex it will call, and check that the CLI is installed on Yujin's agent PATH and logged in, without printing credentials. Confirm that age.secrets.mori-rei-app-webhook-secret decrypts on Yujin by testing that the file is readable and non-empty. Do not print the secret. Record mori app list and the current mori app deliveries summary for app_01knxf3p1aezarprphnkpgsqzj. Confirm Yujin has checkouts, or a plan to create them, for every repository whose plan documents the bridge reads.

Inspect both machines' backup schedules and mounted external volumes immediately. On 2026-11-10, Yujin's backup agents were found loaded. Because the existing offsite path is shared by default, stop Yujin's backup agents first, with launchctl bootout gui/$(id -u)/com.shinzui.pg-backup-offsite-sync and the same for com.shinzui.pg-backup, before the drive is attached anywhere. Then locate aki-2023, attach it to one machine with neither sync able to run, and read its postgresql-backups directory: compare pg_rman.ini and the newest backup with Sungkyung's catalog and Yujin's to establish whose chain it holds and how old that chain is. If Yujin's agent overwrote it, record that plainly, because there has been no independent copy of Sungkyung's data since 2026-10-13. Preserve the directory either way and do not let another mirror run until distinct destinations and the guard from milestone 2 are active. If the drive cannot be found, stop and ask the user, since milestones 4 and 6 both need independent storage.

Resolve the Notion Hub crash loop before leaving this milestone. Use mori://shinzui/notion-hub to find the failing event through kiroku.subscriptions, kiroku.streams, and the worker log, determine why the projection inserts a second non-archived row for one notion_page_id, and repair it through that project's own ExecPlan and normal release path, then deploy the fixed revision to Sungkyung with the usual build and switch. Do not delete events, hand-edit tracked_pages, or advance a checkpoint from this plan. Done means launchctl print gui/$(id -u)/com.shinzui.notion-hub-subscription shows a running process whose runs count stops climbing, and the subscription's position in kiroku.subscriptions has caught up. Anything that moves the deployed Notion Hub schema must finish before the rehearsal, which needs a stable version.

Acceptance: a complete private transfer manifest, every database classified, no unclassified store, Notion Hub's worker running without restarts, aki-2023 located with its contents identified, Yujin's backup agents stopped, sufficient measured disk capacity (Yujin needs room for the restored databases, the WAL the restore generates, and the first full backup), exact source/destination versions, the support-service and mori-rei-app inventory above, and a list of writers/ingress/pending effects exist. The evidence helper detects a changed row with unchanged counts, sequence/checkpoint drift, and the wrong socket. Do not create an empty production store as an inventory fix.


### Milestone 2: Prepare staged ownership and reverse client configuration


Extend home/rei-mori-runtime.nix with workstation.reiMori.stage = "validation" | "active", default active. enable = false forces every owned agent off. On the enabled owner, validation permits only mori-serve, rei-api, mina-web, and reiko-web. It forces all automations, workers, integrations (mori-rei-app included), and healing off. Active preserves each module's existing enable value; never turn the two legacy workers back on. In home/rei-doctor.nix allow --heal and watchdog self-bootstrap only when enabled and active; stop the watchdog before other shutdown hooks.

Add the support-service switch. Create home/support-services.nix, imported by home/default.nix, declaring workstation.supportServices.enable (default true) and a read-only internal list of the agents it owns. It owns local-web-proxy, victorialogs, every generated victorialogs-shipper-* agent, victoriatraces, and victoriatraces-jaeger-ui. home/victorialogs.nix should export its shipper names rather than having them restated, so a new shipper cannot escape the switch. When the switch is false, force those agents off with lib.mkForce and set services.redpanda-container.enable to false. Do not remove the packages, so the CLIs and data stay. Removing a launch agent does not stop Redpanda's containers, which is why milestone 4 runs redpanda-down first. Before writing this, confirm through nix eval that services.redpanda-container.enable = false leaves the redpanda-0-data volume alone and runs no destructive activation. docs/redpanda.md says it does. If the deployed module disagrees, gate only the com.shinzui.redpanda agent instead. Leave Yujin's support services untouched by this revision: both hosts stay true in preparation.

Extend bin/check-rei-mori-owner.py and bin/test-rei-mori-owner.py to validate stage, support-service, and client tunnel placement. Reject dual owners, workers/healing during validation, runtime on an inactive host, a client tunnel on the owner, and a tunnel pointing to its own machine. Preserve --expect none for the stopped interval. Add an --expect-backups option taking a host name or none, reading services.postgresql.backups.enable from each host; reject two backup owners and any disagreement with the expectation. Add an --expect-support option taking both or a host name, reading workstation.supportServices.enable. Once it names one host, reject the other host's support services, and reject a support tunnel on a host that also runs them, since its forwards could never bind. Add tests for these hazards.

Extract hosts/yujin/home.nix's client logic into home/rei-mori-client.nix, imported by home/default.nix. Give it explicit enable, target, tunnelIdentityFile, reiIdentityFile, stateDirectory, forwardWebPort, and gitIngest options, and move the sungkyung-client-ingest agent and the programs.zsh.envExtra refresh into it so the reversed client keeps both. The ingest agent writes to the Mori store on the owner, so it must be off whenever the tunnel is. Reuse JSON/base64 argv encoding from bin/rei-ssh-dispatch.py; remove source-only wording and install the dispatcher at a stable managed path on the destination. The forced command must use Yujin's local managed Rei/environment and never resolve to another remote wrapper. Preserve argument boundaries, exit status, and interactive terminal behavior; reject malformed/non-string/NUL arguments without evaluating shell text.

Create dedicated Sungkyung-to-Yujin tunnel and Rei keys on Sungkyung and enroll only their public halves on Yujin. Review actual macOS authorized_keys/sshd policy; do not copy private keys. Disable agent/X11 forwarding, use verified known_hosts, BatchMode, StrictHostKeyChecking, IdentitiesOnly, ExitOnForwardFailure, and liveness probes. Preserve TTY permission only where needed for interactive Rei. TCP permitopen restrictions do not constrain arbitrary Unix socket paths; document this trusted same-user database access accurately. Verify available options against actual macOS SSH and the official [client](https://man.openbsd.org/ssh.1) and [server](https://man.openbsd.org/sshd.8) manuals.

Sungkyung's final tunnel forwards ~/.local/state/yujin-clients/postgresql/.s.PGSQL.5432 to Yujin's PostgreSQL socket. Forward local 18780 to destination 8780, 18775 to 8775, and 19091 to 9091, bound only to 127.0.0.1. Forward both 127.0.0.1:80 and [::1]:80 to Yujin 127.0.0.1:80; preflight both bind addresses after stopping source Caddy. Keep PostgreSQL off TCP and all new forward listeners off non-loopback interfaces. Ensure socket directories are owned and mode 0700.

Give home/rei-mori-client.nix a supportForwards option that runs a second agent, com.shinzui.yujin-support-tunnel, with the same SSH hardening and its own known_hosts check. It forwards 9428, 10428, 16686, 8080, 8081, 8082, 9092, and 9644 to the same port on Yujin's 127.0.0.1, binding each on both 127.0.0.1 and [::1] on Sungkyung, because OTEL_EXPORTER_OTLP_ENDPOINT and the shippers say localhost, which macOS may resolve to either. Same port numbers mean Sungkyung's OTEL settings, rpk profile, just recipes, and bookmarks need no change. Redpanda's broker advertises 127.0.0.1:9092, which a Sungkyung Kafka client then dials through the same forward. Confirm that with rpk in milestone 7 rather than assuming it. Port 80 stays on the database tunnel as already planned. A failure of the support tunnel must not affect the database tunnel. Add the forward targets to the tunnel key's authorized_keys permitopen list on Yujin.

Sungkyung's final shell sets MORI_PG_CONNECTION_STRING, REI_PG_CONNECTION_STRING, NOTION_HUB_PG_CONNECTION_STRING, and MORI_REI_APP_PG_CONNECTION_STRING to the forwarded private socket with their existing database names and user=shinzui connect_timeout=5, MORI_API_URL to http://127.0.0.1:18780, and KIROKU_REMOTE_URL to http://127.0.0.1:19091. home/notion-hub.nix and home/mori-rei-app.nix also set the first of those in shared session variables, so the client overrides need lib.mkForce as hosts/yujin/home.nix does today. Without the Notion Hub setting, nhub on Sungkyung would connect to the fenced local database. Managed wrappers such as nhub-migrate keep hard-coded local sockets and correctly fail against the fence. Other client endpoint overrides require discovering supported variables first. Yujin loses its old forward agent, its ingest agent, its high-priority remote Rei package, and its remote mkForce environment overrides; it returns to shared local settings. Use fresh shells after switching.

Do not access live SQLite across a network filesystem. Sungkyung's browser reaches Yujin's Mina database through the tunnel; mutable Mina/Reiko CLI operations run in an SSH shell on Yujin in the relevant repository. Document this explicitly so retained source SQLite/files are not used as a second active store. Milestone 1 records which deployed mina commands open the tracking store, so the runbook can name the ones that must run on Yujin; milestone 4's permission fence makes any that are missed fail visibly. Reiko has no comparable local store to fence, since it reads through rei.

Deliver preparation changes with Sungkyung still active and Yujin inactive, keeping the existing client direction until the maintenance window. Prepare reviewed stopped, Yujin-validation, and Yujin-active revisions without activating later stages. Reverse forwarding remains off until final restore passes. Test argv encoding with harmless fake executables and shell metacharacters. Build both physical host targets without switching ownership. Acceptance: preparation still declares Sungkyung sole owner; evaluation of validation permits exactly the four web/API runtime agents; tests reject premature workers; check-rei-mori-owner.py passes with --expect-backups SungkyungM1X --expect-support both; evaluation of the stopped revision shows Sungkyung with no support agents and services.redpanda-container disabled, while Yujin's are unchanged; both builds pass. Inspect generated configuration through Nix values, never by traversing /nix/store.

In this preparation revision, add backup ownership to home/postgresql.nix. Add services.postgresql.backups.enable, defaulting to false, gating the com.shinzui.pg-backup and com.shinzui.pg-backup-offsite-sync agents, and services.postgresql.backups.offsiteDirectory, defaulting to the existing /Volumes/aki-2023/postgresql-backups. Set enable true on Sungkyung and false on Yujin, and set Yujin's offsiteDirectory to /Volumes/aki-2023/postgresql-backups-yujin. That is a sibling of the old mirror, never a child, because rsync --delete on the old path would remove anything nested inside it. The general PostgreSQL agent stays enabled everywhere. Make pg-backup, pg-backup-offsite-sync, and pg-backup-purge exit with an explanatory error when the host is not the backup owner unless PG_BACKUP_ALLOW_INACTIVE=1 is set, following the --heal refusal in home/rei-doctor.nix. Add a pg18 wrapper that executes the named tool from the configured PostgreSQL 18 package, and leave postgresql_17 on PATH unchanged.

Add bin/pg-offsite-guard.py and call it from pg-backup-offsite-sync before rsync. It compares the source cluster's system identifier, read from pg_controldata, with a .postgresql-cluster-id marker in the destination. It creates the marker when the destination is missing or empty, passes when the marker matches, and refuses when the marker differs or when a non-empty destination has none. Add --exclude=/.postgresql-cluster-id to the rsync, since --delete would otherwise remove the marker. Give the guard an adopt subcommand for an operator who has already inspected an existing mirror; use it on Sungkyung's old path only if milestone 1 proved that mirror holds Sungkyung's chain.

The backup state changes with the reviewed revisions. Preparation has Sungkyung on and Yujin off. The stopped revision has both off. The Yujin-validation revision and every later one have Yujin on and Sungkyung off. Activate the preparation revision on Yujin as well as Sungkyung, which is safe because Yujin stays a runtime non-owner, so its backup agents are gone before anything else happens. Test the selected paths and the guard against temporary directories without running a real mirror.


### Milestone 3: Rehearse restoration in isolation


Take online rehearsal PostgreSQL exports and a Mina SQLite API backup. Label these REHEARSAL: snapshots of separate databases while writers run are not the final application-consistent bundle. On Yujin restore into a fresh private PostgreSQL cluster with its own directory/socket, TCP listening disabled, canonical database names, no workers, and no external ingress. Keep its normal production runtime disabled.

Review globals.sql privately and prepare reviewed-globals.sql with the required roles, memberships/settings, and valid tablespace paths. Compare existing bootstrap roles such as shinzui; do not apply an unfiltered globals file to an existing cluster or ignore all duplicate-role errors. Resolve conflicts explicitly without altering unrelated destination roles. Check extension libraries exist in the configured destination package and restore any special extension state using the owning procedure. Do not update an extension opportunistically.

Restore each archive with --create --exit-on-error, preserving owners, permissions, and database-level settings. Fingerprint the restored contents and compare them with a second isolated restore of the same archive. Source fingerprints taken while production is live are informative, not an exact snapshot reference; exact source-to-restored comparison is required during the final write freeze. Restore Mina into a separate SQLite file, run integrity_check and foreign_key_check, and compare schema/data. Stage workspace/repository/Reiko/Mina files privately and verify hashes, modes, symlinks, Git state, and worktree dependencies. Time export, transfer, import, and comparison to set the maintenance budget.

Include each service's specifics in the rehearsal. Confirm the restored notion_hub keeps its keiro, kiroku, message_store, pgmigrate, and public schemas and that the message_store role exists with its source attributes (it owns no object on the source; the rehearsal confirmed this). Count tracked_pages by status and compare kiroku.subscriptions positions and kiroku.dead_letters with the export. nhub-migrate cannot target this cluster, so compare the pgmigrate tables directly here and leave notion-hub-migrations verify for milestone 5. Restore Mina's backup and confirm the write-ahead content arrived by comparing row counts against an API backup taken on the source. Confirm the staged Reiko directory, including its currently empty archives directory, keeps its path and modes.

Also rehearse the backup move, because a backup is only proven by restoring it. In the isolated rehearsal cluster, initialize a scratch pg_rman catalog with its own WAL directory, take a full backup, and restore it with pg_rman restore --hard-copy into another empty directory. Start that copy with its own socket and with -c archive_mode=off and -c listen_addresses='', because the postgresql.conf copied by the backup carries an archive_command that would otherwise write into a production WAL directory. Compare its digests with the source of the backup and record the elapsed time; milestone 6 repeats this against Yujin's real catalog inside the maintenance window.

Never run production daemons or replay/reset commands against a rehearsal copy. Any CLI/API check that can migrate or write runs only in an isolated clone after inspecting its behavior and preventing external effects. Demonstrate a failed import remains isolated and can be retried into another empty target. Acceptance: all four databases restore with zero errors, repeat-restore fingerprints and SQLite checks pass, Notion Hub's schemas, positions, and dead letters match, files/Git state survive, a pg_rman backup of the rehearsal cluster was restored and matched its digests, and the time/space budget fits. Archive listings and transport checksums alone are insufficient.


### Milestone 4: Freeze writes, stop Sungkyung, and produce final exports


Notify the user in the current session that the maintenance window is beginning. Pause external webhook producers/routing and schedulers, close writer terminals/UIs on both machines including any running nhub sync, stop Yujin's com.shinzui.sungkyung-client-ingest agent and then its old tunnel, and block other known clients. Record each pause/resume action and pending-delivery handling. Pause backup/offsite jobs where necessary to prevent mutable catalogs and mirror races, preserving their previous state.

Wait for in-flight work to reach the safe points recorded in milestone 1. For mori-rei-app, that means mori app deliveries for app_01knxf3p1aezarprphnkpgsqzj shows nothing in flight, and the commit-batch queue depth and read counts have been recorded privately. Messages left in the queue are data and travel in the export. A message read but not yet deleted becomes visible again after its 300-second timeout, and the webhook_delivery ledger and Rei's idempotent request handling are what prevent a second action. Record which mechanism applies at the deployed revision. Do not drain or purge the queue by hand.

On Sungkyung run redpanda-down and confirm with container ls that the Redpanda containers have stopped. Never run redpanda-purge. Then switch Sungkyung to the reviewed both-off revision with all client tunnels off and workstation.supportServices.enable false, so Caddy, VictoriaLogs, its shippers, VictoriaTraces, and the Jaeger UI stop with the runtime. From here until milestone 7, VictoriaLogs on Sungkyung is gone, so read Sungkyung's service logs from their files (~/.rei/logs, ~/.mori/logs, ~/.mori-rei-app/logs, ~/.notion-hub/logs, ~/.local/state/postgresql/logs). Complete its Mori directory conversion in docs/new-machine-bootstrap.md before switching if needed. Verify watchdog shutdown first, every owned label and every support label unloaded, processes exited, and manual writers absent. Confirm that nothing on Sungkyung still listens on 80, 9428, 10428, 16686, 8080, 8081, 8082, 9092, or 9644, because milestone 7's forwards need those ports. Inspect pg_stat_activity and pg_prepared_xacts; investigate unexpected work rather than terminating unknown sessions.

Create the final immutable bundle: full PostgreSQL archives and globals, before/after database and filesystem fingerprints, SQLite backup, workspace/repository/state payloads, private manifest, and checksums. Require stable source contents across the entire export. If fingerprints differ, find the writer and repeat into a new bundle. Copy only manifest-selected paths; preserve modes/ownership/Git state; do not use rsync --delete against an existing home or checkout. Protect the bundle and transfer it over verified SSH. Independent storage must be encrypted at rest or hold an encrypted bundle addressed to verified recovery recipients; prove decryption without relying solely on Yujin's internal disk.

After the exports and the unchanged-state comparison, and before fencing, take Sungkyung's final physical backup with PG_BACKUP_ALLOW_INACTIVE=1 pg-backup full. Taking it before the fence keeps the fence out of the physical copy, and it covers the retained-not-migrated databases as well as the migrated ones. Confirm the newest pg-backup-show row is FULL and OK, then record that row privately as the frozen chain's end. If aki-2023 is attached to Sungkyung and milestone 1 proved the old mirror is Sungkyung's, run PG_BACKUP_ALLOW_INACTIVE=1 pg-backup-offsite-sync once. After this, no further pg-backup runs on Sungkyung.

After final exports and unchanged-state comparison, connect to the source postgres maintenance database and set ALLOW_CONNECTIONS false for each migrated source database. This fence blocks fresh connections even from stale worker generations. Existing sessions are not disconnected: require zero remaining sessions and investigate survivors. Prove new connections fail. Record original settings and reversal commands. Export before fencing so destination archives do not inherit disabled connections. Unrelated source databases remain available. PostgreSQL documents the setting in [ALTER DATABASE](https://www.postgresql.org/docs/18/sql-alterdatabase.html).

Fence Sungkyung's retained Mina store the same way after its SQLite backup is in the bundle. Remove write permission from mina.db, mina.db-wal, and mina.db-shm and from their directory, recording the original modes, and do not delete or rename any of them. Prove that opening the database for writing now fails. Mina recreates a missing file, so removal would be worse than leaving it. The mode reversal is the rollback.

Acceptance: both runtimes/clients are off, check-rei-mori-owner.py passes with --expect none --expect-backups none --expect-support yujin, Sungkyung's support agents and Redpanda containers are stopped with its telemetry directories and redpanda-0-data volume intact, final source comparisons match, each required payload exists, Sungkyung's final pg_rman full backup is valid and recorded, source migrated databases reject connections, Sungkyung's Mina store refuses writes, originals remain intact, and two independently stored complete final bundles have verified checksums. One copy must be outside both Macs' internal disks on independently protected storage. Missing or unverified recovery copies block promotion.


### Milestone 5: Restore final state and validate Yujin without workers


Keep Yujin's runtime, client, and scheduled backups disabled during import, so a 03:00 backup cannot run mid-restore. Preserve its existing conflicting databases/files even if believed empty, including any local ~/.local/share/mina/mina.db from earlier Mina CLI use. Rename conflicting databases to unique *_precutover_<tag> names with no connections, disable connections to these retained copies, and do not drop or merge them. If Yujin already has independent production writes, reconcile them before continuing. Restore final roles/settings and canonical database names using the rehearsed procedure.

Compare all four PostgreSQL stores and Mina SQLite before application startup: schemas, digests, sequence states, settings/owners/permissions/extensions, events/membership, checkpoints, queues, timers, ledgers, and large objects. Do not migrate or regenerate to conceal a discrepancy. Install staged filesystem state only after comparing destination conflicts. Prefer identical absolute paths; fix source-only volume references, symlinks, and linked worktrees before workers start. Confirm workspace Git root, attachments, repository checkouts, credential readability, Mina's tracking path, and Reiko's data path.

Keep or mint Yujin's own ~/.config/mori/host-id, protect it with restrictive permissions, and compare privately that it differs from Sungkyung. Do not restore source host-id, Tailscale identity, or SSH private keys. Establish Yujin's host-local repository locations with deployed mori register --path DIR, first proving in rehearsal that it preserves project/repository identities. Registration is a controlled new write after exact restore comparison; record its deltas. Do not re-observe historical Git or reset ingest positions. Verify mori path returns existing Yujin checkouts and all automations use available paths.

Verify Sungkyung remains stopped/fenced. Move any ~/.local/state/postgresql/last-full-backup on Yujin aside so the scheduler cannot pick an incremental as the first backup of the restored data, because that stamp's absence is what selects a full. Confirm ~/.config/nhub/config.kdl has been provisioned on Yujin through the bootstrap runbook. Then enable only Yujin at stage validation with services.postgresql.backups.enable true, and switch it. APIs, Mina, and Reiko may start. Caddy and the other support services are already running on Yujin. Background workers, the mori-rei-app bridge, the Notion consumer, and healing remain off. Before the restore, confirm Yujin has no mori_rei_app database (none existed on 2026-11-10). The bridge's wrapper creates an empty one whenever it starts, so if one exists, the bridge ran early, and that database is preserved as a conflict like any other. Confirm that Yujin's victorialogs-shipper agents are loaded for every runtime log file, so the first worker lines in milestone 7 are captured. Run nhub-migrate verify and expect pending=0 and unknown=0 before the worker is ever allowed to start. Keep ingress paused and avoid mutation-capable UI actions except controlled probes. Inspect actual launch-agent environments privately: spawned Rei/Mori must use Yujin's local socket and intended binaries. A startup migration or version/schema mismatch returns to isolated repair.

Acceptance: exact offline comparisons pass before controlled binding writes; source cannot connect; Yujin identity/paths are correct; only validation agents run; APIs are ready; and known source records appear in the UI without empty-list errors.


### Milestone 6: Move PostgreSQL backups to Yujin


Before any worker can cause an external effect, Yujin must be able to recover its own data. Because a pg_rman catalog is a byte-level copy of one cluster, moving backups does not mean copying files: Yujin starts a new recovery chain from a full backup of the restored data, takes over the daily schedule and the offsite mirror, and Sungkyung's chain stops changing and remains as the rollback copy.

Yujin is at stage validation and its backup agents were installed by that switch. Confirm archive_mode is on and wal_level is replica on Yujin's server, since pg_rman depends on them and home/postgresql.nix only appends them during activation; a change there needs a server restart. Run pg-backup full and confirm its validation passes and the newest pg-backup-show row is FULL and OK. Yujin's generations from before the restore age out through normal retention, so do not reset the catalog.

Prove the backup restores before relying on it. Run the isolated restore rehearsed in milestone 3 against Yujin's real catalog: run pg_rman validate on the catalog, then restore into an empty private directory with --hard-copy. Do not use --check here: it reads pg_control in the target directory and fails on an empty one. Start the copy with -c archive_mode=off, -c listen_addresses='', and its own socket, and compare its rei, mori, mori_rei_app, and notion_hub digests with the values recorded in milestone 5. Allow for the deltas from the controlled path-registration writes. Stop that copy and retain its directory until this milestone is accepted.

Attach aki-2023 to Yujin and run pg-backup-offsite-sync. It must create and fill /Volumes/aki-2023/postgresql-backups-yujin with its .postgresql-cluster-id marker, and must leave /Volumes/aki-2023/postgresql-backups untouched. Compare the old directory's listing and modification times before and after. Back up Mina's SQLite store with the API-backup procedure, the Rei workspace, and Reiko's data directory to a separate private directory on the same drive, because pg_rman protects none of them, and verify their checksums. There is no scheduled job for those three today on either machine; this plan proves one recovery copy and leaves a recurring schedule as a follow-up recorded in Outcomes & Retrospective.

Verify Sungkyung's side of the move. com.shinzui.pg-backup and com.shinzui.pg-backup-offsite-sync must be absent from launchctl list there, pg-backup without the override must refuse, and the newest pg-backup-show row must still be the frozen row recorded in milestone 4. Keep its 19 GB catalog and its WAL archive in place for the retention window, and do not run the reset procedure described in docs/pg-backup.md there.

Acceptance: Yujin's first full backup is valid and was actually restored with matching digests, check-rei-mori-owner.py passes with --expect-backups yujin, the new mirror exists with the correct marker and the old mirror is unchanged, non-database state has a verified copy, and Sungkyung's catalog is frozen and its schedule gone. If the drive is unavailable at this point, stop and ask the user before moving on, because the next milestone starts workers with no offsite copy.


### Milestone 7: Reverse client access and resume workers


Switch Sungkyung to inactive-runtime/reverse-client configuration. Verify source Caddy and old forward agents are absent, and Yujin has no sungkyung-client-tunnel, sungkyung-client-ingest, or remote Rei wrapper. Start Sungkyung's yujin-client-tunnel only; its git ingest agent starts with the tunnel, so confirm the first ingest run succeeds and writes only to Yujin's Mori store. Verify fresh shell settings, bound listener addresses, forwarded server/database identity, API readiness, browser routes, and encoded Rei execution. Tunnel failure must fail quickly without falling back to source databases.

Then start com.shinzui.yujin-support-tunnel and verify that it reaches Yujin's instances rather than anything left on Sungkyung. From Sungkyung, logs.localhost, traces.localhost, jaeger.localhost, and redpanda.localhost must show Yujin's data, and curl -fsS http://127.0.0.1:9428/health and the same on [::1] must succeed. Run one traced rei read command on Sungkyung, and find its trace in Yujin's VictoriaTraces by service name and time. A query against localhost:9428 from Sungkyung must return Yujin's recent mori-serve lines, and no line from Sungkyung's host. rpk cluster info on Sungkyung must report the same cluster ID as on Yujin, and rpk topic list must succeed, which proves the advertised broker address works through the forward. Stop the support tunnel once and confirm the database tunnel and the Rei, Mori, and Mina checks above are unaffected.

Open mina.localhost and reiko.localhost on both machines and inspect the same known tracking item/Obeya/collection/note. Test mori.localhost and rei.localhost readiness via both IPv4 and IPv6 loopback. A second peer's crafted Host-header request to Yujin must not bypass the private Mori/Rei route matchers. PostgreSQL must still have no TCP listener. The forwarded metrics port may be unavailable during validation; test it when the worker starts.

Confirm milestone 6's full backup is still the newest recovery point, taking another pg-backup full if any controlled write has happened since, then move Yujin to active while ingress remains paused. This is the external side-effect boundary: restored timers/queues/automations can execute immediately, before ingress reopens. Pending effects and webhook targets must already be reviewed. Watch subscription positions resume from saved values instead of zero. Keep legacy workers disabled. Verify bridge deduplication with a safely repeatable documented probe or isolated fixture; never blindly replay a real external effect.

Run a uniquely identified controlled Rei write using verified deployed CLI syntax. Observe it through both machines/UI and its expected worker/workspace effect once. Record generated IDs privately.

Acceptance: Sungkyung reaches Yujin's API, database, web routes, telemetry, and Redpanda only through its outgoing tunnels, and the support tunnel fails independently of the database tunnel; workers resumed from saved positions rather than zero; the controlled Rei write took effect exactly once; and ingress is still paused.


### Milestone 8: Prove Mina, Reiko, Notion Hub, and mori-rei-app on Yujin


Mina, Reiko, Notion Hub, and mori-rei-app each fail in ways that the general probes miss, so each gets its own proof while ingress is still paused.

For Mina, open mina.localhost on both machines. The project picker must list projects, which proves the spawned mori reached Yujin's database, and a known intention must open, which proves the spawned rei did. Inspect the same known tracking item and Obeya board from both browsers. Perform one normal Mina tracking/Obeya action and confirm it from both browsers against Yujin's single SQLite store. Then run a mina command that opens the tracking store on Sungkyung and confirm it fails against the permission fence rather than quietly writing locally.

For Reiko, open reiko.localhost on both machines and confirm a known collection and note appear. An empty list is a failure here, because Reiko reports a failed rei call that way. Validate a Reiko archive operation and confirm its sidecar appears under Yujin's ~/.local/share/reiko/archives, which was empty before this move. Record generated IDs privately.

For Notion Hub, compare nhub page list on Yujin and on Sungkyung through the tunnel with the frozen manifest's tracked_pages counts (12 active and 1 archived when last measured on 2026-11-10; use the manifest's figure). Run one controlled nhub page sync on a known harmless page, using deployed --help syntax, which contacts Notion and proves the provisioned token works on Yujin. Watch the worker's position in kiroku.subscriptions advance past its restored value with no growth in kiroku.dead_letters, and confirm launchctl print gui/$(id -u)/com.shinzui.notion-hub-subscription shows a running process whose runs count stops climbing. Run the status check twice several minutes apart so a crash loop cannot pass by timing.

For mori-rei-app, first confirm that launchctl print gui/$(id -u)/com.shinzui.mori-rei-app shows a running process whose runs count holds steady, that mori app list still shows http://localhost:26862/webhook and active, and that the bridge's stderr log shows no signature (401) failures. Any messages that were pending in the commit-batch queue at the freeze will drain at the next batch interval. Compare the Rei actions they produce against the milestone 4 queue record, and confirm that no commit already in webhook_delivery produced a second action. Then make one controlled commit carrying an Intention trailer for a harmless intention, in a repository registered on Yujin, chosen and recorded in the runbook beforehand. Let mori-automate ingest it, and confirm in mori app deliveries that exactly one delivery succeeded. After the next batch drain, confirm that exactly one Rei action was recorded with rei action list for that intention, using deployed --help syntax. The batch interval defaults to an hour: wait for it rather than changing COMMIT_BATCH_INTERVAL_SECONDS, which would be a configuration change mid-migration. Confirm from the bridge's log that the summariser used its CLI rather than the deterministic fallback, and that the commit's project resolved through Mori rather than through the local-repo fallback. Both fallbacks succeed quietly and would hide a missing login or checkout on Yujin. The bridge's lines must also appear in Yujin's VictoriaLogs under app:mori-rei-app.

Only then reopen ingress and verify one eligible normal automation produces its expected result once; inspect attempts/deliveries for duplicates.

Acceptance: known records appear and one controlled action works in each of Mina, Reiko, and Notion Hub from both machines, each with a single store on Yujin; Notion Hub's worker is stable and advancing; mori-rei-app turned one controlled commit into exactly one Rei action using its CLI summariser and Mori project lookup, and queue entries carried over from the freeze produced no duplicates; Sungkyung's local Mina store rejects writes; and ingress is open with its first automation delivered exactly once.


### Milestone 9: Prove durability and update the runbooks


Verify scheduled jobs fire on Yujin: the next com.shinzui.pg-backup run must pick incremental, validate, and sync. A missing external disk means no offsite copy, even if a sync command exits zero, because the script exits 0 when the volume is absent; check the log and the mirror's newest backup instead of the exit status.

Test tunnel recovery after stopping only its process, and login/restart persistence on both Macs. Confirm source fencing survives rebuilding/restarting and Yujin is still sole owner of both the runtime and backups. Prove the end state directly: on Sungkyung, launchctl list shows none of the agents in workstation.reiMori.agents, none of the support-service agents (local-web-proxy, victorialogs and its shippers, victoriatraces, victoriatraces-jaeger-ui, redpanda), and neither pg-backup nor pg-backup-offsite-sync, container ls shows no Redpanda containers after a restart, and pg_stat_activity on its local cluster shows no client sessions beyond the inspecting psql. Retain old data, Sungkyung's frozen catalog, and immutable bundles at least 14 days and until scheduled backups plus recovery proof succeed. Retirement, including stopping Sungkyung's PostgreSQL server and deciding what to do with its retained scratch databases, telemetry directories, and redpanda-0-data volume, is a separate deliberate action; do not delete old copies automatically.

Update docs/rei-mori-cutover.md, docs/local-services.md (including the LAN-name guidance now tied to Yujin's address, the support-service switch, and the support tunnel), docs/redpanda.md (the cluster now lives on Yujin and Sungkyung reaches it through forwards), docs/pg-backup.md (backup ownership, the Yujin mirror path, the guard, and the frozen Sungkyung chain), and bootstrap references. Add a plain Markdown ADR for staged ownership, database fencing, and isolated backup namespaces.

Acceptance: Yujin works independently as primary for every PostgreSQL-dependent service, for backups, and for the support services; Sungkyung reaches the same live records through its outgoing tunnel and runs none of those services; controlled writes/effects occur once; reconnect/restart preserves roles; and database plus non-database recovery is proven.


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

On Yujin, before aki-2023 is attached anywhere, stop the backup agents found loaded on 2026-11-10. bootout removes them only until the next switch. The preparation revision in milestone 2 is what keeps them off.

```bash
launchctl bootout "gui/$(id -u)/com.shinzui.pg-backup-offsite-sync"
launchctl bootout "gui/$(id -u)/com.shinzui.pg-backup"
launchctl list | grep -E 'pg-backup' || echo 'no pg-backup agents loaded'
```

Expect the final line to read no pg-backup agents loaded.

Support-service and bridge inventory on each Mac, read-only:

```bash
launchctl list | grep -E 'local-web-proxy|victoria|redpanda|mori-rei-app'
lsof -nP -iTCP -sTCP:LISTEN | grep -E ':(80|8080|8081|8082|9092|9428|9644|10428|16686|26862) '
/usr/bin/du -sh ~/.local/share/victoria-logs/data ~/.local/share/victoria-traces/data
container ls --all
/opt/homebrew/bin/rpk topic list
mori app list
mori app deliveries app_01knxf3p1aezarprphnkpgsqzj
```

Use /usr/bin/du because du on PATH is another tool. mori app commands go to whichever machine's Mori the shell points at, so run them on Sungkyung, or note which machine answered. Record the output privately.

If clients are absent, obtain the configured PostgreSQL package through the flake's package/development environment; never search /nix/store or update PostgreSQL as a shortcut. Missing configured databases must be investigated, not created as empty replacements. Capture detailed output privately. These read-only commands may use the version-17 psql on PATH; expect the pg_dump --version line to differ from SHOW server_version, which is why every command below that exports, restores, or creates a cluster uses the pg18 wrapper from milestone 2.

After implementing preparation, run focused tests and builds from the root:

```bash
python3 bin/test-rei-mori-owner.py
python3 bin/test-rei-mori-migration.py
python3 bin/test-rei-ssh-dispatch.py
python3 bin/test-pg-offsite-guard.py
python3 bin/check-rei-mori-owner.py --expect SungkyungM1X --expect-backups SungkyungM1X --expect-support both
./bin/build.sh SungkyungM1X --out-link result-sungkyung
./bin/build.sh yujin --out-link result-yujin
```

The migration, SSH, and offsite-guard test files are proposed deliverables. Expected results are passing tests, the correct sole owner, and successful builds. At the stopped revision use --expect none --expect-backups none --expect-support yujin, and at validation and active revisions use --expect yujin --expect-backups yujin --expect-support yujin. Record exact revision/stage and preserve unrelated user changes.

The activation wrapper uses ./result. Do not activate after only a custom-output-link build. On the matching physical machine, build that reviewed revision into ./result immediately before switching:

```bash
# On Sungkyung for its reviewed stopped or later client revision:
./bin/build.sh SungkyungM1X
sudo ./bin/darwin-rebuild.sh SungkyungM1X

# On Yujin for the preparation revision (its runtime stays off), and then,
# only after final restoration, for validation and then active:
./bin/build.sh yujin
sudo ./bin/darwin-rebuild.sh yujin
```

Set up the isolated rehearsal on Yujin using the same PostgreSQL build:

```bash
umask 077
export REHEARSAL_ROOT="$HOME/.local/state/rei-mori-rehearsal-<unique-tag>"
mkdir -m 700 "$REHEARSAL_ROOT"
mkdir -m 700 "$REHEARSAL_ROOT/socket"
pg18 initdb --auth=trust --no-locale --encoding=UTF8 -D "$REHEARSAL_ROOT/data"
pg18 pg_ctl -D "$REHEARSAL_ROOT/data" -l "$REHEARSAL_ROOT/server.log" \
  -o "-k $REHEARSAL_ROOT/socket -c listen_addresses=''" -w start
```

Restore canonical database names into this separate cluster with the commands below, after reviewed role/extension preparation. Stop it with pg18 pg_ctl -D "$REHEARSAL_ROOT/data" -m fast -w stop. Retain its files until accepted. A startup failure is never permission to fall back to the production socket.

On Sungkyung, after the live freeze gate, create a unique final bundle. The following is a command template; wrap it in fail-fast shell settings in the operator script and record completion only after all evidence passes:

```bash
set -euo pipefail
umask 077
export MIGRATION_ROOT="$HOME/.local/state/rei-mori-move-<unique-tag>"
mkdir -m 700 "$MIGRATION_ROOT"
export MIGRATION_SOCKET="$HOME/.local/state/postgresql"

pg18 pg_dumpall -h "$MIGRATION_SOCKET" -p 5432 -U shinzui --globals-only \
  --file="$MIGRATION_ROOT/globals.sql"

for db in rei mori mori_rei_app notion_hub; do
  pg18 pg_dump -h "$MIGRATION_SOCKET" -p 5432 -U shinzui \
    --format=custom --verbose --file="$MIGRATION_ROOT/$db.dump" "$db" \
    2>"$MIGRATION_ROOT/$db.dump.log"
  pg18 pg_restore --list "$MIGRATION_ROOT/$db.dump" >"$MIGRATION_ROOT/$db.contents.txt"
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

Take Sungkyung's final physical backup after the exports compare clean and before fencing. The override is required because the stopped revision has already made this host a non-owner:

```bash
PG_BACKUP_ALLOW_INACTIVE=1 pg-backup full
pg-backup-show | head -5
```

Expect the newest row to read FULL and end in OK, in the form below. Record that row privately as the end of the frozen chain.

```text
2026-11-08 03:00:05  2026-11-08 03:01:08  FULL  3027MB     1  OK
```

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
pg18 psql -X -v ON_ERROR_STOP=1 -h "$RESTORE_SOCKET" -p 5432 -U shinzui -d postgres \
  -f "$RESTORE_ROOT/reviewed-globals.sql"
for db in rei mori mori_rei_app notion_hub; do
  pg18 pg_restore -h "$RESTORE_SOCKET" -p 5432 -U shinzui --dbname=postgres \
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

On Sungkyung, before the stopped switch in milestone 4, stop Redpanda without touching its data, then confirm after the switch that every support port is free:

```bash
redpanda-down
container ls --all | grep -i redpanda || echo 'no redpanda containers'
lsof -nP -iTCP -sTCP:LISTEN | grep -E ':(80|8080|8081|8082|9092|9428|9644|10428|16686) ' || echo 'support ports free'
```

Stopped containers may still be listed by container ls --all. What matters is that none is running, and that the redpanda-0-data volume still appears in container volume ls (confirm that subcommand against the deployed container --help).

On Sungkyung, after the support tunnel starts in milestone 7:

```bash
curl -4 -fsS http://127.0.0.1:9428/health
curl -6 -fsS 'http://[::1]:9428/health'
curl -4 -fsS http://127.0.0.1:10428/health
curl -fsS http://jaeger.localhost/ >/dev/null
/opt/homebrew/bin/rpk cluster info
/opt/homebrew/bin/rpk topic list
```

Compare the cluster ID from rpk cluster info with the same command run on Yujin. Confirm VictoriaTraces' health path against its deployed --help. If it differs, use its VMUI at /select/vmui/.

From another peer request Yujin port 80 with Host: mori.localhost and Host: rei.localhost; Caddy's local-only matcher should return 404. A firewall denial is private but does not itself test the matcher. Do not open public access just for this check.

Milestone 6 takes the backups over on Yujin, at stage validation, as shinzui:

```bash
pg18 psql -X -h "$HOME/.local/state/postgresql" -d postgres -c 'SHOW archive_mode;' -c 'SHOW wal_level;'
pg-backup full
pg-backup-show | head -5

umask 077
export RESTORE_PROOF="$HOME/.local/state/pg-backup-restore-proof-<unique-tag>"
mkdir -m 700 "$RESTORE_PROOF" "$RESTORE_PROOF/data" "$RESTORE_PROOF/socket"
pg_rman validate -B "$HOME/.local/share/postgresql/backups"
pg_rman restore -B "$HOME/.local/share/postgresql/backups" \
  -D "$RESTORE_PROOF/data" -A "$HOME/.local/share/postgresql/archivelog" --hard-copy
pg18 pg_ctl -D "$RESTORE_PROOF/data" -l "$RESTORE_PROOF/server.log" \
  -o "-k $RESTORE_PROOF/socket -c listen_addresses='' -c archive_mode=off" -w start
```

Expect on and replica from the first command and a FULL row ending in OK from pg-backup-show. Run the evidence helper's fingerprint against the socket in $RESTORE_PROOF, then stop the copy with pg18 pg_ctl -D "$RESTORE_PROOF/data" -m fast -w stop. These options were confirmed in the milestone 3 rehearsal against pg_rman 1.3.19. A validate or restore that reports an error stops this step, and the step never falls back to the production data directory. pg_rman writes pg_rman_recovery.conf into the copy with a restore_command that only reads the archive directory.

With aki-2023 attached to Yujin:

```bash
/usr/bin/stat -f '%m %N' /Volumes/aki-2023/postgresql-backups/pg_rman.ini
pg-backup-offsite-sync
cat /Volumes/aki-2023/postgresql-backups-yujin/.postgresql-cluster-id
/usr/bin/stat -f '%m %N' /Volumes/aki-2023/postgresql-backups/pg_rman.ini
```

Expect "offsite sync to /Volumes/aki-2023/postgresql-backups-yujin" and "Offsite sync complete." from the sync, a marker equal to Yujin's own system identifier, and identical modification times for the old mirror before and after. "not mounted; skipping offsite sync" means the copy did not happen even though the command exits zero.

Notion Hub and worker checks during milestone 8 use the deployed commands below. Compare the counts with the frozen manifest.

```bash
nhub page list
launchctl print "gui/$(id -u)/com.shinzui.notion-hub-subscription" | grep -E 'state =|runs =|last exit'
pg18 psql -X -h "$HOME/.local/state/postgresql" -d notion_hub \
  -c 'SELECT status, count(*) FROM tracked_pages GROUP BY status;' \
  -c 'SELECT count(*) FROM kiroku.dead_letters;'
```

Record exact controlled-write CLI syntax from deployed --help and the selected harmless records in the private operator runbook before running probes. Required outcomes are described in milestone 6. Do not invent write commands from memory.


## Validation and Acceptance


Preparation must retain Sungkyung as sole owner. Both-off must prove labels and manual writers stopped. Final exports must be stable across before/after data fingerprints and independently stored/restorable. Before startup, restored data must match schemas, digests, sequence state, ownership/settings/extensions, complete event history/membership, checkpoints, queues/timers, delivery ledgers, and SQLite integrity. Filesystem/Git manifests must match durable content.

Prove known Rei/Mina/Reiko content appears on Yujin, new controlled writes appear from both machines, and resumed automation has its expected effect once. Prove source database refusal separately from the declaration check. Verify listener addresses, IPv4/IPv6 routes, tunnel reconnect and failure without fallback, role persistence after physical restart, and recoverability of Yujin database plus non-database backups.

bin/test-rei-mori-migration.py must cover corrupted/missing payloads, same-count changed content, sequence drift, duplicate rows, partitions, large objects, wrong sockets, destination conflicts, and incomplete/interrupted bundles. bin/test-rei-ssh-dispatch.py must cover malformed payloads and shell metacharacters using harmless fixtures. Ownership tests must reject workers/healing in validation, dual owners, dual backup owners, a wrong --expect-backups value, support services on both hosts once --expect-support names one, a support tunnel on a host that runs the support services, a victorialogs shipper that escapes the support switch, and a tunnel on the owner. bin/test-pg-offsite-guard.py must cover a missing destination, an empty destination, a matching marker, a mismatched marker, a non-empty destination with no marker, and adoption. These checks protect data-loss and split-ownership hazards.

The end state is observable on both machines. On Yujin every PostgreSQL-dependent agent, both backup agents, and every support-service agent are loaded, Redpanda's containers run, and rei-doctor reports a healthy pipeline. On Sungkyung none of those agents is loaded, no Redpanda container runs, a trace emitted there appears in Yujin's VictoriaTraces, the forwarded socket reaches Yujin (SELECT system_identifier FROM pg_control_system() returns Yujin's value), and the local cluster has no client sessions. A Notion Hub worker that restarts repeatedly, an empty Reiko collection, a Mina project picker with no projects, or a mori-rei-app delivery recorded with the summariser or Mori-lookup fallback each means the corresponding service has not moved, whatever its launch agent reports.

If a physical machine, ingress control, credential, or independent storage is unavailable, record the precise unfinished milestone. A Nix build, loaded label, transport checksum, or HTTP status alone never establishes migration completion.


## Idempotence and Recovery


Use unique directories and explicit cluster/machine identities for every attempt. Inventory/comparison is repeatable. Restore only into empty or quarantined targets; retain failures and the last good bundle. Never discard a live SQLite WAL file or reset/replay ledgers to conceal mismatches.

If preparation/rehearsal fails, keep Sungkyung active and Yujin inactive. If final transfer/import fails, keep both stopped while repairing, or use pre-write rollback. Never activate a source owner generation while Yujin is live.

Before Yujin has made any new database/file write, stop/disable destination runtime and client access, verify no sessions/workers remain, and fence its production databases. Only then restore source ALLOW_CONNECTIONS settings from postgres, select Sungkyung sole owner, and activate it. Restore old Yujin-to-Sungkyung client access from its preserved configuration if needed. Resume source backup schedules only against its own catalog/mirror.

Once Yujin has registered paths, run a controlled write, applied a startup migration, or started workers, treat its state as newer even if ingress is paused. Pause ingress, stop Yujin writers, take a fresh consistent database/file bundle and external-effect inventory, fence Yujin, and restore/compare newer state back to Sungkyung through the same tested process before reactivation. Reconcile effects already performed so restored queues do not repeat them. If correctness cannot be established, keep both stopped and repair Yujin instead of reopening the old snapshot.

Backups roll back with the data. Sungkyung's frozen catalog, its WAL archive, and the old mirror directory stay untouched during this plan, so a rollback before Yujin takes writes needs only to restore source ALLOW_CONNECTIONS settings, restore the recorded Mina file modes, and activate a revision that sets services.postgresql.backups.enable true on Sungkyung and false on Yujin. Yujin's catalog and mirror remain for later use. Never let both hosts hold the backup flag, and never point one host's offsiteDirectory at the other's. A failed pg-backup full on Yujin is safe to rerun, and a failed restore proof leaves only its private directory. Delete that directory only after recording why it failed, and never restore into the production data directory.

Support services roll back separately from the data and never drive a data rollback. To give Sungkyung its own support services back, stop com.shinzui.yujin-support-tunnel first, because its forwards hold the ports. Then activate a revision with workstation.supportServices.enable true on Sungkyung, and run redpanda-up, which restarts the cluster from the retained redpanda-0-data volume. Sungkyung's telemetry directories are untouched, so its VictoriaLogs and VictoriaTraces resume with their old history, minus whatever the seven-day retention has aged out. Yujin's support services never stop, so a rollback of the runtime does not need them changed. Re-enable Sungkyung's support switch only together with the runtime rollback, or the port-80 forward and Sungkyung's Caddy contend for the port.

Fencing blocks new connections but does not end existing ones. Nix generation rollback does not undo database settings, data writes, or external effects. Retain source originals and protected bundles for the retention window; retirement requires a separate deliberate action after recovery conditions pass.


## Interfaces and Dependencies


workstation.reiMori.enable remains the ownership interface, supplemented by stage = "validation" | "active". Disabled means no owned agents. Validation permits the four named web/API agents only (mori-serve, rei-api, mina-web, reiko-web). Active preserves original service enables; healing requires enabled + active. Bootstrap-arm remains unchanged.

home/support-services.nix exposes workstation.supportServices.enable (default true) and a read-only list of the agents it owns: local-web-proxy, victorialogs, every victorialogs-shipper-* agent as exported by home/victorialogs.nix, victoriatraces, and victoriatraces-jaeger-ui. False forces those agents off and disables services.redpanda-container while keeping packages, data directories, and the Redpanda volume. It is independent of workstation.reiMori and never enables or disables a runtime agent. bin/check-rei-mori-owner.py gains --expect-support both|<host>.

home/rei-mori-client.nix exposes explicit enable, target, tunnelIdentityFile, reiIdentityFile, stateDirectory, forwardWebPort, gitIngest, and supportForwards options. supportForwards runs com.shinzui.yujin-support-tunnel, a separate SSH agent forwarding 9428, 10428, 16686, 8080, 8081, 8082, 9092, and 9644 on both loopback addresses to the same ports on the target's 127.0.0.1. Client enablement or restoration must never implicitly enable a runtime. Final Sungkyung uses this interface and final Yujin disables it. Two loopback port-80 listeners reach Yujin Caddy, private high-port forwards reach API/metrics, and a private Unix socket supports PostgreSQL clients.

The proposed bin/rei-mori-migration.py provides inventory, fingerprint, manifest, and verify-bundle subcommands with required explicit --socket and/or --root plus a machine role for database evidence operations. Define --help, nonzero failure statuses, immutable complete/incomplete bundle markers, and redacted terminal summaries. Use Python's standard library and installed PostgreSQL clients with argument arrays. The helper collects/verifies evidence only; it never stops services, changes schemas, restores databases, overwrites targets, or opens ingress. No new runtime dependency is needed.

home/postgresql.nix gains services.postgresql.backups.enable (default false; the host that owns scheduled backups) and services.postgresql.backups.offsiteDirectory (default /Volumes/aki-2023/postgresql-backups; Yujin sets the sibling /Volumes/aki-2023/postgresql-backups-yujin, never a child path). It also adds the pg18 command, which runs a named tool from the configured PostgreSQL 18 package as pg18 pg_dump and so on. pg-backup, pg-backup-offsite-sync, and pg-backup-purge refuse on a non-owner unless PG_BACKUP_ALLOW_INACTIVE=1 is set. bin/pg-offsite-guard.py checks the destination's .postgresql-cluster-id against the source cluster and has an adopt subcommand; it never deletes or rewrites catalog files. bin/check-rei-mori-owner.py gains --expect-backups. SQLite and files need separate protection. Retain selected deployed application/PostgreSQL versions; dependency/schema upgrades are separate reviewed work.

Record later provenance revisions through agents/skills/exec-plan/record-provenance.ts using verified runtime identity. Commit on the current branch with Conventional Commits and ExecPlan: docs/plans/8-move-the-primary-rei-and-mori-runtime-from-sungkyung-to-yujin.md. No Intention ID was supplied. Durable cross-repository references must use canonical mori:// URIs; repository-local paths may remain relative.


Created 2026-10-16: grounded six migration milestones in existing ownership, four configured PostgreSQL stores, Mina SQLite, Reiko sidecars, reversed client access, and distinct machine identities. All live inventory and migration actions remain future work.

Revised 2026-11-10: at the user's request the plan was reviewed and expanded so that every service using PostgreSQL ends up on Yujin, explicitly covering Mina, Reiko, and Notion Hub, and so that the PostgreSQL backups move too. The title now states that scope, while the path, slug, and id are unchanged. Milestone 6 is new and moves backups; the former milestone 6 is split into milestones 7 (client reversal and workers), 8 (Mina, Reiko, Notion Hub, and reopening ingress), and 9 (durability and docs). The review, which used the working tree plus read-only inspection of Sungkyung, also corrected defects in the earlier revision: the Yujin offsite path nested inside a directory mirrored with rsync --delete; PostgreSQL 17 tools used against an 18 server; the omitted sungkyung-client-ingest writer; missing Notion Hub and mori-rei-app client settings; no treatment of the 14 extra databases; and no plan for Notion Hub's existing crash loop or the stale offsite mirror. These are recorded in Surprises & Discoveries and the Decision Log. Yujin was not inspected, so its databases, backup catalog, and drive history remain milestone 1 unknowns.

Revised 2026-11-10: the user confirmed the 14 rollout and scratch databases stay on Sungkyung, so milestone 1 now only checks that no service depends on them.

Revised 2026-11-10 (implementation): milestone 6's restore proof replaces pg_rman restore --check, which the rehearsal showed cannot check an empty target, with pg_rman validate. The notion_hub rehearsal check now expects message_store to exist rather than to own objects.

Revised 2026-11-10: recorded the deployed Notion Hub fix and the refreshed, verified offsite mirror, which closes those two milestone 1 items.

Revised 2026-11-10: at the user's request, the scope now includes the shared support services (Caddy, VictoriaLogs with its shippers, VictoriaTraces with its Jaeger UI, and Redpanda) and gives mori-rei-app its own proof in milestone 8. The support services get a separate switch, workstation.supportServices.enable, instead of joining the runtime agents. They stop on Sungkyung in the stopped revision, Sungkyung reaches Yujin's instances through a second SSH agent on the same port numbers, and no support step touches PostgreSQL data. Telemetry history and Redpanda topics are not carried over, by user decision. Because the user stressed not losing the PostgreSQL data, this revision also adds a list of data-safety invariants at the start of Plan of Work. It records a read-only check of Yujin that found its backup agents loaded, the drive's most immediate hazard, now its own first step, as well as two Yujin scratch databases and a Yujin mina.db that the restore must preserve.
