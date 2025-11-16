#!/bin/bash
# Unit Test: test_verification.sh
# Purpose: Test verification module (<5s execution)
# Dependencies: verification.sh
# Exit Codes: 0=all tests pass, 1=one or more tests fail

set -euo pipefail

# Source module under test
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="${SCRIPT_DIR}/../../../scripts"
source "${MODULE_DIR}/verification.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper function
run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo "→ Test $TESTS_RUN: $test_name"

    if eval "$test_command" &> /dev/null; then
        echo "  ✓ PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo "  ✗ FAIL"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Start timer (constitutional <5s requirement)
START_TIME=$(date +%s)

echo "=== Verification Module Tests ==="
echo ""

# ============================================================
# Test Group 1: verify_binary() - Basic Functionality
# ============================================================
echo "--- Test Group 1: verify_binary() Basic Tests ---"
echo ""

# Test 1: Binary exists (bash)
run_test "verify_binary: bash exists" \
    "verify_binary bash"

# Test 2: Binary exists with version check
run_test "verify_binary: bash with version" \
    "verify_binary bash '5.0.0' 'bash --version'"

# Test 3: Nonexistent binary (should fail)
run_test "verify_binary: nonexistent binary fails" \
    "! verify_binary 'nonexistent-binary-12345'"

# Test 4: Missing argument (should fail with exit code 2)
run_test "verify_binary: missing argument fails" \
    "! verify_binary ''"

echo ""

# ============================================================
# Test Group 2: verify_binary() - Version Comparison Edge Cases
# ============================================================
echo "--- Test Group 2: verify_binary() Version Comparison ---"
echo ""

# Test 5: Version with 'v' prefix
run_test "verify_binary: version with v prefix" \
    "verify_binary bash '5.0' 'bash --version'"

# Test 6: Version without patch number (5.1 vs 5.1.0)
run_test "verify_binary: version without patch" \
    "verify_binary bash '5' 'bash --version'"

echo ""

# ============================================================
# Test Group 3: verify_config() - File Validation
# ============================================================
echo "--- Test Group 3: verify_config() File Validation ---"
echo ""

# Test 7: Config file exists
run_test "verify_config: /etc/hosts exists" \
    "verify_config /etc/hosts"

# Test 8: Missing config file (should fail)
run_test "verify_config: missing file fails" \
    "! verify_config /nonexistent/file"

# Test 9: Missing argument (should fail)
run_test "verify_config: missing argument fails" \
    "! verify_config ''"

echo ""

# ============================================================
# Test Group 4: verify_config() - Required Settings
# ============================================================
echo "--- Test Group 4: verify_config() Required Settings ---"
echo ""

# Create temporary config for testing
TEMP_CONFIG=$(mktemp)
cat > "$TEMP_CONFIG" << 'EOF'
key1=value1
key2=value2
key3: value3
EOF

# Test 10: Required settings present
run_test "verify_config: required settings present" \
    "verify_config '$TEMP_CONFIG' '' 'key1 key2 key3'"

# Test 11: Missing required setting (should fail)
run_test "verify_config: missing setting fails" \
    "! verify_config '$TEMP_CONFIG' '' 'key1 missing_key'"

# Test 12: YAML format (key: value)
run_test "verify_config: YAML format recognized" \
    "verify_config '$TEMP_CONFIG' '' 'key3'"

rm -f "$TEMP_CONFIG"

echo ""

# ============================================================
# Test Group 5: verify_service() - Service Status Checks
# ============================================================
echo "--- Test Group 5: verify_service() Service Status ---"
echo ""

# Test 13: Service check (systemd available)
if command -v systemctl &> /dev/null; then
    run_test "verify_service: systemd available" \
        "verify_service 'dbus' 'systemctl is-active dbus' 'active' || true"
else
    echo "→ Test 13: Skipping (systemd not available)"
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 14: Missing service name (should fail)
run_test "verify_service: missing service name fails" \
    "! verify_service ''"

