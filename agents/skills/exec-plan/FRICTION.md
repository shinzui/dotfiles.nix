# Friction Log Workflow for Plan Skills

This guide is shared by ExecPlans and MasterPlans. It governs how planning work records,
triages, and cites friction: the cost of doing the work.


## What friction is

Friction is a surface you used while implementing a plan costing you material effort: a
guide that omitted a step, a command whose help text did not match its behavior, a build
tool that needed an afternoon of retries, credentials that had to be re-issued, a house
process that asked the same question twice. A friction entry records what you attempted,
what happened instead, what it cost, and what you did about it. It makes no claim about
who is wrong.

That is what separates friction from the three places it is most often mistaken for:

- **Surprises & Discoveries** in the plan holds findings that changed the plan or explain
  a non-obvious result. Friction that did not change the plan has no place there. When
  one event is both, record both and cite the friction entry's handle from the plan.
- **A bug report** is a broken provision claim with a reproduction. Friction becomes a bug
  report at triage, once you can name the published claim the behavior contradicts and
  reproduce it.
- **An improvement request** is a gap a producer should close. Friction becomes a request
  at triage, once someone can state the outcome they want.

Friction is in the surfaces you used, not in the thing you are building. A defect in the
code the plan delivers is ordinary implementation work, not friction.

Record an entry when a surface cost more than a few minutes, forced a workaround, blocked
progress, or will recur for the next contributor. Do not record ordinary debugging of the
work itself, your own mistakes, or a transient failure that did not recur. Record it when
it happens, while the command and the error are in front of you, not at the end of the
session. One entry is one surface costing effort once; the same surface costing effort
again under another plan is a second entry, because recurrence is the signal the log
exists to surface.


## Where friction lives

Friction entries are OKF concepts in the repository's friction-log bundle, normally
`docs/friction-log/`, governed by the `coordination.frictionLog` profile published by
`mori://shinzui/okf-profiles`. Each entry is one Markdown file with a stable `FRIC-N`
handle, so an entry can be cited, promoted, and deduplicated, and so a surface's owner can
query friction across every repository that consumes it.

The bundle is bootstrapped on first use by the bundled script, through
`okf profile init`. That writes `profile.dhall` as a hash-pinned import of the profile,
declares the bundle version in `index.md`, and opens `log.md` with an adoption entry. The
first okf-profiles release that exports the profile is `v0.23.0`, which the script pins by
default. If that tag is not published yet, pass the local okf-profiles checkout instead and
repin when it is:

```bash
bun agents/skills/exec-plan/record-friction.ts init \
  --registry "$(mori path mori://shinzui/okf-profiles)/package.dhall"
```

A descriptor written from a local path imports the checkout by relative path and is not
portable. Replace it with the pinned remote import once the release exists, and run
`dhall freeze` on it.

When the repository has a `mori.dhall`, add the bundle to its `okfBundles` in the same
change that creates it, so Mori indexes the entries and resolves their canonical handles:

```dhall
Schema.OkfBundle::{
, name = "friction-log"
, path = "docs/friction-log"
, okfVersion = "0.2"
, profile = Some "docs/friction-log/profile.dhall"
, description = Some "Friction met while implementing plans, before triage into bug reports and requests"
}
```

If the repository uses a different bundle path or a local profile override, pass
`--bundle <dir>` and follow the local descriptor; the fields below are the shared
contract either way.


## Record an entry

Use the bundled script, never hand-authored frontmatter. It bootstraps the bundle when
needed, allocates the next handle through `okf id next`, writes the entry, appends to the
bundle's `log.md`, regenerates `index.md`, and validates the bundle strictly. It prints the
created file path to stdout.

```bash
bun agents/skills/exec-plan/record-friction.ts log \
  --title "<what cost effort, in one line>" \
  --description "<one sentence naming the surface and the cost>" \
  --kind <documentation|interface|tooling|environment|process> \
  --impact <blocked|detour|slowdown|nuisance> \
  --affects <uri> \
  --plan <plan-path> \
  --attempted "<what you were doing, with the exact command or step>" \
  --encountered "<what happened instead>" \
  [--evidence "<error text or transcript>"] \
  [--workaround "<what you did instead>"] \
  [--affected-version <version|unreleased|unknown>] \
  [--tag <tag>]... \
  --model <your-model-id> [--harness <name>]
```

Resolve your runtime model first, exactly as for plan provenance, following
`PROVENANCE.md`; every identity option that the provenance scripts accept works here, and
`generated.by` records the harness and model that observed the friction.

