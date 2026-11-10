# ExecPlan Specification

This document defines the requirements for an execution plan ("ExecPlan"), a design document that a coding agent can follow to deliver a working feature or system change. Treat the reader as a complete beginner to this repository: they have only the current working tree and the single ExecPlan file you provide. There is no memory of prior plans and no external context.


## How to Use ExecPlans and This Specification

When authoring an ExecPlan, use this specification to keep the document implementable and verifiable. Inspect the source material relevant to the design, and expand research where an assumption or interface needs confirmation. Start from the skeleton and replace its guidance with task-specific content.

When implementing an ExecPlan, continue through the work the user authorized without prompting for routine "next steps." Keep the plan useful for a contributor resuming later: update it when a milestone is accepted, a material blocker or change of course appears, or work is handed off. Resolve routine ambiguities autonomously and make working commits at meaningful boundaries.

When discussing an ExecPlan, record material changes to its scope or approach in the Decision Log so the reason remains clear. ExecPlans are living documents, and it should be possible to restart from the plan and working tree without the prior conversation.

When a significant unknown could change the design, research the relevant source and use a bounded prototype if it will answer that question. Make its acceptance or discard criterion explicit. Do not add exploratory milestones solely to show activity.


## Relationship to ADRs

Architecture Decision Records (ADRs) are durable project memory: architectural decisions, rejected alternatives, cross-cutting constraints, and lessons that remain useful after one plan is complete. The shared operational contract is in `ADR.md` beside this specification.

An ExecPlan is active execution memory. It must contain enough context to restart and finish the work, including relevant ADR context, but it should not become the long-term home for durable project judgment. During plan creation, follow `ADR.md`: inspect the local corpus when it exists, scan filenames and headings, and read only ADRs relevant to the work. In Context and Orientation, cite local ADRs by repository-relative path and cross-repository ADRs by Mori's exact project-and-bundle-scoped handle, or state that no relevant ADR was found.

During implementation, update or create ADRs whenever the work changes durable project context. Honor the repository's existing ADR convention; when `docs/adr/` is a profile-governed OKF bundle, preserve or allocate its stable handle and run strict profile enforcement as specified in `ADR.md`. At completion, distill the plan: review Decision Log, Surprises & Discoveries, and Outcomes & Retrospective, then promote project-level decisions, constraints, gotchas, and architectural lessons into `docs/adr/`. Leave task-local execution notes and transient details in the plan.


## Relationship to the Friction Log

Friction is the cost of doing the work: a document, interface, tool, environment, or house process that cost the implementer material effort. It is not a section of the plan. It is recorded as it occurs in the repository's friction-log bundle, one OKF concept per occurrence with a stable `FRIC-N` handle, following `FRICTION.md` beside this specification, so that it can be queried across plans and repositories and promoted to a bug report or an improvement request at triage.

Surprises & Discoveries holds only findings that changed the plan or explain a non-obvious result. When one event is both, record both and cite the friction entry's handle from the plan. Defects in the thing the plan is building are ordinary implementation work, not friction. At completion, triage the entries recorded under the plan and cite each in Outcomes & Retrospective with its triage outcome.


## Provenance

Every ExecPlan should record who wrote it and who has looked at it since. Plans are increasingly authored, revised, and reviewed by different models, and a reader deciding how much to trust a plan needs to know whether it was written by one model and never examined, or reviewed by three that disagreed.

Provenance lives in the plan's YAML frontmatter under an optional `provenance` key with three parts. `created_by` is a single record naming the model that authored the plan, written once when the plan is created. `revisions` is a list of models that changed the plan afterwards, one entry per model per working session, each naming the mode of work (`implement`, `update`, `discuss`, `other`). `reviews` is a list of models that reviewed the plan, each carrying a verdict of `approved`, `changes-requested`, or `comments`. Every entry carries the model identifier, an ISO-8601 UTC timestamp, an optional harness name, and an optional one-line note.

Both lists are append-only. A model recording a review must never remove, reorder, or rewrite an entry left by another model, and a plan reviewed by several models must end up with several review entries. This is why entries are written by the skill's `record-provenance.ts` script rather than by hand: hand-editing frontmatter is how one model's record gets clobbered by the next.

Provenance is optional when reading existing plans and its absence carries no meaning. Older plans may lack `provenance` or `created_by`; neither is a defect to be repaired. New authorship entries must follow `PROVENANCE.md`: discover the current agent's exact runtime model first, and use an explained, explicit `unknown` fallback only when discovery fails. Never backfill a `created_by` record for work you did not do, and never treat a missing block as evidence that a human wrote the plan or that no one has reviewed it. Tooling that reads plans must tolerate the key being absent, partially populated, or carrying entries it does not recognize.

