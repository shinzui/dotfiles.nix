---
name: master-plan
description: >
  Create and manage master plans that decompose large initiatives into multiple coordinated
  ExecPlans with dependencies and integration points. TRIGGER when: user wants to plan a
  large initiative, coordinate multiple exec-plans, or track multi-plan progress.
argument-hint: <create|implement|status|update|discuss> [plan-name-or-path]
user-invocable: true
---

# MasterPlan Skill

You are managing master plans (MasterPlans) — coordination documents that decompose large initiatives into multiple ExecPlans with defined dependencies and integration points. Before doing anything, read the full specifications:

- [MASTERPLAN.md](MASTERPLAN.md) — requirements for MasterPlan documents
- [ExecPlan specification](../exec-plan/PLANS.md) — requirements for child ExecPlan documents
- [ExecPlan skill](../exec-plan/SKILL.md) — the ExecPlan skeleton and implementation protocol

Follow all three to the letter.

MasterPlans live in the `docs/masterplans/` directory at the repository root. Each master plan is a single Markdown file named with a sequential number prefix followed by a slug derived from its title (e.g., `docs/masterplans/1-kafka-consumer-pipeline.md`). Each plan begins with a YAML frontmatter block — `id`, `slug`, `title`, `kind: master-plan`, `created_at`, optional `intention` — so tooling can identify it without parsing prose.

Create new MasterPlans with the bundled `init-masterplan.ts` script (see Mode: create). The script picks the next sequential number, derives the slug from the title, writes the frontmatter and skeleton, and refuses to overwrite an existing file. Do not pick numbers, write skeletons, or hand-author frontmatter by hand.

Child ExecPlans created by a MasterPlan live in `docs/plans/` following the standard ExecPlan naming convention. Create them with the exec-plan skill's `init-plan.ts` script, passing `--master-plan <path-to-this-masterplan>`; the script records the parent in the child's `master_plan` frontmatter field. Do not add a body reference line by hand.


## Git Trailers

Every commit made while working under a MasterPlan must include a `MasterPlan:` git trailer:

    MasterPlan: docs/masterplans/<N>-<slug>.md

When implementing a specific child ExecPlan, include both trailers:

    Implement consumer group rebalance handling

    Add consumer group module with cooperative rebalance protocol.
    Wire partition assignment into the existing consumer loop.

    MasterPlan: docs/masterplans/1-kafka-consumer-pipeline.md
    ExecPlan: docs/plans/3-add-consumer-group.md


## Modes of Operation

Determine the mode from the first argument. If no argument is given, ask the user what they want to do.


### Mode: create

Create a new MasterPlan and all its child ExecPlans. The remaining arguments describe the initiative.

1. Research the codebase thoroughly before writing anything. Use Glob, Grep, and Read to understand the repository: file structure, key modules, build system, test infrastructure, dependency management, and existing patterns. A MasterPlan coordinates multiple plans, so you need both broad and deep understanding of the codebase. The research must be proportional to the initiative's scope.

2. Identify the natural work streams. Group by functional concern, not by file. Each work stream should produce an independently verifiable behavior. Aim for two to seven child plans per the decomposition principles in MASTERPLAN.md. If you identify more than seven, introduce phases to group them into implementation waves.

3. For each work stream, determine its purpose and scope (what exists after it is complete that did not exist before), the key files and modules it touches, its dependencies on other work streams (hard, soft, or integration per MASTERPLAN.md), and integration points with other work streams (shared types, interfaces, files, or configurations).

4. Run the init script to create the MasterPlan file with frontmatter and skeleton:

        bun agents/skills/master-plan/init-masterplan.ts --title "<initiative title>" [--intention <id>]

    The script prints the created file path to stdout. Read the file back and flesh out the prose sections (Vision & Scope, Decomposition Strategy, Dependency Graph, Integration Points). Leave the living-document sections empty for now, except the Decision Log which records the initial decomposition decisions.

