# Ghostty Configuration Files - LLM Instructions (2026 Edition)

> 🔧 **CRITICAL**: This file contains NON-NEGOTIABLE requirements that ALL AI assistants (Claude, Gemini, ChatGPT, etc.) working on this repository MUST follow at ALL times.

## 🎯 Project Overview

**Ghostty Configuration Files** is a comprehensive terminal environment setup featuring Ghostty terminal emulator with 2025 performance optimizations, right-click context menu integration, plus integrated AI tools (Claude Code, Gemini CLI), intelligent update management with zero-cost local CI/CD infrastructure, and system cleanup utilities for Ubuntu bloatware removal.

**Quick Links:** [README](README.md) • [ROADMAP](ROADMAP.md) • [Full Backup](/.claude/instructions-for-agents/AGENTS.md-BACKUP-20251121.md)

---

## 📋 Complete Documentation Index

> **Token Optimization**: This file is now a lightweight gateway (~1.5KB). Detailed instructions are in `.claude/instructions-for-agents/`.

### 🚨 Critical Requirements (NON-NEGOTIABLE)
**Location**: `.claude/instructions-for-agents/requirements/`

- **[All Critical Requirements](/.claude/instructions-for-agents/requirements/CRITICAL-requirements.md)** - Ghostty optimization, package management, prerequisites, MCP integration, GitHub Pages
- **[Git Strategy & Branch Management](/.claude/instructions-for-agents/requirements/git-strategy.md)** - Branch preservation, naming, commit workflow
- **[Local CI/CD Operations](/.claude/instructions-for-agents/requirements/local-cicd-operations.md)** - Pipeline stages, workflow tools, logging system

### 🏗️ System Architecture
**Location**: `.claude/instructions-for-agents/architecture/`

- **[System Architecture](/.claude/instructions-for-agents/architecture/system-architecture.md)** - Directory structure, technology stack, core functionality
- **[Directory Structure](/.claude/instructions-for-agents/architecture/DIRECTORY_STRUCTURE.md)** - Complete file tree with descriptions

### 📚 Operational Guides
**Location**: `.claude/instructions-for-agents/guides/`

- **[First-Time Setup](/.claude/instructions-for-agents/guides/first-time-setup.md)** - Installation, post-install configuration, troubleshooting

### ⚖️ Constitutional Principles
**Location**: `.claude/instructions-for-agents/principles/`

- **[Script Proliferation Prevention](/.claude/instructions-for-agents/principles/script-proliferation.md)** - Mandatory principle for all script creation

### 🔧 Tool Implementation Reference
**Location**: `.claude/instructions-for-agents/tools/`

- **[Tool Documentation Index](/.claude/instructions-for-agents/tools/README.md)** - Complete reference for all 12 installable tools (fastfetch, ghostty, gum, glow, vhs, feh, go, nerdfonts, nodejs, python-uv, zsh, plus update scripts)

---

## ⚡ Top 5 CRITICAL Requirements (Quick Reference)

### 1. Script Proliferation Prevention (CONSTITUTIONAL PRINCIPLE)
**MANDATORY**: Enhance existing scripts, DO NOT create new wrapper/helper scripts.

**Before creating ANY `.sh` file:**
- [ ] Can this be added to existing script? (If YES → STOP, add there)
- [ ] Is this a test file? (Only exempt if in `tests/`)
- [ ] Does this violate proliferation principle? (If YES → STOP)

**Details**: [Script Proliferation Prevention](/.claude/instructions-for-agents/principles/script-proliferation.md)

### 2. Branch Preservation (MANDATORY)
- **NEVER DELETE BRANCHES** without explicit user permission
- Branch naming: `YYYYMMDD-HHMMSS-type-description`
- Always merge to main with `--no-ff`, preserve branch

**Details**: [Git Strategy](/.claude/instructions-for-agents/requirements/git-strategy.md)

