# Output Format Standard (do not change)

Every client, every teammate, every run must produce output in **exactly** this shape.
This is the single source of truth. `WORKFLOW.md` produces it; `tools/build-xlsx.ps1` turns it
into the spreadsheet. Keep it identical across clients — only the URLs and client name change.

---

## 1. `output/recommendations.md` (the canonical text output)

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

## 2. The Excel file `output/<client>-internal-links.xlsx` (generated, never hand-typed)

Built by `tools/build-xlsx.ps1` from `recommendations.md`. Two tabs, fixed columns:

**Tab 1 — `Sheet-Ready`** (one row per blog, mirrors the client's "Blog Links" sheet tab)

| Blog Links | Internal Link -> Anchor Texts | Status |
|---|---|---|
| blog URL | all `Anchor: … Target: …` pairs for that blog, one per line in the cell | (left blank) |

**Tab 2 — `Detailed`** (one row per individual link)

| Blog URL | Anchor Text | Target URL | Target Type |
|---|---|---|---|
| blog URL | anchor | target URL | Service / Key Page / Blog |

---

## 3. The linking rules baked into every result

- **Anchor text is a verbatim phrase from the live page** (find it, hyperlink it — never reworded).
- **Target is a real page** from that client's sitemap (`data/link-inventory.csv`) — never invented.
- **Priority: Service pages first**, then Key pages (doctors/about, contact, location, payment,
  gallery), then other blogs. Aim for 2–3 service-page links per post.
- No self-links, no duplicate anchor within a post, links spread through the article.

## 4. Regenerating the spreadsheet

From the repo folder (Excel must be installed):

```
powershell -ExecutionPolicy Bypass -File tools\build-xlsx.ps1 -Client <client-slug>
```

Produces `output/<client-slug>-internal-links.xlsx`. Omit `-Client` to get `output/internal-links.xlsx`.
