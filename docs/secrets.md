# Secrets

[agenix](https://github.com/ryantm/agenix) decrypts age-encrypted files using the
restored workstation SSH identity. Ciphertext is included in the system build;
plaintext is installed at activation into `/run/agenix/` and linked to its
configured destination. On macOS, agenix installs through a launch daemon, so
wait for that daemon before checking a new secret.

## Two tiers

This public repository keeps only personal, low-impact secrets that are quick to
rotate: the session configuration, local Rei API tokens and local webhook secret.
Their recipient rules are in `secrets/secrets.nix`, and their declarations are in
`darwin/secrets.nix`.

High-tier ciphertext and installation metadata live together in the private
companion, `mori://shinzui/dotfiles-private.nix`. Its `darwinModules.default` is
imported alongside agenix in the full system configuration. A secret belongs
there if disclosure grants third-party account access, can incur charges, permits
publishing to a shared cache or registry, or is slow to rotate. The public
configuration retains generic consumers of the merged `age.secrets` options.
Old high-tier ciphertext remains in public Git history; provider rotation and
revocation must invalidate those old credentials.

## Add or edit a secret

Choose the tier using the rule above, then enter this flake's development shell
with `nix develop` to get the pinned agenix CLI. In the chosen repository's
`secrets/` directory, add a new file's public recipients to `secrets.nix`:

```nix
"newsecret.age".publicKeys = shinzuiAtSungkyung;
```

Edit the encrypted secret interactively:

```bash
agenix -e newsecret.age
```

Declare it in that repository's `darwin/secrets.nix`, selecting an appropriate
path, owner and mode. Keep plaintext out of both repositories and terminal
output. The CLI uses `$RULES` to override the default `./secrets.nix`. Add a new
machine's recipient to both tiers' rules and run `agenix -r` in both directories.

For a private change, commit and push the companion first. In this public
checkout, update the locked input and switch:

```bash
nix flake update dotfiles-private
./bin/build.sh
sudo ./bin/darwin-rebuild-sungkyung.sh
```

See `mori://shinzui/dotfiles-private.nix` (`README.md`; artifact-level URI
pending) for workstation migration and provider rotation.

## New-machine bootstrap

Follow the ordered [new-machine runbook](new-machine-bootstrap.md). The
private companion now installs selected nhub, ntn, gcloud profile, kubectl,
and Nagare files as encrypted `0600` destinations. The exact source and
recovery mapping is in that repository's `config/bootstrap/private-policy.json`
(artifact URI pending under `mori://shinzui/dotfiles-private.nix`). Never
transfer its plaintext source files through Git.

Use the minimal `bootstrap-arm` configuration first if secrets are unavailable:

```bash
./bin/build.sh bootstrap-arm
sudo ./bin/darwin-rebuild.sh bootstrap-arm
```

Its module list excludes agenix and the private companion and disables remote
builders. This does not guarantee
anonymous input fetching: private flake inputs may still require authorized SSH
access during resolution. Restore `~/.ssh/id_ed25519` with mode `600`
and authorize its public key on GitHub, then clone the private companion over SSH:

```bash
mkdir -p ~/Keikaku
git clone git@github.com:shinzui/dotfiles-private.nix.git ~/Keikaku/dotfiles-private.nix
```

Both private inputs use `git+ssh` so fetching them requires SSH authorization
rather than a GitHub API token stored inside the companion. Build the full
configuration as the owner and perform the full switch. Verify installed
symlinks and dependent tools after agenix finishes. The owner workstation sops
identity is managed privately; work-owned cluster host identities are excluded.

## Yujin onboarding

On Yujin, verify the assumptions before activation:

```bash
uname -m                              # arm64
id -un                                # shinzui
networksetup -listallnetworkservices
```

The shared service list is `Wi-Fi` and `Thunderbolt Bridge`. If Yujin differs,
set `networking.knownNetworkServices` in `hosts/yujin/default.nix`; an ordinary
assignment replaces the shared `mkDefault`. A different architecture or login
requires auditing ARM font selection, bootstrap's primary user, home and secret
paths, and the sudo rule before using this configuration.

Clone this checkout to `/Users/shinzui/.config/dotfiles.nix` so the existing
out-of-store configuration symlinks point to the editable source. Establish SSH
access to the private fonts input and `mori://shinzui/dotfiles-private.nix`.
Configuration reuse does not copy databases, Git credentials, external service
authorization, or other unmanaged state.

Restore the already-authorized workstation identity securely to
`/Users/shinzui/.ssh/id_ed25519`, with mode `600`, or use the actual public key
of a new identity. The configured `age.identityPaths` uses that private file.
Adding a host SSH public key to recipient rules is insufficient unless its
matching private identity is also configured. For a different identity path,
add `lib` to `hosts/yujin/default.nix`'s module arguments and replace the list:

```nix
age.identityPaths = lib.mkForce [ "/Users/shinzui/.ssh/workstation_identity" ];
```

Never put private identities in repository files. Restoring an existing authorized
identity needs no recipient or ciphertext changes. For a new identity, add its
real public recipient to both tiers' rules and run `agenix -r` in each tier's
secret directory after identity and access are available. Locate the companion's
current workflow with `mori registry show shinzui/dotfiles-private.nix --full`
and `mori registry docs shinzui/dotfiles-private.nix`. Commit and publish private
changes first, then update only `dotfiles-private` in this checkout's lock file.
Changing recipient rules alone does not re-encrypt existing ciphertext.

After bootstrap if needed, build the full host as `shinzui` and activate on Yujin:

```bash
cd /Users/shinzui/.config/dotfiles.nix
./bin/build.sh yujin
./bin/test-treesitter.sh
sudo ./bin/darwin-rebuild.sh yujin
scutil --get ComputerName
scutil --get HostName
scutil --get LocalHostName
```

All three name checks should print `yujin`. Wait for agenix's launch daemon, then
check secret destinations are readable as their configured owner without printing
contents. A successful build does not prove successful decryption. As `shinzui`:

```bash
command -v nvim zoxide mori
test -L "$HOME/.config/nvim/lua"
test -L "$HOME/.config/nvim/after"
test -L "$HOME/.config/mori/config.dhall"
test -f "$HOME/.config/mori/host-id"
test -r "$HOME/.config/sesh/sesh.toml"
test -r "$HOME/.config/rei-api/tokens"
./bin/test-treesitter.sh
just status-postgres
just status-tools
just status-victorialogs
just status-victoriatraces
just status-redpanda
```

The path and readability checks should exit zero. Check the remaining declared
secret destinations the same way and inspect service readiness using
[the local-services runbook](local-services.md). Neovim's `lua` and `after`
directories are linked individually; its parent directory need not be a symlink.
The Treesitter helper must print PASS against the activated editor. Report missing
state or credentials separately from configuration build results.
