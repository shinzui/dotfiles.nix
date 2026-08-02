---
name: rei-bookmark-url
description: Bookmark a URL into Rei and grow the ontology to hold it — work out every subject the page covers, reuse the topics that already cover them, create properly-wired topics for the ones that don't (instance-of their type, placed under a parent concept, with a canonical external reference), define any missing predicate from the Schema.org vocabulary, anchor the link to its primary topic, and assert `about` associations for the rest.
allowed-tools: AskUserQuestion, Bash, Read, WebFetch
---

# Rei Bookmark URL

This skill bookmarks a URL into Rei as a **topic-anchored link**, and extends the ontology as
far as that bookmark requires. Filing the link is one command; the work is making sure a topic
exists for every subject the page is about, that each one is classified and placed correctly,
and that the link is wired to all of them.

**Creating is a normal outcome, not an exception.** When a subject the page covers has no topic,
the skill creates one — along with its type topic if that is missing too, its `instance-of` or
`broader-than` placement, and its canonical external reference. Reuse happens when an existing
topic genuinely covers the subject; it is not a goal in itself, and a subject is never demoted
to a property or dropped because it "isn't worth a topic". Subjects belong in the ontology.

What the skill is careful about is **modeling correctly**: not minting a near-duplicate of a
topic that already exists, not confusing classification with subsumption, not inventing a
predicate that Schema.org has already named, and not leaving a new topic orphaned.

## When to Use

Activate when the user says things like:
- "Bookmark this link in Rei"
- "Save <url> under the right topic"
- "Add this URL and file it in my ontology"
- "Bookmark this — create whatever topics it needs"
- "/rei-bookmark-url <url>"

Use `/rei-ingest-url` instead when the user wants the page **summarized into a note** and
anchored to an intention. Use `/rei-curate-ontology` when the user wants to restructure or prune
the ontology itself rather than file a link into it.

## Key Concepts

- **Link** — a first-class Rei entity for a URL, with **canonical-URL deduplication**. Rei
  normalizes URLs (strips tracking params, applies per-domain rules, resolves redirects), so
  adding a URL that already exists **reuses the existing link** and just adds a new attachment.
  You will not create a duplicate entity by re-adding a URL.
- **Attachment (the anchor / where it is filed)** — a link's storage location: an intention,
  action, outcome, reflection, or **topic**. A bookmark is a link whose anchor is a topic. A
  link may hold **several** attachments (the same URL filed under an intention *and* a topic);
  `rei link show` lists them all. `rei topic attachments TOPIC` lists what is filed under a
  topic.
- **Association (what it is about)** — a *validated* first-class relation between an entity and
  a topic, written with `rei topic associate`. Three relations exist: `about` (subject matter),
  `scoped-to` (operational membership), `instance-of` (topic → topic classification). For
  bookmarks you use `about` for every subject beyond the anchor, and `instance-of` to classify
  the topics you create.
- **Attachment ≠ association.** Filing a link under a topic does **not** create an `about`
  association, and an `about` association does **not** move the link into
  `rei topic attachments`. The anchor is the primary subject; `about` carries the rest.
- **`rei topic associate` vs `rei edge add`** — the association commands are the everyday API:
  they verify both endpoints exist and are active, and they only ever write the three validated
  relations. `rei edge add` is the open graph, for predicates the association commands never
  create (`broader-than`, `related-to`, `summarizes`, a borrowed Schema.org predicate). **Prefer
  `rei topic associate` for `about` and `instance-of`; use `rei edge add` for everything else.**
- **Seeded ontology predicates** (`rei ontology seed-system`, idempotent):
  `about`, `scoped-to`, `instance-of`, `broader-than` (transitive, inverse `narrower-than`),
  `narrower-than`, `related-to` (symmetric). It also seeds the system `project` topic.
- **Classification vs. subsumption** — the #1 modeling mistake, and it bites hardest here,
  because most bookmarks are about a *named thing*:
  - **`instance-of`** — a concrete thing is an instance of a type: `react` instance-of
    `ui-libraries`, `pkl` instance-of `configuration-language`. Both ends are topics; the source
    is a thing you could put a homepage on.
  - **`broader-than` / `narrower-than`** — *subject subsumption* between two abstract subjects:
    `version-control` broader-than `git-forge`. Both ends are fields you would browse.
  - Litmus test: if the topic names a product/tool/library/service, it is an **instance** →
    `instance-of` its type. If it names another subject area, it is a **concept** →
    `broader-than` from its parent. Never attach a named thing to a category with
    `broader-than`.
