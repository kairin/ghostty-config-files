---
title: Critical Requirements (NON-NEGOTIABLE)
category: requirements
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2026-01-11
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

### Ghostty Terminal Installation (2026 Edition)

- **Ghostty Terminal v1.2.3+**: Two installation methods supported
  - **Build from Source** (Default): Compiles latest stable release with Zig
    - Script: `scripts/002-install-first-time/install_deps_ghostty.sh`
    - Installation time: ~2-5 minutes (includes dependency installation)
    - Requires: Zig compiler, Git, build dependencies (auto-installed)
    - Rationale: Latest features, full control over build options
  - **Snap Package** (Alternative): Official pre-built package
    - Installation: `snap install ghostty --classic`
    - Installation time: ~30-60 seconds
    - Rationale: Quick installation, automatic updates via Snap store

### Build-from-Source Applications

- **Feh Image Viewer**: Built from source (latest stable) with ALL features enabled
  - Repository: https://github.com/derf/feh
  - Build method: GNU Make with ALL feature flags enabled
    - `curl=1` - HTTPS image loading
    - `exif=1` - EXIF metadata display
    - `help=1` - Built-in help text
    - `inotify=1` - Auto-reload on file changes
    - `magic=1` - libmagic file type detection
    - `xinerama=1` - Multi-monitor support
    - `verscmp=1` - Version comparison support
    - `mkstemps=1` - Secure temp file handling
  - Installation: `/usr/local/` (installer: `scripts/002-install-first-time/install_deps_feh.sh`)
  - Build time: ~2-5 minutes
  - Rationale: Maximum versatility with all available features for professional image viewing
  - Configuration preservation: Custom themes (`~/.config/feh/themes`) and desktop file preserved

### Package Managers & Runtime Tools

- **ZSH**: Oh My ZSH with enhanced plugins for productivity
- **Node.js**: Latest version (currently v25.2.0) via fnm (Fast Node Manager) for AI tool integration
  - **Global Policy**: Always use the latest Node.js version (not LTS)
  - **Project-level**: Individual projects define their own version requirements via `.nvmrc` or `package.json` engines field
  - **Version Manager**: fnm (Fast Node Manager) - significantly faster than NVM (performance measured, actual varies ~19-73ms)
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

# 2. Verify MCP server is configured in .mcp.json
cat .mcp.json  # Should include context7 server configuration

# 3. Restart Claude Code to load MCP servers
exit && claude
```

**Available Tools:**
- `mcp__context7__resolve-library-id` - Find library IDs for documentation queries
- `mcp__context7__query-docs` - Retrieve up-to-date library documentation

**Constitutional Compliance:**
- **MANDATORY**: Query Context7 before major configuration changes
- **RECOMMENDED**: Add Context7 validation to local CI/CD workflows
- **BEST PRACTICE**: Document Context7 queries in conversation logs

**Complete Setup Guide:** [Context7 MCP Setup](../guides/context7-mcp.md)

---

## 🚨 CRITICAL: GitHub MCP Integration & Repository Operations

**Purpose**: Direct GitHub API integration for repository operations, issues, PRs, and search.

**Quick Setup:**
```bash
# 1. Verify GitHub CLI authentication
gh auth status

# 2. Verify MCP server is configured in .mcp.json
cat .mcp.json  # Should include github server configuration

# 3. Restart Claude Code to load MCP servers
exit && claude
```

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

**Complete Setup Guide:** [GitHub MCP Setup](../guides/github-mcp.md)

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
