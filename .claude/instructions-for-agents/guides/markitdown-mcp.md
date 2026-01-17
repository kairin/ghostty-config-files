---
title: MarkItDown MCP Setup
category: guides
linked-from: AGENTS.md
status: REDIRECT
last-updated: 2026-01-18
---

# MarkItDown MCP Setup

> **This guide has been consolidated.**
> See: [MCP Setup Guide](./mcp-setup.md#markitdown)

MarkItDown MCP provides document conversion capabilities, allowing Claude Code to convert various file formats to markdown.

**Quick Setup:**
```bash
claude mcp add --scope user markitdown -- uvx markitdown-mcp
```

**Supported Formats:**
- Documents: PDF, DOCX, PPTX, XLSX
- Web: HTML pages via URL
- Images: With OCR capabilities
- Data: Base64-encoded content

**Available Tools:**
- `mcp__markitdown__convert_to_markdown` - Convert URI resource to markdown

For complete setup instructions, best practices, and troubleshooting, see the [MCP Setup Guide](./mcp-setup.md).

---

[← Back to AGENTS.md](../../../../AGENTS.md)
