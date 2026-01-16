# GitHub Token Configuration Guide

> **Status**: ACTIVE - Environment Variable & MCP Configuration Reference
> **Last Updated**: 2025-11-21
> **Related**: [MCP Configuration](./github-mcp.md), [First-Time Setup](./first-time-setup.md)

## 🎯 Overview

This guide explains how GITHUB_TOKEN is configured and accessed in this repository, resolving the common MCP configuration warning:

```
⚠️ Missing GITHUB_TOKEN environment variable for the github MCP server in .mcp.json
```

## 📊 Current Configuration Status

### ✅ GitHub CLI Authentication (PRIMARY METHOD)
**Status**: CONFIGURED AND WORKING

```bash
# Verify GitHub CLI authentication
gh auth status

# Expected output:
# ✓ Logged in to github.com account kairin (keyring)
# - Active account: true
# - Token: gho_************************************
# - Token scopes: 'gist', 'read:org', 'repo', 'workflow'
```

### 📝 MCP Configuration (.mcp.json)
**Configuration**: Uses environment variable substitution

```json
{
  "mcpServers": {
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

## 🔍 Understanding the Warning

The `/doctor` warning indicates:
- ❌ `GITHUB_TOKEN` is **NOT** set as a shell environment variable
- ✅ GitHub CLI **IS** authenticated and has a valid token
- ✅ MCP server **CAN** still work via alternative methods

**Why the warning appears**:
- Claude Code's `/doctor` checks for `GITHUB_TOKEN` in environment variables (`env | grep GITHUB_TOKEN`)
- The token exists in GitHub CLI's keyring, not as an exported shell variable
- This is a **warning**, not a critical failure

## 🛠️ Configuration Options

### Option 1: GitHub CLI Authentication (RECOMMENDED - CURRENT)

**Advantages**:
- ✅ Secure keyring storage (no plaintext token in files)
- ✅ Automatic token rotation via `gh auth refresh`
- ✅ Token scopes managed via GitHub CLI
- ✅ No environment variable management needed
- ✅ Works across all `gh` CLI commands

**How it works**:
1. GitHub CLI stores token in system keyring
2. `gh auth token` retrieves token when needed
3. Scripts can use `$(gh auth token)` for authenticated API calls

**Verification**:
```bash
# Check authentication status
gh auth status

# Retrieve current token (for scripting)
gh auth token

