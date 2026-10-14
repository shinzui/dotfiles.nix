---
id: 5
slug: add-yujin-with-shared-workstation-configuration-and-independent-host-overrides
title: "Add Yujin with shared workstation configuration and independent host overrides"
kind: exec-plan
created_at: 2026-10-14T00:14:04Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-14T00:14:04Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T00:17:40Z
      mode: "other"
      note: "Complete initial three-milestone plan and verify the baseline evaluation command"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T00:24:39Z
      mode: "update"
      note: "Apply review findings: checklist, bootstrap parity, wrapper contract harness, activation semantics, and live smoke checks"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T00:33:32Z
      mode: "implement"
      note: "Implement shared host composition, host-selecting wrappers, and workstation onboarding; record validation"
  reviews:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T00:21:14Z
      verdict: "changes-requested"
      note: "Baseline snapshot and source claims verified; add Progress checklist, bootstrap regression comparison, and non-activating wrapper contract checks"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-14T00:24:39Z
      verdict: "approved"
      note: "Revised plan validated against repository and locked source; temporary prototype passed host parity, independent overrides, bootstrap preservation, and wrapper checks; builds and onboarding remain implementation acceptance"
---

# Add Yujin with shared workstation configuration and independent host overrides


This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture


Support two macOS workstations, Sungkyung and Yujin, from this checkout. Both start with the same applications, services, shell/editor configuration, defaults, and secret declarations. Each gets its own machine name and small system and user override files, so a later Yujin-only change does not require copying the entire configuration or editing Sungkyung.

The existing `SungkyungM1X` flake target continues to work. A new `yujin` target builds independently. A developer can run `./bin/build.sh yujin`, build the existing machine with `./bin/build.sh SungkyungM1X`, and prove that a temporary setting in Yujin's override files affects only Yujin. The design reuses the shared composition already present in the repository.


## Progress


- [x] (2026-10-14 00:21Z) Review repository and locked dependency interfaces; run the baseline snapshot and validate shared-host composition and isolated overrides in a temporary copy. Subsequently verify the added bootstrap comparison and wrapper harness against that copy.
- [x] (2026-10-14 00:34Z) Milestone 1: Capture full-host and bootstrap baselines, add sibling host modules and the shared constructor, compare final snapshots, and build both full hosts.
- [x] (2026-10-14 00:34Z) Milestone 2: Implement executable host-selecting wrappers and pass Bash syntax and the non-activating command harness.
- [ ] Milestone 2 remaining: Exercise real build dispatch for the default, explicit Sungkyung, and Yujin targets.
- [ ] Milestone 3: Repeat the override experiment in the implementation checkout, restore parity, rebuild, and complete README, secrets onboarding, and the local ADR.
- [ ] Record repository acceptance and the ADR distillation pass; record physical Yujin onboarding separately as performed or unperformed.


## Surprises & Discoveries


Implementation (2026-10-14 UTC): The checkout snapshots passed both host parity and bootstrap preservation. Both full system builds exited zero, and bootstrap derivation evaluation exited zero. Concurrent Nix evaluations emitted an ignored SQLite busy warning; they completed successfully. The wrappers passed Bash syntax checks and the complete temporary command harness without activation. ShellCheck is not installed.

```text
PASS: Sungkyung preserved; Yujin matches shared settings
PASS: bootstrap preserved without agenix or Home Manager
PASS: wrapper targets, quoting, directory, errors, and exit status
```

Discovery (2026-10-14 UTC): The original Progress placeholder did not satisfy the required checklist, and syntax checks plus successful builds did not verify the switch wrapper's target, argument boundaries, caller-directory independence, or propagated failures. This review adds an explicit work checklist and a temporary, non-activating command harness. Bootstrap also needs a semantic before/after check; a successful derivation evaluation alone does not demonstrate preservation.

Discovery (2026-10-14 UTC): The original baseline snapshot is executable. It returned Sungkyung's three names as `sungkyung`, DNS as `[ "1.1.1.1" "8.8.8.8" ]`, 214 user packages, and 14 system packages. A temporary copy with the proposed constructor and four host modules preserved that snapshot, matched Yujin after removing the names, and produced the intended isolated override results:

```text
PASS: Sungkyung preserved; Yujin matches shared settings
yujin: DNS ["9.9.9.9"], Zoxide false
SungkyungM1X: DNS ["1.1.1.1","8.8.8.8"], Zoxide true
SungkyungM1X, yujin, bootstrap-arm: system.drvPath evaluation exit 0
```

This is review evidence from a temporary prototype, not completed configuration implementation or a successful build. No configuration was activated. Locked nix-darwin source confirms that `networking.localHostName` defaults to `networking.hostName`; the host modules therefore need only the two explicit name assignments shown below.

