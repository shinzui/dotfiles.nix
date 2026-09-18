#!/usr/bin/env bun
import { parseArgs } from "node:util";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { modelHelp, modelOptions, resolveModel } from "./provenance-model.ts";

const USAGE = `Usage: bun record-provenance.ts <review|revision> --plan <path> <identity options> [options]

Appends one provenance entry to the YAML frontmatter of an ExecPlan or MasterPlan.
Entries are only ever appended: existing entries are never rewritten, reordered, or
removed, so several models can record reviews of the same plan without clobbering
one another.

Events:
  review      Appended to provenance.reviews.
  revision    Appended to provenance.revisions. Requires --mode.

Options:
  --plan <path>       (required) Path to the plan markdown file.
${modelHelp}
  --verdict <v>       review only: approved | changes-requested | comments.
                      Defaults to comments.
  --mode <m>          revision only: implement | update | discuss | other.
  --note <text>       One-line summary of what was reviewed or changed.
  --at <timestamp>    ISO-8601 UTC timestamp. Defaults to now.
  --allow-duplicate   Record the entry even when it repeats the newest entry of the
                      same kind (same model, same verdict or mode, same note, same
                      UTC day). Without this flag such a repeat is skipped.
  -h, --help          Show this message.

Plans created before provenance existed carry no provenance block. The script adds
one containing only the new entry; it never invents a created_by record and never
touches any other frontmatter key. Prints the recorded entry to stdout.`;

const VERDICTS = ["approved", "changes-requested", "comments"];
const MODES = ["implement", "update", "discuss", "other"];

function die(msg: string, code = 1): never {
  console.error(`record-provenance: ${msg}`);
  process.exit(code);
  throw new Error(msg);
}

