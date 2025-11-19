#!/usr/bin/env bash
#
# tests/test_modularity.sh - Verify Modular Architecture
#

set -euo pipefail

# 1. Test running from repo root
echo "Testing execution from repo root..."
if ./scripts/.template.sh > /dev/null; then
    echo "SUCCESS: Ran from repo root"
else
    echo "FAILURE: Failed to run from repo root"
    exit 1
fi

# 2. Test running from subdirectory
echo "Testing execution from subdirectory..."
cd scripts
if ./../scripts/.template.sh > /dev/null; then
    echo "SUCCESS: Ran from subdirectory"
else
    echo "FAILURE: Failed to run from subdirectory"
    exit 1
fi
cd ..

# 3. Test TUI auto-install (mock)
# We can't easily uninstall gum to test install, but we can check if init_tui works
echo "Testing TUI initialization..."
source lib/init.sh
if [[ "$TUI_AVAILABLE" == "true" ]]; then
    echo "SUCCESS: TUI initialized"
else
    echo "FAILURE: TUI failed to initialize"
    exit 1
fi

# 4. Test Environment Verification
echo "Testing Environment Verification..."
if run_environment_checks; then
    echo "SUCCESS: Environment checks passed"
else
    echo "FAILURE: Environment checks failed"
    exit 1
fi

echo "ALL TESTS PASSED"
