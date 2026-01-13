---
title: Playwright MCP Setup Guide
category: guides
linked-from: AGENTS.md
status: ACTIVE
last-updated: 2026-01-14
---

# Playwright MCP Setup Guide

[← Back to AGENTS.md](../../../../AGENTS.md)

## Overview

Playwright MCP provides browser automation capabilities, allowing Claude Code to interact with web pages, take screenshots, fill forms, and perform automated testing. It uses a wrapper script to properly initialize the Node.js environment.

## Prerequisites

- Node.js installed (via fnm)
- Claude Code CLI installed
- Wrapper script created (see below)

## Configuration (User-Scoped)

MCP servers are configured at user scope (`~/.claude.json`), making them available across all projects.

### 1. Create Wrapper Script

First, create the wrapper script that initializes the environment:

```bash
mkdir -p ~/.local/bin

cat > ~/.local/bin/playwright-mcp-wrapper.sh << 'EOF'
#!/bin/bash
# Playwright MCP Wrapper for Claude Code
# This script initializes the environment and runs the Playwright MCP server

# Initialize fnm if available
export PATH="$HOME/.local/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env)"
fi

# Run the Playwright MCP server
exec npx -y @playwright/mcp@latest
EOF

chmod +x ~/.local/bin/playwright-mcp-wrapper.sh
```

### 2. Add MCP Server

```bash
claude mcp add --scope user playwright -- ~/.local/bin/playwright-mcp-wrapper.sh
```

### 3. Verify Configuration

```bash
# Start Claude Code
claude

# Check MCP status (in Claude Code)
/mcp
```

You should see `playwright · ✔ connected`.

### 4. Remove/Update Server

```bash
# Remove existing server
claude mcp remove --scope user playwright

# Re-add
claude mcp add --scope user playwright -- ~/.local/bin/playwright-mcp-wrapper.sh
```

## Available Tools

### Navigation
- `mcp__playwright__browser_navigate` - Navigate to a URL
- `mcp__playwright__browser_navigate_back` - Go back to previous page
- `mcp__playwright__browser_tabs` - List, create, close, or select tabs

### Page Interaction
- `mcp__playwright__browser_click` - Click on elements
- `mcp__playwright__browser_type` - Type text into elements
- `mcp__playwright__browser_fill_form` - Fill multiple form fields
- `mcp__playwright__browser_select_option` - Select dropdown options
- `mcp__playwright__browser_hover` - Hover over elements
- `mcp__playwright__browser_drag` - Drag and drop elements
- `mcp__playwright__browser_press_key` - Press keyboard keys

### Screenshots & Snapshots
- `mcp__playwright__browser_snapshot` - Capture accessibility snapshot (preferred)
- `mcp__playwright__browser_take_screenshot` - Take visual screenshot

### Dialogs & Files
- `mcp__playwright__browser_handle_dialog` - Handle alert/confirm/prompt dialogs
- `mcp__playwright__browser_file_upload` - Upload files

### Advanced
- `mcp__playwright__browser_evaluate` - Execute JavaScript on page
- `mcp__playwright__browser_run_code` - Run Playwright code snippets
- `mcp__playwright__browser_console_messages` - Get console messages
- `mcp__playwright__browser_network_requests` - Get network requests
- `mcp__playwright__browser_wait_for` - Wait for text or time

### Browser Management
- `mcp__playwright__browser_resize` - Resize browser window
- `mcp__playwright__browser_close` - Close the browser
- `mcp__playwright__browser_install` - Install browser if missing

## Use Cases

1. **Web Testing**: Automated testing of web applications
2. **Screenshots**: Capture screenshots of web pages
3. **Form Automation**: Fill and submit forms
4. **Web Scraping**: Extract data from web pages
5. **Visual Verification**: Check page layouts and content

## Best Practices

1. **Use snapshots over screenshots**: `browser_snapshot` provides accessibility tree data that's easier to analyze
2. **Wait for elements**: Use `browser_wait_for` before interacting with dynamic content
3. **Handle dialogs**: Be prepared to handle unexpected dialogs
4. **Close browsers**: Always close browsers when done to free resources

## Troubleshooting

### Browser Not Installed

If you see "browser not installed" errors:

```bash
# In Claude Code, use:
# (Claude will call mcp__playwright__browser_install)
```

Or manually:
```bash
npx playwright install chromium
```

### MCP Server Not Starting

1. Verify wrapper script exists: `ls -la ~/.local/bin/playwright-mcp-wrapper.sh`
2. Verify it's executable: `chmod +x ~/.local/bin/playwright-mcp-wrapper.sh`
3. Test manually: `~/.local/bin/playwright-mcp-wrapper.sh`
4. Check fnm is available: `fnm list`

### Server Shows Disconnected

```bash
# Remove and re-add the server
claude mcp remove --scope user playwright
claude mcp add --scope user playwright -- ~/.local/bin/playwright-mcp-wrapper.sh
```

### Display Issues (Headless)

Playwright runs in headless mode by default. If you need to see the browser:
- Modify the wrapper script to pass `--headed` flag
- Or use screenshots/snapshots to see page state

## Wrapper Script Explained

The wrapper script serves several purposes:

1. **PATH Setup**: Ensures `~/.local/bin` is in PATH
2. **fnm Initialization**: Loads fnm environment for Node.js
3. **Latest Version**: Uses `@playwright/mcp@latest` for updates
4. **Clean Execution**: Uses `exec` to replace shell process

## Related Documentation

- [Context7 MCP Setup](./context7-mcp.md)
- [GitHub MCP Setup](./github-mcp.md)
- [MarkItDown MCP Setup](./markitdown-mcp.md)
- [MCP New Machine Setup](./mcp-new-machine-setup.md)

---

[← Back to AGENTS.md](../../../../AGENTS.md)
