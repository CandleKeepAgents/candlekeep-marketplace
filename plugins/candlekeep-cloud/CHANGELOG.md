# Changelog

All notable changes to the CandleKeep Cloud plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.27.0] - 2026-07-21

### Changed

- **Readers are now dispatched per research angle, not per book** — the librarian previously returned a flat book list and the coordinator spawned one item-reader per book, so a six-book review meant six readers each reading in isolation. The Reading List is now grouped into `#### Angle: <name>` sections (research dimensions like UI/UX, security, data modelling), entries numbered continuously across angles, and **one reader is spawned per angle** receiving that angle's whole group. A six-book, four-angle review now spawns four readers, and the two books that belong to one dimension get read together by a reader that can cross-reference them. Research breadth now scales with the number of distinct angles a problem has — a much better proxy for difficulty than a book count. Applied to both librarians (`agents/librarian.md`, `codex/agents/candlekeep-librarian.toml`) and both coordinators (`skills/candlekeep/SKILL.md`, `codex/skill/candlekeep/SKILL.md`). Both item-readers are now angle-aware and synthesize across the books they're given; the Codex reader — previously written for a single book — batches its reads and cites across the group.

### Fixed

- **Codex users now get the Professional upgrade moment** — the Codex librarian gained the `(Professional preview — first chapter)` marker in 1.26.0, but the rest of the chain didn't exist on Codex: `codex/agents/candlekeep-item-reader.toml` never emitted a `PRO_GATE | <title> | <N> of <M> pages` line, and `codex/skill/candlekeep/SKILL.md` had no upgrade block. So a Codex user never saw the post-answer "this answer opened only N of M pages — upgrade and I'll redo it with the full book" moment that Claude Code users see, which is the one that actually converts. Both pieces are now ported, including the one-upgrade-surface-per-response rule and the real-numbers constraint.

### Removed

- **The librarian eval fixture is gone** — `tests/librarian-eval.md` was a hand-run prose checklist with no runner, and nothing enforced the "re-run before merging" instruction it carried. It is deleted rather than extended.

## [1.26.0] - 2026-07-21

### Changed

- **The Codex `candlekeep-librarian` now matches the Claude Code librarian's full behavior** — the Codex subagent TOML had drifted into a thin "find relevant books" router that emitted a freeform bulleted list and shared only the miss-path vocabulary with `agents/librarian.md`. It dropped the hard output contract, marketplace/pro-tier handling, the web-search-backed book-gap miss path, PII stripping, invisibility, and error handling. The `developer_instructions` are rewritten to encode the *same* behavioral contract as the Claude Code librarian — two-output schema (`## Reading List` on hit / `### No relevant books found` + `<gap_signal>` on miss), silent marketplace subscribe, one-nudge `(Professional preview — first chapter)` marker, the three-step miss path (web search → `ck librarian report-gap` → `<gap_signal>`, with graceful fallback when web search is unavailable), PII-abstracted `<intent>`, and a unified lowercase `<category>` vocabulary. It is phrased in the terse, outcome-first Codex idiom (9-section canon + `<output_contract>`) per OpenAI's prompting guidance, while keeping full execution order because Luna is a small reasoning tier. Model/effort/sandbox unchanged (`gpt-5.6-luna` / `low` / `read-only`).
- **The "1-5 books" cap is removed from both librarians** — the librarian now returns as many books as the task genuinely needs, scaling reader fan-out to problem difficulty (a broad or comparative task can need many books; there is no ceiling). Updated `agents/librarian.md` (schema, Step 4, a new multi-book example, What-NOT-to-Do), the Codex TOML (a `# Retrieval budget` section), and the coupled shelf-preface "top 5" wording in `agents/librarian.md` + `skills/candlekeep/SKILL.md`. Cowork is intentionally untouched.

## [1.25.0] - 2026-07-13

### Changed

