#!/usr/bin/env bash
# CandleKeep session announcement — injects plan-mode directive + manuscripts at session start.
# Output must be JSON with hookSpecificOutput.additionalContext for Claude Code to process it.
# Failures exit silently to never block startup.
#
# IMPORTANT: Keep additionalContext under ~2KB. Claude Code persists large hook
# outputs to a file and only inlines a ~2KB preview. If the directive lands outside
# the preview, the model never sees it. The librarian agent handles full book
# discovery — we only need the item count here, not the full book list.
# Manuscripts are capped at 8 entries (~150 bytes each) to stay within budget.
#
# LATENCY: this hook runs on every session start AND every resume/compact. The two
# data pulls (item count + manuscripts) are cached locally so resumes cost zero
# network round-trips. Genuine new sessions (source=startup/clear) always refresh,
# so new sessions never show stale data. The librarian agent does its own full book
# discovery, so a long cache TTL is safe — the item count / manuscript list is
# informational and changes rarely.
set -euo pipefail

# Local cache of the two network payloads (raw JSON). Keyed globally (item count and
# manuscripts are per-account, not per-directory). TTL is deliberately long — see above.
CACHE_FILE="$HOME/.candlekeep/session-cache.json"
CONFIG_FILE="$HOME/.candlekeep/config.toml"
CACHE_TTL=86400       # seconds (24h); only governs resume/compact — startup always refreshes
CK_FETCH_TIMEOUT=6    # hard per-call cap on the ck network fetches (< the 10s hook timeout)

# Single cleanup for every temp file we may create, set once so later `trap ... EXIT`
# calls can't clobber an earlier one.
items_tmp=""; ms_tmp=""; cache_tmp=""; shelf_tmp=""
_ck_cleanup() { rm -f "$items_tmp" "$ms_tmp" "$cache_tmp" "$shelf_tmp" 2>/dev/null || true; }
trap _ck_cleanup EXIT

# True only for a strictly-positive integer — used to sanity-check epoch timestamps
# read from the cache / `date` before doing arithmetic on them.
_is_pos_int() { [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -gt 0 ]; }

# Run a command under `timeout` when available so a hung CLI or slow API can never
# block Claude Code session startup. `timeout` is absent on some hosts — degrade to
# a raw call there (the hook's own 10s timeout is the last-resort backstop).
_with_timeout() {
  local secs="$1"; shift
  if command -v timeout &>/dev/null; then timeout "$secs" "$@"; else "$@"; fi
}

# File mtime in epoch seconds — GNU (`stat -c`) and BSD/macOS (`stat -f`). Empty on failure.
_mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || true; }

# Guards: ck + jq must be present. Auth is inferred from the items call below (a bad
# token yields no items → silent exit), so we skip a separate `ck auth whoami` round-trip.
if ! command -v ck &>/dev/null; then exit 0; fi
if ! command -v jq &>/dev/null; then exit 0; fi

# Claude Code pipes the hook payload (incl. `.source`) on stdin. Only read when data
# is actually piped — an interactive terminal (`-t 0`, e.g. manual invocation) would
# make an unguarded `cat` block forever.
input=""
if [ ! -t 0 ]; then input=$(cat 2>/dev/null || true); fi
# Note: `source` is a bash builtin — use a distinct name to avoid shadowing it.
hook_source=$(printf '%s' "$input" | jq -r '.source // ""' 2>/dev/null) || hook_source=""

# ---------------------------------------------------------------------------
# Decide: serve from cache (resume/compact + fresh) or refresh from the network.
# ---------------------------------------------------------------------------
items_json=""
ms_json="null"
need_refresh=1

case "$hook_source" in
  resume|compact)
    if [ -f "$CACHE_FILE" ]; then
      cache_ts=$(jq -r '.ts // 0' "$CACHE_FILE" 2>/dev/null) || cache_ts=0
      now=$(date +%s 2>/dev/null || echo 0)
      cfg_mtime=$(_mtime "$CONFIG_FILE")
      use_cache=0
      if _is_pos_int "$cache_ts" && _is_pos_int "$now" \
         && [ $((now - cache_ts)) -lt "$CACHE_TTL" ]; then
        use_cache=1
        # Re-login / account switch / logout rewrites config.toml → its mtime moves
        # past the cache timestamp. Invalidate so we never serve another account's
        # book count or manuscripts (incl. their [auto-update] behavioral directives).
        if _is_pos_int "$cfg_mtime" && [ "$cfg_mtime" -gt "$cache_ts" ]; then use_cache=0; fi
      fi
      if [ "$use_cache" -eq 1 ]; then
        c_items=$(jq -c '.items_json' "$CACHE_FILE" 2>/dev/null) || c_items=""
        c_ms=$(jq -c '.ms_json' "$CACHE_FILE" 2>/dev/null) || c_ms="null"
        if [ -n "$c_items" ] && [ "$c_items" != "null" ]; then
          items_json="$c_items"
          ms_json="$c_ms"
          need_refresh=0
        fi
      fi
    fi
    ;;
esac

