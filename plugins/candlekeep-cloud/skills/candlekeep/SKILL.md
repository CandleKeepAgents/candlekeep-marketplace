---
name: candlekeep
description: Search your CandleKeep document library for answers with citations, write and edit books, and manage your personal library. Trigger on research keywords (research, read, look up) OR writing keywords (write, create, edit, book, chapter).
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

## When NOT to Trigger This Skill

Do **not** invoke CandleKeep when:
- The user is asking for **web search or external research** — not involving their personal library (e.g., "research the latest news on X")
- The user **explicitly says** they don't want CandleKeep (e.g., "don't check my library")
- Keywords like "read" or "write" refer to **file I/O or code operations**, not documents (e.g., "read the config file", "write a function")
- The request is about **general knowledge** the user doesn't expect to be in their library
- The user is asking Claude to **search the web**, use a search engine, or fetch a URL

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

1. **NEVER** run `ck items read` commands directly for research questions
2. **ALWAYS** assess the library first, then dispatch the right number of `item-reader` agents
3. **ALSO** launch the `book-enricher` subagent in the background to opportunistically improve library metadata

### Orchestrator-Workers Research Pattern

The skill acts as an **orchestrator** that assesses scope before dispatching workers. This follows the principle: *scale effort appropriately — simple queries need 1 reader, complex research questions may need multiple readers working in parallel*.

#### Phase 1: Library Assessment (you do this directly)

Run `ck items list --json` yourself (listing is NOT reading — this does not violate the "never read directly" rule). Then analyze:

1. **How many books** are in the library total
2. **Which books are relevant** to the user's question (by title, author, subject)
3. **Are there distinct topic clusters?** — e.g., "research AI safety and quantum computing" touches two unrelated domains
4. **Does the question have sub-questions?** — e.g., "compare approaches to X across my books" vs "what does book Y say about Z"

#### Phase 2: Dynamic Dispatch (decide worker count)

Based on your assessment, dispatch with **clear mandates per worker**:

| Scenario | Readers | Strategy |
|----------|---------|----------|
| 0 relevant books | 0 | Inform user, suggest adding documents |
| 1-3 relevant books, single topic | 1 | All relevant books, full question |
| 4-8 relevant books OR 2 distinct topics | 2 | Each gets specific books + focused sub-question |
| 8+ relevant books OR 3+ distinct topics | 3 (max) | Each gets specific books + focused sub-question |

**Always** launch `book-enricher` in the background alongside the readers (unchanged).

## Decision Tree

```
User request
    │
    ├── Contains RESEARCH keywords (research, read, refer, look up, find)
    │   └── Phase 1: Assess library (ck items list --json)
    │       └── Phase 2: Dispatch 1-3 item-reader agents based on scope
    │
    ├── Contains WRITING keywords (write, create, edit, update, chapter, book)
    │   └── Launch book-writer subagent (Task tool) - AUTOMATIC
    │
    ├── Question that might be answered by documents
    │   └── Phase 1: Assess library (ck items list --json)
    │       └── Phase 2: Dispatch 1-3 item-reader agents based on scope
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

When RESEARCH trigger keywords or patterns are detected, follow the orchestrator workflow:

#### Step 1: Assess the Library

Run this yourself (do NOT delegate to a subagent):

```bash
ck items list --json
```

Analyze the results to determine:
- Total number of books
- Which books are relevant (by title, author, subject keywords)
- Whether the question spans multiple distinct topics
- Whether the question has natural sub-questions

#### Step 2: Decide Dispatch Strategy

Apply the decision criteria:

- **0 relevant books** → Tell the user their library doesn't cover this topic. Suggest adding relevant documents. Do NOT launch any readers.
- **1-3 relevant books, single topic** → Launch 1 reader with all relevant books
- **4-8 relevant books OR 2 distinct topics** → Launch 2 readers, each with a focused mandate
- **8+ relevant books OR 3+ distinct topics** → Launch 3 readers (max), each with a focused mandate

#### Step 3: Dispatch Workers

**Single reader** (simple case):

```
Task tool calls (in a single message):

