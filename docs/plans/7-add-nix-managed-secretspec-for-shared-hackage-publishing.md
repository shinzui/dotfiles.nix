---
id: 7
slug: add-nix-managed-secretspec-for-shared-hackage-publishing
title: "Add Nix-managed SecretSpec for shared Hackage publishing"
kind: exec-plan
created_at: 2026-10-16T10:55:00Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-16T10:55:00Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-16T10:58:44Z
      mode: "other"
      note: "Flesh out creation plan after validating SecretSpec, Cabal release support, Nix packaging, and local ADR context"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-16T11:11:46Z
      mode: "update"
      note: "Defer implementation until an unmodified stable Cabal release supports token-command; remove the backport approach"
---


# Add Nix-managed SecretSpec for shared Hackage publishing

This ExecPlan is a living document. Keep Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective current during implementation. Follow `agents/skills/exec-plan/PLANS.md`, `agents/skills/exec-plan/ADR.md`, and `agents/skills/exec-plan/PROVENANCE.md`. Every implementation commit must use Conventional Commits and include `ExecPlan: docs/plans/7-add-nix-managed-secretspec-for-shared-hackage-publishing.md`. Work on the current branch. No Intention ID was supplied during creation.


## Purpose / Big Picture


Install the latest stable SecretSpec through this repository's pinned Nix package collection and let a supported stable Cabal retrieve a Hackage publishing token from macOS Keychain. SecretSpec is a command-line secret manager; Keychain is macOS's credential store. A shared manifest declares the token's name and requirements without containing its value. One global Cabal setting will enable publishing from any Haskell repository without copying credentials into those repositories.

Implementation is deferred at the user's request until a stable Cabal release provides `token-command` and a suitable unmodified release package is available through Nix. Do not backport, patch Cabal, install a development snapshot, or substitute a credential-passing workaround. This document preserves the intended implementation for that future release; it does not authorize starting installation or configuration now.

After the release gate passes and implementation is resumed, `cabal upload --publish dist-newstyle/sdist/<package>-<version>.tar.gz` will obtain its token by running `hackage-token`. Prove this against a local test server with a dummy token before enrolling the real credential. Actual Hackage publication remains a separate release action.


## Progress


- [ ] Waiting: verify a stable Cabal release includes token-command and its unmodified Nix package is available; resume implementation only when the user returns to this work.
- [ ] Milestone 1: install the verified stable SecretSpec and Cabal packages through Nix.
- [ ] Milestone 2: install the shared manifest and token helper through Home Manager.
- [ ] Milestone 3: verify the integration offline, document enrollment and configuration, and build both full hosts.
- [ ] Milestone 4: activate on the intended Mac, enroll the token locally, verify retrieval, and distill durable decisions into an ADR.


## Surprises & Discoveries


Research found that the latest released Cabal checked on 2026-10-16, 3.18.2.0, lacks `token-command`, although upstream development source contains it. Development version 3.19.0.0 is not a forthcoming stable version: Cabal uses odd second version components for development and even components for stable releases. The next stable series is expected to be 3.20, but inclusion and timing must be checked against the actual release. No release date was found. The user chose to wait rather than maintain a Cabal backport.

No implementation, activation, or credential enrollment has occurred.


## Decision Log


Decision (2026-10-16): use the existing `nixpkgs-unstable` input for SecretSpec, with no Homebrew installation and no new SecretSpec flake input. Its locked revision already packages 0.21.1, matching the stable upstream and non-yanked crates.io releases checked during creation. Revalidate when implementation resumes.

Decision (2026-10-16, supersedes the initial backport proposal): wait for a stable upstream Cabal release supporting `token-command`, then use its unmodified Nix package. The user explicitly rejected hacking or backporting Cabal. Do not create a custom Cabal derivation, apply local Cabal patches, use a development build, or provide an interim token-passing wrapper. Defer the whole implementation until the user resumes it after release availability. Do not schedule automatic monitoring or installation.

