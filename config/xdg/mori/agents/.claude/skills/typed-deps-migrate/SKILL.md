---
name: typed-deps-migrate
version: "0.1.0"
description: >
  Migrate a project's mori.dhall from untyped text dependencies to typed MoriRef
  companions, at the right grain — project-grained where the name means a whole project,
  package-grained where it means one package inside one. Also converts the remaining
  typed-reference companions in the same manifest and verifies the result against the
  registry.
  TRIGGER when: user wants to adopt typed dependencies, add dependencyRefs, migrate to
  typed references / MoriRef, fix a project-grained dependency that should name a
  package, or asks why `mori registry dependents` returns too many projects.
argument-hint: [audit|migrate|verify]
user-invocable: true
---

# Typed Dependency Migration

You are migrating a project's `mori.dhall` from untyped `Text` dependencies to typed
`MoriRef` companions, and correcting the *grain* of each dependency while you are in
there.

This is a registry-driven migration. You cannot do it by reading the manifest alone —
every decision depends on what the local registry knows about the target project.


## What this migration is for

Mori's manifest has carried two parallel ways to name another project for some time:

- **Untyped**: `dependencies = [ "hasql/hasql" ]` — a `List Text`, parsed by mori.
- **Typed**: `dependencyRefs = [ Schema.MoriRef::{ … } ]` — a `List MoriRef`, a real
  Dhall record.

The untyped field is not deprecated and still drives bare-name dependency resolution.
The typed companion is what newer surfaces read, and it is the only one that can carry
an artifact kind — which is what lets a dependency name **one package** of a
multi-package project rather than the whole thing.

Two things go wrong in a manifest written before typed references:

1. **No typed companions at all.** Everything is text, so nothing can express the
   package grain.
2. **Everything is project-grained.** `hasql`, `hasql-pool`, and `hasql-transaction`
   were all collapsed to `hasql/hasql`, because that used to be the only option. A
   project-grained entry is a strictly *wider* claim than the truth, and it is why
   `mori registry dependents 'hasql/hasql:hasql-pool'` reports every project that
   touches any part of hasql instead of the ones that actually use the pool.

Fixing the grain is the substance of this migration. Adding `dependencyRefs` is the
mechanical half.


## What `mori schema migrate` already does — do not redo it

Run the built-in migrator **first**. It is AST-based and offline, so it only populates
the two companions it can derive without consulting the registry:

| Companion | Populated from |
|-----------|----------------|
| `ApiSource.projectRef` | an existing `project` that is already an unambiguous `namespace/name` |
| tech-radar `projectRef` | an existing `project` that is already a project-root `mori://` URI |

`mori schema migrate` works on **one file per invocation** — `--file` selects it, and it
defaults to `mori.dhall`. The tech-radar rule therefore does nothing unless you point it
at the extension file:

```bash
mori schema migrate                                      # preview mori.dhall
mori schema migrate --apply                              # write mori.dhall
mori schema migrate --apply --file mori/tech-radar.dhall # the extension file
```

(`mori registry upgrade-schema` is the sweep that walks every registered local project
*and* its extension files. Use it when migrating a fleet; use `--file` for one repo.)

It will **not** populate `dependencyRefs`, `standardRefs`, `ownerRef`, `packageRef`,
`publisherRef`, or the DDD companions, and it will never change a dependency's grain.
Those all need registry lookups, which is why they are your job. An already-authored
companion is never overwritten by the migrator.


## The grain rules

A dependency name resolves to a project and, when the name identifies one, to a
specific **package** inside that project. Mori tries these rules in order:

| Resolution | The name | Resolves to |
|------------|----------|-------------|
| `qualified-project` | `namespace/name` matching a registered project | that project |
| `project` | a bare name matching exactly one project | that project |
| `package` | a bare name matching packages in exactly one project | that project **and** that package |
| `bundle` | a bare name matching a bundle | that project and the bundle's primary package |
| `qualified-package` | `project:package`, and the project declares it | that project **and** that package |
| `unknown-package` | `project:package`, but no such package | nothing — an error, exit non-zero |
| `ambiguous-project` | a bare name matching more than one project | nothing — an error |
| `ambiguous-package` | a bare name matching packages in more than one project | nothing — an error |
| `not-found` | nothing matched | nothing |

