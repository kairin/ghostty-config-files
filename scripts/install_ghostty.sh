#!/bin/bash
# Module: install_ghostty.sh
# Purpose: Install Ghostty terminal with snap-first fallback chain and multi-file manager context menu
# Dependencies: verification.sh, common.sh, progress.sh
# Modules Required: Git, Wget, Build-Essential (for source build), snapd (for snap)
# Exit Codes: 0=success, 1=installation failed, 2=invalid argument

# Prevent multiple sourcing of this module (idempotent sourcing)
[[ -n "${INSTALL_GHOSTTY_SH_LOADED:-}" ]] && return 0
readonly INSTALL_GHOSTTY_SH_LOADED=1

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]:-}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

set -euo pipefail
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/progress.sh"
source "${SCRIPT_DIR}/verification.sh"

# ============================================================
# CONFIGURATION (Module Constants)
# ============================================================

readonly ZIG_VERSION="0.14.0"
readonly ZIG_INSTALL_DIR="${HOME}/.local/zig-${ZIG_VERSION}"
readonly GHOSTTY_REPO="https://github.com/ghostty-org/ghostty.git"
readonly GHOSTTY_BUILD_DIR="${HOME}/.cache/ghostty-build"
readonly GHOSTTY_INSTALL_DIR="${HOME}/.local/bin"
readonly MIN_GHOSTTY_VERSION="1.1.4"

# ============================================================
# SNAP-FIRST INSTALLATION FUNCTIONS
# ============================================================

# Function: detect_snap_installation
# Purpose: Detect if Ghostty snap is available with publisher verification
# Args: None
# Returns: 0 if snap available, 1 if not found, 2 if snapd unavailable
# Side Effects: Sets SNAP_AVAILABLE, SNAP_OFFICIAL, SNAP_CONFINEMENT, SNAP_VERSION
# Example: detect_snap_installation && echo "Snap available: $SNAP_AVAILABLE"
detect_snap_installation() {
    # Initialize global state variables
    SNAP_AVAILABLE="no"
    SNAP_OFFICIAL="no"
    SNAP_CONFINEMENT="unknown"
    SNAP_VERSION="unknown"

    # Check if snapd is installed and active
    if ! command -v snap &> /dev/null; then
        echo "  snapd not installed" >&2
        return 2
    fi

    if ! systemctl is-active --quiet snapd.service 2>/dev/null; then
        echo "  snapd service not active" >&2
        return 2
    fi

    # Query snap store for Ghostty
    local snap_info
    if ! snap_info=$(snap info ghostty 2>&1); then
        echo "  Ghostty snap not found in store" >&2
        return 1
    fi

    # Extract publisher verification status
    if echo "$snap_info" | grep -qE '(publisher:.*✓|verified publisher)'; then
        SNAP_OFFICIAL="yes"
        echo "  ✓ Ghostty snap found with verified publisher"
    else
        SNAP_OFFICIAL="no"
        echo "  ⚠ Ghostty snap found but publisher not verified"
    fi

    # Extract confinement mode
    if echo "$snap_info" | grep -qE 'confinement:\s+classic'; then
        SNAP_CONFINEMENT="classic"
        echo "  ✓ Classic confinement (full system access)"
    elif echo "$snap_info" | grep -qE 'confinement:\s+strict'; then
        SNAP_CONFINEMENT="strict"
        echo "  ⚠ Strict confinement (limited functionality for terminals)"
    else
        SNAP_CONFINEMENT="unknown"
        echo "  ⚠ Unknown confinement mode"
    fi

    # Extract version
    SNAP_VERSION=$(echo "$snap_info" | grep -oP 'latest/stable:\s+\K[^\s]+' | head -1)
    echo "  Version: ${SNAP_VERSION}"

    SNAP_AVAILABLE="yes"
    return 0
}

# Function: verify_snap_publisher
# Purpose: Verify snap publisher authenticity to prevent social engineering
# Args: None
# Returns: 0 if publisher verified, 1 if not verified
# Side Effects: Logs publisher verification status
# Example: verify_snap_publisher || echo "Publisher not verified"
verify_snap_publisher() {
    local snap_info
    if ! snap_info=$(snap info ghostty 2>&1); then
        echo "✗ Cannot verify publisher: snap info failed" >&2
        return 1
    fi

    # Multiple verification patterns
    if echo "$snap_info" | grep -qE '(publisher:.*✓|verified publisher|developer:\s+Ghostty)'; then
        echo "✓ Snap publisher verified:"
        echo "$snap_info" | grep -E '(publisher|developer):' | head -3
        return 0
    else
        echo "⚠ Snap publisher NOT verified" >&2
        echo "$snap_info" | grep -E '(publisher|developer):' | head -3 >&2
        return 1
    fi
}

