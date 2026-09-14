# Internal Linking Workflow (reusable prompt)

Run this inside Claude for any client. It produces paste-ready internal-link
recommendations for a list of blog posts. Copy the steps below to Claude, or just
say **"Follow WORKFLOW.md for these blogs: <list>"**.

---

## Inputs you provide
- **Client domain** (e.g. `bigsmiledental.com`)
- **Blog URLs that need links** (the blank rows in the sheet's "Blog Links" tab)
- Optionally, which page types count as **service pages** for this client

## Step 1 — Build the link inventory (targets)
1. Fetch `https://<domain>/sitemap_index.xml`, then each child sitemap
   (`page-sitemap.xml`, `post-sitemap.xml`, etc.).
2. Write every linkable URL to `data/link-inventory.csv` with columns:
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
- **Target** must be a URL from `data/link-inventory.csv` and topically match the anchor.
- **Prioritize service pages** (priority 1); aim for 2–3 per post when the topic allows.
  Use a trust page like `/about-us/our-doctors/` when the text mentions the dentist,
  Dr. <name>, "consultation," or credentials.
- No self-links. No duplicate anchors in a post. Don't send two anchors to the same target.
- Spread anchors across the beginning, middle, and end of the article.
- Thin post / few natural anchors → return fewer (minimum 2). Don't force it.

## Step 4 — Output (paste-ready)
Write `output/recommendations.md`. For each blog, produce a single block matching
the sheet's "Internal Link -> Anchor Texts" cell format:

```
BLOG: <blog url>
Anchor: <verbatim text>  Target: <url>
Anchor: <verbatim text>  Target: <url>
Anchor: <verbatim text>  Target: <url>
Anchor: <verbatim text>  Target: <url>
```

## Step 5 — QA before publishing
- Every anchor is a real substring of the live page. ✅
- Every target returns 200 and is in the inventory (no guessed URLs). ✅
- Each post has at least one service-page link where relevant. ✅
- No post links to itself. ✅

## Notes on scaling
For large blog lists, process in batches (≈9 blogs each) using parallel workers,
one output file per batch (`output/batch-01.md` …), then compile into
`output/recommendations.md`.
