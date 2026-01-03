#!/bin/bash
# Comprehensive regression verification script
# Ensures no remote improvements were reverted after integration
# Validates package versions, security, infrastructure, and build functionality

set -euo pipefail

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Counters
PASSED_CHECKS=0
FAILED_CHECKS=0

# Repository paths
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

log_check() {
    local check_name="$1"
    echo -e "${BLUE}✓${NC} Checking $check_name..."
}

log_pass() {
    local message="$1"
    echo -e "  ${GREEN}✓${NC} $message"
    ((PASSED_CHECKS++))
}

log_fail() {
    local message="$1"
    echo -e "  ${RED}✗${NC} $message"
    ((FAILED_CHECKS++))
}

log_warn() {
    local message="$1"
    echo -e "  ${YELLOW}⚠${NC} $message"
}

log_info() {
    local message="$1"
    echo -e "  ℹ️  $message"
}

# ============================================================
# REGRESSION CHECKS
# ============================================================

check_go_tui_architecture() {
    log_check "Go TUI architecture"

    # Check if start.sh exists (primary Go TUI entry point)
    if [ -f "$REPO_ROOT/start.sh" ]; then
        log_pass "start.sh exists (Go TUI entry point)"

        # Try to get version
        if output=$($REPO_ROOT/start.sh --version 2>&1); then
            if echo "$output" | grep -q "ghostty\|version"; then
                log_pass "Go TUI responds to --version command"
            else
                log_warn "start.sh --version output unclear"
            fi
        else
            log_warn "Could not verify start.sh version (may require environment setup)"
        fi
    else
        log_fail "start.sh not found (Go TUI infrastructure missing)"
        return 1
    fi

    # Check for TUI-related infrastructure
    if [ -d "$REPO_ROOT/.runners-local" ]; then
        log_pass ".runners-local infrastructure present (CI/CD)"
    else
        log_warn ".runners-local directory not found"
    fi

    return 0
}

check_package_versions() {
    log_check "package versions"

    local errors=0

    # Check astro-website versions
    if [ ! -d "$REPO_ROOT/astro-website" ]; then
        log_fail "astro-website directory not found"
        return 1
    fi

    cd "$REPO_ROOT/astro-website"

    # Get installed versions using npm
    local astro_version
    local tailwind_version
    local daisyui_version

    astro_version=$(npm list astro --json 2>/dev/null | jq -r '.dependencies.astro.version // empty' | head -1)
    tailwind_version=$(npm list tailwindcss --json 2>/dev/null | jq -r '.dependencies.tailwindcss.version // empty' | head -1)
    daisyui_version=$(npm list daisyui --json 2>/dev/null | jq -r '.dependencies.daisyui.version // empty' | head -1)

    # Validate Astro version (should be >= 5.16.2)
    if [ -n "$astro_version" ]; then
        # Extract major.minor.patch
        local astro_major=$(echo "$astro_version" | cut -d. -f1)
        local astro_minor=$(echo "$astro_version" | cut -d. -f2)
        local astro_patch=$(echo "$astro_version" | cut -d. -f3 | cut -d- -f1)

        if [ "$astro_major" -ge 5 ] && [ "$astro_minor" -ge 16 ] && [ "$astro_patch" -ge 2 ]; then
            log_pass "Astro version: $astro_version (✓ >= 5.16.2)"
        else
            log_fail "Astro version: $astro_version (✗ Expected >= 5.16.2, DOWNGRADED)"
            ((errors++))
        fi
    else
        log_fail "Could not determine Astro version"
        ((errors++))
    fi

    # Validate Tailwind CSS version (should be >= 4.1.17)
    if [ -n "$tailwind_version" ]; then
        local tailwind_major=$(echo "$tailwind_version" | cut -d. -f1)
        local tailwind_minor=$(echo "$tailwind_version" | cut -d. -f2)
        local tailwind_patch=$(echo "$tailwind_version" | cut -d. -f3 | cut -d- -f1)

        if [ "$tailwind_major" -ge 4 ] && [ "$tailwind_minor" -ge 1 ] && [ "$tailwind_patch" -ge 17 ]; then
            log_pass "Tailwind CSS version: $tailwind_version (✓ >= 4.1.17)"
        else
            log_fail "Tailwind CSS version: $tailwind_version (✗ Expected >= 4.1.17, DOWNGRADED)"
            ((errors++))
        fi
    else
        log_warn "Could not determine Tailwind CSS version"
    fi

    # Validate DaisyUI version (should be >= 5.5.5)
    if [ -n "$daisyui_version" ]; then
        local daisy_major=$(echo "$daisyui_version" | cut -d. -f1)
        local daisy_minor=$(echo "$daisyui_version" | cut -d. -f2)
        local daisy_patch=$(echo "$daisyui_version" | cut -d. -f3 | cut -d- -f1)

        if [ "$daisy_major" -ge 5 ] && [ "$daisy_minor" -ge 5 ] && [ "$daisy_patch" -ge 5 ]; then
            log_pass "DaisyUI version: $daisyui_version (✓ >= 5.5.5)"
        else
            log_fail "DaisyUI version: $daisyui_version (✗ Expected >= 5.5.5, DOWNGRADED)"
            ((errors++))
        fi
    else
        log_warn "Could not determine DaisyUI version"
    fi

    cd "$REPO_ROOT"

    return $errors
}