### 3. Local CI/CD First (MANDATORY)
**EVERY** configuration change MUST run local CI/CD BEFORE GitHub:

```bash
./.runners-local/workflows/gh-workflow-local.sh all
ghostty +show-config
```

**Details**: [Local CI/CD Operations](/.claude/instructions-for-agents/requirements/local-cicd-operations.md)

### 4. Zero GitHub Actions Cost (MANDATORY)
- All testing runs locally FIRST
- GitHub Actions only for final deployment
- Monitor usage: `gh api user/settings/billing/actions`

**Details**: [Local CI/CD Operations](/.claude/instructions-for-agents/requirements/local-cicd-operations.md#cost-verification-mandatory)

### 5. Context7 MCP Setup (RECOMMENDED)
Query Context7 before major configuration changes.

**Details**: [Context7 MCP Setup](/.claude/instructions-for-agents/guides/context7-mcp.md) | [Critical Requirements](/.claude/instructions-for-agents/requirements/CRITICAL-requirements.md#-critical-context7-mcp-integration--documentation-synchronization)

---

## 🤖 LLM Quick Start Protocol

> **For AI Assistants**: Use this section to quickly classify your task and determine the correct workflow.

### Step 1: Classify Your Task

| Task Type | Complexity | Action | Orchestrator? |
|-----------|------------|--------|---------------|
| Bug fix (single file) | ATOMIC | Direct fix → validate → commit | No |
| Feature (multi-file) | MODERATE | TodoWrite → incremental execution | Maybe |
| Deployment | COMPLEX | Use `000-deploy` agent or orchestrate | Yes |
| Investigation | VARIABLE | Explore first → propose → await approval | No |
| Cleanup | MODERATE | Scan → present findings → await approval | Yes (approval) |

### Step 2: Pre-Execution Checklist

Before ANY operation, verify:
- [ ] No new scripts created (except in `tests/`)
- [ ] Enhancing existing code (not wrapping with helpers)
- [ ] Local CI/CD will run before GitHub push
- [ ] User approval obtained for destructive operations
- [ ] Branch naming follows `YYYYMMDD-HHMMSS-type-description`

### Step 3: Execution Mode Decision

```
STATE-MUTATING? (git commit, file delete, push)
  └─ YES → SEQUENTIAL execution only
  └─ NO  → Check dependencies...

HAS DEPENDENCY on another task?
  └─ YES → SEQUENTIAL after dependency completes
  └─ NO  → PARALLEL eligible
```

**Parallel-Safe**: Analysis, validation, health checks, documentation scans
**Sequential-Only**: Git operations, file deletions, deployments

### Step 4: Follow Domain Protocol

| Domain | Reference |
|--------|-----------|
| Agent selection | [Agent Delegation Guide](/.claude/instructions-for-agents/architecture/agent-delegation.md) |
| Git workflow | [Git Strategy](/.claude/instructions-for-agents/requirements/git-strategy.md) |
| CI/CD validation | [Local CI/CD Operations](/.claude/instructions-for-agents/requirements/local-cicd-operations.md) |
| Script rules | [Script Proliferation Prevention](/.claude/instructions-for-agents/principles/script-proliferation.md) |

### Error Handling Protocol

| Error Type | Response | Max Retries |
|------------|----------|-------------|
| Transient (network, timeout) | Retry immediately | 3 |
| Input error (invalid format) | Fix input, retry | 2 |
| Dependency failure | Fix upstream first | 1 cascade |
| Constitutional violation | **ESCALATE to user** | 0 (no retry) |

**Constitutional violations NEVER retry** - always escalate immediately.

---

### Dynamic Theme Switching (NEW - 2026)
**Status**: Active
**Script**: `scripts/ghostty-theme-switcher.sh`
**Service**: `~/.config/systemd/user/ghostty-theme-switcher.service` (user-specific, not git-tracked)

**Features**:
- Automatic detection of GNOME/GTK color-scheme changes
- Instant switching between Catppuccin Mocha (dark) and Latte (light)
- Uses SIGUSR2 signal for Ghostty config reload (correct signal per Ghostty docs)
- Systemd user service for background monitoring

**Commands**:
```bash
# Manual control
./scripts/ghostty-theme-switcher.sh apply    # Apply current system theme
./scripts/ghostty-theme-switcher.sh dark     # Force dark theme
./scripts/ghostty-theme-switcher.sh light    # Force light theme
./scripts/ghostty-theme-switcher.sh status   # Show current status
./scripts/ghostty-theme-switcher.sh monitor  # Start monitoring (default)

# Systemd service (optional, create manually)
systemctl --user enable ghostty-theme-switcher.service
systemctl --user start ghostty-theme-switcher.service
```

**Theme Files**:
- Dark: `configs/ghostty/catppuccin-mocha.conf`
- Light: `configs/ghostty/catppuccin-latte.conf`

---

## 🛠️ Development Commands (Quick Reference)

### Environment Setup
```bash
./start.sh                                  # One-command fresh install
./.runners-local/workflows/gh-workflow-local.sh init  # Initialize CI/CD
```

### Local CI/CD Operations
```bash
./.runners-local/workflows/gh-workflow-local.sh all      # Complete workflow
./.runners-local/workflows/gh-workflow-local.sh validate # Config validation
./.runners-local/workflows/gh-workflow-local.sh billing  # Check Actions usage
```

### Update Management
```bash
./scripts/check_updates.sh              # Smart updates
update-all                              # Manual daily updates
update-logs                             # View update logs
```

### TUI Installer (NEW - 2026)
```bash
cd tui && go run ./cmd/installer        # Launch TUI installer
./tui/ghostty-installer                 # Run compiled binary (if built)
```
**Features**: Interactive tool installation, Nerd Fonts management, update/uninstall support, nil-pointer safe

### Testing & Validation
```bash
ghostty +show-config                    # Validate configuration
./.runners-local/workflows/performance-monitor.sh --baseline  # Performance test
```

**Complete Guide**: [First-Time Setup](/.claude/instructions-for-agents/guides/first-time-setup.md)

---

## ⚠️ ABSOLUTE PROHIBITIONS (DO NOT)

- **NEVER REMOVE `docs/.nojekyll`** - Breaks ALL CSS/JS on GitHub Pages
- Delete branches without explicit user permission
- Use GitHub Actions that consume minutes
- Skip local CI/CD validation before GitHub deployment
- Create wrapper/helper scripts (violates script proliferation principle)
- Commit sensitive data (API keys, passwords)

**Complete List**: [Critical Requirements](/.claude/instructions-for-agents/requirements/CRITICAL-requirements.md)

---

## ✅ MANDATORY ACTIONS (Before Every Configuration Change)

1. **Local CI/CD**: Run `./.runners-local/workflows/gh-workflow-local.sh all`
2. **Validation**: Run `ghostty +show-config`
3. **Performance**: Execute `./.runners-local/workflows/performance-monitor.sh`
4. **Branch**: Create timestamped branch (`YYYYMMDD-HHMMSS-type-description`)
5. **Documentation**: Update relevant docs if adding features
6. **Commit**: Use proper format with co-authorship

**Complete Checklist**: [Git Strategy - Pre-Commit](/.claude/instructions-for-agents/requirements/git-strategy.md#pre-commit-checklist)

---

## 🎯 Success Criteria

### Performance Metrics (2025)
- **Startup**: <500ms (CGroup optimization)
- **Memory**: <100MB baseline
- **CI/CD**: <2 minutes complete workflow
- **Setup**: <10 minutes fresh Ubuntu install

### Quality Gates
- Local CI/CD workflows pass
- Configuration validates without errors
- GitHub Actions usage within free tier
- All logging captures complete information

**Complete Metrics**: [System Architecture](/.claude/instructions-for-agents/architecture/system-architecture.md#performance-metrics-2025)

---

## 📚 Additional Documentation

### Key Documents
- [README.md](README.md) - User documentation
- [ROADMAP.md](ROADMAP.md) - Development roadmap and task tracking
- [CLAUDE.md](CLAUDE.md) - Claude Code integration (symlink to this file)
- [GEMINI.md](GEMINI.md) - Gemini CLI integration (symlink to this file)

### Setup Guides
- [MCP New Machine Setup](/.claude/instructions-for-agents/guides/mcp-new-machine-setup.md) - Quick setup for all 7 MCP servers
- [Context7 MCP Setup](/.claude/instructions-for-agents/guides/context7-mcp.md) - Documentation server
- [GitHub MCP Setup](/.claude/instructions-for-agents/guides/github-mcp.md) - Repository operations
- [MarkItDown MCP Setup](/.claude/instructions-for-agents/guides/markitdown-mcp.md) - Document conversion
- [Playwright MCP Setup](/.claude/instructions-for-agents/guides/playwright-mcp.md) - Browser automation
- [Logging Guide](/.claude/instructions-for-agents/guides/LOGGING_GUIDE.md) - Dual-mode logging system
- [PowerLevel10k Integration](astro-website/src/developer/powerlevel10k/README.md) - ZSH prompt theme

### Agent & Command Reference

| Tier | Model | Count | Purpose |
|------|-------|-------|---------|
| 0 | Sonnet | 5 | Complete workflows (000-*) |
| 1 | Opus | 1 | Multi-agent orchestration |
| 2-3 | Sonnet | 9 | Core/utility operations |
| 4 | Haiku | 50 | Atomic execution |

- **[Agent Delegation Guide](/.claude/instructions-for-agents/architecture/agent-delegation.md)** - When to use which tier
- **[Agent Registry](/.claude/instructions-for-agents/architecture/agent-registry.md)** - Complete 65-agent reference
- **Workflow Agents**: `000-health`, `000-cleanup`, `000-commit`, `000-deploy`, `000-docs`

---

## 🔍 Finding Specific Information

### "How do I...?"
→ See [First-Time Setup Guide](/.claude/instructions-for-agents/guides/first-time-setup.md)

### "What are the critical requirements for...?"
→ See [Critical Requirements](/.claude/instructions-for-agents/requirements/CRITICAL-requirements.md)

### "How does the branch workflow work?"
→ See [Git Strategy](/.claude/instructions-for-agents/requirements/git-strategy.md)

### "How do I run local CI/CD?"
→ See [Local CI/CD Operations](/.claude/instructions-for-agents/requirements/local-cicd-operations.md)

### "What is the system architecture?"
→ See [System Architecture](/.claude/instructions-for-agents/architecture/system-architecture.md)

---

## 📊 Metadata

**Version**: 3.3-2026-TUI-Update
**Last Updated**: 2026-01-17
**Status**: ACTIVE - MANDATORY COMPLIANCE
**Target**: Ubuntu 25.10 (Questing) with Ghostty 1.2.3+ and zero-cost local CI/CD
**Token Count**: ~1,500 tokens (87% reduction from 12,000 tokens)
**Review**: Required before any major configuration changes

### Recent Improvements (v3.3)
- **TUI Installer**: Go-based Bubbletea TUI for interactive tool management
- **Nerd Fonts Management**: Interactive font installation/uninstallation with preview
- **Update Scripts**: Per-tool update scripts in `scripts/007-update/`
- **Nil-Pointer Safety**: Defensive programming patterns in all TUI components
- **Documentation Links**: Fixed broken cross-references to modular docs

---

**CRITICAL**: These requirements are NON-NEGOTIABLE. All AI assistants must follow these guidelines exactly. Failure to comply may result in configuration corruption, performance degradation, user data loss, or unexpected GitHub Actions charges.

**Full Details**: All detailed instructions, examples, diagrams, and comprehensive documentation are preserved in `.claude/instructions-for-agents/` directory structure.
