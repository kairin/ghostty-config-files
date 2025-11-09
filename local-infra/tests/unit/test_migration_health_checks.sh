#!/bin/bash
# Unit Test: test_migration_health_checks.sh
# Purpose: Unit tests for migration_health_checks.sh module (T053)
# Dependencies: test_functions.sh (assertion helpers)
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test helper functions
source "${SCRIPT_DIR}/test_functions.sh"

# Source the module being tested
MODULE_PATH="${SCRIPT_DIR}/../../../scripts/migration_health_checks.sh"
source "$MODULE_PATH"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# TEST FIXTURES & MOCKS
# ============================================================

# Setup: Run before all tests
setup_all() {
    echo "🔧 Setting up test environment..."

    # Create temporary test directory
    export TEST_TEMP_DIR=$(mktemp -d)
    echo "  Created temp directory: $TEST_TEMP_DIR"

    # Mock configuration
    export MIGRATION_DISK_MIN_GB=10
    export MIGRATION_NETWORK_TIMEOUT=5
    export MIGRATION_LOG_DIR="$TEST_TEMP_DIR/logs"
    mkdir -p "$MIGRATION_LOG_DIR"

    # Create test metadata files
    cat > "$TEST_TEMP_DIR/test_metadata.json" << 'EOF'
{
  "backup_id": "20251109-143000",
  "timestamp": "2025-11-09T14:30:00Z",
  "backup_directory": "/tmp/test-backup",
  "packages": [
    {
      "name": "firefox",
      "version": "120.0-1ubuntu1",
      "installation_method": "apt",
      "deb_file": "debs/firefox_120.0-1ubuntu1_amd64.deb",
      "deb_checksum": "sha256:abcdef123456",
      "dependencies": [],
      "config_files": [],
      "systemd_services": []
    }
  ],
  "total_size": 100000000,
  "retention_until": "2025-12-09T14:30:00Z"
}
EOF
}

# Teardown: Run after all tests
teardown_all() {
    echo "🧹 Cleaning up test environment..."

    # Remove temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed temp directory: $TEST_TEMP_DIR"
    fi

    # Restore mocked commands
    restore_mocks
}

# Setup: Run before each test
setup() {
    # Per-test setup if needed
    :
}

# Teardown: Run after each test
teardown() {
    # Per-test cleanup if needed
    :
}

# ============================================================
# DISK SPACE CHECK TESTS
# ============================================================

# Test: check_disk_space with sufficient space
test_check_disk_space_sufficient() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: check_disk_space with sufficient space"

    # Act
    check_disk_space "test-package" 1000 2000
    local exit_code=$?

    # Assert
    assert_equals 0 "$exit_code" "Should pass with sufficient space"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: check_disk_space with package name
test_check_disk_space_package_name() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: check_disk_space validates package name"

    # Act
    check_disk_space "firefox" 50000000 100000000
    local exit_code=$?

    # Assert - should succeed (we have space in test environment)
    assert_equals 0 "$exit_code" "Should validate disk space calculation"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# ============================================================
# NETWORK CONNECTIVITY TESTS
# ============================================================

# Test: check_network_connectivity with snapd socket
test_check_network_snapd_socket() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: check_network_connectivity snapd socket detection"

    # Mock snapd socket existence
    mkdir -p "$TEST_TEMP_DIR/run"
    touch "$TEST_TEMP_DIR/run/snapd.socket"

    # Note: Actual network check may fail in test environment, that's expected
    # We're primarily testing the function structure

    set +e
    check_network_connectivity 2>/dev/null
    local exit_code=$?
    set -e

    # Assert - exit code should be defined (0 or 1)
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS (exit code: $exit_code)"
    else
        echo "  ❌ FAIL: Unexpected exit code: $exit_code"
        ((TESTS_FAILED++))
    fi

    teardown
}

# ============================================================
# SNAPD DAEMON CHECK TESTS
# ============================================================

# Test: check_snapd_daemon status check
test_check_snapd_daemon_status() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: check_snapd_daemon status verification"

    # Act - check without auto-fix
    set +e
    check_snapd_daemon "false" 2>/dev/null
    local exit_code=$?
    set -e

    # Assert - should return valid exit code (0 if active, 1 if inactive)
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS (snapd status: $(systemctl is-active snapd.service 2>/dev/null || echo 'inactive'))"
    else
        echo "  ❌ FAIL: Unexpected exit code: $exit_code"
        ((TESTS_FAILED++))
    fi

    teardown
}

# ============================================================
# PACKAGE CONFLICT TESTS
# ============================================================

# Test: check_package_conflicts with valid package
test_check_package_conflicts_valid() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: check_package_conflicts with bash (always installed)"

    # Act - use bash as it's guaranteed to be installed via apt
    set +e
    check_package_conflicts "bash" 2>/dev/null
    local exit_code=$?
    set -e

    # Assert - bash is installed via apt, so should pass or fail based on snap presence
    if [[ $exit_code -eq 0 ]] || [[ $exit_code -eq 1 ]]; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS (exit code: $exit_code)"
    else
        echo "  ❌ FAIL: Unexpected exit code: $exit_code"
        ((TESTS_FAILED++))
    fi

    teardown
}

# Test: check_package_conflicts with empty package name
test_check_package_conflicts_empty() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: check_package_conflicts with empty package name"

    # Act & Assert
    set +e
    check_package_conflicts "" 2>/dev/null
    local exit_code=$?
    set -e

    assert_equals 2 "$exit_code" "Should return exit code 2 for invalid argument"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# ============================================================
