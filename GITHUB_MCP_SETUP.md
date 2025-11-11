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
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_TOKEN}"
      }
    }
  }
}
```

**Key Points:**
- `command: "npx"` - Uses npx to run the server (no global install needed)
- `args: ["-y", "@modelcontextprotocol/server-github"]` - Auto-confirms package download
- `env.GITHUB_PERSONAL_ACCESS_TOKEN` - References GITHUB_TOKEN from environment

### 2. `.env` (Environment Variables)

Location: `/home/kkk/Apps/ghostty-config-files/.env`

**⚠️ CRITICAL REQUIREMENT**: Claude Code's `.mcp.json` uses `${VARIABLE_NAME}` syntax to reference **shell environment variables**. These must be exported to your shell environment.

**Quick Setup**:
```bash
# Add to ~/.zshrc (or ~/.bashrc for bash)
cat >> ~/.zshrc << 'EOF'
if [ -f /home/kkk/Apps/ghostty-config-files/.env ]; then
    set -a
    source /home/kkk/Apps/ghostty-config-files/.env
    set +a
fi
EOF

# Reload configuration
source ~/.zshrc
```

**Example `.env` format**:
```bash
# Context7 MCP Server
CONTEXT7_API_KEY=ctx7sk-your-api-key-here
CONTEXT7_MCP_URL=mcp.context7.com/mcp
CONTEXT7_API_URL=context7.com/api/v1

# GitHub Personal Access Token (for GitHub MCP integration)
# Automatically obtained from GitHub CLI: gh auth token
# Required scopes: repo, read:org, admin:public_key, gist (already configured via gh auth)
# Token refreshes automatically via gh CLI
GITHUB_TOKEN=gho_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Security Notes:**
- ✅ `.env` is in `.gitignore` (not committed to version control)
- ✅ Token obtained from GitHub CLI (`gh auth token`)
- ✅ Token has appropriate scopes for repository operations
- ⚠️ Token expires periodically - refresh with `gh auth refresh`

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
./local-infra/runners/gh-workflow-local.sh local

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
- [Local CI/CD Guide](/home/kkk/Apps/ghostty-config-files/local-infra/README.md) - Integration patterns

### Health Check Script
- Location: `/home/kkk/Apps/ghostty-config-files/scripts/check_github_mcp_health.sh`
- Purpose: Automated verification of GitHub MCP configuration
- Usage: `./scripts/check_github_mcp_health.sh`

## Support

For issues or questions:

1. **Health Check**: Run `./scripts/check_github_mcp_health.sh`
2. **GitHub CLI**: Run `gh auth status` and `gh --version`
3. **MCP Status**: Use `/mcp` command in Claude Code
4. **Logs**: Check Claude Code debug logs for MCP server errors
5. **Documentation**: Review this guide and [CLAUDE.md](CLAUDE.md)

---

**Version**: 1.0
**Last Updated**: 2025-11-11
**Status**: ACTIVE - GITHUB MCP SERVER INSTALLED AND CONFIGURED
**Maintained By**: Claude Code + github-sync-guardian agent
