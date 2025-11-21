---
title: First-Time Setup & Installation Guide
category: guides
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2025-11-21
---

# 🛠️ First-Time Setup & Installation Guide

[← Back to AGENTS.md](../../../../AGENTS.md)

**Related Sections**:
- [Local CI/CD Guide](./local-cicd-guide.md) - Workflow operations
- [Update Management](./update-management.md) - Keeping system current
- [Critical Requirements](../requirements/CRITICAL-requirements.md) - Prerequisites

---

## Prerequisites

### System Requirements
- **OS**: Ubuntu 25.10 (Questing) or compatible
- **Sudo Access**: Passwordless sudo for `/usr/bin/apt` (MANDATORY)
- **Disk Space**: ~2GB for Ghostty, tools, and dependencies
- **Internet**: Required for package downloads

### Passwordless Sudo Setup (MANDATORY)

```bash
# Configure passwordless sudo for apt only
sudo EDITOR=nano visudo

# Add this line (replace 'username' with your username):
username ALL=(ALL) NOPASSWD: /usr/bin/apt

# Test configuration
sudo -n apt update  # Should run without password prompt
```

**Why Required:**
- Enables automated daily updates
- Allows zero-configuration installation
- Restricted to `/usr/bin/apt` only (secure scope)

---

## Installation Steps

### 1. Clone Repository

```bash
# Clone to Apps directory
cd ~/Apps
git clone https://github.com/yourusername/ghostty-config-files.git
cd ghostty-config-files
```

### 2. Run Installation

```bash
# One-command setup
./start.sh

# Or with verbose logging
./start.sh --verbose
```

**What Gets Installed:**
- Ghostty (built from source with Zig 0.14.0)
- ZSH with Oh My ZSH framework
- Node.js (latest) via fnm
- AI tools (Claude Code, Gemini CLI)
- Context menu integration
- Daily update automation

### 3. Verify Installation

```bash
# Check Ghostty configuration
ghostty +show-config

# Test context menu (right-click in file manager)
# Should see "Open in Ghostty" option

# Check AI tools
claude --version
gemini --version

# Verify daily updates scheduled (v2.1 - 13 components)
crontab -l | grep "daily-updates"

# Test manual update
update-all
```

---

## Post-Installation Configuration

### Setup MCP Servers

#### Context7 MCP (Documentation)

```bash
# 1. Get API key from https://context7.ai
# 2. Add to .env
cp .env.example .env
echo "CONTEXT7_API_KEY=ctx7sk-your-api-key" >> .env

# 3. Verify health
./scripts/check_context7_health.sh

# 4. Restart Claude Code
exit && claude
```

#### GitHub MCP (Repository Operations)

```bash
# 1. Authenticate GitHub CLI
gh auth login

# 2. Verify health
./scripts/check_github_mcp_health.sh

# 3. Restart Claude Code
exit && claude
```

### Configure Git

```bash
# Set up Git identity
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Set default branch
git config --global init.defaultBranch main

# Configure editor
git config --global core.editor nano  # or vim, code, etc.
```

### Customize Ghostty Theme

```bash
# Available themes in configs/ghostty/themes/
ls -la configs/ghostty/themes/

# Edit config to change theme
nano ~/.config/ghostty/config

# Change these lines:
# theme = light:catppuccin-latte,dark:catppuccin-mocha
# to your preferred themes

# Validate configuration
ghostty +show-config
```

---

## First Workflow Execution

### Test Local CI/CD

```bash
# Run complete local workflow
./.runners-local/workflows/gh-workflow-local.sh all

# Check status
./.runners-local/workflows/gh-workflow-local.sh status

# View logs
ls -la ./.runners-local/logs/
```

### Create First Branch

```bash
# Create timestamped branch
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-my-first-feature"
git checkout -b "$BRANCH_NAME"

# Make changes
echo "# My First Feature" >> test.md

# Commit
git add test.md
git commit -m "feat: Add my first feature

Testing the constitutional branch workflow.

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

# Push
git push -u origin "$BRANCH_NAME"

# Merge to main
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main

# Branch preserved (NEVER delete)
```

---

## Troubleshooting

### Installation Fails

```bash
# Check logs
ls -la logs/installation/

# View error log
cat logs/errors.log

# Re-run with verbose mode
./start.sh --verbose
```

### Ghostty Won't Start

```bash
# Check configuration
ghostty +show-config

# Restore backup
cp ~/.config/ghostty/config.backup-* ~/.config/ghostty/config

# Verify binary
which ghostty
ghostty --version
```

### Context Menu Missing

```bash
# Re-run Nautilus integration
./lib/installers/ghostty/steps/06-configure-context-menu.sh

# Restart Nautilus
nautilus -q
```

### MCP Servers Not Working

```bash
# Check Context7
./scripts/check_context7_health.sh

# Check GitHub MCP
./scripts/check_github_mcp_health.sh

# Verify .env file
cat .env | grep -E "CONTEXT7|GITHUB"

# Restart Claude Code
exit && claude
```

---

## Daily Operations

### Check for Updates

```bash
# Manual update check
./scripts/check_updates.sh

# View update logs
update-logs                   # Latest summary
update-logs-full             # Complete log
update-logs-errors           # Errors only
```

### Monitor System Health

```bash
# Ghostty performance
./.runners-local/workflows/performance-monitor.sh --test

# GitHub Actions usage
gh api user/settings/billing/actions

# Log disk usage
du -sh logs/
```

### Regular Maintenance

```bash
# Weekly: Check branch status
git branch -a

# Weekly: Review logs
less logs/installation/start-*.log | tail -1

# Monthly: Update documentation
# (if you've made custom changes)
```

---

## Next Steps

After installation:

1. **Read Documentation**: [README.md](../../../../README.md)
2. **Explore Agents**: [.claude/agents/](../../../agents/)
3. **Review Commands**: [.claude/commands/](../../../commands/)
4. **Learn Workflows**: [Local CI/CD Guide](./local-cicd-guide.md)
5. **Understand Architecture**: [System Architecture](../architecture/system-architecture.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
