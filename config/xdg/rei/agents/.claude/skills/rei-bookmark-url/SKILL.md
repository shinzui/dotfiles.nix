---
name: rei-bookmark-url
description: Bookmark a URL into Rei and grow the ontology to hold it — work out every subject the page covers, reuse the topics that already cover them (checked by key, label, and canonical reference), create properly-wired topics for the ones that don't (instance-of their type or broader-than from a parent, with a canonical external reference), name any missing predicate from Schema.org, anchor the link to its primary topic, assert `about` associations for the rest, and verify the result.
allowed-tools: AskUserQuestion, Bash, Read, WebFetch
---

# Rei Bookmark URL

Files a URL into Rei as a **topic-anchored link** and extends the ontology as far as that
bookmark requires. Filing the link is one command; the work is making sure every subject the
page is about has a topic, that each topic is classified and placed correctly, and that the
link is wired to all of them.

**Creating topics is the normal outcome.** A subject with no topic gets one — plus its type or
parent topic if that is missing too. Reuse happens when an existing topic genuinely covers the
subject; it means "don't duplicate", not "don't grow". What the skill is careful about is
modeling correctly: no near-duplicate topics, no confusing classification with subsumption, no
invented predicate where Schema.org has a term, no orphaned topics.

Use `rei-ingest-url` instead when the page should be **summarized into a note** anchored to an
intention; use `rei-curate-ontology` to restructure or prune the ontology itself.

## Key Concepts

- **Link** — a Rei entity for a URL with **canonical-URL deduplication** (tracking params
  stripped, per-domain rules, redirects resolved). `rei link add` on a known URL reuses the
  link and adds an attachment; it never creates a second link.
- **Attachment** (where it is filed) — a link's anchor: an intention, action, outcome,
  reflection, or topic. A link may have several. A bookmark is a topic attachment.
- **Association** (what it is about) — a validated relation written by `rei topic associate`:
  `about` (subject matter), `scoped-to` (operational membership, the default!), `instance-of`
  (topic → topic classification). **Attachment ≠ association**: filing under a topic creates no
  `about` row, and an `about` row files nothing. Anchor = primary subject; `about` = the rest.
- **`rei topic associate` vs `rei edge add`** — associate validates both endpoints and writes
  only the three relations above; use it for `about` and `instance-of`. `rei edge add` is the
  open graph, for `broader-than`, `related-to`, `is-a`, and borrowed predicates; it needs full
  `topic_...` IDs, not keys.
- **Argument order for associate is target-first**: `rei topic associate TOPIC ENTITY` reads
  "ENTITY <relation> TOPIC" — `associate ui-libraries topic_react --relation instance-of` means
  *react instance-of ui-libraries*.
- **Classification vs. subsumption** — the #1 modeling mistake:
  - `instance-of`: a named product/tool/library/service/project → its type (`pkl` instance-of
    `configuration-language`).
  - `broader-than`: between two abstract subject areas only (`version-control` broader-than
    `git-forge`). Never hang a named thing under a category with `broader-than`.
  - Never write both `broader-than` and `narrower-than` for a pair — the inverse is inferred.
- **External reference** — `rei topic add-ref TOPIC SCHEME://KEY` records a topic's canonical
  identity (homepage, `mori://` project URI, Schema.org IRI). One active reference belongs to
  at most one topic, so `rei topic ref-show URL` is the duplicate-topic detector.
- **Projects** — a software project the user tracks in Mori is a typed topic (`instance-of`
  the system `project` topic) carrying a verified `mori://` reference. Find it with
  `rei topic ref-show mori://NS/PROJECT`; if it is missing, `rei project sync mori://NS/PROJECT`
  creates it correctly instead of a hand-made topic.

## Modeling Discipline

1. **Every subject the page substantively covers gets a topic** — never dropped, never recorded
   as a property or tag instead. Properties describe the link's shape and source only.
2. **Search before creating**: key, label, and `ref-show` against the thing's homepage — so
   `github` never gains a `git-hub` twin.
3. **No orphans**: every new topic gets `instance-of` a type or `broader-than` from a parent,
   and missing type/parent topics are created too.
4. **Distinct instances get their distinct correct types** (`react` → `ui-libraries`, `stylex` →
   `css-in-js`), not one generic bucket.
5. **No topic for the publisher** unless the publisher is itself the subject.
6. **Borrow vocabulary** from Schema.org for new predicates and type-topic names — one term at a
   time, never a type's property list or subtype tree.
7. **Keep hierarchies shallow** — one or two `broader-than` levels is normally enough.
8. **Give every new named topic its canonical reference** so the next bookmark finds it.

