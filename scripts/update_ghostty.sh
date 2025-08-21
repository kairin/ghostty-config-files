#!/bin/bash

set -euo pipefail

# Ghostty Update Script with Agent Monitoring
# Enhanced with comprehensive logging and process monitoring capabilities

CONFIG_UPDATED=false
APP_UPDATED=false

# Agent configuration
AGENT_MODE="${1:-normal}"
AGENT_VERBOSE="${GHOSTTY_AGENT_VERBOSE:-true}"
AGENT_LOG_DIR="/tmp/ghostty-agent-logs"
AGENT_LOG_FILE="$AGENT_LOG_DIR/update-agent-$(date +%s).log"
AGENT_PID_FILE="/tmp/ghostty-update-agent.pid"

# Create agent log directory
mkdir -p "$AGENT_LOG_DIR"

# Store agent PID for monitoring
echo $$ > "$AGENT_PID_FILE"

# Import dynamic messaging functions from setup script if available
get_step_status() {
    local step="$1"
    local status="$2"
    case "$status" in
        "start") echo "🔄 Starting: $step" ;;
        "progress") echo "⏳ In progress: $step" ;;
        "success") echo "✅ Completed: $step" ;;
        "warning") echo "⚠️  Warning in: $step" ;;
        "error") echo "❌ Failed: $step" ;;
        *) echo "📋 $step: $status" ;;
    esac
}

get_process_details() {
    local process="$1"
    local detail="$2"
    echo "   └─ $process: $detail"
}

# Enhanced agent logging with process visibility
agent_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [UPDATE-AGENT] [$level] $message"
    
    # Always log to file
    echo "$log_entry" >> "$AGENT_LOG_FILE"
    
    # Show on console based on verbosity
    if [ "$AGENT_VERBOSE" = "true" ] || [ "$level" = "ERROR" ] || [ "$level" = "WARNING" ]; then
        echo "$log_entry"
    fi
}

# Agent cleanup function
agent_cleanup() {
    agent_log "INFO" "🧹 Update agent cleanup initiated"
    rm -f "$AGENT_PID_FILE"
    agent_log "INFO" "📋 Agent log available at: $AGENT_LOG_FILE"
}

# Set trap for agent cleanup
trap agent_cleanup EXIT

agent_log "INFO" "🚀 Update agent started in mode: $AGENT_MODE"

# Determine the real user's home directory, even when run with sudo
if [ -n "${SUDO_USER:-}" ]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_HOME="$HOME"
fi

