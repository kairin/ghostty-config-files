#!/usr/bin/env bash
# test_install_uv.sh - Unit tests for scripts/install_uv.sh
# Constitutional requirement: <10s execution time

set -euo pipefail

# Test framework setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Source the module under test
# shellcheck source=scripts/install_uv.sh
source "${PROJECT_ROOT}/scripts/install_uv.sh"

# Test utilities
TESTS_PASSED=0
TESTS_FAILED=0
TEST_START_TIME=$(date +%s)

#######################################
# Test utility: Assert equals
# Arguments:
#   $1 - Expected value
#   $2 - Actual value
#   $3 - Test name
#######################################
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    if [[ "${expected}" == "${actual}" ]]; then
        echo "✓ PASS: ${test_name}"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "✗ FAIL: ${test_name}"
        echo "  Expected: ${expected}"
        echo "  Actual: ${actual}"
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

#######################################
# Test utility: Assert command succeeds
# Arguments:
#   $1 - Command to test
#   $2 - Test name
#######################################
assert_success() {
    local test_name="$2"

    if eval "$1" > /dev/null 2>&1; then
        echo "✓ PASS: ${test_name}"
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo "✗ FAIL: ${test_name}"
        echo "  Command failed: $1"
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

#######################################
# Test: Module can be sourced without errors
#######################################
test_module_source() {
    # Module is already sourced at top of file
    assert_equals "1" "1" "Module sources without errors"
}

#######################################
# Test: UV_INSTALL_DIR environment variable exists
#######################################
test_uv_install_dir_set() {
    if [[ -n "${UV_INSTALL_DIR:-}" ]]; then
        assert_equals "1" "1" "UV_INSTALL_DIR environment variable set"
    else
        assert_equals "1" "0" "UV_INSTALL_DIR environment variable set"
    fi
}

#######################################
# Test: UV_INSTALL_URL environment variable exists
#######################################
test_uv_install_url_set() {
    if [[ -n "${UV_INSTALL_URL:-}" ]]; then
        assert_equals "1" "1" "UV_INSTALL_URL environment variable set"
    else
        assert_equals "1" "0" "UV_INSTALL_URL environment variable set"
    fi
}

#######################################
# Test: install_uv function exists
#######################################
test_install_uv_function_exists() {
    if declare -f install_uv > /dev/null; then
        assert_equals "1" "1" "install_uv function exists"
    else
        assert_equals "1" "0" "install_uv function exists"
    fi
}

#######################################
# Test: update_uv function exists
#######################################
test_update_uv_function_exists() {
    if declare -f update_uv > /dev/null; then
        assert_equals "1" "1" "update_uv function exists"
    else
        assert_equals "1" "0" "update_uv function exists"
    fi
}

#######################################
# Test: install_uv_tool function exists
#######################################
test_install_uv_tool_function_exists() {
    if declare -f install_uv_tool > /dev/null; then
        assert_equals "1" "1" "install_uv_tool function exists"
    else
        assert_equals "1" "0" "install_uv_tool function exists"
    fi
}

#######################################
# Test: update_uv_tool function exists
#######################################
test_update_uv_tool_function_exists() {
    if declare -f update_uv_tool > /dev/null; then
        assert_equals "1" "1" "update_uv_tool function exists"
    else
        assert_equals "1" "0" "update_uv_tool function exists"
    fi
}

#######################################
# Test: install_uv_full function exists
#######################################
test_install_uv_full_function_exists() {
    if declare -f install_uv_full > /dev/null; then
        assert_equals "1" "1" "install_uv_full function exists"
    else
        assert_equals "1" "0" "install_uv_full function exists"
    fi
}

#######################################
# Test: Examples directory exists
#######################################
test_examples_directory_exists() {
    if [[ -d "${PROJECT_ROOT}/scripts/examples/python" ]]; then
        assert_equals "1" "1" "Python examples directory exists"
    else
        assert_equals "1" "0" "Python examples directory exists"
    fi
}

#######################################
# Test: example_requests.py exists and is executable
#######################################
test_example_requests_exists() {
    local example_file="${PROJECT_ROOT}/scripts/examples/python/example_requests.py"
    if [[ -f "${example_file}" ]] && [[ -x "${example_file}" ]]; then
        assert_equals "1" "1" "example_requests.py exists and is executable"
    else
        assert_equals "1" "0" "example_requests.py exists and is executable"
    fi
}

#######################################
# Test: pyproject.toml exists
#######################################
test_pyproject_toml_exists() {
    local pyproject_file="${PROJECT_ROOT}/scripts/examples/python/pyproject.toml"
    if [[ -f "${pyproject_file}" ]]; then
        assert_equals "1" "1" "pyproject.toml exists"
    else
        assert_equals "1" "0" "pyproject.toml exists"
    fi
}

#######################################
# Test: Example scripts README exists
#######################################
test_examples_readme_exists() {
    local readme_file="${PROJECT_ROOT}/scripts/examples/python/README.md"
    if [[ -f "${readme_file}" ]]; then
        assert_equals "1" "1" "Examples README.md exists"
    else
        assert_equals "1" "0" "Examples README.md exists"
    fi
}

#######################################
# Test: Module execution time <10s (constitutional requirement)
#######################################
test_execution_time_under_10s() {
    local test_end_time=$(date +%s)
    local execution_time=$((test_end_time - TEST_START_TIME))

    if [[ ${execution_time} -lt 10 ]]; then
        assert_equals "1" "1" "Test execution time under 10 seconds (${execution_time}s)"
    else
        assert_equals "1" "0" "Test execution time under 10 seconds (${execution_time}s - FAILED)"
    fi
}

#######################################
# Main test runner
#######################################
main() {
    echo "=========================================="
    echo "Unit Tests: scripts/install_uv.sh"
    echo "=========================================="
    echo ""

    # Run all tests
    test_module_source
    test_uv_install_dir_set
    test_uv_install_url_set
    test_install_uv_function_exists
    test_update_uv_function_exists
    test_install_uv_tool_function_exists
    test_update_uv_tool_function_exists
    test_install_uv_full_function_exists
    test_examples_directory_exists
    test_example_requests_exists
    test_pyproject_toml_exists
    test_examples_readme_exists
    test_execution_time_under_10s

    # Summary
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo "Passed: ${TESTS_PASSED}"
    echo "Failed: ${TESTS_FAILED}"
    echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    if [[ ${TESTS_FAILED} -eq 0 ]]; then
        echo "✓ ALL TESTS PASSED"
        return 0
    else
        echo "✗ SOME TESTS FAILED"
        return 1
    fi
}

# Execute tests
main "$@"
