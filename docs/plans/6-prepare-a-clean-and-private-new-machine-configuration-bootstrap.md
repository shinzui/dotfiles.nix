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
---

# Prepare a clean and private new-machine configuration bootstrap


This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture


Make a new Apple Silicon Mac usable from the public configuration checkout, an authorized private companion checkout, and explicitly recovered user data, without copying the old machine's entire `~/.config`. Preserve user-selected preferences and editable symlinks, install credentials required by retained tools through encrypted private declarations, and recreate login sessions, caches, local trust, and machine identity. The confirmed additional keepers are `nhub`, `ntn`, `nihongo`, `seihou`, `nagare`, `gcloud`, and `kubectl`; other unmanaged application configurations are excluded unless the user selects them. A successful result is a documented bootstrap whose preflight reports concrete missing prerequisites and whose live checks confirm settings, secret installation, and useful tools on the new machine.

This is creation of an implementation plan after a read-only audit. It does not activate either workstation, relocate credentials, delete backups, or claim the new machine has been tested. Repository preparation and actual deployment are separate acceptance results.


## Progress


- [ ] Classify all 70 configuration entries plus `~/.kube`, record the seven confirmed keepers, and introduce an explicit public configuration policy with private credential mappings.
- [ ] Recover required Nagare, gcloud, and kubectl settings/access and encrypt retained credentials privately, verifying deployment without exposing values.
- [ ] Capture the four confirmed CLI preference files, extend symlink patterns for selected keepers only, and separate Mori's per-machine identity.
- [ ] Provide a consistent Determinate bootstrap runbook and read-only prerequisite/live checker.
- [ ] Pass isolated checker scenarios, configuration evaluation and builds, and record fresh-machine acceptance separately.
- [ ] Distill durable decisions into ADRs and complete the implementation retrospective.


## Surprises & Discoveries


(No implementation discoveries yet. Initial audit evidence is recorded in Context and Orientation.)


## Decision Log


Decision (2026-10-14 UTC): Use an explicit selection of settings, never a recursive copy of `~/.config`. Every top-level entry must have a disposition, and mixed directories must have file-level exceptions. Cache exclusion must not discard unique preferences, skills, or user data.

Decision (2026-10-14 UTC): Keep sensitive values and detailed credential/account metadata in `mori://shinzui/dotfiles-private.nix`, physically checked out at `/Users/shinzui/Keikaku/dotfiles-private.nix`. Persistent credentials are encrypted; plaintext never becomes Git-tracked content in either repository. Recreate renewable login sessions. Respect the existing work-owned cluster-identity boundary: sensitive workstation onboarding metadata goes privately, while work-owned host authority remains with its owning project and recovery process.

Decision (2026-10-14 UTC): Follow `home/xdg-configs.nix`: use out-of-store symlinks, which link to editable checkout files rather than immutable generated content, for hand-maintained preferences. Use individual files inside mixed directories. Keep existing Home Manager generated settings and agenix secret links under their current managers. Mori's host identity must be local to the machine.

Decision (2026-10-14 UTC): Scope the initial onboarding to `arm64` macOS with login `shinzui` and public checkout `~/.config/dotfiles.nix`, matching the current configuration. Report other architectures or login names as unsupported prerequisites rather than promising path independence that the repository does not have. Coordinate with the existing host plan instead of implementing another host abstraction here.

Decision (2026-10-14 UTC): Preserve existing dependencies and compatibility state versions. Fix bootstrap ordering and documented prerequisites rather than adding dependency upgrades. The user selected Skip for Intention tracking.


Decision (2026-10-14 UTC, user clarification): Directory presence does not establish continued use. The user explicitly selected `nhub`, `ntn`, `nihongo`, `seihou`, `nagare`, `gcloud`, and `kubectl`. These are required keepers. Other unmanaged application settings default to exclusion until explicitly selected. Existing declared modules remain the baseline and are rebuilt by Nix; they are not additional migration candidates or an app-retirement task. Do not migrate credentials for an unselected app merely because they exist.


