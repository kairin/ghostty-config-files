#!/usr/bin/env bash
#
# Module: Go - Install Latest Version
# Purpose: Download and install the latest Go version from go.dev
#
set -euo pipefail

# 1. Bootstrap
source "$(dirname "${BASH_SOURCE[0]}")/../../../init.sh"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Constants
readonly GO_DL_JSON_URL="https://go.dev/dl/?mode=json"

# Temp directory tracking
TEMP_DIR=""

cleanup_temp_files() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
}
trap cleanup_temp_files EXIT ERR INT TERM

main() {
    local task_id="go-install"
    # We don't register task here as it's handled by the runner, but we can log
    log "INFO" "Starting Go installation..."

    # Step 1: Determine OS and Arch
    local os
    os=$(uname -s | tr '[:upper:]' '[:lower:]')
    local arch
    arch=$(uname -m)
    
    # Map arch to Go arch
    case "$arch" in
        x86_64) arch="amd64" ;;
        aarch64) arch="arm64" ;;
        armv7l) arch="armv6l" ;; # approximate
        *) 
            log "ERROR" "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    log "INFO" "Detected system: $os/$arch"

    # Step 2: Fetch latest version
    log "INFO" "Fetching latest Go version..."
    local latest_version
    # Try to get version from JSON
    if command -v jq >/dev/null 2>&1; then
        latest_version=$(curl -s "$GO_DL_JSON_URL" | jq -r '.[0].version')
    else
        # Fallback using grep/sed
        latest_version=$(curl -s "$GO_DL_JSON_URL" | grep -oP '"version": "\K[^"]+' | head -1)
    fi

    if [[ -z "$latest_version" ]]; then
        log "ERROR" "Failed to determine latest Go version"
        exit 1
    fi

    log "INFO" "Latest version: $latest_version"

    # Step 2.5: Remove conflicting APT installation (Run BEFORE version check to ensure clean state)
    log "INFO" "Checking for and removing conflicting APT packages..."
    # Always try to remove these to ensure clean state
    sudo apt-get remove -y golang-go golang-1.24-go golang-src golang-doc golang || true
    sudo apt-get autoremove -y || true
    
    # Ensure /usr/bin/go is gone
    if [ -f "/usr/bin/go" ] || [ -L "/usr/bin/go" ]; then
        log "WARNING" "/usr/bin/go still exists. Forcing removal..."
        sudo rm -f /usr/bin/go
    fi

    # Check if already installed
    local current_version
    current_version=$(get_go_version)
    if [[ "$current_version" == "$latest_version" ]]; then
        log "SUCCESS" "✓ Go $latest_version is already installed"
        exit 0
    fi

    # Step 3: Download
    local filename="${latest_version}.${os}-${arch}.tar.gz"
    local download_url="https://go.dev/dl/${filename}"
    
    TEMP_DIR=$(mktemp -d)
    local tar_file="$TEMP_DIR/$filename"

    log "INFO" "Downloading $download_url..."
    if ! curl -fL --progress-bar "$download_url" -o "$tar_file"; then
        log "ERROR" "Failed to download Go binary"
        exit 1
    fi

    # Step 4: Install
    log "INFO" "Installing to /usr/local/go..."
    
    # Remove old installation
    if [ -d "/usr/local/go" ]; then
        log "INFO" "Removing previous installation..."
        sudo rm -rf /usr/local/go
    fi

    # Extract
    log "INFO" "Extracting..."
    if ! sudo tar -C /usr/local -xzf "$tar_file"; then
        log "ERROR" "Failed to extract Go archive"
        exit 1
    fi

    # Create symlinks in /usr/local/bin to ensure precedence over /usr/bin
    log "INFO" "Creating symlinks in /usr/local/bin..."
    sudo ln -sf /usr/local/go/bin/go /usr/local/bin/go
    sudo ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt

    # Step 5: Update PATH
    log "INFO" "Updating PATH..."
    
    # Add to current session for immediate use (prepend to ensure precedence)
    export PATH=/usr/local/go/bin:$PATH
    
    # Persist in shell config
    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
        if [ -f "$rc_file" ]; then
            if ! grep -q '/usr/local/go/bin' "$rc_file"; then
                {
                    echo ""
                    echo "# Go programming language"
                    echo 'export PATH=/usr/local/go/bin:$PATH'
                } >> "$rc_file"
                log "INFO" "Updated $rc_file"
            fi
        fi
    done

    log "SUCCESS" "✓ Go installed successfully"
    log "INFO" "NOTE: You may need to restart your shell or run 'hash -r' to pick up the new version."
    exit 0
}

main "$@"
