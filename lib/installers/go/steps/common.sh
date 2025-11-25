#!/usr/bin/env bash
#
# lib/installers/go/steps/common.sh - Shared utilities for Go installation
#

set -euo pipefail

# Source core libraries if not already sourced
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"
fi

# Get Go version
get_go_version() {
    if command -v go >/dev/null 2>&1; then
        local version_output
        version_output=$(go version 2>&1 | awk '{print $3}' || echo "unknown")
        echo "$version_output"
    else
        echo "none"
    fi
}

# Export functions
export -f get_go_version