Decision (2026-10-14 UTC, ownership correction): Determine management at the exact file level from the merged Home Manager `home.file` and `xdg.configFile` declarations, including exported flake modules, rather than from directory names or package installation. Existing generated settings, tracked-source symlinks, agenix destinations, and declared service configuration are reconstructed by their managers. Only unmanaged settings selected by the user require capture. Preserve the declared application baseline; app retirement is outside this audit correction.


## Outcomes & Retrospective


(Implementation has not started. The user narrowed the migration selection to seven keepers; a supplemental metadata audit includes kubectl outside `~/.config`. Other unmanaged app settings are excluded by default, and existing managed settings are excluded from the additional migration selection. Fill this section with verified repository preparation and, separately, results observed on the new machine. Do not equate a successful build or synthetic home-directory check with physical onboarding.)


## Context and Orientation


The public repository is `/Users/shinzui/.config/dotfiles.nix`. `flake.nix` names its dependencies, `flake.lock` fixes their revisions, and `flake-modules/darwin-configurations.nix` combines system modules from `darwin/` and user modules from `home/`. Nix-darwin applies system settings; Home Manager applies user programs and files. A build assembles a candidate configuration; activation changes the running machine. The current full targets are `SungkyungM1X` and `yujin`; `bootstrap-arm` includes `darwin/bootstrap.nix` and Determinate integration but omits Home Manager and agenix secret installation.

`home/xdg-configs.nix` links whole `kazuha`, `mori`, and `rei` directories from `config/xdg/`, and individual `mina/config.kdl` and `okf/config.dhall` files. `home/neovim.nix` individually links `nvim/lua` and `nvim/after`; generated startup configuration remains separately managed. `home/external-configs.nix` deploys PostgreSQL client, pspg, Bird, and YAML lint settings. `home/claude.nix` links shared agent instructions outside XDG configuration; those declarations are already covered and must survive. XDG configuration means the conventional `~/.config` directory here.

Live Home Manager links often first point into `/nix/store` even when the final editable source is outside it. The audit used only `lstat`, directory walks that do not follow links, and first-hop `readlink`. It never traversed those targets or secret links. Maintain this restriction: never search, read, glob, or resolve paths inside `/nix/store`, and never search filesystem root. Source declarations establish intended ownership; metadata alone does not prove a final symlink chain works.

The audit on 2026-10-14 UTC covered 70 top-level entries in `~/.config`, excluding traversal of the public repository and `.git`/`node_modules` trees. Detailed metadata and credential findings are saved in `mori://shinzui/dotfiles-private.nix` with project-relative path `docs/audits/2026-10-14-config-bootstrap.json` (artifact-level URI pending). This contains paths, types, modes, counts, first-hop links, and disposition suggestions, never credential values. It is an observation snapshot, not an automatic copy list. The self-contained policy below is sufficient to implement public changes; consult the private snapshot locally for exact sensitive paths.

Ownership was rechecked by evaluating the actual `SungkyungM1X` Home Manager configuration, not only by scanning modules. The merged `xdg.configFile` has 20 target names, and merged `home.file` includes targets declared through `home/external-configs.nix`, the exported aliases/Wezterm/Starship modules, and shared user modules. Existing Atuin, Bat, Btop, Cachix, Git/GitHub CLI settings, Neovim, Starship, tmux, Wezterm, Bird, pgcli, pspg, and yamllint settings are already declared and need no migration capture. `home/xdg-configs.nix` already owns the Kazuha/Mori/Rei directory links and Mina/OKF file links. Agenix owns the already-declared secret destinations. `home/local-web-proxy.nix` generates Caddy's configuration and runs it as a declared service; its autosave is not a source config to capture.

Package management is separate from preference-file management. `home/notion-hub.nix` installs `nhub`, completions, its PostgreSQL connection environment, and subscription agent, but does not deploy `~/.config/nhub/config.kdl`. `home/notion-cli.nix`, `home/nihongo.nix`, and `home/seihou.nix` install their packages/completions but do not deploy their respective `config.kdl`/`config.dhall` files. Those four paths are regular unmanaged files and are absent from both merged deployment target sets. `home/default.nix` already installs gcloud with the GKE auth plugin and kubectl; profiles and `~/.kube/config` are absent from deployment declarations. `darwin/gcp-nix-builder.nix` depends on the user's authenticated gcloud environment, so recovering access is an existing infrastructure prerequisite, not adding another SDK install.

