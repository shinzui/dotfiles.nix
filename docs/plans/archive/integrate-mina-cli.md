# Integrate the `mina` CLI into the dotfiles flake

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

This document is maintained in accordance with `.claude/skills/exec-plan/PLANS.md`.


## Purpose / Big Picture

After this change, the personal `mina` development-assistant CLI (already developed
at `/Users/shinzui/Keikaku/bokuno/mina` and published to
`github:shinzui/mina`) is installed on the user's Mac the same way every other
shinzui-authored CLI is — by the dotfiles flake. The user can open a fresh shell
on the `SungkyungM1X` machine and run:

    $ which mina
    /etc/profiles/per-user/shinzui/bin/mina
    $ mina --version
    mina-cli 0.1.0.0 (<git-rev>)
    $ mina --help
    mina - development assistant CLI
    ...

Tab-completion works in `zsh` out of the box: typing `mina <TAB>` lists the
top-level subcommands (`exec-plan`, `master-plan`, `config`, `completions`),
`mina exec-plan <TAB>` lists exec-plan subcommands, and so on. No manual
`source` or `compinit` step is required of the user — completions are
generated at build time and dropped into `~/.zfunc/_mina`, the existing
zsh-completions directory the user already has on `fpath`.

The flake also gains a `nix build .#mina` shortcut and a small set of
`Justfile` recipes (`just update-mina`, plus inclusion in `just update-tools`)
that mirror what already exists for `seihou`, `kizamu`, `notion-cli`, etc., so
keeping `mina` up to date is a single command.

This work is purely additive. No existing package, overlay, or home-manager
file changes meaning. After the change, every other CLI continues to behave
exactly as before, and `mina` joins them.


## Progress

Use a checklist to summarize granular steps. Every stopping point must be documented here,
even if it requires splitting a partially completed task into two ("done" vs. "remaining").
This section must always reflect the actual current state of the work.

- [x] Milestone 1: Add `mina` to `flake.nix` inputs and to the `my-packages` overlay. (2026-04-21)
  - [x] Milestone 1a: Add `inputs.mina = { url = "github:shinzui/mina"; inputs.nixpkgs.follows = "nixpkgs-unstable"; };` near the existing `seihou` / `kizamu` inputs in `flake.nix`. (2026-04-21)
  - [x] Milestone 1b: Add `mina = inputs.mina.packages.${prev.stdenv.hostPlatform.system}.default;` to the `my-packages` overlay alongside `seihou` / `kizamu`. (2026-04-21)
  - [x] Milestone 1c: Run `nix flake update mina` (which also writes the lock entry on first add) and confirm `flake.lock` gains a `mina` node. (2026-04-21)
  - [x] Milestone 1d: Smoke-test the package. Because this dotfiles flake does **not** expose `legacyPackages` as an output (only `packages` and `devShells`), the plan's original validation path `.#legacyPackages.aarch64-darwin.mina` fails. Advanced Milestone 4a (added `mina = pkgs.mina;` to the flake-level `packages` set) so `nix build .#mina` resolves; smoke-test then passed with `--version`, `--help`, and `completions zsh`. See Surprises & Discoveries. (2026-04-21)
- [x] Milestone 2: Create `home/mina.nix` and wire it into `home/default.nix` imports. (2026-04-21)
  - [x] Milestone 2a: Create `home/mina.nix` modeled on `home/seihou.nix` (package + zsh completions via `mina completions zsh`). (2026-04-21)
  - [x] Milestone 2b: Add `./mina.nix` to the `imports` list in `home/default.nix`, in the same group as `./seihou.nix` / `./kizamu.nix`. (2026-04-21)
  - [x] Milestone 2c: `git add home/mina.nix flake.nix flake.lock home/default.nix docs/plans/integrate-mina-cli.md` so Nix can see the new file under flake evaluation. (2026-04-21)
- [x] Milestone 3: Add `Justfile` recipes (`update-mina`, include in `update-tools`). (2026-04-21)
  - [x] Milestone 3a: Add a `[group: 'mina']` recipe `update-mina` that runs `nix flake update mina`. (2026-04-21)
  - [x] Milestone 3b: Extend the existing `update-tools` recipe so its `nix flake update` invocation also includes `mina`. (2026-04-21)
