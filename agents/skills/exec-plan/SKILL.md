---
name: exec-plan
description: >
  Create, implement, review, or update an ExecPlan for a substantial feature or system change.
  Use when the user asks to plan work, follow a plan, or manage an existing ExecPlan.
argument-hint: <create|implement|discuss|review|update|status> [plan-name-or-path]
user-invocable: true
---

# ExecPlan Skill

You are managing execution plans (ExecPlans) — self-contained living documents that guide implementation of features and system changes. Read [PLANS.md](PLANS.md) when creating, implementing, or reviewing a plan; for a narrow edit, consult the relevant sections. For ADR discovery, citation, creation, update, or validation, use [ADR.md](ADR.md). For recording and triaging friction met while implementing, use [FRICTION.md](FRICTION.md). The user's requested scope takes precedence over this skill's workflow defaults.

ExecPlans live in the `docs/plans/` directory at the repository root. Each plan is a single Markdown file named with a sequential number prefix followed by a slug derived from its title (e.g., `docs/plans/1-add-template-engine.md`). Each plan begins with a YAML frontmatter block — `id`, `slug`, `title`, `kind: exec-plan`, `created_at`, optional `intention`, optional `master_plan`, optional `provenance` — so tooling can identify it without parsing prose.

Create new plans with the bundled `init-plan.ts` script (see Mode: create). The script picks the next sequential number, derives the slug from the title, writes the frontmatter and skeleton, and refuses to overwrite an existing file. Record every later authorship event with the bundled `record-provenance.ts` script (see Provenance), and record friction with the bundled `record-friction.ts` script (see Friction Log). Do not pick numbers, allocate handles, write skeletons, or hand-author frontmatter by hand.


## Formatting

When you write commands, transcripts, diffs, or code into a plan, use fenced code blocks (triple backticks) and **always specify a language tag** on the opening fence — for example ` ```bash `, ` ```typescript `, ` ```haskell `, ` ```python `, ` ```diff `, or ` ```text ` for plain output and commit messages. Never emit a bare ` ``` ` fence without a language. This rule applies to every plan file you create or edit. See PLANS.md for the full formatting rules.


## Architecture Decision Records

Architecture Decision Records (ADRs) hold durable project context. Follow `ADR.md` for the
conditional local-filesystem versus profiled-OKF workflow, stable `ADR-N` allocation, strict
validation, and local versus cross-repository references. Plans remain self-contained: summarize
the relevant decision context in the plan even when you also cite the ADR.


## Friction Log

Friction is the cost of doing the work: a document, interface, tool, environment, or house
process that cost material effort while implementing. Record it as it happens, in the
repository's friction-log bundle, with the bundled `record-friction.ts` script, and triage it
when the plan completes. Follow `FRICTION.md` for the threshold, the fields, bootstrap of the
bundle through `okf profile init`, triage, and citation. Friction is not Surprises & Discoveries,
which holds only findings that changed the plan: when one event is both, record both and cite
the entry's `FRIC-N` handle from the plan. Friction is in the surfaces you used, not in the thing
you are building.


## Git Trailers

Every commit made while working on an ExecPlan **must** include a git trailer linking back to the plan:

```text
ExecPlan: docs/plans/<N>-<slug>.md
```

Add the trailer to the end of the commit message body, separated by a blank line:

```text
Implement health-check endpoint

Add GET /health route that returns 200 OK with uptime info.
Wire into the existing router module.

ExecPlan: docs/plans/3-add-health-check.md
```

If a single commit spans multiple plans (rare — prefer not to), include one trailer per plan.


## Provenance

Every plan records which model wrote it and which models have touched it since. The frontmatter carries an optional `provenance` block with three parts: `created_by`, a single record written by the init script; `revisions`, an append-only list of models that changed the plan; and `reviews`, an append-only list of models that reviewed it.

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
      note: "Milestones 1 and 2 implemented"
  reviews:
    - model: "gpt-5"
      at: 2026-02-03T08:05:00Z
      verdict: "changes-requested"
      note: "Milestone 2 acceptance is not observable"
```

Record entries with the bundled script, never by hand:

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

**Never hand-edit the `provenance` block, and never delete, reorder, or rewrite an existing entry.** The script only appends, so any number of models can review the same plan without clobbering one another's records. Running the same command twice in one day is a no-op unless you pass `--allow-duplicate`.

