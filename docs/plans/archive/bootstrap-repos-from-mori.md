## Bootstrap Local Repo Checkouts From the Mori Registry

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

This document is maintained in accordance with `.claude/skills/exec-plan/PLANS.md`.


## Purpose / Big Picture

After this change, on a freshly provisioned Mac the user can run a single command —
`bootstrap-repos` — and every project registered in the user's "mori" project
registry will be cloned to the exact local path that registry records for it. The
command is a Nix-managed, Nix-installed shell application: it is built by the
flake in this repository and reaches the user's `$PATH` through the normal
`home-manager` package list, so a new machine gets it for free as soon as the
dotfiles flake is applied.

The user already lists registered projects with `mori registry list` (including a
`--json` mode). Each project knows its canonical local checkout directory and,
via `mori registry show <qname> --full --json`, its upstream repository URL
(GitHub, raw git, or GitLab). Today bootstrapping that tree of checkouts is
manual: re-clone dozens of repos by hand to the right spots under
`~/Keikaku/...`. This plan automates it.

You can see the command working like this on a machine that already has `mori`
set up and its registry populated:

    $ bootstrap-repos --dry-run
    [dry-run] would clone https://github.com/shinzui/mori.git -> /Users/shinzui/Keikaku/bokuno/mori-project/mori
    [dry-run] would clone https://github.com/shinzui/mori-rei-app.git -> /Users/shinzui/Keikaku/bokuno/mori-project/mori-rei-app
    [dry-run] would skip /Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku (already a git repo)
    ...
    Summary: 12 cloned, 34 skipped, 0 errors (dry-run)

Without `--dry-run` the same invocation actually performs the clones. Running it
a second time is a no-op for paths that already contain a git checkout, so the
command is safe to rerun after adding a few new projects in mori.


## Progress

Use a checklist to summarize granular steps. Every stopping point must be documented here,
even if it requires splitting a partially completed task into two ("done" vs. "remaining").
This section must always reflect the actual current state of the work.

- [x] Milestone 1: shell script derivation exists at `derivations/bootstrap-repos/default.nix` and builds in isolation. (2026-04-12)
- [x] Milestone 1a: `default.nix` written using `pkgs.writeShellApplication` with explicit `runtimeInputs = [ mori git jq coreutils ]`. (2026-04-12)
- [x] Milestone 1b: script source embedded inline in the derivation — chose inline per Decision Log. (2026-04-12)
- [x] Milestone 1c: `git add` the new files so Nix can see them in the flake checkout. (2026-04-12)
- [x] Milestone 1d: `nix build .#bootstrap-repos` succeeds and produces `result/bin/bootstrap-repos`. (2026-04-12)
- [x] Milestone 1e: `./result/bin/bootstrap-repos --help` prints usage. (2026-04-12)
- [x] Milestone 1f: `./result/bin/bootstrap-repos --dry-run` against the live `mori` registry prints the expected plan without touching the filesystem. Output: `Summary: 0 cloned, 49 skipped, 2 errors (dry-run)` — two errors are pre-existing non-git directories (see Surprises & Discoveries), not script bugs. (2026-04-12)
- [x] Milestone 2: package is wired into the flake's `my-packages` overlay and into the `home/default.nix` package list.
- [x] Milestone 2a: overlay entry `bootstrap-repos = final.callPackage (self + "/derivations/bootstrap-repos") { };` added in `flake.nix`. (2026-04-12)
- [x] Milestone 2b: `bootstrap-repos` added to `home/default.nix` alongside `markit`, `beautiful-mermaid`. (2026-04-12)
- [x] Milestone 2c: also surfaced under the flake-level `packages = { ... }` output. (2026-04-12)
- [ ] Milestone 2d: `darwin-rebuild switch --flake .#SungkyungM1X` — deferred, waiting for user confirmation before touching the system.
- [ ] Milestone 2e: from a fresh shell, `which bootstrap-repos` resolves into the nix store and `bootstrap-repos --help` prints usage.
- [x] Milestone 3a (via ./result/bin): `bootstrap-repos --dry-run` prints expected plan for all non-docs-only projects; docs-only entries skipped as designed. (2026-04-12)
- [x] Milestone 3b (via ./result/bin): `bootstrap-repos --dry-run --filter shinzui/ephemeral-pg` restricts output to that single project. (2026-04-12)
- [ ] Milestone 3c: one real clone of a currently-missing project to verify the write path.
- [ ] Milestone 3d: rerun for idempotence check.


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

