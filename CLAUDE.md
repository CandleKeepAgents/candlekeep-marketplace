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

## Version Bumping

**CRITICAL**: When releasing, bump version in BOTH files:
1. `plugins/candlekeep-cloud/.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json` (at monorepo root)

Both MUST have matching versions.
