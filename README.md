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
├── .claude/
│   └── skills/
│       └── blog-internal-linking/
│           └── SKILL.md      <- the process as a Claude skill (auto-triggers on internal-linking asks)
├── tools/
│   └── build-xlsx.ps1        <- turns <client>-recommendations.md into the standard 3-tab .xlsx (needs Excel)
├── data/
│   ├── link-inventory.TEMPLATE.csv      <- copy this to start a new client (no real site data)
│   └── link-inventory-<client>.csv      <- ONE client's linkable pages (url, type, priority, topic)
└── output/
    ├── <client>-recommendations.md      <- that client's compiled, paste-ready results
    └── <client>-internal-links.xlsx     <- spreadsheet (Sheet-Ready + Detailed + Suggested-Additions tabs)
```

> **Source of truth = what you feed each run.** The repo ships **no** site-specific data. Every file
> is per-client (`data/link-inventory-<client>.csv`, `output/<client>-recommendations.md`, …), so one
> client's data never stands in for another. Committed example runs (e.g. `big-smile-dental`,
> `norman-and-gill`, `mint-dental`) are samples, not defaults.

> **This process is also a Claude skill** (`.claude/skills/blog-internal-linking/`). When this repo
> is open in Claude Code, asking for internal links on a list of blogs auto-triggers the correct
> live-content / verbatim-anchor / service-page-first process — no need to name a skill or file.

**Output shape is fixed** — see [OUTPUT-FORMAT.md](OUTPUT-FORMAT.md). Every client and teammate
gets the same `<client>-recommendations.md` block format and the same three-tab spreadsheet.

## How to run it (inside Claude)

1. Open this repo folder in **Claude Code** (the "No folder" session already points here).
2. Give Claude the **client site + the list of blog URLs** that need links, and say:
   > "Follow WORKFLOW.md for these blogs."
3. Claude builds `data/link-inventory-<client>.csv` from that client's live sitemap (or from an
   inventory you provide — what you feed is the source of truth), processes the blogs, and writes
   `output/<client>-recommendations.md`.
4. Copy each blog's block into the sheet's **Blog Links** tab and set Status.

## The linking rules (what "good" looks like)

- **4–6 links per blog** (fewer if the post is thin — never force it).
- **Anchor = verbatim substring** of the live article body. Natural noun phrases, 2–5 words.
- **Target priority:** `1` service pages → `2` key/trust pages → `3` other blogs. Aim for 2–3 service-page links per post when the topic allows.
- **No self-links**, no duplicate anchors within a post, spread links across the article.
- **Few verbatim anchors?** Claude may add a **suggested anchor** — a `SUGGEST:` block with a full sentence to insert, its exact placement, and a (usually service-page) target. The added copy must be relevant and read naturally in the post, and is always labeled separately from verbatim links so the editor knows to add it. Kept to 1–2 per thin post.

## Publishing changes

This folder is a GitHub Desktop clone of `jkb17-12/internal-linking-strategy`.
After Claude updates files, open **GitHub Desktop → Commit to main → Push origin**. No command line needed.

## Adapting to a new client

The whole process is site-agnostic — nothing is hardcoded to one website. For a new client, copy
`data/link-inventory.TEMPLATE.csv` to `data/link-inventory-<client>.csv` and fill it from **that
client's** sitemap (`/sitemap_index.xml`), or feed your own crawl/CSV — the input you provide is the
source of truth. Service pages get priority `1`. Then run WORKFLOW.md; outputs are written per-client
(`output/<client>-recommendations.md` / `-internal-links.xlsx`).
