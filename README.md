# dotfiles.nix

Personal macOS system configuration: [nix-darwin](https://github.com/LnL7/nix-darwin)
for the system, [home-manager](https://github.com/nix-community/home-manager) for
the user environment, wired together with [flake-parts](https://flake.parts).

Two Apple Silicon workstations share the configuration: `SungkyungM1X`
(Sungkyung) and `yujin`, both `aarch64-darwin` with the `shinzui` login.
`bootstrap-arm` provides the separate minimal system configuration, including
Homebrew installation through [nix-homebrew](mori://zhaofengli/nix-homebrew). Yujin also uses that installer;
the full host's existing `homebrew.*` declarations manage formulae and casks.
Sungkyung retains its existing Homebrew installation.

For a new Mac, start with the [machine bootstrap runbook](docs/new-machine-bootstrap.md).
It separates commands for the new and trusted Macs, covers SSH onboarding,
secret enrollment, minimal/full activation, and application recovery, and names
the checkpoints required before continuing. `bin/bootstrap-machine-keys.py`
creates separate local keys without replacing existing pairs;
`bin/add-machine-recipient.py` enrolls only the public agenix key in both tiers.
Neither helper activates the machine or publishes enrollment changes.
`bin/bootstrap-nix-auth.py` prepares authentication from encrypted ciphertext
before the first build, carries it explicitly through sudo, and removes its
temporary credential only after the managed user/root authentication passes.

Sungkyung remains the sole active Rei/Mori runtime host. Yujin prepares the
workstation with the runtime and integrations disabled; follow the separate
[host cutover](docs/rei-mori-cutover.md) before moving live application state.

## Everyday commands

```bash
./bin/build.sh                           # build the system without activating
sudo ./bin/darwin-rebuild-sungkyung.sh   # build and activate

./bin/build.sh SungkyungM1X              # explicit Sungkyung build
sudo ./bin/darwin-rebuild.sh SungkyungM1X # activate on Sungkyung
./bin/build.sh yujin                     # build Yujin
sudo ./bin/darwin-rebuild.sh yujin        # activate on Yujin

nix flake update                         # update every input
nix flake update home-manager            # update one input

nix build .#parqeye                      # build a single packaged tool
nix develop                              # dev shell (agenix and age on PATH)
```

Build the intended host as the owner immediately before switching with sudo.
`result` is one shared build link; `darwin-rebuild switch` evaluates and builds
the explicitly selected target again before activation. The owner build checks
the configuration and primes access to private inputs. Activate each full host
only on its corresponding workstation.

The wrappers work from any caller directory. Build defaults to `SungkyungM1X`;
the generic switch requires a target. Both accept `SungkyungM1X`, `yujin`, and
`bootstrap-arm`, reject unknown names, and forward remaining arguments unchanged.
Follow the [new-machine bootstrap](docs/new-machine-bootstrap.md) before a new-machine
switch. Its [selection audit](docs/config-bootstrap-audit.md) explains which
preferences are portable; [secret onboarding](docs/secrets.md) covers age keys.

## Layout

```text
flake.nix                    inputs + mkFlake; outputs live in flake-modules/
flake-modules/
  overlays.nix               flake.overlays -- package fixes and local packages
  modules.nix                reusable darwinModules / homeManagerModules
  darwin-configurations.nix  the host definitions
  packages.nix               perSystem: devShells + individually-buildable packages
lib/nixpkgs-config.nix       shared { config, overlays } for nixpkgs

darwin/                      nix-darwin config (bootstrap, homebrew, secrets, defaults)
home/                        home-manager config, one file per topic
hosts/sungkyung/              Sungkyung system (default.nix) and user (home.nix) overrides
hosts/yujin/                  Yujin system (default.nix) and user (home.nix) overrides
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

### Shared settings and host differences

`flake-modules/darwin-configurations.nix` composes both full hosts with
`mkDarwinHost` and the same shared modules. Common system changes belong in
`darwin/`, and common user changes belong in `home/`. A machine's differences
belong in `hosts/<name>/default.nix` for system settings or `home.nix` for user
settings. Neither host imports the other; shared user configuration is imported
once by the common composition.

Later imports do not automatically win. Conflicting ordinary scalar settings
produce an error, and ordinary list settings generally accumulate. A shared
`lib.mkDefault` preference has lower priority than an ordinary host definition.
Use `lib.mkForce` for intentional replacement of an unconditional shared setting
or a whole list. `lib.mkBefore` and `lib.mkAfter` control list order, not replacement.
For example, these temporary differences were used to verify isolation:

```nix
# In hosts/yujin/default.nix, with lib added to the module arguments:
networking.dns = lib.mkForce [ "9.9.9.9" ];
# In hosts/yujin/home.nix, with lib added to the module arguments:
programs.zoxide.enable = lib.mkForce false;
```

When a shared preference first needs real per-host variation, prefer giving that
preference `mkDefault` rather than forcing every future override. Avoid hostname
conditionals across shared modules. Introduce a named shared profile only when
repeated subsets emerge across hosts. The reasoning is recorded in
[the shared workstation ADR](docs/adr/1-shared-workstation-modules-and-host-overrides.md).

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
recurring failure mode. The helper uses `nvim` on PATH, so rerun it after activation
to check the installed editor. `~/.local/share/nvim/site/` is unmanaged state that
survives every rebuild and takes runtimepath priority over Nix-provided plugins;
stale parsers there have broken treesitter twice. See `docs/bugs/` for both
write-ups.

## Secrets

Managed with [agenix](https://github.com/ryantm/agenix). Low-impact ciphertext and
declarations live here; high-tier ciphertext and metadata come from the private
companion `mori://shinzui/dotfiles-private.nix`. See `docs/secrets.md` and
`docs/access-tokens.md` for the tier rule and SSH bootstrap.

## Docs

- `docs/debugging-broken-packages.md` — what to do when a bump breaks a package
- `docs/bugs/` — post-mortems for problems likely to recur
- `docs/plans/` — design notes for larger changes (historical)
- `docs/neovim/` — per-plugin notes
- `docs/INSTALLED_PACKAGES.md` — inventory of what's installed and why