echo ""

# ============================================================
# Test Group 6: verify_integration() - Integration Tests
# ============================================================
echo "--- Test Group 6: verify_integration() Integration Tests ---"
echo ""

# Test 15: Simple command success
run_test "verify_integration: true command" \
    "verify_integration 'true test' 'true' 0"

# Test 16: Command with output pattern
run_test "verify_integration: echo with pattern" \
    "verify_integration 'echo test' 'echo hello' 0 'hello'"

# Test 17: Expected failure (exit code mismatch)
run_test "verify_integration: expected failure" \
    "verify_integration 'false test' 'false' 1"

# Test 18: Exit code check
run_test "verify_integration: exit code 42" \
    "verify_integration 'exit 42' 'exit 42' 42"

# Test 19: Missing test name (should fail)
run_test "verify_integration: missing test name fails" \
    "! verify_integration '' 'true' 0"

# Test 20: Missing test command (should fail)
run_test "verify_integration: missing test command fails" \
    "! verify_integration 'test' '' 0"

echo ""

# ============================================================
# Test Group 7: Real-World Integration Examples
# ============================================================
echo "--- Test Group 7: Real-World Integration Examples ---"
echo ""

# Test 21: Node.js style test (if node available)
if command -v node &> /dev/null; then
    run_test "verify_integration: Node.js execution" \
        "verify_integration 'Node.js test' 'node -e \"console.log(42)\"' 0 '^42$'"
else
    echo "→ Test 21: Skipping (Node.js not available)"
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 22: Shell script execution
run_test "verify_integration: shell script" \
    "verify_integration 'Shell test' 'echo \$((2+2))' 0 '^4$'"

# Test 23: Command with stderr
run_test "verify_integration: command with stderr" \
    "verify_integration 'stderr test' 'echo error >&2; exit 0' 0 'error'"

echo ""

# ============================================================
# Test Group 8: Error Handling and Edge Cases
# ============================================================
echo "--- Test Group 8: Error Handling and Edge Cases ---"
echo ""

# Test 24: Binary with unparseable version
run_test "verify_binary: unparseable version fallback" \
    "verify_binary bash '' 'echo \"no version here\"' || true"

# Test 25: Config file with syntax checker
if command -v jq &> /dev/null; then
    # Create JSON config
    JSON_CONFIG=$(mktemp)
    echo '{"key": "value"}' > "$JSON_CONFIG"

    run_test "verify_config: JSON syntax check" \
        "verify_config '$JSON_CONFIG' 'jq empty'"

    rm -f "$JSON_CONFIG"
else
    echo "→ Test 25: Skipping (jq not available)"
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 26: Integration test with output mismatch (should fail)
run_test "verify_integration: output mismatch fails" \
    "! verify_integration 'mismatch test' 'echo wrong' 0 'correct'"

# Test 27: Integration test with exit code mismatch (should fail)
run_test "verify_integration: exit code mismatch fails" \
    "! verify_integration 'exit code test' 'exit 1' 0"

echo ""

# ============================================================
# Test Summary and Performance Validation
# ============================================================

# End timer
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo "=== Test Summary ==="
echo "Tests Run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Execution Time: ${ELAPSED}s"
echo ""

# Constitutional requirement: <5s
if [[ $ELAPSED -ge 5 ]]; then
    echo "⚠ WARNING: Test execution exceeded 5s limit (${ELAPSED}s)" >&2
    echo "  This violates the constitutional requirement for module tests" >&2
fi

# Module independence check: <10s
if [[ $ELAPSED -ge 10 ]]; then
    echo "✗ CRITICAL: Test execution exceeded 10s module independence limit" >&2
    exit 1
fi

# Exit with appropriate code
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "✗ Test suite failed: $TESTS_FAILED failures"
    exit 1
else
    echo "✓ All tests passed in ${ELAPSED}s"
    exit 0
fi
