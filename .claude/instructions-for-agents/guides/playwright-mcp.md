---
title: Playwright MCP Setup
category: guides
linked-from: AGENTS.md
status: REDIRECT
last-updated: 2026-01-18
---

# Playwright MCP Setup

> **This guide has been consolidated.**
> See: [MCP Setup Guide](./mcp-setup.md#playwright)

Playwright MCP provides browser automation capabilities, allowing Claude Code to interact with web pages, take screenshots, fill forms, and perform automated testing.

**Quick Setup:**
```bash
# Create wrapper script (see full guide for details)
claude mcp add --scope user playwright -- ~/.local/bin/playwright-mcp-wrapper.sh
```

**Key Features:**
- Navigation and tab management
- Page interaction (click, type, fill forms)
- Screenshots and accessibility snapshots
- Dialog handling and file uploads
- JavaScript evaluation

**Ubuntu 23.10+ Users:** AppArmor fix required. See [MCP Setup Guide](./mcp-setup.md#ubuntu-2310-apparmor-fix-required).

For wrapper script setup, full tool list, and troubleshooting, see the [MCP Setup Guide](./mcp-setup.md).

---

[← Back to AGENTS.md](../../../../AGENTS.md)