Discovery (2026-10-14 UTC): The added bootstrap snapshot matched between the current checkout and the prototype, with `hasAgenix = false` and `hasHomeManager = false`. The embedded wrapper harness passed against temporary implementations of the proposed wrappers, printing `PASS: wrapper targets, quoting, directory, errors, and exit status`. On macOS, temporary directories may be addressed through `/var` while commands report `/private/var`; the harness resolves its temporary directory before comparing working directories to avoid mistaking that alias for a wrapper defect.


## Decision Log


Decision (2026-10-14 UTC): Keep `darwin/` and `home/` as the shared workstation configuration, and add sibling `hosts/sungkyung/` and `hosts/yujin/` directories. Neither host imports the other. This preserves the existing organization and makes ownership of later differences explicit without introducing a second configuration framework.

Decision (2026-10-14 UTC): Preserve the `SungkyungM1X` output and the default behavior of `bin/build.sh` and `bin/darwin-rebuild-sungkyung.sh`. Add the exact output name `yujin`, selected explicitly by commands. This avoids breaking established commands and avoids deriving a target from the hostname of the machine doing the build.

Decision (2026-10-14 UTC): Assume `aarch64-darwin` (Apple Silicon) and the `shinzui` login for Yujin, because its initial configuration is to match Sungkyung. The user confirmed both machines are Macs, but did not independently confirm Yujin's processor or login. Verify these during onboarding. Supporting another architecture or login would require auditing the shared ARM font selection, bootstrap primary user, home paths, and sudo rule, and is outside this initial change.

Decision (2026-10-14 UTC): Use ordinary Nix modules and the existing dependencies and lock file. Promote a shared preference to `lib.mkDefault` when hosts need to choose it independently; use `lib.mkForce` for intentional replacement of an existing unconditional value or whole list. Do not blanket-wrap the entire shared configuration or preemptively split every service into a configurable feature.

Decision (2026-10-14 UTC): Document Yujin secret onboarding using the established two-tier secret contract. Do not fabricate a recipient key, copy a private identity through repository files, or rekey unrelated secrets as part of the host refactor. No Intention ID is associated with this plan; the user selected Skip.

Decision (2026-10-14 UTC, review): Preserve bootstrap using a separate before/after snapshot that does not require Home Manager or agenix. Verify wrapper dispatch, quoting, working directory, missing build handling, and exit status using temporary command substitutes. These checks make the promised behavior observable without switching the reviewer's machine.


## Outcomes & Retrospective


Review (2026-10-14 UTC): The three-milestone design is supported by repository inspection, locked source inspection, successful baseline evaluation, and a temporary host-composition experiment. The review corrected missing progress tracking and incomplete bootstrap and wrapper acceptance. Implementation, full system builds, documentation changes, ADR creation, and physical Yujin onboarding remain outstanding; keep those results distinct from this review's evidence.


## Context and Orientation


This is a macOS configuration repository. A flake is a Nix entry point that names dependencies and exports build targets. `flake.nix` declares the dependencies; `flake.lock` fixes their revisions. `flake.nix` imports four flake-parts modules, including `flake-modules/darwin-configurations.nix`, which defines the actual workstation outputs. The latter already assembles `nixDarwinCommonModules` and `homeManagerCommonConfig`; only one small inline module supplies Sungkyung's user, machine names, and network service names. A Nix module is a file that declares or sets configuration options; the module system combines definitions according to each option's type and priority.

`flake-modules/darwin-configurations.nix` imports custom modules from `flake-modules/modules.nix`, agenix, the private secret module, Determinate Nix, `darwin/default.nix`, and Home Manager. It supplies shared overlays through `lib/nixpkgs-config.nix`, passes `private-fonts` through `specialArgs` (arguments supplied to system modules), and passes the merged `age` configuration through Home Manager's `extraSpecialArgs` (arguments supplied to user modules). Preserve all this wiring. The custom `users.primaryUser` option is declared in `modules/darwin/users.nix`; it selects the Home Manager account. The upstream `system.primaryUser` is separately set to `shinzui` in `darwin/bootstrap.nix`.

`darwin/default.nix` imports `darwin/bootstrap.nix`, `darwin/homebrew.nix`, `darwin/secrets.nix`, `darwin/mac-defaults.nix`, and `darwin/gcp-nix-builder.nix`. It also selects an ARM font package and sets shared DNS, keyboard settings, and a sudo rule with the literal `shinzui` username. `home/default.nix` imports shared user modules and contains the large package list. `home/xdg-configs.nix` and other modules use configuration files from this checkout; clone it to `~/.config/dotfiles.nix` on Yujin so existing out-of-store symlinks, which point directly into the editable checkout, remain valid.

The full output is currently `darwinConfigurations.SungkyungM1X`. Its hardware platform is `aarch64-darwin`, its machine names are `sungkyung`, its user is `shinzui`, and its known network services are `Wi-Fi` and `Thunderbolt Bridge`. The separate `bootstrap-arm` output omits both agenix and the private secret module. It must remain unchanged. The existing `system.stateVersion = 4` and Home Manager `home.stateVersion = "26.05"` are compatibility settings, not instructions to upgrade dependencies; preserve them for this initial matching configuration.