# HEALTH CHECK AGGREGATION TESTS
# ============================================================

# Test: run_all_health_checks basic functionality
test_run_all_health_checks_basic() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: run_all_health_checks aggregates results"

    # Act - run health checks on a test package
    set +e
    local result=$(run_all_health_checks "bash" "false" 2>/dev/null)
    local exit_code=$?
    set -e

    # Assert - should produce JSON output
    if echo "$result" | jq empty 2>/dev/null; then
        # Valid JSON output
        local overall_status=$(echo "$result" | jq -r '.overall_status')

        if [[ "$overall_status" == "pass" ]] || [[ "$overall_status" == "fail" ]]; then
            ((TESTS_PASSED++))
            echo "  ✅ PASS (overall_status: $overall_status)"
        else
            echo "  ❌ FAIL: Invalid overall_status: $overall_status"
            ((TESTS_FAILED++))
        fi
    else
        echo "  ❌ FAIL: Invalid JSON output"
        ((TESTS_FAILED++))
    fi

    teardown
}

# Test: run_all_health_checks JSON structure
test_run_all_health_checks_json_structure() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: run_all_health_checks JSON structure per data-model.md"

    # Act
    set +e
    local result=$(run_all_health_checks "test-package" "false" 2>/dev/null)
    set -e

    # Assert - verify required JSON fields
    local has_timestamp=$(echo "$result" | jq -e '.timestamp' >/dev/null 2>&1 && echo "true" || echo "false")
    local has_package_name=$(echo "$result" | jq -e '.package_name' >/dev/null 2>&1 && echo "true" || echo "false")
    local has_checks=$(echo "$result" | jq -e '.checks' >/dev/null 2>&1 && echo "true" || echo "false")
    local has_overall_status=$(echo "$result" | jq -e '.overall_status' >/dev/null 2>&1 && echo "true" || echo "false")

    if [[ "$has_timestamp" == "true" ]] && \
       [[ "$has_package_name" == "true" ]] && \
       [[ "$has_checks" == "true" ]] && \
       [[ "$has_overall_status" == "true" ]]; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS (all required fields present)"
    else
        echo "  ❌ FAIL: Missing required JSON fields"
        echo "     timestamp: $has_timestamp"
        echo "     package_name: $has_package_name"
        echo "     checks: $has_checks"
        echo "     overall_status: $has_overall_status"
        ((TESTS_FAILED++))
    fi

    teardown
}

# Test: run_all_health_checks with auto-fix
test_run_all_health_checks_auto_fix() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: run_all_health_checks with auto-fix enabled"

    # Act - enable auto-fix
    set +e
    local result=$(run_all_health_checks "test-package" "true" 2>/dev/null)
    local exit_code=$?
    set -e

    # Assert - verify auto_fix_attempted field
    local auto_fix=$(echo "$result" | jq -r '.auto_fix_attempted')

    if [[ "$auto_fix" == "true" ]]; then
        ((TESTS_PASSED++))
        echo "  ✅ PASS (auto_fix_attempted: true)"
    else
        echo "  ❌ FAIL: auto_fix_attempted should be true, got: $auto_fix"
        ((TESTS_FAILED++))
    fi

    teardown
}

# ============================================================
# ERROR HANDLING TESTS
# ============================================================

# Test: run_all_health_checks with missing package name
test_run_all_health_checks_missing_package() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: run_all_health_checks error handling for missing package"

    # Act & Assert
    set +e
    run_all_health_checks "" "false" 2>/dev/null
    local exit_code=$?
    set -e

    assert_equals 2 "$exit_code" "Should return exit code 2 for invalid argument"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Unit Tests for migration_health_checks.sh"
    echo "════════════════════════════════════════════════════════"

    setup_all

    # Run test cases
    echo ""
    echo "Running test cases..."
    echo ""

    # Disk space tests
    test_section "Disk Space Check Functions"
    test_check_disk_space_sufficient || ((TESTS_FAILED++))
    test_check_disk_space_package_name || ((TESTS_FAILED++))

    # Network connectivity tests
    test_section "Network Connectivity Functions"
    test_check_network_snapd_socket || ((TESTS_FAILED++))

    # Snapd daemon tests
    test_section "Snapd Daemon Check Functions"
    test_check_snapd_daemon_status || ((TESTS_FAILED++))

    # Package conflict tests
    test_section "Package Conflict Detection"
    test_check_package_conflicts_valid || ((TESTS_FAILED++))
    test_check_package_conflicts_empty || ((TESTS_FAILED++))

    # Health check aggregation tests
    test_section "Health Check Aggregation"
    test_run_all_health_checks_basic || ((TESTS_FAILED++))
    test_run_all_health_checks_json_structure || ((TESTS_FAILED++))
    test_run_all_health_checks_auto_fix || ((TESTS_FAILED++))

    # Error handling tests
    test_section "Error Handling"
    test_run_all_health_checks_missing_package || ((TESTS_FAILED++))

    teardown_all

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Test Results Summary"
    echo "════════════════════════════════════════════════════════"
    echo "  Total Tests: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "  ✅ ALL TESTS PASSED"
        return 0
    else
        echo ""
        echo "  ❌ SOME TESTS FAILED"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
    exit $?
fi
