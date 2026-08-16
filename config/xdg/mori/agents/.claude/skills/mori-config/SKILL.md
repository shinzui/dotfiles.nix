---
name: mori-config
version: "0.3.1"
description: >
  Help author, validate, and edit mori.dhall project configuration files. Covers project
  identity, packages, dependencies, repositories, documentation, skills, and subagents.
  TRIGGER when: user wants to create, edit, or understand their mori.dhall config.
argument-hint: [create|edit|validate]
user-invocable: true
---

# Mori Config Skill

You are helping the user author, edit, and validate a `mori.dhall` project configuration
for the mori project identity system.


## What mori.dhall does

Every mori-managed project has a `mori.dhall` at its root. It declares the project's
identity: name, namespace, language, packages, dependencies, documentation, and optional
AI agent configuration. This config is the source of truth for `mori show`, `mori register`,
dependency resolution, and automation.


## Getting the schema reference

Always use these commands to get the current schema — do NOT guess at field names or types:

```bash
mori schema print                      # Full schema type reference
mori schema print --category types     # Union types only
mori schema print --category records   # Record types only
mori help schema-records               # Annotated record type reference
mori help schema-types                 # Annotated union type reference
mori help project-config               # Root Project type reference
mori help schema-modification          # Guidance on editing mori.dhall
```


## Minimal valid config

```dhall
let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/<commit>/package.dhall
        sha256:<hash>

in  Schema.Project::{
    , project = Schema.ProjectIdentity::{
      , namespace = "myorg"
      , name = "my-project"
      , type = Schema.PackageType.Application
      , language = Schema.Language.Haskell
      , lifecycle = Schema.Lifecycle.Active
      }
    }
```

The `Schema.Project::{ ... }` and `Schema.ProjectIdentity::{ ... }` syntax
uses Dhall defaults — only override fields you need. Every list-valued
field on `Schema.Project` (`repos`, `packages`, `bundles`, `dependencies`,
`dependencyRefs`, `apis`, `agents`, `skills`, `subagents`, `standards`,
`standardRefs`, `docs`, `templates`) defaults to empty, so omit the lines
you do not need.


## Key sections

### Project identity

The identity block is the inner `project = Schema.ProjectIdentity::{ … }`
field on `Schema.Project`. Required Input fields are `name`, `namespace`,
`type`, `language`, `lifecycle`; everything else has a default.

```dhall
, project = Schema.ProjectIdentity::{
  , namespace   = "myorg"                       -- organizational grouping
  , name        = "my-project"                  -- project name (unique within namespace)
  , type        = Schema.PackageType.Library    -- Library, Application, Service, Tool, etc.
  , language    = Schema.Language.Haskell       -- primary language
  , lifecycle   = Schema.Lifecycle.Active       -- Active, Deprecated, Experimental, Archived
  , description = Some "What this project does" -- optional; omit to use the default `None Text`
  }
```

### Repos

```dhall
, repos =
    [ Schema.Repo::{
      , name = "my-project"
      , github = Some "myorg/my-project"
      , localPath = Some "/path/to/local/checkout"
      }
    ]
```

### Packages

`Schema.Package` requires `name`, `type`, `language` on its Input. Every
other field (including `dependencies`, `docs`, `config`, `visibility`)
has a default.

```dhall
, packages =
    [ Schema.Package::{
      , name = "my-lib"
      , type = Schema.PackageType.Library
      , language = Schema.Language.Haskell
      , path = Some "my-lib/"
      }
    , Schema.Package::{
      , name = "my-cli"
      , type = Schema.PackageType.Executable
      , language = Schema.Language.Haskell
      , path = Some "my-cli/"
      }
    ]
```

### Dependencies

`Project.dependencies` is a `List Text` — dependencies resolved by
name via the local registry:

```dhall
, dependencies = [ "hasql", "effectful", "streamly" ]
```

A name resolves to a project and, when the name identifies one, to a
specific **package** inside it. A bare name that matches packages in
exactly one project resolves to that package; `namespace/name:package`
says so explicitly and fails loudly when the target declares no such
package. Keep that grain — collapsing several packages of one project
into a single project-grained entry is what makes
`mori registry dependents 'ns/name:pkg'` answer about everyone instead
of the right subset. `mori deps explain <name>` prints which rule fired.

A bare name matching more than one registered project is an error, not a
coin flip: qualify it as `namespace/name`.

For fine-grained control over a single dependency (local augmentation,
path overrides, scope, version constraints), declare it on a `Package`
using the `Schema.Dependency` union type's `WithAugmentation`
constructor:

```dhall
, packages =
    [ Schema.Package::{
      , name = "my-lib"
      , type = Schema.PackageType.Library
      , language = Schema.Language.Haskell
      , dependencies =
          [ Schema.Dependency.ByName "effectful"
          , Schema.Dependency.WithAugmentation
              { name = "hasql"
              , extraDocs = [] : List Schema.DocRef.Type
              , localPathOverride = None Text
              , kind = Some Schema.DependencyKind.ThirdParty
              , source = Some Schema.DependencySource.Hackage
              , scope = Some Schema.DependencyScope.Regular
              , versionConstraint = Some ">=2.2 && <2.3"
              }
          ]
      }
    ]
```

`WithAugmentation` is a union alternative, not a `::{ … }` bundle — it has
no defaults, so **all seven fields are mandatory**. Write
`versionConstraint = None Text` when there is no bound. A config written
against the older five- or six-field shape no longer type-checks.

