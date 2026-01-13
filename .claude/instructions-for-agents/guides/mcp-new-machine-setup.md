---
title: MCP New Machine Setup Guide
category: guides
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2026-01-14
---

# MCP New Machine Setup Guide

[← Back to AGENTS.md](../../../../AGENTS.md)

## Overview

This guide provides quick setup instructions for configuring all 4 MCP servers on a new machine. MCP servers are configured at **user scope** (`~/.claude.json`), making them available across all projects.

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Claude Code CLI installed
- [ ] GitHub CLI (`gh`) installed and authenticated
- [ ] Node.js via fnm installed
- [ ] Python UV (`uvx`) installed

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

## Quick Setup (All 4 Servers)

Run these commands to set up all MCP servers:

### Step 1: Authenticate GitHub CLI

```bash
gh auth login
gh auth status  # Verify
```

### Step 2: Create Playwright Wrapper Script

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/playwright-mcp-wrapper.sh << 'EOF'
#!/bin/bash
# Playwright MCP Wrapper for Claude Code
export PATH="$HOME/.local/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env)"
fi
exec npx -y @playwright/mcp@latest
EOF

chmod +x ~/.local/bin/playwright-mcp-wrapper.sh
```

### Step 3: Add All MCP Servers

```bash
# Context7 (Documentation Server)
# Replace <your-api-key> with your Context7 API key
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp \
  --header "CONTEXT7_API_KEY: <your-api-key>"

# GitHub (Repository Operations)
claude mcp add --scope user github -- bash -c 'export PATH="$HOME/.local/bin:$PATH" && eval "$(fnm env)" && GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) npx -y @modelcontextprotocol/server-github'

# MarkItDown (Document Conversion)
claude mcp add --scope user markitdown -- uvx markitdown-mcp

# Playwright (Browser Automation)
claude mcp add --scope user playwright -- ~/.local/bin/playwright-mcp-wrapper.sh
```

### Step 4: Verify Setup

```bash
claude
# In Claude Code, type:
/mcp
```

**Expected output:** 4 servers, all showing `✔ connected`:
- context7
- github
- markitdown
- playwright

## Server Details

| Server | Purpose | Requires |
|--------|---------|----------|
| **context7** | Up-to-date library documentation | API key |
| **github** | Repository operations, issues, PRs | `gh auth login` |
| **markitdown** | Document format conversion | `uvx` |
| **playwright** | Browser automation, screenshots | Wrapper script |

## Troubleshooting

### Server Not Connecting

```bash
# List current servers
claude mcp list

# Remove and re-add problematic server
claude mcp remove --scope user <server-name>
# Then re-run the add command
```

### Check Server Status

In Claude Code:
```
/mcp
```

### Common Issues

1. **GitHub disconnected**: Re-run `gh auth login`
2. **Playwright disconnected**: Verify wrapper script exists and is executable
3. **Context7 disconnected**: Check API key is correct
4. **MarkItDown disconnected**: Verify `uvx` is installed

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

## Detailed Guides

For more information on each server:

- [Context7 MCP Setup](./context7-mcp.md)
- [GitHub MCP Setup](./github-mcp.md)
- [MarkItDown MCP Setup](./markitdown-mcp.md)
- [Playwright MCP Setup](./playwright-mcp.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
