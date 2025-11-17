# Constitutional Compliance Git Hooks

This directory contains Git hooks that enforce constitutional compliance requirements for the ghostty-config-files repository.

## Available Hooks

### pre-commit
Validates before each commit:
- AGENTS.md size (must be <40KB)
- Symlink integrity (CLAUDE.md, GEMINI.md)
- docs/.nojekyll file existence (critical for GitHub Pages)
- Ghostty configuration validity (if config files changed)

**Blocking conditions**: Size violation, config invalid
**Auto-repair**: Symlinks, .nojekyll creation

### pre-push
Validates before each push:
- Branch naming convention (YYYYMMDD-HHMMSS-type-description)
- Prevents accidental branch deletion

**Blocking conditions**: Invalid branch name
**Note**: main branch is always allowed

### commit-msg
Validates commit message format:
- Co-authorship attribution (warning for AI commits)
- Subject line length (recommendation)
- Prohibited vague messages (blocking)

**Blocking conditions**: Vague messages (wip, temp, test, update, fix)
**Warnings**: Missing co-authorship, long subject line

## Installation

Run the installation script:
```bash
./.runners-local/workflows/install-git-hooks.sh
```

This will:
1. Copy hooks to .git/hooks/
2. Make them executable
3. Verify installation

## Manual Installation

If needed, manually install hooks:
```bash
cp .runners-local/git-hooks/pre-commit .git/hooks/pre-commit
cp .runners-local/git-hooks/pre-push .git/hooks/pre-push
cp .runners-local/git-hooks/commit-msg .git/hooks/commit-msg

chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
chmod +x .git/hooks/commit-msg
```

## Bypassing Hooks (EMERGENCY ONLY)

In rare emergency situations, you can bypass hooks:

```bash
# Bypass all hooks
git commit --no-verify -m "Emergency fix: description"

# Bypass pre-commit only
SKIP=pre-commit git commit -m "Description"

# Bypass pre-push only
git push --no-verify
```

**IMPORTANT**: Document all hook bypasses in:
- Commit message
- Conversation logs
- Compliance reports

## Testing Hooks

Test hooks without committing:

```bash
# Test pre-commit hook
.git/hooks/pre-commit

# Test pre-push hook
.git/hooks/pre-push

# Test commit-msg hook
echo "test commit message" | .git/hooks/commit-msg /dev/stdin
```

## Troubleshooting

### Hook not executing
```bash
# Check if hook is executable
ls -la .git/hooks/pre-commit

# Make executable if needed
chmod +x .git/hooks/pre-commit
```

### Hook errors
```bash
# Run hook manually to see detailed output
bash -x .git/hooks/pre-commit
```

### Disable specific hook
```bash
# Temporarily rename to disable
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled

# Re-enable
mv .git/hooks/pre-commit.disabled .git/hooks/pre-commit
```

## Maintenance

Hooks are stored in this repository directory and copied to `.git/hooks/` during installation. To update hooks:

1. Edit hook in `.runners-local/git-hooks/`
2. Test hook manually
3. Reinstall: `./.runners-local/workflows/install-git-hooks.sh`
4. Commit hook changes to repository

## Constitutional Compliance

These hooks enforce requirements from:
- AGENTS.md (NON-NEGOTIABLE REQUIREMENTS)
- docs-setup/constitutional-compliance-criteria.md (Validation criteria)

All hooks are MANDATORY for constitutional compliance.

## Version

**Version**: 1.0
**Last Updated**: 2025-11-17
**Status**: ACTIVE
