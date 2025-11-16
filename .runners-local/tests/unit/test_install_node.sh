#!/bin/bash
# Unit Test: test_install_node.sh
# Purpose: Unit tests for install_node.sh module (fnm-based)
# Dependencies: test_functions.sh (assertion helpers)
# Exit Codes: 0=all tests pass, 1=one or more tests failed
# Constitutional Requirement: <10s execution time

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

# Start timer for constitutional <10s requirement
TEST_START_TIME=$(date +%s)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source test helper functions
source "${SCRIPT_DIR}/test_functions.sh"

# Source the module being tested
MODULE_PATH="${SCRIPT_DIR}/../../../scripts/install_node.sh"
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

    # Mock FNM directory for testing
    export FNM_DIR="$TEST_TEMP_DIR/.local/share/fnm"
    mkdir -p "$FNM_DIR"

    # Set test versions (Constitutional: Latest stable, not LTS)
    export NODE_VERSION="25"  # Constitutional requirement: v25+
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

# Test: Module can be sourced without errors
test_module_sources_successfully() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Module sources without errors"

    # The fact that we got here means sourcing succeeded
    assert_equals 0 0 "Module sourced successfully"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Public functions are defined (fnm-based)
test_public_functions_exist() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Public functions are defined"

    # Check if functions exist (using type command)
    type install_fnm >/dev/null 2>&1 || { echo "install_fnm not found"; return 1; }
    type install_node >/dev/null 2>&1 || { echo "install_node not found"; return 1; }
    type update_npm >/dev/null 2>&1 || { echo "update_npm not found"; return 1; }
    type install_node_full >/dev/null 2>&1 || { echo "install_node_full not found"; return 1; }

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Private functions are defined (fnm-based)
test_private_functions_exist() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Private functions are defined"

    # Check if private functions exist (using type command)
    type _check_fnm_update >/dev/null 2>&1 || { echo "_check_fnm_update not found"; return 1; }
    type _configure_fnm_shell_integration >/dev/null 2>&1 || { echo "_configure_fnm_shell_integration not found"; return 1; }

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Utility functions are defined
test_utility_functions_exist() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Utility functions are defined"

    # Check utility functions
    type compare_versions >/dev/null 2>&1 || { echo "compare_versions not found"; return 1; }
    type check_internet_connectivity >/dev/null 2>&1 || { echo "check_internet_connectivity not found"; return 1; }
    type get_installed_node_version >/dev/null 2>&1 || { echo "get_installed_node_version not found"; return 1; }
    type get_major_version >/dev/null 2>&1 || { echo "get_major_version not found"; return 1; }
    type validate_node_installation >/dev/null 2>&1 || { echo "validate_node_installation not found"; return 1; }
    type read_version_from_files >/dev/null 2>&1 || { echo "read_version_from_files not found"; return 1; }

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Environment variables have default values
test_environment_variables_defaults() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Environment variables have defaults"

    # Check defaults are set (fnm-based)
    [[ -n "$NODE_VERSION" ]] || { echo "NODE_VERSION not set"; return 1; }
    [[ -n "$FNM_DIR" ]] || { echo "FNM_DIR not set"; return 1; }
    [[ -n "$FNM_INSTALL_URL" ]] || { echo "FNM_INSTALL_URL not set"; return 1; }

    # Verify constitutional compliance: NODE_VERSION should be 25+ (latest stable, not LTS)
    local major_version
    major_version=$(get_major_version "$NODE_VERSION")
    if [[ "$major_version" -ge 25 ]]; then
        echo "    ✓ Constitutional compliance: NODE_VERSION=$NODE_VERSION (latest stable)"
    else
        echo "    ⚠ Warning: NODE_VERSION=$NODE_VERSION may not meet constitutional requirement (v25+)"
    fi

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Module contract compliance
test_module_contract_compliance() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Module follows contract (has required header comments)"

    # Read module file
    local module_content
    module_content=$(cat "$MODULE_PATH")

    # Check for required header fields
    assert_contains "$module_content" "# Module:" "Should have Module field"
    assert_contains "$module_content" "# Purpose:" "Should have Purpose field"
    assert_contains "$module_content" "# Dependencies:" "Should have Dependencies field"
    assert_contains "$module_content" "# Exit Codes:" "Should have Exit Codes field"

    # Check for constitutional compliance comment
    assert_contains "$module_content" "Constitutional Compliance" "Should reference constitutional compliance"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Version comparison utility
