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
    EXTRA="$EXTRA^     ✓ Claude Code v${CLAUDE_VER}"
else
    EXTRA="$EXTRA^     ✗ Claude Code"
fi

# Check Gemini CLI (npm package @google/gemini-cli)
if command -v gemini &> /dev/null; then
    GEMINI_INSTALLED=1
    GEMINI_VER=$(gemini --version 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "installed")
    EXTRA="$EXTRA^     ✓ Gemini CLI v${GEMINI_VER}"
else
    EXTRA="$EXTRA^     ✗ Gemini CLI"
fi

# Check GitHub Copilot CLI (npm package @github/copilot)
if command -v copilot &> /dev/null; then
    COPILOT_INSTALLED=1
    COPILOT_VER=$(copilot --version 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+\.\d+' || echo "installed")
    EXTRA="$EXTRA^     ✓ GitHub Copilot v${COPILOT_VER}"
else
    EXTRA="$EXTRA^     ✗ GitHub Copilot"
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

# Query latest versions from official sources (with timeout to avoid blocking)
# Claude Code: Query from official release manifest
# Gemini CLI: npm view @google/gemini-cli version
# GitHub Copilot: npm view @github/copilot version

CLAUDE_LATEST="-"
GEMINI_LATEST="-"
COPILOT_LATEST="-"

# Only query if npm is available (for Gemini and Copilot)
if command -v npm &> /dev/null; then
    GEMINI_LATEST=$(timeout 5 npm view @google/gemini-cli version 2>/dev/null || echo "-")
    COPILOT_LATEST=$(timeout 5 npm view @github/copilot version 2>/dev/null || echo "-")
fi

# Query Claude latest from official manifest (with timeout)
CLAUDE_LATEST=$(timeout 5 curl -sL "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/latest/manifest.json" 2>/dev/null | grep -oP '"version":\s*"\K[^"]+' || echo "-")

# Determine if any updates are available
UPDATES_AVAILABLE=0
if [[ "$CLAUDE_INSTALLED" -eq 1 && "$CLAUDE_LATEST" != "-" && "$CLAUDE_VER" != "$CLAUDE_LATEST" ]]; then
    UPDATES_AVAILABLE=1
fi
if [[ "$GEMINI_INSTALLED" -eq 1 && "$GEMINI_LATEST" != "-" && "$GEMINI_VER" != "$GEMINI_LATEST" ]]; then
    UPDATES_AVAILABLE=1
fi
if [[ "$COPILOT_INSTALLED" -eq 1 && "$COPILOT_LATEST" != "-" && "$COPILOT_VER" != "$COPILOT_LATEST" ]]; then
    UPDATES_AVAILABLE=1
fi

# Build LATEST output - show combined latest versions
if [[ "$UPDATES_AVAILABLE" -eq 1 ]]; then
    LATEST="updates"
else
    LATEST="-"
fi

# Output in standard format
echo "${STATUS}|${VERSION}|${METHOD}|${LOCATION}${EXTRA}|${LATEST}"
