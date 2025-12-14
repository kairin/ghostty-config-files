#!/bin/bash
# install_ai_tools.sh - Install Local AI CLI Tools
# Tools: Claude Code, Gemini CLI, GitHub Copilot CLI

set -e

# Ensure npm global bin is in PATH
if command -v npm &> /dev/null; then
    NPM_BIN=$(npm config get prefix 2>/dev/null)/bin
    export PATH="$NPM_BIN:$PATH"
fi

# Also ensure fnm-managed Node.js is available
if command -v fnm &> /dev/null; then
    eval "$(fnm env --shell bash 2>/dev/null)" || true
fi

echo "Installing AI CLI tools..."

# Install Claude Code
install_claude() {
    echo ""
    echo "Installing Claude Code..."
    if npm install -g @anthropic-ai/claude-code 2>/dev/null; then
        echo "Claude Code installed successfully."
    else
        echo "Failed to install Claude Code (may require API key setup after)."
    fi
}

# Install Gemini CLI
install_gemini() {
    echo ""
    echo "Installing Gemini CLI..."
    if npm install -g @google/generative-ai-cli 2>/dev/null; then
        echo "Gemini CLI installed successfully."
    else
        echo "Failed to install Gemini CLI."
    fi
}

# Install GitHub Copilot CLI (via gh extension)
install_copilot() {
    echo ""
    echo "Installing GitHub Copilot CLI..."
    if command -v gh &> /dev/null; then
        # Check if already installed
        if gh extension list 2>/dev/null | grep -q "copilot"; then
            echo "GitHub Copilot already installed, upgrading..."
            gh extension upgrade gh-copilot 2>/dev/null || true
        else
            if gh extension install github/gh-copilot 2>/dev/null; then
                echo "GitHub Copilot CLI installed successfully."
            else
                echo "Failed to install GitHub Copilot (requires gh auth login first)."
            fi
        fi
    else
        echo "GitHub CLI (gh) not installed. Skipping Copilot."
    fi
}

# Check for gum for interactive selection
if command -v gum &> /dev/null; then
    echo ""
    CHOICE=$(gum choose --header "Select AI tools to install:" \
        "All (Claude + Gemini + Copilot)" \
        "Claude Code only" \
        "Gemini CLI only" \
        "GitHub Copilot only" \
        "Cancel")

    case "$CHOICE" in
        "All (Claude + Gemini + Copilot)")
            install_claude
            install_gemini
            install_copilot
            ;;
        "Claude Code only")
            install_claude
            ;;
        "Gemini CLI only")
            install_gemini
            ;;
        "GitHub Copilot only")
            install_copilot
            ;;
        "Cancel")
            echo "Installation cancelled."
            exit 0
            ;;
    esac
else
    # Non-interactive: install all
    install_claude
    install_gemini
    install_copilot
fi

echo ""
echo "AI CLI tools installation complete."
echo ""
echo "Next steps:"
echo "  - Claude Code: Run 'claude' and follow authentication prompts"
echo "  - Gemini CLI: Set GOOGLE_API_KEY environment variable"
echo "  - Copilot: Run 'gh auth login' then 'gh copilot'"
