#!/usr/bin/env bash
#
# Module: Install UV Package Manager
# Purpose: Download and install UV using official Astral installer
# Prerequisites: curl available, internet connection
# Outputs: $HOME/.local/bin/uv binary
# Exit Codes:
#   0 - Installation successful
#   1 - Installation failed
#   2 - Already installed (skip)
#
# Context7 Best Practices:
# - Official installer: https://astral.sh/uv/install.sh
# - XDG-compliant installation (~/.local/bin)
# - Automatic PATH detection and configuration
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    log "INFO" "Installing UV package manager..."

    # Idempotency check
    if verify_uv_binary; then
        log "INFO" "↷ UV already installed at $UV_BINARY"
        exit 2
    fi

    # Ensure target directory exists
    mkdir -p "$UV_BIN_DIR"

    # Download and run official installer
    log "INFO" "Downloading UV installer from $UV_INSTALL_URL..."

    if ! curl -LsSf "$UV_INSTALL_URL" | sh; then
        log "ERROR" "✗ UV installation failed"
        log "ERROR" "  Check internet connection"
        log "ERROR" "  Manual installation: https://github.com/astral-sh/uv"
        exit 1
    fi

    # Verify binary exists
    if ! verify_uv_binary; then
        log "ERROR" "✗ UV binary not found after installation"
        log "ERROR" "  Expected location: $UV_BINARY"
        exit 1
    fi

    # Ensure executable
    chmod +x "$UV_BINARY"

    log "SUCCESS" "✓ UV installed successfully at $UV_BINARY"
    exit 0
}

main "$@"
