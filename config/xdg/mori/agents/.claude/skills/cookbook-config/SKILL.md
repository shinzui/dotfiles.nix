---
name: cookbook-config
description: >
  Help author, validate, and edit mori/cookbook.dhall cookbook extension catalogs. Covers
  entry fields, content types, topics, imports, and validation rules. TRIGGER when: user
  wants to create, edit, or validate their mori/cookbook.dhall config.
argument-hint: [create|edit|validate]
user-invocable: true
---

# Cookbook Config Skill

You are helping the user author, edit, and validate a `mori/cookbook.dhall` cookbook catalog
for the mori extension system.


## What mori/cookbook.dhall does

The cookbook extension catalogs a project's code examples, step-by-step instructions,
reusable patterns, configuration templates, and scaffolding templates as structured metadata.
Each entry describes one resource with its content type, domain topics, related packages,
language, audience, and file location. This metadata powers three things: local browsing via
`mori cookbook list` and `mori cookbook show`, cross-project querying via
`mori extension query cookbook`, and agent context enrichment (agents receive the catalog
as structured data so they can recommend relevant resources).


## File location and imports

The file lives at `mori/cookbook.dhall` relative to the project root. It must produce a
record with a single field `entries` containing a list of cookbook entries.

Every cookbook.dhall needs these imports:

```dhall
let Mori = ../schema/package.dhall

let ContentType = ../schema/extensions/cookbook/ContentType.dhall

let Topic = ../schema/extensions/cookbook/Topic.dhall

in  { entries =
      [ -- entries go here
      ]
    }
```

`Mori` re-exports core types: `Mori.Language`, `Mori.DocAudience`, `Mori.DocLocation`.
`ContentType` and `Topic` are cookbook-specific enums imported from the extension schema.


## Entry fields

Each entry in the `entries` list is a Dhall record with these fields:

### key (Text, required)

Unique identifier for this entry within the catalog. Use kebab-case (e.g., `"event-sourcing-patterns"`). Duplicate keys cause a validation error.

### title (Text, required)

Human-readable title. Cannot be empty. Prefer task-oriented phrasing: "How to X" or verb-first (e.g., "Event Sourcing Patterns with Message-DB").

### contentType (ContentType, required)

What form the content takes. One of:

- `ContentType.SampleCode` — runnable or copy-pasteable code examples
- `ContentType.Instructions` — step-by-step procedures to follow
- `ContentType.Pattern` — reusable design or code patterns to adapt
- `ContentType.Configuration` — config file templates or environment setup
- `ContentType.Template` — project or file scaffolding templates
- `ContentType.Other "custom"` — escape hatch for custom types

### topics (List Topic, required)

Domain areas this entry covers. **Must have at least one topic** — an empty list causes a
validation error. Multiple topics are allowed. Values:

- `Topic.Database`
- `Topic.API`
- `Topic.Testing`
- `Topic.ErrorHandling`
- `Topic.Deployment`
- `Topic.Security`
- `Topic.Performance`
- `Topic.Streaming`
- `Topic.Effects`
- `Topic.Migration`
- `Topic.Observability`
- `Topic.Other "custom"` — escape hatch for custom topics

### packages (List Text, required)

Related libraries or tools this entry uses (e.g., `["hasql", "hasql-pool"]`). Can be an
empty list `[] : List Text` if no specific packages apply.

### language (Language, required)

Target language or tool. Accessed via `Mori.Language.X`:

`Haskell`, `TypeScript`, `JavaScript`, `Python`, `Go`, `Rust`, `Java`, `Kotlin`, `Swift`,
`Ruby`, `Elixir`, `Clojure`, `Scala`, `Dhall`, `Nix`, `SQL`, `Shell`, `Other "custom"`

### audience (DocAudience, required)

Who this entry is for. Accessed via `Mori.DocAudience.X`:

- `Module` — module/library developers
- `User` — end users of the API/library
- `API` — API consumers
- `Internal` — internal team members
- `Other "custom"` — escape hatch

### location (DocLocation, required)

Where the cookbook file lives. Accessed via `Mori.DocLocation.X`:

- `LocalFile "path"` — relative path to a file from project root
- `LocalDir "path"` — relative path to a directory
- `RepoPath "path"` — path within a repo (for wrapper projects)
- `Url "https://..."` — external URL

