---
name: cabal-deps-sync
version: "0.1.0"
description: >
  Inspect a Haskell project's .cabal files and sync the dependency declarations in its
  mori.dhall against the local mori registry — mapping cabal build-depends to registered
  projects by qualified name, per package and per scope, and reporting deps that are not
  registered yet.
  TRIGGER when: user wants to update, sync, audit, or fill in mori.dhall dependencies for
  a Haskell/cabal project, or asks "which of my cabal deps are in the registry".
argument-hint: [project-path]
user-invocable: true
---

# Cabal Dependencies → mori.dhall Sync

You are syncing a Haskell project's `mori.dhall` dependency declarations with what its
`.cabal` files actually say, resolving every cabal dependency through the local mori
registry.

`mori.dhall` dependencies are **not** cabal dependencies. Cabal names Hackage packages;
mori names *registered projects* by qualified name (`namespace/project`). One mori
dependency usually covers several cabal packages — `hasql`, `hasql-pool`, and
`hasql-transaction` all resolve to the single project `hasql/hasql`. Your job is that
mapping, not a one-to-one copy.


## What "in sync" means

For each `Schema.Package` in `mori.dhall`, its `dependencies` list holds the qualified
names of the registered projects that the matching `.cabal` file's `build-depends`
resolve to. The top-level `Project.dependencies` (a `List Text`) is the union of those,
**plus** every project pinned by a `source-repository-package` stanza in `cabal.project`.

`cabal.project` is a second, independent source of dependencies, and skipping it is the
easiest way to get this wrong. Its `source-repository-package` stanzas pin upstream git
repos that are frequently *transitive* — a patched `crypton`, a `memory`→`ram` swap, a
fork of `jose-jwt` — and therefore appear in **no** `build-depends` anywhere in the
project. They are still deliberate, load-bearing dependencies whose source you want
mori to resolve, so they belong in the top-level `dependencies` list. Never conclude a
declared dependency is stale until you have checked `cabal.project` for it.

Because these pins are project-wide rather than owned by one cabal package, declare them
on the top-level `Project.dependencies` only — do not attribute them to a
`Schema.Package` whose `build-depends` does not name them.

Dependencies that are **not** declared:

| Cabal dependency                            | Why it is skipped                              |
|---------------------------------------------|------------------------------------------------|
| GHC boot libs (`base`, `text`, `containers`, `mtl`, …) | Ship with the compiler; not registry projects |
| Sibling packages in the same project        | Internal wiring; mori already knows the packages |
| Third-party packages with no registry entry | Nothing to point at — report these to the user  |


## Step 1 — Locate the project and read the current config

```bash
cd <project-path>
cat mori.dhall             # current declarations — you will edit, not rewrite, this
cat cabal.project          # pinned git repos are dependencies too — read this
mori show --full           # what the registry currently believes
```

Confirm the project is Haskell and has `.cabal` files. If the project uses **hpack**
(`package.yaml` and a generated `.cabal`), run `hpack` first — or read `package.yaml`'s
`dependencies:` blocks directly — so the parse sees current data. Never edit a
generated `.cabal`.


## Step 2 — Extract and resolve dependencies

`scripts/cabal_mori_deps.py`, bundled next to this `SKILL.md`, parses every `.cabal`
file under the project — plus `cabal.project` — and classifies each dependency against
the registry:

```bash
python3 <dir-of-this-SKILL.md>/scripts/cabal_mori_deps.py .          # TSV report
python3 <dir-of-this-SKILL.md>/scripts/cabal_mori_deps.py . --json   # structured
```

Columns are `cabal-package`, `scope`, `cabal-dep`, `classification`:

```text
hasql-opentelemetry	Regular	hasql                  hasql/hasql
hasql-opentelemetry	Regular	hasql-pool             hasql/hasql
hasql-opentelemetry	Regular	text                   BOOT
hasql-opentelemetry	Regular	unliftio-core          UNREGISTERED
jitsurei            	Regular	hasql-opentelemetry    INTERNAL
jitsurei            	Test  	tasty                  UnkindPartition/tasty
cabal.project       	Regular	crypton                kazu-yamamoto/crypton
cabal.project       	Regular	streamly-project       composewell/streamly
```

Rows whose first column is the literal `cabal.project` come from
`source-repository-package` stanzas, keyed by the repo name in the `location:` URL.
They are project-wide pins, always reported as `Regular`, and go on the top-level
`dependencies` list only.

Scope comes from the cabal stanza: `library`/`executable` → `Regular`,
`test-suite`/`benchmark` → `Test`, `custom-setup` and `build-tool-depends` → `Build`.
A dep used by both the library and its tests is `Regular`.

Resolution rule (the script applies it; apply the same rule if you resolve anything by
hand): `mori registry search` matches **substrings**, so only an exact match on the
project name — or on a package name inside a project — counts. Searching `text` also
returns `text-iso8601` and TypeScript packages; taking the first hit is wrong.

For a `cabal.project` repo the search key is the repo name, with two wrinkles: corpus
projects are conventionally named `<upstream>-project`, so the script also tries the
`-project`-stripped name; and a fork is pinned under the forker's account while the
registry knows it by the upstream namespace, so the URL owner is a tiebreaker, not a
requirement — `https://github.com/shinzui/streamly-project` correctly resolves to
`composewell/streamly`.

```bash
mori registry search <cabal-dep> --json    # inspect a single mapping
mori deps locate <namespace/project>       # confirm a qualified name resolves
```


