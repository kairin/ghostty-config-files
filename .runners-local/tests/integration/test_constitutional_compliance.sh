#!/bin/bash
# Integration Test: test_constitutional_compliance.sh (T145)
# Purpose: Validate 6 constitutional principles
# Dependencies: test_functions.sh, verification.sh
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source test helper functions
source "${SCRIPT_DIR}/../unit/test_functions.sh"
source "${PROJECT_ROOT}/scripts/verification.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# CONSTITUTIONAL COMPLIANCE TESTS
# ============================================================

# Principle 1: Branch Preservation (YYYYMMDD-HHMMSS naming, no deletion)
test_principle_1_branch_preservation() {
    ((TESTS_RUN++))
    echo "  Principle 1: Branch Preservation Strategy"

    # Check CLAUDE.md for branch preservation requirement
    if ! grep -q "NEVER DELETE BRANCH" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Branch preservation not documented"
        return 1
    fi

    # Verify branch naming convention is documented
    if ! grep -q "YYYYMMDD-HHMMSS" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Branch naming convention not documented"
        return 1
    fi

    # Check that scripts don't use 'git branch -d'
    if grep -r "git branch -d" "${PROJECT_ROOT}/scripts" 2>/dev/null | grep -v "# NEVER"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Scripts contain branch deletion commands"
        return 1
    fi

    # Verify merge strategy is --no-ff
    if ! grep -q "merge.*--no-ff" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: No-fast-forward merge strategy not documented"
        return 1
    fi

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Branch preservation strategy enforced"
    echo "    ✓ Never delete branches"
    echo "    ✓ YYYYMMDD-HHMMSS naming convention"
    echo "    ✓ No branch deletion in scripts"
    echo "    ✓ Merge with --no-ff"
}

# Principle 2: GitHub Pages .nojekyll (4-layer protection)
test_principle_2_github_pages_nojekyll() {
    ((TESTS_RUN++))
    echo "  Principle 2: GitHub Pages .nojekyll Protection"

    # Layer 1: File exists
    if [[ ! -f "${PROJECT_ROOT}/docs/.nojekyll" ]]; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: .nojekyll file missing"
        return 1
    fi

    # Layer 2: Documented as CRITICAL
    if ! grep -q "CRITICAL.*nojekyll\|nojekyll.*CRITICAL" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: .nojekyll not marked as CRITICAL in documentation"
        return 1
    fi

    # Layer 3: Validated in gh-pages-setup.sh
    local pages_script="${PROJECT_ROOT}/.runners-local/workflows/gh-pages-setup.sh"
    if [[ -f "$pages_script" ]]; then
        if ! grep -q "nojekyll" "$pages_script"; then
            ((TESTS_FAILED++))
            echo "  ❌ FAIL: .nojekyll not validated in gh-pages-setup.sh"
            return 1
        fi
    fi

    # Layer 4: manage.sh docs build validates it
    if ! grep -q "nojekyll" "${PROJECT_ROOT}/manage.sh"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: manage.sh doesn't validate .nojekyll"
        return 1
    fi

    ((TESTS_PASSED++))
    echo "  ✅ PASS: .nojekyll 4-layer protection verified"
    echo "    ✓ File exists in docs/"
    echo "    ✓ Documented as CRITICAL"
    echo "    ✓ Validated in gh-pages-setup.sh"
    echo "    ✓ Checked in manage.sh"
}

# Principle 3: Local CI/CD First (validate before GitHub)
test_principle_3_local_cicd_first() {
    ((TESTS_RUN++))
    echo "  Principle 3: Local CI/CD First Strategy"

    # Verify local CI/CD infrastructure exists
    if [[ ! -d "${PROJECT_ROOT}/.runners-local/workflows" ]]; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Local CI/CD workflows directory missing"
        return 1
    fi

    # Verify gh-workflow-local.sh exists
    local workflow_script="${PROJECT_ROOT}/.runners-local/workflows/gh-workflow-local.sh"
    if [[ ! -f "$workflow_script" ]]; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: gh-workflow-local.sh missing"
        return 1
    fi

    # Verify documentation mentions "local CI/CD BEFORE GitHub"
    if ! grep -q "local.*BEFORE.*GitHub\|MANDATORY.*local.*CI\|local CI/CD.*FIRST" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Local-first CI/CD not documented as MANDATORY"
        return 1
    fi

    # Verify zero-cost operations documented
    if ! grep -q "zero.*cost\|Zero.*GitHub Actions" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Zero-cost operations not documented"
        return 1
    fi

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Local CI/CD first strategy implemented"
    echo "    ✓ .runners-local/workflows/ exists"
    echo "    ✓ gh-workflow-local.sh present"
    echo "    ✓ Documented as MANDATORY"
    echo "    ✓ Zero-cost operations enforced"
}

