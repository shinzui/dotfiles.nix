---
id: 6
slug: prepare-a-clean-and-private-new-machine-configuration-bootstrap
title: "Prepare a clean and private new-machine configuration bootstrap"
kind: exec-plan
created_at: 2026-10-14T00:27:16Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-14T00:27:16Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T00:32:41Z
      mode: "other"
      note: "Complete initial five-milestone plan from the configuration audit and private metadata snapshot"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T00:41:59Z
      mode: "discuss"
      note: "Restrict new config additions to seven user-selected keepers and include kubectl private recovery"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T00:52:15Z
      mode: "update"
      note: "Correct scope from evaluated Home Manager ownership and trace confirmed infrastructure prerequisites"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T02:13:08Z
      mode: "discuss"
      note: "Include Tailscale local preference recovery, new-device enrollment and remote-builder connectivity"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T02:41:37Z
      mode: "update"
      note: "Correct nhub and ntn to private encrypted configs after detecting literal KDL workspace tokens"
    - model: "gpt-6-sol"
      harness: "codex-cli"
      at: 2026-10-14T03:15:37Z
      mode: "implement"
      note: "Implement selective bootstrap policy, encrypted recovery, checker, runbook, builds, and ADR"
---

# Prepare a clean and private new-machine configuration bootstrap


This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture


Make a new Apple Silicon Mac usable from the public configuration checkout, an authorized private companion checkout, and explicitly recovered user data, without copying the old machine's entire `~/.config`. Preserve user-selected preferences and editable symlinks, install credentials required by retained tools through encrypted private declarations, and recreate login sessions, caches, local trust, and machine identity. The confirmed additional keepers are `nhub`, `ntn`, `nihongo`, `seihou`, `nagare`, `gcloud`, and `kubectl`; other unmanaged application configurations are excluded unless the user selects them. Tailscale installation is already managed, but its local preferences and fresh-device enrollment are an additional required onboarding prerequisite. A successful result is a documented bootstrap whose preflight reports concrete missing prerequisites and whose live checks confirm settings, secret installation, and useful tools on the new machine.

This is creation of an implementation plan after a read-only audit. It does not activate either workstation, relocate credentials, delete backups, or claim the new machine has been tested. Repository preparation and actual deployment are separate acceptance results.


## Progress


- [x] (2026-10-14 03:14 UTC) Classify all 70 audited top-level entries and selected file exceptions in the public policy; add exact private mappings for `~/.kube`, Tailscale, and selected sensitive files.
- [x] (2026-10-14 03:14 UTC) Encrypt and decrypt-compare ten selected private files, including nhub/ntn, gcloud profiles, kubectl, and Nagare local files; publish the private companion and update only its public lock input.
- [x] (2026-10-14 03:14 UTC) Add public editable nihongo/seihou links, isolate Mori's tracked host identity with a protected source-machine backup, and disable the bootstrap target's remote builder.
- [x] (2026-10-14 03:14 UTC) Provide the Determinate installer helper, ordered runbook, audit rationale, and read-only checker.
- [x] (2026-10-14 03:14 UTC) Pass isolated checker scenarios, bootstrap/full-host evaluations, and non-activating builds for all three targets.
- [x] (2026-10-14 03:14 UTC) Distill selective ownership, encrypted credentials, local identity, and bootstrap ordering into a local ADR.
- [ ] Review unique differences in historical Mori/Rei backups privately and export any desired preference before discarding those backups.
- [x] (2026-10-14 03:18 UTC) Build released Nagare `v0.2.2` without installation; verify `nagarectl context list` and `NAGARE_CONTEXT=local nagare --list` against the source configuration without changing its profile.
- [ ] On the actual new Mac, enroll Tailscale, restore renewable authentication, activate the matching host, verify secret modes and consumers, Mori identity, services, and data restoration. No new Mac is accessible in this implementation session.
- [ ] Finish the retrospective after the remaining repository probe and record physical onboarding separately when it occurs.


## Surprises & Discoveries


Implementation evidence (2026-10-14 UTC): The evaluated `bootstrap-arm` builder settings changed from `true` and one `nix-gcp-builder` entry to `false` and `[]`; full-host derivations and non-activating builds succeeded. `./bin/check-bootstrap.sh bootstrap-arm` on Sungkyung reports four public target conflicts and ten pre-existing private destination conflicts, as expected from its existing whole Mori link, unmanaged CLI files, and original private files; it does not overwrite them.

The historical `mori.bak/config.dhall` and `rei.bak/config.yaml` differ byte-for-byte from active source. A redacted structural comparison found no old-only setting keys; Rei's backup carries an older option value. Mori's backup-only `automation-config` skill is absent from current linked sources and the registered Mori checkout. Their policy action is `data-export`, not `exclude`, pending a decision on that unique skill. No backup was deleted.

The pinned agenix editor returned exit zero when its editor failed to create ciphertext, and a heredoc loop caused it to replace `EDITOR` with `cp /dev/stdin`. Running each edit with terminal stdin (`</dev/tty`) and checking non-empty ciphertext plus decrypt-to-`cmp` produced ten verified files. The original plaintext files remain only on the source machine.

The Determinate stable macOS package endpoint returned v3.23.2. Its downloaded package reported that version in `PackageInfo` and passed Apple's signature and notarization check; no package installer ran. The final private policy records thirteen Nagare first-hop links without following their targets. With that final private pin, checker fixtures and all three non-activating Darwin builds passed again.

The current `v0.2.2` Nagare tag exposes `#nagare` and `#nagarectl` on `aarch64-darwin`, and its non-activating build passed. `nagarectl context list` parsed local state. The launcher failed when the source's stale active context name pointed to a missing file, then passed `--list` with an explicit `NAGARE_CONTEXT=local` and isolated temporary state. The release commit differs from the old profile's recorded revision; the new machine must repeat the private context check before installing the tag.


## Decision Log


Decision (2026-10-14 UTC): Use an explicit selection of settings, never a recursive copy of `~/.config`. Every top-level entry must have a disposition, and mixed directories must have file-level exceptions. Cache exclusion must not discard unique preferences, skills, or user data.

Decision (2026-10-14 UTC): Keep sensitive values and detailed credential/account metadata in `mori://shinzui/dotfiles-private.nix`, physically checked out at `/Users/shinzui/Keikaku/dotfiles-private.nix`. Persistent credentials are encrypted; plaintext never becomes Git-tracked content in either repository. Recreate renewable login sessions. Respect the existing work-owned cluster-identity boundary: sensitive workstation onboarding metadata goes privately, while work-owned host authority remains with its owning project and recovery process.

Decision (2026-10-14 UTC): Follow `home/xdg-configs.nix`: use out-of-store symlinks, which link to editable checkout files rather than immutable generated content, for hand-maintained preferences. Use individual files inside mixed directories. Keep existing Home Manager generated settings and agenix secret links under their current managers. Mori's host identity must be local to the machine.

