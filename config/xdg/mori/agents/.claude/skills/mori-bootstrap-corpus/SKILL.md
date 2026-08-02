---
name: mori-bootstrap-corpus
version: "0.1.0"
description: >
  Bootstrap a complete corpus project from a repo name — initializes git, adds upstream
  subtrees, writes mori.dhall and Justfile, validates, registers, and optionally sets up
  cookbook and documentation entries.
  TRIGGER when: user wants to create a corpus project, wrap upstream repos as subtrees,
  or set up a third-party code reading workspace.
argument-hint: <repo-name>
user-invocable: true
---

# Bootstrap Corpus Project

You are helping the user bootstrap a **corpus project** end-to-end. The user provides a
repo name (or GitHub owner/repo) and you handle everything: git init, subtree adds,
mori.dhall, Justfile, validation, registration, and optional enrichment (cookbook,
documentation entries).

Unlike `mori agent bootstrap --corpus` (which is interactive and step-by-step), this
skill drives the full process autonomously given just a repo name.


## What a corpus project is

A corpus project wraps one or more third-party upstream repositories as git subtrees,
providing a unified workspace for reading, learning from, or building adapters around
external code.

- **Mechanism**: `git subtree add` (never `--squash`) — full history preserved
- **Identity**: Registered via `mori register --local` so other projects can declare
  dependencies and agents can resolve its filesystem path via `mori deps locate`

### Directory layout

```
<corpus-dir>/                     # Named after the upstream ecosystem
  .git/                           # Git repo with subtree history
  mori.dhall                      # Project config (mk-form: Schema.Project::{ … })
  Justfile                        # Subtree management recipes
  mori/                           # Optional extensions
    cookbook.dhall                 # Classified code examples (optional)
  <subtree-1>/                    # First upstream repo (full source)
  <subtree-2>/                    # Second upstream repo
```


## Corpus conventions

These are corpus-specific conventions — for general schema types and records, use
`mori schema print` and `mori help schema-records`.

| Field         | Corpus convention                                           |
|---------------|-------------------------------------------------------------|
| `name`        | Upstream repo name (NOT suffixed with `-project`)           |
| `namespace`   | Upstream GitHub owner/org                                   |
| `owners`      | Same as `namespace` — the upstream owner                    |
| `origin`      | `Schema.Origin.ThirdParty` (read-only) or `Vendored`       |
| `description` | `Some "Corpus: <ecosystem> libraries"`                      |
| `type`        | Usually `Schema.PackageType.Library`                        |

Each subtree gets **both** a `Repo` entry (with `github` and `localPath`) and a matching
`Package` entry (with the same `path`). Packages in a corpus typically have
`runtime = { deployable = False, exposesApi = False }` and empty dependency/config lists.


## Critical rules

1. **Use `Schema.Project::{}` record completion** — since plan 5,
   every `schema/records/*.dhall` (and `Project.dhall`) exports a
   `{ Input, Type, default, mk }` bundle. The idiomatic form is
   `Schema.Project::{ project = Schema.ProjectIdentity::{ … },
   repos = [ Schema.Repo::{ … } ], packages = [ Schema.Package::{ … } ] }`,
   skipping any top-level field whose value would be the default
   (`bundles`, `dependencies`, `apis`, `agents`, `skills`,
   `subagents`, `standards`, `docs`, `templates` all default to
   empty lists).
2. **Only the required Input fields are mandatory** — for the root
   `Schema.Project`, only `project` is required (everything else
   has a default). For each nested bundle, see the Input record on
   `schema/records/<Name>.dhall` for what must be supplied.
   **Important:** `Schema.ProjectIdentity` is unusual — its `Input`
   includes `lifecycle`, which has no default. Every
   `Schema.ProjectIdentity::{ … }` must write
   `lifecycle = Schema.Lifecycle.Active` (or `Maintained`,
   `Deprecated`, etc.) explicitly, or `mori validate` will fail with
   `missing field lifecycle`.