- **2026-04-12 — Two pre-existing non-git directories on disk.** The first live `--dry-run` surfaced two `[error]` lines for paths that exist but do not contain `.git`:

      [error] /Users/shinzui/Keikaku/work/libraries/haskell/message-db-hs-master exists and is not a git repo
      [error] /Users/shinzui/Keikaku/work/microtan/mls-service-v2-master exists and is not a git repo

  These are real disk state (note the `-master` suffix, suggesting they were
  extracted from GitHub archive zips at some point) — not script bugs. The
  script correctly refuses to overwrite them. Resolution is up to the operator:
  either rename/delete those directories and rerun, or update the mori
  registry to point at a different path. Flagging for awareness only; does not
  block this plan.

- **2026-04-12 — `mori registry list --json` returns 51 projects on this machine**, of which 2 are docs-only and 49 have repositories. The script handled all of them in under a second in dry-run mode — no performance concerns at this scale.


## Decision Log

Record every decision made while working on the plan.

- Decision: Clone destination is the `path` field from `mori registry list --json`, verbatim.
  Rationale: Inspection of live data on this machine showed that `path` is the actual on-disk repo root for already-cloned projects. For example, `Bodigrim/tasty-bench` has `path = /Users/shinzui/Keikaku/hub/haskell/tasty-bench-project` and that directory already contains a `.git` dir. Similarly `shinzui/mori` has `path = /Users/shinzui/Keikaku/bokuno/mori-project/mori` and that directory contains `.git`. The `repositories[].localPath` field refers to where the *package* lives inside the repo, not where the repo goes on disk, and must be ignored for cloning purposes.
  Date: 2026-04-12

- Decision: URL selection preference order is `github` → `git` → `gitlab`, and `github` is expanded to `https://github.com/<OWNER>/<REPO>.git` by default, `git@github.com:<OWNER>/<REPO>.git` when `--ssh` is passed.
  Rationale: Every `shinzui/*` project in the live registry uses `github: "shinzui/<name>"` and `git: null`. Supporting the other two keys is cheap and future-proofs against non-GitHub projects. HTTPS is the default because it works without an agent or keys on a brand-new machine, which is exactly the bootstrap scenario.
  Date: 2026-04-12

- Decision: Projects whose `repositories` array is empty or whose first entry has `github`, `git`, and `gitlab` all null are skipped with a warning. Docs-only projects (`docsOnly: true` in `registry list`) are also skipped.
  Rationale: Such projects have no upstream to clone. Example: the `shinzui/haskell-jitsurei` docs-only entry in the live registry.
  Date: 2026-04-12

- Decision: When multiple registered projects share a single `path`, the script dedupes by `path` and clones each destination at most once per run. When multiple projects map to *different* paths that happen to be nested (e.g. a monorepo parent and a child), the script treats them as independent and clones each at its own path, even if one ends up inside the other on disk.
  Rationale: The authoritative source of truth is what the registry recorded for each project. Deduping by path keeps the run idempotent and prevents cloning the same repo twice. Nesting is the user's deliberate layout choice (e.g. `mori-project/mori` and `mori-project/mori-rei-app` are two separate repos under a shared parent directory), so the script must not try to be clever about collapsing them.
  Date: 2026-04-12

- Decision: The script does *not* attempt to `git pull` or `git fetch` existing checkouts. A destination that is already a valid git repo is skipped with a message. If the user wants to update, there will be a follow-up `--update` flag in a later plan — it is intentionally out of scope here.
  Rationale: Bootstrap means "make the tree exist"; refreshing is a different operation with different failure modes (local edits, detached branches, diverged remotes). Keeping this plan tightly scoped avoids surprising the user by touching repos they are actively editing.
  Date: 2026-04-12

- Decision: Script is authored as a single inline `text` block inside `writeShellApplication` rather than a separate `bootstrap-repos.sh` file.
  Rationale: It keeps the derivation self-contained and matches how other custom Nix tools in this repo live (see `derivations/markit/default.nix`). If the script grows past ~150 lines this decision can be revisited; current draft fits in well under that.
  Date: 2026-04-12


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose.

(To be filled during and after implementation.)


## Context and Orientation

This section describes the current state of the repository and the surrounding
tooling as if the reader knows nothing about either.

**The repository.** The working directory is `/Users/shinzui/.config/dotfiles.nix`,
a Nix flake that manages a macOS machine via `nix-darwin` and `home-manager`. It
defines personal CLI packages under `derivations/<name>/default.nix`, exposes
them on the system as Nix overlays in `flake.nix`, and installs them to the
user's environment by listing them in `home/default.nix`. The key files to know
about:

