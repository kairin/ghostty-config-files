#!/bin/bash
# verify_deps_ai_tools.sh - Verify dependencies for Local AI CLI Tools

MISSING=0

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "Node.js missing"
    MISSING=1
fi

# Check npm
if ! command -v npm &> /dev/null; then
    echo "npm missing"
    MISSING=1
fi

# Check gh CLI (for Copilot)
if ! command -v gh &> /dev/null; then
    echo "gh CLI missing (optional, required for GitHub Copilot)"
fi

# Check Node.js version
if command -v node &> /dev/null; then
    NODE_VER=$(node -v | grep -oP '\d+' | head -1)
    if [[ "$NODE_VER" -lt 18 ]]; then
        echo "Warning: Node.js 18+ recommended (current: $(node -v))"
    fi
fi

if [[ $MISSING -eq 1 ]]; then
    echo "Some dependencies are missing."
    exit 1
fi

echo "Dependencies verified."
