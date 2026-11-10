#!/usr/bin/env bun
import { parseArgs } from "node:util";
import { existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { modelHelp, modelOptions, resolveModel } from "./provenance-model.ts";

const USAGE = `Usage: bun init-plan.ts --title "<title>" [options]

Creates a new ExecPlan markdown file with YAML frontmatter and the canonical
skeleton, then prints the created file path to stdout.

Options:
  --title <text>          (required) Human-readable plan title.
  --intention <id>        Intention ID to record in frontmatter.
  --master-plan <path>    Path to the parent MasterPlan, recorded in frontmatter.
${modelHelp}
  --dir <path>            Directory to write into. Defaults to docs/plans.
  -h, --help              Show this message.

The next sequential number is chosen by scanning <dir> for files matching
"<N>-<slug>.md" and using max(N) + 1. Gaps are not filled. The script never
overwrites an existing file.`;

function die(msg: string, code = 1): never {
  console.error(`init-plan: ${msg}`);
  process.exit(code);
  throw new Error(msg);
}

const { values } = (() => {
  try {
    return parseArgs({
      args: process.argv.slice(2),
      options: {
        title: { type: "string" },
        intention: { type: "string" },
        "master-plan": { type: "string" },
        ...modelOptions,
        dir: { type: "string", default: "docs/plans" },
        help: { type: "boolean", short: "h" },
      },
      strict: true,
      allowPositionals: false,
    });
  } catch (e) {
    console.error(USAGE);
    die((e as Error).message);
  }
})();

if (values.help) {
  console.log(USAGE);
  process.exit(0);
}

const title = values.title;
if (!title || !title.trim()) {
  console.error(USAGE);
  die("--title is required");
}

const identity = (() => {
  try {
    return resolveModel(values);
  } catch (e) {
    die((e as Error).message);
  }
})();

const dir = values.dir!;

function slugify(s: string): string {
  return s
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

const slug = slugify(title);
if (!slug) die(`title "${title}" produced an empty slug`);

if (!existsSync(dir)) mkdirSync(dir, { recursive: true });

let nextN = 1;
for (const entry of readdirSync(dir)) {
  if (!entry.endsWith(".md")) continue;
  const m = entry.match(/^(\d+)-/);
  if (!m) continue;
  const n = parseInt(m[1], 10);
  if (n >= nextN) nextN = n + 1;
}

const filename = `${nextN}-${slug}.md`;
const path = join(dir, filename);
if (existsSync(path)) die(`refusing to overwrite ${path}`);

const createdAt = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");

function yamlString(v: string): string {
  return JSON.stringify(v);
}

const fm: string[] = ["---"];
fm.push(`id: ${nextN}`);
fm.push(`slug: ${slug}`);
fm.push(`title: ${yamlString(title)}`);
fm.push(`kind: exec-plan`);
fm.push(`created_at: ${createdAt}`);
if (values.intention) fm.push(`intention: ${yamlString(values.intention)}`);
if (values["master-plan"]) fm.push(`master_plan: ${yamlString(values["master-plan"])}`);
fm.push("provenance:");
fm.push("  created_by:");
fm.push(`    model: ${yamlString(identity.model)}`);
if (identity.harness) fm.push(`    harness: ${yamlString(identity.harness)}`);
fm.push(`    at: ${createdAt}`);
if (identity.note) fm.push(`    note: ${yamlString(identity.note)}`);
fm.push("---");
fm.push("");
fm.push("");

const skeleton = `# ${title}

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.
Record friction met while implementing in the friction-log bundle as it occurs (see FRICTION.md).


## Purpose / Big Picture

Explain in a few sentences what someone gains after this change and how they can see it
working. State the user-visible behavior you will enable.


## Progress

Use checkboxes for verifiable milestones or substantial deliverables, not individual
edits, commands, tests, commits, or session activity. Update this section when a milestone
is accepted, a material blocker or change of course arises, or work is handed off. For a
handoff during a milestone, add a short prose note stating the remaining outcome.

- [ ] <First verifiable milestone or deliverable and its acceptance condition.>


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence. Friction with the tools, documents, and processes
used to do the work belongs in the friction log (see FRICTION.md); cite an entry's FRIC-N
handle here only when it also changed the plan.

(None yet.)


## Decision Log

Record decisions that change scope, architecture, interfaces, acceptance, or the path a
future contributor should follow. Omit routine implementation choices.

- Decision: ...
  Rationale: ...
  Date: ...


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose. Cite the friction entries recorded under
this plan by handle with their triage outcome. Before marking the plan complete,
distill durable project context from the Decision Log, Surprises & Discoveries, and
this section into docs/adr/. Keep task-local execution details here.

(To be filled during and after implementation.)


## Context and Orientation

Describe the current state relevant to this task as if the reader knows nothing. Name the
key files and modules by full path. Define any non-obvious term you will use. Do not refer
to prior plans unless they are checked into the repository, in which case reference them by
path. Follow the skill's ADR.md workflow: scan local filenames and headings, read only ADRs
relevant to this work, and summarize them here with repository-relative links. Cite a
cross-repository ADR only with the exact canonical handle returned by Mori. If no relevant
ADR exists, say so.


## Plan of Work

Describe the sequence of meaningful changes in prose. Name key files and locations
(functions or modules) and the intended result, leaving routine edit choices open.

Break into milestones if the work spans multiple independent phases. Each milestone must be
independently verifiable. Introduce each milestone with a brief paragraph: scope, what will
exist at the end, commands to run, acceptance criteria.


## Concrete Steps

State the exact commands to run and where to run them (working directory). When a command
generates output, show a short expected transcript so the reader can compare. This section
should be revised when the implementation approach changes.


## Validation and Acceptance

Describe how to exercise the system and what to observe. Phrase acceptance as behavior with
specific inputs and outputs. If tests are involved, name the exact test commands and expected
results. Show that the change is effective beyond compilation.
If an uncertain interface connects independently developed pieces, identify an early
representative interaction check appropriate to the project and authorized environment.
Distinguish required acceptance from proposals for additional scope.


## Idempotence and Recovery

If steps can be repeated safely, say so. If a step is risky, provide a safe retry or
rollback path.


## Interfaces and Dependencies

Name the libraries, modules, and services whose choice matters. Specify key types or
interfaces that other work depends on, using full module paths.
For a child plan, identify prerequisite artifacts or behavior and the parent-declared
plan or milestone that must be accepted before this work begins.
`;

writeFileSync(path, fm.join("\n") + skeleton, "utf8");
console.log(path);