# Function: install_via_snap
# Purpose: Install Ghostty via snap with confinement handling and fallback
# Args: None
# Returns: 0 if snap installed, 1 if strict confinement refused, 2 if snap unavailable
# Side Effects: Installs Ghostty snap, configures PATH
# Example: install_via_snap || echo "Snap installation failed, trying apt..."
install_via_snap() {
    echo "→ Attempting Ghostty installation via snap..."

    # Detect snap availability
    detect_snap_installation
    local snap_status=$?

    if [[ $snap_status -ne 0 ]]; then
        echo "  Snap unavailable (status: $snap_status), falling back to apt" >&2
        return 2
    fi

    # Verify publisher (warning only, not blocking per user decision)
    if ! verify_snap_publisher; then
        echo "  ⚠ WARNING: Publisher not verified, but proceeding per user policy"
    fi

    # Check confinement mode (CRITICAL: refuse strict confinement)
    if [[ "$SNAP_CONFINEMENT" == "strict" ]]; then
        echo "✗ Refusing strict confinement snap (terminals require full system access)" >&2
        echo "  Falling back to apt/source installation for full functionality" >&2
        return 1
    fi

    # Check if already installed
    if snap list ghostty &> /dev/null; then
        echo "  Ghostty snap already installed, refreshing to latest..."
        if snap refresh ghostty 2>&1; then
            echo "✓ Ghostty snap refreshed to latest version"
            return 0
        else
            echo "⚠ Snap refresh failed, but existing installation available" >&2
            return 0
        fi
    fi

    # Install snap with classic confinement
    echo "  Installing Ghostty snap (classic confinement)..."
    if sudo snap install ghostty --classic 2>&1; then
        echo "✓ Ghostty installed via snap successfully"
        echo "  Binary location: /snap/bin/ghostty"
        return 0
    else
        echo "✗ Snap installation failed, falling back to apt" >&2
        return 2
    fi
}

# Function: install_via_apt
# Purpose: Install Ghostty via APT (fallback from snap)
# Args: None
# Returns: 0 if apt installed, 1 if package unavailable, 2 if installation failed
# Side Effects: Installs via apt, updates package cache
# Example: install_via_apt || echo "APT installation failed, trying source build..."
install_via_apt() {
    echo "→ Attempting Ghostty installation via APT..."

    # Update package cache
    echo "  Updating apt package cache..."
    if ! sudo apt update -qq 2>&1; then
        echo "⚠ APT update failed, continuing with existing cache" >&2
    fi

    # Check if Ghostty package exists
    if ! apt-cache show ghostty &> /dev/null; then
        echo "  Ghostty package not available in APT repositories" >&2
        echo "  Falling back to source build" >&2
        return 1
    fi

    # Get available version
    local apt_version
    apt_version=$(apt-cache policy ghostty | grep Candidate | awk '{print $2}')
    echo "  Available APT version: ${apt_version}"

    # Install via apt
    echo "  Installing Ghostty via apt..."
    if sudo apt install -y ghostty 2>&1; then
        echo "✓ Ghostty installed via APT successfully"
        echo "  Binary location: $(command -v ghostty)"
        return 0
    else
        echo "✗ APT installation failed, falling back to source build" >&2
        return 2
    fi
}

# ============================================================
# SOURCE BUILD FUNCTIONS
# ============================================================

