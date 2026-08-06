# Changelog

## 0.7.0 — Citation block toggle

- The end-of-response CandleKeep citation box can now be turned off per user from the webapp's Settings page (or `ck config set skill.citationBlock off`). Cowork's SKILL.md ships frozen in the uploaded zip, so the live MCP server is the delivery channel: when the setting is off, `read_items` / `get_item_content` results carry a one-line `CITATION STYLE` notice, and the skill's citation-block rules gained a `SKIP always` clause keyed to it. Works for already-installed skill zips too, since the notice arrives in tool output. Inline `(Book Title, p. N)` citations are unaffected; the default (show) is unchanged.

## 0.6.1 — Directory-submission readiness

- Example prompt 3 in the README asked the reader to create a knowledge doc called "Incident Response Runbook", which is also one of the books seeded into the review demo account — so anyone following the prompts verbatim would be told to create something that already existed. Renamed the prompt's target to "On-Call Escalation Policy", which no seeded book uses.
- The marketplace catalog now lists only `candlekeep-cowork`. `candlekeep-cloud` is the Claude Code plugin and needs the `ck` CLI installed locally, so it cannot be exercised from Cowork or by a directory reviewer; it continues to ship through the webapp's `AgentSkill` table instead. The mirror workflow now refuses to publish a manifest that still advertises it.
- Corrected the version heading below: the sub-agent orchestration release shipped as `0.6.0`, but its changelog entry was written under `0.5.0` — a version that never existed in `plugin.json`.
- **Privacy:** the README now links the privacy policy, terms, security and subprocessor pages, and states plainly what is retained. Previously it asserted "not your Cowork conversation" without qualification; three tools do persist short agent-supplied free text (a research topic, an unanswered-question topic, a book-suggestion rationale), and those are now itemised with their retention limits. The same categories were added to the privacy policy's "What We Collect" section.
- **`start_access_session` no longer accepts `itemIds`.** The parameter was declared and then silently discarded, while `item-reader.md` told the agent that listing item ids "is what scopes the session" — it scoped nothing. Removed from the tool schema, the shared type and both agent docs. `intent` is now documented as stored and reviewable, with an instruction to write subject matter only.
- **`subscribe_marketplace` description rewritten** to say outright that it takes no payment and changes no plan. The verb reads as financial, and "financial transactions" is a prohibited category in the directory policy — the handler only grants an access row.
- **`get_table_of_contents` no longer claims to consume the monthly read quota.** On the MCP path it does not: the quota is counted from `AccessLog`, which only the REST read routes write. The description is now silent on metering, which is accurate before and after that counter is wired up.
- **Gap reports filed from Cowork are now secret-scrubbed.** The redaction pass for emails, API keys, tokens and phone-shaped numbers previously ran only on in-book gaps; the MCP tool can only file library gaps, so the one path a plugin user could reach was the only one storing raw text. Both paths scrub now.
- **OAuth discovery metadata points at pages that exist.** `resource_documentation` advertised `/cowork-plugin`, which 404s (verified against production); it now points at `/help/cowork`, and the metadata additionally advertises the privacy policy and terms.

## 0.6.0 — Real sub-agent orchestration

- The `candlekeep` skill is now a pure delegation layer instead of an inlined nine-step workflow. It calls `library_summary` once for orientation and then spawns the four sub-agents that already shipped in the zip: `librarian` (library + marketplace discovery, subscriptions, gap reporting), `item-reader` (targeted reads and cited findings), `book-writer` (create/edit/manuscript updates) and `book-enricher` (opportunistic metadata backfill). This gives Cowork parity with the Claude Code plugin, which has always fanned out to sub-agents.
- Registered `candlekeep-cowork` in the repo-root `.claude-plugin/marketplace.json` so the plugin is installable in a single step from Claude Desktop's *Customize → Plugins* panel — skill, sub-agents and the MCP connector all arrive together.
- Version hygiene: marketplace catalog version is now independent of any individual plugin version (previously it mirrored an old `candlekeep-cloud` release), and the changelog entries below backfill the two releases that shipped without one.

## 0.4.0 — No leaked sub-agents, correct thread-limit errors

- Stopped the skill from leaking one-shot sub-agent scaffolding into user-visible output, and stopped mislabeling Codex thread-limit failures as CandleKeep read-limit failures.

## 0.3.0 — Professional upgrade block

- When a `restricted: true` (pro-only) book materially shapes an answer for a Free user, the skill now renders a boxed upgrade prompt once at the end of the response (mirroring the Citation Block style) instead of a passive inline sentence. The copy quantifies the loss using the **real** page count received ("saw only N of M pages — the rest is locked"; M omitted when unknown, never invented) and offers to **redo the answer with the full book** after upgrade — deliverable, since the next `read_items` returns full content. Applied to both the linear SKILL workflow and the `item-reader` subagent; supersedes the old inline "Some pages are gated…" line so there's one upgrade moment, not two.

## 0.2.3 — Manuscript auto-update

- Manuscripts carry per-manuscript `instructions`, and manuscripts marked `autoUpdate` are appended to without asking for confirmation first.

## 0.2.2 — Republish at clean URL (recover from poisoned CF cache on v0.2.1)

- Post-merge verification curl on v0.2.1 hit `downloads.getcandlekeep.com` ~60s before the Railway redeploy of the downloads service finished, so Cloudflare cached the still-old (no-`attachment;`) response under `max-age=31536000, immutable`. Real users redirected from `getcandlekeep.com/cowork-plugin.zip` would have kept getting the auto-extract behavior for up to a year. Bumping to a fresh version URL is the fastest way to bypass the cached entry — no behavior change.

## 0.2.1 — Force zip download (fix Safari auto-extract)

- Downloads service now sets `Content-Disposition: attachment` on `.zip` artifacts so Safari's "Open safe files after downloading" stops expanding the plugin into a folder. Users were left with `plugin/` on their Desktop, which Claude Desktop's skill uploader rejects.
- Bumped to publish at a fresh URL so the Cloudflare-cached `v0.2.0` response (1-year immutable) doesn't keep serving the buggy header.

## 0.2.0 — Subagents

- Adds four specialist subagents (`librarian`, `item-reader`, `book-writer`, `book-enricher`) that autorun from their `description:` field. The `candlekeep` skill stays unchanged — subagents augment it.
- Subagent files ship inside the plugin zip; users upload them via Claude Desktop / Cowork's *Customize → Skills → Create skill → Upload a skill* flow alongside the main skill.

## 0.1.0 — Initial release

- First public release of the Claude Cowork plugin for CandleKeep.
- One ambient skill (`candlekeep`) running a nine-step linear workflow: orient → discover → survey → read → cite → miss-path → write/edit → enrich → manuscript curation.
- MCP server at `https://www.getcandlekeep.com/api/v1/mcp` exposing 17 tools, with OAuth 2.1 + PKCE auth and RFC 8707 resource binding.
- Server-side deduplication for book suggestions (replaces the local `~/.candlekeep/suggested-books.txt` file used by the Claude Code plugin).
