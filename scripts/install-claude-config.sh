#!/bin/bash
# Install Claude Code configuration (skills and agents) to user-level directories
#
# This script copies:
# - Skills (5) from .claude/skill-sources/ to ~/.claude/commands/
# - Agents (65) from .claude/agent-sources/ to ~/.claude/agents/
#
# Usage: ./scripts/install-claude-config.sh
#
# Features:
# - Idempotent (safe to run multiple times)
# - Removes deprecated configuration files
# - Preserves existing user configuration (only overwrites project files)

set -uo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Paths
PROJECT_SKILLS="$PROJECT_ROOT/.claude/skill-sources"
PROJECT_AGENTS="$PROJECT_ROOT/.claude/agent-sources"
USER_SKILLS="$HOME/.claude/commands"
USER_AGENTS="$HOME/.claude/agents"

# Skills to install (numbered 001-XX for workflow ordering)
SKILLS=(
    "001-01-health-check.md"
    "001-02-deploy-site.md"
    "001-03-git-sync.md"
    "001-04-full-workflow.md"
    "001-05-issue-cleanup.md"
)

# Deprecated skills to remove (old naming conventions)
DEPRECATED_SKILLS=(
    "full-git-workflow.md"
    "health-check.md"
    "deploy-site.md"
    "git-sync.md"
    "full-workflow.md"
    "001-health-check.md"
    "001-deploy-site.md"
    "001-git-sync.md"
    "001-full-workflow.md"
    "001-issue-cleanup.md"
)

echo "=================================="
echo "Claude Code Configuration Installer"
echo "=================================="
echo ""

# Step 1: Verify source directories exist
if [ ! -d "$PROJECT_SKILLS" ]; then
    echo -e "${RED}ERROR: Skills source directory not found: $PROJECT_SKILLS${NC}"
    exit 1
fi

if [ ! -d "$PROJECT_AGENTS" ]; then
    echo -e "${RED}ERROR: Agents source directory not found: $PROJECT_AGENTS${NC}"
    exit 1
fi

# Step 2: Create user directories if needed
if [ ! -d "$USER_SKILLS" ]; then
    echo -e "${YELLOW}Creating user skills directory: $USER_SKILLS${NC}"
    mkdir -p "$USER_SKILLS"
fi

if [ ! -d "$USER_AGENTS" ]; then
    echo -e "${YELLOW}Creating user agents directory: $USER_AGENTS${NC}"
    mkdir -p "$USER_AGENTS"
fi

# Step 3: Remove deprecated skills
echo "Checking for deprecated skills..."
for skill in "${DEPRECATED_SKILLS[@]}"; do
    if [ -f "$USER_SKILLS/$skill" ]; then
        echo -e "${YELLOW}Removing deprecated: $skill${NC}"
        rm "$USER_SKILLS/$skill"
    fi
done

# Step 4: Install skills
echo ""
echo "Installing skills..."
SKILLS_INSTALLED=0
SKILLS_SKIPPED=0

for skill in "${SKILLS[@]}"; do
    SOURCE="$PROJECT_SKILLS/$skill"
    DEST="$USER_SKILLS/$skill"

    if [ ! -f "$SOURCE" ]; then
        echo -e "${YELLOW}SKIP: $skill (not found in project)${NC}"
        SKILLS_SKIPPED=$((SKILLS_SKIPPED + 1))
        continue
    fi

    # Copy skill (overwrite if exists)
    cp "$SOURCE" "$DEST"
    echo -e "${GREEN}INSTALLED: $skill${NC}"
    SKILLS_INSTALLED=$((SKILLS_INSTALLED + 1))
done

# Step 5: Install agents
echo ""
echo "Installing agents..."
AGENTS_INSTALLED=0
AGENTS_SKIPPED=0

for agent in "$PROJECT_AGENTS"/*.md; do
    if [ ! -f "$agent" ]; then
        continue
    fi

    filename=$(basename "$agent")
    DEST="$USER_AGENTS/$filename"

    # Copy agent (overwrite if exists)
    cp "$agent" "$DEST"
    AGENTS_INSTALLED=$((AGENTS_INSTALLED + 1))
done

echo -e "${GREEN}INSTALLED: $AGENTS_INSTALLED agents${NC}"

# Step 6: Summary
echo ""
echo "=================================="
echo "Installation Complete"
echo "=================================="
echo ""
echo "Skills installed: $SKILLS_INSTALLED"
echo "Agents installed: $AGENTS_INSTALLED"
echo ""
echo "User directories:"
echo "  Skills:  $USER_SKILLS"
echo "  Agents:  $USER_AGENTS"
echo ""
echo "To use skills, type the skill name in Claude Code (e.g., /001-01-health-check)"
echo ""