# Function: install_build_dependencies
# Purpose: Install system dependencies for Ghostty build
# Args: None
# Returns: 0 if dependencies installed, 1 otherwise
# Side Effects: Installs apt packages
# Example: install_build_dependencies
install_build_dependencies() {
    local required_packages=(
        "git"
        "build-essential"
        "pkg-config"
        "libgtk-4-dev"
        "libadwaita-1-dev"
        "wget"
    )

    local missing_packages=()

    # Check for missing packages
    for package in "${required_packages[@]}"; do
        if ! dpkg -l | grep -qw "^ii.*${package}"; then
            missing_packages+=("$package")
        fi
    done

    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        echo "✓ All build dependencies already installed"
        return 0
    fi

    echo "→ Installing build dependencies: ${missing_packages[*]}"

    # Update package list
    if ! sudo apt update 2>&1 | grep -v "^Hit:"; then
        echo "✗ Failed to update package list" >&2
        return 1
    fi

    # Install missing packages
    if ! sudo apt install -y "${missing_packages[@]}" 2>&1 | grep -E "^(Setting up|Processing)"; then
        echo "✗ Failed to install build dependencies" >&2
        return 1
    fi

    echo "✓ Build dependencies installed successfully"
    return 0
}

# Function: install_zig
# Purpose: Install Zig 0.14.0 compiler for Ghostty build
# Args: None
# Returns: 0 if Zig installed successfully, 1 otherwise
# Side Effects: Installs to ~/.local/zig-0.14.0/, updates PATH
# Example: install_zig
install_zig() {
    local zig_bin="${ZIG_INSTALL_DIR}/zig"

    # Check if already installed
    if [[ -x "$zig_bin" ]]; then
        local installed_version
        installed_version=$("$zig_bin" version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1)
        if [[ "$installed_version" == "$ZIG_VERSION" ]]; then
            echo "✓ Zig ${ZIG_VERSION} already installed at ${zig_bin}"
            export PATH="${ZIG_INSTALL_DIR}:${PATH}"
            return 0
        fi
    fi

    # Determine architecture
    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="aarch64" ;;
        *)
            echo "✗ Unsupported architecture: $arch" >&2
            return 1
            ;;
    esac

    # Download Zig tarball
    local zig_tarball="zig-linux-${arch}-${ZIG_VERSION}.tar.xz"
    local download_url="https://ziglang.org/download/${ZIG_VERSION}/${zig_tarball}"
    local temp_dir
    temp_dir="$(mktemp -d)"

    echo "→ Downloading Zig ${ZIG_VERSION} for ${arch}..."
    if ! wget -q --show-progress -O "${temp_dir}/${zig_tarball}" "$download_url" 2>&1; then
        echo "✗ Failed to download Zig from $download_url" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract tarball
    echo "→ Extracting Zig to ${ZIG_INSTALL_DIR}..."
    mkdir -p "${ZIG_INSTALL_DIR}"
    if ! tar -xJf "${temp_dir}/${zig_tarball}" -C "${ZIG_INSTALL_DIR}" --strip-components=1 2>&1; then
        echo "✗ Failed to extract Zig tarball" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Cleanup
    rm -rf "$temp_dir"

    # Add to PATH
    export PATH="${ZIG_INSTALL_DIR}:${PATH}"

    # Verify installation using verification.sh
    if verify_binary "zig" "${ZIG_VERSION}" "zig version"; then
        echo "✓ Zig ${ZIG_VERSION} installed successfully"
        return 0
    else
        echo "✗ Zig installation verification failed" >&2
        return 1
    fi
}

# Function: build_ghostty
# Purpose: Clone and build Ghostty from source
# Args: None
# Returns: 0 if build successful, 1 otherwise
# Side Effects: Clones repo to ~/.cache/ghostty-build/, builds with Zig
# Example: build_ghostty
build_ghostty() {
    # Ensure Zig is available
    if ! command -v zig &> /dev/null; then
        echo "✗ Zig not found in PATH" >&2
        return 1
    fi

    # Clone or update repository
    if [[ -d "$GHOSTTY_BUILD_DIR" ]]; then
        echo "→ Updating existing Ghostty repository..."
        if ! git -C "$GHOSTTY_BUILD_DIR" pull --rebase 2>&1 | grep -v "Already up to date"; then
            echo "⚠ Git pull failed, removing and re-cloning..." >&2
            rm -rf "$GHOSTTY_BUILD_DIR"
        fi
    fi

    if [[ ! -d "$GHOSTTY_BUILD_DIR" ]]; then
        echo "→ Cloning Ghostty repository..."
        if ! git clone "$GHOSTTY_REPO" "$GHOSTTY_BUILD_DIR" 2>&1 | grep -E "^(Cloning|Receiving)"; then
            echo "✗ Failed to clone Ghostty repository" >&2
            return 1
        fi
    fi

    # Build with Zig
    echo "→ Building Ghostty with Zig (this may take 5-10 minutes)..."
    cd "$GHOSTTY_BUILD_DIR"

    # Clean previous build
    if [[ -d "zig-out" ]]; then
        rm -rf zig-out
    fi

    # Run build with progress indicators
    if ! zig build -Doptimize=ReleaseFast 2>&1 | grep -E "^(Build|Compiling|Linking)"; then
        echo "✗ Ghostty build failed" >&2
        echo "  Check build logs in ${GHOSTTY_BUILD_DIR}" >&2
        return 1
    fi

    # Verify build artifact exists
    if [[ ! -f "zig-out/bin/ghostty" ]]; then
        echo "✗ Build completed but ghostty binary not found" >&2
        return 1
    fi

    echo "✓ Ghostty built successfully"
    return 0
}