`mori deps explain <name> --json` is the tool that answers "which rule fired, and at
what grain". Its `packages` array is the **matched** set, which tells you the grain
directly:

```bash
$ mori deps explain kiroku --json
{"dependency":"kiroku","namespace":"shinzui","projectName":"kiroku",
 "packages":[{"name":"kiroku-cli",...},{"name":"kiroku-store",...}, ...8 entries],
 "resolution":"bare name matched exactly one project, shinzui/kiroku"}

$ mori deps explain kiroku-store --json
{"dependency":"kiroku-store","namespace":"shinzui","projectName":"kiroku",
 "packages":[{"name":"kiroku-store","language":"haskell","packageType":"library"}],
 "resolution":"bare name matched the package 'kiroku-store' of project shinzui/kiroku"}
```

Eight packages back means the name is the **project**. One package back, with a
`resolution` naming that package, means the name is a **package** — migrate it
package-grained.

A failure is loud and exits non-zero, which is the behavior you want:

```bash
$ mori deps explain 'shinzui/kiroku:nope' --json
Dependency 'shinzui/kiroku:nope' resolved to project shinzui/kiroku, which declares no package 'nope'.
Declared packages: kiroku-cli, kiroku-jitsurei, kiroku-metrics, kiroku-otel, kiroku-store, ...
```


## The MoriRef record

```dhall
Schema.MoriRef::{
, namespace = "shinzui"          -- required
, name      = "kiroku"           -- required
, kind      = None Schema.MoriArtifactKind   -- default; omit for a project-root ref
, key       = None Text                      -- default; omit for a project-root ref
, anchor    = None Text                      -- default; omit
}
```

Only `namespace` and `name` are on the Input. Omit anything equal to the default —
`mori schema migrate --apply` strips it on the next run.

`kind` and `key` are **set together or not at all**. A half-specified ref is a
validation error, not a project reference.

The two shapes you will write:

```dhall
-- project-root: the dependency is the whole project
Schema.MoriRef::{ namespace = "shinzui", name = "kiroku" }

-- package-grained: the dependency is one package of that project
Schema.MoriRef::{
, namespace = "shinzui"
, name = "kiroku"
, kind = Some Schema.MoriArtifactKind.Package
, key = Some "kiroku-store"
}
```


## Companion reference

Every untyped field that names something, its typed companion, and the constraint the
validator enforces. **Read the "Targets" column carefully** — it is the single most
common mistake in this migration.

| Untyped field | Companion | Allowed kind | Targets |
|---------------|-----------|--------------|---------|
| `Project.dependencies` | `dependencyRefs` | project-root **or** `Package` | the **dependency's** project |
| `Project.standards` | `standardRefs` | project-root only | the standard's project |
| `Api.owner` | `Api.ownerRef` | `Package` | the **declaring** project |
| `ApiDependency.package` | `packageRef` | `Package` | the **declaring** project |
| `ApiSource.project` | `projectRef` | project-root only | the source's project |
| `PinnedImport.publisher` | `publisherRef` | project-root only | the publisher's project |
| tech-radar `project` | `projectRef` | project-root only | the recommended project |
| ddd `BoundedContext.subdomain` | `subdomainRef` | `DddSubdomain` | the declaring project |
| ddd `Aggregate.context` | `contextRef` | `DddContext` | the declaring project |
| ddd `ContextMapping.upstream` | `upstreamRef` | `DddContext` | the declaring project |
| ddd `ContextMapping.downstream` | `downstreamRef` | `DddContext` | the declaring project |

**The trap.** `Api.owner` and `ApiDependency.package` hold a *package name from this
project* — not a project name. Their companions are `Package`-kind refs pointing at
**your own** namespace/name, with `key` set to one of your own declared packages:

