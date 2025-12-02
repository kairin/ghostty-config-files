#!/bin/bash
# Unit tests for scripts/005-confirm/confirm_ide_fonts.sh
# Constitutional requirement: <10s execution time

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
START_TIME=$(date +%s)

# ============================================================
# TEST HELPER FUNCTIONS
# ============================================================

assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$expected" == "$actual" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_file_exists() {
    local file_path="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -f "$file_path" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "    File not found: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_function_defined() {
    local func_name="$1"
    local test_name="$2"
    local script="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if grep -q "^${func_name}()" "$script" || grep -q "function ${func_name}" "$script"; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "    Function not found: $func_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================
# TEST SUITE
# ============================================================

echo "=== Unit Tests: confirm_ide_fonts.sh ==="
echo ""
echo "Performance requirement: <10s execution time"
echo ""

CONFIRM_SCRIPT="${PROJECT_ROOT}/scripts/005-confirm/confirm_ide_fonts.sh"

# ============================================================
# TEST GROUP 1: Script Existence and Syntax
# ============================================================

echo "TEST GROUP 1: Script Validation"
echo "================================"

# Test 1: Script file exists
assert_file_exists "$CONFIRM_SCRIPT" "confirm_ide_fonts.sh exists"

# Test 2: Script is executable
TESTS_RUN=$((TESTS_RUN + 1))
if [[ -x "$CONFIRM_SCRIPT" ]]; then
    echo "✓ PASS: Script is executable"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Script is not executable"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 3: Script has valid bash syntax
TESTS_RUN=$((TESTS_RUN + 1))
if bash -n "$CONFIRM_SCRIPT" 2>/dev/null; then
    echo "✓ PASS: Script has valid bash syntax"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Script has syntax errors"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# ============================================================
# TEST GROUP 2: Function Definitions
# ============================================================

echo "TEST GROUP 2: Function Definitions"
echo "==================================="

# Test required functions exist
assert_function_defined "check_jq" "check_jq() function defined" "$CONFIRM_SCRIPT"
assert_function_defined "check_nerdfonts" "check_nerdfonts() function defined" "$CONFIRM_SCRIPT"
assert_function_defined "backup_settings" "backup_settings() function defined" "$CONFIRM_SCRIPT"
assert_function_defined "configure_antigravity" "configure_antigravity() function defined" "$CONFIRM_SCRIPT"
assert_function_defined "configure_vscode" "configure_vscode() function defined" "$CONFIRM_SCRIPT"
assert_function_defined "main" "main() function defined" "$CONFIRM_SCRIPT"

echo ""

# ============================================================
# TEST GROUP 3: Execution Test
# ============================================================

echo "TEST GROUP 3: Execution Test"
echo "============================="

# Test: Script executes without crash (exit code 0 or 1 is acceptable)
TESTS_RUN=$((TESTS_RUN + 1))
"$CONFIRM_SCRIPT" >/dev/null 2>&1 || EXIT_CODE=$?
EXIT_CODE=${EXIT_CODE:-0}

if [[ $EXIT_CODE -le 1 ]]; then
    echo "✓ PASS: Script executes without crash (exit: $EXIT_CODE)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Script crashed with unexpected exit code: $EXIT_CODE"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# ============================================================
# TEST GROUP 4: Idempotency
# ============================================================

echo "TEST GROUP 4: Idempotency"
echo "========================="

# Test: Running twice produces same exit code
"$CONFIRM_SCRIPT" >/dev/null 2>&1 || EXIT1=$?
EXIT1=${EXIT1:-0}
"$CONFIRM_SCRIPT" >/dev/null 2>&1 || EXIT2=$?
EXIT2=${EXIT2:-0}

assert_equals "$EXIT1" "$EXIT2" "Script is idempotent (same exit code on re-run)"

echo ""

# ============================================================
# TEST GROUP 5: Configuration Constants
# ============================================================

echo "TEST GROUP 5: Configuration Constants"
echo "======================================"

# Test: Default font configuration present
TESTS_RUN=$((TESTS_RUN + 1))
if grep -q "FiraCode Nerd Font" "$CONFIRM_SCRIPT"; then
    echo "✓ PASS: FiraCode Nerd Font is default"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Default font not found in script"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test: Environment variable override supported
TESTS_RUN=$((TESTS_RUN + 1))
if grep -q "GHOSTTY_IDE_TERMINAL_FONT" "$CONFIRM_SCRIPT"; then
    echo "✓ PASS: Environment variable override supported"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Environment variable override not supported"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# ============================================================
# TEST GROUP 6: Performance
# ============================================================

echo "TEST GROUP 6: Performance"
echo "========================="

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

TESTS_RUN=$((TESTS_RUN + 1))
if [[ $EXECUTION_TIME -lt 10 ]]; then
    echo "✓ PASS: Test execution time: ${EXECUTION_TIME}s (<10s requirement)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Test execution time: ${EXECUTION_TIME}s (exceeds 10s requirement)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# ============================================================
# TEST SUMMARY
# ============================================================

echo "=== Test Summary ==="
echo "Total: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Execution time: ${EXECUTION_TIME}s"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed"
    exit 1
fi
