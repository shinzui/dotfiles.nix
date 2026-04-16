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
mori schema print --for-agent   # Compact LLM-optimized reference
mori schema print               # Full schema type reference
mori help schema-records        # All Dhall record types
mori help schema-types          # All Dhall union types
mori help project-config        # Root Project type reference
mori help schema-modification   # Guidance on editing mori.dhall
```


## Minimal valid config

```dhall
let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/<commit>/package.dhall
        sha256:<hash>

in  Schema.Project::{
    , namespace = "myorg"
    , name = "my-project"
    , projectType = Schema.ProjectType.Application
    , language = Schema.Language.Haskell
    , lifecycle = Schema.Lifecycle.Active
    }
```

The `Schema.Project::{ ... }` syntax uses Dhall defaults — only override fields you need.


## Key sections

### Project identity

```dhall
, namespace   = "myorg"                     -- organizational grouping
, name        = "my-project"                -- project name (unique within namespace)
, projectType = Schema.ProjectType.Library  -- Library, Application, Service, Tool, Framework, Plugin
, language    = Schema.Language.Haskell     -- primary language
, lifecycle   = Schema.Lifecycle.Active     -- Active, Deprecated, Experimental, Archived
, description = Some "What this project does"
```

### Repositories

```dhall
, repositories =
    [ Schema.Repository::{
      , url = "https://github.com/myorg/my-project"
      , kind = Schema.RepositoryKind.Git
      , localPath = Some "/path/to/local/checkout"
      }
    ]
```

### Packages

```dhall
, packages =
    [ Schema.Package::{
      , name = "my-lib"
      , packageType = Schema.PackageType.Library
      , language = Schema.Language.Haskell
      , path = Some "my-lib/"
      }
    , Schema.Package::{
      , name = "my-cli"
      , packageType = Schema.PackageType.Executable
      , language = Schema.Language.Haskell
      , path = Some "my-cli/"
      }
    ]
```

### Dependencies

```dhall
, dependencies =
    [ Schema.Dependency::{
      , name = "some-dependency"
      , namespace = Some "myorg"      -- matches registry entry
      , source = Schema.DependencySource.Registry
      }
    ]
```

Use `mori registry list` to find available dependencies. Reference them by namespace/name.

### Documentation

```dhall
, documentation =
    [ Schema.DocReference::{
      , title = "API Reference"
      , url = "https://docs.example.com/api"
      , kind = Schema.DocKind.ApiReference
      }
    ]
```

### Skills and subagents (optional)

```dhall
, skills =
    [ Schema.Skill::{
      , name = "my-skill"
      , description = Some "What this skill does"
      }
    ]
, subagents =
    [ Schema.Subagent::{
      , name = "test-runner"
      , description = Some "Runs project tests"
      , provider = "claude"
      , model = Some "sonnet"
      }
    ]
```


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
2. Run `mori schema print --for-agent` for the schema reference
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
- Enums: `Schema.Language.Haskell`, `Schema.ProjectType.Library`, etc.