`bin/build.sh` contains a single build command fixed to Sungkyung. `bin/darwin-rebuild-sungkyung.sh` invokes the built `result/sw/bin/darwin-rebuild` for Sungkyung with an unquoted `$@`. The current workflow is an owner-run build followed by a sudo switch. A build assembles an installable system; a switch activates it and changes the running computer. `bin/test-treesitter.sh` is the existing editor verification helper. There is no `.github/` workflow, host parity test, or root-level test runner in this working tree.

The locked `darwin-rebuild switch` command evaluates and builds its selected flake again before activating; the owner-run build primes access to the private inputs and detects build failures, rather than making the later switch build-free. `bin/test-treesitter.sh` runs `nvim` from the caller's PATH, so its result describes that editor and its current runtime state, not necessarily the newly built editor. Onboarding must check the installed editor again after activation.

At implementation start, no local `docs/adr/` records existed, and `mori show --full` reported no ADR bundle or profile in this repository. Implementation added [the shared-host ADR](../adr/1-shared-workstation-modules-and-host-overrides.md), recording sibling modules, merge priorities, preserved outputs, and the separate owner-build/sudo-switch workflow. One relevant decision was consulted in the private companion: `mori://shinzui/dotfiles-private.nix` with project-relative path `docs/adr/1-two-tier-agenix-secrets.md` (artifact-level URI pending; the registry exposes no concept handle for it). Its contract keeps low-impact ciphertext here, high-tier ciphertext and declarations privately, fetches private inputs over SSH, builds as the owner before switching with sudo, and verifies secret installation after the agenix launch daemon runs. Adding a recipient requires rekeying both tiers. The needed public workflow is described in `docs/secrets.md` and is summarized below, so implementing this plan does not depend on access to that separate decision file.

Dependency discovery used Mori first. The registered flake-parts source was inspected through `mori://hercules-ci/flake-parts/repos/flake-parts`. Mori searches did not find nix-darwin, Home Manager, or nixpkgs corpus projects. Their relevant source files were then downloaded from upstream at this checkout's locked revisions and inspected: nix-darwin `43975d782b418ebf4969e9ccba82466728c2851b`, Home Manager `abfad3d2958c9e6300a883bd443512c55dfeb1be`, and nixpkgs `38a4887411571457d700c51c64a6e49ead2ed5ab`. The verified interfaces are `darwinSystem { system; modules; specialArgs; }`, Home Manager's `home-manager.users` module merging, and Nix's definition priorities. No dependency bounds, version upgrades, or new compatibility workarounds are proposed.


## Plan of Work


### Milestone 1: Compose two independent hosts from the existing shared modules


First capture the existing Sungkyung and bootstrap configuration snapshots with the commands below. Add `hosts/sungkyung/default.nix`, `hosts/sungkyung/home.nix`, `hosts/yujin/default.nix`, and `hosts/yujin/home.nix`. Each `default.nix` is a system module that sets only its machine names and imports its adjacent user module into the selected Home Manager account. The initial `home.nix` files contain `{ ... }: { }`, with a short comment identifying where future user differences belong. They do not import `home/default.nix`; shared Home Manager composition continues to do that once.

In `flake-modules/darwin-configurations.nix`, add shared `users.primaryUser = lib.mkDefault "shinzui"` and `networking.knownNetworkServices = lib.mkDefault [ "Wi-Fi" "Thunderbolt Bridge" ]` to the existing common system module that configures Home Manager. Remove those settings from the inline Sungkyung definition. Add a local constructor named `mkDarwinHost` in the `let` block. It takes `{ hostModule, system ? "aarch64-darwin" }`, calls `darwinSystem`, appends `hostModule` to `nixDarwinCommonModules`, and supplies the existing `private-fonts` special argument. Define `SungkyungM1X` using `../hosts/sungkyung` and `yujin` using `../hosts/yujin`. Leave the bootstrap definition separate. Keep the common Home Manager modules, state versions, registry entries, overlays, secret imports, and extra arguments intact.

Each host system module follows this form, with the names changed for Sungkyung:

```nix
{ config, ... }:
{
  networking.computerName = "yujin";
  networking.hostName = "yujin";
  home-manager.users.${config.users.primaryUser}.imports = [ ./home.nix ];
}
```

Stage the new files so Git-based flake evaluation includes them. Evaluate both host names and compare snapshots: Sungkyung retains its old settings, and the snapshots of the two hosts are identical after removing the machine name fields. Compare bootstrap snapshots as well: its settings remain unchanged and it still excludes Home Manager and agenix. Build both system targets using the commands below. This milestone passes when both configurations evaluate and build without changing the existing user's configuration, and bootstrap passes its regression check. A changed whole-system derivation path alone is not a regression: these outputs embed the source flake in registry configuration, so source edits can legitimately change build paths.

