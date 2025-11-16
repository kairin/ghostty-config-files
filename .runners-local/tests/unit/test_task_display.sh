#!/bin/bash
# Unit tests for task_display.sh
# Constitutional requirement: <5s execution time

set -euo pipefail

# Source module for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Disable display rendering for tests
export DISPLAY_ENABLED=0
export NO_COLOR=1
export MANAGE_NO_COLOR=1

source "${PROJECT_ROOT}/scripts/task_display.sh"

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
        echo "✗ FAIL: $test_name"
        echo "    Expected: $expected"
        echo "    Actual:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_not_empty() {
    local actual="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -n "$actual" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name (value is empty)"
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
        echo "    Expected to find: $needle"
        echo "    In: $haystack"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "=== Unit Tests: task_display.sh ==="
echo

# Test 1: Task registration
register_task "test_task_1" "Test Task 1"
assert_equals "pending" "${TASK_STATUS[test_task_1]}" "Task registered with pending status"
assert_equals "Test Task 1" "${TASK_DESCRIPTION[test_task_1]}" "Task description stored"

# Test 2: Task start
start_task "test_task_1"
assert_equals "running" "${TASK_STATUS[test_task_1]}" "Task started with running status"
assert_not_empty "${TASK_START_TIME[test_task_1]}" "Start time recorded"

# Test 3: Task completion (success)
complete_task "test_task_1" "success" "Success output"
assert_equals "completed" "${TASK_STATUS[test_task_1]}" "Task completed with completed status"
assert_equals "1" "${TASK_COLLAPSED[test_task_1]}" "Successful task auto-collapsed"
assert_not_empty "${TASK_END_TIME[test_task_1]}" "End time recorded"

# Test 4: Task completion (failed)
register_task "test_task_2" "Test Task 2"
start_task "test_task_2"
complete_task "test_task_2" "failed" "Error output"
assert_equals "failed" "${TASK_STATUS[test_task_2]}" "Task failed with failed status"
assert_equals "0" "${TASK_COLLAPSED[test_task_2]}" "Failed task auto-expanded"

# Test 5: Duration calculation
register_task "test_task_3" "Test Task 3"
TASK_START_TIME[test_task_3]=1000000000000  # 1 second in nanoseconds
TASK_END_TIME[test_task_3]=1000500000000    # 1.5 seconds
duration=$(get_task_duration "test_task_3")
assert_equals "500ms" "$duration" "Duration formatted as milliseconds"

# Test 6: Duration formatting (seconds)
TASK_START_TIME[test_task_4]=1000000000000  # 1 second
TASK_END_TIME[test_task_4]=1002500000000    # 2.5 seconds
register_task "test_task_4" "Test Task 4"
duration=$(get_task_duration "test_task_4")
assert_contains "$duration" "2." "Duration formatted as seconds (contains 2.)"

# Test 7: Terminal width detection
width=$(detect_terminal_width)
assert_not_empty "$width" "Terminal width detected"

# Test 8: ANSI support detection
if detect_ansi_support; then
    ansi_result="supported"
else
    ansi_result="not_supported"
fi
# With NO_COLOR=1, ANSI should not be supported
assert_equals "not_supported" "$ansi_result" "ANSI detection respects NO_COLOR"

# Test 9: Display mode detection
export COLUMNS=120
mode=$(get_display_mode)
assert_equals "full" "$mode" "Full display mode at 120 columns"

export COLUMNS=90
mode=$(get_display_mode)
assert_equals "truncated" "$mode" "Truncated display mode at 90 columns"

export COLUMNS=60
mode=$(get_display_mode)
assert_equals "minimal" "$mode" "Minimal display mode at 60 columns"

# Test 10: Render task line
register_task "test_task_5" "Test Render Task"
start_task "test_task_5"
line=$(render_task_line "test_task_5")
assert_contains "$line" "Test Render Task" "Rendered line contains description"

# Test 11: Multiple task registration
register_task "test_task_6" "Task 6"
register_task "test_task_7" "Task 7"
register_task "test_task_8" "Task 8"
# Count should be 10: test_task_1 through test_task_10
# (test_task_1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
assert_equals "8" "${#TASK_STATUS[@]}" "8 tasks registered so far"

# Test 12: Task ID collision detection
if register_task "test_task_1" "Duplicate Task"; then
    echo "✗ FAIL: Task ID collision not detected"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo "✓ PASS: Task ID collision detected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 13: Invalid task completion status
register_task "test_task_9" "Task 9"
start_task "test_task_9"
if complete_task "test_task_9" "invalid_status" "Output"; then
    echo "✗ FAIL: Invalid status not rejected"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
else
    echo "✓ PASS: Invalid status rejected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
fi

# Test 14: Task output storage
register_task "test_task_10" "Task with output"
start_task "test_task_10"
complete_task "test_task_10" "success" "Line 1\nLine 2\nLine 3"
assert_contains "${TASK_OUTPUT[test_task_10]}" "Line 1" "Task output stored correctly"

# Test 15: Performance - registration timing
start_time=$(date +%s%N)
for i in {100..109}; do
    register_task "perf_task_$i" "Performance Test $i"
done
end_time=$(date +%s%N)
duration_ms=$(( (end_time - start_time) / 1000000 ))
if [[ $duration_ms -lt 100 ]]; then
    echo "✓ PASS: 10 task registrations in ${duration_ms}ms (<100ms)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "✗ FAIL: 10 task registrations took ${duration_ms}ms (>100ms)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Summary
echo
echo "=== Test Summary ==="
echo "Total: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
