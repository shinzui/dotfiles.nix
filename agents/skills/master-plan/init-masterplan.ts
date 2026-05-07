#!/usr/bin/env bun
import { parseArgs } from "node:util";
import { existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const USAGE = `Usage: bun init-masterplan.ts --title "<title>" [options]

Creates a new MasterPlan markdown file with YAML frontmatter and the canonical
skeleton, then prints the created file path to stdout.

Options:
  --title <text>          (required) Human-readable initiative title.
  --intention <id>        Intention ID to record in frontmatter.
  --dir <path>            Directory to write into. Defaults to docs/masterplans.
  -h, --help              Show this message.

The next sequential number is chosen by scanning <dir> for files matching
"<N>-<slug>.md" and using max(N) + 1. Gaps are not filled. The script never
overwrites an existing file.`;

function die(msg: string, code = 1): never {
  console.error(`init-masterplan: ${msg}`);
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
        dir: { type: "string", default: "docs/masterplans" },
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
fm.push(`kind: master-plan`);
fm.push(`created_at: ${createdAt}`);
if (values.intention) fm.push(`intention: ${yamlString(values.intention)}`);
fm.push("---");
fm.push("");
fm.push("");

const skeleton = `# ${title}

This MasterPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.


## Vision & Scope

Explain in a few sentences what the system looks like after the entire initiative is
complete. State the user-visible behaviors that will be enabled. Describe the scope
boundary: what is included and what is explicitly excluded.


## Decomposition Strategy

Explain how and why the initiative was decomposed into these specific work streams.
Describe the principles that guided the decomposition (functional concerns, dependency
minimization, independent verifiability). State alternatives considered and why they
were rejected.


## Exec-Plan Registry

| # | Title | Path | Hard Deps | Soft Deps | Status |
|---|-------|------|-----------|-----------|--------|
| 1 | ... | docs/plans/... | None | None | Not Started |
| 2 | ... | docs/plans/... | EP-1 | None | Not Started |

Status values: Not Started, In Progress, Complete, Cancelled.
Hard Deps and Soft Deps reference other rows by their # prefix (e.g., EP-1, EP-3).


## Dependency Graph

Describe the ordering constraints between child plans in prose. Explain why each hard
dependency exists — what artifact or behavior from the earlier plan does the later plan
require? Identify which plans can proceed in parallel and under what conditions.


## Integration Points

For each shared artifact (type, module, configuration, database table) that multiple
child plans touch, document: which plans are involved, what the shared artifact is,
which plan is responsible for defining it, and how later plans should consume or extend
it.

(None identified, or list each integration point.)


## Progress

Track milestone-level progress across all child plans. Each entry names the child plan
and the milestone. This section provides an at-a-glance view of the entire initiative.

- [ ] EP-1: <first milestone description>
- [ ] EP-1: <second milestone description>
- [ ] EP-2: <first milestone description>


## Surprises & Discoveries

Document cross-plan insights, dependency changes, scope adjustments, or unexpected
interactions between child plans. Provide concise evidence.

(None yet.)


## Decision Log

Record every decomposition or coordination decision made while working on the master
plan.

- Decision: ...
  Rationale: ...
  Date: ...


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original vision.

(To be filled during and after implementation.)
`;

writeFileSync(path, fm.join("\n") + skeleton, "utf8");
console.log(path);
