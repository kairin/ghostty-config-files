#!/bin/bash
# install_antigravity.sh - Install Google Antigravity via official APT repository
#
# This script installs Google Antigravity using the official APT repository
# method from https://antigravity.google/download/linux
#
# Exit codes:
#   0 - Success
#   1 - Installation failed

set -euo pipefail

# Source logging utilities
source "$(dirname "$0")/../006-logs/logger.sh"

# Constants
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_FILE="$KEYRING_DIR/antigravity-repo-key.gpg"
SOURCES_LIST="/etc/apt/sources.list.d/antigravity.list"
GPG_KEY_URL="https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg"
APT_REPO="deb [signed-by=$KEYRING_FILE] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main"

# Check if already installed via apt
check_existing_apt_install() {
    if dpkg -l antigravity 2>/dev/null | grep -q "^ii"; then
        log "INFO" "Antigravity is already installed via apt"
        return 0
    fi
    return 1
}

# Step 1: Setup APT repository
setup_apt_repository() {
    log "INFO" "Setting up Google Antigravity APT repository..."

    # Create keyring directory
    log "INFO" "Creating keyring directory..."
    sudo mkdir -p "$KEYRING_DIR"

    # Download and install GPG key (two-step to avoid "nobody" user ownership issue)
    log "INFO" "Downloading GPG signing key from Google..."
    local TEMP_KEY="/tmp/antigravity-repo-key.gpg"

    # Step 1: Download and dearmor as current user (avoids sudo gpg homedir issues)
    if ! curl -fsSL "$GPG_KEY_URL" | gpg --dearmor --yes -o "$TEMP_KEY"; then
        log "ERROR" "Failed to download or dearmor GPG key"
        rm -f "$TEMP_KEY" 2>/dev/null
        return 1
    fi

    # Step 2: Install with correct ownership using sudo install
    if ! sudo install -o root -g root -m 644 "$TEMP_KEY" "$KEYRING_FILE"; then
        log "ERROR" "Failed to install GPG key to $KEYRING_FILE"
        rm -f "$TEMP_KEY" 2>/dev/null
        return 1
    fi
    rm -f "$TEMP_KEY" 2>/dev/null
    log "SUCCESS" "GPG key installed to $KEYRING_FILE (owned by root:root)"

    # Add repository to sources.list.d
    log "INFO" "Adding APT repository..."
    echo "$APT_REPO" | sudo tee "$SOURCES_LIST" > /dev/null
    if [[ ! -f "$SOURCES_LIST" ]]; then
        log "ERROR" "Failed to create sources list file"
        return 1
    fi
    log "SUCCESS" "APT repository added to $SOURCES_LIST"

    return 0
}

# Step 2: Update package cache
update_apt_cache() {
    log "INFO" "Updating APT package cache..."
    if ! sudo apt-get update; then
        log "WARNING" "apt update had warnings, continuing anyway..."
    fi
    log "SUCCESS" "APT cache updated"
    return 0
}

# Step 3: Install Antigravity package
install_antigravity_package() {
    log "INFO" "Installing Google Antigravity package..."

    if sudo apt-get install -y antigravity; then
        log "SUCCESS" "Google Antigravity installed successfully via apt"
        return 0
    else
        log "ERROR" "apt install antigravity failed"
        return 1
    fi
}

# Verify installation
verify_installation() {
    log "INFO" "Verifying installation..."

    # Check dpkg
    if dpkg -l antigravity 2>/dev/null | grep -q "^ii"; then
        local version
        version=$(dpkg -l antigravity 2>/dev/null | grep "^ii" | awk '{print $3}')
        log "SUCCESS" "Antigravity $version installed via apt"
        return 0
    fi

    # Check if binary is available
    if command -v antigravity &>/dev/null; then
        log "SUCCESS" "Antigravity binary is available in PATH"
        return 0
    fi

    log "ERROR" "Installation verification failed"
    return 1
}

# Cleanup on failure
cleanup_on_failure() {
    log "WARNING" "Cleaning up after failed installation..."
    sudo rm -f "$KEYRING_FILE" 2>/dev/null || true
    sudo rm -f "$SOURCES_LIST" 2>/dev/null || true
}

# Main installation flow
main() {
    log "INFO" "Installing Google Antigravity..."
    log "INFO" "Using official APT repository method from https://antigravity.google/download/linux"

    # Check if repository already exists and is configured
    if [[ -f "$SOURCES_LIST" ]] && [[ -f "$KEYRING_FILE" ]]; then
        log "INFO" "APT repository already configured, skipping setup"
    else
        # Setup repository
        if ! setup_apt_repository; then
            cleanup_on_failure
            exit 1
        fi
    fi

    # Update apt cache
    if ! update_apt_cache; then
        log "WARNING" "apt update failed, attempting install anyway..."
    fi

    # Install package
    if ! install_antigravity_package; then
        cleanup_on_failure
        exit 1
    fi

    # Verify
    if ! verify_installation; then
        exit 1
    fi

    log "SUCCESS" "Google Antigravity installation complete!"
    echo ""
    echo "To launch Antigravity:"
    echo "  - Run 'antigravity' from terminal"
    echo "  - Or find 'Google Antigravity' in your application menu"
    exit 0
}

main "$@"
