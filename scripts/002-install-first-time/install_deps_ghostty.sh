#!/bin/bash
source "$(dirname "$0")/../006-logs/logger.sh"

# Parse method argument (default: source for backwards compatibility)
METHOD="${1:-source}"

log "INFO" "Installing Ghostty dependencies for method: $METHOD..."

# Handle different installation methods
case "$METHOD" in
    snap)
        # Snap method requires minimal dependencies - just ensure snap is available
        log "INFO" "Snap method requires no additional dependencies"

        if ! command -v snap &>/dev/null; then
            log "ERROR" "Snap not available on this system"
            log "ERROR" "Install snapd: sudo apt install snapd"
            exit 1
        fi

        log "SUCCESS" "Snap is available"
        exit 0
        ;;

    source)
        # Continue with existing build-from-source logic below
        log "INFO" "Installing build-from-source dependencies..."
        ;;

    *)
        log "ERROR" "Unknown installation method: $METHOD"
        log "ERROR" "Supported methods: snap, source"
        exit 1
        ;;
esac

# === BUILD-FROM-SOURCE DEPENDENCIES (Original logic) ===
log "INFO" "Installing Ghostty build-from-source dependencies..."

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

# Build-from-source dependencies (Context7 verified)
# https://ghostty.org/docs/install/build
# NOTE: libgtk4-layer-shell-dev is NOT available in Ubuntu 24.04 repos
#       It must be built from source (see install_gtk4_layer_shell below)
BUILD_DEPS=(
    "libgtk-4-dev"
    "libadwaita-1-dev"
    "gettext"
    "libxml2-utils"
    "git"
    "curl"
    "xz-utils"
    "pkg-config"
    "meson"
    "ninja-build"
    "libwayland-dev"
    "libgirepository1.0-dev"
    "valac"
)

log "INFO" "Installing APT build dependencies..."
wait_for_apt_lock

MISSING_PKGS=()
for pkg in "${BUILD_DEPS[@]}"; do
    if ! dpkg -s "$pkg" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    log "INFO" "Installing: ${MISSING_PKGS[*]}"
    if sudo apt-get update && sudo apt-get install -y "${MISSING_PKGS[@]}"; then
        log "SUCCESS" "APT dependencies installed"
    else
        log "ERROR" "Failed to install APT dependencies"
        exit 1
    fi
else
    log "SUCCESS" "All APT dependencies already installed"
fi

# Build gtk4-layer-shell from source (not available in Ubuntu 24.04 repos)
install_gtk4_layer_shell() {
    if pkg-config --exists gtk4-layer-shell-0 2>/dev/null; then
        local VERSION=$(pkg-config --modversion gtk4-layer-shell-0 2>/dev/null)
        log "SUCCESS" "gtk4-layer-shell $VERSION already installed"
        return 0
    fi

    log "INFO" "Building gtk4-layer-shell from source (not in Ubuntu repos)..."

    local BUILD_DIR=$(mktemp -d)
    local ORIG_DIR=$(pwd)

    cd "$BUILD_DIR" || exit 1

    # Clone the repository
    log "INFO" "Cloning gtk4-layer-shell repository..."
    if ! git clone --depth 1 https://github.com/wmww/gtk4-layer-shell.git; then
        log "ERROR" "Failed to clone gtk4-layer-shell"
        cd "$ORIG_DIR"
        rm -rf "$BUILD_DIR"
        exit 1
    fi

    cd gtk4-layer-shell || exit 1

    # Build with meson
    log "INFO" "Configuring build with meson..."
    if ! meson setup build; then
        log "ERROR" "Meson setup failed"
        cd "$ORIG_DIR"
        rm -rf "$BUILD_DIR"
        exit 1
    fi

    log "INFO" "Building gtk4-layer-shell..."
    if ! ninja -C build; then
        log "ERROR" "Ninja build failed"
        cd "$ORIG_DIR"
        rm -rf "$BUILD_DIR"
        exit 1
    fi

    log "INFO" "Installing gtk4-layer-shell..."
    if ! sudo ninja -C build install; then
        log "ERROR" "Installation failed"
        cd "$ORIG_DIR"
        rm -rf "$BUILD_DIR"
        exit 1
    fi

    # Update library cache
    sudo ldconfig

    # Cleanup
    cd "$ORIG_DIR"
    rm -rf "$BUILD_DIR"

    # Verify installation
    if pkg-config --exists gtk4-layer-shell-0; then
        local VERSION=$(pkg-config --modversion gtk4-layer-shell-0 2>/dev/null)
        log "SUCCESS" "gtk4-layer-shell $VERSION built and installed"
    else
        log "ERROR" "gtk4-layer-shell installation verification failed"
        exit 1
    fi
}

