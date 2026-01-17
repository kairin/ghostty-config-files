# Research: Wave 1 - Scripts Documentation Foundation

**Feature**: 002-scripts-documentation
**Date**: 2026-01-18

## Overview

This feature is documentation-only work. Research phase focused on understanding existing content structure.

## Findings

### Scripts Directory Analysis

**Total Scripts**: 114 shell scripts

**Directory Structure**:
| Directory | Purpose | Script Count |
|-----------|---------|--------------|
| 000-check | Tool presence detection | 14 |
| 001-uninstall | Clean removal | 13 |
| 002-install-first-time | Fresh installation + deps | 15 |
| 003-verify | Dependency verification | 13 |
| 004-reinstall | Reinstallation | 13 |
| 005-confirm | Post-install confirmation | 13 |
| 006-logs | Logging utilities | 1 |
| 007-diagnostics | System health checks | 2 + subdirs |
| 007-update | Tool updates | 12 |
| mcp | MCP server scripts | varies |
| vhs | VHS recording scripts | varies |
| root | Utility scripts | 6 |

**Script Naming Convention**: `<action>_<tool>.sh`
- Examples: `check_ghostty.sh`, `update_nodejs.sh`, `uninstall_zsh.sh`

### MCP Documentation Analysis

**Current State**: 5 separate files with overlapping content

| File | Lines | Content |
|------|-------|---------|
| mcp-new-machine-setup.md | 324 | Comprehensive all-server guide |
| context7-mcp.md | 123 | Context7-specific details |
| github-mcp.md | 170 | GitHub MCP details |
| markitdown-mcp.md | 132 | MarkItDown details |
| playwright-mcp.md | 233 | Playwright details |

**Decision**: Use `mcp-new-machine-setup.md` as base, rename to `mcp-setup.md`
**Rationale**: Already comprehensive (324 lines), covers all 7 servers
**Alternative Considered**: Create new file from scratch - rejected (duplicates existing work)

### AI Tools Scripts Status

**Claimed Status** (in ai-cli-tools.md): "scripts not yet created"
**Actual Status**: Scripts exist

| Script | Path | Exists |
|--------|------|--------|
| install | scripts/004-reinstall/install_ai_tools.sh | ✅ Yes |
| uninstall | scripts/001-uninstall/uninstall_ai_tools.sh | ✅ Yes |
| confirm | scripts/005-confirm/confirm_ai_tools.sh | ✅ Yes |
| update | scripts/007-update/update_ai_tools.sh | ✅ Yes |

**Decision**: Update documentation to reflect reality
**Rationale**: Documentation accuracy is critical for trust

## Documentation Patterns Observed

From existing project documentation:

1. **Headers**: Use `#` hierarchy, no emojis in technical docs
2. **Tables**: GFM tables with alignment
3. **Code blocks**: Fenced with language identifier
4. **Links**: Relative paths preferred
5. **Metadata**: YAML frontmatter in guide files

## No Clarifications Needed

All requirements are clear from the spec and codebase exploration. Proceeding to implementation.
