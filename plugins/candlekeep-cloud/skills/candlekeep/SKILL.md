---
name: candlekeep
description: Access your CandleKeep Cloud document library. When users ask questions that might be answered by their documents, launch the item-reader subagent. For library management (list, add, remove), use CLI directly.
---

# CandleKeep Cloud - Document Library for AI Agents

Access and search your CandleKeep Cloud document library to answer questions with citations from your uploaded PDFs.

## CRITICAL: MANDATORY SUBAGENT USAGE

When answering questions that might be in the user's document library:

1. **ALWAYS** launch the `item-reader` subagent using the Task tool
2. **NEVER** run `ck items read` commands directly for research questions
3. The subagent handles the full research workflow with proper citations

## Decision Tree

```
User request
    │
    ├── Research question about document content
    │   └── Launch item-reader subagent (Task tool)
    │
    ├── "What documents do I have?" / "List my library"
    │   └── Run: ck items list
    │
    ├── "Add this PDF to my library"
    │   └── Run: ck items add <path>
    │
    ├── "Remove document X"
    │   └── Run: ck items remove <id> --yes
    │
    └── "Check my CandleKeep auth status"
        └── Run: ck auth whoami
```

## Prerequisites Check

Before first use, verify the CLI is installed and authenticated:

```bash
ck auth whoami
```

If not authenticated, guide the user to:
```bash
ck auth login
```

If CLI is not installed, guide the user to install it:
```bash
# Homebrew (macOS/Linux)
brew tap CandleKeepAgents/candlekeep
brew install candlekeep-cli

# Or via Cargo
cargo install candlekeep-cli
```

## Handling Authentication Errors

If you encounter `Authentication failed: Invalid or revoked API key` errors:

1. **Don't just tell the user to login** - proactively fix it
2. Run logout first, then login (the CLI won't re-auth if it thinks you're logged in):

```bash
ck auth logout && ck auth login
```

3. This will open the browser for the user to authenticate
4. Wait for the auth flow to complete (use a longer timeout ~120s)
5. Then retry the original command

**Common error patterns:**
- `Invalid or revoked API key` → Run `ck auth logout && ck auth login`
- `Not authenticated` → Run `ck auth login`
- `CLI not found` → Guide user to install via Homebrew or Cargo

## CLI Commands Reference (Library Management Only)

| Command | Purpose |
|---------|---------|
| `ck items list` | List all documents in the library |
| `ck items list --json` | List documents with full metadata |
| `ck items add <file>` | Upload a PDF to the library |
| `ck items remove <ids> --yes` | Delete documents (comma-separated IDs) |
| `ck auth whoami` | Check authentication status |
| `ck auth login` | Authenticate with CandleKeep Cloud |
| `ck auth logout` | Log out of CandleKeep Cloud |

## Launching the Research Agent

When a user asks a question that might be answered by their documents, launch the item-reader agent:

```
Task tool with subagent_type: "candlekeep-cloud:item-reader"
prompt: "Research the user's question: [question here]"
```

Example triggers for launching item-reader:
- "What does my library say about X?"
- "Research Y using my documents"
- "Find information about Z in my PDFs"
- "Can you look up A in my CandleKeep?"
- "Check my books for information on B"

## Example Workflow

**User asks:** "What do my books say about machine learning?"

**Correct response:**
1. Launch item-reader subagent with the research question
2. Let the subagent handle searching, reading, and citing
3. Present the subagent's findings to the user

**Incorrect response:**
- Running `ck items read` directly without using the subagent
- Trying to manually piece together research without proper workflow
