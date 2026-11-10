## Add Timestamps to mori, rei, and mori-rei-app Logs Without Touching App Code

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

This document is maintained in accordance with `.claude/skills/exec-plan/PLANS.md`.


## Purpose / Big Picture

Today, the launchd-managed background services for `mori`, `rei`, and `mori-rei-app`
write their stdout and stderr to plain files under `~/.mori/logs`, `~/.rei/logs`, and
`~/.mori-rei-app/logs`. None of those lines carry a timestamp, so when something goes
wrong it is impossible to tell when an event happened or correlate failures across the
three services. The Haskell binaries themselves do not emit timestamps and the user has
asked to fix this *without* changing application code.

After this change, every line written to those log files will be prefixed with an ISO-8601
timestamp produced at the moment the line was written, by piping the wrapper script's
stdout and stderr through the `ts` utility from `pkgs.moreutils` (a small Perl script
that reads lines and prints them prefixed with the current time). A reader can verify the
fix by running `tail -f ~/.mori/logs/automate.stderr.log` and observing that each new line
begins with something like `2026-04-15T14:32:07-04:00`.

The change is contained entirely to three Nix files in the home-manager configuration
(`home/mori.nix`, `home/rei.nix`, `home/mori-rei-app.nix`). No Haskell source is touched,
no new derivations are created, and the existing log file paths and launchd labels are
unchanged.


## Progress

- [x] Pipe `mori-automate-wrapper` stdout/stderr through `ts` in `home/mori.nix`. (2026-04-15)
- [x] Pipe `rei-subscription-wrapper` and `rei-worker-wrapper` stdout/stderr through
  `ts` in `home/rei.nix`. (2026-04-15)
- [x] Pipe `mori-rei-app-wrapper` stdout/stderr through `ts` in `home/mori-rei-app.nix`. (2026-04-15)
- [ ] Run `darwin-rebuild switch --flake .` (via `just` if applicable) and verify the
  build succeeds with no errors.
- [ ] Confirm each of the five launchd agents restarted under the new wrapper script,
  using `launchctl print gui/$(id -u)/<label>`.
- [ ] Tail each of the five log files and verify that newly produced lines carry a
  timestamp prefix.
- [ ] Commit the change with the `ExecPlan:` git trailer linking to this file.


## Surprises & Discoveries

(None yet.)


## Decision Log

- Decision: Use `ts` from `pkgs.moreutils` rather than `awk`, `gawk strftime`, `logger`,
  or a custom Haskell change.
  Rationale: `ts` is a tiny well-tested Perl filter packaged in nixpkgs; it understands
  `strftime` format strings, line-buffers automatically, and adds zero ceremony. `awk`
  on macOS does not reliably support `%z` for timezone offset, and `gawk` would also
  pull in a runtime. `logger` would route to the unified system log instead of the
  existing files, which would break the user's current `tail -f` workflow.
  Date: 2026-04-15.

- Decision: Apply the timestamping inside the existing shell wrappers (which `launchd`
  already invokes via `ProgramArguments`) rather than introducing a new wrapper layer or
  changing launchd's `StandardOutPath` mechanism.
  Rationale: The wrappers already exist for `pg_isready` waiting and environment setup,
  so adding two `exec`-redirect lines is a minimal additive change. launchd continues to
  capture the wrapper's final stdout/stderr to the same files, so the StandardOutPath
  configuration does not need to change.
  Date: 2026-04-15.

- Decision: Use ISO-8601 with timezone offset (`%Y-%m-%dT%H:%M:%S%z`) as the timestamp
  format.
  Rationale: Sortable, unambiguous, and matches what most log aggregators expect. The
  user is in a single timezone but the offset makes the logs portable if they are ever
  copied off the machine.
  Date: 2026-04-15.

- Decision: Do not change the existing `StandardOutPath`/`StandardErrorPath` file names
  or the directory layout.
  Rationale: Changing log paths would break any tail commands or shell history the user
  relies on. Keeping paths constant means the only observable difference is the new
  prefix on each line.
  Date: 2026-04-15.


## Outcomes & Retrospective

(To be filled during and after implementation.)


## Context and Orientation

The dotfiles repository at `/Users/shinzui/.config/dotfiles.nix` is a Nix flake that
configures a Darwin (macOS) machine using `nix-darwin` and `home-manager`. Three of the
home-manager modules under `home/` register background services as launchd "user agents",
which is macOS's equivalent of a per-user systemd unit. Each agent is described in Nix as
an entry under `launchd.agents.<name>` and ends up as a `.plist` file in
`~/Library/LaunchAgents/com.shinzui.<name>.plist` after `darwin-rebuild switch`.

