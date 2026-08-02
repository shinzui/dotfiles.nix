---
name: rei-note-from-url-markdown
description: Capture a page's markdown snapshot into Rei as a single note — read a pre-converted markdown file (with frontmatter), reuse or create a link for the source URL, store the full markdown verbatim as one note anchored to an intention, connect them with a `captured-from` edge, and tag the note with reused/new topical tags. No archive/summary split, no link classification.
allowed-tools: AskUserQuestion, Bash, Read
---

# Rei Note From URL Markdown

This skill captures a **markdown snapshot of a web page** into Rei as a single note. The
markdown file is typically produced by a URL-to-markdown converter (Defuddle, Jina Reader,
or similar) and has YAML frontmatter containing the source URL and metadata. The skill
stores the markdown **verbatim, as-is** — it is neither archived nor summarized, and no
second note is produced. The result is one note whose content *is* the page content, wired
to a link for the source URL via a `captured-from` edge so the note's provenance is
queryable in the graph.

Contrast with the sibling skill `rei-ingest-markdown`, which splits the same input into an
archive note plus a summary note and classifies the link with `author-type`,
`content-type`, `media`, and `platform`. This skill deliberately does none of that.

## When to Use

Activate when the user says things like:
- "Capture this page markdown as a note in Rei"
- "Store /tmp/article.md as a note from its URL"
- "Snapshot this markdown into an intention — don't summarize it"
- "Add this markdown as a note and record which URL it came from"
- "/rei-note-from-url-markdown /tmp/article.md"

## Key Concepts

- **Snapshot note** — a single Rei note containing the **full markdown content** of the
  source page, stored verbatim. Not summarized, not split, not archived. Anchored to an
  intention.
- **Link** — a Rei entity for the source URL, extracted from the markdown frontmatter.
- **Edge** — a typed relationship between two entities, identified by a predicate.
- **`captured-from` predicate** — `note -[captured-from]-> link`: this note's content was
  captured from this URL. New to this skill; defined on first use with
  `--source-types note --target-types link`.
- **Frontmatter** — YAML block at the top of the markdown file, between `---` fences. Keys
  vary by converter but typically include some of: `url`, `source`, `source_url`, `title`,
  `author`, `published` / `date`, `site_name`. The URL is the only **required** field.
- **Tags on notes** — the global `tags` custom property (`tag-set`) is scoped to notes as
  well as links. This skill tags the **note**, not the link.

## Workflow Overview

1. **Get the markdown file path** — from args or from the user
2. **Read the file and parse frontmatter** — extract URL, title, author, etc.
3. **Check for existing link** — search by URL; if found, reuse it
4. **Get intention ID** — from the reused link's anchor, or ask the user
5. **Create the link** — `rei link add` with title from frontmatter (new links only)
6. **Ensure the `captured-from` predicate exists**
7. **Create the snapshot note** — pipe the full markdown into `rei note new`
8. **Set the note title** — from frontmatter, if present
9. **Create the `captured-from` edge** — `note -[captured-from]-> link`
10. **Tag the note** — harvest existing tags, pick + propose new ones, set `tags`
11. **Summary** — show everything that was created

## Instructions for Claude

### Phase 1: Get the Markdown File Path

The path may be supplied as an argument. If not, ask:

```
Question: "What markdown file should I capture into Rei? (e.g., /tmp/article.md)"
Header: "File"
Options:
- Let me paste the path
```

Validate that the path exists and is readable. If not, stop and tell the user.

### Phase 2: Read the File and Parse Frontmatter

Read the file with the Read tool. Then parse the YAML frontmatter (the block between the
first two `---` fences at the top of the file).

Extract these fields, trying common alternative keys for each:

- **URL** — try `url`, `source`, `source_url`, `canonical_url`, `link` (in that order).
  This field is **required**. If missing, ask the user (see below).
- **TITLE** — try `title`, `name`, `headline`. Optional but strongly preferred.
- **AUTHOR** — try `author`, `byline`, `creator`. Optional.
- **PUBLISHED** — try `published`, `date`, `published_at`, `pubdate`. Optional.
- **SITE** — try `site_name`, `site`, `source_site`. Optional, shown in the note header.

Validate that **URL** is a well-formed absolute URL (`http://` or `https://`). If not, stop
and report the problem.

If there is no frontmatter, or no recognizable URL key, ask explicitly:

```
Question: "This file has no source URL in its frontmatter. What URL is this markdown a snapshot of?"
Header: "URL"
Options:
- Let me paste the URL
- This isn't from a URL — abort
```

Do **not** modify, reformat, or trim the markdown. The whole file is what gets stored.

### Phase 3: Check Whether a Link Already Exists

Extract the registrable domain from the URL (e.g., `example.com`) and search for an
existing link:

