# Version XDG App Configs with Out-of-Store Symlinks

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

This document is maintained in accordance with `.claude/skills/exec-plan/PLANS.md`.


## Purpose / Big Picture

Many app configurations live under `~/.config/` (e.g., `~/.config/rei/config.yaml`) but are not tracked in this dotfiles repository. If the machine dies or is replaced, those configs are lost. At the same time, these configs change frequently during normal use — editing a YAML key, tweaking an agent definition — and running `darwin-rebuild switch` just to pick up a one-line config edit is too heavy.

After this change, you will be able to copy an app config directory into `config/xdg/` in this repository, add its name to an explicit list in `home/xdg-configs.nix`, run one rebuild to register the symlink, and then freely edit the config file forever without rebuilding again. On a fresh machine, `darwin-rebuild switch` will recreate all the symlinks automatically. Both the config files and the symlink declarations are tracked in git — the file contents carry full edit history, and the Nix module records when each config was added or removed from version control.


## Progress

- [x] Create the `config/xdg/` directory and seed it with the rei config. (2026-04-16)
- [x] Create `home/xdg-configs.nix` module with explicit tracked-configs list. (2026-04-16)
- [x] Import `xdg-configs.nix` in `home/default.nix`. (2026-04-16)
- [x] Run `darwin-rebuild switch` and verify the symlink for `~/.config/rei`. (2026-04-16)
- [x] Confirm that editing `config/xdg/rei/config.yaml` is immediately visible at `~/.config/rei/config.yaml` without a rebuild. (2026-04-16)


## Surprises & Discoveries

(None yet.)


## Decision Log

- Decision: Use an explicit list of tracked configs rather than `builtins.readDir` auto-discovery.
  Rationale: An explicit list makes the "decision to track this config" a visible git commit — you can see when each app was added or removed from version control by reading the Nix file history. Auto-discovery would hide that intent behind directory creation, making it harder to audit what is tracked and why. The small cost of editing one line in the Nix module when adding a new config is worth the clarity.
  Date: 2026-04-16

- Decision: Symlink at the directory level, not individual files.
  Rationale: Most XDG-compliant apps expect a directory under `~/.config/appname/`. Symlinking the whole directory is simpler and means any file the user adds inside that directory is automatically tracked. If an app mixes config with runtime state (caches, databases), the user should either gitignore the runtime files or handle that app with an explicit module instead.
  Date: 2026-04-16

- Decision: Keep existing `external-configs.nix` entries (pgcli, yamllint, pspg, bird) as-is for now.
  Rationale: Those configs work today. Migrating them to the new `config/xdg/` pattern would be a nice consistency improvement but is out of scope for this plan. It can be done as a follow-up.
  Date: 2026-04-16

- Decision: No standalone bootstrap script outside of Nix.
  Rationale: On a new machine, the user will run `darwin-rebuild switch` anyway, which activates home-manager and creates all symlinks. A separate script would be redundant. The one place a script would help is adding a new config without rebuilding, but the rebuild is a one-time cost per new app, and edits (the common case) are already free.
  Date: 2026-04-16


## Outcomes & Retrospective

(To be filled during and after implementation.)


## Context and Orientation

This repository at `/Users/shinzui/.config/dotfiles.nix` is a Nix flake that configures macOS via nix-darwin with home-manager integrated as a nix-darwin module. All user-level configuration lives under the `home/` directory as individual `.nix` files imported by `home/default.nix`.

Raw (non-Nix) config files live under `config/`. Today this directory contains configs for nvim, hammerspoon, pgcli, pspg, psqlrc, yamllint, and bird. These are wired to their target locations by two mechanisms:

The first mechanism is Nix-store copies, used in `home/external-configs.nix`. This file uses `home.file."path".source = ../config/file` which copies the config into the Nix store and symlinks `~/.config/path` to the store path. Editing the source file requires a rebuild to propagate because the symlink target is a store path, not the working tree.

The second mechanism is out-of-store symlinks, used in `home/neovim.nix` and `home/hammerspoon.nix`. These use `config.lib.file.mkOutOfStoreSymlink` to create a symlink that points directly to the file on disk at its absolute path under `~/.config/dotfiles.nix/config/`. Edits to the source file take effect immediately because the symlink target is the actual file, not a Nix store copy. This is the mechanism we will use.

