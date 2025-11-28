#!/usr/bin/env bash
#
# lib/tasks/feh.sh - Feh image viewer installation (build from source)
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Build from source with ALL compile-time features enabled
# - Replaces apt version (3.10.3) with latest (3.11.0+)
# - ALL features: curl, exif, inotify, verscmp, xinerama
#
# User Stories: US1 (Fresh Installation), US3 (Re-run Safety)
#
# Requirements:
# - FR-053: Idempotency (skip if already installed)
# - Build dependencies: libimlib2-dev, libcurl4-openssl-dev, etc.
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
readonly FEH_MIN_VERSION="3.11.0"
readonly FEH_REPO="https://github.com/derf/feh.git"
readonly FEH_BUILD_DIR="/tmp/feh-build"
readonly FEH_INSTALL_PREFIX="/usr/local"

# Export for modular installer
export FEH_MIN_VERSION
export FEH_REPO
export FEH_BUILD_DIR
export FEH_INSTALL_PREFIX

# Verify feh installation
verify_feh_installed() {
    if command -v feh >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Get installed feh version
get_installed_feh_version() {
    if command -v feh >/dev/null 2>&1; then
        feh --version 2>&1 | head -1 | grep -oP 'feh version \K[0-9]+\.[0-9]+(\.[0-9]+)?'
    else
        echo ""
    fi
}

# Compare version strings (returns 0 if $1 >= $2)
version_ge() {
    local v1="$1"
    local v2="$2"

    # Use sort -V for version comparison
    local highest
    highest=$(printf '%s\n%s' "$v1" "$v2" | sort -V | tail -n1)
    [ "$v1" = "$highest" ]
}

# Check if source build is needed (APT version too old or not installed)
needs_source_build() {
    if ! verify_feh_installed; then
        return 0  # Not installed, need to build
    fi

    local installed_version
    installed_version=$(get_installed_feh_version)

    if [ -z "$installed_version" ]; then
        return 0  # Cannot determine version, rebuild
    fi

    # Check if installed version meets minimum requirement
    if version_ge "$installed_version" "$FEH_MIN_VERSION"; then
        return 1  # Version is adequate, no build needed
    fi

    return 0  # Version too old, need to build
}

#
# Install feh image viewer from source
#
# Process:
#   1. Check if source build is needed (idempotency)
#   2. Install build dependencies
#   3. Clone feh repository
#   4. Build with all features enabled
#   5. Install to /usr/local (with icons)
#   6. Create desktop entry
#   7. Update icon cache
#   8. Verify installation
#
# Returns:
#   0 = success
#   1 = failure
#
task_install_feh() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installing Feh Image Viewer (Source Build)"
    log "INFO" "════════════════════════════════════════"

    local task_start
    task_start=$(get_unix_timestamp)

    # Step 1: Check if source build is needed (Idempotency)
    log "INFO" "Checking for existing feh installation..."

    if ! needs_source_build; then
        local current_version
        current_version=$(get_installed_feh_version)
        log "INFO" "↷ feh $current_version already installed (≥$FEH_MIN_VERSION)"
        mark_task_completed "install-feh" 0
        return 0
    fi

    # Step 2: Install build dependencies
    log "INFO" "Installing build dependencies..."

    local build_deps=(
        "build-essential"
        "libimlib2-dev"
        "libcurl4-openssl-dev"
        "libpng-dev"
        "libx11-dev"
        "libxt-dev"
        "libxinerama-dev"
        "libexif-dev"
        "libmagic-dev"
        "git"
    )

    if ! sudo apt update -qq; then
        handle_error "install-feh" 1 "Failed to update package list" \
            "Check internet connection" \
            "Try: sudo apt update"
        return 1
    fi

    if ! sudo apt install -y "${build_deps[@]}" 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-feh" 2 "Failed to install build dependencies" \
            "Check apt error messages"
        return 1
    fi

    log "SUCCESS" "✓ Build dependencies installed"

    # Step 3: Clone feh repository
    log "INFO" "Cloning feh repository..."

    if [ -d "$FEH_BUILD_DIR" ]; then
        log "INFO" "  Build directory exists, cleaning..."
        rm -rf "$FEH_BUILD_DIR"
    fi

    if ! git clone --depth 1 "$FEH_REPO" "$FEH_BUILD_DIR" 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-feh" 3 "Failed to clone feh repository" \
            "Check internet connection" \
            "Verify GitHub access: ping github.com"
        return 1
    fi

    log "SUCCESS" "✓ Repository cloned"

    # Step 4: Build feh with all features
    log "INFO" "Building feh with all features enabled..."

    cd "$FEH_BUILD_DIR" || {
        handle_error "install-feh" 4 "Cannot access build directory"
        return 1
    }

    # Enable all compile-time features
    # Features: curl (HTTPS loading), exif (metadata), xinerama (multimonitor),
    #           inotify (file watching), verscmp (version sorting), magic (file type detection)
    local make_opts="curl=1 exif=1 xinerama=1 inotify=1 verscmp=1 magic=1"
    make_opts="$make_opts PREFIX=$FEH_INSTALL_PREFIX"

    if ! make $make_opts 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-feh" 5 "feh build failed" \
            "Check build log for errors" \
            "Verify build dependencies are installed"
        return 1
    fi

    log "SUCCESS" "✓ Build completed"

    # Step 5: Install feh (includes binary, man pages, icons, desktop file)
    log "INFO" "Installing feh to $FEH_INSTALL_PREFIX..."

    if ! sudo make $make_opts install 2>&1 | tee -a "$(get_log_file)"; then
        handle_error "install-feh" 6 "feh installation failed" \
            "Check for permission errors"
        return 1
    fi

    log "SUCCESS" "✓ feh installed to $FEH_INSTALL_PREFIX"

    # Step 6: Verify icons were installed
    log "INFO" "Verifying icon installation..."

    local icon_48="$FEH_INSTALL_PREFIX/share/icons/hicolor/48x48/apps/feh.png"
    local icon_svg="$FEH_INSTALL_PREFIX/share/icons/hicolor/scalable/apps/feh.svg"

    if [ -f "$icon_48" ]; then
        log "SUCCESS" "  ✓ 48x48 PNG icon installed: $icon_48"
    else
        log "WARNING" "  ⚠ 48x48 PNG icon not found (non-critical)"
    fi

    if [ -f "$icon_svg" ]; then
        log "SUCCESS" "  ✓ Scalable SVG icon installed: $icon_svg"
    else
        log "WARNING" "  ⚠ Scalable SVG icon not found (non-critical)"
    fi

    # Step 7: Create/update icon theme index and cache
    log "INFO" "Updating icon cache..."

    local icon_dir="$FEH_INSTALL_PREFIX/share/icons/hicolor"

    # Create index.theme if missing (prevents gtk-update-icon-cache warnings)
    if [ -d "$icon_dir" ] && [ ! -f "$icon_dir/index.theme" ]; then
        log "INFO" "  Creating icon theme index..."
        sudo tee "$icon_dir/index.theme" > /dev/null << 'EOF'
[Icon Theme]
Name=Hicolor
Comment=Fallback icon theme
Hidden=true
Directories=48x48/apps,scalable/apps

[48x48/apps]
Size=48
Context=Applications
Type=Fixed

[scalable/apps]
Size=48
Context=Applications
Type=Scalable
MinSize=8
MaxSize=512
EOF
    fi

    # Update icon cache
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        if [ -d "$icon_dir" ]; then
            sudo gtk-update-icon-cache -f -t "$icon_dir" 2>/dev/null || true
            log "SUCCESS" "  ✓ Icon cache updated"
        fi
    fi

    # Step 8: Create user desktop entry with smart launcher
    log "INFO" "Creating user desktop entry..."

    local user_apps="$HOME/.local/share/applications"
    mkdir -p "$user_apps"

    # Copy system desktop file and customize
    if [ -f "$FEH_INSTALL_PREFIX/share/applications/feh.desktop" ]; then
        cp "$FEH_INSTALL_PREFIX/share/applications/feh.desktop" "$user_apps/feh.desktop"
        # Ensure Icon is set to 'feh' (not 'image-viewer')
        sed -i 's/^Icon=image-viewer$/Icon=feh/' "$user_apps/feh.desktop"
        log "SUCCESS" "  ✓ Desktop entry created: $user_apps/feh.desktop"
    else
        # Create desktop entry manually
        cat > "$user_apps/feh.desktop" << EOF
[Desktop Entry]
Name=Feh
GenericName=Image Viewer
Comment=Fast, lightweight image viewer with all features enabled
Exec=feh %F
Icon=feh
Terminal=false
Type=Application
Categories=Graphics;2DGraphics;Viewer;
MimeType=image/bmp;image/gif;image/jpeg;image/jpg;image/png;image/tiff;image/webp;image/x-bmp;image/x-png;
EOF
        log "SUCCESS" "  ✓ Desktop entry created manually"
    fi

    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$user_apps" 2>/dev/null || true
    fi

    # Step 9: Cleanup build directory
    log "INFO" "Cleaning up build directory..."
    rm -rf "$FEH_BUILD_DIR"

    # Step 10: Verify installation
    log "INFO" "Verifying installation..."

    if verify_feh_installed; then
        local new_version
        new_version=$(get_installed_feh_version)

        # Verify compile-time features
        log "INFO" "Checking compile-time features..."
        local features
        features=$(feh --version 2>&1 | grep -A1 "Compile-time" || echo "")

        if echo "$features" | grep -q "curl"; then
            log "SUCCESS" "  ✓ curl support (HTTPS image loading)"
        fi
        if echo "$features" | grep -q "exif"; then
            log "SUCCESS" "  ✓ EXIF support (image metadata)"
        fi
        if echo "$features" | grep -q "xinerama"; then
            log "SUCCESS" "  ✓ Xinerama support (multimonitor)"
        fi

        local task_end
        task_end=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$task_start" "$task_end")

        mark_task_completed "install-feh" "$duration"

        log "SUCCESS" "════════════════════════════════════════"
        log "SUCCESS" "✓ feh $new_version installed successfully ($(format_duration "$duration"))"
        log "SUCCESS" "════════════════════════════════════════"
        return 0
    else
        handle_error "install-feh" 7 "Installation verification failed" \
            "Check logs for errors" \
            "Try manual verification: feh --version"
        return 1
    fi
}

# Export functions
export -f verify_feh_installed
export -f get_installed_feh_version
export -f version_ge
export -f needs_source_build
export -f task_install_feh
