# New Device Setup Guide - Local CI/CD & Cross-Device Compatibility

> Complete step-by-step guide for setting up ghostty-config-files repository on a fresh device or cloning to an additional machine.

## 🎯 Overview

This guide covers **three distinct scenarios**:
1. **Fresh Ubuntu Install**: Setting up on a new Ubuntu 25.10 system
2. **Existing System Clone**: Adding repository to a system with existing development tools
3. **Multi-Device Development**: Working across desktop, laptop, and other machines

**Goal**: Achieve 100% local CI/CD functionality with zero GitHub Actions consumption on any device.

---

## 📋 Prerequisites Checklist

### Minimum Requirements (ALL Devices)

| Component | Version | Installation Command | Verification |
|-----------|---------|---------------------|--------------|
| **Ubuntu** | 25.10+ | N/A (OS install) | `lsb_release -a` |
| **Git** | 2.40+ | `sudo apt install git` | `git --version` |
| **GitHub CLI** | 2.40+ | `sudo apt install gh` | `gh --version` |
| **Node.js** | 18+ (25+ recommended) | See fnm section below | `node --version` |
| **npm** | 10+ | Bundled with Node.js | `npm --version` |
| **jq** | 1.6+ | `sudo apt install jq` | `jq --version` |
| **curl** | 7.80+ | `sudo apt install curl` | `curl --version` |
| **bash** | 5.0+ | Pre-installed on Ubuntu | `bash --version` |

### Optional Components

| Component | Purpose | Installation | Required For |
|-----------|---------|--------------|--------------|
| **Ghostty** | Terminal emulator | Build from source | Terminal configuration |
| **ShellCheck** | Shell script linting | `sudo apt install shellcheck` | Code quality validation |
| **Lighthouse CLI** | Performance audits | `npm install -g lighthouse` | Performance benchmarking |
| **Python 3** | Utility scripts | `sudo apt install python3` | Some helper scripts |

---

## 🚀 Quick Start (5-Minute Setup)

### Scenario 1: Fresh Ubuntu Install (Recommended Path)

**Complete one-command installation** via the main `start.sh` script:

```bash
# Step 1: Clone repository
git clone https://github.com/kairin1/ghostty-config-files.git
cd ghostty-config-files

# Step 2: Run installation script
./start.sh

# Step 3: Verify installation
ghostty --version
claude --version

# Step 4: Test local CI/CD
./.runners-local/workflows/gh-workflow-local.sh all
```

**What `start.sh` does**:
- Installs all prerequisites (Ghostty, Node.js via fnm, GitHub CLI, etc.)
- Configures terminal environment (themes, dircolors, context menu)
- Sets up AI tools (Claude Code, Gemini CLI)
- Initializes local CI/CD infrastructure
- Creates backup of existing configurations

**Expected Duration**: 8-10 minutes on fresh Ubuntu 25.10

---

### Scenario 2: Existing System (Selective Setup)

**You already have development tools** - just need repository-specific setup:

```bash
# Step 1: Clone repository
git clone https://github.com/kairin1/ghostty-config-files.git
cd ghostty-config-files

# Step 2: Run health check to see what's missing
./.runners-local/workflows/health-check.sh

# Step 3: Follow generated setup instructions
cat .runners-local/logs/setup-instructions-*.md

# Step 4: Install only missing components
# (Example: if only MCP setup needed)
cp .env.example .env
# Edit .env with your API keys

# Add to ~/.zshrc:
cat >> ~/.zshrc << 'EOF'

# ghostty-config-files environment
if [ -f "$HOME/path/to/ghostty-config-files/.env" ]; then
    set -a
    source "$HOME/path/to/ghostty-config-files/.env"
    set +a
fi
EOF

# Step 5: Restart shell and verify
source ~/.zshrc
./.runners-local/workflows/health-check.sh
```

**Expected Duration**: 2-5 minutes depending on what's already installed

---

### Scenario 3: Multi-Device Development (Clone to Additional Machine)

**Already have repository on another device** - synchronizing to new machine:

```bash
# On NEW device:
# Step 1: Clone repository to your preferred location
git clone https://github.com/kairin1/ghostty-config-files.git ~/dev/ghostty-config

# Step 2: Change to repository directory
cd ~/dev/ghostty-config

# Step 3: Run health check
./.runners-local/workflows/health-check.sh --setup-guide

# Step 4: Install missing tools (example)
# Install GitHub CLI
sudo apt install gh
gh auth login

# Install Node.js via fnm (Fast Node Manager)
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.bashrc
fnm install 25
fnm use 25

# Install project dependencies
npm install

# Step 5: Configure environment variables
cp .env.example .env
# Copy API keys from original device OR generate new ones

# Add environment loading to shell
echo '
# ghostty-config environment
if [ -f "$HOME/dev/ghostty-config/.env" ]; then
    set -a
    source "$HOME/dev/ghostty-config/.env"
    set +a
fi' >> ~/.zshrc

# Step 6: Verify setup
source ~/.zshrc
./.runners-local/workflows/health-check.sh
```

**Expected Duration**: 5-10 minutes

---

## 🔧 Detailed Component Setup

### 1. GitHub CLI Authentication (CRITICAL)

**Why**: Required for workflow simulation, billing checks, repository operations

```bash
# Install GitHub CLI
sudo apt install gh

# Authenticate (choose one method):

# Method A: Interactive browser login (RECOMMENDED)
gh auth login
# Select: GitHub.com → HTTPS → Login with browser → Authorize

# Method B: Personal access token
# 1. Generate token: https://github.com/settings/tokens
#    Scopes needed: repo, read:org, admin:public_key, gist
# 2. Authenticate:
gh auth login --with-token < token.txt

# Verify authentication
gh auth status
# Should show: ✓ Logged in to github.com as YOUR_USERNAME

# Set default repository
cd /path/to/ghostty-config-files
gh repo set-default
# Select your repository from the list
```

**Troubleshooting**:
- **"gh: command not found"**: Run `sudo apt install gh`
- **"authentication failed"**: Token may be expired, regenerate and retry
- **"permission denied"**: Check token has required scopes

---

### 2. Node.js Setup via fnm (Fast Node Manager)

**Why**: Project uses latest Node.js (25+) for Astro.build and AI CLI tools

**fnm vs nvm**: fnm is 40x faster with performance measured and logged startup impact vs NVM's 2000ms

```bash
# Install fnm
curl -fsSL https://fnm.vercel.app/install | bash

# Add fnm to shell (automatic for most shells)
# For bash/zsh, already added by installer

# Restart shell or source config
source ~/.bashrc  # or source ~/.zshrc

# Install latest Node.js
fnm install 25
fnm use 25
fnm default 25

# Verify installation
node --version  # Should show: v25.x.x
npm --version   # Should show: 10.x.x

# Install global tools
npm install -g @anthropic-ai/claude-code
npm install -g @google/gemini-cli
npm install -g lighthouse  # Optional: for performance benchmarks
```

**Troubleshooting**:
- **"fnm: command not found"**: Restart terminal or `source ~/.bashrc`
- **"node: command not found"**: Run `fnm default 25` to set system default
- **npm install slow**: Use `npm ci` instead of `npm install` for faster installs

---

### 3. Environment Variables Setup (CRITICAL FOR MCP)

**Why**: Claude Code's MCP servers use `${VARIABLE_NAME}` syntax requiring shell-exported variables

#### Step 3.1: Create .env File

```bash
# Navigate to repository
cd /path/to/ghostty-config-files

# Copy example file
cp .env.example .env

# Edit with your API keys
nano .env
```

**Required variables**:
```bash
# Context7 MCP Server
# Get API key from: https://context7.com/
CONTEXT7_API_KEY=ctx7sk-your-api-key-here
CONTEXT7_MCP_URL=mcp.context7.com/mcp
CONTEXT7_API_URL=context7.com/api/v1

# GitHub Personal Access Token
# Option 1: Use GitHub CLI token (RECOMMENDED)
GITHUB_TOKEN=$(gh auth token)

# Option 2: Generate token manually
# From: https://github.com/settings/tokens
# Scopes: repo, read:org, admin:public_key, gist
GITHUB_TOKEN=ghp_your_token_here
```

#### Step 3.2: Export to Shell Environment

**⚠️ CRITICAL**: `.env` file alone is NOT sufficient. Variables MUST be exported to shell.

```bash
# Detect your shell
echo $SHELL
# Output: /bin/zsh OR /bin/bash

# For ZSH (Ubuntu 25.10 default):
cat >> ~/.zshrc << 'EOF'

# ═══════════════════════════════════════════════════════════
# ghostty-config-files Environment Variables
# CRITICAL: Claude Code MCP requires shell-exported variables
# ═══════════════════════════════════════════════════════════
if [ -f "$HOME/Apps/ghostty-config-files/.env" ]; then
    set -a  # Automatically export all variables
    source "$HOME/Apps/ghostty-config-files/.env"
    set +a
fi
EOF

# For BASH:
cat >> ~/.bashrc << 'EOF'

# ghostty-config-files Environment Variables
if [ -f "$HOME/Apps/ghostty-config-files/.env" ]; then
    set -a
    source "$HOME/Apps/ghostty-config-files/.env"
    set +a
fi
EOF
```