```dhall
-- this project is acme/svc, and it declares a package named "svc-core"
, apis =
  [ Schema.Api::{
    , name = "orders"
    , type = Schema.ApiType.OpenAPI
    , specPath = "api/orders.yaml"
    , owner = "svc-core"
    , ownerRef = Some Schema.MoriRef::{
      , namespace = "acme"                     -- ← this project, not a dependency
      , name = "svc"
      , kind = Some Schema.MoriArtifactKind.Package
      , key = Some "svc-core"
      }
    }
  ]
```

`dependencyRefs` is the opposite: a `Package`-kind entry there names a package of the
**target** project, and no other kind is accepted.

Two more typed fields are not companions — they are typed outright, and both are
project-root only:

- `ProjectIdentity.upstream` — what a `Fork` or `Vendored` project tracks. Setting it
  on an `Own` or `ThirdParty` project is kept but warns.
- `Repo.upstream` — the same, per repository, when one project vendors several sources.

```dhall
, project = Schema.ProjectIdentity::{
  , namespace = "acme"
  , name = "hasql"
  , type = Schema.PackageType.Library
  , language = Schema.Language.Haskell
  , lifecycle = Schema.Lifecycle.Active
  , origin = Schema.Origin.Vendored
  , upstream = Some Schema.MoriRef::{ namespace = "hasql", name = "hasql" }
  }
```


## Package-level dependencies

`Package.dependencies` is a different type — `List Schema.Dependency`, a union, with no
typed-ref companion. It is where per-dependency detail lives, and its names follow the
same grain rules, so it needs the same correction:

```dhall
, packages =
  [ Schema.Package::{
    , name = "svc-core"
    , type = Schema.PackageType.Library
    , language = Schema.Language.Haskell
    , path = Some "svc-core"
    , dependencies =
      [ Schema.Dependency.ByName "shinzui/kiroku:kiroku-store"
      , Schema.Dependency.WithAugmentation
          { name = "hasql/hasql:hasql-pool"
          , extraDocs = [] : List Schema.DocRef.Type
          , localPathOverride = None Text
          , kind = Some Schema.DependencyKind.ThirdParty
          , source = Some Schema.DependencySource.Hackage
          , scope = Some Schema.DependencyScope.Regular
          , versionConstraint = Some ">=1.1 && <1.2"
          }
      ]
    }
  ]
```

`WithAugmentation` is a **union alternative, not a `::{ … }` bundle**. It has no
defaults, so all **seven** fields are mandatory — write `versionConstraint = None Text`
and `localPathOverride = None Text` rather than omitting them. This is the one place the
"never write empty lists or defaults" rule does not apply.

Field values:

- `kind` — `Schema.DependencyKind.Internal` (another package in this project) |
  `.ThirdParty` (external)
- `source` — `Schema.DependencySource.` one of `Hackage`, `Npm`, `PyPI`, `Crates`,
  `Maven`, `Nixpkgs`, `Flake`, `GitHub`, `GitLab`, `Git`, `Local`, or the open arm
  `Other "<freeform>"`. Note it is `Crates`, not `Cargo`.
- `scope` — `Schema.DependencyScope.` one of `Regular` (required at runtime, the
  default), `Dev` (tooling only), `Test` (test framework or fixture), `Build`
  (build-time only). `Test`-scoped deps are filtered out of agent context unless the
  user passes `--include-test-deps`.
- `versionConstraint` — opaque ecosystem-native text. Mori checks only that it is
  non-blank and single-line; it never parses, compares, or solves it. Copy the
  ecosystem's own syntax verbatim (`>=2.2 && <2.3`, `^18.2`).

Run `mori schema print --category types` for the current constructor lists if a value
is rejected.


## How to help the user

### Mode: audit (start here, always)

Do this before editing anything, and show the user the result before you touch the file.

1. **Read the manifest.**

   ```bash
   cat mori.dhall
   mori show --full
   ```

