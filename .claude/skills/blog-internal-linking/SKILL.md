---
name: blog-internal-linking
description: >-
  Adds internal links to blog posts that have none or too few, by reading each
  blog's LIVE page content and returning paste-ready Anchor/Target pairs where the
  anchor text is a verbatim phrase already on the page. Prioritizes linking to
  relevant SERVICE pages first, then key trust pages (doctors, contact, location),
  then other blogs. When a thin post offers few verbatim anchors, it may add a
  clearly-labeled "suggested anchor" — a natural full sentence to insert, with the
  exact placement and a service-page target. Trigger whenever the user wants internal
  links / internal linking for a list of blog URLs, mentions blogs with no or missing
  internal links, asks to "follow WORKFLOW.md", provides blank blog rows from an SEO
  tracker's "Blog Links" tab, or asks for anchor-text-and-target recommendations read
  from live blog content. Works for any client website. This is the LIVE-CONTENT,
  verbatim-anchor blog process — NOT the sitemap-only orphan/crawled-not-indexed
  target-list skill.
---

# Blog Internal Linking

Produces paste-ready internal-link recommendations for a list of blog posts by reading
each blog's **live** content. The anchor text must be a phrase that already appears on the
page (so an editor can find it and hyperlink it without rewriting), and links point first to
relevant **service pages**. Output matches this repo's `OUTPUT-FORMAT.md` exactly.

> If you are running inside the `internal-linking-strategy` repo, `WORKFLOW.md`,
> `OUTPUT-FORMAT.md`, and `tools/build-xlsx.ps1` are the source of truth — follow them.
> This skill encodes the same process so it triggers automatically and works standalone.

## Inputs to confirm before starting
- **Client domain** (e.g. `bigsmiledental.com`).
- **Blog URLs that need links** (usually the blank rows in the sheet's "Blog Links" tab).
- Whether a `data/link-inventory.csv` already exists for this client. If not, build it (Step 1).

If the blog list or domain is missing, ask for it. Do not invent URLs.

## Step 1 — Build the link inventory (targets)
Only if `data/link-inventory.csv` doesn't already cover this client.
1. Fetch `https://<domain>/sitemap_index.xml`, then each child sitemap (`page-sitemap.xml`,
   `post-sitemap.xml`, etc.).
2. Write every linkable URL to `data/link-inventory.csv` with columns `url,type,priority,topic`:
   - `priority 1` = **service pages** (e.g. anything under `/our-services/`) → link here first.
   - `priority 2` = **key trust pages** (doctors/about, contact, location, payment, gallery).
   - `priority 3` = **other blog posts**.
   - `topic` = a short human description so anchors can be matched to the right page.

## Step 2 — Read each blog's LIVE content
For every blog URL, fetch the page (WebFetch) and get the full article body **verbatim**:
> "Return the full main article body text word-for-word, verbatim, with no summarizing,
> paraphrasing, or omissions."

Work only from what the live page actually says. If a fetch fails, flag that blog rather than
guessing its content.

## Step 3 — Choose the links
For each blog pick **4–6** internal links:
- **Anchor text must be a verbatim substring** of that blog's live body text — a phrase a reader
  can actually see. Prefer natural noun phrases, 2–5 words. Never invent or reword a verbatim anchor.
- **Target** must be a URL from `data/link-inventory.csv` and topically match the anchor.
- **Prioritize service pages** (priority 1) — aim for 2–3 per post when the topic allows. Use a
  trust page (e.g. `/about-us/our-doctors/`) when the text mentions the dentist, Dr. <name>,
  "consultation," or credentials.
- No self-links. No duplicate anchors in a post. Don't send two anchors to the same target.
- Spread anchors across the beginning, middle, and end of the article.

## Step 3b — Few verbatim opportunities → suggested anchors
Some blogs are thin, or their wording gives no natural hook to an important service page. When you
cannot reach a good link count from verbatim anchors alone (typically fewer than ~4 usable verbatim
anchors), you MAY add **suggested anchors** — a short piece of *new* copy to insert — instead of
forcing an awkward existing phrase.

A suggested anchor is valid only if it includes **all three**:
1. **A full sentence to add** — natural, factually accurate, and genuinely relevant to that blog's
   topic. It must read like it belongs in the article. The anchor phrase is a substring of it.
2. **The exact placement** — where in the live article to insert it (name a real section/paragraph,
   e.g. "at the end of the *Causes* section, after the paragraph on dehydration").
3. **A target** from the inventory — prefer a relevant **service page**.

Keep suggested anchors rare and high-value (1–2 per thin post at most). Never present suggested copy
as if it already exists on the page. If a post supports neither verbatim nor natural suggested links,
return fewer (minimum 2). Don't force it.

## Step 4 — Output (paste-ready)
Write `output/recommendations.md`: a short header (client + date), then one block per blog.
Verbatim links use `Anchor:` lines; suggested additions use a `SUGGEST:` block after them:

```
BLOG: <blog url>
Anchor: <verbatim text>  Target: <url>
Anchor: <verbatim text>  Target: <url>
SUGGEST: <anchor phrase>  Target: <url>
  Sentence: <full sentence to add, containing the anchor phrase, reads naturally>
  Placement: <exactly where to insert it in the live article>
```

Exact labels and the **two spaces** before `Target:` matter — `tools/build-xlsx.ps1` parses on them.
One blank line between blogs. See `OUTPUT-FORMAT.md` for the full standard.

## Step 5 — Build the spreadsheet
Generate the standard workbook from `recommendations.md` (Excel required):

```
powershell -ExecutionPolicy Bypass -File tools\build-xlsx.ps1 -Client <client-slug>
```

Produces `output/<client-slug>-internal-links.xlsx` with three tabs: `Sheet-Ready` (one row per
blog), `Detailed` (one row per verbatim link), and `Suggested-Additions` (one row per `SUGGEST:`
block). Never hand-build the spreadsheet — always generate it so it stays identical across clients.

## Step 6 — QA before publishing
- Every `Anchor:` is a real substring of the live page.
- Every `SUGGEST:` has a full sentence + exact placement, reads naturally, and points to a relevant
  (ideally service) page; the anchor phrase appears inside its own suggested sentence.
- Every target is in the inventory (no guessed URLs) and isn't the blog itself.
- Each post has at least one service-page link where the topic allows.
- `recommendations.md` and the `.xlsx` match `OUTPUT-FORMAT.md`.

## Scaling
For large blog lists, process in batches (~9 blogs each) with parallel workers, one output file per
batch, then compile into a single `output/recommendations.md` before building the spreadsheet.

## Anti-patterns
- Don't reword or invent verbatim anchors, or point a link to a page not in the inventory.
- Don't pad thin posts with weak links or unnecessary suggested sentences.
- Don't mix suggested (added) copy into the verbatim link list — keep `SUGGEST:` blocks separate.
- Don't confuse this with the sitemap-only orphan-page target-list process; this skill reads the
  live blog and uses verbatim anchors.