- **The Codex `always` directive is now calm and condition-gated** — the default `always` fragment (the one every user on the default setting gets) was a `<EXTREMELY_IMPORTANT>` wall — "TIMING IS LOAD-BEARING", "your VERY FIRST tool call MUST be `spawn_agent('candlekeep-librarian')`", "Do NOT rationalize past the library" — which made Codex spawn the librarian even on trivial tasks (e.g. reviewing a 5-line file), and unlike Claude Code's plan-mode-scoped directive it fired on *every* task. The gating machinery from 1.23.0 already honored `smart`/`ask`/`off`; the remaining defect was purely the `always` calibration. `always` is now an `<IMPORTANT>` block that leads with the librarian for genuine domain-judgment tasks (code review, security, design, architecture, agent dev, research) and carries an explicit **skip list** (typo/rename/lint, git/terminal, build plumbing) so trivial work no longer triggers it. The Codex `SKILL.md` description + body were likewise de-escalated: SKILL.md now owns *how* to run CandleKeep and defers *whether/when* to `AGENTS.md`. Updated in both the deploy source (`codex/AGENTS.md.fragment`) and the CLI's compiled-in fallback (`apps/cli/src/codex_fragments.rs` `ALWAYS`), which also brings the fallback's model reference up to `gpt-5.6-luna`.

## [1.24.0] - 2026-07-12

### Changed

- **Codex subagents now pin GPT-5.6 Luna** — the `candlekeep-librarian` and `candlekeep-book-enricher` subagent TOMLs previously pinned `gpt-5.4-mini` (chosen because it was the only cheap tier available under both ChatGPT-sign-in and API-key auth). The GPT-5.6 generation (GA July 9, 2026) makes all three tiers — Sol/Terra/Luna — available with API-key authentication, so pinning `gpt-5.6-luna` is now portable across both auth modes. Luna is the modern low-cost tier: stronger capability than 5.4-mini at a modest cost bump. The `AGENTS.md` fragments (base + `smart`/`ask` variants) and the `item-reader`/`book-writer` inheritance comments were updated to match. No prompt-structure changes — the Codex bundle stays outcome-first.

## [1.23.0] - 2026-07-06

### Fixed

- **Codex now honors the plan-mode activation setting** — previously the activation mode (`always` / `smart` / `ask` / `off`) was applied only by the Claude Code SessionStart hook (`session-announce.sh`), which re-reads `~/.candlekeep/skill-config.json` every session. Codex has no hook, so its `~/.codex/AGENTS.md` block was written once at install with the static `always` directive and never re-templated — changing the mode to Smart/Off had no effect on Codex. The CLI now re-templates `~/.codex/AGENTS.md` from `planMode` at install and on every mode change (`ck config set`, background config sync): `off` removes the block, `smart`/`ask` install softer directives, `always` keeps the aggressive "librarian-first" wall.

### Added

- **Per-plan-mode Codex `AGENTS.md` fragments** — `codex/AGENTS.md.fragment.smart` and `codex/AGENTS.md.fragment.ask` alongside the base (`always`) fragment. The deploy pipeline ships all three as an `agents_md_fragments` map inside `agent_variants.codex`; the CLI caches them (`~/.candlekeep/codex-fragments.json`) and falls back to compiled-in defaults when the API predates the map. The `__VERSION__` marker in the installed block is now substituted with the running CLI version.

## [1.21.0] - 2026-06-21

### Added
- **Agents now know about `ck report` — bug reports & feature requests from inside a session.** Added a "Reporting Bugs & Feature Requests" directive to the skill (both the Claude Code `SKILL.md` and the Codex variant) so the agent knows when and how to file product feedback via `ck report --title … --body …` (with `--type bug|feature`, `--body-file`, and stdin `--body -`). Triggers are scoped to genuine signals — an unrecoverable `ck`/CandleKeep error, a silently wrong/empty tool result, or the user explicitly reporting a bug or requesting a feature — with an explicit "don't" list (transient/auth/network errors, missing-book gaps) so it doesn't over-report. Phrased as "Use when…" (not "MUST") per prompting guidance to avoid over-triggering, and explicitly disambiguated from the librarian's `report-gap` (missing-book demand signal). Without this, the `ck report` CLI command shipped but was undiscoverable to agents.

## [1.20.0] - 2026-06-14

