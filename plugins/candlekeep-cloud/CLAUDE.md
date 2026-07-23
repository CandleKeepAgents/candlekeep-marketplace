# CandleKeep Claude Code Plugin

Claude Code marketplace plugin with agents and skills for CandleKeep.

## Structure

```
.claude-plugin/plugin.json    # Plugin metadata (version here)
agents/
├── item-reader.md            # Research agent — searches library, reads pages
├── book-enricher.md          # Enrichment agent — adds metadata to books
└── book-writer.md            # Writing agent — creates/edits markdown docs
hooks/
└── hooks.json                # SessionStart hook — runs session-announce.sh
scripts/
└── session-announce.sh       # Injects library + marketplace into session context
skills/
└── candlekeep/SKILL.md       # Main skill — ambient activation + research + writing
```

## Version Bumping & Release

Bump version in `plugins/candlekeep-cloud/.claude-plugin/plugin.json` and merge to `main`.

The `plugin-deploy.yml` GitHub Action auto-deploys skill changes to the webapp's `AgentSkill` table on merge. Users' CLIs auto-update within 24h, or immediately via `ck setup`.

## Active Shelf (per-project)

The plugin makes the librarian agent shelf-aware via a soft preference signal — never a filter. The mechanism, end-to-end:

1. The CLI writes the active shelf slug to `./.candlekeep/active-shelf` (a single-line file in the current repo) when the user runs `ck shelf use <slug>`. Each repo has its own active shelf; switching projects flips the signal automatically.
2. On every Claude Code session start, `scripts/session-announce.sh` reads that file from `cwd`, calls `ck shelf show <slug> --json` to validate it, and (on success) injects an `ACTIVE SHELF: "<name>" (<N> books, slug: <slug>)` line into the `<candlekeep>` context block. If the file is absent, empty, or points at a deleted shelf, the line is omitted silently.
3. The librarian agent (`agents/librarian.md` Step 4b) detects that line, identifies shelf members via each item's `shelves[]` field, and applies a **soft preference**: shelf members lead the reading list (marked ` ★ active shelf`) and break ties in ranking — but the librarian still scans the full library and full marketplace.
4. The parent skill (`skills/candlekeep/SKILL.md`) handles direct shelf CRUD requests via bash (`ck shelf list/show/use/...`), offers proactive "set a shelf?" suggestions as **copy-pasteable text** (never silent mutation), and falls back to a recovery message if the CLI predates `ck shelf`.

Backend support lives in `/api/v1/shelves/*` (Bearer auth, mirrors the existing Clerk-authed `/api/shelves/*` routes for the webapp UI). The `Item.shelves[]` array on `/api/v1/items` is what the librarian uses for membership lookup — one round trip, no extra calls.

**Do not add the shelf data path to the parent skill's bash plan-mode allowlist** — proactive shelf mutations route through user-typed commands, not parent-skill execution.