- `flake.nix` is the top-level flake. It declares inputs (nixpkgs, nix-darwin,
  home-manager, plus project flakes like `mori`, `rei`, `kizamu`), defines an
  overlay attribute set called `my-packages` (currently around
  `flake.nix` lines 204–243) that attaches personal packages to the nixpkgs set,
  and also lists a few of them under the flake-level `packages = { ... }`
  output (around lines 323–332) so they can be built directly with
  `nix build .#<name>`.
- `home/default.nix` is the home-manager configuration. Around lines 170–180 it
  lists custom packages like `beautiful-mermaid`, `markit`, and `tmuxai`; that
  list is how personal tools reach the user's `$PATH`.
- `derivations/` holds one directory per custom package. Examples to imitate
  for structure and style: `derivations/markit/default.nix` (a Bun application),
  `derivations/uuinfo.nix` (a plain Rust derivation). There is currently no
  example that uses `pkgs.writeShellApplication`; this plan introduces the
  first.
- `docs/plans/` is where ExecPlans live. The current file lives at
  `docs/plans/bootstrap-repos-from-mori.md`.
- `Justfile` at the repository root holds convenience recipes; it already has
  recipes like `update-mori`. This plan does not add a new recipe — the command
  lands on `$PATH` directly — but a small `bootstrap` recipe could be added
  later.

**The `mori` tool.** `mori` is a personal project registry CLI already installed
on this machine (it is pulled in via `flake.nix` inputs.mori and exposed in the
`my-packages` overlay). It maintains a database of "projects" — each project is
a named unit of source code with a canonical local path and one or more upstream
repositories. The two subcommands this plan relies on are:

- `mori registry list --json` prints every registered project as a JSON array.
  Each element includes at least the fields `namespace`, `name`, `path`,
  `docsOnly`, `origin`, and `projectType`. The *qualified name* of a project is
  the string `"${namespace}/${name}"` — e.g. `shinzui/mori`,
  `Bodigrim/tasty-bench`, `tan/qualified-agent-service`. The `path` field is the
  absolute filesystem path where that project's checkout lives on disk.
- `mori registry show <qualified-name> --full --json` prints a single JSON
  object with richer metadata for one project. The interesting key for this
  plan is `repositories`, which is an array of objects, each of which has the
  shape `{ "github": string|null, "git": string|null, "gitlab": string|null,
  "localPath": string|null, "name": string }`. Exactly one of `github`, `git`,
  `gitlab` is typically non-null. A non-null `github` value is a shorthand like
  `"shinzui/mori"` (owner/repo), *not* a full URL. A non-null `git` value is a
  full clone URL. A non-null `gitlab` value is a shorthand like
  `"group/project"`. The `localPath` field describes where inside the repo the
  package lives and must be ignored for cloning — see the Decision Log.

On this development machine the `mori` database is served by a local Postgres
socket at `/Users/shinzui/.local/state/postgresql/`; commands run under a
sandbox that blocks that socket will fail with a Postgres connection error.
That is a harness-level constraint, not a script bug: the packaged
`bootstrap-repos` binary will run inside the user's normal shell, not in a
sandbox, so it simply calls `mori` and trusts it to succeed or fail loudly.

**The home directory layout this targets.** The user organizes source checkouts
under `~/Keikaku/...` with namespaced subdirectories. A small sample of real
entries (taken from `mori registry list` on 2026-04-12):

    Bodigrim/tasty-bench        /Users/shinzui/Keikaku/hub/haskell/tasty-bench-project
    shinzui/mori                /Users/shinzui/Keikaku/bokuno/mori-project/mori
    shinzui/mori-rei-app        /Users/shinzui/Keikaku/bokuno/mori-project/mori-rei-app
    shinzui/kiroku              /Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku
    shinzui/ephemeral-pg        /Users/shinzui/Keikaku/bokuno/ephemeral-pg-project/ephemeral-pg
    shinzui/seihou              /Users/shinzui/Keikaku/bokuno/seihou-project/seihou
    tan/qualified-agent-service /Users/shinzui/Keikaku/work/microtan/qa-project/qualified-agent-service

Nothing about these paths is hardcoded in the script — it pulls them from
`mori registry list --json` at runtime. That is the entire point of the
plan: the script is data-driven, so adding a project to `mori` is enough to
make it show up in `bootstrap-repos` output the next time it runs.


