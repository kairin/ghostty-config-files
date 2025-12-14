#!/bin/bash
# check_ai_tools.sh - Check installation status of Local AI CLI Tools
# Tools: Claude Code (curl), Gemini CLI (npm), GitHub Copilot CLI (npm)

# Ensure fnm environment is loaded
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd 2>/dev/null)" || true
fi

# Ensure npm global bin is in PATH
if command -v npm &> /dev/null; then
    NPM_BIN=$(npm config get prefix 2>/dev/null)/bin
    export PATH="$NPM_BIN:$PATH"
fi

# Track installation status
CLAUDE_INSTALLED=0
GEMINI_INSTALLED=0
COPILOT_INSTALLED=0

CLAUDE_VER="-"
GEMINI_VER="-"
COPILOT_VER="-"

EXTRA=""

# Check Claude Code (standalone binary installed via curl script)
if command -v claude &> /dev/null; then
    CLAUDE_INSTALLED=1
    CLAUDE_VER=$(claude --version 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "installed")
    EXTRA="$EXTRA^     \xe2\x9c\x93 Claude Code v${CLAUDE_VER}"
else
    EXTRA="$EXTRA^     \xe2\x9c\x97 Claude Code"
fi

# Check Gemini CLI (npm package @google/gemini-cli)
if command -v gemini &> /dev/null; then
    GEMINI_INSTALLED=1
    GEMINI_VER=$(gemini --version 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "installed")
    EXTRA="$EXTRA^     \xe2\x9c\x93 Gemini CLI v${GEMINI_VER}"
else
    EXTRA="$EXTRA^     \xe2\x9c\x97 Gemini CLI"
fi

# Check GitHub Copilot CLI (npm package @github/copilot)
if command -v copilot &> /dev/null; then
    COPILOT_INSTALLED=1
    COPILOT_VER=$(copilot --version 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "installed")
    EXTRA="$EXTRA^     \xe2\x9c\x93 GitHub Copilot v${COPILOT_VER}"
else
    EXTRA="$EXTRA^     \xe2\x9c\x97 GitHub Copilot"
fi

# Calculate total installed
TOTAL_INSTALLED=$((CLAUDE_INSTALLED + GEMINI_INSTALLED + COPILOT_INSTALLED))

# Determine overall status
if [[ $TOTAL_INSTALLED -eq 3 ]]; then
    STATUS="INSTALLED"
    VERSION="3/3 tools"
elif [[ $TOTAL_INSTALLED -gt 0 ]]; then
    STATUS="INSTALLED"
    VERSION="${TOTAL_INSTALLED}/3 tools"
else
    STATUS="NOT_INSTALLED"
    VERSION="-"
fi

# Method description
if [[ $TOTAL_INSTALLED -gt 0 ]]; then
    METHOD="mixed"
    LOCATION="curl+npm^tools:"
else
    METHOD="-"
    LOCATION="-"
fi

# Aggregate tools: no single "latest version" - disable update detection
# Individual versions shown in details section with checkmarks
LATEST="-"

# Output in standard format
echo "${STATUS}|${VERSION}|${METHOD}|${LOCATION}${EXTRA}|${LATEST}"
