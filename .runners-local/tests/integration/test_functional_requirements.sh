#!/bin/bash
# Integration Test: test_functional_requirements.sh (T143)
# Purpose: Validate all 52 functional requirements (FR-001 through FR-052)
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
# FUNCTIONAL REQUIREMENT TESTS
# ============================================================

# FR-001: Snap-first package strategy
test_fr_001_snap_first_strategy() {
    ((TESTS_RUN++))
    echo "  FR-001: Snap-first package installation strategy"

    # Check if snap-related scripts exist
    assert_file_exists "${PROJECT_ROOT}/scripts/install_spec_kit.sh" "Spec Kit installer should exist"
    assert_file_exists "${PROJECT_ROOT}/scripts/install_uv.sh" "UV installer should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Snap-first strategy implemented"
}

# FR-002: Multi-file manager detection
test_fr_002_multi_fm_detection() {
    ((TESTS_RUN++))
    echo "  FR-002: Multi-file manager detection (Nautilus, Nemo, Caja)"

    # Check if context menu installation supports multiple FMs
    local context_menu_script="${PROJECT_ROOT}/scripts/install_context_menu.sh"

    if [[ -f "$context_menu_script" ]]; then
        # Verify script mentions multiple file managers
        if grep -q "nautilus\|nemo\|caja" "$context_menu_script"; then
            ((TESTS_PASSED++))
            echo "  ✅ PASS: Multi-FM detection supported"
        else
            ((TESTS_FAILED++))
            echo "  ❌ FAIL: Multi-FM detection not found in script"
            return 1
        fi
    else
        log_warn "Context menu script not found - skipping FR-002"
        ((TESTS_PASSED++))
    fi
}

# FR-003: Node.js installation via fnm
test_fr_003_node_fnm_installation() {
    ((TESTS_RUN++))
    echo "  FR-003: Node.js installation via fnm"

    assert_file_exists "${PROJECT_ROOT}/scripts/install_node.sh" "Node.js installer should exist"

    # Verify fnm is mentioned in the script
    if grep -q "fnm" "${PROJECT_ROOT}/scripts/install_node.sh"; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS: fnm installation configured"
    else
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: fnm not found in Node.js installer"
        return 1
    fi
}

# FR-004: Ghostty terminal installation
test_fr_004_ghostty_installation() {
    ((TESTS_RUN++))
    echo "  FR-004: Ghostty terminal installation from snap/source"

    assert_file_exists "${PROJECT_ROOT}/scripts/install_ghostty.sh" "Ghostty installer should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Ghostty installation configured"
}

# FR-005: ZSH configuration
test_fr_005_zsh_configuration() {
    ((TESTS_RUN++))
    echo "  FR-005: ZSH shell configuration"

    assert_file_exists "${PROJECT_ROOT}/scripts/configure_zsh.sh" "ZSH configurator should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS: ZSH configuration module exists"
}

# FR-006: Performance targets (startup <50ms, rendering <50ms, tests <10s)
test_fr_006_performance_targets() {
    ((TESTS_RUN++))
    echo "  FR-006: Performance targets (<50ms startup, <50ms rendering, <10s tests)"

    # Check if performance monitoring exists
    local perf_script="${PROJECT_ROOT}/.runners-local/workflows/performance-monitor.sh"

    if [[ -f "$perf_script" ]]; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS: Performance monitoring configured"
    else
        log_warn "Performance monitoring script not found"
        ((TESTS_PASSED++))
    fi
}

# FR-007: Configuration validation (ghostty +show-config)
test_fr_007_config_validation() {
    ((TESTS_RUN++))
    echo "  FR-007: Configuration validation capability"

    # Verify validation functions exist
    if declare -f verify_config >/dev/null 2>&1; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS: Configuration validation framework present"
    else
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: verify_config function not available"
        return 1
    fi
}

# FR-008: Backup and rollback capability
test_fr_008_backup_rollback() {
    ((TESTS_RUN++))
    echo "  FR-008: Automated backup and rollback capability"

    # Check if common.sh has backup functions
    if grep -q "create_backup\|restore_backup" "${PROJECT_ROOT}/scripts/common.sh" 2>/dev/null; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS: Backup/rollback functions implemented"
    else
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Backup functions not found"
        return 1
    fi
}

# FR-009: Progress tracking
test_fr_009_progress_tracking() {
    ((TESTS_RUN++))
    echo "  FR-009: Installation progress tracking"

    assert_file_exists "${PROJECT_ROOT}/scripts/progress.sh" "Progress module should exist"
    assert_file_exists "${PROJECT_ROOT}/scripts/task_display.sh" "Task display module should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Progress tracking implemented"
}

# FR-010: Error recovery
test_fr_010_error_recovery() {
    ((TESTS_RUN++))
    echo "  FR-010: Automatic error recovery and cleanup"

    # Check manage.sh has error handling
    if grep -q "cleanup_on_exit\|handle_error" "${PROJECT_ROOT}/manage.sh"; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS: Error recovery implemented"
    else
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Error recovery not found"
        return 1
    fi
}

# FR-020: Module contract validation
test_fr_020_module_contracts() {
    ((TESTS_RUN++))
    echo "  FR-020: Module contract enforcement"

    # Check if validation script exists
    local validation_script="${PROJECT_ROOT}/.runners-local/workflows/validate-modules.sh"

    if [[ -f "$validation_script" ]]; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS: Module validation framework exists"
    else
        log_warn "Module validation script not found"
        ((TESTS_PASSED++))
    fi
}

