#!/usr/bin/env bash
#
# Common functions for glow installer
#

# Get repository root
get_repo_root() {
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [ "$current_dir" != "/" ]; do
        if [ -f "$current_dir/start.sh" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done
    echo "/home/kkk/Apps/ghostty-config-files"
}

export REPO_ROOT="${REPO_ROOT:-$(get_repo_root)}"

# Source core utilities
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/core/utils.sh"
source "${REPO_ROOT}/lib/core/state.sh"
source "${REPO_ROOT}/lib/core/errors.sh"

# Glow-specific constants
export GLOW_MIN_VERSION="2.0.0"
export GLOW_APT_PACKAGE="glow"