if [ "$need_refresh" -eq 1 ]; then
  # Fetch both payloads concurrently — cold start is max(items, ms), not the sum.
  items_tmp=$(mktemp -t ck-items.XXXXXX 2>/dev/null || true)
  ms_tmp=$(mktemp -t ck-ms.XXXXXX 2>/dev/null || true)
  if [ -n "$items_tmp" ] && [ -n "$ms_tmp" ]; then
    _with_timeout "$CK_FETCH_TIMEOUT" ck items list --json >"$items_tmp" 2>/dev/null &
    pid_items=$!
    _with_timeout "$CK_FETCH_TIMEOUT" ck ms list --active --json >"$ms_tmp" 2>/dev/null &
    pid_ms=$!
    set +e
    wait "$pid_items"; items_rc=$?
    wait "$pid_ms"; ms_rc=$?
    set -e
    items_json=$(cat "$items_tmp" 2>/dev/null) || items_json=""
    ms_json=$(cat "$ms_tmp" 2>/dev/null) || ms_json="null"
    [ "$ms_rc" -eq 0 ] || ms_json="null"
  else
    # No temp files available — degrade to sequential fetch.
    items_json=$(_with_timeout "$CK_FETCH_TIMEOUT" ck items list --json 2>/dev/null) || items_json=""
    ms_json=$(_with_timeout "$CK_FETCH_TIMEOUT" ck ms list --active --json 2>/dev/null) || ms_json="null"
    items_rc=0
    [ -n "$items_json" ] || items_rc=1
  fi
  # Auth / availability check: `ck items list` returns a non-zero exit on 401/unauth
  # (or timeout), so a bad/absent token exits here silently. The `.items | length`
  # numeric guard below is a second gate against a 200 with an unexpected body.
  [ "${items_rc:-1}" -eq 0 ] || exit 0
fi

# item_count drives the "You have N books" line. A missing/invalid payload (unauth,
# corrupt cache) means we have nothing useful to say → exit silently.
item_count=$(printf '%s' "$items_json" | jq '.items | length' 2>/dev/null) || exit 0
[[ "$item_count" =~ ^[0-9]+$ ]] || exit 0

# Normalise ms payload to valid JSON or the literal null (manuscripts are optional).
if ! printf '%s' "$ms_json" | jq -e . >/dev/null 2>&1; then ms_json="null"; fi

# Persist the refreshed payloads (atomic write) so the next resume/compact is free.
if [ "$need_refresh" -eq 1 ]; then
  cache_dir="$HOME/.candlekeep"
  if [ -d "$cache_dir" ]; then
    # Create the temp file INSIDE the target dir so `mv` is a same-filesystem
    # atomic rename (a $TMPDIR temp can land on another fs → mv becomes copy+unlink,
    # which is non-atomic and lets a concurrent session read a torn file).
    cache_tmp=$(mktemp "$cache_dir/.session-cache.XXXXXX" 2>/dev/null || true)
    if [ -n "$cache_tmp" ]; then
      now=$(date +%s 2>/dev/null || echo 0)
      if _is_pos_int "$now" \
         && jq -n --argjson ts "$now" --argjson items "$items_json" --argjson ms "$ms_json" \
              '{ts: $ts, items_json: $items, ms_json: $ms}' >"$cache_tmp" 2>/dev/null; then
        mv -f "$cache_tmp" "$CACHE_FILE" 2>/dev/null || true
      fi
    fi
  fi
fi

# Active shelf for this directory (per-project file ./.candlekeep/active-shelf).
# Always live (per-directory, not cacheable), but only touches the network when the
# file exists in cwd. Degrades silently on four failure modes:
#   1. CLI doesn't have `ck shelf` yet (old binary)            → `ck shelf show` errors → no section
#   2. file is missing or empty                                → guard skips probe → no section
#   3. file points at a deleted/renamed shelf                  → `ck shelf show` 404s → no section
#   4. CLI / API hangs                                         → `timeout` kills the call → no section
shelf_section=""
if [ -s ".candlekeep/active-shelf" ]; then
  shelf_slug=$(head -n1 .candlekeep/active-shelf | tr -d '[:space:]')
  # Reject anything that doesn't match the slug character set so a stale or
  # malformed file (e.g. from a malicious repo) can't smuggle unexpected input
  # into the CLI call. The leading char must be alphanumeric — a leading `-`
  # would let the value be parsed as a CLI option (`--json`, a future global
  # flag) rather than the positional target.
  if [ -n "$shelf_slug" ] && [[ "$shelf_slug" =~ ^[a-z0-9][a-z0-9_-]*$ ]] && [ "${#shelf_slug}" -le 64 ]; then
    shelf_tmp=$(mktemp -t ck-shelf.XXXXXX 2>/dev/null || true)
    if [ -n "$shelf_tmp" ]; then
      # Hard 3s cap so a hung CLI or slow API can never block Claude Code session
      # startup (falls back to a raw call where `timeout` is absent). `--` terminates
      # option parsing so the slug can never be read as a flag (defense-in-depth with
      # the regex). Run as an `if` condition so a non-zero exit (deleted/renamed shelf,
      # 404, timeout) is handled here instead of aborting the whole hook under `set -e`.
      if _with_timeout 3 ck shelf show --json --no-session -- "$shelf_slug" > "$shelf_tmp" 2>/dev/null; then
        shelf_name=$(jq -r '.shelf.name // empty' "$shelf_tmp" 2>/dev/null)
        shelf_count=$(jq -r '.shelf.itemCount // 0' "$shelf_tmp" 2>/dev/null)
        if [ -n "$shelf_name" ]; then
          shelf_section="