# Function to get Ghostty version
get_ghostty_version() {
    if command -v ghostty &> /dev/null; then
        # Capture the version output once
        local version_output
        version_output=$(ghostty --version 2>/dev/null | head -n 1 | awk '{print $NF}')
        if [ -n "$version_output" ]; then
            echo "$version_output"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# This script automates the process of updating Ghostty to the latest version.

# Pull latest changes for the config repository itself
echo ""
echo "-> Pulling latest changes for Ghostty config..."

# Backup current working configuration files
CONFIG_BACKUP_DIR="/tmp/ghostty-config-backup-$(date +%s)"
mkdir -p "$CONFIG_BACKUP_DIR"
echo "-> Backing up current config to $CONFIG_BACKUP_DIR"
cp config theme.conf "$CONFIG_BACKUP_DIR/" 2>/dev/null || echo "Warning: Some config files may not exist"

# Check for local changes before pulling
if ! git diff-index --quiet HEAD --; then
    echo "-> Local changes detected. Stashing them before pull..."
    git stash push -m "Ghostty config changes before pull by setup_ghostty.sh" || { echo "Error: Failed to stash local changes."; exit 1; }
    STASHED_CHANGES=true
else
    STASHED_CHANGES=false
fi

if ! CONFIG_PULL_OUTPUT=$(git pull 2>&1); then
    echo "Error: Failed to pull Ghostty config changes."
    echo "Git output: $CONFIG_PULL_OUTPUT"
    exit 1
fi

# If changes were stashed, reapply them
if [ "$STASHED_CHANGES" = true ]; then
    echo "-> Reapplying stashed changes..."
    git stash pop || { echo "Warning: Failed to reapply stashed changes. Please resolve conflicts manually."; }
fi

# Test the configuration for errors
echo "-> Testing Ghostty configuration for errors..."
if ghostty +show-config >/dev/null 2>config_test_errors.log; then
    echo "✅ Configuration test passed"
    rm -f config_test_errors.log
else
    echo "❌ Configuration test failed. Attempting automatic cleanup..."
    cat config_test_errors.log
    
    # Try to fix common configuration issues automatically
    if [ -x "scripts/fix_config.sh" ]; then
        echo "-> Running automatic configuration cleanup..."
        if scripts/fix_config.sh; then
            echo "-> Automatic cleanup completed, re-testing configuration..."
            if ghostty +show-config >/dev/null 2>&1; then
                echo "✅ Configuration fixed automatically"
                rm -f config_test_errors.log
            else
                echo "❌ Automatic fix failed, restoring backup..."
                cp "$CONFIG_BACKUP_DIR/config" config 2>/dev/null && echo "-> Restored config file"
                cp "$CONFIG_BACKUP_DIR/theme.conf" theme.conf 2>/dev/null && echo "-> Restored theme.conf file"
            fi
        else
            echo "❌ Automatic cleanup failed, restoring backup..."
            cp "$CONFIG_BACKUP_DIR/config" config 2>/dev/null && echo "-> Restored config file"
            cp "$CONFIG_BACKUP_DIR/theme.conf" theme.conf 2>/dev/null && echo "-> Restored theme.conf file"
        fi
    else
        echo "❌ Automatic cleanup script not found, restoring backup..."
        cp "$CONFIG_BACKUP_DIR/config" config 2>/dev/null && echo "-> Restored config file"
        cp "$CONFIG_BACKUP_DIR/theme.conf" theme.conf 2>/dev/null && echo "-> Restored theme.conf file"
    fi
    
    echo "-> Configuration issues handled. Please check for incompatible changes in the repository."
    rm -f config_test_errors.log
    
    # Re-test after restoration/fix
    if ghostty +show-config >/dev/null 2>&1; then
        echo "✅ Configuration now works"
    else
        echo "❌ Configuration still has issues. Please check manually."
    fi
fi

# Clean up backup if everything is working
if [ -d "$CONFIG_BACKUP_DIR" ]; then
    rm -rf "$CONFIG_BACKUP_DIR"
fi


if [[ "$CONFIG_PULL_OUTPUT" == *"Already up to date."* ]]; then
    echo "Ghostty config is already up to date."
    CONFIG_UPDATED=false
else
    echo "$CONFIG_PULL_OUTPUT"
    echo "Ghostty config updated."
    CONFIG_UPDATED=true
fi

echo "Starting dependency check..."
agent_log "INFO" "🔍 Initiating dependency verification process..."

# Function to install Zig
install_zig() {
    local zig_dir="$REAL_HOME/Apps/zig"
    local zig_version="0.14.0"
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
    
    # Try apt first (though we know it's not available, this is future-proof)
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
    mkdir -p "$REAL_HOME/Apps"
    
    # Download Zig
    local zig_tarball="zig-linux-$arch-$zig_version.tar.xz"
    local download_url="https://ziglang.org/download/$zig_version/$zig_tarball"
    
    cd "$REAL_HOME/Apps" || { echo "Error: Cannot access $REAL_HOME/Apps"; return 1; }
    
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

# List of required dependencies
REQUIRED_DEPS=(
    # Build tools and essential packages
    build-essential
    pkg-config
    gettext
    libxml2-utils
    pandoc
    lsof
    wget
    # GTK4 and UI libraries
    libgtk-4-dev
    libadwaita-1-dev
    blueprint-compiler
    libgtk4-layer-shell-dev
    # Font and graphics libraries
    libfreetype-dev
    libharfbuzz-dev
    libfontconfig-dev
    libpng-dev
    libbz2-dev
    # System libraries
    zlib1g-dev
    libglib2.0-dev
    libgio-2.0-dev
    libpango1.0-dev
    libgdk-pixbuf-2.0-dev
    libcairo2-dev
    # Graphics and rendering
    libvulkan-dev
    libgraphene-1.0-dev
    # X11 and Wayland support
    libx11-dev
    libwayland-dev
    # Regex and text processing
    libonig-dev
    libxml2-dev
)

MISSING_DEPS=()
for dep in "${REQUIRED_DEPS[@]}"; do
    echo "Checking dependency: $dep"
    if ! dpkg -s "$dep" >/dev/null 2>&1; then
        echo "dpkg -s exit code: $?"
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo "Required dependencies are not installed: ${MISSING_DEPS[*]}"
    echo "Installing missing dependencies (this will require sudo password)..."
    
    # Try to install dependencies with better error handling
    if sudo apt update; then
        # Install in smaller batches to identify problematic packages
        install_failed=false
        failed_packages=()
        
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
            echo "Please install them manually or check package availability."
        else
            echo "Dependencies installed successfully."
        fi
    else
        echo "Error: Failed to update package lists."
        echo "You can try to install them manually with:"
        echo "sudo apt update && sudo apt install -y ${MISSING_DEPS[*]}"
        exit 1
    fi
fi

# Verify essential build tools are available
echo "Verifying essential build tools..."
BUILD_TOOLS=("gcc" "g++" "make" "pkg-config" "msgfmt" "xmllint")
MISSING_TOOLS=()

for tool in "${BUILD_TOOLS[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo "Warning: Some essential build tools are still missing: ${MISSING_TOOLS[*]}"
    echo "Attempting to install missing build tools..."
    
    # Map missing tools to packages
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
        for tool in "${BUILD_TOOLS[@]}"; do
            if ! command -v "$tool" &> /dev/null; then
                still_missing+=("$tool")
            fi
        done
        
        if [ ${#still_missing[@]} -eq 0 ]; then
            echo "All essential build tools are now available."
        else
            echo "Some build tools are still missing: ${still_missing[*]}"
            echo "Build may fail. Please install them manually."
        fi
    fi
else
    echo "All essential build tools are available."
fi

# Ensure Zig is installed
if ! install_zig; then
    echo "Error: Failed to install Zig."
    exit 1
fi

# Final verification and troubleshooting information
echo ""
echo "=================================="
echo "     Pre-build System Verification"
echo "=================================="

# Check if we have all the tools needed
echo "Final system check before building Ghostty..."

# Essential build tools verification
missing_critical=()
critical_tools=("zig" "pkg-config" "msgfmt" "gcc" "g++")

for tool in "${critical_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        missing_critical+=("$tool")
    fi
done

if [ ${#missing_critical[@]} -ne 0 ]; then
    echo "❌ Critical build tools are missing: ${missing_critical[*]}"
    echo ""
    echo "MANUAL INSTALLATION REQUIRED:"
    echo "Please run the following commands manually to install missing dependencies:"
    echo ""
    echo "# Update package lists"
    echo "sudo apt update"
    echo ""
    echo "# Install essential build tools and dependencies"
    echo "sudo apt install -y \\"
    echo "  build-essential \\"
    echo "  pkg-config \\"
    echo "  gettext \\"
    echo "  libxml2-utils \\"
    echo "  pandoc \\"
    echo "  libgtk-4-dev \\"
    echo "  libadwaita-1-dev \\"
    echo "  blueprint-compiler \\"
    echo "  libgtk4-layer-shell-dev \\"
    echo "  libfreetype-dev \\"
    echo "  libharfbuzz-dev \\"
    echo "  libfontconfig-dev \\"
    echo "  libpng-dev \\"
    echo "  libbz2-dev \\"
    echo "  zlib1g-dev \\"
    echo "  libglib2.0-dev \\"
    echo "  libgio-2.0-dev \\"
    echo "  libpango1.0-dev \\"
    echo "  libgdk-pixbuf-2.0-dev \\"
    echo "  libcairo2-dev \\"
    echo "  libvulkan-dev \\"
    echo "  libgraphene-1.0-dev \\"
    echo "  libx11-dev \\"
    echo "  libwayland-dev \\"
    echo "  libonig-dev \\"
    echo "  libxml2-dev"
    echo ""
    echo "# Verify tools are available"
    echo "pkg-config --modversion gtk4"
    echo "pkg-config --modversion libadwaita-1" 
    echo ""
    echo "After installing dependencies, re-run this script."
    exit 1
else
    echo "✅ All critical build tools are available"
fi

# Check GTK4 and libadwaita via pkg-config
if pkg-config --exists gtk4 && pkg-config --exists libadwaita-1; then
    gtk4_version=$(pkg-config --modversion gtk4 2>/dev/null || echo "unknown")
    adwaita_version=$(pkg-config --modversion libadwaita-1 2>/dev/null || echo "unknown")
    echo "✅ GTK4 version: $gtk4_version"
    echo "✅ libadwaita version: $adwaita_version"
else
    echo "❌ GTK4 or libadwaita not properly installed or configured"
    echo "This may cause build failures. Please ensure the development packages are installed."
fi

echo "System verification complete."

echo "Getting old Ghostty version..."
OLD_VERSION=$(get_ghostty_version)

echo "======================================="
echo "   Updating Ghostty to the latest version"
echo "======================================="

# Navigate to the Ghostty repository
cd ~/Apps/ghostty || { echo "Error: Ghostty application directory not found at ~/Apps/ghostty."; exit 1; }

echo ""
echo "-> Pulling the latest changes for Ghostty app..."

if ! APP_PULL_OUTPUT=$(git pull 2>&1); then
    echo "Error: Failed to pull Ghostty app changes."
    exit 1
fi

if [[ "$APP_PULL_OUTPUT" == *"Already up to date."* ]]; then
    echo "Ghostty app is already up to date."
    APP_UPDATED=false
else
    echo "$APP_PULL_OUTPUT"
    echo "Ghostty app updated."
    APP_UPDATED=true
fi

echo ""
echo "-> Building Ghostty..."
agent_log "INFO" "🔨 Starting Ghostty build process..."
if ! DESTDIR=/tmp/ghostty zig build --prefix /usr -Doptimize=ReleaseFast -Dcpu=baseline; then
    agent_log "ERROR" "❌ Ghostty build failed"
    echo "Error: Ghostty build failed."
    APP_UPDATED=false
    exit 1
fi
agent_log "SUCCESS" "✅ Ghostty build completed successfully"

echo ""
echo "-> Checking for running Ghostty processes holding /usr/bin/ghostty..."
GHOSTTY_PIDS=$(sudo lsof -t /usr/bin/ghostty 2>/dev/null || true)
if [ -n "$GHOSTTY_PIDS" ]; then
    # Convert newlines to spaces for display and create an array
    PID_LIST=$(echo "$GHOSTTY_PIDS" | tr '\n' ' ')
    echo ""
    echo "-> Found Ghostty process(es) (PIDs: $PID_LIST) holding /usr/bin/ghostty. Terminating..."
    # Kill each PID individually
    for pid in $GHOSTTY_PIDS; do
        sudo kill -9 "$pid" 2>/dev/null || true
    done
    sleep 1 # Give the processes a moment to terminate
else
    echo ""
    echo "-> No Ghostty process found holding /usr/bin/ghostty."
fi

echo ""
echo "-> Installing Ghostty..."
if ! sudo cp -r /tmp/ghostty/usr/* /usr/; then
    echo "Error: Ghostty installation failed."
    APP_UPDATED=false
    exit 1
fi

# Test configuration after Ghostty installation to catch any issues
echo "-> Testing configuration after Ghostty installation..."
if ! ghostty +show-config >/dev/null 2>post_install_errors.log; then
    echo "❌ Configuration errors detected after Ghostty installation:"
    cat post_install_errors.log
    echo "-> This suggests the new Ghostty version has compatibility issues with current config."
    echo "-> Consider updating your configuration format or reporting this as a compatibility issue."
    rm -f post_install_errors.log
else
    echo "✅ Configuration works with new Ghostty version"
    rm -f post_install_errors.log
fi

# Return to config directory to pull latest config changes


echo "======================================="
echo "         Ghostty Update Summary"
echo "======================================="

NEW_VERSION=$(get_ghostty_version)

if [ "$CONFIG_UPDATED" = true ]; then
    echo "Ghostty config: Updated"
else
    echo "Ghostty config: Already up to date"
fi

if [ "$APP_UPDATED" = true ]; then
    echo "Ghostty app: Updated to version $NEW_VERSION"
elif [ -n "$NEW_VERSION" ]; then
    echo "Ghostty app: Already at version $NEW_VERSION"
else
    echo "Ghostty app: Not found or not updated"
fi

if [ -z "$OLD_VERSION" ] && [ -z "$NEW_VERSION" ]; then
    echo "Overall Status: Failed (Ghostty not found)"
elif [ "$CONFIG_UPDATED" = true ] || [ "$APP_UPDATED" = true ]; then
    echo "Overall Status: Success (Updates applied)"
else
    echo "Overall Status: Already up to date"
fi
echo "======================================="