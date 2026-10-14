# Selective and private workstation bootstrap

Date: 2026-10-14

Status: Accepted

## Context

A full copy of `~/.config` would mix useful preferences with credentials, per-machine identity, generated sessions, caches, backups, and work-owned authority. Home Manager and agenix already own many exact targets. New Macs must be able to build before decryptable workstation secrets or the remote builder are available.

## Decision

Use `config/bootstrap/config-policy.json` as the explicit public disposition for the 70 audited XDG top-level entries and file-level exceptions. Only user-selected, non-secret settings become editable Home Manager out-of-store source links. Existing generated and linked targets retain their current manager. Public settings are checked for sensitive content before adding them. Unselected application settings remain excluded; possible unique user data gets an owner-specific export route.

Credential-bearing configs and persistent access material belong in encrypted agenix files in `mori://shinzui/dotfiles-private.nix`, project-relative `config/bootstrap/private-policy.json`, `secrets/`, and `darwin/secrets.nix` (artifact URIs pending). The public flake pins a published private revision. Renewable logins are recreated, while work-owned cluster authority stays under its owning recovery process. Source originals remain until installed consumers pass checks.

Mori's `host-id` is local writable state, never a shared tracked config file. Link its selected settings and source skills individually. Preserve the source workstation ID in a protected local backup before replacing its whole-directory link; a new machine mints a different ID. Tailscale likewise enrolls each new machine as a distinct device and reapplies reviewed local preferences without copying node identity or a mutable plist.

The minimal `bootstrap-arm` target has no agenix or Home Manager and explicitly disables remote builders, because it has no decrypted builder SSH key. Authorized SSH access to private flake inputs is still a prerequisite before evaluation. Full hosts keep their existing builder definitions. The read-only checker reports missing sources, conflicts, access, and live secret state without installing or authenticating anything.

## Consequences

Repository evaluation and builds can be verified before a physical new Mac exists, but they do not prove activation, decryption, tailnet enrollment, authentication, or service restoration. The new-machine runbook records those as separate live acceptance steps. The source workstation must resolve existing target conflicts and preserve its Mori identity before adopting the new file ownership. Secret edits require re-encryption and decrypt-to-comparison verification, not plaintext Git source.
