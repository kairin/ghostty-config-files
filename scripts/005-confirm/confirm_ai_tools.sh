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

# Check GitHub Copilot CLI
echo -n "GitHub Copilot: "
if command -v gh &> /dev/null && gh extension list 2>/dev/null | grep -q "copilot"; then
    VER=$(gh copilot --version 2>/dev/null | head -n 1 || echo "installed")
    echo "INSTALLED ($VER)"
    ((INSTALLED++))
else
    echo "NOT INSTALLED"
fi

echo ""
echo "Summary: $INSTALLED/$TOTAL AI tools installed."

if [[ $INSTALLED -eq 0 ]]; then
    exit 1
fi

echo ""
echo "Configuration hints:"
if command -v claude &> /dev/null; then
    echo "  Claude: Run 'claude' to authenticate with Anthropic"
fi
if command -v gemini &> /dev/null; then
    echo "  Gemini: Export GOOGLE_API_KEY in your shell profile"
fi
if command -v gh &> /dev/null && gh extension list 2>/dev/null | grep -q "copilot"; then
    echo "  Copilot: Run 'gh auth login' then 'gh copilot suggest'"
fi
