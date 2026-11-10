# Add Hammerspoon with Focus-Follows-Mouse

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

This document is maintained in accordance with `.claude/skills/exec-plan/PLANS.md`.


## Purpose / Big Picture

After this change, Hammerspoon will be installed via Homebrew cask and managed through the dotfiles.nix configuration. A Lua configuration file will implement focus-follows-mouse behavior: as the mouse pointer moves over a window, that window automatically receives focus without requiring a click. The user can verify this by moving the mouse between overlapping windows and observing that the window under the cursor gains focus immediately.


## Progress

- [x] Add `hammerspoon` to Homebrew casks in `darwin/homebrew.nix`. (2026-03-24)
- [x] Create the Hammerspoon Lua configuration file at `config/hammerspoon/init.lua` with focus-follows-mouse logic and IPC support. (2026-03-24)
- [x] Create the home-manager module at `home/hammerspoon.nix` that symlinks the config directory and reloads Hammerspoon on activation. (2026-03-24)
- [x] Import `./hammerspoon.nix` in `home/default.nix`. (2026-03-24)
- [x] Validate the configuration builds with `darwin-rebuild`. (2026-03-24 — dry-run successful, `hm_hammerspoon.drv` produced)
- [ ] Verify Hammerspoon launches, focus-follows-mouse works, and config reloads on activation.


## Surprises & Discoveries

(None yet.)


## Decision Log

- Decision: Install Hammerspoon via Homebrew cask rather than nixpkgs.
  Rationale: Hammerspoon is a macOS GUI application that is not packaged in nixpkgs. The codebase already uses Homebrew casks for GUI apps like Ghostty, Tuple, and Discord. This is the established pattern.
  Date: 2026-03-24

- Decision: Store the Lua config in `config/hammerspoon/` and symlink via `mkOutOfStoreSymlink` rather than inline Nix strings.
  Rationale: This follows the same pattern used for neovim in `home/neovim.nix`, where Lua configuration lives in `config/nvim/lua/` and is symlinked into the XDG config directory. Keeping Lua files as actual `.lua` files enables editor support (syntax highlighting, LSP) and makes them easier to iterate on.
  Date: 2026-03-24

- Decision: Symlink the entire `~/.hammerspoon` directory to the repo config directory.
  Rationale: Hammerspoon looks for its configuration in `~/.hammerspoon/init.lua` by default (not XDG). Using `mkOutOfStoreSymlink` keeps the config editable in-place, matching the neovim pattern.
  Date: 2026-03-24

- Decision: Use `hs.window.filter` with a debounce approach rather than raw `hs.eventtap` for focus-follows-mouse.
  Rationale: The raw eventtap approach from the user's snippet fires on every single mouse-move event, which can cause excessive CPU usage and focus-fighting between windows. A refined approach uses a delayed timer so that focus only changes after the mouse has settled over a window briefly, avoiding jitter when moving the mouse across window boundaries.
  Date: 2026-03-24

- Decision: Reload Hammerspoon config on `darwin-rebuild switch` via a `home.activation` hook.
  Rationale: Without this, changes to `init.lua` only take effect when the user manually reloads Hammerspoon (menu bar > Reload Config). The repo already uses `home.activation` hooks for service lifecycle in `mori.nix`, `rei.nix`, and `postgresql.nix`. The reload uses `hs -c "hs.reload()"` which requires the IPC module to be loaded in `init.lua`. If Hammerspoon is not running, the hook silently skips the reload.
  Date: 2026-03-24

- Decision: Enable `hs.ipc` in `init.lua` to support CLI-driven reload.
  Rationale: The `hs` command-line tool communicates with the running Hammerspoon instance via IPC. Without `require("hs.ipc")` in the config, the `hs` CLI cannot send commands. This is a one-line addition that enables both the activation reload hook and ad-hoc CLI usage (e.g., `hs -c "hs.reload()"` from a terminal).
  Date: 2026-03-24


## Outcomes & Retrospective

(To be filled during and after implementation.)


## Context and Orientation

This repository is a Nix-based dotfiles configuration for macOS. It uses nix-darwin for system-level configuration and home-manager for user-level configuration. The main entry points are:

