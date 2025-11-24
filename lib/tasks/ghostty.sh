#!/usr/bin/env bash
#
# lib/tasks/ghostty.sh - Ghostty terminal installation from source
#
# CONTEXT7 STATUS: API authentication failed (invalid key)
# FALLBACK STRATEGY: Use constitutional compliance requirements and documented best practices
# - Build from source with Zig 0.14.0+ (constitutional requirement)
# - XDG-compliant installation location
# - 2025 performance optimizations (CGroup single-instance, shell integration)
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Ghostty from official .deb package (simplified installation)
# - Configuration in $HOME/.config/ghostty (XDG compliant)
#
# User Stories: US1 (Fresh Installation), US3 (Re-run Safety)
#
# Requirements:
# - FR-053: Idempotency (skip if already installed)
# - FR-071: Query Context7 (fallback if unavailable)
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"
source "${SCRIPT_DIR}/../verification/duplicate_detection.sh"
source "${SCRIPT_DIR}/../verification/unit_tests.sh"

# Installation constants
readonly GHOSTTY_REPO="https://github.com/ghostty-org/ghostty.git"
readonly GHOSTTY_BUILD_DIR="/tmp/ghostty-build"
readonly GHOSTTY_INSTALL_DIR="${GHOSTTY_APP_DIR:-$HOME/.local/share/ghostty}"
readonly ZIG_MIN_VERSION="0.15.2"
readonly ZIG_DOWNLOAD_URL="https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz"
readonly ZIG_INSTALL_DIR="$HOME/Apps/zig"

#
# Check Zig compiler availability and version
#
# Returns:
#   0 = Zig available and version OK
#   1 = Zig missing or version too old
#
check_zig_compiler() {
    log "INFO" "Checking Zig compiler..."

    local zig_version=""
    if command_exists "zig"; then
        zig_version=$(zig version 2>&1 | head -n 1)
        log "INFO" "  Zig version: $zig_version"

        # Extract version number (e.g., "0.15.2" from "0.15.2-dev.1234+abc")
        local zig_major zig_minor zig_patch
        zig_major=$(echo "$zig_version" | cut -d. -f1)
        zig_minor=$(echo "$zig_version" | cut -d. -f2 | cut -d- -f1)
        zig_patch=$(echo "$zig_version" | cut -d. -f3 | cut -d- -f1)

        # Check if version >= 0.15.2
        if [ "$zig_major" -eq 0 ] && [ "$zig_minor" -gt 15 ]; then
            log "SUCCESS" "✓ Zig compiler ready ($zig_version ≥$ZIG_MIN_VERSION)"
            return 0
        elif [ "$zig_major" -eq 0 ] && [ "$zig_minor" -eq 15 ] && [ "${zig_patch:-0}" -ge 2 ]; then
            log "SUCCESS" "✓ Zig compiler ready ($zig_version ≥$ZIG_MIN_VERSION)"
            return 0
        fi

        log "WARNING" "⚠ Zig version too old: $zig_version (need ≥$ZIG_MIN_VERSION)"
        log "INFO" "  Will upgrade Zig automatically..."
    else
        log "WARNING" "⚠ Zig compiler not found"
        log "INFO" "  Will install Zig $ZIG_MIN_VERSION automatically..."
    fi

    # Auto-upgrade/install Zig
    upgrade_zig
    return $?
}

