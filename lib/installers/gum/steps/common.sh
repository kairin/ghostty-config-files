#!/usr/bin/env bash
#
# lib/installers/gum/steps/common.sh - Shared utilities for gum installation
#

set -euo pipefail

# Source core libraries if not already sourced
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"
fi

# Get gum version
get_gum_version() {
    if command -v gum >/dev/null 2>&1; then
        local version_output
        version_output=$(gum --version 2>&1 || echo "unknown")
        echo "$version_output"
    else
        echo "none"
    fi
}

# Check if gum is functional
is_gum_functional() {
    command -v gum >/dev/null 2>&1 && gum style "test" >/dev/null 2>&1
}

# Get gum installation method
get_gum_install_method() {
    local gum_path
    if ! gum_path=$(command -v gum 2>/dev/null); then
        echo "none"
        return 1
    fi

    case "$gum_path" in
        /usr/bin/gum)
            echo "apt"
            ;;
        "$HOME/.local/bin/gum")
            echo "binary"
            ;;
        */go/bin/gum)
            echo "go"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Export functions
export -f get_gum_version
export -f is_gum_functional
export -f get_gum_install_method