Nagare and nagarectl are available through a separate active `nix profile` element named `nagare`, not through this dotfiles package list. That element reports original URL `github:shinzui/nagare/v0.2.2`, resolved revision `248e5f95803c0110b5890b611c7bbd24468f8d71`, and package version `0.2.2`. Upstream release metadata currently reports `v0.6.3`, and the current `v0.2.2` tag does not resolve to the installed element's revision. The registered checkout does not provide a root `flake.nix` at that old revision. Therefore do not assume reinstalling the old tag or adopting the newest same-named package reproduces this installation. Establish a compatible reproducible Nagare install from its owning project during bootstrap preparation. A read-only `nagare --help` invocation also failed a missing-context lookup while `nagarectl --help` succeeded; verify wrapper environment/context selection as well as file recovery. No command deployment, authentication, or infrastructure mutation was performed.

Confirmed preference additions are `nhub/config.kdl`, `ntn/config.kdl`, `nihongo/config.kdl`, and `seihou/config.dhall`. Nagare, gcloud, and kubectl are also explicitly required. Other unmanaged candidates are observations, not approved additions. Selecting a config file does not approve an entire agent installation tree.

Historically observed unmanaged preference candidates are `ghostty/config` and its four theme files, `gh-dash/config.yml`, `gitui/theme.ron`, `goose/config.yaml`, `cmux/cmux.json`, `karabiner/karabiner.json`, `zed/settings.json`, `worktrunk/config.toml`, `direnv/direnv.toml`, `television/config.toml` and selected `television/cable/*.toml`, plus `nhub/config.kdl`, `ntn/config.kdl`, `nihongo/config.kdl`, and `seihou/config.dhall`. Preserve selected source skills under `mina/agents`, `ntn/agents`, `seihou/agents`, and `testkit/agents` only after comparing them with their producing repositories or installation recipes. An absence of a credential-shaped field is not proof that a candidate is public-safe. `cmux/cmux.json` has JSON comments and a `socketPassword` field; that field was empty during audit. Do not treat the marker as evidence of a stored password or parse this file as strict JSON without supporting comments.

There are genuine mixed-file pitfalls. Worktrunk's active config contains command-approval records and absolute paths as well as preferences; its `.new` file is a separate comparison candidate, not the active source. Television already owns the generated `cable/nix-search-tv.toml` through `home/nix-search-tv.nix`; do not link the entire `television` directory over it. Direnv already manages integration files through `home/default.nix`; its additional `load_dotenv` preference is unselected. If selected later, add it through the existing module or one file, not a second directory owner. Karabiner backups and hardware profile settings must be separated from desired remappings, and compared with the existing Caps Lock remapping in `darwin/default.nix`.

Sensitive or authentication-bearing families include `gcloud`, `argocd`, parts of `nagare`, the standalone signer directory, and potentially app-specific account settings. A standalone JSON signer has a private-key field. Existing `sops` and other managed secret links should be recreated by agenix, not copied after decryption. `gh/hosts.yml` currently contains account metadata without an inline token; its live credential may be elsewhere, so copying this file does not establish GitHub authentication. The private report contains the exact persistent credential candidates. Use private declarations for required persistent files and reauthenticate renewable user sessions.

The user explicitly added kubectl to the scope. Its main config is outside `~/.config`, at `~/.kube/config`, observed as a regular file with mode `0600`. A redacted CLI parse counted seven contexts, five clusters, and five user records, with embedded certificate/private-key authentication and executable authentication commands. Preserve needed contexts and authentication through private recovery, never public plaintext. Recreate `~/.kube/cache`, `~/.kube/http-cache`, and the GKE auth plugin cache. A supplemental metadata-only audit is in `mori://shinzui/dotfiles-private.nix` with project-relative path `docs/audits/2026-10-14-kubectl-bootstrap.json` (artifact-level URI pending). Gcloud has three named profiles to recover privately; Nagare contains context settings, kubeconfigs, operator settings, repository-owned links, and work-owned identities requiring their existing recovery boundary.

