# Context7 Integration for Powerlevel10k

> Architectural Synchronization of Terminal Themes and AI-Driven Contextual Engines

## Overview

Context7 is an MCP (Model Context Protocol) server that provides up-to-date, version-specific documentation to AI coding assistants, eliminating "documentation decay" where LLMs rely on stale training data.

This document covers how to ensure Powerlevel10k documentation is properly indexed for AI consumption.

---

## Why Context7 for Powerlevel10k?

### Project Status
Powerlevel10k is in a **"limited support" phase**:
- No new feature development
- Critical bug fixes only
- Community-led support

Because human support is limited, the ability for AI assistants to accurately parse existing documentation becomes the primary troubleshooting method.

### The Problem
Generic LLM knowledge may recommend deprecated or non-existent parameters. Context7 grounds AI responses in the official source of truth.

---

## Context7 Architecture

### MCP Components

| Component | Function |
|-----------|----------|
| **Tools** | `resolve-library-id`, `query-docs` - AI can look up and fetch specific snippets |
| **Resources** | `context7://libraries` - Directory of all indexed projects |
| **Prompts** | Trigger phrases like `use context7` |

### Ingestion Pipeline

1. **Parsing**: Extract from `.md`, `.rst`, `.ipynb` formats
2. **Enrichment**: Add metadata and explanations to code examples
3. **Vectorization**: Store in vector database for semantic search
4. **Reranking**: `c7score` algorithm prioritizes high-quality code examples

---

## Indexing Powerlevel10k in Context7

### Option 1: Automated Submission (Web Interface)

1. Navigate to [context7.com/add-library](https://context7.com/add-library)
2. Submit URL: `https://github.com/romkatv/powerlevel10k`
3. Wait for status to change from `initial` to `finalized`

### Option 2: Manual Submission (Pull Request)

Create a JSON entry for the Context7 repository:

```json
{
  "settings": {
    "library": "powerlevel10k",
    "title": "Powerlevel10k Zsh Theme",
    "docsRepoUrl": "https://github.com/romkatv/powerlevel10k",
    "folders": ["config", "gitstatus"],
    "excludeFolders": ["internal", "archive"]
  }
}
```

### Option 3: GitHub Actions (Continuous Ingestion)

Use the `rennf93/upsert-context7` action:

```yaml
- uses: rennf93/upsert-context7@v1
  with:
    operation: refresh
    library-name: /romkatv/powerlevel10k
    repo-url: https://github.com/romkatv/powerlevel10k
    timeout: 30
```

---

## Optimizing Documentation for AI (AEO)

### The `context7.json` Manifest

Place at project root to dictate how Context7 interprets the structure:

```json
{
  "$schema": "https://context7.com/schema/context7.json",
  "projectTitle": "Powerlevel10k",
  "description": "High-performance Zsh theme with speed and flexibility features",
  "rules": [
    "Always recommend Meslo Nerd Font for icons",
    "Prefer p10k configure wizard for basic style changes",
    "Refer to .p10k.zsh for all specific color variables"
  ],
  "excludeFiles": ["LICENSE.md", "Makefile"]
}
```

### The `llms.txt` Standard

A simplified Markdown file providing an "AI-friendly" summary:

- `llms.txt` - Structured index with links and descriptions
- `llms-full.txt` - Concatenated version for single-pass reading

---

## Using Context7 with AI Clients

### Configuration

| Environment | Configuration |
|-------------|---------------|
| **Cursor** | Settings → MCP → Add server |
| **VS Code** | Install MCP extension, add server via CLI |
| **Claude Code** | `claude mcp add --transport sse context7 https://mcp.context7.com/sse` |
| **Windsurf** | Add to `mcpServers` in config |

### Prompt Patterns

```
# Direct trigger
How do I make my prompt two-line? use context7

# Library specification
Update my .p10k.zsh to show AWS profile only when active. use context7:/romkatv/powerlevel10k

# Topic filtering
Show me transient prompt configuration. use context7 topic:transient
```

### Library ID Shortcut

Skip detection by using the ID directly:
```
/llmstxt/romkatv-powerlevel10k-llms-full.txt
```

---

## Key Documentation Sources

| Source | Content |
|--------|---------|
| `README.md` | Installation, instant prompt, configuration wizard |
| `font.md` | Meslo Nerd Font requirements |
| `gitstatus/README.md` | gitstatusd technical documentation |
| `config/*.zsh` | Example configurations (lean, classic, rainbow, pure) |
| GitHub Wiki | Segment library and styling details |

---

## Rate Limits

| Tier | Query Limit | Private Repos |
|------|-------------|---------------|
| Free | 50/day | Not supported |
| API Key | Higher/Unlimited | Supported |

Obtain an API key from the Context7 dashboard for higher limits.

---

*Source: Context7 Documentation and [upstash/context7](https://github.com/upstash/context7)*
