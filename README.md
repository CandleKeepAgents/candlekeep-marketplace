# CandleKeep Cloud - Claude Code Plugin

Give AI agents access to your CandleKeep Cloud document library. Research questions, get cited answers, and manage your library directly from Claude Code.

## What This Plugin Does

- **Research with citations**: Ask questions and get answers sourced from your uploaded PDFs
- **Intelligent document search**: The AI identifies relevant documents and sections automatically
- **Library management**: List, add, and remove documents from your CandleKeep Cloud library
- **Cross-reference**: Synthesize information from multiple documents in a single query

## Installation

### Prerequisites

#### 1. Install the CandleKeep CLI

Choose one installation method:

**Homebrew (macOS/Linux) - Recommended:**
```bash
brew tap CandleKeepAgents/candlekeep
brew install candlekeep-cli
```

**Cargo:**
```bash
cargo install candlekeep-cli
```

**cargo-binstall (faster binary installation):**
```bash
cargo binstall candlekeep-cli
```

#### 2. Authenticate with CandleKeep Cloud

```bash
ck auth login
```

This opens your browser to sign in to CandleKeep Cloud and authorize the CLI.

Verify authentication:
```bash
ck auth whoami
```

### Plugin Installation

#### 1. Add the CandleKeep Marketplace

In Claude Code, run:
```
/plugin marketplace add CandleKeepAgents/candlekeep-marketplace
```

#### 2. Install the Plugin

```
/plugin install candlekeep-cloud@candlekeep
```

## Usage

### Research Questions

Ask Claude Code questions about your documents:

- "What does my library say about machine learning?"
- "Research neural networks using my CandleKeep documents"
- "Find information about data structures in my PDFs"
- "Can you look up algorithms in my books?"

The AI will:
1. Search your library for relevant documents
2. Identify the most relevant sections using table of contents
3. Read specific pages with the information you need
4. Provide a cited answer with references to specific pages

### Library Management

Manage your CandleKeep Cloud library:

- "What documents do I have in CandleKeep?"
- "List my library"
- "Add this PDF to my library" (provide file path)
- "Remove document X from my library"

### Example Session

```
You: What do my books say about recursion?

Claude: I'll search your CandleKeep library for information about recursion.

[Launches item-reader agent]

Based on your documents, here's what I found about recursion:

**Sources Consulted:**
- *Introduction to Algorithms* by Cormen et al. - Chapter 4 covers divide-and-conquer
- *Structure and Interpretation of Computer Programs* - Extensive coverage of recursive procedures

**Core Findings:**
Recursion is defined as "a method where the solution depends on solutions to smaller instances of the same problem" (*Introduction to Algorithms*, p. 65).

SICP emphasizes that recursive processes can be either linear or tree-shaped, noting that "the time required grows linearly with the input" for linear recursion (*SICP*, p. 35).

**Additional Insights:**
- Tail recursion optimization is covered in SICP pp. 36-38
- Master theorem for recursive running time analysis in Algorithms pp. 73-96
```

## CLI Commands Reference

| Command | Description |
|---------|-------------|
| `ck auth login` | Authenticate with CandleKeep Cloud |
| `ck auth logout` | Log out |
| `ck auth whoami` | Check authentication status |
| `ck items list` | List all documents |
| `ck items list --json` | List with full metadata |
| `ck items add <file>` | Upload a PDF |
| `ck items remove <ids> --yes` | Delete documents |
| `ck items toc <ids>` | View table of contents |
| `ck items read "id:pages"` | Read specific pages |

## Troubleshooting

### "Command not found: ck"
The CLI isn't installed. Follow the installation steps above.

### "Not authenticated"
Run `ck auth login` to authenticate with CandleKeep Cloud.

### "No items found"
Your library is empty. Add documents with `ck items add <file.pdf>` or upload at [getcandlekeep.com](https://www.getcandlekeep.com).

### Plugin not found
1. Verify marketplace is added: `/plugin marketplace list`
2. Re-add if needed: `/plugin marketplace add CandleKeepAgents/candlekeep-marketplace`
3. Install plugin: `/plugin install candlekeep-cloud@candlekeep`

## Links

- [CandleKeep Cloud](https://www.getcandlekeep.com) - Web app and document upload
- [CLI on crates.io](https://crates.io/crates/candlekeep-cli) - Rust package
- [CLI Repository](https://github.com/CandleKeepAgents/candlekeep-cloud/tree/main/apps/cli) - Source code
- [CandleKeep GitHub](https://github.com/CandleKeepAgents) - Organization

## License

MIT License - see [LICENSE](LICENSE) for details.
