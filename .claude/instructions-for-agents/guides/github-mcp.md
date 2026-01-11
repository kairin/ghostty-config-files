---
title: GitHub MCP Setup Guide
category: guides
linked-from: AGENTS.md, CRITICAL-requirements.md
status: ACTIVE
last-updated: 2026-01-11
---

# GitHub MCP Setup Guide

[← Back to AGENTS.md](../../../../AGENTS.md)

## Overview

GitHub MCP provides direct GitHub API integration for repository operations, issues, pull requests, and code search. It leverages the GitHub CLI (`gh`) for authentication.

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Node.js installed (via fnm)
- Claude Code CLI installed

## Configuration

### 1. Authenticate GitHub CLI

```bash
# Login to GitHub CLI
gh auth login

# Verify authentication
gh auth status
```

### 2. MCP Server Configuration

The GitHub MCP server is configured in `.mcp.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "bash",
      "args": ["-c", "export PATH=\"$HOME/.local/bin:$PATH\" && eval \"$(fnm env)\" && GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) npx -y @modelcontextprotocol/server-github"]
    }
  }
}
```

This configuration:
- Uses the `gh auth token` command to get the authentication token
- Runs the official `@modelcontextprotocol/server-github` package
- Automatically sets up the required environment

### 3. Verify Configuration

```bash
# Check GitHub CLI authentication
gh auth status

# Check MCP configuration
cat .mcp.json | grep github

# Restart Claude Code to load MCP servers
exit && claude
```

## Available Tools

Once configured, these tools become available:

### Repository Operations
- `mcp__github__search_repositories` - Search GitHub repositories
- `mcp__github__create_repository` - Create new repository
- `mcp__github__fork_repository` - Fork a repository
- `mcp__github__get_file_contents` - Get file contents from repo

### Issue Management
- `mcp__github__list_issues` - List repository issues
- `mcp__github__get_issue` - Get issue details
- `mcp__github__create_issue` - Create new issue
- `mcp__github__update_issue` - Update existing issue
- `mcp__github__add_issue_comment` - Add comment to issue

### Pull Request Operations
- `mcp__github__list_pull_requests` - List PRs
- `mcp__github__get_pull_request` - Get PR details
- `mcp__github__create_pull_request` - Create new PR
- `mcp__github__merge_pull_request` - Merge a PR
- `mcp__github__create_pull_request_review` - Review a PR
- `mcp__github__get_pull_request_files` - Get changed files
- `mcp__github__get_pull_request_status` - Get PR status

### Branch & File Operations
- `mcp__github__create_branch` - Create new branch
- `mcp__github__list_commits` - List commits
- `mcp__github__create_or_update_file` - Create/update file
- `mcp__github__push_files` - Push multiple files

### Search Operations
- `mcp__github__search_code` - Search code across repos
- `mcp__github__search_issues` - Search issues and PRs
- `mcp__github__search_users` - Search GitHub users

## Best Practices

1. **Use MCP for all GitHub operations**: Prefer MCP tools over manual `gh` CLI commands for consistency and logging.

2. **Follow branch naming**: Use `YYYYMMDD-HHMMSS-type-description` format for branches.

3. **Preserve branches**: Never delete branches without explicit user permission.

4. **Constitutional compliance**: All repository operations should follow the project's git strategy.

## Troubleshooting

### Authentication Errors

```bash
# Re-authenticate GitHub CLI
gh auth logout
gh auth login

# Verify token has required scopes
gh auth status
```

### MCP Server Not Starting

1. Verify Node.js is available: `node --version`
2. Verify fnm is configured: `fnm list`
3. Check the command manually:
   ```bash
   GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) npx -y @modelcontextprotocol/server-github
   ```

### Rate Limiting

GitHub API has rate limits. If you encounter limits:
- Wait for the rate limit to reset
- Reduce the frequency of API calls
- Consider using authenticated requests (increases limits)

## Security

- Token is obtained dynamically via `gh auth token`
- Token is never stored in files (only in GitHub CLI's secure storage)
- Token auto-refreshes via GitHub CLI
- `.env` file (if used) should never be committed

## Related Documentation

- [Critical Requirements](../requirements/CRITICAL-requirements.md#-critical-github-mcp-integration--repository-operations)
- [Context7 MCP Setup](./context7-mcp.md)
- [Git Strategy](../requirements/git-strategy.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