# Function: install_ghostty_binary
# Purpose: Install Ghostty binary to ~/.local/bin/
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Copies binary to GHOSTTY_INSTALL_DIR
# Example: install_ghostty_binary
install_ghostty_binary() {
    local source_bin="${GHOSTTY_BUILD_DIR}/zig-out/bin/ghostty"
    local target_bin="${GHOSTTY_INSTALL_DIR}/ghostty"

    # Verify source binary exists
    if [[ ! -f "$source_bin" ]]; then
        echo "✗ Source binary not found: $source_bin" >&2
        return 1
    fi

    # Create installation directory
    mkdir -p "$GHOSTTY_INSTALL_DIR"

    # Copy binary
    echo "→ Installing Ghostty to ${target_bin}..."
    if ! cp "$source_bin" "$target_bin" 2>&1; then
        echo "✗ Failed to copy Ghostty binary" >&2
        return 1
    fi

    # Make executable
    chmod +x "$target_bin"

    # Add to PATH if not already present
    if [[ ":$PATH:" != *":${GHOSTTY_INSTALL_DIR}:"* ]]; then
        export PATH="${GHOSTTY_INSTALL_DIR}:${PATH}"

        # Add to shell RC files
        local shell_rcs=("${HOME}/.bashrc" "${HOME}/.zshrc")
        for rc_file in "${shell_rcs[@]}"; do
            if [[ -f "$rc_file" ]]; then
                if ! grep -q "export PATH=\"${GHOSTTY_INSTALL_DIR}:\$PATH\"" "$rc_file"; then
                    echo "" >> "$rc_file"
                    echo "# Ghostty installation (added by install_ghostty.sh)" >> "$rc_file"
                    echo "export PATH=\"${GHOSTTY_INSTALL_DIR}:\$PATH\"" >> "$rc_file"
                fi
            fi
        done
    fi

    # Verify installation using verification.sh
    if verify_binary "ghostty" "${MIN_GHOSTTY_VERSION}" "ghostty --version"; then
        echo "✓ Ghostty installed successfully to ${target_bin}"
        return 0
    else
        echo "✗ Ghostty installation verification failed" >&2
        return 1
    fi
}

# Function: install_ghostty_from_source
# Purpose: Build Ghostty from source (fallback when snap/apt unavailable)
# Args: None
# Returns: 0 if built successfully, 1 otherwise
# Side Effects: Installs Zig, clones repo, builds Ghostty
# Example: install_ghostty_from_source
install_ghostty_from_source() {
    echo "→ Building Ghostty from source..."

    install_build_dependencies || return 1
    install_zig || return 1
    build_ghostty || return 1
    install_ghostty_binary || return 1

    return 0
}

# Function: install_ghostty_with_fallback
# Purpose: Master installation function with snap-first fallback chain
# Args: None
# Returns: 0 if installed via any method, 1 if all methods failed
# Side Effects: Installs Ghostty via snap, apt, or source
# Example: install_ghostty_with_fallback || exit 1
install_ghostty_with_fallback() {
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   Ghostty Installation (Snap-First Strategy)          ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""

    # Method 1: Official Snap (PREFERRED, <3 minutes)
    if install_via_snap; then
        echo ""
        echo "✅ Ghostty installed successfully via SNAP"
        return 0
    fi

    # Method 2: APT Latest (FALLBACK, ~2 minutes)
    if install_via_apt; then
        echo ""
        echo "✅ Ghostty installed successfully via APT"
        return 0
    fi

    # Method 3: Source Build (LAST RESORT, 5-10 minutes)
    echo ""
    echo "→ Falling back to source build (this will take 5-10 minutes)..."
    if install_ghostty_from_source; then
        echo ""
        echo "✅ Ghostty installed successfully via SOURCE BUILD"
        return 0
    fi

    # All methods failed
    echo ""
    echo "❌ INSTALLATION FAILED: All methods exhausted (snap, apt, source)"
    return 1
}