1. subagent_type: "candlekeep-cloud:item-reader"
   prompt: "Research the user's question: [question here]
   RESEARCH_INTENT: [user's exact question]
   ASSIGNED_BOOKS: [id1, id2, id3]
   LIBRARY_CONTEXT: [total N books in library, M deemed relevant]"

2. subagent_type: "candlekeep-cloud:book-enricher"
   run_in_background: true
   prompt: "Enrich any books in the library that need metadata improvements.
   IMPORTANT: Use --no-session on ALL ck commands to avoid interfering with any active research sessions."
```

**Multiple readers** (complex case — each reader gets a focused mandate):

```
Task tool calls (in a single message):

1. subagent_type: "candlekeep-cloud:item-reader"
   prompt: "Research the user's question: [full question]
   RESEARCH_INTENT: [user's exact question]
   FOCUS: [specific sub-topic or angle for this reader]
   ASSIGNED_BOOKS: [ids relevant to this focus]
   LIBRARY_CONTEXT: You are reader 1 of N. Other readers are covering: [list other focuses]. Do not duplicate their work."

2. subagent_type: "candlekeep-cloud:item-reader"
   prompt: "Research the user's question: [full question]
   RESEARCH_INTENT: [user's exact question]
   FOCUS: [different sub-topic or angle]
   ASSIGNED_BOOKS: [different set of book ids]
   LIBRARY_CONTEXT: You are reader 2 of N. Other readers are covering: [list other focuses]. Do not duplicate their work."

3. subagent_type: "candlekeep-cloud:book-enricher"
   run_in_background: true
   prompt: "Enrich any books in the library that need metadata improvements.
   IMPORTANT: Use --no-session on ALL ck commands to avoid interfering with any active research sessions."
```

The `LIBRARY_CONTEXT` line tells each reader what the others are handling, preventing overlap. Without explicit delegation guidance, agents under-delegate or create overlapping assignments — always be explicit about scope boundaries.

**DO NOT HESITATE** — if the user's request contains research-related keywords, assess and dispatch immediately.

### For Writing/Editing Tasks

When WRITING trigger keywords or patterns are detected, launch the book-writer agent:

```
Task tool call:

subagent_type: "candlekeep-cloud:book-writer"
prompt: "Help the user with their writing task: [task description]
IMPORTANT: Use --no-session on ALL ck commands to avoid interfering with any active research sessions."
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

### Authentication

| Command | Purpose |
|---------|---------|
| `ck auth whoami` | Check authentication status |
| `ck auth login` | Authenticate with CandleKeep Cloud |
| `ck auth logout` | Log out of CandleKeep Cloud |

## Common Mistakes to Avoid

### Uploading without downloading first
**Bad:** `ck items put <id> --file /tmp/new-content.md` — overwrites the entire book.
**Better:** `ck items get <id> > /tmp/book-<id>.md` first, edit locally, then put.

### Reading pages that don't exist
**Bad:** `ck items read "<id>:50-60"` on a 16-page book.
**Better:** Check page count with `ck items toc <id>` first, then request valid ranges.

### Using stale item IDs
**Bad:** Reusing an item ID from a previous conversation.
**Better:** Always `ck items list` fresh to get current IDs.

### Skipping TOC verification for enrichment
**Bad:** Submitting TOC page numbers without verifying them — wrong page numbers make retrieval unreliable.
**Better:** Verify at least 3 TOC entries by reading those pages before submitting.

### Running CLI commands directly for research
**Bad:** Running `ck items read` in the main conversation instead of launching the item-reader subagent.
**Better:** Always launch the `item-reader` subagent via the Task tool — it handles the full research workflow with proper citations.

## Example Workflows

### Simple: Single-Topic Research

**User asks:** "What do my books say about machine learning?"

**Correct response:**
1. Recognize "my books" and "say about" as trigger patterns
2. **Phase 1**: Run `ck items list --json` — find 3 books, 2 relevant (a ML textbook and a data science guide)
3. **Phase 2**: 2 relevant books, single topic → dispatch 1 reader
4. Launch reader with `ASSIGNED_BOOKS: [id1, id2]` + book-enricher in background
5. Present the reader's findings to the user

### Complex: Multi-Topic Research

**User asks:** "Compare what my library says about neural networks vs genetic algorithms"

**Correct response:**
1. Recognize "my library" and "says about" as trigger patterns
2. **Phase 1**: Run `ck items list --json` — find 8 books, 5 relevant (3 on neural nets, 2 on evolutionary computing)
3. **Phase 2**: 5 relevant books, 2 distinct topics → dispatch 2 readers
4. Launch:
   - Reader 1: `FOCUS: neural networks`, `ASSIGNED_BOOKS: [id1, id2, id3]`
   - Reader 2: `FOCUS: genetic algorithms`, `ASSIGNED_BOOKS: [id4, id5]`
   - book-enricher in background
5. Synthesize both readers' findings into a comparison for the user

### Large Library: Broad Research

**User asks:** "Research everything my documents say about software architecture"

**Correct response:**
1. Recognize "research" as a trigger keyword
2. **Phase 1**: Run `ck items list --json` — find 15 books, 9 relevant across design patterns, microservices, and system design
3. **Phase 2**: 9 relevant books, 3 topic clusters → dispatch 3 readers
4. Launch:
   - Reader 1: `FOCUS: design patterns and principles`, `ASSIGNED_BOOKS: [id1, id2, id3]`
   - Reader 2: `FOCUS: microservices and distributed systems`, `ASSIGNED_BOOKS: [id4, id5, id6]`
   - Reader 3: `FOCUS: system design and scalability`, `ASSIGNED_BOOKS: [id7, id8, id9]`
   - book-enricher in background
5. Combine all three readers' findings into a comprehensive answer

### Edge Case: Empty or No Relevant Books

**User asks:** "What do my documents say about quantum computing?"

**Correct response:**
1. **Phase 1**: Run `ck items list --json` — find 5 books, 0 relevant to quantum computing
2. **Phase 2**: 0 relevant books → do NOT launch any readers
3. Inform user: "Your library doesn't currently contain documents about quantum computing. Consider adding relevant PDFs or markdown files with `ck items add <file>`."

**Incorrect responses:**
- Running `ck items read` directly without using the subagent
- Asking if the user wants to search their library (just do it!)
- Skipping Phase 1 assessment and blindly launching a single reader
- Launching the same number of readers regardless of library size or question complexity
- Not recognizing trigger keywords and missing an opportunity to help
- Only launching item-reader without book-enricher (miss enrichment opportunity)