Most measured bytes are generated data: the regular files under `gcloud` total roughly 296 MB, and under `raycast` roughly 180 MB, excluding symlink targets and skipped `node_modules`. Do not claim all those bytes are disposable. Exclude token databases, logs, SDK caches, generated extensions, compiled caches, sockets, update-notifier state, editor embeddings, and stale backups from the bootstrap payload. Preserve unique prompts, conversations, custom extensions, and meaningful differences through an explicit data export when needed; they are user data, not portable application settings.

Other observed entries needing explicit disposition are `.DS_Store`, `anthropic`, `asciinema`, `btop` logs, `cabal`, `caddy` autosave, `cai`, `configstore`, `ghc`, `helix`, `hunk` state, `iterm2`, `k3d`, `kitty`, `longbridge`, `mole`, `mori-rei-app`, `mori.bak`, `nagare`, `nix`, `notion-cli`, `op`, `raycast`, `rei.bak`, `reiko`, `silicon`, `simple-update-notifier`, `testkit`, `yarn`, and `zed` data. Empty directories require no transfer. `mole` has a hand-edited-looking cleanup list: review it before exclusion. `caddy/autosave.json` can contain operational configuration: preserve its intentional source privately when required, regenerate autosave from the declared proxy config. `nix/registry.json` and `nix.conf.backup` should not silently override the declared Nix settings. Yarn's global manifests and link registrations require comparison with declared packages; do not copy global installation state wholesale.

`config/xdg/mori/host-id` is Git-tracked and included in the whole-directory symlink. The installed `mori --version` reports `v6.0.0.0 (9b6d0e1)`, matching the public lock. Source at that revision in `mori://shinzui/mori/packages/mori-core`, project-relative file `mori-core/src/Mori/Host/Identity.hs` (file-level URI pending), creates a local identity when missing and supports `MORI_HOST_ID_FILE`. Copying the tracked identity would make two machines appear identical to Mori. Preserve Sungkyung's existing identity locally before excluding it from shared sources; let the new machine mint its own.

The host work is now implemented: `flake-modules/darwin-configurations.nix` composes `SungkyungM1X` and `yujin` from shared modules plus sibling `hosts/sungkyung/` and `hosts/yujin/` modules. `bin/build.sh` accepts an explicit target and defaults to Sungkyung; `bin/darwin-rebuild.sh` requires a target and the Sungkyung compatibility wrapper delegates to it. Keep those contracts. `bin/darwin-install.sh` still invokes the upstream installer while active modules use Determinate. Minimal bootstrap still declares a remote builder without its decryptable identity; disable remote builders for that target only. `bootstrap-repos` requires a reachable populated Mori registry and cannot seed it. Existing declared service and workspace data recovery remains separate from configuration capture.

The relevant local decision is `docs/adr/1-shared-workstation-modules-and-host-overrides.md` ([local link](../adr/1-shared-workstation-modules-and-host-overrides.md)), now present following host implementation. It preserves shared `darwin/` and `home/` configuration, independent host overrides, explicit build/switch targets, and separate live onboarding acceptance. No profiled ADR bundle is declared by `mori show --full`. The relevant private decision was read at `mori://shinzui/dotfiles-private.nix` with project-relative path `docs/adr/1-two-tier-agenix-secrets.md` (artifact-level URI pending; a registry concept search returned no handle). Its rule keeps account access, chargeable services, publishing privileges, and hard-to-rotate credentials private; fetches private inputs through authorized SSH; retains work-owned cluster identities under their owner; and verifies installation after the Darwin agenix launch daemon runs. Both public and private recipient rules must be rekeyed when a real new identity is added. A known pinned agenix editor behavior can return success without ciphertext, so require non-empty ciphertext and a decrypt-to-comparison check.

