#!/usr/bin/env bash
# lib/installers/zig.sh - Zig compiler installation module

set -euo pipefail

# Source guard
[ -z "${ZIG_SH_LOADED:-}" ] || return 0
ZIG_SH_LOADED=1

# Default Zig version
readonly ZIG_VERSION="${ZIG_VERSION:-0.14.0}"

#
# Install Zig compiler
#
# Args:
#   $1 - Installation directory (optional, defaults to $HOME/Apps/zig)
#
# Returns:
#   0 = success, 1 = failure
#
install_zig() {
    local zig_dir="${1:-${REAL_HOME:-$HOME}/Apps/zig}"
    local zig_version="${ZIG_VERSION}"
    local arch
    
    # Determine architecture
    case "$(uname -m)" in
        x86_64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        *)
            echo "Error: Unsupported architecture $(uname -m)"
            return 1
            ;;
    esac
    
    # Check if Zig is already installed
    if command -v zig &> /dev/null; then
        local current_version
        current_version=$(zig version 2>/dev/null || echo "unknown")
        echo "Zig is already installed (version: $current_version)"
        return 0
    fi
    
    echo "Installing Zig $zig_version..."
    
    # Try apt first (future-proof)
    if apt search zig 2>/dev/null | grep -q "^zig/"; then
        echo "-> Installing Zig via apt..."
        if sudo apt install -y zig; then
            echo "Zig installed successfully via apt"
            return 0
        fi
    fi
    
    # Fallback to installation from source
    echo "-> Installing Zig from source..."
    
    # Create Apps directory if it doesn't exist
    mkdir -p "${REAL_HOME:-$HOME}/Apps"
    
    # Download Zig
    local zig_tarball="zig-linux-$arch-$zig_version.tar.xz"
    local download_url="https://ziglang.org/download/$zig_version/$zig_tarball"
    
    cd "${REAL_HOME:-$HOME}/Apps" || { echo "Error: Cannot access ${REAL_HOME:-$HOME}/Apps"; return 1; }
    
    if [ -d "$zig_dir" ]; then
        echo "-> Removing existing Zig directory..."
        rm -rf "$zig_dir"
    fi
    
    echo "-> Downloading Zig $zig_version..."
    if ! wget -O "$zig_tarball" "$download_url"; then
        echo "Error: Failed to download Zig"
        return 1
    fi
    
    echo "-> Extracting Zig..."
    if ! tar -xf "$zig_tarball"; then
        echo "Error: Failed to extract Zig"
        rm -f "$zig_tarball"
        return 1
    fi
    
    # Rename extracted directory to just 'zig'
    mv "zig-linux-$arch-$zig_version" "zig"
    rm -f "$zig_tarball"
    
    # Add Zig to PATH for this script
    export PATH="$zig_dir:$PATH"
    
    # Create a symlink in /usr/local/bin for system-wide access
    echo "-> Creating system-wide Zig symlink..."
    if ! sudo ln -sf "$zig_dir/zig" /usr/local/bin/zig; then
        echo "Warning: Failed to create system-wide Zig symlink. Zig will be available in this session only."
    fi
    
    # Verify installation
    if command -v zig &> /dev/null; then
        local installed_version
        installed_version=$(zig version 2>/dev/null || echo "unknown")
        echo "Zig installed successfully (version: $installed_version)"
        return 0
    else
        echo "Error: Zig installation verification failed"
        return 1
    fi
}

# Export function
export -f install_zig
