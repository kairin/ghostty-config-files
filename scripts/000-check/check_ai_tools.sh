#!/bin/bash
# check_ai_tools.sh - Check installation status of Local AI CLI Tools
# Tools: Claude Code, Gemini CLI, GitHub Copilot CLI

# Ensure npm global bin is in PATH
if command -v npm &> /dev/null; then
    NPM_BIN=$(npm config get prefix 2>/dev/null)/bin
    export PATH="$NPM_BIN:$PATH"
fi

# Also check fnm-managed Node.js
if command -v fnm &> /dev/null; then
    eval "$(fnm env --shell bash 2>/dev/null)" || true
fi

# Track installation status
CLAUDE_INSTALLED=0
GEMINI_INSTALLED=0
COPILOT_INSTALLED=0

CLAUDE_VER="-"
GEMINI_VER="-"
COPILOT_VER="-"

EXTRA=""

# Check Claude Code
if command -v claude &> /dev/null; then
    CLAUDE_INSTALLED=1
    CLAUDE_VER=$(claude --version 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "installed")
    EXTRA="$EXTRA^     \xe2\x9c\x93 Claude Code v${CLAUDE_VER}"
else
    EXTRA="$EXTRA^     \xe2\x9c\x97 Claude Code"
fi

# Check Gemini CLI
if command -v gemini &> /dev/null; then
    GEMINI_INSTALLED=1
    GEMINI_VER=$(gemini --version 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "installed")
    EXTRA="$EXTRA^     \xe2\x9c\x93 Gemini CLI v${GEMINI_VER}"
else
    EXTRA="$EXTRA^     \xe2\x9c\x97 Gemini CLI"
fi

# Check GitHub Copilot CLI (via gh extension)
if command -v gh &> /dev/null && gh extension list 2>/dev/null | grep -q "copilot"; then
    COPILOT_INSTALLED=1
    COPILOT_VER=$(gh copilot --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "installed")
    EXTRA="$EXTRA^     \xe2\x9c\x93 GitHub Copilot v${COPILOT_VER}"
else
    EXTRA="$EXTRA^     \xe2\x9c\x97 GitHub Copilot"
fi

# Calculate total installed
TOTAL_INSTALLED=$((CLAUDE_INSTALLED + GEMINI_INSTALLED + COPILOT_INSTALLED))

# Determine overall status
# Note: Use "INSTALLED" for partial too, so dashboard shows status correctly
if [[ $TOTAL_INSTALLED -eq 3 ]]; then
    STATUS="INSTALLED"
    VERSION="3/3 tools"
elif [[ $TOTAL_INSTALLED -gt 0 ]]; then
    STATUS="INSTALLED"
    VERSION="${TOTAL_INSTALLED}/3 tools"
else
    STATUS="Not Installed"
    VERSION="-"
fi

# Method (all npm-based)
if [[ $TOTAL_INSTALLED -gt 0 ]]; then
    METHOD="npm"
    LOCATION="npm global^tools:"
else
    METHOD="-"
    LOCATION="-"
fi

# Latest version info (we don't track individual latest versions for aggregate)
LATEST="-"

# Output in standard format
echo "${STATUS}|${VERSION}|${METHOD}|${LOCATION}${EXTRA}|${LATEST}"
