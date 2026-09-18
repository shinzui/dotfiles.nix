# ADR Workflow for Plan Skills

This guide is shared by ExecPlans and MasterPlans. It governs how planning work discovers,
creates, updates, validates, and cites Architecture Decision Records (ADRs).


## Discover the repository's ADR contract

ADRs normally live in `docs/adr/`. Always scan filenames and headings first, then read only
the records relevant to the current work. Do not bulk-load the corpus.

Before writing an ADR, inspect the repository rather than assuming one universal format:

1. Read repository-local instructions and existing ADRs.
2. If `mori.dhall` exists, inspect it with `mori show --full` and find any OKF bundle whose
   path is `docs/adr`.
3. If that bundle declares a profile, read and type-check the local descriptor named by the
   manifest. The descriptor and existing valid ADRs are authoritative for metadata.
4. If no profiled bundle exists, preserve the repository's established filesystem convention.
   Do not add OKF frontmatter or invent Mori identity as an incidental plan edit.

This conditional behavior lets the plan skills work in repositories before and after ADR
adoption. Migrating an existing corpus to the shared profile is separate work and should use
the `adopt-architecture-decisions` Seihou blueprint from `okf-profiles`.


## Work with a profile-governed ADR bundle

The shared `documentation.architectureDecisions` profile requires one decision per Markdown
file at the bundle root and the frontmatter fields `type`, `title`, `docId`, `status`, and
`date`. Strict OKF authoring also requires a one-sentence `description` and a `timestamp` for
the last meaningful revision. Its type is `Architecture Decision Record`; its stable document
handle is a unique, positive, unpadded `ADR-N`. `index.md` and `log.md` are reserved OKF files
and are not concepts.

Preserve a valid existing `docId`. Before creating a record, inspect allocated handles and ask
OKF for the next unused one:

```bash
okf id list docs/adr --profile docs/adr/profile.dhall
okf id next docs/adr --profile docs/adr/profile.dhall ADR
```

Do not derive a new handle by counting files, fill a numbering gap, recycle a retired handle,
or guess from a filename. Keep a record's `docId` stable across renames. Preserve additional
producer-owned frontmatter unless the local profile forbids it.

After creating or changing ADRs, run strict profile enforcement in addition to the repository's
normal checks:

```bash
okf validate docs/adr \
  --strict \
  --profile docs/adr/profile.dhall \
  --profile-enforce \
  --log-enforce
```

Mori's observation-time profile diagnostics are useful but advisory; they do not replace this
failing repository check. Maintain the bundle's reserved `log.md` with `okf log add` whenever
an ADR timestamp advances. If the repository uses a different ADR profile or descriptor path,
follow that local contract and its declared ID prefix instead of hard-coding this example.


## Cite decisions locally and across repositories

Within the same repository, use repository-relative Markdown links. They work in an ordinary
checkout and remain readable without registry access.

Across repositories, use the exact project-and-bundle-scoped handle-form URI returned by Mori,
for example `mori://shinzui/mina/okf/adrs/concepts/ADR-4`. Discover the record through the
registry:

```bash
mori registry concepts --search '<title or term>' --json
mori registry concepts --id ADR-4 --json
```

Exact IDs are only bundle-local and may match multiple projects, so select the intended result
and copy its canonical reference exactly. Never guess a `mori://` URI, cite another checkout's
absolute path, or use an unscoped `ADR-N` as a cross-repository reference.


## Distill plan decisions

Plans are active execution or coordination memory; ADRs are durable project memory. During
implementation, update or create an ADR in the same change when a decision changes architectural
boundaries, shared interface ownership, persistent constraints, deliberate exclusions, or another
project-level judgment. At completion, review Decision Logs, Surprises & Discoveries, and Outcomes
& Retrospectives and promote only durable context. Leave transient blockers, execution notes, and
task-local retrospectives in the plan.