2. **Establish a clean baseline.** If these already fail, fix that first — you do not
   want to attribute a pre-existing failure to your migration.

   ```bash
   mori validate
   mori validate --check-deps
   mori validate --check-refs
   ```

3. **Run the built-in migrator** so you are not hand-writing what it can derive:

   ```bash
   mori schema migrate            # preview the diff
   mori schema migrate --apply
   ```

4. **Resolve every dependency name and record its grain.** For each entry in
   `Project.dependencies` and each `Package.dependencies` name:

   ```bash
   mori deps explain <name> --json
   ```

   Classify each into one of:

   - **Project-grained and correct** — `packages` lists many, `resolution` names the
     project. Companion is a project-root ref.
   - **Package-grained** — `packages` has one entry and `resolution` names that
     package. Companion sets `kind`/`key`; rewrite the untyped name as
     `namespace/name:package`.
   - **Over-collapsed** — the manifest says `hasql/hasql`, but the `.cabal`/
     `package.json`/`Cargo.toml` actually depends on `hasql-pool`. This is the case
     worth flagging: it resolves fine, so nothing has been complaining, but it is a
     wider claim than the truth. **Ask before splitting it** — you are changing what
     the manifest asserts, and the user may have meant the whole project.
   - **Broken** — `ambiguous-project`, `ambiguous-package`, `unknown-package`, or
     `not-found`. Report it; do not paper over it with a guess.

5. **Report before editing.** Show the user a table: each dependency, its current
   grain, its resolved grain, and what you propose. Get agreement on the
   over-collapsed ones.

### Mode: migrate

Edit in place. Preserve the `let Schema = …` header verbatim, the existing formatting,
and every field you are not changing.

1. **Add `dependencyRefs`** alongside the existing `dependencies`, one companion per
   entry, at the grain the audit established.

2. **Correct the untyped names too** where the grain changed —
   `"hasql/hasql"` → `"hasql/hasql:hasql-pool"`. The two fields are siblings; leaving
   the untyped one project-grained while the companion is package-grained is a
   disagreement.

3. **Do the same for `Package.dependencies`** — same grain, `ByName` or
   `WithAugmentation` as appropriate.

4. **Convert the remaining companions** in the same file — `standardRefs`, `ownerRef`,
   `packageRef`, `publisherRef` — per the companion table. Remember that `ownerRef` and
   `packageRef` target *this* project.

5. **Convert extension files** if present: `mori/tech-radar.dhall` (`projectRef`) and
   `mori/ddd.dhall` (`subdomainRef`, `contextRef`, `upstreamRef`, `downstreamRef`).

6. **Omit every default.** Do not write `kind = None Schema.MoriArtifactKind`,
   `anchor = None Text`, or `dependencyRefs = [] : List Schema.MoriRef.Type`. If the
   project has no dependencies, omit the field entirely.

A complete before/after for a project named `acme/svc`:

```dhall
-- BEFORE
in  Schema.Project::{
    , project = Schema.ProjectIdentity::{
      , namespace = "acme"
      , name = "svc"
      , type = Schema.PackageType.Application
      , language = Schema.Language.Haskell
      , lifecycle = Schema.Lifecycle.Active
      }
    , dependencies = [ "shinzui/kiroku", "hasql/hasql" ]
    }

-- AFTER: kiroku is used only for its store package; hasql is used whole
in  Schema.Project::{
    , project = Schema.ProjectIdentity::{
      , namespace = "acme"
      , name = "svc"
      , type = Schema.PackageType.Application
      , language = Schema.Language.Haskell
      , lifecycle = Schema.Lifecycle.Active
      }
    , dependencies = [ "shinzui/kiroku:kiroku-store", "hasql/hasql" ]
    , dependencyRefs =
      [ Schema.MoriRef::{
        , namespace = "shinzui"
        , name = "kiroku"
        , kind = Some Schema.MoriArtifactKind.Package
        , key = Some "kiroku-store"
        }
      , Schema.MoriRef::{ namespace = "hasql", name = "hasql" }
      ]
    }
```

