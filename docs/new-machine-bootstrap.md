# New Apple Silicon Mac runbook

**Rei/Mori runtime ownership:** Sungkyung remains the sole active host. Yujin's
full configuration keeps these background services and their integrations
disabled while the workstation is prepared. Do not start them, restore their
live state, or run mutating application commands on Yujin during bootstrap.
Use the separate [stop-before-start cutover](rei-mori-cutover.md) once Yujin is ready.

Follow these phases in order. Commands marked **NEW MAC** run as `shinzui` on the destination, locally or over SSH. Commands marked **TRUSTED MAC** run on an already-authorized workstation with GitHub CLI access and an identity that decrypts both secret tiers. Keep one Bash terminal for each machine; reconnect after installing Nix and reset the variables below. Stop a phase if a command fails, resolve the cause, then resume that phase. After phase 6, keep the bootstrap credential until the managed handoff passes. Do not paste this entire document into a shell.

This configuration supports Apple Silicon macOS with the `shinzui` login and the exact checkout paths below. A new hostname needs a declared host target before activation. Keys stay on their owning machine; only public keys and encrypted files cross machines. Builds prepare a candidate. `sudo ./bin/darwin-rebuild.sh` changes the running machine.

The command examples use `yujin`. For a future machine, replace that value in every `MACHINE_HOST` assignment with the host declared in phase 1. Keep the same host value in both terminals; do not derive it from the trusted Mac's hostname.

GitHub authorization, sudo, Apple installers, macOS permissions, and provider/application logins can require interaction. The helpers automate repeatable file operations; they do not bypass those checkpoints. Keep a private checklist of completed phases, host, public-key fingerprints, repository commits, and system generation. Keep tokens and plaintext secrets out of that record.

| Checkpoint | Continue when |
| --- | --- |
| Tools and public checkout | Nix, Git, Python work without relying on Apple's stubs |
| Machine keys | Two distinct local key pairs; private files mode `0600` |
| GitHub | Both private inputs accept the new GitHub key |
| Secret enrollment | Both tiers rekeyed, private published first, public lock updated, new identity decrypts all files |
| Minimal activation | Native Homebrew works; minimal live checker passes |
| Full activation | Host names match; full live checker and private consumers pass |
| Workstation recovery | Logins, device enrollment, identity, and data/services independently verified |

## 1. Select or add the host target — TRUSTED MAC

For Yujin use the existing `yujin` target. Do not use `SungkyungM1X` on a new machine. For a future host, for example `atlas`:

1. Copy the configuration templates `hosts/yujin/default.nix` and `home.nix` into `hosts/atlas/`; these are settings, not keys. Change `networking.computerName` and `networking.hostName` to `atlas`. Keep the dedicated `age.identityPaths` override and GitHub key selection.
2. Add `atlas = mkDarwinHost { hostModule = ../hosts/atlas; extraModules = homebrewInstallationModules; };` alongside `yujin` in `flake-modules/darwin-configurations.nix`.
3. Add `atlas` to the accepted targets and usage text in `bin/build.sh`, `bin/darwin-rebuild.sh`, and `TARGETS` in `bin/check-bootstrap.py`. Record the host in the README. The managed Homebrew module is required for this runbook's preactivation checks.
4. Check the destination's network services in phase 8. Add any required host overrides, commit with a Conventional Commit message, and publish before the new machine pulls and builds it.

For a different login or architecture, first audit bootstrap's primary user, ARM font selection, home/secret paths, and sudo rules. Those machines are outside this runbook's current tested scope.

**TRUSTED MAC:** set these for the destination, not this workstation's hostname:

Start `/bin/bash` first if this terminal is using zsh.

```bash
set -euo pipefail
export MACHINE_HOST=yujin
export NEW_MAC="shinzui@${MACHINE_HOST}.local"
export PUBLIC_ROOT=/Users/shinzui/.config/dotfiles.nix
export PRIVATE_ROOT=/Users/shinzui/Keikaku/dotfiles-private.nix
```

Use an IP address for `NEW_MAC` if `.local` discovery fails. Enable Remote Login on the destination when using SSH; an SSH session may be passwordless while sudo still requires its password. Use `ssh -t "$NEW_MAC"` for an interactive terminal and sudo. Do not forward an old SSH agent as a substitute for registering the destination's own key.

## 2. Install Nix, then obtain Git and Python — NEW MAC

Verify the account and architecture:

```bash
test "$(id -un)" = shinzui
test "$(uname -m)" = arm64
export MACHINE_HOST=yujin
```

