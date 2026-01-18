#!/bin/bash
# Install Claude Code workflow skills to user-level directory
#
# This script copies skills from the project's .claude/commands/ to
# ~/.claude/commands/ for global availability across all projects.
#
# Usage: ./scripts/install-claude-skills.sh
#
# Features:
# - Idempotent (safe to run multiple times)
# - Removes deprecated full-git-workflow.md
# - Preserves existing user skills (only overwrites project skills)

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
PROJECT_SKILLS="$PROJECT_ROOT/.claude/commands"
USER_SKILLS="$HOME/.claude/commands"

# Skills to install
SKILLS=(
    "001-health-check.md"
    "001-deploy-site.md"
    "001-git-sync.md"
    "001-full-workflow.md"
)

# Deprecated skills to remove (old names without 001- prefix)
DEPRECATED=(
    "full-git-workflow.md"
    "health-check.md"
    "deploy-site.md"
    "git-sync.md"
    "full-workflow.md"
)

echo "=================================="
echo "Claude Code Skills Installer"
echo "=================================="
echo ""

# Step 1: Verify source directory exists
if [ ! -d "$PROJECT_SKILLS" ]; then
    echo -e "${RED}ERROR: Source directory not found: $PROJECT_SKILLS${NC}"
    exit 1
fi

# Step 2: Create user directory if needed
if [ ! -d "$USER_SKILLS" ]; then
    echo -e "${YELLOW}Creating user skills directory: $USER_SKILLS${NC}"
    mkdir -p "$USER_SKILLS"
fi

# Step 3: Remove deprecated skills
echo "Checking for deprecated skills..."
for skill in "${DEPRECATED[@]}"; do
    if [ -f "$USER_SKILLS/$skill" ]; then
        echo -e "${YELLOW}Removing deprecated: $skill${NC}"
        rm "$USER_SKILLS/$skill"
    fi
done

# Step 4: Install skills
echo ""
echo "Installing skills..."
INSTALLED=0
SKIPPED=0

for skill in "${SKILLS[@]}"; do
    SOURCE="$PROJECT_SKILLS/$skill"
    DEST="$USER_SKILLS/$skill"

    if [ ! -f "$SOURCE" ]; then
        echo -e "${YELLOW}SKIP: $skill (not found in project)${NC}"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Copy skill (overwrite if exists)
    cp "$SOURCE" "$DEST"
    echo -e "${GREEN}INSTALLED: $skill${NC}"
    INSTALLED=$((INSTALLED + 1))
done

# Step 5: Summary
echo ""
echo "=================================="
echo "Installation Complete"
echo "=================================="
echo ""
echo "Skills installed: $INSTALLED"
echo "Skills skipped:   $SKIPPED"
echo ""
echo "User skills directory: $USER_SKILLS"
echo ""
echo "Available skills:"
for skill in "${SKILLS[@]}"; do
    name="${skill%.md}"
    if [ -f "$USER_SKILLS/$skill" ]; then
        echo "  /${name}"
    fi
done
echo ""
echo "To use, type the skill name in Claude Code (e.g., /001-health-check)"
echo ""