# Build blueprint-compiler from source (Ubuntu repos only have 0.12.0, need 0.16.0+)
install_blueprint_compiler() {
    local REQUIRED_VERSION="0.16.0"
    local CURRENT_VERSION=$(blueprint-compiler --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || echo "0.0.0")

    # Check if already installed with correct version
    if command -v blueprint-compiler &>/dev/null; then
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$CURRENT_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            log "SUCCESS" "blueprint-compiler $CURRENT_VERSION already installed (>= $REQUIRED_VERSION)"
            return 0
        else
            log "WARNING" "blueprint-compiler $CURRENT_VERSION installed but need $REQUIRED_VERSION+"
        fi
    fi

    log "INFO" "Building blueprint-compiler from source (Ubuntu repos only have 0.12.0)..."

    local BUILD_DIR=$(mktemp -d)
    local ORIG_DIR=$(pwd)

    cd "$BUILD_DIR" || exit 1

    # Clone the repository
    log "INFO" "Cloning blueprint-compiler repository..."
    if ! git clone --depth 1 --branch v0.16.0 https://gitlab.gnome.org/jwestman/blueprint-compiler.git; then
        log "ERROR" "Failed to clone blueprint-compiler"
        cd "$ORIG_DIR"
        rm -rf "$BUILD_DIR"
        exit 1
    fi

    cd blueprint-compiler || exit 1

    # Build with meson
    log "INFO" "Configuring build with meson..."
    if ! meson setup builddir --prefix=/usr/local; then
        log "ERROR" "Meson setup failed"
        cd "$ORIG_DIR"
        rm -rf "$BUILD_DIR"
        exit 1
    fi

    log "INFO" "Building blueprint-compiler..."
    if ! ninja -C builddir; then
        log "ERROR" "Ninja build failed"
        cd "$ORIG_DIR"
        rm -rf "$BUILD_DIR"
        exit 1
    fi

    log "INFO" "Installing blueprint-compiler to /usr/local..."
    if ! sudo ninja -C builddir install; then
        log "ERROR" "Installation failed"
        cd "$ORIG_DIR"
        rm -rf "$BUILD_DIR"
        exit 1
    fi

    # Cleanup
    cd "$ORIG_DIR"
    rm -rf "$BUILD_DIR"

    # Verify installation
    if command -v blueprint-compiler &>/dev/null; then
        local VERSION=$(blueprint-compiler --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+')
        if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            log "SUCCESS" "blueprint-compiler $VERSION built and installed successfully"
        else
            log "ERROR" "blueprint-compiler installation verification failed (got $VERSION, need $REQUIRED_VERSION+)"
            exit 1
        fi
    else
        log "ERROR" "blueprint-compiler not found after installation"
        exit 1
    fi
}

# Zig installation
# Ghostty requires a specific Zig version defined in build.zig
install_zig() {
    local ZIG_VERSION="0.14.0"  # Default, will be verified against build.zig during build
    local ARCH=$(dpkg --print-architecture)
    local ZIG_ARCH
    local ZIG_PATH="/usr/local/bin/zig"

    # Map Debian architecture to Zig architecture
    case "$ARCH" in
        amd64) ZIG_ARCH="x86_64" ;;
        arm64) ZIG_ARCH="aarch64" ;;
        *)
            log "ERROR" "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    # CRITICAL: Remove snap zig if installed (it shadows our installation)
    if snap list zig &>/dev/null 2>&1; then
        log "WARNING" "Removing snap zig (wrong version for Ghostty)..."
        if sudo snap remove zig; then
            log "SUCCESS" "Snap zig removed"
        else
            log "ERROR" "Failed to remove snap zig"
            exit 1
        fi
    fi

    local ZIG_TARBALL="zig-linux-${ZIG_ARCH}-${ZIG_VERSION}.tar.xz"
    local ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/${ZIG_TARBALL}"
    local ZIG_INSTALL_DIR="/opt/zig-linux-${ZIG_ARCH}-${ZIG_VERSION}"

    # Check if correct Zig version already installed at our location
    if [ -x "$ZIG_PATH" ]; then
        local CURRENT_ZIG=$($ZIG_PATH version 2>/dev/null)
        if [[ "$CURRENT_ZIG" == "$ZIG_VERSION"* ]]; then
            log "SUCCESS" "Zig $CURRENT_ZIG already installed at $ZIG_PATH"
            return 0
        else
            log "INFO" "Zig $CURRENT_ZIG at $ZIG_PATH, but need $ZIG_VERSION"
        fi
    fi

    log "INFO" "Installing Zig $ZIG_VERSION for $ZIG_ARCH..."

    # Download Zig
    local TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR" || exit 1

    log "INFO" "Downloading Zig from $ZIG_URL..."
    if ! curl -L --progress-bar -o "$ZIG_TARBALL" "$ZIG_URL"; then
        log "ERROR" "Failed to download Zig"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Remove old Zig installations in /opt
    log "INFO" "Cleaning up old Zig installations..."
    sudo rm -rf /opt/zig-linux-* 2>/dev/null

    # Extract to /opt
    log "INFO" "Extracting Zig to /opt..."
    if ! sudo tar -xJf "$ZIG_TARBALL" -C /opt; then
        log "ERROR" "Failed to extract Zig"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Create symlink
    log "INFO" "Creating symlink at $ZIG_PATH..."
    sudo rm -f "$ZIG_PATH"
    if sudo ln -sf "$ZIG_INSTALL_DIR/zig" "$ZIG_PATH"; then
        log "SUCCESS" "Zig symlink created"
    else
        log "ERROR" "Failed to create Zig symlink"
        rm -rf "$TMP_DIR"
        exit 1
    fi

    # Cleanup
    rm -rf "$TMP_DIR"

    # Verify installation using explicit path
    if [ -x "$ZIG_PATH" ]; then
        local INSTALLED_VER=$($ZIG_PATH version)
        log "SUCCESS" "Zig $INSTALLED_VER installed at $ZIG_PATH"
    else
        log "ERROR" "Zig installation verification failed"
        exit 1
    fi
}

# Install dependencies in order
install_gtk4_layer_shell
install_zig
install_blueprint_compiler

log "SUCCESS" "All Ghostty build dependencies ready"
