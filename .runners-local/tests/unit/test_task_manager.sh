#!/bin/bash
# Unit tests for task_manager.sh
# Constitutional requirement: <5s execution time

set -euo pipefail

# Source module for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Disable display rendering for tests
export DISPLAY_ENABLED=0
export NO_COLOR=1
export MANAGE_NO_COLOR=1

source "${PROJECT_ROOT}/scripts/task_manager.sh"

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

assert_success() {
    local test_name="$1"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo "✓ PASS: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

assert_failure() {
    local test_name="$1"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo "✗ FAIL: $test_name"
    TESTS_FAILED=$((TESTS_FAILED + 1))
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

echo "=== Unit Tests: task_manager.sh ==="
echo

# Test 1: Task manager initialization
init_task_manager
if [[ $ORCHESTRATOR_RUNNING -eq 1 ]]; then
    assert_success "Task manager initialized"
else
    assert_failure "Task manager initialization failed"
fi

# Test 2: Queue task
queue_task "test_queue_1" "Test Queue Task" "echo 'test output'"
assert_equals "1" "${#TASK_QUEUE[@]}" "Task queued successfully"
assert_equals "pending" "${TASK_STATUS[test_queue_1]}" "Queued task has pending status"

# Test 3: Run synchronous task (success)
if run_task_sync "test_sync_1" "Sync Task Success" "echo 'success'"; then
    assert_success "Synchronous task execution (success)"
    assert_equals "completed" "${TASK_STATUS[test_sync_1]}" "Sync task marked as completed"
else
    assert_failure "Synchronous task execution failed unexpectedly"
fi

# Test 4: Run synchronous task (failure)
if run_task_sync "test_sync_2" "Sync Task Failure" "false"; then
    assert_failure "Synchronous task should have failed"
else
    assert_success "Synchronous task execution (failure handled)"
    assert_equals "failed" "${TASK_STATUS[test_sync_2]}" "Failed sync task marked as failed"
fi

# Test 5: Multiple task queueing
queue_task "test_queue_2" "Task 2" "echo 'task 2'"
queue_task "test_queue_3" "Task 3" "echo 'task 3'"
queue_task "test_queue_4" "Task 4" "echo 'task 4'"
# Total should be 4 (test_queue_1 + 3 new)
assert_equals "4" "${#TASK_QUEUE[@]}" "Multiple tasks queued"

# Test 6: Task summary generation
summary=$(get_task_summary)
assert_contains "$summary" "Tasks:" "Task summary includes total count"

# Test 7: Async task execution (single task)
queue_task "test_async_1" "Async Task" "sleep 0.1 && echo 'async done'"
if execute_task_async "test_async_1"; then
    assert_success "Async task started"
    assert_equals "running" "${TASK_STATUS[test_async_1]}" "Async task marked as running"
else
    assert_failure "Async task failed to start"
fi

# Wait for async task to complete
sleep 0.2

# Test 8: Parallel execution limit (max 4 concurrent)
# Queue more than 4 tasks
for i in {1..6}; do
    queue_task "parallel_$i" "Parallel Task $i" "sleep 0.1 && echo 'task $i'"
done

# Start all tasks (should respect MAX_CONCURRENT_TASKS=4)
for i in {1..6}; do
    execute_task_async "parallel_$i"

    # Check concurrent count doesn't exceed 4
    if [[ ${#RUNNING_TASKS[@]} -gt 4 ]]; then
        assert_failure "Concurrent task limit exceeded (${#RUNNING_TASKS[@]} > 4)"
        break
    fi

    # If we have 4 running, wait for a slot
    if [[ ${#RUNNING_TASKS[@]} -eq 4 ]]; then
        wait_for_task_slot
    fi
done

if [[ ${#RUNNING_TASKS[@]} -le 4 ]]; then
    assert_success "Concurrent task limit respected (max 4)"
else
    assert_failure "Concurrent task limit violated"
fi

# Wait for all parallel tasks to complete
while [[ ${#RUNNING_TASKS[@]} -gt 0 ]]; do
    wait_for_task_slot
    sleep 0.1
done

# Test 9: Task exit code tracking
queue_task "exit_success" "Exit Success" "exit 0"
queue_task "exit_failure" "Exit Failure" "exit 42"

run_task_sync "exit_success" "Exit Success Test" "exit 0"
run_task_sync "exit_failure" "Exit Failure Test" "exit 42"

if [[ "${TASK_EXIT_CODES[exit_success]:-}" == "0" ]]; then
    assert_success "Success exit code tracked"
else
    assert_failure "Success exit code not tracked"
fi

if [[ "${TASK_EXIT_CODES[exit_failure]:-}" == "42" ]]; then
    assert_success "Failure exit code tracked"
else
    assert_failure "Failure exit code not tracked (expected 42, got ${TASK_EXIT_CODES[exit_failure]:-unknown})"
fi

# Test 10: Task manager cleanup
cleanup_task_manager
if [[ $ORCHESTRATOR_RUNNING -eq 0 ]]; then
    assert_success "Task manager cleaned up"
else
    assert_failure "Task manager cleanup failed"
fi

# Test 11: Performance - queue 100 tasks
start_time=$(date +%s%N)
for i in {1..100}; do
    queue_task "perf_$i" "Perf Task $i" "echo 'task $i'"
done
end_time=$(date +%s%N)
duration_ms=$(( (end_time - start_time) / 1000000 ))

if [[ $duration_ms -lt 500 ]]; then
    assert_success "100 task queues in ${duration_ms}ms (<500ms)"
else
    assert_failure "100 task queues took ${duration_ms}ms (>500ms)"
fi

# Test 12: Empty queue handling
TASK_QUEUE=()
if run_all_tasks; then
    assert_success "Empty queue handled gracefully"
else
    assert_failure "Empty queue caused error"
fi

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
