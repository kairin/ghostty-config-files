#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Starting Ghostty build-from-source installation..."

# Configuration
GHOSTTY_REPO="https://github.com/ghostty-org/ghostty.git"
BUILD_DIR="/tmp/ghostty-build-$$"
INSTALL_PREFIX="/usr"
ZIG_PATH="/usr/local/bin/zig"

# Cleanup function
cleanup() {
    if [ -d "$BUILD_DIR" ]; then
        log "INFO" "Cleaning up build directory..."
        rm -rf "$BUILD_DIR"
    fi
}
trap cleanup EXIT

# Verify Zig is available at the expected location
if [ ! -x "$ZIG_PATH" ]; then
    log "ERROR" "Zig not found at $ZIG_PATH. Run install_deps_ghostty.sh first."
    if command -v zig &>/dev/null; then
        log "ERROR" "Found zig at $(which zig) but need it at $ZIG_PATH"
    fi
    exit 1
fi

CURRENT_ZIG=$($ZIG_PATH version 2>/dev/null)
log "INFO" "Using Zig $CURRENT_ZIG from $ZIG_PATH"

# Clean previous build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Clone repository with depth 1 for faster download
log "INFO" "Cloning Ghostty repository..."
CLONE_ATTEMPTS=0
MAX_CLONE_ATTEMPTS=3

while [ $CLONE_ATTEMPTS -lt $MAX_CLONE_ATTEMPTS ]; do
    if git clone --depth 1 "$GHOSTTY_REPO" "$BUILD_DIR" 2>&1; then
        log "SUCCESS" "Repository cloned successfully"
        break
    else
        CLONE_ATTEMPTS=$((CLONE_ATTEMPTS + 1))
        if [ $CLONE_ATTEMPTS -lt $MAX_CLONE_ATTEMPTS ]; then
            log "WARNING" "Clone failed, retrying ($CLONE_ATTEMPTS/$MAX_CLONE_ATTEMPTS)..."
            sleep 5
        else
            log "ERROR" "Failed to clone repository after $MAX_CLONE_ATTEMPTS attempts"
            exit 1
        fi
    fi
done

cd "$BUILD_DIR" || exit 1

# Extract required Zig version from build.zig.zon
REQUIRED_ZIG=$(grep -oP '\.zig_version\s*=\s*\.{\s*\.\K[0-9]+\.[0-9]+\.[0-9]+' build.zig.zon 2>/dev/null || \
               grep -oP 'required_zig\s*=\s*"\K[^"]+' build.zig 2>/dev/null || \
               echo "0.14.0")

log "INFO" "Required Zig version: $REQUIRED_ZIG"
log "INFO" "Current Zig version: $CURRENT_ZIG"

# Verify Zig version compatibility
if [[ "$CURRENT_ZIG" != "$REQUIRED_ZIG"* ]]; then
    log "ERROR" "Zig version mismatch! Required: $REQUIRED_ZIG, Have: $CURRENT_ZIG"
    log "ERROR" "Please update Zig by re-running install_deps_ghostty.sh"
    exit 1
fi

# Get git commit info for version tracking
GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
log "INFO" "Building from commit: $GIT_COMMIT"

# Build with optimizations using explicit zig path
log "INFO" "Building Ghostty with ReleaseFast optimization..."
log "INFO" "This may take 5-15 minutes depending on your system..."

BUILD_START=$(date +%s)

if $ZIG_PATH build -Doptimize=ReleaseFast 2>&1 | tee /tmp/ghostty-build-$$.log; then
    BUILD_END=$(date +%s)
    BUILD_DURATION=$((BUILD_END - BUILD_START))
    log "SUCCESS" "Build completed in ${BUILD_DURATION}s"
else
    log "ERROR" "Build failed. Check /tmp/ghostty-build-$$.log for details"
    log "ERROR" "Common issues:"
    log "ERROR" "  - Insufficient RAM (need 4GB+)"
    log "ERROR" "  - Missing development libraries"
    log "ERROR" "  - Zig version mismatch"
    exit 1
fi

# Install to system using explicit zig path
log "INFO" "Installing Ghostty to $INSTALL_PREFIX..."
log "INFO" "This requires sudo privileges..."

if sudo $ZIG_PATH build -p "$INSTALL_PREFIX" -Doptimize=ReleaseFast 2>&1; then
    log "SUCCESS" "Installation to $INSTALL_PREFIX completed"
else
    log "ERROR" "Installation failed"
    exit 1
fi

# Verify installation
if command -v ghostty &>/dev/null; then
    GHOSTTY_VERSION=$(ghostty --version 2>&1 | head -1)
    log "SUCCESS" "Ghostty installed: $GHOSTTY_VERSION"
else
    log "ERROR" "Ghostty binary not found after installation"
    exit 1
fi

# Install terminfo symlink if needed (Ghostty uses TERM=xterm-ghostty)
if [ -f "/usr/share/terminfo/g/ghostty" ] && [ ! -e "/usr/share/terminfo/x/xterm-ghostty" ]; then
    sudo mkdir -p /usr/share/terminfo/x 2>/dev/null
    if sudo ln -sf /usr/share/terminfo/g/ghostty /usr/share/terminfo/x/xterm-ghostty 2>/dev/null; then
        log "SUCCESS" "Created xterm-ghostty terminfo symlink"
    fi
fi

# Install Configurations
CONFIG_SCRIPT="$(dirname "$0")/../002-install-first-time/install_ghostty_config.sh"
if [ -f "$CONFIG_SCRIPT" ]; then
    log "INFO" "Installing Ghostty configurations..."
    bash "$CONFIG_SCRIPT"
else
    log "WARNING" "Config script not found: $CONFIG_SCRIPT"
fi

# Summary
log "SUCCESS" "Ghostty build-from-source installation complete"
log "INFO" "Version: $GHOSTTY_VERSION"
log "INFO" "Commit: $GIT_COMMIT"
log "INFO" "Location: $(which ghostty)"
log "INFO" "Build time: ${BUILD_DURATION}s"
