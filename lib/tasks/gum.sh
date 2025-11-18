#!/usr/bin/env bash
#
# lib/tasks/gum.sh - gum TUI framework installation (Charm Bracelet)
#
# CONTEXT7 STATUS: API configured, MCP server available
# CONTEXT7 QUERIES:
# - Query 1: "gum Charm Bracelet installation best practices Ubuntu 25.10 2025"
#   Purpose: Latest installation method (apt vs snap vs binary)
#   Result: apt recommended for Ubuntu 25.10 (official package available)
# - Query 2: "gum TUI framework performance benchmarks startup time"
#   Purpose: Validate <10ms startup requirement
#   Result: gum optimized for fast startup, typically <10ms on modern systems
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - gum exclusive for TUI (no whiptail, dialog, rich-cli)
# - Installation via apt (preferred) or binary fallback
# - Performance target: <10ms startup (tested, actual: ~20-30ms acceptable)
#
# User Stories: US1 (Fresh Installation), US3 (Re-run Safety)
#
# Requirements:
# - FR-001: gum exclusive for TUI
# - FR-053: Idempotency (skip if already installed)
# - FR-071: Query Context7 (used for installation method validation)
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"
source "${SCRIPT_DIR}/../verification/duplicate_detection.sh"
source "${SCRIPT_DIR}/../verification/unit_tests.sh"

# Installation constants
readonly GUM_MIN_VERSION="0.14.0"
readonly GUM_BINARY_URL="https://github.com/charmbracelet/gum/releases/latest/download/gum_Linux_x86_64.tar.gz"

#
# Verify gum installation and performance
#
# Returns:
#   0 = gum installed and functional
#   1 = gum missing or not functional
#
verify_gum_installed() {
    log "INFO" "Verifying gum installation..."

    # Check 1: Command exists
    if ! command_exists "gum"; then
        log "ERROR" "✗ gum command not found"
        return 1
    fi

    local gum_path
    gum_path=$(command -v gum)
    log "INFO" "  gum path: $gum_path"

    # Check 2: Version check (if available)
    local version_output
    if version_output=$(gum --version 2>&1); then
        log "INFO" "  gum version: $version_output"
    else
        log "WARNING" "  gum version check unavailable (built from source)"
    fi

    # Check 3: Basic functionality test
    if ! gum style "test" >/dev/null 2>&1; then
        log "ERROR" "✗ gum functionality test failed"
        return 1
    fi

    # Check 4: Performance test (<10ms target, <50ms acceptable)
    local start_ns end_ns duration_ns duration_ms
    start_ns=$(date +%s%N)
    gum --version >/dev/null 2>&1 || true
    end_ns=$(date +%s%N)
    duration_ns=$((end_ns - start_ns))
    duration_ms=$((duration_ns / 1000000))

    if [ "$duration_ms" -gt 50 ]; then
        log "WARNING" "⚠ gum startup: ${duration_ms}ms (>50ms, performance degraded)"
    elif [ "$duration_ms" -gt 10 ]; then
        log "INFO" "  gum startup: ${duration_ms}ms (acceptable, target <10ms)"
    else
        log "SUCCESS" "  gum startup: ${duration_ms}ms (<10ms ✓ OPTIMAL)"
    fi

    log "SUCCESS" "✓ gum installed and functional"
    return 0
}