**`impact`** is what happened to the work, assigned by observation, most severe first.
`blocked`: the planned path could not proceed without a human or a change outside the
repository. `detour`: the work proceeded only through a workaround, which you must name
with `--workaround`. `slowdown`: the intended path worked but cost material time through
retries, re-reading, or trial and error. `nuisance`: no material cost; recorded because it
will recur. Take the most severe value that actually occurred.

**`kind`** is the sort of surface, not the cause. `documentation`: a guide, README, help
text, or reference page. `interface`: a CLI, API, schema, or type whose behavior differed
from what its name, types, or help text led you to expect. `tooling`: a build, test,
generation, lint, or packaging tool, or the agent harness itself. `environment`:
credentials, network, permissions, machine state, or installed versions. `process`: a
house workflow, skill instruction, convention, or review step.

**`origin`** is the Mori URI of this repository. The script derives it from `mori.dhall`
through `mori show --json`; pass `--origin mori://<namespace>/<project>` when the
repository has no Mori declaration.

**`affects`** is the project or artifact whose surface cost the effort. Use the canonical
Mori URI when the subject is registered: find it with `mori registry search <name>` and
use `mori://<namespace>/<project>`, or a more specific artifact URI such as a capability
or a guide when one applies. For an unregistered tool, use its canonical URL, such as its
repository or documentation home. When the surface is this repository's own process or
tooling, `affects` is the same URI as `origin`.

**`--plan`** is the repository-relative path of the plan you are implementing. Under a
MasterPlan, name the child ExecPlan; name the MasterPlan only for friction met while doing
coordination work on the MasterPlan itself.

**`--attempted`** and **`--encountered`** become the body's `## Attempted` and
`## Encountered` sections. Give the exact command or step and what happened, as fact.
Put the error text or transcript in `--evidence`; it is written as a fenced block.

If strict validation fails after the entry is written, the script exits non-zero and
leaves the file in place. Read the diagnostics, fix the entry, and re-run the validation
command the script prints. Never relax `--strict` or `--profile-enforce` to make it pass.


## Triage at completion

Before filling in Outcomes & Retrospective, list the entries recorded under the plan that
are still `logged`:

```bash
okf concepts docs/friction-log --where status=logged --where plan=<plan-path> \
  --show frictionId --show impact --show kind --show affects
```

For each, decide what it has become and record the decision with the script. Only the
recording repository moves an entry between statuses.

```bash
bun agents/skills/exec-plan/record-friction.ts update --id FRIC-<N> \
  --status <promoted|resolved|accepted|duplicate> \
  [--promoted-to <uri>] [--resolution "<one sentence>"] [--duplicate-of <FRIC-M|mori-uri>] \
  --change "<one line saying what was decided and why>" \
  --model <your-model-id> [--harness <name>]
```

- **`promoted`** when a bug report, improvement request, plan, or external issue now
  tracks the friction; `--promoted-to` names it. Promote to a bug report when you can name
  the published claim the behavior contradicts and reproduce it, and to an improvement
  request when you can state the outcome. File those through the repository's own
  bug-report or improvement-request bundle, or the affecting project's issue tracker, then
  record the URI here. Promotion is where a cause is named; the entry's `kind` stays what
  it was.
- **`resolved`** when the cause is gone, such as a fixed guide or a released version;
  `--resolution` says what changed.
- **`accepted`** when the house will live with it; `--resolution` says why.
- **`duplicate`** when another entry records the same occurrence; `--duplicate-of` names
  it. Two occurrences of the same cause are two entries, not a duplicate.

Leave an entry `logged` when triage cannot yet decide. That is an ordinary state, not a
deficiency. Each update appends an `amended` record, so `generated` keeps who observed the
friction, and appends to the bundle's `log.md`.

Then cite the entries in Outcomes & Retrospective by handle with their triage outcome, in
one sentence each. Friction that recurred across several plans is a lesson worth a
sentence in the retrospective and, when it changed durable project context, an ADR per
`ADR.md`. Under a MasterPlan, friction with the same surface under more than one child
plan belongs in the MasterPlan's Surprises & Discoveries with the handles, and is the
strongest case for promotion.


## Cite entries

Within the same repository, cite an entry by handle and bundle path, for example
`FRIC-3 in docs/friction-log/`, or by a repository-relative Markdown link to its file.
Across repositories, use the exact project-and-bundle-scoped handle-form URI that Mori
returns, of the form `mori://<namespace>/<project>/okf/friction-log/concepts/FRIC-3`.
Discover it through the registry rather than guessing:

```bash
mori registry concepts --id FRIC-3 --json
```


## Validate

The script validates after every write. The same command belongs in the repository's own
checks:

```bash
okf validate docs/friction-log \
  --strict \
  --profile docs/friction-log/profile.dhall \
  --profile-enforce \
  --log-enforce
```

Mori's observation-time diagnostics are advisory; this failing repository check is the
gate.