## Plan of Work

The work is three additive milestones. Each one ends in a runnable, verifiable
state; at no point does the tree become broken.


### Milestone 1 — build the script derivation in isolation

Scope: introduce a new Nix derivation under `derivations/bootstrap-repos/` that,
when built, produces a standalone `bootstrap-repos` executable in a nix-store
path. Nothing in the rest of the flake changes yet. At the end of this
milestone the executable exists and its `--help` and `--dry-run` modes both
run successfully against the machine's live `mori` registry.

Create the directory `derivations/bootstrap-repos/` and inside it a single
`default.nix` file. The file is a callPackage-compatible Nix expression that
takes `pkgs.writeShellApplication`, `pkgs.git`, `pkgs.jq`, `pkgs.coreutils`,
and `pkgs.mori` as arguments (the last one comes from the `my-packages`
overlay and is already on this flake's nixpkgs set — see `flake.nix` line
223 where `mori = inputs.mori.packages.${...}.default;` is defined). The
derivation body calls `writeShellApplication` with `name = "bootstrap-repos"`,
`runtimeInputs = [ mori git jq coreutils ]`, and a multiline `text` attribute
holding the script described below.

The script:

1. Parses command-line flags. Supported flags:
   - `--help` / `-h`: print usage and exit 0.
   - `--dry-run`: print planned actions, do not touch the filesystem.
   - `--ssh`: emit `git@github.com:OWNER/REPO.git` / `git@gitlab.com:...`
     forms instead of `https://`.
   - `--filter <substring>`: only operate on projects whose qualified name
     (the string `"${namespace}/${name}"`) contains that substring. Case
     sensitive; the user can compose multiple `--filter` flags by running the
     command twice, or we can accept the flag once — start with once, noted in
     the Decision Log if it needs to grow later.
   - Any unrecognized flag: print usage and exit 2.

