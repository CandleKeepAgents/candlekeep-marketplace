# Changelog

All notable changes to the CandleKeep Cloud plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