```bash
rei link list --all --domain DOMAIN --json | jq -r --arg url "URL" '.[] | select(.url == $url)'
```

If `jq` is unavailable, fall back to:

```bash
rei link list --all --query "URL" --json
```

and scan the output for an exact URL match.

- **If a matching link exists**: capture its ID as `LINK_ID` and any anchor intention ID
  from the output. Inform the user and **skip Phase 5**.
- **If no match**: proceed to Phase 4, then Phase 5.

Also check whether a snapshot note already exists for that link before creating a second
one:

```bash
rei edge show LINK_ID --predicate captured-from
```

(`rei edge show` reports both outgoing and incoming edges for the entity; incoming
`captured-from` edges are the existing snapshot notes. Note that the `captured-from`
predicate may not exist yet on a fresh install — a "no such predicate" error here just
means no snapshot exists, so treat it as a clean result and continue.)

If one is found, tell the user and ask whether to capture a fresh snapshot anyway (the page
may have changed) or stop:

```
Question: "This URL already has a captured snapshot note. Capture another one?"
Header: "Duplicate"
Options:
- Stop — the existing snapshot is fine (Recommended)
- Capture a fresh snapshot (the page changed since last capture)
```

### Phase 4: Get Intention ID

If Phase 3 reused an existing link and its anchor is an intention, use that intention for
the note and skip the question — but tell the user which intention you're using.

Otherwise ask:

```
Question: "Which intention should the snapshot note (and link) be attached to? Provide the intention ID (e.g., intention_01h455vb4pex)."
Header: "Intention"
Options:
- Let me type the intention ID
- Let me browse intentions first
```

If the user wants to browse, run:

```bash
rei intention list
```

Then ask again for the ID.

### Phase 5: Create the Link (new links only)

If `TITLE` was extracted from the frontmatter, pass it with `-t`:

```bash
rei link add "URL" -i INTENTION_ID -t "TITLE" --actor claude-code
```

Otherwise:

```bash
rei link add "URL" -i INTENTION_ID --actor claude-code
```

Capture the new link ID from the command output as `LINK_ID`.

### Phase 6: Ensure the `captured-from` Predicate Exists

`captured-from` is specific to this skill. Define it once, idempotently:

```bash
rei predicate show captured-from >/dev/null 2>&1 || \
  rei predicate define captured-from \
    --label "Captured from" \
    --description "This note's content is a captured snapshot of the target link" \
    --source-types note \
    --target-types link
```

### Phase 7: Create the Snapshot Note

The note holds the **full, verbatim markdown content** of the file — frontmatter included.
Prepend a small provenance header so a human reading the note immediately sees where the
content came from, then a `---` separator, then the file unchanged.

```bash
{
  echo '# TITLE'
  echo ''
  echo 'Captured from: URL'
  [ -n "AUTHOR" ] && echo 'Author: AUTHOR'
  [ -n "PUBLISHED" ] && echo 'Published: PUBLISHED'
  [ -n "SITE" ] && echo 'Site: SITE'
  echo ''
  echo 'This note is a markdown snapshot of the page at the URL above.'
  echo ''
  echo '---'
  echo ''
  cat "/path/to/file.md"
} | rei note new -i INTENTION_ID --stdin --actor claude-code
```

(Substitute the bracketed placeholders inline rather than using shell variables — the
example above shows the structure. Omit the optional lines entirely when the corresponding
frontmatter field is absent.)

Capture the note ID from the output as `NOTE_ID`.

If the user asked for a category, pass `-c CATEGORY_SLUG` to `rei note new` as well. Browse
available categories with `rei category list` if they're unsure.

### Phase 8: Set the Note Title

If `TITLE` was found in the frontmatter, set it explicitly so listings show the page title
rather than a derived one:

```bash
rei note set-title -n NOTE_ID "TITLE"
```

Skip this if no title is available.

### Phase 9: Create the `captured-from` Edge

```bash
rei edge add --from NOTE_ID --to LINK_ID --predicate captured-from
```

If this fails because the predicate is missing, re-run the `rei predicate define` command
from Phase 6 and retry.

### Phase 10: Tag the Note

Goal: assign 3–7 topical `tags` **to the note** that categorize what the content is *about*
(subject matter, technologies, concepts, domains).

**Step 10a — Harvest existing tag vocabulary.**

```bash
rei custom-property entities tags --json
```

The output is an object of the shape:

```json
{
  "count": <int>,
  "entities": [ { ..., "properties": { "tags": "tag-one,tag-two,..." } }, ... ],
  "property": "tags",
  "value_type": "tag-set"
}
```

If `count` is `0` (or `entities` is empty), the vocabulary is empty — proceed with
freshly-minted tags. Otherwise extract every tag value across all entities into a single
deduplicated list (the `EXISTING_TAGS` vocabulary). One-liner:

```bash
rei custom-property entities tags --json \
  | jq -r '.entities[].properties.tags' \
  | tr ',' '\n' \
  | sed 's/^ *//; s/ *$//' \
  | sort -u
```

Note: tags are stored as a single comma-separated string per entity (not a JSON array),
which is why the `tr ','` split is needed.

**Step 10b — Propose tags.** Read the markdown body and choose 3–7 tags that best describe
the subject matter. Apply these rules in order:

1. **Prefer reuse.** If an existing tag covers the concept, use it verbatim — do not create
   a variant. Watch for near-duplicates:
   - singular vs plural (`graph` vs `graphs`) — reuse whichever exists
   - abbreviation vs expansion (`llm` vs `large-language-models`) — reuse whichever exists
   - synonyms (`event-sourcing` vs `event-sourced`) — reuse whichever exists
   - case / punctuation (`EventSourcing` vs `event-sourcing`) — reuse whichever exists
2. **Normalize new tags.** When no existing tag fits, mint a new one in lowercase,
   hyphen-separated, singular-where-natural (e.g., `event-sourcing`, `haskell`,
   `distributed-systems`, `claude-code`). No spaces, no underscores, no punctuation beyond
   hyphens.
3. **Stay topical.** Tags describe the subject matter, not the format or the source. Don't
   tag with `article`, `snapshot`, `markdown`, or the site name.
4. **Be specific but not narrow.** Prefer `event-sourcing` over both `programming` (too
   broad) and `event-sourcing-in-haskell-with-postgres` (too narrow — that's a sentence).
5. **Cap at ~7.** More than 7 tags dilutes the signal; aim for 3–5 when in doubt.

**Step 10c — Confirm with the user.** Show the proposed tags, clearly marking which are
reused from the existing vocabulary and which would be newly minted, then ask:

```
Question: "I propose these tags for the snapshot note. Apply them?"
Header: "Tags"
Options:
- Apply as proposed (Recommended)
- Let me edit the list
- Skip tagging
```

If the user picks "Let me edit the list", accept their revised comma-separated list and
re-validate against the normalization rules (lowercase, hyphenated, no duplicates). Also
re-check the edited list against `EXISTING_TAGS` for near-duplicates and surface any you
notice before applying.

**Step 10d — Apply the tags.** Tags are a `tag-set`, so pass them as a single
comma-separated value in one call:

```bash
rei note set-property -n NOTE_ID tags "tag-one,tag-two,tag-three"
```

Setting replaces the full set, so pass every desired tag in one call.

### Phase 11: Summary

Display a final summary:

```
## Page Snapshot Captured

- **File**: <path>
- **URL**: <url>
- **Link**: <link_id>  (reused existing / newly created)
- **Intention**: <intention_id>
- **Note**: <note_id>
- **Title**: <title or "not set">
- **Size**: <N> lines of markdown stored verbatim

### Edge
- note -[captured-from]-> link

### Tags
- <tag-one, tag-two, ...>  (N reused, M new)

### Next Steps
- Read the snapshot: `rei note show <note_id>`
- Inspect the link: `rei link show <link_id>`
- See what else came from this URL: `rei edge show <link_id>`
```

## Important Notes

- Always use `--actor claude-code` when creating entities (link, note).
- **The note is the page content, verbatim.** Do not summarize, condense, reformat, or trim
  the markdown. The only addition is the small provenance header above the `---` separator;
  everything after it is the file unchanged, frontmatter included.
- **One note, not two.** Unlike `rei-ingest-markdown`, there is no separate summary note and
  no `archives` / `summarizes` edge. If the user actually wants an archive + summary pair,
  point them at `rei-ingest-markdown` instead.
- **The URL comes from frontmatter, not from the user.** If frontmatter is missing or has no
  recognizable URL key, ask the user explicitly — don't guess.
- **`captured-from` is defined by this skill.** Define it idempotently before the first
  `rei edge add`; `rei predicate show captured-from` is the cheap existence check.
- **Check before creating**: `rei link list --all --domain DOMAIN --json` is the cheapest
  way to detect an existing link; fall back to `--query URL` if needed. Never create a
  second link for the same URL.
- **Don't silently re-snapshot**: if a `captured-from` edge already points at the link, ask
  before creating another note. A second snapshot is legitimate when the page changed, but
  it should be a deliberate choice.
- **No link classification.** This skill does not set `author-type`, `content-type`,
  `media`, or `platform`. Tags go on the **note**, via `rei note set-property`.
- **Tags are a `tag-set`**: pass all desired tags as one comma-separated value in a single
  `rei note set-property … tags "a,b,c"` call — `set-property` replaces the full set, so
  splitting it across calls would lose earlier tags.
- The link is created *before* the note; if note creation fails after the link is in place,
  leave the link, report the error, and let the user retry the remaining phases manually.
