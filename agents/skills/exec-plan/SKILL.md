---
name: exec-plan
description: >
  Create, implement, discuss, or update execution plans (ExecPlans) — self-contained design
  documents that guide a coding agent or novice through delivering a working feature or system
  change. Use when planning significant work, implementing from a plan, or recording design
  decisions. TRIGGER when: user wants to plan a feature, follow a plan, or manage ExecPlan documents.
argument-hint: <create|implement|discuss|update|status> [plan-name-or-path]
user-invocable: true
---

# ExecPlan Skill

You are managing execution plans (ExecPlans) — self-contained living documents that guide implementation of features and system changes. Before doing anything, read the full specification at [PLANS.md](PLANS.md) and follow it to the letter.

ExecPlans live in the `docs/plans/` directory at the repository root. Each plan is a single Markdown file named with a sequential number prefix followed by a slug derived from its title (e.g., `docs/plans/1-add-template-engine.md`). Each plan begins with a YAML frontmatter block — `id`, `slug`, `title`, `kind: exec-plan`, `created_at`, optional `intention`, optional `master_plan` — so tooling can identify it without parsing prose.

Create new plans with the bundled `init-plan.ts` script (see Mode: create). The script picks the next sequential number, derives the slug from the title, writes the frontmatter and skeleton, and refuses to overwrite an existing file. Do not pick numbers, write skeletons, or hand-author frontmatter by hand.


## Git Trailers

Every commit made while working on an ExecPlan **must** include a git trailer linking back to the plan:

    ExecPlan: docs/plans/<N>-<slug>.md

Add the trailer to the end of the commit message body, separated by a blank line:

    Implement health-check endpoint

    Add GET /health route that returns 200 OK with uptime info.
    Wire into the existing router module.

    ExecPlan: docs/plans/3-add-health-check.md

If a single commit spans multiple plans (rare — prefer not to), include one trailer per plan.


## Modes of Operation

Determine the mode from the first argument. If no argument is given, ask the user what they want to do.


### Mode: create

Create a new ExecPlan. The remaining arguments describe the feature or change.

1. Research the codebase thoroughly before writing anything. Use Glob, Grep, and Read to understand the current state of the repository — file structure, key modules, build system, test infrastructure, and any existing patterns relevant to the planned work.

2. Run the init script to create the file with frontmatter and skeleton:

        bun agents/skills/exec-plan/init-plan.ts --title "<short, action-oriented title>" [--intention <id>] [--master-plan <path>]

    The script prints the created file path to stdout (e.g., `docs/plans/4-add-template-engine.md`). Pass `--intention` only when an Intention ID is active for this session; pass `--master-plan` only when this plan is a child of an existing MasterPlan, naming the parent's file path.

3. Read the file back and flesh out each prose section in order, grounding every claim in what you found during research. The Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective sections start empty by design — only the Decision Log should be seeded now, with any initial scoping decisions you made.

4. The plan must be fully self-contained per PLANS.md: a novice with only the plan file and the working tree must be able to implement the feature end-to-end. Define every term of art in plain language. Name files by full repository-relative path. Show exact commands with working directories and expected output.

5. Anchor the plan with observable outcomes — what the user can do after implementation, commands to run, behavior to verify.

6. After writing, present a summary to the user: the plan's purpose, milestone count, and the file path.


### Mode: implement

Implement an existing ExecPlan. The argument is the plan file path (e.g., `docs/plans/1-add-template-engine.md`).

1. Read the entire ExecPlan file. This is your sole source of truth. Do not rely on any context outside the plan and the working tree.

2. Identify the current state from the Progress section — find the first unchecked item or the next milestone to begin.

3. Proceed through the plan step by step. Do not prompt the user for "next steps"; simply continue to the next milestone.

4. At every stopping point (completing a step, encountering an issue, finishing a milestone), update the ExecPlan file:
   - Check off completed items in Progress with a timestamp.
   - Split partially completed items into "done" and "remaining" entries.
   - Add new items discovered during implementation.
   - Record any surprises in Surprises & Discoveries with evidence.
   - Record any decisions in the Decision Log with rationale.

5. Resolve ambiguities autonomously. When you make a judgment call, record it in the Decision Log.

6. Commit frequently. Each commit should leave the codebase in a working state. Every commit must include an `ExecPlan:` git trailer linking to the plan file (see Git Trailers above).

7. After completing each milestone, run the validation steps described in the plan and record the results.

8. At completion, fill in the Outcomes & Retrospective section.


### Mode: discuss

Discuss or review an existing ExecPlan. The argument is the plan file path.

1. Read the entire ExecPlan file.

2. Engage with the user's questions or proposed changes.

3. For every decision reached during discussion, update the Decision Log in the plan file with the decision, rationale, and date.

4. If the discussion results in changes to the plan, update all affected sections — not just the one being discussed. Per PLANS.md, revisions must be comprehensively reflected across all sections.

5. Append a revision note at the bottom of the plan describing what changed and why.


### Mode: update

Revise an existing ExecPlan to reflect new information or changed requirements. The argument is the plan file path.

1. Read the entire ExecPlan file.

2. Make the requested changes.

3. Ensure changes are comprehensively reflected across all sections, including the living document sections (Progress, Surprises & Discoveries, Decision Log, Outcomes & Retrospective).

4. Append a revision note at the bottom of the plan describing what changed and why.


### Mode: status

Show the current state of one or all ExecPlans.

If a plan path is given, read that plan and summarize: title, purpose, progress percentage (checked vs total items), current milestone, any blockers noted in Surprises & Discoveries.

If no path is given, scan `docs/plans/` for all `.md` files and show a summary table of each plan's title and progress.


## ExecPlan Skeleton

The skeleton is owned by `init-plan.ts`; the script writes it into every new plan. Section names and the order they appear in are: Purpose / Big Picture, Progress, Surprises & Discoveries, Decision Log, Outcomes & Retrospective, Context and Orientation, Plan of Work, Concrete Steps, Validation and Acceptance, Idempotence and Recovery, Interfaces and Dependencies. Each generated section carries inline guidance describing what belongs there — read the file after creation and follow the guidance verbatim.
# --- seihou:exec-plan#bfa0a336 ---


## Intention Tracking

When starting work in **create** or **implement** mode, use the `AskUserQuestion` tool to ask the user if they want to associate this work with an intention. Provide two options:

- **Yes** — "I have an Intention ID to associate with this work"
- **Skip** — "Proceed without linking an intention"

If the user selects "Yes", they will provide the Intention ID via the "Other" free-text input or as a follow-up.

If the user provides an Intention ID, store it for the duration of the session and:

1. **Pass it to the init script.** When creating a new ExecPlan, pass `--intention <IntentionId>` to `init-plan.ts`. The script writes it into the plan's YAML frontmatter (`intention: <IntentionId>`); do not add a body line for it. When implementing an existing plan whose frontmatter does not yet have an `intention` field, add it directly to the frontmatter block (do not introduce a body line).

2. **Include an `Intention:` git trailer on every commit:**

        Intention: <IntentionId>

When both an ExecPlan and an Intention are active, commits must include both trailers:

    Implement health-check endpoint

    Add GET /health route that returns 200 OK with uptime info.

    ExecPlan: docs/plans/3-add-health-check.md
    Intention: INTENT-42

Ask once at the start of a session. Do not ask again on subsequent commits within the same session. If the user skips or declines, proceed without the trailer.
# --- /seihou:exec-plan#bfa0a336 ---
