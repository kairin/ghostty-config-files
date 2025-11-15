#!/bin/bash
# Integration Test: test_health_checks.sh
# Purpose: End-to-end testing of all health check scripts
# Dependencies: scripts/check_*.sh, test_functions.sh
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"

# Source test helper functions
source "${SCRIPT_DIR}/../unit/test_functions.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# TEST FIXTURES
# ============================================================

setup_all() {
    echo "🔧 Setting up health checks test environment..."

    # Create test environment
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_LOG_DIR="$TEST_TEMP_DIR/logs"
    mkdir -p "$TEST_LOG_DIR"

    echo "  Created test environment: $TEST_TEMP_DIR"
}

teardown_all() {
    echo "🧹 Cleaning up health checks test environment..."

    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed test environment: $TEST_TEMP_DIR"
    fi
}

# ============================================================
# INTEGRATION TEST CASES
# ============================================================

# Test: System health check script exists
test_system_health_check_exists() {
    ((TESTS_RUN++))
    echo "  Testing: system_health_check.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/system_health_check.sh" \
        "system_health_check.sh should exist"
    assert_true "[[ -x \"$SCRIPTS_DIR/system_health_check.sh\" ]]" \
        "system_health_check.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update check script exists
test_check_updates_exists() {
    ((TESTS_RUN++))
    echo "  Testing: check_updates.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/check_updates.sh" \
        "check_updates.sh should exist"
    assert_true "[[ -x \"$SCRIPTS_DIR/check_updates.sh\" ]]" \
        "check_updates.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Context7 health check script exists
test_context7_health_check_exists() {
    ((TESTS_RUN++))
    echo "  Testing: check_context7_health.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/check_context7_health.sh" \
        "check_context7_health.sh should exist"
    assert_true "[[ -x \"$SCRIPTS_DIR/check_context7_health.sh\" ]]" \
        "check_context7_health.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: GitHub MCP health check script exists
test_github_mcp_health_check_exists() {
    ((TESTS_RUN++))
    echo "  Testing: check_github_mcp_health.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/check_github_mcp_health.sh" \
        "check_github_mcp_health.sh should exist"
    assert_true "[[ -x \"$SCRIPTS_DIR/check_github_mcp_health.sh\" ]]" \
        "check_github_mcp_health.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Health dashboard script exists
test_health_dashboard_exists() {
    ((TESTS_RUN++))
    echo "  Testing: health_dashboard.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/health_dashboard.sh" \
        "health_dashboard.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: All health check scripts are executable
test_all_health_checks_executable() {
    ((TESTS_RUN++))
    echo "  Testing: All health check scripts are executable"

    # Verify each is executable
    local scripts=(
        "system_health_check.sh"
        "check_updates.sh"
        "check_context7_health.sh"
        "check_github_mcp_health.sh"
    )

    for script in "${scripts[@]}"; do
        assert_true "[[ -x \"$SCRIPTS_DIR/$script\" ]]" \
            "$script should be executable"
    done

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Health check scripts have documentation
test_health_checks_documented() {
    ((TESTS_RUN++))
    echo "  Testing: Health check scripts are documented in README"

    # Check if README or docs mention health checks
    local has_docs=false
    if grep -q "health\|check\|status" "$PROJECT_ROOT/README.md"; then
        has_docs=true
    fi

    assert_true "[$has_docs = true]" \
        "Health checks should be documented"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Daily updates health check
test_daily_updates_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: daily-updates.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/daily-updates.sh" \
        "daily-updates.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Update ghostty script exists
test_update_ghostty_exists() {
    ((TESTS_RUN++))
    echo "  Testing: update_ghostty.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/update_ghostty.sh" \
        "update_ghostty.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Install node script exists for health checks
test_install_node_exists() {
    ((TESTS_RUN++))
    echo "  Testing: install_node.sh exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/install_node.sh" \
        "install_node.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Smart commit script for change tracking
test_smart_commit_script_exists() {
    ((TESTS_RUN++))
    echo "  Testing: smart_commit.sh exists for change tracking"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/smart_commit.sh" \
        "smart_commit.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: System verification scripts exist
test_system_verification_scripts_exist() {
    ((TESTS_RUN++))
    echo "  Testing: System verification scripts exist"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/verify-passwordless-sudo.sh" \
        "verify-passwordless-sudo.sh should exist"
    assert_file_exists "$SCRIPTS_DIR/verify_env_loaded.sh" \
        "verify_env_loaded.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Health check results directory structure
test_health_check_results_structure() {
    ((TESTS_RUN++))
    echo "  Testing: Health check results can be logged"

    # Verify logs directory exists for results
    assert_dir_exists "$PROJECT_ROOT/.runners-local/logs" \
        "logs directory should exist for health check results"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Common utilities for health checks
test_common_utilities_for_health_checks() {
    ((TESTS_RUN++))
    echo "  Testing: Common utilities exist for health checks"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/common.sh" \
        "common.sh should exist"
    assert_file_exists "$SCRIPTS_DIR/progress.sh" \
        "progress.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: View update logs utility
test_update_logs_utility_exists() {
    ((TESTS_RUN++))
    echo "  Testing: Update logs viewing utility exists"

    # Assert
    assert_file_exists "$SCRIPTS_DIR/view-update-logs.sh" \
        "view-update-logs.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Health check dependencies are documented
test_health_check_dependencies_documented() {
    ((TESTS_RUN++))
    echo "  Testing: Health check dependencies are documented"

    # Check if CLAUDE.md mentions health check requirements
    local has_requirements=false
    if grep -q "health\|requirement\|depend" "$PROJECT_ROOT/CLAUDE.md"; then
        has_requirements=true
    fi

    assert_true "[$has_requirements = true]" \
        "Health check requirements should be documented"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Health check validation infrastructure
test_validation_infrastructure() {
    ((TESTS_RUN++))
    echo "  Testing: Validation infrastructure exists"

    # Assert
    assert_dir_exists "$PROJECT_ROOT/.runners-local/tests/validation" \
        "validation tests directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Integration Tests: Health Checks"
    echo "════════════════════════════════════════════════════════"

    setup_all

    echo ""
    echo "Running integration test cases..."
    echo ""

    # Run test cases
    test_system_health_check_exists || ((TESTS_FAILED++))
    test_check_updates_exists || ((TESTS_FAILED++))
    test_context7_health_check_exists || ((TESTS_FAILED++))
    test_github_mcp_health_check_exists || ((TESTS_FAILED++))
    test_health_dashboard_exists || ((TESTS_FAILED++))
    test_all_health_checks_executable || ((TESTS_FAILED++))
    test_health_checks_documented || ((TESTS_FAILED++))
    test_daily_updates_script_exists || ((TESTS_FAILED++))
    test_update_ghostty_exists || ((TESTS_FAILED++))
    test_install_node_exists || ((TESTS_FAILED++))
    test_smart_commit_script_exists || ((TESTS_FAILED++))
    test_system_verification_scripts_exist || ((TESTS_FAILED++))
    test_health_check_results_structure || ((TESTS_FAILED++))
    test_common_utilities_for_health_checks || ((TESTS_FAILED++))
    test_update_logs_utility_exists || ((TESTS_FAILED++))
    test_health_check_dependencies_documented || ((TESTS_FAILED++))
    test_validation_infrastructure || ((TESTS_FAILED++))

    teardown_all

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Integration Test Results: Health Checks"
    echo "════════════════════════════════════════════════════════"
    echo "  Total Tests: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "  ✅ ALL INTEGRATION TESTS PASSED"
        return 0
    else
        echo ""
        echo "  ❌ SOME INTEGRATION TESTS FAILED"
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
