---
title: Context7 MCP Setup Guide
category: guides
linked-from: AGENTS.md, CRITICAL-requirements.md
status: ACTIVE
last-updated: 2026-01-14
---

# Context7 MCP Setup Guide

[← Back to AGENTS.md](../../../../AGENTS.md)

## Overview

Context7 MCP provides up-to-date documentation and code examples for programming libraries. It allows Claude Code to query current documentation rather than relying on training data.

## Prerequisites

- Claude Code CLI installed
- Internet access for MCP server connection
- Context7 API key (obtain from [Context7](https://context7.com))

## Configuration (User-Scoped)

MCP servers are configured at user scope (`~/.claude.json`), making them available across all projects.

### 1. Add MCP Server

```bash
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp \
  --header "CONTEXT7_API_KEY: <your-api-key>"
```

Replace `<your-api-key>` with your Context7 API key.

### 2. Verify Configuration

```bash
# Start Claude Code
claude

# Check MCP status (in Claude Code)
/mcp
```

You should see `context7 · ✔ connected`.

### 3. Remove/Update Server

```bash
# Remove existing server
claude mcp remove --scope user context7

# Re-add with new configuration
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp \
  --header "CONTEXT7_API_KEY: <your-new-key>"
```

## Available Tools

Once configured, these tools become available:

### `mcp__context7__resolve-library-id`

Resolves a library name to a Context7-compatible library ID.

**Example usage:**
```
Resolve library ID for "react" to query its documentation
```

### `mcp__context7__query-docs`

Retrieves up-to-date documentation for a library.

**Example usage:**
```
Query Context7 for React hooks documentation using library ID /facebook/react
```

## Best Practices

1. **Query before major changes**: Always check Context7 for current best practices before implementing significant configuration changes.

2. **Verify library IDs**: Use `resolve-library-id` first to get the correct library ID before querying documentation.

3. **Be specific**: Provide detailed queries for better documentation results.

## Troubleshooting

### MCP Server Not Available

If Context7 tools aren't showing:

1. Verify server is added: `claude mcp list`
2. Restart Claude Code: exit and run `claude` again
3. Check internet connectivity
4. Verify API key is correct

### Authentication Errors

```bash
# Remove and re-add with correct API key
claude mcp remove --scope user context7
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp \
  --header "CONTEXT7_API_KEY: <your-api-key>"
```

### No Results Returned

- Try different search terms
- Verify the library ID is correct
- Check if the library is indexed by Context7

## Related Documentation

- [Critical Requirements](../requirements/CRITICAL-requirements.md#-critical-context7-mcp-integration--documentation-synchronization)
- [GitHub MCP Setup](./github-mcp.md)
- [MCP New Machine Setup](./mcp-new-machine-setup.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