The three relevant module files and the agents they register are:

`home/mori.nix`

  Registers one agent, `com.shinzui.mori-automate`, which runs the `mori automate daemon`
  subcommand. The launchd agent invokes a wrapper shell script defined inline as
  `mori-automate-wrapper = pkgs.writeShellScript "mori-automate" '' ... ''`. The wrapper
  exports `MORI_PG_CONNECTION_STRING`, waits for PostgreSQL to be ready via `pg_isready`,
  and then `exec`s the `mori` binary. Logs go to `~/.mori/logs/automate.stdout.log` and
  `~/.mori/logs/automate.stderr.log`.

`home/rei.nix`

  Registers two agents, `com.shinzui.rei-subscription` (runs `rei subscription run all`)
  and `com.shinzui.rei-worker` (runs `rei worker all`). Both have their own wrapper shell
  scripts (`rei-subscription-wrapper`, `rei-worker-wrapper`) that share the same
  `waitForPg` snippet. Logs go to `~/.rei/logs/subscription.{stdout,stderr}.log` and
  `~/.rei/logs/worker.{stdout,stderr}.log`.

`home/mori-rei-app.nix`

  Registers one agent, `com.shinzui.mori-rei-app`, which runs the `mori-rei-app` binary
  (a webhook ingestion server). The wrapper waits for PostgreSQL, ensures the
  `mori_rei_app` operational database exists via `createdb`, then `exec`s the binary.
  Logs go to `~/.mori-rei-app/logs/server.{stdout,stderr}.log`.

In all five cases, the launchd plist field `StandardOutPath` and `StandardErrorPath`
point at the corresponding `.log` files, and launchd captures whatever the wrapper script
emits on file descriptors 1 and 2.

Definitions of terms used in this plan:

- "launchd agent" — a per-user background service description loaded by macOS's launchd,
  the OS init system. Each is a `.plist` file under `~/Library/LaunchAgents/`. The
  `launchctl` command lists, starts, stops, and inspects them. We use the home-manager
  `launchd.agents.<name>` Nix attribute to declare them; home-manager generates the
  plist on `darwin-rebuild switch`.

- "wrapper script" — the shell script invoked by launchd's `ProgramArguments`. It is the
  process whose stdout and stderr launchd routes to the `StandardOutPath` and
  `StandardErrorPath` files. The wrapper performs setup work (waiting for the database,
  exporting environment variables) and then replaces itself with the real binary using
  the bash `exec` builtin.

- "process substitution" — bash syntax of the form `>(command)` that creates a named pipe
  and starts `command` reading from it in the background. We use it to send the wrapper's
  stdout and stderr through `ts` while keeping each stream separate.

- "`ts`" — a Perl filter from the `moreutils` package. It reads lines from stdin and
  prints them on stdout prefixed with the current time formatted by an `strftime` format
  string. Default flush is per-line, so the output appears in the destination file in
  near real time. It is provided by `pkgs.moreutils` in nixpkgs and lives at
  `${pkgs.moreutils}/bin/ts`.


## Plan of Work

The work is a single, additive edit applied identically (with file-path adjustments) to
each of the three home-manager modules. There is one milestone: "Pipe wrapper streams
through `ts`". A second optional milestone covers verification.

### Milestone 1: Pipe wrapper stdout and stderr through `ts`

At the end of this milestone, every line that any of the five wrapper scripts writes to
its stdout or stderr will pass through `${pkgs.moreutils}/bin/ts` and arrive in the same
log file with an ISO-8601 timestamp prefix. The launchd agents will be reloaded and the
log files will show timestamped output going forward.

The shape of the edit is the same in each wrapper. Inside the wrapper script body,
*before* the existing `pg_isready` wait loop, insert two `exec` redirections that route
file descriptors 1 and 2 through `ts` via process substitution, and then carry on with
the existing logic. The redirection must happen before any `echo` or command output is
produced, so the wait loop and the eventual `exec` of the binary all benefit from it.

The two new lines that go into each wrapper look like this (indented as a literal
shell snippet):

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

The first line redirects the wrapper's fd 1 into a `ts` process whose stdout becomes the
wrapper's new fd 1 (which launchd then captures into `StandardOutPath`). The second line
does the same for fd 2: it redirects fd 2 into a separate `ts` process and uses `>&2`
inside the process substitution so the timestamped output ends up on fd 2 of the parent,
which launchd captures into `StandardErrorPath`. The two streams remain independent.

