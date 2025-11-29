#!/usr/bin/env bash
#
# Integration test for version comparison utilities
#
# NOTE: This test MUST disable 'set -e' because version_compare returns
# non-zero exit codes as part of its API (0=equal, 1=greater, 2=lesser)
#

# Source the logging library (this will enable set -euo pipefail)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/lib/core/logging.sh"

# CRITICAL: Disable exit-on-error after sourcing because version_compare
# returns non-zero codes as part of its API
set +e

echo "======================================"
echo "Testing version_compare function"
echo "======================================"

test_count=0
pass_count=0

run_test() {
    local test_name="$1"
    local expected="$2"
    shift 2

    test_count=$((test_count + 1))
    echo ""
    echo "Test $test_count: $test_name"

    "$@"
    result=$?

    if [ $result -eq "$expected" ]; then
        echo "✓ PASS (got exit code $result as expected)"
        pass_count=$((pass_count + 1))
        return 0
    else
        echo "✗ FAIL (expected $expected, got $result)"
        return 1
    fi
}

# Run tests
run_test "Equal versions (1.2.3 == 1.2.3)" 0 version_compare "1.2.3" "1.2.3"
run_test "First version greater (1.2.4 > 1.2.3)" 1 version_compare "1.2.4" "1.2.3"
run_test "Second version greater (1.2.3 < 1.2.4)" 2 version_compare "1.2.3" "1.2.4"
run_test "Version with 'v' prefix (v1.2.3 == 1.2.3)" 0 version_compare "v1.2.3" "1.2.3"
run_test "Major version difference (2.0.0 > 1.9.9)" 1 version_compare "2.0.0" "1.9.9"
run_test "Different component counts (1.2.3.4 > 1.2.3)" 1 version_compare "1.2.3.4" "1.2.3"

# Test helper functions (these return 0 for true, 1 for false - standard bash convention)
echo ""
echo "======================================"
echo "Testing version_greater function"
echo "======================================"

test_count=$((test_count + 1))
echo ""
echo "Test $test_count: version_greater (1.2.4 > 1.2.3)"
if version_greater "1.2.4" "1.2.3"; then
    echo "✓ PASS"
    pass_count=$((pass_count + 1))
else
    echo "✗ FAIL"
fi

test_count=$((test_count + 1))
echo ""
echo "Test $test_count: version_greater false case (1.2.3 NOT > 1.2.4)"
if ! version_greater "1.2.3" "1.2.4"; then
    echo "✓ PASS"
    pass_count=$((pass_count + 1))
else
    echo "✗ FAIL"
fi

echo ""
echo "======================================"
echo "Testing version_equal function"
echo "======================================"

test_count=$((test_count + 1))
echo ""
echo "Test $test_count: version_equal (1.2.3 == 1.2.3)"
if version_equal "1.2.3" "1.2.3"; then
    echo "✓ PASS"
    pass_count=$((pass_count + 1))
else
    echo "✗ FAIL"
fi

test_count=$((test_count + 1))
echo ""
echo "Test $test_count: version_equal false case (1.2.3 != 1.2.4)"
if ! version_equal "1.2.3" "1.2.4"; then
    echo "✓ PASS"
    pass_count=$((pass_count + 1))
else
    echo "✗ FAIL"
fi

echo ""
echo "======================================"
echo "Test Summary"
echo "======================================"
echo "Tests run: $test_count"
echo "Tests passed: $pass_count"
echo "Tests failed: $((test_count - pass_count))"

if [ $pass_count -eq $test_count ]; then
    echo ""
    echo "✓ All tests passed!"
    exit 0
else
    echo ""
    echo "✗ Some tests failed"
    exit 1
fi
