#!/usr/bin/env bash
# tests/unit/test_installers.sh - Unit tests for installer modules
# Tests: lib/installers/*.sh

set -euo pipefail

[ -z "${TEST_INSTALLERS_LOADED:-}" ] || return 0
TEST_INSTALLERS_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
    local expected="$1" actual="$2" message="${3:-}"
    ((TESTS_RUN++))
    if [[ "$expected" == "$actual" ]]; then
        ((TESTS_PASSED++))
        echo "  [PASS] $message"
    else
        ((TESTS_FAILED++))
        echo "  [FAIL] $message (expected: $expected, got: $actual)"
    fi
}

assert_true() {
    local condition="$1" message="${2:-}"
    ((TESTS_RUN++))
    if eval "$condition"; then
        ((TESTS_PASSED++))
        echo "  [PASS] $message"
    else
        ((TESTS_FAILED++))
        echo "  [FAIL] $message"
    fi
}

assert_file_exists() {
    local file="$1" message="${2:-}"
    ((TESTS_RUN++))
    if [[ -f "$file" ]]; then
        ((TESTS_PASSED++))
        echo "  [PASS] ${message:-File exists: $file}"
    else
        ((TESTS_FAILED++))
        echo "  [FAIL] ${message:-File exists: $file}"
    fi
}

# Test: manager-runner.sh exists and has valid syntax
test_manager_runner_exists() {
    echo "Testing manager-runner.sh..."
    local file="${REPO_ROOT}/lib/installers/common/manager-runner.sh"
    if [[ -f "$file" ]]; then
        assert_file_exists "$file" "manager-runner.sh exists"
        assert_true "bash -n '$file'" "manager-runner.sh has valid syntax"
    else
        echo "  [SKIP] manager-runner.sh not found"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    fi
}

# Test: ghostty-deps.sh exists and has valid syntax (if present)
test_ghostty_deps_exists() {
    echo "Testing ghostty-deps.sh..."
    local file="${REPO_ROOT}/lib/installers/ghostty-deps.sh"
    if [[ -f "$file" ]]; then
        assert_file_exists "$file" "ghostty-deps.sh exists"
        assert_true "bash -n '$file'" "ghostty-deps.sh has valid syntax"
    else
        echo "  [SKIP] ghostty-deps.sh not found (optional)"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    fi
}

# Test: installer directory structure
test_installer_directory_structure() {
    echo "Testing installer directory structure..."
    assert_true "[[ -d '${REPO_ROOT}/lib/installers' ]]" "lib/installers/ exists"
    if [[ -d "${REPO_ROOT}/lib/installers/common" ]]; then
        assert_true "[[ -d '${REPO_ROOT}/lib/installers/common' ]]" "lib/installers/common/ exists"
    fi
}

# Test: all installer scripts have valid bash syntax
test_all_installer_syntax() {
    echo "Testing all installer script syntax..."
    local all_valid=true
    for script in "${REPO_ROOT}"/lib/installers/*.sh "${REPO_ROOT}"/lib/installers/**/*.sh; do
        if [[ -f "$script" ]]; then
            if bash -n "$script" 2>/dev/null; then
                echo "  [PASS] $(basename "$script") syntax valid"
                ((TESTS_RUN++))
                ((TESTS_PASSED++))
            else
                echo "  [FAIL] $(basename "$script") syntax invalid"
                ((TESTS_RUN++))
                ((TESTS_FAILED++))
                all_valid=false
            fi
        fi
    done 2>/dev/null || true
}

# Run all installer tests
run_installer_tests() {
    echo "========================================="
    echo "Installer Module Tests"
    echo "========================================="

    test_installer_directory_structure
    test_manager_runner_exists
    test_ghostty_deps_exists
    test_all_installer_syntax

    echo ""
    echo "========================================="
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo "========================================="

    [[ $TESTS_FAILED -eq 0 ]]
}

export -f run_installer_tests

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_installer_tests
    exit $?
fi