5. Create each child ExecPlan by running the exec-plan skill's init script, passing the parent path:

        bun agents/skills/exec-plan/init-plan.ts --title "<child title>" --master-plan <path-to-this-masterplan> [--intention <id>]

    Then read each child file back and flesh it out per `agents/skills/exec-plan/PLANS.md`. Each child plan must:

    - Be fully self-contained: a novice with only the child plan and the working tree must be able to implement it end-to-end.
    - Reference other child plans only by file path when describing dependencies or integration points, never by assumed shared context.
    - Include all relevant codebase context discovered during research, even if it overlaps with other child plans. Self-containment takes precedence over avoiding repetition.

6. After creating all documents, fill in the MasterPlan's Exec-Plan Registry with each child plan's number, title, path, dependencies, and initial status (Not Started).

7. Present a summary to the user: the initiative's purpose, the number of child plans created, a one-line description of each with its dependencies, and all file paths.

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

6. Check for the next implementable child plan. If one exists, present it and ask the user whether to continue implementation or stop here. If the user chooses to continue, repeat from step 2. If no plans remain, fill in the MasterPlan's Outcomes & Retrospective section.


### Mode: status

Show the current state of a MasterPlan and all its child plans.

If a master plan path is given:

1. Read the MasterPlan file. Parse the Exec-Plan Registry.

2. For each child plan in the registry, read its Progress section and compute completion percentage (checked items vs total items).

3. Present a summary: the initiative title, overall progress (child plans completed / total), and a table showing each child plan's number, title, status, progress percentage, current milestone, and any blockers.

4. Highlight dependency bottlenecks — child plans that are blocked and what they are waiting on. If multiple plans can proceed in parallel, note this.

If no path is given, scan `docs/masterplans/` for all `.md` files and show a summary table of each master plan's title and aggregate progress.


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

5. Append a revision note at the bottom of the MasterPlan describing what changed and why.


### Mode: discuss

Discuss or review an existing MasterPlan. The argument is the master plan file path.

1. Read the entire MasterPlan file. Read all child ExecPlan files referenced in the Exec-Plan Registry to have full context.

2. Engage with the user's questions or proposed changes. Common discussion topics include decomposition alternatives, dependency ordering, scope of individual child plans, integration concerns, risk assessment, and phase planning.

3. For every decision reached during discussion, update the Decision Log in the MasterPlan with the decision, rationale, and date.

4. If the discussion results in changes to the MasterPlan or any child plans, update all affected sections and documents. Per MASTERPLAN.md, revisions must be comprehensively reflected across all sections. Append a revision note at the bottom of the MasterPlan.


## MasterPlan Skeleton

The skeleton is owned by `init-masterplan.ts`; the script writes it into every new MasterPlan. Section names and the order they appear in are: Vision & Scope, Decomposition Strategy, Exec-Plan Registry, Dependency Graph, Integration Points, Progress, Surprises & Discoveries, Decision Log, Outcomes & Retrospective. Each generated section carries inline guidance describing what belongs there — read the file after creation and follow the guidance verbatim. The Exec-Plan Registry is a table; populate it once all child ExecPlans have been created so the paths are real.
# --- seihou:master-plan ---



## Intention Tracking

When starting work in **create** or **implement** mode, use the `AskUserQuestion` tool to ask the user if they want to associate this work with an intention. Provide two options:

- **Yes** — "I have an Intention ID to associate with this initiative"
- **Skip** — "Proceed without linking an intention"

If the user provides an Intention ID, store it for the duration of the session and:

1. **Pass it to the init scripts.** When creating a new MasterPlan, pass `--intention <IntentionId>` to `init-masterplan.ts`; when creating each child ExecPlan in the same session, pass the same `--intention <IntentionId>` to `init-plan.ts`. Both scripts write it into the plan's YAML frontmatter (`intention: <IntentionId>`); do not add a body line for it. When working with an existing plan whose frontmatter does not yet have an `intention` field, add it directly to the frontmatter block.

2. **Include an `Intention:` git trailer on every commit** alongside the other trailers:

        Implement consumer group rebalance handling

        Add consumer group module with cooperative rebalance protocol.

        MasterPlan: docs/masterplans/1-kafka-consumer-pipeline.md
        ExecPlan: docs/plans/3-add-consumer-group.md
        Intention: INTENT-42

Ask once at the start of a session. Do not ask again on subsequent operations within the same session. If the user skips or declines, proceed without the trailer.
# --- /seihou:master-plan ---
