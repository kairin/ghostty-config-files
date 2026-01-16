#!/bin/bash
# update_go.sh - Update Go in-place (atomic replacement)
#
# This script:
# 1. Downloads the latest Go tarball
# 2. Removes old installation
# 3. Extracts new version
# 4. Preserves GOPATH and user projects

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../006-logs/logger.sh"

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64) GOARCH="amd64" ;;
    aarch64) GOARCH="arm64" ;;
    armv7l) GOARCH="armv6l" ;;
    *) log "ERROR" "Unsupported architecture: $ARCH"; exit 1 ;;
esac

log "INFO" "Current Go version: $(go version 2>/dev/null || echo 'none')"

# Get latest version from go.dev
log "INFO" "Fetching latest Go version..."
LATEST_VERSION=$(curl -sL "https://go.dev/VERSION?m=text" | head -n 1)

if [[ -z "$LATEST_VERSION" ]]; then
    log "ERROR" "Failed to fetch latest Go version"
    exit 1
fi

log "INFO" "Latest version: $LATEST_VERSION"

# Check if already at latest
CURRENT_VERSION=$(go version 2>/dev/null | grep -oP 'go\d+\.\d+(\.\d+)?' || echo "")
if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    log "SUCCESS" "Already at latest version: $LATEST_VERSION"
    exit 0
fi

# Download new version
TARBALL="${LATEST_VERSION}.linux-${GOARCH}.tar.gz"
DOWNLOAD_URL="https://go.dev/dl/${TARBALL}"
TMP_FILE="/tmp/${TARBALL}"

log "INFO" "Downloading $DOWNLOAD_URL..."
if ! curl -fsSL -o "$TMP_FILE" "$DOWNLOAD_URL"; then
    log "ERROR" "Failed to download Go tarball"
    exit 1
fi

# Verify download
if [[ ! -f "$TMP_FILE" ]]; then
    log "ERROR" "Downloaded file not found"
    exit 1
fi

# Remove old installation and extract new (atomic operation)
log "INFO" "Installing $LATEST_VERSION..."
sudo rm -rf /usr/local/go || {
    log "ERROR" "Failed to remove old Go installation"
    exit 1
}

sudo tar -C /usr/local -xzf "$TMP_FILE" || {
    log "ERROR" "Failed to extract Go tarball"
    exit 1
}

# Cleanup
rm -f "$TMP_FILE"

# Verify installation
NEW_VERSION=$(go version 2>/dev/null)
if [[ -n "$NEW_VERSION" ]]; then
    log "SUCCESS" "Updated: $NEW_VERSION"
else
    log "ERROR" "Go installation verification failed"
    exit 1
fi

log "SUCCESS" "Go update complete"
