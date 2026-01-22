#!/usr/bin/env bash
# Uninstall script for Claude Config (SpecKit skills + agents)

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
COMMANDS_DIR="${CLAUDE_DIR}/commands"
AGENTS_DIR="${CLAUDE_DIR}/agents"

echo "Removing Claude Config (SpecKit skills + agents)..."

# Remove all skills (commands directory .md files)
if [[ -d "$COMMANDS_DIR" ]]; then
    skills_count=$(find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l)
    if [[ "$skills_count" -gt 0 ]]; then
        find "$COMMANDS_DIR" -maxdepth 1 -name "*.md" -delete 2>/dev/null || true
        echo "✓ Removed $skills_count skill file(s) from $COMMANDS_DIR"
    else
        echo "ℹ No skill files found in $COMMANDS_DIR"
    fi
else
    echo "ℹ Commands directory not found: $COMMANDS_DIR"
fi

# Remove all agents
if [[ -d "$AGENTS_DIR" ]]; then
    agents_count=$(ls -1 "$AGENTS_DIR" 2>/dev/null | wc -l)
    if [[ "$agents_count" -gt 0 ]]; then
        rm -rf "${AGENTS_DIR:?}"/*
        echo "✓ Removed $agents_count agent file(s) from $AGENTS_DIR"
    else
        echo "ℹ No agent files found in $AGENTS_DIR"
    fi
else
    echo "ℹ Agents directory not found: $AGENTS_DIR"
fi

echo ""
echo "✓ Claude Config uninstalled successfully"
echo "  Note: Restart Claude Code for changes to take effect"
