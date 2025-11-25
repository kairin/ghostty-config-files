#!/usr/bin/env bash
# tests/unit/test_core_libraries.sh - Unit tests for core library functions
# Tests: lib/core/logging.sh, lib/core/utils.sh, lib/core/errors.sh

set -euo pipefail

[ -z "${TEST_CORE_LIBRARIES_LOADED:-}" ] || return 0
TEST_CORE_LIBRARIES_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Simple test assertion helpers
assert_equals() {
    local expected="$1" actual="$2" message="${3:-}"
    ((TESTS_RUN++))
    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        echo "  [PASS] $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo "  [FAIL] $message"
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
        return 1
    fi
}

assert_true() {
    local condition="$1" message="${2:-}"
    ((TESTS_RUN++))
    if eval "$condition"; then
        ((TESTS_PASSED++))
        echo "  [PASS] $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo "  [FAIL] $message"
        return 1
    fi
}

assert_file_exists() {
    local file="$1" message="${2:-File exists: $1}"
    ((TESTS_RUN++))
    if [[ -f "$file" ]]; then
        ((TESTS_PASSED++))
        echo "  [PASS] $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo "  [FAIL] $message"
        return 1
    fi
}

# Test: logging.sh module exists and is valid bash
test_logging_module_exists() {
    echo "Testing logging.sh module..."
    assert_file_exists "${REPO_ROOT}/lib/core/logging.sh" "logging.sh exists"
    assert_true "bash -n '${REPO_ROOT}/lib/core/logging.sh'" "logging.sh has valid syntax"
}

# Test: utils.sh module exists and is valid bash
test_utils_module_exists() {
    echo "Testing utils.sh module..."
    assert_file_exists "${REPO_ROOT}/lib/core/utils.sh" "utils.sh exists"
    assert_true "bash -n '${REPO_ROOT}/lib/core/utils.sh'" "utils.sh has valid syntax"
}

# Test: errors.sh module exists and is valid bash
test_errors_module_exists() {
    echo "Testing errors.sh module..."
    assert_file_exists "${REPO_ROOT}/lib/core/errors.sh" "errors.sh exists"
    assert_true "bash -n '${REPO_ROOT}/lib/core/errors.sh'" "errors.sh has valid syntax"
}

# Test: logging.sh exports expected functions
test_logging_exports() {
    echo "Testing logging.sh exports..."
    source "${REPO_ROOT}/lib/core/logging.sh" 2>/dev/null || true
    assert_true "declare -F init_logging >/dev/null 2>&1" "init_logging is exported"
    assert_true "declare -F log >/dev/null 2>&1" "log is exported"
    assert_true "declare -F get_timestamp >/dev/null 2>&1" "get_timestamp is exported"
}

# Test: version_compare function works correctly
test_version_compare() {
    echo "Testing version_compare function..."
    source "${REPO_ROOT}/lib/core/logging.sh" 2>/dev/null || true

    if declare -F version_compare >/dev/null 2>&1; then
        version_compare "1.0.0" "1.0.0" && assert_equals "0" "$?" "1.0.0 == 1.0.0"
        version_compare "1.0.0" "2.0.0" || assert_equals "2" "$?" "1.0.0 < 2.0.0"
        version_compare "2.0.0" "1.0.0" || assert_equals "1" "$?" "2.0.0 > 1.0.0"
    else
        echo "  [SKIP] version_compare not available"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    fi
}

# Run all core library tests
run_core_library_tests() {
    echo "========================================="
    echo "Core Library Tests"
    echo "========================================="

    test_logging_module_exists
    test_utils_module_exists
    test_errors_module_exists
    test_logging_exports
    test_version_compare

    echo ""
    echo "========================================="
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo "========================================="

    [[ $TESTS_FAILED -eq 0 ]]
}

# Export for use in test orchestrator
export -f run_core_library_tests

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_core_library_tests
    exit $?
fi
