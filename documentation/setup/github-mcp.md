# GitHub MCP Server Setup Guide

> Complete guide for integrating GitHub MCP (Model Context Protocol) server with Claude Code CLI

## Overview

The GitHub MCP server enables Claude Code to interact directly with GitHub repositories, providing capabilities for:
- **Repository Management**: List, create, and manage repositories
- **Issue Tracking**: Create, read, update, and search issues
- **Pull Requests**: Manage PRs, reviews, and merge operations
- **Branch Operations**: Create, list, and manage branches
- **File Operations**: Read, create, update repository files
- **Search**: Search across repositories, issues, and pull requests

## Architecture

```
┌─────────────────┐
│  Claude Code    │
│  CLI Client     │
└────────┬────────┘
         │
         │ Loads .mcp.json
         ▼
┌─────────────────────────────────────┐
│  MCP Configuration                  │
│  - Context7 (HTTP server)           │
│  - GitHub (stdio server via npx)    │
└────────┬────────────────────────────┘
         │
         │ Spawns process
         ▼
┌─────────────────────────────────────┐
│  @modelcontextprotocol/server-github│
│  - Runs via npx (no install needed) │
│  - Uses GITHUB_TOKEN from .env      │
└────────┬────────────────────────────┘
         │
         │ GitHub API calls
         ▼
┌─────────────────────────────────────┐
│  GitHub API                         │
│  - Authenticated via token          │
│  - Scopes: repo, read:org, gist     │
└─────────────────────────────────────┘
```

## Installation Status

**Status**: ✅ INSTALLED AND CONFIGURED

- [x] GitHub CLI authenticated
- [x] GitHub MCP server configured in `.mcp.json`
- [x] GITHUB_TOKEN configured in `.env`
- [x] Node.js and npx available
- [x] Health check passed

## Configuration Files

### 1. `.mcp.json` (Project-Level MCP Configuration)

Location: `/home/kkk/Apps/ghostty-config-files/.mcp.json`

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
      "command": "/home/kkk/Apps/ghostty-config-files/scripts/mcp/start-github-mcp.sh",
      "args": []
    }
  }
}
```

**Key Points:**
- `command` - Uses wrapper script that gets fresh token from `gh auth token`
- No `env` section needed - wrapper handles token internally
- No static `GITHUB_TOKEN` polluting shell environment
- Token always fresh and auto-refreshes via gh CLI

### 2. `.env` (Environment Variables)

Location: `/home/kkk/Apps/ghostty-config-files/.env`

**Example `.env` format**:
```bash
# Context7 MCP Server
CONTEXT7_API_KEY=ctx7sk-your-api-key-here

# GitHub MCP Integration
# Token is dynamically obtained from 'gh auth token' via wrapper script
# No static token needed here - prevents GITHUB_TOKEN from polluting shell environment
```

**Security Notes:**
- ✅ `.env` is in `.gitignore` (not committed to version control)
- ✅ GitHub token obtained dynamically from `gh auth token` (always fresh)
- ✅ No static `GITHUB_TOKEN` in `.env` (prevents interference with `gh copilot`)
- ✅ Token has appropriate scopes for repository operations
- ✅ Token auto-refreshes via gh CLI

### 3. `~/.claude.json` (User-Level Configuration)

The GitHub MCP server is also registered in the user-level Claude Code configuration at `~/.claude.json` under the project-specific settings:

```json
{
  "projects": {
    "/home/kkk/Apps/ghostty-config-files": {
      "mcpServers": {
        "context7": { ... },
        "github": { ... }
      }
    }
  }
}
```

This allows Claude Code to load the MCP server automatically when working in this project directory.

## GitHub CLI Integration

The GitHub MCP server leverages the existing GitHub CLI authentication, providing seamless integration:

```bash
# Check authentication status
gh auth status

# Output:
# github.com
#   ✓ Logged in to github.com account kairin (keyring)
#   - Active account: true
#   - Git operations protocol: ssh
#   - Token: gho_************************************
#   - Token scopes: 'admin:public_key', 'gist', 'read:org', 'repo'