**Resolve your exact runtime model before writing provenance.** Read and follow [PROVENANCE.md](PROVENANCE.md), including current-agent metadata discovery for Codex and Claude Code. A missing ID in your prompt is not enough to declare it unavailable. All writing scripts accept a verified `--model` or a session-file adapter; `unknown` requires `--allow-unknown` and `--unknown-reason`, which is saved in the entry. Never infer identity from configured defaults or another agent. Recheck after model switches and record each contributing model's own entry.

**Plans created before provenance existed have no `provenance` block.** That is expected, not a defect. Record your own entry when you touch such a plan; the script adds the block containing only your entry. Never invent a `created_by` record for work you did not do, and never assume an absent block means the plan was written by a human.

**Record one revision entry per plan per session,** when you first make a substantive edit to the plan — not once per commit or milestone. Record one review entry per review pass.

**Provenance is metadata about authorship only.** It never substitutes for material decisions, discoveries, or revision notes.


## Modes of Operation

Determine the mode from the argument or the user's request. Ask only if the intended action cannot be inferred.


### Mode: create

Create a new ExecPlan. The remaining arguments describe the feature or change.

1. Inspect the parts of the codebase and existing plans needed to ground the proposed work, including relevant build and validation paths. Expand the research when a design claim depends on it.

2. Follow the discovery workflow in `ADR.md`. Scan ADR filenames and headings, then read only ADRs relevant to this plan. Carry relevant local ADR context into Context and Orientation with repository-relative links; use Mori's exact canonical handle for a cross-repository ADR. If no relevant ADR exists, note that explicitly in the same section.

3. Run the init script to create the file with frontmatter and skeleton:

    ```bash
    bun agents/skills/exec-plan/init-plan.ts --title "<short, action-oriented title>" --model <your-model-id> [--harness <name>] [--intention <id>] [--master-plan <path>]
    ```

    The script prints the created file path to stdout (e.g., `docs/plans/4-add-template-engine.md`). Always supply your own verified identity using `--model` or a session-file adapter (see Provenance); add `--harness` when passing an explicit model and you know the harness. Pass `--intention` only when an Intention ID is active for this session; pass `--master-plan` only when this plan is a child of an existing MasterPlan, naming the parent's file path.

4. Read the file back and fill the sections with task-relevant context. In Progress, list only verifiable milestones or substantial deliverables. Leave Surprises & Discoveries and Outcomes & Retrospective empty until there is something material to record; seed the Decision Log only with consequential design or scope decisions.

5. The plan must be fully self-contained per PLANS.md: a novice with only the plan file and the working tree must be able to implement the feature end-to-end. Define every term of art in plain language. Name files by full repository-relative path. Show exact commands with working directories and expected output.

6. Anchor the plan with observable outcomes — what the user can do after implementation, commands to run, behavior to verify.

7. After writing, present a summary to the user: the plan's purpose, milestone count, relevant ADRs consulted, and the file path.


### Mode: implement

Implement an existing ExecPlan. The argument is the plan file path (e.g., `docs/plans/1-add-template-engine.md`).

1. Read the entire ExecPlan file and, for a child, the relevant parent coordination and dependency guidance. Use these documents and the working tree to resume without relying on prior conversation memory; the user's current instructions govern scope.

2. Identify the next unfinished milestone within the requested scope and any parent execution order. Check its prerequisites and recorded acceptance evidence against the working tree; the Progress section may lag work in progress.

3. Select an observable acceptance criterion, implement a cohesive set of changes toward it, and validate the result. Mark a milestone complete only when all its required acceptance criteria pass. Follow PLANS.md's early integration guidance when uncertain interfaces are involved. Continue through the implementation the user authorized; a commit or passing test suite is a checkpoint, not a reason to stop while authorized work can proceed.