## Workflow

Run writes non-interactively: always pass IDs/keys explicitly (omitted arguments open fzf
pickers), and use `rei --actor claude-code <command>` on every write. Most of these commands
predate Rei's automation exit contract and can print an error yet exit `0` — the topic
association commands are the exception (`2` invalid/refused, `70` store failure) — so confirm
writes by reading them back (Phase 9).

### 1. Get the URL

From the argument or the user. It must be an absolute `http(s)` URL. Keep any stated reason for
saving it ("for the Pkl work") — it is a strong anchor signal.

### 2. Check What Rei Already Knows

Dedup is automatic; this phase finds whether the link exists and where it is filed.

```bash
rei link list --all -d DOMAIN --json \
  | jq -c --arg url "URL" '.[] | select(.canonical_url == $url or .original_url == $url)'
rei link list --all -q "DISTINCTIVE-URL-FRAGMENT" --json   # if canonicalization changed the URL
```

For a match, read attachments and existing properties (the `--json` form omits both):

```bash
rei link show LINK_ID
rei topic associations LINK_ID --json
```

- Already attached to the intended anchor → skip Phase 7's `link add`, still do the rest.
- Attached elsewhere → ask whether to **add** a topic attachment (recommended) or **move** the
  existing one.
- No match → fresh bookmark.

### 3. Work Out the Subjects

Skip the fetch only if the user already stated the subject matter and you recognize all of it.
Otherwise WebFetch asking for: title; a 1–2 sentence statement of what the page is about; the
3–6 subjects it substantively covers, most central first, each marked named thing (with
canonical homepage) or subject area; and the publishing platform. If the fetch fails, ask the
user for title and subjects — nothing has been written yet.

### 4. Survey the Ontology

```bash
rei topic list --json | jq -r '.[] | "\(.topicKey)\t\(.topicLabel)\t\(.topicId)"' | grep -i "SUBJECT"
rei topic ref-show https://SUBJECT-HOMEPAGE --json        # exit 2 = no owner
rei predicate list --json | jq -r '.[] | "\(.predicateKey)\t\(.sourceTypes)\t\(.targetTypes)"'
```

For promising matches and intended types/parents:

```bash
rei topic show TOPIC --json          # refs, types
rei topic attachments TOPIC
rei topic edges TOPIC --json         # .graphEdges.incoming/.outgoing[].predicateKey
rei topic tree TOPIC --direction narrower --include-inferred
```

Per subject record **reuse** (exact or genuinely covering match) or **create**, and for each
create resolve its type (instance) or parent (concept) and whether that exists. Match the
neighbourhood's key style.

### 5. Plan the Placement

- **Anchor** — exactly one: the most specific topic for the primary subject (may be new).
- **About** — every other subject.
- **Create** — each new topic with kind, wiring, and canonical reference; types/parents first.
- **Predicates** — normally none (Phase 6).

Show the plan, then proceed — this is an announcement, not an approval gate. Stop only for real
ambiguity: two existing topics fit the anchor equally, the subject is unclear after fetching, or
a proposed key collides with a topic meaning something different.

```
Bookmark placement for: <TITLE>
<one-line statement>

ANCHOR:  pkl — Pkl                          CREATE (instance)
           instance-of → configuration-language   CREATE (type)
           ref → https://pkl-lang.org
ABOUT:   schema-validation                   CREATE (concept) broader-than ← configuration-language
         infrastructure-as-code              REUSE
PREDICATES: seeded only
PROPERTIES: content-type=documentation, platform=docs_site
```

### 6. Ensure the Predicates

```bash
rei ontology seed-system    # idempotent: about, scoped-to, instance-of, broader-than, narrower-than, related-to, project topic
```

**Reconcile `is-a` vs `instance-of`** before classifying: check how siblings under the intended
type are wired (`rei topic edges TYPE_TOPIC --json`). If they use `is-a`, stay consistent with
`rei edge add ... --predicate is-a`, mention the divergence once, and point at
`rei-curate-ontology` — don't migrate edges here. Otherwise use `instance-of`.

**A new predicate** is needed only for a relationship beyond filing plus `about` ("built on",
"supersedes"). Name it from Schema.org:

```bash
SCHEMAORG=$(mori path mori://schemaorg/schemaorg)
(cd "$SCHEMAORG" && just find-prop "built on")      # properties by name/description
(cd "$SCHEMAORG" && just show SoftwareApplication)  # one type in full
```