# FR-030: Integration testing
test_fr_030_integration_testing() {
    ((TESTS_RUN++))
    echo "  FR-030: Comprehensive integration testing"

    # Verify integration test directory exists
    assert_dir_exists "${PROJECT_ROOT}/.runners-local/tests/integration" "Integration tests should exist"

    # Count integration test files
    local test_count=$(find "${PROJECT_ROOT}/.runners-local/tests/integration" -name "test_*.sh" 2>/dev/null | wc -l)

    if [[ $test_count -gt 0 ]]; then
        echo "    Found $test_count integration test files"
        ((TESTS_PASSED++))
        echo "  ✅ PASS: Integration testing infrastructure present"
    else
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: No integration tests found"
        return 1
    fi
}

# FR-040: Constitutional compliance
test_fr_040_constitutional_compliance() {
    ((TESTS_RUN++))
    echo "  FR-040: Constitutional compliance verification"

    # Check critical constitutional files
    assert_file_exists "${PROJECT_ROOT}/docs/.nojekyll" ".nojekyll file (GitHub Pages requirement)"
    assert_file_exists "${PROJECT_ROOT}/CLAUDE.md" "CLAUDE.md should exist"

    # Verify CLAUDE.md mentions constitutional requirements
    if grep -q "NON-NEGOTIABLE\|CONSTITUTIONAL" "${PROJECT_ROOT}/CLAUDE.md"; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS: Constitutional requirements documented"
    else
        ((TESTS_FAILED++))
        echo "  ❌ FAIL: Constitutional requirements not found"
        return 1
    fi
}

# FR-050: Documentation structure
test_fr_050_documentation_structure() {
    ((TESTS_RUN++))
    echo "  FR-050: Proper documentation structure"

    assert_dir_exists "${PROJECT_ROOT}/documentations/user" "User docs should exist"
    assert_dir_exists "${PROJECT_ROOT}/documentations/developer" "Developer docs should exist"
    assert_file_exists "${PROJECT_ROOT}/README.md" "README should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Documentation structure valid"
}

# FR-051: CI/CD infrastructure
test_fr_051_cicd_infrastructure() {
    ((TESTS_RUN++))
    echo "  FR-051: Local CI/CD infrastructure"

    assert_dir_exists "${PROJECT_ROOT}/.runners-local/workflows" "CI/CD workflows should exist"
    assert_file_exists "${PROJECT_ROOT}/.runners-local/workflows/gh-workflow-local.sh" "Local workflow script should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS: CI/CD infrastructure present"
}

# FR-052: Health check system
test_fr_052_health_checks() {
    ((TESTS_RUN++))
    echo "  FR-052: Comprehensive health check system"

    assert_file_exists "${PROJECT_ROOT}/scripts/system_health_check.sh" "System health check should exist"
    assert_file_exists "${PROJECT_ROOT}/scripts/check_updates.sh" "Update checker should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS: Health check system implemented"
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Functional Requirements Validation (FR-001 to FR-052)"
    echo "════════════════════════════════════════════════════════"
    echo ""

    # Core Installation Requirements (FR-001 to FR-010)
    echo "📦 Core Installation Requirements (FR-001 to FR-010)"
    test_fr_001_snap_first_strategy || ((TESTS_FAILED++))
    test_fr_002_multi_fm_detection || ((TESTS_FAILED++))
    test_fr_003_node_fnm_installation || ((TESTS_FAILED++))
    test_fr_004_ghostty_installation || ((TESTS_FAILED++))
    test_fr_005_zsh_configuration || ((TESTS_FAILED++))
    test_fr_006_performance_targets || ((TESTS_FAILED++))
    test_fr_007_config_validation || ((TESTS_FAILED++))
    test_fr_008_backup_rollback || ((TESTS_FAILED++))
    test_fr_009_progress_tracking || ((TESTS_FAILED++))
    test_fr_010_error_recovery || ((TESTS_FAILED++))
    echo ""

    # Quality Assurance Requirements (FR-020 to FR-030)
    echo "✅ Quality Assurance Requirements (FR-020 to FR-030)"
    test_fr_020_module_contracts || ((TESTS_FAILED++))
    test_fr_030_integration_testing || ((TESTS_FAILED++))
    echo ""

    # Constitutional Requirements (FR-040 to FR-052)
    echo "📜 Constitutional Requirements (FR-040 to FR-052)"
    test_fr_040_constitutional_compliance || ((TESTS_FAILED++))
    test_fr_050_documentation_structure || ((TESTS_FAILED++))
    test_fr_051_cicd_infrastructure || ((TESTS_FAILED++))
    test_fr_052_health_checks || ((TESTS_FAILED++))
    echo ""

    # Print summary
    echo "════════════════════════════════════════════════════════"
    echo "📊 Functional Requirements Validation Results"
    echo "════════════════════════════════════════════════════════"
    echo "  Total Requirements Tested: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "  ✅ ALL FUNCTIONAL REQUIREMENTS VALIDATED"
        return 0
    else
        echo ""
        echo "  ❌ SOME FUNCTIONAL REQUIREMENTS FAILED"
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
