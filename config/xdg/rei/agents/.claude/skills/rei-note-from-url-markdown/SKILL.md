---
name: rei-note-from-url-markdown
description: Capture a page's markdown snapshot into Rei as a single note — read a pre-converted markdown file (with frontmatter), reuse or create a link for the source URL, store the file verbatim as one note anchored to an intention, connect them with a `captured-from` edge, tag the note with reused/new facet tags, associate it `about` the existing topics it covers, and verify the stored content. No archive/summary split, no link classification.
allowed-tools: AskUserQuestion, Bash, Read
---

# Rei Note From URL Markdown

Stores a markdown snapshot of a web page (produced by Defuddle, Jina Reader, …) as **one Rei
note whose content is the file, byte-for-byte**. The frontmatter supplies the source URL; the
note is wired to a link for that URL with `note -[captured-from]-> link`, so provenance lives in
the graph rather than in a wrapper header.

Siblings: `rei-ingest-markdown` takes the same input but writes an archive note plus a summary
note and classifies the link — point the user there if they want a summary. `rei-bookmark-url`
files a link into the ontology and creates topics; this skill **reuses topics only**.

## When to Use

- "Capture this page markdown as a note in Rei"
- "Snapshot /tmp/article.md into an intention — don't summarize it"
- "/rei-note-from-url-markdown /tmp/article.md"

## Key Concepts

- **Snapshot note** — the file stored verbatim, frontmatter included; the title is set
  separately. Never pass `rei note new --archive` (that hides the note).
- **`captured-from`** — `note -[captured-from]-> link`, defined by this skill on first use. It
  is not created by `rei ontology seed-system`.
- **Tags vs topics** — `tags` (a `tag-set`) goes on the **note** as filter facets. Subjects
  belong in topics via `rei topic associate TOPIC NOTE_ID --relation about`.
- **Canonical-URL dedup** — `rei link add` normalizes the URL and reuses an existing link,
  adding an attachment rather than a second entity.

## Instructions

Use `rei --actor claude-code <command>` on every write and always pass IDs explicitly
(`-i`, `-n`, `-l`, full entity IDs) — an omitted ID opens an fzf picker. Link, edge, predicate,
and property writes may print an error yet exit `0`, so rely on the read-back in Phase 8.

### Phase 1: Parse the File

Take the path from the arguments or ask. Stop if it is missing, unreadable, or empty. Read the
whole file and parse the leading YAML frontmatter:

- **URL** (required) — first of `url`, `source`, `source_url`, `canonical_url`, `link`; must be
  an absolute `http(s)` URL. If absent, ask the user for it (offering to abort) — never guess.
- **TITLE** — `title`, `name`, `headline`; otherwise derive a short title from the first
  heading. **AUTHOR**, **PUBLISHED**, **SITE** are informational only (they stay in the stored
  frontmatter).

### Phase 2: Check Existing State

`link list --json` exposes `canonical_url` and `original_url` (there is no `url` field):

```bash
rei link list --all --domain DOMAIN --json \
  | jq -r --arg url "URL" '.[] | select(.canonical_url == $url or .original_url == $url) | .id'
```

If nothing matches, retry with `--query "URL"` instead of `--domain`. If a link exists, capture
`LINK_ID` and inspect it:

```bash
rei link show LINK_ID          # attachments (text; --json omits them)
rei edge show LINK_ID --predicate captured-from --json \
  | jq -r --arg l LINK_ID '.[] | select(.status == "active" and .targetId == $l) | .sourceId'
```