**⚠️ IMPORTANT**: Replace `$HOME/Apps/ghostty-config-files` with YOUR actual repository path!

#### Step 3.3: Verify Environment Variables

```bash
# Restart shell or source config
source ~/.zshrc  # or source ~/.bashrc

# Verify variables are exported
env | grep CONTEXT7_API_KEY
env | grep GITHUB_TOKEN

# Expected output:
# CONTEXT7_API_KEY=ctx7sk-...
# GITHUB_TOKEN=ghp_... OR gho_...

# Test MCP server access
claude mcp list
# Should show: context7 (connected), github (connected)
```

**Troubleshooting**:
- **Variables not showing**: Check shell config path is correct
- **MCP not connected**: Restart Claude Code: `exit` then `claude`
- **GITHUB_TOKEN empty**: Run `gh auth token` and paste value in .env

---

### 4. MCP Server Configuration

**Why**: Provides up-to-date documentation and GitHub API integration

#### Step 4.1: Verify .mcp.json

```bash
# Check if .mcp.json exists
ls -la /path/to/ghostty-config-files/.mcp.json

# View configuration
cat .mcp.json
```

**Expected content**:
```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp",
      "headers": {
        "CONTEXT7_API_KEY": "${CONTEXT7_API_KEY}"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

#### Step 4.2: Test MCP Connectivity

```bash
# Check MCP server status
claude mcp list

# Expected output:
# Name       Type    Status
# ────────   ─────   ──────────
# context7   http    connected
# github     stdio   connected

# Test Context7 query
# In Claude Code conversation:
# "Use Context7 to find Astro configuration best practices"

# Test GitHub MCP
# In Claude Code conversation:
# "Use GitHub MCP to list recent commits in this repository"
```

**Troubleshooting**:
- **"context7: disconnected"**: Check CONTEXT7_API_KEY is valid
- **"github: failed to spawn"**: Check Node.js and npx are available
- **"MCP servers not loading"**: Restart Claude Code and check logs

---

### 5. Local CI/CD Infrastructure Setup

**Why**: Zero GitHub Actions consumption via local workflow simulation

```bash
# Navigate to repository
cd /path/to/ghostty-config-files

# Verify .runners-local/ structure
ls -la .runners-local/
# Expected:
# drwxr-xr-x workflows/
# drwxr-xr-x logs/
# drwxr-xr-x self-hosted/
# drwxr-xr-x tests/

