#!/usr/bin/env bun
import { parseArgs } from "node:util";
import { spawnSync } from "node:child_process";
import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { isAbsolute, join, resolve } from "node:path";
import { modelHelp, modelOptions, resolveModel } from "./provenance-model.ts";

const PROFILE_EXPORT = "coordination.frictionLog";
const PROFILE_RELEASE = "v0.23.0";
const DEFAULT_REGISTRY = `https://raw.githubusercontent.com/shinzui/okf-profiles/${PROFILE_RELEASE}/package.dhall`;
const DEFAULT_BUNDLE = "docs/friction-log";
const HANDLE_PREFIX = "FRIC";
const BUNDLE_VERSION = "0.2";

const KINDS = ["documentation", "interface", "tooling", "environment", "process"];
const IMPACTS = ["blocked", "detour", "slowdown", "nuisance"];
const STATUSES = ["logged", "promoted", "resolved", "accepted", "duplicate"];

const USAGE = `Usage: bun record-friction.ts <log|update|init> [options]

Records friction -- the cost of doing planned work -- as OKF concepts in the
repository's friction-log bundle, governed by ${PROFILE_EXPORT} from okf-profiles.
See FRICTION.md for what to record and how to triage it.

Commands:
  init      Bootstrap the bundle (pinned profile.dhall, index.md, log.md) if it is
            missing. Prints the bundle path.
  log       Record one friction entry. Bootstraps the bundle when needed, allocates
            the next ${HANDLE_PREFIX}-N handle with okf, writes the entry, appends to
            log.md, regenerates index.md, and validates. Prints the entry path.
  update    Change an entry's triage status, appending an amended record and a log
            entry, then validates. Prints the entry path.

Common options:
  --bundle <dir>          Bundle directory. Defaults to ${DEFAULT_BUNDLE}.
  --registry <ref>        okf-profiles package to pin at bootstrap: a URL or a local
                          path to package.dhall. Defaults to $FRICTION_PROFILE_REGISTRY
                          or ${DEFAULT_REGISTRY}
${modelHelp}

log options:
  --title <text>          (required) What cost effort, in one line.
  --description <text>    (required) One sentence naming the surface and the cost.
  --kind <k>              (required) ${KINDS.join(" | ")}
  --impact <i>            (required) ${IMPACTS.join(" | ")}
  --affects <uri>         (required) Mori URI of the registered project or artifact
                          whose surface cost the effort, else its canonical URL.
  --attempted <text>      (required) What you were doing, with the exact command/step.
  --encountered <text>    (required) What happened instead, as fact.
  --origin <uri>          Mori URI of this repository. Derived from mori.dhall through
                          \`mori show --json\` when omitted.
  --plan <path>           Repository-relative path of the plan being implemented.
  --evidence <text>       Error text or transcript, written as a fenced block.
  --workaround <text>     What you did instead. Required when --impact is detour.
  --affected-version <v>  Released version of the affecting surface; unreleased|unknown.
  --tag <tag>             Grouping tag; repeatable.

update options:
  --id ${HANDLE_PREFIX}-<N>            (required) The entry to update.
  --status <s>            (required) ${STATUSES.join(" | ")}
  --promoted-to <uri>     Required when --status is promoted.
  --resolution <text>     Required when --status is resolved or accepted.
  --duplicate-of <ref>    Required when --status is duplicate: ${HANDLE_PREFIX}-<M> or a Mori URI.
  --workaround <text>     Set or replace the workaround.
  --change <text>         One line saying what was decided and why. Defaults to the
                          status change.

  -h, --help              Show this message.`;

function die(msg: string, code = 1): never {
  console.error(`record-friction: ${msg}`);
  process.exit(code);
  throw new Error(msg);
}

