# Team Guide: Internal Linking with Claude Code

This repo automates internal linking for blogs that have no (or few) internal links.
You give Claude Code a client site + a list of blog URLs; it reads each **live** blog and
returns paste-ready `Anchor / Target` links (anchor text taken word-for-word from the live
page, service pages prioritized). No coding required.

---

## One-time setup (about 10 minutes)

1. **Install GitHub Desktop** — https://desktop.github.com/ — and sign in with your GitHub account
   (ask the admin to add you as a collaborator on `jkb17-12/internal-linking-strategy` first).
2. **Clone the repo:** GitHub Desktop → **File → Clone repository** → pick
   `internal-linking-strategy` → Clone. Note the local folder it saves to
   (usually `Documents\GitHub\internal-linking-strategy`).
3. **Install Claude Code** (desktop app) and sign in.

## Every time you use it

### 1. Get the latest version
Open **GitHub Desktop** → select **internal-linking-strategy** → click **Fetch/Pull origin**.
(This pulls any updates teammates pushed.)

### 2. Open the repo in Claude Code
Claude Code → **Open Folder** → choose the cloned `internal-linking-strategy` folder.

### 3. Give Claude the job
Paste a message like this (fill in the client + blog URLs):

> Follow WORKFLOW.md. Client site: **example-dentist.com**.
> Generate internal links for these blogs:
> - https://example-dentist.com/blog-one/
> - https://example-dentist.com/blog-two/
> - (…paste the blank rows from the client's Blog Links tab…)

**For a brand-new client**, also tell Claude to build the inventory first:

> First build `data/link-inventory.csv` from example-dentist.com's sitemap
> (`/sitemap_index.xml`), marking service pages as priority 1. Then follow WORKFLOW.md
> for the blogs below.

Claude will read each live blog, pick verbatim anchors, prioritize service pages, and write
the results to **`output/recommendations.md`** — in the exact format defined in
`OUTPUT-FORMAT.md` (same for every client).

### 4. Generate the Excel file
Ask Claude to run the builder, or run it yourself from the repo folder (Excel must be installed):

> Build the spreadsheet: run `tools\build-xlsx.ps1 -Client <client-slug>`.

This creates `output/<client-slug>-internal-links.xlsx` with two tabs:
- **Sheet-Ready** — one row per blog (matches the Blog Links tab).
- **Detailed** — one row per link.

### 5. Put the links in the sheet
Open `output/recommendations.md`. For each blog block, copy the `Anchor / Target` lines into
that blog's row in the client's **Blog Links** tab (Column B), then set Status.

### 6. Save your work back to GitHub
GitHub Desktop → you'll see the changed files → write a short summary
(e.g. "Add links for example-dentist – 20 blogs") → **Commit to main** → **Push origin**.

---

## The rules Claude follows (so output is consistent)

- **4–6 links per blog** (fewer if the post is thin — never forced).
- **Anchor = a real phrase from the live page** (find it, then hyperlink it — no rewriting).
- **Target priority:** service pages first → key pages (doctors, contact, location, payment)
  → other blogs. Aim for 2–3 service-page links per post.
- **No self-links**, no duplicate anchors in a post, links spread through the article.
- **Few natural anchors on a thin post?** Claude may add a **suggested anchor** (`SUGGEST:` block):
  a full sentence to insert, exactly where to put it, and a service-page target. It's new copy you
  **add** to the blog — relevant and natural — so it's listed separately (in `recommendations.md`
  and the `Suggested-Additions` tab), never mixed with the verbatim links.

## Good to know

- **Always quick-check thin posts** before publishing — Claude flags any blog that only got
  2–3 links because the topic was narrow.
- **One client per folder is cleanest.** `data/link-inventory.csv` holds one client's pages;
  regenerate it (Step 3, new-client prompt) when switching clients, or keep a copy per client.
- **Never edit files directly on the GitHub website** while also editing locally — pull first,
  then work, then push, to avoid conflicts.
- Questions or a weird result? Send the client + blog URL to the admin.