### Milestone 2: Select hosts through the existing build and activation workflow


Give `bin/build.sh` a Bash shebang, fail-fast shell settings, and an optional first argument defaulting to `SungkyungM1X`; forward remaining arguments as quoted `"$@"` to `nix build`. Its target is `.#darwinConfigurations.<host>.system`. Support exactly `SungkyungM1X`, `yujin`, and the existing `bootstrap-arm`; reject other names with a clear error before invoking Nix. Resolve the repository directory from the script location and change to it, so invocation does not depend on the caller's directory. Preserve the ordinary `result` link produced by the build.

Create executable `bin/darwin-rebuild.sh`, taking a required host argument followed by optional darwin-rebuild arguments. Use the same explicit target validation and repository-directory handling. Invoke `./result/sw/bin/darwin-rebuild switch --flake ".#<host>"` and forward remaining arguments with `"$@"`. If `result/sw/bin/darwin-rebuild` is absent, print an instruction to run `./bin/build.sh <host>` as the owner and exit unsuccessfully. Keep owner-build and sudo-activation as separate actions, matching the verified SSH/private-input workflow. `result` is a single link: the operator builds the intended host immediately before switching, and the explicit `--flake` argument selects the desired configuration.

Turn `bin/darwin-rebuild-sungkyung.sh` into an executable Bash script that resolves its own directory and uses `exec` to delegate to the absolute sibling script path with `SungkyungM1X` and quoted `"$@"`. Do not add an identical Yujin-specific wrapper. Make all three scripts executable. Validate scripts with `bash -n` and the temporary command harness below, exercise build selection for both names, and verify that unknown targets fail without invoking the substituted build or switch command. This milestone passes when the documented commands build the requested targets and the harness verifies defaults, both host names, bootstrap selection, arguments containing spaces, invocation from outside the checkout, the compatible Sungkyung wrapper, propagated failures, and missing-result guidance. Actual activation occurs only on the corresponding workstation during onboarding or an explicitly requested switch.

### Milestone 3: Prove divergence and document machine onboarding


Prove that the host boundaries work with temporary differences. Set Yujin's `networking.dns = lib.mkForce [ "9.9.9.9" ]` in `hosts/yujin/default.nix` and `programs.zoxide.enable = lib.mkForce false` in `hosts/yujin/home.nix`, adding a `lib` module argument to each file. Evaluate both machines: only Yujin changes. Remove these temporary definitions and rebuild Yujin to deliver identical initial settings. This experiment tests both system and user module composition; it does not activate the changes.

In `README.md`, replace the one-host description, add the host directories to Layout, and document commands for both targets. Explain that common changes belong in `darwin/` or `home/`, while host-specific system and user changes belong in that host's `default.nix` and `home.nix`. Document Nix's merging behavior: later imports do not automatically win; ordinary conflicting scalar settings produce an error, and ordinary list settings generally accumulate. `lib.mkDefault` gives a shared preference lower priority so an ordinary host definition wins. `lib.mkForce` replaces an already unconditional shared setting; `lib.mkBefore` and `lib.mkAfter` control list order, not replacement. Prefer changing a deliberately variable shared preference to `mkDefault` when the first real divergence occurs. Avoid hostname conditionals scattered across shared modules. Introduce a named shared profile only if repeated subsets of configuration emerge across hosts, rather than guessing those subsets now.

Extend `docs/secrets.md` with Yujin onboarding. Verify the architecture and login locally with `uname -m` and `id -un`; expected values are `arm64` and `shinzui`. Confirm network service names with `networksetup -listallnetworkservices`; override the default service list if Yujin differs. Restore the existing workstation identity securely to the configured path, or supply the actual public key for a new identity and update recipient rules in both tiers. The configured `age.identityPaths` currently uses `/Users/shinzui/.ssh/id_ed25519`; adding a machine's host SSH public key alone will not help unless the matching private identity is also among the configured identity paths. Never invent key material. Rekey only after the real identity and access are available; private-tier changes are published before updating the public `dotfiles-private` lock entry. Existing encrypted files and keys need no change if Yujin restores an already-authorized identity.

Document building and switching `bootstrap-arm` before full activation if secrets are not available, then owner-building and sudo-switching `yujin` after SSH access to private fonts and the private companion is established. Explain that excluding private modules from bootstrap does not guarantee that every private flake input can be fetched anonymously; authorized SSH access may still be needed during input resolution. Keep the current secret tier separation and use the existing identity-path override mechanism if a different identity file is required.

Create `docs/adr/1-shared-workstation-modules-and-host-overrides.md` during implementation using a simple local ADR format with title, date, accepted status, context, decision, and consequences. Before writing it, repeat ADR discovery; if another task has introduced an ADR contract or occupied that filename, follow the new local convention and allocate a distinct filename. Record sibling host modules, preserved output names, and Nix merge semantics as durable context. No profile-governed ADR bundle exists today; do not invent OKF metadata or modify Mori identity as part of this task. The milestone passes when the isolated override experiment succeeds, the final configurations again match apart from identity names, and the README, secrets guide, and ADR explain the complete workflow.