#
# Upgrade or install Zig to required version
#
upgrade_zig() {
    log "INFO" "Installing Zig $ZIG_MIN_VERSION..."

    # Create Apps directory if needed
    mkdir -p "$HOME/Apps"

    # Download Zig
    local zig_tarball="/tmp/zig-$ZIG_MIN_VERSION.tar.xz"
    log "INFO" "  Downloading Zig $ZIG_MIN_VERSION..."
    if ! curl -fsSL "$ZIG_DOWNLOAD_URL" -o "$zig_tarball"; then
        log "ERROR" "✗ Failed to download Zig"
        return 1
    fi

    # Extract
    log "INFO" "  Extracting Zig..."
    cd "$HOME/Apps"
    tar xf "$zig_tarball"

    # Remove/backup old zig installation
    if [ -e "zig" ]; then
        log "INFO" "  Backing up old Zig installation..."
        if [ -d "zig" ] && [ ! -L "zig" ]; then
            # It's a directory (old installation), move it
            mv zig zig-old-backup-$(date +%Y%m%d-%H%M%S)
        elif [ -L "zig" ]; then
            # It's a symlink, just remove it
            rm -f zig
        else
            # It's a file, remove it
            rm -f zig
        fi
    fi

    # Create new symlink
    ln -s "zig-x86_64-linux-$ZIG_MIN_VERSION" zig

    # Cleanup
    rm -f "$zig_tarball"

    # Verify
    if ! command_exists "zig"; then
        log "ERROR" "✗ Zig installation failed (not in PATH)"
        log "ERROR" "  Add to PATH: export PATH=\"$HOME/Apps/zig:\$PATH\""
        return 1
    fi

    local new_version
    new_version=$(zig version 2>&1 | head -n 1)
    log "SUCCESS" "✓ Zig $new_version installed successfully"
    return 0
}