Decision (2026-10-16): keep publishing configuration in a shared Home Manager module, but retain the existing writable global Cabal configuration. Document a one-time targeted edit to the path reported by `cabal path --config-file`. Do not adopt the entire configuration into Nix or make activation access Keychain.

Decision (2026-10-16): explicitly select the manifest, `keyring` provider, and `default` profile in the helper and enrollment commands. This makes publication independent of the caller's directory and unrelated global SecretSpec defaults. The valid `config global init` command remains optional and is not needed for this integration.

Decision (2026-10-16): use a regular TOML table for the secret declaration. SecretSpec 0.21.1 accepts the supplied multiline inline table, but a regular table also works with TOML 1.0 tools.

Decision (2026-10-16): validate with dummy credentials and a loopback HTTP server; real token entry occurs only in the user's interactive terminal. Shared configuration does not transfer Keychain entries between Macs. No real package publication is an automated acceptance step.


## Outcomes & Retrospective


The researched plan is deferred pending a supported stable Cabal release and the user's return to this work. The initial custom-backport approach has been removed from the implementation, commands, interfaces, and acceptance criteria. Only this plan has changed; no package installation, configuration, activation, or credential enrollment was performed.

When implementation eventually completes, record the released Cabal and SecretSpec versions, Nix revision, offline validation, and per-machine live acceptance. Distill lasting workstation decisions into an ADR then; waiting for an external release does not itself change the repository's implemented architecture.


## Context and Orientation


This is a macOS workstation configuration repository. Nix evaluates package descriptions and writes immutable build results; its lock file fixes input revisions. Home Manager installs user packages and configuration files. `flake.nix` declares inputs, and `flake.lock` pins `nixpkgs-unstable` to `8edc0c72e3a38faf5434e40d1f19431125fe4b30` at plan creation. The package definition at that revision, `pkgs/by-name/se/secretspec/package.nix` in `mori://NixOS/nixpkgs` (artifact URI pending), selects SecretSpec 0.21.1. It already supplies the crate and Cargo dependency hashes. Use the upstream package rather than duplicating its derivation.

Research on 2026-10-16 checked SecretSpec upstream stable tag `v0.21.1`, commit `5a8927d2b800c604fee72970ffbd137c57820fd5`, and the non-yanked crates.io index entry for 0.21.1. Running the locked Nix package reported `secretspec 0.21.1`; the existing profile reported 0.21.0. These are historical observations to refresh when work resumes. Newer nightly versions do not satisfy the stable-release requirement.

`home/default.nix` imports shared user modules and installs `(lib.lowPrio haskellPackages.cabal-install)`. Both full hosts, `SungkyungM1X` and `yujin`, import that module through `flake-modules/darwin-configurations.nix`; `bootstrap-arm` has no Home Manager. `flake-modules/packages.nix` exposes individually buildable packages. Add the shared publishing module in `home/`, retaining ordinary upstream Cabal packaging and the shared Haskell toolchain. No custom Cabal overlay or patch is part of this plan.

`home/xdg-configs.nix` owns neither Cabal nor SecretSpec's global config. The `cabal` entry in `config/bootstrap/config-policy.json` is excluded from transfer. Keep that exclusion: the generated publishing manifest can be shared independently without transferring a live Cabal configuration.

Cabal is the Haskell package tool; Hackage is the registry. During research `cabal --numeric-version` reported 3.16.1.0, `cabal upload --help` lacked `token-command`, and `cabal path --config-file` reported `/Users/shinzui/.cabal/config`. Cabal honors `--config-file`, `CABAL_CONFIG`, and `CABAL_DIR`, and can retain the legacy `~/.cabal` directory. Discover the active path rather than assuming `~/.config/cabal/config`. Project shells can select different executable versions; check the actual publishing shell.

Dependency discovery used `mori registry list`, `mori registry search secretspec`, `mori registry search nixpkgs`, `mori registry show haskell/cabal --full`, and `mori registry docs haskell/cabal`. SecretSpec and nixpkgs were absent from the local corpus, so official upstream sources were inspected. Cabal source is registered as `mori://haskell/cabal/repos/cabal`; resolve with `mori path` before reading it. Its corpus project wraps upstream sources in project-relative `cabal/`. Source-file artifact URIs are pending: accompany any external relative source path with its canonical project or repository URI.

