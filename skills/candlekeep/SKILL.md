---
name: candlekeep
description: Augment any substantive task with the user's CandleKeep document library. Activates on planning, architecture, code review, debugging, implementation, learning, research, writing, and technical discussions. Searches library in the background and weaves citations into responses. Also handles writing/editing books and marketplace browsing.
---

# CandleKeep Cloud — Document Library for AI Agents

Access and search your CandleKeep Cloud document library to answer questions with citations from your uploaded PDFs and markdown files.

## When to Use This Skill

Use this skill for any substantive technical task where domain knowledge could help:

<use_for>
- Planning, architecture, and design discussions
- Code review and quality assessment
- Debugging and troubleshooting
- Learning new technologies or frameworks
- Implementation strategy and decision-making
- Research and information lookup
- Writing and editing documents or books
- Marketplace browsing and discovery
</use_for>

<do_not_use_for>
- Trivial tasks: single-line fixes, typos, simple git commands
- Pure conversational chat with no technical substance
- When "read"/"write" refers to file I/O or code operations (e.g., "read this config file")
- When user explicitly says "don't check my library"
- Web search or external research unrelated to the personal library
</do_not_use_for>

## Decision Tree

```
User request
    │
    ├── Substantive technical task (plan, design, review, debug, implement, learn, decide)
    │   └── AMBIENT MODE: spawn item-reader in background, continue responding
    │       ├── Found relevant books → weave citations into response
    │       ├── Library thin → item-reader checks marketplace, auto-subscribes, cites
    │       └── Nothing found → stay silent about CandleKeep
    │
    ├── Explicit research request (research, look up, what do my books say about)
    │   └── Launch item-reader + book-enricher in parallel (foreground)
    │
    ├── Writing/editing request (write a book, edit chapter, create document)
    │   └── Launch book-writer
    │
    ├── Marketplace keywords (marketplace, browse books, subscribe)
    │   └── Run: ck marketplace browse --search "<query>" --json
    │
    └── Library management (list my library, add PDF, remove document)
        └── Run ck commands directly
```

## Ambient Activation — Background Library Enrichment

When the user starts any substantive technical task, search the library in the background without being asked.

**Spawn item-reader in background immediately:**

```
Task tool call:
subagent_type: "candlekeep-cloud:item-reader"
prompt: "Search the user's library for guidance relevant to: [topic]
RESEARCH_INTENT: Find best practices, patterns, and domain knowledge for: [topic]
Focus on actionable guidance. If library has nothing relevant, search marketplace
and auto-subscribe to relevant books."
run_in_background: true
```

**Then continue responding normally** — do not wait for item-reader.

**When item-reader returns:**
- Found relevant library content → weave citations naturally: "Your library's *Book Title* has guidance on this — [cite relevant content]"
- Auto-subscribed to marketplace books → announce it: "I found *Book Title* on the CandleKeep marketplace and added it to your library. It suggests..."
- Nothing found anywhere → say nothing about CandleKeep

Also spawn book-enricher in background for opportunistic metadata improvement:
```
subagent_type: "candlekeep-cloud:book-enricher"
prompt: "Enrich any books needing metadata improvements.
IMPORTANT: Use --no-session on ALL ck commands."
run_in_background: true
```

## Explicit Research Requests

When user explicitly asks to research something from their library, launch both agents in parallel (foreground):

```
Task tool calls (in parallel):
1. subagent_type: "candlekeep-cloud:item-reader"
   prompt: "Research the user's question: [question]
   RESEARCH_INTENT: [exact user question]"

2. subagent_type: "candlekeep-cloud:book-enricher"
   prompt: "Enrich any books needing metadata improvements.
   IMPORTANT: Use --no-session on ALL ck commands."
```

**Research trigger patterns:**
- "What do my books say about...", "research X", "look up Y", "refer to my library"
- "according to my documents", "what does [book] say", "check my files for"

## Writing and Editing

When user wants to write or edit documents:

```
Task tool call:
subagent_type: "candlekeep-cloud:book-writer"
prompt: "Help the user with their writing task: [task description]
IMPORTANT: Use --no-session on ALL ck commands."
```

**Writing trigger patterns:**
- "write a book about", "create a new document", "edit chapter X"
- "add a section to", "draft a manuscript", "update my book on"

## Marketplace Discovery

When user mentions marketplace or wants to find books:

```bash
ck marketplace browse --search "<keywords>" --json --limit 10
```

Present results as:
```
Found X books on the marketplace:

1. **"Book Title"** by Author (42 pages, 128 subscribers)
   `ck marketplace subscribe <listing-id>`
```

## Library Management

Direct CLI commands (no subagent needed):

| Command | Purpose |
|---------|---------|
| `ck items list` | List all documents |
| `ck items list --json` | List with full metadata |
| `ck items add <file>` | Upload a PDF or Markdown file |
| `ck items remove <ids> --yes` | Delete documents |
| `ck auth whoami` | Check authentication status |
| `ck marketplace browse` | Browse marketplace listings |
| `ck marketplace subscribe <id>` | Add a marketplace book |

## Enrichment Quality Guidelines

TOC page numbers must be **PDF page numbers**, not printed page numbers. Before submitting any TOC, verify at least 3 entries by reading those pages.

## Common Mistakes to Avoid

- Running `ck items read` directly instead of launching item-reader subagent
- Asking if user wants to check their library — just do it
- Waiting for background item-reader before responding to the user
- Mentioning CandleKeep when nothing relevant was found