Decision (2026-10-14 UTC): Scope the initial onboarding to `arm64` macOS with login `shinzui` and public checkout `~/.config/dotfiles.nix`, matching the current configuration. Report other architectures or login names as unsupported prerequisites rather than promising path independence that the repository does not have. Coordinate with the existing host plan instead of implementing another host abstraction here.

Decision (2026-10-14 UTC): Preserve existing dependencies and compatibility state versions. Fix bootstrap ordering and documented prerequisites rather than adding dependency upgrades. The user selected Skip for Intention tracking.


Decision (2026-10-14 UTC, user clarification): Directory presence does not establish continued use. The user explicitly selected `nhub`, `ntn`, `nihongo`, `seihou`, `nagare`, `gcloud`, and `kubectl`. These are required keepers. Other unmanaged application settings default to exclusion until explicitly selected. Existing declared modules remain the baseline and are rebuilt by Nix; they are not additional migration candidates or an app-retirement task. Do not migrate credentials for an unselected app merely because they exist.


Decision (2026-10-14 UTC, ownership correction): Determine management at the exact file level from the merged Home Manager `home.file` and `xdg.configFile` declarations, including exported flake modules, rather than from directory names or package installation. Existing generated settings, tracked-source symlinks, agenix destinations, and declared service configuration are reconstructed by their managers. Only unmanaged settings selected by the user require capture. Preserve the declared application baseline; app retirement is outside this audit correction.


Decision (2026-10-14 UTC, Tailscale): Preserve the existing standalone `tailscale-app` cask declaration. Enroll each new machine with its own Tailscale identity and reapply selected client preferences; do not transfer node keys, raw state, cached account profiles, or a whole preference plist. Keep account/tailnet metadata and reviewed recovery settings in the private companion. macOS network-extension/VPN consent and login are explicit onboarding steps. The existing remote builder prefers tailnet connectivity, so validate that dependency before claiming the builder is ready.


Decision (2026-10-14 UTC, content placement correction): The actual `nhub/config.kdl` and `ntn/config.kdl` contain literal workspace tokens. Preserve each whole config as an agenix-encrypted private secret installed at its current destination, retaining aliases and workspace settings without inventing a split-config mechanism. Neither file is a public tracked source or ordinary private plaintext Git source. `nihongo/config.kdl` contains aliases and `seihou/config.dhall` contains non-secret preferences; those two are public editable sources. A credential check must recognize KDL `token` nodes and provider-token literals, not only API-key-shaped field names.

Decision (2026-10-14 UTC, implementation): Encrypt the selected gcloud profile files and active selection, `~/.kube/config`, and Nagare's local context and two local kubeconfigs as individual private agenix records. Reauthenticate renewable gcloud state and keep work-owned Nagare host authority with its owning project. This preserves the selected workflows without copying a broad token database or whole config tree.

Decision (2026-10-14 UTC, implementation): Treat differing Mori/Rei backups as possible user data until privately reviewed. Keep the backup files untouched and mark them `data-export`; do not infer that a historical backup is disposable from its name.


## Outcomes & Retrospective


Repository preparation has produced a 70-entry selection policy, an ordered runbook, a read-only checker with synthetic risk scenarios, private encrypted recovery files, editable public links, a machine-local Mori identity boundary, and a bootstrap target free of remote-builder credentials. The private companion commits `ac0575b` (encrypted recovery), `78e7973` (metadata-only audit history), and `a0f7e54` (Nagare link recovery map) are published; the companion is the only updated public lock input. Non-activating Nix evaluations and builds passed for bootstrap, Sungkyung, and Yujin. The released Nagare `v0.2.2` operator package built and passed explicit local-context command probes. The source-Mac preflight correctly reports existing target conflicts. This is not a live deployment result. Remaining work is disposition of Mori's unique backup-only skill and physical new-Mac activation, authentication, Tailscale enrollment, secret consumer checks, and service/data recovery.


## Context and Orientation


The public repository is `/Users/shinzui/.config/dotfiles.nix`. `flake.nix` names its dependencies, `flake.lock` fixes their revisions, and `flake-modules/darwin-configurations.nix` combines system modules from `darwin/` and user modules from `home/`. Nix-darwin applies system settings; Home Manager applies user programs and files. A build assembles a candidate configuration; activation changes the running machine. The current full targets are `SungkyungM1X` and `yujin`; `bootstrap-arm` includes `darwin/bootstrap.nix` and Determinate integration but omits Home Manager and agenix secret installation.

`home/xdg-configs.nix` links whole `kazuha`, `mori`, and `rei` directories from `config/xdg/`, and individual `mina/config.kdl` and `okf/config.dhall` files. `home/neovim.nix` individually links `nvim/lua` and `nvim/after`; generated startup configuration remains separately managed. `home/external-configs.nix` deploys PostgreSQL client, pspg, Bird, and YAML lint settings. `home/claude.nix` links shared agent instructions outside XDG configuration; those declarations are already covered and must survive. XDG configuration means the conventional `~/.config` directory here.

Live Home Manager links often first point into `/nix/store` even when the final editable source is outside it. The audit used only `lstat`, directory walks that do not follow links, and first-hop `readlink`. It never traversed those targets or secret links. Maintain this restriction: never search, read, glob, or resolve paths inside `/nix/store`, and never search filesystem root. Source declarations establish intended ownership; metadata alone does not prove a final symlink chain works.

The audit on 2026-10-14 UTC covered 70 top-level entries in `~/.config`, excluding traversal of the public repository and `.git`/`node_modules` trees. Detailed metadata and credential findings are saved in `mori://shinzui/dotfiles-private.nix` with project-relative path `docs/audits/2026-10-14-config-bootstrap.json` (artifact-level URI pending). This contains paths, types, modes, counts, first-hop links, and disposition suggestions, never credential values. It is an observation snapshot, not an automatic copy list. The self-contained policy below is sufficient to implement public changes; consult the private snapshot locally for exact sensitive paths.

Ownership was rechecked by evaluating the actual `SungkyungM1X` Home Manager configuration, not only by scanning modules. The merged `xdg.configFile` has 20 target names, and merged `home.file` includes targets declared through `home/external-configs.nix`, the exported aliases/Wezterm/Starship modules, and shared user modules. Existing Atuin, Bat, Btop, Cachix, Git/GitHub CLI settings, Neovim, Starship, tmux, Wezterm, Bird, pgcli, pspg, and yamllint settings are already declared and need no migration capture. `home/xdg-configs.nix` already owns the Kazuha/Mori/Rei directory links and Mina/OKF file links. Agenix owns the already-declared secret destinations. `home/local-web-proxy.nix` generates Caddy's configuration and runs it as a declared service; its autosave is not a source config to capture.

