#!/usr/bin/env bash
#
# Test: Streaming Output Demonstration
# Purpose: Show the new run_command_streaming function in action
#

set -euo pipefail

# Bootstrap
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/init.sh"

# Load required libraries
source "${REPO_ROOT}/lib/ui/collapsible.sh"
source "${REPO_ROOT}/lib/core/logging.sh"

# Initialize
init_collapsible_output

echo "=== Test: Streaming Output ==="
echo ""
echo "This demonstrates the new run_command_streaming() function"
echo "which shows live progress during long-running operations."
echo ""

# Test 1: Simulated download with progress
echo "Test 1: Simulated download (5 seconds)"
register_task "test-download" "Downloading test file"
start_task "test-download"

if run_command_streaming "test-download" bash -c '
    for i in {1..10}; do
        echo "Downloaded $((i * 10))%"
        sleep 0.5
    done
'; then
    complete_task "test-download" 5
fi

echo ""

# Test 2: Simulated build with progress
echo "Test 2: Simulated build (8 seconds)"
register_task "test-build" "Building project"
start_task "test-build"

if run_command_streaming "test-build" bash -c '
    echo "Compiling source files..."
    sleep 2
    echo "Linking libraries..."
    sleep 2
    echo "Generating binaries..."
    sleep 2
    echo "Build complete!"
    sleep 2
'; then
    complete_task "test-build" 8
fi

echo ""
echo "=== Test Complete ==="
echo ""
echo "As you can see, the run_command_streaming() function:"
echo "  1. Shows periodic spinner updates"
echo "  2. Displays the last 3 lines of output as they appear"
echo "  3. Prevents the 'stuck' appearance during long operations"
echo ""

cleanup_collapsible_output
