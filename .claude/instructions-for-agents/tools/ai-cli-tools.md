# AI CLI Tools Implementation Summary

> **Status**: PLANNED - Installation scripts not yet implemented

This document covers AI CLI tools that are mentioned in the project documentation and daily update scripts but do not yet have full installation scripts.

## Planned Tools

| Tool | Package Name | Status |
|------|--------------|--------|
| Claude Code | `@anthropic-ai/claude-code` | Daily updates only |
| Gemini CLI | `@google/generative-ai-cli` | Daily updates only |
| Copilot CLI | `@githubnext/github-copilot-cli` | Daily updates only |

## Current Implementation

### Daily Updates (`scripts/updates/daily-updates.sh`)

These tools are updated via npm global update:
```bash
npm update -g @anthropic-ai/claude-code
npm update -g @google/generative-ai-cli
npm update -g @githubnext/github-copilot-cli
```

### TUI Dashboard

The "Local AI Tools" option appears in `start.sh` but shows "Missing" status, indicating planned but not yet implemented functionality.

## Missing Scripts

The 6-step installation framework scripts are not yet created:

| Stage | Script | Status |
|-------|--------|--------|
| 000 | `check_ai_tools.sh` | Not created |
| 001 | `uninstall_ai_tools.sh` | Not created |
| 002 | `install_deps_ai_tools.sh` | Not created |
| 003 | `verify_deps_ai_tools.sh` | Not created |
| 004 | `install_ai_tools.sh` | Not created |
| 005 | `confirm_ai_tools.sh` | Not created |

### Test File Exists

A test file exists at `.runners-local/tests/unit/test_install_ai_tools.sh` that expects `scripts/install_ai_tools.sh`, but this script does not exist yet.

## Prerequisites

All AI CLI tools require:
- Node.js (npm)
- API keys for respective services

## Manual Installation (Current)

### Claude Code
```bash
npm install -g @anthropic-ai/claude-code
```
Requires: `ANTHROPIC_API_KEY`

### Gemini CLI
```bash
npm install -g @google/generative-ai-cli
```
Requires: Google Cloud authentication

### GitHub Copilot CLI
```bash
npm install -g @githubnext/github-copilot-cli
```
Requires: GitHub Copilot subscription

## Future Implementation

When implemented, these tools should follow the same 6-step framework pattern as other tools, with:
- Version detection for each tool
- npm-based installation
- API key validation (without exposing keys)
- Integration with TUI dashboard

---

**Last Updated**: 2025-12-13
**Status**: Documentation only - awaiting implementation