- **External reference** — `rei topic add-ref TOPIC SCHEME://KEY` records a topic's canonical
  identity (a homepage, a `mori://` project URI, a Schema.org IRI). One reference belongs to at
  most one topic, so it is also a **duplicate-topic detector**: `rei topic ref-show URL` answers
  "does a topic for this thing already exist under some other key?".
- **Schema.org alignment** — the vendored vocabulary at `mori://schemaorg/schemaorg` is where a
  new *predicate* gets its name and definition, and a good source of names for *type* topics.
  See Phase 6.

## Modeling Discipline

These rules govern *how* to extend the ontology, not *whether* to. Apply all of them:

1. **Reuse an existing topic when one genuinely covers the subject.** Search by key *and* by
   label, and check `rei topic ref-show` against the thing's homepage before creating — a topic
   for it may already exist under a key you did not guess. Reuse is about not minting
   `git-hub` next to `github`, not about avoiding growth.
2. **Every subject the page is about gets a topic.** The anchor is the single most specific
   topic that fits; every other subject gets its own topic and an `about` association. Do not
   drop a subject, and do not record it as a property instead — properties describe the
   link's *shape and source*, never its subject matter.
3. **Classify and place every new topic; never leave one orphaned.** An instance gets
   `instance-of` its type. A concept gets `broader-than` from a parent concept. A topic that
   connects to nothing is a modeling failure, not a shortcut.
4. **Create the type or parent topic too when it is missing.** If `pkl` needs
   `configuration-language` and that topic does not exist, create both. The classification is
   the point — a new instance with nowhere to hang is worse than no topic.
5. **Classify distinct instances into their distinct correct types.** `react` → `ui-libraries`,
   `stylex` → `css-in-js` — not both into one generic bucket. If two instances need two
   different types, create two.
6. **Never create a topic for the publisher.** A post on a personal site is about its *subject*,
   not the site. `platform` and `content-type` already record the source and shape. The
   exception is when the publisher is genuinely the subject (a bookmark *about* GitHub itself).
7. **Borrow vocabulary before inventing it.** A new predicate takes its name and definition from
   Schema.org when a standard term fits (Phase 6). Type-topic names can borrow too
   (`SoftwareApplication` → `software-application`) — but never import a type's property list or
   subtype tree.
8. **Keep hierarchies shallow.** One or two levels of `broader-than` is normally enough. Depth
   for elegance's sake makes browsing worse.
9. **Give every new topic a canonical reference when it has one.** It is what makes the next
   bookmark find this topic instead of creating a twin.

## Workflow Overview

1. **Get the URL** — from args or the user, plus any subject hint they offer
2. **Check what Rei already knows about this URL** — dedup, existing anchors, existing properties
3. **Work out every subject the page covers** — fetch; subjects ranked, each instance or concept
4. **Survey the ontology** — match each subject against existing topics, refs, and predicates
5. **Plan the placement** — anchor, `about` topics, topics to create with their wiring
6. **Ensure the predicates exist** — `rei ontology seed-system`; reconcile `is-a` vs
   `instance-of`; name any missing predicate from Schema.org
7. **Create and wire the topics** — `rei topic create`, `instance-of` / `broader-than`, `add-ref`
8. **Bookmark the link** — `rei link add --topic` (or `rei link set-topic` to re-anchor)
9. **Assert the remaining subjects** — `rei topic associate LINK --relation about`
10. **Record shape and source** — `content-type`, `platform`
11. **Validate and review** — `rei ontology validate`, `rei topic tree`, `rei topic attachments`
12. **Summary**

## Instructions for Claude

### Phase 1: Get the URL

The URL may be supplied as an argument. If not:

```
Question: "What URL should I bookmark into Rei?"
Header: "URL"
Options:
- Let me paste the URL
```

Validate it is a well-formed absolute `http(s)` URL; if not, stop and say so.

If the user volunteered *why* they are saving it ("for the Pkl work", "another jj article"),
keep that — it is a strong signal for which topic should be the anchor.

### Phase 2: Check What Rei Already Knows About This URL

Rei deduplicates by canonical URL, so this phase is **not** about avoiding a duplicate entity —
it is about learning whether the link already exists and where it is already filed.

