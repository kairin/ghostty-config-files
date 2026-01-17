---
title: Context7 MCP Setup
category: guides
linked-from: AGENTS.md
status: REDIRECT
last-updated: 2026-01-18
---

# Context7 MCP Setup

> **This guide has been consolidated.**
> See: [MCP Setup Guide](./mcp-setup.md#context7)

Context7 MCP provides up-to-date documentation and code examples for programming libraries. It allows Claude Code to query current documentation rather than relying on training data.

**Quick Setup:**
```bash
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp \
  --header "CONTEXT7_API_KEY: $CONTEXT7_API_KEY"
```

**Available Tools:**
- `mcp__context7__resolve-library-id` - Resolve library name to Context7 ID
- `mcp__context7__query-docs` - Query documentation for a library

For complete setup instructions, troubleshooting, and best practices, see the [MCP Setup Guide](./mcp-setup.md).

---

[← Back to AGENTS.md](../../../../AGENTS.md)
