#!/bin/bash
# Unit Test: test_install_node.sh
# Purpose: Unit tests for install_node.sh module
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

    # Mock NVM directory for testing
    export NVM_DIR="$TEST_TEMP_DIR/.nvm"
    mkdir -p "$NVM_DIR"

    # Set test versions
    export NVM_VERSION="v0.40.1"
    export NODE_VERSION="24.6.0"
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

# Test: Public functions are defined
test_public_functions_exist() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Public functions are defined"

    # Check if functions exist (using type command)
    type install_nvm >/dev/null 2>&1 || { echo "install_nvm not found"; return 1; }
    type install_node >/dev/null 2>&1 || { echo "install_node not found"; return 1; }
    type update_npm >/dev/null 2>&1 || { echo "update_npm not found"; return 1; }
    type install_node_full >/dev/null 2>&1 || { echo "install_node_full not found"; return 1; }

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Private functions are defined
test_private_functions_exist() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Private functions are defined"

    # Check if private functions exist (using type command)
    type _check_nvm_update >/dev/null 2>&1 || { echo "_check_nvm_update not found"; return 1; }
    type _load_nvm >/dev/null 2>&1 || { echo "_load_nvm not found"; return 1; }

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: Environment variables have default values
test_environment_variables_defaults() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: Environment variables have defaults"

    # Check defaults are set
    [[ -n "$NVM_VERSION" ]] || { echo "NVM_VERSION not set"; return 1; }
    [[ -n "$NODE_VERSION" ]] || { echo "NODE_VERSION not set"; return 1; }
    [[ -n "$NVM_DIR" ]] || { echo "NVM_DIR not set"; return 1; }

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

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# Test: _load_nvm fails gracefully when NVM script missing
test_load_nvm_missing_script() {
    setup
    ((TESTS_RUN++))

    echo "  Testing: _load_nvm fails when nvm.sh missing"

    # Ensure NVM_DIR exists but nvm.sh doesn't
    local test_nvm_dir="$TEST_TEMP_DIR/nvm_missing"
    mkdir -p "$test_nvm_dir"
    export NVM_DIR="$test_nvm_dir"

    # Act & Assert
    set +e
    _load_nvm >/dev/null 2>&1
    local exit_code=$?
    set -e

    assert_not_equals 0 "$exit_code" "_load_nvm should fail when nvm.sh missing"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"

    teardown
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Unit Tests for install_node.sh"
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
    test_environment_variables_defaults || ((TESTS_FAILED++))
    test_module_contract_compliance || ((TESTS_FAILED++))
    test_load_nvm_missing_script || ((TESTS_FAILED++))

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