Package management is separate from preference-file management. `home/notion-hub.nix` installs `nhub`, completions, its PostgreSQL connection environment, and subscription agent, but does not deploy `~/.config/nhub/config.kdl`. `home/notion-cli.nix`, `home/nihongo.nix`, and `home/seihou.nix` install their packages/completions but do not deploy their respective `config.kdl`/`config.dhall` files. Those four paths are regular unmanaged files and are absent from both merged deployment target sets. `home/default.nix` already installs gcloud with the GKE auth plugin and kubectl; profiles and `~/.kube/config` are absent from deployment declarations. `darwin/gcp-nix-builder.nix` depends on the user's authenticated gcloud environment, so recovering access is an existing infrastructure prerequisite, not adding another SDK install.

Nagare and nagarectl are available through a separate active `nix profile` element named `nagare`, not through this dotfiles package list. That element reports original URL `github:shinzui/nagare/v0.2.2`, resolved revision `248e5f95803c0110b5890b611c7bbd24468f8d71`, and package version `0.2.2`. Upstream release metadata currently reports `v0.6.3`, and the current `v0.2.2` tag does not resolve to the installed element's revision. The registered checkout does not provide a root `flake.nix` at that old revision. Therefore do not assume reinstalling the old tag or adopting the newest same-named package reproduces this installation. Establish a compatible reproducible Nagare install from its owning project during bootstrap preparation. A read-only `nagare --help` invocation also failed a missing-context lookup while `nagarectl --help` succeeded; verify wrapper environment/context selection as well as file recovery. No command deployment, authentication, or infrastructure mutation was performed.

Confirmed config additions are the privately encrypted `nhub/config.kdl` and `ntn/config.kdl`, and the public `nihongo/config.kdl` and `seihou/config.dhall`. A content-level check found literal provider tokens under KDL `token` nodes in nhub/ntn; the earlier field-marker scan was insufficient. Detailed placement findings are recorded without values in `mori://shinzui/dotfiles-private.nix` with project-relative path `docs/audits/2026-10-14-notion-config-bootstrap.json` (artifact-level URI pending). Nagare, gcloud, and kubectl are also explicitly required. Other unmanaged candidates are observations, not approved additions. Selecting a config file does not approve an entire agent installation tree.

Historically observed unmanaged preference candidates are `ghostty/config` and its four theme files, `gh-dash/config.yml`, `gitui/theme.ron`, `goose/config.yaml`, `cmux/cmux.json`, `karabiner/karabiner.json`, `zed/settings.json`, `worktrunk/config.toml`, `direnv/direnv.toml`, `television/config.toml` and selected `television/cable/*.toml`, plus `nhub/config.kdl`, `ntn/config.kdl`, `nihongo/config.kdl`, and `seihou/config.dhall`. Preserve selected source skills under `mina/agents`, `ntn/agents`, `seihou/agents`, and `testkit/agents` only after comparing them with their producing repositories or installation recipes. An absence of a credential-shaped field is not proof that a candidate is public-safe. `cmux/cmux.json` has JSON comments and a `socketPassword` field; that field was empty during audit. Do not treat the marker as evidence of a stored password or parse this file as strict JSON without supporting comments.

There are genuine mixed-file pitfalls. Worktrunk's active config contains command-approval records and absolute paths as well as preferences; its `.new` file is a separate comparison candidate, not the active source. Television already owns the generated `cable/nix-search-tv.toml` through `home/nix-search-tv.nix`; do not link the entire `television` directory over it. Direnv already manages integration files through `home/default.nix`; its additional `load_dotenv` preference is unselected. If selected later, add it through the existing module or one file, not a second directory owner. Karabiner backups and hardware profile settings must be separated from desired remappings, and compared with the existing Caps Lock remapping in `darwin/default.nix`.

Sensitive or authentication-bearing families include `gcloud`, `argocd`, parts of `nagare`, the standalone signer directory, and potentially app-specific account settings. A standalone JSON signer has a private-key field. Existing `sops` and other managed secret links should be recreated by agenix, not copied after decryption. `gh/hosts.yml` currently contains account metadata without an inline token; its live credential may be elsewhere, so copying this file does not establish GitHub authentication. The private report contains the exact persistent credential candidates. Use private declarations for required persistent files and reauthenticate renewable user sessions.

The user explicitly added kubectl to the scope. Its main config is outside `~/.config`, at `~/.kube/config`, observed as a regular file with mode `0600`. A redacted CLI parse counted seven contexts, five clusters, and five user records, with embedded certificate/private-key authentication and executable authentication commands. Preserve needed contexts and authentication through private recovery, never public plaintext. Recreate `~/.kube/cache`, `~/.kube/http-cache`, and the GKE auth plugin cache. A supplemental metadata-only audit is in `mori://shinzui/dotfiles-private.nix` with project-relative path `docs/audits/2026-10-14-kubectl-bootstrap.json` (artifact-level URI pending). Gcloud has three named profiles to recover privately; Nagare contains context settings, kubeconfigs, operator settings, repository-owned links, and work-owned identities requiring their existing recovery boundary.

Tailscale is already installed by the `tailscale-app` cask in `darwin/homebrew.nix`, shared by both full hosts. The installed standalone app has bundle identifier `io.tailscale.ipn.macsys` and version `1.102.3`. Its observed GUI preferences live at `~/Library/Preferences/io.tailscale.ipn.macsys.plist`, not under `~/.config`; the plist also contains cached profile/account state and is not a wholesale migration source. Querying the app's bundled CLI, rather than assuming a separate `tailscaled` service, showed a running online client. The current selected preferences accept tailnet DNS, reject advertised subnet routes, select no exit node, and leave shields-up disabled. The GUI start-at-login and VPN-on-demand preferences are false; preserve those intentional values rather than automatically enabling them. Tailscale SSH server and web client are disabled. A private allowlisted preference snapshot with no `Persist`, node keys, account names, or peer list is stored in `mori://shinzui/dotfiles-private.nix` with project-relative path `docs/audits/2026-10-14-tailscale-bootstrap.json` (artifact-level URI pending).

`darwin/gcp-nix-builder.nix` prefers the builder's existing tailnet hostname and falls back to gcloud IAP. That endpoint is already declared; there is no new public Tailscale config directory to add. Recreate enrollment and selected preferences, retain host-specific naming, and verify required tailnet reachability. Central tailnet access policies and device approval are not local dotfiles and should not be inferred from a plist. Official [macOS variant guidance](https://tailscale.com/docs/concepts/macos-variants), [system-extension instructions](https://tailscale.com/docs/concepts/macos-sysext), and [CLI preferences reference](https://tailscale.com/docs/reference/tailscale-cli?tab=macos) were checked, together with the installed app's `set --help`. Mori searches found no registered Tailscale corpus. No release pin or upgrade is proposed.

