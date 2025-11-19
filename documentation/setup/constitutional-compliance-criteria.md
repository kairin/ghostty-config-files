# Constitutional Compliance Criteria

> Validation checkpoints and quality gates for constitutional Git workflow compliance

**Last Updated**: 2025-11-17
**Status**: ACTIVE - MANDATORY COMPLIANCE
**Version**: 1.0

## Overview

This document defines the validation criteria, quality gates, and compliance checkpoints for all Git operations, commits, and deployments in the ghostty-config-files repository. These criteria enforce the constitutional requirements defined in AGENTS.md and ensure repository integrity.

## 1. Branch Management Validation

### 1.1 Branch Naming Pattern Validation

**MANDATORY Format**: `YYYYMMDD-HHMMSS-type-short-description`

**Validation Rules**:
```bash
# Valid branch name pattern
^[0-9]{8}-[0-9]{6}-(feat|fix|docs|refactor|test|chore|perf|style|ci)-[a-z0-9-]+$

# Examples:
✅ 20251117-143000-feat-context-menu-integration
✅ 20251117-143515-fix-performance-optimization
✅ 20251117-144030-docs-agents-enhancement
✅ 20251117-145000-refactor-ci-pipeline
✅ 20251117-150000-test-validation-suite

❌ feature-branch                    # Missing timestamp
❌ 20251117-feat-description         # Missing time component
❌ 20251117-143000-feature-test      # Invalid type (use 'feat')
❌ 20251117-143000-FEAT-test         # Uppercase not allowed
❌ 20251117-143000-feat-Test_Case    # Underscores not allowed
```

**Automated Validation**:
```bash
#!/bin/bash
# Branch name validator (to be integrated in pre-push hook)
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
PATTERN='^[0-9]{8}-[0-9]{6}-(feat|fix|docs|refactor|test|chore|perf|style|ci)-[a-z0-9-]+$'

if [[ ! "$BRANCH_NAME" =~ $PATTERN ]] && [[ "$BRANCH_NAME" != "main" ]]; then
    echo "ERROR: Branch name does not follow constitutional format"
    echo "Expected: YYYYMMDD-HHMMSS-type-short-description"
    echo "Got: $BRANCH_NAME"
    exit 1
fi
```

**Valid Branch Types**:
- `feat`: New features or significant enhancements
- `fix`: Bug fixes and corrections
- `docs`: Documentation updates only
- `refactor`: Code restructuring without behavior change
- `test`: Test additions or modifications
- `chore`: Maintenance tasks, dependency updates
- `perf`: Performance improvements
- `style`: Code formatting, whitespace changes
- `ci`: CI/CD pipeline and workflow changes

### 1.2 Branch Preservation Rules

**CRITICAL**: Branch deletion is PROHIBITED without explicit user permission.

**Validation Checkpoints**:
```bash
# Pre-delete validation (to be integrated in Git hooks)
#!/bin/bash
# Prevent accidental branch deletion

if [[ "$1" == "branch" ]] && [[ "$2" == "-d" || "$2" == "-D" ]]; then
    echo "CONSTITUTIONAL VIOLATION: Branch deletion is prohibited"
    echo "All branches contain valuable configuration history"
    echo "Contact repository owner for explicit permission"
    exit 1
fi
```

**Protected Operations**:
- `git branch -d <branch>` - BLOCKED
- `git branch -D <branch>` - BLOCKED
- `git push origin --delete <branch>` - BLOCKED

**Allowed Operations**:
- `git merge <branch> --no-ff` - ALLOWED
- `git checkout <branch>` - ALLOWED
- `git push -u origin <branch>` - ALLOWED

### 1.3 Merge Strategy Validation

**MANDATORY**: All merges must use `--no-ff` (no fast-forward) to preserve history.

**Validation Rules**:
```bash
# Pre-merge validation
#!/bin/bash
# Ensure no-fast-forward merges

if git merge-base --is-ancestor "$BRANCH" main; then
    # Fast-forward merge possible - reject
    echo "ERROR: Fast-forward merge detected"
    echo "Use: git merge $BRANCH --no-ff"
    exit 1
fi
```

**Constitutional Merge Workflow**:
```bash
# CORRECT workflow
git checkout main
git merge feature-branch --no-ff -m "Merge feature: description"

# INCORRECT workflows (REJECTED)
git merge feature-branch              # Missing --no-ff
git merge feature-branch --ff-only    # Explicitly fast-forward
git rebase feature-branch             # Rewriting history prohibited
```