Dependency discovery used Mori first; Home Manager, nix-darwin, and agenix were not registered. Relevant upstream files were obtained into a specific temporary directory at the root inputs' actual locked revisions, without searching the store. Home Manager source verifies `mkOutOfStoreSymlink`, collision checks, and file ownership for Television and Direnv. This plan introduces no version bounds, pins, or compatibility workarounds. The current Determinate installation and nix-darwin integration guidance was also checked against the provider's official documentation.


## Plan of Work


### Milestone 1: Turn the snapshot into an explicit migration policy


Create `config/bootstrap/config-policy.json` as a public, versioned selection of non-sensitive paths and actions, and `docs/config-bootstrap-audit.md` as its readable rationale. Each record has `path`, `action`, `owner`, and `reason`. Supported actions are `managed`, `public-file`, `public-directory`, `private`, `reauthenticate`, `recreate`, `data-export`, and `exclude`. Paths are relative to the source configuration root; reject absolute paths and parent-directory escapes. Public sensitive-family records identify only a broad family; exact credential mapping, account identifiers, and exclusions inside that family go in the private companion's project-relative `config/bootstrap/private-policy.json` (artifact-level URI pending). Store no credential values in either manifest.

Account for all 70 snapshot entries using the groups above, then inspect mixed directories at file level. Keep the raw private snapshot as historical evidence and put later decisions in the policy, rather than rewriting the snapshot. First evaluate merged `home.file` and `xdg.configFile` targets, including exported modules and ordinary Home Manager program modules. Mark exact already-owned targets `managed`; never add them to the user selection list or recapture their generated content. A package being installed does not establish ownership of its application preference files. Retain managers instead of duplicating sources. Select the four confirmed CLI config files and required Nagare/gcloud/kubectl recovery records. Assign other unmanaged candidates `exclude` unless the user explicitly adds them; local inspection alone cannot approve an unused app. Omit empty directories and generated state. Compare backups with active settings without printing contents; carry forward meaningful unique preferences before excluding backups. Explicitly classify app data and local source skills, with a recovery method for each desired export. Keep unrelated package/application retirement outside this migration work; saving a theme does not justify enabling an old disabled program such as GitUI.

Acceptance is a coverage check in `bin/test-bootstrap-checker.py`: every snapshot top-level name has a policy action, and every selected source path exists as a regular file or approved source directory without following symlinks. There is no unresolved disposition. The public document reports the policy and exceptions without revealing private account metadata.

### Milestone 2: Manage required sensitive workstation files privately


In `mori://shinzui/dotfiles-private.nix`, extend project-relative `secrets/secrets.nix` and `darwin/secrets.nix`, following its existing naming, recipients, paths, owners, and permissions. The artifact-level URIs for those files are pending. Select persistent service-account or signer material only when required by retained tools, assign stable secret names in the private policy, and install it at each consumer's existing destination with mode `0600`. Keep parent directories suitably restricted. Do not commit plaintext private keys or build plaintext into a Nix derivation. An ordinary out-of-store symlink into a private Git checkout is appropriate only for non-secret private settings; private source control alone is not encryption.

Recover the three gcloud named profiles and intended active selection privately. Reauthenticate gcloud user sessions and application-default credentials when needed by retained consumers; encrypt necessary persistent service-account material privately. Omit SDK caches, logs, and token databases. For Nagare, privately map required contexts, kubeconfigs, operator settings, repository-owned links, and recovery prerequisites; clone the owning repositories before recreating those links. Restore an active context only after its destination exists. For kubectl, recover required contexts and authentication mechanisms from `~/.kube/config` and Nagare kubeconfigs. Embedded client keys/certificates are private secret material; retain required authentication executables, including the already-declared GKE plugin. Recreate discovery, HTTP, and auth caches. Reauthenticate GitHub or other applications only as required by the retained baseline; Argo CD and the standalone signer are not selected additions. Preserve work-owned cluster authority in the owning recovery workflow and document its prerequisite privately; do not collect cluster host keys into the personal companion merely because they appear under `~/.config`. For each required sensitive record, its outcome must be encrypted deployment, successful fresh authentication, or a verified owning-project recovery handoff, rather than an ambiguous omission.