At creation, authoritative Hackage preferred versions and release tags established Cabal 3.18.2.0 as the latest release. Its `cabal-install/src/Distribution/Client/Setup.hs` lacks `token-command`, while development source declares 3.19.0.0 and includes the feature. Stable Cabal versions use even second components; 3.19 is the development line toward the next stable series. Do not infer a scheduled date or feature inclusion from the development number. Confirm actual released source, executable help, and behavior before resuming this plan.

SecretSpec 0.21.1 confirms `SECRETSPEC_FILE`, equivalent `--file`, and explicit provider/profile options for `set`, `get`, and `check`. `schema --profile default` parses the manifest without secret access. The supplied manifest parsed under both installed SecretSpec 0.21.0 and the locked Nix 0.21.1, including its multiline inline table. Use a regular table for broader TOML compatibility.

The default Keychain service contains project, profile, and key: `secretspec/haskell-publishing/default/HACKAGE_TOKEN`. Keep these stable. SecretSpec 0.21.1 writes exact secret bytes without an added newline when stdout is a pipe. The helper's stdout must contain only those bytes; errors belong on stderr with a nonzero exit. macOS authorizes the executable's code identity, and a new Nix build can require renewed approval. Lock, sleep, and login behavior depends on local Keychain settings. Do not promise unattended access.

Relevant local ADRs are [shared workstation modules and host overrides](../adr/1-shared-workstation-modules-and-host-overrides.md), which places shared user settings in `home/`, and [selective and private workstation bootstrap](../adr/2-selective-private-workstation-bootstrap.md), which separates portable preferences from credentials and local identity. Neither specifies Hackage or SecretSpec. No Hackage-specific ADR exists. The current `mori.dhall` has no profiled ADR bundle; preserve the plain Markdown ADR convention during future implementation.


## Plan of Work


### Milestone 1: Select and install supported stable packages


Do not start this milestone while the release gate is unmet. When the user resumes the work, locate Cabal source with Mori, check authoritative Hackage preferred versions and upstream release tags, then verify that a stable release includes `token-command`. The Nix package must contain that unmodified upstream feature. A development snapshot or a version number alone does not pass this gate.

Use the standard `haskellPackages.cabal-install` package already selected by `home/default.nix` when it is suitable. If necessary, update only `nixpkgs-unstable` after confirming its upstream package includes the released capability. Preserve the shared Haskell toolchain inputs. If nixpkgs still lacks a suitable release package, keep waiting; do not create a Cabal derivation or patch as a workaround.

Export `secretspec` and the selected ordinary `cabal-install` as individually buildable outputs from `flake-modules/packages.nix`. Continue to install one Cabal executable in the Home Manager profile. Add SecretSpec through the module in Milestone 2. Do not rename Cabal to a locally patched package or introduce a competing copy. Reverify the latest stable SecretSpec release against the registry and upstream tags when choosing its package.

Acceptance is that `nix build .#secretspec .#cabal-install --no-link` succeeds, both outputs identify the verified stable releases, and `nix run .#cabal-install -- upload --help` lists `--token-command`. An isolated global config containing the field must parse without an unknown-field warning. Milestone 3 then proves actual credential-command behavior.


### Milestone 2: Install the shared manifest and helper


Add `home/haskell-publishing.nix`, import it from `home/default.nix`, and install `pkgs.secretspec` and a helper built with `pkgs.writeShellScriptBin`. Generate `xdg.configFile."haskell-publishing/secretspec.toml".text` with this content:

```toml
[project]
name = "haskell-publishing"
revision = "1.0"

[profiles.default.HACKAGE_TOKEN]
description = "Hackage publishing token"
required = true
providers = ["keyring"]
```

Generate the helper named `hackage-token` with strict shell error handling. Embed the absolute `config.xdg.configHome` manifest path and the Nix-selected SecretSpec executable path at evaluation time. Its essential body is:

