---
name: keiro-ddd-bootstrap
version: "0.2.0"
description: >
  Bootstrap a project's mori DDD extension model (mori/ddd.dhall) from the keiro-dsl
  definition of a service built on the keiro runtime. Inventories the service's
  .keiro-workspace and .keiro specs (aggregates, commands, events, states, guards,
  domain outcomes, processes, routers, workflows, integration contracts, intakes,
  emits), reads the prose the DSL cannot hold (spec comments, hole modules, docs,
  hand-written Haskell coordination), and maps all of it onto subdomains, bounded
  contexts, aggregates, reactors, process managers, durable workflows, context
  mappings, message flows, and a glossary, recording the evidence behind every value
  and flagging every inference for review.
  TRIGGER when: user wants to create, seed, bootstrap, or refresh mori/ddd.dhall for a
  keiro service, or asks to "derive the DDD model from the keiro DSL/specs".
argument-hint: [project-path]
user-invocable: true
---

# keiro-dsl → mori DDD Bootstrap

You are drafting the `mori/ddd.dhall` for a service built on the keiro runtime. Most of
the draft comes from the service's keiro-dsl specs, and the rest comes from the prose
around them. The aim is **as much as the evidence supports, and no more**. Every value
you write is either:

- **extracted**: copied or mechanically renamed from a DSL node, or
- **evidenced**: a paraphrase of prose found in spec comments, hole-module Haddocks,
  docs, or ADRs, or
- **inferred**: your judgment. You **mark** it for review and never present it as fact.

The keiro-dsl is implementation evidence and not the domain model. `mori help ddd` says
it plainly: "Keiro is implementation evidence; terms such as 'awakeable' do not enter
Mori's portable schema." So translate keiro vocabulary into business and DDD language.
Don't transcribe keiro node kinds into DDD kinds one for one.

```bash
mori help ddd                  # full schema, validation rules, query surfaces
mori help ddd-decomposition    # splitting one model across Dhall files
mori ddd print-schema          # the schema the running binary validates against
mori schema pin                # commit + ddd hash + main schema hash to import
```


## Step 0 — Preflight

```bash
cd <project-path>
cat mori.dhall                          # identity, description, packages, runtime package
ls mori/ddd.dhall mori/ddd/ 2>/dev/null # existing model? → merge mode (see below)
mori schema pin                         # commit, ddd hash, main schema hash
```

