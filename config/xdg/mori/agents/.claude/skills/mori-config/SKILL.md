---
name: mori-config
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
`apis`, `agents`, `skills`, `subagents`, `standards`, `docs`, `templates`)
defaults to empty, so omit the lines you do not need.


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

For fine-grained control over a single dependency (local augmentation,
path overrides), declare it on a `Package` using the
`Schema.Dependency` union type's `WithAugmentation` constructor:

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
              }
          ]
      }
    ]
```

Use `mori registry list` to find registered dependencies.

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

Extension files are migrated alongside `mori.dhall` when you run
`mori schema migrate --apply` or `mori registry upgrade-schema`.


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
- Schema version mismatch → run `mori schema upgrade` to update the schema import

**Dhall syntax tips:**
- `=` for record fields, `,` to separate them
- `//` for record merge (override defaults)
- `Some value` for optional present, `None Type` for optional absent
- `Schema.Type::{ field = value }` uses defaults for unspecified fields
- Enums: `Schema.Language.Haskell`, `Schema.PackageType.Library`, etc.