## Concrete Steps


Run commands from the repository root, currently `/Users/shinzui/.config/dotfiles.nix`. Do not search or traverse `/nix/store` or the filesystem root. Start with `git status --short` and preserve unrelated work. Capture the initial semantic snapshot before editing configuration:

```bash
cd /Users/shinzui/.config/dotfiles.nix
cat > /tmp/dotfiles-host-snapshot.nix <<'NIX'
cfg:
let
  hm = cfg.home-manager.users.${cfg.users.primaryUser};
  packageNames = packages:
    builtins.sort builtins.lessThan
      (map (p: p.pname or p.name) packages);
in {
  inherit (cfg.networking) hostName computerName localHostName dns knownNetworkServices;
  primaryUser = cfg.users.primaryUser;
  systemPrimaryUser = cfg.system.primaryUser;
  systemStateVersion = cfg.system.stateVersion;
  homeStateVersion = hm.home.stateVersion;
  homeDirectory = hm.home.homeDirectory;
  homePackages = packageNames hm.home.packages;
  systemPackages = packageNames cfg.environment.systemPackages;
  secretNames = builtins.attrNames cfg.age.secrets;
  identityPaths = cfg.age.identityPaths;
  systemDaemonNames = builtins.attrNames cfg.launchd.daemons;
  userAgents = builtins.mapAttrs (_: agent: agent.enable) hm.launchd.agents;
  keyboard = cfg.system.keyboard;
}
NIX
nix eval --json .#darwinConfigurations.SungkyungM1X.config \
  --apply "$(cat /tmp/dotfiles-host-snapshot.nix)" \
  > /tmp/dotfiles-sungkyung-before.json
cat > /tmp/dotfiles-bootstrap-snapshot.nix <<'NIX'
cfg: {
  inherit (cfg.system) primaryUser stateVersion;
  inherit (cfg.networking) hostName computerName localHostName;
  systemPackages = builtins.sort builtins.lessThan
    (map (p: p.pname or p.name) cfg.environment.systemPackages);
  daemonNames = builtins.attrNames cfg.launchd.daemons;
  hasAgenix = cfg ? age;
  hasHomeManager = cfg ? home-manager;
  nixSettings = cfg.determinateNix.customSettings;
  distributedBuilds = cfg.determinateNix.distributedBuilds;
  buildMachines = cfg.determinateNix.buildMachines;
}
NIX
nix eval --json .#darwinConfigurations.bootstrap-arm.config \
  --apply "$(cat /tmp/dotfiles-bootstrap-snapshot.nix)" \
  > /tmp/dotfiles-bootstrap-before.json
```

The snapshot contains configuration metadata and package names, not plaintext secrets. Initial authoring verified `nix eval --json .#darwinConfigurations.SungkyungM1X.config.networking.hostName` returns `"sungkyung"`. After Milestone 1 edits, stage only the new host files and take updated snapshots:

```bash
git add hosts/sungkyung/default.nix hosts/sungkyung/home.nix \
  hosts/yujin/default.nix hosts/yujin/home.nix
nix eval --json .#darwinConfigurations.SungkyungM1X.config \
  --apply "$(cat /tmp/dotfiles-host-snapshot.nix)" \
  > /tmp/dotfiles-sungkyung-after.json
nix eval --json .#darwinConfigurations.yujin.config \
  --apply "$(cat /tmp/dotfiles-host-snapshot.nix)" \
  > /tmp/dotfiles-yujin.json
nix eval --json .#darwinConfigurations.bootstrap-arm.config \
  --apply "$(cat /tmp/dotfiles-bootstrap-snapshot.nix)" \
  > /tmp/dotfiles-bootstrap-after.json
python3 - <<'PY'
import json
from pathlib import Path
before = json.loads(Path('/tmp/dotfiles-sungkyung-before.json').read_text())
after = json.loads(Path('/tmp/dotfiles-sungkyung-after.json').read_text())
yujin = json.loads(Path('/tmp/dotfiles-yujin.json').read_text())
assert before == after, 'Sungkyung configuration changed'
for key in ('hostName', 'computerName', 'localHostName'):
    assert after.pop(key) == 'sungkyung', key
    assert yujin.pop(key) == 'yujin', key
assert after == yujin, 'Shared settings differ between hosts'
print('PASS: Sungkyung preserved; Yujin matches shared settings')
bootstrap_before = json.loads(Path('/tmp/dotfiles-bootstrap-before.json').read_text())
bootstrap_after = json.loads(Path('/tmp/dotfiles-bootstrap-after.json').read_text())
assert bootstrap_before == bootstrap_after, 'Bootstrap configuration changed'
assert not bootstrap_after['hasAgenix'], 'Bootstrap imports agenix'
assert not bootstrap_after['hasHomeManager'], 'Bootstrap imports Home Manager'
print('PASS: bootstrap preserved without agenix or Home Manager')
PY
nix build .#darwinConfigurations.SungkyungM1X.system --out-link result-sungkyung
nix build .#darwinConfigurations.yujin.system --out-link result-yujin
nix eval --raw .#darwinConfigurations.bootstrap-arm.system.drvPath
```

