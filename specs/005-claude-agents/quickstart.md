# Quickstart: Claude Agents User-Level Consolidation

**Branch**: `005-claude-agents` | **Date**: 2026-01-18

## Overview

This guide covers testing the agents consolidation feature.

## Prerequisites

- Git repository cloned
- Ubuntu Linux with Bash shell
- Claude Code CLI installed

## Installation

### Fresh Install

```bash
# Clone repository (if not already done)
git clone https://github.com/kairin/ghostty-config-files.git
cd ghostty-config-files

# Run combined installer
./scripts/install-claude-config.sh
```

Expected output:
```
==================================
Claude Code Configuration Installer
==================================

Checking for deprecated skills...

Installing skills...
INSTALLED: 001-health-check.md
INSTALLED: 001-deploy-site.md
INSTALLED: 001-git-sync.md
INSTALLED: 001-full-workflow.md

Installing agents...
INSTALLED: 65 agents

==================================
Installation Complete
==================================

Skills installed: 4
Agents installed: 65

User directories:
  Skills:  ~/.claude/commands/
  Agents:  ~/.claude/agents/

To use skills, type the skill name in Claude Code (e.g., /001-health-check)
```

### Update Existing Installation

```bash
# Pull latest changes
git pull

# Re-run installer (idempotent)
./scripts/install-claude-config.sh
```

## Verification

### Check Installed Files

```bash
# Verify skills installed
ls ~/.claude/commands/
# Expected: 001-deploy-site.md  001-full-workflow.md  001-git-sync.md  001-health-check.md

# Verify agents installed
ls ~/.claude/agents/ | wc -l
# Expected: 65

# Verify agent tiers present
ls ~/.claude/agents/ | grep -E '^0[0-3][0-9]-' | head -5
# Expected: 000-*, 001-*, 002-*, 003-* files
```

### Check Project Directory is Clean

```bash
# Verify no agents at project level
ls .claude/agents/ 2>/dev/null || echo "Directory empty or removed (correct)"
# Expected: "Directory empty or removed (correct)"

# Verify agents in source directory
ls .claude/agent-sources/ | wc -l
# Expected: 65
```

### Test Agent Availability

1. Open Claude Code in any project:
   ```bash
   claude
   ```

2. Check available agents by typing a task that would invoke an agent

3. Verify no duplicate agents appear in the list

## Test Scenarios

### Scenario 1: Fresh System Setup (US1)

**Given**: Freshly cloned repository with no user-level agents
**When**: Run `./scripts/install-claude-config.sh`
**Then**:
- 65 agents copied to `~/.claude/agents/`
- Success message shows "Agents installed: 65"

**Verification**:
```bash
rm -rf ~/.claude/agents/
./scripts/install-claude-config.sh
ls ~/.claude/agents/ | wc -l  # Should be 65
```

### Scenario 2: Idempotent Updates (US2)

**Given**: Agents already installed
**When**: Run install script multiple times
**Then**: Script completes successfully each time

**Verification**:
```bash
./scripts/install-claude-config.sh
./scripts/install-claude-config.sh
./scripts/install-claude-config.sh
# All three should succeed with no errors
```

### Scenario 3: Combined Installation (US3)

**Given**: Clean `~/.claude/` directory
**When**: Run `./scripts/install-claude-config.sh`
**Then**: Both skills (4) and agents (65) installed

**Verification**:
```bash
rm -rf ~/.claude/commands/ ~/.claude/agents/
./scripts/install-claude-config.sh
ls ~/.claude/commands/ | wc -l  # Should be 4
ls ~/.claude/agents/ | wc -l     # Should be 65
```

### Scenario 4: Deprecated Cleanup (US4)

**Given**: Old non-prefixed skill files exist
**When**: Run install script
**Then**: Deprecated files removed

**Verification**:
```bash
# Create deprecated file
echo "test" > ~/.claude/commands/health-check.md
./scripts/install-claude-config.sh
ls ~/.claude/commands/health-check.md 2>/dev/null || echo "Deprecated file removed (correct)"
# Expected: "Deprecated file removed (correct)"
```

## Troubleshooting

### Install Script Not Found

```bash
# Ensure you're in repository root
cd /path/to/ghostty-config-files
ls scripts/install-claude-config.sh
```

### Permission Denied

```bash
# Make script executable
chmod +x scripts/install-claude-config.sh
```

### Agents Not Appearing in Claude Code

1. Check agents installed correctly:
   ```bash
   ls ~/.claude/agents/ | wc -l
   ```

2. Restart Claude Code CLI

3. Verify agent file format (should have YAML frontmatter with `name:` field)

## Rollback

To undo the agent installation:

```bash
# Remove installed agents
rm -rf ~/.claude/agents/

# Note: This only removes installed agents, source files remain in repo
```
