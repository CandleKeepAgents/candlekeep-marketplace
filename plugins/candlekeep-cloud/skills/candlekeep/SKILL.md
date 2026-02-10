---
name: candlekeep
description: Research, read, write, or edit documents in your personal library. Use for research questions (launch item-reader), book writing/editing (launch book-writer), or library management. Trigger on research keywords (research, read, look up) OR writing keywords (write, create, edit, book, chapter).
---

# CandleKeep Cloud - Document Library for AI Agents

Access and search your CandleKeep Cloud document library to answer questions with citations from your uploaded PDFs and markdown files.

## PROACTIVE RESEARCH TRIGGERING

**IMPORTANT**: This skill should be automatically invoked when users mention ANY of these keywords or patterns:

### Research Trigger Keywords (launch item-reader)
- **Research words**: "research", "investigate", "study", "explore", "dig into"
- **Reading words**: "read", "read about", "what does it say", "tell me about"
- **Reference words**: "refer", "refer to", "reference", "consult", "check"
- **Lookup words**: "look up", "look into", "find", "search for", "search my"
- **Library words**: "my documents", "my library", "my books", "my PDFs", "my markdown", "my files"
- **Knowledge words**: "according to", "based on", "what do my", "does my library"

### Writing Trigger Keywords (launch book-writer)
- **Creation words**: "write", "create", "author", "draft", "compose", "start writing"
- **Book words**: "book", "chapter", "section", "document", "manuscript"
- **Editing words**: "edit", "update", "revise", "modify", "change", "rewrite"
- **Structure words**: "add chapter", "new section", "reorganize", "restructure"

### Source Trigger Keywords (launch item-reader for review, book-writer for curation)
- **Source words**: "sources", "saved tweets", "my tweets", "what have I saved", "saved sources"
- **Curation words**: "curate", "organize my sources", "turn sources into", "create from sources"

### Research Trigger Patterns (launch item-reader)
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

### Writing Trigger Patterns (launch book-writer)
- "Write a book about..."
- "Create a new document..."
- "Help me write..."
- "Add a chapter about..."
- "Edit my document..."
- "Update the chapter on..."
- "Start a new book..."
- "Draft a section about..."

### Auto-Trigger Scenarios

**Launch item-reader when:**
1. User asks a factual question that could be in their documents
2. User mentions needing to "research", "read", or "refer" to something
3. User asks "what do my documents say about..."
4. User wants to "look up" or "find" information
5. User asks a question and has CandleKeep documents available
6. User mentions their "library", "books", "PDFs", or "documents" in a research context

**Launch book-writer when:**
1. User wants to "write", "create", or "author" a document
2. User mentions "book", "chapter", "section" in a writing context
3. User wants to "edit", "update", or "revise" document content
4. User asks to "add", "draft", or "compose" new content

## CRITICAL: MANDATORY SUBAGENT USAGE

When answering questions that might be in the user's document library:

1. **ALWAYS** launch the `item-reader` subagent using the Task tool
2. **NEVER** run `ck items read` commands directly for research questions
3. The subagent handles the full research workflow with proper citations
4. **ALSO** launch the `book-enricher` subagent in parallel to opportunistically improve library metadata

### Parallel Agent Launch

For research requests, spawn BOTH agents simultaneously in a single message:

```
Task tool calls (in parallel):
1. subagent_type: "candlekeep-cloud:item-reader"
   prompt: "Research the user's question: [question here]"

2. subagent_type: "candlekeep-cloud:book-enricher"
   prompt: "Enrich any books in the library that need metadata improvements."
```

The `item-reader` agent handles the user's research request while `book-enricher` opportunistically improves 1-2 books' metadata in the background.

## Decision Tree

```
User request
    │
    ├── Contains RESEARCH keywords (research, read, refer, look up, find)
    │   └── Launch item-reader subagent (Task tool) - AUTOMATIC
    │
    ├── Contains WRITING keywords (write, create, edit, update, chapter, book)
    │   └── Launch book-writer subagent (Task tool) - AUTOMATIC
    │
    ├── Contains SOURCE keywords (sources, tweets, saved, curate)
    │   ├── Research/review context → Launch item-reader (which now checks sources too)
    │   └── "Create/curate/organize from sources" → Launch book-writer with source context
    │
    ├── Question that might be answered by documents
    │   └── Launch item-reader subagent (Task tool) - AUTOMATIC
    │
    ├── "What documents do I have?" / "List my library"
    │   └── Run: ck items list
    │
    ├── "Add this PDF/markdown file to my library"
    │   └── Run: ck items add <path>
    │
    ├── "Remove document X"
    │   └── Run: ck items remove <id> --yes
    │
    └── "Check my CandleKeep auth status"
        └── Run: ck auth whoami
```