# ============================================================
# MULTI-FILE MANAGER CONTEXT MENU FUNCTIONS
# ============================================================

# Function: detect_file_manager
# Purpose: Detect active file manager using multiple methods
# Args: None
# Returns: 0 and sets FM_NAME (nautilus/nemo/thunar/unknown)
# Side Effects: Sets global FM_NAME variable with detection confidence
# Example: detect_file_manager && echo "File manager: $FM_NAME"
detect_file_manager() {
    FM_NAME="unknown"
    local confidence="none"

    # Method 1: Check running processes (HIGHEST confidence)
    if pgrep -x nautilus > /dev/null 2>&1; then
        FM_NAME="nautilus"
        confidence="high (process running)"
        echo "  ✓ Detected Nautilus (GNOME Files) via running process"
        return 0
    elif pgrep -x nemo > /dev/null 2>&1; then
        FM_NAME="nemo"
        confidence="high (process running)"
        echo "  ✓ Detected Nemo (Cinnamon Files) via running process"
        return 0
    elif pgrep -x thunar > /dev/null 2>&1; then
        FM_NAME="thunar"
        confidence="high (process running)"
        echo "  ✓ Detected Thunar (XFCE Files) via running process"
        return 0
    fi

    # Method 2: Check XDG_CURRENT_DESKTOP (MEDIUM confidence)
    case "${XDG_CURRENT_DESKTOP:-}" in
        *GNOME*)
            FM_NAME="nautilus"
            confidence="medium (XDG desktop environment)"
            echo "  ✓ Detected GNOME environment, assuming Nautilus"
            return 0
            ;;
        *Cinnamon*)
            FM_NAME="nemo"
            confidence="medium (XDG desktop environment)"
            echo "  ✓ Detected Cinnamon environment, assuming Nemo"
            return 0
            ;;
        *XFCE*)
            FM_NAME="thunar"
            confidence="medium (XDG desktop environment)"
            echo "  ✓ Detected XFCE environment, assuming Thunar"
            return 0
            ;;
    esac

    # Method 3: Check installed packages (LOW confidence)
    if command -v nautilus &> /dev/null || dpkg -l nautilus 2>/dev/null | grep -q ^ii; then
        FM_NAME="nautilus"
        confidence="low (installed package)"
        echo "  ℹ Nautilus installed (not running), using as fallback"
        return 0
    elif command -v nemo &> /dev/null || dpkg -l nemo 2>/dev/null | grep -q ^ii; then
        FM_NAME="nemo"
        confidence="low (installed package)"
        echo "  ℹ Nemo installed (not running), using as fallback"
        return 0
    elif command -v thunar &> /dev/null || dpkg -l thunar 2>/dev/null | grep -q ^ii; then
        FM_NAME="thunar"
        confidence="low (installed package)"
        echo "  ℹ Thunar installed (not running), using as fallback"
        return 0
    fi

    # Method 4: Check default file manager (MEDIUM confidence)
    local default_fm
    default_fm=$(xdg-mime query default inode/directory 2>/dev/null || echo "")
    case "$default_fm" in
        nautilus*|org.gnome.Nautilus*)
            FM_NAME="nautilus"
            confidence="medium (xdg default)"
            echo "  ✓ Detected Nautilus as XDG default file manager"
            return 0
            ;;
        nemo*)
            FM_NAME="nemo"
            confidence="medium (xdg default)"
            echo "  ✓ Detected Nemo as XDG default file manager"
            return 0
            ;;
        thunar*|Thunar*)
            FM_NAME="thunar"
            confidence="medium (xdg default)"
            echo "  ✓ Detected Thunar as XDG default file manager"
            return 0
            ;;
    esac

    # All methods failed - unknown file manager
    echo "  ℹ File manager not detected (will use universal .desktop fallback)"
    FM_NAME="unknown"
    confidence="none"
    return 0
}

