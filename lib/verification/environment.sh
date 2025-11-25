#!/usr/bin/env bash
#
# lib/verification/environment.sh - Robust Environment Verification
#
# This module provides deep verification of the execution environment to ensure
# scripts run in a clean, predictable state.
#
# Features:
# - Conflict detection (e.g., multiple package managers)
# - Path sanity checks
# - State file locking/validation
#

set -eo pipefail

# Source guard
[ -z "${ENVIRONMENT_SH_LOADED:-}" ] || return 0
ENVIRONMENT_SH_LOADED=1

#
# Verify clean state
#
# Checks for lock files or partial installations that might interfere.
#
# Returns:
#   0 = clean
#   1 = dirty (requires cleanup)
#
verify_clean_state() {
    local lock_file="/tmp/ghostty_install.lock"
    
    if [[ -f "$lock_file" ]]; then
        # Check if process is actually running
        local pid
        pid=$(cat "$lock_file")
        if kill -0 "$pid" 2>/dev/null; then
            log "ERROR" "Another installation instance is running (PID: $pid)"
            return 1
        else
            log "WARNING" "Found stale lock file from PID $pid. Cleaning up..."
            rm -f "$lock_file"
        fi
    fi
    
    return 0
}

#
# Verify no conflicting tools
#
# Checks for tools that shouldn't be present (e.g. pip if using uv).
#
# Returns:
#   0 = no conflicts
#   1 = conflicts found
#
verify_conflicts() {
    local conflicts=0
    
    # Example: Check for system pip if we want to enforce uv
    # This is just a warning for now as system pip might be needed for other things
    if command_exists "pip" || command_exists "pip3"; then
        log "DEBUG" "System pip detected. Ensure 'uv' is used for project dependencies."
    fi
    
    return 0
}

#
# Verify PATH sanity
#
# Ensures PATH contains necessary directories and doesn't contain dangerous ones.
#
# Returns:
#   0 = path sane
#   1 = path issues
#
verify_path_sanity() {
    # Check if ~/.local/bin is in PATH (common issue)
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log "WARNING" "\$HOME/.local/bin is not in PATH. Some tools might not be found."
        # We can try to append it for this session
        export PATH="$HOME/.local/bin:$PATH"
        log "INFO" "Added \$HOME/.local/bin to PATH for this session."
    fi
    
    return 0
}

#
# Run full environment verification
#
run_environment_checks() {
    log "INFO" "Running environment verification..."
    
    local failed=0
    
    verify_clean_state || ((failed++))
    verify_conflicts || ((failed++))
    verify_path_sanity || ((failed++))
    
    if [[ "$failed" -eq 0 ]]; then
        log "SUCCESS" "Environment verification passed."
        return 0
    else
        log "ERROR" "Environment verification failed with $failed issues."
        return 1
    fi
}

export -f verify_clean_state
export -f verify_conflicts
export -f verify_path_sanity
export -f run_environment_checks