A `versionConstraint` is opaque to mori: it validates only that the value
is non-blank and single-line, then stores and displays it. Mori never
parses a range or picks a version, so copy the ecosystem's own syntax
verbatim (`>=2.2 && <2.3`, `^18.2`) rather than normalizing it.

Use `mori registry list` to find registered dependencies.

### Typed references

Fields that name another project have typed `MoriRef` companions
alongside the older text form. Singular fields take the suffix `Ref`,
list fields `Refs`:

```dhall
, dependencies = [ "hasql" ]
, dependencyRefs =
    [ Schema.MoriRef::{ namespace = "shinzui", name = "hasql" } ]
```

A `dependencyRef` may also name one **package** of the target project —
the only kind accepted there:

```dhall
, dependencyRefs =
    [ Schema.MoriRef::{
      , namespace = "acme"
      , name = "auth-service"
      , kind = Some Schema.MoriArtifactKind.Package
      , key = Some "auth-core"
      }
    ]
```

`standardRefs` must stay project-root refs, so `kind` and `key` keep
their `None` defaults there.

The same pattern covers `standardRefs`, `Api.ownerRef`,
`ApiDependency.packageRef`, `ApiSource.projectRef`, tech-radar
`projectRef`, and the DDD link companions (`subdomainRef`, `contextRef`,
`upstreamRef`, `downstreamRef`). DDD companions use the corresponding
`DddSubdomain` or `DddContext` kind and must target the declaring
project. When both a companion and its untyped sibling are present they
must agree, or validation fails.

Canonical-string surfaces such as `DocLocation.Canonical` and tech-radar
`project` accept only a full `mori://` URI. Prefer the typed arm
(`DocLocation.CanonicalRef`) when no nested sub-key is needed.

A `Fork` or `Vendored` project can also name what it tracks:

```dhall
, project = Schema.ProjectIdentity::{
  , name = "hasql"
  , namespace = "acme"
  , type = Schema.PackageType.Library
  , language = Schema.Language.Haskell
  , lifecycle = Schema.Lifecycle.Active
  , origin = Schema.Origin.Vendored
  , upstream = Some Schema.MoriRef::{ namespace = "shinzui", name = "hasql" }
  }
```

`Repo.upstream` does the same per repository when one project vendors
several sources. An `upstream` on an `Own` or `ThirdParty` project is
kept but warns — it is meaningful only for `Fork` and `Vendored`. An
upstream that is not registered locally warns rather than failing
`mori validate --check-refs`, since it may live outside this registry.

### Documentation

```dhall
, docs =
    [ Schema.DocRef::{
      , key = "api-reference"
      , kind = Schema.DocKind.Reference
      , audience = Schema.DocAudience.User
      , description = Some "Main API reference"
      , location = Schema.DocLocation.Url "https://docs.example.com/api"
      }
    ]
```

### Skills and subagents (optional)

```dhall
, skills =
    [ Schema.Skill::{
      , name = "my-skill"
      , description = "What this skill does"
      }
    ]
, subagents =
    [ Schema.Subagent::{
      , name = "test-runner"
      , description = "Runs project tests"
      , provider = Some "claude-code"
      , model = Some "sonnet"
      }
    ]
```

### Extensions

Mori supports per-project extension config files alongside
`mori.dhall`:

- `mori/tech-radar.dhall` — technology recommendations per
  language/category. Use the `TechRadar.TechRadar::{
  recommendations = [ TechRadar.Recommendation::{ … } ] }` idiom.
  Run `mori help extensions` for the template.
- `mori/cookbook.dhall` — classified code examples, patterns, and
  guides. Use `Cookbook.CookbookCatalog::{ entries =
  [ Cookbook.CookbookEntry::{ … } ] }`. The `cookbook-config` skill
  (`mori kit install cookbook-config`) has the full schema and a
  complete example. `mori help cookbook` shows the same.

`mori schema migrate` handles **one file per invocation**; `--file` selects it and
defaults to `mori.dhall`. To migrate an extension file, point it there explicitly:

```bash
mori schema migrate --apply --file mori/tech-radar.dhall
```

`mori registry upgrade-schema` is the sweep that walks every registered local
project *and* its extension files in one pass.


## How to help the user

**Creating a new config:**
1. Run `mori init` to create the skeleton
2. Ask about project identity (name, namespace, language, type)
3. Ask about packages the project publishes
4. Check `mori registry list` for available dependencies
5. Fill in repositories, docs, and optional sections
6. Validate: `mori validate`
7. Register: `mori register --local`

**Editing an existing config:**
1. Read the current `mori.dhall`
2. Run `mori schema print` for the schema reference
3. Make the requested changes using correct Dhall syntax
4. Validate: `mori validate`

**Common validation errors:**
- Missing required fields → check `mori help schema-records` for required vs optional
- Wrong enum value → check `mori help schema-types` for valid constructors
- Dependency not found → check `mori registry list` and ensure the dep is registered
- `unknown-package` → a `project:package` name whose target declares no such package.
  Mori lists the packages it does declare; fix the name, or add the missing `Package`
  entry to the target's own `mori.dhall`
- `ambiguous-project` / `ambiguous-package` → a bare name matched more than one
  registered project. Qualify it as `namespace/name`
- A typed companion disagrees with its untyped sibling → make the two name the same
  thing, or drop one
- Schema version mismatch → run `mori schema upgrade` to update the schema import

**Dhall syntax tips:**
- `=` for record fields, `,` to separate them
- `//` for record merge (override defaults)
- `Some value` for optional present, `None Type` for optional absent
- `Schema.Type::{ field = value }` uses defaults for unspecified fields
- Enums: `Schema.Language.Haskell`, `Schema.PackageType.Library`, etc.
