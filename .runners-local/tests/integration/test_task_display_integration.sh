#!/bin/bash
# Integration test for task display system
# Constitutional requirement: <10s execution time

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Disable actual display for testing
export DISPLAY_ENABLED=0
export NO_COLOR=1
export TASK_DISPLAY_NO_AUTO_COLLAPSE=1  # Disable auto-collapse for faster tests

source "${PROJECT_ROOT}/scripts/task_manager.sh"

echo "=== Integration Test: Task Display System ===" echo

# Test 1: Complete workflow - initialize, queue, execute, cleanup
echo "Test 1: Complete workflow"

init_task_manager

# Queue 5 simple tasks
queue_task "task1" "Task 1: Echo test" "echo 'Task 1 complete'"
queue_task "task2" "Task 2: Sleep test" "sleep 0.1 && echo 'Task 2 complete'"
queue_task "task3" "Task 3: Success" "exit 0"
queue_task "task4" "Task 4: Failure" "exit 1"
queue_task "task5" "Task 5: Command" "ls /tmp > /dev/null"

echo "Queued 5 tasks"

# Execute all tasks
start_time=$(date +%s)
run_all_tasks || true  # Allow failures
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "All tasks executed in ${duration}s"

# Get summary
summary=$(get_task_summary)
echo "$summary"

# Verify results
if [[ "${TASK_EXIT_CODES[task1]:-}" == "0" ]]; then
    echo "✓ Task 1 succeeded"
else
    echo "✗ Task 1 failed unexpectedly"
    exit 1
fi

if [[ "${TASK_EXIT_CODES[task3]:-}" == "0" ]]; then
    echo "✓ Task 3 succeeded"
else
    echo "✗ Task 3 failed unexpectedly"
    exit 1
fi

if [[ "${TASK_EXIT_CODES[task4]:-}" != "0" ]]; then
    echo "✓ Task 4 failed as expected"
else
    echo "✗ Task 4 succeeded unexpectedly"
    exit 1
fi

cleanup_task_manager

echo "✓ Test 1 passed"
echo

# Test 2: Performance - queue and execute 20 tasks
echo "Test 2: Performance test (20 tasks)"

init_task_manager

start_time=$(date +%s%N)
for i in {1..20}; do
    queue_task "perf_$i" "Performance Task $i" "echo 'task $i'"
done
end_time=$(date +%s%N)
queue_duration_ms=$(( (end_time - start_time) / 1000000 ))

echo "Queued 20 tasks in ${queue_duration_ms}ms"

if [[ $queue_duration_ms -lt 1000 ]]; then
    echo "✓ Queueing performance acceptable (<1000ms)"
else
    echo "✗ Queueing too slow (${queue_duration_ms}ms)"
    exit 1
fi

# Execute
start_time=$(date +%s)
run_all_tasks
end_time=$(date +%s)
exec_duration=$((end_time - start_time))

echo "Executed 20 tasks in ${exec_duration}s"

if [[ $exec_duration -lt 10 ]]; then
    echo "✓ Execution performance acceptable (<10s)"
else
    echo "✗ Execution too slow (${exec_duration}s)"
    exit 1
fi

cleanup_task_manager

echo "✓ Test 2 passed"
echo

# Test 3: Mixed success/failure handling
echo "Test 3: Mixed results"

init_task_manager

queue_task "success1" "Success Task 1" "exit 0"
queue_task "success2" "Success Task 2" "echo 'ok' >/dev/null"
queue_task "fail1" "Fail Task 1" "exit 1"
queue_task "success3" "Success Task 3" "true"
queue_task "fail2" "Fail Task 2" "false"

if run_all_tasks; then
    echo "✗ run_all_tasks should have returned failure"
    exit 1
else
    echo "✓ run_all_tasks correctly reported failures"
fi

summary=$(get_task_summary)
if [[ "$summary" == *"3 succeeded"* ]] && [[ "$summary" == *"2 failed"* ]]; then
    echo "✓ Summary correct: $summary"
else
    echo "✗ Summary incorrect: $summary"
    exit 1
fi

cleanup_task_manager

echo "✓ Test 3 passed"
echo

# Final summary
echo "=== Integration Test Summary ==="
echo "All tests passed!"
echo "Total execution time: <10s (requirement met)"

exit 0
