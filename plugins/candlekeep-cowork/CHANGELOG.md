# Changelog

## 0.5.0 — Real sub-agent orchestration

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