```bash
rei link list --all --domain DOMAIN --json | jq -r --arg url "URL" '.[] | select(.url == $url)'
```

Fallback without `jq`:

```bash
rei link list --all --query "URL" --json
```

If a match exists, capture its ID and inspect every attachment and property:

```bash
rei link show LINK_ID --json
```

Then branch:

- **Already anchored to the topic that will be the anchor** → the filing is done; continue with
  Phases 3–7 and 9 anyway, since the ontology may still be missing topics for its other
  subjects. Skip Phase 8.
- **Anchored elsewhere (an intention, action, or another topic)** → ask in Phase 5 whether to
  add a topic attachment or move the existing one.
- **No match** → a fresh bookmark; continue.

Note any properties already set (`content-type`, `platform`) so Phase 10 does not overwrite them.

### Phase 3: Work Out Every Subject the Page Covers

Skip the fetch only if the user already stated the subject matter and you recognize all of it.

Otherwise fetch with WebFetch. This is a bookmark, not an ingest — ask for subjects, not a
summary:

> "Return: the page title; a 1–2 sentence statement of what this page is about; every distinct
> subject it substantively covers (3–6, most central first) — technologies, products, concepts,
> or fields; for each, say whether it is a named product/tool/library/service or an abstract
> subject area, and give its canonical homepage URL if it is a named thing; and the publishing
> platform (blog, docs site, GitHub, YouTube, …)."

Build a list of subjects, each labelled **instance** (named thing, with its homepage) or
**concept** (subject area), ranked by centrality. Drop only what the page merely mentions in
passing — everything it is substantively about stays on the list.

If the fetch fails, ask the user for the title and the subjects in one question and continue.
Nothing has been written yet.

### Phase 4: Survey the Ontology

For each subject, find whether a topic already covers it:

```bash
rei topic list --json
rei predicate list --json
```

Match on key *and* label, and check the canonical identity — a topic for the thing may exist
under a key you would not have guessed:

```bash
rei topic list --json | jq -r '.[] | "\(.key) — \(.label)"' | grep -i "SUBJECT"

# Does a topic already own this thing's homepage?
rei topic ref-show https://SUBJECT-HOMEPAGE

# For a promising match: what is it, what is under it, how is it wired?
rei topic show TOPIC_KEY
rei topic attachments TOPIC_KEY
rei topic edges TOPIC_KEY
rei topic tree TOPIC_KEY --direction narrower --include-inferred
```

Record per subject: **exact match** (reuse), **near match that genuinely covers it** (reuse), or
**nothing** (create). For each subject to create, also resolve its **type** (for an instance) or
its **parent concept** (for a concept), and check whether *that* topic exists — it may need
creating too.

Browsing the neighbourhood also tells you the local naming style, which the new keys should
match.

### Phase 5: Plan the Placement

Decide, for the whole bookmark:

- **Anchor topic** — exactly one: the most specific topic that fits the page's primary subject.
  It may be one you are about to create.
- **`about` topics** — every other subject on the list.
- **Topics to create** — each with its kind (instance / concept), its wiring (`instance-of` a
  type, or `broader-than` from a parent), and its canonical reference. Include type and parent
  topics that are themselves missing.
- **Predicates to define** — normally none; see Phase 6.

Show the plan, then carry it out. This is an announcement, not an approval gate — do not stop
and wait unless something is genuinely ambiguous (two existing topics fit the anchor equally
well; the page's subject is unclear even after fetching; a proposed key collides with an
existing topic that means something different).

```
Bookmark placement for: <TITLE>
<one-line statement of what the page is about>

ANCHOR (link is filed here):
- pkl — Pkl                                CREATE (instance)
    instance-of → configuration-language      CREATE (type)
    ref → https://pkl-lang.org

ABOUT (subject associations):
- configuration-language — Configuration Language   (created above)
- schema-validation — Schema Validation    CREATE (concept)
    broader-than ← configuration-language
- infrastructure-as-code                   REUSE

PREDICATES: seeded only (about, instance-of, broader-than)

PROPERTIES: content-type=documentation, platform=docs_site
```

Ask only when the link already exists and is anchored somewhere else:

```
Question: "This URL is already filed under <existing anchor>. Add a topic attachment or move it?"
Header: "Anchor"
Options:
- Add a topic attachment, keep the existing one (Recommended)
- Move it to the topic
```

### Phase 6: Ensure the Predicates Exist

Seed the standard ontology. Idempotent — existing entries are reported, never overwritten:

```bash
rei ontology seed-system
```

This guarantees `about`, `scoped-to`, `instance-of`, `broader-than`, `narrower-than`, and
`related-to`, plus the system `project` topic.

**Reconcile `is-a` with `instance-of` before classifying anything.** Some workspaces were curated
before `instance-of` was seeded and classify instances with a locally-defined `is-a` predicate.
Check how the *neighbours* under the intended type topic are already wired:

```bash
rei topic edges TYPE_TOPIC_KEY
```

- Siblings wired with `instance-of`, or no siblings at all → use `instance-of` via
  `rei topic associate` (the validated, first-class relation — prefer it).
- Siblings wired with `is-a` → **stay consistent with the neighbours** and use `is-a` via
  `rei edge add`, so browsing that type does not return half its instances. Mention the
  divergence once and suggest `/rei-curate-ontology` for a migration — do not migrate edges as a
  side effect of a bookmark.

**Define a predicate when the bookmark needs a relationship the seeded set cannot express** —
for example "this tool is built on that runtime", "this spec supersedes that one". Most bookmarks
need none, because filing plus `about` covers subject matter. When one is needed, **name it from
Schema.org rather than inventing a key**:

```bash
SCHEMAORG=$(mori path mori://schemaorg/schemaorg)

(cd "$SCHEMAORG" && just find-prop "built on")     # properties by name or description
(cd "$SCHEMAORG" && just find "software")          # types by name or description
(cd "$SCHEMAORG" && just show SoftwareApplication) # one type in full
```

Search the relationship *in plain words* — `find-prop` matches descriptions too. Vet the
candidate: a non-empty `supersededBy` means adopt the successor instead (`runtime` →
`runtimePlatform`); `isPartOf = https://pending.schema.org` means proposed (usable, but say so).
Then translate: the camelCase `label` becomes a kebab-case `KEY`, the `comment` becomes a
one-line `--description` with the term IRI appended for provenance. Do **not** copy
`domainIncludes` / `rangeIncludes` — set `--source-types` / `--target-types` from how the edges
actually run.

```bash
rei --actor claude-code predicate define runtime-platform --label "Runtime platform" \
  --description "Runtime platform or script interpreter dependency (schema.org/runtimePlatform)" \
  --source-types topic --target-types topic
```

Borrow only the one property you need — never a type's inherited property list or its subtype
tree. If nothing standard fits, define a rei-native key and note that no standard term applied.
For the full lookup-and-vetting procedure, see `/rei-curate-ontology` Phase 4.

### Phase 7: Create and Wire the Topics

Create every topic from the Phase 5 plan, **types and parents first** so the classification edges
have somewhere to point:

```bash
rei --actor claude-code topic create KEY "LABEL" --description "DESCRIPTION"
```

Keys are stable, lowercase, hyphen-separated, and specific (`pkl`, `configuration-language`).
Match the style of neighbouring keys and never collide with an existing one. Capture each new
`topic_...` ID — the edge commands need IDs.

Note the flag position: `topic create`, `predicate define`, and `edge add` take **no local
`--actor`** — it is the global `rei --actor claude-code <command>`. (`link add` and
`link set-topic` take a trailing `--actor`; `rei topic associate` takes no actor flag.)

Wire each new topic. Every one gets a classification or a placement — none is left orphaned:

```bash
# Classification — a named thing is an instance of its type.
# Argument order: associate TARGET_TYPE_TOPIC SOURCE_INSTANCE_TOPIC.
rei topic associate TYPE_TOPIC_KEY INSTANCE_TOPIC_ID --relation instance-of

# ...or, in an is-a workspace (Phase 6), stay consistent with the neighbours:
rei --actor claude-code edge add --from INSTANCE_TOPIC_ID --to TYPE_TOPIC_ID --predicate is-a

# Concept placement — broader subject -[broader-than]-> narrower subject. BOTH ends abstract.
rei --actor claude-code edge add --from PARENT_TOPIC_ID --to NEW_TOPIC_ID --predicate broader-than

# Peers (symmetric) — when two topics are genuine cross-links rather than parent/child
rei --actor claude-code edge add --from TOPIC_A_ID --to TOPIC_B_ID --predicate related-to
```

