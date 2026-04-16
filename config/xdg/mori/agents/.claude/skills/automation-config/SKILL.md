---
name: automation-config
description: >
  Help author, validate, and debug mori automation configurations (mori.automation.dhall).
  Covers event selectors, reactions, template interpolation, cross-repo signals, and
  execution policies. TRIGGER when: user wants to create or edit automation rules, debug
  why a reaction isn't firing, or design cross-repo workflows.
argument-hint: [create|debug|explain]
user-invocable: true
---

# Automation Config Skill

You are helping the user author, validate, and debug a `mori.automation.dhall` configuration
for the mori automation system.


## What mori automation does

Mori watches VCS events (commits, tags, branches, cross-repo signals) and runs reactions
when events match configured selectors. The config file is `mori.automation.dhall`.


## Top-level structure

```dhall
let Schema = (./mori.dhall).Schema

in  { events    = [ ... ] : List Schema.EventSelector
    , reactions = [ ... ] : List Schema.Reaction
    , execution = { allowLocal = True, allowCI = True, maxConcurrency = Some +4 }
    }
```


## Event Selectors

### ChangesetSelector — match commits

```dhall
Schema.EventSelector.ChangesetSelector
  { name            = "src-changes"
  , paths           = [ "src/**/*.hs" ]       -- glob patterns for changed files
  , branches        = [ "main", "develop" ]    -- branch name patterns
  , messagePatterns = [] : List Text           -- commit message patterns
  , trailerPatterns = [] : List { mapKey : Text, mapValue : Text }
  }
```

- Empty list = wildcard (matches everything)
- Multiple entries = OR logic (any match succeeds)
- `paths` uses glob: `*` = any filename, `**` = across directories
- `trailerPatterns` uses AND logic (all entries must match)

### RefSelector — match tags or branch creation

```dhall
Schema.EventSelector.RefSelector
  { name        = "release-tags"
  , refPatterns = [ "v*" ]
  , kinds       = [ "tag" ]       -- "tag" or "branch"
  }
```

### SignalSelector — match cross-repo signals

```dhall
Schema.EventSelector.SignalSelector
  { name           = "schema-updated"
  , signalTypes    = [ "SchemaChanged" ]
  , sourceProjects = [ "schema-repo" ]
  }
```


## Reactions

Bind selectors to actions:

```dhall
{ name    = "run-tests"
, on      = [ "src-changes", "test-changes" ]    -- selector names from events list
, actions = [ ... ]                               -- list of ReactionAction
}
```


## Reaction Actions

### RunCommand

```dhall
Schema.ReactionAction.RunCommand
  { command    = "cabal"
  , args       = [ "test", "all" ]
  , workingDir = None Text
  , timeout    = Some +300
  , env        = [] : List { mapKey : Text, mapValue : Text }
  }
```

### EmitEvent

```dhall
Schema.ReactionAction.EmitEvent
  { eventType  = "TestsPassed"
  , streamName = "ci-pipeline"
  , eventData  = [ { mapKey = "result", mapValue = "success" } ]
  }
```

### Notify — HTTP notification

```dhall
Schema.ReactionAction.Notify
  { url          = "https://hooks.example.com/notify"
  , method       = Some "POST"
  , headers      = [ { mapKey = "Authorization", mapValue = "Bearer token" } ]
  , bodyTemplate = Some "Build passed for commit {{changeset.id}}"
  }
```

### Schedule — delayed execution

```dhall
Schema.ReactionAction.Schedule
  { delaySeconds = +60
  , action = Schema.ScheduledAction.RunCommand
      { command = "deploy", args = [ "--env", "staging" ]
      , workingDir = None Text, timeout = Some +600
      , env = [] : List { mapKey : Text, mapValue : Text }
      }
  }
```

### Signal — cross-repo signal

```dhall
Schema.ReactionAction.Signal
  { signalType = "SchemaChanged"
  , targets    = [ "*dependents*" ]   -- or explicit project names
  , payload    = [ { mapKey = "file", mapValue = "openapi.yaml" } ]
  }
```

Use `"*dependents*"` to dynamically resolve all projects that depend on the current one.


## Template Interpolation

Action fields support `{{variable}}` syntax, expanded at trigger time.

**Changeset variables:**

    {{changeset.id}}              Commit hash
    {{changeset.subject}}         First line of commit message
    {{changeset.body}}            Full body text
    {{changeset.timestamp}}       ISO 8601 timestamp
    {{changeset.author.name}}     Author name
    {{changeset.author.email}}    Author email

**Trailer variables:**

    {{trailer.<Key>}}             e.g. {{trailer.Intention}}

**Ref variables:**

    {{ref.name}}                  Ref name (e.g. "v1.0")
    {{ref.target}}                Target object ID

**Signal variables:**

    {{signal.type}}               Signal type name
    {{signal.source}}             Source project name


## Execution Policy

```dhall
{ allowLocal     = True
, allowCI        = True
, maxConcurrency = Some +4    -- None = unlimited
}
```


## Trailer Matching

Git trailers are key-value pairs at the end of commit messages. Match them with:

```dhall
, trailerPatterns = [ { mapKey = "Deploy", mapValue = "staging" } ]
```

- All entries must match (AND logic)
- Values support glob: `{ mapKey = "Intention", mapValue = "*" }` = key must exist


## How to help the user

**Creating a config from scratch:**
1. Ask what events they want to react to (commits to certain paths? tags? signals?)
2. Ask what actions to run (command? notification? signal to other repos?)
3. Write the `mori.automation.dhall` with selectors, reactions, and execution policy
4. Validate: `dhall type-check < mori.automation.dhall`
5. Suggest: `mori automate inspect` to verify after ingesting events

**Debugging why a reaction isn't triggering:**
1. Check config loads: `mori automate inspect`
2. Check event matching: `mori automate explain <global_position>`
3. Verify selector patterns (paths, branches, trailers)
4. Check reaction `on` field references correct selector names
5. Check history: `mori reaction list --name <reaction-name>`

**Debugging a failed reaction:**
1. Find failures: `mori reaction list --status failed`
2. Get details: `mori reaction show <REACTION_ID>`
3. Common causes: command not found, timeout, non-zero exit, HTTP errors

**Designing cross-repo workflows:**
1. Identify source event and target repos
2. Write Signal action in source config
3. Write SignalSelector + reaction in target configs
4. Register both repos: `mori register --local && mori automate register`
5. Run daemon: `mori automate daemon`
6. Trace: `mori workflow list` and `mori workflow trace <ID>`
