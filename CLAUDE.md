# CandleKeep Marketplace

Claude Code plugin marketplace for CandleKeep.

## Versioning Rules

**CRITICAL**: When bumping versions, you MUST update BOTH files together:

| File | Location | Purpose |
|------|----------|---------|
| `marketplace.json` | `.claude-plugin/marketplace.json` | Marketplace metadata |
| `plugin.json` | `plugins/candlekeep-cloud/.claude-plugin/plugin.json` | **Plugin version (read by Claude Code)** |

Claude Code reads the version from `plugin.json`, NOT from `marketplace.json`. If you only update one file, Claude Code won't see the version change.

### Version Bump Checklist

When releasing a new version:

1. [ ] Update version in `plugins/candlekeep-cloud/.claude-plugin/plugin.json`
2. [ ] Update version in `.claude-plugin/marketplace.json` metadata
3. [ ] Add entry to `plugins/candlekeep-cloud/CHANGELOG.md`
4. [ ] Commit all three files together

### Example Version Bump

```bash
# Files to update for version X.Y.Z:
# 1. plugins/candlekeep-cloud/.claude-plugin/plugin.json  →  "version": "X.Y.Z"
# 2. .claude-plugin/marketplace.json                      →  "version": "X.Y.Z"
# 3. plugins/candlekeep-cloud/CHANGELOG.md                →  Add ## [X.Y.Z] entry
```