`rei edge add` requires `topic_...` **IDs**, not keys (keys are rejected as "not an allowed
source type"). `rei topic associate` accepts a key or an ID for the topic argument.

Never create both `broader-than` and `narrower-than` for a pair — inference derives the inverse
at query time.

Record each new topic's canonical identity, so the next bookmark finds this topic instead of
creating a twin:

```bash
rei topic add-ref TOPIC_KEY https://CANONICAL-HOMEPAGE --label "LABEL"
```

Use the thing's own canonical home (project homepage, `mori://` project URI, or the Schema.org
IRI when the topic borrows a standard type name) — **not** the URL being bookmarked. A reference
another topic already owns is refused and names that topic; if that happens, you found a
duplicate — archive or reuse rather than forcing a second topic.

### Phase 8: Bookmark the Link

Anchor the link to the anchor topic. Pass the `topic_...` **ID** to `--topic`:

```bash
rei link add --topic TOPIC_ID "URL" -t "TITLE" --actor claude-code
```

Because Rei deduplicates by canonical URL, this reuses an existing link entity when the URL is
already known and files it under the topic as an additional attachment. Capture the link ID.

To **move** an existing attachment instead (only when the user chose that in Phase 5) — `TOPIC`
may be a key or an ID:

```bash
rei link set-topic LINK_ID TOPIC --actor claude-code

# When the link has several attachments, name the one to move:
rei link set-topic LINK_ID TOPIC --attachment LINK_ATT_ID --actor claude-code
```

Always pass both arguments explicitly; omitting them opens an fzf picker that blocks a
non-interactive run. If the title was unknown at add time:

```bash
rei link title LINK_ID "TITLE"
```

### Phase 9: Assert the Remaining Subjects

For every subject topic other than the anchor — reused and newly created alike:

```bash
rei topic associate TOPIC_KEY LINK_ID --relation about
```

Idempotent: re-associating reports "Already associated" and changes nothing. Both endpoints must
be active — an archived topic is refused.

Read it back from either end:

```bash
rei topic associations LINK_ID
rei topic entities TOPIC_KEY --relation about --entity-type link
```

Use `rei edge add` here only for a genuinely different predicate (e.g. a borrowed
`runtime-platform` between two topics), never to hand-write an `about` row.

### Phase 10: Record Shape and Source

Two properties describe what kind of artifact the link is and where it came from. They are
**not** subject matter — the ontology carries that. Skip any already set on a reused link, and
skip rather than guess:

```bash
rei link set-property -l LINK_ID content-type VALUE
rei link set-property -l LINK_ID platform VALUE
```

Allowed values (verify with `rei custom-property show KEY` if a set fails):

- `content-type`: `homepage`, `page`, `article`, `blog_post`, `essay`, `documentation`,
  `api_reference`, `tutorial`, `guide`, `research_paper`, `whitepaper`, `case_study`,
  `announcement`, `changelog`, `repository`, `repository_issue`, `repository_pr`,
  `repository_release`, `package`, `social_post`, `thread`, `discussion`, `qa_question`,
  `qa_answer`, `video`, `podcast`, `image`, `presentation`, `pdf`, `dataset`, `course`
- `platform`: `website`, `blog`, `x`, `linkedin`, `reddit`, `hackernews`, `github`, `gitlab`,
  `bitbucket`, `youtube`, `vimeo`, `substack`, `medium`, `notion`, `wikipedia`, `arxiv`,
  `stack_overflow`, `lobsters`, `newsletter`, `docs_site`, `package_registry`,
  `podcast_platform`, `chatgpt`, `claude`

`author-type` and `media` exist too — set them only if the page made them obvious.

**Do not set `tags`.** Subject matter belongs in topics and associations, which are browsable and
carry their own relationships. A tag is not a substitute for a topic, and a subject recorded as a
tag is a subject missing from the ontology.

### Phase 11: Validate and Review

```bash
rei ontology validate
rei link show LINK_ID
rei topic attachments ANCHOR_TOPIC_KEY
rei topic associations LINK_ID
rei topic tree ROOT_KEY --direction narrower --include-inferred
rei topic entities TYPE_TOPIC_KEY --relation instance-of
```

If `validate` reports an error caused by an edge you just wrote, fix the edge — never loosen a
predicate's constraints to silence the validator. Pre-existing errors: surface them and point at
`/rei-curate-ontology`; do not fix them as a side effect of a bookmark.

Confirm every new topic is reachable: it should appear in its type's `instance-of` list or under
its parent in `topic tree`. A new topic that appears in neither was left orphaned — wire it.

