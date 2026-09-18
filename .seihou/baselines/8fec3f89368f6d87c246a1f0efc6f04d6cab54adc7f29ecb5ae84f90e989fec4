# ExecPlan Specification

This document defines the requirements for an execution plan ("ExecPlan"), a design document that a coding agent can follow to deliver a working feature or system change. Treat the reader as a complete beginner to this repository: they have only the current working tree and the single ExecPlan file you provide. There is no memory of prior plans and no external context.


## How to Use ExecPlans and This Specification

When authoring an ExecPlan, follow this specification to the letter. Be thorough in reading (and re-reading) source material to produce an accurate specification. When creating a spec, start from the skeleton and flesh it out as you do research.

When implementing an ExecPlan, do not prompt the user for "next steps"; simply proceed to the next milestone. Keep all sections up to date, add or split entries in the progress list at every stopping point to affirmatively state the progress made and next steps. Resolve ambiguities autonomously, and commit frequently.

When discussing an ExecPlan, record decisions in the Decision Log section for posterity; it should be unambiguously clear why any change to the specification was made. ExecPlans are living documents, and it should always be possible to restart from only the ExecPlan and no other work.

When researching a design with challenging requirements or significant unknowns, use milestones to implement proof of concepts, "toy implementations", etc., that allow validating whether the user's proposal is feasible. Read the source code of libraries by finding or acquiring them, research deeply, and include prototypes to guide a fuller implementation.


## Relationship to ADRs

Architecture Decision Records (ADRs) are durable project memory: architectural decisions, rejected alternatives, cross-cutting constraints, and lessons that remain useful after one plan is complete. The shared operational contract is in `ADR.md` beside this specification.

An ExecPlan is active execution memory. It must contain enough context to restart and finish the work, including relevant ADR context, but it should not become the long-term home for durable project judgment. During plan creation, follow `ADR.md`: inspect the local corpus when it exists, scan filenames and headings, and read only ADRs relevant to the work. In Context and Orientation, cite local ADRs by repository-relative path and cross-repository ADRs by Mori's exact project-and-bundle-scoped handle, or state that no relevant ADR was found.

During implementation, update or create ADRs whenever the work changes durable project context. Honor the repository's existing ADR convention; when `docs/adr/` is a profile-governed OKF bundle, preserve or allocate its stable handle and run strict profile enforcement as specified in `ADR.md`. At completion, distill the plan: review Decision Log, Surprises & Discoveries, and Outcomes & Retrospective, then promote project-level decisions, constraints, gotchas, and architectural lessons into `docs/adr/`. Leave task-local execution notes and transient details in the plan.


## Provenance

Every ExecPlan should record who wrote it and who has looked at it since. Plans are increasingly authored, revised, and reviewed by different models, and a reader deciding how much to trust a plan needs to know whether it was written by one model and never examined, or reviewed by three that disagreed.

Provenance lives in the plan's YAML frontmatter under an optional `provenance` key with three parts. `created_by` is a single record naming the model that authored the plan, written once when the plan is created. `revisions` is a list of models that changed the plan afterwards, one entry per model per working session, each naming the mode of work (`implement`, `update`, `discuss`, `other`). `reviews` is a list of models that reviewed the plan, each carrying a verdict of `approved`, `changes-requested`, or `comments`. Every entry carries the model identifier, an ISO-8601 UTC timestamp, an optional harness name, and an optional one-line note.

Both lists are append-only. A model recording a review must never remove, reorder, or rewrite an entry left by another model, and a plan reviewed by several models must end up with several review entries. This is why entries are written by the skill's `record-provenance.ts` script rather than by hand: hand-editing frontmatter is how one model's record gets clobbered by the next.

Provenance is optional when reading existing plans and its absence carries no meaning. Older plans may lack `provenance` or `created_by`; neither is a defect to be repaired. New authorship entries must follow `PROVENANCE.md`: discover the current agent's exact runtime model first, and use an explained, explicit `unknown` fallback only when discovery fails. Never backfill a `created_by` record for work you did not do, and never treat a missing block as evidence that a human wrote the plan or that no one has reviewed it. Tooling that reads plans must tolerate the key being absent, partially populated, or carrying entries it does not recognize.

Provenance records authorship, not reasoning. It never substitutes for the Decision Log, the Surprises & Discoveries section, or the revision note at the bottom of the plan: those explain what changed and why, while provenance only says who was involved and when.


## Non-Negotiable Requirements

Every ExecPlan must be fully self-contained. Self-contained means that in its current form it contains all knowledge and instructions needed for a novice to succeed.