3. **Schema prefix required** — use `Schema.PackageType.Library` not `PackageType.Library`.
4. **Never type out empty lists or default-valued fields.** The
   whole point of `Schema.<Name>::{ … }` is that the bundle's
   `default` supplies every unset field. Writing `packages = [] :
   List Schema.Package`, `docs = [] : List Schema.DocRef`, or any
   similar empty-list annotation is both a type error (bundles are
   no longer bare types) and contrary to the idiom. Omit the
   field; the default supplies it. The same rule applies to
   `description = None Text`, `localPath = None Text`, and every
   other optional that defaults to absent.
5. **No `--squash`** — full history is needed so agents can see what changed upstream.
6. **Detect default branch** — run `git ls-remote --symref <url> HEAD`. Do NOT assume
   `main` — many repos use `master`.
7. **No `mori init`** — write `mori.dhall` directly. `mori init` creates a regular project
   skeleton that does not match corpus layout.
8. **Initial commit required** — `git subtree add` needs at least one commit.
   Use `git commit --allow-empty -m "Initial commit"` for fresh repos.
9. **Respect user's branch** — do NOT rename the user's branch.


## Complete mori.dhall example

Get the current schema commit and hashes by running `mori schema pin`. Sample
output:

```text
commit:                <commit>
main schema hash:      sha256:<schema-hash>
agent-plans hash:      sha256:<agent-plans-hash>
```

Use the commit in the URL and the `main schema hash` value (after `sha256:`)
in the `let Schema = …` header below.

```dhall
let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/<commit>/package.dhall
        sha256:<hash>

in  Schema.Project::{
    , project = Schema.ProjectIdentity::{
      , name = "hasql"
      , namespace = "nikita-volkov"
      , type = Schema.PackageType.Library
      , description = Some "Corpus: hasql ecosystem libraries"
      , language = Schema.Language.Haskell
      , lifecycle = Schema.Lifecycle.Active
      , domains = [ "database" ]
      , owners = [ "nikita-volkov" ]
      , origin = Schema.Origin.ThirdParty
      }
    , repos =
      [ Schema.Repo::{
        , name = "hasql"
        , github = Some "nikita-volkov/hasql"
        , localPath = Some "hasql"
        }
      , Schema.Repo::{
        , name = "hasql-pool"
        , github = Some "nikita-volkov/hasql-pool"
        , localPath = Some "hasql-pool"
        }
      ]
    , packages =
      [ Schema.Package::{
        , name = "hasql"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "hasql"
        , description = Some "PostgreSQL driver"
        }
      , Schema.Package::{
        , name = "hasql-pool"
        , type = Schema.PackageType.Library
        , language = Schema.Language.Haskell
        , path = Some "hasql-pool"
        , description = Some "Connection pool for hasql"
        }
      ]
    }
```


## Justfile template

For each upstream repo, generate pull/push/log recipes using the branch detected via
`git ls-remote --symref` (never hardcode `main`).

```just
# List available recipes
default:
    @just --list

# Pull latest changes from upstream hasql
pull-hasql:
    git subtree pull --prefix=hasql https://github.com/nikita-volkov/hasql.git master

# Push local changes to upstream hasql
push-hasql:
    git subtree push --prefix=hasql https://github.com/nikita-volkov/hasql.git master

# Show what changed upstream for hasql
log-hasql:
    git fetch https://github.com/nikita-volkov/hasql.git master
    git log --oneline FETCH_HEAD

# Pull all upstream repos
pull-all: pull-hasql pull-hasql-pool
```


## Optional enrichment

### Cookbook

If the upstream repos contain useful code examples or patterns,
create `mori/cookbook.dhall`. Use the `cookbook-config` skill for
the full field reference, or run `mori cookbook print-schema`.

```dhall
let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/<commit>/package.dhall
        sha256:<hash>

let Cookbook =
      https://raw.githubusercontent.com/shinzui/mori-schema/<commit>/extensions/cookbook/package.dhall
        sha256:<hash>

in  Cookbook.CookbookCatalog::{
    , entries =
      [ Cookbook.CookbookEntry::{
        , key = "connection-example"
        , title = "How to establish a hasql connection"
        , contentType = Cookbook.ContentType.SampleCode
        , topics = [ Cookbook.Topic.Database ]
        , packages = [ "hasql" ]
        , language = Schema.Language.Haskell
        , audience = Schema.DocAudience.User
        , location = Schema.DocLocation.RepoPath "hasql/test/Main.hs"
        , description = Some "Shows basic connection setup and query execution"
        }
      ]
    }
```