The comparison prints both PASS lines shown above. Builds exit zero and create their result links; bootstrap evaluation prints a derivation path. Record existing unrelated build failures explicitly rather than silently treating a partial evaluation as a successful build. Do not update all flake inputs to resolve an unrelated build failure.

After Milestone 2 edits, stage the new script, verify syntax, and exercise build dispatch:

```bash
git add bin/darwin-rebuild.sh
chmod +x bin/build.sh bin/darwin-rebuild.sh bin/darwin-rebuild-sungkyung.sh
for script in bin/build.sh bin/darwin-rebuild.sh bin/darwin-rebuild-sungkyung.sh; do
  bash -n "$script" || exit 1
done
./bin/build.sh
./bin/build.sh SungkyungM1X --out-link result-sungkyung
./bin/build.sh yujin --out-link result-yujin
./bin/build.sh unknown-host
./bin/darwin-rebuild.sh unknown-host
```

The first three build invocations select the intended host and exit zero. The last two invocations must fail with a nonzero status and an unknown-host error before running Nix or activating anything. Run these failure cases individually; their failure is expected. If ShellCheck is already available, run it on the three modified scripts; do not add a toolchain dependency solely for these wrappers.

Run this command from the repository root after the scripts exist. It copies only the three wrappers into a temporary directory, replaces Nix and the built switch command with recorders, and invokes the copies from another directory. The substitutes record argument arrays and return a requested exit code; they cannot build or activate anything. All assertions must pass and the final line must be `PASS: wrapper targets, quoting, directory, errors, and exit status`.

```bash
python3 - <<'PY'
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

source = Path.cwd()
with tempfile.TemporaryDirectory(prefix='dotfiles-wrapper-check-') as directory:
    root = Path(directory).resolve()
    for subdir in ('bin', 'shim', 'result/sw/bin', 'caller'):
        (root / subdir).mkdir(parents=True, exist_ok=True)
    for name in ('build.sh', 'darwin-rebuild.sh', 'darwin-rebuild-sungkyung.sh'):
        assert os.access(source / 'bin' / name, os.X_OK), f'{name} is not executable'
        shutil.copy2(source / 'bin' / name, root / 'bin' / name)
    recorder = '''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
Path(os.environ['WRAPPER_LOG']).write_text(json.dumps({
    'argv': sys.argv[1:], 'cwd': os.getcwd()
}))
sys.exit(int(os.environ.get('WRAPPER_EXIT', '0')))
'''
    for command in (root / 'shim/nix', root / 'result/sw/bin/darwin-rebuild'):
        command.write_text(recorder)
        command.chmod(0o755)
    log = root / 'invocation.json'
    env = dict(os.environ, PATH=f"{root / 'shim'}:{os.environ['PATH']}",
               WRAPPER_LOG=str(log), WRAPPER_EXIT='0')

    def run(script, args=(), exit_code=0):
        log.write_text('')
        completed = subprocess.run([str(root / 'bin' / script), *args],
                                   cwd=root / 'caller', env=env,
                                   capture_output=True, text=True)
        assert completed.returncode == exit_code, completed.stderr
        return json.loads(log.read_text()) if log.read_text() else None

    def expect(script, args, argv, exit_code=0):
        actual = run(script, args, exit_code)
        assert actual == {'argv': argv, 'cwd': str(root)}, actual

    expect('build.sh', [], ['build', '.#darwinConfigurations.SungkyungM1X.system'])
    build_flags = ['--out-link', 'result with spaces']
    switch_flags = ['--option', 'substituters', 'https://one.invalid https://two.invalid']
    for host in ('SungkyungM1X', 'yujin', 'bootstrap-arm'):
        expect('build.sh', [host, *build_flags],
               ['build', f'.#darwinConfigurations.{host}.system', *build_flags])
        expect('darwin-rebuild.sh', [host, *switch_flags],
               ['switch', '--flake', f'.#{host}', *switch_flags])
    expect('darwin-rebuild-sungkyung.sh', switch_flags,
           ['switch', '--flake', '.#SungkyungM1X', *switch_flags])
    for script, args in (('build.sh', ['unknown-host']),
                         ('darwin-rebuild.sh', ['unknown-host']),
                         ('darwin-rebuild.sh', [])):
        log.write_text('')
        failed = subprocess.run([str(root / 'bin' / script), *args],
                                cwd=root / 'caller', env=env,
                                capture_output=True, text=True)
        assert failed.returncode != 0 and not log.read_text(), failed
        assert failed.stderr.strip(), 'Missing error or usage message'
    env['WRAPPER_EXIT'] = '23'
    expect('build.sh', ['yujin'], ['build', '.#darwinConfigurations.yujin.system'], 23)
    expect('darwin-rebuild.sh', ['yujin'], ['switch', '--flake', '.#yujin'], 23)
    expect('darwin-rebuild-sungkyung.sh', [],
           ['switch', '--flake', '.#SungkyungM1X'], 23)
    (root / 'result/sw/bin/darwin-rebuild').rename(root / 'saved-rebuild')
    log.write_text('')
    missing = subprocess.run([str(root / 'bin/darwin-rebuild.sh'), 'yujin'],
                             cwd=root / 'caller', env=env,
                             capture_output=True, text=True)
    assert missing.returncode != 0 and not log.read_text(), missing
    assert './bin/build.sh yujin' in missing.stderr, missing.stderr
print('PASS: wrapper targets, quoting, directory, errors, and exit status')
PY
```

