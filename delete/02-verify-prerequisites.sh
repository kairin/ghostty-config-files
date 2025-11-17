#!/bin/bash

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  SPEC-KIT CONSTITUTION PREREQUISITE VERIFICATION              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

check_pass() {
    echo "   ✅ $1"
    ((PASS_COUNT++))
}

check_fail() {
    echo "   ❌ $1"
    ((FAIL_COUNT++))
}

check_warn() {
    echo "   ⚠️  $1"
    ((WARN_COUNT++))
}

echo "1. CRITICAL FILES & DIRECTORIES"
echo "================================"

if [ -f "docs/.nojekyll" ]; then
    check_pass "docs/.nojekyll exists (CRITICAL for GitHub Pages)"
else
    check_fail "docs/.nojekyll MISSING - MUST CREATE BEFORE PROCEEDING"
fi

if [ -d ".runners-local" ]; then
    WORKFLOW_COUNT=$(ls .runners-local/workflows/*.sh 2>/dev/null | wc -l)
    TEST_COUNT=$(find .runners-local/tests -name '*.sh' 2>/dev/null | wc -l)
    check_pass ".runners-local/ exists ($WORKFLOW_COUNT workflows, $TEST_COUNT tests)"
else
    check_fail ".runners-local/ MISSING - Should NOT be local-infra/"
fi

if [ -d "website" ]; then
    check_pass "website/ directory exists (Astro source)"
else
    check_fail "website/ directory MISSING"
fi

if [ -d "docs" ]; then
    HTML_COUNT=$(find docs -name "*.html" 2>/dev/null | wc -l)
    check_pass "docs/ directory exists ($HTML_COUNT HTML files)"
else
    check_warn "docs/ directory missing (will be created by Astro build)"
fi

echo ""
echo "2. COMPONENT LIBRARY VERIFICATION"
echo "=================================="

if [ -f "website/package.json" ]; then
    if grep -q "daisyui" website/package.json; then
        VERSION=$(grep "daisyui" website/package.json | sed 's/.*: *"\([^"]*\)".*/\1/')
        check_pass "DaisyUI in package.json ($VERSION)"
    else
        check_fail "DaisyUI MISSING - Should NOT be shadcn/ui"
    fi

    if grep -q "shadcn" website/package.json; then
        check_fail "shadcn/ui found in package.json - INCORRECT library"
    fi
else
    check_warn "website/package.json not found"
fi

echo ""
echo "3. NODE.JS VERSION"
echo "=================="

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    check_pass "Node.js installed: $NODE_VERSION"

    if [ -f ".node-version" ]; then
        EXPECTED=$(cat .node-version)
        check_pass "Expected version file exists: $EXPECTED"
    else
        check_warn "No .node-version file (should track latest)"
    fi
else
    check_fail "Node.js not found"
fi

if command -v fnm &> /dev/null; then
    check_pass "fnm (Fast Node Manager) installed"
else
    check_warn "fnm not found (using alternative Node manager?)"
fi

echo ""
echo "4. MCP SERVER HEALTH"
echo "===================="

if [ -f "./scripts/check_context7_health.sh" ]; then
    check_pass "Context7 health check script exists"
    echo "      Running Context7 health check..."
    ./scripts/check_context7_health.sh 2>&1 | grep -E "CONTEXT7|✅|❌" | head -3 | sed 's/^/      /'
else
    check_warn "Context7 health check script not found"
fi

echo ""
if [ -f "./scripts/check_github_mcp_health.sh" ]; then
    check_pass "GitHub MCP health check script exists"
    echo "      Running GitHub MCP health check..."
    ./scripts/check_github_mcp_health.sh 2>&1 | grep -E "GitHub|✅|❌" | head -3 | sed 's/^/      /'
else
    check_warn "GitHub MCP health check script not found"
fi

echo ""
echo "5. GIT CONFIGURATION"
echo "===================="

CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
if [ -n "$CURRENT_BRANCH" ]; then
    check_pass "Current branch: $CURRENT_BRANCH"
else
    check_fail "Not in a git repository"
fi

if [ -z "$(git status --porcelain 2>/dev/null)" ]; then
    check_pass "Working tree is clean"
else
    CHANGES=$(git status --porcelain | wc -l)
    check_warn "Working tree has $CHANGES uncommitted changes"
fi

echo ""
echo "6. LOCAL CI/CD INFRASTRUCTURE"
echo "=============================="

if [ -f ".runners-local/workflows/gh-workflow-local.sh" ]; then
    check_pass "gh-workflow-local.sh exists"
else
    check_fail "gh-workflow-local.sh MISSING"
fi

if [ -f ".runners-local/workflows/astro-build-local.sh" ]; then
    check_pass "astro-build-local.sh exists"
else
    check_fail "astro-build-local.sh MISSING"
fi

if command -v gh &> /dev/null; then
    GH_VERSION=$(gh --version | head -1)
    check_pass "GitHub CLI installed: $GH_VERSION"
else
    check_fail "GitHub CLI (gh) not found"
fi

echo ""
echo "7. PASSWORDLESS SUDO"
echo "===================="

if sudo -n apt update --dry-run &>/dev/null; then
    check_pass "Passwordless sudo configured for apt"
else
    check_warn "Passwordless sudo NOT configured (manual intervention needed)"
fi

echo ""
echo "8. SPEC-KIT REFERENCE DOCUMENTS"
echo "================================"

if [ -f "delete/speckit-constitution-reference-MASTER.md" ]; then
    SIZE=$(du -h delete/speckit-constitution-reference-MASTER.md | cut -f1)
    check_pass "Master reference document exists ($SIZE)"
else
    check_fail "Master reference document MISSING"
fi

if [ -f "delete/constitutional-principles-reference.md" ]; then
    check_pass "Constitutional principles reference exists"
else
    check_fail "Constitutional principles reference MISSING"
fi

if [ -f "delete/reversion-issues-analysis.md" ]; then
    check_pass "Reversion issues analysis exists"
else
    check_fail "Reversion issues analysis MISSING"
fi

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  PREREQUISITE VERIFICATION SUMMARY                            ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "   ✅ PASSED:  $PASS_COUNT"
echo "   ❌ FAILED:  $FAIL_COUNT"
echo "   ⚠️  WARNINGS: $WARN_COUNT"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "   🎯 STATUS: READY TO PROCEED WITH /speckit.constitution"
    echo ""
    echo "   Next steps:"
    echo "   1. Read: delete/speckit-constitution-reference-MASTER.md"
    echo "   2. Execute: /speckit.constitution (with UPDATED prompt)"
    echo "   3. Apply reconciliation matrix to generated output"
    echo "   4. Validate critical files still exist"
    exit 0
else
    echo "   🚨 STATUS: PREREQUISITES NOT MET - FIX FAILURES FIRST"
    echo ""
    echo "   Required actions:"
    echo "   - Fix all ❌ failures above"
    echo "   - Re-run this script to verify"
    echo "   - Only proceed when all critical items pass"
    exit 1
fi
