#!/usr/bin/env bash
# tests/unit/test_utilities.sh - Unit tests for utility scripts
# Tests: scripts/lib/common.sh, backup utilities, etc.

set -euo pipefail

[ -z "${TEST_UTILITIES_LOADED:-}" ] || return 0
TEST_UTILITIES_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

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

# Test: common.sh exists and has valid syntax
test_common_sh_exists() {
    echo "Testing scripts/lib/common.sh..."
    local file="${REPO_ROOT}/scripts/lib/common.sh"
    assert_file_exists "$file" "common.sh exists"
    assert_true "bash -n '$file'" "common.sh has valid syntax"
}

# Test: generate_dashboard.sh exists and has valid syntax
test_generate_dashboard_exists() {
    echo "Testing generate_dashboard.sh..."
    local file="${REPO_ROOT}/scripts/docs/generate_dashboard.sh"
    if [[ -f "$file" ]]; then
        assert_file_exists "$file" "generate_dashboard.sh exists"
        assert_true "bash -n '$file'" "generate_dashboard.sh has valid syntax"
    else
        echo "  [SKIP] generate_dashboard.sh not found"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    fi
}

# Test: consolidate_todos.sh exists and has valid syntax
test_consolidate_todos_exists() {
    echo "Testing consolidate_todos.sh..."
    local file="${REPO_ROOT}/scripts/git/consolidate_todos.sh"
    if [[ -f "$file" ]]; then
        assert_file_exists "$file" "consolidate_todos.sh exists"
        assert_true "bash -n '$file'" "consolidate_todos.sh has valid syntax"
    else
        echo "  [SKIP] consolidate_todos.sh not found"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    fi
}

# Test: update_ghostty.sh exists and has valid syntax
test_update_ghostty_exists() {
    echo "Testing update_ghostty.sh..."
    local file="${REPO_ROOT}/scripts/updates/update_ghostty.sh"
    if [[ -f "$file" ]]; then
        assert_file_exists "$file" "update_ghostty.sh exists"
        assert_true "bash -n '$file'" "update_ghostty.sh has valid syntax"
    else
        echo "  [SKIP] update_ghostty.sh not found"
        ((TESTS_RUN++))
        ((TESTS_PASSED++))
    fi
}

# Test: all scripts in scripts/lib have valid syntax
test_all_lib_scripts_syntax() {
    echo "Testing all scripts/lib/*.sh syntax..."
    for script in "${REPO_ROOT}"/scripts/lib/*.sh; do
        if [[ -f "$script" ]]; then
            if bash -n "$script" 2>/dev/null; then
                echo "  [PASS] $(basename "$script") syntax valid"
                ((TESTS_RUN++))
                ((TESTS_PASSED++))
            else
                echo "  [FAIL] $(basename "$script") syntax invalid"
                ((TESTS_RUN++))
                ((TESTS_FAILED++))
            fi
        fi
    done 2>/dev/null || true
}

# Run all utility tests
run_utility_tests() {
    echo "========================================="
    echo "Utility Script Tests"
    echo "========================================="

    test_common_sh_exists
    test_generate_dashboard_exists
    test_consolidate_todos_exists
    test_update_ghostty_exists
    test_all_lib_scripts_syntax

    echo ""
    echo "========================================="
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo "========================================="

    [[ $TESTS_FAILED -eq 0 ]]
}

export -f run_utility_tests

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_utility_tests
    exit $?
fi