### Added
- **Professional upgrade block — a contextual, end-of-answer upgrade moment when a Pro book carried the answer.** When a Personal-tier user's research materially leans on a `proOnly` book they could only preview, the main agent now renders a boxed upgrade prompt (mirroring the Citation Block's 60-wide style) as the last element of the response. The item-reader emits a machine-readable `PRO_GATE | <title> | <N> of <M> pages` line (real preview-vs-total page counts from the read response — never invented), and SKILL.md instructs the orchestrator to build one box from it. The copy quantifies the loss ("opened only N of M pages — the rest is locked") and offers to **redo the answer with the full book** after upgrade — a real, deliverable promise since the next read returns full content live. Shown at most once per response; supersedes the reader's old inline upgrade line and the librarian's reading-list upgrade line so it's one moment, not a repeated pitch. Motivated by production data: free, post-trial users hit the Pro preview gate ~1,777×/month (on CandleKeep's own agent-skill books) with near-zero conversion, because the gate signal was stranded in subagent context and never surfaced to the human.

## [1.19.0] - 2026-06-09

### Fixed
- **Manuscript listing now includes the manuscript ID** — the SessionStart hook emits `[ms:<id>]` alongside `[book:<itemId>]` for each active manuscript, and the auto-update directive tells the agent to use the `[ms:...]` value with `ck ms show <id>`. Previously only the book's item ID was in context, so agents ran `ck ms show <bookId>` and hit "Manuscript not found" — one of the two root causes behind LLM wikis never being written (29/1052 seeded wikis in production).
- **SKILL.md ID references corrected** — the book-writer prompts now reference `{the [ms:...] value from the manuscript listing}` and `{the [book:...] value from the manuscript listing}` instead of ambiguous `{id from manuscript listing}` / `{itemId from manuscript listing}`, plus a fallback instruction for sessions running the older hook without `[ms:...]` markers.

### Notes
- The companion CLI release ships the other half of the fix: `ck setup` (and the 24h background updater) now merge explicit `permissions.allow` rules for `ck ms list/show`, `ck items get/toc`, and `ck items put` into `~/.claude/settings.json` — Claude Code's auto-mode permission classifier was silently blocking the wiki write because the `[auto-update]` authorization lives in hook-injected context. The CLI's `ck ms show` also accepts the book's item ID as a fallback.

## [1.17.0] - 2026-05-21

### Changed
- **Librarian agent now surfaces Professional books as a contextual upgrade moment, not a recurring nudge.** When a Personal-tier user's query is best answered by a Professional book, the librarian still subscribes (so the book lands in the user's library with first-chapter access) and marks the most relevant restricted book on the reading list as `(Professional preview — first chapter)`. At most ONE such marker per session, plus a single upgrade line at the end of the list — multiple Pro books on the same reading list no longer each carry an upgrade pitch.
- **Preview length updated from "2 pages" to "first chapter".** Reflects the May-2026 webapp change that replaces the hardcoded 2-page clamp with a chapter-1 boundary. The item-reader's `Pro-restricted` synthesis hint now describes "first chapter" semantics so readers don't pretend the book is exhaustive when only a chapter is visible.
- **Tier names updated to Personal / Professional** in user-facing copy (reading list markers, restricted-read notices, upgrade lines). Schema enum stays FREE/PRO — this is a pure-display rename. Existing Pro subscribers keep their $10/mo price; the new cohort sees the redesigned offer at $19/mo.

## [1.16.2] - 2026-05-12

### Added
- **Skill now surfaces book updates from `ck items read`** — when the CLI reports `freshness.changesSinceLastRead`, the agent narrates what changed (new chapter, refreshed section, word delta) before answering from the book. Surfacing happens only as a side effect of natural reads — no speculative polling.

## [1.16.1] - 2026-05-12

### Changed
- **Codex SKILL.md frontmatter rewritten as a broad activation contract** — replaces narrow "Use for questions that begin with..." trigger with explicit domain enumeration (code review, UI/UX, design, security, architecture, agent development, "research X", "find improvements"). Names `spawn_agent('candlekeep-librarian', ...)` as the REQUIRED first action, BEFORE pwd / file reads / web search. Fixes activation losses to competing installed skills (e.g., `web-design-guidelines`, `audit`, `critique`) on judgment-heavy queries.
- **Anti-rationalization section added to Codex SKILL.md body** — `<EXTREMELY_IMPORTANT>` block at the top of the body enumerates the specific rationalizations Codex uses to skip the librarian ("I'll just read the code first", "I prioritized local repo inspection", "the web has the latest info") and overrides each. Mirrors the proven pattern from Superpowers' `using-superpowers/SKILL.md`.
- **AGENTS.md fragment rewritten as a directive wall** — replaces the single-sentence informational fragment with a `<EXTREMELY_IMPORTANT>` block containing the proactive-activation trigger list, "TIMING IS LOAD-BEARING" first-tool-call rule, anti-rationalization examples, and explicit skip-list for mechanical edits. ~2 KB total — Codex concatenates AGENTS.md into every session prompt, so this becomes the SessionStart-equivalent directive surface.