Preserve recoverable originals until activated copies match byte-for-byte and their consumers work. For actual new recipients, use the real public key, update both tiers, and re-encrypt ciphertext; never invent identities. Publish private changes before updating only `dotfiles-private` in the public lock. Do not rotate unrelated credentials or rewrite public history as part of this task. Acceptance is non-empty ciphertext, decrypt-to-`cmp` success, private repository diffs containing ciphertext/declarations only, and mode/readability/consumer checks after agenix finishes. A successful switch alone does not pass this milestone's live acceptance.

### Milestone 3: Deploy portable preferences with appropriate symlinks


The seven selected tools do not require seven new package installations. Four already-installed personal CLIs need only their missing preference-file declarations; gcloud and kubectl need private profile/context/authentication recovery; Nagare additionally needs reproduction of its separate profile installation. Confirm exact destination ownership before adding any new declaration.

Copy the reviewed `nhub/config.kdl`, `ntn/config.kdl`, `nihongo/config.kdl`, and `seihou/config.dhall` files into matching `config/xdg/<app>/` paths and extend `trackedConfigFiles` in `home/xdg-configs.nix`. Link each file individually, leaving runtime state and installation records outside shared sources. Nagare and gcloud use the private settings and secret/recovery mappings from milestone 2; kubectl's private destination is `~/.kube/config`, outside XDG configuration. Promote only sanitized public settings. Other unmanaged app settings are excluded until explicitly selected.

Preserve the existing Television-generated Nix search channel and Direnv integration; their unmanaged settings/custom channels and additional local preferences are unselected. If the user adds Worktrunk later, omit embedded approvals and use active preferences rather than blindly preferring `.new`. If Karabiner is selected, compare mappings with the declared Caps Lock behavior and omit nonportable hardware matching. Only separately selected source skills are linked or regenerated from a recorded owning project/recipe. An app config selection does not approve its entire agent installation tree.

Change Mori from a shared whole-directory link to individually selected config/skill sources, leaving `~/.config/mori/host-id` writable and local. Before that change on Sungkyung, back up its identity from `config/xdg/mori/host-id` in the editable source checkout to a private local recovery location; do not follow the live store link to make that backup. After unlinking the directory and before running Mori, restore that identity at the local destination without altering its value. Remove `config/xdg/mori/host-id` from shared tracked source and prevent reintroduction. New machines start without that file. Source skills below `config/xdg/mori/agents` may still be linked through selected safe files or an audited source-only subtree. Existing `kazuha`/`rei` directory links remain only if their content audit finds no per-machine or writable state requiring separation.

Acceptance is successful Home Manager evaluation with exactly one owner per destination, correct source coverage, and no deployed backups, logs, approval records, or shared host identity. On an activated machine, edits to selected checkout settings are visible without rebuilding; verify this through a harmless temporary preference change and restore it. Mori's old identity remains stable on Sungkyung and differs from the identity minted on the new machine.

### Milestone 4: Make bootstrap prerequisites and ordering executable