### description (Optional Text, optional)

Brief summary. Use `Some "text"` to provide a description, or `None Text` to omit it.


## Complete example

```dhall
let Mori = ../schema/package.dhall

let ContentType = ../schema/extensions/cookbook/ContentType.dhall

let Topic = ../schema/extensions/cookbook/Topic.dhall

in  { entries =
      [ { key = "event-sourcing-patterns"
        , title = "Event Sourcing Patterns with Message-DB"
        , contentType = ContentType.SampleCode
        , topics = [ Topic.Database, Topic.Streaming ]
        , packages = [ "message-db-hs", "tan-event-source" ]
        , language = Mori.Language.Haskell
        , audience = Mori.DocAudience.Module
        , location = Mori.DocLocation.LocalFile "docs/event-sourcing.md"
        , description = Some "Event types, stream naming, projections, and subscriptions"
        }
      , { key = "cli-command-pattern"
        , title = "How to Add a CLI Command"
        , contentType = ContentType.Instructions
        , topics = [ Topic.API ]
        , packages = [ "optparse-applicative" ]
        , language = Mori.Language.Haskell
        , audience = Mori.DocAudience.Module
        , location = Mori.DocLocation.LocalFile "docs/architecture/CLI.md"
        , description = Some "Step-by-step guide to creating a new CLI command"
        }
      , { key = "nix-dev-setup"
        , title = "Development Environment Setup"
        , contentType = ContentType.Configuration
        , topics = [ Topic.Deployment ]
        , packages = [] : List Text
        , language = Mori.Language.Nix
        , audience = Mori.DocAudience.User
        , location = Mori.DocLocation.LocalFile "docs/dev-setup.md"
        , description = None Text
        }
      ]
    }
```


## Validation rules

The cookbook loader validates entries at load time during `mori register` and `mori cookbook list`.
All three rules must pass or the entire catalog is rejected:

1. **No duplicate keys** — every `key` must be unique within the catalog.
   Error: `Duplicate cookbook key: <key>`

2. **Non-empty topics** — every entry must have at least one topic in its `topics` list.
   Error: `Cookbook entry '<key>' has no topics`

3. **Non-empty title** — every entry must have a non-empty `title`.
   Error: `Cookbook entry '<key>' has an empty title`


## How to help the user

**Creating a cookbook from scratch:**
1. Check if `mori/cookbook.dhall` already exists — if so, read it first
2. Ask what resources the user wants to catalog (code examples, guides, patterns, configs)
3. For each resource, determine the content type, topics, related packages, and file location
4. Write `mori/cookbook.dhall` with the correct imports and entries
5. Validate: `mori cookbook list` (should display entries without errors)
6. Optionally register: `mori register` to push to the registry for cross-project querying

**Editing an existing cookbook:**
1. Read the current `mori/cookbook.dhall`
2. Make the requested changes (add entries, update fields, remove entries)
3. Validate: `mori cookbook list`
4. If registered, re-register: `mori register`

**Common mistakes and fixes:**
- **Empty topics list** — most common error. Always include at least one `Topic.*` value.
- **Wrong Optional syntax** — use `Some "text"` (not bare `"text"`) for description, and `None Text` (not `None`) to omit.
- **Duplicate keys** — each entry needs a unique `key`. Check existing entries before adding.
- **String instead of enum** — use `ContentType.SampleCode` (not `"SampleCode"`), `Topic.Database` (not `"Database"`).
- **Wrong import paths** — imports must use `../schema/` (relative from the `mori/` subdirectory up to project root, then into `schema/`).
- **Empty packages list without type annotation** — use `[] : List Text` (not bare `[]`) for an empty packages list, since Dhall needs the type annotation.


## CLI commands for verification

```bash
# Print the cookbook extension Dhall schema (types, entry fields, etc.)
mori cookbook print-schema

# List all entries (validates the file)
mori cookbook list

# Filter by content type, topic, package, or language
mori cookbook list --content-type sample-code
mori cookbook list --topic database
mori cookbook list --package hasql
mori cookbook list --language haskell

# Show full details of a single entry
mori cookbook show event-sourcing-patterns

# Register to push extension data to the event store
mori register

# Query cookbook data across all registered projects
mori extension query cookbook
mori extension query cookbook --topic database
mori extension query cookbook --content-type pattern
```
