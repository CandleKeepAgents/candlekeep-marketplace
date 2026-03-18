# Changelog

All notable changes to the CandleKeep Cloud plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.0] - 2026-03-18

### Added
- Marketplace gap-check workflow in item-reader agent (Step 4.5) — suggests marketplace books when library coverage is thin
- Marketplace trigger keywords and discovery flow in SKILL.md
- Marketplace CLI commands table (browse, subscribe, unsubscribe)
- Plan mode: parallel library exploration for planning-related requests
- Marketplace decision tree branches in SKILL.md
- Pro-restricted content handling in item-reader agent (Step 4b: cite + tease pattern)
- Pro books awareness in orchestrator skill

### Changed
- Plugin description updated to mention contextual prompts
- item-reader output format now includes Section 4 (Marketplace Recommendations) and Section 5 (Recommendations)
- item-reader gracefully handles `proRestricted` API responses with preview-only content

## [1.7.0] - 2026-03-08

### Changed
- Research flow now uses orchestrator-workers pattern: skill assesses library scope before dispatching readers
- Multiple item-reader agents launched in parallel for multi-topic or large-scope research
- Each reader receives a focused mandate with assigned books and specific sub-questions
- item-reader now accepts ASSIGNED_BOOKS, FOCUS, and LIBRARY_CONTEXT parameters

## [1.6.0] - 2026-02-14

### Added
- Research session tracking in item-reader agent (Step 0: start session, Step 6: complete session)
- RESEARCH_INTENT passed from skill to item-reader for intent tracking
- `--no-session` flag on all book-enricher commands to avoid session interference

### Changed
- book-enricher and book-writer agents now explicitly opt out of session tracking

## [1.5.1] - 2026-02-12

### Added
- **README.md** for the candlekeep skill — human-readable guide with quick start, prerequisites, and agent descriptions
- **"When NOT to Trigger" section** in SKILL.md — prevents false triggers on web search, file I/O keywords, and general knowledge questions
- **"Common Mistakes to Avoid" section** in SKILL.md — 5 Bad/Better anti-patterns covering upload-without-download, stale IDs, page range errors, TOC verification, and direct CLI usage
- **Cross-references between agents** — each agent now lists related agents with handoff guidance

### Changed
- **Skill description sharpened** — value proposition replaces verb list

## [1.5.0] - 2026-02-04

### Added
- **Book Writer Agent** - New `book-writer` subagent for creating and editing markdown documents
  - Create new markdown documents with `ck items create`
  - Retrieve content with `ck items get`
  - Update content with `ck items put`
  - Full support for markdown editing workflow
- **Writing Trigger Keywords** - Skill now triggers for writing-related requests
  - "write", "draft", "create document", "start writing", "compose"
  - "take notes", "write notes", "document this", "capture"

### Changed
- Candlekeep skill description updated to mention writing capabilities
- Decision tree updated with book-writer launch path

## [1.4.1] - 2026-02-03

### Added
- **TOC Verification Requirement** - Book enricher must verify TOC page numbers before submitting
  - Determine PDF page offset vs printed page numbers
  - Verify at least 3 TOC entries by reading actual pages
  - Only submit TOC if verified entries match content
- **Enrichment Quality Guidelines** in candlekeep skill explaining why TOC accuracy matters

### Changed
- Book enricher TOC Guidelines expanded with mandatory verification steps
- Candlekeep skill updated with enrichment quality section

## [1.4.0] - 2026-02-03

### Added
- **TOC Extraction** - Book enricher agent now extracts and saves table of contents
  - Checks existing TOC via `ck items toc`
  - Scans content for chapter structure if TOC is missing
  - Submits TOC with `--toc` flag in JSON format
  - Guidelines for level structure (Part > Chapter > Section)
  - Instructions for using PDF page numbers vs printed page numbers

### Changed
- Book enricher description updated to mention TOC support
- Enrichment workflow now includes TOC extraction as step 3

## [1.3.0] - 2026-02-03

### Added
- **Book Enricher Agent** - New `book-enricher` subagent that automatically enriches books with missing metadata
  - Reads first 5-10 pages to extract title, author, and description
  - Submits enrichments with confidence scores (0.0-1.0)
  - Processes items from the enrichment queue prioritized by page count
- **Metadata Flagging** - item-reader now flags books with poor metadata during research
  - Detects filename-like titles (e.g., "document.pdf", "scan_001.pdf")
  - Uses `ck items flag <id>` to queue items for enrichment

### Changed
- item-reader updated with metadata flagging guidance

## [1.2.0] - 2025-01-30

### Changed
- Version bump to sync with marketplace metadata

## [1.1.0] - 2025-01-30

### Added
- **Proactive Research Triggering** - The skill now automatically triggers when detecting research-related keywords
- **Trigger Keywords** - Organized into categories:
  - Research words: "research", "investigate", "study", "explore", "dig into"
  - Reading words: "read", "read about", "what does it say", "tell me about"
  - Reference words: "refer", "refer to", "reference", "consult", "check"
  - Lookup words: "look up", "look into", "find", "search for", "search my"
  - Library words: "my documents", "my library", "my books", "my PDFs", "my files"
  - Knowledge words: "according to", "based on", "what do my", "does my library"
- **12 Trigger Patterns** - Common phrase patterns that auto-invoke the skill
- **6 Auto-Trigger Scenarios** - Defined scenarios for automatic subagent launch
- **Enhanced Decision Tree** - Updated with automatic paths for trigger keywords

### Changed
- **Skill Description** - Now keyword-rich to improve automatic skill matching
- **Example Workflows** - Added more examples including incorrect response patterns
- **"DO NOT HESITATE" Guidance** - Explicit instruction to launch subagent proactively

## [1.0.0] - 2025-01-29

### Added
- Initial release
- CandleKeep Cloud document library integration
- `item-reader` subagent for research questions with citations
- CLI commands for library management (list, add, remove)
- Authentication handling with automatic re-auth flow
- Prerequisites check and installation guidance
