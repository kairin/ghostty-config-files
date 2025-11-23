#!/usr/bin/env bash
#
# Module: Gum - Install Latest Version
# Purpose: Intelligently install gum using best method (apt/source/binary)
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"

# 2. Load Common Utils
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "${LIB_DIR}/core/version-intelligence.sh"
source "${LIB_DIR}/core/uninstaller.sh"

# Constants
readonly GUM_BINARY_URL="https://github.com/charmbracelet/gum/releases/latest/download/gum_Linux_x86_64.tar.gz"
readonly GUM_GITHUB_REPO="charmbracelet/gum"

# Temp directory tracking
TEMP_DIR=""

# 3. Temp file cleanup on exit
cleanup_temp_files() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
}
trap cleanup_temp_files EXIT ERR INT TERM

# 4. Main Logic
main() {
    # Environment Check
    run_environment_checks || exit 1

    # TUI Integration
    local task_id="gum-install"
    register_task "$task_id" "Installing gum with intelligent strategy"
    start_task "$task_id"

    log "INFO" "Installing gum TUI framework with intelligent strategy..."

    # Step 1: Determine best installation strategy
    log "INFO" "Analyzing installation options..."
    local strategy_json
    strategy_json=$(determine_installation_strategy "gum" "gum" "$GUM_GITHUB_REPO" "N/A")

    local install_method
    install_method=$(echo "$strategy_json" | grep -oP '"method": "\K[^"]+')
    local reason
    reason=$(echo "$strategy_json" | grep -oP '"reason": "\K[^"]+')
    local version_target
    version_target=$(echo "$strategy_json" | grep -oP '"version_target": "\K[^"]+')

    log "INFO" "Strategy: $install_method - $reason"
    log "INFO" "Target version: $version_target"

    # Step 2: Remove old installation completely
    if command -v gum >/dev/null 2>&1; then
        log "INFO" "Removing existing gum installation..."
        uninstall_tool_complete "gum" false
    fi

    # Step 3: Install using determined method
    case "$install_method" in
        apt)
            install_via_apt
            ;;
        github_binary|source)
            install_via_binary
            ;;
        *)
            log "ERROR" "Unknown installation method: $install_method"
            complete_task "$task_id" 1
            exit 1
            ;;
    esac

    # Step 4: Verify installation
    if ! command -v gum >/dev/null 2>&1; then
        log "ERROR" "gum installation failed - binary not found in PATH"
        complete_task "$task_id" 1
        exit 1
    fi

    local installed_version
    installed_version=$(gum --version 2>&1 | grep -oP 'v?\d+\.\d+\.\d+' | head -1 || echo "unknown")
    log "SUCCESS" "✓ gum installed successfully: version $installed_version"

    complete_task "$task_id" 0
    exit 0
}

#
# Install via APT package manager
#
install_via_apt() {
    log "INFO" "Installing via apt..."
    echo "  ⠋ Updating package lists..."

    # Update package lists (silent, non-blocking)
    sudo apt-get update >/dev/null 2>&1 || true

    echo "  ⠋ Installing gum package..."

    # Install gum via apt
    if sudo apt-get install -y gum >/dev/null 2>&1; then
        log "SUCCESS" "✓ Installed gum via apt"
        return 0
    else
        log "WARNING" "apt installation failed, falling back to binary..."
        install_via_binary
        return $?
    fi
}

#
# Install via GitHub binary download
#
install_via_binary() {
    log "INFO" "Installing via GitHub binary download..."
    echo "  ⠋ Downloading latest gum from GitHub releases..."

    TEMP_DIR=$(mktemp -d)
    local tar_file="$TEMP_DIR/gum.tar.gz"

    # Download with progress bar
    if ! curl -fL --progress-bar "$GUM_BINARY_URL" -o "$tar_file" 2>&1; then
        log "ERROR" "Failed to download gum binary"
        return 1
    fi

    # Extract binary
    echo "  ⠋ Extracting gum binary..."
    if ! tar -xzf "$tar_file" -C "$TEMP_DIR"; then
        log "ERROR" "Failed to extract gum binary"
        return 1
    fi

    # Install to ~/.local/bin
    echo "  ⠋ Installing binary to ~/.local/bin..."
    mkdir -p "$HOME/.local/bin"

    if ! cp "$TEMP_DIR/gum" "$HOME/.local/bin/gum"; then
        log "ERROR" "Failed to install gum binary"
        return 1
    fi

    chmod +x "$HOME/.local/bin/gum"
    log "SUCCESS" "✓ Installed gum via binary download"

    # Ensure ~/.local/bin is in PATH
    ensure_local_bin_in_path
    return 0
}

#
# Ensure ~/.local/bin is in PATH and shell config
#
ensure_local_bin_in_path() {
    # Add to current session
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        export PATH="$HOME/.local/bin:$PATH"
        log "INFO" "Added ~/.local/bin to PATH for current session"
    fi

    # Add to shell config files if not already present
    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [ -f "$rc_file" ]; then
            # Check if PATH modification already exists
            if ! grep -q 'HOME/.local/bin' "$rc_file"; then
                {
                    echo ""
                    echo "# User binaries (added by ghostty-config installer)"
                    echo 'export PATH="$HOME/.local/bin:$PATH"'
                } >> "$rc_file"
                log "INFO" "  ✓ Updated $rc_file with PATH modification"
            fi
        fi
    done
}

main "$@"