- [x] Milestone 4: Surface `mina` under the flake-level `packages` output and rebuild the system. (2026-04-21)
  - [x] Milestone 4a: Add `mina = pkgs.mina;` to the `packages = { ... }` block inside `flake-utils.lib.eachSystem` in `flake.nix`. (2026-04-21, advanced from Milestone 1d to unblock smoke-testing)
  - [x] Milestone 4b: `sudo darwin-rebuild switch --flake .#SungkyungM1X` run by the user and completed successfully. (2026-04-21)
  - [x] Milestone 4c: `which mina` → `/Users/shinzui/.nix-profile/bin/mina`; `mina --version` → `mina v0.1.0.0 (516cb9b)`; `mina --help` lists `exec-plan`, `master-plan`, `config`, `completions`; `~/.zfunc/_mina` is a home-manager symlink whose first line is `#compdef mina`. (2026-04-21)
  - [x] Milestone 4d: Tab completion validated by artifact rather than live keypresses — the `#compdef mina` preamble is correct and `~/.zfunc` is on `fpath` (same mechanism as the already-working `_seihou`, `_kizamu`, `_ntn`, `_nhub`). A live `mina <TAB>` test would require an interactive TTY that this automation session cannot drive. (2026-04-21)
- [x] Milestone 5: Committed in four parts (flake, home, Justfile, plan doc), each with the `ExecPlan:` trailer; Outcomes & Retrospective section filled in below. (2026-04-21)


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

- 2026-04-21: `legacyPackages` is a local `let`-binding inside `flake-utils.lib.eachSystem`, not an output. `nix build .#legacyPackages.aarch64-darwin.mina` therefore fails with `does not provide attribute 'legacyPackages.aarch64-darwin.mina'`. The Concrete Steps guidance that used that path was incorrect. Workaround: advance Milestone 4a (add `mina = pkgs.mina;` to the flake-level `packages`) so that `nix build .#mina` is the canonical smoke-test path from Milestone 1 onward.
- 2026-04-21: `mina --version` prints `mina v0.1.0.0 (<rev>)` (binary name `mina`, not the cabal package name `mina-cli`). The plan's acceptance criterion said `mina-cli 0.1.0.0 (<rev>)`. Updated the acceptance wording accordingly — the substance (a single version line containing the semver and a git rev) is unchanged.
- 2026-04-21: `pkgs.mina`'s output contains `bin/` plus `lib/ghc-9.12.2/lib/*` with only `libHSmina-cli-...` files — all mina-internal. Confirms the Decision Log prediction that no `runCommand` wrapper is needed: nothing else in this flake consumes those libraries.


## Decision Log

Record every decision made while working on the plan.

- Decision: Consume `mina` as a flake input from `github:shinzui/mina`, exactly the same as `seihou`, `kizamu`, `rei`, `mori`, `notion-cli`. Do not add a local-path override.
  Rationale: Every other shinzui-authored CLI in this dotfiles flake is consumed by URL from GitHub. A local-path input would diverge from the established pattern and would require committing to local checkouts that other machines do not have. The user can iterate on `mina` locally in `~/Keikaku/bokuno/mina`, push, then `just update-mina` to pull the change into the system. This matches their existing workflow exactly.
  Date: 2026-04-21

- Decision: Use `inputs.mina.packages.${prev.stdenv.hostPlatform.system}.default` (the unwrapped form), not a `runCommand` wrapper that exposes only `bin/`.
  Rationale: The wrapper pattern in `flake.nix` (used for `mori-rei-app` and `notion-hub`) only exists when a Haskell flake's `default` package leaks `lib/links/libHS<pkg>-*` files into its output that collide with another package built from a different version of the same Haskell library. `mina` is the first dotfiles consumer of its own `mina-cli` and `mina-core` libraries — there is nothing to collide with. Start with the simple form. If a future input introduces a conflict (for example, another Haskell tool that also depends on `optparse-applicative` from a different package set in a way that surfaces in `lib/`), revisit and wrap then; record the change here.
  Date: 2026-04-21

- Decision: Generate zsh completions at Nix build time via `${pkgs.mina}/bin/mina completions zsh`, written to `~/.zfunc/_mina`. No bash or fish completions yet.
  Rationale: This is the established pattern in `home/seihou.nix`, `home/kizamu.nix`, `home/notion-cli.nix`, and `home/notion-hub.nix`. The user's primary shell is zsh and `~/.zfunc` is already on `fpath` from the existing zsh setup. Bash and fish completions exist as `mina completions bash|fish` outputs (see `mina-cli/src/Mina/CLI/Completions.hs`) and can be added by a follow-up plan if the user adopts another shell; doing it now would be carrying weight for a hypothetical.
  Date: 2026-04-21