- `flake.nix` — defines the Nix flake, composing darwin modules and home-manager modules.
- `darwin/homebrew.nix` — manages Homebrew packages and casks. GUI applications are installed as casks (line 61 onward). The `onActivation.cleanup = "zap"` setting means any cask not listed here will be removed on activation.
- `home/default.nix` — the main home-manager configuration. It imports individual module files (lines 25–44) and defines packages.
- `home/neovim.nix` — an example of the symlink pattern. It uses `mkOutOfStoreSymlink` (line 5) to create a live symlink from `~/.config/nvim/lua` to `config/nvim/lua` in this repository (line 38). This means edits to the Lua files take effect immediately without rebuilding.
- `home/external-configs.nix` — an example of the static config copy pattern, where config files are copied (not symlinked) from the repo into the home directory.
- `config/` — directory containing configuration files that are symlinked or copied into the user's home.

Hammerspoon is a macOS automation tool that executes Lua scripts. It looks for its configuration at `~/.hammerspoon/init.lua` by default. The term "focus-follows-mouse" means that the window under the mouse pointer automatically becomes the focused (active) window, without requiring a mouse click.

The repo uses `home.activation` hooks (from home-manager's `lib.hm.dag` module) to run shell commands during `darwin-rebuild switch`. Examples exist in `home/mori.nix` (lines 43–84) and `home/postgresql.nix`. These hooks use `lib.hm.dag.entryAfter [ "writeBoundary" ]` to run after home-manager has written files, or `lib.hm.dag.entryBefore [ "setupLaunchAgents" ]` to run before launchd agents are reconfigured. For Hammerspoon, an `entryAfter [ "writeBoundary" ]` hook is appropriate since we want to reload after the symlink is in place.

Hammerspoon ships a command-line tool `hs` (located at `/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs`) that can send Lua commands to the running Hammerspoon instance over IPC. This requires `require("hs.ipc")` to be present in `init.lua`. The command `hs -c "hs.reload()"` tells Hammerspoon to reload its configuration.


## Plan of Work

The work has a single milestone since all changes are small and interdependent.


### Milestone 1: Install Hammerspoon and Configure Focus-Follows-Mouse

This milestone adds Hammerspoon as a Homebrew cask, creates the Lua configuration for focus-follows-mouse, and wires everything together through a home-manager module. At the end, Hammerspoon will be installed and configured so that moving the mouse over a window causes it to gain focus after a short delay.

First, add `"hammerspoon"` to the `homebrew.casks` list in `darwin/homebrew.nix`. Place it alphabetically or alongside the other desktop applications.

Second, create the configuration file `config/hammerspoon/init.lua`. This file implements focus-follows-mouse using a timer-debounced eventtap. The approach listens for mouse-move events but uses a short delay (0.2 seconds) before changing focus. This prevents rapid focus-switching when the mouse crosses window boundaries. The implementation:

1. Creates an `hs.eventtap` that listens for `mouseMoved` events.
2. On each mouse move, it resets a timer.
3. When the timer fires (after 0.2s of no further movement), it checks which window is under the mouse using `hs.window.filter`.
4. If that window differs from the currently focused window, it calls `focus()` on the target window.

The Lua code should also handle edge cases: ignore the desktop, ignore windows that belong to Hammerspoon itself, and avoid focusing windows from certain apps if needed in the future (via a configurable exclusion list).

Third, create `home/hammerspoon.nix`. This module uses `mkOutOfStoreSymlink` to symlink `~/.hammerspoon` to the `config/hammerspoon` directory in this repository, following the neovim pattern. It also defines a `home.activation.hammerspoon-reload` hook that runs after `writeBoundary`. The hook checks whether Hammerspoon is running (via `pgrep -x Hammerspoon`), and if so, uses the `hs` CLI to send `hs.reload()`. If Hammerspoon is not running, the hook silently does nothing — the config will be picked up on next launch.

Fourth, add `./hammerspoon.nix` to the imports list in `home/default.nix`.


## Concrete Steps

All commands should be run from the repository root at `/Users/shinzui/.config/dotfiles.nix`.

**Step 1: Add Hammerspoon cask.** Edit `darwin/homebrew.nix` and add `"hammerspoon"` to the `homebrew.casks` list.

**Step 2: Create the Lua configuration.** Create the file `config/hammerspoon/init.lua` with IPC support and the focus-follows-mouse implementation. The file contents:

    -- Enable IPC so the `hs` CLI can communicate with the running instance.
    -- This is required for the activation reload hook to work.
    require("hs.ipc")

    -- Focus follows mouse
    -- When the mouse hovers over a window for a brief moment, that window gains focus.

    local focusDelay = 0.3
    local focusTimer = nil

    local mouseMoved = hs.eventtap.new({ hs.eventtap.event.types.mouseMoved }, function()
      if focusTimer then
        focusTimer:stop()
      end

      focusTimer = hs.timer.doAfter(focusDelay, function()
        local mousePoint = hs.mouse.absolutePosition()
        local win = hs.window.orderedWindows()

        for _, w in ipairs(win) do
          if w:frame():inside(mousePoint) then
            local focused = hs.window.focusedWindow()
            if focused and w:id() ~= focused:id() then
              w:focus()
            end
            break
          end
        end
      end)

      return false
    end)

    mouseMoved:start()

The `require("hs.ipc")` at the top enables the IPC server so the `hs` command-line tool can send commands to the running Hammerspoon process. Without this line, the activation reload hook cannot function.

The `inside` check tests whether the mouse point falls within a window's frame rectangle. The loop iterates windows in z-order (front to back), so the topmost window under the mouse is found first. The `return false` ensures the event propagates normally.

Note: `hs.mouse.absolutePosition()` is the modern equivalent of `hs.mouse.getAbsolutePosition()`. The `hs.geometry.point` returned by `absolutePosition()` can be tested against a window's frame using the `inside` method on the frame rect.

**Step 3: Create the home-manager module.** Create `home/hammerspoon.nix`:

    { config, lib, ... }:

    let
      inherit (config.lib.file) mkOutOfStoreSymlink;
      nixConfigDir = "${config.home.homeDirectory}/.config/dotfiles.nix";
      hsCliPath = "/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs";
    in
    {
      home.file.".hammerspoon".source = mkOutOfStoreSymlink "${nixConfigDir}/config/hammerspoon";

      home.activation.hammerspoon-reload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if /usr/bin/pgrep -x Hammerspoon > /dev/null 2>&1; then
          if [ -x "${hsCliPath}" ]; then
            verboseEcho "Reloading Hammerspoon configuration..."
            "${hsCliPath}" -c "hs.reload()" 2>/dev/null || true
          fi
        else
          verboseEcho "Hammerspoon is not running, skipping reload"
        fi
      '';
    }

This module does two things. First, it creates a symlink from `~/.hammerspoon` to the `config/hammerspoon` directory in this repo. Second, it defines an activation hook that runs after home-manager writes files (`writeBoundary`). The hook checks if Hammerspoon is running via `pgrep`, then uses the `hs` CLI (bundled inside the Hammerspoon app bundle) to send `hs.reload()`. The `|| true` ensures the activation does not fail if the reload command errors (e.g., IPC not yet initialized on first install). If Hammerspoon is not running, the hook is skipped entirely.

The `hsCliPath` variable points to the `hs` binary inside the Hammerspoon application bundle. This is a stable location — Hammerspoon always ships this CLI tool at this path within its `.app` bundle.

**Step 4: Import the module.** In `home/default.nix`, add `./hammerspoon.nix` to the imports list.

**Step 5: Stage new files for Nix.** New files must be staged in git before Nix can see them:

    git add config/hammerspoon/init.lua home/hammerspoon.nix

**Step 6: Build and activate.** Run:

    darwin-rebuild switch --flake .

Expected: the build completes without errors. Hammerspoon is installed via Homebrew (or already present), and `~/.hammerspoon` is a symlink to the repo's `config/hammerspoon` directory.

**Step 7: Verify the symlink.** Run:

    ls -la ~/.hammerspoon

Expected output should show a symlink pointing to the repo:

    .hammerspoon -> /Users/shinzui/.config/dotfiles.nix/config/hammerspoon

**Step 8: Launch and test.** Open Hammerspoon (from Applications or Spotlight). Grant it Accessibility permissions when prompted (System Settings > Privacy & Security > Accessibility). With two overlapping windows visible, move the mouse from one to the other. After a brief pause (~0.3s), the window under the mouse should gain focus without clicking.


## Validation and Acceptance

The change is accepted when all of the following hold:

1. `darwin-rebuild switch --flake .` completes without errors.
2. `ls -la ~/.hammerspoon` shows a symlink to `config/hammerspoon` in this repo.
3. `cat ~/.hammerspoon/init.lua` shows the focus-follows-mouse Lua code with `require("hs.ipc")` at the top.
4. Hammerspoon is running (visible in the menu bar).
5. Moving the mouse between two overlapping windows causes the window under the cursor to gain focus after approximately 0.3 seconds, without clicking.
6. After editing `config/hammerspoon/init.lua` (e.g., changing `focusDelay`) and running `darwin-rebuild switch --flake .`, the Hammerspoon console shows "Config reloaded" and the change takes effect without manually reloading.

If focus-follows-mouse does not work, check the Hammerspoon console (click the menu bar icon > Console) for errors. Common issues: missing Accessibility permission, or `hs.window.orderedWindows()` returning an empty list (which happens if Hammerspoon lacks permission to see other applications' windows).

If the activation reload does not work, verify that `require("hs.ipc")` is in `init.lua` and that `/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs` exists. Run `hs -c "hs.reload()"` manually from a terminal to test IPC connectivity.


## Idempotence and Recovery

All steps are idempotent. Running `darwin-rebuild switch --flake .` multiple times is safe. The symlink creation is idempotent — home-manager will replace an existing symlink. If the Lua configuration needs to be changed, simply edit `config/hammerspoon/init.lua` and reload Hammerspoon (menu bar > Reload Config, or Cmd+Shift+R in the console). No rebuild is needed for Lua changes since the symlink points to the live file.

To undo this entire change: remove the import from `home/default.nix`, remove `"hammerspoon"` from `darwin/homebrew.nix`, delete `home/hammerspoon.nix` and `config/hammerspoon/`, then run `darwin-rebuild switch --flake .`. The cleanup setting (`zap`) will uninstall the Hammerspoon cask automatically.


## Interfaces and Dependencies

**Hammerspoon** (installed via Homebrew cask `hammerspoon`): A macOS automation tool that runs Lua scripts from `~/.hammerspoon/init.lua`. Requires Accessibility permission in System Settings to interact with windows.

**Hammerspoon Lua API** (bundled with Hammerspoon): The following functions are used:

- `hs.eventtap.new(eventTypes, callback)` — creates an event listener. `eventTypes` is a list of event type constants. The callback receives the event and returns `false` to propagate it.
- `hs.eventtap.event.types.mouseMoved` — constant for mouse-move events.
- `hs.timer.doAfter(seconds, callback)` — runs callback after a delay. Returns a timer object with a `stop()` method.
- `hs.mouse.absolutePosition()` — returns the current mouse position as an `hs.geometry.point`.
- `hs.window.orderedWindows()` — returns visible windows in z-order (front to back), excluding minimized and hidden windows.
- `hs.window.focusedWindow()` — returns the currently focused window.
- `hs.window:frame()` — returns the window's frame as an `hs.geometry.rect`.
- `hs.geometry.rect:inside(point)` — tests whether a point falls within the rectangle. Note: this is actually tested via checking if the point's x/y coordinates fall within the rect's boundaries.
- `hs.window:focus()` — brings the window to front and gives it keyboard focus.
- `hs.window:id()` — returns a unique numeric identifier for the window.

**Hammerspoon IPC** (`hs.ipc` module and `hs` CLI): The `hs.ipc` Lua module starts an IPC server inside the running Hammerspoon process. The `hs` command-line tool (at `/Applications/Hammerspoon.app/Contents/Frameworks/hs/hs`) connects to this server to send Lua commands. The command `hs -c "hs.reload()"` tells Hammerspoon to reload its `init.lua`. This is the mechanism used by the activation hook.

**home-manager** `mkOutOfStoreSymlink`: A function provided by home-manager's `config.lib.file` that creates a symlink pointing to an absolute path outside the Nix store. This means the target is the actual file on disk (not a Nix store copy), so edits to the file take effect immediately.

**home-manager** `home.activation` and `lib.hm.dag`: The activation system runs shell scripts during `darwin-rebuild switch`. `lib.hm.dag.entryAfter [ "writeBoundary" ]` schedules a hook to run after home-manager has written all managed files (symlinks, config files). The `verboseEcho` function is available inside activation scripts to print messages when home-manager runs in verbose mode. The `run` function prefixes commands with dry-run awareness. For simple conditional logic (like checking if a process is running), plain shell commands are used directly.

**nix-darwin** `homebrew.casks`: A list of Homebrew cask names to install. Managed by nix-darwin's Homebrew integration. The `onActivation.cleanup = "zap"` setting in this repo means unlisted casks are removed during activation.


---

**Revision 1** (2026-03-24): Added `home.activation.hammerspoon-reload` hook to automatically reload Hammerspoon config on `darwin-rebuild switch`. Added `require("hs.ipc")` to `init.lua` to enable CLI-driven reload. Updated Progress, Decision Log, Plan of Work, Concrete Steps, Context and Orientation, Validation, and Interfaces sections to reflect this addition. Reason: the original plan required manual reload after activation, which breaks the expected dotfiles workflow where `darwin-rebuild switch` fully applies all configuration changes.