Most measured bytes are generated data: the regular files under `gcloud` total roughly 296 MB, and under `raycast` roughly 180 MB, excluding symlink targets and skipped `node_modules`. Do not claim all those bytes are disposable. Exclude token databases, logs, SDK caches, generated extensions, compiled caches, sockets, update-notifier state, editor embeddings, and stale backups from the bootstrap payload. Preserve unique prompts, conversations, custom extensions, and meaningful differences through an explicit data export when needed; they are user data, not portable application settings.

Other observed entries needing explicit disposition are `.DS_Store`, `anthropic`, `asciinema`, `btop` logs, `cabal`, `caddy` autosave, `cai`, `configstore`, `ghc`, `helix`, `hunk` state, `iterm2`, `k3d`, `kitty`, `longbridge`, `mole`, `mori-rei-app`, `mori.bak`, `nagare`, `nix`, `notion-cli`, `op`, `raycast`, `rei.bak`, `reiko`, `silicon`, `simple-update-notifier`, `testkit`, `yarn`, and `zed` data. Empty directories require no transfer. `mole` has a hand-edited-looking cleanup list: review it before exclusion. `caddy/autosave.json` can contain operational configuration: preserve its intentional source privately when required, regenerate autosave from the declared proxy config. `nix/registry.json` and `nix.conf.backup` should not silently override the declared Nix settings. Yarn's global manifests and link registrations require comparison with declared packages; do not copy global installation state wholesale.

`config/xdg/mori/host-id` is Git-tracked and included in the whole-directory symlink. The installed `mori --version` reports `v6.0.0.0 (9b6d0e1)`, matching the public lock. Source at that revision in `mori://shinzui/mori/packages/mori-core`, project-relative file `mori-core/src/Mori/Host/Identity.hs` (file-level URI pending), creates a local identity when missing and supports `MORI_HOST_ID_FILE`. Copying the tracked identity would make two machines appear identical to Mori. Preserve Sungkyung's existing identity locally before excluding it from shared sources; let the new machine mint its own.

The host work is now implemented: `flake-modules/darwin-configurations.nix` composes `SungkyungM1X` and `yujin` from shared modules plus sibling `hosts/sungkyung/` and `hosts/yujin/` modules. `bin/build.sh` accepts an explicit target and defaults to Sungkyung; `bin/darwin-rebuild.sh` requires a target and the Sungkyung compatibility wrapper delegates to it. Keep those contracts. `bin/darwin-install.sh` still invokes the upstream installer while active modules use Determinate. Minimal bootstrap still declares a remote builder without its decryptable identity; disable remote builders for that target only. `bootstrap-repos` requires a reachable populated Mori registry and cannot seed it. Existing declared service and workspace data recovery remains separate from configuration capture.

The relevant local decision is `docs/adr/1-shared-workstation-modules-and-host-overrides.md` ([local link](../adr/1-shared-workstation-modules-and-host-overrides.md)), now present following host implementation. It preserves shared `darwin/` and `home/` configuration, independent host overrides, explicit build/switch targets, and separate live onboarding acceptance. No profiled ADR bundle is declared by `mori show --full`. The relevant private decision was read at `mori://shinzui/dotfiles-private.nix` with project-relative path `docs/adr/1-two-tier-agenix-secrets.md` (artifact-level URI pending; a registry concept search returned no handle). Its rule keeps account access, chargeable services, publishing privileges, and hard-to-rotate credentials private; fetches private inputs through authorized SSH; retains work-owned cluster identities under their owner; and verifies installation after the Darwin agenix launch daemon runs. Both public and private recipient rules must be rekeyed when a real new identity is added. A known pinned agenix editor behavior can return success without ciphertext, so require non-empty ciphertext and a decrypt-to-comparison check.

Dependency discovery used Mori first; Home Manager, nix-darwin, and agenix were not registered. Relevant upstream files were obtained into a specific temporary directory at the root inputs' actual locked revisions, without searching the store. Home Manager source verifies `mkOutOfStoreSymlink`, collision checks, and file ownership for Television and Direnv. This plan introduces no version bounds, pins, or compatibility workarounds. The current Determinate installation and nix-darwin integration guidance was also checked against the provider's official documentation.


## Plan of Work


### Milestone 1: Turn the snapshot into an explicit migration policy


Create `config/bootstrap/config-policy.json` as a public, versioned selection of non-sensitive paths and actions, and `docs/config-bootstrap-audit.md` as its readable rationale. Each record has `path`, `action`, `owner`, and `reason`. Supported actions are `managed`, `public-file`, `public-directory`, `private`, `reauthenticate`, `recreate`, `data-export`, and `exclude`. Paths are relative to the source configuration root; reject absolute paths and parent-directory escapes. Public sensitive-family records identify only a broad family; exact credential mapping, account identifiers, and exclusions inside that family go in the private companion's project-relative `config/bootstrap/private-policy.json` (artifact-level URI pending). Store no credential values in either manifest.

Account for all 70 snapshot entries using the groups above, then inspect mixed directories at file level. Keep the raw private snapshot as historical evidence and put later decisions in the policy, rather than rewriting the snapshot. First evaluate merged `home.file` and `xdg.configFile` targets, including exported modules and ordinary Home Manager program modules. Mark exact already-owned targets `managed`; never add them to the user selection list or recapture their generated content. A package being installed does not establish ownership of its application preference files. Retain managers instead of duplicating sources. Select nihongo/seihou as public source files, nhub/ntn as encrypted private config records, and required Nagare/gcloud/kubectl recovery records. Assign other unmanaged candidates `exclude` unless the user explicitly adds them; local inspection alone cannot approve an unused app. Omit empty directories and generated state. Compare backups with active settings without printing contents; carry forward meaningful unique preferences before excluding backups. Explicitly classify app data and local source skills, with a recovery method for each desired export. Keep unrelated package/application retirement outside this migration work; saving a theme does not justify enabling an old disabled program such as GitUI.

Acceptance is a coverage check in `bin/test-bootstrap-checker.py`: every snapshot top-level name has a policy action, and every selected source path exists as a regular file or approved source directory without following symlinks. There is no unresolved disposition. The public document reports the policy and exceptions without revealing private account metadata.

### Milestone 2: Manage required sensitive workstation files privately


In `mori://shinzui/dotfiles-private.nix`, extend project-relative `secrets/secrets.nix` and `darwin/secrets.nix`, following its existing naming, recipients, paths, owners, and permissions. The artifact-level URIs for those files are pending. Select persistent service-account or signer material only when required by retained tools, assign stable secret names in the private policy, and install it at each consumer's existing destination with mode `0600`. Keep parent directories suitably restricted. Do not commit plaintext private keys or build plaintext into a Nix derivation. An ordinary out-of-store symlink into a private Git checkout is appropriate only for non-secret private settings; private source control alone is not encryption.

