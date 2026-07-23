---
name: candlekeep
description: Runs the CandleKeep librarian and reader pipeline inside Cowork. Spawns the librarian to find relevant books in the user's library and the marketplace, spawns the item-reader to read the selected pages, and answers with citations. Also delegates writing and editing books, and metadata enrichment. Use whenever the user asks a research, summarisation, citation, "what does my [book/library] say about…" question, or wants to write a knowledge document.
user-invocable: false
---

# CandleKeep — Librarian + Reader Pipeline (Cowork)

You were invoked to work with the user's CandleKeep library. **You do not do this work yourself — you delegate it to the four sub-agents bundled with this plugin.** Your job is to pick the right agent, give it a good prompt, and shape what comes back into an answer for the user.

## The four sub-agents

| Agent | `subagent_type` | Responsibility | Returns |
|---|---|---|---|
| Librarian | `librarian` | Finds books. Lists the library, browses and subscribes to the marketplace, pulls TOCs, ranks. Never reads pages. Owns the miss path (`report_gap` + `suggest_book`). | `## Reading List` **or** `### No relevant books found` + `<gap_signal>` |
| Item reader | `item-reader` | Reads the page ranges on the reading list, opens and closes the access session, synthesizes with citations. | `## Findings` + `## Sources consulted` |
| Book writer | `book-writer` | Creates and edits markdown books and manuscripts through the MCP server. | One-line confirmation (`Created "Title" (id: …)`) |
| Book enricher | `book-enricher` | Backfills missing title / author / description / TOC on thin books. | `## Enrichment` block |

Spawn them with the Agent tool:

```
Agent tool call:
subagent_type: "<name from the table above>"
prompt: "<see the sections below>"
```

The `subagent_type` is the agent's frontmatter `name`. If your host namespaces plugin agents, `candlekeep-cowork:librarian` (and so on) resolves to the same agent.

## Environment — Cowork has no shell

Every CandleKeep action is an MCP tool call against the `candlekeep` MCP server: `whoami`, `library_summary`, `list_items`, `search_items`, `get_table_of_contents`, `read_items`, `get_item_content`, `put_item_content`, `create_markdown_item`, `enrich_item`, `flag_item`, `start_access_session`, `complete_access_session`, `browse_marketplace`, `subscribe_marketplace`, `report_gap`, `suggest_book`. There is no `ck` CLI, no bash, no filesystem — not for you and not for the agents. Never propose one.

**Do not call the discovery or reading tools yourself.** `search_items`, `browse_marketplace`, `subscribe_marketplace`, `get_table_of_contents`, `read_items`, `start_access_session`, `complete_access_session`, `report_gap`, and `suggest_book` belong to the sub-agents. The only tool you call directly is `library_summary`, once, for orientation and manuscript context.

---

## Orientation

At the start of a CandleKeep task, call `candlekeep:library_summary` once. It returns the user's tier (`FREE` / `PRO`), item count, most recent items, and the list of active **manuscripts**. This is the Cowork equivalent of the SessionStart context the Claude Code plugin gets from its hook — you need the manuscripts for the end-of-task step and the tier for the Professional upgrade block.

Do not repeat this call mid-task, and never let it stand in for spawning the librarian.

---

## Research path

**Trigger patterns:**
- "what do my books say about…", "research X", "look up Y", "refer to my library"
- "according to my documents", "what does [book] say", "check my library for"
- "summarise chapter X of…", "cite [book] on…", "is there a book about…", "find me a book on…"

### Step 1 — Spawn the librarian

```
Agent tool call:
subagent_type: "librarian"
prompt: "[The user's exact research question, plus any context from this conversation
that changes what 'relevant' means — the project, the technology, the decision being made.]

List what's available in the library and the marketplace and tell me which books are
relevant to this. Subscribe to any relevant marketplace listings."
```

Wait for it. The reader has nothing to do until the reading list exists.

### Step 2 — Hand the reading list to the item-reader, verbatim

