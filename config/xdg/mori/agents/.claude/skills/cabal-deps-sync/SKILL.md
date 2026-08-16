---
name: cabal-deps-sync
version: "1.0.0"
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
mori names a registered *project*, or one *package* inside it. Your job is that mapping,
not a one-to-one copy.


## The package grain (read before you collapse anything)

A dependency name resolves to a project and, when the name identifies one, to a specific
**package** inside that project. These are the rules, in the order mori tries them:

| Resolution | The name | Resolves to |
|------------|----------|-------------|
| `qualified-project` | `namespace/name` matching a registered project | that project |
| `project` | a bare name matching exactly one project | that project |
| `package` | a bare name matching packages in exactly one project | that project **and** that package |
| `bundle` | a bare name matching a bundle | that project and the bundle's primary package |
| `qualified-package` | `project:package`, and the project declares it | that project **and** that package |
| `unknown-package` | `project:package`, but no such package | nothing — an error |
| `ambiguous-project` / `ambiguous-package` | a bare name matching more than one | nothing — an error |

So `hasql`, `hasql-pool`, and `hasql-transaction` do **not** all mean `hasql/hasql`. Each
bare name matches a package of that project and resolves to `hasql/hasql:<that-package>`.

**Do not collapse several cabal packages of one project into a single project-grained
entry.** A project-grained entry is a strictly wider claim, and it is what makes
`mori registry dependents 'hasql/hasql:hasql-pool'` return everyone who touches any part
of hasql instead of the right subset. Keep the grain the `.cabal` file actually states.
Write `namespace/name:package` when a bare name would be ambiguous across projects, or
when you want the qualification to be explicit and to fail loudly if the package
disappears upstream.

Check your work with `mori deps explain <name>`, which prints the rule that fired:

```text
mori deps explain hasql-pool
hasql-pool
  Resolution: bare name matched the package 'hasql-pool' of project hasql/hasql
```


## What "in sync" means

For each `Schema.Package` in `mori.dhall`, its `dependencies` list holds the names that
the matching `.cabal` file's `build-depends` resolve to, at the grain those
`build-depends` state. The top-level `Project.dependencies` (a `List Text`) is the union
of those, **plus** every project pinned by a `source-repository-package` stanza in
`cabal.project`.

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

Columns are `cabal-package`, `scope`, `cabal-dep`, `classification`,
`version-constraint`:

```text
hasql-opentelemetry	Regular	hasql                  hasql/hasql              ^>=1.9
hasql-opentelemetry	Regular	hasql-pool             hasql/hasql              ^>=1.3
hasql-opentelemetry	Regular	text                   BOOT                     ^>=2.1
hasql-opentelemetry	Regular	unliftio-core          UNREGISTERED
jitsurei            	Regular	hasql-opentelemetry    INTERNAL
jitsurei            	Test  	tasty                  UnkindPartition/tasty    >=1.4 && <1.6
cabal.project       	Regular	crypton                kazu-yamamoto/crypton
cabal.project       	Regular	streamly-project       composewell/streamly
```

The last column is the cabal bound verbatim, empty when the dep declares none.
Where stanzas disagree about a bound, the script reports every distinct value
joined by ` | ` — mori holds one single-line value, so you pick. `cabal.project`
rows never carry one: a pinned repo has a commit, not a range.

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

A non-`Regular` scope — or a version constraint you want to record — needs the
`WithAugmentation` form:

```dhall
      , Schema.Dependency.WithAugmentation
          { name = "UnkindPartition/tasty"
          , extraDocs = [] : List Schema.DocRef.Type
          , localPathOverride = None Text
          , kind = Some Schema.DependencyKind.ThirdParty
          , source = Some Schema.DependencySource.Hackage
          , scope = Some Schema.DependencyScope.Test
          , versionConstraint = Some ">=1.4 && <1.6"
          }
```

Rules that bite here:

1. **Qualified names, always** — `"hasql/hasql"`, not `"hasql"`. Bare names may resolve
   today and break the moment a second namespace registers the same name. When the
   `build-depends` entry names one package of a multi-package project, qualify to the
   package: `"hasql/hasql:hasql-pool"`. Mori rejects a `project:package` name whose
   target declares no such package, which is the failure you want.
2. **`WithAugmentation` is a union alternative, not a `::{ … }` bundle** — it has no
   defaults, so you must write *every* field, including `extraDocs = [] : List
   Schema.DocRef.Type`, `localPathOverride = None Text`, and
   `versionConstraint = None Text` when there is no bound. This is the one place the
   "never write empty lists or defaults" rule of the mk form does not apply.
