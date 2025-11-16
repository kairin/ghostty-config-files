#!/bin/bash
# Demo script for task display system
# Shows parallel task execution with collapsible output

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Disable auto-collapse for demo (faster)
export TASK_DISPLAY_NO_AUTO_COLLAPSE=1

source "${SCRIPT_DIR}/task_manager.sh"

echo "=== Task Display System Demo ===" echo ""

# Initialize
init_task_manager

# Demo 1: Simple sequential tasks
echo "Demo 1: Sequential task execution"
echo "-----------------------------------"

run_task_sync "demo1_task1" "Installing Node.js" "sleep 0.2 && echo 'Node.js v25.2.0 installed'"
run_task_sync "demo1_task2" "Installing Ghostty" "sleep 0.3 && echo 'Ghostty 1.1.4 built successfully'"
run_task_sync "demo1_task3" "Installing AI tools" "sleep 0.1 && echo 'Claude Code, Gemini CLI installed'"

echo ""
echo "✓ Demo 1 complete"
echo ""

# Demo 2: Mixed success/failure
echo "Demo 2: Handling failures"
echo "-------------------------"

run_task_sync "demo2_success" "Successful operation" "echo 'This task succeeded'"
run_task_sync "demo2_failure" "Failing operation" "echo 'Error: Something went wrong' && exit 1" || true

echo ""
echo "✓ Demo 2 complete"
echo ""

# Demo 3: Performance test
echo "Demo 3: Performance (10 tasks)"
echo "-------------------------------"

start_time=$(date +%s)

for i in {1..10}; do
    run_task_sync "perf_$i" "Task $i" "echo 'Processing item $i...'"
done

end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo "Executed 10 tasks in ${duration}s"
echo "✓ Demo 3 complete"
echo ""

# Cleanup
cleanup_task_manager

echo "=== Demo Complete ===" echo "Task display system working correctly!"
