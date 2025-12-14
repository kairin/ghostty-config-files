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

# Check if binary needs rebuilding (source newer than binary)
needs_rebuild() {
    local binary="$1"
    local source_dir="$2"

    # If binary doesn't exist, definitely need to build
    [[ ! -f "$binary" ]] && return 0

    # Get binary modification time
    local binary_mtime
    binary_mtime=$(stat -c%Y "$binary" 2>/dev/null) || return 0

    # Check if any .go file or go.mod/go.sum is newer than binary
    while IFS= read -r -d '' file; do
        local file_mtime
        file_mtime=$(stat -c%Y "$file" 2>/dev/null) || continue
        if [[ "$file_mtime" -gt "$binary_mtime" ]]; then
            return 0  # Needs rebuild
        fi
    done < <(find "$source_dir" \( -name "*.go" -o -name "go.mod" -o -name "go.sum" \) -print0 2>/dev/null)

    return 1  # Binary is up-to-date
}

# If Go binary exists, is executable, and is up-to-date, use it (fast path)
if [[ -f "$GO_BINARY" && -x "$GO_BINARY" ]]; then
    if ! needs_rebuild "$GO_BINARY" "$SCRIPT_DIR/tui"; then
        exec "$GO_BINARY" "$@"
    fi
    echo "[Auto-rebuild] Source code changed, rebuilding TUI..."
fi

# =============================================================================
# Bootstrap Functions (Auto-install Go + Build TUI)
# =============================================================================

# Check if Go is installed and functional
check_go_installed() {
    # Check multiple locations - symlink, official install, or PATH
    if command -v go &> /dev/null; then
        return 0
    elif [[ -x "/usr/local/bin/go" ]]; then
        return 0
    elif [[ -x "/usr/local/go/bin/go" ]]; then
        return 0
    fi
    return 1
}

# Get path to working Go binary
get_go_binary() {
    if command -v go &> /dev/null; then
        command -v go
    elif [[ -x "/usr/local/bin/go" ]]; then
        echo "/usr/local/bin/go"
    elif [[ -x "/usr/local/go/bin/go" ]]; then
        echo "/usr/local/go/bin/go"
    fi
}

# Install Go using existing scripts (4-stage pipeline)
install_go() {
    echo "[Bootstrap] Go not found. Installing Go 1.23+..."
    echo ""

    # Stage 1: Install dependencies (curl, tar, wget)
    if [[ -x "$SCRIPT_DIR/scripts/002-install-first-time/install_deps_go.sh" ]]; then
        "$SCRIPT_DIR/scripts/002-install-first-time/install_deps_go.sh" || {
            echo "[Bootstrap] ERROR: Failed to install Go dependencies." >&2
            return 1
        }
    fi

    # Stage 2: Verify dependencies
    if [[ -x "$SCRIPT_DIR/scripts/003-verify/verify_deps_go.sh" ]]; then
        "$SCRIPT_DIR/scripts/003-verify/verify_deps_go.sh" || {
            echo "[Bootstrap] ERROR: Go dependencies verification failed." >&2
            return 1
        }
    fi

    # Stage 3: Install Go
    if [[ -x "$SCRIPT_DIR/scripts/004-reinstall/install_go.sh" ]]; then
        "$SCRIPT_DIR/scripts/004-reinstall/install_go.sh" || {
            echo "[Bootstrap] ERROR: Go installation failed." >&2
            return 1
        }
    else
        echo "[Bootstrap] ERROR: install_go.sh not found." >&2
        return 1
    fi

    # Stage 4: Confirm installation
    if [[ -x "$SCRIPT_DIR/scripts/005-confirm/confirm_go.sh" ]]; then
        "$SCRIPT_DIR/scripts/005-confirm/confirm_go.sh" || {
            echo "[Bootstrap] ERROR: Go installation verification failed." >&2
            return 1
        }
    fi

    echo ""
    echo "[Bootstrap] Go installation complete."
    return 0
}

# Build the TUI binary
build_tui() {
    local go_bin
    go_bin=$(get_go_binary)

    if [[ -z "$go_bin" ]]; then
        echo "[Bootstrap] ERROR: Go binary not found after installation." >&2
        return 1
    fi

    echo "[Bootstrap] Building TUI installer... (this may take a moment)"

    cd "$SCRIPT_DIR/tui" || {
        echo "[Bootstrap] ERROR: Cannot access tui/ directory." >&2
        return 1
    }

    # Build with verbose output to show progress
    if "$go_bin" build -v -o installer ./cmd/installer 2>&1; then
        echo "[Bootstrap] Build complete!"
        cd "$SCRIPT_DIR"
        return 0
    else
        echo "[Bootstrap] ERROR: Build failed." >&2
        cd "$SCRIPT_DIR"
        return 1
    fi
}

# =============================================================================
# Bootstrap: TUI binary not found - auto-build it
# =============================================================================

echo ""

# Step 1: Ensure Go is installed
if ! check_go_installed; then
    install_go || {
        echo "" >&2
        echo "Manual installation:" >&2
        echo "  Visit https://go.dev/dl/ to download Go 1.23+" >&2
        echo "  Then run: cd $SCRIPT_DIR/tui && go build -o installer ./cmd/installer" >&2
        exit 1
    }
fi

# Step 2: Build the TUI binary
build_tui || {
    echo "" >&2
    echo "Manual build command:" >&2
    echo "  cd $SCRIPT_DIR/tui && go build -o installer ./cmd/installer" >&2
    exit 1
}

echo ""

# Step 3: Launch the newly built TUI
if [[ -f "$GO_BINARY" && -x "$GO_BINARY" ]]; then
    exec "$GO_BINARY" "$@"
else
    echo "ERROR: Binary still not found after build." >&2
    exit 1
fi