# Get current token
gh auth token

# Refresh token if expired
gh auth refresh
```

**Token Scopes:**
- `repo` - Full control of private repositories
- `read:org` - Read organization membership and teams
- `admin:public_key` - Manage public keys
- `gist` - Create and manage gists

## Health Check

Verify GitHub MCP server installation and configuration:

```bash
# Run comprehensive health check
./scripts/check_github_mcp_health.sh
```

**Health Check Validates:**
1. ✅ GitHub CLI authentication
2. ✅ Environment configuration (.env file and GITHUB_TOKEN)
3. ✅ MCP configuration (.mcp.json structure)
4. ✅ Node.js and npx availability
5. ✅ GitHub MCP server package accessibility
6. ✅ Repository context (git remote and branch)

## Usage Examples

Once Claude Code is restarted with the GitHub MCP server loaded, you can use natural language commands:

### Repository Operations

```
User: Can you list all repositories in my GitHub account?
Claude: [Uses github.list_repositories tool]

User: Create a new repository called 'my-project' with a README
Claude: [Uses github.create_repository and github.create_or_update_file tools]
```

### Issue Management

```
User: Show me open issues in this repository
Claude: [Uses github.search_issues with current repository context]

User: Create an issue for the bug we just found
Claude: [Uses github.create_issue tool]

User: Update issue #42 to add a 'bug' label
Claude: [Uses github.update_issue tool]
```

### Pull Request Operations

```
User: List recent pull requests
Claude: [Uses github.list_pull_requests tool]

User: Create a PR from the current branch to main
Claude: [Uses github.create_pull_request tool]

User: Show me the diff for PR #15
Claude: [Uses github.get_pull_request tool]
```

### Branch Management

```
User: List all branches in this repository
Claude: [Uses github.list_branches tool]

User: Create a feature branch for the new authentication system
Claude: [Uses github.create_branch tool]
```

### File Operations

```
User: Show me the contents of README.md in the main branch
Claude: [Uses github.get_file_contents tool]

User: Update the installation instructions in docs/setup.md
Claude: [Uses github.create_or_update_file tool]
```

### Search Operations

```
User: Find all issues mentioning 'performance optimization'
Claude: [Uses github.search_issues tool]

User: Search for repositories using Astro.build framework
Claude: [Uses github.search_repositories tool]
```

## Activation Steps

### 1. Restart Claude Code

The GitHub MCP server is configured but requires a restart to load:

```bash
# Exit current Claude Code session
exit

# Start new session (loads MCP servers from .mcp.json)
claude
```

### 2. Verify MCP Servers Loaded

Within Claude Code conversation:

```
User: What MCP servers are available?
Claude: [Lists available MCP servers including 'github']

# Or use the /mcp command
/mcp
```

### 3. Test GitHub MCP Functionality

```
User: Can you list the issues in this repository?
Claude: [Demonstrates GitHub MCP is working]

User: Show me recent pull requests
Claude: [Confirms GitHub API integration]
```

## Troubleshooting

### Issue: GitHub MCP Server Not Loaded

**Symptoms:**
- `/mcp` command doesn't show 'github' server
- Claude doesn't have access to GitHub tools

**Solutions:**
```bash
# 1. Verify health check passes
./scripts/check_github_mcp_health.sh

# 2. Check .mcp.json syntax
jq '.' .mcp.json

# 3. Verify environment variable
source .env && echo $GITHUB_TOKEN

# 4. Restart Claude Code completely
exit
claude
```

### Issue: Authentication Errors

**Symptoms:**
- "Unauthorized" errors when accessing GitHub API
- "Bad credentials" messages

**Solutions:**
```bash
# 1. Check GitHub CLI authentication
gh auth status

# 2. Refresh authentication
gh auth refresh

# 3. Update token in .env
export GITHUB_TOKEN=$(gh auth token)
echo "GITHUB_TOKEN=$(gh auth token)" >> .env

