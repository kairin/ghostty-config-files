---
title: Critical Requirements (NON-NEGOTIABLE)
category: requirements
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2025-11-21
---

# 🚨 CRITICAL Requirements (NON-NEGOTIABLE)

[← Back to AGENTS.md](../../../../AGENTS.md)

**Related Sections**:
- [Git Strategy](./git-strategy.md) - Branch preservation, commit workflow
- [Local CI/CD Operations](./local-cicd-operations.md) - Workflow requirements
- [GitHub Integration](./github-integration.md) - MCP setup, GitHub Pages

---

## 🚨 CRITICAL: Ghostty Performance & Optimization (2025)

- **Linux CGroup Single-Instance**: MANDATORY for performance (`linux-cgroup = single-instance`)
- **Enhanced Shell Integration**: Auto-detection with advanced features
- **Memory Management**: Unlimited scrollback (999999999 lines) with CGroup protection
- **Auto Theme Switching**: Light/dark mode support with Catppuccin themes
- **Security Features**: Clipboard paste protection enabled

---

## 🚨 CRITICAL: Package Management & Dependencies

- **Ghostty**: Built from source with Zig 0.14.0 (latest stable)
- **ZSH**: Oh My ZSH with enhanced plugins for productivity
- **Node.js**: Latest version (currently v25.2.0) via fnm (Fast Node Manager) for AI tool integration
  - **Global Policy**: Always use the latest Node.js version (not LTS)
  - **Project-level**: Individual projects define their own version requirements via `.nvmrc` or `package.json` engines field
  - **Version Manager**: fnm (Fast Node Manager) - 40x faster than NVM with <50ms startup impact
  - **Health Audit Note**: Latest Node.js version is intentional and should NOT be flagged as a warning
- **Dependencies**: Smart detection and minimal installation footprint

---

## 🚨 CRITICAL: Installation Prerequisites

- **Passwordless Sudo**: MANDATORY for automated installation
  - Required for: apt package installation, system configuration
  - Security scope: Limited to `/usr/bin/apt` only (not unrestricted)
  - Configuration: `sudo visudo` → Add `username ALL=(ALL) NOPASSWD: /usr/bin/apt`
  - Alternative: Manual installation with interactive password prompts (not recommended)
  - Test: `sudo -n apt update` should run without password prompt
- **Impact**: Installation script will EXIT immediately if passwordless sudo not configured
- **Rationale**: Enables automated daily updates and zero-configuration installation experience

---

## 🚨 CRITICAL: Context7 MCP Integration & Documentation Synchronization

**Purpose**: Up-to-date documentation and best practices for all project technologies.

**Quick Setup:**
```bash
# 1. Configure environment
cp .env.example .env  # Add CONTEXT7_API_KEY=ctx7sk-your-api-key

# 2. Verify configuration
./scripts/check_context7_health.sh

# 3. Restart Claude Code to load MCP servers
exit && claude
```

**Health Check:** `./scripts/check_context7_health.sh`

**Available Tools:**
- `mcp__context7__resolve-library-id` - Find library IDs for documentation queries
- `mcp__context7__get-library-docs` - Retrieve up-to-date library documentation

**Constitutional Compliance:**
- **MANDATORY**: Query Context7 before major configuration changes
- **RECOMMENDED**: Add Context7 validation to local CI/CD workflows
- **BEST PRACTICE**: Document Context7 queries in conversation logs

**Complete Setup Guide:** [Context7 MCP Setup](../../../../documentation/setup/context7-mcp.md)

---

## 🚨 CRITICAL: GitHub MCP Integration & Repository Operations

**Purpose**: Direct GitHub API integration for repository operations, issues, PRs, and search.

**Quick Setup:**
```bash
# 1. Verify GitHub CLI authentication
gh auth status

# 2. Run health check
./scripts/check_github_mcp_health.sh

# 3. Restart Claude Code to load MCP servers
exit && claude
```

**Health Check:** `./scripts/check_github_mcp_health.sh`

**Core Capabilities:**
- **Repository Operations**: List, create, manage repositories
- **Issue Management**: Create, update, search issues
- **Pull Request Operations**: Create, review, merge PRs
- **Branch Management**: Create, list, delete branches
- **File Operations**: Read, create, update repository files
- **Search Operations**: Search repos, issues, PRs, code

**Constitutional Compliance:**
- **MANDATORY**: Use GitHub MCP for all repository operations (no manual gh CLI)
- **RECOMMENDED**: GitHub MCP operations follow branch preservation strategy
- **REQUIREMENT**: Respect branch naming conventions (YYYYMMDD-HHMMSS-type-description)

**Security:**
- ✅ Token stored in .env (not committed)
- ✅ Leverages existing gh CLI authentication
- ✅ Token auto-refreshes via gh CLI

**Complete Setup Guide:** [GitHub MCP Setup](../../../../documentation/setup/github-mcp.md)

---

## 🚨 CRITICAL: GitHub Pages Infrastructure (MANDATORY)

- **`.nojekyll` File**: ABSOLUTELY CRITICAL for GitHub Pages deployment
- **Location**: `docs/.nojekyll` (empty file, no content needed)
- **Purpose**: Disables Jekyll processing to allow `_astro/` directory assets
- **Impact**: Without this file, ALL CSS/JS assets return 404 errors
- **WARNING**: This file is ESSENTIAL - never remove during cleanup operations
- **Alternative**: No alternative - this file is required for Astro + GitHub Pages

### Jekyll Cleanup Protection (MANDATORY)

```bash
# BEFORE removing ANY Jekyll-related files, verify this file exists:
ls -la docs/.nojekyll

# If missing, recreate immediately:
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "CRITICAL: Restore .nojekyll for GitHub Pages asset loading"
```

---

[← Back to AGENTS.md](../../../../AGENTS.md)