### Project-level docs

Add DocRef entries to the top-level `docs` field for augmented documentation. Use
`mori help schema-records` for the full DocRef type.

```dhall
    , docs =
      [ Schema.DocRef::{
        , key = "pool-sizing-guide"
        , kind = Schema.DocKind.Guide
        , audience = Schema.DocAudience.User
        , description = Some "Team guidance on hasql connection pool sizing"
        , location = Schema.DocLocation.LocalFile "docs/pool-sizing.md"
        }
      ]
```


## How to help the user

### Bootstrapping a corpus (primary workflow)

The user provides a repo name (e.g., `hasql`, `nikita-volkov/hasql`). Drive the process:

1. **Parse the input** — determine the GitHub owner and repo name(s):
   - If given `owner/repo`, use directly
   - If given just a repo name, ask for the GitHub owner/org
   - Ask if there are additional related repos to include (e.g., `hasql` + `hasql-pool`)

2. **Create the project directory** — named `<repo>-project` (e.g., `hasql-project`).
   Ask the user where to create it or use a sensible default.

3. **Initialize git**:
   ```bash
   git init && git commit --allow-empty -m "Initial commit"
   ```

4. **Detect default branches** — for each upstream repo:
   ```bash
   git ls-remote --symref https://github.com/<owner>/<repo>.git HEAD
   ```

5. **Add subtrees** — for each upstream repo (no `--squash`):
   ```bash
   git subtree add --prefix=<repo> https://github.com/<owner>/<repo>.git <branch>
   ```

6. **Detect language** — inspect subtree contents for build files
   (`*.cabal` → Haskell, `package.json` → TS/JS, `Cargo.toml` → Rust, etc.)

7. **Read package metadata** — extract descriptions from upstream config files
   (`.cabal`, `package.json`, `Cargo.toml`) for `Package.description` fields

8. **Get the current schema commit and hashes** via `mori schema pin`
   (not `mori schema print`, which prints the type reference). Use the
   `commit` and `main schema hash` lines from its output in the
   `let Schema = …` header.

9. **Write mori.dhall** — `Schema.Project::{ … }` mk form, supplying only
   the fields you need to override, following the corpus conventions and
   complete example above

10. **Write Justfile** — subtree management recipes per repo plus `pull-all`

11. **Validate**: `mori validate`

12. **Register**: `mori register --local`

13. **Commit**: `git add mori.dhall Justfile && git commit -m "Add mori.dhall and Justfile"`

14. **Optional enrichment** — ask the user about cookbook entries, documentation, domain tags

15. **Verify**: `mori show --full` and `mori registry show <namespace>/<name>`

### Adding repos to an existing corpus

1. Read the current `mori.dhall`
2. Detect default branch via `git ls-remote --symref`
3. `git subtree add --prefix=<repo> <url> <branch>`
4. Add `Repo` + `Package` entries to `mori.dhall`
5. Add Justfile recipes for the new repo
6. `mori validate` then `mori register --local`

### Debugging

- **Validation fails** → common causes: missing required Input field
  (most often `lifecycle` on `Schema.ProjectIdentity`), wrong Schema
  prefix (use `Schema.PackageType.Library`, not `PackageType.Library`),
  wrong record name (`Schema.Repo` not `Schema.Repository`,
  `Schema.DocRef` not `Schema.DocReference`).
- **Validation fails with `Wrong type of function argument — Type vs { … : … }`**
  → you wrote an empty list annotation as `List Schema.<Record>` when
  the correct type is `List Schema.<Record>.Type`. `Schema.<Record>`
  is the `{ Input, Type, default, mk }` bundle, not a type. Easier
  fix: drop the empty field entirely and let completion supply the
  default (per Rule 4).
- **Subtree add fails** → ensure at least one commit exists in the repo
- **Branch detection fails** → check the GitHub URL is correct and repo is public
- **Dependency resolution fails** → ensure corpus is registered (`mori registry list`)
