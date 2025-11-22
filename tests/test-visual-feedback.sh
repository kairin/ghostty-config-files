#!/usr/bin/env bash
#
# Test visual feedback in installation system
#
# Demonstrates the collapsible output system with animated spinners
# This test verifies that visual feedback works in non-verbose mode
#

set -euo pipefail

# Source required libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/core/utils.sh"
source "${REPO_ROOT}/lib/ui/tui.sh"
source "${REPO_ROOT}/lib/ui/collapsible.sh"
source "${REPO_ROOT}/lib/ui/progress.sh"

# Initialize systems
init_logging
init_tui
init_collapsible_output
init_progress_tracking

# Register demo tasks
echo "Registering tasks..."
register_task "task-1" "Downloading Dependencies"
register_task "task-2" "Extracting Archives"
register_task "task-3" "Building Application"
register_task "task-4" "Running Tests"
register_task "task-5" "Installing Binary"

# Render initial state
render_all_tasks

# Start spinner loop
echo "Starting spinner animation..."
spinner_pid=$(start_spinner_loop)

# Simulate task execution
sleep 1
start_task "task-1"
sleep 2
complete_task "task-1" 2

sleep 0.5
start_task "task-2"
sleep 1.5
complete_task "task-2" 1

sleep 0.5
start_task "task-3"
sleep 3
complete_task "task-3" 3

sleep 0.5
start_task "task-4"
sleep 2
complete_task "task-4" 2

sleep 0.5
start_task "task-5"
sleep 1.5
complete_task "task-5" 1

# Stop spinner
stop_spinner_loop "$spinner_pid"

# Cleanup
cleanup_collapsible_output

echo ""
echo "✅ Visual feedback test complete!"
echo ""
echo "Expected behavior:"
echo "  - Tasks should show with animated spinner (⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏)"
echo "  - Running task should have animated spinner"
echo "  - Completed tasks should show ✓ with duration"
echo "  - Task list should update in real-time"