The librarian returns a block starting with `## Reading List`, containing numbered entries that each carry an `(id: …)`, a `Pages:` range, and a `Why:` line. **Paste that block into the reader's prompt unchanged** — do not summarise it, re-rank it, or drop the ids and page ranges. Those ids and ranges are the entire handoff contract; a paraphrase forces the reader into an extra TOC round-trip and burns read quota on the wrong pages.

```
Agent tool call:
subagent_type: "item-reader"
prompt: "Research the user's question: [the user's exact question]

Read these books:
[paste the librarian's ## Reading List block verbatim — ids, page ranges, Why lines,
plus any ' (Pro preview — 2 pages)' markers and the 'Pro upgrade:' line if present]

RESEARCH_INTENT: [what specifically needs to be learned to answer the question]
Focus on actionable patterns, best practices, and pitfalls."
```

For a broad question spanning several domains, split the reading list by domain and spawn one item-reader per slice. Never spawn a reader without a reading list.

### Step 3 — Answer

Fold the reader's `## Findings` into your answer, preserving its page citations. Then:

1. Append the **Citation Block**.
2. If the reader emitted a `🔒 Locked content` box, append the **Professional upgrade block** after it.

**Librarian health notes.** If the librarian flagged a book with a line like `⚠ "Title" failed to process — <reason>`, pass that one line through to the user. It explains why an obviously relevant book contributed nothing.

**Read limit reached.** If the item-reader reports that the monthly read limit is exhausted ("Monthly read limit reached", "Upgrade to Professional"), that message *is* the answer. Relay it verbatim, including its upgrade link. Do not retry, do not re-spawn the reader, and do not report it as "couldn't retrieve the content".

### Step 4 — Enrichment (opportunistic, explicit research runs only)

On an explicit research run — not on incidental or planning-adjacent use — **after** you have answered the user, spawn the enricher for any book the librarian surfaced whose metadata was clearly thin (placeholder title like `document.pdf`, empty TOC, missing author):

```
Agent tool call:
subagent_type: "book-enricher"
prompt: "Enrich the metadata for book id <id> (current title: '<title>').
Its [title / author / description / TOC] looks missing or placeholder.
Skip it if the metadata is already good."
run_in_background: true   // if your host supports it; otherwise run it after answering
```

Skip this entirely when every book already has a real title, author, and TOC. Never make the user wait on it — the answer ships first.

---

## Miss path

The librarian returns `### No relevant books found` when neither the library nor the marketplace has anything relevant.

**The gap has already been logged.** The librarian calls `report_gap` itself on this path, and `suggest_book` when it can name a book. Do **not** call either from here — you would double-report. Your only two jobs are to surface the suggestion and to make sure no reader is spawned.

**Step 1 — Detect the miss.** Any librarian response containing the literal heading `### No relevant books found`.

**Step 2 — Read the `<gap_signal>` block.** The librarian emits:

```
<gap_signal>
  <intent>...</intent>
  <category>...</category>
  <subcategory>...</subcategory>
  <suggested_title>...</suggested_title>     <!-- omitted when there is no suggestion, or the server said alreadySuggested -->
  <suggested_author>...</suggested_author>   <!-- omitted when unknown -->
</gap_signal>
```

Pull out `<suggested_title>` and `<suggested_author>`. The `<intent>` / `<category>` / `<subcategory>` fields were the librarian's own `report_gap` payload — you don't need them.

If there is no `<gap_signal>` block, skip to Step 4. The librarian's `report_gap` still happened, so no demand signal is lost — you simply have no book to recommend.

**Step 3 — Show the suggestion, once.** Only when `<suggested_title>` is present. Its presence already means the server's dedup cleared it as a new suggestion, so there is nothing for you to check — render the box:

```
┌─ 📖 Suggested Reading ──────────────────────────────────────┐
│                                                              │
│  "[Title]" by [Author]                                       │
│  [One sentence on why this book is relevant]                 │
│                                                              │
│  Your library doesn't cover this topic yet.                  │
└──────────────────────────────────────────────────────────────┘
```