Manage nhub and ntn whole configs as encrypted secrets in the private companion. Assign stable private names such as `notion-hub-config` and `notion-cli-config`, with the existing destinations `~/.config/nhub/config.kdl` and `~/.config/ntn/config.kdl`, owner `shinzui`, mode `0600`, and appropriately restricted parent directories. Preserve the complete existing config, including aliases, through encrypt/decrypt comparison without printing values. Do not copy these files into public `config/xdg/` or declare a second Home Manager owner for either destination. Editing those credential-bearing files must use the private encrypted-source workflow.

Recover the three gcloud named profiles and intended active selection privately. Reauthenticate gcloud user sessions and application-default credentials when needed by retained consumers; encrypt necessary persistent service-account material privately. Omit SDK caches, logs, and token databases. For Nagare, privately map required contexts, kubeconfigs, operator settings, repository-owned links, and recovery prerequisites; clone the owning repositories before recreating those links. Restore an active context only after its destination exists. For kubectl, recover required contexts and authentication mechanisms from `~/.kube/config` and Nagare kubeconfigs. Embedded client keys/certificates are private secret material; retain required authentication executables, including the already-declared GKE plugin. Recreate discovery, HTTP, and auth caches. Reauthenticate GitHub or other applications only as required by the retained baseline; Argo CD and the standalone signer are not selected additions. Preserve work-owned cluster authority in the owning recovery workflow and document its prerequisite privately; do not collect cluster host keys into the personal companion merely because they appear under `~/.config`. For each required sensitive record, its outcome must be encrypted deployment, successful fresh authentication, or a verified owning-project recovery handoff, rather than an ambiguous omission.

For Tailscale, keep only reviewed preference values and required account/tailnet onboarding metadata in the private policy. Do not encrypt and transfer the old node's identity as a migration credential. Sign the new standalone app into the intended account/tailnet as a new device, complete any device approval, and reapply preferences through the supported CLI or GUI. Do not symlink its mutable plist into a checkout or copy cached profiles. Use the new host's own hostname. The app's system-extension and VPN permissions are macOS onboarding requirements; preserve the GUI startup/on-demand preference choices recorded privately.

Preserve recoverable originals until activated copies match byte-for-byte and their consumers work. For actual new recipients, use the real public key, update both tiers, and re-encrypt ciphertext; never invent identities. Publish private changes before updating only `dotfiles-private` in the public lock. Do not rotate unrelated credentials or rewrite public history as part of this task. Acceptance is non-empty ciphertext, decrypt-to-`cmp` success, private repository diffs containing ciphertext/declarations only, and mode/readability/consumer checks after agenix finishes. A successful switch alone does not pass this milestone's live acceptance.

### Milestone 3: Deploy portable preferences with appropriate symlinks


The seven selected tools do not require seven new package installations, and Tailscale already has a managed cask installation. Four already-installed personal CLIs need their missing config-file deployment: two public editable source declarations and two private encrypted secret declarations; gcloud and kubectl need private profile/context/authentication recovery; Nagare additionally needs reproduction of its separate profile installation. Confirm exact destination ownership before adding any new declaration.

Copy only the reviewed `nihongo/config.kdl` and `seihou/config.dhall` into matching `config/xdg/<app>/` paths and extend `trackedConfigFiles` in `home/xdg-configs.nix`. Link these two files individually as editable sources. Nhub and ntn are deployed by the private agenix module from milestone 2, not as public source links; their current config files contain actual tokens. Nagare and gcloud use private settings and secret/recovery mappings; kubectl's private destination is `~/.kube/config`, outside XDG configuration. Tailscale installation and the existing remote-builder wiring stay in this public repository, with reviewed client preferences and account-specific onboarding metadata recorded privately and each new device identity generated locally. Leave runtime state and installation records outside shared sources. Other unmanaged app settings remain excluded until explicitly selected.

Preserve the existing Television-generated Nix search channel and Direnv integration; their unmanaged settings/custom channels and additional local preferences are unselected. If the user adds Worktrunk later, omit embedded approvals and use active preferences rather than blindly preferring `.new`. If Karabiner is selected, compare mappings with the declared Caps Lock behavior and omit nonportable hardware matching. Only separately selected source skills are linked or regenerated from a recorded owning project/recipe. An app config selection does not approve its entire agent installation tree.

Change Mori from a shared whole-directory link to individually selected config/skill sources, leaving `~/.config/mori/host-id` writable and local. Before that change on Sungkyung, back up its identity from `config/xdg/mori/host-id` in the editable source checkout to a private local recovery location; do not follow the live store link to make that backup. After unlinking the directory and before running Mori, restore that identity at the local destination without altering its value. Remove `config/xdg/mori/host-id` from shared tracked source and prevent reintroduction. New machines start without that file. Source skills below `config/xdg/mori/agents` may still be linked through selected safe files or an audited source-only subtree. Existing `kazuha`/`rei` directory links remain only if their content audit finds no per-machine or writable state requiring separation.

Acceptance is successful Home Manager evaluation with exactly one owner per destination, correct source coverage, and no deployed backups, logs, approval records, or shared host identity. On an activated machine, edits to the public nihongo/seihou checkout settings are visible without rebuilding; verify this through a harmless temporary preference change and restore it. Mori's old identity remains stable on Sungkyung and differs from the identity minted on the new machine.

### Milestone 4: Make bootstrap prerequisites and ordering executable


