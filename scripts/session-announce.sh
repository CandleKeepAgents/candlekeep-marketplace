#!/usr/bin/env bash
# CandleKeep session announcement — injects library + marketplace context at session start.
# Output must be JSON with hookSpecificOutput.additionalContext for Claude Code to process it.
# Failures exit silently to never block startup.
set -euo pipefail

# Guard: ck must be installed and on PATH
if ! command -v ck &>/dev/null; then
  exit 0
fi

# Guard: must be authenticated
if ! ck auth whoami &>/dev/null 2>&1; then
  exit 0
fi

# Guard: need jq for JSON parsing
if ! command -v jq &>/dev/null; then
  exit 0
fi

# Fetch library (fail silently)
items_json=$(ck items list --json 2>/dev/null) || exit 0

# Guard: empty library → no announcement needed
item_count=$(echo "$items_json" | jq '.items | length' 2>/dev/null) || exit 0
if [ "$item_count" -eq 0 ]; then
  exit 0
fi

# Fetch marketplace (fail silently — library list is still useful alone)
marketplace_json=$(ck marketplace browse --json --limit 20 2>/dev/null) || marketplace_json='{"listings":[]}'

# Build the context string
library_lines=$(echo "$items_json" | jq -r '.items[] | "- \(.title // "Untitled") (\(.pageCount // "?")pp)"' 2>/dev/null)

marketplace_section=""
marketplace_count=$(echo "$marketplace_json" | jq '.listings | length' 2>/dev/null) || marketplace_count=0
if [ "$marketplace_count" -gt 0 ]; then
  marketplace_lines=$(echo "$marketplace_json" | jq -r '.listings[] | "- \(.item.title // "Untitled") (ck marketplace subscribe \(.id), \(.subscriberCount // 0) subscribers)"' 2>/dev/null)
  marketplace_section="\n\nMarketplace (available to subscribe):\n${marketplace_lines}"
fi

context="<candlekeep-library>
Your Library (${item_count} books):
${library_lines}${marketplace_section}

When working on a substantive task (planning, architecture, code review, debugging, implementation, learning), use the candlekeep skill to search these books for relevant guidance.
Auto-subscribe to marketplace books when they would help the current task.
If nothing is relevant, say nothing about CandleKeep.
</candlekeep-library>"

# Output JSON in the format Claude Code expects for SessionStart hooks
jq -n --arg ctx "$context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