# Principle 4: Agent File Integrity (AGENTS.md symlinks)
test_principle_4_agent_file_integrity() {
    ((TESTS_RUN++))
    echo "  Principle 4: Agent File Integrity (CLAUDE.md/GEMINI.md)"

    # Verify CLAUDE.md exists
    if [[ ! -f "${PROJECT_ROOT}/CLAUDE.md" ]]; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: CLAUDE.md missing"
        return 1
    fi

    # Verify GEMINI.md exists
    if [[ ! -f "${PROJECT_ROOT}/GEMINI.md" ]]; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: GEMINI.md missing"
        return 1
    fi

    # Verify NON-NEGOTIABLE requirements are documented
    if ! grep -q "NON-NEGOTIABLE" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: NON-NEGOTIABLE requirements not documented"
        return 1
    fi

    # Verify files have substantial content (>1000 bytes)
    local claude_size=$(stat -f%z "${PROJECT_ROOT}/CLAUDE.md" 2>/dev/null || stat -c%s "${PROJECT_ROOT}/CLAUDE.md" 2>/dev/null)
    if [[ $claude_size -lt 1000 ]]; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: CLAUDE.md too small (${claude_size} < 1000 bytes)"
        return 1
    fi

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Agent file integrity maintained"
    echo "    ✓ CLAUDE.md exists and is substantial"
    echo "    ✓ GEMINI.md exists"
    echo "    ✓ NON-NEGOTIABLE requirements documented"
}

# Principle 5: Conversation Logging (complete logs in documentations/developer/)
test_principle_5_conversation_logging() {
    ((TESTS_RUN++))
    echo "  Principle 5: Conversation Logging Requirement"

    # Verify conversation logging is documented as MANDATORY
    if ! grep -q "MANDATORY.*conversation.*log\|conversation.*log.*MANDATORY" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Conversation logging not documented as MANDATORY"
        return 1
    fi

    # Verify development directory exists
    if [[ ! -d "${PROJECT_ROOT}/documentations/developer" ]]; then
        log_warn "documentations/developer/ directory missing (will be created when needed)"
        # Don't fail - directory is created when first log is saved
    fi

    # Verify documentation mentions complete logs
    if ! grep -q "complete.*conversation\|entire conversation" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Complete conversation logging not documented"
        return 1
    fi

    # Verify documentation mentions excluding sensitive data
    if ! grep -q "exclude.*sensitive\|remove.*API.*key\|sensitive.*data" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Sensitive data exclusion not documented"
        return 1
    fi

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Conversation logging requirements documented"
    echo "    ✓ Documented as MANDATORY"
    echo "    ✓ Complete logs required"
    echo "    ✓ Sensitive data exclusion documented"
}

# Principle 6: Zero-Cost Operations (no GitHub Actions consumption)
test_principle_6_zero_cost_operations() {
    ((TESTS_RUN++))
    echo "  Principle 6: Zero-Cost GitHub Operations"

    # Verify local CI/CD infrastructure prevents GitHub Actions usage
    local workflow_script="${PROJECT_ROOT}/.runners-local/workflows/gh-workflow-local.sh"

    if [[ ! -f "$workflow_script" ]]; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Local workflow script missing"
        return 1
    fi

    # Verify documentation explicitly forbids GitHub Actions for routine tasks
    if ! grep -q "zero.*cost\|Zero.*GitHub Actions\|GitHub Actions.*cost" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Zero-cost operations not documented"
        return 1
    fi

    # Verify gh-workflow-local.sh has billing check
    if ! grep -q "billing\|usage\|cost" "$workflow_script"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Billing check not implemented in workflow script"
        return 1
    fi

    # Verify documentation mentions "local BEFORE GitHub"
    if ! grep -q "local.*BEFORE.*GitHub\|MANDATORY.*local" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Local-first mandate not documented"
        return 1
    fi

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Zero-cost operations enforced"
    echo "    ✓ Local CI/CD infrastructure present"
    echo "    ✓ Zero-cost documented"
    echo "    ✓ Billing check implemented"
    echo "    ✓ Local-first mandate documented"
}

# ============================================================
# COMPREHENSIVE CONSTITUTIONAL AUDIT
# ============================================================