```nix
pkgs.writeShellScriptBin "hackage-token" ''
  set -euo pipefail
  exec ${pkgs.secretspec}/bin/secretspec \
    --file ${lib.escapeShellArg "${config.xdg.configHome}/haskell-publishing/secretspec.toml"} \
    get HACKAGE_TOKEN --provider keyring --profile default
''
```

Use the generated package in `home.packages`, and expose it at `home.file.".local/bin/hackage-token".source` using the same executable so Cabal has the stable absolute path `${config.home.homeDirectory}/.local/bin/hackage-token`. The Nix-generated executable is executable and immutable. Do not follow the draft's `chmod 700` instruction on a Nix store-backed symlink; Unix executable permissions are not the token's security boundary. The script and manifest are public metadata, while Keychain protects the value.

Do not generate or overwrite `~/.config/secretspec/config.toml`; explicit selection makes that unnecessary. Leave user-global aliases and audit settings intact. Do not call `secretspec set`, `get`, or `check` in Home Manager activation. The feature can build and activate on a Mac with no Hackage credential enrolled.

The generated helper package should be bound once in the module and reused for both installation locations. Acceptance is that evaluating each full host yields the same logical manifest and helper with its home directory resolved correctly; `bootstrap-arm` remains independent of them. The manifest parses and its generated schema requires `HACKAGE_TOKEN`. Executing the helper from two unrelated directories must choose the same manifest; prove this with a fake SecretSpec executable in tests rather than reading the real Keychain.


### Milestone 3: Prove integration offline and write the corrected guide


Add `bin/test-hackage-publishing.py`, using Python's standard library, temporary directories, dummy tokens, and a local HTTP server. Accept explicit `--cabal` and `--secretspec` paths so the command tests the newly built packages. Add a `just test-hackage-publishing` recipe that builds the two package outputs, resolves their executable paths, and runs the test. Add helper-level tests using the same Nix helper generation with a substituted fake SecretSpec package; expose it as `checks.hackage-token-helper` in the per-system section of `flake-modules/packages.nix` so the test does not merely test a duplicated shell script. The fake must assert the absolute manifest argument, secret name, provider and profile, then return a dummy token or fail on request.

Create a minimal valid source archive in the temporary directory, an isolated Cabal config with a repository URL restricted to `http://127.0.0.1:<ephemeral-port>/`, and an executable dummy token helper that records invocation without logging a token. Drive both a candidate source upload and a documentation upload using that config. Assert an `Authorization: X-ApiKey <dummy-value>` header reaches the loopback server, stdout and stderr contain no dummy token at normal and verbose logging, and no Hackage hostname is contacted. A failing helper must exit nonzero and produce no upload request. Also exercise config serialization with `user-config update` and ordinary explicit dummy-token behavior without a token-command. Ensure temporary files and listeners are closed after failure. Upstream Cabal transports can pass authentication headers to external curl or wget processes; command retrieval does not establish a blanket absence of credentials from all subprocess arguments. Test captured logging with dummy values before selecting the supported publishing verbosity. If an exercised transport logs the dummy token, do not patch Cabal or weaken the assertion. Record the upstream issue and defer live use of that mode until an unmodified stable release handles it safely. Do not claim that Keychain storage guarantees transport-log safety. These tests protect a real credential-handling change; they are not tests of Markdown wording.

Add `docs/hackage-publishing.md` as the corrected version of the user's guide. Explain the current SecretSpec release, the minimum verified stable Cabal release and its capability check, stable helper path, shared manifest, explicit enrollment commands, active-config discovery, per-machine credential enrollment, and conditional Keychain prompts. Update `README.md`, `docs/INSTALLED_PACKAGES.md`, and `docs/new-machine-bootstrap.md` with concise links and enrollment context. Keep `config/bootstrap/config-policy.json`'s exclusion of the actual Cabal config.

