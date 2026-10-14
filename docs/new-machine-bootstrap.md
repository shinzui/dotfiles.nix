# New Apple Silicon Mac bootstrap

This runbook prepares a clean `shinzui` account on an Apple Silicon Mac using the public checkout, authorized private inputs, and selected user data. It never requires a copy of the old `~/.config`. The supported full host for the new Mac is `yujin`; use `SungkyungM1X` only on the existing source Mac. Builds assemble a candidate without switching the running system. A switch activates it and must run only on the matching machine.

## 1. Prepare the account and Nix

Sign in as `shinzui`, install Apple's Command Line Tools if prompted, and confirm `uname -m` is `arm64`. Install Git and an SSH identity authorized for both private flake inputs. Restore an already authorized workstation identity securely with `0600` mode, or enroll a genuinely new recipient in both secret tiers and rekey them before a full switch. Never put a private key in either Git checkout. Review [Determinate's workstation installation guide](https://docs.determinate.systems/getting-started/individuals/) before running the helper. It recognizes an existing Determinate installation and stops on a non-Determinate Nix installation. The stable package endpoint delivered v3.23.2 during repository preparation on 2026-10-14 UTC; its package metadata, Apple signature, and notarization were checked without installing it. Installation on the new Mac remains untested.

The public checkout must be at `/Users/shinzui/.config/dotfiles.nix`, because editable links point there. Clone it over SSH or HTTPS after Git is available, then run the installer helper. Private fonts and `mori://shinzui/dotfiles-private.nix` are root flake inputs even for the minimal bootstrap; authorized SSH access is required before evaluation. Clone the private companion to `/Users/shinzui/Keikaku/dotfiles-private.nix` and confirm both input fetches. For a new age recipient, use the actual public key in both repositories' `secrets/secrets.nix` and run `agenix -r` in each `secrets/` directory; publish the private change before updating the public input lock. Follow [secret onboarding](secrets.md) for identity paths and ciphertext checks.

```bash
mkdir -p /Users/shinzui/.config /Users/shinzui/Keikaku
git clone git@github.com:shinzui/dotfiles.nix.git /Users/shinzui/.config/dotfiles.nix
cd /Users/shinzui/.config/dotfiles.nix
./bin/darwin-install.sh
```

After a fresh installation, close this terminal and open a new one so its shell loads Nix's environment. Then confirm `nix --version` succeeds before continuing. If the helper reported that Determinate was already installed, use a shell where `nix` is available.

```bash
nix --version
```

```bash
mkdir -p /Users/shinzui/Keikaku
cd /Users/shinzui/Keikaku
git clone git@github.com:shinzui/dotfiles-private.nix.git
cd /Users/shinzui/.config/dotfiles.nix
git ls-remote --exit-code git@github.com:shinzui/fonts.git HEAD >/dev/null
git ls-remote --exit-code git@github.com:shinzui/dotfiles-private.nix.git HEAD >/dev/null
./bin/check-bootstrap.sh bootstrap-arm
```

The checker is read-only. `PASS`, `MISSING`, and `CONFLICT` lines name prerequisites without printing secrets. It exits 0 only when all required checks pass, 1 for a missing prerequisite or conflict, and 2 for invalid input or policy. Do not overwrite a conflicting target: inspect it and preserve it under a unique protected name outside both repositories before an intentional migration. Its `--home-dir` option is for isolated file checks and does not prove a machine is onboarded.

## 2. Build the minimal system, then the full host

The minimal target omits Home Manager and agenix and has no remote builder. On a clean Mac with required SSH input access, build as `shinzui`, record the current Darwin generation if one exists, and switch only on that Mac. Before the full switch, run `networksetup -listallnetworkservices` and confirm that `Wi-Fi` and `Thunderbolt Bridge` are present; the shared configuration declares those names. If either differs, adjust `networking.knownNetworkServices` in `hosts/yujin/default.nix` as described in [secret onboarding](secrets.md). Then run the full checker and build for `yujin`. Homebrew may need App Store and command line tool agreements. The full system retains the remote builder and its access requirements.

Prepare restricted parent directories for the selected private destinations before the full switch. These commands affect only the new Mac, after resolving any existing-file conflicts reported by the checker:

```bash
install -d -m 700 "$HOME/.config/nhub" "$HOME/.config/ntn" \
  "$HOME/.config/gcloud" "$HOME/.config/gcloud/configurations" \
  "$HOME/.config/nagare" "$HOME/.config/nagare/contexts" \
  "$HOME/.config/nagare/kubeconfigs" "$HOME/.kube"
```

```bash
cd /Users/shinzui/.config/dotfiles.nix
./bin/build.sh bootstrap-arm
sudo ./bin/darwin-rebuild.sh bootstrap-arm
networksetup -listallnetworkservices
```

Confirm the network service names and make any Yujin override before continuing:

```bash
./bin/check-bootstrap.sh yujin
./bin/build.sh yujin
sudo ./bin/darwin-rebuild.sh yujin
```

Wait for the agenix launch daemon after the full switch. `./bin/check-bootstrap.sh yujin --live` checks private secret destinations as `shinzui` for readability, owner, and mode `0600`; it does not print contents. The private companion's ciphertext is installed at nhub, ntn, gcloud profile, kubectl, and selected Nagare paths. Parent directories containing these files should be accessible only as intended. Keep source originals until the new machine's installed files and consumers work. New macOS Accessibility and Automation grants, application login prompts, and App Store or Homebrew requirements are interactive onboarding steps.

## 3. Restore application access and local identity

Reauthenticate renewable gcloud user sessions and application-default credentials for the three selected profiles. Check the intended active profile privately and test read-only access to the intended GCP resources; do not copy credentials databases, token caches, SDK logs, or print profile/account lists into a public log. The already-declared GKE auth plugin is required by some kubectl contexts. Restore private Kubernetes contexts from the encrypted config and owning Nagare checkouts, recreate auth/discovery/HTTP caches, then test a read-only query against each reachable intended environment. Work-owned host age keys and cluster authority remain with their owning project recovery process.

Nagare has a separate Nix profile installation. The source Mac's old profile references a revision that is not the current `v0.2.2` tag and has no root flake at that revision. The immutable `v0.2.2` release tag built on this Mac; its `nagarectl context list` parsed the selected local configuration, and its launcher listed recipes when `NAGARE_CONTEXT=local` was explicit. The source's old active context name is absent from its current context directory, so the launcher fails without that override. On the new Mac, recover and select an intended context before running the launcher. Do not silently install the latest 0.6 release or run a context upgrade. The currently published latest release was `v0.6.3` during preparation, but an upgrade needs its own reviewed transition. Consult `mori://shinzui/nagare/docs/user-manual`, project-relative `installation.md` (file URI pending). Repeat these nonactivating compatibility probes after restoring the selected context:

```bash
nix run 'github:shinzui/nagare/v0.2.2#nagarectl' -- context list
NAGARE_CONTEXT=local nix run 'github:shinzui/nagare/v0.2.2#nagare' -- --list
```

If those probes and a private read-only context check pass, install `nix profile install 'github:shinzui/nagare/v0.2.2#nagare'`. Clone the owning Nagare and operations repositories before recreating the selected symlinks under `~/.config/nagare`. Select the active context only after its destination and credentials exist. The local Mori registry and data must be restored before `bootstrap-repos` can clone its recorded projects; on a completely clean Mac, clone the essential repositories explicitly first. Generated databases and workspaces have separate recovery sources in [local services](local-services.md) and their owning runbooks; no database belongs in these dotfiles.

Mori must create a new local `~/.config/mori/host-id`. Verify privately that it differs from Sungkyung's protected copy; do not copy that value or write it back into shared source. On Sungkyung, before activating this changed Home Manager ownership, preserve the old `~/.config/mori` symlink itself under a unique name outside both repositories, create a real local `~/.config/mori` directory, and restore the protected `~/.local/state/dotfiles-bootstrap/sungkyung-mori-host-id` to `~/.config/mori/host-id` with mode `0600`. Confirm its bytes match the protected backup before using Mori. The tracked source's `host-id` was removed from Git, while the old source file remains ignored locally until this switch.

Review the differing historical `mori.bak` and `rei.bak` settings privately before discarding those backups. Their policy action is `data-export` until desired unique preferences have a specific owner and recovery route.

## 4. Enroll Tailscale as a new device

The full configuration already installs the standalone Tailscale app. Start it, approve the macOS system/network extension and VPN configuration, sign into the intended private tailnet, and complete any device approval. Do not copy the old plist, cached profiles, or node keys. Reapply the reviewed routing and DNS preferences with the app's bundled CLI after confirming the bundle exists:

```bash
test -x /Applications/Tailscale.app/Contents/MacOS/Tailscale
/Applications/Tailscale.app/Contents/MacOS/Tailscale set \
  --accept-dns=true --accept-routes=false --exit-node= \
  --exit-node-allow-lan-access=false --shields-up=false
```

Keep GUI start-at-login and VPN-on-demand disabled, matching the private preference snapshot. Check status and the newly enrolled device identity locally without publishing the peer list. Verify connectivity to an intended available peer and, when running, the declared remote builder. IAP fallback is a separate path and does not prove tailnet readiness. The live checker only checks whether the bundled Tailscale CLI's `status --json` command succeeds; confirm enrollment, device identity, and connectivity separately.

## 5. Verify the activated workstation

```bash
cd /Users/shinzui/.config/dotfiles.nix
./bin/check-bootstrap.sh yujin --live
command -v nvim mori rei tv nagarectl kubectl gcloud
test -L "$HOME/.config/nvim/lua"
test -L "$HOME/.config/nihongo/config.kdl"
test -L "$HOME/.config/seihou/config.dhall"
test -r "$HOME/.config/nhub/config.kdl"
test -r "$HOME/.config/ntn/config.kdl"
./bin/test-treesitter.sh
just status-postgres
just status-tools
just status-victorialogs
just status-victoriatraces
just status-redpanda
```

The two public CLI files should be editable source links: a harmless temporary checkout edit should appear at the installed path and be restored afterward. Check each private consumer without printing tokens or keys. Inspect actual service readiness using [local services](local-services.md), not just launch-agent presence. Restore application data only from the selected owner backup. Record each authentication, service, Tailscale, and Mori identity result independently. A source-machine build or synthetic checker fixture does not count as physical onboarding.