If Determinate Nix is installed, use a fresh terminal where `nix --version` works and skip the installer. If no Nix is installed, download the public installer helper before cloning; this avoids needing Apple's Git or Python first. Review [Determinate's installation guide](https://docs.determinate.systems/getting-started/individuals/) and the downloaded helper, then run:

```bash
umask 077
INSTALL_WORK=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX")
curl -fL https://raw.githubusercontent.com/shinzui/dotfiles.nix/master/bin/darwin-install.sh \
  -o "$INSTALL_WORK/darwin-install.sh"
cat "$INSTALL_WORK/darwin-install.sh"
sh "$INSTALL_WORK/darwin-install.sh"
```

The helper downloads the stable Determinate macOS package, displays its Apple signature, invokes `sudo installer`, and recognizes an existing Determinate installation. It refuses to replace a different Nix installation. Reopen the terminal or reconnect over SSH after installation. Do not reinstall just because an old shell's PATH is missing Nix; check `/nix/var/nix/profiles/default/bin/nix --version` first.

```bash
nix --version
nix shell nixpkgs#gitMinimal nixpkgs#python3 --command /bin/bash
```

Keep this Nix-provided Bash shell open through the checkout and preflight phases. Reset `MACHINE_HOST` if you reconnected. These tools do not require Apple's Command Line Tools; some later Homebrew packages do. The initial tools use the Nix registry's nixpkgs; repository builds and the enrollment dev shell use `flake.lock`.

```bash
set -euo pipefail
export MACHINE_HOST=yujin
export PUBLIC_ROOT=/Users/shinzui/.config/dotfiles.nix
export PRIVATE_ROOT=/Users/shinzui/Keikaku/dotfiles-private.nix
mkdir -p /Users/shinzui/.config /Users/shinzui/Keikaku
if [ ! -e "$PUBLIC_ROOT" ] && [ ! -L "$PUBLIC_ROOT" ]; then
  git clone https://github.com/shinzui/dotfiles.nix.git "$PUBLIC_ROOT"
else
  test -d "$PUBLIC_ROOT/.git"
  test -z "$(git -C "$PUBLIC_ROOT" status --porcelain)"
  git -C "$PUBLIC_ROOT" remote -v
  # Confirm this is shinzui/dotfiles.nix before pulling.
  git -C "$PUBLIC_ROOT" pull --ff-only
fi
cd "$PUBLIC_ROOT"
```

Do not replace an existing directory, dirty checkout, incomplete clone, or unexpected remote. Preserve and inspect conflicts before continuing. The public checkout must stay at this exact path because editable Home Manager links point to it.

## 3. Generate separate machine keys — NEW MAC

```bash
python3 "$PUBLIC_ROOT/bin/bootstrap-machine-keys.py" "$MACHINE_HOST"
```

This creates `~/.ssh/id_ed25519` for GitHub and `~/.ssh/agenix_ed25519` for unattended agenix decryption. It keeps complete existing pairs, refuses partial pairs or symlink destinations, sets directory mode `0700` and private-key mode `0600`, and prints public fingerprints. It does not enroll either key. If a key pair already exists, confirm it was generated on this machine and its public key matches its private key; the helper does not validate an encrypted private key's contents.

By default both new keys are passwordless. For a passphrase on a newly created GitHub key, add `--github-passphrase`. To add or change its passphrase later, run `ssh-keygen -p -f ~/.ssh/id_ed25519` interactively; the public key and GitHub registration stay the same. Keep the dedicated agenix key passwordless for launch-daemon decryption. Never copy another machine's SSH private key or place either key in Git or a Nix expression.

## 4. Register GitHub access — TRUSTED MAC, then NEW MAC

**TRUSTED MAC:** retrieve only the public files into a protected enrollment directory. Keep this terminal open; phase 5 reuses `ENROLLMENT_WORK`.

```bash
umask 077
mkdir -p "$HOME/.local/state/dotfiles-bootstrap"
export ENROLLMENT_WORK
ENROLLMENT_WORK=$(mktemp -d "$HOME/.local/state/dotfiles-bootstrap/enrollment-${MACHINE_HOST}.XXXXXX")
scp "$NEW_MAC:/Users/shinzui/.ssh/id_ed25519.pub" "$ENROLLMENT_WORK/github.pub"
scp "$NEW_MAC:/Users/shinzui/.ssh/agenix_ed25519.pub" "$ENROLLMENT_WORK/agenix.pub"
ssh-keygen -lf "$ENROLLMENT_WORK/github.pub"
ssh-keygen -lf "$ENROLLMENT_WORK/agenix.pub"
test "$(awk '{print $1, $2}' "$ENROLLMENT_WORK/github.pub")" != \
     "$(awk '{print $1, $2}' "$ENROLLMENT_WORK/agenix.pub")"
gh api user --jq .login
```

Confirm the logged-in GitHub account is `shinzui`, fingerprints match those shown on the new Mac, and neither public key is reused from the source machine. Check `gh api user/keys`. If it fails for insufficient public-key scope, run `gh auth refresh --hostname github.com --scopes write:public_key` and complete its browser/device flow. A logged-in CLI without that scope can fail `gh ssh-key add` with HTTP 404; this does not mean the public key is invalid. The [GitHub scope](https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps) allows creating/listing keys; full administration scope is unnecessary.

Register only if the exact key is absent, so this phase can be resumed:

```bash
gh api --paginate user/keys --jq '.[].key' > "$ENROLLMENT_WORK/registered.keys"
if ! awk '{print $1, $2}' "$ENROLLMENT_WORK/registered.keys" | \
     grep -Fx "$(awk '{print $1, $2}' "$ENROLLMENT_WORK/github.pub")" >/dev/null; then
  gh ssh-key add "$ENROLLMENT_WORK/github.pub" --title "$MACHINE_HOST" --type authentication
fi
```

**NEW MAC:** establish GitHub host trust from its HTTPS-published metadata. Do not disable SSH host-key checking. This preserves existing host entries and refuses a symlink file:

```bash
curl -fsSL https://api.github.com/meta -o "$HOME/.ssh/github-meta.json"
python3 - <<'PY_HOSTS'
import json, os, subprocess
from pathlib import Path
p = Path.home() / '.ssh/known_hosts'
if p.is_symlink() or (p.exists() and not p.is_file()):
    raise SystemExit('CONFLICT: inspect known_hosts before continuing')
if p.exists():
    os.chmod(p, 0o600)
found = p.exists() and subprocess.run(['ssh-keygen', '-F', 'github.com', '-f', str(p)], capture_output=True).returncode == 0
if not found:
    keys = json.loads((p.parent / 'github-meta.json').read_text())['ssh_keys']
    with p.open('a') as f:
        f.write('\n' + ''.join('github.com ' + key + '\n' for key in keys))
    os.chmod(p, 0o600)
PY_HOSTS
```

Create GitHub SSH settings only when `~/.ssh/config` is absent. Existing files are preserved; inspect and merge equivalent settings yourself if needed. The full Home Manager configuration will manage the same settings.

```bash
python3 - <<'PY_SSH'
import os
from pathlib import Path
p = Path.home() / '.ssh/config'
if p.exists() or p.is_symlink():
    print('KEPT: existing SSH config; verify the GitHub settings before continuing')
else:
    with p.open('x') as f:
        f.write('''Host github.com
  IgnoreUnknown UseKeychain
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
''')
    os.chmod(p, 0o600)
PY_SSH
```

For an existing config, require `User git`, `IdentityFile ~/.ssh/id_ed25519`, and `IdentitiesOnly yes` for `github.com` and file mode `0600`. Verify authentication with real reads of both required repositories; a GitHub `ssh -T` greeting by itself normally returns exit code 1.

```bash
git ls-remote --exit-code git@github.com:shinzui/fonts.git HEAD >/dev/null
git ls-remote --exit-code git@github.com:shinzui/dotfiles-private.nix.git HEAD >/dev/null
git ls-remote --exit-code git@github.com:topagentnetwork/tan-effectful.git HEAD >/dev/null
git ls-remote --exit-code git@github.com:topagentnetwork/typeid-hs.git HEAD >/dev/null
git -C "$PUBLIC_ROOT" remote set-url origin git@github.com:shinzui/dotfiles.nix.git
umask 077
if [ ! -e "$PRIVATE_ROOT" ] && [ ! -L "$PRIVATE_ROOT" ]; then
  git clone git@github.com:shinzui/dotfiles-private.nix.git "$PRIVATE_ROOT"
else
  test -d "$PRIVATE_ROOT/.git"
  test -z "$(git -C "$PRIVATE_ROOT" status --porcelain)"
  git -C "$PRIVATE_ROOT" remote -v
  # Confirm the private companion remote before pulling.
  git -C "$PRIVATE_ROOT" pull --ff-only
fi
```

The private companion is `mori://shinzui/dotfiles-private.nix`. Its source/recovery mapping is project-relative `config/bootstrap/private-policy.json` (artifact URI pending). Both private inputs require SSH access even when building `bootstrap-arm`; a GitHub key grants Git access, not secret decryption.

## 5. Enroll and rekey the agenix recipient — TRUSTED MAC

Start with clean public and private checkouts. Pull both before modifying them. Use an existing identity that decrypts both tiers: Sungkyung currently uses `~/.ssh/id_ed25519`; an already-onboarded Yujin uses `~/.ssh/agenix_ed25519`. Do not select a GitHub-only key merely because it is named `id_ed25519`.

```bash
test -z "$(git -C "$PUBLIC_ROOT" status --porcelain)"
test -z "$(git -C "$PRIVATE_ROOT" status --porcelain)"
git -C "$PUBLIC_ROOT" pull --ff-only
git -C "$PRIVATE_ROOT" pull --ff-only
export ENROLL_IDENTITY="$HOME/.ssh/id_ed25519"  # choose this source Mac's decrypting identity
python3 "$PUBLIC_ROOT/bin/add-machine-recipient.py" "$MACHINE_HOST" \
  "$ENROLLMENT_WORK/agenix.pub" --private-repo "$PRIVATE_ROOT"
```

The helper validates both recipient files before changing either, keeps all current recipients, and reuses an already-enrolled key. A hostname binding with a different key stops enrollment: for an intentional replacement, use a unique `--recipient-name machine_HOST_replacement1`, keeping the old key until recovery is verified. It accepts only an Ed25519 **public** file, discards its comment, and does not rekey, commit, or publish. Adding a recipient without re-encrypting existing `.age` files is insufficient.

Before rekeying, preserve encrypted originals outside both repositories. On a resumed enrollment, reuse the recorded backup directory rather than replacing it. Enter the repository's locked dev shell, which supplies both `agenix` and `age`:

```bash
export CIPHERTEXT_BACKUP
CIPHERTEXT_BACKUP=$(mktemp -d "$HOME/.local/state/dotfiles-bootstrap/ciphertexts-${MACHINE_HOST}.XXXXXX")
mkdir -m 700 "$CIPHERTEXT_BACKUP/public" "$CIPHERTEXT_BACKUP/private"
cp "$PUBLIC_ROOT"/secrets/*.age "$CIPHERTEXT_BACKUP/public/"
cp "$PRIVATE_ROOT"/secrets/*.age "$CIPHERTEXT_BACKUP/private/"
cd "$PUBLIC_ROOT"
nix develop --command /bin/bash
```

**Still TRUSTED MAC, inside the dev shell:** verify originals decrypt before changing ciphertext; compare streams afterward without writing or displaying plaintext.

```bash
set -euo pipefail
for tier in public private; do
  for saved in "$CIPHERTEXT_BACKUP/$tier"/*.age; do
    age -d -i "$ENROLL_IDENTITY" "$saved" >/dev/null
  done
done
(cd "$PUBLIC_ROOT/secrets" && agenix -r -i "$ENROLL_IDENTITY")
(cd "$PRIVATE_ROOT/secrets" && agenix -r -i "$ENROLL_IDENTITY")
for tier in public private; do
  checkout="$PUBLIC_ROOT"
  if [ "$tier" = private ]; then checkout="$PRIVATE_ROOT"; fi
  for saved in "$CIPHERTEXT_BACKUP/$tier"/*.age; do
    current="$checkout/secrets/$(basename "$saved")"
    age -d -i "$ENROLL_IDENTITY" "$current" >/dev/null
    cmp <(age -d -i "$ENROLL_IDENTITY" "$saved") \
        <(age -d -i "$ENROLL_IDENTITY" "$current")
  done
done
```

`cmp` prints nothing when plaintext is unchanged. Keep the protected ciphertext backup until destination decryption and consumers pass. Review `git diff --stat` and recipient-rule diffs without opening secrets. For a newly enrolled recipient, publish in this order:

```bash
cd "$PRIVATE_ROOT"
git add secrets/secrets.nix secrets/*.age
if ! git diff --cached --quiet; then
  git commit -m "feat(secrets): enroll $MACHINE_HOST recipient"
fi
git push
cd "$PUBLIC_ROOT"
nix flake update dotfiles-private
./bin/build.sh "$MACHINE_HOST" --no-link
git diff -- flake.lock secrets/secrets.nix
git add secrets/secrets.nix secrets/*.age flake.lock
if ! git diff --cached --quiet; then
  git commit -m "feat(secrets): enroll $MACHINE_HOST recipient"
fi
git push
exit  # leave the enrollment dev shell
```

Confirm only the intended private input changed in `flake.lock`. The nonactivating build must pass before publishing the public enrollment. Do not run `nix flake update` without an input name here. If enrollment is already complete and published, skip rekeying and proceed to destination verification; rerunning `agenix -r` may change ciphertext even with identical recipients.

## 6. Bootstrap Nix authentication — TRUSTED MAC, then NEW MAC

GitHub SSH authorization does not authenticate Nix's `github:` archive fetches. Private tool inputs can return HTTP 404 without a Nix GitHub token even when both prerequisite checkers pass. A cold-cache build is a separate readiness check. Keep SSH access for cloning and an independent read-only GitHub token for each machine's Nix downloads.

The current organization-owned library inputs use SSH at their existing locked
revisions. Confirm the destination key is authorized for those repositories in
phase 4. A fine-grained token targeting `shinzui` covers personal repositories;
it cannot authenticate archives owned by an organization. Future organization
inputs need authorized SSH fetching or a token for the appropriate resource owner.

**TRUSTED MAC:** for a future machine, create a fine-grained token targeting `shinzui`, with All repositories access, Contents read-only, and an expiration date. Store it only as encrypted ciphertext in `mori://shinzui/dotfiles-private.nix`. Yujin's token is already enrolled. For another host:

1. Add `"access_tokens-HOST.conf.age".publicKeys = workstationRecipients;` to the private recipient rules. Enter the public checkout's dev shell on the already-authenticated trusted Mac, then use `agenix -e access_tokens-HOST.conf.age` from the private `secrets/` directory. Its plaintext must contain exactly `access-tokens = github.com=TOKEN` on one line. Edit locally; never paste the token into shell arguments, Nix expressions, logs, or this runbook. Verify the resulting ciphertext decrypts before deleting any temporary plaintext source.
2. Create a private host module that overrides `age.secrets.access_token.file` to that encrypted file with `lib.mkForce` and mode `"600"`. Export it as `darwinModules.HOST` and add it to that host's public `extraModules` alongside `homebrewInstallationModules`. Preserve the existing shared token for hosts that do not select a dedicated one. These paths are project-relative under `mori://shinzui/dotfiles-private.nix` (artifact URIs pending).
3. Publish private ciphertext and declarations first, update only `dotfiles-private` in the public lock, check the host selection, build on the trusted Mac, and publish the public update. Pull both clean checkouts on the destination before preparing authentication. Review the lock's revision against the private checkout as in phase 7.

The helper below needs the ciphertext from the new private revision. It uses standalone `age`; do not enter this dotfiles flake's dev shell until the credential is available, because evaluating that shell can itself fetch private inputs.

**NEW MAC:** enter a standalone tools shell and prepare authentication:

```bash
cd "$PUBLIC_ROOT"
nix shell nixpkgs#age nixpkgs#python3 --command /bin/bash
python3 ./bin/bootstrap-nix-auth.py prepare "$MACHINE_HOST" \
  --ciphertext "$PRIVATE_ROOT/secrets/access_tokens-${MACHINE_HOST}.conf.age"
```

The helper decrypts with the local `~/.ssh/agenix_ed25519` key, validates one GitHub token setting, and creates `~/.local/state/dotfiles-bootstrap/nix-auth/HOST/access-tokens.conf` with mode `0600` inside owned directories with mode `0700`. It keeps a matching existing credential and refuses conflicting state. It never displays its decrypted contents. This temporary credential must stay available through minimal activation and the full switch.

Run Nix commands through `bootstrap-nix-auth.py run HOST -- COMMAND...` until full activation. For root switches, use `run HOST --sudo -- COMMAND...`; the wrapper passes `NIX_USER_CONF_FILES` explicitly across sudo and removes a conflicting `NIX_CONFIG`. Only the protected file path appears in arguments. Do not run token-printing commands, environment dumps, or debug configuration dumps through the wrapper. The helper's setting is scoped to that command; it does not edit existing Nix configuration files.

After full activation, wait for agenix and authenticate sudo with `sudo -v`, then run:

```bash
python3 ./bin/bootstrap-nix-auth.py verify "$MACHINE_HOST"
python3 ./bin/bootstrap-nix-auth.py cleanup "$MACHINE_HOST"
```

Verification requires the managed agenix file to contain the same token with owner `shinzui` and mode `0600`, normal user and root Nix settings to select it, and a fresh private GitHub commit read to succeed. Cleanup temporarily hides the bootstrap file and repeats verification, so a lingering dependency on it cannot pass. Failure restores/preserves the credential; success removes only the helper's credential and metadata. Run this cleanup on the destination, not the trusted source Mac. The raw token source file used for enrollment can be deleted immediately after its ciphertext decrypts correctly; it is separate from this runtime bootstrap credential.

## 7. Pull and verify destination decryption — NEW MAC

Use the existing Nix-provided Git/Python shell. Check both trees are clean before pulling. The full host uses the private revision in the public lock, so the lock must include the published enrollment.

```bash
test -z "$(git -C "$PUBLIC_ROOT" status --porcelain)"
test -z "$(git -C "$PRIVATE_ROOT" status --porcelain)"
git -C "$PUBLIC_ROOT" pull --ff-only
git -C "$PRIVATE_ROOT" pull --ff-only
python3 - <<'PY_LOCK'
import json, subprocess
from pathlib import Path
root = Path('/Users/shinzui/.config/dotfiles.nix')
private = Path('/Users/shinzui/Keikaku/dotfiles-private.nix')
lock = json.loads((root / 'flake.lock').read_text())
node = lock['nodes']['root']['inputs']['dotfiles-private']
revision = lock['nodes'][node]['locked']['rev']
head = subprocess.check_output(['git', '-C', str(private), 'rev-parse', 'HEAD'], text=True).strip()
if head != revision:
    raise SystemExit('CONFLICT: private checkout differs from the public locked revision; review before continuing')
print('PASS: private checkout matches public lock')
PY_LOCK
cd "$PUBLIC_ROOT"
python3 ./bin/bootstrap-nix-auth.py run "$MACHINE_HOST" -- nix develop --command /bin/bash
```

**Inside the destination dev shell:** test every encrypted file using the destination's dedicated identity. This complements the source-side plaintext comparison.

```bash
set -euo pipefail
for checkout in "$PUBLIC_ROOT" "$PRIVATE_ROOT"; do
  for ciphertext in "$checkout"/secrets/*.age; do
    age -d -i "$HOME/.ssh/agenix_ed25519" "$ciphertext" >/dev/null
  done
done
nix eval --json ".#darwinConfigurations.${MACHINE_HOST}.config.age.identityPaths" | \
  python3 -c 'import json,sys; assert json.load(sys.stdin) == ["/Users/shinzui/.ssh/agenix_ed25519"], "host must select the dedicated destination identity"'
./bin/check-bootstrap.sh bootstrap-arm
./bin/check-bootstrap.sh "$MACHINE_HOST"
exit
```

The checker is read-only and emits `PASS`, `MISSING`, or `CONFLICT` without printing secret contents. Exit 0 means its required checks pass; 1 means missing/conflicting prerequisites; 2 means invalid input/policy. Resolve conflicts before switching. A synthetic `--home-dir` check or source-machine build does not prove destination onboarding.

## 8. Activate minimal, then full configuration — NEW MAC

The minimal target omits Home Manager, agenix, the private module, and remote builders. It installs native Homebrew at `/opt/homebrew` using the locked [nix-homebrew module](mori://zhaofengli/nix-homebrew), owned by `shinzui`. It does not install the full formula/cask bundle. Automatic migration of an existing unmanaged Homebrew installation is disabled; inspect such a conflict before intentionally enabling migration in `darwin/homebrew-installation.nix`.

Record an existing system generation before activation, if present:

```bash
if [ -L /nix/var/nix/profiles/system ]; then
  nix-env --list-generations --profile /nix/var/nix/profiles/system
fi
cd "$PUBLIC_ROOT"
python3 ./bin/bootstrap-nix-auth.py run "$MACHINE_HOST" -- ./bin/build.sh bootstrap-arm
python3 ./bin/bootstrap-nix-auth.py run "$MACHINE_HOST" --sudo -- ./bin/darwin-rebuild.sh bootstrap-arm
test "$(/opt/homebrew/bin/brew --prefix)" = /opt/homebrew
./bin/check-bootstrap.sh bootstrap-arm --live
```

Build as `shinzui` immediately before switching the same target with sudo. Over SSH, keep a TTY for the password prompt. `result` is a shared build link; never assume it represents the last target you intended. Minimal live checks skip secret destinations it does not install. Open a new shell after activation to load managed shell integration; reset the exported variables if you reconnect.

Install Apple's Command Line Tools before packages that require them. Follow [Apple's instructions](https://developer.apple.com/documentation/xcode/installing-the-command-line-tools/): `xcode-select --install` opens a GUI prompt on the destination. Over SSH, download the appropriate signed Command Line Tools package from Apple on a machine with browser access, extract the `.pkg` from its disk image, copy the package to the destination, and run `sudo /usr/sbin/installer -pkg /path/to/CommandLineTools.pkg -target /` in a TTY there. Verify:

```bash
xcode-select -p
pkgutil --pkg-info com.apple.pkg.CLTools_Executables
networksetup -listallnetworkservices
```

`softwareupdate --list` returning no updates is not proof that CLT is installed; a fresh Mac may offer no CLT package there. Homebrew itself is installed by Nix. Apple developer agreements and App Store/cask prompts may remain interactive.

The shared network service names are `Wi-Fi` and `Thunderbolt Bridge`. If they differ, update `networking.knownNetworkServices` in this host's `default.nix`, publish from the trusted Mac, and pull before building. An ordinary host assignment replaces the shared `mkDefault`.

Before full activation, sign into the Mac App Store with the account that owns
your apps. The shared declarations in
[`darwin/app-store.nix`](../darwin/app-store.nix) install Adobe Lightroom and
Slack automatically on both full hosts. Add future App Store apps there with
their numeric ID, installation path, and bundle identifier. Activation checks
the matching bundle identifier, executable, and App Store receipt directly;
it does not depend on Spotlight indexing or `mas list`. Existing verified
apps are kept, and missing apps are installed with `mas get`. Free apps can be
acquired by that command; paid apps must already belong to the signed-in
account. App Store authentication may still require approval.

Rebuilds do not run `mas update`: enable automatic updates in the App Store
to keep applications current. Installation failures and conflicting existing
bundles fail activation. Resolve the reported error and rerun the normal
rebuild; no separate install command is needed. Adobe account and Slack
workspace sign-in remain per-machine.

App Store installation runs separately from Homebrew Bundle. Leave
`homebrew.masApps` empty: with this configuration's forced Bundle cleanup,
adding an App Store entry there also makes other unlisted App Store apps
eligible for removal. `programs.mas.cleanup = false` preserves unlisted apps.
The minimal `bootstrap-arm` target does not install desktop apps.

After resolving checker conflicts, prepare restricted directories and activate the full target:

```bash
install -d -m 700 "$HOME/.config/nhub" "$HOME/.config/ntn" \
  "$HOME/.config/gcloud" "$HOME/.config/gcloud/configurations" \
  "$HOME/.config/nagare" "$HOME/.config/nagare/contexts" \
  "$HOME/.config/nagare/kubeconfigs" "$HOME/.kube"
cd "$PUBLIC_ROOT"
./bin/check-bootstrap.sh "$MACHINE_HOST"
python3 ./bin/bootstrap-nix-auth.py run "$MACHINE_HOST" -- ./bin/build.sh "$MACHINE_HOST"
python3 ./bin/bootstrap-nix-auth.py run "$MACHINE_HOST" --sudo -- ./bin/darwin-rebuild.sh "$MACHINE_HOST"
scutil --get ComputerName
scutil --get HostName
scutil --get LocalHostName
```

All three names should match `MACHINE_HOST`. Complete the authentication handoff verification and cleanup from phase 6 after agenix has installed the token. Wait for the agenix launch daemon, then inspect `./bin/check-bootstrap.sh "$MACHINE_HOST" --live` as `shinzui`. It checks installed private files for readability, ownership and mode `0600`; a full live pass also depends on the Tailscale enrollment below. Keep source originals until private consumers work. Accessibility, Automation, application login, and VPN grants are per-machine onboarding.

The full host declares a Linux remote builder whose identity is `/etc/nix/builder_ed25519`. Neither repository provisions that private key. If Linux builds are needed, arrange authorized builder access separately, provision a builder-specific identity securely at that path with root ownership and mode `0600`, and register its public key with the builder owner. Do not reuse the GitHub or agenix private key for this. Builder connectivity and GCP authorization are separate from workstation activation.

## 9. Restore application access and local identity

Reauthenticate renewable gcloud user sessions and application-default credentials for the three selected profiles. Check the intended active profile privately and test read-only access to the intended GCP resources; do not copy credentials databases, token caches, SDK logs, or print profile/account lists into a public log. The already-declared GKE auth plugin is required by some kubectl contexts. Restore private Kubernetes contexts from the encrypted config and owning Nagare checkouts, recreate auth/discovery/HTTP caches, then test a read-only query against each reachable intended environment. Work-owned host age keys and cluster authority remain with their owning project recovery process.

Nagare has a separate Nix profile installation. The source Mac's old profile references a revision that is not the current `v0.2.2` tag and has no root flake at that revision. The immutable `v0.2.2` release tag built on this Mac; its `nagarectl context list` parsed the selected local configuration, and its launcher listed recipes when `NAGARE_CONTEXT=local` was explicit. The source's old active context name is absent from its current context directory, so the launcher fails without that override. On the new Mac, recover and select an intended context before running the launcher. Do not silently install the latest 0.6 release or run a context upgrade. The currently published latest release was `v0.6.3` during preparation, but an upgrade needs its own reviewed transition. Consult `mori://shinzui/nagare/docs/user-manual`, project-relative `installation.md` (file URI pending). Repeat these nonactivating compatibility probes after restoring the selected context:

```bash
nix run 'github:shinzui/nagare/v0.2.2#nagarectl' -- context list
NAGARE_CONTEXT=local nix run 'github:shinzui/nagare/v0.2.2#nagare' -- --list
```

If those probes and a private read-only context check pass, install `nix profile install 'github:shinzui/nagare/v0.2.2#nagare'`. Clone the owning Nagare and operations repositories before recreating the selected symlinks under `~/.config/nagare`. Select the active context only after its destination and credentials exist. Restoration and use of the live Mori registry/data on Yujin are deferred to the sole-owner cutover. Clone essential preparation repositories explicitly; do not run `bootstrap-repos` against a second restored production registry during onboarding. Generated databases and workspaces have separate recovery sources in [local services](local-services.md) and their owning runbooks; no database belongs in these dotfiles.

### Source-machine Mori migration

When Mori is first used at cutover, it must create a new local `~/.config/mori/host-id`. Defer production runtime use on Yujin until then. Verify privately that it differs from Sungkyung's protected copy; do not copy that value or write it back into shared source. On Sungkyung, before activating this changed Home Manager ownership, preserve the old `~/.config/mori` symlink itself under a unique name outside both repositories, create a real local `~/.config/mori` directory, and restore the protected `~/.local/state/dotfiles-bootstrap/sungkyung-mori-host-id` to `~/.config/mori/host-id` with mode `0600`. Confirm its bytes match the protected backup before using Mori. The tracked source's `host-id` was removed from Git, while the old source file remains ignored locally until this switch.

Review the differing historical `mori.bak` and `rei.bak` settings privately before discarding those backups. Their policy action is `data-export` until desired unique preferences have a specific owner and recovery route.

## 10. Enroll Tailscale as a new device

The full configuration already installs the standalone Tailscale app. Start it, approve the macOS system/network extension and VPN configuration, sign into the intended private tailnet, and complete any device approval. Do not copy the old plist, cached profiles, or node keys. Reapply the reviewed routing and DNS preferences with the app's bundled CLI after confirming the bundle exists:

```bash
test -x /Applications/Tailscale.app/Contents/MacOS/Tailscale
/Applications/Tailscale.app/Contents/MacOS/Tailscale set \
  --accept-dns=true --accept-routes=false --exit-node= \
  --exit-node-allow-lan-access=false --shields-up=false
```

Keep GUI start-at-login and VPN-on-demand disabled, matching the private preference snapshot. Check status and the newly enrolled device identity locally without publishing the peer list. Verify connectivity to an intended available peer and, when running, the declared remote builder. IAP fallback is a separate path and does not prove tailnet readiness. The live checker only checks whether the bundled Tailscale CLI's `status --json` command succeeds; confirm enrollment, device identity, and connectivity separately.

## 11. Verify the activated workstation

```bash
cd /Users/shinzui/.config/dotfiles.nix
./bin/check-bootstrap.sh "$MACHINE_HOST" --live
command -v nvim mori rei tv nagarectl kubectl gcloud
test -L "$HOME/.config/nvim/lua"
test -L "$HOME/.config/nihongo/config.kdl"
test -L "$HOME/.config/seihou/config.dhall"
test -r "$HOME/.config/nhub/config.kdl"
test -r "$HOME/.config/ntn/config.kdl"
./bin/test-treesitter.sh
just status-postgres
python3 ./bin/check-rei-mori-owner.py --expect SungkyungM1X
# Runtime service health belongs to the active host until the separate cutover.
just status-victorialogs
just status-victoriatraces
just status-redpanda
```

The two public CLI files should be editable source links: a harmless temporary checkout edit should appear at the installed path and be restored afterward. Check each private consumer without printing tokens or keys. Inspect actual infrastructure readiness using [local services](local-services.md), not just launch-agent presence. Rei/Mori and their integrations must remain stopped on Yujin until the [sole-owner cutover](rei-mori-cutover.md); their inactive status is expected during bootstrap. Restore application data only from the selected owner backup. Record each authentication, service, Tailscale, and Mori identity result independently. A source-machine build or synthetic checker fixture does not count as physical onboarding.

## Resume and recovery

Resume at the first incomplete checkpoint. Keep the same destination keys, enrollment directory, and pre-rekey ciphertext backup. The key and recipient helpers preserve existing pairs and enrolled recipients. Neither helper deletes keys or removes old recipients. A complete GitHub registration can be detected and skipped; completed secret enrollment should be verified instead of needlessly rekeyed.

If enrollment stopped with uncommitted recipient/ciphertext changes, first confirm those changes belong to this enrollment. Do not repeat the clean-checkout/pull commands in phase 5 over that work. Restore the recorded `ENROLLMENT_WORK`, `CIPHERTEXT_BACKUP`, and `ENROLL_IDENTITY` variables, enter the dev shell, and resume rekeying/comparison against the original backup. If private publication already succeeded, resume with the public lock update and build. Never create a new baseline backup that hides an unresolved plaintext mismatch.

A failed switch may have applied some changes. Preserve its output privately, inspect the active generation, and fix the concrete failing prerequisite before retrying. If a previous working generation exists, use the built `./result/sw/bin/darwin-rebuild --help` to confirm rollback support and run `sudo ./result/sw/bin/darwin-rebuild switch --rollback` on that machine. Generation rollback does not undo Homebrew changes, logins, copied application data, or external device/key enrollment. Preserve conflict backups until the affected consumers pass.

## Evidence and remaining physical checks

As of 2026-10-14, all three declared system targets built on the source Mac. Yujin has its own two keys, GitHub registration, both checkouts, and passing prerequisite checks. A cold-cache evaluation subsequently exposed the private Kazuha HTTPS authentication requirement; the dedicated encrypted Nix token and phase 6 address that bootstrap dependency. All 24 secret ciphertexts were verified against original plaintext on the source and decrypted with Yujin's new identity without displaying plaintext.

With the dedicated token prepared from encrypted ciphertext, Yujin fetched the locked Kazuha archive, built `bootstrap-arm`, and completed full `yujin` evaluation with `--dry-run --no-link`. The organization library fetches succeeded over SSH at unchanged commits and content hashes. The helper kept matching credential state when rerun and refused cleanup before managed activation. The temporary enrollment token source was deleted after successful encryption and decrypt-to-comparison verification.

Minimal/full activation, Homebrew installation, Apple's Command Line Tools installation, provider logins, Tailscale enrollment, and application/data recovery have **not** been completed on Yujin. The checkpoints above make those remaining steps explicit; passing builds and helper tests are not evidence that the entire runbook has been exercised on a fresh machine.