Note the use of `${pkgs.moreutils}/bin/ts` rather than a bare `ts`: the wrapper runs
under launchd with a minimal `PATH`, so the absolute store path is required. Because the
wrapper is generated by `pkgs.writeShellScript`, the `${pkgs.moreutils}` interpolation is
a Nix string interpolation evaluated at build time, which means `pkgs.moreutils` becomes
a build input of the wrapper derivation automatically.

Edit `home/mori.nix`. Locate the let-binding `mori-automate-wrapper = pkgs.writeShellScript "mori-automate" ''` and modify the body so it begins like this (the `set -euo pipefail` and `export` lines are existing; the two `exec` lines are new):

    set -euo pipefail
    export MORI_PG_CONNECTION_STRING="${connStr}"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    # Wait for PostgreSQL to be ready
    until ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; do
      sleep 2
    done

    exec ${pkgs.mori}/bin/mori automate daemon

Edit `home/rei.nix`. There are two wrappers: `rei-subscription-wrapper` and
`rei-worker-wrapper`. Both already share a `waitForPg` snippet. The cleanest place for
the timestamping is inside each wrapper individually, immediately after the `set -euo
pipefail` and `export` lines and before the `${waitForPg}` interpolation. After the
edit, `rei-subscription-wrapper` should look like:

    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${connStr}"
    export PG_CONNECTION_STRING="${connStr}"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    ${waitForPg}

    exec ${reiBin} subscription run all

and `rei-worker-wrapper` is identical except for the final `exec` line which stays as
`exec ${reiBin} worker all`.

Edit `home/mori-rei-app.nix`. The wrapper currently does several setup steps including
reading a secret and calling `createdb`. Insert the two `exec` lines immediately after
the `export WEBHOOK_SECRET="$(cat ${secretPath})"` line and before the `until` loop.
After the edit, the wrapper should look like this:

    set -euo pipefail
    export REI_PG_CONNECTION_STRING="${reiConnStr}"
    export MORI_REI_APP_PG_CONNECTION_STRING="${appConnStr}"
    export WEBHOOK_SECRET="$(cat ${secretPath})"

    exec >  >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z')
    exec 2> >(${pkgs.moreutils}/bin/ts '%Y-%m-%dT%H:%M:%S%z' >&2)

    # Wait for PostgreSQL to be ready
    until ${pg}/bin/pg_isready -h "${pgSocket}" > /dev/null 2>&1; do
      sleep 2
    done

    # Ensure the operational database exists (idempotent). createdb
    # exits non-zero if the database is already there, which is the
    # steady state after the first successful startup.
    ${pg}/bin/createdb -h "${pgSocket}" mori_rei_app 2>/dev/null || true

    exec ${pkgs.mori-rei-app}/bin/mori-rei-app

No other edits are needed. There is no `import`, no new dependency to add to a package
list, and no change to the launchd plist itself: the `StandardOutPath` and
`StandardErrorPath` fields keep pointing at the same log files, the wrapper just
arranges to write timestamped lines into them.


### Milestone 2: Build, reload agents, and verify

At the end of this milestone, the new wrapper scripts are running under launchd and the
log files contain at least one new line with a timestamp prefix.


## Concrete Steps

All commands are run from `/Users/shinzui/.config/dotfiles.nix`.

1. Make the three edits described in Milestone 1. Use the `Edit` tool to keep the
   surrounding lines exactly as they are.

2. Build and switch the system. The repository's `Justfile` is the conventional entry
   point; if no recipe matches, fall back to `darwin-rebuild`:

       just rebuild

   or, equivalently:

       darwin-rebuild switch --flake .

   Expected output ends with something like:

       activating launchd agents...
       (re)starting service org.nixos.com.shinzui.mori-automate

   and exits zero.

3. Confirm the new wrappers are loaded. Run, one per agent:

       launchctl print gui/$(id -u)/com.shinzui.mori-automate     | grep -E 'state|program'
       launchctl print gui/$(id -u)/com.shinzui.rei-subscription  | grep -E 'state|program'
       launchctl print gui/$(id -u)/com.shinzui.rei-worker        | grep -E 'state|program'
       launchctl print gui/$(id -u)/com.shinzui.mori-rei-app      | grep -E 'state|program'

   Each should report `state = running` and a `program =` line pointing at a fresh
   `/nix/store/...-<wrapper-name>` path that is *different* from the path that was active
   before the rebuild.