# 4. Verify token scopes
gh auth status 2>&1 | grep 'Token scopes'
```

### Issue: npx Package Download Fails

**Symptoms:**
- "Failed to start MCP server" errors
- Network timeout during server initialization

**Solutions:**
```bash
# 1. Test npx directly
npx -y @modelcontextprotocol/server-github --version

# 2. Check npm registry access
npm config get registry

# 3. Clear npx cache if needed
rm -rf ~/.npm/_npx/

# 4. Install package globally (alternative)
npm install -g @modelcontextprotocol/server-github
```

### Issue: Rate Limiting

**Symptoms:**
- "API rate limit exceeded" errors
- Slow response times

**Solutions:**
```bash
# 1. Check rate limit status
gh api rate_limit

# 2. Authenticate to increase limits (5000/hour vs 60/hour)
gh auth login

# 3. Use conditional requests (automatic in MCP server)
# No action needed - server handles this
```

## Best Practices

### 1. Token Management

```bash
# Rotate tokens periodically
gh auth refresh --scopes repo,read:org,admin:public_key,gist

# Update .env after rotation
export GITHUB_TOKEN=$(gh auth token)
# Manually update .env file with new token
```

### 2. Security Considerations

- ✅ Never commit `.env` to version control
- ✅ Use `.env.example` for documentation only
- ✅ Limit token scopes to minimum required
- ✅ Rotate tokens regularly (every 90 days recommended)
- ✅ Use GitHub CLI keyring for secure token storage

### 3. Performance Optimization

```bash
# Pre-download GitHub MCP package for faster startup
npx -y @modelcontextprotocol/server-github --version

# Monitor MCP server resource usage
ps aux | grep server-github
```

### 4. Constitutional Compliance

Following project constitutional requirements:

- ✅ **Zero GitHub Actions Consumption**: All operations local via MCP
- ✅ **Branch Preservation**: GitHub MCP respects branch naming conventions
- ✅ **Documentation Synchronization**: Updates tracked in AGENTS.md
- ✅ **Environment Variable Pattern**: Follows Context7 MCP setup pattern

## Integration with Local CI/CD

The GitHub MCP server enhances local CI/CD workflows:

```bash
# Local workflow with GitHub integration
./.runners-local/workflows/gh-workflow-local.sh local

# Claude Code can now:
# - Create issues for failed tests
# - Update PR status with build results
# - Commit fixes and create PRs automatically
# - Query repository state during CI/CD
```

## Advanced Configuration

### Custom GitHub Enterprise

If using GitHub Enterprise Server:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}",
        "GITHUB_API_URL": "https://github.enterprise.com/api/v3"
      }
    }
  }
}
```

### Multiple GitHub Accounts

Configure separate MCP servers for different accounts:

```json
{
  "mcpServers": {
    "github-personal": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN_PERSONAL}"
      }
    },
    "github-work": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN_WORK}"
      }
    }
  }
}
```

## Resources

