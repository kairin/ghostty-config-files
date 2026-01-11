---
title: Context7 MCP Setup Guide
category: guides
linked-from: AGENTS.md, CRITICAL-requirements.md
status: ACTIVE
last-updated: 2026-01-11
---

# Context7 MCP Setup Guide

[← Back to AGENTS.md](../../../../AGENTS.md)

## Overview

Context7 MCP provides up-to-date documentation and code examples for programming libraries. It allows Claude Code to query current documentation rather than relying on training data.

## Prerequisites

- Claude Code CLI installed
- Internet access for MCP server connection

## Configuration

### 1. MCP Server Configuration

The Context7 server is configured in `.mcp.json`:

```json
{
  "mcpServers": {
    "context7": {
      "type": "http",
      "url": "https://mcp.context7.com/mcp"
    }
  }
}
```

### 2. Verify Configuration

```bash
# Check MCP configuration exists
cat .mcp.json | grep context7

# Restart Claude Code to load MCP servers
exit && claude
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

1. Verify `.mcp.json` configuration
2. Restart Claude Code: `exit && claude`
3. Check internet connectivity

### No Results Returned

- Try different search terms
- Verify the library ID is correct
- Check if the library is indexed by Context7

## Related Documentation

- [Critical Requirements](../requirements/CRITICAL-requirements.md#-critical-context7-mcp-integration--documentation-synchronization)
- [GitHub MCP Setup](./github-mcp.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