const { values, positionals } = (() => {
  try {
    return parseArgs({
      args: process.argv.slice(2),
      options: {
        plan: { type: "string" },
        ...modelOptions,
        verdict: { type: "string" },
        mode: { type: "string" },
        note: { type: "string" },
        at: { type: "string" },
        "allow-duplicate": { type: "boolean", default: false },
        help: { type: "boolean", short: "h" },
      },
      strict: true,
      allowPositionals: true,
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

if (positionals.length !== 1) {
  console.error(USAGE);
  die("exactly one event kind is required: review or revision");
}

const kind = positionals[0];
if (kind !== "review" && kind !== "revision") {
  console.error(USAGE);
  die(`unknown event kind "${kind}" (expected review or revision)`);
}

const planPath = values.plan;
if (!planPath || !planPath.trim()) {
  console.error(USAGE);
  die("--plan is required");
}
if (!existsSync(planPath)) die(`no such file: ${planPath}`);

const identity = (() => {
  try {
    return resolveModel(values);
  } catch (e) {
    die((e as Error).message);
  }
})();
const { model, harness } = identity;

if (kind === "review" && values.mode) die("--mode applies to revision entries, not reviews");
if (kind === "revision" && values.verdict) die("--verdict applies to reviews, not revision entries");

const verdict = kind === "review" ? (values.verdict ?? "comments") : undefined;
if (verdict !== undefined && !VERDICTS.includes(verdict)) {
  die(`invalid --verdict "${verdict}" (expected one of: ${VERDICTS.join(", ")})`);
}

const mode = kind === "revision" ? values.mode : undefined;
if (kind === "revision") {
  if (!mode) {
    console.error(USAGE);
    die("--mode is required for revision entries");
  }
  if (!MODES.includes(mode)) {
    die(`invalid --mode "${mode}" (expected one of: ${MODES.join(", ")})`);
  }
}

const at = (() => {
  if (!values.at) return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
  if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$/.test(values.at)) {
    die(`invalid --at "${values.at}" (expected an ISO-8601 UTC timestamp like 2026-01-31T09:15:00Z)`);
  }
  return values.at.replace(/\.\d+Z$/, "Z");
})();

const note = [values.note?.trim(), identity.note].filter(Boolean).join("; ") || undefined;
const listKey = kind === "review" ? "reviews" : "revisions";

function yamlString(v: string): string {
  return JSON.stringify(v);
}

function unquote(v: string): string {
  const t = v.trim();
  if (t.startsWith('"')) {
    try {
      return JSON.parse(t) as string;
    } catch {
      return t;
    }
  }
  return t;
}

function indentOf(line: string): string {
  return /^(\s*)/.exec(line)![1];
}

const original = readFileSync(planPath, "utf8");
const lines = original.split("\n");

// Split off the YAML frontmatter block, if the file has one. Only a `---` on the
// very first line opens frontmatter; anything else means the plan predates it.
let fm: string[];
let rest: string[];
let hadFrontmatter = false;
if (lines.length > 0 && /^---\s*$/.test(lines[0])) {
  let close = -1;
  for (let i = 1; i < lines.length; i++) {
    if (/^---\s*$/.test(lines[i])) {
      close = i;
      break;
    }
  }
  if (close === -1) die(`${planPath}: frontmatter opens with --- but is never closed`);
  hadFrontmatter = true;
  fm = lines.slice(1, close);
  rest = lines.slice(close + 1);
} else {
  fm = [];
  rest = lines;
}

const entryLines = (itemIndent: string): string[] => {
  const out = [`${itemIndent}- model: ${yamlString(model)}`];
  const cont = `${itemIndent}  `;
  if (harness) out.push(`${cont}harness: ${yamlString(harness)}`);
  out.push(`${cont}at: ${at}`);
  if (verdict) out.push(`${cont}verdict: ${yamlString(verdict)}`);
  if (mode) out.push(`${cont}mode: ${yamlString(mode)}`);
  if (note) out.push(`${cont}note: ${yamlString(note)}`);
  return out;
};

function parseEntries(from: number, to: number, itemIndent: string): Record<string, string>[] {
  const entries: Record<string, string>[] = [];
  const itemRe = new RegExp(`^${itemIndent}-\\s+(\\w+):\\s*(.*)$`);
  const contRe = new RegExp(`^${itemIndent}\\s+(\\w+):\\s*(.*)$`);
  for (let i = from; i < to; i++) {
    const item = itemRe.exec(fm[i]);
    if (item) {
      entries.push({ [item[1]]: unquote(item[2]) });
      continue;
    }
    const cont = contRe.exec(fm[i]);
    if (cont && entries.length > 0) entries[entries.length - 1][cont[1]] = unquote(cont[2]);
  }
  return entries;
}

function isDuplicate(entries: Record<string, string>[]): boolean {
  const newest = entries[entries.length - 1];
  if (!newest) return false;
  if (newest.model !== model) return false;
  if ((newest.note ?? "") !== (note ?? "")) return false;
  if (verdict !== undefined && (newest.verdict ?? "comments") !== verdict) return false;
  if (mode !== undefined && newest.mode !== mode) return false;
  return (newest.at ?? "").slice(0, 10) === at.slice(0, 10);
}

function skipDuplicate(): never {
  console.error(
    `record-provenance: ${planPath} already records this ${kind} by ${model} on ${at.slice(0, 10)}; ` +
      `nothing written (pass --allow-duplicate to record it anyway)`,
  );
  process.exit(0);
  throw new Error("unreachable");
}

// Locate `provenance:` at the top level of the frontmatter.
let provIdx = -1;
for (let i = 0; i < fm.length; i++) {
  const m = /^provenance:(.*)$/.exec(fm[i]);
  if (!m) continue;
  const trailing = m[1].trim();
  if (trailing && !trailing.startsWith("#")) {
    die(
      `${planPath}: frontmatter has an inline provenance value (${fm[i].trim()}); ` +
        `rewrite it as a nested block before recording entries`,
    );
  }
  provIdx = i;
  break;
}

if (provIdx === -1) {
  // No provenance block yet — normal for plans created before provenance existed.
  // Append one holding only this entry; never fabricate a created_by record.
  while (fm.length > 0 && fm[fm.length - 1].trim() === "") fm.pop();
  fm.push("provenance:", `  ${listKey}:`, ...entryLines("    "));
} else {
  // Extent of the provenance block: following lines that are blank or indented.
  let blockEnd = provIdx + 1;
  while (blockEnd < fm.length && (fm[blockEnd].trim() === "" || /^\s/.test(fm[blockEnd]))) blockEnd++;
  while (blockEnd > provIdx + 1 && fm[blockEnd - 1].trim() === "") blockEnd--;

  let listIdx = -1;
  let listIndent = "";
  for (let i = provIdx + 1; i < blockEnd; i++) {
    const m = new RegExp(`^(\\s+)${listKey}:(.*)$`).exec(fm[i]);
    if (!m) continue;
    const trailing = m[2].trim();
    if (trailing === "[]") {
      fm[i] = `${m[1]}${listKey}:`;
    } else if (trailing && !trailing.startsWith("#")) {
      die(
        `${planPath}: provenance.${listKey} is written inline (${fm[i].trim()}); ` +
          `rewrite it as a block list before recording entries`,
      );
    }
    listIdx = i;
    listIndent = m[1];
    break;
  }

  if (listIdx === -1) {
    // The block exists but has no list of this kind yet. Match the block's own
    // indentation so hand-formatted frontmatter stays internally consistent.
    let childIndent = "  ";
    for (let i = provIdx + 1; i < blockEnd; i++) {
      if (fm[i].trim() !== "") {
        childIndent = indentOf(fm[i]);
        break;
      }
    }
    fm.splice(blockEnd, 0, `${childIndent}${listKey}:`, ...entryLines(`${childIndent}  `));
  } else {
    // Extent of the list: lines indented deeper than the list key itself.
    let listEnd = listIdx + 1;
    while (listEnd < blockEnd) {
      const line = fm[listEnd];
      if (line.trim() === "") {
        listEnd++;
        continue;
      }
      if (indentOf(line).length <= listIndent.length) break;
      listEnd++;
    }
    while (listEnd > listIdx + 1 && fm[listEnd - 1].trim() === "") listEnd--;

    let itemIndent = `${listIndent}  `;
    for (let i = listIdx + 1; i < listEnd; i++) {
      const m = /^(\s+)-\s/.exec(fm[i]);
      if (m) {
        itemIndent = m[1];
        break;
      }
    }

    if (!values["allow-duplicate"] && isDuplicate(parseEntries(listIdx + 1, listEnd, itemIndent))) {
      skipDuplicate();
    }
    fm.splice(listEnd, 0, ...entryLines(itemIndent));
  }
}

const out = hadFrontmatter
  ? ["---", ...fm, "---", ...rest].join("\n")
  : ["---", ...fm, "---", "", ...rest].join("\n");

writeFileSync(planPath, out, "utf8");

const detail = verdict ? `verdict ${verdict}` : `mode ${mode}`;
console.log(`${planPath}: recorded ${kind} by ${model} (${detail}) at ${at}`);