### Official Documentation
- [GitHub MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/github)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub API Documentation](https://docs.github.com/en/rest)

### Project Documentation
- [CLAUDE.md](/home/kkk/Apps/ghostty-config-files/CLAUDE.md) - Project constitutional requirements
- [Context7 Setup](CONTEXT7_SETUP.md) - Parallel MCP server setup
- [Local CI/CD Guide](/home/kkk/Apps/ghostty-config-files/.runners-local/README.md) - Integration patterns

### Health Check Script
- Location: `/home/kkk/Apps/ghostty-config-files/scripts/check_github_mcp_health.sh`
- Purpose: Automated verification of GitHub MCP configuration
- Usage: `./scripts/check_github_mcp_health.sh`

## GitHub Copilot CLI Configuration

### Important: Enable All AI Models

If you're using GitHub Copilot CLI (installed by `./start.sh`), you **must enable alternative AI models** in your GitHub account settings to access Claude, Gemini, and other models beyond GPT.

#### Steps to Enable All Models:

1. **Navigate to GitHub Copilot Settings**:
   - Go to **https://github.com/settings/copilot**
   - Or: Click your profile → Settings → Copilot

2. **Verify All Models Are Enabled**:

   Ensure the following models show as enabled in the **Features** section:

   - ✅ **Anthropic Claude Sonnet 4** - "You can use the latest Anthropic Claude Sonnet 4 model"
   - ✅ **Anthropic Claude Sonnet 4.5** - "You can use the latest Anthropic Claude Sonnet 4.5 model"
   - ✅ **Anthropic Claude Haiku 4.5** - "You can use the latest Anthropic Claude Haiku 4.5 model"
   - ✅ **Google Gemini 2.5 Pro** - "You can use the latest Google Gemini 2.5 Pro model"
   - ✅ **Google Gemini 3 Pro Preview** - "You can use the latest Google Gemini 3 Pro model"
   - ✅ **OpenAI GPT-5** - "You can use the latest OpenAI GPT-5 model"
   - ✅ **OpenAI GPT-5.1 Preview** - Available for use
   - ✅ **xAI Grok Code Fast 1** - If enabled, you can access xAI Grok

3. **What Happens If Models Are Disabled**:

   If models are disabled in settings, `gh copilot` and `copilot` CLI will show:
   ```
   Some models are not available due to configured policy.

   Select Model
   ❯ 1. Claude Sonnet 4 (1x) (default) (current)
     2. Cancel (Esc)
   ```

   **This is a GitHub account-level policy restriction**, not a local configuration issue.

4. **Troubleshooting Model Access**:

   ```bash
   # Check your Copilot subscription status
   # Visit: https://github.com/settings/copilot

   # Verify you have Copilot Pro or Pro+ subscription
   # Individual Free plan has limited model access

   # Test model access in Copilot CLI
   copilot
   # Should show multiple models if all are enabled

   # Alternative: Use gh copilot with GitHub CLI extension
   gh copilot
   ```

### Important Notes

- **GitHub MCP for Claude Code** ≠ **GitHub Copilot CLI**
  - GitHub MCP: Allows Claude Code to interact with GitHub API (repos, issues, PRs)
  - GitHub Copilot CLI: Standalone AI assistant with model selection

- **GITHUB_TOKEN Environment Variable**:
  - Our configuration **does NOT set** `GITHUB_TOKEN` in `.env` or shell
  - This prevents interference with `gh copilot` model selection
  - GitHub MCP uses wrapper script (`start-github-mcp.sh`) that gets token dynamically

- **Model Policy is Per-Account**:
  - Settings at https://github.com/settings/copilot apply globally
  - Changes take effect immediately (no restart needed)
  - Applies to all Copilot CLI installations on all machines

### Reference Documentation

- [Managing GitHub Copilot policies as an individual subscriber](https://docs.github.com/copilot/how-tos/manage-your-account/managing-copilot-policies-as-an-individual-subscriber)
- [Configuring access to AI models in GitHub Copilot](https://docs.github.com/en/copilot/how-tos/use-ai-models/configure-access-to-ai-models)
- [GitHub Copilot CLI: Enhanced model selection](https://github.blog/changelog/2025-10-03-github-copilot-cli-enhanced-model-selection-image-support-and-streamlined-ui/)

## Support

For issues or questions:

1. **Health Check**: Run `./scripts/check_github_mcp_health.sh`
2. **GitHub CLI**: Run `gh auth status` and `gh --version`
3. **MCP Status**: Use `/mcp` command in Claude Code
4. **Copilot Models**: Visit https://github.com/settings/copilot to enable all models
5. **Logs**: Check Claude Code debug logs for MCP server errors
6. **Documentation**: Review this guide and [CLAUDE.md](CLAUDE.md)

---

**Version**: 1.1
**Last Updated**: 2025-11-24
**Status**: ACTIVE - GITHUB MCP SERVER INSTALLED AND CONFIGURED
**Maintained By**: Claude Code + github-sync-guardian agent