No CandleKeep branding on a miss — the suggestion box stands alone.

**Step 4 — Do NOT spawn readers.** There is nothing to read. Answer from your own knowledge and say plainly that the library didn't cover it.

**Step 5 — Do NOT show the Citation Block.** Nothing was read, so there is nothing to cite.

---

## Writing path

**Trigger patterns:** "write a book about", "create a new document", "edit chapter X", "add a section to…", "draft a manuscript", "update my book on…".

```
Agent tool call:
subagent_type: "book-writer"
prompt: "Help the user with their writing task: [full task description]

[Include the book id if you already know it. If not, the writer will search for the
book and confirm the match with the user before editing.]"
```

The book-writer owns the whole create / get / edit / put cycle. Do not call `create_markdown_item`, `get_item_content`, or `put_item_content` yourself — routing through the agent is what keeps version snapshots and full-body writes correct. Relay the writer's one-line confirmation to the user.

---

## Manuscripts — end-of-task curation

`library_summary` returns active manuscripts in this shape:

```jsonc
{
  "manuscripts": [
    {
      "id": "...",              // manuscript id
      "itemId": "...",          // the BOOK id — this is what the writer edits
      "title": "Building for Agents: The Toolmaker's Guide",
      "topics": ["agent platforms", "tool building for AI", "distribution"],
      "criteria": ["Non-obvious solution to a distribution problem", "..."],
      "instructions": "…",      // how to write/maintain this book (may be null)
      "autoUpdate": true         // if true: maintain automatically, no proposal
    }
  ]
}
```

If `library_summary` returned no manuscripts, skip this entire section.

**When to check:** only at task completion — never mid-task. After you finish the user's request and before declaring done, evaluate each active manuscript.

**Evaluation per manuscript:**
1. Does this session's work match the manuscript's topics?
2. Does the outcome meet at least one of the manuscript's criteria?
3. Is the insight genuinely non-obvious — would someone working in this area benefit from knowing it?

If all three are true, act. If not, stay silent.

### Path A — `autoUpdate: true` (LLM wiki): write directly, no proposal

Spawn the writer:

```
Agent tool call:
subagent_type: "book-writer"
prompt: "Add an entry to an auto-update LLM-wiki manuscript.

Manuscript ID: {manuscript.id}
Book ID: {manuscript.itemId}
Manuscript instructions: {manuscript.instructions verbatim, or 'none provided'}
Insight to add: {the full insight from this session}

FOLLOW the manuscript's instructions exactly (structure, Index/Changelog pages,
interlinks, tone). If none were provided, append cleanly under the most relevant
'#' page. Read the current body with get_item_content, merge, then write the FULL
merged body back with put_item_content."
```

After it returns, post exactly one line to the user — not a proposal box:

```
📝 Added to your LLM wiki "{title}": {one-sentence summary of what was added}
```

The write is reversible from version history, so no confirmation is needed. Still only once per manuscript per session, still only at task completion.

### Path B — no `autoUpdate`: propose and wait

```
┌─ Manuscript: {title} ─────────────────────────────────────┐
│ Chapter: {relevant chapter or "New section"}               │
│                                                            │
│ Proposed addition:                                         │
│ "{2-4 sentence summary of the insight to add}"             │
│                                                            │
│ From this session: {what triggered this — 1 sentence}      │
│                                                            │
│ Say "yes" to add, or "skip" to dismiss.                    │
└────────────────────────────────────────────────────────────┘
```

**On user confirmation**, spawn the writer:

```
Agent tool call:
subagent_type: "book-writer"
prompt: "Edit the book to add the following content.

Book ID: {manuscript.itemId}
Target chapter: {chapter title}
Content to add: {the full proposed text, expanded from the summary}
Writing style: Match the existing book's tone and structure.

Read the current body with get_item_content, insert under the target chapter, then
write the FULL merged body back with put_item_content."
```