## 2. Commit Message Validation

### 2.1 Format Requirements

**MANDATORY Structure**:
```
<imperative-description>

[Optional: Detailed explanation of changes]

[Optional: Breaking changes, migration notes]

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Validation Rules**:
```bash
#!/bin/bash
# Commit message validator (pre-commit hook)

COMMIT_MSG_FILE="$1"
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

# Check for mandatory co-authorship
if ! grep -q "Co-Authored-By: Claude" "$COMMIT_MSG_FILE"; then
    echo "ERROR: Missing mandatory co-authorship"
    echo "Add: Co-Authored-By: Claude <noreply@anthropic.com>"
    exit 1
fi

# Check for Claude Code attribution
if ! grep -q "Generated with \[Claude Code\]" "$COMMIT_MSG_FILE"; then
    echo "WARNING: Missing Claude Code attribution"
    echo "Consider adding: 🤖 Generated with [Claude Code](https://claude.ai/code)"
fi

# Check subject line length (recommended <50 chars)
SUBJECT=$(head -n1 "$COMMIT_MSG_FILE")
if [ ${#SUBJECT} -gt 72 ]; then
    echo "WARNING: Subject line exceeds 72 characters"
    echo "Consider shortening for better Git log readability"
fi
```

### 2.2 Co-Authorship Requirements

**MANDATORY for AI-assisted commits**:
```
Co-Authored-By: Claude <noreply@anthropic.com>
```

**Optional additional co-authors**:
```
Co-Authored-By: Human Name <human@email.com>
Co-Authored-By: Gemini <noreply@google.com>
```

### 2.3 Prohibited Commit Patterns

**BLOCKED commit messages**:
```bash
# Empty or minimal commits
❌ "update"
❌ "fix"
❌ "wip"
❌ "temp"
❌ "test"

# Missing context
❌ "Update README"  # What was updated? Why?
❌ "Fix bug"        # Which bug? How?

# All-caps
❌ "FIX CRITICAL BUG"  # Use sentence case

# Inappropriate content
❌ Commits with profanity
❌ Commits with sensitive data references
```

**REQUIRED commit messages**:
```bash
✅ "Add Context7 MCP integration for up-to-date documentation"
✅ "Fix branch naming validation in pre-push Git hook"
✅ "Update AGENTS.md to document constitutional compliance criteria"
✅ "Refactor local CI/CD workflow for improved performance"
```

## 3. Documentation Validation

### 3.1 Symlink Integrity Checks

**CRITICAL**: CLAUDE.md and GEMINI.md must be symlinks to AGENTS.md

**Validation Script**:
```bash
#!/bin/bash
# Symlink integrity validator

validate_symlink() {
    local LINK=$1
    local TARGET=$2

    if [ ! -L "$LINK" ]; then
        echo "ERROR: $LINK is not a symlink"
        return 1
    fi

    if [ "$(readlink -f $LINK)" != "$(readlink -f $TARGET)" ]; then
        echo "ERROR: $LINK does not point to $TARGET"
        return 1
    fi

    echo "✓ $LINK correctly linked to $TARGET"
    return 0
}

# Validate all required symlinks
validate_symlink "CLAUDE.md" "AGENTS.md"
validate_symlink "GEMINI.md" "AGENTS.md"
```

**Repair Script**:
```bash
#!/bin/bash
# Symlink repair (run if validation fails)

rm -f CLAUDE.md GEMINI.md
ln -s AGENTS.md CLAUDE.md
ln -s AGENTS.md GEMINI.md
echo "✓ Symlinks restored"
```

### 3.2 AGENTS.md Size Limits

**CRITICAL**: AGENTS.md must stay under 40KB for optimal LLM processing

**Validation Thresholds**:
- Green Zone (Excellent): 0-30KB - No action required
- Yellow Zone (Warning): 30-35KB - Proactive modularization recommended
- Orange Zone (Critical): 35-40KB - Modularization required
- Red Zone (Violation): >40KB - Emergency modularization required

**Automated Size Check**:
```bash
#!/bin/bash
# AGENTS.md size validator

AGENTS_FILE="AGENTS.md"
AGENTS_SIZE=$(stat -c%s "$AGENTS_FILE" 2>/dev/null || stat -f%z "$AGENTS_FILE")
AGENTS_KB=$((AGENTS_SIZE / 1024))

echo "AGENTS.md Current Size: ${AGENTS_KB}KB"

if [ $AGENTS_KB -gt 40 ]; then
    echo "🚨 RED ZONE: Size violation (${AGENTS_KB}KB > 40KB)"
    echo "BLOCKING COMMIT: Emergency modularization required"
    exit 1
elif [ $AGENTS_KB -gt 35 ]; then
    echo "⚠️ ORANGE ZONE: Critical size (${AGENTS_KB}KB)"
    echo "WARNING: Modularization required before next commit"
    exit 0  # Allow commit but warn
elif [ $AGENTS_KB -gt 30 ]; then
    echo "⚡ YELLOW ZONE: Warning size (${AGENTS_KB}KB)"
    echo "RECOMMENDATION: Proactive modularization recommended"
    exit 0
else
    echo "✅ GREEN ZONE: Size compliant (${AGENTS_KB}KB)"
    exit 0
fi
```

### 3.3 Cross-Reference Validation

**MANDATORY**: All internal links must resolve to valid files

**Link Validator**:
```bash
#!/bin/bash
# Documentation link validator

validate_markdown_links() {
    local FILE=$1
    local BROKEN_LINKS=0

    # Extract all markdown links
    grep -o '\[.*\](.*\.md)' "$FILE" | while read link; do
        # Extract file path
        LINKED_FILE=$(echo "$link" | sed -n 's/.*(\(.*\))/\1/p')

        # Check if file exists
        if [ -f "$LINKED_FILE" ]; then
            echo "✓ Valid link: $LINKED_FILE"
        else
            echo "✗ Broken link: $LINKED_FILE"
            BROKEN_LINKS=$((BROKEN_LINKS + 1))
        fi
    done

    if [ $BROKEN_LINKS -gt 0 ]; then
        echo "ERROR: Found $BROKEN_LINKS broken links in $FILE"
        return 1
    fi

    return 0
}

# Validate all documentation files
validate_markdown_links "AGENTS.md"
validate_markdown_links "README.md"
validate_markdown_links "docs-setup/context7-mcp.md"
validate_markdown_links "docs-setup/github-mcp.md"
```

### 3.4 .nojekyll File Validation

**CRITICAL**: docs/.nojekyll must exist for GitHub Pages

**Validator**:
```bash
#!/bin/bash
# .nojekyll file validator (CRITICAL for GitHub Pages)

NOJEKYLL_FILE="docs/.nojekyll"

if [ ! -f "$NOJEKYLL_FILE" ]; then
    echo "🚨 CRITICAL ERROR: docs/.nojekyll is missing"
    echo "This file is REQUIRED for GitHub Pages asset loading"
    echo "Without it, ALL CSS/JS assets will return 404 errors"
    echo ""
    echo "Creating file now..."
    touch "$NOJEKYLL_FILE"
    git add "$NOJEKYLL_FILE"
    echo "✓ docs/.nojekyll created and staged"
    echo ""
    echo "IMPORTANT: Commit this file immediately:"
    echo "git commit -m 'CRITICAL: Restore .nojekyll for GitHub Pages'"
    exit 1
fi

echo "✓ docs/.nojekyll exists"
exit 0
```

## 4. Quality Gate Definitions

### 4.1 Pre-Commit Gates (LOCAL VALIDATION)

**BLOCKING conditions** (commit rejected):
1. AGENTS.md size exceeds 40KB
2. Symlinks broken (CLAUDE.md, GEMINI.md)
3. Commit message missing co-authorship
4. Configuration validation fails (ghostty +show-config)
5. docs/.nojekyll file missing

**WARNING conditions** (commit allowed with warning):
1. AGENTS.md size 35-40KB
2. Commit message lacks Claude Code attribution
3. Branch name doesn't follow convention (if on feature branch)

**Pre-Commit Hook Script**:
```bash
#!/bin/bash
# .git/hooks/pre-commit - Constitutional compliance validation

set -e  # Exit on first error

echo "Running constitutional compliance checks..."

# 1. AGENTS.md size validation (BLOCKING)
AGENTS_SIZE=$(stat -c%s "AGENTS.md" 2>/dev/null || stat -f%z "AGENTS.md")
AGENTS_KB=$((AGENTS_SIZE / 1024))
if [ $AGENTS_KB -gt 40 ]; then
    echo "🚨 BLOCKING: AGENTS.md exceeds 40KB (${AGENTS_KB}KB)"
    exit 1
fi

# 2. Symlink validation (BLOCKING)
if [ ! -L "CLAUDE.md" ] || [ ! -L "GEMINI.md" ]; then
    echo "🚨 BLOCKING: Documentation symlinks broken"
    exit 1
fi

# 3. .nojekyll validation (BLOCKING)
if [ ! -f "docs/.nojekyll" ]; then
    echo "🚨 BLOCKING: docs/.nojekyll missing (CRITICAL for GitHub Pages)"
    touch "docs/.nojekyll"
    git add "docs/.nojekyll"
    echo "✓ Created docs/.nojekyll - commit will proceed"
fi

# 4. Configuration validation (BLOCKING)
if ! ghostty +show-config > /dev/null 2>&1; then
    echo "🚨 BLOCKING: Ghostty configuration invalid"
    exit 1
fi

echo "✅ All constitutional compliance checks passed"
exit 0
```

### 4.2 Pre-Push Gates (BRANCH VALIDATION)

**BLOCKING conditions** (push rejected):
1. Branch name doesn't follow YYYYMMDD-HHMMSS-type-description pattern
2. Attempting to delete a branch
3. Attempting to force push to main

**Pre-Push Hook Script**:
```bash
#!/bin/bash
# .git/hooks/pre-push - Branch validation

BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
PATTERN='^[0-9]{8}-[0-9]{6}-(feat|fix|docs|refactor|test|chore|perf|style|ci)-[a-z0-9-]+$'

# Allow main branch
if [[ "$BRANCH_NAME" == "main" ]]; then
    exit 0
fi

# Validate feature branch naming
if [[ ! "$BRANCH_NAME" =~ $PATTERN ]]; then
    echo "🚨 BLOCKING: Branch name doesn't follow constitutional format"
    echo "Expected: YYYYMMDD-HHMMSS-type-short-description"
    echo "Got: $BRANCH_NAME"
    exit 1
fi

echo "✅ Branch name validation passed"
exit 0
```

### 4.3 Pre-Deployment Gates (CI/CD VALIDATION)

**BLOCKING conditions** (deployment rejected):
1. Local CI/CD workflow not run
2. Any CI/CD stage failed
3. GitHub Actions minutes consumed
4. Astro build failed
5. Performance benchmarks below thresholds

**Deployment Validation Script**:
```bash
#!/bin/bash
# Pre-deployment constitutional validation

set -e

echo "Running pre-deployment validation..."

# 1. Local CI/CD execution check
LATEST_WORKFLOW_LOG=$(ls -t .runners-local/logs/workflow-*.log 2>/dev/null | head -n1)
if [ -z "$LATEST_WORKFLOW_LOG" ]; then
    echo "🚨 BLOCKING: No local CI/CD workflow logs found"
    echo "Run: ./.runners-local/workflows/gh-workflow-local.sh all"
    exit 1
fi

# 2. Check workflow success
if ! grep -q "SUCCESS" "$LATEST_WORKFLOW_LOG"; then
    echo "🚨 BLOCKING: Local CI/CD workflow failed"
    echo "Review: $LATEST_WORKFLOW_LOG"
    exit 1
fi

# 3. GitHub Actions cost verification
ACTIONS_USAGE=$(gh api user/settings/billing/actions --jq '.total_minutes_used')
if [ "$ACTIONS_USAGE" -gt 0 ]; then
    echo "⚠️ WARNING: GitHub Actions minutes consumed: $ACTIONS_USAGE"
    echo "This violates zero-cost operation requirement"
fi

# 4. Astro build validation (if website changes)
if git diff --name-only HEAD~1 | grep -q "^website/"; then
    if [ ! -f "docs/index.html" ]; then
        echo "🚨 BLOCKING: Astro build output missing"
        exit 1
    fi
fi

echo "✅ Pre-deployment validation passed"
exit 0
```

### 4.4 Automatic vs Manual Gates

**Automatic Gates** (enforced by Git hooks):
- Pre-commit: AGENTS.md size, symlinks, .nojekyll, config validation
- Pre-push: Branch naming, branch deletion prevention
- Pre-receive: Force push prevention on main

**Manual Gates** (require human verification):
- Code review for significant changes
- Security review for credential-related changes
- Performance review for CI/CD modifications
- User acceptance for UI/UX changes

## 5. Git Hook Integration

### 5.1 Installation Script

**Script**: `.runners-local/workflows/install-git-hooks.sh`

```bash
#!/bin/bash
# Install constitutional compliance Git hooks

set -e

HOOKS_DIR=".git/hooks"
HOOK_SOURCE_DIR=".runners-local/git-hooks"

echo "Installing constitutional compliance Git hooks..."

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Install pre-commit hook
cp "$HOOK_SOURCE_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
echo "✓ Installed pre-commit hook"

# Install pre-push hook
cp "$HOOK_SOURCE_DIR/pre-push" "$HOOKS_DIR/pre-push"
chmod +x "$HOOKS_DIR/pre-push"
echo "✓ Installed pre-push hook"

# Install commit-msg hook
cp "$HOOK_SOURCE_DIR/commit-msg" "$HOOKS_DIR/commit-msg"
chmod +x "$HOOKS_DIR/commit-msg"
echo "✓ Installed commit-msg hook"

echo "✅ All Git hooks installed successfully"
echo ""
echo "Hooks installed:"
echo "  - pre-commit: AGENTS.md size, symlinks, config validation"
echo "  - pre-push: Branch naming validation"
echo "  - commit-msg: Co-authorship verification"
```

### 5.2 Hook Source Files Location

**Directory**: `.runners-local/git-hooks/` (committed to repository)

```
.runners-local/git-hooks/
├── pre-commit           # Size, symlink, config validation
├── pre-push             # Branch naming validation
├── commit-msg           # Co-authorship verification
└── README.md            # Hook documentation
```

### 5.3 Hook Bypass (EMERGENCY ONLY)

**Emergency bypass** (use only when absolutely necessary):
```bash
# Bypass all hooks for emergency fix
git commit --no-verify -m "Emergency fix: description"

# Bypass only pre-commit hook
SKIP=pre-commit git commit -m "Description"

# Bypass only pre-push hook
git push --no-verify
```

**IMPORTANT**: Bypassing hooks violates constitutional compliance. Use only for:
- Emergency hotfixes
- Fixing broken hooks
- Repository recovery operations

Document all hook bypasses in commit messages and conversation logs.

## 6. Compliance Monitoring

### 6.1 Daily Compliance Checks

**Automated daily validation** (add to cron):
```bash
#!/bin/bash
# Daily constitutional compliance check

REPO_PATH="/home/kkk/Apps/ghostty-config-files"
cd "$REPO_PATH"

echo "=== Daily Constitutional Compliance Check ==="
echo "Date: $(date)"
echo ""

# Check AGENTS.md size
AGENTS_SIZE=$(stat -c%s "AGENTS.md" 2>/dev/null || stat -f%z "AGENTS.md")
AGENTS_KB=$((AGENTS_SIZE / 1024))
echo "AGENTS.md size: ${AGENTS_KB}KB (limit: 40KB)"

# Check symlinks
if [ -L "CLAUDE.md" ] && [ -L "GEMINI.md" ]; then
    echo "✓ Symlinks intact"
else
    echo "✗ Symlinks broken - REPAIR NEEDED"
fi

# Check .nojekyll
if [ -f "docs/.nojekyll" ]; then
    echo "✓ docs/.nojekyll exists"
else
    echo "✗ docs/.nojekyll missing - CRITICAL"
fi

# Check branch count
BRANCH_COUNT=$(git branch -r | wc -l)
echo "Remote branches: $BRANCH_COUNT (should only increase)"

# Check latest commit compliance
LATEST_COMMIT_MSG=$(git log -1 --pretty=%B)
if echo "$LATEST_COMMIT_MSG" | grep -q "Co-Authored-By: Claude"; then
    echo "✓ Latest commit has co-authorship"
else
    echo "⚠️ Latest commit missing co-authorship"
fi

echo ""
echo "=== End of Daily Check ==="
```

**Cron schedule**:
```bash
# Add to crontab -e
0 9 * * * /home/kkk/Apps/ghostty-config-files/.runners-local/workflows/daily-compliance-check.sh >> /tmp/constitutional-compliance.log 2>&1
```

### 6.2 Compliance Metrics

**Track these metrics over time**:
1. AGENTS.md size trend (KB)
2. Number of branches (should only increase)
3. Commit message compliance rate (% with co-authorship)
4. GitHub Actions minutes consumed (should be 0)
5. Documentation link integrity (% valid links)
6. Hook bypass frequency (should be minimal)

**Metrics Dashboard** (generate weekly):
```bash
#!/bin/bash
# Generate weekly compliance metrics report

WEEK_START=$(date -d "7 days ago" +%Y-%m-%d)
WEEK_END=$(date +%Y-%m-%d)

echo "=== Constitutional Compliance Metrics ==="
echo "Period: $WEEK_START to $WEEK_END"
echo ""

# Commits this week
COMMIT_COUNT=$(git log --since="$WEEK_START" --until="$WEEK_END" --oneline | wc -l)
echo "Commits this week: $COMMIT_COUNT"

# Commits with co-authorship
COMPLIANT_COMMITS=$(git log --since="$WEEK_START" --until="$WEEK_END" --grep="Co-Authored-By: Claude" --oneline | wc -l)
COMPLIANCE_RATE=$(awk "BEGIN {printf \"%.1f\", ($COMPLIANT_COMMITS/$COMMIT_COUNT)*100}")
echo "Co-authorship compliance: $COMPLIANCE_RATE%"

# Branches created
NEW_BRANCHES=$(git reflog --since="$WEEK_START" --until="$WEEK_END" | grep "checkout: moving from" | wc -l)
echo "New branches created: $NEW_BRANCHES"

# AGENTS.md size
AGENTS_SIZE=$(stat -c%s "AGENTS.md" 2>/dev/null || stat -f%z "AGENTS.md")
AGENTS_KB=$((AGENTS_SIZE / 1024))
echo "Current AGENTS.md size: ${AGENTS_KB}KB"

echo ""
echo "=== End of Metrics Report ==="
```

## 7. Enforcement Strategy

### 7.1 Enforcement Levels

**Level 1: Preventive (Git Hooks)**
- Automatically block non-compliant commits/pushes
- Most effective enforcement mechanism
- No human intervention required

**Level 2: Detective (Daily Checks)**
- Identify compliance drift over time
- Detect issues that bypassed hooks
- Generate reports for review

**Level 3: Corrective (Manual Review)**
- Human review for complex violations
- Policy updates based on patterns
- Training and documentation improvements

### 7.2 Violation Response

**For each violation type**:

1. **AGENTS.md size violation**:
   - Block commit immediately
   - Trigger modularization workflow
   - Document sections to extract

2. **Symlink breakage**:
   - Block commit immediately
   - Auto-repair symlinks
   - Commit repair separately

3. **Branch naming violation**:
   - Block push immediately
   - Provide correct format example
   - Rename branch with user confirmation

4. **Missing co-authorship**:
   - Block commit immediately
   - Amend commit message
   - Re-run commit

5. **Hook bypass**:
   - Log bypass event
   - Notify repository owner
   - Require justification in commit message

## 8. Future Enhancements

### 8.1 Planned Validations

- Automated performance regression detection
- Dependency vulnerability scanning
- Code quality metrics enforcement
- Documentation coverage requirements

### 8.2 Integration Points

- CI/CD pipeline status checks
- GitHub Actions workflow validation
- Context7 MCP best practices queries
- Automated compliance reporting

## 9. Quick Reference

### 9.1 Command Quick Reference

```bash
# Install Git hooks
./.runners-local/workflows/install-git-hooks.sh

# Validate AGENTS.md size
./.runners-local/workflows/validate-agents-size.sh

# Check symlink integrity
./.runners-local/workflows/validate-symlinks.sh

# Validate all documentation links
./.runners-local/workflows/validate-doc-links.sh

# Run complete compliance check
./.runners-local/workflows/constitutional-compliance-check.sh

# Generate compliance report
./.runners-local/workflows/generate-compliance-report.sh
```

### 9.2 Troubleshooting

**Problem**: Commit blocked by AGENTS.md size
**Solution**: Run modularization workflow or reduce content

**Problem**: Symlinks broken
**Solution**: Run `./.runners-local/workflows/repair-symlinks.sh`

**Problem**: Branch name invalid
**Solution**: Rename branch: `git branch -m old-name new-name`

**Problem**: Missing co-authorship
**Solution**: Amend commit: `git commit --amend`

## 10. Contact and Support

**Repository Owner**: kkk
**Constitutional Compliance Agent**: constitutional-compliance-agent
**Documentation**: AGENTS.md, CLAUDE.md, GEMINI.md
**Support Files**: `.runners-local/workflows/*`

---

**CRITICAL**: These compliance criteria are MANDATORY and NON-NEGOTIABLE. All Git operations must pass these validations. Violations will be blocked automatically by Git hooks or detected in daily compliance checks.

**Version**: 1.0
**Last Updated**: 2025-11-17
**Review Cycle**: Monthly
**Next Review**: 2025-12-17
