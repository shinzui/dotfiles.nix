# Rei and Mori host ownership

Sungkyung is the sole active runtime host for `mori://shinzui/rei` and
`mori://shinzui/mori`. Yujin is a prepared destination until an explicit cutover.
A successful Yujin bootstrap or full switch does not authorize starting this
runtime on a second machine. Do not perform the migration during initial setup.

| Full host | `workstation.reiMori.enable` | Current role |
| --- | --- | --- |
| `SungkyungM1X` | `true` | Active, authoritative databases and application state |
| `yujin` | `false` | Prepare the workstation with the runtime stopped |

The host settings are in `hosts/sungkyung/home.nix` and `hosts/yujin/home.nix`.
The shared [runtime profile](../home/rei-mori-runtime.nix) defaults to disabled,
so a future host must be explicitly chosen as the runtime owner. It disables
Mori's daemon and API, Rei's workers/API/subscriptions/watchdog, the webhook
bridge, Notion Hub subscription, and the Mina/Reiko web integrations together.
Legacy Rei subscriptions and git-sync remain disabled on the active host, as
before. General PostgreSQL, other local services, packages, completions, and
configuration files can be installed on the prepared machine.

The watchdog cannot self-bootstrap on an inactive host, and `rei-doctor --heal`
refuses there. During an inactive-host switch, healing is stopped before the
application stop hooks. Do not manually run these servers, workers, automations,
healing commands, or mutating application CLIs on Yujin before cutover. Installed
binaries and available secrets are preparation, not permission to use a second
live runtime. The profile is not a distributed lock and cannot fence a stale
Sungkyung generation or an independently launched process.

## Preparation now

Keep both host flags as shown above. Complete Yujin's workstation prerequisites,
minimal/full activation, token handoff, application access, repositories, and
infrastructure readiness using the [new-machine runbook](new-machine-bootstrap.md).
Keep source application data authoritative on Sungkyung. Do not initialize a
second production event store or run automatic migrations, consumers, registry
restoration, or replay on Yujin as a bootstrap check.

```bash
python3 ./bin/check-rei-mori-owner.py --expect SungkyungM1X
```

This read-only check evaluates the declared flags, detects multiple declared
owners, and rejects runtime agents or watchdog self-healing on an inactive host.
It does not inspect either machine's running generation or prove that manual
processes are absent. Builds and evaluation checks do not stop Sungkyung.

## Cutover later: stop, transfer, then start

Schedule this separately when Yujin is ready. Preserve recoverable backups and
record private checkpoints. Resolve the exact database/state transfer procedure
against the owning projects' recovery instructions before the maintenance window;
consult `mori://shinzui/mori/docs/user-guide` and
`mori://shinzui/rei/docs/quickstart` and the [local database guide](local-services.md).
Do not improvise replay, reset subscription offsets, upgrade schemas, or copy
PostgreSQL's live data directory between machines.

1. Pause incoming writes and external webhook/automation routing. Close manual
   Rei/Mori writers and UI clients on Sungkyung. Stop the healing watchdog first.
   Change Sungkyung's host flag to `false`, keeping Yujin `false`, and publish that
   stopped configuration. Run `check-rei-mori-owner.py --expect none`.
2. Build and switch **Sungkyung** to that configuration. Complete its
   [Mori directory migration](new-machine-bootstrap.md#source-machine-mori-migration)
   before this switch if the old whole-directory link remains. Verify the
   watchdog and every runtime/integration launchd label are unloaded and all
   corresponding processes and manual writers have exited. Wait for the owning
   projects' drain/checkpoint requirements. A disabled flag in Git is insufficient.
3. Take final application-consistent backups after writes have stopped. Restore
   the required event stores, operational databases, registry/project bindings,
   application state, credentials, and repository checkouts on Yujin using the
   reviewed recovery procedure. Keep Yujin's runtime disabled during restoration
   and offline verification. Include the webhook bridge's operational state and
   the integrated subscription state. Keep Yujin's new machine identity; do not
   transplant Sungkyung's Mori host ID. Retain original data and backups.
4. Verify Sungkyung is still stopped. Change only Yujin's host flag to `true`,
   retaining Sungkyung `false`, publish, and check `--expect yujin`. Build and
   switch Yujin. Confirm services, private read/write probes, API readiness,
   subscription checkpoints, routing, and external consumers before reopening
   ingress. Check Sungkyung remains stopped after login/reboot and that Yujin is
   the only live runtime host.

The two stages deliberately allow a period with neither host active. Never set
both flags to `true` or enable Yujin before Sungkyung's live shutdown is verified.
No cutover, data movement, shutdown, or activation is performed by the ownership
checker. Future host changes need the same live verification.

## Rollback after cutover

Pause writes and stop/fence Yujin first. If Yujin has accepted writes, reconcile
or transfer its newer state through the owning recovery procedure before
reactivating Sungkyung. Verify Yujin's workers, APIs, bridge, integrations, and
watchdog are stopped. Only then enable and switch Sungkyung, with Yujin disabled.
Never roll Sungkyung back to an older active generation while Yujin is live;
that would violate sole ownership. A dotfiles generation rollback alone does
not roll back databases, processed events, or external side effects.