**What NOT to do:**
- Don't show a proposal box for an `autoUpdate` manuscript — write directly and post the one-line notice
- Don't drop the manuscript's `instructions` from the writer's prompt — they are the source of truth for how that book is maintained
- Don't edit the manuscript body yourself — that's the book-writer's job
- Don't propose additions for routine or obvious work
- Don't propose if the session was just reading with no new insights
- Don't propose multiple additions to the same manuscript in one session — pick the best one
- Don't interrupt the user mid-task — only act at task completion

---

## Citation Block

When CandleKeep content influenced your response, append a citation block at the very end.

**SHOW** when: an item-reader returned content that you used or referenced in your response.
**SKIP** when: nothing relevant was found (miss path), or the content did not influence what you said.

Format:

```
┌─ CandleKeep ──────────────────────────────────────────────┐
│ Read: Book Title                                           │
│ Learned: key insight 1 · key insight 2 · key insight 3     │
│ How it helped: one sentence on impact                      │
│                                                            │
│ Worth remembering: "A memorable quote or principle from    │
│ the book." — Book Title, p. N                              │
└────────────────────────────────────────────────────────────┘
```

**Field rules:**
- **Read**: Each book title that contributed. One per line if multiple. Max 3; if more, add "+ N more".
- **Learned**: 2–5 short phrases separated by ` · `. The specific insights that mattered, not a content dump.
- **How it helped**: One sentence framing impact as a contrast. "grounded in X, not Y" — not "CandleKeep provided information."
- **Worth remembering**: A single quote or principle from the book that goes *beyond* what was directly used. Pick something surprising, concrete, or counter-intuitive that the user would benefit from knowing over time. Always attribute with book title and page. This field turns the block from attribution into gradual learning.

<examples>

<example>
Single book:
┌─ CandleKeep ──────────────────────────────────────────────┐
│ Read: Refactoring UI                                       │
│ Learned: whitespace hierarchy · softer contrast ·          │
│          one primary action per zone                       │
│ How it helped: UI changes grounded in design theory,       │
│                not taste                                   │
│                                                            │
│ Worth remembering: "Limiting your choices to a handful     │
│ of options frees you from the tyranny of unlimited         │
│ possibility." — Refactoring UI, p. 42                      │
└────────────────────────────────────────────────────────────┘
</example>

<example>
Multiple books:
┌─ CandleKeep ──────────────────────────────────────────────┐
│ Read: Refactoring UI                                       │
│       Clean Code                                           │
│ Learned: whitespace hierarchy · single-responsibility      │
│          functions · softer contrast ratios                 │
│ How it helped: design and code suggestions backed by       │
│                published principles, not guesswork          │
│                                                            │
│ Worth remembering: "The first rule of functions is that    │
│ they should be small. The second rule is that they should  │
│ be smaller than that." — Clean Code, p. 34                 │
└────────────────────────────────────────────────────────────┘
</example>

<example>
Marketplace auto-subscribe:
┌─ CandleKeep ──────────────────────────────────────────────┐
│ Read: Effective Rust Programming (added from marketplace)  │
│ Learned: Result<T,E> over panics · anyhow for apps ·      │
│          thiserror for libraries                           │
│ How it helped: error handling advice from a Rust-specific  │
│                reference, not general knowledge             │
│                                                            │
│ Worth remembering: "Make illegal states                    │
│ unrepresentable." — Effective Rust Programming, p. 8       │
└────────────────────────────────────────────────────────────┘
</example>

</examples>

The citation block comes after your answer, never inline within it. The only thing that may follow it is the Professional upgrade block below.

When the librarian's `### Marketplace actions` section says it subscribed to something, acknowledge it in one sentence in your answer — *"I added 'Effective Rust Programming' from the marketplace because it directly covers your question."* — and mark that title `(added from marketplace)` on the `Read:` line.

---

## Professional upgrade block

Pro gating reaches you through the agents — never invent it, and never infer it from the user's tier alone.