Provenance records authorship, not reasoning. It never substitutes for material decisions, discoveries, or revision notes: those explain what changed and why, while provenance only says who was involved and when.


## Non-Negotiable Requirements

Every ExecPlan must be fully self-contained. Self-contained means that in its current form it contains all knowledge and instructions needed for a novice to succeed.

Every ExecPlan is a living document. Contributors are required to revise it as progress is made, as discoveries occur, and as design decisions are finalized. Each revision must remain fully self-contained.

Every ExecPlan must enable a complete novice to implement the feature end-to-end without prior knowledge of this repo.

Every ExecPlan must produce a demonstrably working behavior, not merely code changes to "meet a definition".

Every ExecPlan must define every term of art in plain language or do not use it.


## Writing Style

Purpose and intent come first. Begin by explaining, in a few sentences, why the work matters from a user's perspective: what someone can do after this change that they could not do before, and how to see it working. Then guide the reader through the exact steps to achieve that outcome, including what to edit, what to run, and what they should observe.

The agent executing your plan can list files, read files, search, run the project, and run tests. It does not know prior conversation context. Include the assumptions and decisions it needs to act, while linking to checked-in source and relevant local documentation instead of copying them wholesale. If an ExecPlan builds upon a prior ExecPlan that is checked in, reference it and summarize the dependency needed here. Otherwise include the relevant context.

Write in plain prose. Prefer sentences over lists. Avoid checklists, tables, and long enumerations unless brevity would obscure meaning. Checklists are permitted only in the Progress section, where they are mandatory. Narrative sections must remain prose-first.


## Formatting Rules