### Phase 12: Summary

Report what was created, what was reused, and how the link is wired.

## Output Format

```
## Bookmarked

- **URL**: <url>
- **Title**: <title>
- **Link**: <link_id>  (new link / reused existing canonical link)
- **Anchor topic**: <key> — <label>  (reused / created)  [attachment added / moved from <old anchor>]

### Topics created
- <key> — <label>   instance-of <type-key>        ref: <scheme://key>
- <key> — <label>   broader-than ← <parent-key>   ref: <none — abstract subject>

### Topics reused
- <key> — <label>

### Predicates
- Seeded/reused: about, instance-of, broader-than, ...
- Defined: <key> ← <schema.org/term>   (or: none needed)

### Associations
- about: <topic-key>, <topic-key>, ...

### Properties
- content-type: <value or "skipped">
- platform: <value or "skipped">

### Validation
- rei ontology validate: <passed / N pre-existing errors, unchanged>
- every new topic reachable via its type or parent: <yes / fixed>

### Next Steps
- Browse the topic: `rei topic attachments <anchor-key>`
- See the link's subjects: `rei topic associations <link_id>`
- See the new tree: `rei topic tree <root-key> --direction narrower --include-inferred`
```

## Important Notes

- **Creating topics is the normal path.** A subject with no topic gets one, wired to its type or
  parent, with its canonical reference. Do not drop a subject, do not record it as a property,
  and do not ask the user to justify it.
- **Reuse means "don't duplicate", not "don't grow".** Search by key and label and check
  `rei topic ref-show` against the homepage before creating, so `github` never gains a `git-hub`
  twin.
- **Never leave a new topic orphaned**, and create its type or parent when that is missing too.
  Phase 11 verifies each new topic is reachable from its type or parent.
- **Classify with `instance-of`, subsume with `broader-than`.** A named product/tool/library is
  an *instance* of its type; only two abstract subjects stand in a broader/narrower relation.
  Check `rei topic edges TYPE_TOPIC` first: in a workspace that still classifies with `is-a`,
  stay consistent with the neighbours rather than splitting the type in half.
- **Never set `tags`.** Subject matter is topics and associations. `content-type` and `platform`
  record the artifact's shape and source, which is a different thing.
- **Links deduplicate by canonical URL.** `rei link add` on a known URL reuses the link entity
  and adds an attachment — it never creates a second link. Phase 2 discovers existing anchors; it
  does not prevent a duplicate.
- **Adding an attachment ≠ moving one.** `rei link add --topic` keeps every existing filing;
  `rei link set-topic` moves one. Default to adding, and ask before moving.
- **Attachment ≠ `about` association.** Filing does not create an `about` row and an `about` row
  does not file. Anchor = primary subject; `about` = every other subject.
- **Prefer `rei topic associate` over `rei edge add`** for `about` and `instance-of` — it
  validates both endpoints and is the supported everyday API. Reserve `rei edge add` for
  `broader-than`, `related-to`, `is-a`, and borrowed predicates.
- **Argument order for `associate` is target-first**: `rei topic associate TOPIC ENTITY` reads
  "ENTITY <relation> TOPIC". So `associate ui-libraries topic_react --relation instance-of`
  means *react instance-of ui-libraries*.
- **Never create a topic for the publisher** unless the publisher is genuinely the subject.
- **Name new predicates from Schema.org**, vetting `supersededBy` and `isPartOf`; borrow one
  property, never a type's property list or subtype tree. Set `--source-types`/`--target-types`
  from real usage, not from `domainIncludes`.
- **Actor flag position differs by command**: `topic create`, `predicate define`, and `edge add`
  take only the global `rei --actor claude-code <command>`; `link add` and `link set-topic` take
  a trailing `--actor claude-code`; `rei topic associate` takes no actor flag.
- **Always pass IDs explicitly** to `link set-topic` and `link set-property` — omitting them
  opens an fzf picker that blocks non-interactive runs. `rei edge add` needs `topic_...` IDs;
  `rei topic associate`, `link set-topic`, and `topic attachments` accept keys.
- **Seeding is idempotent**: `rei ontology seed-system` is safe anytime; it reports
  already-present entries and never overwrites incompatible ones.
- **Don't restructure the ontology as a side effect.** Surface pre-existing validation errors,
  duplicate topics, or `is-a`/`instance-of` divergence, and point at `/rei-curate-ontology`.
