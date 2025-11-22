#!/usr/bin/env bash
set -u

# Simulate the issue
start_spinner_loop() {
    # Start background process that writes to stdout (inherited)
    (
        while true; do
            echo "Spinner..." >&2  # Write to stderr to see it
            sleep 0.5
        done
    ) &
    
    local pid=$!
    echo "$pid"
}

echo "Starting test..."
# This should hang if the background process keeps stdout open
pid=$(start_spinner_loop)
echo "PID captured: $pid"
echo "Test finished (if you see this, it didn't hang)"

# Cleanup
kill "$pid" 2>/dev/null
