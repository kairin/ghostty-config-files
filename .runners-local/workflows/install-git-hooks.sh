#!/bin/bash
# Install Constitutional Compliance Git Hooks
# Copies hooks from repository to .git/hooks/ and makes them executable

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOKS_DIR="$REPO_ROOT/.git/hooks"
HOOK_SOURCE_DIR="$REPO_ROOT/.runners-local/git-hooks"

echo "Installing constitutional compliance Git hooks..."
echo "Repository: $REPO_ROOT"
echo ""

# Verify we're in a Git repository
if [ ! -d "$REPO_ROOT/.git" ]; then
    echo "ERROR: Not in a Git repository"
    echo "Run this script from within the repository"
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
if [ -f "$HOOK_SOURCE_DIR/pre-commit" ]; then
    cp "$HOOK_SOURCE_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
    chmod +x "$HOOKS_DIR/pre-commit"
    echo "✓ Installed pre-commit hook"
    echo "  - AGENTS.md size validation"
    echo "  - Symlink integrity checks"
    echo "  - .nojekyll file validation"
    echo "  - Configuration validation"
else
    echo "✗ pre-commit hook not found in $HOOK_SOURCE_DIR"
fi

echo ""

# Install pre-push hook
if [ -f "$HOOK_SOURCE_DIR/pre-push" ]; then
    cp "$HOOK_SOURCE_DIR/pre-push" "$HOOKS_DIR/pre-push"
    chmod +x "$HOOKS_DIR/pre-push"
    echo "✓ Installed pre-push hook"
    echo "  - Branch naming validation"
    echo "  - Branch deletion prevention"
else
    echo "✗ pre-push hook not found in $HOOK_SOURCE_DIR"
fi

echo ""

# Install commit-msg hook
if [ -f "$HOOK_SOURCE_DIR/commit-msg" ]; then
    cp "$HOOK_SOURCE_DIR/commit-msg" "$HOOKS_DIR/commit-msg"
    chmod +x "$HOOKS_DIR/commit-msg"
    echo "✓ Installed commit-msg hook"
    echo "  - Co-authorship verification"
    echo "  - Message format validation"
    echo "  - Prohibited pattern detection"
else
    echo "✗ commit-msg hook not found in $HOOK_SOURCE_DIR"
fi

echo ""
echo "✅ Git hooks installation complete"
echo ""
echo "Test hooks by running:"
echo "  $HOOKS_DIR/pre-commit"
echo "  $HOOKS_DIR/pre-push"
echo ""
echo "To bypass hooks in emergency situations:"
echo "  git commit --no-verify -m 'Emergency fix: description'"
echo ""
echo "IMPORTANT: Document all hook bypasses in commit messages"
