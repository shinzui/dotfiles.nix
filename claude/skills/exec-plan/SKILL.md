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

ExecPlans live in the `docs/plans/` directory at the repository root. Each plan is a single Markdown file named with a slug derived from its title (e.g., `docs/plans/add-template-engine.md`).


## Git Trailers

Every commit made while working on an ExecPlan **must** include a git trailer linking back to the plan:

    ExecPlan: docs/plans/<slug>.md

Add the trailer to the end of the commit message body, separated by a blank line:

    Implement health-check endpoint

    Add GET /health route that returns 200 OK with uptime info.
    Wire into the existing router module.

    ExecPlan: docs/plans/add-health-check.md

If a single commit spans multiple plans (rare — prefer not to), include one trailer per plan.


## Modes of Operation

Determine the mode from the first argument. If no argument is given, ask the user what they want to do.


### Mode: create

Create a new ExecPlan. The remaining arguments describe the feature or change.

1. Research the codebase thoroughly before writing anything. Use Glob, Grep, and Read to understand the current state of the repository — file structure, key modules, build system, test infrastructure, and any existing patterns relevant to the planned work.

2. Start from the skeleton below and flesh it out section by section as you research. Do not write the plan from memory or assumptions; ground every claim in what you find in the codebase.

3. Write the ExecPlan to `docs/plans/<slug>.md`. The plan must be fully self-contained per PLANS.md: a novice with only the plan file and the working tree must be able to implement the feature end-to-end.

4. Define every term of art in plain language. Name files by full repository-relative path. Show exact commands with working directories and expected output.

5. Anchor the plan with observable outcomes — what the user can do after implementation, commands to run, behavior to verify.

6. Initialize all living sections: Progress (empty checklist), Surprises & Discoveries (empty), Decision Log (record initial scoping decisions), Outcomes & Retrospective (empty, to be filled during implementation).

7. After writing, present a summary to the user: the plan's purpose, milestone count, and the file path.


### Mode: implement

Implement an existing ExecPlan. The argument is the plan file path (e.g., `docs/plans/add-template-engine.md`).

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

When creating a new plan, use this structure. Every section is mandatory.

    # <Short, action-oriented title>

    This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
    Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

    This document is maintained in accordance with `.claude/skills/exec-plan/PLANS.md`.


    ## Purpose / Big Picture

    Explain in a few sentences what someone gains after this change and how they can see it
    working. State the user-visible behavior you will enable.


    ## Progress

    Use a checklist to summarize granular steps. Every stopping point must be documented here,
    even if it requires splitting a partially completed task into two ("done" vs. "remaining").
    This section must always reflect the actual current state of the work.

    - [ ] Example incomplete step.


    ## Surprises & Discoveries

    Document unexpected behaviors, bugs, optimizations, or insights discovered during
    implementation. Provide concise evidence.

    (None yet.)


    ## Decision Log

    Record every decision made while working on the plan.

    - Decision: ...
      Rationale: ...
      Date: ...


    ## Outcomes & Retrospective

    Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
    Compare the result against the original purpose.

    (To be filled during and after implementation.)


    ## Context and Orientation

    Describe the current state relevant to this task as if the reader knows nothing. Name the
    key files and modules by full path. Define any non-obvious term you will use. Do not refer
    to prior plans unless they are checked into the repository, in which case reference them by
    path.


    ## Plan of Work

    Describe, in prose, the sequence of edits and additions. For each edit, name the file and
    location (function, module) and what to insert or change. Keep it concrete and minimal.

    Break into milestones if the work spans multiple independent phases. Each milestone must be
    independently verifiable. Introduce each milestone with a brief paragraph: scope, what will
    exist at the end, commands to run, acceptance criteria.


    ## Concrete Steps

    State the exact commands to run and where to run them (working directory). When a command
    generates output, show a short expected transcript so the reader can compare. This section
    must be updated as work proceeds.


    ## Validation and Acceptance

    Describe how to exercise the system and what to observe. Phrase acceptance as behavior with
    specific inputs and outputs. If tests are involved, name the exact test commands and expected
    results. Show that the change is effective beyond compilation.


    ## Idempotence and Recovery

    If steps can be repeated safely, say so. If a step is risky, provide a safe retry or
    rollback path.


    ## Interfaces and Dependencies

    Name the libraries, modules, and services to use and why. Specify the types, interfaces, and
    function signatures that must exist at the end of each milestone. Use full module paths. For
    example:

        In src/Seihou/Core/Template.hs, define:

            renderTemplate :: TemplatePath -> Variables -> IO Text
