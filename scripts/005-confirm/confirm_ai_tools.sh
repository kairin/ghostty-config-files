#!/bin/bash
# confirm_ai_tools.sh - Verify AI CLI Tools installation

# Ensure npm global bin is in PATH
if command -v npm &> /dev/null; then
    NPM_BIN=$(npm config get prefix 2>/dev/null)/bin
    export PATH="$NPM_BIN:$PATH"
fi

# Also ensure fnm-managed Node.js is available
if command -v fnm &> /dev/null; then
    eval "$(fnm env --shell bash 2>/dev/null)" || true
fi

echo "Verifying AI CLI tools installation..."
echo ""

INSTALLED=0
TOTAL=3

# Check Claude Code
echo -n "Claude Code: "
if command -v claude &> /dev/null; then
    VER=$(claude --version 2>/dev/null | head -n 1 || echo "installed")
    echo "INSTALLED ($VER)"
    ((INSTALLED++))
else
    echo "NOT INSTALLED"
fi

# Check Gemini CLI
echo -n "Gemini CLI: "
if command -v gemini &> /dev/null; then
    VER=$(gemini --version 2>/dev/null | head -n 1 || echo "installed")
    echo "INSTALLED ($VER)"
    ((INSTALLED++))
else
    echo "NOT INSTALLED"
fi

# Check GitHub Copilot CLI (npm package @github/copilot)
echo -n "GitHub Copilot: "
if command -v copilot &> /dev/null; then
    VER=$(copilot --version 2>/dev/null | head -n 1 || echo "installed")
    echo "INSTALLED ($VER)"
    ((INSTALLED++))
else
    echo "NOT INSTALLED"
fi

echo ""
echo "Summary: $INSTALLED/$TOTAL AI tools installed."

# Setup MCP configuration for Claude Code if it's installed
if command -v claude &> /dev/null; then
    echo ""
    echo "MCP Configuration:"
    SCRIPT_DIR="$(dirname "$0")"
    REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

    if [ -f "$REPO_DIR/.mcp.json" ]; then
        echo "  ✓ MCP configuration exists"
        # Count configured servers
        SERVER_COUNT=$(grep -c '"command"\|"type": "http"' "$REPO_DIR/.mcp.json" 2>/dev/null || echo "0")
        echo "  ✓ $SERVER_COUNT MCP server(s) configured"
    else
        echo "  Setting up MCP configuration..."
        if [ -x "$SCRIPT_DIR/../002-install-first-time/setup_mcp_config.sh" ]; then
            "$SCRIPT_DIR/../002-install-first-time/setup_mcp_config.sh" 2>&1 | sed 's/^/    /'
        else
            echo "  ✗ MCP setup script not found"
            echo "    Run: scripts/002-install-first-time/setup_mcp_config.sh"
        fi
    fi
fi

if [[ $INSTALLED -eq 0 ]]; then
    exit 1
fi

echo ""
echo "PATH verification:"
if echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo "  ✓ $HOME/.local/bin is in PATH"
else
    echo "  ✗ WARNING: $HOME/.local/bin NOT in current PATH"
    echo "    This will be fixed after reloading your shell"
fi

# Check each tool's availability
for cmd in claude gemini copilot; do
    if [ -x "$HOME/.local/bin/$cmd" ] || [ -L "$HOME/.local/bin/$cmd" ]; then
        if command -v $cmd &> /dev/null; then
            echo "  ✓ $cmd: accessible via PATH"
        else
            echo "  ⚠ $cmd: installed but NOT in current PATH (reload shell)"
        fi
    elif command -v $cmd &> /dev/null; then
        echo "  ✓ $cmd: accessible via PATH"
    fi
done

echo ""
echo "Configuration hints:"
if command -v claude &> /dev/null; then
    echo "  Claude: Run 'claude' to authenticate with Anthropic"
elif [ -L "$HOME/.local/bin/claude" ]; then
    echo "  Claude: Installed at $HOME/.local/bin/claude"
    echo "          Reload shell to use 'claude' command"
fi
if command -v gemini &> /dev/null; then
    echo "  Gemini: Export GOOGLE_API_KEY in your shell profile"
fi
if command -v copilot &> /dev/null; then
    echo "  Copilot: Run 'copilot' and use /login to authenticate with GitHub"
fi

# Generate separate artifact manifests for each tool
echo ""
echo "Generating artifact manifests..."
SCRIPT_DIR="$(dirname "$0")"

if command -v claude &> /dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" ai_tools_claude "$CLAUDE_VER" npm > /dev/null 2>&1 && \
        echo "  ✓ Claude manifest generated" || echo "  ✗ Claude manifest failed"
fi

if command -v gemini &> /dev/null; then
    GEMINI_VER=$(gemini --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" ai_tools_gemini "$GEMINI_VER" npm > /dev/null 2>&1 && \
        echo "  ✓ Gemini manifest generated" || echo "  ✗ Gemini manifest failed"
fi

if command -v copilot &> /dev/null; then
    COPILOT_VER=$(copilot --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "unknown")
    "$SCRIPT_DIR/generate_manifest.sh" ai_tools_copilot "$COPILOT_VER" npm > /dev/null 2>&1 && \
        echo "  ✓ Copilot manifest generated" || echo "  ✗ Copilot manifest failed"
fi