For Milestone 3, save copies of the two Yujin files outside the repository before inserting the temporary DNS and Zoxide definitions described above. With those definitions present, run:

```bash
nix eval --json .#darwinConfigurations.yujin.config.networking.dns
nix eval --json .#darwinConfigurations.SungkyungM1X.config.networking.dns
nix eval --json .#darwinConfigurations.yujin.config.home-manager.users.shinzui.programs.zoxide.enable
nix eval --json .#darwinConfigurations.SungkyungM1X.config.home-manager.users.shinzui.programs.zoxide.enable
```

Expected outputs, in command order, are:

```text
["9.9.9.9"]
["1.1.1.1","8.8.8.8"]
false
true
```

Restore the saved Yujin files, repeat the snapshot comparison, and rebuild Yujin. Run `./bin/test-treesitter.sh` before any real full switch, following the existing workflow. Check `git diff --check` and inspect the final diff; `flake.lock` should be unchanged unless real new-recipient onboarding required publishing a private-tier revision, in which case update only `dotfiles-private` and explain that change.

On Yujin itself, after prerequisites and the owner's matching build, the full activation commands are:

```bash
cd /Users/shinzui/.config/dotfiles.nix
./bin/build.sh yujin
sudo ./bin/darwin-rebuild.sh yujin
scutil --get ComputerName
scutil --get HostName
scutil --get LocalHostName
```

All three name checks should print `yujin`. If a bootstrap activation is needed first, use `./bin/build.sh bootstrap-arm` followed by `sudo ./bin/darwin-rebuild.sh bootstrap-arm`, then establish identity and private-input access before the full commands above. These are onboarding instructions; do not activate Yujin's configuration on Sungkyung. If Yujin is not accessible in the implementation session, finish repository validation and document live onboarding as unperformed, rather than claiming successful physical deployment.

During implementation, update this plan's living sections and record one provenance revision with `agents/skills/exec-plan/record-provenance.ts` using the current verified runtime model. Commit on the current branch using Conventional Commits, for example `feat(hosts): add independent Yujin workstation configuration`, with `ExecPlan: docs/plans/5-add-yujin-with-shared-workstation-configuration-and-independent-host-overrides.md` as a trailer. Do not add an Intention trailer.


## Validation and Acceptance


Acceptance requires the before/after snapshot to preserve Sungkyung and the two final snapshots to match apart from their three machine names. Bootstrap's before/after snapshot must also match and show neither agenix nor Home Manager. Both full system builds and bootstrap evaluation must succeed. The default build command must still select `SungkyungM1X`; the explicit `yujin` command must select Yujin. The temporary wrapper harness must pass, including the compatible Sungkyung wrapper, caller-directory independence, arguments with spaces, nonzero underlying command statuses, and missing-result guidance. Invalid target names and an omitted switch target fail before invoking a build or switch command. The temporary DNS and Zoxide experiment must produce the four outputs above, then be removed from the final configuration. This proves independent system and user changes without a copied package list or service configuration.

Review the composition as well as the snapshot: both outputs use the same constructor and shared module lists, and neither host imports the other's files. Confirm inherited Homebrew definitions, shared secret imports, overlays, state versions, and module arguments were not altered. The snapshot is deliberately a focused regression check and does not claim exhaustive equality of every option. Builds exercise the complete evaluated configuration; the isolated override experiment demonstrates the feature's behavior.

When onboarding is actually performed on Yujin, verify its three macOS names, expected package availability, and configuration symlinks. After the agenix daemon finishes, verify that the already-declared secret destination files are readable by their configured owner without printing their contents, and run the dependent tools' existing health checks from `docs/local-services.md`. A build cannot prove successful decryption. Separate these live results from repository-only acceptance in Outcomes & Retrospective.

