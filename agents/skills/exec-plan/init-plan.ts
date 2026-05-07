#!/usr/bin/env bun
import { parseArgs } from "node:util";
import { existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const USAGE = `Usage: bun init-plan.ts --title "<title>" [options]

Creates a new ExecPlan markdown file with YAML frontmatter and the canonical
skeleton, then prints the created file path to stdout.

Options:
  --title <text>          (required) Human-readable plan title.
  --intention <id>        Intention ID to record in frontmatter.
  --master-plan <path>    Path to the parent MasterPlan, recorded in frontmatter.
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
fm.push("---");
fm.push("");
fm.push("");

const skeleton = `# ${title}

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.


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
function signatures that must exist at the end of each milestone. Use full module paths.
`;

writeFileSync(path, fm.join("\n") + skeleton, "utf8");
console.log(path);
