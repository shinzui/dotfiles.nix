---
name: master-plan
description: >
  Create, implement, review, and manage master plans that decompose large initiatives into
  multiple coordinated ExecPlans with dependencies and integration points. TRIGGER when: user
  wants to plan a large initiative, coordinate multiple exec-plans, review a decomposition
  another model produced, or track multi-plan progress.
argument-hint: <create|implement|status|update|discuss|review> [plan-name-or-path]
user-invocable: true
---

# MasterPlan Skill

You are managing master plans (MasterPlans) — coordination documents that decompose large initiatives into multiple ExecPlans with defined dependencies and integration points. Before doing anything, read the full specifications:

- [MASTERPLAN.md](MASTERPLAN.md) — requirements for MasterPlan documents
- [ExecPlan specification](../exec-plan/PLANS.md) — requirements for child ExecPlan documents
- [ExecPlan skill](../exec-plan/SKILL.md) — the ExecPlan skeleton and implementation protocol

Follow all three to the letter.

MasterPlans live in the `docs/masterplans/` directory at the repository root. Each master plan is a single Markdown file named with a sequential number prefix followed by a slug derived from its title (e.g., `docs/masterplans/1-kafka-consumer-pipeline.md`). Each plan begins with a YAML frontmatter block — `id`, `slug`, `title`, `kind: master-plan`, `created_at`, optional `intention`, optional `provenance` — so tooling can identify it without parsing prose.

Create new MasterPlans with the bundled `init-masterplan.ts` script (see Mode: create). The script picks the next sequential number, derives the slug from the title, writes the frontmatter and skeleton, and refuses to overwrite an existing file. Record every later authorship event with the exec-plan skill's `record-provenance.ts` script (see Provenance). Do not pick numbers, write skeletons, or hand-author frontmatter by hand.

Child ExecPlans created by a MasterPlan live in `docs/plans/` following the standard ExecPlan naming convention. Create them with the exec-plan skill's `init-plan.ts` script, passing `--master-plan <path-to-this-masterplan>`; the script records the parent in the child's `master_plan` frontmatter field. Do not add a body reference line by hand.


## Formatting

When you write commands, transcripts, diffs, or code into a MasterPlan or any child ExecPlan, use fenced code blocks (triple backticks) and **always specify a language tag** on the opening fence — for example ` ```bash `, ` ```typescript `, ` ```haskell `, ` ```python `, ` ```diff `, or ` ```text ` for plain output and commit messages. Never emit a bare ` ``` ` fence without a language. This rule applies to every plan file you create or edit. See MASTERPLAN.md and the ExecPlan PLANS.md for the full formatting rules.


## Architecture Decision Records

Architecture Decision Records (ADRs) hold durable project context. Before any ADR discovery, citation, creation, update, or validation, read and follow `agents/skills/exec-plan/ADR.md`, the shared contract installed by the exec-plan dependency.

When creating a MasterPlan, use that guide to inspect the local corpus and any relevant Mori-indexed cross-repository decisions. Read only ADRs relevant to the initiative. Carry their context into the MasterPlan and into any child ExecPlans whose work depends on it; use repository-relative links locally and exact canonical Mori handles across repositories.

When implementing or updating a MasterPlan, update or create ADRs in the same change whenever the initiative changes durable project context. MasterPlans should especially identify cross-plan decisions that deserve ADR records: architecture boundaries, decomposition rationale that will matter later, shared interface ownership, durable integration constraints, and deliberate exclusions.

At completion, distill durable context from the MasterPlan and child ExecPlans: review Decision Logs, Surprises & Discoveries, and Outcomes & Retrospectives, then promote project-level decisions or lessons into `docs/adr/`. Leave task-local execution details in the plans.


## Git Trailers

Every commit made while working under a MasterPlan must include a `MasterPlan:` git trailer:

```text
MasterPlan: docs/masterplans/<N>-<slug>.md
```

When implementing a specific child ExecPlan, include both trailers:

```text
Implement consumer group rebalance handling

Add consumer group module with cooperative rebalance protocol.
Wire partition assignment into the existing consumer loop.