The variable `nixConfigDir` is defined as `"${config.home.homeDirectory}/.config/dotfiles.nix"` and is already used in `home/neovim.nix` (line 6) and `home/hammerspoon.nix` (line 5) for constructing out-of-store symlink paths.

Home-manager provides `xdg.configFile` as a convenience attrset. Setting `xdg.configFile."appname".source = path` places a symlink at `~/.config/appname` pointing to `path`. When the source is an `mkOutOfStoreSymlink` call, the symlink chain is: `~/.config/appname` -> home-manager generation link -> actual file on disk. The key point is that edits to the actual file propagate immediately.

`lib.genAttrs` is a nixpkgs library function that takes a list of names and a function, producing an attribute set keyed by those names. It is used here to generate `xdg.configFile` entries from an explicit list of config names. This makes the set of tracked configs visible and auditable in git history — every addition or removal is a one-line diff in the Nix module.


## Plan of Work

The work is a single milestone since it is small and linear.


### Milestone 1: Explicitly tracked XDG config symlinks

At the end of this milestone, a new directory `config/xdg/` exists containing the rei config as the first entry. A new home-manager module `home/xdg-configs.nix` declares an explicit list of config names to track and creates an `mkOutOfStoreSymlink`-backed `xdg.configFile` entry for each one. The module is imported by `home/default.nix`. After one `darwin-rebuild switch`, `~/.config/rei` is a symlink chain pointing to `config/xdg/rei/` in this repo, and edits to `config/xdg/rei/config.yaml` are instantly visible at `~/.config/rei/config.yaml`. Both the config file contents and the symlink declarations are committed to git, giving full history of what is tracked and what changed.

Acceptance: `readlink ~/.config/rei` shows a path through the home-manager generation that ultimately resolves to the repo. `cat ~/.config/rei/config.yaml` matches `cat config/xdg/rei/config.yaml`. Editing `config/xdg/rei/config.yaml` and re-reading `~/.config/rei/config.yaml` shows the change without any rebuild. `git log --oneline -- home/xdg-configs.nix` shows when the rei config was added to tracking.


## Concrete Steps

All commands run from the repo root `/Users/shinzui/.config/dotfiles.nix` unless stated otherwise.

**Step 1: Create `config/xdg/rei/` and copy the rei config into it.**

    mkdir -p config/xdg/rei
    cp ~/.config/rei/config.yaml config/xdg/rei/config.yaml

If `~/.config/rei/` contains other files or directories that should also be versioned (like `agents/`), copy those too. The entire `config/xdg/rei/` directory will be symlinked as `~/.config/rei`.

Expected result: `config/xdg/rei/config.yaml` exists in the repo with the same content as the current `~/.config/rei/config.yaml`.


**Step 2: Create `home/xdg-configs.nix`.**

This module declares an explicit list of config names and generates an `xdg.configFile` declaration with an out-of-store symlink for each one.

    # home/xdg-configs.nix
    { config, lib, ... }:

    let
      inherit (config.lib.file) mkOutOfStoreSymlink;
      nixConfigDir = "${config.home.homeDirectory}/.config/dotfiles.nix";

      # Explicit list of app configs to symlink.
      # Each name corresponds to a directory or file under config/xdg/
      # that will be symlinked to ~/.config/<name>.
      # Adding or removing an entry here is a one-line diff tracked in git.
      trackedConfigs = [
        "rei"
      ];
    in
    {
      xdg.configFile = lib.genAttrs trackedConfigs (name: {
        source = mkOutOfStoreSymlink "${nixConfigDir}/config/xdg/${name}";
      });
    }

To track a new app config in the future, add its name to the `trackedConfigs` list. This one-line change is committed to git, creating a clear audit trail of when each config was added to or removed from version control. The corresponding files must also exist under `config/xdg/`.


**Step 3: Import the new module in `home/default.nix`.**

Add `./xdg-configs.nix` to the imports list in `home/default.nix`, after the existing `./external-configs.nix` line (line 31 in the current file). The exact insertion point does not matter as long as it is within the `imports` list.


**Step 4: Stage and rebuild.**

    git add config/xdg home/xdg-configs.nix
    darwin-rebuild switch --flake .

Nix flakes require new files to be staged before they are visible to the evaluator. The rebuild will activate home-manager, which creates the symlink at `~/.config/rei`.