const { values, positionals } = (() => {
  try {
    return parseArgs({
      args: process.argv.slice(2),
      options: {
        bundle: { type: "string", default: DEFAULT_BUNDLE },
        registry: { type: "string" },
        ...modelOptions,
        title: { type: "string" },
        description: { type: "string" },
        kind: { type: "string" },
        impact: { type: "string" },
        affects: { type: "string" },
        origin: { type: "string" },
        plan: { type: "string" },
        attempted: { type: "string" },
        encountered: { type: "string" },
        evidence: { type: "string" },
        workaround: { type: "string" },
        "affected-version": { type: "string" },
        tag: { type: "string", multiple: true },
        id: { type: "string" },
        status: { type: "string" },
        "promoted-to": { type: "string" },
        resolution: { type: "string" },
        "duplicate-of": { type: "string" },
        change: { type: "string" },
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

if (positionals.length !== 1 || !["log", "update", "init"].includes(positionals[0])) {
  console.error(USAGE);
  die("exactly one command is required: log, update, or init");
}
const command = positionals[0] as "log" | "update" | "init";

const bundle = values.bundle!;
const profilePath = join(bundle, "profile.dhall");
const registry = values.registry ?? process.env.FRICTION_PROFILE_REGISTRY ?? DEFAULT_REGISTRY;

function text(name: string, required: boolean): string | undefined {
  const v = (values as Record<string, unknown>)[name];
  const t = typeof v === "string" ? v.trim() : "";
  if (!t) {
    if (required) {
      console.error(USAGE);
      die(`--${name} is required for ${command}`);
    }
    return undefined;
  }
  return t;
}

function oneOf(name: string, allowed: string[], required: boolean): string | undefined {
  const v = text(name, required);
  if (v !== undefined && !allowed.includes(v)) {
    die(`invalid --${name} "${v}" (expected one of: ${allowed.join(", ")})`);
  }
  return v;
}

function yamlString(v: string): string {
  return JSON.stringify(v);
}

function run(cmd: string, args: string[], opts: { allowFailure?: boolean } = {}) {
  const result = spawnSync(cmd, args, { encoding: "utf8" });
  if (result.error) {
    if ((result.error as NodeJS.ErrnoException).code === "ENOENT") {
      die(`"${cmd}" is not on PATH; install it before recording friction`);
    }
    die(`${cmd} ${args.join(" ")} failed: ${result.error.message}`);
  }
  if (result.status !== 0 && !opts.allowFailure) {
    die(`${cmd} ${args.join(" ")} exited ${result.status}:\n${result.stdout}${result.stderr}`);
  }
  return { code: result.status ?? 1, stdout: result.stdout, stderr: result.stderr };
}

function isUri(v: string): boolean {
  return /^[a-z][a-z0-9+.-]*:\/\/\S+$/i.test(v);
}

function slugify(s: string): string {
  return s
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function nowUtc(): string {
  return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
}

// §7 actor for who observed the friction: `<harness>/<model>` as the house's
// own ADRs record agent authorship, or a process actor when no harness is known.
function actorFor(identity: { model: string; harness?: string }): string {
  const model = identity.model.replace(/[^A-Za-z0-9._-]+/g, "-");
  return identity.harness ? `${identity.harness}/${model}` : `process:${model}`;
}

function ensureBundle(): boolean {
  if (existsSync(profilePath)) return false;
  const ref = /^[a-z][a-z0-9+.-]*:\/\//i.test(registry) || isAbsolute(registry) ? registry : resolve(registry);
  if (!/^[a-z][a-z0-9+.-]*:\/\//i.test(ref) && !existsSync(ref)) {
    die(`--registry ${registry} does not exist`);
  }
  const init = run(
    "okf",
    ["profile", "init", PROFILE_EXPORT, "--no-local", "--registry", ref, "--bundle", bundle, "--write"],
    { allowFailure: true },
  );
  if (init.code !== 0 || !existsSync(profilePath)) {
    console.error(init.stdout + init.stderr);
    if (ref === DEFAULT_REGISTRY) {
      console.error(
        `record-friction: the default registry pins okf-profiles ${PROFILE_RELEASE}, the first release ` +
          `exporting ${PROFILE_EXPORT}. If that tag is not published yet, bootstrap from a local checkout ` +
          `(\`--registry "$(mori path mori://shinzui/okf-profiles)/package.dhall"\`) and repin the descriptor ` +
          `with the release later; see FRICTION.md.`,
      );
    }
    die(`okf profile init could not bootstrap ${bundle}`);
  }
  console.error(init.stdout.trimEnd());
  if (existsSync("mori.dhall")) {
    console.error(
      `record-friction: ${bundle} was bootstrapped; add it to okfBundles in mori.dhall in the same change (see FRICTION.md)`,
    );
  }
  return true;
}

function deriveOrigin(): string {
  const explicit = text("origin", false);
  if (explicit) {
    if (!/^mori:\/\/[^/\s]+\/[^/\s]+/.test(explicit)) die(`--origin must be a mori://<namespace>/<project> URI, got "${explicit}"`);
    return explicit;
  }
  if (existsSync("mori.dhall")) {
    const shown = run("mori", ["show", "--json"], { allowFailure: true });
    if (shown.code === 0) {
      try {
        const project = (JSON.parse(shown.stdout) as { project?: { namespace?: string; name?: string } }).project;
        if (project?.namespace && project?.name) return `mori://${project.namespace}/${project.name}`;
      } catch {
        // fall through to the explicit requirement below
      }
    }
  }
  die("--origin is required: pass this repository's mori://<namespace>/<project> URI (no readable mori.dhall was found)");
}

function validate(): number {
  const result = run(
    "okf",
    ["validate", bundle, "--strict", "--profile", profilePath, "--profile-enforce", "--log-enforce"],
    { allowFailure: true },
  );
  console.error((result.stdout + result.stderr).trimEnd());
  if (result.code !== 0) {
    console.error(
      `record-friction: strict validation failed; fix the entry and re-run: okf validate ${bundle} --strict --profile ${profilePath} --profile-enforce --log-enforce`,
    );
  }
  return result.code;
}

function logAdd(kind: string, message: string) {
  run("okf", ["log", "add", bundle, "--kind", kind, "-m", message]);
}

function reindex() {
  run("okf", ["index", bundle, "--write", "--okf-version", BUNDLE_VERSION]);
}

type Entry = { path: string; fm: string[]; rest: string[] };

function readEntry(path: string): Entry {
  const lines = readFileSync(path, "utf8").split("\n");
  if (!/^---\s*$/.test(lines[0] ?? "")) die(`${path}: no YAML frontmatter`);
  const close = lines.findIndex((l, i) => i > 0 && /^---\s*$/.test(l));
  if (close === -1) die(`${path}: frontmatter opens with --- but is never closed`);
  return { path, fm: lines.slice(1, close), rest: lines.slice(close + 1) };
}

function writeEntry(entry: Entry) {
  writeFileSync(entry.path, ["---", ...entry.fm, "---", ...entry.rest].join("\n"), "utf8");
}

function findEntry(id: string): Entry {
  if (!existsSync(bundle)) die(`no bundle at ${bundle}`);
  const matches: Entry[] = [];
  for (const name of readdirSync(bundle)) {
    if (!name.endsWith(".md") || name === "index.md" || name === "log.md") continue;
    const entry = readEntry(join(bundle, name));
    if (entry.fm.some((l) => new RegExp(`^frictionId:\\s*"?${id}"?\\s*$`).test(l))) matches.push(entry);
  }
  if (matches.length === 0) die(`no entry in ${bundle} carries frictionId ${id}`);
  if (matches.length > 1) die(`${id} is carried by several entries: ${matches.map((m) => m.path).join(", ")}`);
  return matches[0];
}

// Extent of a top-level frontmatter key: its line plus following lines that are
// blank or indented. Returns [start, end) or null.
function keyExtent(fm: string[], key: string): [number, number] | null {
  const start = fm.findIndex((l) => new RegExp(`^${key}:`).test(l));
  if (start === -1) return null;
  let end = start + 1;
  while (end < fm.length && (fm[end].trim() === "" || /^\s/.test(fm[end]))) end++;
  while (end > start + 1 && fm[end - 1].trim() === "") end--;
  return [start, end];
}

function setScalar(entry: Entry, key: string, value: string) {
  const line = `${key}: ${yamlString(value)}`;
  const extent = keyExtent(entry.fm, key);
  if (extent) entry.fm.splice(extent[0], extent[1] - extent[0], line);
  else entry.fm.push(line);
}

function appendAmended(entry: Entry, by: string, at: string, change: string) {
  const item = [`  - by: ${yamlString(by)}`, `    at: ${yamlString(at)}`, `    change: ${yamlString(change)}`];
  const extent = keyExtent(entry.fm, "amended");
  if (extent) {
    if (/^amended:\s*\S/.test(entry.fm[extent[0]]) && !/^amended:\s*\[\]\s*$/.test(entry.fm[extent[0]])) {
      die(`${entry.path}: amended is written inline; rewrite it as a block list before updating`);
    }
    entry.fm.splice(extent[0], extent[1] - extent[0], "amended:", ...entry.fm.slice(extent[0] + 1, extent[1]), ...item);
  } else {
    entry.fm.push("amended:", ...item);
  }
}

function identityOrDie() {
  try {
    return resolveModel(values);
  } catch (e) {
    die((e as Error).message);
  }
}

if (command === "init") {
  const created = ensureBundle();
  if (!created) console.error(`record-friction: ${bundle} already carries a profile descriptor; nothing to do`);
  console.log(bundle);
  process.exit(0);
}

if (command === "log") {
  const title = text("title", true)!;
  const description = text("description", true)!;
  const kind = oneOf("kind", KINDS, true)!;
  const impact = oneOf("impact", IMPACTS, true)!;
  const affects = text("affects", true)!;
  if (!isUri(affects)) die(`--affects must be an absolute URI (a mori:// URI or a canonical URL), got "${affects}"`);
  const attempted = text("attempted", true)!;
  const encountered = text("encountered", true)!;
  const workaround = text("workaround", false);
  if (impact === "detour" && !workaround) die("--workaround is required when --impact is detour");
  const plan = text("plan", false);
  const evidence = text("evidence", false);
  const affectedVersion = text("affected-version", false);
  const tags = (values.tag ?? []).map((t) => t.trim()).filter(Boolean);
  for (const name of ["id", "status", "promoted-to", "resolution", "duplicate-of", "change"]) {
    if (text(name, false)) die(`--${name} applies to update, not log`);
  }
  const identity = identityOrDie();
  const origin = deriveOrigin();
  const slug = slugify(title);
  if (!slug) die(`title "${title}" produced an empty slug`);

  ensureBundle();
  const next = run("okf", ["id", "next", bundle, HANDLE_PREFIX, "--profile", profilePath]).stdout.trim();
  const m = new RegExp(`^${HANDLE_PREFIX}-(\\d+)$`).exec(next);
  if (!m) die(`okf id next returned "${next}", expected ${HANDLE_PREFIX}-<N>`);
  const n = parseInt(m[1], 10);
  const path = join(bundle, `${n}-${slug}.md`);
  if (existsSync(path)) die(`refusing to overwrite ${path}`);

  const at = nowUtc();
  const fm: string[] = [
    "---",
    "type: Friction Entry",
    `title: ${yamlString(title)}`,
    `description: ${yamlString(description)}`,
    "generated:",
    `  by: ${yamlString(actorFor(identity))}`,
    `  at: ${yamlString(at)}`,
    `frictionId: ${next}`,
    "status: logged",
    `impact: ${impact}`,
    `kind: ${kind}`,
    `origin: ${yamlString(origin)}`,
    `affects: ${yamlString(affects)}`,
  ];
  if (affectedVersion) fm.push(`affectedVersion: ${yamlString(affectedVersion)}`);
  if (plan) fm.push(`plan: ${yamlString(plan)}`);
  if (workaround) fm.push(`workaround: ${yamlString(workaround)}`);
  if (tags.length) fm.push("tags:", ...tags.map((t) => `  - ${yamlString(t)}`));
  fm.push("---", "");

  const body: string[] = [`# ${title}`, "", "## Attempted", "", attempted, "", "## Encountered", "", encountered, ""];
  if (evidence) body.push("```text", evidence.replace(/\n+$/, ""), "```", "");
  if (workaround) body.push("## Workaround", "", workaround, "");
  if (identity.note) body.push(`Recorded with ${identity.note.charAt(0).toLowerCase()}${identity.note.slice(1)}.`, "");

  writeFileSync(path, fm.join("\n") + body.join("\n"), "utf8");
  logAdd("Addition", `${next} records ${impact} ${kind} friction with ${affects}: ${title}`);
  reindex();
  const code = validate();
  console.log(path);
  process.exit(code);
}

// command === "update"
const id = text("id", true)!;
if (!new RegExp(`^${HANDLE_PREFIX}-[1-9][0-9]*$`).test(id)) die(`--id must look like ${HANDLE_PREFIX}-<N>, got "${id}"`);
const status = oneOf("status", STATUSES, true)!;
const promotedTo = text("promoted-to", false);
const resolution = text("resolution", false);
const duplicateOf = text("duplicate-of", false);
const workaround = text("workaround", false);
for (const name of ["title", "description", "kind", "impact", "affects", "attempted", "encountered", "evidence", "plan", "affected-version"]) {
  if (text(name, false)) die(`--${name} applies to log, not update`);
}
if (status === "promoted" && !promotedTo) die("--promoted-to is required when --status is promoted");
if (promotedTo && !isUri(promotedTo)) die(`--promoted-to must be an absolute URI, got "${promotedTo}"`);
if ((status === "resolved" || status === "accepted") && !resolution) die(`--resolution is required when --status is ${status}`);
if (status === "duplicate" && !duplicateOf) die("--duplicate-of is required when --status is duplicate");
if (duplicateOf && !new RegExp(`^(${HANDLE_PREFIX}-[1-9][0-9]*|mori://\\S+)$`).test(duplicateOf)) {
  die(`--duplicate-of must be ${HANDLE_PREFIX}-<M> or a mori:// URI, got "${duplicateOf}"`);
}
if (duplicateOf === id) die(`${id} cannot duplicate itself`);
const identity = identityOrDie();
const entry = findEntry(id);
const at = nowUtc();
const change = text("change", false) ?? `Status set to ${status}.`;

setScalar(entry, "status", status);
if (promotedTo) setScalar(entry, "promotedTo", promotedTo);
if (resolution) setScalar(entry, "resolution", resolution);
if (duplicateOf) setScalar(entry, "duplicateOf", duplicateOf);
if (workaround) setScalar(entry, "workaround", workaround);
appendAmended(entry, actorFor(identity), at, change);
writeEntry(entry);
logAdd("Update", `${id} ${status}: ${change}`);
reindex();
const code = validate();
console.log(entry.path);
process.exit(code);