For a concrete initial smoke check on Yujin as `shinzui`, run `command -v nvim zoxide mori`, `test -L "$HOME/.config/nvim/lua"`, `test -L "$HOME/.config/nvim/after"`, `test -L "$HOME/.config/mori"`, `test -r "$HOME/.config/sesh/sesh.toml"`, and `test -r "$HOME/.config/rei-api/tokens"`. Each command must exit zero; the first prints three executable paths. Neovim's `lua` and `after` directories are individually linked by `home/neovim.nix`; the containing `nvim` directory need not itself be a symlink. Rerun `./bin/test-treesitter.sh` against the activated editor and expect its PASS message. Run `just status-postgres`, `just status-tools`, `just status-victorialogs`, `just status-victoriatraces`, and `just status-redpanda` from the repository root; their recipes are defined in `Justfile`. Inspect the reported readiness and use the local-services runbook for failures. Configuration reuse installs declarations and programs; existing databases, Git credentials, external service authorization, and unmanaged state are separate onboarding prerequisites, so report any such missing prerequisite instead of claiming live service parity from a successful build.


## Idempotence and Recovery


Evaluation, snapshots, syntax checking, the isolated wrapper harness, and non-activating builds can be rerun. Keep the initial snapshot files until acceptance completes; do not overwrite the before files with post-edit settings. New files must remain staged for Git-based flake evaluation. Temporary override experiments are reversible: keep copies outside the repository, restore them even if evaluation fails, and recheck the final diff before committing. The wrapper harness copies scripts and substitutes commands only inside its own temporary directory. Do not use a broad `git reset` or restore unrelated work. Build result links are generated artifacts, not source files to commit.

If a full build fails, keep the last working activated generation, record the failing command, and fix only the cause relevant to this work. There is no need to switch to test module composition. Preserve the bootstrap output and old Sungkyung commands throughout the change.

If a real activation fails, inspect the retained system generations and use the previously working generation through `darwin-rebuild --list-generations` and `sudo darwin-rebuild --switch-generation <previous-generation>`, selecting the actual known-good generation number. Do not remove keys or prior ciphertext as part of retrying. For recipient changes, retain recoverable identities until installed secrets and their consumers work; a new recipient added to a rules file requires re-encryption of the actual ciphertext before it can decrypt. Consult the current private companion workflow through Mori rather than guessing its internal paths.


## Interfaces and Dependencies


The local constructor in `flake-modules/darwin-configurations.nix` has the Nix argument shape `mkDarwinHost = { hostModule, system ? "aarch64-darwin" }: ...`. `hostModule` is a path to a host system module, and `system` is a Nix platform string. It returns the existing nix-darwin configuration object, including `config` for inspection and `system` for building. Keep the constructor private to this file; a generic exported host framework is unnecessary for two machines.

Each `hosts/<name>/default.nix` accepts the system module's `config` argument and may accept `lib` for future overrides. Each `hosts/<name>/home.nix` is a Home Manager module, using Home Manager's own `config` and `lib` arguments when needed. The system host module adds it through `home-manager.users.${config.users.primaryUser}.imports`; the shared user configuration still imports `home/default.nix` and the exported Home Manager modules exactly once. Existing `age` extra arguments remain available to every user module.

The command interfaces are `bin/build.sh [SungkyungM1X|yujin|bootstrap-arm] [nix-build-arguments...]`, `bin/darwin-rebuild.sh <SungkyungM1X|yujin|bootstrap-arm> [darwin-rebuild-arguments...]`, and the compatible `bin/darwin-rebuild-sungkyung.sh [darwin-rebuild-arguments...]`. An omitted build target means Sungkyung. The generic switch requires a target. All wrappers preserve argument boundaries and return the underlying command's exit status.

Use the already locked nix-darwin, Home Manager, flake-parts, agenix, Determinate Nix, and private-font inputs. No dependency upgrade is required. The high-tier secret dependency is `mori://shinzui/dotfiles-private.nix`; its module is already imported. If onboarding changes that dependency, locate its current source and workflow with `mori registry show shinzui/dotfiles-private.nix --full` and `mori registry docs shinzui/dotfiles-private.nix`, and publish the narrowly scoped private change before updating its public lock entry.

Authoring note (2026-10-14 UTC): Created this plan after inspecting the existing host assembly, shared system and user modules, scripts, secret workflow, relevant dependency source, and private two-tier ADR. Configuration implementation and physical Yujin onboarding have not been performed.

Revision note (2026-10-14 UTC): Reviewed against the ExecPlan specification and current repository, verified the baseline command and proposed host composition in a temporary copy, and corrected Progress tracking, bootstrap preservation checks, non-activating wrapper verification, executable wrapper requirements, and live smoke-check instructions. Clarified that `switch` rebuilds and the existing Treesitter helper checks the editor on PATH. No host configuration, dependency pin, secret, or activated system was changed by this review.

Revision note (2026-10-14 UTC, implementation checkpoint): Implemented and built both host outputs with preserved Sungkyung and bootstrap snapshots; added host-selecting wrappers with passing non-activating contracts and distilled the architectural boundary into a local ADR. Real wrapper builds, the override experiment, and onboarding documentation remain.
