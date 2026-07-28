# dotfiles.nix

Personal macOS system configuration: [nix-darwin](https://github.com/LnL7/nix-darwin)
for the system, [home-manager](https://github.com/nix-community/home-manager) for
the user environment, wired together with [flake-parts](https://flake.parts).

One host is defined, `SungkyungM1X` (aarch64-darwin).

## Everyday commands

```bash
./bin/build.sh                           # build the system without activating
sudo ./bin/darwin-rebuild-sungkyung.sh   # build and activate

nix flake update                         # update every input
nix flake update home-manager            # update one input

nix build .#parqeye                      # build a single packaged tool
nix develop                              # dev shell (agenix on PATH)
```

Build before you switch. `bin/build.sh` catches everything except activation,
and a failed build costs far less than a failed activation.

## Layout

```
flake.nix                    inputs + mkFlake; outputs live in flake-modules/
flake-modules/
  overlays.nix               flake.overlays -- package fixes and local packages
  modules.nix                reusable darwinModules / homeManagerModules
  darwin-configurations.nix  the host definitions
  packages.nix               perSystem: devShells + individually-buildable packages
lib/nixpkgs-config.nix       shared { config, overlays } for nixpkgs

darwin/                      nix-darwin config (bootstrap, homebrew, secrets, defaults)
home/                        home-manager config, one file per topic
modules/darwin/              custom nix-darwin modules (users, pam, accessibility)
overlays/                    individual overlay files, imported by flake-modules/overlays.nix
derivations/                 packages built from source in this repo
config/                      dotfiles deployed to ~/.config
secrets/                     agenix-encrypted secrets
docs/                        guides, plans, and bug write-ups
bin/                         build / rebuild / test helpers
```

## How the flake fits together

Outputs are flake-parts modules imported from `flake.nix`. Flake-level outputs
(`darwinConfigurations`, `overlays`, `darwinModules`, `homeManagerModules`) are
set via `flake.*`; per-system outputs (`packages`, `devShells`) via `perSystem`.

`lib/nixpkgs-config.nix` is the shared nixpkgs configuration. It sets
`allowUnfree` and `overlays = attrValues self.overlays`.

### Overlays apply in alphabetical order

`attrValues self.overlays` sorts by attribute name, so **the attribute name
determines application order**. One overlay depends on this today:
`vimExtraPlugins-require-check-exemptions` must sort after `nix-neovimplugins`,
which is what introduces `vimExtraPlugins`. Renaming an overlay can silently
change behaviour.

Note that `flake-modules/packages.nix` deliberately applies only the few
overlays its packages need, not the full set.

### The `pkgs-stable` escape hatch

When a package doesn't build against current unstable, take just that package
from `nixpkgs-stable` (pinned to a release channel) rather than pinning
everything:

```nix
harlequin = final.pkgs-stable.harlequin;         # a whole package
rustPlatform = final.pkgs-stable.rustPlatform;   # or just a toolchain
```

Do **not** reach for `builtins.fetchTarball` to a hardcoded nixpkgs revision.
That sits outside `flake.lock`, so `nix flake update` can never move it, it
instantiates an entire extra nixpkgs, and it drifts silently — two such pins
were retired in July 2026 after quietly going years out of date.

### Retire workarounds as you go

Overlays that outlive their cause become the next outage. When a bump breaks
something, check whether the *existing* workaround is the problem before adding
another:

- `dateutils-fix` broke the build once nixpkgs shipped the same patch upstream —
  the overlay's `--replace-fail` then matched nothing and aborted.
- `tmux-extrakto-darwin-fix` existed to keep Linux-only dependencies off Darwin,
  but nixpkgs fixed that upstream and the overlay was left force-adding `xclip`
  to the Darwin closure — causing the exact problem it was named after.

Every overlay in `overlays/` should say what it fixes and when it can go.

## Adding a package

Prefer nixpkgs. If it isn't there, add a derivation under `derivations/` and
wire it into `my-packages` in `flake-modules/overlays.nix`.

New files must be `git add`ed before the flake can see them — Nix only sees
tracked files, and an untracked derivation fails with a confusing "file not
found".

Haskell tools from sibling flakes go through the `hsBin` / `hsBinShare` helpers,
which expose only `bin/` (and `share/` where a bundled UI needs it). Their full
outputs ship `lib/` directories that collide with each other, and with `hoogle`,
when home-manager assembles the profile.

## Neovim

Plugins come from nixpkgs and [NixNeovimPlugins](https://github.com/NixNeovim/NixNeovimPlugins)
(`pkgs.vimExtraPlugins`), declared in `home/neovim.nix`.

Lua config lives in `config/nvim/` and is deployed as an **out-of-store symlink**,
so edits take effect immediately without a rebuild.

```bash
./bin/test-treesitter.sh    # verify treesitter queries + injections
```

Run that after a build and before switching — grammar/query mismatches are a
recurring failure mode. `~/.local/share/nvim/site/` is unmanaged state that
survives every rebuild and takes runtimepath priority over Nix-provided plugins;
stale parsers there have broken treesitter twice. See `docs/bugs/` for both
write-ups.

## Secrets

Managed with [agenix](https://github.com/ryantm/agenix); encrypted files live in
`secrets/` and are declared in `darwin/secrets.nix`. See `docs/secrets.md` and
`docs/access-tokens.md`.

## Docs

- `docs/debugging-broken-packages.md` — what to do when a bump breaks a package
- `docs/bugs/` — post-mortems for problems likely to recur
- `docs/plans/` — design notes for larger changes (historical)
- `docs/neovim/` — per-plugin notes
- `docs/INSTALLED_PACKAGES.md` — inventory of what's installed and why