Expected output: the rebuild completes without errors. Among the home-manager activation messages, you should see the rei config being linked.


**Step 5: Verify the symlink.**

    ls -la ~/.config/rei

Expected: `~/.config/rei` is a symlink. Following the chain (it may go through a home-manager generation directory) should ultimately resolve to `config/xdg/rei/` in this repo.

    diff ~/.config/rei/config.yaml config/xdg/rei/config.yaml

Expected: no differences (the files are the same because one is a symlink to the other).


**Step 6: Verify edit-without-rebuild.**

    echo "# test edit" >> config/xdg/rei/config.yaml
    tail -1 ~/.config/rei/config.yaml

Expected: the last line is `# test edit`, confirming that edits propagate immediately.

Then remove the test line:

    sed -i '' '/^# test edit$/d' config/xdg/rei/config.yaml


## Validation and Acceptance

The implementation is accepted when all of the following are true:

1. `~/.config/rei` is a symlink (possibly indirect through home-manager) whose final target is `config/xdg/rei/` in this repo.

2. Editing `config/xdg/rei/config.yaml` is instantly visible at `~/.config/rei/config.yaml` without running any Nix command.

3. Adding a new app config requires: create directory under `config/xdg/`, add the name to `trackedConfigs` in `home/xdg-configs.nix`, `git add` both, run `darwin-rebuild switch`, and the symlink appears. The commit clearly shows what was added.

4. `darwin-rebuild switch --flake .` completes without errors.

5. Existing configs managed by `external-configs.nix`, `neovim.nix`, and `hammerspoon.nix` are unaffected.


## Idempotence and Recovery

Every step is safe to repeat. Creating directories and copying files is idempotent. The Nix module produces the same output given the same `config/xdg/` contents. `darwin-rebuild switch` is idempotent by design.

If the rebuild fails, the most likely cause is a conflict between the new `xdg.configFile` entry and an existing one. For example, if `home/external-configs.nix` already declares `xdg.configFile."rei"`, home-manager will report a collision. The fix is to remove the conflicting declaration from the other module. None of the current `external-configs.nix` entries conflict with `rei`, so this should not happen for the first config, but could happen when migrating existing entries later.

If `~/.config/rei` already exists as a regular directory (not a symlink), home-manager will refuse to replace it. Back it up and remove it before rebuilding:

    mv ~/.config/rei ~/.config/rei.bak
    darwin-rebuild switch --flake .


## Interfaces and Dependencies

No new external dependencies. The implementation uses only home-manager built-ins:

- `config.lib.file.mkOutOfStoreSymlink` (home-manager) — creates a symlink pointing to an absolute path outside the Nix store.
- `lib.genAttrs` (nixpkgs lib) — takes a list of names and a function, returns an attrset keyed by those names.
- `xdg.configFile` (home-manager) — declares files/symlinks under `~/.config/`.

The module signature is:

    In home/xdg-configs.nix, the module takes { config, lib, ... } and produces:

        xdg.configFile.<name>.source :: Path

    for every <name> in the trackedConfigs list.


## Future Considerations

The existing entries in `home/external-configs.nix` (pgcli, yamllint, pspg, bird) use Nix-store copies, meaning edits require a rebuild. These could be migrated to `config/xdg/` to gain the same edit-without-rebuild benefit. This is out of scope for this plan but would be a natural follow-up:

- Move `config/yamllint` to `config/xdg/yamllint/config` (yamllint expects `~/.config/yamllint/config`)
- Move `config/pgcli` to `config/xdg/pgcli/config`
- Move `config/pspg/` to `config/xdg/pspg/`
- Move `config/bird.json5` to `config/xdg/bird/config.json5`
- Remove the corresponding lines from `home/external-configs.nix`

Non-XDG configs like `~/.psqlrc` cannot use this mechanism and should continue to use `home.file` (or be converted to `mkOutOfStoreSymlink` individually).


## Revision Notes

- 2026-04-16: Replaced `builtins.readDir` auto-discovery with an explicit `trackedConfigs` list in the Nix module. Reason: the user wants to be intentional about which configs are tracked, and wants the symlink declarations committed to git so the history shows when each config was added or removed. Updated: Decision Log, Progress, Milestone 1, Concrete Steps (Step 2), Validation (point 3), Interfaces and Dependencies, Context and Orientation.
