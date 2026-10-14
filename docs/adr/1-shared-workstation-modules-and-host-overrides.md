# Shared workstation modules and host overrides

Date: 2026-10-14

Status: Accepted

## Context

Sungkyung and Yujin are Apple Silicon macOS workstations using the `shinzui`
account. Their initial applications, services, defaults, user configuration, and
secret declarations are shared. Each machine needs independent system and user
settings without duplicating configuration or depending on the other's modules.

## Decision

Keep shared system configuration in `darwin/` and shared Home Manager
configuration in `home/`. Compose full hosts through the private `mkDarwinHost`
constructor in `flake-modules/darwin-configurations.nix`, preserving module
arguments, overlays, secret imports, and compatibility state versions.

Use sibling `hosts/sungkyung/` and `hosts/yujin/` directories. Each `default.nix`
sets machine names and imports its adjacent `home.nix` into the selected Home
Manager user. Neither host imports the other. Preserve `SungkyungM1X` and add
`yujin`; keep `bootstrap-arm` separate without agenix or Home Manager.

Nix module import order does not make later scalar assignments win. Conflicting
ordinary scalar definitions fail; ordinary list definitions generally accumulate.
Use `lib.mkDefault` for shared preferences that hosts may replace, and
`lib.mkForce` for an intentional replacement of an unconditional definition or
whole list. `lib.mkBefore` and `lib.mkAfter` affect list order, not replacement.
Promote a shared setting to `mkDefault` when a real divergence calls for it,
rather than lowering the priority of every shared setting preemptively.

Build as the owner before switching with sudo. Build and switch wrappers select
explicit targets rather than infer them from the current machine name. The build
defaults to Sungkyung; the generic switch requires a host. The compatibility
Sungkyung switch wrapper delegates to it. The `result` link holds one build, so
build the intended host immediately before switching. `darwin-rebuild switch`
evaluates and builds again before activation.

## Consequences

Common edits affect both hosts, while differences stay in each host's files.
The shared composition remains visible in one place; introduce a named shared
profile only when repeated subsets emerge. Avoid scattered hostname conditionals.

Yujin inherits ARM font selection, the `shinzui` home paths and sudo rule, and
both tiers of secret declarations. Verify architecture, login, and network service
names when onboarding. Configuration reuse does not transfer private identities,
credentials, databases, or unmanaged state. Follow [the secrets guide](../secrets.md)
for identity restoration or actual-recipient rekeying and live checks. Excluding
private modules from bootstrap does not guarantee anonymous flake-input fetching.

Focused configuration snapshots and full builds protect existing behavior;
temporary DNS and Zoxide differences demonstrate system and user isolation.
Non-activating wrapper checks verify dispatch and argument handling. Physical
activation and successful decryption remain separate onboarding checks.