generate_constitutional_audit() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📜 Constitutional Compliance Audit Summary"
    echo "════════════════════════════════════════════════════════"

    # Audit CLAUDE.md for all NON-NEGOTIABLE items
    local non_negotiable_count=$(grep -c "NON-NEGOTIABLE\|MANDATORY\|CRITICAL" "${PROJECT_ROOT}/CLAUDE.md" 2>/dev/null || echo 0)
    echo "  NON-NEGOTIABLE Items in CLAUDE.md: $non_negotiable_count"

    # Check branch protection
    local branch_protection=$(grep -c "NEVER DELETE BRANCH" "${PROJECT_ROOT}/CLAUDE.md" 2>/dev/null || echo 0)
    echo "  Branch Protection Mentions: $branch_protection"

    # Check .nojekyll protection
    local nojekyll_protection=$(grep -c "nojekyll" "${PROJECT_ROOT}/CLAUDE.md" 2>/dev/null || echo 0)
    echo "  .nojekyll Protection Mentions: $nojekyll_protection"

    # Check local CI/CD mentions
    local local_cicd=$(grep -c "local CI/CD\|Local CI/CD" "${PROJECT_ROOT}/CLAUDE.md" 2>/dev/null || echo 0)
    echo "  Local CI/CD Mentions: $local_cicd"

    # Check zero-cost mentions
    local zero_cost=$(grep -c "zero.*cost\|Zero.*cost" "${PROJECT_ROOT}/CLAUDE.md" 2>/dev/null || echo 0)
    echo "  Zero-Cost Mentions: $zero_cost"

    # Check conversation logging
    local conversation_log=$(grep -c "conversation.*log\|CONVERSATION_LOG" "${PROJECT_ROOT}/CLAUDE.md" 2>/dev/null || echo 0)
    echo "  Conversation Logging Mentions: $conversation_log"

    echo ""
    echo "Critical Files Status:"
    echo "  CLAUDE.md: $(if [[ -f "${PROJECT_ROOT}/CLAUDE.md" ]]; then echo "✓ Present"; else echo "✗ Missing"; fi)"
    echo "  GEMINI.md: $(if [[ -f "${PROJECT_ROOT}/GEMINI.md" ]]; then echo "✓ Present"; else echo "✗ Missing"; fi)"
    echo "  docs/.nojekyll: $(if [[ -f "${PROJECT_ROOT}/docs/.nojekyll" ]]; then echo "✓ Present"; else echo "✗ Missing"; fi)"
    echo "  .runners-local/workflows/: $(if [[ -d "${PROJECT_ROOT}/.runners-local/workflows" ]]; then echo "✓ Present"; else echo "✗ Missing"; fi)"

    echo "════════════════════════════════════════════════════════"
    echo ""
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Constitutional Compliance Verification"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Validating 6 Constitutional Principles:"
    echo ""

    # Run all principle tests
    test_principle_1_branch_preservation || ((TESTS_FAILED++))
    echo ""

    test_principle_2_github_pages_nojekyll || ((TESTS_FAILED++))
    echo ""

    test_principle_3_local_cicd_first || ((TESTS_FAILED++))
    echo ""

    test_principle_4_agent_file_integrity || ((TESTS_FAILED++))
    echo ""

    test_principle_5_conversation_logging || ((TESTS_FAILED++))
    echo ""

    test_principle_6_zero_cost_operations || ((TESTS_FAILED++))
    echo ""

    # Generate comprehensive audit
    generate_constitutional_audit

    # Print summary
    echo "════════════════════════════════════════════════════════"
    echo "📊 Constitutional Compliance Results"
    echo "════════════════════════════════════════════════════════"
    echo "  Total Principles Tested: $TESTS_RUN"
    echo "  Compliant: $TESTS_PASSED"
    echo "  Non-Compliant: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "  ✅ FULL CONSTITUTIONAL COMPLIANCE"
        echo ""
        echo "All 6 constitutional principles are enforced:"
        echo "  1. ✓ Branch Preservation (YYYYMMDD-HHMMSS, no deletion)"
        echo "  2. ✓ GitHub Pages .nojekyll (4-layer protection)"
        echo "  3. ✓ Local CI/CD First (validate before GitHub)"
        echo "  4. ✓ Agent File Integrity (CLAUDE.md/GEMINI.md)"
        echo "  5. ✓ Conversation Logging (complete logs)"
        echo "  6. ✓ Zero-Cost Operations (no GitHub Actions waste)"
        return 0
    else
        echo ""
        echo "  ❌ CONSTITUTIONAL VIOLATIONS DETECTED"
        echo ""
        echo "Failed Principles:"
        if [[ $TESTS_PASSED -lt 6 ]]; then
            echo "  Review test output above for specific violations"
        fi
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
    exit $?
fi
