#!/bin/bash
# Unit tests for scripts/000-check/check_antigravity.sh
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

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "    Expected to contain: $needle"
        echo "    Actual: $haystack"
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

# ============================================================
# TEST SUITE
# ============================================================

echo "=== Unit Tests: check_antigravity.sh ==="
echo ""
echo "Performance requirement: <10s execution time"
echo ""

CHECK_SCRIPT="${PROJECT_ROOT}/scripts/000-check/check_antigravity.sh"

# ============================================================
# TEST GROUP 1: Script Existence and Syntax
# ============================================================

echo "TEST GROUP 1: Script Validation"
echo "================================"

# Test 1: Script file exists
assert_file_exists "$CHECK_SCRIPT" "check_antigravity.sh exists"

# Test 2: Script is executable
TESTS_RUN=$((TESTS_RUN + 1))
if [[ -x "$CHECK_SCRIPT" ]]; then
    echo "✓ PASS: Script is executable"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Script is not executable"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 3: Script has valid bash syntax
TESTS_RUN=$((TESTS_RUN + 1))
if bash -n "$CHECK_SCRIPT" 2>/dev/null; then
    echo "✓ PASS: Script has valid bash syntax"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Script has syntax errors"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# ============================================================
# TEST GROUP 2: Output Format
# ============================================================

echo "TEST GROUP 2: Output Format"
echo "==========================="

# Run the script and capture output
OUTPUT=$("$CHECK_SCRIPT" 2>/dev/null | head -1)

# Test 4: Output has correct number of pipe-delimited fields (5)
FIELD_COUNT=$(echo "$OUTPUT" | tr '|' '\n' | wc -l)
assert_equals "5" "$FIELD_COUNT" "Output has 5 pipe-delimited fields"

# Test 5: First field is INSTALLED or NOT_INSTALLED
FIRST_FIELD=$(echo "$OUTPUT" | cut -d'|' -f1)
TESTS_RUN=$((TESTS_RUN + 1))
if [[ "$FIRST_FIELD" == "INSTALLED" ]] || [[ "$FIRST_FIELD" == "NOT_INSTALLED" ]]; then
    echo "✓ PASS: First field is valid status ($FIRST_FIELD)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: Invalid first field: $FIRST_FIELD"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Test 6: If installed, method is valid
if [[ "$FIRST_FIELD" == "INSTALLED" ]]; then
    METHOD=$(echo "$OUTPUT" | cut -d'|' -f3)
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$METHOD" =~ ^(PATH|System|Local|Opt|ConfigOnly)$ ]]; then
        echo "✓ PASS: Method field is valid ($METHOD)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: Invalid method: $METHOD"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Test 7: Font status is valid
    FONT_STATUS=$(echo "$OUTPUT" | cut -d'|' -f5)
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$FONT_STATUS" =~ ^(CONFIGURED|PARTIAL|NOT_CONFIGURED|NO_FILE|NO_JQ)$ ]]; then
        echo "✓ PASS: Font status field is valid ($FONT_STATUS)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: Invalid font status: $FONT_STATUS"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
fi

echo ""

# ============================================================
# TEST GROUP 3: Idempotency
# ============================================================

echo "TEST GROUP 3: Idempotency"
echo "========================="

# Test 8: Running twice produces same output
OUTPUT1=$("$CHECK_SCRIPT" 2>/dev/null | head -1)
OUTPUT2=$("$CHECK_SCRIPT" 2>/dev/null | head -1)
assert_equals "$OUTPUT1" "$OUTPUT2" "Script produces consistent output on re-run"

echo ""

# ============================================================
# TEST GROUP 4: Performance
# ============================================================

echo "TEST GROUP 4: Performance"
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
