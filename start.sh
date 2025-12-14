#!/bin/bash

# start.sh - System Installer for Ghostty, Feh, Local AI Tools
# Single entry point for installing feh and ghostty.
#
# Phase 4 (2025-12): Go TUI wrapper mode - invokes compiled binary if available

# set -e removed to prevent premature exit on confirmation warnings

# =============================================================================
# Go TUI Binary Check (Phase 4 Wrapper Mode)
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GO_BINARY="$SCRIPT_DIR/tui/installer"

# If Go binary exists and is executable, use it instead of shell TUI
if [[ -f "$GO_BINARY" && -x "$GO_BINARY" ]]; then
    exec "$GO_BINARY" "$@"
fi

# Go binary not found - show helpful error message
echo "ERROR: Go TUI binary not found at: $GO_BINARY" >&2
echo "" >&2
echo "To build the binary (requires Go 1.23+):" >&2
echo "  cd $SCRIPT_DIR/tui && go build -o installer ./cmd/installer" >&2
echo "" >&2
echo "If Go is not installed, visit: https://go.dev/dl/" >&2
exit 1
