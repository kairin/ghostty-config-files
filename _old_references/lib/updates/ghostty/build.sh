#!/usr/bin/env bash
# lib/updates/ghostty/build.sh - Ghostty build operations
# Extracted from lib/updates/ghostty-specific.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_GHOSTTY_BUILD_SOURCED:-}" ]] && return 0
readonly _GHOSTTY_BUILD_SOURCED=1

#######################################
# Verify critical build tools are installed
# Arguments:
#   None
# Outputs:
#   Status messages for each tool
# Returns:
#   0 if all tools present, 1 if any missing
#######################################
verify_critical_build_tools() {
    local missing_critical=()
    local critical_tools=("zig" "pkg-config" "msgfmt" "gcc" "g++")

    echo ""
    echo "=================================="
    echo "     Pre-build System Verification"
    echo "=================================="
    echo "Final system check before building Ghostty..."

    for tool in "${critical_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_critical+=("$tool")
        fi
    done

    if [[ ${#missing_critical[@]} -ne 0 ]]; then
        echo "Critical build tools are missing: ${missing_critical[*]}"
        return 1
    fi

    echo "All critical build tools are available"
    return 0
}

#######################################
# Print manual installation instructions
# Outputs:
#   Instructions for installing missing dependencies
#######################################
print_dependency_instructions() {
    cat <<'EOF'

MANUAL INSTALLATION REQUIRED:
Please run the following commands manually to install missing dependencies:

# Update package lists
sudo apt update

# Install essential build tools and dependencies
sudo apt install -y \
  build-essential \
  pkg-config \
  gettext \
  libxml2-utils \
  pandoc \
  libgtk-4-dev \
  libadwaita-1-dev \
  blueprint-compiler \
  libgtk4-layer-shell-dev \
  libfreetype-dev \
  libharfbuzz-dev \
  libfontconfig-dev \
  libpng-dev \
  libbz2-dev \
  zlib1g-dev \
  libglib2.0-dev \
  libgio-2.0-dev \
  libpango1.0-dev \
  libgdk-pixbuf-2.0-dev \
  libcairo2-dev \
  libvulkan-dev \
  libgraphene-1.0-dev \
  libx11-dev \
  libwayland-dev \
  libonig-dev \
  libxml2-dev

# Verify tools are available
pkg-config --modversion gtk4
pkg-config --modversion libadwaita-1

After installing dependencies, re-run this script.
EOF
}

#######################################
# Verify GTK4 and libadwaita via pkg-config
# Returns:
#   0 if both are available, 1 otherwise
#######################################
verify_gtk4_libadwaita() {
    if pkg-config --exists gtk4 && pkg-config --exists libadwaita-1; then
        local gtk4_version adwaita_version
        gtk4_version=$(pkg-config --modversion gtk4 2>/dev/null || echo "unknown")
        adwaita_version=$(pkg-config --modversion libadwaita-1 2>/dev/null || echo "unknown")
        echo "GTK4 version: $gtk4_version"
        echo "libadwaita version: $adwaita_version"
        return 0
    fi

    echo "GTK4 or libadwaita not properly installed or configured"
    echo "This may cause build failures. Please ensure the development packages are installed."
    return 1
}

#######################################
# Build Ghostty from source
# Arguments:
#   $1 - Source directory (optional, defaults to ~/Apps/ghostty)
# Returns:
#   0 on success, 1 on failure
#######################################
build_ghostty() {
    local source_dir="${1:-$HOME/Apps/ghostty}"

    echo ""
    echo "-> Building Ghostty..."

    cd "$source_dir" || {
        echo "Error: Ghostty application directory not found at $source_dir"
        return 1
    }

    if ! DESTDIR=/tmp/ghostty zig build --prefix /usr -Doptimize=ReleaseFast -Dcpu=baseline; then
        echo "Error: Ghostty build failed."
        return 1
    fi

    echo "Ghostty build completed successfully"
    return 0
}

#######################################
# Verify build output exists
# Arguments:
#   $1 - Build output directory (optional, defaults to /tmp/ghostty)
# Returns:
#   0 if build output valid, 1 otherwise
#######################################
verify_build_output() {
    local build_dir="${1:-/tmp/ghostty}"

    if [[ ! -d "$build_dir" ]]; then
        echo "Error: Build output directory not found: $build_dir"
        return 1
    fi

    if [[ ! -f "$build_dir/usr/bin/ghostty" ]]; then
        echo "Error: Ghostty binary not found in build output"
        return 1
    fi

    echo "Build output verified: $build_dir/usr/bin/ghostty"
    return 0
}

#######################################
# Clean build artifacts
# Arguments:
#   $1 - Build output directory (optional, defaults to /tmp/ghostty)
# Returns:
#   0 always
#######################################
clean_build_artifacts() {
    local build_dir="${1:-/tmp/ghostty}"

    if [[ -d "$build_dir" ]]; then
        echo "-> Cleaning build artifacts: $build_dir"
        rm -rf "$build_dir"
    fi

    return 0
}

# Export functions
export -f verify_critical_build_tools print_dependency_instructions
export -f verify_gtk4_libadwaita build_ghostty
export -f verify_build_output clean_build_artifacts
