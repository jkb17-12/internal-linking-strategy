# Output Format Standard (do not change)

Every client, every teammate, every run must produce output in **exactly** this shape.
This file defines the output *format*; the *data* for any run comes from the client inputs you feed
(domain, blog URLs, that client's inventory) — nothing site-specific is baked in. `WORKFLOW.md`
produces it; `tools/build-xlsx.ps1` turns it into the spreadsheet. Keep the shape identical across
clients — only the URLs and client name change, and every file is per-client
(`output/<client>-recommendations.md`, `output/<client>-internal-links.xlsx`).

---

## 1. `output/<client>-recommendations.md` (the canonical text output)

- A short header (3–4 lines) naming the client and generation date.
- Then one block per blog, in this exact line format:

```
BLOG: <full blog url>
Anchor: <verbatim phrase from the live page>  Target: <full internal url>
Anchor: <verbatim phrase from the live page>  Target: <full internal url>
```

Rules that make the block valid:
- The line starts with `BLOG: ` then the blog URL.
- Each link line is `Anchor: ` + the anchor text + **two spaces** + `Target: ` + the target URL.
- 4–6 link lines per blog (fewer only if the post is thin; minimum 2).
- One blank line between blogs.

> The two spaces before `Target:` and the exact `BLOG:` / `Anchor:` / `Target:` labels matter —
> `tools/build-xlsx.ps1` parses on them. Don't reformat.

### Suggested anchors (`SUGGEST:` blocks)

`Anchor:` lines are **verbatim** — the phrase already exists on the live page. When a post is thin
or has no natural hook for an important (usually service) page, add a **suggested anchor**: a short
piece of new copy the editor inserts. Format, placed after the verbatim `Anchor:` lines in the same
`BLOG:` block:

```
SUGGEST: <anchor phrase>  Target: <full internal url>
  Sentence: <full sentence to add, containing the anchor phrase, reads naturally>
  Placement: <exactly where to insert it in the live article>
```

Rules that make a `SUGGEST:` block valid:
- The header line is `SUGGEST: ` + anchor phrase + **two spaces** + `Target: ` + URL.
- The next two lines are indented `  Sentence: …` and `  Placement: …` (both required).
- The anchor phrase is a substring of the suggested sentence.
- The sentence is relevant, accurate, and natural for that blog; the placement names a real
  section/paragraph on the live page.
- Suggested anchors supplement verbatim ones — 1–2 per thin post at most, never padding.

## 2. The Excel file `output/<client>-internal-links.xlsx` (generated, never hand-typed)

Built by `tools/build-xlsx.ps1` from `output/<client>-recommendations.md`. Three tabs, fixed columns:

**Tab 1 — `Sheet-Ready`** (one row per blog, mirrors the client's "Blog Links" sheet tab)

| Blog Links | Internal Link -> Anchor Texts | Status |
|---|---|---|
| blog URL | all `Anchor: … Target: …` pairs for that blog, one per line in the cell | (left blank) |

**Tab 2 — `Detailed`** (one row per individual verbatim link)

| Blog URL | Anchor Text | Target URL | Target Type |
|---|---|---|---|
| blog URL | anchor | target URL | Service / Key Page / Blog |

**Tab 3 — `Suggested-Additions`** (one row per `SUGGEST:` block — new copy the editor must add)

| Blog URL | Suggested Anchor | Sentence To Add | Placement | Target URL | Target Type |
|---|---|---|---|---|---|
| blog URL | anchor phrase | full sentence to insert | where to insert it | target URL | Service / Key Page / Blog |

This tab only appears populated when a run produced suggested anchors; verbatim links never
appear here, and suggested rows never appear in `Sheet-Ready`/`Detailed`.

---

## 3. The linking rules baked into every result

- **Anchor text is a verbatim phrase from the live page** (find it, hyperlink it — never reworded).
- **Target is a real page** from that client's own inventory (`data/link-inventory-<client>.csv`) — never invented, never another site's.
- **Priority: Service pages first**, then Key pages (doctors/about, contact, location, payment,
  gallery), then other blogs. Aim for 2–3 service-page links per post.
- No self-links, no duplicate anchor within a post, links spread through the article.
- **Few verbatim opportunities?** Supplement with `SUGGEST:` blocks — new copy the editor adds —
  each with a natural, relevant full sentence, an exact placement, and (ideally) a service-page
  target. Suggested copy is always labeled separately, never mixed into verbatim links.

## 4. Regenerating the spreadsheet

From the repo folder (Excel must be installed):

```
powershell -ExecutionPolicy Bypass -File tools\build-xlsx.ps1 -Client <client-slug>
```

Reads `output/<client-slug>-recommendations.md` and produces `output/<client-slug>-internal-links.xlsx`.
`-Client` (or an explicit `-In`) is required — there is no fixed single-site default.