The guide must distinguish configuration validation from authentication. `schema` verifies declarations, `check --no-prompt` verifies resolvability, and neither proves Hackage accepts the token. Show `cabal sdist` followed by a command naming the intended archive explicitly; a wildcard can accidentally include old or unrelated archives. Explain that omitting `--publish` creates a candidate, which is still a remote mutation. Do not run either remotely during automated validation.

Run the offline tests, evaluate both full hosts, and build both using the existing wrappers. Inspect diffs for unrelated lock changes. Acceptance is a green offline integration, successful full-host builds, and a guide whose commands match the exact packaged executables without displaying a real token.


### Milestone 4: Enroll locally and complete the global Cabal integration


Build the intended host immediately before activating it on that physical machine. Use the repository's owner-build and sudo-switch wrappers. In the user's interactive terminal, enroll the token with the explicit manifest/provider/profile command below. Choose a dedicated Hackage token using the restrictions and expiry actually available in the Hackage account interface; do not claim a particular scope exists without checking.

Verify a nonempty token can be retrieved while discarding its bytes. Discover the active Cabal config from the publishing shell, make a protected local backup if editing an existing file, and add exactly one top-level `token-command` line pointing to the stable helper. Preserve other settings. Once retrieval and the offline Cabal behavior are proven, remove any active plaintext `token:` entry from that config. A backup may still contain old credentials: keep it private and have the owner remove or securely retain it according to their recovery needs. Do not copy it into Git, documentation, or Nix expressions. Do not assume that merely deleting a field revokes a previously exposed token.

Inspect configuration privately rather than dumping it into tool output. If `cabal path --config-file` reports a symlink or a path owned by another manager, update that owner instead of replacing its generated target. If the publishing shell selects a Cabal that lacks the option, select `$HOME/.nix-profile/bin/cabal` explicitly and verify its help before configuring it. A project that intentionally passes another `--config-file` needs the setting in that selected file as well.

Update or create a plain Markdown ADR under `docs/adr/` covering Keychain ownership, stable manifest identity, the requirement to use an unmodified stable Cabal release, writable global config, and the distinction between shared configuration and local credentials. Reuse an ADR covering the topic if one exists by implementation time. Timestamp the plan's completed steps and record actual validation results. If interactive Keychain access or activation is unavailable, keep those tasks unchecked and describe the missing evidence; a build alone is not end-to-end completion.


## Concrete Steps


All implementation commands below are for after the user resumes work and the stable-release gate passes. Do not install or configure anything while waiting. Run repository commands from the checkout root:

```bash
cd /Users/shinzui/.config/dotfiles.nix
git status --short
mori registry show haskell/cabal --full
mori path mori://haskell/cabal/repos/cabal
curl -fsSL https://hackage.haskell.org/package/cabal-install/preferred.json | jq '."normal-version"[:5]'
git ls-remote --tags https://github.com/haskell/cabal.git 'refs/tags/cabal-install-v*'
jq '.nodes["nixpkgs-unstable"].locked' flake.lock
curl -fsSL https://index.crates.io/se/cr/secretspec | tail -n 1 | jq '{vers,yanked}'
git ls-remote --tags https://github.com/cachix/secretspec.git 'refs/tags/v*'
```

Compare stable releases and their actual tagged source with the Nix package selected by the lock. Exclude prereleases and yanked entries. If the required released Cabal package has not reached nixpkgs, leave the gate unchecked and wait. If a suitable package requires an input refresh, run `nix flake update nixpkgs-unstable`, inspect its diff, and build both hosts before accepting it. Do not refresh unrelated inputs, add local Cabal patches, or query “latest” during ordinary Nix evaluation. Never traverse or read `/nix/store` for dependency research.

After implementing the ordinary package outputs, module, and tests, stage only the new Nix inputs required by the Git-backed flake, then run:

```bash
nix build .#secretspec .#cabal-install --no-link
nix run .#secretspec -- --version
nix run .#cabal-install -- --numeric-version
nix run .#cabal-install -- upload --help
python3 bin/test-hackage-publishing.py \
  --cabal "$(nix build .#cabal-install --no-link --print-out-paths)/bin/cabal" \
  --secretspec "$(nix build .#secretspec --no-link --print-out-paths)/bin/secretspec"
just test-hackage-publishing
nix build .#checks.aarch64-darwin.hackage-token-helper --no-link
nix eval --raw '.#darwinConfigurations.SungkyungM1X.config.home-manager.users.shinzui.xdg.configFile."haskell-publishing/secretspec.toml".text'
nix eval --raw '.#darwinConfigurations.yujin.config.home-manager.users.shinzui.xdg.configFile."haskell-publishing/secretspec.toml".text'
./bin/build.sh SungkyungM1X
./bin/build.sh yujin
git diff --check
```

Expected observations are the verified stable version numbers, upload help containing `--token-command=COMMAND`, the manifest shown in Milestone 2 for both full hosts, passing dummy-credential tests, and successful host builds. Record actual versions and results in this plan. No real token is needed for these checks.

After the release gate passes and implementation is resumed, activate only the intended host on its corresponding physical machine. Build it immediately before switching. For Sungkyung:

```bash
cd /Users/shinzui/.config/dotfiles.nix
./bin/build.sh SungkyungM1X
sudo ./bin/darwin-rebuild.sh SungkyungM1X
```

On Yujin substitute `yujin` in both commands. Enroll independently in the user's interactive terminal. The repository currently uses the default XDG configuration directory:

```bash
set -o pipefail
secretspec --file "$HOME/.config/haskell-publishing/secretspec.toml" \
  set HACKAGE_TOKEN --provider keyring --profile default
secretspec --file "$HOME/.config/haskell-publishing/secretspec.toml" \
  check --provider keyring --profile default --no-prompt
"$HOME/.local/bin/hackage-token" | python3 -c 'import sys; sys.exit(0 if sys.stdin.buffer.read() else 1)'
cabal upload --help | rg -- '--token-command'
cabal path --config-file
```

The prompt accepts the token interactively, `check` reports presence, and the retrieval pipeline succeeds silently. With `pipefail`, helper failure cannot be masked by the final command. If `config.xdg.configHome` differs, use the generated manifest path consistently. Do not print the helper's output to the terminal.

Privately inspect the reported Cabal config, preserve unrelated settings, and add exactly one top-level entry:

```text
token-command: /Users/shinzui/.local/bin/hackage-token
```

Verify parsing under the supported released Cabal. Remove an existing active plaintext token only after helper retrieval succeeds. An intended future package release, run from its package repository, uses:

```bash
cabal sdist
cabal upload --publish dist-newstyle/sdist/<package>-<version>.tar.gz
```

Replace the placeholders with the archive just produced. This publication is not an automated test and is not authorized merely by implementing this plan.


## Validation and Acceptance


The release gate passes only when authoritative upstream tags and Hackage show a stable Cabal release with `token-command`, and the selected ordinary Nix package provides that feature without local changes. Development snapshots, custom Cabal builds, backports, token arguments as a substitute, and a release version guessed in advance do not satisfy the user's requirement. Work remains deferred until the user resumes it.

After resumption, the package check requires the latest verified stable SecretSpec, a supported unmodified stable Cabal, and successful builds on `aarch64-darwin`. A help string alone is insufficient: isolated local HTTP tests must prove source and documentation uploads use the helper's stdout, helper failure prevents upload, and dummy tokens stay out of captured logs in supported modes. If upstream behavior fails these checks, record it and wait for an upstream fix rather than patching Cabal.

The helper check requires an absolute generated manifest path, the Nix-selected SecretSpec executable, explicit `keyring` and `default`, directory independence, forwarded errors, and token-only stdout. Exercise the production-generated helper with a fake provider executable, and parse the manifest through SecretSpec schema generation without contacting Keychain.

The repository check requires successful full-host builds, one ordinary Cabal executable in the user profile, no ownership takeover of the entire global Cabal or SecretSpec configs, an independent bootstrap target, and no unintended input changes. Check Markdown, whitespace, and commands.