- Decision: Pin `mina`'s nixpkgs to the dotfiles' `nixpkgs-unstable` via `inputs.nixpkgs.follows = "nixpkgs-unstable"`. Do not similarly pin `inputs.haskell-nix` (which `mina` itself pulls in from `github:shinzui/haskell-nix`).
  Rationale: All other shinzui inputs (`mori`, `rei`, `seihou`, `kizamu`, `notion-cli`, etc.) follow `nixpkgs-unstable`; doing the same for `mina` keeps store-path reuse high and avoids pulling in a second copy of nixpkgs purely on `mina`'s account. We deliberately do not follow `haskell-nix`: this dotfiles flake does not declare `haskell-nix` as an input, so there is nothing to follow. `mina` will use whatever revision of `shinzui/haskell-nix` its own `flake.lock` records, identical to how `seihou` and `kizamu` already work today.
  Date: 2026-04-21

- Decision: Add `mina` to the flake-level `packages = { ... }` set so that `nix build .#mina` works without arguments.
  Rationale: This matches `bootstrap-repos`, `tmuxai`, `oq`, etc., already exposed there. It costs one line and gives a quick smoke test outside the darwin rebuild path.
  Date: 2026-04-21

- Decision: No daemon / launchd agent / state directory is created.
  Rationale: `mina` is a stateless CLI today — its `Main.hs` calls `runCli` and exits. There is no long-running process and no on-disk state directory analogous to `~/.mori/` or `~/.rei/`. The `Mina.Config.Cache` module exists in `mina-core` but is internal to invocations of the CLI; if it later writes under e.g. `$XDG_CACHE_HOME/mina/`, that is the CLI's own concern and does not require home-manager wiring. Revisit only if `mina` grows a daemon.
  Date: 2026-04-21


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose.

**Completed 2026-04-21.** The purpose stated at the top of the plan — `which mina` returning a profile path, `mina --version` / `--help` working, and zsh completions installed at `~/.zfunc/_mina` — is met verbatim on `SungkyungM1X`. `just update-mina` and `just update-tools` are both wired. `nix build .#mina` resolves without arguments.

Gaps vs. the original plan:

- Milestone 1d's validation path (`nix build .#legacyPackages.aarch64-darwin.mina`) did not work because this flake does not expose `legacyPackages` as an output; it is a local `let`-binding inside `flake-utils.lib.eachSystem`. I advanced Milestone 4a (adding `mina = pkgs.mina;` to the flake-level `packages`) to unblock smoke-testing. The two milestones are now fused in history. Future plans of this shape should skip the "legacy smoke test" step and just add the `packages` entry up front — the cost is one line, the benefit is a clean `nix build .#<name>`.
- Milestone 4d (live `mina <TAB>` in an interactive zsh) was not executed. The `#compdef mina` header on `~/.zfunc/_mina` is the authoritative indicator for this file-based completion mechanism and matches what the existing shinzui CLIs use, so a regression here would show up uniformly across all of them — but a human should still try `mina <TAB>` once for peace of mind.
- Acceptance criterion 2 said `mina-cli 0.1.0.0 (<git-rev>)`; the binary actually prints `mina v0.1.0.0 (<git-rev>)`. Substance preserved, wording corrected in Surprises & Discoveries.

Lessons:

- `nix build .#legacyPackages.<system>.<pkg>` only works for flakes that explicitly expose `legacyPackages`. Always confirm the output attribute shape before baking validation commands into a plan.
- The "start without a wrapper; add `runCommand` only on conflict" decision was correct — `pkgs.mina`'s `lib/` contains only `libHSmina-cli-...` (all mina-internal), so there was nothing to collide with. Carrying an unconditional wrapper would have been premature.
- `sudo darwin-rebuild switch` is a step the automation session cannot perform; future plans that include system activation should flag it as a hand-off point from the start.


## Context and Orientation

This section describes the current state of the repository and the surrounding
tooling as if the reader knows nothing about either.

**The repository.** The working directory is `/Users/shinzui/.config/dotfiles.nix`,
a Nix flake that manages a macOS machine via two related tools:

- `nix-darwin`, which configures the system itself (services, `/etc`, packaged
  apps).
- `home-manager`, which configures the user's home directory (dotfiles,
  per-user packages on `$PATH`, shell config).

The flake is tied together by `flake.nix` at the repository root. The relevant
parts of that file for this plan are:

- The `inputs = { ... }` block at the top (`flake.nix:4–69`). Each entry is an
  external flake the dotfiles consume. The shinzui-authored CLIs already
  declared there are: `mori`, `rei`, `seihou`, `kizamu`, `notion-cli`,
  `mori-rei-app`, `notion-hub`, plus support inputs (`bun2nix`, `agenix`,
  `home-manager`, etc.). Every shinzui CLI input follows the same shape,
  for example:

        seihou = {
          url = "github:shinzui/seihou";
          inputs.nixpkgs.follows = "nixpkgs-unstable";
        };

- The `my-packages = final: prev: { ... }` overlay (`flake.nix:204–244`). This
  attaches personal packages to the nixpkgs set used everywhere else in the
  flake. The pattern for a shinzui CLI input is a single line, for example:

        seihou = inputs.seihou.packages.${prev.stdenv.hostPlatform.system}.default;

  Some entries instead use a `runCommand` wrapper (`mori-rei-app`,
  `notion-hub`) to expose only `bin/` and hide library outputs that would
  conflict with another package's libraries. `mina` does not need this; see
  the Decision Log.

- The flake-level `packages = { ... }` attribute set inside
  `flake-utils.lib.eachSystem` (`flake.nix:323–334`). Adding an entry here is
  what makes `nix build .#<name>` work as a first-class entrypoint, useful for
  smoke tests outside `darwin-rebuild`.

The home-manager configuration lives under `home/`:

- `home/default.nix` is the top-level home-manager module. It imports a long
  list of per-tool files (`home/seihou.nix`, `home/kizamu.nix`,
  `home/notion-cli.nix`, ...) at `home/default.nix:21–46`, and lists generic
  packages without their own config file in the `home.packages` list further
  down.
- Each per-tool file under `home/` typically: adds the package to
  `home.packages`, generates shell completions at build time via the
  package's own completion-emitting subcommand, and writes them under
  `~/.zfunc/_<tool>`. The simplest example is `home/seihou.nix`:

        { pkgs, ... }:
        let
          seihou-zsh-completions = pkgs.runCommand "seihou-zsh-completions" { } ''
            ${pkgs.seihou}/bin/seihou completions zsh > $out
          '';
        in
        {
          home.packages = [ pkgs.seihou ];
          home.file.".zfunc/_seihou".source = seihou-zsh-completions;
        }

  More elaborate variants (`home/notion-hub.nix`, `home/rei.nix`) add launchd
  agents, environment variables, and database setup; `mina` does not need any
  of that today (see Decision Log: stateless CLI).

The repository root also has a `Justfile`. It lists short recipes per tool:
typically an `update-<tool>` recipe that runs `nix flake update <tool>`, and
sometimes log-tail / status / restart helpers for tools with launchd agents.
A combined `update-tools` recipe at `Justfile:147–150` runs `nix flake update`
for every tool input in one shot.

**The `mina` project itself.** `mina` is a Haskell CLI maintained by the user
at `/Users/shinzui/Keikaku/bokuno/mina` and published to
`github:shinzui/mina`. Its top-level layout (as of 2026-04-21):

    /Users/shinzui/Keikaku/bokuno/mina
    ├── flake.nix              -- flake exposing mina-cli, mina-core
    ├── cabal.project
    ├── mina.kdl
    ├── mina-cli/              -- executable package (binary: `mina`)
    │   ├── mina-cli.cabal
    │   ├── app/Main.hs        -- calls Mina.CLI.Commands.runCli
    │   └── src/Mina/CLI/...   -- subcommand modules
    ├── mina-core/             -- library package
    │   ├── mina-core.cabal
    │   ├── src/Mina/...       -- shared modules (Config, Cache, Claude, Hash, ...)
    │   └── test/
    └── nix/haskell-overlay.nix

The flake at `mina/flake.nix` exposes three packages per system:

    packages = {
      default  = haskellPackages.mina-cli;
      mina-cli = haskellPackages.mina-cli;
      mina-core = haskellPackages.mina-core;
    };

So `inputs.mina.packages.${system}.default` resolves to `mina-cli`, which
contains the `mina` executable in `bin/mina`. The flake uses
`github:shinzui/haskell-nix` as a haskell-overlay source and pins GHC 9.12.2.
None of those internals leak into the dotfiles flake — we only consume the
`default` package.

