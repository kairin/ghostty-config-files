#!/usr/bin/env bash
#
# Common functions for VHS installer
#

# Get repository root
get_repo_root() {
    local current_dir
    current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# VHS-specific constants
export VHS_MIN_VERSION="0.7.0"
export VHS_APT_PACKAGE="vhs"
export TTYD_MIN_VERSION="1.7.0"
export TTYD_GITHUB_REPO="tsl0922/ttyd"
export FFMPEG_MIN_VERSION="4.0"