ACTIVE SHELF: \"${shelf_name}\" (${shelf_count} books, slug: ${shelf_slug}). The librarian agent will give books in this shelf a relevance boost and list them first in its reading list. It still searches the full library and marketplace — this is a preference, not a filter."
        fi
      fi
    fi
  fi
fi

# Build the manuscripts section from the (cached-or-fresh) ms payload.
ms_section=""
ms_count=$(printf '%s' "$ms_json" | jq '.manuscripts | length' 2>/dev/null) || ms_count=0
if [ "${ms_count:-0}" -gt 0 ] 2>/dev/null; then
  # Cap at 8 manuscripts to stay under 2KB total
  max_display=8
  # Markers: [auto-update] = maintain silently at task completion (LLM wiki);
  # [has-instructions] = the manuscript carries a writing playbook to fetch
  # with `ck ms show <id>`. Full instructions are intentionally NOT inlined
  # here to stay within the ~2KB context budget.
  ms_listing=$(printf '%s' "$ms_json" | jq -r --argjson max "$max_display" '
    [.manuscripts[] | select(.itemId != null)][:$max] | map(
      (if .autoUpdate then " [auto-update]" else "" end) as $au |
      (if ((.instructions // "") | length) > 0 then " [has-instructions]" else "" end) as $hi |
      "- \(.title)\($au)\($hi) [ms:\(.id)] [book:\(.itemId)]\n  Topics: \(.topics | join(", "))\n  Criteria: \(.criteria | join(", "))"
    ) | join("\n")
  ' 2>/dev/null) || ms_listing=""

  if [ -n "$ms_listing" ]; then
    overflow=""
    if [ "$ms_count" -gt "$max_display" ]; then
      remaining=$((ms_count - max_display))
      overflow=$'\n'"... and ${remaining} more"
    fi
    ms_section="
MANUSCRIPTS (LLM Knowledge Bases):
You have ${ms_count} active manuscript(s). When you finish a task, check if this session produced insights relevant to any manuscript. If so, propose an addition to the user before declaring complete. Before writing to ANY manuscript, first run \`ck ms show <id>\` (id from its [ms:...] marker) to load its full instructions and criteria, so your addition matches the manuscript's format and scope. Manuscripts marked [auto-update] are maintained automatically at task completion WITHOUT asking — for those, read the instructions, write the addition directly, then post a one-line notice instead of a proposal.

${ms_listing}${overflow}"
  fi
fi

# Plan-mode trigger mode — read live from the local config file the CLI keeps
# in sync (~/.candlekeep/skill-config.json). LOCAL read only — never a network
# call (the hook runs many times per session). Defaults to "always" on any
# failure (missing file, no jq, parse error) to preserve activation-safe
# behavior and the script's silent-degrade discipline.
plan_mode=$(jq -r '.planMode // "always"' "$HOME/.candlekeep/skill-config.json" 2>/dev/null) || plan_mode="always"
case "$plan_mode" in
  always|smart|ask|off) ;;
  *) plan_mode="always" ;;
esac

case "$plan_mode" in
  smart)
    plan_directive="
PLAN MODE DIRECTIVE: When you enter plan mode, first assess whether your library (you have ${item_count} books) likely covers this domain -- architecture, security, a framework/language with a dedicated book, code-review standards. If it does, invoke the CandleKeep skill BEFORE writing your plan: Skill tool with skill=\"candlekeep-cloud:candlekeep\". If the task is trivial or clearly outside your library's scope, skip silently. Never ask the user whether to check -- decide yourself. For explicit research requests, always invoke.
"
    ;;
  ask)
    plan_directive="
PLAN MODE DIRECTIVE: When you enter plan mode, briefly ask the user whether to consult the CandleKeep library before planning (one short question, default yes). If they agree, invoke: Skill tool with skill=\"candlekeep-cloud:candlekeep\". For explicit research requests, invoke without asking.
"
    ;;
  off)
    plan_directive=""
    ;;
  *)
    plan_directive="
PLAN MODE DIRECTIVE: When you enter plan mode (designing features, architecture, security audits, refactoring, code review), you MUST invoke the CandleKeep skill BEFORE writing your plan. Once exploration is complete, invoke: Skill tool with skill=\"candlekeep-cloud:candlekeep\". Do not skip this step. Do not ask the user whether to check the library -- just invoke the skill. If nothing relevant is found, stay silent. For explicit research requests (\"what do my books say about...\", \"research X\"), also invoke the skill.
"
    ;;
esac

context="<candlekeep>
CandleKeep is active. You have ${item_count} books in your library.
${plan_directive}${shelf_section}${ms_section}</candlekeep>"

# Output JSON in the format Claude Code expects for SessionStart hooks
jq -n --arg ctx "$context" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