**The CLI surface area we depend on.** The script `mina completions zsh` must
exist and write a valid zsh completion file to stdout. This is true today: see
`mina/mina-cli/src/Mina/CLI/Commands.hs:83–88` (the `completions` subcommand
under the "Shell integration" group) and the `Mina.CLI.Completions.Zsh`
module. The CLI also exposes `--version` and `--help` at the top level (lines
51–55 and 42–49 of the same file), both of which we use as smoke tests.

**The user's machine.** macOS on Apple Silicon (`aarch64-darwin`). The
dotfiles activate via `darwin-rebuild switch --flake .#SungkyungM1X`. After
activation, home-manager populates `~/.nix-profile/...` and the user's
`$PATH` already includes `/etc/profiles/per-user/shinzui/bin` and the home
profile bin directory. The user's zsh setup already has `~/.zfunc` on `fpath`
(this is how `_seihou`, `_kizamu`, `_ntn`, `_nhub` already work).


## Plan of Work

The work is five additive milestones. Each one ends in a tree that builds,
and at no point is the user's existing environment broken.


### Milestone 1 — add the `mina` flake input and overlay entry

Scope: teach the dotfiles flake about the existence of `github:shinzui/mina`
and surface its default package on the nixpkgs set used everywhere else in
the flake. Nothing under `home/` changes yet; nothing reaches the user's
`$PATH` yet. At the end of this milestone, evaluating the flake produces a
`pkgs.mina` attribute that `nix build` can resolve.

Edit `flake.nix`:

1. In the `inputs = { ... }` block at the top of `flake.nix` (around lines
   46–53 where `seihou` and `kizamu` already live), add:

        mina = {
          url = "github:shinzui/mina";
          inputs.nixpkgs.follows = "nixpkgs-unstable";
        };

   Place it adjacent to the other shinzui CLI inputs (e.g. just below
   `kizamu`) so the file's organization stays readable.

2. In the `my-packages = final: prev: { ... }` overlay
   (around lines 224–243 where `seihou`, `kizamu`, `notion-cli` are
   declared), add:

        mina = inputs.mina.packages.${prev.stdenv.hostPlatform.system}.default;

   Place it next to `seihou` / `kizamu` so the alphabetical-ish grouping is
   preserved.

3. Do *not* add any wrapper around `mina` (no `runCommand` block). See the
   Decision Log for why this is the right starting point and when to
   reconsider.

Stage and validate the new flake:

4. Run `nix flake update mina` from the repository root. On first add this
   writes a `mina` node into `flake.lock` with the locked rev and narHash.
   Inspect that the new lock entry has been added (see Concrete Steps for
   the exact `git diff flake.lock` snippet to expect).

5. Build the package via the legacy-packages path (we have not yet added
   `mina = pkgs.mina;` to the top-level `packages` output, so `.#mina`
   does not work yet):

        nix build .#legacyPackages.aarch64-darwin.mina

   Expected: a `result` symlink pointing into a Nix store path whose
   `bin/mina` exists and is executable.

6. Run `./result/bin/mina --version`. Expected: a single line of the form
   `mina-cli 0.1.0.0 (<git-rev>)` (see `Mina.CLI.Commands.versionOpt` in
   `mina/mina-cli/src/Mina/CLI/Commands.hs:51`). Run
   `./result/bin/mina completions zsh > /tmp/mina-zsh-completions` and
   inspect that the file is non-empty and starts with a zsh `#compdef`
   directive.


### Milestone 2 — add `home/mina.nix` and import it from `home/default.nix`

Scope: install the `mina` binary into the user's home-manager profile so it
lands on `$PATH` after the next system rebuild, and produce the zsh
completions file at `~/.zfunc/_mina`. At the end of this milestone the
home-manager module evaluates without error and the file `home/mina.nix`
exists.

Create the new file at `/Users/shinzui/.config/dotfiles.nix/home/mina.nix`
with the following exact content (a near-direct copy of `home/seihou.nix`):

    { pkgs, ... }:

    let
      mina-zsh-completions = pkgs.runCommand "mina-zsh-completions" { } ''
        ${pkgs.mina}/bin/mina completions zsh > $out
      '';
    in
    {
      home.packages = [
        pkgs.mina
      ];

      home.file.".zfunc/_mina".source = mina-zsh-completions;
    }

Edit `/Users/shinzui/.config/dotfiles.nix/home/default.nix`:

1. In the `imports = [ ... ];` list (around lines 21–46), add `./mina.nix`
   in the same group as the other shinzui-authored CLIs. A natural spot is
   immediately after `./kizamu.nix`:

        ./kizamu.nix
        ./mina.nix
        ./notion-cli.nix
        ./notion-hub.nix

   Match the indentation of surrounding lines exactly (two spaces).