# Function: install_nautilus_context_menu
# Purpose: Install "Open in Ghostty" for Nautilus (GNOME Files)
# Args: $1 = ghostty binary path (optional, auto-detects if omitted)
# Returns: 0 if installed successfully, 1 otherwise
# Side Effects: Creates ~/.local/share/nautilus/scripts/Open in Ghostty
# Example: install_nautilus_context_menu "/snap/bin/ghostty"
install_nautilus_context_menu() {
    local ghostty_bin="${1:-$(command -v ghostty)}"
    local scripts_dir="${HOME}/.local/share/nautilus/scripts"
    local script_file="${scripts_dir}/Open in Ghostty"

    # Validate Ghostty binary
    if [[ -z "$ghostty_bin" ]] || [[ ! -x "$ghostty_bin" ]]; then
        echo "✗ Ghostty binary not found or not executable" >&2
        return 1
    fi

    # Create scripts directory
    mkdir -p "$scripts_dir"

    # Create context menu script (snap-aware)
    cat > "$script_file" << EOF
#!/bin/bash
# Nautilus script: Open directory in Ghostty terminal
# Location: ~/.local/share/nautilus/scripts/Open in Ghostty

# Get selected directory or fallback to current directory
if [[ -n "\$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ]]; then
    # Use first selected item
    target_dir=\$(echo "\$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" | head -1)

    # If it's a file, use its parent directory
    if [[ -f "\$target_dir" ]]; then
        target_dir=\$(dirname "\$target_dir")
    fi
else
    # Fallback to current directory
    target_dir="\$NAUTILUS_SCRIPT_CURRENT_URI"
    target_dir=\$(echo "\$target_dir" | sed 's|^file://||')
fi

# Launch Ghostty in the target directory
if [[ -x "${ghostty_bin}" ]]; then
    "${ghostty_bin}" --working-directory="\$target_dir" &
else
    notify-send "Ghostty Error" "Ghostty not found at ${ghostty_bin}"
fi
EOF

    # Make executable
    chmod +x "$script_file"

    # Verify installation
    if [[ -x "$script_file" ]]; then
        echo "✓ Nautilus context menu installed: 'Open in Ghostty'"
        echo "  Location: ${script_file}"
        echo "  Binary: ${ghostty_bin}"
        return 0
    else
        echo "✗ Failed to create Nautilus script" >&2
        return 1
    fi
}

# Function: install_nemo_context_menu
# Purpose: Install "Open in Ghostty" for Nemo (Cinnamon Files)
# Args: $1 = ghostty binary path (optional, auto-detects if omitted)
# Returns: 0 if installed successfully, 1 otherwise
# Side Effects: Creates ~/.local/share/nemo/actions/open-in-ghostty.nemo_action
# Example: install_nemo_context_menu "/snap/bin/ghostty"
install_nemo_context_menu() {
    local ghostty_bin="${1:-$(command -v ghostty)}"
    local actions_dir="${HOME}/.local/share/nemo/actions"
    local action_file="${actions_dir}/open-in-ghostty.nemo_action"

    # Validate Ghostty binary
    if [[ -z "$ghostty_bin" ]] || [[ ! -x "$ghostty_bin" ]]; then
        echo "✗ Ghostty binary not found or not executable" >&2
        return 1
    fi

    # Create actions directory
    mkdir -p "$actions_dir"

    # Create Nemo action file (INI format)
    cat > "$action_file" << EOF
[Nemo Action]
Name=Open in Ghostty
Comment=Open terminal in this directory
Exec=${ghostty_bin} --working-directory=%F
Icon-Name=terminal
Selection=Any
Extensions=dir;
EOF

    # Verify installation
    if [[ -f "$action_file" ]]; then
        echo "✓ Nemo context menu installed: 'Open in Ghostty'"
        echo "  Location: ${action_file}"
        echo "  Binary: ${ghostty_bin}"
        return 0
    else
        echo "✗ Failed to create Nemo action file" >&2
        return 1
    fi
}

# Function: install_thunar_context_menu
# Purpose: Install "Open in Ghostty" for Thunar (XFCE Files)
# Args: $1 = ghostty binary path (optional, auto-detects if omitted)
# Returns: 0 if installed successfully, 1 otherwise
# Side Effects: Edits ~/.config/Thunar/uca.xml to add custom action
# Example: install_thunar_context_menu "/snap/bin/ghostty"
install_thunar_context_menu() {
    local ghostty_bin="${1:-$(command -v ghostty)}"
    local config_dir="${HOME}/.config/Thunar"
    local uca_file="${config_dir}/uca.xml"

    # Validate Ghostty binary
    if [[ -z "$ghostty_bin" ]] || [[ ! -x "$ghostty_bin" ]]; then
        echo "✗ Ghostty binary not found or not executable" >&2
        return 1
    fi

    # Create config directory
    mkdir -p "$config_dir"

    # Create uca.xml if it doesn't exist
    if [[ ! -f "$uca_file" ]]; then
        cat > "$uca_file" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<actions>
</actions>
EOF
    fi

    # Check if action already exists
    if grep -q "Open in Ghostty" "$uca_file" 2>/dev/null; then
        echo "  ℹ Thunar action already exists, skipping"
        return 0
    fi

    # Insert action before closing </actions> tag
    local action_xml
    action_xml=$(cat << EOF
  <action>
    <icon>terminal</icon>
    <name>Open in Ghostty</name>
    <command>${ghostty_bin} --working-directory=%f</command>
    <description>Open terminal in this directory</description>
    <patterns>*</patterns>
    <directories/>
  </action>
EOF
)

    # Safe XML insertion (backup first)
    cp "$uca_file" "${uca_file}.backup"
    sed -i "s|</actions>|${action_xml}\n</actions>|" "$uca_file"

    # Verify installation
    if grep -q "Open in Ghostty" "$uca_file"; then
        echo "✓ Thunar context menu installed: 'Open in Ghostty'"
        echo "  Location: ${uca_file}"
        echo "  Binary: ${ghostty_bin}"
        return 0
    else
        echo "✗ Failed to add Thunar custom action" >&2
        mv "${uca_file}.backup" "$uca_file"  # Restore backup
        return 1
    fi
}

# Function: install_universal_context_menu
# Purpose: Install universal .desktop file (works with most file managers)
# Args: $1 = ghostty binary path (optional, auto-detects if omitted)
# Returns: 0 if installed successfully, 1 otherwise
# Side Effects: Creates ~/.local/share/applications/ghostty-here.desktop
# Example: install_universal_context_menu "/snap/bin/ghostty"
install_universal_context_menu() {
    local ghostty_bin="${1:-$(command -v ghostty)}"
    local desktop_dir="${HOME}/.local/share/applications"
    local desktop_file="${desktop_dir}/ghostty-here.desktop"

    # Validate Ghostty binary
    if [[ -z "$ghostty_bin" ]] || [[ ! -x "$ghostty_bin" ]]; then
        echo "✗ Ghostty binary not found or not executable" >&2
        return 1
    fi

    # Create applications directory
    mkdir -p "$desktop_dir"

    # Create .desktop file (XDG standard)
    cat > "$desktop_file" << EOF
[Desktop Entry]
Type=Application
Name=Open in Ghostty
Comment=Open Ghostty terminal in current directory
Exec=${ghostty_bin} --working-directory=%U
Icon=terminal
Terminal=false
Categories=System;TerminalEmulator;
MimeType=inode/directory;
NoDisplay=true
EOF

    # Update desktop database
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$desktop_dir" 2>/dev/null || true
    fi

    # Verify installation
    if [[ -f "$desktop_file" ]]; then
        echo "✓ Universal context menu installed: 'Open in Ghostty'"
        echo "  Location: ${desktop_file}"
        echo "  Binary: ${ghostty_bin}"
        echo "  Compatible with: Most XDG-compliant file managers"
        return 0
    else
        echo "✗ Failed to create .desktop file" >&2
        return 1
    fi
}

# Function: configure_context_menu
# Purpose: Configure context menu for detected file manager (multi-FM aware)
# Args: None (auto-detects file manager and Ghostty binary)
# Returns: 0 if configured successfully, 1 otherwise
# Side Effects: Installs native FM integration + universal .desktop fallback
# Example: configure_context_menu
configure_context_menu() {
    echo "→ Configuring file manager context menu..."

    # Detect Ghostty binary (snap-aware)
    local ghostty_bin
    if [[ -x "/snap/bin/ghostty" ]]; then
        ghostty_bin="/snap/bin/ghostty"
        echo "  Detected snap installation: ${ghostty_bin}"
    elif [[ -x "${HOME}/.local/bin/ghostty" ]]; then
        ghostty_bin="${HOME}/.local/bin/ghostty"
        echo "  Detected source installation: ${ghostty_bin}"
    elif command -v ghostty &> /dev/null; then
        ghostty_bin="$(command -v ghostty)"
        echo "  Detected system installation: ${ghostty_bin}"
    else
        echo "✗ Ghostty binary not found in any expected location" >&2
        return 1
    fi

    # Detect active file manager
    detect_file_manager

    # Install native integration for detected file manager
    case "$FM_NAME" in
        nautilus)
            install_nautilus_context_menu "$ghostty_bin" || return 1
            ;;
        nemo)
            install_nemo_context_menu "$ghostty_bin" || return 1
            ;;
        thunar)
            install_thunar_context_menu "$ghostty_bin" || return 1
            ;;
        unknown)
            echo "  No specific file manager detected, using universal method"
            ;;
    esac

    # Always install universal .desktop file as fallback (per user decision)
    echo ""
    echo "→ Installing universal .desktop fallback..."
    install_universal_context_menu "$ghostty_bin" || return 1

    echo ""
    echo "✅ Context menu configuration complete"
    if [[ "$FM_NAME" != "unknown" ]]; then
        echo "  ✓ Native integration: ${FM_NAME^}"
    fi
    echo "  ✓ Universal fallback: XDG .desktop file"

    return 0
}