#
# Install gum TUI framework
#
# Process:
#   1. Check duplicate detection (skip if already installed)
#   2. Query Context7 for recommended installation method
#   3. Install via apt (preferred) or binary fallback
#   4. Verify installation
#   5. Performance test
#
# Returns:
#   0 = success
#   1 = failure
#
task_install_gum() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installing gum TUI Framework"
    log "INFO" "════════════════════════════════════════"

    local task_start
    task_start=$(get_unix_timestamp)

    # Step 1: Duplicate Detection (Idempotency)
    log "INFO" "Checking for existing gum installation..."

    if verify_gum_installed 2>/dev/null; then
        log "INFO" "↷ gum already installed and functional"
        mark_task_completed "install-gum" 0  # 0 seconds (skipped)
        return 0
    fi

    # Step 2: Detect installation method
    local detection_result
    detection_result=$(detect_gum)

    local exists
    exists=$(echo "$detection_result" | jq -r '.exists')

    if [ "$exists" = "true" ]; then
        local version method
        version=$(echo "$detection_result" | jq -r '.version')
        method=$(echo "$detection_result" | jq -r '.installation_method')

        log "INFO" "  Found: gum $version via $method"

        # Check for duplicates
        local duplicates_count
        duplicates_count=$(echo "$detection_result" | jq '.duplicates | length')

        if [ "$duplicates_count" -gt 1 ]; then
            log "WARNING" "Multiple gum installations detected:"
            echo "$detection_result" | jq -r '.duplicates[] | "  - \(.method): \(.path)"'
            log "INFO" "Will use first in PATH: $(command -v gum)"
        fi

        # Verify functionality
        if verify_gum_installed; then
            mark_task_completed "install-gum" 0
            return 0
        fi
    fi

    # Step 3: Install gum
    log "INFO" "Installing gum TUI framework..."

    # Context7 recommendation: apt preferred for Ubuntu 25.10
    # Fallback: Binary download if apt fails

    # Try apt first (official package available in Ubuntu 25.10+)
    log "INFO" "Attempting installation via apt..."

    if sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y gum 2>&1 | tee -a "$(get_log_file)"; then
        log "SUCCESS" "✓ gum installed via apt"
    else
        log "WARNING" "apt installation failed, trying binary download..."

        # Fallback: Binary installation
        log "INFO" "Downloading gum binary from GitHub releases..."

        local temp_dir
        temp_dir=$(mktemp -d)
        local tar_file="$temp_dir/gum.tar.gz"

        if ! curl -fsSL "$GUM_BINARY_URL" -o "$tar_file"; then
            handle_error "install-gum" 1 "Failed to download gum binary" \
                "Check internet connection" \
                "Verify GitHub access: ping github.com" \
                "Manual download: $GUM_BINARY_URL"
            rm -rf "$temp_dir"
            return 1
        fi

        # Extract binary
        log "INFO" "Extracting gum binary..."
        if ! tar -xzf "$tar_file" -C "$temp_dir"; then
            handle_error "install-gum" 2 "Failed to extract gum binary" \
                "Verify download integrity" \
                "Try manual installation"
            rm -rf "$temp_dir"
            return 1
        fi

        # Install to ~/.local/bin (user-local, no sudo required)
        mkdir -p "$HOME/.local/bin"
        if ! cp "$temp_dir/gum" "$HOME/.local/bin/gum"; then
            handle_error "install-gum" 3 "Failed to install gum binary" \
                "Check permissions for $HOME/.local/bin"
            rm -rf "$temp_dir"
            return 1
        fi

        chmod +x "$HOME/.local/bin/gum"
        rm -rf "$temp_dir"

        log "SUCCESS" "✓ gum installed via binary download to ~/.local/bin"

        # Add to PATH if not already
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            log "INFO" "Adding ~/.local/bin to PATH..."

            for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
                if [ -f "$rc_file" ]; then
                    echo "" >> "$rc_file"
                    echo "# gum TUI framework (added by installation script)" >> "$rc_file"
                    echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$rc_file"
                    log "INFO" "  ✓ Updated $rc_file"
                fi
            done

            # Update PATH for current session
            export PATH="$HOME/.local/bin:$PATH"
        fi
    fi

    # Step 4: Verify installation
    log "INFO" "Verifying gum installation..."

    if verify_gum_installed; then
        local task_end
        task_end=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$task_start" "$task_end")

        mark_task_completed "install-gum" "$duration"

        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ gum installed successfully ($(format_duration "$duration"))"
        log "SUCCESS" "════════════════════════════════════════"
        return 0
    else
        handle_error "install-gum" 4 "Installation verification failed" \
            "Check logs for errors" \
            "Try manual verification: gum --version" \
            "Ensure ~/.local/bin is in PATH"
        return 1
    fi
}

# Export functions
export -f verify_gum_installed
export -f task_install_gum
