---
title: 'MCP Integration Guide'
description: 'Complete guide to Context7 and GitHub MCP integration for enhanced AI development'
pubDate: 2025-11-13
author: 'System Documentation'
tags: ['mcp', 'context7', 'github', 'ai-tools', 'documentation']
order: 4
---

# MCP Integration Guide

This guide covers the integration of Model Context Protocol (MCP) servers for enhanced AI-assisted development.

## What is MCP?

Model Context Protocol (MCP) provides AI assistants with real-time access to external data sources and APIs. This configuration includes two essential MCP servers:

1. **Context7 MCP**: Up-to-date documentation for all project technologies
2. **GitHub MCP**: Direct GitHub API integration for repository operations

## Context7 MCP Setup

### Purpose
Access up-to-date documentation and best practices for all technologies used in the project.

### Quick Setup

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env and add: CONTEXT7_API_KEY=ctx7sk-your-api-key

# 2. Verify configuration
./scripts/check_context7_health.sh

# 3. Restart Claude Code
exit && claude
```

### Available Tools

- `mcp__context7__resolve-library-id` - Find library IDs for documentation queries
- `mcp__context7__get-library-docs` - Retrieve up-to-date library documentation

### Usage Example

```bash
# Query latest Next.js documentation
# Claude automatically uses Context7 MCP when you ask about libraries
"What are the latest best practices for Next.js 14 routing?"
```

### Constitutional Compliance

- **MANDATORY**: Query Context7 before major configuration changes
- **RECOMMENDED**: Add Context7 validation to local CI/CD workflows
- **BEST PRACTICE**: Document Context7 queries in conversation logs

### Complete Documentation

See [Context7 MCP Setup](../../documentations/user/setup/context7-mcp.md) for:
- Installation steps
- API key configuration
- Troubleshooting
- Advanced usage examples

## GitHub MCP Setup

### Purpose
Direct GitHub API integration for repository operations without manual CLI commands.

### Quick Setup

```bash
# 1. Verify GitHub CLI authentication
gh auth status

# 2. Run health check
./scripts/check_github_mcp_health.sh

# 3. Restart Claude Code
exit && claude
```

### Core Capabilities

**Repository Operations**:
- List, create, manage repositories
- Fork repositories
- Create branches

**Issue Management**:
- Create, update, search issues
- Add comments
- Update issue status

**Pull Request Operations**:
- Create pull requests
- Review PRs
- Merge PRs
- Check PR status

**File Operations**:
- Read repository files
- Create/update files
- Push multiple files in single commit

**Search Operations**:
- Search repositories
- Search issues and PRs
- Search code
- Search users

### Constitutional Compliance

- **MANDATORY**: Use GitHub MCP for all repository operations
- **RECOMMENDED**: GitHub MCP operations follow branch preservation strategy
- **REQUIREMENT**: Respect branch naming conventions (YYYYMMDD-HHMMSS-type-description)

### Security

- ✅ Token stored in .env (not committed)
- ✅ Leverages existing gh CLI authentication
- ✅ Token auto-refreshes via gh CLI

### Complete Documentation

See [GitHub MCP Setup](../../documentations/user/setup/github-mcp.md) for:
- Installation steps
- Authentication setup
- Usage examples
- Troubleshooting

## Benefits of MCP Integration

### Context7 Benefits
- Always up-to-date documentation
- Best practices validation
- Technology-specific guidance
- Constitutional compliance verification

### GitHub MCP Benefits
- No manual gh CLI commands
- Constitutional branch workflows
- Automated PR creation
- Integrated issue management

## Health Checks

Run health checks to verify MCP integration:

```bash
# Context7 health check
./scripts/check_context7_health.sh

# GitHub MCP health check
./scripts/check_github_mcp_health.sh

# Combined health check (via guardian command)
/guardian-health
```

## Troubleshooting

### Context7 Issues

**Problem**: "MCP server not responding"
**Solution**:
1. Verify API key in .env
2. Check network connectivity
3. Restart Claude Code

**Problem**: "Library not found"
**Solution**:
1. Use `resolve-library-id` first
2. Check library name spelling
3. Try alternative library names

### GitHub MCP Issues

**Problem**: "Authentication failed"
**Solution**:
1. Run `gh auth login`
2. Verify token in .env
3. Check token permissions

**Problem**: "Rate limit exceeded"
**Solution**:
1. Wait for rate limit reset
2. Use authenticated requests
3. Check GitHub API status

## Integration with Guardian Commands

MCP servers integrate seamlessly with guardian slash commands:

- `/guardian-health` - Checks MCP server health
- `/guardian-deploy` - Uses GitHub MCP for deployment
- `/guardian-commit` - Uses GitHub MCP for commits

## Next Steps

- Review [AI Guidelines](../../ai-guidelines/core-principles.md) for MCP usage
- Explore [Developer Documentation](../../developer/architecture.md) for technical details
- Try [Guardian Commands](./usage.md) for automated workflows