Create `docs/new-machine-bootstrap.md` and `bin/check-bootstrap.sh`; link the guide from `README.md` and reconcile `docs/secrets.md`. Replace the obsolete `bin/darwin-install.sh` with a helper for the repository's selected Determinate installation path. It must detect an existing Nix installation and avoid installing a second daemon. The current official macOS package download is `https://install.determinate.systems/determinate-pkg/stable/Universal`, verified through the provider's [workstation installation guide](https://docs.determinate.systems/getting-started/individuals/). Have the helper report an existing installation; otherwise download that package to a unique temporary path with `curl -fL` and invoke `/usr/sbin/installer -pkg <downloaded-package> -target /` through sudo when the owner explicitly runs the install helper on the new machine. Record the package version tested during implementation, detect an existing non-Determinate installation as a migration prerequisite, and recheck the provider's current instructions before executing installation. The existing module follows the provider's [nix-darwin integration contract](https://docs.determinate.systems/guides/nix-darwin/), so retain that distribution and module ownership.

The guide's order is developer tools and Determinate Nix, an authorized SSH identity, public checkout at the expected path, private-input access, bootstrap build/activation when needed, private secret access or recipient enrollment, full host build/activation, secret installation checks, authentication, and declared service/data restoration. Private fonts and the companion are root flake inputs even when their modules are excluded; do not advertise anonymous bootstrap without an isolated proof. Require SSH access before evaluating this flake. Keep remote builds disabled for the minimal bootstrap through `flake-modules/darwin-configurations.nix` so its shared bootstrap settings do not need a decrypted builder key; preserve full-host remote-builder behavior.

Add Tailscale enrollment to `docs/new-machine-bootstrap.md`: start the existing managed standalone app, approve the network extension and VPN configuration when requested by macOS, sign in to the intended tailnet, complete required device approval, then reapply the selected private preferences. Preserve the already-declared cask and avoid installing a second client variant or starting a parallel `tailscaled` daemon. The app-bundled CLI is `/Applications/Tailscale.app/Contents/MacOS/Tailscale`; verify the installed bundle before using it. `debug prefs` is an unstable diagnostic interface, so use it for local observation only and use supported `set` flags for recovery. First-build checks must distinguish a not-yet-installed app or unenrolled device from a missing source config; live readiness requires successful enrollment and connectivity. Do not treat successful IAP fallback as proof of Tailscale readiness.

The checker takes an explicit target and has a read-only default mode and `--live` mode. Validate known target names from the current flake, `arm64`, `shinzui`, checkout location, required commands, source presence, intended symlink conflicts, and GitHub private-input access. Report labels and statuses without secret contents or private metadata. Default mode does not demand installed secrets, because it precedes activation. Live mode checks installed destinations from the private policy locally, permission/readability and selected tool/service health. A missing secret reports a generic label and nonzero status. It never installs, copies, authenticates, activates, or deletes anything. Conflicts are reported, not force-overwritten; use a unique protected backup before a later intentional migration rather than relying on repeatedly available `.backup` names.

Use the implemented `yujin` target and generic build/switch wrappers without introducing another host assembly. Add a reproducible recovery step for the separately installed Nagare CLI: consult `mori://shinzui/nagare` through Mori, inspect the owning source and installation documentation, compare released tags with the recorded installed source, and demonstrate compatibility with the selected context/command workflow before choosing an installation reference. Preserve existing dotfiles inputs and avoid an implicit Nagare major-version migration. The acceptance for this prerequisite is working `nagarectl` and the expected Nagare entry point on the new Mac without dependence on the old user profile. The guide must require a valid new-machine target before full activation and must never switch Sungkyung to the new machine's identity. Explain App Store/Homebrew prerequisites, application logins, macOS accessibility permissions, and optional apps. These cannot be inferred from config files. Explain that a Mori registry/data recovery precedes `bootstrap-repos`; a clean machine may need explicit essential clones first. Document the existing data runbooks and the source of each required backup, without bundling databases into dotfiles.

Acceptance is actionable `PASS`, `MISSING`, or `CONFLICT` output with exit status zero only when required checks pass. The guide has a complete ordered path on a machine without the old config tree and names every remaining interactive credential or OS permission step.

### Milestone 5: Prove selective recovery and record deployment evidence


Implement `bin/test-bootstrap-checker.py` using Python's standard library. Give the checker a `--home-dir` path parameter for file checks and controlled command substitutes in the test harness; never repurpose process `HOME` or execute activation commands. Create synthetic fixtures with public settings, a sibling fake log/history/cache, a link to a forbidden target, a pre-existing target conflict, missing required sources, and local approval state. Check policy coverage, path escape rejection, no link traversal, exact target validation, argument handling, and secret-free output. Verify live-mode permission and missing-secret behavior using dummy fixtures, never real credentials. A fixture with an absent secret must pass pre-activation file checks but fail the corresponding live checks. Clearly label these as checker tests rather than a simulated nix-darwin deployment.

Run bootstrap and full-host evaluation and non-activating builds. Then follow the guide on the actual new Mac with no blanket config transfer and record package availability, editable settings, independent Mori identity, authentication readiness, secret installation, and service readiness. If no new Mac is accessible, complete repository checks and leave the live acceptance item open with that limitation. Update or create local ADRs for selective config ownership, local machine identity, private encrypted persistent credentials, and bootstrap prerequisites, following any ADR convention introduced since this plan was created. Only then fill Outcomes & Retrospective and distinguish prepared code from proven physical onboarding.


## Concrete Steps


Start from the public repository and preserve unrelated work, including existing edits to the host plan. The following commands are read-only:

```bash
cd /Users/shinzui/.config/dotfiles.nix
git status --short
mori registry show shinzui/dotfiles-private.nix --full
mori registry docs shinzui/dotfiles-private.nix
mori path mori://shinzui/dotfiles-private.nix
uname -m
id -un
```

The Mori path resolves to `/Users/shinzui/Keikaku/dotfiles-private.nix`; architecture and login must be `arm64` and `shinzui` for this scope. Read the private audit locally without dumping its sensitive details to public logs. Refresh changed observations using metadata only. Public audit prose uses broad private-family labels; private mappings supply exact paths.

Before selecting source files, run these read-only ownership queries from the public repository root:

```bash
nix eval --json .#darwinConfigurations.SungkyungM1X.config.home-manager.users.shinzui.xdg.configFile --apply 'files: builtins.attrNames files'
nix eval --json .#darwinConfigurations.SungkyungM1X.config.home-manager.users.shinzui.home.file --apply 'files: builtins.attrNames files'
```

The output lists deployment targets, never file or secret contents. Confirm the four selected CLI config paths are absent, while their `.zfunc` completion targets are present. `gh/config.yml` is owned; `gh/hosts.yml` is separate account state. Television's generated Nix search channel is owned, while its unmanaged main config remains an unselected observation. The historical 70-directory inventory is bookkeeping, not a list of additional config migration work.

After milestone 1 creates the public policy, validate its syntax and repeat this after changes:

```bash
cd /Users/shinzui/.config/dotfiles.nix
python3 -m json.tool config/bootstrap/config-policy.json >/dev/null
```

For milestone 2, work in the private repository's `secrets/` directory. The names below illustrate the stable record assigned in the private policy; use that actual record for each file. Add its real recipients and declaration before editing. The pinned editor requires a terminal-backed edit and explicit ciphertext verification:

```bash
cd /Users/shinzui/Keikaku/dotfiles-private.nix/secrets
nix develop /Users/shinzui/.config/dotfiles.nix -c agenix -e bootstrap-credential.age
test -s bootstrap-credential.age
nix develop /Users/shinzui/.config/dotfiles.nix -c agenix -d bootstrap-credential.age |
  cmp -s - "$credential_source"
```

Set `credential_source` to the selected original's exact private-audit path in this shell; do not put its content in arguments. Insert the original into the terminal editor locally. Both checks must exit zero. A zero editor exit without a non-empty decryptable file is failure. Keep the original until deployment checks complete. For new recipients, use `agenix -r` in both repositories' `secrets/` directories only after their actual public recipient rules are updated. Private commits must be published before the public lock references them. Then, from the public root, update only the companion:

```bash
cd /Users/shinzui/.config/dotfiles.nix
nix flake update dotfiles-private
```

Use focused staging for new source files so Git-based flake evaluation can see them; never stage all of `~/.config`. Inspect public/private diffs locally. After milestones 3 through 5 create the checker and tests, run:

```bash
cd /Users/shinzui/.config/dotfiles.nix
bash -n bin/check-bootstrap.sh bin/darwin-install.sh
python3 bin/test-bootstrap-checker.py
./bin/check-bootstrap.sh bootstrap-arm
nix eval --raw .#darwinConfigurations.bootstrap-arm.system.drvPath
nix build .#darwinConfigurations.bootstrap-arm.system --out-link result-bootstrap
nix eval --raw .#darwinConfigurations.SungkyungM1X.system.drvPath
./bin/build.sh
git diff --check
```

The test runner should print the following stable success summary, and exit nonzero on any violated scenario:

```text
PASS: policy coverage, safe paths, no link traversal, conflicts, prerequisites, live checks
```

The checker reports prerequisites independently; missing external access is a real failed preflight, not a reason to weaken the checks. Evaluation returns a derivation path, which need not be opened; builds exit zero and create result links. `git diff --check` prints nothing. Before changing bootstrap behavior, record its evaluated `determinateNix.distributedBuilds` and `determinateNix.buildMachines`, then verify the final bootstrap evaluates to `false` and an empty list while full-host builder definitions remain unchanged.

The `yujin` output is already implemented; explicitly validate it as well:

```bash
cd /Users/shinzui/.config/dotfiles.nix
./bin/check-bootstrap.sh yujin
nix eval --raw .#darwinConfigurations.yujin.system.drvPath
nix build .#darwinConfigurations.yujin.system --out-link result-yujin
```

After enrolling the target Mac's standalone Tailscale app, reapply the observed routing/DNS preferences with the supported installed CLI. This is an implementation/onboarding command for the target Mac, not a command to run during this audit:

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale set \
  --accept-dns=true --accept-routes=false --exit-node= \
  --exit-node-allow-lan-access=false --shields-up=false
```

Configure GUI start-at-login and on-demand choices through the supported app settings, using the private snapshot as the intended values. Query status and verify a new device identity privately; do not dump status JSON or the peer list into public logs. Check connectivity against an intended available peer, including the declared builder when it is running. No Tailscale command was used to change the source Mac during plan authoring.

Only on the target machine, after building its matching target and satisfying preflight, run the guide's activation commands and these live checks:

```bash
cd /Users/shinzui/.config/dotfiles.nix
./bin/check-bootstrap.sh yujin --live
command -v nvim mori rei tv
test -L "$HOME/.config/nvim/lua"
test -r "$HOME/.config/nhub/config.kdl"
test -r "$HOME/.config/ntn/config.kdl"
test -L "$HOME/.config/nihongo/config.kdl"
test -L "$HOME/.config/seihou/config.dhall"
./bin/test-treesitter.sh
just status-postgres
just status-tools
just status-victorialogs
just status-victoriatraces
just status-redpanda
```

The command lookup prints executable paths, link tests exit zero, and Treesitter reports PASS. Inspect actual service readiness according to `docs/local-services.md`, not only whether a launch agent exists. Test authenticated tools without printing tokens, private keys, account listings, or credential-bearing configuration. Compare Mori identity files privately between machines and require different IDs, with Sungkyung's value unchanged. Generated services can need an explicit database or workspace restore before they are useful; record that result independently.

Use Conventional Commits on the current branch. Every implementation commit carries `ExecPlan: docs/plans/6-prepare-a-clean-and-private-new-machine-configuration-bootstrap.md` in this repository. In the private repository, the trailer must instead use the canonical cross-repository plan URI `mori://shinzui/dotfiles.nix/plans/6-prepare-a-clean-and-private-new-machine-configuration-bootstrap`. Do not add an Intention trailer. Record one plan revision per implementing session with the bundled provenance script using the implementing agent's verified runtime model.


## Validation and Acceptance


Coverage is complete when all 70 observed top-level entries and the supplemental `~/.kube` and Tailscale Library audits have explicit actions, mixed directories have sufficient file-level decisions, public sources have been inspected for secrets and private account metadata, and desired unique preferences/skills/data have a recovery route. Public and private policies contain no credential values. Inspect only proposed public source files for private-key headers, token-shaped fields, and hardcoded sensitive endpoints; pattern checks are a supplement to local review, not a proof that arbitrary content is safe.

The ownership queries must prove existing declared targets are preserved and are not recaptured or offered as unmanaged choices. Tailscale live acceptance requires a newly enrolled distinct device, the reviewed DNS/routes/exit-node/startup preferences, and connectivity to an intended available tailnet endpoint. If the builder VM is offline, record that dependency separately rather than changing source-machine settings or starting infrastructure solely for this read-only audit. The two public CLI config files must be deployed as editable source links, and the two credential-bearing Notion CLI configs must be privately encrypted with readable `0600` installed destinations after agenix finishes; Nagare, gcloud, and kubectl must have verified usable recovery. Other unmanaged application settings are excluded unless explicitly selected. Validate recovered gcloud profiles and Kubernetes contexts privately, then demonstrate authenticated read-only access to the intended environments when reachable. Do not publish context names, endpoints, certificate/key data, or credential values.

The isolated checker tests must demonstrate that a symlink pointing outside the permitted source is never followed, an existing conflicting file is left byte-for-byte unchanged, unknown targets and path escapes fail before command execution, missing private access gives an actionable nonzero status, and dummy secret contents never appear in output. Preflight and live checks must differ appropriately. A runtime or approval fixture cannot become a portable source just because it sits beside a selected config file. Test coverage directly exercises migration risks rather than mirroring the implementation.

Evaluation and builds must preserve existing Sungkyung settings apart from the intended new preferences, identity-file ownership, and narrowly updated companion pin. Bootstrap must remain free of agenix and Home Manager activation and must no longer require its remote builder. No new credential plaintext is included in public or private tracked files or generated Nix text. Existing Home Manager generated targets have one owner; Television and Direnv integration remains functional. Physical source checks and builds do not by themselves validate credentials or live symlink behavior.

Full acceptance requires a new Mac bootstrapped through the documented sequence with only the chosen configuration payload, access to the required private inputs, selected preferences visible in tools, successful secret installation and authentication, and a new local Mori identity. Cache, backup, log, socket, machine trust, and opaque login-state trees are absent from the transfer payload. They may naturally be recreated when tools run. Existing sensitive originals remain recoverable until private deployment and actual consumer checks pass. Report any inaccessible provider or unavailable new machine explicitly and leave the corresponding live work unfinished rather than declaring seamless migration proven.


## Idempotence and Recovery


Metadata inventory, policy checks, syntax checks, isolated fixtures, evaluation, and non-activating builds can be repeated. Keep snapshots historical and place changed decisions in the policy. Checkers have no mutating mode. Never use `cp -R ~/.config`, broad `rsync`, blanket cleanup, force-overwrite file ownership, or broad Git restore/reset. New exclusions affect what is transferred, not deletion on the source machine. Compare backup preferences and preserve needed data before excluding them; actual source cleanup is outside this plan.

For symlink ownership changes, keep uniquely named protected local backups outside both repositories. Detect an existing `.backup` rather than assuming Home Manager can overwrite it. Mori is particularly order-sensitive: preserve Sungkyung's identity, replace the whole directory owner with selected-file ownership, restore the old identity locally, then run Mori. On the new Mac, leave identity absent until Mori creates one. Never edit a shared tracked identity to change one machine.

Keep prior ciphertext and recoverable identities until encryption comparison and installed consumer checks pass. If encryption fails, retry the verified terminal-backed workflow and leave the original untouched. If a provider requires authentication, complete that specific authentication rather than copying an old token database. If a private update is not yet published, do not update its public pin. If a build fails, retain the current activated generation and fix the relevant failure without upgrading every dependency. An activation failure requires the existing nix-darwin generation recovery procedure; record the known-good generation before any actual switch. Never activate a new host on the source Mac to test a build.


## Interfaces and Dependencies


`config/bootstrap/config-policy.json` has shape `{ "schema_version": 1, "audit_top_level": [".DS_Store", "anthropic"], "entries": [ { "path": "nihongo/config.kdl", "action": "public-file", "owner": "home/xdg-configs.nix", "reason": "Explicitly selected CLI preferences" } ] }`. The actual `audit_top_level` has all 70 observed names; the checker requires a one-to-one top-level policy match. Require each entry's four fields, unique paths, known actions, and no absolute or parent-escape paths. A directory-level decision does not override a more specific file decision; validate overlaps explicitly. Private mappings use the same version plus exact source/destination/secret-name/recovery-method fields as appropriate, never values. They live in the private companion and are not a public flake data dependency. External-home records for `~/.kube` and Tailscale Library preferences belong in these exact private mappings; do not invent corresponding paths under `~/.config` or bypass the public path-escape checks.

`bin/check-bootstrap.sh <target> [--live] [--home-dir <absolute-home-path>]` is executable, read-only, preserves argument boundaries, and exits `0` for all required checks passing, `1` for failed prerequisites/conflicts/live checks, and `2` for invalid usage or policy. Its normal home is `/Users/shinzui`; a synthetic path is for isolated file checks only and must not cause machine activation or an assertion that hardware deployment passed. Unknown target names fail before network or Nix commands. Use a small Python helper if JSON/policy checks become clearer there, with responsibility limited to safe validation. `bin/test-bootstrap-checker.py` exercises the externally observable checker contract without third-party test dependencies.

Reuse the locked Home Manager file module and `config.lib.file.mkOutOfStoreSymlink`, existing `xdg.configFile` declarations, agenix integration, Determinate module, shell tools, and Python standard library. Do not add a second symlink manager or plaintext template engine for secrets. Preserve `system.stateVersion = 4` and Home Manager state version `26.05`. Find dependency sources using Mori before relying on an API; verify registry releases and upstream tags if a later implementation proposes bounds, pins, or workarounds. No upgrade is required by this plan.

The private companion remains the owner of high-tier ciphertext and secret installation metadata. Cross-repository references use canonical Mori URIs and, where a file artifact cannot yet be named, the project URI plus an explicitly stated relative file path and pending artifact URI. Public host composition stays with the existing host plan; data recovery stays with service/workspace owners. This plan connects those prerequisites in one ordered bootstrap workflow.

Authoring note (2026-10-14 UTC): Created after auditing all 70 top-level configuration entries, selected preference structure, source declarations, private credential metadata, bootstrap helpers, the pending host plan, relevant locked dependency source, and the private two-tier ADR. Saved a metadata-only audit privately. No configuration activation, credential migration, source cleanup, or new-machine deployment has occurred.


Revision note (2026-10-14 UTC): Narrowed additions to the user's confirmed `nhub`, `ntn`, `nihongo`, `seihou`, `nagare`, `gcloud`, and `kubectl` keepers. Other unmanaged configs now default to exclusion, with existing declared apps presented separately for retirement review. Updated policy selection, private recovery, symlink work, live examples, and acceptance; added a metadata-only `~/.kube` audit without credential values. No app configuration was migrated or deleted.


Revision note (2026-10-14 UTC, ownership correction): Evaluated merged Home Manager deployment targets and traced all seven selected tools to their actual modules. Restricted additional capture to four unmanaged CLI config files and required private infrastructure state; removed declared-app retirement from scope. Recorded Nagare's separate profile installation and reproduction risk, Caddy service generation, and current implemented Yujin host/wrapper/local-ADR context. Configuration implementation remains unperformed.


Revision note (2026-10-14 UTC, Tailscale): Added the already-managed standalone app's missing onboarding coverage: fresh device enrollment, selected local preferences outside XDG config, macOS extension/VPN consent, and tailnet readiness for the existing remote builder. Saved an allowlisted private audit without node keys/account identities; updated progress, decisions, private recovery, bootstrap steps, and live acceptance. No client settings, login, device registration, or infrastructure were changed during this audit.


Revision note (2026-10-14 UTC, public/private placement): A content-level review found actual workspace-token literals in nhub/ntn KDL config files. Corrected their deployment to whole-file private agenix encryption; public editable additions are now only nihongo and seihou. Updated progress, decisions, private deployment, symlink work, live checks, and acceptance, and saved a private metadata-only finding without tokens or workspace identifiers. Neither credential-bearing file was copied, staged, or committed to either repository.


Revision note (2026-10-14 UTC, implementation): Implemented the selection policy, encrypted private recovery mappings, editable public sources, local Mori identity boundary, bootstrap checker and guide, builder isolation, and ADR. Recorded repository validation and kept live onboarding, differing backup review, and Nagare compatibility as explicit remaining work.


Revision note (2026-10-14 UTC, validation addendum): Verified the released Nagare `v0.2.2` operator build and explicit local-context probe; mapped Nagare symlink first hops privately; confirmed Determinate package metadata and signature without installing; tightened preflight to report private destination conflicts and validated the final companion pin with fresh non-activating builds. Mori's unique backup-only skill and physical new-machine checks remain open.
