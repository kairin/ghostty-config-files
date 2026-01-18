# Quickstart: Claude Code Workflow Skills

**Feature**: 004-claude-skills
**Date**: 2026-01-18

## Overview

Four Claude Code slash commands that streamline development workflow:

| Skill | Purpose | Duration |
|-------|---------|----------|
| `/health-check` | System diagnostics | <30s |
| `/deploy-site` | Astro build + deploy | ~2min |
| `/git-sync` | Branch synchronization | <30s |
| `/full-workflow` | Complete development cycle | ~5min |

## Installation

### Option 1: Manual Copy (Recommended)

```bash
# From repository root
cp .claude/commands/*.md ~/.claude/commands/

# Remove deprecated skill
rm -f ~/.claude/commands/full-git-workflow.md
```

### Option 2: Install Script

```bash
./scripts/install-claude-skills.sh
```

## Usage

### Health Check

```
/health-check
```

**Output**: Structured report with PASS/FAIL/WARNING status for:
- Core tools (git, gh, node, npm, jq)
- MCP server connectivity
- Astro environment

**Handoff**: Suggests `/deploy-site` when environment is healthy

### Deploy Site

```
/deploy-site
```

**Output**: Build metrics and deployment status:
- File count, bundle size, build duration
- .nojekyll verification
- Deployment URL

**Handoff**: Suggests `/git-sync` after successful deploy

### Git Sync

```
/git-sync
```

**Output**: Synchronization status:
- Current branch and tracking info
- Sync status (up-to-date/behind/ahead/diverged)
- Branch name validation

**Constitutional Enforcement**:
- Never deletes branches
- Validates YYYYMMDD-HHMMSS-type-description format
- Stops on divergence (requires user decision)

### Full Workflow

```
/full-workflow
```

**Output**: Comprehensive report with stage timing:
1. Health check results
2. Deploy metrics
3. Sync status

**Constitutional Enforcement**:
- Local CI/CD must pass before GitHub operations
- Prompts for uncommitted changes

## Project Detection

Skills automatically detect the current project:

| Project | Feature Set |
|---------|------------|
| ghostty-config-files | Full features (all 4 skills) |
| Other projects | Basic features (git-sync, basic health-check) |

Detection markers:
- `.runners-local/` directory
- `AGENTS.md` file

## Workflow Chain

```
/health-check → /deploy-site → /git-sync
       └──────────────────────────────────┘
                 /full-workflow
```

Each skill suggests the next step via handoff buttons.

## Troubleshooting

### Skills Not Appearing

1. Verify files exist in `~/.claude/commands/`
2. Restart Claude Code (skills hot-reload in v2.1.0+)
3. Check YAML frontmatter syntax

### Health Check Failures

1. Run diagnostics manually: `./.runners-local/workflows/health-check.sh`
2. Install missing tools
3. Verify MCP server configuration

### Deploy Failures

1. Check Node.js version: `node --version` (should be latest via fnm)
2. Verify npm dependencies: `cd astro-website && npm install`
3. Check .nojekyll exists: `ls docs/.nojekyll`

### Git Sync Issues

1. Verify git credentials: `gh auth status`
2. Check branch tracking: `git branch -vv`
3. For diverged branches: resolve manually or choose resolution strategy