A non-empty `supersededBy` means adopt the successor; `isPartOf = https://pending.schema.org`
means proposed (usable — say so). camelCase label → kebab-case key; `comment` → one-line
description with the term IRI appended. Set source/target types from how the edges actually
run, not from `domainIncludes`/`rangeIncludes`:

```bash
rei --actor claude-code predicate define runtime-platform -l "Runtime platform" \
  -d "Runtime platform or script interpreter dependency (schema.org/runtimePlatform)" \
  --source-types topic --target-types topic
```

If nothing standard fits, define a rei-native key and note that. Full procedure:
`rei-curate-ontology` Phase 4.

### 7. Create, Wire, and File

Types and parents first. `topic create` prints no JSON, so read each ID back:

```bash
rei --actor claude-code topic create KEY "LABEL" -d "DESCRIPTION"
rei topic show KEY --json | jq -r .topicId
```

Wire every new topic:

```bash
# instance → type (target-first)
rei --actor claude-code topic associate TYPE_TOPIC INSTANCE_TOPIC_ID --relation instance-of
# is-a workspace
rei --actor claude-code edge add -f INSTANCE_TOPIC_ID -t TYPE_TOPIC_ID -p is-a
# concept placement: broader → narrower, both abstract
rei --actor claude-code edge add -f PARENT_TOPIC_ID -t NEW_TOPIC_ID -p broader-than
# genuine peers (symmetric)
rei --actor claude-code edge add -f TOPIC_A_ID -t TOPIC_B_ID -p related-to
# canonical identity — the thing's own home, not the bookmarked URL
rei --actor claude-code topic add-ref TOPIC https://CANONICAL-HOMEPAGE -l "LABEL"
```

If `add-ref` is refused because another topic owns the reference, you found a duplicate: reuse
that topic instead of forcing a second one.

File the link under the anchor (`--topic` takes the `topic_...` ID). For a **new** link, set
shape/source properties inline; `-p` failures are reported per property but don't block
creation:

```bash
rei --actor claude-code link add --topic ANCHOR_TOPIC_ID "URL" -t "TITLE" \
  -p content-type=VALUE -p platform=VALUE
```

To **move** an existing attachment instead (only if the user chose that):

```bash
rei --actor claude-code link set-topic LINK_ID TOPIC [--attachment ATTACHMENT_ID]
```

Missing title on a reused link: `rei --actor claude-code link title LINK_ID -t "TITLE"`.

### 8. Assert Subjects and Properties

For every subject topic other than the anchor (idempotent; archived topics are refused):

```bash
rei --actor claude-code topic associate TOPIC LINK_ID --relation about
```

Always pass `--relation about` — the default is `scoped-to`.

On a **reused** link, set `content-type` / `platform` only where missing (don't overwrite):

```bash
rei --actor claude-code link set-property -l LINK_ID content-type VALUE
```

Values must come from the definition — read them with `rei custom-property show content-type`
(and `platform`). `author-type` and `media` only when obvious. **Never set `tags`** — subject
matter lives in topics.

### 9. Verify

```bash
rei link show LINK_ID                                     # anchor attachment + properties
rei topic associations LINK_ID --relation about --json | jq -r '.[].topic.key'
rei topic entities TYPE_TOPIC --relation instance-of --json
rei topic tree ROOT_TOPIC --direction narrower --include-inferred
rei ontology validate
```

- Every planned attachment, `about` association, property, and reference is actually present;
  redo any write that silently failed.
- Every new topic is reachable from its type's `instance-of` list or its parent's tree — wire
  any orphan.
- A `validate` error caused by an edge you wrote: fix the edge, never loosen the predicate.
  Pre-existing errors: report and point at `rei-curate-ontology`.

## Output Format

```
## Bookmarked

- **URL**: <url>
- **Link**: <link_id> — <title>  (new / reused canonical link)
- **Anchor**: <key> — <label>  (reused / created)  [attachment added / moved from <old>]

### Topics
- Created: <key> instance-of <type> (ref: <uri>) | <key> broader-than ← <parent>
- Reused: <key>, <key>

### Wiring
- about: <key>, <key>
- Predicates defined: <key> ← <schema.org/term>  (or: none)
- Properties: content-type=<v>, platform=<v>  (or: skipped / already set)

### Verification
- ontology validate: <passed / N pre-existing errors, unchanged>
- all new topics reachable: <yes / fixed>
- Divergences noted: <is-a workspace, duplicate refs, ...>  (or: none)
```

## Important Notes

- Default to **adding** a topic attachment; move an existing one only when the user says so.
- Don't restructure the ontology as a side effect — surface pre-existing errors, duplicates, or
  `is-a`/`instance-of` divergence and point at `rei-curate-ontology`.
