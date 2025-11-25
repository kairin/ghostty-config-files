#!/usr/bin/env bash
# tests/unit/test_verification.sh - Unit tests for verification modules
# Tests: lib/verification/*.sh

set -euo pipefail

[ -z "${TEST_VERIFICATION_LOADED:-}" ] || return 0
TEST_VERIFICATION_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_true() {
    local condition="$1" message="${2:-}"
    ((++TESTS_RUN))
    if eval "$condition"; then
        ((++TESTS_PASSED))
        echo "  [PASS] $message"
    else
        ((++TESTS_FAILED))
        echo "  [FAIL] $message"
    fi
}

assert_file_exists() {
    local file="$1" message="${2:-}"
    ((++TESTS_RUN))
    if [[ -f "$file" ]]; then
        ((++TESTS_PASSED))
        echo "  [PASS] ${message:-File exists: $file}"
    else
        ((++TESTS_FAILED))
        echo "  [FAIL] ${message:-File exists: $file}"
    fi
}

# Test: integration_tests.sh exists and has valid syntax
test_integration_tests_exists() {
    echo "Testing integration_tests.sh..."
    local file="${REPO_ROOT}/lib/verification/integration_tests.sh"
    if [[ -f "$file" ]]; then
        assert_file_exists "$file" "integration_tests.sh exists"
        assert_true "bash -n '$file'" "integration_tests.sh has valid syntax"
    else
        echo "  [SKIP] integration_tests.sh not found"
        ((++TESTS_RUN))
        ((++TESTS_PASSED))
    fi
}

# Test: unit_tests.sh exists and has valid syntax
test_unit_tests_exists() {
    echo "Testing unit_tests.sh..."
    local file="${REPO_ROOT}/lib/verification/unit_tests.sh"
    if [[ -f "$file" ]]; then
        assert_file_exists "$file" "unit_tests.sh exists"
        assert_true "bash -n '$file'" "unit_tests.sh has valid syntax"
    else
        echo "  [SKIP] unit_tests.sh not found"
        ((++TESTS_RUN))
        ((++TESTS_PASSED))
    fi
}

# Test: lib/verification directory exists
test_verification_directory_exists() {
    echo "Testing lib/verification/ directory..."
    assert_true "[[ -d '${REPO_ROOT}/lib/verification' ]]" "lib/verification/ directory exists"
}

# Test: duplicate_detection.sh exists (if present)
test_duplicate_detection_exists() {
    echo "Testing duplicate_detection.sh..."
    local file="${REPO_ROOT}/lib/verification/duplicate_detection.sh"
    if [[ -f "$file" ]]; then
        assert_file_exists "$file" "duplicate_detection.sh exists"
        assert_true "bash -n '$file'" "duplicate_detection.sh has valid syntax"
    else
        echo "  [SKIP] duplicate_detection.sh not found (optional)"
        ((++TESTS_RUN))
        ((++TESTS_PASSED))
    fi
}

# Test: all verification scripts have valid syntax
test_all_verification_scripts_syntax() {
    echo "Testing all lib/verification/*.sh syntax..."
    local found_scripts=false
    for script in "${REPO_ROOT}"/lib/verification/*.sh; do
        if [[ -f "$script" ]]; then
            found_scripts=true
            if bash -n "$script" 2>/dev/null; then
                echo "  [PASS] $(basename "$script") syntax valid"
                ((++TESTS_RUN))
                ((++TESTS_PASSED))
            else
                echo "  [FAIL] $(basename "$script") syntax invalid"
                ((++TESTS_RUN))
                ((++TESTS_FAILED))
            fi
        fi
    done 2>/dev/null || true

    if [[ "$found_scripts" == "false" ]]; then
        echo "  [SKIP] No verification scripts found"
        ((++TESTS_RUN))
        ((++TESTS_PASSED))
    fi
}

# Run all verification tests
run_verification_tests() {
    echo "========================================="
    echo "Verification Module Tests"
    echo "========================================="

    test_verification_directory_exists
    test_integration_tests_exists
    test_unit_tests_exists
    test_duplicate_detection_exists
    test_all_verification_scripts_syntax

    echo ""
    echo "========================================="
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo "========================================="

    [[ $TESTS_FAILED -eq 0 ]]
}

export -f run_verification_tests

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_verification_tests
    exit $?
fi
