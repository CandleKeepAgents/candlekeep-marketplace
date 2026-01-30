---
name: candlekeep
description: Research, read, refer to, or look up information from your personal document library. Use when the user asks to research a topic, read about something, refer to their documents, look up information, find details, check their books/PDFs, consult their library, or any question that might be answered by their uploaded documents. Launch item-reader subagent for all research questions.
---

# CandleKeep Cloud - Document Library for AI Agents

Access and search your CandleKeep Cloud document library to answer questions with citations from your uploaded PDFs.

## PROACTIVE RESEARCH TRIGGERING

**IMPORTANT**: This skill should be automatically invoked when users mention ANY of these keywords or patterns:

### Trigger Keywords (auto-invoke this skill)
- **Research words**: "research", "investigate", "study", "explore", "dig into"
- **Reading words**: "read", "read about", "what does it say", "tell me about"
- **Reference words**: "refer", "refer to", "reference", "consult", "check"
- **Lookup words**: "look up", "look into", "find", "search for", "search my"
- **Library words**: "my documents", "my library", "my books", "my PDFs", "my files"
- **Knowledge words**: "according to", "based on", "what do my", "does my library"

### Trigger Patterns (auto-invoke this skill)
- "What does X say about..."
- "Can you research..."
- "Look up Y in my documents"
- "Refer to my library for..."
- "Read about Z from my books"
- "Find information about..."
- "Check my documents for..."
- "According to my library..."
- "What do my books/PDFs/documents say about..."
- "Research X using my documents"
- "Is there anything in my library about..."
- "Consult my files about..."

### Auto-Trigger Scenarios
Launch the item-reader subagent automatically when:
1. User asks a factual question that could be in their documents
2. User mentions needing to "research", "read", or "refer" to something
3. User asks "what do my documents say about..."
4. User wants to "look up" or "find" information
5. User asks a question and has CandleKeep documents available
6. User mentions their "library", "books", "PDFs", or "documents"

## CRITICAL: MANDATORY SUBAGENT USAGE

When answering questions that might be in the user's document library:

1. **ALWAYS** launch the `item-reader` subagent using the Task tool
2. **NEVER** run `ck items read` commands directly for research questions
3. The subagent handles the full research workflow with proper citations

## Decision Tree

```
User request
    │
    ├── Contains research keywords (research, read, refer, look up, find, etc.)
    │   └── Launch item-reader subagent (Task tool) - AUTOMATIC
    │
    ├── Question that might be answered by documents
    │   └── Launch item-reader subagent (Task tool) - AUTOMATIC
    │
    ├── Mentions "my library", "my documents", "my books", "my PDFs"
    │   └── Launch item-reader subagent (Task tool) - AUTOMATIC
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

## Launching the Research Agent

When ANY trigger keyword or pattern is detected, immediately launch the item-reader agent:

```
Task tool with subagent_type: "candlekeep-cloud:item-reader"
prompt: "Research the user's question: [question here]"
```

**DO NOT HESITATE** - if the user's request contains research-related keywords, launch the subagent. It's better to check the library and find nothing than to miss answering a question the user's documents could answer.

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

## Example Workflow

**User asks:** "What do my books say about machine learning?"

**Correct response:**
1. Recognize "my books" and "say about" as trigger patterns
2. Immediately launch item-reader subagent with the research question
3. Let the subagent handle searching, reading, and citing
4. Present the subagent's findings to the user

**User asks:** "Research neural networks for me"

**Correct response:**
1. Recognize "research" as a trigger keyword
2. Immediately launch item-reader subagent
3. Present findings with citations

**User asks:** "Can you look up information about databases?"

**Correct response:**
1. Recognize "look up" as a trigger keyword
2. Launch item-reader subagent automatically
3. Report findings from the user's document library

**Incorrect responses:**
- Running `ck items read` directly without using the subagent
- Asking if the user wants to search their library (just do it!)
- Trying to manually piece together research without proper workflow
- Not recognizing trigger keywords and missing an opportunity to help
