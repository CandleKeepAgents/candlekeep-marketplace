# CandleKeep for Claude Cowork

Give Claude a library it can actually read.

CandleKeep turns the PDFs, ebooks and markdown documents you've collected into a knowledge source Claude can search, read and cite inside Cowork. Ask a question, and Claude finds the right books, reads the right pages, and answers with page-level citations instead of guessing from memory. It can also browse the CandleKeep marketplace for a book you don't own yet, and write or update knowledge documents in your library.

This is the Cowork sibling of our Claude Code plugin (`candlekeep-cloud`). Same behaviour, adapted to Cowork's runtime.

---

## Install

**One step, from inside Claude.**

1. Open **Customize → Plugins → Add marketplace**.
2. Paste `CandleKeepAgents/candlekeep-marketplace` and confirm.
3. **CandleKeep** now appears in the plugin list — click **Install**.
4. Claude prompts you to sign in to CandleKeep so the bundled connector can reach your library. Sign in with the same account you use on [getcandlekeep.com](https://www.getcandlekeep.com) and click **Authorize**.

That's it. Installing the plugin adds the skill, the four subagents, and the CandleKeep connector together — no terminal involved. Click **Update** on the marketplace to pull later versions.

> We're under review for Anthropic's official plugin catalog. Once listed, steps 1–2 collapse into **Browse plugins**; marketplaces you added by hand keep working either way.

**Prefer a file?** Download <https://getcandlekeep.com/cowork-plugin.zip> and use the upload option on the **Plugins** page. It's the same package the marketplace serves, but an uploaded file doesn't auto-update. Note this is a *plugin package*, not a skill bundle — install it under **Plugins**, not under **Skills**; the Skills uploader expects a single skill at the top level and will reject it.

Don't have a library yet? [Create a free CandleKeep account](https://www.getcandlekeep.com) and upload a few PDFs first — the plugin reads whatever is in your account.

Illustrated walkthrough: <https://www.getcandlekeep.com/help/cowork>

---

## How it works

The plugin ships three things that install together:

| Component | What it is |
|---|---|
| **`candlekeep` skill** | The orchestrator. It activates automatically when you ask a research, citation, or "write me a doc" question, and delegates the actual work to the subagents. It doesn't do the searching or reading itself. |
| **Four subagents** | The specialists that do the work — each runs in its own context so long reading sessions don't crowd out your conversation. |
| **CandleKeep connector (MCP)** | The bundled connection to `https://www.getcandlekeep.com/api/v1/mcp`, authorised with your account over OAuth. Every library action is a tool call against this server. |

The four subagents:

| Subagent | What it does |
|---|---|
| **librarian** | Finds books. Lists your library, browses the marketplace, subscribes to relevant listings, pulls tables of contents, and returns a short reading list of book ids + page ranges. Never reads pages. If nothing relevant exists, it reports the gap and can suggest a book worth adding. |
| **item-reader** | Reads the pages on that reading list, opens and closes the access session, and returns findings with citations to specific pages. |
| **book-writer** | Creates and edits markdown books in your library — new knowledge docs, new chapters, revisions, and updates to your manuscripts. |
| **book-enricher** | Cleans up thin metadata in the background: a book that came in as `scan_001.pdf` with no author and no table of contents gets a real title, author and TOC. |

A typical research turn: the skill orients itself with a library summary → spawns the **librarian** → hands its reading list verbatim to the **item-reader** → folds the findings into an answer with a citation block. Broad questions get split across several readers running in parallel.

Everything runs through the connector. Cowork has no shell and no filesystem, so there is no CLI to install and nothing written to your machine.

---

## Try it

The skill activates from plain language — no slash command needed. Concrete prompts to start with:

**1. Research a question against your own library**

> What does my library say about backpressure in async Rust? Cite the pages.

The librarian picks the two or three books that actually cover it, the reader pulls the relevant pages, and you get an answer with a citation block listing each book and page range consulted — so you can verify every claim.

**2. Find and add a book from the marketplace**

> I need to get up to speed on Verilog. Check the CandleKeep marketplace, add the best book, and summarise its approach to testbenches.

The librarian browses community-published listings, subscribes to the best match, then reads it in the same turn. If nothing on the marketplace fits either, it records the gap so we know what to publish next.

**3. Write or update a knowledge document**

> Draft a knowledge doc called "On-Call Escalation Policy" covering our rotation, severity levels, and the postmortem template. Then add a section on paging escalation.

The book-writer creates the markdown item in your library, then edits it in place on the follow-up. Every save is versioned, so nothing is overwritten irrecoverably.

**More things that work**

> Summarise chapter 4 of *Refactoring UI* and quote the part about spacing scales.

> Add what we just figured out to my "Building for Agents" manuscript.

> My library has a book called `document.pdf` with no author — clean up its metadata.

---

## Permissions you grant

When you authorize during install, the connector requests:

- **`library:read`** — list, search and read your items and their tables of contents.
- **`library:write`** — create new markdown items, edit existing ones, and enrich metadata.
- **`marketplace:read`** — browse community-published listings.
- **`marketplace:write`** — subscribe to listings (a subscription counts against your plan's item limit).

Revoke at any time from <https://www.getcandlekeep.com/settings>. Revoking immediately invalidates the current access and refresh tokens.

---

## Plans and limits

The plugin respects the same limits as the rest of CandleKeep:

- **Personal (free)** — up to 20 items, 500 reads per month, two-page previews of Professional marketplace books.
- **Professional** — 200 items, unlimited reads, full access to Professional books, and the ability to publish to the marketplace.

If you hit a limit, the plugin says so in one line and links to `/billing`. It never silently truncates an answer.

---

## Privacy

**Full privacy policy: <https://www.getcandlekeep.com/privacy>** · [Terms](https://www.getcandlekeep.com/terms) · [Security](https://www.getcandlekeep.com/security) · [Subprocessors](https://www.getcandlekeep.com/subprocessors)

All traffic goes to `https://www.getcandlekeep.com/api/v1/mcp` over TLS. Tokens are stored hashed at rest and bound to this specific resource (RFC 8707), so a stolen token can't be replayed against another MCP server.

**We store no transcript of your Cowork conversation** — no prompt stream, no turns, no message history. What we do keep is the tool calls themselves plus three short pieces of free text the agent supplies, all of which you can see it write:

| What | Written by | Why we keep it | Limit |
|---|---|---|---|
| A one-line research topic | `start_access_session` | Groups a run of reads into one session | 500 chars |
| An unanswered-question topic | `report_gap` | So we know which book to publish next, and can tell you when it exists | 1000 chars |
| A book-suggestion rationale | `suggest_book` | De-duplicates suggestions | 1000 chars |

The agents are instructed to write subject matter only ("backpressure in async Rust"), never your verbatim question. Independently of that, the server redacts recognisable emails, API keys, access tokens and phone numbers from **all three** of the above before storing them — the same redaction pass runs on every writer, so the guarantee does not depend on the agent behaving.

Reader-gap signals shown to a book's author are abstracted topics only ("missing: testbench randomisation"), never your question text and never anything identifying you.

---

## Troubleshooting

**Claude isn't using CandleKeep when I ask a question.**
Check that the plugin shows as installed and enabled under **Customize → Plugins**, and that the CandleKeep connector next to it is connected. Then try a more explicit phrasing: *"what does my CandleKeep library say about X?"*.

**The authorize step failed, or I'm asked to sign in twice.**
Open <https://www.getcandlekeep.com/dashboard> in your browser first, then retry the install. Claude reuses that session.

**It says my library is empty.**
The plugin reads the account you authorised. Confirm you signed in with the same email you use on getcandlekeep.com, and that your uploads finished processing (the dashboard's Library Health view flags anything stuck or failed).

**An answer mentions a "Professional preview".**
That book comes from the marketplace and its author scoped full access to Professional. On the free plan you see the first two pages. Upgrade at <https://www.getcandlekeep.com/billing> and ask Claude to redo the answer with the full book.

**A book is listed but reads as empty.**
It likely failed to process — often a scanned PDF with no text layer. The plugin will flag it in its answer; re-upload an OCR'd copy, or check Library Health in the dashboard.

**Behaviour looks out of date.**
The connector's tools update live on our side. The skill and subagents ship inside the plugin, so update the plugin from **Customize → Plugins** to pick up workflow changes.

---

## Support

- Email: **support@getcandlekeep.com**
- Support page: <https://www.getcandlekeep.com/support>
- Install guide: <https://www.getcandlekeep.com/help/cowork>

Bug reports, a research answer that went wrong, or a book you wish existed — all welcome at either address.

---

## Differences from the Claude Code plugin

Intentional, and driven by the runtime:

| | Claude Code (`candlekeep-cloud`) | Claude Cowork (this plugin) |
|---|---|---|
| Auth | Browser flow minting a long-lived `ck_…` API key | OAuth 2.1 + PKCE via the bundled connector; tokens rotate |
| Install | `ck setup` from a terminal | One click in Customize → Plugins |
| Reading | `ck items read` in the shell | `read_items` MCP tool returning structured JSON |
| Editing | Downloads markdown to `/tmp`, edits, re-uploads | `get_item_content` → edit in chat → `put_item_content` |
| Suggestion dedup | Local `~/.candlekeep/suggested-books.txt` | Server-side, deduped per user across all clients |
| Repo-stack hints | Reads `package.json` / `Cargo.toml` | Not available — Cowork has no project context |
| Session context | SessionStart hook announces the library | `library_summary` tool call at the start of a task |

Subagent orchestration is the same in both: librarian → item-reader, with book-writer and book-enricher on their own paths.

---

Licensed under the terms in [LICENSE](./LICENSE).