MasterPlan: docs/masterplans/1-kafka-consumer-pipeline.md
ExecPlan: docs/plans/3-add-consumer-group.md
```


## Provenance

Every MasterPlan and every child ExecPlan records which model wrote it and which models have touched it since. The frontmatter carries an optional `provenance` block with three parts: `created_by`, a single record written by the init script; `revisions`, an append-only list of models that changed the plan; and `reviews`, an append-only list of models that reviewed it.

```yaml
provenance:
  created_by:
    model: "claude-opus-5"
    harness: "claude-code"
    at: 2026-01-31T09:15:00Z
  revisions:
    - model: "claude-sonnet-5"
      harness: "claude-code"
      at: 2026-02-02T11:40:00Z
      mode: "implement"
      note: "EP-2 completed, registry updated"
  reviews:
    - model: "gpt-5"
      at: 2026-02-03T08:05:00Z
      verdict: "changes-requested"
      note: "EP-3 and EP-4 both define the offset store"
```

Record entries with the script installed by the exec-plan dependency, never by hand. It works on MasterPlans and ExecPlans alike — pass whichever file the entry belongs to:

```bash
bun agents/skills/exec-plan/record-provenance.ts review \
  --plan <plan-path> --model <your-model-id> [--harness <name>] \
  --verdict <approved|changes-requested|comments> --note "<one line>"
```

```bash
bun agents/skills/exec-plan/record-provenance.ts revision \
  --plan <plan-path> --model <your-model-id> [--harness <name>] \
  --mode <implement|update|discuss|other> --note "<one line>"
