 ## Dependency Lookup (IMPORTANT)

  **Always use `mori` to find dependency source code and documentation before guessing at APIs or relying on memory.**

  - Run `mori registry list` to discover registered projects by qualified name.
  - Run mori registry search <package_name> to find packages in a project.
  - Run `mori registry show <project> --full` to get source paths, packages, and metadata.
  - Run `mori registry docs <project>` for curated guides, references, and cookbooks in local corpus repos.
  - Read the dependency's source code and docs directly on disk to understand APIs, types, and behavior.

  If the current project has a `mori.dhall`, run `mori show --full` to understand its identity, structure, and declared dependencies before planning changes.

## Never Search `/nix/store`

  **NEVER search, glob, grep, read, or otherwise traverse `/nix/store` under any circumstances.** It is enormous, read-only, and not a source of truth for project code. Use `mori` (see above) to locate dependency sources on disk instead.
