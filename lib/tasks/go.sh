#!/usr/bin/env bash
#
# lib/tasks/go.sh - Go installation tasks
#

verify_go_installed() {
    if command -v go >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

export -f verify_go_installed