3. **`extraDocs` is typed `List Schema.DocRef.Type`**, not `List Schema.DocRef` —
   `Schema.DocRef` is the `{ Input, Type, default, mk }` bundle, not a type.
4. **Keep the top-level `dependencies` list a deduplicated union** of the per-package
   lists. Scope information lives on the package entries; the top-level list is plain
   `Text`. If the project also declares `dependencyRefs` — the typed `MoriRef`
   companion — keep it in step with the untyped list; validation fails when the two
   disagree. A package-grained companion sets `kind` and `key`:

   ```dhall
   , dependencyRefs =
     [ Schema.MoriRef::{ namespace = "hasql", name = "hasql" }
     , Schema.MoriRef::{
       , namespace = "hasql"
       , name = "hasql"
       , kind = Some Schema.MoriArtifactKind.Package
       , key = Some "hasql-pool"
       }
     ]
   ```
5. **Only mention a package in `mori.dhall` that has a `Package` entry.** If a `.cabal`
   file has no matching `Schema.Package::{ … }`, add it (with `path`, `type`, `language`)
   rather than folding its deps into a sibling.
6. **A `versionConstraint` is opaque to mori** — it validates only that the value is
   non-blank and single-line, and never parses or compares it. Copy the cabal bound
   verbatim rather than normalizing it into some other syntax; the point is that a reader
   can compare it against the `.cabal` file. A multi-line or empty string fails
   `mori validate`.


## Step 4b — Version constraints (optional, ask first)

Recording bounds converts every constrained dependency from `ByName` to
`WithAugmentation`, which is a large and noisy diff on a project with many deps. Do not
do it unsolicited. Ask, and if the user wants it, prefer scoping it to the dependencies
that matter — the ones whose bounds are load-bearing — over a blanket rewrite.

When you do record them:

- Copy the bound from the report's last column verbatim.
- A ` | ` in that column means stanzas disagreed. Do not invent a merged bound; show the
  user the alternatives and let them choose, or leave `versionConstraint = None Text`.
- Leave `cabal.project` pins unconstrained. They pin a commit, not a range, and a
  fabricated range would be worse than no claim.
- Nothing keeps this in sync afterwards. Mori will not notice when the `.cabal` file
  moves and the manifest does not — re-running this skill is the only check.


## Step 5 — Validate, resolve, register

```bash
mori validate                     # Dhall type + schema check
mori deps resolve                 # every declared dep must resolve against the registry
mori deps explain <name>          # which rule fired, and at what grain
mori deps tree --scope all        # optional: see the resulting graph
mori register --local             # publish the updated identity
```

`mori validate` passing does **not** mean the names resolve — it only type-checks. Always
run `mori deps resolve` and confirm every line is a ✓ before registering.

Resolving is also not the same as resolving *at the right grain*. Spot-check a few
multi-package targets with `mori deps explain <name>` and confirm the rule is the one you
intended — a `project` where you meant `package` is a silent widening, not an error.
After registering, `mori registry dependents '<ns>/<name>:<package>' --packages` should
name this project for the packages it actually consumes.

Finally, report to the user: what was added, what was removed, and the unregistered deps
with your recommendation for each.


## Debugging

- **`mori deps resolve` shows ✗ for a name you just added** → the qualified name is wrong.
  Re-check with `mori registry search <cabal-dep> --json`. `namespace + "/" + name` of the
  *project* always works; add `:` plus the matched package name when you mean that one
  package.
- **`unknown-package`** → you wrote `project:package` and the target project declares no
  such package. Mori lists the packages it *does* declare. Either the package name is
  wrong or the target's `mori.dhall` is missing a `Package` entry — fix it there.
- **`ambiguous-project` / `ambiguous-package`** → a bare name matched more than one
  registered project. Qualify it; mori refuses to guess.
- **`Wrong type of function argument — Type vs { … : … }`** → you wrote
  `List Schema.DocRef` where `List Schema.DocRef.Type` is required.
- **`missing field scope` / `missing field extraDocs` / `missing field versionConstraint`**
  → an incomplete `WithAugmentation` record. All **seven** fields are mandatory; a config
  written against the pre-3.0.0.0 six-field shape no longer type-checks.
- **`has an empty version constraint` / `has a multi-line version constraint`** → you
  passed `Some ""` or a bound containing a newline. Use `None Text` for "no bound".
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