# ============================================================
# PERFORMANCE OPTIMIZATION VERIFICATION
# ============================================================

# Function: verify_performance_optimizations
# Purpose: Ensure 2025 Ghostty optimizations are enabled
# Args: None
# Returns: 0 if optimizations verified, 1 otherwise
# Side Effects: Reads Ghostty configuration
# Example: verify_performance_optimizations
verify_performance_optimizations() {
    local config_file="${HOME}/.config/ghostty/config"

    # Verify configuration file exists
    if [[ ! -f "$config_file" ]]; then
        echo "✗ Ghostty configuration not found: $config_file" >&2
        return 1
    fi

    # Check for required optimizations
    local required_settings=(
        "linux-cgroup"
        "shell-integration"
    )

    local missing_settings=()

    for setting in "${required_settings[@]}"; do
        if ! grep -qE "^${setting}" "$config_file"; then
            missing_settings+=("$setting")
        fi
    done

    if [[ ${#missing_settings[@]} -gt 0 ]]; then
        echo "⚠ Some performance settings missing in ${config_file}:" >&2
        for setting in "${missing_settings[@]}"; do
            echo "    $setting" >&2
        done
        echo "  Note: Configuration will be applied by start.sh" >&2
    fi

    # Validate configuration syntax
    echo "→ Validating Ghostty configuration..."
    if ghostty +show-config &> /dev/null; then
        echo "✓ Ghostty configuration validated successfully"
        return 0
    else
        echo "⚠ Ghostty configuration validation failed (may need deployment)" >&2
        echo "  Run: cp configs/ghostty/config ~/.config/ghostty/config" >&2
        return 0  # Non-blocking, configuration applied later
    fi
}

# ============================================================
# MAIN INSTALLATION FUNCTION
# ============================================================

# Function: install_ghostty
# Purpose: Main entry point for Ghostty installation
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs Ghostty, configures context menu
# Example: install_ghostty
install_ghostty() {
    echo "=== Ghostty Installation (Snap-First with Multi-FM Support) ==="
    echo

    # Step 1: Install Ghostty via snap-first fallback
    if ! install_ghostty_with_fallback; then
        echo "✗ Failed to install Ghostty" >&2
        return 1
    fi

    # Step 2: Configure context menu
    echo
    if ! configure_context_menu; then
        echo "⚠ Context menu configuration failed (non-critical)" >&2
    fi

    # Step 3: Verify performance optimizations (non-blocking)
    echo
    verify_performance_optimizations || true

    echo
    echo "✅ Ghostty installation complete!"
    echo
    echo "Next steps:"
    echo "  1. Deploy configuration: cp configs/ghostty/config ~/.config/ghostty/"
    echo "  2. Restart shell: exec \$SHELL"
    echo "  3. Launch Ghostty: ghostty"
    echo

    return 0
}

# ============================================================
# MODULE SELF-TEST (runs if executed directly, not sourced)
# ============================================================

if [[ $SOURCED_FOR_TESTING -eq 0 ]]; then
    install_ghostty
fi