4. Record friction as it occurs. When a surface you used, rather than the thing you are building, costs more than a few minutes, forces a workaround, blocks progress, or will recur for the next contributor, run the bundled script while the command and the error are in front of you:

    ```bash
    bun agents/skills/exec-plan/record-friction.ts log --title "<what cost effort>" \
      --description "<one sentence naming the surface and the cost>" \
      --kind <documentation|interface|tooling|environment|process> \
      --impact <blocked|detour|slowdown|nuisance> --affects <uri> --plan <plan-path> \
      --attempted "<what you were doing>" --encountered "<what happened instead>" \
      [--evidence "<error text>"] [--workaround "<what you did instead>"] \
      --model <your-model-id> [--harness <name>]
    ```

    One entry per occurrence, per `FRICTION.md`. The script bootstraps the bundle on first use, allocates the handle, and validates; it prints the entry path. Do not repeat the entry in the plan unless it also changed the plan; then cite its handle from Surprises & Discoveries.

5. Update the ExecPlan when a milestone is verified, a material blocker or course change arises, or work is handed off. Keep Progress at milestone or substantial-deliverable scale: record the outcome, date, and concise evidence, and describe partial work in a short handoff note when needed. Do not add checkboxes for routine actions or split items merely to show session activity. Record consequential discoveries and decisions in their respective sections. Update or create ADRs when durable project context changes. The first time you write to the plan in this session, record one provenance revision entry with `--mode implement` (see Provenance).

6. Resolve routine ambiguities and defects within the accepted scope autonomously. Distinguish work needed to meet an existing criterion from a proposed new requirement; obtain a scope decision before adding the latter to acceptance. Record decisions only when they change the plan's scope, architecture, interfaces, acceptance, or future implementation path.

7. Commit at meaningful working boundaries. Every commit must include an `ExecPlan:` git trailer linking to the plan file (see Git Trailers above).

8. Use focused checks while developing and run the required milestone checks at a coherent boundary. Record concise acceptance evidence. Repeat checks when relevant changes, failures, or remaining risks invalidate that evidence; preserve applicable results while honoring any required final-candidate validation.

9. At completion, triage the friction entries recorded under this plan per `FRICTION.md` (`record-friction.ts update`), then fill in the Outcomes & Retrospective section, citing each entry by handle with its triage outcome.

10. Distill durable context before declaring the plan complete: review the Decision Log, Surprises & Discoveries, and Outcomes & Retrospective, then update or create ADRs in `docs/adr/` for project-level decisions, constraints, gotchas, or architectural lessons that should survive beyond this plan.


### Mode: discuss

Discuss or review an existing ExecPlan. The argument is the plan file path.

1. Read the entire ExecPlan file.

2. Engage with the user's questions or proposed changes.

3. Record material decisions reached during discussion in the Decision Log with rationale and date.

4. If the discussion changes the plan, review affected sections for consistency and update those that need it.

5. For a material plan revision, append one concise note describing what changed and why.

6. If you changed the plan, record a provenance revision entry with `--mode discuss` (see Provenance). If the user asked for an assessment of the plan's quality rather than a conversation about it, use Mode: review instead so the result is recorded as a review.


### Mode: review

Review an existing ExecPlan against the specification and record the verdict. The argument is the plan file path. Use this mode when a plan written by another session — or another model — needs a second pair of eyes before implementation begins.

1. Read the entire ExecPlan file, then read `PLANS.md` so you audit against the specification rather than against taste.

2. Read the plan's `provenance` block first. Note which model authored it and which models have already reviewed it, and say so in your report: a plan already reviewed by three models with the same verdict needs a different kind of attention than an unreviewed one. An absent block means the provenance is unknown, not that the plan is unreviewed.

3. Audit the plan and gather concrete findings. At minimum check that: it is self-contained (a novice with only this file and the working tree could implement it); every milestone is independently verifiable and states its acceptance as observable behavior; the Context and Orientation section names real files by repository-relative path and its claims match the current working tree; ADR citations follow `ADR.md` and resolve; friction handles the plan cites resolve in the repository's friction-log bundle; every fenced code block carries a language tag; and the living-document sections exist and are consistent with each other.

4. Verify claims against the repository rather than trusting the prose. Open the files the plan names, run the commands it says to run when they are safe and cheap, and report anything that no longer matches reality.

5. Report your findings to the user, ordered most serious first, each naming the section it applies to and what would have to change.

6. Record the review in the plan's frontmatter:

    ```bash
    bun agents/skills/exec-plan/record-provenance.ts review --plan <plan-path> --model <your-model-id> [--harness <name>] --verdict <approved|changes-requested|comments> --note "<one line>"
    ```

    Use `approved` when the plan is implementable as written, `changes-requested` when a finding must be fixed first, and `comments` when your findings are advisory. The `--note` is one line summarizing what you checked or what blocks approval. Your entry is appended after any existing reviews; it never replaces them.