# Make all workflow scripts executable
chmod +x .runners-local/workflows/*.sh

# Run health check
./.runners-local/workflows/health-check.sh

# Expected output:
# ✅ Core Tools: 7/7 passed
# ✅ Environment Variables: 4/4 passed
# ✅ Local CI/CD: 4/4 passed
# ✅ MCP Servers: 4/4 passed
# ✅ Astro Build: 5/5 passed
# 🎉 Overall Status: READY FOR LOCAL CI/CD

# Test complete workflow
./.runners-local/workflows/gh-workflow-local.sh all

# Expected: All steps pass with zero GitHub Actions consumption
```

---

### 6. Astro Build Environment Setup

**Why**: Documentation website requires Astro.build with specific configuration

```bash
# Navigate to website directory
cd /path/to/ghostty-config-files/website

# Install dependencies
npm install

# Verify installation
ls -la node_modules/  # Should have astro, tailwindcss, etc.

# Test Astro build
npm run build

# Expected output:
# Building...
# 16 pages built in Xs
# ✅ Build complete in docs/

# Verify critical .nojekyll file
ls -la ../docs/.nojekyll
# CRITICAL: This file MUST exist for GitHub Pages CSS/JS loading

# If missing, create it:
touch ../docs/.nojekyll
```

---

## 🔒 Security Best Practices

### API Key Management

**DO**:
- ✅ Store API keys ONLY in `.env` file (gitignored)
- ✅ Use GitHub CLI token management: `gh auth token`
- ✅ Rotate keys periodically (every 90 days)
- ✅ Use Context7 API key with limited scopes
- ✅ Keep `.env.example` updated with placeholder values

**DON'T**:
- ❌ Commit `.env` to version control
- ❌ Share API keys via chat, email, or screenshots
- ❌ Hard-code API keys in scripts
- ❌ Use production tokens for testing
- ❌ Grant more scopes than necessary

### GitHub Token Scopes

**Minimum required scopes**:
- `repo` - Repository access (required for GitHub MCP)
- `read:org` - Organization membership (for org repos)
- `admin:public_key` - Deploy keys management
- `gist` - Gist operations

**Generate token**: https://github.com/settings/tokens/new

**Token expiration**: Set to 90 days and create calendar reminder to rotate

---

## 🧪 Verification Checklist

Use this checklist to verify complete setup on ANY device:

### ✅ Core Tools Verification
```bash
# Run all verification commands
gh --version          # ✓ 2.40+
node --version        # ✓ 25+ (or 18+ minimum)
npm --version         # ✓ 10+
git --version         # ✓ 2.40+
jq --version          # ✓ 1.6+
curl --version        # ✓ 7.80+
bash --version        # ✓ 5.0+

# GitHub CLI authentication
gh auth status        # ✓ Logged in to github.com
```

### ✅ Environment Variables Verification
```bash
# Check variables exported to shell
env | grep CONTEXT7_API_KEY  # ✓ Shows: CONTEXT7_API_KEY=ctx7sk-...
env | grep GITHUB_TOKEN       # ✓ Shows: GITHUB_TOKEN=ghp_... or gho_...

# Check shell config loads .env
grep -A 5 "ghostty-config-files" ~/.zshrc  # ✓ Shows set -a, source .env, set +a
```

### ✅ MCP Server Verification
```bash
# MCP connectivity
claude mcp list       # ✓ context7: connected, github: connected

# .mcp.json exists
ls -la .mcp.json      # ✓ File exists in repository root
```

### ✅ Local CI/CD Verification
```bash
# Health check passes
./.runners-local/workflows/health-check.sh
# ✓ All categories: PASSED

# Complete workflow simulation
./.runners-local/workflows/gh-workflow-local.sh all
# ✓ All steps: SUCCESS
# ✓ Workflow completed in <120s
```

### ✅ Astro Build Verification
```bash
# Dependencies installed
ls -la website/node_modules/  # ✓ Directory exists and populated

# Build succeeds
cd website && npm run build   # ✓ 16 pages built successfully

# .nojekyll exists
ls -la docs/.nojekyll          # ✓ File exists
```

### ✅ Cross-Device Compatibility Verification
```bash
# Repository path detection
git rev-parse --show-toplevel  # ✓ Shows current repository path

# Scripts use relative paths
grep -r "/home/kkk" .runners-local/workflows/*.sh
# ✓ Should show minimal or zero hard-coded paths

# Health check generates device-specific setup
./.runners-local/workflows/health-check.sh --setup-guide
# ✓ Creates setup-instructions-HOSTNAME-*.md
```

**If ALL items above show ✓, your device is READY for local CI/CD workflows!**

---

## 🛠️ Troubleshooting Common Issues

### Issue 1: "gh: command not found"

**Cause**: GitHub CLI not installed

**Fix**:
```bash
sudo apt update
sudo apt install gh
gh --version  # Verify installation
```

---

### Issue 2: "node: command not found" (after fnm install)

**Cause**: fnm not added to shell PATH

**Fix**:
```bash
# Restart terminal OR
source ~/.bashrc  # or ~/.zshrc

# Verify fnm available
fnm --version

# Set Node.js default
fnm install 25
fnm default 25

# Verify
node --version
```

---

### Issue 3: "CONTEXT7_API_KEY: not found" (MCP connection failure)

**Cause**: Environment variables not exported to shell

**Fix**:
```bash
# Check if .env exists
cat .env | grep CONTEXT7_API_KEY
# Should show: CONTEXT7_API_KEY=ctx7sk-...

# Check shell config
cat ~/.zshrc | grep -A 3 "ghostty-config-files"
# Should show: set -a, source .env, set +a

# Verify path is correct in shell config
# Edit ~/.zshrc and update path to match:
nano ~/.zshrc
# Change: source /home/kkk/Apps/ghostty-config-files/.env
# To: source /YOUR/ACTUAL/PATH/.env

# Reload shell
source ~/.zshrc

# Verify
env | grep CONTEXT7_API_KEY
```

---

### Issue 4: "MCP server failed to spawn" (GitHub MCP)

**Cause**: npx not available or GITHUB_TOKEN not set

**Fix**:
```bash
# Verify npx available
npx --version

# If not available, install Node.js
fnm install 25 && fnm use 25

# Verify GITHUB_TOKEN
env | grep GITHUB_TOKEN

# If empty, get token from GitHub CLI
gh auth token
# Copy output and add to .env:
echo "GITHUB_TOKEN=$(gh auth token)" >> .env

# Reload shell
source ~/.zshrc
```

---

### Issue 5: "Astro build failed" (npm install errors)

**Cause**: Node.js version too old OR corrupted node_modules

**Fix**:
```bash
# Check Node.js version
node --version
# If <18, upgrade:
fnm install 25 && fnm use 25

# Clean install
cd website
rm -rf node_modules package-lock.json
npm install

# Retry build
npm run build
```

---

### Issue 6: "CSS/JS returns 404 on GitHub Pages"

**Cause**: Missing `.nojekyll` file (CRITICAL)

**Fix**:
```bash
# Create .nojekyll file
touch docs/.nojekyll

# Verify
ls -la docs/.nojekyll

# Rebuild and commit
cd website && npm run build
git add docs/.nojekyll
git commit -m "CRITICAL: Add .nojekyll for GitHub Pages asset loading"
git push
```

---

### Issue 7: "Health check shows NEEDS_SETUP"

**Cause**: Missing components or incorrect configuration

**Fix**:
```bash
# Run health check with setup guide generation
./.runners-local/workflows/health-check.sh --setup-guide

# View generated instructions
cat .runners-local/logs/setup-instructions-*.md

# Follow instructions step-by-step

# Re-run health check to verify
./.runners-local/workflows/health-check.sh
```

---

## 📊 Platform-Specific Notes

### Ubuntu 25.10 (Primary Target)
- ✅ ZSH is default shell (use ~/.zshrc)
- ✅ GitHub CLI available in apt repositories
- ✅ All dependencies available via apt
- ⚠️ Ensure universe repository enabled: `sudo add-apt-repository universe`

### Ubuntu 24.04 LTS
- ⚠️ bash is default shell (use ~/.bashrc instead of ~/.zshrc)
- ✅ All setup instructions compatible
- ⚠️ May need to install gh from GitHub releases: https://github.com/cli/cli/releases

### Ubuntu 22.04 LTS
- ⚠️ Older package versions, may need manual installs
- ⚠️ GitHub CLI requires manual installation
- ✅ fnm works identically
- ⚠️ Verify Node.js compatibility

### Debian-based Systems
- ✅ Most instructions compatible
- ⚠️ Use `sudo apt` (not `sudo apt-get`)
- ⚠️ Check package availability: `apt search <package>`

---

## 🎯 Quick Reference: Essential Commands

### Daily Operations
```bash
# Health check (run anytime)
./.runners-local/workflows/health-check.sh

# Complete local workflow
./.runners-local/workflows/gh-workflow-local.sh all

# Build website
cd website && npm run build

# Update dependencies
npm install  # In website/ directory
```

### Troubleshooting
```bash
# Check GitHub authentication
gh auth status

# Check environment variables
env | grep -E "CONTEXT7|GITHUB_TOKEN"

# Check MCP connectivity
claude mcp list

# Regenerate setup instructions
./.runners-local/workflows/health-check.sh --setup-guide
```

### Maintenance
```bash
# Update global tools
npm update -g @anthropic-ai/claude-code
npm update -g @google/gemini-cli

# Update Node.js
fnm install latest
fnm use latest
fnm default latest

# Update GitHub CLI
sudo apt update && sudo apt upgrade gh
```

---

## 📚 Additional Resources

### Official Documentation
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [fnm Documentation](https://github.com/Schniz/fnm)
- [Context7 MCP Setup](./context7-mcp.md)
- [GitHub MCP Setup](./github-mcp.md)
- [Local CI/CD Infrastructure](../.runners-local/README.md)

### Repository Documentation
- [CLAUDE.md](../CLAUDE.md) - Complete AI assistant instructions
- [README.md](../README.md) - User documentation
- [Development Commands](../website/src/ai-guidelines/development-commands.md)

### Support
- **Issues**: https://github.com/kairin1/ghostty-config-files/issues
- **Discussions**: Use GitHub Discussions for setup questions
- **Local Logs**: Check `.runners-local/logs/` for detailed error logs

---

**Last Updated**: 2025-11-17
**Tested On**: Ubuntu 25.10, Ubuntu 24.04 LTS, Ubuntu 22.04 LTS
**Supported Shells**: ZSH (default), bash
**Estimated Setup Time**: 5-15 minutes depending on existing tools
