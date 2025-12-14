#!/bin/bash
# verify_deps_ai_tools.sh - Verify dependencies for Local AI CLI Tools
# Claude Code: uses curl (no Node.js needed)
# Gemini CLI & GitHub Copilot: require Node.js (installed via fnm)

# Ensure fnm environment is loaded
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd 2>/dev/null)" || true
fi

# Ensure npm global bin is in PATH
if command -v npm &> /dev/null; then
    NPM_BIN=$(npm config get prefix 2>/dev/null)/bin
    export PATH="$NPM_BIN:$PATH"
fi

MISSING=0

# Check curl (required for Claude Code installer)
if ! command -v curl &> /dev/null; then
    echo "curl missing (required for Claude Code)"
    MISSING=1
fi

# Check Node.js (required for Gemini CLI and GitHub Copilot)
if ! command -v node &> /dev/null; then
    echo "Node.js missing (required for Gemini CLI and GitHub Copilot)"
    MISSING=1
fi

# Check npm
if ! command -v npm &> /dev/null; then
    echo "npm missing (required for Gemini CLI and GitHub Copilot)"
    MISSING=1
fi

if [[ $MISSING -eq 1 ]]; then
    echo "Some dependencies are missing."
    echo "Please install Node.js first from the main menu."
    exit 1
fi

# Show versions
NODE_VER=$(node -v)
NPM_VER=$(npm -v)
echo "Dependencies verified:"
echo "  curl: $(curl --version | head -n 1 | cut -d' ' -f1-2)"
echo "  Node.js: $NODE_VER"
echo "  npm: $NPM_VER"