Every ExecPlan is a living document. Contributors are required to revise it as progress is made, as discoveries occur, and as design decisions are finalized. Each revision must remain fully self-contained.

Every ExecPlan must enable a complete novice to implement the feature end-to-end without prior knowledge of this repo.

Every ExecPlan must produce a demonstrably working behavior, not merely code changes to "meet a definition".

Every ExecPlan must define every term of art in plain language or do not use it.


## Writing Style

Purpose and intent come first. Begin by explaining, in a few sentences, why the work matters from a user's perspective: what someone can do after this change that they could not do before, and how to see it working. Then guide the reader through the exact steps to achieve that outcome, including what to edit, what to run, and what they should observe.

The agent executing your plan can list files, read files, search, run the project, and run tests. It does not know any prior context and cannot infer what you meant from earlier milestones. Repeat any assumption you rely on. Do not point to external blogs or docs; if knowledge is required, embed it in the plan itself in your own words. If an ExecPlan builds upon a prior ExecPlan and that file is checked in, incorporate it by reference. If it is not, you must include all relevant context from that plan.

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

Validation is not optional. Include instructions to run tests, to start the system if applicable, and to observe it doing something useful. Describe comprehensive testing for any new features or capabilities. Include expected outputs and error messages so a novice can tell success from failure. Where possible, show how to prove that the change is effective beyond compilation (for example, through a small end-to-end scenario, a CLI invocation, or an HTTP request/response transcript). State the exact test commands appropriate to the project's toolchain and how to interpret their results.

Capture evidence. When your steps produce terminal output, short diffs, or logs, include them in fenced code blocks with an appropriate language tag (`text` for plain output, `diff` for patches, `log` or `console` for transcripts). Keep them concise and focused on what proves success. If you need to include a patch, prefer file-scoped diffs or small excerpts that a reader can recreate by following your instructions rather than pasting large blobs.


## Milestones

Milestones are narrative, not bureaucracy. If you break the work into milestones, introduce each with a brief paragraph that describes the scope, what will exist at the end of the milestone that did not exist before, the commands to run, and the acceptance you expect to observe. Keep it readable as a story: goal, work, result, proof. Progress and milestones are distinct: milestones tell the story, progress tracks granular work. Both must exist. Never abbreviate a milestone merely for the sake of brevity, do not leave out details that could be crucial to a future implementation.

Each milestone must be independently verifiable and incrementally implement the overall goal of the execution plan.


## Living Plan Sections

ExecPlans must contain and maintain a Progress section, a Surprises & Discoveries section, a Decision Log, and an Outcomes & Retrospective section. These are not optional.

When you discover optimizer behavior, performance tradeoffs, unexpected bugs, or inverse/unapply semantics that shaped your approach, capture those observations in the Surprises & Discoveries section with short evidence snippets (test output is ideal).

If you change course mid-implementation, document why in the Decision Log and reflect the implications in Progress. Plans are guides for the next contributor as much as checklists for you.

At completion of a major task or the full plan, write an Outcomes & Retrospective entry summarizing what was achieved, what remains, and lessons learned.

Before marking the full plan complete, perform the ADR distillation pass: promote durable project context from the Decision Log, Surprises & Discoveries, and Outcomes & Retrospective into `docs/adr/`, updating existing ADRs when they already cover the topic and creating a new ADR when the topic is new.


## Prototyping and Parallel Implementations

It is acceptable and often encouraged to include explicit prototyping milestones when they de-risk a larger change. Examples: adding a low-level operator to a dependency to validate feasibility, or exploring two composition orders while measuring optimizer effects. Keep prototypes additive and testable. Clearly label the scope as "prototyping"; describe how to run and observe results; and state the criteria for promoting or discarding the prototype.

Prefer additive code changes followed by subtractions that keep tests passing. Parallel implementations (e.g., keeping an adapter alongside an older path during migration) are fine when they reduce risk or enable tests to continue passing during a large migration. Describe how to validate both paths and how to retire one safely with tests. When working with multiple new libraries or feature areas, consider creating spikes that evaluate the feasibility of these features independently of one another, proving that the external library performs as expected and implements the features we need in isolation.


## Revision Protocol

When you revise a plan, you must ensure your changes are comprehensively reflected across all sections, including the living document sections, and you must write a note at the bottom of the plan describing the change and the reason why. ExecPlans must describe not just the what but the why for almost everything. If a revision changes durable project context, update the relevant ADR in `docs/adr/` in the same change.