#
# Install Ghostty terminal from source
#
# Process:
#   1. Check duplicate detection (skip if already installed)
#   2. Verify Zig compiler available
#   3. Clone Ghostty repository
#   4. Build with Zig (ReleaseFast optimization)
#   5. Install to XDG-compliant location
#   6. Copy configuration files
#   7. Create desktop entry
#   8. Verify installation
#
# Returns:
#   0 = success
#   1 = failure
#
task_install_ghostty() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installing Ghostty Terminal"
    log "INFO" "════════════════════════════════════════"

    local task_start
    task_start=$(get_unix_timestamp)

    # Step 1: Duplicate Detection (Idempotency)
    log "INFO" "Checking for existing Ghostty installation..."

    if verify_ghostty_installed 2>/dev/null; then
        log "INFO" "↷ Ghostty already installed and functional"
        mark_task_completed "install-ghostty" 0  # 0 seconds (skipped)
        return 0
    fi

    # Step 2: Verify Zig compiler
    if ! check_zig_compiler; then
        handle_error "install-ghostty" 1 "Zig compiler not available or version too old" \
            "Install Zig 0.14.0+ from https://ziglang.org/download/"
        return 1
    fi

    # Step 3: Clone Ghostty repository
    log "INFO" "Cloning Ghostty repository..."

    if [ -d "$GHOSTTY_BUILD_DIR" ]; then
        log "INFO" "  Build directory exists, cleaning..."
        rm -rf "$GHOSTTY_BUILD_DIR"
    fi

    if ! git clone --depth 1 "$GHOSTTY_REPO" "$GHOSTTY_BUILD_DIR" 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-ghostty" 2 "Failed to clone Ghostty repository" \
            "Check internet connection" \
            "Verify GitHub access: ping github.com"
        return 1
    fi

    log "SUCCESS" "✓ Repository cloned"

    # Step 4: Build Ghostty with Zig
    log "INFO" "Building Ghostty (this may take 5-10 minutes)..."

    cd "$GHOSTTY_BUILD_DIR" || {
        handle_error "install-ghostty" 3 "Cannot access build directory" \
            "Check directory permissions"
        return 1
    }

    if ! zig build -Doptimize=ReleaseFast 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-ghostty" 4 "Ghostty build failed" \
            "Check build log for errors" \
            "Verify Zig version: zig version" \
            "Try: zig build clean && zig build -Doptimize=ReleaseFast"
        return 1
    fi

    log "SUCCESS" "✓ Build completed"

    # Step 5: Install to XDG-compliant location
    log "INFO" "Installing Ghostty to $GHOSTTY_INSTALL_DIR..."

    mkdir -p "$GHOSTTY_INSTALL_DIR/bin"
    mkdir -p "$GHOSTTY_INSTALL_DIR/share"

    # Copy binary
    if [ -f "zig-out/bin/ghostty" ]; then
        cp "zig-out/bin/ghostty" "$GHOSTTY_INSTALL_DIR/bin/"
        chmod +x "$GHOSTTY_INSTALL_DIR/bin/ghostty"
        log "SUCCESS" "  ✓ Binary installed"
    else
        handle_error "install-ghostty" 5 "Build output not found: zig-out/bin/ghostty" \
            "Verify build completed successfully"
        return 1
    fi

    # Copy additional files if present
    if [ -d "zig-out/share" ]; then
        cp -r zig-out/share/* "$GHOSTTY_INSTALL_DIR/share/" 2>/dev/null || true
        log "INFO" "  ✓ Shared files installed"
    fi

    # Step 6: Copy configuration files
    log "INFO" "Configuring Ghostty..."

    local config_dir="$HOME/.config/ghostty"
    mkdir -p "$config_dir"

    # Copy configuration from repository if available
    local repo_config="/home/kkk/Apps/ghostty-config-files/configs/ghostty/config"
    if [ -f "$repo_config" ]; then
        cp "$repo_config" "$config_dir/config"
        log "SUCCESS" "  ✓ Configuration copied from repository"
    else
        # Create basic configuration
        cat > "$config_dir/config" <<EOF
# Ghostty Configuration (Generated)
# Performance optimizations (2025)
linux-cgroup = single-instance

# Shell integration
shell-integration = detect
shell-integration-features = true

# Theme
theme = catppuccin-mocha

# Font
font-family = "JetBrains Mono"
font-size = 12

# Scrollback
scrollback-limit = 999999999

# Clipboard
clipboard-paste-protection = true
EOF
        log "SUCCESS" "  ✓ Basic configuration created"
    fi

    # Step 7: Create desktop entry
    log "INFO" "Creating desktop entry..."

    local desktop_dir="$HOME/.local/share/applications"
    mkdir -p "$desktop_dir"

    cat > "$desktop_dir/ghostty.desktop" <<EOF
[Desktop Entry]
Name=Ghostty
Comment=Fast, native, feature-rich terminal emulator
Exec=$GHOSTTY_INSTALL_DIR/bin/ghostty
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
StartupNotify=true
EOF

    chmod +x "$desktop_dir/ghostty.desktop"
    log "SUCCESS" "  ✓ Desktop entry created"

    # Step 8: Add to PATH (if not already)
    if [[ ":$PATH:" != *":$GHOSTTY_INSTALL_DIR/bin:"* ]]; then
        log "INFO" "Adding Ghostty to PATH..."

        for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
            if [ -f "$rc_file" ]; then
                echo "" >> "$rc_file"
                echo "# Ghostty terminal (added by installation script)" >> "$rc_file"
                echo "export PATH=\"$GHOSTTY_INSTALL_DIR/bin:\$PATH\"" >> "$rc_file"
                log "INFO" "  ✓ Updated $rc_file"
            fi
        done
    fi

    # Step 9: Cleanup build directory
    log "INFO" "Cleaning up build directory..."
    rm -rf "$GHOSTTY_BUILD_DIR"

    # Step 10: Verify installation
    log "INFO" "Verifying installation..."

    if verify_ghostty_installed; then
        local task_end
        task_end=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$task_start" "$task_end")

        mark_task_completed "install-ghostty" "$duration"

        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ Ghostty installed successfully ($(format_duration "$duration"))"
        log "SUCCESS" "════════════════════════════════════════"
        return 0
    else
        handle_error "install-ghostty" 6 "Installation verification failed" \
            "Check logs for errors" \
            "Try manual verification: $GHOSTTY_INSTALL_DIR/bin/ghostty --version"
        return 1
    fi
}

# Export functions
export -f check_zig_compiler
export -f task_install_ghostty
