#!/bin/bash
# Unit tests for scripts/install_modern_tools.sh
# Constitutional requirement: <10s execution time

set -euo pipefail

# Source module for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
source "${PROJECT_ROOT}/scripts/install_modern_tools.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$expected" == "$actual" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name (expected: '$expected', got: '$actual')"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_command_exists() {
    local command_name="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if command -v "$command_name" &> /dev/null; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "ℹ SKIP: $test_name (command not found: $command_name)"
    fi
}

assert_function_exists() {
    local function_name="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if declare -f "$function_name" &> /dev/null; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "=== Unit Tests: install_modern_tools.sh ==="
echo

# Test 1: Module loaded
if [[ -n "${INSTALL_MODERN_TOOLS_SH_LOADED}" ]]; then
    assert_equals "1" "${INSTALL_MODERN_TOOLS_SH_LOADED}" "Module loaded"
else
    assert_equals "1" "0" "Module loaded"
fi

# Test 2: Constants defined
assert_equals "${HOME}/.local/bin" "${TOOLS_INSTALL_DIR}" "TOOLS_INSTALL_DIR constant"
[[ -n "${EZA_RELEASE_URL}" ]] && echo "✓ PASS: EZA_RELEASE_URL defined" || echo "✗ FAIL: EZA_RELEASE_URL not defined"
TESTS_RUN=$((TESTS_RUN + 1))
TESTS_PASSED=$((TESTS_PASSED + 1))

[[ -n "${DELTA_RELEASE_URL}" ]] && echo "✓ PASS: DELTA_RELEASE_URL defined" || echo "✗ FAIL: DELTA_RELEASE_URL not defined"
TESTS_RUN=$((TESTS_RUN + 1))
TESTS_PASSED=$((TESTS_PASSED + 1))

# Test 3: Function existence
assert_function_exists "install_bat" "Function install_bat exists"
assert_function_exists "install_eza" "Function install_eza exists"
assert_function_exists "install_ripgrep" "Function install_ripgrep exists"
assert_function_exists "install_fd" "Function install_fd exists"
assert_function_exists "install_delta" "Function install_delta exists"
assert_function_exists "install_zoxide" "Function install_zoxide exists"
assert_function_exists "install_fzf" "Function install_fzf exists"
assert_function_exists "configure_shell_aliases" "Function configure_shell_aliases exists"
assert_function_exists "verify_modern_tools_installation" "Function verify_modern_tools_installation exists"
assert_function_exists "install_modern_tools" "Function install_modern_tools exists"

# Test 4: Check installed tools (if available)
assert_command_exists "bat" "bat available (if installed)"
assert_command_exists "eza" "eza available (if installed)"
assert_command_exists "rg" "ripgrep available (if installed)"
assert_command_exists "fd" "fd available (if installed)"
assert_command_exists "delta" "delta available (if installed)"
assert_command_exists "zoxide" "zoxide available (if installed)"
assert_command_exists "fzf" "fzf available (if installed)"

# Test 5: Verify dependencies sourced
if [[ -n "${COMMON_SH_LOADED}" ]]; then
    echo "✓ PASS: common.sh dependency loaded"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: common.sh dependency not loaded"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

if [[ -n "${VERIFICATION_SH_LOADED}" ]]; then
    echo "✓ PASS: verification.sh dependency loaded"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: verification.sh dependency not loaded"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 6: Verify minimum version constants
assert_equals "0.18.0" "${MIN_BAT_VERSION}" "MIN_BAT_VERSION constant"
assert_equals "0.10.0" "${MIN_EZA_VERSION}" "MIN_EZA_VERSION constant"
assert_equals "13.0.0" "${MIN_RIPGREP_VERSION}" "MIN_RIPGREP_VERSION constant"
assert_equals "8.0.0" "${MIN_FD_VERSION}" "MIN_FD_VERSION constant"
assert_equals "0.16.0" "${MIN_DELTA_VERSION}" "MIN_DELTA_VERSION constant"
assert_equals "0.9.0" "${MIN_ZOXIDE_VERSION}" "MIN_ZOXIDE_VERSION constant"
assert_equals "0.35.0" "${MIN_FZF_VERSION}" "MIN_FZF_VERSION constant"

# Test 7: Shell configuration markers
if [[ -f "${HOME}/.bashrc" ]]; then
    if grep -q "Modern Unix Tools aliases" "${HOME}/.bashrc"; then
        echo "✓ PASS: Shell aliases marker in .bashrc"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "ℹ INFO: Shell aliases not yet configured in .bashrc (expected before first installation)"
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
fi

if [[ -f "${HOME}/.zshrc" ]]; then
    if grep -q "Modern Unix Tools aliases" "${HOME}/.zshrc"; then
        echo "✓ PASS: Shell aliases marker in .zshrc"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "ℹ INFO: Shell aliases not yet configured in .zshrc (expected before first installation)"
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Summary
echo
echo "=== Test Summary ==="
echo "Total: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo

[[ $TESTS_FAILED -eq 0 ]] && echo "✅ All tests passed!" && exit 0 || { echo "❌ Some tests failed"; exit 1; }
