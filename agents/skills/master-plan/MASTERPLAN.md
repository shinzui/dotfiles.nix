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


## Writing Style and Formatting

Follow the same writing style and formatting rules as ExecPlans (see `agents/skills/exec-plan/PLANS.md`). Write in plain prose. Use indented blocks (four-space indent) for commands and transcripts rather than fenced code blocks. The Exec-Plan Registry is the one exception where a table is preferred for scanability.