```

The rules that keep this metadata trustworthy:

**Never hand-edit the `provenance` block, and never delete, reorder, or rewrite an existing entry.** The script only appends, so any number of models can review the same MasterPlan without clobbering one another's records. Running the same command twice in one day is a no-op unless you pass `--allow-duplicate`.

**Resolve your exact runtime model before writing provenance.** Read and follow `agents/skills/exec-plan/PROVENANCE.md`, the shared Codex and Claude Code discovery procedure. A missing ID in your prompt is not enough to declare it unavailable. All writing scripts accept a verified `--model` or a session-file adapter; `unknown` requires `--allow-unknown` and `--unknown-reason`, which is saved in the entry. Never infer identity from configured defaults or another agent. Recheck after model switches and record each contributing model's own entry.

**Plans created before provenance existed have no `provenance` block.** That is expected, not a defect. Record your own entry when you touch such a plan; the script adds the block containing only your entry. Never invent a `created_by` record for work you did not do.

**Provenance follows the file that changed.** Implementing a child ExecPlan records a revision on that child; the coordination edits you make to the MasterPlan in the same session record one revision on the MasterPlan. Record each at most once per session.

**When child plans are drafted by parallel agents, each agent records its own `created_by` through the init script.** Pass `--model` for the model that actually drafted that child plan, not the model coordinating the initiative.


## Modes of Operation

Determine the mode from the first argument. If no argument is given, ask the user what they want to do.


### Mode: create

Create a new MasterPlan and all its child ExecPlans. The remaining arguments describe the initiative.

1. Research the codebase thoroughly before writing anything. Use Glob, Grep, and Read to understand the repository: file structure, key modules, build system, test infrastructure, dependency management, and existing patterns. A MasterPlan coordinates multiple plans, so you need both broad and deep understanding of the codebase. The research must be proportional to the initiative's scope.

2. Follow `agents/skills/exec-plan/ADR.md`. Scan local ADR filenames and headings, search Mori when cross-repository decisions may apply, and read only relevant records. Carry the context into the MasterPlan and affected child ExecPlans, using repository-relative links locally and exact Mori handles across repositories. If no relevant ADR exists, note that explicitly in the MasterPlan.

3. Identify the natural work streams. Group by functional concern, not by file. Each work stream should produce an independently verifiable behavior. Aim for two to seven child plans per the decomposition principles in MASTERPLAN.md. If you identify more than seven, introduce phases to group them into implementation waves.

4. For each work stream, determine its purpose and scope (what exists after it is complete that did not exist before), the key files and modules it touches, its dependencies on other work streams (hard, soft, or integration per MASTERPLAN.md), and integration points with other work streams (shared types, interfaces, files, or configurations). Identify any cross-plan decisions likely to deserve ADR records, especially architecture boundaries, durable integration constraints, shared interface ownership, decomposition rationale that will matter later, and deliberate exclusions.

5. Run the init script to create the MasterPlan file with frontmatter and skeleton:

    ```bash
    bun agents/skills/master-plan/init-masterplan.ts --title "<initiative title>" --model <your-model-id> [--harness <name>] [--intention <id>]
    ```

    Always supply your own verified identity using `--model` or a session-file adapter (see Provenance); add `--harness` when passing an explicit model and you know the harness. The script prints the created file path to stdout. Read the file back and flesh out the prose sections (Vision & Scope, Decomposition Strategy, Dependency Graph, Integration Points). Leave the living-document sections empty for now, except the Decision Log which records the initial decomposition decisions.

6. Create each child ExecPlan by running the exec-plan skill's init script, passing the parent path:

    ```bash
    bun agents/skills/exec-plan/init-plan.ts --title "<child title>" --master-plan <path-to-this-masterplan> --model <drafting-model-id> [--harness <name>] [--intention <id>]
    ```

    Then read each child file back and flesh it out per `agents/skills/exec-plan/PLANS.md`. Each child plan must:

    - Be fully self-contained: a novice with only the child plan and the working tree must be able to implement it end-to-end.
    - Reference other child plans only by file path when describing dependencies or integration points, never by assumed shared context.
    - Include all relevant codebase context discovered during research, even if it overlaps with other child plans. Self-containment takes precedence over avoiding repetition.
    - Include any ADR context relevant to that child plan, by repository-relative path.

7. After creating all documents, fill in the MasterPlan's Exec-Plan Registry with each child plan's number, title, path, dependencies, and initial status (Not Started).

8. Present a summary to the user: the initiative's purpose, relevant ADRs consulted, the number of child plans created, a one-line description of each with its dependencies, and all file paths.

For large initiatives (five or more child plans), consider using the Agent tool to research and draft child exec-plans in parallel. Each agent should receive the full codebase context relevant to its work stream plus the integration points it must respect. After parallel creation, review all child plans for cross-plan consistency — shared types must agree, dependency references must be correct, and integration points must be documented identically in each plan that touches them.


### Mode: implement

Implement child ExecPlans under an existing MasterPlan. The first argument is the master plan file path. An optional second argument names a specific child ExecPlan to implement.

1. Read the entire MasterPlan file. Parse the Exec-Plan Registry to understand the current state of all child plans.

2. Determine which child plan to implement next:

   - If a specific child plan path was given as a second argument, use that plan. Verify its hard dependencies are all marked Complete first; if not, report the unmet dependencies and stop.
   - Otherwise, find the first child plan in the registry whose hard dependencies are all Complete and whose own status is Not Started or In Progress.
   - If no plan is implementable (all remaining plans have unsatisfied hard dependencies), report the blocking situation — which plans are blocked and what they are waiting on — and stop.

3. Update the child plan's status to In Progress in the MasterPlan's Exec-Plan Registry.

4. Read the child ExecPlan file. Follow the implementation protocol described in `agents/skills/exec-plan/SKILL.md` (Mode: implement) to carry out the work. This means: identify the current state from the Progress section, proceed step by step through milestones, update the child plan's living sections at every stopping point, resolve ambiguities autonomously, and commit frequently. Every commit must include both `MasterPlan:` and `ExecPlan:` git trailers.

5. After completing the child plan:

   - Finalize the child plan's living sections per the exec-plan protocol (Outcomes & Retrospective, etc.).
   - Update the MasterPlan's Exec-Plan Registry: mark the child plan Complete.
   - Update the MasterPlan's Progress section: check off the corresponding milestones.
   - Record any cross-plan discoveries in the MasterPlan's Surprises & Discoveries section — especially anything that affects other child plans' assumptions, interfaces, or feasibility.
   - Update or create ADRs in `docs/adr/` for durable cross-plan decisions, architecture boundaries, shared interface ownership, integration constraints, or deliberate exclusions revealed by the child plan.
   - Record provenance revision entries with `--mode implement` (see Provenance): one on the child ExecPlan for the implementation work, and one on the MasterPlan for the coordination edits. Record each at most once per session, even when several child plans are implemented back to back.

6. Check for the next implementable child plan. If one exists, present it and ask the user whether to continue implementation or stop here. If the user chooses to continue, repeat from step 2. If no plans remain, fill in the MasterPlan's Outcomes & Retrospective section.

7. When the MasterPlan is complete, perform the ADR distillation pass across the MasterPlan and all child ExecPlans. Review Decision Logs, Surprises & Discoveries, and Outcomes & Retrospectives, then promote durable project context into `docs/adr/`.


### Mode: status

Show the current state of a MasterPlan and all its child plans.

If a master plan path is given:

1. Read the MasterPlan file. Parse the Exec-Plan Registry.

2. For each child plan in the registry, read its Progress section and compute completion percentage (checked items vs total items).

3. Present a summary: the initiative title, overall progress (child plans completed / total), and a table showing each child plan's number, title, status, progress percentage, current milestone, and any blockers.

4. Highlight dependency bottlenecks — child plans that are blocked and what they are waiting on. If multiple plans can proceed in parallel, note this.

If no path is given, scan `docs/masterplans/` for all `.md` files and show a summary table of each master plan's title and aggregate progress.

Status is read-only: it never writes to a plan, and it never records a provenance entry. When summarizing a single MasterPlan, include its authoring model and the verdict of its most recent review when the `provenance` block has them.


### Mode: update

Revise an existing MasterPlan to reflect new information, changed requirements, or decomposition adjustments. The argument is the master plan file path.

1. Read the entire MasterPlan file.

2. Make the requested changes. Common update scenarios:

   Adding a child plan: create the new ExecPlan in `docs/plans/`, add it to the Exec-Plan Registry, update the Dependency Graph and Integration Points sections.

   Cancelling a child plan: mark it Cancelled in the registry with a brief reason, update dependencies of plans that depended on it (remove or redirect the dependency), record rationale in the Decision Log.

   Splitting a child plan: create the new replacement plans, mark the original Cancelled with a reference to its replacements, redistribute progress items, update all sections.

   Merging child plans: create the merged plan incorporating content from both originals, mark the originals Cancelled with a reference to the merged plan, update all sections.

   Reordering: update the Dependency Graph and Exec-Plan Registry, propagate changed dependency references to affected child plans.

3. Ensure changes are comprehensively reflected across all sections of the MasterPlan, including living document sections (Progress, Surprises & Discoveries, Decision Log).

4. Cascade changes to affected child ExecPlans when necessary — update dependency references, integration point descriptions, or context sections that reference changed plans.

5. Update or create ADRs in `docs/adr/` when the revision changes durable project context, especially cross-plan boundaries, shared interfaces, integration constraints, or exclusions.

6. Append a revision note at the bottom of the MasterPlan describing what changed and why.

7. Record a provenance revision entry with `--mode update` on the MasterPlan (see Provenance), and one on each child ExecPlan you edited in the same pass.


### Mode: discuss

Discuss or review an existing MasterPlan. The argument is the master plan file path.

1. Read the entire MasterPlan file. Read all child ExecPlan files referenced in the Exec-Plan Registry to have full context.

2. Engage with the user's questions or proposed changes. Common discussion topics include decomposition alternatives, dependency ordering, scope of individual child plans, integration concerns, risk assessment, and phase planning.

3. For every decision reached during discussion, update the Decision Log in the MasterPlan with the decision, rationale, and date.

4. If a decision reached during discussion changes durable project context, update or create the relevant ADR in `docs/adr/`.

5. If the discussion results in changes to the MasterPlan or any child plans, update all affected sections and documents. Per MASTERPLAN.md, revisions must be comprehensively reflected across all sections. Append a revision note at the bottom of the MasterPlan.

6. If you changed any document, record a provenance revision entry with `--mode discuss` on each file you edited (see Provenance). If the user asked for an assessment of the decomposition's quality rather than a conversation about it, use Mode: review instead so the result is recorded as a review.


### Mode: review

Review an existing MasterPlan and its decomposition, then record the verdict. The argument is the master plan file path. Use this mode when an initiative planned by another session — or another model — needs a second pair of eyes before implementation begins.

1. Read the entire MasterPlan file and every child ExecPlan in the Exec-Plan Registry. Read `MASTERPLAN.md` and `agents/skills/exec-plan/PLANS.md` so you audit against the specifications rather than against taste.

2. Read the `provenance` block of the MasterPlan and of each child plan first. Note which model authored each document and which models have already reviewed it, and say so in your report — including any child plan that no model has reviewed. An absent block means the provenance is unknown, not that the document is unreviewed.

3. Audit the coordination layer, which is what a MasterPlan exists to get right. At minimum check that: the decomposition follows the principles in MASTERPLAN.md (functional concerns, two to seven plans, balanced scope); every registry row names a child file that exists at the stated path; hard dependencies are genuinely blocking rather than a preference for ordering, and the graph has no cycles; every shared artifact touched by more than one child plan appears in Integration Points with a single owning plan; and no two child plans define the same type, table, or interface incompatibly.

4. Audit each child plan for the properties the MasterPlan promises: self-containment, independent implementability once its hard dependencies are complete, observable acceptance per milestone, and ADR citations that resolve per `agents/skills/exec-plan/ADR.md`.

5. Verify claims against the repository rather than trusting the prose. Open the files the plans name, and report anything that no longer matches the working tree.

6. Report your findings to the user, ordered most serious first, separating findings about the decomposition from findings about individual child plans and naming the file and section each applies to.

7. Record the review in frontmatter — one entry on the MasterPlan, plus one on each child plan you reviewed in depth:

    ```bash
    bun agents/skills/exec-plan/record-provenance.ts review --plan <plan-path> --model <your-model-id> [--harness <name>] --verdict <approved|changes-requested|comments> --note "<one line>"
    ```

    Use `approved` when the decomposition is ready to implement as written, `changes-requested` when a finding must be fixed first, and `comments` when your findings are advisory. Your entries are appended after any existing reviews; they never replace them.

8. Do not rewrite the MasterPlan or its children in this mode. If the user wants the findings applied, switch to Mode: update, which records its own revision entries.


## MasterPlan Skeleton

The skeleton is owned by `init-masterplan.ts`; the script writes it into every new MasterPlan. Section names and the order they appear in are: Vision & Scope, Decomposition Strategy, Exec-Plan Registry, Dependency Graph, Integration Points, Progress, Surprises & Discoveries, Decision Log, Outcomes & Retrospective. Each generated section carries inline guidance describing what belongs there — read the file after creation and follow the guidance verbatim. The Exec-Plan Registry is a table; populate it once all child ExecPlans have been created so the paths are real.
# --- seihou:master-plan ---



## Intention Tracking

Before asking any intention-related question, perform this mandatory preflight:

- In **create** mode, no target plan exists yet, so use the `AskUserQuestion` tool to ask the user if they want to associate this initiative with an intention.
- In **implement** mode, read the target MasterPlan's YAML frontmatter before doing anything else. If it contains a non-empty `intention` field, that value is authoritative: use it as the active Intention ID for the session. **Do not call `AskUserQuestion`, do not ask the user to confirm or replace it, and do not offer the Skip option.**
- Every child ExecPlan implemented under that MasterPlan inherits the active Intention ID. If a child lacks the `intention` field, add the inherited ID to its YAML frontmatter; **do not prompt again when selecting or switching child plans.**
- Ask only when the target MasterPlan has no non-empty Intention ID.

When prompting, provide two options:

- **Yes** — "I have an Intention ID to associate with this initiative"
- **Skip** — "Proceed without linking an intention"

If the user provides an Intention ID, store it for the duration of the session and:

1. **Pass it to the init scripts.** When creating a new MasterPlan, pass `--intention <IntentionId>` to `init-masterplan.ts`; when creating each child ExecPlan in the same session, pass the same `--intention <IntentionId>` to `init-plan.ts`. Both scripts write it into the plan's YAML frontmatter (`intention: <IntentionId>`); do not add a body line for it. When working with an existing plan whose frontmatter does not yet have an `intention` field, add it directly to the frontmatter block.

2. **Include an `Intention:` git trailer on every commit** alongside the other trailers:

    ```text
    Implement consumer group rebalance handling

    Add consumer group module with cooperative rebalance protocol.

    MasterPlan: docs/masterplans/1-kafka-consumer-pipeline.md
    ExecPlan: docs/plans/3-add-consumer-group.md
    Intention: INTENT-42
    ```

Existing plan frontmatter takes precedence over the general instruction to ask at the start of create or implement work. Ask at most once per session and only after the mandatory preflight proves that the active MasterPlan provides no Intention ID. Do not ask again on subsequent operations or child ExecPlans within the same session. If the user skips or declines, proceed without the trailer.
# --- /seihou:master-plan ---
