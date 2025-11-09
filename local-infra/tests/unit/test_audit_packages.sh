#!/bin/bash
# Unit Test: test_audit_packages.sh
# Purpose: Unit tests for audit_packages.sh module
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
MODULE_PATH="${SCRIPT_DIR}/../../../scripts/audit_packages.sh"
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

    # Override cache directory for tests
    export CACHE_DIR="$TEST_TEMP_DIR/cache"
    mkdir -p "$CACHE_DIR"
}

# Teardown: Run after all tests
teardown_all() {
    echo "🧹 Cleaning up test environment..."

    # Remove temporary directory
    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed temp directory: $TEST_TEMP_DIR"
    fi
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
# TEST CASES
# ============================================================

# Test: Equivalence score calculation - exact name and version match
test_equivalence_score_exact_match() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: calculate_equivalence_score with exact match"

    # Arrange
    local apt_pkg="firefox"
    local apt_version="120.0"
    local snap_data='{"name":"firefox","version":"120.0"}'

    # Act
    local result=$(calculate_equivalence_score "$apt_pkg" "$apt_version" "$snap_data")
    local total_score=$(echo "$result" | jq '.total_score')

    # Assert
    assert_equals "70" "$total_score" "Exact name and version should score 70 (20+30+15+10 default)"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Equivalence score calculation - partial name match
test_equivalence_score_partial_match() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: calculate_equivalence_score with partial name match"

    # Arrange
    local apt_pkg="firefox"
    local apt_version="120.0"
    local snap_data='{"name":"firefox-esr","version":"120.0"}'

    # Act
    local result=$(calculate_equivalence_score "$apt_pkg" "$apt_version" "$snap_data")
    local name_score=$(echo "$result" | jq '.breakdown.name_match')

    # Assert
    assert_equals "15" "$name_score" "Partial name match should score 15"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Equivalence score calculation - version mismatch
test_equivalence_score_version_mismatch() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: calculate_equivalence_score with version mismatch"

    # Arrange
    local apt_pkg="firefox"
    local apt_version="120.0"
    local snap_data='{"name":"firefox","version":"121.0"}'

    # Act
    local result=$(calculate_equivalence_score "$apt_pkg" "$apt_version" "$snap_data")
    local version_score=$(echo "$result" | jq '.breakdown.version_compat')

    # Assert
    assert_equals "20" "$version_score" "Different version but snap exists should score 20"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Publisher verification - verified publisher
test_publisher_verification_verified() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: verify_snap_publisher with verified publisher"

    # Arrange
    local snap_data='{"publisher":{"id":"canonical","username":"canonical","validation":"verified"}}'

    # Act
    local result=$(verify_snap_publisher "$snap_data")
    local is_verified=$(echo "$result" | jq '.is_verified')

    # Assert
    assert_equals "true" "$is_verified" "Verified publisher should return is_verified=true"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Publisher verification - starred publisher
test_publisher_verification_starred() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: verify_snap_publisher with starred publisher"

    # Arrange
    local snap_data='{"publisher":{"id":"mozilla","username":"mozilla","validation":"starred"}}'

    # Act
    local result=$(verify_snap_publisher "$snap_data")
    local is_verified=$(echo "$result" | jq '.is_verified')

    # Assert
    assert_equals "true" "$is_verified" "Starred publisher should return is_verified=true"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Publisher verification - unverified publisher
test_publisher_verification_unverified() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: verify_snap_publisher with unverified publisher"

    # Arrange
    local snap_data='{"publisher":{"id":"random-dev","username":"randomdev","validation":"unverified"}}'

    # Act
    local result=$(verify_snap_publisher "$snap_data")
    local is_verified=$(echo "$result" | jq '.is_verified')

    # Assert
    assert_equals "false" "$is_verified" "Unverified publisher should return is_verified=false"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Text report formatting - basic functionality
test_format_text_report_basic() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: format_text_report with sample data"

    # Arrange
    local packages_json='[{"name":"firefox","version":"120.0","install_method":"apt","size_kb":234567}]'

    # Act
    local result=$(format_text_report "$packages_json")

    # Assert
    assert_contains "$result" "Package Migration Audit Report" "Report should contain header"
    assert_contains "$result" "Total Packages Found: 1" "Report should show package count"
    assert_contains "$result" "firefox" "Report should contain package name"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Cache TTL validation - cache hit
test_cache_ttl_validation_hit() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Cache TTL validation with fresh cache"

    # Arrange
    local cache_file="$CACHE_DIR/test-cache.json"
    echo '{"test":"data"}' > "$cache_file"
    local CACHE_TTL_SECONDS=3600

    # Get cache age
    local cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))

    # Assert
    assert_true "[[ $cache_age -lt $CACHE_TTL_SECONDS ]]" "Fresh cache should be within TTL"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Cache TTL validation - cache miss
test_cache_ttl_validation_miss() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Cache TTL validation with expired cache"

    # Arrange
    local cache_file="$CACHE_DIR/test-cache-old.json"
    echo '{"test":"data"}' > "$cache_file"

    # Make file appear old (simulate with very short TTL)
    local CACHE_TTL_SECONDS=0
    sleep 1

    local cache_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))

    # Assert
    assert_false "[[ $cache_age -lt $CACHE_TTL_SECONDS ]]" "Old cache should exceed TTL"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Unit Tests for audit_packages.sh"
    echo "════════════════════════════════════════════════════════"

    setup_all

    # Run test cases
    echo ""
    echo "Running test cases..."
    echo ""

    # Equivalence scoring tests
    test_equivalence_score_exact_match || ((TESTS_FAILED++))
    test_equivalence_score_partial_match || ((TESTS_FAILED++))
    test_equivalence_score_version_mismatch || ((TESTS_FAILED++))

    # Publisher verification tests
    test_publisher_verification_verified || ((TESTS_FAILED++))
    test_publisher_verification_starred || ((TESTS_FAILED++))
    test_publisher_verification_unverified || ((TESTS_FAILED++))

    # Report formatting tests
    test_format_text_report_basic || ((TESTS_FAILED++))

    # Cache tests
    test_cache_ttl_validation_hit || ((TESTS_FAILED++))
    test_cache_ttl_validation_miss || ((TESTS_FAILED++))

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
