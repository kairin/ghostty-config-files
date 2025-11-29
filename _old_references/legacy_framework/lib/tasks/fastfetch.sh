#!/usr/bin/env bash
#
# lib/tasks/fastfetch.sh - fastfetch system information tool
#
# Purpose: Verify fastfetch installation for system audit display
# Dependencies: apt or GitHub binary download
# Constitutional Compliance: Priority -1 (installed before gum)
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"

#
# Verify fastfetch installation and functionality
#
# Purpose: Check if fastfetch is installed and working properly
#
# Returns:
#   0 = fastfetch installed and functional
#   1 = fastfetch missing or not functional
#
verify_fastfetch_installed() {
    # Check 1: Command exists
    if ! command_exists "fastfetch"; then
        return 1
    fi

    # Check 2: Version can be retrieved
    local version
    version=$(fastfetch --version 2>&1 | head -n1 | grep -oP '\d+\.\d+\.\d+' || echo "")
    if [ -z "$version" ]; then
        return 1
    fi

    # Check 3: Basic execution works (with timeout)
    if ! timeout 3s fastfetch --pipe >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

# Export functions
export -f verify_fastfetch_installed