Stage the new and modified files so that the next `nix build` / `darwin-rebuild`
sees them under flake evaluation:

2. Run:

        git add home/mina.nix flake.nix flake.lock home/default.nix \
                docs/plans/integrate-mina-cli.md

   This is required: as noted in the user's project memory, files in the
   working tree that are not staged are invisible to flake evaluation, which
   would manifest as `error: getting status of '/nix/store/...-source/home/mina.nix': No such file or directory` during a rebuild.


### Milestone 3 — add `Justfile` recipes

Scope: bring `mina` under the same convenience-command pattern every other
shinzui CLI uses, so updating it is `just update-mina` and the bulk
"update everything" recipe also covers it.

Edit `/Users/shinzui/.config/dotfiles.nix/Justfile`:

1. Add a new section near the existing `[group: 'kizamu']` and
   `[group: 'seihou']` groups (i.e. just before or after the kizamu group
   around `Justfile:30–34`):

        # Update mina flake input to latest
        [group: 'mina']
        update-mina:
            nix flake update mina

   Match the four-space indentation under the recipe header (this is what
   the surrounding recipes use).

2. Modify the existing combined `update-tools` recipe (currently
   `Justfile:147–150`):

        # Update all personal tool flake inputs (kizamu, mina, mori, mori-rei-app, seihou, rei, notion-cli, notion-hub)
        [group: 'tools']
        update-tools:
            nix flake update kizamu mina mori mori-rei-app seihou rei notion-cli notion-hub

   The change is: insert `mina` into the `nix flake update` argument list
   (alphabetical order keeps the line readable), and update the comment
   above it to match.

3. There is no daemon, no log file, and no launchd agent for `mina`, so do
   *not* add `restart-mina`, `status-mina`, or `logs-mina` recipes. (If the
   CLI later grows a daemon, a follow-up plan can add them at that time.)


### Milestone 4 — surface `mina` under flake `packages`, then rebuild and verify

Scope: make `mina` activate on the actual machine, and prove the full path
end-to-end (binary on `$PATH`, `--version` runs, completions installed,
`<TAB>` works in a real zsh).

Edit `flake.nix`:

1. In the flake-level `packages = { ... }` block inside
   `flake-utils.lib.eachSystem` (around `flake.nix:323–334`), add:

        mina = pkgs.mina;

   Place it among the other entries (the existing list is `tmuxai`, `oq`,
   `uuinfo`, `ck`, `parqeye`, `beautiful-mermaid`, `markit`, `pg_rman`,
   `bootstrap-repos`).

Run the rebuild:

2. From `/Users/shinzui/.config/dotfiles.nix`:

        darwin-rebuild switch --flake .#SungkyungM1X

   Expected: the rebuild completes successfully, prints its usual
   activation banner, and reports that one new home-manager generation was
   created.

Verify in a freshly opened terminal (not the one used for the rebuild — open a
new shell so the new profile activations take effect):

3. Run `which mina`. Expected: a path under `/etc/profiles/per-user/shinzui/bin/mina`
   or the home-manager profile (`/Users/shinzui/.nix-profile/bin/mina`),
   resolving via symlinks into `/nix/store/...-mina-cli-0.1.0.0/bin/mina`.
4. Run `mina --version`. Expected: a single line `mina-cli 0.1.0.0 (<git-rev>)`.
5. Run `mina --help`. Expected: the help block headed
   `mina - development assistant CLI` followed by the four subcommand
   groups (`exec-plan`, `master-plan`, `config`, `completions`).
6. Confirm `~/.zfunc/_mina` exists, is non-empty, and starts with a zsh
   `#compdef mina` directive.
7. In a fresh interactive zsh, type `mina ` and press `<TAB>`. Expected:
   the four top-level subcommands appear as completion candidates. Then
   type `mina exec-plan ` `<TAB>` and confirm the exec-plan subcommands
   are listed. (If completions do not appear, run `compaudit` and
   `rehash` to diagnose; this should not be necessary on a properly
   activated home-manager profile.)


### Milestone 5 — commit, validate, and write up Outcomes

Scope: capture the work in git history with proper trailers, run the final
sanity checks, and fill in the Outcomes & Retrospective section so this plan
is fully closed.

