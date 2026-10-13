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

Use the minimal `bootstrap-arm` configuration first. Its module list excludes
agenix and the private companion. Restore `~/.ssh/id_ed25519` with mode `600`
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
