# MasterPlan Specification

This document defines the requirements for a master plan ("MasterPlan"), a coordination document that decomposes a large initiative into multiple ExecPlans and manages their dependencies, ordering, and integration. Treat the reader as a complete beginner: they have only the current working tree, the MasterPlan file, and the child ExecPlan files it references.


## When to Use a MasterPlan

Use a MasterPlan when the work requires multiple independently-deliverable changes that share a unifying goal. Indicators that a MasterPlan is appropriate:

The initiative spans three or more distinct functional concerns (for example, a new data model, a consumer, and an API endpoint). Work streams have ordering constraints or shared interfaces that require coordination. The total scope would produce an unwieldy single ExecPlan (more than five milestones or touching more than ten files across unrelated modules). Multiple contributors or sessions will work on different parts of the initiative.

If the work fits comfortably in a single ExecPlan with two to four milestones, use an ExecPlan directly. A MasterPlan adds value only when coordination across plans is the hard problem.


## Non-Negotiable Requirements

Every MasterPlan must be fully self-contained. In its current form it contains all knowledge needed for someone to understand the initiative's decomposition, the relationships between child plans, and how to proceed.

Every MasterPlan is a living document. Contributors must revise it as child plans progress, as discoveries occur across plans, and as the decomposition changes.

Every MasterPlan must produce child ExecPlans that each conform to the ExecPlan specification in `agents/skills/exec-plan/PLANS.md`. The MasterPlan governs coordination; each child plan governs its own implementation.

Every child ExecPlan must be independently implementable. A contributor should be able to pick up any child plan whose dependencies are satisfied and implement it without reading the other child plans. The MasterPlan itself provides the coordination context, but a child plan must stand alone for implementation purposes.


## Relationship to ADRs

Architecture Decision Records (ADRs) are durable project memory: architectural decisions, rejected alternatives, cross-cutting constraints, and lessons that remain useful after one plan is complete. The shared operational contract is in `agents/skills/exec-plan/ADR.md`.

A MasterPlan is active coordination memory. It should include enough ADR context to explain why the initiative is decomposed and coordinated the way it is, but durable project judgment belongs in ADRs. During MasterPlan creation, follow the shared ADR guide, scan local filenames and headings, search Mori when cross-repository decisions may apply, and read only relevant records. Summarize local ADRs by repository-relative path and cross-repository ADRs by Mori's exact project-and-bundle-scoped handle, or state that no relevant ADR exists.

MasterPlans should identify cross-plan decisions that deserve ADR records: architecture boundaries, decomposition rationale that will matter later, shared interface ownership, durable integration constraints, and deliberate exclusions. During implementation and update, revise or create ADRs whenever those durable decisions change. When the repository has a profile-governed ADR bundle, preserve or allocate its stable handle and run strict profile enforcement through the shared guide.

At completion, distill durable context from the MasterPlan and child ExecPlans. Review Decision Logs, Surprises & Discoveries, and Outcomes & Retrospectives, then promote project-level decisions, constraints, gotchas, and architectural lessons into `docs/adr/`. Leave task-local execution notes and transient coordination details in the plans.


## Provenance

Every MasterPlan and every child ExecPlan should record who wrote it and who has looked at it since, using the same frontmatter contract as ExecPlans (see `agents/skills/exec-plan/PLANS.md`): an optional `provenance` key holding a single `created_by` record, an append-only `revisions` list, and an append-only `reviews` list. Entries are written by `agents/skills/exec-plan/record-provenance.ts`, never by hand, so that reviews by several models accumulate instead of overwriting one another.

A MasterPlan's provenance is coordination provenance: it says which model produced the decomposition. Each child plan carries its own, which matters most when child plans are drafted in parallel by different agents — the model that drafted a child plan is the one recorded in that child's `created_by`, not the model coordinating the initiative.

Provenance is optional and its absence carries no meaning. Documents created before provenance existed have no `provenance` block, and that is not a defect to repair. Never backfill a `created_by` record for work you did not do.


## Decomposition Principles

Break the initiative into work streams by functional concern, not by file or module. Each work stream should produce a demonstrable, independently verifiable behavior. Prefer fewer well-scoped plans (two to seven) over many granular ones. If you find yourself creating more than seven child plans, introduce phases to group related plans into implementation waves.

When deciding where to draw boundaries, consider the following. Minimize cross-plan coupling: two plans that must modify the same function in the same way should likely be one plan. Maximize independent verifiability: each plan's outcome should be testable without the others being complete. Respect natural ordering: if feature B is meaningless without feature A, make A a dependency of B rather than merging them. Balance scope: avoid one plan doing eighty percent of the work while others are trivial; redistribute if possible.


## Dependency Modeling

MasterPlans model three kinds of relationships between child plans.

Hard dependencies mean plan B cannot begin until plan A is complete. Use these sparingly as they serialize work and extend timelines. A hard dependency is warranted when plan B's code would not compile or make sense without plan A's artifacts (types, modules, configurations).

Soft dependencies mean plan B benefits from plan A being complete but can proceed independently, perhaps with temporary stubs or assumptions. Soft dependencies are the norm when two plans share context but not code artifacts.

Integration dependencies mean plans A and B both define interfaces or data structures that must agree. Neither blocks the other, but a reconciliation step is needed before or after implementation to ensure the interfaces align. Document the shared interfaces in the Integration Points section of the MasterPlan.


## Integration Points

When multiple child plans touch the same files, types, or interfaces, the MasterPlan must document these shared concerns in its Integration Points section. For each integration point, state which child plans are involved, what the shared artifact is (type, module, configuration file, database table), which plan is responsible for defining it (typically the earliest plan in dependency order), and how later plans should consume or extend it.

Integration points prevent silent conflicts where two plans make incompatible assumptions about shared code.


## Living Document Requirements

The MasterPlan must maintain and keep current the following sections: a Progress section (aggregate checklist tracking milestone-level progress across all child plans), a Surprises & Discoveries section (cross-plan insights, dependency changes, scope adjustments), a Decision Log (every decomposition or coordination decision with rationale and date), and an Outcomes & Retrospective section (filled during and after the initiative).

When a child plan's implementation reveals that the decomposition was wrong (a plan should be split, merged, reordered, or cancelled), update the MasterPlan first, then cascade the changes to affected child plans. Record the change in the Decision Log with rationale.

When a living-document entry captures durable project context, update `docs/adr/` in the same change. This is especially important for cross-plan discoveries that alter shared interfaces, architectural boundaries, integration constraints, or deliberate exclusions.


## Writing Style and Formatting

Follow the same writing style and formatting rules as ExecPlans (see `agents/skills/exec-plan/PLANS.md`). Write in plain prose. Use fenced code blocks (triple backticks) with an explicit language tag — for example `bash`, `typescript`, `haskell`, `diff`, or `text` — for every command, transcript, diff, or code snippet. Bare fences without a language tag are not permitted. The Exec-Plan Registry is the one exception where a table is preferred for scanability.
