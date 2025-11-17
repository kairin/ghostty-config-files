#!/bin/bash
# Complete Constitutional Compliance Check
# Runs all validation scripts and generates compliance report

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
REPORT_DIR=".runners-local/logs/compliance"
mkdir -p "$REPORT_DIR"
REPORT_FILE="$REPORT_DIR/compliance-report-$TIMESTAMP.txt"

echo "=== Constitutional Compliance Check ===" | tee "$REPORT_FILE"
echo "Date: $(date)" | tee -a "$REPORT_FILE"
echo "Repository: $REPO_ROOT" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Track overall status
OVERALL_STATUS="COMPLIANT"
ERRORS=0
WARNINGS=0

# 1. AGENTS.md Size Validation
echo "## 1. AGENTS.md Size Validation" | tee -a "$REPORT_FILE"
if ./.runners-local/workflows/validate-agents-size.sh 2>&1 | tee -a "$REPORT_FILE"; then
    echo "✓ AGENTS.md size check passed" | tee -a "$REPORT_FILE"
else
    echo "✗ AGENTS.md size check failed" | tee -a "$REPORT_FILE"
    ERRORS=$((ERRORS + 1))
    OVERALL_STATUS="CRITICAL"
fi
echo "" | tee -a "$REPORT_FILE"

# 2. Symlink Validation
echo "## 2. Symlink Integrity" | tee -a "$REPORT_FILE"
if ./.runners-local/workflows/validate-symlinks.sh 2>&1 | tee -a "$REPORT_FILE"; then
    echo "✓ Symlink validation passed" | tee -a "$REPORT_FILE"
else
    echo "✗ Symlink validation failed" | tee -a "$REPORT_FILE"
    ERRORS=$((ERRORS + 1))
    OVERALL_STATUS="CRITICAL"
fi
echo "" | tee -a "$REPORT_FILE"

# 3. Documentation Links
echo "## 3. Documentation Link Validation" | tee -a "$REPORT_FILE"
if ./.runners-local/workflows/validate-doc-links.sh 2>&1 | tee -a "$REPORT_FILE"; then
    echo "✓ Documentation links valid" | tee -a "$REPORT_FILE"
else
    echo "✗ Documentation links validation failed" | tee -a "$REPORT_FILE"
    WARNINGS=$((WARNINGS + 1))
    if [ "$OVERALL_STATUS" = "COMPLIANT" ]; then
        OVERALL_STATUS="WARNING"
    fi
fi
echo "" | tee -a "$REPORT_FILE"

# 4. .nojekyll File Check
echo "## 4. GitHub Pages .nojekyll File" | tee -a "$REPORT_FILE"
if [ -f "docs/.nojekyll" ]; then
    echo "✓ docs/.nojekyll exists" | tee -a "$REPORT_FILE"
else
    echo "✗ docs/.nojekyll missing (CRITICAL for GitHub Pages)" | tee -a "$REPORT_FILE"
    ERRORS=$((ERRORS + 1))
    OVERALL_STATUS="CRITICAL"
fi
echo "" | tee -a "$REPORT_FILE"

# 5. Git Hooks Installation
echo "## 5. Git Hooks Status" | tee -a "$REPORT_FILE"
HOOKS_INSTALLED=true
for hook in pre-commit pre-push commit-msg; do
    if [ -x ".git/hooks/$hook" ]; then
        echo "✓ $hook hook installed" | tee -a "$REPORT_FILE"
    else
        echo "✗ $hook hook not installed" | tee -a "$REPORT_FILE"
        HOOKS_INSTALLED=false
        WARNINGS=$((WARNINGS + 1))
    fi
done

if [ "$HOOKS_INSTALLED" = false ]; then
    echo "" | tee -a "$REPORT_FILE"
    echo "Install hooks with: ./.runners-local/workflows/install-git-hooks.sh" | tee -a "$REPORT_FILE"
    if [ "$OVERALL_STATUS" = "COMPLIANT" ]; then
        OVERALL_STATUS="WARNING"
    fi
fi
echo "" | tee -a "$REPORT_FILE"

# 6. Configuration Validation
echo "## 6. Ghostty Configuration" | tee -a "$REPORT_FILE"
if command -v ghostty &> /dev/null; then
    if ghostty +show-config > /dev/null 2>&1; then
        echo "✓ Ghostty configuration valid" | tee -a "$REPORT_FILE"
    else
        echo "✗ Ghostty configuration invalid" | tee -a "$REPORT_FILE"
        ERRORS=$((ERRORS + 1))
        OVERALL_STATUS="CRITICAL"
    fi
else
    echo "⚠️ ghostty command not found, skipping validation" | tee -a "$REPORT_FILE"
    WARNINGS=$((WARNINGS + 1))
fi
echo "" | tee -a "$REPORT_FILE"

# 7. Branch Count (should only increase)
echo "## 7. Branch Preservation" | tee -a "$REPORT_FILE"
LOCAL_BRANCHES=$(git branch -a | grep -v HEAD | wc -l)
echo "Total branches: $LOCAL_BRANCHES" | tee -a "$REPORT_FILE"
echo "ℹ️ Branch count should only increase (preservation policy)" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# 8. Recent Commit Compliance
echo "## 8. Recent Commit Compliance" | tee -a "$REPORT_FILE"
LATEST_COMMIT_MSG=$(git log -1 --pretty=%B)
if echo "$LATEST_COMMIT_MSG" | grep -q "Co-Authored-By:"; then
    echo "✓ Latest commit has co-authorship" | tee -a "$REPORT_FILE"
else
    echo "⚠️ Latest commit missing co-authorship" | tee -a "$REPORT_FILE"
    WARNINGS=$((WARNINGS + 1))
fi
echo "" | tee -a "$REPORT_FILE"

# Summary
echo "=== Summary ===" | tee -a "$REPORT_FILE"
echo "Overall Status: $OVERALL_STATUS" | tee -a "$REPORT_FILE"
echo "Errors: $ERRORS" | tee -a "$REPORT_FILE"
echo "Warnings: $WARNINGS" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"
echo "Full report saved to: $REPORT_FILE" | tee -a "$REPORT_FILE"

# Exit code based on status
if [ "$OVERALL_STATUS" = "CRITICAL" ]; then
    echo "🚨 CRITICAL issues found - immediate action required"
    exit 1
elif [ "$OVERALL_STATUS" = "WARNING" ]; then
    echo "⚠️ Warnings found - review recommended"
    exit 0
else
    echo "✅ All constitutional compliance checks passed"
    exit 0
fi
