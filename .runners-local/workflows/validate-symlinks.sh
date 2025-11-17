#!/bin/bash
# Validate and repair documentation symlinks

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

echo "Validating documentation symlinks..."
echo ""

ERRORS=0

validate_symlink() {
    local LINK=$1
    local TARGET=$2

    if [ ! -L "$LINK" ]; then
        echo "✗ $LINK is not a symlink"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    LINK_TARGET=$(readlink "$LINK")
    if [ "$LINK_TARGET" != "$TARGET" ]; then
        echo "✗ $LINK points to $LINK_TARGET (expected: $TARGET)"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    echo "✓ $LINK → $TARGET (correct)"
    return 0
}

# Validate required symlinks
validate_symlink "CLAUDE.md" "AGENTS.md"
validate_symlink "GEMINI.md" "AGENTS.md"

echo ""

if [ $ERRORS -gt 0 ]; then
    echo "Found $ERRORS symlink errors"
    echo ""
    read -p "Repair symlinks automatically? (y/n) " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Repairing symlinks..."
        rm -f CLAUDE.md GEMINI.md
        ln -s AGENTS.md CLAUDE.md
        ln -s AGENTS.md GEMINI.md
        echo "✓ Symlinks repaired"
        echo ""
        echo "Stage changes with:"
        echo "  git add CLAUDE.md GEMINI.md"
        echo "  git commit -m 'Fix documentation symlinks'"
    else
        echo "Skipping repair"
        exit 1
    fi
else
    echo "✅ All symlinks are valid"
fi
