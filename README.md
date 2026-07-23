# CandleKeep — Claude plugin marketplace

CandleKeep gives your AI agents a library they can actually read.

Point an agent at the PDFs, ebooks and markdown documents you've collected, and it
answers from those books with page-level citations instead of guessing from memory.
This repository is the **plugin marketplace** — it hosts two plugins, one for each
surface Claude runs on.

Home: <https://www.getcandlekeep.com> · Support: <support@getcandlekeep.com>

---

## Add this marketplace

**Claude Cowork / Claude Desktop** — open **Customize → Plugins → Add marketplace**
and enter:

```
CandleKeepAgents/candlekeep-marketplace
```

**Claude Code**:

```bash
/plugin marketplace add CandleKeepAgents/candlekeep-marketplace
```

Both plugins then appear in the plugin list. Install whichever matches where you work.

---

## Plugins in this marketplace

| Plugin | Surface | Reaches your library via |
|---|---|---|
| [`candlekeep-cowork`](./plugins/candlekeep-cowork) | Claude Cowork & Claude Desktop | Hosted MCP connector (OAuth) — no CLI, no shell |
| [`candlekeep-cloud`](./plugins/candlekeep-cloud) | Claude Code | The `ck` CLI |

Both deliver the same workflow through four specialist sub-agents:

| Sub-agent | Responsibility |
|---|---|
| **librarian** | Finds books. Searches your library and the marketplace, subscribes to relevant listings, and returns a reading list of book ids + page ranges. Never reads pages itself. |
| **item-reader** | Reads the pages the librarian selected and answers with page-level citations. |
| **book-writer** | Creates and edits markdown documents in your library. |
| **book-enricher** | Fills in missing book metadata opportunistically during research. |

### `candlekeep-cowork`

For Claude Cowork and Claude Desktop. Bundles the `candlekeep` skill, the four
sub-agents, and the hosted CandleKeep MCP connector, so research, marketplace
subscriptions and document writing all work with **no local CLI and no filesystem
access**. Installing it prompts you to sign in to CandleKeep once via OAuth.

You can also install it from a file — download
<https://getcandlekeep.com/cowork-plugin.zip> and use the upload option on the
**Plugins** page. That's a *plugin package*, so install it under **Plugins**, not
under **Skills**. File installs don't auto-update; the marketplace route does.

### `candlekeep-cloud`

For Claude Code. Same four sub-agents, driven by the `ck` CLI rather than MCP, plus
a session-start hook that tells Claude how many books are available and surfaces your
active manuscripts. Install the CLI first:

```bash
curl -fsSL https://getcandlekeep.com/install.sh | sh
```

---

## Requirements

A CandleKeep account — [create one free](https://www.getcandlekeep.com/sign-up) and
upload a few documents. The plugins read whatever is in your account. The free tier
covers 20 items and 500 reads per month.

## Permissions

The Cowork connector requests four scopes, revocable anytime from your
[settings page](https://www.getcandlekeep.com/settings):

- `library:read` — list, search and read your items and their tables of contents
- `library:write` — create and edit markdown items, enrich metadata
- `marketplace:read` — browse community-published listings
- `marketplace:write` — subscribe to listings (counts against your plan's item limit)

## Try it

Once installed, talk to Claude normally — the skill activates from natural language,
no slash command needed:

- *"What does my library say about Rust async?"* — searches, reads the relevant pages, cites them.
- *"Find me a book on Verilog and add it."* — browses the marketplace, subscribes to the best match, then reads it.
- *"Draft a knowledge doc on our incident-response runbook."* — creates a markdown document you can iterate on.

## Documentation

- Cowork / Desktop install guide: <https://www.getcandlekeep.com/help/cowork>
- All install paths: <https://www.getcandlekeep.com/install>
- Developers (API keys, MCP endpoint): <https://www.getcandlekeep.com/developers>

## Support

Email <support@getcandlekeep.com> or open a ticket at
<https://www.getcandlekeep.com/support>. Include what you asked Claude and what it
answered — that's usually enough to reproduce.

## License

MIT. See [LICENSE](./LICENSE).
