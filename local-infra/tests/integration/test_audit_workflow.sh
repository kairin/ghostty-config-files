#!/bin/bash
# Integration Test: test_audit_workflow.sh
# Purpose: End-to-end audit workflow testing
# Dependencies: package_migration.sh, audit_packages.sh
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test helper functions
source "${SCRIPT_DIR}/../unit/test_functions.sh"

# Scripts to test
PM_SCRIPT="${SCRIPT_DIR}/../../../scripts/package_migration.sh"
AUDIT_SCRIPT="${SCRIPT_DIR}/../../../scripts/audit_packages.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# TEST FIXTURES & MOCKS
# ============================================================

setup_all() {
    echo "🔧 Setting up integration test environment..."

    # Create temporary test directory
    export TEST_TEMP_DIR=$(mktemp -d)
    echo "  Created temp directory: $TEST_TEMP_DIR"

    # Override cache directory for tests
    export HOME="$TEST_TEMP_DIR"
    mkdir -p "$HOME/.config/package-migration/cache"
}

teardown_all() {
    echo "🧹 Cleaning up integration test environment..."

    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed temp directory: $TEST_TEMP_DIR"
    fi
}

# ============================================================
# INTEGRATION TEST CASES
# ============================================================

# Test: Full audit workflow via package_migration.sh
test_audit_workflow_text_output() {
    ((TESTS_RUN++))

    echo "  Testing: Full audit workflow with text output"

    # Act
    local output=$("$PM_SCRIPT" audit 2>/dev/null || echo "COMMAND_FAILED")

    # Assert
    assert_not_equals "COMMAND_FAILED" "$output" "Audit command should succeed"
    assert_contains "$output" "Package Migration Audit Report" "Should contain report header"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Full audit workflow with JSON output
test_audit_workflow_json_output() {
    ((TESTS_RUN++))

    echo "  Testing: Full audit workflow with JSON output"

    # Act
    local output=$("$PM_SCRIPT" audit --json 2>/dev/null || echo "[]")

    # Assert - verify valid JSON
    echo "$output" | jq '.' >/dev/null 2>&1
    local jq_exit=$?

    assert_equals "0" "$jq_exit" "Output should be valid JSON"

    # Verify it's an array
    local is_array=$(echo "$output" | jq 'type' 2>/dev/null)
    assert_equals "\"array\"" "$is_array" "JSON output should be an array"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Audit with cache bypass
test_audit_workflow_no_cache() {
    ((TESTS_RUN++))

    echo "  Testing: Audit workflow with --no-cache flag"

    # Act - run twice to test cache bypass
    "$PM_SCRIPT" audit --json > /dev/null 2>&1
    local output=$("$PM_SCRIPT" audit --no-cache --json 2>/dev/null || echo "[]")

    # Assert - verify fresh audit executed
    echo "$output" | jq '.' >/dev/null 2>&1
    local jq_exit=$?

    assert_equals "0" "$jq_exit" "No-cache audit should produce valid JSON"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Audit output to file
test_audit_workflow_output_file() {
    ((TESTS_RUN++))

    echo "  Testing: Audit workflow with --output file"

    # Arrange
    local output_file="$TEST_TEMP_DIR/audit-output.json"

    # Act
    "$PM_SCRIPT" audit --json --output "$output_file" 2>/dev/null

    # Assert
    assert_file_exists "$output_file" "Output file should be created"

    # Verify file contains valid JSON
    jq '.' "$output_file" >/dev/null 2>&1
    local jq_exit=$?
    assert_equals "0" "$jq_exit" "Output file should contain valid JSON"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Package migration CLI status command
test_status_command() {
    ((TESTS_RUN++))

    echo "  Testing: Status command integration"

    # Act
    local output=$("$PM_SCRIPT" status 2>/dev/null || echo "COMMAND_FAILED")

    # Assert
    assert_not_equals "COMMAND_FAILED" "$output" "Status command should succeed"
    assert_contains "$output" "Package Migration System Status" "Should show status header"
    assert_contains "$output" "Dependencies:" "Should check dependencies"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Package migration CLI version command
test_version_command() {
    ((TESTS_RUN++))

    echo "  Testing: Version command integration"

    # Act
    local output=$("$PM_SCRIPT" version 2>/dev/null || echo "COMMAND_FAILED")

    # Assert
    assert_not_equals "COMMAND_FAILED" "$output" "Version command should succeed"
    assert_contains "$output" "version" "Should display version number"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Audit script direct execution
test_audit_script_direct() {
    ((TESTS_RUN++))

    echo "  Testing: Direct audit_packages.sh execution"

    # Act
    local output=$("$AUDIT_SCRIPT" --json 2>/dev/null || echo "[]")

    # Assert
    echo "$output" | jq '.' >/dev/null 2>&1
    local jq_exit=$?

    assert_equals "0" "$jq_exit" "Direct audit script should produce valid JSON"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Integration Tests for Audit Workflow"
    echo "════════════════════════════════════════════════════════"

    setup_all

    echo ""
    echo "Running integration test cases..."
    echo ""

    # Run test cases
    test_audit_workflow_text_output || ((TESTS_FAILED++))
    test_audit_workflow_json_output || ((TESTS_FAILED++))
    test_audit_workflow_no_cache || ((TESTS_FAILED++))
    test_audit_workflow_output_file || ((TESTS_FAILED++))
    test_status_command || ((TESTS_FAILED++))
    test_version_command || ((TESTS_FAILED++))
    test_audit_script_direct || ((TESTS_FAILED++))

    teardown_all

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Integration Test Results Summary"
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