## Step 3 — Decide what changes

Compare the report against `mori.dhall` and produce three lists:

1. **Missing** — resolved qualified names absent from the package's `dependencies`.
2. **Stale** — declared dependencies backed by neither a `build-depends` entry nor a
   `cabal.project` pin (the dep was dropped). Remove them. A name that appears only in
   the `cabal.project` rows of the report is **not** stale — it is a transitive pin, and
   removing it is the single most likely mistake in this whole workflow.
3. **Unregistered** — real third-party deps with no registry entry.

Do not silently drop the unregistered ones — report them, and check each for these two
cases before calling it genuinely absent:

- The dep looks like a package of a project that *is* registered (e.g. `keiki-codec-json`
  when `shinzui/keiki` exists). That project's `mori.dhall` is missing a `Package` entry.
  Say so; fixing it there is better than adding anything here.
- It is a third-party library worth reading. Offer to bootstrap a corpus project for it
  with the `mori-bootstrap-corpus` skill, then re-run the sync.

Ask before removing stale entries — a dependency may be declared deliberately (docs
augmentation, an upcoming migration) ahead of the cabal file.


## Step 4 — Edit mori.dhall

Edit in place, preserving the existing `let Schema = …` header, formatting, and every
field you are not changing.

Plain dependencies use `ByName` with the qualified name:

```dhall
, packages =
  [ Schema.Package::{
    , name = "hasql-opentelemetry"
    , type = Schema.PackageType.Library
    , language = Schema.Language.Haskell
    , path = Some "."
    , dependencies =
      [ Schema.Dependency.ByName "hasql/hasql"
      , Schema.Dependency.ByName "iand675/hs-opentelemetry"
      , Schema.Dependency.ByName "haskell-hvr/uuid"
      ]
    }
  ]
, dependencies =
  [ "hasql/hasql", "iand675/hs-opentelemetry", "haskell-hvr/uuid" ]
```

A non-`Regular` scope needs the `WithAugmentation` form:

```dhall
      , Schema.Dependency.WithAugmentation
          { name = "UnkindPartition/tasty"
          , extraDocs = [] : List Schema.DocRef.Type
          , localPathOverride = None Text
          , kind = Some Schema.DependencyKind.ThirdParty
          , source = Some Schema.DependencySource.Hackage
          , scope = Some Schema.DependencyScope.Test
          }
```

Rules that bite here:

1. **Qualified names, always** — `"hasql/hasql"`, not `"hasql"`. Bare names may resolve
   today and break the moment a second namespace registers the same name.
2. **`WithAugmentation` is a union alternative, not a `::{ … }` bundle** — it has no
   defaults, so you must write *every* field, including `extraDocs = [] : List
   Schema.DocRef.Type` and `localPathOverride = None Text`. This is the one place the
   "never write empty lists or defaults" rule of the mk form does not apply.
3. **`extraDocs` is typed `List Schema.DocRef.Type`**, not `List Schema.DocRef` —
   `Schema.DocRef` is the `{ Input, Type, default, mk }` bundle, not a type.
4. **Keep the top-level `dependencies` list a deduplicated union** of the per-package
   lists. Scope information lives on the package entries; the top-level list is plain
   `Text`.
5. **Only mention a package in `mori.dhall` that has a `Package` entry.** If a `.cabal`
   file has no matching `Schema.Package::{ … }`, add it (with `path`, `type`, `language`)
   rather than folding its deps into a sibling.


## Step 5 — Validate, resolve, register

```bash
mori validate                     # Dhall type + schema check
mori deps resolve                 # every declared dep must resolve against the registry
mori deps tree --scope all        # optional: see the resulting graph
mori register --local             # publish the updated identity
```

`mori validate` passing does **not** mean the names resolve — it only type-checks. Always
run `mori deps resolve` and confirm every line is a ✓ before registering.

Finally, report to the user: what was added, what was removed, and the unregistered deps
with your recommendation for each.


## Debugging

- **`mori deps resolve` shows ✗ for a name you just added** → the qualified name is wrong.
  Re-check with `mori registry search <cabal-dep> --json`; the answer is
  `namespace + "/" + name` of the *project*, not the matched package name.
- **`Wrong type of function argument — Type vs { … : … }`** → you wrote
  `List Schema.DocRef` where `List Schema.DocRef.Type` is required.
- **`missing field scope` / `missing field extraDocs`** → an incomplete
  `WithAugmentation` record. All six fields are mandatory.
- **A dep resolves to a surprising project** → this is usually correct: corpus projects
  vendor several upstream repos, so `generic-lens` legitimately resolves to `ekmett/lens`
  if that corpus carries it. Confirm with
  `mori registry show <namespace/project> --full`.
- **Script finds no `.cabal` files** → an hpack project whose `.cabal` files are
  gitignored. Run `hpack` in each package directory first.
- **A declared dep looks stale but the user says it is real** → you almost certainly
  ignored `cabal.project`. Grep its `source-repository-package` stanzas before proposing
  any removal.
- **A `cabal.project` repo resolves to `UNREGISTERED`** → the repo name may differ from
  the registered project name (a monorepo pinned via `subdir:`, or a rename). Check the
  `subdir:` package names with `mori registry search` before concluding it is absent.
- **A conditional cabal block (`if flag(...)`) hides a dep** → the parser reads
  `build-depends` inside conditionals too, so its deps appear; if a flag is off by
  default and the dep is not really used, drop it when editing.