Each ExecPlan is written as a standard Markdown file. When you need to show commands, transcripts, diffs, or code within the plan, use fenced code blocks (triple backticks) and **always specify a language tag** on the opening fence — for example `bash`, `sh`, `typescript`, `haskell`, `python`, `json`, `yaml`, `diff`, or `text` for plain output and commit messages. Bare fences without a language tag are not permitted. Use two newlines after every heading. Use standard Markdown heading levels (#, ##, etc.) and correct syntax for ordered and unordered lists.


## Content Guidelines

Self-containment and plain language are paramount. If you introduce a phrase that is not ordinary English ("daemon", "middleware", "RPC gateway", "filter graph"), define it immediately and remind the reader how it manifests in this repository (for example, by naming the files or commands where it appears). Do not say "as defined previously" or "according to the architecture doc." Include the needed explanation here, even if you repeat yourself.

Avoid common failure modes. Do not rely on undefined jargon. Do not describe "the letter of a feature" so narrowly that the resulting code compiles but does nothing meaningful. Do not outsource key decisions to the reader. When ambiguity exists, resolve it in the plan itself and explain why you chose that path. Err on the side of over-explaining user-visible effects and under-specifying incidental implementation details.

Anchor the plan with observable outcomes. State what the user can do after implementation, the commands to run, and the outputs they should see. Acceptance should be phrased as behavior a human can verify ("after starting the server, navigating to http://localhost:8080/health returns HTTP 200 with body OK") rather than internal attributes ("added a HealthCheck struct"). If a change is internal, explain how its impact can still be demonstrated (for example, by running tests that fail before and pass after, and by showing a scenario that uses the new behavior).

Specify repository context explicitly. Name files with full repository-relative paths, name functions and modules precisely, and describe where new files should be created. If touching multiple areas, include a short orientation paragraph that explains how those parts fit together so a novice can navigate confidently. When running commands, show the working directory and exact command line. When outcomes depend on environment, state the assumptions and provide alternatives when reasonable.

If relevant local ADRs exist under `docs/adr/`, summarize the parts that matter and link each by repository-relative path. Cite cross-repository ADRs with an exact canonical Mori handle discovered through the registry. If no relevant ADR exists, say so. Do not require the implementer to read unrelated ADRs to understand the plan.

Be idempotent and safe. Write the steps so they can be run multiple times without causing damage or drift. If a step can fail halfway, include how to retry or adapt. If a migration or destructive operation is necessary, spell out backups or safe fallbacks. Prefer additive, testable changes that can be validated as you go.

Validation is not optional. Include tests and a useful behavioral check appropriate to the change, including how to start the system if applicable. State the commands and the observations that distinguish success from failure. Show how to prove the change works beyond compilation when that matters for acceptance. Broaden testing for material risk, rather than prescribing exhaustive checks for routine changes.

When the design depends on an uncertain interaction between independently developed pieces, exercise a representative producer/consumer path before expanding variants. Choose proof appropriate to the project and authorized environment: a library consumer test, a public command, or a native roundtrip. Use that check's failures to guide implementation. Isolated changes need no extra integration fixture, and existing acceptance checks can supply this proof.

Capture evidence that proves acceptance or explains a material discovery. Use short fenced snippets with an appropriate language tag (`text` for plain output, `diff` for patches, `log` or `console` for transcripts). Do not accumulate routine command transcripts. If a patch is necessary, prefer a small excerpt that a reader can recreate by following the instructions.


## Milestones

Milestones are narrative, not bureaucracy. If you break the work into milestones, introduce each with a brief paragraph describing the scope, what will exist at the end, and how to verify it. Keep it readable as a story: goal, work, result, proof. Progress summarizes these outcomes; it is not a second task breakdown. Include details that affect implementation or acceptance, while leaving routine execution choices to the implementer.

Each milestone must be independently verifiable and incrementally implement the overall goal of the execution plan.

Keep acceptance tied to the authorized outcome. A discovered defect or missing integration needed to meet an existing criterion remains implementation work. A new capability or guarantee is a proposed scope change and needs a scope decision before becoming required acceptance. Splitting or reordering work preserves the existing acceptance obligations unless the user changes them.


## Living Plan Sections

ExecPlans must contain and maintain a Progress section, a Surprises & Discoveries section, a Decision Log, and an Outcomes & Retrospective section. These are not optional.

Use Progress checkboxes only for milestones or substantial deliverables with an observable completion condition. A completed item states the result, completion date, and concise evidence; an unfinished item states the remaining outcome. Do not create checkboxes for reading files, running a command, editing an individual file, committing, writing an ADR, or other routine actions unless one is itself the requested deliverable. During unfinished work, add a short prose handoff note only when another contributor needs it. Do not split an item into "done" and "remaining" checkboxes merely because a session or tool call ended. Keep existing plans at their useful level of detail; consolidate noisy entries when updating a plan, preserving material evidence and unresolved work.

Record only decisions that change scope, architecture, interfaces, acceptance, or the path a future contributor should follow. Routine implementation choices do not need Decision Log entries. Likewise, Surprises & Discoveries holds findings that change the plan or explain a non-obvious result, not a transcript of ordinary work. Friction with the surfaces used to do the work belongs in the friction-log bundle, cited here only when it also changed the plan.

When you discover optimizer behavior, performance tradeoffs, unexpected bugs, or inverse/unapply semantics that shaped your approach, capture those observations in the Surprises & Discoveries section with short evidence snippets (test output is ideal).

If you change course mid-implementation, document why in the Decision Log and reflect the implications in Progress. Plans are guides for the next contributor as much as checklists for you.

At completion of a major task or the full plan, write an Outcomes & Retrospective entry summarizing what was achieved, what remains, lessons learned, and the friction entries recorded under the plan with their triage outcomes.

Before marking the full plan complete, perform the ADR distillation pass: promote durable project context from the Decision Log, Surprises & Discoveries, and Outcomes & Retrospective into `docs/adr/`, updating existing ADRs when they already cover the topic and creating a new ADR when the topic is new.


## Prototyping and Parallel Implementations

It is acceptable and often encouraged to include explicit prototyping milestones when they de-risk a larger change. Examples: adding a low-level operator to a dependency to validate feasibility, or exploring two composition orders while measuring optimizer effects. Keep prototypes additive and testable. Clearly label the scope as "prototyping"; describe how to run and observe results; and state the criteria for promoting or discarding the prototype.

Prefer additive code changes followed by subtractions that keep tests passing. Parallel implementations (e.g., keeping an adapter alongside an older path during migration) are fine when they reduce risk or enable tests to continue passing during a large migration. Describe how to validate both paths and how to retire one safely with tests. When working with multiple new libraries or feature areas, consider creating spikes that evaluate the feasibility of these features independently of one another, proving that the external library performs as expected and implements the features we need in isolation.


## Revision Protocol

When a revision changes scope, approach, dependencies, or acceptance, review all affected sections for consistency and add one concise revision note describing what changed and why. Routine milestone status updates need no revision note. Explain consequential choices, leaving incidental implementation details to the working tree. If a revision changes durable project context, update the relevant ADR in `docs/adr/` in the same change.
