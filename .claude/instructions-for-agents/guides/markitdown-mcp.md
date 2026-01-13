---
title: MarkItDown MCP Setup Guide
category: guides
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2026-01-14
---

# MarkItDown MCP Setup Guide

[← Back to AGENTS.md](../../../../AGENTS.md)

## Overview

MarkItDown MCP provides document conversion capabilities, allowing Claude Code to convert various file formats to markdown. This is useful for reading and analyzing PDFs, Office documents, and other file types.

## Prerequisites

- Python UV (`uv`) or `uvx` installed
- Claude Code CLI installed

### Installing UV (if needed)

```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Verify installation
uvx --version
```

## Configuration (User-Scoped)

MCP servers are configured at user scope (`~/.claude.json`), making them available across all projects.

### 1. Add MCP Server

```bash
claude mcp add --scope user markitdown -- uvx markitdown-mcp
```

### 2. Verify Configuration

```bash
# Start Claude Code
claude

# Check MCP status (in Claude Code)
/mcp
```

You should see `markitdown · ✔ connected`.

### 3. Remove/Update Server

```bash
# Remove existing server
claude mcp remove --scope user markitdown

# Re-add
claude mcp add --scope user markitdown -- uvx markitdown-mcp
```

## Available Tools

### `mcp__markitdown__convert_to_markdown`

Converts a resource described by a URI to markdown.

**Parameters:**
- `uri`: The URI of the resource to convert (http:, https:, file:, or data: URIs)

**Example usage:**
```
Convert the file at file:///home/user/document.pdf to markdown
```

## Supported Formats

MarkItDown can convert various formats to markdown:

- **Documents**: PDF, DOCX, PPTX, XLSX
- **Web**: HTML pages via URL
- **Images**: With OCR capabilities
- **Data**: Base64-encoded content via data URIs

## Use Cases

1. **PDF Analysis**: Convert PDF documents to markdown for analysis
2. **Web Page Processing**: Fetch and convert web pages to clean markdown
3. **Document Extraction**: Extract text from Office documents
4. **File Processing**: Convert local files to markdown format

## Best Practices

1. **Use file URIs for local files**: Prefix local paths with `file://`
2. **Use https URIs for web content**: Always use HTTPS when possible
3. **Large files**: Be aware that large documents may take longer to process

## Troubleshooting

### MCP Server Not Available

If MarkItDown tools aren't showing:

1. Verify `uvx` is installed: `uvx --version`
2. Verify server is added: `claude mcp list`
3. Restart Claude Code: exit and run `claude` again

### Conversion Errors

- Verify the file exists and is accessible
- Check file format is supported
- Ensure the URI is properly formatted (e.g., `file:///absolute/path`)

### Package Not Found

```bash
# Update uvx cache
uvx --refresh markitdown-mcp
```

## Related Documentation

- [Context7 MCP Setup](./context7-mcp.md)
- [GitHub MCP Setup](./github-mcp.md)
- [Playwright MCP Setup](./playwright-mcp.md)
- [MCP New Machine Setup](./mcp-new-machine-setup.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
