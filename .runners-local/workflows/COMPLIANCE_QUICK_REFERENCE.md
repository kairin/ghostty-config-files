# Constitutional Compliance Quick Reference

Fast access to compliance validation commands and troubleshooting.

## Installation

```bash
# Install all Git hooks (one-time setup)
./.runners-local/workflows/install-git-hooks.sh
```

## Validation Commands

```bash
# Complete compliance check (recommended before commits)
./.runners-local/workflows/constitutional-compliance-check.sh

# Individual validations
./.runners-local/workflows/validate-agents-size.sh      # AGENTS.md size check
./.runners-local/workflows/validate-symlinks.sh         # Symlink integrity
./.runners-local/workflows/validate-doc-links.sh        # Documentation links

# Test hooks manually
.git/hooks/pre-commit     # Test pre-commit validations
.git/hooks/pre-push       # Test pre-push validations
```

## Common Issues & Solutions

### Issue: Commit blocked by AGENTS.md size

```bash
# Check current size
./.runners-local/workflows/validate-agents-size.sh

# If in Red/Orange zone, modularize content
# Extract large sections to separate files in documentations/
```

### Issue: Symlinks broken

```bash
# Auto-repair symlinks
./.runners-local/workflows/validate-symlinks.sh

# Stage repaired symlinks
git add CLAUDE.md GEMINI.md
```

### Issue: Branch name invalid

```bash
# Get current branch name
git branch --show-current

# Rename to constitutional format
DATETIME=$(date +"%Y%m%d-%H%M%S")
git branch -m ${DATETIME}-type-short-description

# Valid types: feat, fix, docs, refactor, test, chore, perf, style, ci
```

### Issue: Missing co-authorship

```bash
# Amend last commit to add co-authorship
git commit --amend

# Add to commit message:
# Co-Authored-By: Claude <noreply@anthropic.com>
```

### Issue: docs/.nojekyll missing

```bash
# Create .nojekyll file (CRITICAL for GitHub Pages)
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "CRITICAL: Restore .nojekyll for GitHub Pages"
```

## Emergency Bypass (USE SPARINGLY)

```bash
# Bypass all hooks (emergency only)
git commit --no-verify -m "Emergency fix: detailed description"

# Bypass pre-commit only
SKIP=pre-commit git commit -m "Description"

# Bypass pre-push only
git push --no-verify
```

**IMPORTANT**: Document all hook bypasses in commit messages and conversation logs.

## Branch Naming Examples

```bash
# Feature
DATETIME=$(date +"%Y%m%d-%H%M%S")
git checkout -b ${DATETIME}-feat-new-validation-rules

# Bugfix
git checkout -b ${DATETIME}-fix-symlink-detection

# Documentation
git checkout -b ${DATETIME}-docs-compliance-guide

# Refactor
git checkout -b ${DATETIME}-refactor-hook-structure

# Performance
git checkout -b ${DATETIME}-perf-optimize-validation
```

## Commit Message Template

```
<imperative-description>

[Optional: Detailed explanation]

[Optional: Breaking changes, migration notes]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Compliance Status Zones

### AGENTS.md Size Limits
- 🟩 **Green (0-30KB)**: Excellent - no action
- 🟨 **Yellow (30-35KB)**: Warning - monitor closely
- 🟧 **Orange (35-40KB)**: Critical - modularization required
- 🚨 **Red (>40KB)**: Violation - BLOCKING commit

## Daily Maintenance

```bash
# Run daily compliance check (add to cron)
0 9 * * * /home/kkk/Apps/ghostty-config-files/.runners-local/workflows/constitutional-compliance-check.sh >> /tmp/constitutional-compliance.log 2>&1
```

## Quick Status Check

```bash
# One-liner compliance check
./.runners-local/workflows/constitutional-compliance-check.sh | grep "Overall Status"
```

## Documentation

- **Full Criteria**: `/home/kkk/Apps/ghostty-config-files/docs-setup/constitutional-compliance-criteria.md`
- **Implementation Summary**: `/home/kkk/Apps/ghostty-config-files/docs-setup/CONSTITUTIONAL_COMPLIANCE_SUMMARY.md`
- **Git Hooks README**: `/home/kkk/Apps/ghostty-config-files/.runners-local/git-hooks/README.md`
- **AGENTS.md**: Constitutional requirements source

## Support

**Repository Owner**: kkk
**Constitutional Compliance Agent**: 002-compliance
**Issue Reporting**: Document in conversation logs

---

**Last Updated**: 2025-11-17
**Version**: 1.0