# Test API access
gh api user
```

**When to use**:
- **Default choice** for most users
- When using `gh` CLI commands extensively
- When security is a priority (keyring > environment variables)

### Option 2: Environment Variable (ALTERNATIVE)

**Advantages**:
- ✅ Claude Code's MCP server reads directly from environment
- ✅ Eliminates `/doctor` warning
- ✅ Simpler for MCP server configuration

**Disadvantages**:
- ❌ Token stored in plaintext in `.env` file
- ❌ Must manually rotate token
- ❌ Risk of committing token to Git (if `.env` not in `.gitignore`)

**Setup Instructions**:

1. **Get GitHub Token**:
   ```bash
   # Via GitHub CLI (if authenticated)
   gh auth token

   # Or create new token at: https://github.com/settings/tokens
   # Required scopes: repo, workflow, read:org, gist
   ```

2. **Add to .env file**:
   ```bash
   # Add to /home/kkk/Apps/ghostty-config-files/.env
   echo "GITHUB_TOKEN=gho_YOUR_TOKEN_HERE" >> .env
   ```

3. **Export to shell environment** (CRITICAL):
   ```bash
   # Add to ~/.zshrc (or ~/.bashrc):
   set -a
   source /home/kkk/Apps/ghostty-config-files/.env
   set +a
   ```

4. **Reload shell**:
   ```bash
   source ~/.zshrc  # or source ~/.bashrc
   ```

5. **Verify**:
   ```bash
   env | grep GITHUB_TOKEN
   # Should output: GITHUB_TOKEN=gho_YOUR_TOKEN_HERE
   ```

**When to use**:
- When you want to eliminate the `/doctor` warning
- When MCP server requires direct environment variable access
- When you understand the security trade-offs

### Option 3: Hybrid Approach (BALANCED)

**Best of both worlds**:
- Use GitHub CLI as primary authentication method
- Set `GITHUB_TOKEN` environment variable from `gh auth token`
- Gets security benefits + eliminates warning

**Setup**:
```bash
# Add to ~/.zshrc (or ~/.bashrc):
# Auto-populate GITHUB_TOKEN from gh CLI
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    export GITHUB_TOKEN=$(gh auth token)
fi
```

**Verification**:
```bash
source ~/.zshrc
env | grep GITHUB_TOKEN
gh auth status
```

**Advantages**:
- ✅ Token never stored in plaintext files
- ✅ Automatic token refresh via `gh auth refresh`
- ✅ Eliminates `/doctor` warning
- ✅ MCP servers get environment variable access

## 🚨 Security Considerations

### DO:
- ✅ Use GitHub CLI authentication (keyring storage)
- ✅ Keep `.env` in `.gitignore` (already configured)
- ✅ Use minimal token scopes required for operations
- ✅ Rotate tokens regularly via `gh auth refresh`
- ✅ Use hybrid approach for best security + compatibility

### DO NOT:
- ❌ Commit `.env` file to Git
- ❌ Share tokens in chat/email
- ❌ Use tokens with excessive scopes
- ❌ Store tokens in configuration files committed to Git
- ❌ Use the same token across multiple machines (create per-device tokens)

## 🧪 Testing MCP Server Access

### Test GitHub MCP Server Connectivity
```bash
# Via Claude Code (if MCP configured)
# The MCP server should work even without GITHUB_TOKEN in environment
# if GitHub CLI is authenticated

# Test via gh CLI (alternative)
gh api user
gh api repos/OWNER/REPO
gh api repos/OWNER/REPO/issues
```

### Troubleshooting MCP Issues

**Issue**: MCP server fails to spawn
```bash
# Check npx availability
npx --version

# Check MCP server package
npx -y @modelcontextprotocol/server-github --help

# Check environment variable substitution
env | grep GITHUB_TOKEN
```

**Issue**: MCP server authentication fails
```bash
# Verify gh CLI authentication
gh auth status

# Verify token scopes
gh auth token | gh api user --input -

# Refresh authentication
gh auth refresh
```

## 📊 Current Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| GitHub CLI Authentication | ✅ CONFIGURED | Token in keyring, scopes: repo, workflow, read:org, gist |
| GITHUB_TOKEN Environment Variable | ❌ NOT SET | Not required with gh CLI authentication |
| MCP Configuration (.mcp.json) | ✅ CONFIGURED | Uses `${GITHUB_TOKEN}` substitution |
| `/doctor` Warning | ⚠️ EXPECTED | Warning is informational, not critical |
| GitHub API Access | ✅ WORKING | Via `gh` CLI commands |

## 🎯 Recommendation

**For this repository**: Continue using **Option 1** (GitHub CLI Authentication)

**Rationale**:
- Current setup is secure and functional
- `/doctor` warning is informational only
- GitHub CLI provides superior security (keyring vs plaintext)
- All local CI/CD workflows use `gh` CLI commands (not direct token access)
- MCP server can fall back to `gh auth token` if needed

**Optional Enhancement**: Implement **Option 3** (Hybrid Approach) to eliminate warning while maintaining security

```bash
# Add to ~/.zshrc:
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    export GITHUB_TOKEN=$(gh auth token)
fi
```

## 🔗 Related Documentation

- [GitHub MCP Setup Guide](./github-mcp.md)
- [First-Time Setup Guide](first-time-setup.md)
- [Local CI/CD Operations](../requirements/local-cicd-operations.md)
- [Critical Requirements](../requirements/CRITICAL-requirements.md)

## 📝 Metadata

**Version**: 1.0
**Created**: 2025-11-21
**Status**: ACTIVE - CONFIGURATION REFERENCE
**Purpose**: Resolve MCP GITHUB_TOKEN warning and provide configuration options