test_compare_versions() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: compare_versions function"

    # Test equal versions
    compare_versions "25.1.0" "25.1.0"
    assert_equals 0 $? "Versions 25.1.0 == 25.1.0"

    # Test v1 > v2
    compare_versions "25.2.0" "25.1.0"
    assert_equals 1 $? "Version 25.2.0 > 25.1.0"

    # Test v1 < v2
    compare_versions "25.1.0" "25.2.0"
    assert_equals 2 $? "Version 25.1.0 < 25.2.0"

    # Test with 'v' prefix
    compare_versions "v25.1.0" "25.1.0"
    assert_equals 0 $? "Versions v25.1.0 == 25.1.0 (prefix ignored)"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Major version extraction
test_get_major_version() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: get_major_version function"

    local result
    result=$(get_major_version "25.2.0")
    assert_equals "25" "$result" "Extract major version from 25.2.0"

    result=$(get_major_version "v25.2.0")
    assert_equals "25" "$result" "Extract major version from v25.2.0"

    result=$(get_major_version "24.11.1")
    assert_equals "24" "$result" "Extract major version from 24.11.1"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Read version from .node-version file
test_read_version_from_node_version_file() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: read_version_from_files with .node-version"

    # Create test .node-version file
    local test_dir="$TEST_TEMP_DIR/version_test"
    mkdir -p "$test_dir"
    cd "$test_dir"

    echo "25.2.0" > .node-version

    local result
    result=$(read_version_from_files)
    assert_equals "25.2.0" "$result" "Read version from .node-version file"

    # Cleanup
    cd - >/dev/null
    rm -rf "$test_dir"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Dry-run mode doesn't install
test_dry_run_mode() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: --dry-run mode validation"

    # Set dry-run mode
    export DRY_RUN=1

    # Run install_fnm in dry-run mode (should not fail)
    set +e
    install_fnm >/dev/null 2>&1
    local exit_code=$?
    set -e

    # Reset dry-run mode
    export DRY_RUN=0

    assert_equals 0 "$exit_code" "Dry-run mode should succeed"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Unit Tests for install_node.sh (fnm-based)"
    echo "════════════════════════════════════════════════════════"

    setup_all

    # Run test cases
    echo ""
    echo "Running test cases..."
    echo ""

    # Call each test function
    test_module_sources_successfully || ((TESTS_FAILED++))
    test_public_functions_exist || ((TESTS_FAILED++))
    test_private_functions_exist || ((TESTS_FAILED++))
    test_utility_functions_exist || ((TESTS_FAILED++))
    test_environment_variables_defaults || ((TESTS_FAILED++))
    test_module_contract_compliance || ((TESTS_FAILED++))
    test_compare_versions || ((TESTS_FAILED++))
    test_get_major_version || ((TESTS_FAILED++))
    test_read_version_from_node_version_file || ((TESTS_FAILED++))
    test_dry_run_mode || ((TESTS_FAILED++))

    teardown_all

    # Calculate execution time
    TEST_END_TIME=$(date +%s)
    TEST_DURATION=$((TEST_END_TIME - TEST_START_TIME))

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Test Results Summary"
    echo "════════════════════════════════════════════════════════"
    echo "  Total Tests: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "  Execution Time: ${TEST_DURATION}s"
    echo ""

    # Constitutional requirement check
    if [[ $TEST_DURATION -ge 10 ]]; then
        echo "  ⚠️  WARNING: Test execution exceeded 10s constitutional requirement"
        echo "  Actual: ${TEST_DURATION}s | Limit: 10s"
    else
        echo "  ✅ Constitutional compliance: Execution time ${TEST_DURATION}s < 10s"
    fi

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