7. Do not rewrite the plan in this mode. If the user wants the findings applied, switch to Mode: update, which records its own revision entry.


### Mode: update

Revise an existing ExecPlan to reflect new information or changed requirements. The argument is the plan file path.

1. Read the entire ExecPlan file.

2. Make the requested changes.

3. Review the affected sections, including living sections, and update what is needed to keep the plan consistent. Avoid filler in unaffected sections.

4. For a material plan revision, append one concise note describing what changed and why. Routine milestone status updates need no revision note.

5. Record a provenance revision entry with `--mode update` (see Provenance), noting in one line what the revision changed.


### Mode: status

Show the current state of one or all ExecPlans.

If a plan path is given, read it and summarize its purpose, completed and remaining milestones, current work, and material blockers. Do not calculate a percentage from checkbox counts; checkboxes are outcomes, not units of effort. When the repository has a friction-log bundle, list the entries recorded under the plan that are still `logged`, by handle (see `FRICTION.md` for the query).

If no path is given, scan `docs/plans/` for all `.md` files and show a summary table of each plan's title and milestone state.

Status is read-only: it never writes to a plan, and it never records a provenance entry. When summarizing a single plan, include its authoring model and the verdict of its most recent review when the `provenance` block has them.


## ExecPlan Skeleton

The skeleton is owned by `init-plan.ts`; the script writes it into every new plan. Section names and the order they appear in are: Purpose / Big Picture, Progress, Surprises & Discoveries, Decision Log, Outcomes & Retrospective, Context and Orientation, Plan of Work, Concrete Steps, Validation and Acceptance, Idempotence and Recovery, Interfaces and Dependencies. Each generated section carries inline guidance describing what belongs there — read the file after creation and follow the guidance verbatim.
# --- seihou:exec-plan#bfa0a336 ---


## Intention Tracking

Before asking any intention-related question, perform this mandatory preflight:

- In **create** mode, no target plan exists yet, so use the `AskUserQuestion` tool to ask the user if they want to associate this work with an intention.
- In **implement** mode, read the target ExecPlan's YAML frontmatter before doing anything else. If it contains a non-empty `intention` field, that value is authoritative: use it as the active Intention ID for the session. **Do not call `AskUserQuestion`, do not ask the user to confirm or replace it, and do not offer the Skip option.**
- If the ExecPlan has no non-empty `intention` field but has a `master_plan` field, read the referenced MasterPlan's YAML frontmatter. If the MasterPlan contains a non-empty `intention` field, inherit it, add it to the ExecPlan frontmatter, and **do not prompt**.
- Ask only when neither the ExecPlan nor its referenced MasterPlan provides a non-empty Intention ID.

When prompting, provide two options:

- **Yes** — "I have an Intention ID to associate with this work"
- **Skip** — "Proceed without linking an intention"

If the user selects "Yes", they will provide the Intention ID via the "Other" free-text input or as a follow-up.

If the user provides an Intention ID, store it for the duration of the session and:

1. **Pass it to the init script.** When creating a new ExecPlan, pass `--intention <IntentionId>` to `init-plan.ts`. The script writes it into the plan's YAML frontmatter (`intention: <IntentionId>`); do not add a body line for it. When implementing an existing plan whose frontmatter does not yet have an `intention` field, add it directly to the frontmatter block (do not introduce a body line).

2. **Include an `Intention:` git trailer on every commit:**

    ```text
    Intention: <IntentionId>
    ```

When both an ExecPlan and an Intention are active, commits must include both trailers:

```text
Implement health-check endpoint

Add GET /health route that returns 200 OK with uptime info.

ExecPlan: docs/plans/3-add-health-check.md
Intention: INTENT-42
```

Existing plan frontmatter takes precedence over the general instruction to ask at the start of create or implement work. Ask at most once per session and only after the mandatory preflight proves that no active plan provides an Intention ID. Do not ask again on subsequent commits within the same session. If the user skips or declines, proceed without the trailer.
# --- /seihou:exec-plan#bfa0a336 ---
