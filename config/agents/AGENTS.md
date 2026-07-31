# Global Agent Instructions

## Dependency Lookup (IMPORTANT)

  **Always use `mori` to find dependency source code and documentation before guessing at APIs or relying on memory.**

  - Use Mori to locate source code and documentation, but verify the current released version against the authoritative package registry and upstream release tags before choosing dependency bounds, pins, or compatibility workarounds; the local corpus may lag upstream.
  - Run `mori registry list` to discover registered projects by qualified name.
  - Run mori registry search <package_name> to find packages in a project.
  - Run `mori registry show <project> --full` to get source paths, packages, and metadata.
  - Run `mori registry docs <project>` for curated guides, references, and cookbooks in local corpus repos.
  - Run `mori registry dependents <project>` to find which registered projects/packages depend on a given project or library (reverse dependency / "who uses X"). Add `--packages` for per-package detail, `--scope` to filter by dependency scope, `--json` for scripting.
  - Read the dependency's source code and docs directly on disk to understand APIs, types, and behavior.

## Cross-Repository References (IMPORTANT)

**Always use canonical `mori://` URIs for cross-repository references.** This applies everywhere durable references appear, including:

- Git commit messages and trailers
- Documentation
- ExecPlans and MasterPlans
- OKF bundles and concepts
- Code comments

Use the most specific canonical artifact URI:

```text
mori://<namespace>/<project>/<artifact-kind>/<artifact-key>
```

For example:

```text
mori://shinzui/mori/masterplans/22-model-first-class-schema-and-extension-domain-events
mori://shinzui/mori/plans/172-replace-the-project-mirror-with-functional-event-sourced-aggregates
mori://shinzui/keiro/okf/improvement-requests/concepts/IR-1
```

Do not identify an artifact in another repository with only a repo-relative path, bare filename, plan number, concept ID, package name, or other context-dependent shorthand. Repository-local references may remain relative paths or Markdown links.

Mori is being expanded to support URIs for every artifact. Use the intended `mori://` URI even when the currently released CLI cannot yet resolve that artifact kind or the local registry is behind the producing repository. A current resolution failure is not a reason to write an ambiguous path instead. If the intended artifact URI shape is not yet defined, use the canonical project URI together with the project-relative path and state that the artifact-level URI is pending; never use the path alone.

Use `mori registry list`, `mori registry search`, `mori registry show --full`, and `mori registry docs` to discover the owning project's qualified name, artifacts, and current URI conventions. Verify a reference with `mori path <mori-uri>` when possible, while recognizing that resolution may depend on ongoing Mori URI coverage work or refreshed registry data.

## Never Search `/nix/store`

  **NEVER search, glob, grep, read, or otherwise traverse `/nix/store` under any circumstances.** It is enormous, read-only, and not a source of truth for project code. Use `mori` (see above) to locate dependency sources on disk instead.

## Never Search `/`

  **NEVER search, glob, grep, read, or otherwise traverse the filesystem root `/` under any circumstances.** It is enormous and not a source of truth for project code. Scope searches to the current project directory (or another specific path) and use `mori` (see above) to locate dependency sources on disk instead.

## Git Commits

  **Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for all commit messages.** Use types like `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, etc., optionally with a scope (e.g. `feat(parser): ...`) and a `!` or `BREAKING CHANGE:` footer for breaking changes.

## Git Branches

  **Do not create feature branches by default.** Commit directly to the current branch unless the user explicitly asks for a new branch.