## Launching Agents

### For Research Questions

When RESEARCH trigger keywords or patterns are detected, launch the research agents:

```
Task tool calls (in a single message with multiple tool uses):

1. subagent_type: "candlekeep-cloud:item-reader"
   prompt: "Research the user's question: [question here]"

2. subagent_type: "candlekeep-cloud:book-enricher"
   prompt: "Enrich any books in the library that need metadata improvements."
```

**DO NOT HESITATE** - if the user's request contains research-related keywords, launch both subagents.

### For Writing/Editing Tasks

When WRITING trigger keywords or patterns are detected, launch the book-writer agent:

```
Task tool call:

subagent_type: "candlekeep-cloud:book-writer"
prompt: "Help the user with their writing task: [task description]"
```

**Examples:**
- User: "Write a book about Python" → Launch book-writer
- User: "Edit chapter 2 of my cookbook" → Launch book-writer
- User: "Add a new chapter to my novel" → Launch book-writer
- User: "Create a document about testing" → Launch book-writer

## Enrichment Quality Guidelines

The `book-enricher` agent must follow these rules to ensure accurate metadata:

### TOC Accuracy is Critical

TOC page numbers must be **PDF page numbers**, not printed page numbers. Before submitting any TOC:

1. **Determine the page offset** between PDF pages and printed pages
2. **Verify at least 3 TOC entries** by reading those pages and confirming the chapter starts there
3. **Only submit if verified** - wrong page numbers make retrieval unreliable

### Why This Matters

When users ask "What does Chapter 5 say about X?", the system uses TOC page numbers to find the right content. If the TOC says Chapter 5 starts on page 50 but it's actually on page 55, retrieval will return the wrong content.

### Verification Command

```bash
ck items read "<id>" <page> <page>
```

Check that the chapter heading appears at the top of the returned content.

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

## CLI Commands Reference

### Library Management

| Command | Purpose |
|---------|---------|
| `ck items list` | List all documents in the library |
| `ck items list --json` | List documents with full metadata |
| `ck items add <file>` | Upload a PDF or Markdown file to the library |
| `ck items remove <ids> --yes` | Delete documents (comma-separated IDs) |

### Document Writing (for book-writer agent)

| Command | Purpose |
|---------|---------|
| `ck items create "Title"` | Create a new markdown document |
| `ck items get <id>` | Get full document content (outputs to stdout) |
| `ck items put <id> --file path.md` | Replace document content from file |
| `echo "content" \| ck items put <id>` | Replace document content from stdin |

### Source Management

| Command | Purpose |
|---------|---------|
| `ck sources list --json` | List all saved sources |
| `ck sources list` | List sources in table format |
| `ck sources delete <ids> --yes` | Delete sources by ID |

### Authentication

| Command | Purpose |
|---------|---------|
| `ck auth whoami` | Check authentication status |
| `ck auth login` | Authenticate with CandleKeep Cloud |
| `ck auth logout` | Log out of CandleKeep Cloud |

## Source Curation Workflow

When a user wants to turn saved sources into a curated document:

1. Launch `item-reader` to review sources and find themes
2. Launch `book-writer` to create a curated document from those sources

**Example:** "Turn my saved tweets about AI into a document"

1. `item-reader` runs `ck sources list --json`, clusters by topic, identifies themes
2. `book-writer` receives the themes and creates a synthesized markdown document with citations

## Example Workflow

**User asks:** "What do my books say about machine learning?"

**Correct response:**
1. Recognize "my books" and "say about" as trigger patterns
2. Immediately launch BOTH subagents in parallel:
   - `item-reader`: Research the user's question about machine learning
   - `book-enricher`: Enrich any books needing metadata
3. Present the item-reader's findings to the user
4. Optionally mention any books that were enriched

**User asks:** "Research neural networks for me"

**Correct response:**
1. Recognize "research" as a trigger keyword
2. Immediately launch both item-reader and book-enricher subagents in parallel
3. Present findings with citations

**User asks:** "Can you look up information about databases?"

**Correct response:**
1. Recognize "look up" as a trigger keyword
2. Launch both subagents automatically in parallel
3. Report findings from the user's document library

**Incorrect responses:**
- Running `ck items read` directly without using the subagent
- Asking if the user wants to search their library (just do it!)
- Trying to manually piece together research without proper workflow
- Not recognizing trigger keywords and missing an opportunity to help
- Only launching item-reader without book-enricher (miss enrichment opportunity)
