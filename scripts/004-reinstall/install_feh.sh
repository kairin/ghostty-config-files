#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Starting feh build and install process..."

BUILD_DIR="/tmp/feh-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

log "INFO" "Cloning feh repository..."
if git clone --depth 1 https://github.com/derf/feh.git "$BUILD_DIR"; then
    log "SUCCESS" "Cloned successfully"
else
    log "ERROR" "Failed to clone feh"
    exit 1
fi

cd "$BUILD_DIR"

log "INFO" "Building feh..."
if make; then
    log "SUCCESS" "Build successful"
else
    log "ERROR" "Build failed"
    exit 1
fi

log "INFO" "Installing feh..."
if sudo make install; then
    log "SUCCESS" "Installation successful"
else
    log "ERROR" "Installation failed"
    exit 1
fi

log "INFO" "Cleaning up..."
rm -rf "$BUILD_DIR"
