# Internal Linking Strategy

A repeatable process for adding internal links to blog posts that have **none** (or too few) — built to run inside **Claude** (no software to install).

For each blog it:

1. Reads the **live** content of the post.
2. Suggests internal links with **anchor text that actually appears in the live blog** (verbatim — copy/paste ready).
3. **Prioritizes relevant service pages**, then key trust pages (doctors, contact, location), then other blogs.

Output is formatted to paste straight into the **"Blog Links"** tab of the client's SEO tracker sheet:

```
Anchor: <text>  Target: <url>
Anchor: <text>  Target: <url>
```

---

## Why it exists

Doing internal linking one blog at a time is slow. This process fans the work out across the whole blog list at once and returns paste-ready anchor/target blocks, while enforcing two rules that are easy to get wrong by hand:

- **The anchor must exist in the live page** (so you can find and hyperlink it without rewriting).
- **The target must be a real page on the site** (pulled from the live sitemap — no broken/guessed URLs).

---

## Repository structure

```
internal-linking-strategy/
├── README.md                 <- you are here
├── WORKFLOW.md               <- the reusable step-by-step prompt (run this in Claude for ANY client)
├── OUTPUT-FORMAT.md          <- the locked output standard (same shape for every client)
├── TEAM-INSTRUCTIONS.md      <- how a teammate uses this repo with Claude Code
├── tools/
│   └── build-xlsx.ps1        <- turns recommendations.md into the standard 2-tab .xlsx (needs Excel)
├── data/
│   └── link-inventory.csv    <- the site's linkable pages (url, type, priority, topic)
└── output/
    ├── batch-01.md ...        <- raw worker output per batch
    ├── recommendations.md     <- final compiled, paste-ready results (canonical text output)
    └── <client>-internal-links.xlsx  <- generated spreadsheet (Sheet-Ready + Detailed tabs)
```

**Output shape is fixed** — see [OUTPUT-FORMAT.md](OUTPUT-FORMAT.md). Every client and teammate
gets the same `recommendations.md` block format and the same two-tab spreadsheet.

## How to run it (inside Claude)

1. Open this repo folder in **Claude Code** (the "No folder" session already points here).
2. Give Claude the **client site + the list of blog URLs** that need links, and say:
   > "Follow WORKFLOW.md for these blogs."
3. Claude builds/updates `data/link-inventory.csv` from the live sitemap, processes the blogs, and writes `output/recommendations.md`.
4. Copy each blog's block into the sheet's **Blog Links** tab and set Status.

## The linking rules (what "good" looks like)

- **4–6 links per blog** (fewer if the post is thin — never force it).
- **Anchor = verbatim substring** of the live article body. Natural noun phrases, 2–5 words.
- **Target priority:** `1` service pages → `2` key/trust pages → `3` other blogs. Aim for 2–3 service-page links per post when the topic allows.
- **No self-links**, no duplicate anchors within a post, spread links across the article.

## Publishing changes

This folder is a GitHub Desktop clone of `jkb17-12/internal-linking-strategy`.
After Claude updates files, open **GitHub Desktop → Commit to main → Push origin**. No command line needed.

## Adapting to a new client

Everything is site-agnostic except `data/link-inventory.csv`. For a new client, regenerate that file from the client's sitemap (`/sitemap_index.xml`) — see WORKFLOW.md, Step 1. Service pages get priority `1`.