An existing snapshot note means the page was captured before: ask whether to capture a fresh
snapshot (the page changed) or stop. Never duplicate silently. (No output is also what you get
when `captured-from` hasn't been defined yet.)

### Phase 3: Choose the Anchor and Category

Reuse the existing link's intention attachment when it has one (tell the user which). Otherwise
take the intention from the request or ask, offering candidates from
`rei intention list --all -s "KEYWORD" --json`.

A category is optional. If one is given, read `rei category print-note-guidance SLUG` and
`rei category show SLUG` first — bound properties are set automatically on the note, so don't
set them again.

### Phase 4: Propose Tags and Topics

Identify the 1–5 subjects the content substantively covers, then gather vocabulary:

```bash
rei custom-property entities tags --json | jq -r '.entities[].value' \
  | tr ',' '\n' | sed 's/^ *//; s/ *$//' | sort -u
rei topic list --json | jq -r '.[] | "\(.topicKey)\t\(.topicLabel)"'
rei topic ref-show https://SUBJECT-HOMEPAGE --json     # topic filed under another key?
```

- **Topics** — for each subject, the existing topic that genuinely covers it (key, label, or
  reference). Subjects with none go on an **uncovered** list; do not create topics here.
- **Tags** — 3–7 facets. Reuse existing tags verbatim (watch plural, abbreviation, synonym, case
  variants); new tags lowercase and hyphenated; no format/source tags (`article`, `snapshot`,
  `markdown`, the site name).

Show the plan (link reused/new, intention, tags marked reused/new, topics, uncovered subjects)
and ask once: apply, edit, or skip tagging/associations. Nothing has been written yet.

### Phase 5: Create the Link and Note

New link, or an existing one not yet attached to this intention:

```bash
rei --actor claude-code link add "URL" -i INTENTION_ID -t "TITLE"
```

Capture `LINK_ID`; fix a missing title with `rei --actor claude-code link title LINK_ID -t "TITLE"`.

```bash
rei --actor claude-code note new -i INTENTION_ID [-c CATEGORY_SLUG] --stdin < "PATH"
rei --actor claude-code note set-title -n NOTE_ID "TITLE"
```

Capture `NOTE_ID` from the output. `note new` exits `2` when the write is refused and `70` on a
store failure — stop and report on either; a link already created stays in place.

### Phase 6: Edge

```bash
rei predicate list --json | jq -e '.[] | select(.predicateKey == "captured-from")' >/dev/null || \
  rei --actor claude-code predicate define captured-from --label "Captured from" \
    --description "This note's content is a captured snapshot of the target link" \
    --source-types note --target-types link
rei --actor claude-code edge add --from NOTE_ID --to LINK_ID --predicate captured-from
```

(`rei predicate show` exits `0` even for a missing key, so it can't be the existence check.)
Never redefine or widen an existing predicate.

### Phase 7: Tag and Associate

```bash
rei --actor claude-code note set-property -n NOTE_ID tags "tag-one,tag-two,tag-three"
rei --actor claude-code topic associate TOPIC_KEY NOTE_ID --relation about
```

`set-property` replaces the whole tag set, so pass every tag in one call. Always pass
`--relation about` — the default is `scoped-to`.

### Phase 8: Verify

```bash
diff <(rei note print NOTE_ID) "PATH" && echo IDENTICAL    # trailing-newline-only diff = pass
rei edge show NOTE_ID --predicate captured-from --json \
  | jq -r --arg l LINK_ID '.[] | select(.status == "active" and .targetId == $l) | .edgeId'
rei note show NOTE_ID                                      # anchor, category, tags
rei topic associations NOTE_ID --relation about --json | jq -r '.[].topic.key'
```

Any content difference beyond trailing whitespace is a failure — report it with the note ID.
Redo once any write missing from the read-back, then report what still is.

### Phase 9: Summary

```
## Page Snapshot Captured

- **File**: <path>
- **URL**: <url>
- **Link**: <link_id> (reused / new)
- **Intention**: <intention_id>   **Category**: <slug or none>
- **Note**: <note_id> — <title> (content verified, N lines)
- **Edge**: note -[captured-from]-> link  (predicate defined this run: yes/no)

### Tags and Topics
- tags: <tag-one, tag-two, ...> (N reused, M new)
- about: <topic-key, ...>
- uncovered subjects: <subject, ...> — file with `/rei-bookmark-url` to grow the ontology

### Skipped / Failed
- <item — reason> (or: nothing)
```