check_security_vulnerabilities() {
    log_check "security vulnerabilities"

    cd "$REPO_ROOT/astro-website"

    local vulnerabilities
    vulnerabilities=$(npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities.total // 0')

    if [ "$vulnerabilities" = "0" ]; then
        log_pass "Zero vulnerabilities maintained (✓ 0/all)"
    else
        log_fail "SECURITY REGRESSION: Found $vulnerabilities vulnerabilities"
        npm audit 2>/dev/null | head -20
        cd "$REPO_ROOT"
        return 1
    fi

    cd "$REPO_ROOT"
    return 0
}

check_constitutional_compliance() {
    log_check "constitutional compliance"

    local errors=0

    # Check .nojekyll protection (multi-layer)
    if [ -f "$REPO_ROOT/public/.nojekyll" ]; then
        log_pass "public/.nojekyll (primary protection layer) present"
    else
        log_warn "public/.nojekyll missing (primary layer)"
    fi

    if [ -f "$REPO_ROOT/docs/.nojekyll" ]; then
        log_pass "docs/.nojekyll (build output layer) present"
    else
        log_warn "docs/.nojekyll missing (build layer)"
    fi

    # Check branch preservation (no accidental deletions)
    if git show-ref --verify --quiet refs/heads/main; then
        log_pass "main branch exists (not deleted)"
    else
        log_fail "main branch missing (CRITICAL)"
        ((errors++))
    fi

    # Check for critical infrastructure files
    if [ -f "$REPO_ROOT/CLAUDE.md" ]; then
        log_pass "CLAUDE.md documentation present"
    else
        log_warn "CLAUDE.md missing"
    fi

    return $errors
}

check_remote_infrastructure() {
    log_check "remote-specific infrastructure"

    local missing_count=0

    # Check for CI/CD infrastructure
    if [ -d "$REPO_ROOT/.runners-local" ]; then
        log_pass ".runners-local directory intact"
    else
        log_fail ".runners-local directory missing (REGRESSION)"
        ((missing_count++))
    fi

    # Check for agent instructions
    if [ -d "$REPO_ROOT/.claude/instructions-for-agents" ]; then
        log_pass ".claude/instructions-for-agents intact"
    elif [ -d "$REPO_ROOT/.claude" ]; then
        log_warn ".claude exists but instructions subdirectory missing"
    else
        log_warn ".claude directory not found"
    fi

    # Check for GitHub workflows
    if [ -d "$REPO_ROOT/.github/workflows" ]; then
        local workflow_count
        workflow_count=$(find "$REPO_ROOT/.github/workflows" -name "*.yml" -o -name "*.yaml" | wc -l)
        if [ "$workflow_count" -gt 0 ]; then
            log_pass ".github/workflows infrastructure intact ($workflow_count workflows)"
        else
            log_warn ".github/workflows directory exists but no workflows found"
        fi
    else
        log_warn ".github/workflows not found"
    fi

    return $missing_count
}

check_package_json_structure() {
    log_check "package.json structure"

    # Check root package.json
    if [ ! -f "$REPO_ROOT/package.json" ]; then
        log_fail "Root package.json missing"
        return 1
    fi

    local pkg_type
    pkg_type=$(jq -r '.type // "commonjs"' "$REPO_ROOT/package.json")

    if [ "$pkg_type" = "module" ]; then
        log_pass "Root package.json: type='module' (ESM preserved)"
    else
        log_fail "Root package.json: type='$pkg_type' (Expected 'module', CHANGED)"
        return 1
    fi

    # Check for critical scripts
    if jq -e '.scripts["docs:build"]' "$REPO_ROOT/package.json" >/dev/null 2>&1; then
        log_pass "Root package.json: docs:build script present"
    else
        log_warn "docs:build script missing from root package.json"
    fi

    # Check astro-website package.json
    if [ -f "$REPO_ROOT/astro-website/package.json" ]; then
        local astro_pkg_type
        astro_pkg_type=$(jq -r '.type // "undefined"' "$REPO_ROOT/astro-website/package.json")
        log_pass "astro-website/package.json: type='$astro_pkg_type'"
    else
        log_warn "astro-website/package.json not found"
    fi

    return 0
}

check_build_functionality() {
    log_check "build functionality"

    if [ ! -d "$REPO_ROOT/astro-website" ]; then
        log_fail "astro-website directory not found"
        return 1
    fi

    cd "$REPO_ROOT/astro-website"

    # Try astro check
    if npm run check >/dev/null 2>&1; then
        log_pass "astro check: SUCCESS"
    else
        log_warn "astro check: had issues (non-blocking)"
    fi

    # Verify astro build can run
    if npm run build >/dev/null 2>&1; then
        log_pass "astro build: SUCCESS"

        # Verify output exists
        if [ -f "$REPO_ROOT/docs/index.html" ]; then
            log_pass "Build output verified in docs/"
        else
            log_fail "Build output missing (docs/index.html not found)"
            cd "$REPO_ROOT"
            return 1
        fi
    else
        log_fail "astro build: FAILED"
        cd "$REPO_ROOT"
        return 1
    fi

    cd "$REPO_ROOT"
    return 0
}

# ============================================================
# SUMMARY AND REPORTING
# ============================================================

print_summary() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "           REGRESSION VERIFICATION SUMMARY"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo -e "Passed Checks:  ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed Checks:  ${RED}$FAILED_CHECKS${NC}"
    echo ""

    if [ $FAILED_CHECKS -eq 0 ]; then
        echo -e "${GREEN}✅ ALL CHECKS PASSED${NC}"
        echo "No regressions detected - integration successful!"
        return 0
    else
        echo -e "${RED}❌ REGRESSION DETECTED${NC}"
        echo "Found $FAILED_CHECKS critical issues"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    echo "════════════════════════════════════════════════════════"
    echo "     COMPREHENSIVE REGRESSION VERIFICATION SCRIPT"
    echo "════════════════════════════════════════════════════════"
    echo ""
    echo "Verifying no remote improvements were reverted..."
    echo "Repository: $REPO_ROOT"
    echo ""

    # Run all checks
    check_go_tui_architecture || true
    echo ""

    check_package_versions || true
    echo ""

    check_security_vulnerabilities || true
    echo ""

    check_constitutional_compliance || true
    echo ""

    check_remote_infrastructure || true
    echo ""

    check_package_json_structure || true
    echo ""

    check_build_functionality || true
    echo ""

    # Print summary and exit with appropriate code
    print_summary
}

# Execute main
main "$@"
exit $?