Live acceptance on each enrolled machine requires the supported stable Cabal in the actual publishing shell, one token-command entry in the active global config, silent nonempty retrieval, and successful `check --no-prompt`. Keychain dialogs may require the user's action. This proves local retrieval; an independently authorized Hackage operation alone proves server-side token validity. Record that distinction.


## Idempotence and Recovery


Nix builds and evaluations can be repeated without changing credentials. Home Manager installs the same manifest identity and helper paths on each activation and does not access Keychain. If the preexisting helper or manifest conflicts with Home Manager ownership, inspect it before replacement and preserve any user-owned non-secret customization through the usual local backup process.

Cabal's config edit is a one-time, targeted migration. Back up a writable config with restrictive permissions before editing; never print or commit it. Repeating the edit must replace the existing token-command rather than append duplicates. Preserve unrelated repositories, build settings, and credential sources. Do not automatically rewrite symlinks or another manager's output. To roll back, restore the prior config privately, rebuild the previous Nix configuration, and keep the Keychain entry until the owner deliberately removes or revokes it. An earlier Cabal should not be left reading an unsupported field.

`secretspec set` updates the entry addressed by the fixed project/profile/key. Changing those identifiers can make an existing entry appear absent; restore the original identifiers before assuming the value is lost. Denying a macOS prompt or a locked Keychain should fail retrieval, not trigger a plaintext fallback. Retry interactively after unlocking or granting access. Upgrades can require renewed authorization for the new executable.

Keep live publication separate from tests: published Hackage versions cannot be treated as disposable test data. The loopback tests use only dummy values and clean up temporary files and listeners. Keep ordinary upstream package checks enabled. If the required stable release is unavailable or fails validation, leave the relevant milestone incomplete and record the issue. Wait for a suitable upstream release rather than adding a local workaround.


## Interfaces and Dependencies


The future shared module is `home/haskell-publishing.nix`. Its installed interface is the generated `haskell-publishing/secretspec.toml` and executable `hackage-token`, available through the user profile and stable `~/.local/bin/hackage-token` link. The helper takes no arguments, emits token bytes only on stdout, writes diagnostics to stderr, and returns nonzero on lookup failure. Cabal receives its absolute path through the top-level `token-command` field. Neither helper nor manifest contains a real credential.

Use ordinary `pkgs.secretspec`, verified as 0.21.1 during plan creation and to be refreshed at resumption. SecretSpec upstream is `mori://cachix/secretspec` (source-file artifact URIs pending). Relevant project-relative sources are `secretspec/src/cli/mod.rs`, `secretspec/src/config.rs`, and `secretspec/src/provider/keyring.rs`. Compare the stable release against the authoritative crates.io index when selecting the package.

Use the ordinary released `pkgs.haskellPackages.cabal-install` when it passes the release gate; expose it as `packages.cabal-install` for focused builds. Do not introduce `cabal-install-hackage`, a token-command patch, a custom Cabal derivation, or a development source pin. Cabal upstream is `mori://haskell/cabal/repos/cabal` (source-file artifact URIs pending); verify the chosen release's project-relative `cabal-install/src/Distribution/Client/Setup.hs` and upload implementation. Cabal 3.18.2.0 lacked the required feature at creation. The development line 3.19.0.0 is not a stable release commitment. Record the actual supported stable version after it becomes available.

The future validation interface is `python3 bin/test-hackage-publishing.py --cabal <absolute-executable> --secretspec <absolute-executable>`, returning zero only when the isolated dummy-credential cases pass. `just test-hackage-publishing` is the convenience command. Existing `bin/build.sh` and `bin/darwin-rebuild.sh` remain the build and activation interfaces.


Created 2026-10-16 after validating the supplied guide against SecretSpec, pinned Nix packaging, released and development Cabal source, authoritative registries, and both relevant local ADRs.

Revision 2026-10-16: the user chose to wait for the upstream release and rejected a Cabal backport. Removed the custom package, patch instructions, development-build alternatives, and local Cabal modification path from all implementation sections. Deferred the whole implementation until a supported stable release is packaged by Nix and the user resumes the work. No system or credential changes have been made.