4. Tail each log file and watch for at least one timestamped line. Some services emit
   output continuously; for ones that are quiet, restarting the agent forces fresh
   output.

       tail -f ~/.mori/logs/automate.stderr.log
       tail -f ~/.rei/logs/subscription.stderr.log
       tail -f ~/.rei/logs/worker.stderr.log
       tail -f ~/.mori-rei-app/logs/server.stderr.log

   Expected: every newly written line begins with a string of the form
   `2026-04-15T14:32:07-0400 ` followed by the original log content. Lines that were
   in the file *before* the rebuild are unchanged and have no prefix; only new lines
   are timestamped.

5. Commit the change. Stage only the three modified files explicitly:

       git add home/mori.nix home/rei.nix home/mori-rei-app.nix
       git commit -m "$(cat <<'EOF'
       Prefix mori, rei, and mori-rei-app logs with timestamps

       Pipe each launchd wrapper's stdout and stderr through ts(1) from
       pkgs.moreutils so every log line gets an ISO-8601 timestamp without
       touching the application binaries.

       ExecPlan: docs/plans/timestamped-app-logs.md
       EOF
       )"


## Validation and Acceptance

The change is accepted when all four of the following are true:

1. `darwin-rebuild switch --flake .` completes without errors.

2. After the rebuild, `launchctl print gui/$(id -u)/<label>` reports `state = running`
   for each of the four labels: `com.shinzui.mori-automate`, `com.shinzui.rei-subscription`,
   `com.shinzui.rei-worker`, and `com.shinzui.mori-rei-app`.

3. For each of the eight log files (stdout and stderr for each of the four agents),
   any line written after the rebuild begins with an ISO-8601 timestamp followed by a
   space, for example `2026-04-15T14:32:07-0400 hello`.

4. The contents emitted *before* the timestamp prefix (the rest of the line) are byte-
   for-byte identical to what the binary would have written without the wrapper change.
   This can be spot-checked against a known message: pick any error stack trace already
   present in `~/.rei/logs/worker.stderr.log` and confirm the format of the *content*
   portion of any new line still matches.

A negative test is also useful: if you `touch` the log file or write to it through
launchd's StandardErrorPath without the wrapper, no timestamp will be prefixed, because
the timestamping happens inside the wrapper, not in launchd. This proves the prefix is
coming from the change and not from somewhere else.


## Idempotence and Recovery

Every step is idempotent. Running `darwin-rebuild switch --flake .` repeatedly with no
further edits is a no-op: home-manager will detect that the wrapper plists are unchanged
and skip the bootout/bootstrap dance (the existing `cmp -s` guards in the
`*-stop-agents` activation snippets in each module already implement this).

If something goes wrong and the wrappers fail to start (for example, a typo in the
process-substitution syntax that bash rejects), recovery is to revert the three edits and
re-run `darwin-rebuild switch --flake .`. Because no log paths or labels have changed,
the rollback restores the previous behavior cleanly. The previous generation is also
always reachable via `darwin-rebuild --rollback` if the current generation cannot even
build.

A subtle failure mode worth noting: if `${pkgs.moreutils}/bin/ts` is somehow missing or
broken at runtime, the wrapper's `exec >  >(...)` line will still succeed (process
substitution does not wait for the child to exec), but the child `ts` process will exit
immediately and the writing end of the pipe will get `EPIPE` on the next write. Bash's
`set -e` plus `set -o pipefail` may cause the wrapper to exit with a broken-pipe error,
and launchd's `KeepAlive = true` will then restart the wrapper in a tight loop. To detect
this scenario, watch `launchctl print gui/$(id -u)/<label>` for a rapidly incrementing
`run count`. The fix in that case is to roll back as above and report the issue;
`pkgs.moreutils` is a stable, well-maintained package and this scenario is unlikely.


## Interfaces and Dependencies

This change introduces exactly one new build-time dependency on each of the three
modules' wrapper derivations: `pkgs.moreutils`. It is referenced via Nix string
interpolation `${pkgs.moreutils}/bin/ts`, which causes the wrapper derivation to record
moreutils as a runtime input. The runtime closure of the wrapper grows by the moreutils
store path (Perl plus a few small scripts).

No new Nix modules, no new flake inputs, and no changes to packages exposed in
`home.packages` are required. The launchd agent attribute sets in each of the three
files retain the same shape:

    launchd.agents.<name> = {
      enable = true;
      config = {
        Label             = "com.shinzui.<name>";
        ProgramArguments  = [ "${<wrapper>}" ];
        RunAtLoad         = true;
        KeepAlive         = true;
        StandardOutPath   = "${logDir}/<...>.stdout.log";
        StandardErrorPath = "${logDir}/<...>.stderr.log";
        EnvironmentVariables = { ... };
      };
    };

The function signatures and types of the existing Nix attributes are unchanged. The only
thing that changes is the string body of each `pkgs.writeShellScript` call.