Create `docs/new-machine-bootstrap.md` and `bin/check-bootstrap.sh`; link the guide from `README.md` and reconcile `docs/secrets.md`. Replace the obsolete `bin/darwin-install.sh` with a helper for the repository's selected Determinate installation path. It must detect an existing Nix installation and avoid installing a second daemon. The current official macOS package download is `https://install.determinate.systems/determinate-pkg/stable/Universal`, verified through the provider's [workstation installation guide](https://docs.determinate.systems/getting-started/individuals/). Have the helper report an existing installation; otherwise download that package to a unique temporary path with `curl -fL` and invoke `/usr/sbin/installer -pkg <downloaded-package> -target /` through sudo when the owner explicitly runs the install helper on the new machine. Record the package version tested during implementation, detect an existing non-Determinate installation as a migration prerequisite, and recheck the provider's current instructions before executing installation. The existing module follows the provider's [nix-darwin integration contract](https://docs.determinate.systems/guides/nix-darwin/), so retain that distribution and module ownership.

The guide's order is developer tools and Determinate Nix, an authorized SSH identity, public checkout at the expected path, private-input access, bootstrap build/activation when needed, private secret access or recipient enrollment, full host build/activation, secret installation checks, authentication, and declared service/data restoration. Private fonts and the companion are root flake inputs even when their modules are excluded; do not advertise anonymous bootstrap without an isolated proof. Require SSH access before evaluating this flake. Keep remote builds disabled for the minimal bootstrap through `flake-modules/darwin-configurations.nix` so its shared bootstrap settings do not need a decrypted builder key; preserve full-host remote-builder behavior.

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

Only on the target machine, after building its matching target and satisfying preflight, run the guide's activation commands and these live checks:

```bash
cd /Users/shinzui/.config/dotfiles.nix
./bin/check-bootstrap.sh yujin --live
command -v nvim mori rei tv
test -L "$HOME/.config/nvim/lua"
test -L "$HOME/.config/nhub/config.kdl"
test -L "$HOME/.config/ntn/config.kdl"
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


Coverage is complete when all 70 observed top-level entries and the supplemental `~/.kube` audit have explicit actions, mixed directories have sufficient file-level decisions, public sources have been inspected for secrets and private account metadata, and desired unique preferences/skills/data have a recovery route. Public and private policies contain no credential values. Inspect only proposed public source files for private-key headers, token-shaped fields, and hardcoded sensitive endpoints; pattern checks are a supplement to local review, not a proof that arbitrary content is safe.

The ownership queries must prove existing declared targets are preserved and are not recaptured or offered as unmanaged choices. The four confirmed CLI config files must be deployed; Nagare, gcloud, and kubectl must have verified usable recovery. Other unmanaged application settings are excluded unless explicitly selected. Validate recovered gcloud profiles and Kubernetes contexts privately, then demonstrate authenticated read-only access to the intended environments when reachable. Do not publish context names, endpoints, certificate/key data, or credential values.

The isolated checker tests must demonstrate that a symlink pointing outside the permitted source is never followed, an existing conflicting file is left byte-for-byte unchanged, unknown targets and path escapes fail before command execution, missing private access gives an actionable nonzero status, and dummy secret contents never appear in output. Preflight and live checks must differ appropriately. A runtime or approval fixture cannot become a portable source just because it sits beside a selected config file. Test coverage directly exercises migration risks rather than mirroring the implementation.

Evaluation and builds must preserve existing Sungkyung settings apart from the intended new preferences, identity-file ownership, and narrowly updated companion pin. Bootstrap must remain free of agenix and Home Manager activation and must no longer require its remote builder. No new credential plaintext is included in public or private tracked files or generated Nix text. Existing Home Manager generated targets have one owner; Television and Direnv integration remains functional. Physical source checks and builds do not by themselves validate credentials or live symlink behavior.

Full acceptance requires a new Mac bootstrapped through the documented sequence with only the chosen configuration payload, access to the required private inputs, selected preferences visible in tools, successful secret installation and authentication, and a new local Mori identity. Cache, backup, log, socket, machine trust, and opaque login-state trees are absent from the transfer payload. They may naturally be recreated when tools run. Existing sensitive originals remain recoverable until private deployment and actual consumer checks pass. Report any inaccessible provider or unavailable new machine explicitly and leave the corresponding live work unfinished rather than declaring seamless migration proven.


## Idempotence and Recovery


Metadata inventory, policy checks, syntax checks, isolated fixtures, evaluation, and non-activating builds can be repeated. Keep snapshots historical and place changed decisions in the policy. Checkers have no mutating mode. Never use `cp -R ~/.config`, broad `rsync`, blanket cleanup, force-overwrite file ownership, or broad Git restore/reset. New exclusions affect what is transferred, not deletion on the source machine. Compare backup preferences and preserve needed data before excluding them; actual source cleanup is outside this plan.

For symlink ownership changes, keep uniquely named protected local backups outside both repositories. Detect an existing `.backup` rather than assuming Home Manager can overwrite it. Mori is particularly order-sensitive: preserve Sungkyung's identity, replace the whole directory owner with selected-file ownership, restore the old identity locally, then run Mori. On the new Mac, leave identity absent until Mori creates one. Never edit a shared tracked identity to change one machine.

Keep prior ciphertext and recoverable identities until encryption comparison and installed consumer checks pass. If encryption fails, retry the verified terminal-backed workflow and leave the original untouched. If a provider requires authentication, complete that specific authentication rather than copying an old token database. If a private update is not yet published, do not update its public pin. If a build fails, retain the current activated generation and fix the relevant failure without upgrading every dependency. An activation failure requires the existing nix-darwin generation recovery procedure; record the known-good generation before any actual switch. Never activate a new host on the source Mac to test a build.


## Interfaces and Dependencies


`config/bootstrap/config-policy.json` has shape `{ "schema_version": 1, "entries": [ { "path": "nhub/config.kdl", "action": "public-file", "owner": "home/xdg-configs.nix", "reason": "Explicitly selected CLI preferences" } ] }`. Require each entry's four fields, unique paths, known actions, and no absolute or parent-escape paths. A directory-level decision does not override a more specific file decision; validate overlaps explicitly. Private mappings use the same version plus exact source/destination/secret-name/recovery-method fields as appropriate, never values. They live in the private companion and are not a public flake data dependency.

`bin/check-bootstrap.sh <target> [--live] [--home-dir <absolute-home-path>]` is executable, read-only, preserves argument boundaries, and exits `0` for all required checks passing, `1` for failed prerequisites/conflicts/live checks, and `2` for invalid usage or policy. Its normal home is `/Users/shinzui`; a synthetic path is for isolated file checks only and must not cause machine activation or an assertion that hardware deployment passed. Unknown target names fail before network or Nix commands. Use a small Python helper if JSON/policy checks become clearer there, with responsibility limited to safe validation. `bin/test-bootstrap-checker.py` exercises the externally observable checker contract without third-party test dependencies.

Reuse the locked Home Manager file module and `config.lib.file.mkOutOfStoreSymlink`, existing `xdg.configFile` declarations, agenix integration, Determinate module, shell tools, and Python standard library. Do not add a second symlink manager or plaintext template engine for secrets. Preserve `system.stateVersion = 4` and Home Manager state version `26.05`. Find dependency sources using Mori before relying on an API; verify registry releases and upstream tags if a later implementation proposes bounds, pins, or workarounds. No upgrade is required by this plan.

The private companion remains the owner of high-tier ciphertext and secret installation metadata. Cross-repository references use canonical Mori URIs and, where a file artifact cannot yet be named, the project URI plus an explicitly stated relative file path and pending artifact URI. Public host composition stays with the existing host plan; data recovery stays with service/workspace owners. This plan connects those prerequisites in one ordered bootstrap workflow.

Authoring note (2026-10-14 UTC): Created after auditing all 70 top-level configuration entries, selected preference structure, source declarations, private credential metadata, bootstrap helpers, the pending host plan, relevant locked dependency source, and the private two-tier ADR. Saved a metadata-only audit privately. No configuration activation, credential migration, source cleanup, or new-machine deployment has occurred.


Revision note (2026-10-14 UTC): Narrowed additions to the user's confirmed `nhub`, `ntn`, `nihongo`, `seihou`, `nagare`, `gcloud`, and `kubectl` keepers. Other unmanaged configs now default to exclusion, with existing declared apps presented separately for retirement review. Updated policy selection, private recovery, symlink work, live examples, and acceptance; added a metadata-only `~/.kube` audit without credential values. No app configuration was migrated or deleted.


Revision note (2026-10-14 UTC, ownership correction): Evaluated merged Home Manager deployment targets and traced all seven selected tools to their actual modules. Restricted additional capture to four unmanaged CLI config files and required private infrastructure state; removed declared-app retirement from scope. Recorded Nagare's separate profile installation and reproduction risk, Caddy service generation, and current implemented Yujin host/wrapper/local-ADR context. Configuration implementation remains unperformed.
