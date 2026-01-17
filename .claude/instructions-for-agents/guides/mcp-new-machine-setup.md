---
title: MCP New Machine Setup Guide
category: guides
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2026-01-16
---

# MCP New Machine Setup Guide

[← Back to AGENTS.md](../../../../AGENTS.md)

## Overview

This guide provides setup instructions for configuring all **7 MCP servers** on a new machine. MCP servers are configured at **user scope** (`~/.claude.json`), making them available across all projects.

## All 7 MCP Servers

| # | Server | Purpose | Type |
|---|--------|---------|------|
| 1 | **context7** | Up-to-date library documentation | HTTP |
| 2 | **github** | Repository operations, issues, PRs | stdio |
| 3 | **markitdown** | Document format conversion | stdio |
| 4 | **playwright** | Browser automation, screenshots | stdio |
| 5 | **hf-mcp-server** | Hugging Face model hub access | HTTP |
| 6 | **shadcn** | Official shadcn/ui CLI MCP | stdio |
| 7 | **shadcn-ui** | shadcn component tools | stdio |

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Claude Code CLI installed
- [ ] GitHub CLI (`gh`) installed and authenticated
- [ ] Node.js via fnm installed
- [ ] Python UV (`uvx`) installed
- [ ] API keys ready (Context7, HuggingFace)
- [ ] **Ubuntu 23.10+**: AppArmor fix applied (see [Ubuntu 23.10+ Fix](#ubuntu-2310-apparmor-fix-required))

### Quick Prerequisite Install

```bash
# GitHub CLI (if not installed)
# See: https://cli.github.com/

# fnm (Fast Node Manager)
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.bashrc  # or restart shell
fnm install --lts

# Python UV
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc  # or restart shell

# Verify installations
gh --version
fnm --version
node --version
uvx --version
```

### Ubuntu 23.10+ AppArmor Fix (REQUIRED)

Ubuntu 23.10+ disabled unprivileged user namespaces by default, which breaks Chromium's sandbox. **This must be fixed before Playwright will work.**

```bash
# Step 1: Apply immediately
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0

# Step 2: Make permanent (survives reboot)
echo 'kernel.apparmor_restrict_unprivileged_userns=0' | sudo tee /etc/sysctl.d/99-userns.conf
```

**Why this is safe:** This is the default setting on Fedora, Arch, and many other distributions. It's required for Chromium/Chrome sandbox, Flatpak apps, and some container tools.

## Quick Setup (All 7 Servers)

### Step 1: Set Up Secrets

Copy the secrets template and fill in your API keys:

```bash
# If you have the ghostty-config-files repo
cp ~/Apps/ghostty-config-files/configs/mcp/.mcp-secrets.template ~/.mcp-secrets

# Or create manually
cat > ~/.mcp-secrets << 'EOF'
# MCP Server Secrets
export CONTEXT7_API_KEY="your-context7-key"
export HUGGINGFACE_TOKEN="your-hf-token"
export HF_TOKEN="$HUGGINGFACE_TOKEN"
EOF

# Add to shell config
echo '[ -f ~/.mcp-secrets ] && source ~/.mcp-secrets' >> ~/.zshrc
source ~/.zshrc
```

**Get your API keys:**
- Context7: https://context7.com (sign up for API key)
- HuggingFace: https://huggingface.co/settings/tokens

### Step 2: Authenticate GitHub CLI

```bash
gh auth login
gh auth status  # Verify
```

### Step 3: Create Playwright Wrapper Script

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/playwright-mcp-wrapper.sh << 'EOF'
#!/bin/bash
# Playwright MCP Wrapper for Claude Code
export PATH="$HOME/.local/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env)"
fi

# Use system Chromium instead of Chrome (optional)
export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/snap/bin/chromium

# --isolated: Prevents stale browser lock issues between sessions
exec npx -y @playwright/mcp@latest --browser chromium --isolated
EOF

chmod +x ~/.local/bin/playwright-mcp-wrapper.sh
```

**Key flags:**
- `--isolated`: Creates fresh browser instances, preventing stale lock issues
- `--browser chromium`: Uses Chromium (lighter than Chrome)

### Step 4: Add All 7 MCP Servers

```bash
# 1. Context7 (Documentation Server)
# Note: Requires CONTEXT7_API_KEY set in environment (from ~/.mcp-secrets)
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp \
  --header "CONTEXT7_API_KEY: $CONTEXT7_API_KEY"

# 2. GitHub (Repository Operations)
claude mcp add --scope user github -- bash -c 'GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) npx -y @modelcontextprotocol/server-github'

# 3. MarkItDown (Document Conversion)
claude mcp add --scope user markitdown -- uvx markitdown-mcp

# 4. Playwright (Browser Automation)
claude mcp add --scope user playwright -- ~/.local/bin/playwright-mcp-wrapper.sh

# 5. HuggingFace (Model Hub)
claude mcp add --scope user hf-mcp-server --transport http https://huggingface.co/mcp

# 6. shadcn (Official CLI MCP)
claude mcp add --scope user shadcn -- npx shadcn@latest mcp

# 7. shadcn-ui (Component Tools)
claude mcp add --scope user shadcn-ui -- bash -c 'GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) npx @jpisnice/shadcn-ui-mcp-server'
```

### Step 5: Verify Setup

```bash
claude mcp list
```

**Expected output:** 7 servers, all showing `✓ Connected`:
- context7
- github
- markitdown
- playwright
- hf-mcp-server
- shadcn
- shadcn-ui

Or in Claude Code:
```
/mcp
```

## Server Details

| Server | Purpose | Requires | Tools Provided |
|--------|---------|----------|----------------|
| **context7** | Library documentation | API key (header auth) | resolve-library-id, query-docs |
| **github** | Repository operations | `gh auth login` | Issues, PRs, file contents, search |
| **markitdown** | Document conversion | `uvx` | convert_to_markdown |
| **playwright** | Browser automation | Wrapper script | Navigate, click, screenshot, etc. |
| **hf-mcp-server** | HuggingFace access | HF login | Model search, download, etc. |
| **shadcn** | shadcn/ui CLI | Node.js | Component installation |
| **shadcn-ui** | Component tools | `gh auth login` | Component search, docs |

## Syncing Secrets Between Machines

### Option 1: Manual Copy (Most Secure)

```bash
# On source machine
cat ~/.mcp-secrets
# Copy output

# On target machine
cat > ~/.mcp-secrets << 'EOF'
# Paste content here
EOF
```

### Option 2: Private Gist

```bash
# On source machine - create encrypted gist
gh gist create ~/.mcp-secrets --private --desc "MCP Secrets"
# Note the gist ID

# On target machine - download
gh gist view <gist-id> --raw > ~/.mcp-secrets
chmod 600 ~/.mcp-secrets
```

### Option 3: Syncthing/Dropbox

Add `~/.mcp-secrets` to your sync folder and create a symlink:
```bash
ln -s ~/Sync/.mcp-secrets ~/.mcp-secrets
```

### Option 4: 1Password/Bitwarden CLI

```bash
# Using 1Password CLI
op read "op://Private/MCP Secrets/notes" > ~/.mcp-secrets
```

## Troubleshooting

### Server Not Connecting

```bash
# List current servers
claude mcp list

# Remove and re-add problematic server
claude mcp remove --scope user <server-name>
# Then re-run the add command
```

### Common Issues

| Issue | Solution |
|-------|----------|
| GitHub disconnected | Re-run `gh auth login` |
| Playwright disconnected | Verify wrapper script exists and is executable |
| Playwright sandbox error (Ubuntu 23.10+) | Apply [AppArmor fix](#ubuntu-2310-apparmor-fix-required) |
| Playwright stale lock error | Ensure `--isolated` flag in wrapper script |
| Context7 disconnected | Verify `CONTEXT7_API_KEY` is set and re-add with `--header` flag |
| MarkItDown disconnected | Verify `uvx` is installed |
| HuggingFace disconnected | Login at huggingface.co in browser first |
| shadcn disconnected | Verify Node.js is installed via fnm |
| shadcn-ui disconnected | Check GitHub auth token |

### Check Environment Variables

```bash
# Verify secrets are loaded
echo $CONTEXT7_API_KEY | head -c 10
echo $HUGGINGFACE_TOKEN | head -c 10
```

### Restart Claude Code

After making changes, restart Claude Code for servers to reconnect:
```bash
# Exit current session and start fresh
claude
```

## Managing Servers

### List All Servers
```bash
claude mcp list
```

### Remove a Server
```bash
claude mcp remove --scope user <server-name>
```

### Update a Server
```bash
# Remove then re-add with new configuration
claude mcp remove --scope user <server-name>
claude mcp add --scope user <server-name> -- <command>
```

## Automated Setup Script

For even faster setup, use the automated script:

```bash
./scripts/002-install-first-time/setup_mcp_config.sh
```

This script will:
1. Check all prerequisites
2. Create wrapper scripts
3. Add all 7 MCP servers
4. Verify connectivity

## Detailed Guides

For more information on specific servers:

- [Context7 MCP Setup](./context7-mcp.md)
- [GitHub MCP Setup](./github-mcp.md)
- [MarkItDown MCP Setup](./markitdown-mcp.md)
- [Playwright MCP Setup](./playwright-mcp.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
