# CandleKeep Cloud Skill

Search your personal document library, write and edit books, and manage your collection — all from Claude Code.

## What is CandleKeep?

CandleKeep Cloud is a personal document library where you upload PDFs and markdown files. This skill gives Claude Code direct access to your library so you can research your documents, get cited answers, write new books, and organize your collection without leaving your terminal.

## Quick Start

After installing the plugin, just ask Claude naturally:

- **Research:** "What do my documents say about transformer architectures?"
- **Write:** "Write a book summarizing my notes on distributed systems"
- **List:** "What documents do I have in my library?"

The skill automatically detects your intent and launches the right agent.

## Prerequisites

1. **CandleKeep CLI (`ck`)** installed:
   ```bash
   brew tap CandleKeepAgents/candlekeep && brew install candlekeep-cli
   ```
2. **Authenticated** with your CandleKeep account:
   ```bash
   ck auth login
   ```

## Agents

| Agent | What it does |
|-------|-------------|
| **item-reader** | Searches your library, reads relevant pages, and answers questions with citations |
| **book-enricher** | Improves metadata (title, author, TOC) on books that are missing it |
| **book-writer** | Creates, edits, and manages markdown documents in your library |

## How It Works

1. You ask a question or request a writing task
2. The skill matches your intent to the right agent (research, write, or enrich)
3. The agent uses the `ck` CLI to interact with your CandleKeep Cloud library
4. You get answers with page citations, or your document is created/updated

## Links

- [CandleKeep Cloud](https://www.getcandlekeep.com)
- [GitHub](https://github.com/CandleKeepAgentOrg/candlekeep)
