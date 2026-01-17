---
title: GitHub MCP Setup
category: guides
linked-from: AGENTS.md
status: REDIRECT
last-updated: 2026-01-18
---

# GitHub MCP Setup

> **This guide has been consolidated.**
> See: [MCP Setup Guide](./mcp-setup.md#github)

GitHub MCP provides direct GitHub API integration for repository operations, issues, pull requests, and code search. It leverages the GitHub CLI (`gh`) for authentication.

**Quick Setup:**
```bash
gh auth login
claude mcp add --scope user github -- bash -c 'GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token) npx -y @modelcontextprotocol/server-github'
```

**Key Features:**
- Repository operations (create, fork, search)
- Issue management (list, create, update, comment)
- Pull request operations (create, review, merge)
- Code and user search

For complete setup instructions, full tool list, and troubleshooting, see the [MCP Setup Guide](./mcp-setup.md).

---

[← Back to AGENTS.md](../../../../AGENTS.md)