2. Runs `mori registry list --json` and captures stdout. If the exit status is
   non-zero, prints a clear error ("failed to query mori registry; ensure
   mori is installed and its database is reachable") and exits 1. It does
   *not* attempt to hide or recover from the error — the bootstrap scenario
   requires that `mori` itself be functional first.

3. For each element of the JSON array, extracts `namespace`, `name`, `path`,
   and `docsOnly` using `jq`. If `docsOnly` is `true`, skip with a
   `[docs-only] skipping <qname>` message. Otherwise compute
   `qname="${namespace}/${name}"`, and if a `--filter` is active and `qname`
   does not contain it, skip silently.

4. For surviving projects, runs `mori registry show "$qname" --full --json`
   and pipes through `jq` to extract the first element of `.repositories`.
   From that element, picks the first non-null URL in the order `github`,
   `git`, `gitlab`. If all three are null (or the array is empty), prints
   `[no-repo] skipping <qname>` and increments a counter; does not fail.

5. Expands the chosen URL into a full clone URL:
   - `github` shorthand `OWNER/REPO`:
     - HTTPS (default): `https://github.com/OWNER/REPO.git`
     - SSH (`--ssh`):   `git@github.com:OWNER/REPO.git`
   - `gitlab` shorthand `GROUP/PROJECT`:
     - HTTPS (default): `https://gitlab.com/GROUP/PROJECT.git`
     - SSH (`--ssh`):   `git@gitlab.com:GROUP/PROJECT.git`
   - `git`: used verbatim; `--ssh` has no effect on raw `git` URLs.

6. Decides what to do with the destination `path`:
   - If `path/.git` exists (checked via `test -d`): print
     `[skip] <path> (already a git repo)`, increment "skipped".
   - If `path` exists and is a non-empty directory without `.git`: print
     `[error] <path> exists and is not a git repo` to stderr, increment
     "errors", continue to the next project.
   - If `path` does not exist: create the parent directory with
     `mkdir -p "$(dirname "$path")"` and run
     `git clone --quiet "<url>" "$path"`. On success, print
     `[clone] <url> -> <path>` and increment "cloned". On failure print
     `[error] git clone failed for <qname>: <url> -> <path>` to stderr,
     increment "errors", and continue (do not abort the whole run).

7. Tracks a per-path dedupe set: once a `path` has been handled in this run,
   subsequent projects reporting the same `path` are skipped with
   `[dup-path] skipping <qname> (path already handled this run)`.

8. In `--dry-run` mode, steps 6 and 7 print `[dry-run] would <action>` lines
   instead of performing the filesystem operations. The skipped/error/cloned
   counters still update so the final summary is meaningful.

9. At the end, prints a one-line summary:
   `Summary: N cloned, N skipped, N errors${dry_run? " (dry-run)": ""}`. Exit
   code is 0 if `errors == 0`, else 1.

The script uses `set -euo pipefail`, quotes all variable expansions, and does
not rely on bash arrays beyond what `writeShellApplication` already sets up.
Because `writeShellApplication` runs `shellcheck` on the script at build time,
the build itself is the first line of defense against typos and unquoted
expansions — this is the main reason to use `writeShellApplication` over a raw
`writeScriptBin`.


### Milestone 2 — wire the package into the flake and home-manager

Scope: make `bootstrap-repos` available on the user's `$PATH` after a darwin
rebuild, without having to invoke `nix build` manually.

Edit `flake.nix`:

1. Inside the `my-packages = final: prev: { ... }` overlay (currently at
   `flake.nix` around lines 204–243), add the line:

        bootstrap-repos = final.callPackage (self + "/derivations/bootstrap-repos") { };

   Place it near the other `callPackage` entries (e.g. next to `markit` and
   `beautiful-mermaid`) so the alphabetical-ish grouping stays consistent.

2. Inside the flake-level `packages = { ... }` attribute set (currently at
   `flake.nix` around lines 323–332), add:

        bootstrap-repos = pkgs.bootstrap-repos;

   This is what makes `nix build .#bootstrap-repos` keep working as a
   first-class entrypoint and is how you invoke the script from this repo's
   directory without a full darwin rebuild.

Edit `home/default.nix`:

3. Add `bootstrap-repos` to the custom-packages list near
   `beautiful-mermaid` / `markit` (currently around lines 176–179). Keep the
   alphabetical-ish grouping.

Make sure the new files are visible to Nix:

4. Run `git add derivations/bootstrap-repos/default.nix flake.nix home/default.nix docs/plans/bootstrap-repos-from-mori.md`. This is not optional: as recorded in `memory/MEMORY.md`, new files in `derivations/` must be staged before `nix build` can see them under flake evaluation.

Rebuild the system:

5. Run `darwin-rebuild switch --flake .#SungkyungM1X` (or the equivalent
   `sudo darwin-rebuild` invocation the user's environment expects). Wait for
   it to finish.

Verify:

6. In a fresh shell, run `which bootstrap-repos`. It should print a path
   inside `/nix/store/.../bin/bootstrap-repos` (or a home-manager profile
   symlink that resolves to one).
7. Run `bootstrap-repos --help` and confirm the usage text prints.


### Milestone 3 — end-to-end validation against the real registry

Scope: prove the data-driven behavior by running the command against the live
`mori` registry on this machine and spot-checking its output.

Validation is done in dry-run mode first so nothing on disk is disturbed, then
one targeted real clone is performed to prove the write path works.

1. Run `bootstrap-repos --dry-run 2>&1 | tee /tmp/bootstrap-repos.plan.log`
   and visually scan the output. Confirm:
   - `shinzui/mori` appears with the line
     `[dry-run] would clone https://github.com/shinzui/mori.git -> /Users/shinzui/Keikaku/bokuno/mori-project/mori` (or a `[skip]` if it is already cloned on this machine).
   - `shinzui/rei` appears similarly.
   - `tan/qualified-agent-service` appears with URL
     `https://github.com/topagentnetwork/qualified-agent-service.git` and
     destination `/Users/shinzui/Keikaku/work/microtan/qa-project/qualified-agent-service`.
   - `shinzui/haskell-jitsurei` (docs-only) is skipped with a `[docs-only]` line.
   - The final `Summary:` line has zero errors.

2. Run `bootstrap-repos --dry-run --filter shinzui/ephemeral-pg` and confirm
   the output contains a line for that project only (plus the final summary).

3. Pick a project whose destination is *missing* — or create that situation on
   purpose by moving an existing checkout aside to a backup location. Run
   `bootstrap-repos --filter <qname>` (no `--dry-run`). Confirm:
   - The expected clone appears at the advertised path.
   - `git -C <path> remote -v` prints an `origin` URL matching the one
     `mori registry show` reports.
   - A second invocation of the same command prints `[skip] <path> (already a git repo)` and reports zero clones / zero errors.

4. If step 3 required moving an existing checkout aside, restore it to its
   original path (or delete the new clone if the restore is simpler). Leave
   the machine in its pre-test state.


## Concrete Steps

All commands assume the working directory `/Users/shinzui/.config/dotfiles.nix`
unless otherwise noted.

1. Create the derivation directory and file:

       mkdir -p derivations/bootstrap-repos

   Then write `derivations/bootstrap-repos/default.nix` with approximately
   the following content. Treat this as a concrete starting point, not a
   frozen text: the script logic follows Milestone 1 faithfully.

       { lib
       , writeShellApplication
       , mori
       , git
       , jq
       , coreutils
       }:

       writeShellApplication {
         name = "bootstrap-repos";
         runtimeInputs = [ mori git jq coreutils ];
         text = ''
           set -euo pipefail

           usage() {
             cat <<'EOF'
           Usage: bootstrap-repos [--dry-run] [--ssh] [--filter SUBSTR] [--help]

           Clone every project registered in the local mori registry to the
           on-disk path that registry records for it. Destinations that are
           already git repos are skipped. Safe to rerun.

             --dry-run        Print planned actions; do not touch the filesystem.
             --ssh            Prefer SSH (git@github.com:OWNER/REPO.git) URLs.
             --filter SUBSTR  Only process projects whose "namespace/name"
                              contains SUBSTR.
             --help, -h       Show this help.
           EOF
           }

           dry_run=0
           use_ssh=0
           filter=""
           while [ $# -gt 0 ]; do
             case "$1" in
               --dry-run) dry_run=1 ;;
               --ssh)     use_ssh=1 ;;
               --filter)  shift; filter="''${1:-}" ;;
               -h|--help) usage; exit 0 ;;
               *) echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
             esac
             shift
           done

           if ! list_json="$(mori registry list --json)"; then
             echo "error: failed to query mori registry; is mori installed and its database reachable?" >&2
             exit 1
           fi

           cloned=0
           skipped=0
           errors=0
           declare -A seen_paths=()

           # Stream one TSV row per project: namespace<TAB>name<TAB>path<TAB>docsOnly
           rows="$(printf '%s' "$list_json" | jq -r '.[] | [.namespace, .name, .path, (.docsOnly|tostring)] | @tsv')"

           while IFS=$'\t' read -r namespace name path docs_only; do
             [ -n "$namespace" ] || continue
             qname="$namespace/$name"

             if [ -n "$filter" ] && [[ "$qname" != *"$filter"* ]]; then
               continue
             fi

             if [ "$docs_only" = "true" ]; then
               echo "[docs-only] skipping $qname"
               skipped=$((skipped+1))
               continue
             fi

             if [ -n "''${seen_paths[$path]:-}" ]; then
               echo "[dup-path] skipping $qname (path $path already handled this run)"
               skipped=$((skipped+1))
               continue
             fi
             seen_paths[$path]=1

             if ! show_json="$(mori registry show "$qname" --full --json 2>/dev/null)"; then
               echo "[error] mori registry show failed for $qname" >&2
               errors=$((errors+1))
               continue
             fi

             # Extract first repository triple (github, git, gitlab).
             read -r gh git_url gl < <(printf '%s' "$show_json" | jq -r '
               .repositories[0] as $r
               | [ ($r.github // "-"), ($r.git // "-"), ($r.gitlab // "-") ]
               | @tsv
             ')

             url=""
             if [ "$gh" != "-" ] && [ -n "$gh" ]; then
               if [ "$use_ssh" = "1" ]; then
                 url="git@github.com:$gh.git"
               else
                 url="https://github.com/$gh.git"
               fi
             elif [ "$git_url" != "-" ] && [ -n "$git_url" ]; then
               url="$git_url"
             elif [ "$gl" != "-" ] && [ -n "$gl" ]; then
               if [ "$use_ssh" = "1" ]; then
                 url="git@gitlab.com:$gl.git"
               else
                 url="https://gitlab.com/$gl.git"
               fi
             fi

             if [ -z "$url" ]; then
               echo "[no-repo] skipping $qname"
               skipped=$((skipped+1))
               continue
             fi

             if [ -d "$path/.git" ]; then
               echo "[skip] $path (already a git repo)"
               skipped=$((skipped+1))
               continue
             fi

             if [ -e "$path" ] && [ -n "$(ls -A "$path" 2>/dev/null || true)" ]; then
               echo "[error] $path exists and is not a git repo" >&2
               errors=$((errors+1))
               continue
             fi

             if [ "$dry_run" = "1" ]; then
               echo "[dry-run] would clone $url -> $path"
               cloned=$((cloned+1))
               continue
             fi

             mkdir -p "$(dirname "$path")"
             if git clone --quiet "$url" "$path"; then
               echo "[clone] $url -> $path"
               cloned=$((cloned+1))
             else
               echo "[error] git clone failed for $qname: $url -> $path" >&2
               errors=$((errors+1))
             fi
           done <<< "$rows"

           suffix=""
           if [ "$dry_run" = "1" ]; then suffix=" (dry-run)"; fi
           echo "Summary: $cloned cloned, $skipped skipped, $errors errors$suffix"
           if [ "$errors" -gt 0 ]; then exit 1; fi
         '';

         meta = with lib; {
           description = "Clone every project registered in the local mori registry to its recorded path";
           mainProgram = "bootstrap-repos";
           platforms = platforms.unix;
         };
       }

   Note: the double-single-quote escapes (`''${...}`) are Nix string-literal
   escaping for literal `${...}` to appear in the emitted bash. The Nix
   evaluator sees `''$` as a literal `$`. If this escape style causes
   shellcheck hiccups at build time, fall back to `writeShellApplication`
   with `bashOptions = []` or move to a `./bootstrap-repos.sh` file referenced
   via `${./bootstrap-repos.sh}` — record that switch in the Decision Log if
   it happens.

2. Stage the new file and prove the derivation builds:

       git add derivations/bootstrap-repos/default.nix docs/plans/bootstrap-repos-from-mori.md
       nix build .#bootstrap-repos

   Expected: a `result` symlink appears pointing into `/nix/store/.../bootstrap-repos`. If `nix build` complains that `.#bootstrap-repos` does not exist, that means the flake-level `packages` entry from Milestone 2 step 2 has not been added yet — add it (and the overlay entry) before running `nix build`, since Nix evaluates from the flake outputs, not from the derivation file directly.

3. Smoke-test the binary:

       ./result/bin/bootstrap-repos --help
       ./result/bin/bootstrap-repos --dry-run

   Expected for `--help`: the usage block from the script.

   Expected for `--dry-run` against this machine's real registry: one line per
   eligible project, each either `[dry-run] would clone ...`, `[skip] ...`,
   `[docs-only] skipping ...`, or `[dup-path] skipping ...`, followed by a
   `Summary:` line whose error count is zero. A representative excerpt from the
   live registry on 2026-04-12 should include:

       [dry-run] would clone https://github.com/shinzui/mori.git -> /Users/shinzui/Keikaku/bokuno/mori-project/mori
       [dry-run] would clone https://github.com/shinzui/mori-rei-app.git -> /Users/shinzui/Keikaku/bokuno/mori-project/mori-rei-app
       [dry-run] would clone https://github.com/topagentnetwork/qualified-agent-service.git -> /Users/shinzui/Keikaku/work/microtan/qa-project/qualified-agent-service
       [docs-only] skipping shinzui/haskell-jitsurei

4. Wire into `flake.nix`. Add, in the `my-packages` overlay block around
   `flake.nix:204–243`:

       bootstrap-repos = final.callPackage (self + "/derivations/bootstrap-repos") { };

   And in the flake-level `packages = { ... }` attribute set around
   `flake.nix:323–332`:

       bootstrap-repos = pkgs.bootstrap-repos;

5. Wire into `home/default.nix`. Add `bootstrap-repos` to the custom-packages
   list around `home/default.nix:176–179`, next to `markit` and
   `beautiful-mermaid`.

6. Stage the edits and rebuild:

       git add flake.nix home/default.nix
       darwin-rebuild switch --flake .#SungkyungM1X

   Expected: darwin-rebuild completes without errors and prints its usual
   activation banner.

7. Verify `$PATH` pickup:

       which bootstrap-repos
       bootstrap-repos --help

   Expected: the `which` output begins with `/nix/store/` or points to a
   home-manager profile symlink; `--help` prints the usage block.

8. Run the end-to-end validation described in Milestone 3 and record
   outcomes in the Progress and Outcomes & Retrospective sections as they
   happen.

9. Commit. Every commit made while working on this plan must include the
   git trailer:

       ExecPlan: docs/plans/bootstrap-repos-from-mori.md

   Suggested commit points (the implementer can bundle or split as
   convenient, as long as each commit leaves the tree buildable):

   - Commit A: "bootstrap-repos: add writeShellApplication derivation" — adds
     `derivations/bootstrap-repos/default.nix` and this ExecPlan file.
   - Commit B: "bootstrap-repos: wire into flake overlay and home packages" —
     edits `flake.nix` and `home/default.nix`.
   - Commit C: "bootstrap-repos: record end-to-end validation results" —
     pure ExecPlan updates if any (Progress checkboxes, Outcomes section).


## Validation and Acceptance

Acceptance is phrased as observable behavior:

1. Running `nix build .#bootstrap-repos` at the repository root exits 0 and
   creates a `result/bin/bootstrap-repos` binary.

2. Running `result/bin/bootstrap-repos --help` prints the usage block
   described in Milestone 1, including all four flags (`--dry-run`, `--ssh`,
   `--filter`, `--help`).

3. Running `result/bin/bootstrap-repos --dry-run` on this machine prints at
   least one line for every non-docs-only project in the live mori registry
   and ends with a `Summary:` line whose "errors" count is zero. At least
   one line must be a `[dry-run] would clone ... -> ...` entry (i.e. the
   script is computing actions, not skipping everything).

4. Running `result/bin/bootstrap-repos --dry-run --filter shinzui/ephemeral-pg`
   prints exactly the action for that project (plus the summary). No other
   project's line appears.

5. After running Milestone 2 (overlay + home-manager wiring + darwin-rebuild),
   `which bootstrap-repos` in a fresh shell returns a path whose prefix is
   `/nix/store/` or the home-manager profile (`~/.nix-profile/bin/bootstrap-repos`
   or the darwin equivalent). Running `bootstrap-repos --help` from that
   shell prints the usage block. The `./result/` symlink is no longer
   required.

6. A real clone test (Milestone 3 step 3) performs `git clone` into the
   expected path, and `git -C <path> remote -v` shows the origin URL
   matching what `mori registry show` advertises for that project. Rerunning
   the command is a no-op and reports `[skip] ...` for that path.

7. `shellcheck` passes as part of the Nix build (this is automatic with
   `writeShellApplication`). If shellcheck fails, the build fails; there is
   no way to ship a broken script past this check.


## Idempotence and Recovery

The `bootstrap-repos` command is designed to be safely rerunnable:

- It never touches a path that already contains `.git`. It prints `[skip]` and
  moves on.
- It never pulls / fetches / resets existing checkouts. Local edits and
  in-flight branches in pre-existing clones are preserved.
- If it encounters a non-empty directory at a destination that is *not* a git
  repo, it refuses (prints `[error]` and increments the error count) instead
  of overwriting. The operator decides what to do with that directory; the
  script never deletes anything.
- A failed `git clone` for one project does not abort the run: the script
  reports the error, increments the counter, and continues with the next
  project. The run exits non-zero at the end if any errors occurred, so the
  operator can re-run after fixing whatever caused them (e.g. missing auth).
- `--dry-run` has no side effects at all; use it freely to preview.

Recovery from a partial run: simply rerun the command. Successfully cloned
paths will be skipped; previously failed ones will be retried.

Rollback: nothing to roll back. If a bad clone was produced and needs to be
removed, the operator deletes that directory manually (the script will not
delete it). The Nix-level rollback for the package itself is the usual
`darwin-rebuild` rollback, i.e. `darwin-rebuild switch --rollback`.


## Interfaces and Dependencies

Nix-level interfaces:

- A new package attribute `bootstrap-repos` is added to `pkgs` via the
  `my-packages` overlay in `flake.nix`. Its derivation lives at
  `derivations/bootstrap-repos/default.nix` and is constructed from
  `pkgs.writeShellApplication`.
- The flake's top-level `packages` output gains a `bootstrap-repos`
  attribute so `nix build .#bootstrap-repos` works outside the darwin
  rebuild path.
- `home/default.nix` adds `bootstrap-repos` to its custom-packages list, which
  is how it lands on `$PATH` after a darwin rebuild.

Runtime dependencies (the closure of the script):

- `mori` (from the `mori` flake input, already exposed via the `my-packages`
  overlay in `flake.nix` line 223). The script runs `mori registry list --json`
  and `mori registry show <qname> --full --json`.
- `git` (from nixpkgs), for `git clone`.
- `jq` (from nixpkgs), for parsing mori's JSON output.
- `coreutils` (from nixpkgs), for `mkdir`, `dirname`, `ls`, `test`, etc.

All four are listed in `runtimeInputs` of `writeShellApplication`, which
guarantees they are on `PATH` when the script runs, regardless of the user's
shell environment.

There are no new language toolchains, no new flake inputs, and no new overlays.


---

Revision history:

- 2026-04-12: Initial plan written.