- **An existing `mori/ddd.dhall` switches you to merge mode.** Never regenerate over
  it. See [Merge mode](#merge-mode-an-existing-mori-ddd-dhall).
- The `mori/ddd.dhall` import must use the **same mori-schema commit** as `mori.dhall`
  and the running binary. If `mori.dhall` is pinned to a different commit than
  `mori schema pin` reports, stop and tell the user to run `mori schema migrate --apply`
  first. Otherwise the file you write will not validate, and neither will
  `mori agent bootstrap-ddd` later.
- Find out whether this is a keiro service at all. The quickest check is whether any
  file matches `**/*.keiro-workspace` or `**/*.keiro`. If nothing does, the service
  uses keiro only through hand-written Haskell. The Haskell scan in Step 1 still
  applies, but tell the user the model will be much thinner.


## Step 1 — Inventory the keiro-dsl definition

### Where the DSL lives

keiro-dsl is a standalone textual language with two file kinds:

| File | Role |
|------|------|
| `domain/<service>.keiro-workspace` | Manifest (canonical location). Its `service`, `layout`, `runtime-package`, and `spec <path>` lines define the service graph. |
| `*.keiro` | One spec. It starts with an optional preamble (`language keiro-dsl N`, `context <ns>`, `module <Root>`, `layout …`), followed by column-0 nodes. |

The workspace's `spec` lines are **the** authoritative member set. A `.keiro` file that
no manifest lists is **not** part of the service. Scratch copies under `.tmp/`,
design-time sketches such as `kdsl/*.keiro`, `test-fixtures/`, and backups do not count
unless the user says otherwise. When there is no manifest (for example, jitsurei's
`services/<svc>/spec/` layout), every `.keiro` file outside those directories is read,
one service per directory.

### Run the bundled inventory

`scripts/keiro_inventory.py` sits next to this `SKILL.md`. It reads the specs as source
text, which keeps the `#` comments. Those comments carry the domain rationale that
`keiro-dsl parse` drops.

```bash
python3 <dir-of-this-SKILL.md>/scripts/keiro_inventory.py . --summary   # read this first
python3 <dir-of-this-SKILL.md>/scripts/keiro_inventory.py . > "$SCRATCH/keiro-inventory.json"
python3 <dir-of-this-SKILL.md>/scripts/keiro_inventory.py --workspace domain/svc.keiro-workspace
```

For each spec, the JSON gives you the following. Every node carries its `line` and the
`doc` comment block directly above it.

- **Aggregates:** states (initial first, `terminalStates` from `!`), registers,
  commands, events (with `retiring`/`deprecated` and a version), `domainOutcomes`, and
  every transition. A transition carries `from`, `command`, `guard`, `guardKind`,
  `outcome`, `emits`, `to`, `implementationHole`, and the `note` comment above it. Each
  aggregate also has `businessGuards`, `rejections`, and `isSaga`.
- **Processes:** the runtime name, inputs, `correlate`, `saga` and its category, the
  target, handlers (advances, dispatches, schedules, cancels, and `when` guards), and
  timers (`fireAt`, what they fire, the dead letter).
- **Routers:** input, key, `resolve`, target, and the `dispatch-each` command.
- **Workflows:** runtime name, `in`/`out`, the id derivation, and `step`, `await`,
  `sleep`, `child`, `patch`, and `continueAsNew`.
- **Operations:** `command`, `query`, `signal`, and `run`.
- **Integration:** `contract` (topic aliases → literal topic names, events), `intake`
  (accepted events), `emit` (source, key, and the state → contract-event map), and
  `publisher`.
- **Queues and reads:** `workqueue`, `dispatch`, `readmodel`, and catalog nodes.
- **Vocabulary:** `id`, `enum` (with constructors), `rule`, and `mapped`.
- **Outside the specs:** `haskellCoordination` lists non-generated, non-test Haskell
  modules that import `Keiro.ProcessManager`, `.Router`, `.Workflow`, `.Timer`, `.PGMQ`,
  `.Inbox`, or `.Outbox`. `holeModules` lists `Holes.hs`, `BehaviorHoles.hs`, and
  `ProcessHoles.hs`.
- **`notes`:** non-member specs and missing members.

Two classifications the script makes for you:

- `guardKind: "identity"` marks a guard whose every conjunct is `cmd.x == reg.y` (or
  `!=`). These pin a command to its own stream, for example "same project id, same
  content hash". They are **not** business invariants. Mention the count, not the
  expressions.
- `isSaga: true` marks an aggregate named by some process's `saga` clause. It is
  **process-manager state, not a domain aggregate** (see Step 3).

The script is a line-oriented reader that relies on column-0 layout, not the keiro-dsl
parser. If a spec reports `unknown` top-level lines, read that region of the file by
hand.

### Optional: confirm with the real toolchain

`keiro-dsl` normally runs only inside the keiro nix dev shell. It is
`<keiro>/keiro-dsl/bin/keiro-dsl` (find `<keiro>` with
`mori registry show shinzui/keiro --full`). When it works, it gives you ground truth:

```bash
keiro-dsl check domain/<svc>.keiro-workspace --emit                       # merged canonical service
keiro-dsl behavior-obligations domain/<svc>.keiro-workspace --format=json # state × command matrix
```

Outside the dev shell, the cabal plan usually fails to resolve. Don't burn time fixing
the build. The inventory script is enough for extraction.

### Language versions

| Preamble | Meaning for extraction |
|----------|------------------------|
| none | Legacy unversioned (effective 1). |
| `language keiro-dsl 5` | Stable. May declare `domain-outcomes` and `outcome rejected E.X` / `no-op E.X` on transitions. |
| `language keiro-dsl 6` | Candidate. A process may carry `reactions version N` with `on X when <guard> … otherwise no-action`, `schedule … once`, and `cancel`. |


## Step 2 — Read what the DSL cannot hold

The DSL has **no description clause**. Meaning lives elsewhere, so read in this order
and stop when you have enough:

1. **Spec comments.** The file `headerDoc`, each node's `doc`, and each transition's
   `note`. In rei and kotei these are rich business prose.
2. **Hole modules** from `holeModules`. A transition marked `implementation hole` runs
   hand-written logic in `<Concept>/Holes.hs` or `BehaviorHoles.hs`, usually with a
   Haddock explaining the rule. This is where most invariants the DSL cannot express
   live: cross-field rules, uniqueness, and anything a scalar guard can't say.
3. **Hand-written coordination** from `haskellCoordination`. Many services declare no
   process, router, or workflow nodes at all. rei, for example, keeps its reactors in
   `Rei.Modules.<X>.Reactor.*`, and mori keeps its routers in
   `Mori/Modules/*/Subscription/*` and `Mori/Automation/*Router.hs`. Read each module's
   header and handler to learn what it consumes, what it emits, and whether it owns
   state or timers.
4. **Project docs.** `README.md`, `docs/` (ADRs, architecture notes, plans), and
   `mori.dhall`'s `description` and `docs`. `mori registry docs <ns>/<project>` lists the
   curated ones.
5. **Neighbouring services.** For integration edges, run the inventory on the other end
   (Step 3, *Mappings*). `mori registry dependents shinzui/keiro` lists every registered
   keiro consumer. `mori ddd search --project <ns>/<name>` and `mori ddd map` show which
   of them already have a DDD model whose context keys you can reference.

keiro modelling guidance, useful for classifying what you find:
`mori://shinzui/keiro-runtime-patterns/docs/messaging-process-managers`,
`mori://shinzui/keiro-runtime-patterns/docs/keiro-durable-workflows`, and the
runtime-patterns `architecture/domain-design.md`. Resolve these with `mori path` or
`mori registry docs shinzui/keiro-runtime-patterns`.


## Step 3 — Map the DSL onto the DDD model

### Mapping at a glance

| keiro-dsl | DDD record | Grade |
|-----------|-----------|-------|
| workspace `service`, spec `context` | `BoundedContext` (key, name) | extracted, but check the name (below) |
| — | `domain`, `Subdomain`, context `purpose` | evidenced from docs, else inferred |
| `aggregate` (not a saga) | `Aggregate` | extracted |
| `command` / `event` names | `Aggregate.commands` / `.events` | extracted |
| business `guard`, `outcome rejected/no-op`, terminal `!` states, hole Haddocks | `Aggregate.invariants` | evidenced, phrased in business language |
| `router` | `Reactor` | extracted + evidenced |
| `process` + its `saga` aggregate + `timer` | `ProcessManager` | extracted + evidenced; policy fields often inferred |
| `workflow` + `operation … signal/run` | `DurableWorkflow` | extracted (steps, waits) + inferred (policies) |
| hand-written `Keiro.Router` / `Keiro.ProcessManager` / `Keiro.Workflow` modules | `Reactor` / `ProcessManager` / `DurableWorkflow` | evidenced from code |
| `contract` + `emit`/`publisher` (outbound), `intake` (inbound) | `ContextMapping` (PublishedLanguage), `MessageFlow` steps | extracted edges; the counterpart is evidenced |
| `operation command/query` | flow entry steps | extracted |
| `id`, `enum`, aggregate and state names, rejection names | `GlossaryTerm` candidates | term extracted; definition must be evidenced |
| `readmodel`, catalog nodes, `workqueue`, `dispatch`, `mapped`, `wire`, `snapshot` | none (implementation detail) | mention in `implementation` text or omit |

### Domain, subdomains, contexts

- **Bounded context.** Default to one context per keiro service or workspace, with
  `key` = the workspace `service` name in kebab-case. The spec `context` is a
  code-generation namespace. Sometimes it is a business name (`hospital-capacity`), and
  sometimes it is plumbing (`context modules` in rei and mori). Never use a plumbing
  namespace as a context name. Split into several contexts only when the docs describe
  separate models, or when the specs declare several distinct business `context`
  values with separate vocabularies. Say which you did and why.
- `purpose` comes from the README or mori.dhall `description`, rewritten as one or two
  business sentences. `status`: omit it (Active) unless the docs say the service is
  emerging or being sunset.
- **Subdomains and `domain`** are never in the DSL. Propose them from the docs:
  usually one subdomain per service, sometimes one per cluster of aggregates. Mark
  `kind` (Core / Supporting / Generic) and `evolution` as inferred unless a doc states
  them. If the evidence is thin, write one subdomain and say so. Don't invent a
  taxonomy.

### Aggregates

For each aggregate where `isSaga` is false:

- `key` = kebab-case name (`ActionRun` → `action-run`). `name` = the aggregate name
  with spaces added (`Action Run`). `context` = the context key. Add
  `contextRef = Some Schema.MoriRef::{ namespace, name, kind = Some Schema.MoriArtifactKind.DddContext, key = Some "<context>" }`
  **only** if the file imports `Schema` (see Step 4).
- `commands` = every `command` name, and `events` = every `event` name, in spec order.
  Keep retiring and deprecated events; they still exist in streams. Note them in a
  comment.
- `description` comes from the node `doc`, and otherwise from the concept's Haddock.
  If neither exists, omit it. Don't paraphrase the states list as a description.
- `invariants` are **business statements**, one rule each, never a guard expression.
  Derive them from:
  - **business guards** (`businessGuards`). For example,
    `divertStatus != TotalDivert || lifeCriticalOverride` becomes "A transfer
    reservation cannot be held at a hospital on total divert unless the patient's case
    is life-critical."
  - **named rejections** (`rejections`, `outcome rejected E.X`). For example,
    `FocusRejection.FocusNotFound` on `NotCreated -- UpdateFocus` becomes "A focus must
    exist before it can be updated or retired." `no-op` outcomes state idempotency:
    "Creating a focus that already exists changes nothing."
  - **terminal states**, for example "A completed action run accepts no further
    commands". Include this only when it matters to the business. Skip it for trivial
    lifecycles.
  - **transition `note` comments and hole-module Haddocks.** These are often the
    richest source.
  - Leave out identity-only guards. If they are the only rule, say "commands are pinned
    to their stream identity" in the report, not in `invariants`.
- `size` and `throughputPerDay`: omit. Nothing in the DSL measures them. Suggest them
  in the report only if the user asks.
- **"Workflow"-named aggregates are still aggregates.** mori's `Workflow` aggregate,
  for instance, is an event-sourced aggregate. If it also coordinates other
  aggregates, record it as an aggregate **and** propose a ProcessManager for its
  coordination role. Follow the decision ladder, not the name.

### Coordination: apply the decision ladder

`mori help ddd` defines three kinds. Choose by behaviour, never by keiro type name:

1. **Reactor.** Stateless, idempotent, reacts to one event, and owns no durable state or
   timers.
2. **ProcessManager.** One correlated instance owns durable state. It reacts by issuing
   commands and may own timers, retries, dead-lettering, and repair.
3. **DurableWorkflow.** A versioned definition resumes an imperative continuation from a
   journal across named steps, waits, and timers.

`mori validate` enforces these rules. Violating one fails the load:

- A reactor's `trigger` must be an **Event** and must also appear in `consumes`.
  `actions` must not be empty. `ownsDurableState` and `ownsTimers` must be `False`.
- `context` must be a local context key. Each `participants` entry must be a local
  context key or have a typed `participantRefs` companion. Each `flows` entry must be a
  local flow key or have a `flowRefs` companion.
- Every required Text field must be non-blank. For a process manager, `durableState`
  and `correlationKeys` must be non-empty. For a workflow, `steps` must be non-empty.
  Step, wait, and timer keys must be unique.

**`router` → Reactor.**

| Field | Source |
|-------|--------|
| `key` / `name` | Runtime `name "…"` (already kebab-case), else the node name. |
| `trigger`, `consumes` | The router's `input`. If the input record names an integration event (for example, accepted from an `intake`), use that event name. Otherwise use the input name. Kind `Event`. |
| `emits` | One `Command` per `dispatch-each`. |
| `actions` | For example, "Dispatch RequestTransferReservation to each resolved Reservation". Mention the `resolve … via read-model X` lookup. |
| `idempotencyStrategy` | From `dispatch-id strategy=uuidv5 from=(…)`: "Deterministic command id (uuidv5 of name, key, source event id, target stream, occurrence); duplicates are acknowledged." |
| `implementation` | `"keiro-dsl router <Name> (<spec>:<line>)"`. |
| `participants` | The target aggregate's context, if it isn't this context. |

A router that `resolve`s through a read model is still stateless from the domain's point
of view.

**`process` → ProcessManager.**

| Field | Source |
|-------|--------|
| `key` / `name` | Runtime `name`. |
| `durableState` | The **saga aggregate's registers** (`isSaga` true). You can also add its state names ("lifecycle: Waiting → Scheduled → Fired"). Do **not** also list the saga as an Aggregate. |
| `correlationKeys` | The field in `correlate input.<field> via …`. |
| `correlationRule` | The `correlate` clause in words: "One instance per actionRunId". |
| `transactionBoundary` | "The saga advance, its follow-up dispatch/schedule/cancel intents, and the source event's checkpoint commit in one append". This is keiro's process transaction; Language 6 says so explicitly. Mark it inferred for Language ≤5. |
| `consumes` | Each `input` or `on X` (Event). |
| `emits` | Each `dispatch Agg@… Cmd` and each timer's `fire dispatch …` (Command). Leave out the saga's own `advance` commands; they are internal. |
| `timers` | One per `timer`: `key` = the timer name, `name` = spaced words, `deadline` = the `fireAt` expression in words ("5 minutes after the observed tick"), `emits` = the command it fires. |
| `idempotencyStrategy` | From `dispatch-id`, as for routers. |
| `retryPolicy` | From `on-failed Retry`, `on-ambiguous Retry`, and timer `max-attempts N`. |
| `deadLetterPolicy` | From `rejected => halt`, `poison => halt`, and timer `dead-letter "…"`. |
| `repairProcedure` | Not in the DSL. Look in the ProcessHoles module and the docs. If nothing is there, write the most specific evidenced statement you can and mark it inferred. |
| `replayEvidence` | "Instance state is rebuilt from the saga stream (category `<category>`)". |
| `implementation` | The keiro-dsl process plus the `ProcessHoles` module path. |
| `participants` | The target's context, if it is remote. |

**`workflow` → DurableWorkflow.**

| Field | Source |
|-------|--------|
| `key` | Kebab-case node name. |
| `name` | Spaced words. |
| `definitionId` | Runtime `name "…"`. |
| `definitionVersion` | `"1"` unless `patch` ids exist. In that case list them in `versioningPolicy` and mark the version inferred. |
| `journal` | `name` = `"wf:<runtime-name>"`, `persistence` = "keiro event store (PostgreSQL), one stream per workflow instance". Omit `retention` unless the docs state it. |
| `steps` | One per `step` **and** per `child`, in order. `key` = label, `name` = spaced label. Put the result type in `description` ("returns ProfileResolution"). For `child`, the description is "starts child workflow …". `idempotencyStrategy` = "Result journaled under the step label; replay returns the recorded result without re-running". Steps are at-least-once, so mark the strategy inferred unless the hole module shows how side effects are deduplicated. |
| `externalWaits` | One per `await`: `callbackIdentity` = "workflow id + wait label", `wakeSource` = the `operation … signal <label> of <Workflow>` that delivers it, else inferred. Keep the word "awakeable" out. |
| `timers` | One per `sleep` (`deadline` from `after <field>`). |
| `wakeSources` | The signal operations and timers. |
| `progressMechanisms` | `["journaled step completion"]`, plus `"continue-as-new"` when present. |
| `consumes` / `emits` | Only when evidenced (the `in` type is usually a job, not an event). |
| `terminalPolicy`, `replayEvidence`, `recoveryProcedure` | Required Text that the DSL never states. Write the narrowest keiro-true statement, for example "Completion is recorded once in the journal; a finished instance is not resumed". Mark each inferred. |

**Hand-written coordination.** Classify each module from `haskellCoordination` with the
decision ladder after reading it:

- Anything that imports `Keiro.Router` and keeps no state is a Reactor.
- A `Keiro.ProcessManager` import plus a saga or state stream plus timers makes a
  ProcessManager.
- `inbox`/`outbox` imports are integration edges, not coordinators. `queue` imports are
  work handlers. Model a queue handler only if it is a real domain reaction.
- `implementation` = the module name.

Don't create a record for a module you haven't read. List unread modules as candidates
in the report.

### Context mappings and message flows

These come from the integration nodes, which are the only cross-context facts the DSL
holds.

- **Outbound.** `emit` → `publisher` on `contract C` with topic literal `T` means this
  context publishes a **PublishedLanguage**. The downstream side is whoever has an
  `intake` for `T`. Find it by running the inventory on other keiro services and
  matching topic literals (`contracts[].topics` values).
- **Inbound.** `intake` of contract topic `T` means this context is downstream. The
  upstream side is the service that `emit`s `T`. Its `bind source from header` and
  `emit … source "…"` value often names it directly, as in `source "shinzui/kotei"`.
  The downstream stance is usually **Conformist** when the contract is consumed
  verbatim, and **AnticorruptionLayer** when an intake handler or hole translates it
  into local commands. Read the handler before choosing, and mark the choice inferred.
- **Counterpart endpoint.**
  - If the counterpart has a registered DDD model (`mori ddd search --project <ns>/<n>`),
    use its context key plus a typed `upstreamRef`/`downstreamRef` (kind `DddContext`).
  - Otherwise use the counterpart project URI as text (`"mori://shinzui/kotei"`), as
    keiei does. Never guess a context key for a project that has no model.
  - If you cannot identify the counterpart, record the mapping with the topic name as
    the endpoint (`"kafka:kotei.forge.webhook.v1"`) and flag it.
- `teamRelationship` and `notes`: put the topic and contract name in `notes`. Omit
  `teamRelationship` unless the docs describe the teams.

**Message flows** narrate end-to-end chains the evidence actually shows. Each step is
`{ order, message, kind, from, to }`. `from` and `to` are actors, context keys, or
external systems. The chain to trace is:

```
operation/intake event ─▶ router/process ─▶ Command ─▶ aggregate ─▶ Event ─▶ emit contract event
```

Build one flow per distinct chain. Put field lists in `contents` when a contract event
names them. Link each coordinator to its flows (`flows = [ "<flow-key>" ]`). Don't build
flows from aggregates alone; a single command → event pair is already in the aggregate.

### Glossary

Candidate terms are aggregate names, business `enum` types (with the constructors as
the vocabulary), `id` types that name a domain concept, business state names, and
rejection names. `definition` is required, so **include a term only when you have an
evidenced definition** from a comment, a Haddock, or a doc. Scope it with `context`.
Record `aliases` when the DSL and the docs use different words for the same thing.
Every other candidate goes in the report as "terms needing definitions". Never write a
definition that just repeats the name ("Run: a run").

### Collaborators and verification

- `collaborators`: only from CODEOWNERS or docs that name owning teams. Otherwise omit.
- `verification`: include `Ddd.Verification::{ lastReviewed = Some "<today> (bootstrapped from keiro-dsl; not yet reviewed)", notes = Some "<counts of extracted/evidenced/inferred values; spec paths>" }`.
  Leave `coveragePercent` unset unless you measured it.


## Step 4 — Write mori/ddd.dhall

### Imports

```dhall
let Ddd =
      https://raw.githubusercontent.com/shinzui/mori-schema/<commit>/extensions/ddd/package.dhall
        sha256:<ddd hash>

let Schema =   -- only when you use MoriRef companions
      https://raw.githubusercontent.com/shinzui/mori-schema/<commit>/package.dhall
        sha256:<main schema hash>
```

Take `<commit>` and both hashes from `mori schema pin`. Use relative imports
(`../schema/extensions/ddd/package.dhall`) only in a repo that vendors the schema, as
mori itself does.

### Shape and provenance

- Use the `Ddd.<Record>::{ … }` completion form everywhere.
- Use `let` bindings for any `CoordinationMessage` used more than once and for a shared
  `contextRef`.
- Put a **Dhall comment on every record** naming its evidence, and put a `-- REVIEW:`
  comment on every inferred value. The comments stay in the file and never reach the
  registry. That is the point: the registry holds clean prose, and the file shows
  where each claim came from.
- If the model has more than about 10 aggregates or more than 5 coordinators, split it
  per `mori help ddd-decomposition`: `mori/ddd/contexts.dhall`,
  `mori/ddd/<concept>-aggregates.dhall`, `mori/ddd/coordination.dhall`,
  `mori/ddd/flows.dhall`, `mori/ddd/glossary.dhall`. Pin every fragment to the same
  URL and hash.

```dhall
let Ddd =
      https://raw.githubusercontent.com/shinzui/mori-schema/<commit>/extensions/ddd/package.dhall
        sha256:<ddd hash>

let createActionRun =
      Ddd.CoordinationMessage::{ message = "CreateActionRun", kind = Ddd.MessageKind.Command }

in  Ddd.DddModel::{
    , domain = Some "Continuous Delivery"                 -- REVIEW: inferred from README
    , subdomains =
      [ Ddd.Subdomain::{
        , key = "delivery-automation"
        , name = "Delivery Automation"
        , kind = Ddd.SubdomainKind.Core                   -- REVIEW: inferred
        }
      ]
    , contexts =
      [ -- evidence: domain/kotei.keiro-workspace (service kotei); purpose from README.md
        Ddd.BoundedContext::{
        , key = "kotei"
        , name = "Kotei"
        , purpose = Some "Run pipelines, execute rules, and roll out deployments for forge changes."
        , subdomain = Some "delivery-automation"
        }
      ]
    , aggregates =
      [ -- evidence: domain/action-run.keiro:21 (aggregate ActionRun)
        Ddd.Aggregate::{
        , key = "action-run"
        , name = "Action Run"
        , context = Some "kotei"
        , commands =
          [ "CreateActionRun", "StartActionRun", "CompleteActionRun", "FailActionRun", "CancelActionRun" ]
        , events =
          [ "ActionRunCreated", "ActionRunStarted", "ActionRunSucceeded", "ActionRunFailed", "ActionRunCancelled" ]
        , invariants =
          [ "An action run can only be started while pending."        -- transitions Pending→Running
          , "A finished, failed, or cancelled action run accepts no further commands." -- terminal states
          ]
        }
      ]
    , processManagers =
      [ -- evidence: domain/action-run.keiro:76 (process ActionSchedule, saga ActionScheduleSaga)
        Ddd.ProcessManager::{
        , key = "action-schedule"
        , name = "Action schedule"
        , context = "kotei"
        , durableState = [ "actionRunId", "tickAt", "timerId", "lifecycle: Waiting → Scheduled → Fired" ]
        , correlationKeys = [ "actionRunId" ]
        , correlationRule = "One instance per action run id"
        , transactionBoundary = "Saga advance and its dispatch/schedule intents commit in one append"  -- REVIEW: inferred (Language 5)
        , idempotencyStrategy = "Deterministic uuidv5 command ids from process name, correlation id, source event id and emit index"
        , retryPolicy = "Retry failed dispatches; timer delivery retried up to 5 attempts"
        , deadLetterPolicy = "Halt on rejected or poison input; exhausted timers dead-letter to kotei.action_schedule.timer_exhausted"
        , repairProcedure = "Operator resumes the halted process after correcting the input"  -- REVIEW: inferred, not in DSL or docs
        , replayEvidence = "State is rebuilt from the actionSchedule saga stream"
        , consumes = [ Ddd.CoordinationMessage::{ message = "ActionScheduleInput", kind = Ddd.MessageKind.Event } ]
        , emits = [ createActionRun ]
        , timers =
          [ Ddd.CoordinationTimer::{
            , key = "action-schedule-follow-up"
            , name = "Action schedule follow-up"
            , deadline = "5 minutes after the observed tick"
            , emits = Ddd.CoordinationMessage::{ message = "MarkActionScheduleTimerFired", kind = Ddd.MessageKind.Command }
            }
          ]
        , implementation = Some "keiro-dsl process ActionSchedule; Kotei.ActionSchedule.ProcessHoles"
        }
      ]
    }
```


## Step 5 — Validate, then register with consent

```bash
mori ddd contexts && mori ddd aggregates     # loads and validates the composed model
mori ddd coordination                        # reactor / PM / workflow rules
mori ddd flows && mori ddd glossary
mori validate                                # whole project
mori validate --check-refs                   # every MoriRef companion resolves
```

A failure names the record and the rule (for example, "Reactor 'x' trigger must appear
in consumes"). Fix it and reload. Don't drop the record to make the error go away.

`mori register` projects the model into the shared registry. **Ask before running it.**
The draft is full of `REVIEW:` markers, and the user may want to review first. After
registering, check with `mori extension query ddd` and
`mori ddd search --project <ns>/<name>`.


## Step 6 — Report

End with a short report the user can act on:

1. **Sources read.** The workspace and spec count, the language versions, and the docs
   and hole modules consulted.
2. **What was modelled.** Counts per record kind, split into extracted, evidenced, and
   inferred values.
3. **Review list.** Every `-- REVIEW:` value, grouped by record, and the evidence that
   would settle it.
4. **Not modelled.** Unread Haskell coordination modules, glossary candidates without a
   definition, non-member specs, integration counterparts you couldn't identify, and
   DSL nodes with no DDD home (read models, work queues).
5. **Drift** (merge mode). See below.


## Merge mode: an existing mori/ddd.dhall

Human-authored prose is worth more than anything you can extract. So in merge mode:

- **Keep** every existing record, key, description, purpose, invariant, mapping,
  flow, and glossary definition. Don't reword them.
- **Add** records for DSL nodes with no counterpart. Match on key, or on the kebab-case
  name; `Run` matches `run`.
- **Complete** list fields where the DSL has more. Append missing `commands` and
  `events`, keeping the existing order.
- **Report drift** instead of fixing it silently. Drift covers:
  - commands or events in the model that no longer exist in the specs, which usually
    means a rename or removal
  - aggregates in the model with no spec, which may be planned or hand-written. keiei,
    for example, lists planned aggregates deliberately.
  - saga aggregates wrongly modelled as aggregates
  - coordinators whose DSL kind contradicts their DDD kind

  Ask before deleting anything.
- Keep the existing file layout (single file or decomposed) and its import style.


## Pitfalls

- **Treating `context modules` as a bounded context.** It is a code-generation
  namespace.
- **Listing saga aggregates as aggregates.** They are process-manager state.
- **Copying guard expressions into `invariants`.** Rephrase them as business rules,
  and leave out identity-only guards.
- **Inventing definitions, purposes, or subdomain kinds with no evidence.** Leave them
  out, or mark them `REVIEW:`.
- **Reading non-member specs** (`.tmp/`, `kdsl/` sketches, fixtures) as part of the
  service.
- **Assuming a service has no coordinators because its specs declare none.** Scan the
  Haskell code; rei and mori keep theirs there.
- **Letting keiro terms leak into portable fields.** Don't write awakeable, transducer,
  hole, or `pm:`/`wf:` prefixes into descriptions. Stream names in
  `journal.name`/`replayEvidence` are fine as identifiers.
- **Using a different schema commit** in `ddd.dhall` than in `mori.dhall`, or than the
  one in the binary.
- **Running `mori register`** without asking.

## Repository Dhall import boundary

Repository-controlled Dhall is sealed. Use relative imports that stay inside the evaluation
root, embedded mori-schema URLs, installed extension schema URLs, or other URLs with a Dhall
sha256 pin. Do not introduce env:, absolute, home-relative, out-of-root, missing, or custom-header
imports. Symbolic links must also stay inside the root. Run `mori validate` after edits and use
`mori help sealed-evaluation` to repair a refusal. Hash-pinned external imports can fetch on a
cache miss; the operator's own user config is outside this repository policy.