### Fixed
- **`ck` CLI panic inside Codex's read-only sandbox** — `reqwest` switched from `native-tls` to `rustls-tls` (and `default-features = false` to drop the `macos-system-configuration` proxy probe). Previously `ck items list` hit a Rust panic in `system-configuration-0.6.1/src/dynamic_store.rs:154:1` ("Attempted to create a NULL object") because Codex's seatbelt blocked the `SCDynamicStoreCreate` IPC to `configd`. Codex now sees a graceful DNS error if network is sandbox-blocked instead of a Rust stack trace, and `ck` from inside the sandbox just works for read paths that don't need network (`ck items get --no-session`).
- **Deprecated Codex skill path not cleaned up on upgrade** — `install_codex_bundle` now removes `~/.codex/skills/candlekeep/` after writing the new `~/.agents/skills/candlekeep/SKILL.md`. Existing users upgrading from pre-1.15 layouts were seeing TWO `candlekeep` entries in Codex's `/skills` picker because Codex auto-discovers both the old (`.codex/skills/`) and new (`.agents/skills/`) paths. Only the `candlekeep/` subdir is removed; sibling skills under `~/.codex/skills/` are preserved.

## [1.16.0] - 2026-05-12

### Added
- **Codex CLI install bundle** — `ck setup` on a machine with OpenAI Codex CLI installed now provisions a Codex-tuned SKILL.md at `~/.agents/skills/candlekeep/`, four subagent TOML files at `~/.codex/agents/candlekeep-{librarian,item-reader,book-writer,book-enricher}.toml`, and an idempotent CandleKeep block in `~/.codex/AGENTS.md`. Replaces the previous single-file install that mirrored the Claude Code skill.
- **Codex prompts authored against OpenAI's Cookbook Codex Prompting Guide** — SKILL.md and all four subagent `developer_instructions` use the Cookbook's 9-section canon (General / Autonomy and Persistence / Exploration and Reading Files / Plan Tool / Presenting Your Work), Pragmatic personality, and `multi_tool_use.parallel` as the canonical batching mechanism.
- **Model assignments per subagent task class** — librarian and enricher pin to `gpt-5.4-mini` (Codex docs' explicit subagent recommendation, available to all auth modes). item-reader and book-writer omit `model` to inherit the session default (gpt-5.5 for ChatGPT-sign-in users, gpt-5.4 for API-key users), so no hard failure either way.

### Changed
- `InstallType::CodexBundle` introduced; Codex agent now uses `skills_dir: ".agents/skills"` per OpenAI's actual filesystem convention (was incorrectly `.codex/skills`).

## [1.14.3] - 2026-05-11

### Added
- **Pro-restriction handling in `item-reader` and `librarian` agents** — agents now detect `proRestricted: true` (or the `⚠ Pro-only book — showing N/M preview pages` CLI banner) in responses and surface the restriction explicitly in their synthesis instead of silently truncating. The reader includes a dedicated "Pro-restricted notice" section with the upgrade URL; the librarian marks Pro books in its reading list with ` (Pro preview — 2 pages)` and prefers non-Pro books on relevance ties.

### Notes
- Version bumped from 1.14.2 to force a cache refresh on existing installs. The agent prompt content shipped with the merge of PR #183, but without a version bump existing users would only pick up the new prompts on the 24h auto-refresh window. Bumping the manifest version triggers the version-mismatch path in `ck setup` and refreshes the local plugin cache immediately on the next `ck` invocation.

## [1.13.0] - 2026-04-14

### Changed
- **Skill description rewritten as routing classifier** — passive "Augments planning and research..." replaced with imperative "Searches... Use when entering plan mode (designing features, architecture decisions, security audits...)" to fix auto-triggering failure. Follows proven patterns from "Writing Effective Tools for Agents" and "The Complete Guide to Building Skills for Claude".
- **Plan mode integration streamlined** — single-phase librarian → reader pipeline (after exploration, before design). Removed Phase 2 "validate plan after writing" to reduce complexity.
- **Decision tree simplified** — plan mode and explicit research both use librarian → reader; ambient activation removed in favor of focused plan mode triggering.

### Removed
- **Ambient Activation section** — replaced with focused Plan Mode integration. The broad "fire on any substantive task" pattern caused neither plan mode nor ambient to trigger reliably.
- **Marketplace Discovery and Library Management sections** — these are direct CLI operations, not skill-level features. Reduces skill content size for better attention budget.

## [1.12.0] - 2026-04-13

### Added
- **Librarian agent** — new `agents/librarian.md` (Haiku model). Lists all library + marketplace books, decides relevance based on metadata, auto-subscribes to useful marketplace books, and returns a targeted reading list for item-reader agents. Does NOT read book content.
- **Plan mode integration** — two-phase CandleKeep pipeline during plan mode:
  1. After exploration: librarian finds relevant books → reader(s) extract knowledge
  2. After plan written: librarian + reader(s) review plan against books

### Changed
- **SKILL.md rewritten** — plan-mode-only activation (not every task). Simplified decision tree: plan mode → librarian → reader(s) pipeline. Removed ambient activation on every task.
- **item-reader trimmed** — removed marketplace gap check (Step 5). Reader now receives targeted prompts from librarian with specific book IDs and page ranges. Marketplace acquisition is the librarian's job.
- **session-announce.sh** — removed empty-library exit guard. Even users with 0 books now get CandleKeep context (marketplace catalog injected so librarian can find books for them).

### Removed
- Marketplace Discovery section from SKILL.md (librarian handles invisibly)
- Library Management section from SKILL.md (users don't manage libraries)
- Ambient activation on every task (plan mode only now)
- Marketplace gap check from item-reader (librarian's responsibility)

## [1.11.1] - 2026-04-11

### Changed
- **item-reader model switched from Opus to Sonnet** — experiment (CND-430) showed Sonnet delivers 99.4% of Opus quality at 20% cost with zero citation accuracy loss

## [1.11.0] - 2026-04-11

### Added
- **Citation Block** — agents now append a structured citation block at the end of responses when CandleKeep content influenced the answer. Shows what was read, what was learned, how it helped, and a "Worth remembering" quote for gradual learning.
- **Citation Summary** in item-reader output — pre-digested data (books, takeaways, impact, memorable quote) that the main agent uses to build the citation block.

## [1.10.0] - 2026-03-31

### Added
- **SessionStart hook** — `hooks/hooks.json` + `scripts/session-announce.sh`: injects library books and marketplace catalog into Claude's context at every session start as a behavioral prompt (XML-tagged, compact format)
- **Ambient activation** — skill now fires on any substantive technical task (planning, architecture, code review, debugging, implementation, learning) without requiring explicit research keywords
- **hook_files support in CLI** — `ck setup` now installs hook files and scripts from the plugin, making scripts executable automatically

### Changed
- **SKILL.md rewritten** for Opus 4.6 — softer trigger language, constraints-based instructions, XML-structured sections, under 5,000 tokens
- **Frontmatter description broadened** — covers planning, architecture, code review, debugging, implementation, learning, not just research/writing keywords
- **Plan Mode section replaced** with broader Ambient Activation section
- **"When NOT to Trigger" narrowed** — only excludes truly trivial tasks and explicit opt-outs

## [1.6.0] - 2026-02-14

### Added
- Research session tracking in item-reader agent (Step 0: start session, Step 6: complete session)
- RESEARCH_INTENT passed from skill to item-reader for intent tracking
- `--no-session` flag on all book-enricher commands to avoid session interference

### Changed
- book-enricher and book-writer agents now explicitly opt out of session tracking

## [1.5.1] - 2026-02-12

### Added
- **README.md** for the candlekeep skill — human-readable guide with quick start, prerequisites, and agent descriptions
- **"When NOT to Trigger" section** in SKILL.md — prevents false triggers on web search, file I/O keywords, and general knowledge questions
- **"Common Mistakes to Avoid" section** in SKILL.md — 5 Bad/Better anti-patterns covering upload-without-download, stale IDs, page range errors, TOC verification, and direct CLI usage
- **Cross-references between agents** — each agent now lists related agents with handoff guidance

### Changed
- **Skill description sharpened** — value proposition replaces verb list

## [1.5.0] - 2026-02-04

### Added
- **Book Writer Agent** - New `book-writer` subagent for creating and editing markdown documents
  - Create new markdown documents with `ck items create`
  - Retrieve content with `ck items get`
  - Update content with `ck items put`
  - Full support for markdown editing workflow
- **Writing Trigger Keywords** - Skill now triggers for writing-related requests
  - "write", "draft", "create document", "start writing", "compose"
  - "take notes", "write notes", "document this", "capture"

### Changed
- Candlekeep skill description updated to mention writing capabilities
- Decision tree updated with book-writer launch path

## [1.4.1] - 2026-02-03

### Added
- **TOC Verification Requirement** - Book enricher must verify TOC page numbers before submitting
  - Determine PDF page offset vs printed page numbers
  - Verify at least 3 TOC entries by reading actual pages
  - Only submit TOC if verified entries match content
- **Enrichment Quality Guidelines** in candlekeep skill explaining why TOC accuracy matters

### Changed
- Book enricher TOC Guidelines expanded with mandatory verification steps
- Candlekeep skill updated with enrichment quality section

## [1.4.0] - 2026-02-03

### Added
- **TOC Extraction** - Book enricher agent now extracts and saves table of contents
  - Checks existing TOC via `ck items toc`
  - Scans content for chapter structure if TOC is missing
  - Submits TOC with `--toc` flag in JSON format
  - Guidelines for level structure (Part > Chapter > Section)
  - Instructions for using PDF page numbers vs printed page numbers

### Changed
- Book enricher description updated to mention TOC support
- Enrichment workflow now includes TOC extraction as step 3

## [1.3.0] - 2026-02-03

### Added
- **Book Enricher Agent** - New `book-enricher` subagent that automatically enriches books with missing metadata
  - Reads first 5-10 pages to extract title, author, and description
  - Submits enrichments with confidence scores (0.0-1.0)
  - Processes items from the enrichment queue prioritized by page count
- **Metadata Flagging** - item-reader now flags books with poor metadata during research
  - Detects filename-like titles (e.g., "document.pdf", "scan_001.pdf")
  - Uses `ck items flag <id>` to queue items for enrichment

### Changed
- item-reader updated with metadata flagging guidance

## [1.2.0] - 2025-01-30

### Changed
- Version bump to sync with marketplace metadata

## [1.1.0] - 2025-01-30

### Added
- **Proactive Research Triggering** - The skill now automatically triggers when detecting research-related keywords
- **Trigger Keywords** - Organized into categories:
  - Research words: "research", "investigate", "study", "explore", "dig into"
  - Reading words: "read", "read about", "what does it say", "tell me about"
  - Reference words: "refer", "refer to", "reference", "consult", "check"
  - Lookup words: "look up", "look into", "find", "search for", "search my"
  - Library words: "my documents", "my library", "my books", "my PDFs", "my files"
  - Knowledge words: "according to", "based on", "what do my", "does my library"
- **12 Trigger Patterns** - Common phrase patterns that auto-invoke the skill
- **6 Auto-Trigger Scenarios** - Defined scenarios for automatic subagent launch
- **Enhanced Decision Tree** - Updated with automatic paths for trigger keywords

### Changed
- **Skill Description** - Now keyword-rich to improve automatic skill matching
- **Example Workflows** - Added more examples including incorrect response patterns
- **"DO NOT HESITATE" Guidance** - Explicit instruction to launch subagent proactively

## [1.0.0] - 2025-01-29

### Added
- Initial release
- CandleKeep Cloud document library integration
- `item-reader` subagent for research questions with citations
- CLI commands for library management (list, add, remove)
- Authentication handling with automatic re-auth flow
- Prerequisites check and installation guidance