- The **librarian** marks a listing ` (Pro preview — 2 pages)` in the reading list and adds a trailing `Pro upgrade: …` line.
- The **item-reader** appends a `🔒 Locked content` box when `read_items` came back with `restricted: true`.

When a `restricted: true` book **materially shaped** your answer, surface the upgrade exactly once — right after the citation block, as the very last element of your response. The user just felt the value of the locked content; this is the moment.

Use the reader's **real numbers**: `N` = the pages actually received, `M` = the book's total page count *only if the reader or the librarian's TOC actually reported one*. If the total is unknown, say "the first N pages" and do not invent a total. Pick the single most impactful gated book; if there are others, append `+ N more` after its title.

```
┌─ 🔒 Locked content ───────────────────────────────────────┐
│ This answer leaned on <Book Title>, but on Free you        │
│ saw only <N> of <M> pages — the rest is locked.            │
│                                                            │
│ → Upgrade to Pro and I'll redo this answer with the        │
│   full book: https://www.getcandlekeep.com/billing         │
└────────────────────────────────────────────────────────────┘
```

The offer to **redo the answer with the full book** is the point — it is deliverable, because after upgrading the next `read_items` returns full content. Don't soften it into a passive link. Show this block *instead of* any inline "some pages are gated…" sentence — one upgrade moment per response, not two.

`restricted: true` is a successful preview, not an error. Don't apologise for it and don't re-spawn the reader to retry.

---

## Quota and error handling

The MCP server is the source of truth for limits, not this skill. When an agent reports one of these, surface it to the user in one sentence at most:

- **401 Unauthorized:** the user's OAuth session expired or was revoked. Tell them: *"Your CandleKeep connection needs to be refreshed — reconnect the CandleKeep connector in your Claude settings."* Don't retry.
- **403 with `code: PLAN_LIMIT_EXCEEDED`:** the user hit their item count limit (20 on FREE, 200 on PRO). Suggest archiving an item or upgrading.
- **429 Read quota exceeded:** monthly read cap, which applies to **FREE tier only** (500 reads/month). **PRO users have unlimited reads and can never hit this** — if a PRO user sees a 429, treat it as a transient server error and retry, do not tell them they hit a quota. For a genuine FREE-tier 429, suggest waiting for the calendar-month reset or upgrading.
- **200 with `restricted: true`:** a successful preview, not an error — see the Professional upgrade block.

Only the four conditions above are real CandleKeep limits, and only the first two are tier-based. Never invent a "CandleKeep limit", "thread limit", or "quota" the MCP server didn't actually return — if a tool call simply errored or timed out, say so as a transient failure and retry; do not reframe it as the user hitting a usage cap, and never suggest upgrading off a non-quota error.

---

## Common mistakes to avoid

- **Doing the work inline.** If you catch yourself calling `search_items` → `get_table_of_contents` → `read_items`, stop: that is the librarian and the item-reader. Spawn them.
- Spawning an item-reader without first running the librarian — always librarian, then reader.
- Paraphrasing, re-ranking, or truncating the reading list instead of pasting it verbatim — the ids and page ranges are the handoff contract.
- Spawning readers on the miss path — there is nothing to read.
- Calling `report_gap` or `suggest_book` yourself — the librarian already did both. Your only `<gap_signal>` interaction is reading `<suggested_title>` / `<suggested_author>` to render the Suggested Reading box.
- Writing or editing book bodies yourself instead of routing to `book-writer`.
- Mentioning CandleKeep when nothing relevant was found — use the Suggested Reading box: no branding, no citation block.
- Omitting the citation block when reader content shaped your answer, or pasting raw page content into "Worth remembering" — that field is for principles, not excerpts.
- Showing both an inline "pages are gated" sentence and the 🔒 box — one upgrade moment per response.
- Blocking the user's answer on `book-enricher` — it is opportunistic and always runs after the answer.
- Suggesting `ck`, bash, `/tmp`, or any local file operation — Cowork has none of them, only the MCP tools.
