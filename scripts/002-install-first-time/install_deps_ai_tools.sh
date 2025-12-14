#!/bin/bash
# install_deps_ai_tools.sh - Install dependencies for Local AI CLI Tools

echo "Installing dependencies for AI CLI tools..."

# Check if Node.js is available (required for npm)
if ! command -v node &> /dev/null; then
    echo "Node.js is required but not installed."
    echo "Please install Node.js first from the main menu."
    exit 1
fi

# Ensure npm is available
if ! command -v npm &> /dev/null; then
    echo "npm is required but not installed."
    echo "npm should come with Node.js - please reinstall Node.js."
    exit 1
fi

# Check Node.js version (>= 18 required for modern CLI tools)
NODE_VER=$(node -v | grep -oP '\d+' | head -1)
if [[ "$NODE_VER" -lt 18 ]]; then
    echo "Warning: Node.js 18+ recommended for AI CLI tools."
    echo "Current version: $(node -v)"
fi

# gh CLI (required for GitHub Copilot)
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI (required for Copilot)..."
    # Check if gh repo is configured
    if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    fi
    sudo apt update
    sudo apt install -y gh
fi

echo "Dependencies for AI CLI tools are ready."
