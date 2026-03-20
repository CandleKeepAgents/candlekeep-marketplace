---
name: code-review
description: Run a comprehensive code review using CandleKeep books. Launches parallel review agents — code quality (186-rule book), security (webapp security book), and UI/UX (design principles book) — each with its own context window. Trigger on "code review", "review my code", "review this PR", "review the diff", "/code-review".
---

# CandleKeep Code Review — Parallel Multi-Agent Review

Three specialized agents review code simultaneously, each powered by a dedicated CandleKeep book and operating in its own clean context window. The lead (you) orchestrates: prepare the diff, classify it, launch relevant agents, synthesize results.

## Architecture

This follows the **parallelization (sectioning)** pattern from Anthropic's "Building Effective Agents" — each agent focuses on one aspect of the review with dedicated context, then the lead synthesizes.

| Agent | Book ID | Pages | Focus |
|-------|---------|-------|-------|
| `code-reviewer` | `cmmwi3mo700vlta0zlbfqjtcb` | 546 | 186 rules: naming, functions, classes, errors, performance, testing, concurrency, API, database |
| `security-reviewer` | `cmmj33tuj00pumw01eqmthzdh` | 39 | CSRF, SSRF, BOLA, mass assignment, auth, headers, prototype pollution, GraphQL |
| `uiux-reviewer` | `cmmfdl2z503qep10zhi9dp1m4` | 15 | Accessibility, responsive design, component patterns, UX heuristics |

## Workflow

### Step 1: Prepare the Diff

Determine what to review, in order of preference:

1. **PR number/URL provided** → `gh pr diff <number> > /tmp/code-review-diff.txt`
2. **On a feature branch** → `git diff main...HEAD > /tmp/code-review-diff.txt`
3. **Uncommitted changes** → `git diff > /tmp/code-review-diff.txt && git diff --staged >> /tmp/code-review-diff.txt`
4. **Specific files** → `cat <files> > /tmp/code-review-diff.txt`

Also get the file list for agent selection:
```bash
# From PR
gh pr diff <number> --name-only > /tmp/code-review-files.txt
# From branch
git diff main...HEAD --name-only > /tmp/code-review-files.txt
```

### Step 2: Scale Effort — Select Which Agents to Launch

Not every PR needs all 3 agents. Scan the file list and skip irrelevant agents (this saves cost and context — per Anthropic's "scale effort appropriately" principle).

```
ALWAYS launch: code-reviewer (covers everything)

Launch security-reviewer IF any file matches:
  api/*, route.ts, route.js, middleware/*, auth/*, webhook*,
  *.env*, security/*, or any new dependency addition

Launch uiux-reviewer IF any file matches:
  *.tsx, *.jsx, *.css, *.scss, *.html, components/*,
  pages/*, app/*, layouts/*, styles/*

Skip ALL agents IF only:
  *.md, *.txt, *.json (config only), *.yml, docs/*
  → Do a quick manual review instead
```

### Step 3: Launch Agents in Parallel

Launch selected agents in a **single message** with multiple Agent tool calls. Each agent writes to its own output file, keeping the lead's context clean.

Each agent prompt must include:
1. The diff file path
2. The output file path
3. Brief context about the PR (title, type, what it does)

```
Agent tool call 1:
  subagent_type: "candlekeep-cloud:code-reviewer"
  run_in_background: true
  prompt: |
    Review the code diff at /tmp/code-review-diff.txt
    PR context: [title and brief description]
    File list: [paste file names]
    Write your complete review to /tmp/code-review-quality.md

Agent tool call 2 (if security-relevant):
  subagent_type: "candlekeep-cloud:security-reviewer"
  run_in_background: true
  prompt: |
    Review the code diff at /tmp/code-review-diff.txt for security issues.
    PR context: [title and brief description]
    Write your complete review to /tmp/code-review-security.md

Agent tool call 3 (if UI-relevant):
  subagent_type: "candlekeep-cloud:uiux-reviewer"
  run_in_background: true
  prompt: |
    Review the code diff at /tmp/code-review-diff.txt for UI/UX issues.
    PR context: [title and brief description]
    Write your complete review to /tmp/code-review-uiux.md
```

### Step 4: Synthesize Results

After all agents complete, read their output files. Present a **unified review** — deduplicate findings that appear in multiple reviews, merge severity ratings (take the higher severity if agents disagree).

```markdown
# Code Review: [PR title]

## Summary
| Domain | Findings | Critical/High |
|--------|----------|---------------|
| Code Quality | X | Y |
| Security | X | Y |
| UI/UX | X | Y |

## Verdict: [Block / Request Changes / Approve]
[1-2 sentence justification]

## Must Fix (Critical + High)
[Merged findings with file:line, rule citations, and fix suggestions]

## Should Fix (Medium)
[Merged findings]

## Suggestions (Low)
[Merged findings]

## What's Done Well
[Positive findings — explicitly note secure patterns, good architecture, etc.]

## Audit Trail
[Combined rules-applied tables from all agents]
```

### Verdict Rules
- **Block** → Any CRITICAL finding
- **Request changes** → Any HIGH finding
- **Approve with comments** → Only MEDIUM/LOW findings
- **Clean approve** → No findings (rare, but celebrate it)

## Error Handling

- Agent fails → Present results from agents that succeeded, note which agent failed and why
- Book can't be read (auth) → Agent falls back to built-in knowledge, notes the limitation
- No diff available → Ask user what to review
- Empty diff → Report "no changes to review"

## Examples

**User:** "Review PR #42"
→ Fetch diff, scan files, launch 2-3 agents, synthesize, present unified review

**User:** "Code review" (on a feature branch)
→ Use `git diff main...HEAD`, launch agents, synthesize

**User:** "Review my changes"
→ Check for uncommitted changes, launch agents, synthesize
