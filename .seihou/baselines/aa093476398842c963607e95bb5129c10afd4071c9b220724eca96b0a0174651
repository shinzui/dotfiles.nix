# MasterPlan Specification

This document defines the requirements for a master plan ("MasterPlan"), a coordination document that decomposes a large initiative into multiple ExecPlans and manages their dependencies, ordering, and integration. Treat the reader as a complete beginner: they have only the current working tree, the MasterPlan file, and the child ExecPlan files it references.


## When to Use a MasterPlan

Use a MasterPlan when the work requires multiple independently-deliverable changes that share a unifying goal. Indicators that a MasterPlan is appropriate:

The initiative contains distinct, independently deliverable work streams with dependencies or shared interfaces that need coordination. A single ExecPlan would obscure those boundaries or become hard to resume. Multiple contributors or sessions may work on different parts of the initiative.

If one ExecPlan can explain and verify the work clearly, use it directly. A MasterPlan adds value when coordination across plans is the hard problem.


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

Break the initiative into work streams by functional concern, not by file or module. Each work stream should produce a demonstrable, independently verifiable behavior. Use the fewest child plans that preserve clear ownership, dependencies, and acceptance. Group plans into phases only when phases make ordering or handoffs clearer.

When deciding where to draw boundaries, consider the following. Minimize cross-plan coupling: two plans that must modify the same function in the same way should likely be one plan. Maximize independent verifiability: each plan's outcome should be testable without the others being complete. Respect natural ordering: if feature B is meaningless without feature A, make A a dependency of B rather than merging them. Balance scope: avoid one plan doing eighty percent of the work while others are trivial; redistribute if possible.


## Dependency Modeling

MasterPlans model three kinds of relationships between child plans.

Hard dependencies identify artifacts or behavior that must be accepted before dependent work begins. A reference to a whole child requires that child to be Complete. When only one milestone is needed, explicitly name that milestone and its required output in the registry and Dependency Graph, and reflect the prerequisite in the affected child plans. Use hard dependencies sparingly as they serialize work and extend timelines; do not silently reinterpret an existing whole-child dependency as a milestone dependency.

Soft dependencies mean plan B benefits from plan A being complete but can proceed independently, perhaps with temporary stubs or assumptions. Soft dependencies are the norm when two plans share context but not code artifacts.

Integration dependencies mean plans A and B both define interfaces or data structures that must agree. Neither blocks the other, but a reconciliation step is needed before or after implementation to ensure the interfaces align. Document the shared interfaces in the Integration Points section of the MasterPlan.

Keep a simple child-by-child sequence when it fits the dependencies. When coupled work needs interleaving, describe an explicit milestone sequence in Dependency Graph using the existing child milestones and their acceptance conditions. The registry continues to track whole-child status. Interleaving does not waive hard dependencies or require another progress checklist.


## Integration Points

When multiple child plans touch the same files, types, or interfaces, the MasterPlan must document these shared concerns in its Integration Points section. For each integration point, state which child plans are involved, what the shared artifact is (type, module, configuration file, database table), which plan is responsible for defining it (typically the earliest plan in dependency order), and how later plans should consume or extend it.

Integration points prevent silent conflicts where two plans make incompatible assumptions about shared code.

When a shared interface or behavior is uncertain, name a representative producer/consumer check and its owner, and schedule it before expanding dependent variants. Use the actual implementation path appropriate to the project, such as a library consumer test or an authorized native roundtrip. An isolated change needs no additional integration exercise; reuse existing acceptance where it already proves the interaction.


## Living Document Requirements

The MasterPlan must maintain and keep current the following sections: a Progress section summarizing initiative state and remaining integration work, a Surprises & Discoveries section for findings that affect more than one child plan, a Decision Log for material decomposition or coordination decisions with rationale and date, and an Outcomes & Retrospective section filled during and after the initiative.

The Exec-Plan Registry is the source of truth for child-plan status; each child ExecPlan owns its milestone progress. Do not copy child milestones or routine tasks into MasterPlan checkboxes. In Progress, identify the current phase, blocked plans, and any cross-plan integration or acceptance gate not represented by a child plan. Use a checklist for those gates only if checking them off makes the initiative easier to manage. Update the snapshot on child-plan status changes, material blockers, integration results, or handoff, not after every action.

When a child plan's implementation reveals that the decomposition was wrong (a plan should be split, merged, reordered, or cancelled), update the MasterPlan first, then cascade the changes to affected child plans. Record the change in the Decision Log with rationale.

When a living-document entry captures durable project context, update `docs/adr/` in the same change. This is especially important for cross-plan discoveries that alter shared interfaces, architectural boundaries, integration constraints, or deliberate exclusions.

Friction met while implementing is recorded in the repository's friction-log bundle under the child plan being implemented, following `agents/skills/exec-plan/FRICTION.md`, not in MasterPlan sections. The MasterPlan's Surprises & Discoveries records friction with the same surface recurring across child plans, by `FRIC-N` handle, because recurrence is a coordination signal and the strongest case for promotion to a bug report or an improvement request.


## Writing Style and Formatting

Follow the same writing style and formatting rules as ExecPlans (see `agents/skills/exec-plan/PLANS.md`), except that MasterPlan Progress is a concise coordination snapshot rather than a mandatory checklist. Write in plain prose. Use fenced code blocks (triple backticks) with an explicit language tag — for example `bash`, `typescript`, `haskell`, `diff`, or `text` — for every command, transcript, diff, or code snippet. Bare fences without a language tag are not permitted. The Exec-Plan Registry is the one exception where a table is preferred for scanability.
