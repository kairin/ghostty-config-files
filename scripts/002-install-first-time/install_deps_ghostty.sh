#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Installing dependencies for ghostty..."

DEPS="libgtk-4-dev libadwaita-1-dev git libgtk4-layer-shell-dev blueprint-compiler libxml2-utils"

# Function to wait for apt lock
wait_for_apt_lock() {
    local lock_file="/var/lib/dpkg/lock-frontend"
    local max_attempts=30 # 5 minutes (10s intervals)
    local attempt=0
    
    while sudo fuser "$lock_file" >/dev/null 2>&1; do
        if [ $attempt -ge $max_attempts ]; then
            log "ERROR" "Timed out waiting for apt lock."
            return 1
        fi
        log "WARNING" "Apt lock is held by another process. Waiting 10s..."
        sleep 10
        ((attempt++))
    done
    return 0
}

log "INFO" "Updating apt..."
wait_for_apt_lock
sudo stdbuf -oL apt-get update

log "INFO" "Installing: $DEPS"
if sudo stdbuf -oL apt-get install -y $DEPS; then
    log "SUCCESS" "Dependencies installed successfully"
else
    log "ERROR" "Failed to install dependencies"
    exit 1
fi

# Install Zig (required for build)
REQUIRED_ZIG_VERSION="0.15.2"
NEED_ZIG_INSTALL=false

if ! command -v zig &> /dev/null; then
    NEED_ZIG_INSTALL=true
else
    CURRENT_ZIG=$(zig version 2>/dev/null || echo "0.0.0")
    log "INFO" "Found Zig version: $CURRENT_ZIG (need >= $REQUIRED_ZIG_VERSION)"

    # Compare versions - extract major.minor
    CURRENT_MAJOR=$(echo "$CURRENT_ZIG" | cut -d. -f1)
    CURRENT_MINOR=$(echo "$CURRENT_ZIG" | cut -d. -f2)
    REQUIRED_MAJOR=$(echo "$REQUIRED_ZIG_VERSION" | cut -d. -f1)
    REQUIRED_MINOR=$(echo "$REQUIRED_ZIG_VERSION" | cut -d. -f2)

    if [ "$CURRENT_MAJOR" -lt "$REQUIRED_MAJOR" ] || \
       ([ "$CURRENT_MAJOR" -eq "$REQUIRED_MAJOR" ] && [ "$CURRENT_MINOR" -lt "$REQUIRED_MINOR" ]); then
        log "WARNING" "Zig $CURRENT_ZIG is too old. Removing and installing $REQUIRED_ZIG_VERSION..."
        # Remove old Zig
        sudo rm -f /usr/local/bin/zig
        sudo rm -rf /usr/local/zig-*
        NEED_ZIG_INSTALL=true
    fi
fi

if [ "$NEED_ZIG_INSTALL" = true ]; then
    log "INFO" "Installing Zig $REQUIRED_ZIG_VERSION..."
    ZIG_INSTALLED=false

    # Try snap first (if available)
    if command -v snap &> /dev/null; then
        log "INFO" "Attempting Zig installation via snap..."
        if sudo snap install zig --classic --beta; then
            log "SUCCESS" "Zig installed via snap"
            ZIG_INSTALLED=true
        else
            log "WARNING" "Snap install failed, trying direct download..."
        fi
    else
        log "INFO" "Snap not available, using direct download..."
    fi

    # Fallback: Direct download from ziglang.org
    if [ "$ZIG_INSTALLED" = false ]; then
        log "INFO" "Installing Zig via direct download..."
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) ZIG_ARCH="x86_64" ;;
            aarch64) ZIG_ARCH="aarch64" ;;
            *) log "ERROR" "Unsupported architecture: $ARCH"; exit 1 ;;
        esac

        # Use Zig 0.15.2 (minimum required by Ghostty 1.3.0+)
        ZIG_VERSION="0.15.2"
        ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz"

        log "INFO" "Downloading Zig ${ZIG_VERSION} for ${ZIG_ARCH}..."
        if wget -q --show-progress -O /tmp/zig.tar.xz "$ZIG_URL"; then
            log "INFO" "Extracting Zig..."
            sudo tar -xf /tmp/zig.tar.xz -C /usr/local/
            sudo ln -sf /usr/local/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}/zig /usr/local/bin/zig
            rm /tmp/zig.tar.xz

            if command -v zig &> /dev/null; then
                log "SUCCESS" "Zig installed via direct download"
                ZIG_INSTALLED=true
            else
                log "ERROR" "Zig installation verification failed"
                exit 1
            fi
        else
            log "ERROR" "Failed to download Zig from $ZIG_URL"
            exit 1
        fi
    fi
else
    log "SUCCESS" "Zig $(zig version 2>/dev/null) is already installed and meets requirements"
fi
