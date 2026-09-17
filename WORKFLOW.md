# Internal Linking Workflow (reusable prompt)

Run this inside Claude for any client. It produces paste-ready internal-link
recommendations for a list of blog posts. Copy the steps below to Claude, or just
say **"Follow WORKFLOW.md for these blogs: <list>"**.

> **The output must match `OUTPUT-FORMAT.md` exactly** — same file names, same block
> format, same two-tab spreadsheet, same rules — for every client. Do not vary the shape;
> only the client name and URLs change.

---

## Source of truth = what you feed this run
This process is **client-agnostic**. The repo ships **no** site-specific data. For every run the
inputs you provide are the source of truth — nothing about one website is baked in. Never reuse a
previous client's inventory, domain, or recommendations.

## Inputs you provide
- **Client domain** (e.g. `example-dentist.com`).
- **Blog URLs that need links** (the blank rows in the sheet's "Blog Links" tab).
- **The client's page inventory** — either let Step 1 build it from that client's own sitemap, or
  feed your own sitemap/crawl/CSV of the client's URLs. What you feed wins.
- Optionally, which page types count as **service pages** for this client.

Per-client files (one client per set — never overwrite another client's):
- `data/link-inventory-<client>.csv`
- `output/<client>-recommendations.md`
- `output/<client>-internal-links.xlsx`

Start a new client's inventory from `data/link-inventory.TEMPLATE.csv`.

## Step 1 — Build the link inventory (targets)
Use the inventory the user fed if they provided one; otherwise build it from the **client's own**
sitemap:
1. Fetch `https://<domain>/sitemap_index.xml`, then each child sitemap
   (`page-sitemap.xml`, `post-sitemap.xml`, etc.).
2. Write every linkable URL to `data/link-inventory-<client>.csv` (copy
   `data/link-inventory.TEMPLATE.csv` to start) with columns:
   `url,type,priority,topic`
   - `priority 1` = **service pages** (e.g. anything under `/our-services/`) → link here first
   - `priority 2` = **key trust pages** (doctors/about, contact, location, payment, gallery)
   - `priority 3` = **other blog posts**
   - `topic` = a short human description so anchors can be matched to the right page.

## Step 2 — Read each blog's LIVE content
For every blog URL, fetch the page with WebFetch using the prompt:
> "Return the full main article body text word-for-word, verbatim, with no
> summarizing, paraphrasing, or omissions."

Work only from what the live page actually says. If a fetch fails, flag it.

## Step 3 — Choose the links
For each blog, pick **4–6** internal links:
- **Anchor text must be a verbatim substring** of that blog's live body text —
  a phrase a reader can actually see. Prefer natural noun phrases, 2–5 words.
  Never invent or reword an anchor.
- **Target** must be a URL from this client's `data/link-inventory-<client>.csv` and topically match the anchor.
- **Prioritize service pages** (priority 1); aim for 2–3 per post when the topic allows.
  Use a trust page like `/about-us/our-doctors/` when the text mentions the dentist,
  Dr. <name>, "consultation," or credentials.
- No self-links. No duplicate anchors in a post. Don't send two anchors to the same target.
- Spread anchors across the beginning, middle, and end of the article.

### Step 3b — When there are few verbatim anchor opportunities (suggested anchors)
Some blogs are thin, or their existing wording gives no natural hook to an important
**service page**. When you cannot reach a good link count from verbatim anchors alone
(typically fewer than ~4 usable verbatim anchors), you MAY propose **suggested anchors** —
a short piece of *new* copy to add to the post — instead of forcing an awkward existing phrase.

A suggested anchor is only valid if it includes **all three** of:
1. **A full sentence to add** — natural, factually accurate, and genuinely relevant to that blog's
   topic. It must read like it belongs in the article, not like an inserted ad. The anchor phrase
   is a substring of this sentence.
2. **The exact placement** — where in the live article the sentence should be inserted
   (e.g. "at the end of the *Causes* section, after the paragraph on dehydration" or
   "in the conclusion, before the final call-to-action"). Reference a real section/paragraph
   that exists on the live page.
3. **A target** from this client's `data/link-inventory-<client>.csv` — prioritize a relevant **service page**
   (adding a sentence is usually how you earn a missing service-page link).

Rules for suggested anchors:
- Use them to *supplement* verbatim anchors, never to replace easy verbatim wins.
- Keep them rare and high-value — 1–2 per thin post at most. Don't pad.
- Never present a suggested sentence as if it already exists on the page. It is labeled
  separately (see `SUGGEST:` in Step 4) because the editor has to **add** it.
- If a post genuinely supports neither verbatim nor natural suggested links, return fewer
  (minimum 2 total). Don't force it.

## Step 4 — Output (paste-ready)
Write `output/<client>-recommendations.md`. For each blog, produce a single block matching
the sheet's "Internal Link -> Anchor Texts" cell format:

```
BLOG: <blog url>
Anchor: <verbatim text>  Target: <url>
Anchor: <verbatim text>  Target: <url>
Anchor: <verbatim text>  Target: <url>
Anchor: <verbatim text>  Target: <url>
```

`Anchor:` lines are **verbatim** (the phrase already exists on the live page — find it and hyperlink it).

For **suggested anchors** (Step 3b — new copy the editor must add), use a `SUGGEST:` block with an
indented `Sentence:` and `Placement:` under it:

```
SUGGEST: <anchor phrase>  Target: <url>
  Sentence: <full sentence to add, containing the anchor phrase, reads naturally in context>
  Placement: <exactly where to insert it in the live article>
```

List `SUGGEST:` blocks after the verbatim `Anchor:` lines within the same `BLOG:` block. They are
kept visibly separate so no one mistakes added copy for existing text.

## Step 5 — Build the spreadsheet
Turn `output/<client>-recommendations.md` into the standard Excel file (Excel must be installed).
Pass the client slug — the tool reads `output/<client>-recommendations.md` and writes
`output/<client>-internal-links.xlsx`:

```
powershell -ExecutionPolicy Bypass -File tools\build-xlsx.ps1 -Client <client-slug>
```

Tabs: `Sheet-Ready`, `Detailed`, and `Suggested-Additions`. There is no fixed single-site default —
you must name the client (or pass `-In` a specific recommendations file). Never hand-build the
spreadsheet — always generate it so it stays identical across clients.

## Step 6 — QA before publishing
- Every `Anchor:` is a real substring of the live page. ✅
- Every `SUGGEST:` has a full sentence + exact placement, reads naturally, and points to a
  relevant (ideally service) page. The anchor phrase appears inside its own suggested sentence. ✅
- Every target returns 200 and is in the inventory (no guessed URLs). ✅
- Each post has at least one service-page link where relevant. ✅
- No post links to itself. ✅
- `output/<client>-recommendations.md` and the `.xlsx` both exist and match `OUTPUT-FORMAT.md`. ✅
- The inventory used is this client's own (`data/link-inventory-<client>.csv`) — not another site's. ✅

## Notes on scaling
For large blog lists, process in batches (≈9 blogs each) using parallel workers,
one output file per batch (`output/<client>-batch-01.md` …), then compile into
`output/<client>-recommendations.md`.