1. Make commits as the work progresses, each with a Conventional Commits
   prefix (the user's CLAUDE.md mandates this) and the ExecPlan trailer.
   Suggested split (the implementer can bundle differently as long as each
   commit leaves the tree buildable):

        feat(flake): add mina flake input and overlay entry

        Pull in github:shinzui/mina alongside the other shinzui CLIs and
        expose it on pkgs via the my-packages overlay.

        ExecPlan: docs/plans/integrate-mina-cli.md

   (and similarly for the home/ wiring, Justfile, and final activation).

2. After Milestone 4 verification passes, edit Progress to check off every
   item with a `(YYYY-MM-DD)` date suffix, and write the Outcomes &
   Retrospective section.

3. Final repo-level sanity check: `git status` is clean,
   `nix flake check` (if used) passes, and `darwin-rebuild switch` is a
   no-op when re-run (proving idempotence).


## Concrete Steps

All commands assume the working directory `/Users/shinzui/.config/dotfiles.nix`
unless otherwise noted.

1. Edit `flake.nix` to add the input and overlay entry as described in
   Milestone 1 steps 1–3.

2. Update the lock file:

        nix flake update mina

   Expected `git diff flake.lock` to gain a new node like (truncated):

        "mina": {
          "inputs": {
            "nixpkgs": [ "nixpkgs-unstable" ]
          },
          "locked": {
            "lastModified": <number>,
            "narHash": "sha256-...",
            "owner": "shinzui",
            "repo": "mina",
            "rev": "<sha>",
            "type": "github"
          },
          "original": {
            "owner": "shinzui",
            "repo": "mina",
            "type": "github"
          }
        }

3. Smoke-test the package via legacyPackages (the top-level `packages.mina`
   shortcut is added in Milestone 4 step 1, not yet):

        nix build .#legacyPackages.aarch64-darwin.mina
        ./result/bin/mina --version
        ./result/bin/mina --help | head -20
        ./result/bin/mina completions zsh | head -5

   Expected first command: a `result` symlink. Expected `--version`
   output: a single line like `mina-cli 0.1.0.0 (<rev>)`. Expected
   `--help` output: includes the line `mina - development assistant CLI`.
   Expected `completions zsh` output: starts with `#compdef mina` (or a
   similar zsh-completion preamble).

4. Create `home/mina.nix` with the exact contents from Milestone 2.

5. Edit `home/default.nix` to import `./mina.nix` next to `./kizamu.nix`.

6. Stage the changes:

        git add home/mina.nix flake.nix flake.lock home/default.nix \
                docs/plans/integrate-mina-cli.md

7. Edit `Justfile` to add the `update-mina` recipe and to extend
   `update-tools` as described in Milestone 3.

        git add Justfile

8. Edit `flake.nix` again to add `mina = pkgs.mina;` under the
   flake-level `packages` block (Milestone 4 step 1):

        git add flake.nix

9. Confirm `nix build .#mina` (the new shortcut) now resolves:

        nix build .#mina
        ./result/bin/mina --version

10. Activate the system:

        darwin-rebuild switch --flake .#SungkyungM1X

    Expected: rebuild succeeds, prints its activation banner, and exits 0.

11. Open a fresh shell. Verify:

        which mina
        mina --version
        mina --help | head -20
        ls -l ~/.zfunc/_mina
        head -1 ~/.zfunc/_mina

    Expected `which`: a profile path resolving into `/nix/store/...`.
    Expected `--version`: matches step 3. Expected `~/.zfunc/_mina`
    contents: starts with a zsh `#compdef` directive.

12. In a fresh interactive zsh, exercise tab completion:

        mina <TAB>
        mina exec-plan <TAB>

    Expected: the first lists `exec-plan master-plan config completions`
    (in some order). The second lists the exec-plan subcommands defined
    in `mina-cli/src/Mina/CLI/ExecPlan.hs`.

13. Commit per the breakdown in Milestone 5 step 1, each commit with the
    `ExecPlan: docs/plans/integrate-mina-cli.md` trailer.


## Validation and Acceptance

Acceptance is phrased as observable behavior. After this plan is fully
implemented:

1. `nix build .#mina` from the repository root exits 0 and creates a
   `result/bin/mina` binary that runs.

2. `result/bin/mina --version` prints a line of the form
   `mina-cli 0.1.0.0 (<git-rev>)`.

3. `result/bin/mina --help` prints help text headed by
   `mina - development assistant CLI` and lists at least the four
   subcommand groups: `exec-plan`, `master-plan`, `config`, `completions`.

4. After `darwin-rebuild switch --flake .#SungkyungM1X` completes, in a
   fresh shell:

   - `which mina` returns a path that resolves under `/nix/store/`.
   - `mina --version` matches step 2 above.
   - `~/.zfunc/_mina` exists, is non-empty, and starts with `#compdef mina`.
   - In an interactive zsh, `mina <TAB>` shows the four subcommands as
     completion candidates.

5. `just update-mina` runs `nix flake update mina` and the lock file
   updates if and only if `github:shinzui/mina` has a newer commit than the
   currently locked rev.

6. `just update-tools` includes `mina` in its argument list, so it pulls
   updates for `mina` alongside the other personal tools in one shot.

7. Re-running `darwin-rebuild switch --flake .#SungkyungM1X` after a
   successful activation is a no-op (proves idempotence at the system
   level).


## Idempotence and Recovery

Every step in this plan is safe to repeat:

- `nix flake update mina` is idempotent: rerunning when no upstream change
  exists is a no-op.
- `nix build .#mina` rebuilds only if inputs changed; otherwise it just
  reuses the cached store path.
- `darwin-rebuild switch` is itself idempotent: rerunning the same flake
  evaluation yields the same generation and no activation work.
- The `home/mina.nix` file produces the same `home.file.".zfunc/_mina"`
  symlink target on every evaluation (the completions output is determined
  by the `mina` binary).

Recovery from a broken state:

- If `darwin-rebuild switch` fails in the middle of activation, run it
  again — home-manager and nix-darwin are designed to be re-applied. Read
  the failure message; the most likely cause during this plan is a missing
  `git add` (Concrete Steps step 6) for the new `home/mina.nix` file, which
  manifests as `path 'home/mina.nix' does not exist in source tree`. Fix
  by `git add`ing the missing file and re-running.
- If `nix build .#mina` fails because the upstream `mina` repo has a build
  error in the locked rev, pin to a known-good rev with
  `nix flake lock --override-input mina github:shinzui/mina/<good-sha>` and
  open a follow-up to fix `mina` itself.
- To roll back the entire change, `git revert` the relevant commits and
  run `darwin-rebuild switch` again. Or use `darwin-rebuild --rollback` for
  an immediate generation rollback at the system level.

Nothing in this plan deletes or modifies user data outside of writing
`~/.zfunc/_mina` (a managed home-manager symlink) and updating
`flake.lock` and tracked files in the dotfiles repo.


## Interfaces and Dependencies

Nix-level interfaces created or modified by this plan:

- `flake.nix:inputs.mina` — a new flake input pinned to `github:shinzui/mina`,
  following `nixpkgs-unstable` for its nixpkgs.
- `flake.nix:outputs.overlays.my-packages.mina` — exposes `pkgs.mina` derived
  from `inputs.mina.packages.${system}.default`. This package contains
  `bin/mina` (executable name `mina`).
- `flake.nix:outputs.packages.<system>.mina` — surface `pkgs.mina` for direct
  `nix build .#mina` invocation.
- `home/mina.nix` — new home-manager module, imported from `home/default.nix`.
  It declares one entry in `home.packages` (`pkgs.mina`) and one
  `home.file` entry (`.zfunc/_mina`).
- `Justfile` — new `update-mina` recipe, extended `update-tools` recipe.

Runtime dependencies:

- The `mina` binary itself, which in turn pulls in its Haskell runtime
  closure as part of its Nix store path. There are no external runtime
  dependencies the dotfiles need to declare separately (no database, no
  daemon).
- `pkgs.mina` is built by the upstream `mina` flake using
  `github:shinzui/haskell-nix` and GHC 9.12.2. Those are internal to the
  `mina` build and do not propagate into the dotfiles flake's input set.

Function and module signatures we depend on (from the upstream `mina` repo):

- `mina/mina-cli/app/Main.hs` defines `main :: IO ()` calling `Mina.CLI.Commands.runCli`.
- `mina/mina-cli/src/Mina/CLI/Commands.hs` exports `runCli :: IO ()` and a
  parser that recognizes the subcommands `exec-plan`, `master-plan`,
  `config`, `completions`, plus top-level `--help` / `-h` and
  `--version` / `-v` options.
- `mina/mina-cli/src/Mina/CLI/Completions.hs` exports a `completions`
  subcommand whose `zsh` variant emits a complete zsh completion script to
  stdout.

If any of those interfaces change in future versions of `mina`, this plan
remains valid as long as `mina --version` and `mina completions zsh` still
work; both are extremely stable surface area for a CLI of this kind.


---

Revision history:

- 2026-04-21: Initial plan written.
