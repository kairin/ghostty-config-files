#!/usr/bin/env bash
# lib/installers/ghostty-deps.sh - Ghostty dependency management module

set -euo pipefail

# Source guard
[ -z "${GHOSTTY_DEPS_SH_LOADED:-}" ] || return 0
GHOSTTY_DEPS_SH_LOADED=1

# List of required dependencies
readonly GHOSTTY_REQUIRED_DEPS=(
    build-essential
    pkg-config
    gettext
    libxml2-utils
    pandoc
    lsof
    wget
    libgtk-4-dev
    libadwaita-1-dev
    blueprint-compiler
    libgtk4-layer-shell-dev
    libfreetype-dev
    libharfbuzz-dev
    libfontconfig-dev
    libpng-dev
    libbz2-dev
    zlib1g-dev
    libglib2.0-dev
    libgio-2.0-dev
    libpango1.0-dev
    libgdk-pixbuf-2.0-dev
    libcairo2-dev
    libvulkan-dev
    libgraphene-1.0-dev
    libx11-dev
    libwayland-dev
    libonig-dev
    libxml2-dev
)

# Essential build tools
readonly GHOSTTY_BUILD_TOOLS=("gcc" "g++" "make" "pkg-config" "msgfmt" "xmllint")

#
# Install Ghostty dependencies
#
# Returns:
#   0 = success, 1 = some packages failed (non-fatal)
#
install_ghostty_dependencies() {
    echo "Checking Ghostty dependencies..."
    
    local MISSING_DEPS=()
    for dep in "${GHOSTTY_REQUIRED_DEPS[@]}"; do
        echo "Checking dependency: $dep"
        if ! dpkg -s "$dep" > /dev/null 2>&1; then
            MISSING_DEPS+=("$dep")
        fi
    done
    
    if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
        echo "Required dependencies are not installed: ${MISSING_DEPS[*]}"
        echo "Installing missing dependencies..."
        
        if sudo apt update; then
            local install_failed=false
            local failed_packages=()
            
            for dep in "${MISSING_DEPS[@]}"; do
                if ! sudo apt install -y "$dep"; then
                    echo "Warning: Failed to install $dep"
                    failed_packages+=("$dep")
                    install_failed=true
                fi
            done
            
            if $install_failed; then
                echo "Some packages failed to install: ${failed_packages[*]}"
                echo "This may be due to package name differences or repository issues."
                return 1
            else
                echo "Dependencies installed successfully."
            fi
        else
            echo "Error: Failed to update package lists."
            return 1
        fi
    fi
    
    return 0
}

#
# Verify essential build tools are available
#
# Returns:
#   0 = all tools available, 1 = some tools missing
#
verify_build_tools() {
    echo "Verifying essential build tools..."
    
    local MISSING_TOOLS=()
    for tool in "${GHOSTTY_BUILD_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            MISSING_TOOLS+=("$tool")
        fi
    done
    
    if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
        echo "Warning: Some essential build tools are missing: ${MISSING_TOOLS[*]}"
        echo "Attempting to install missing build tools..."
        
        local tool_packages=()
        for tool in "${MISSING_TOOLS[@]}"; do
            case "$tool" in
                "gcc"|"g++"|"make") tool_packages+=("build-essential") ;;
                "msgfmt") tool_packages+=("gettext") ;;
                "xmllint") tool_packages+=("libxml2-utils") ;;
                "pkg-config") tool_packages+=("pkg-config") ;;
            esac
        done
        
        # Remove duplicates and install
        local unique_packages=($(printf "%s\n" "${tool_packages[@]}" | sort -u))
        
        if [ ${#unique_packages[@]} -gt 0 ]; then
            echo "Installing additional packages for build tools: ${unique_packages[*]}"
            for pkg in "${unique_packages[@]}"; do
                sudo apt install -y "$pkg" || echo "Failed to install $pkg"
            done
            
            # Re-verify tools
            local still_missing=()
            for tool in "${GHOSTTY_BUILD_TOOLS[@]}"; do
                if ! command -v "$tool" &> /dev/null; then
                    still_missing+=("$tool")
                fi
            done
            
            if [ ${#still_missing[@]} -eq 0 ]; then
                echo "All essential build tools are now available."
                return 0
            else
                echo "Some build tools are still missing: ${still_missing[*]}"
                return 1
            fi
        fi
    else
        echo "All essential build tools are available."
        return 0
    fi
}

# Export functions
export -f install_ghostty_dependencies
export -f verify_build_tools