### Mode: verify

```bash
mori validate                  # Dhall typecheck + structural rules
mori validate --check-deps     # every dependency name resolves
mori validate --check-refs     # every mori:// reference resolves; ✓ / ✗ / ⚠ per ref
mori deps resolve              # on-disk paths for every dependency
mori register --local          # publish the corrected identity
```

`mori validate` passing does **not** mean the names resolve — it only type-checks.
Always run `--check-deps` and `--check-refs` before registering.

After registering, confirm the grain actually took effect. This is the payoff, so
check it rather than assuming:

```bash
mori registry dependents 'shinzui/kiroku:kiroku-store' --packages   # should name this project
mori registry dependents 'shinzui/kiroku:kiroku-cli' --packages     # should NOT
mori registry relations --to shinzui/kiroku                         # typed-reference grain
```

`--check-refs` reports ✗ for a failure and ⚠ for a warning; warnings do not fail the
run. The one systematic downgrade is `upstream`: an upstream naming a project that is
not in this registry warns rather than fails, because it may legitimately live
elsewhere. Every other unresolvable ref is a ✗.


## Validation errors

Verbatim messages and what causes each:

| Message | Cause |
|---------|-------|
| `… must set kind and key together, or leave both absent for a project reference` | half-specified ref — you set `kind` without `key` or vice versa |
| `… must be a project-root reference with kind and key absent` | you set `kind`/`key` on a project-root-only field (`standardRefs`, `ApiSource.projectRef`, `publisherRef`, `upstream`) |
| `… may name a project or one of its packages; kind X is not supported here` | a `dependencyRef` with a kind other than `Package` |
| `… must use reference kind Package` | `ownerRef` or `packageRef` without `kind = Some …Package` |
| `… must target declaring project acme/svc, not other/thing` | `ownerRef`/`packageRef`/a DDD companion pointing at another project |
| `… disagrees with its untyped sibling: expected key 'x', got 'y'` | companion and untyped field name different things |
| `… names package 'x', which is not declared by this project` | `ownerRef`/`packageRef` key is not in this project's `packages` |
| `package 'p' dependency 'd' has an empty version constraint` | `versionConstraint = Some ""` — use `None Text` |
| `package 'p' dependency 'd' has a multi-line version constraint` | a newline in the constraint; mori holds one single-line value |
| `… declares apiSource project 'x' which is not in the project-level dependencies — add 'x' to dependencies or dependencyRefs` | an `apiSource` naming a project the manifest does not depend on |
| `Project.upstream is meaningful for Fork or Vendored origins, but this project is Own` | warning — `upstream` on a non-vendored project |
| `missing field scope` / `missing field extraDocs` / `missing field versionConstraint` | an incomplete `WithAugmentation`; all seven fields are mandatory |

Dhall-level errors:

- `Wrong type of function argument — Type vs { … : … }` → you wrote
  `List Schema.DocRef` where `List Schema.DocRef.Type` is required. `Schema.DocRef` is
  the `{ Input, Type, default, mk }` bundle, not a type. Same for
  `Schema.MoriRef` vs `Schema.MoriRef.Type`.
- An unknown `Schema.MoriArtifactKind.…` constructor → run
  `mori schema print --category types` for the current arm list.


## What this migration does not buy

Be honest with the user about the ceiling. A package-grained manifest gives a
*narrower* reverse-dependency answer, not a complete one:

- Resolution identifies the package a dependency **names**, not the modules it actually
  imports. A project that uses one module of a multi-package target still shows up in
  that target's project-grained blast radius.
- An unregistered dependent cannot appear at all, and a manifest that omits a real
  dependency produces a graph that is confidently wrong.
- Nothing keeps the manifest in sync afterwards. Mori will not notice when a `.cabal`
  file gains a dependency and `mori.dhall` does not. For Haskell projects, the
  `cabal-deps-sync` skill (`mori kit install cabal-deps-sync`) re-derives the mapping
  from the build files.
