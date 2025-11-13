#!/bin/bash
# Module: install_node.sh
# Purpose: Install and manage Node.js via fnm (Fast Node Manager)
# Dependencies: curl, bash
# Modules Required: common.sh
# Exit Codes: 0=success, 1=general failure, 2=fnm installation failed, 3=Node installation failed
# Constitutional Compliance: AGENTS.md line 23 mandates fnm for 40x faster startup (<50ms vs 500ms-3s)

set -euo pipefail

# Module-level guard: Allow sourcing for testing (before sourcing common.sh)
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    _INSTALL_NODE_SOURCED=1
else
    _INSTALL_NODE_SOURCED=0
fi

# Source required modules
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${MODULE_DIR}/common.sh"

# Restore our own sourcing status (common.sh sets its own SOURCED_FOR_TESTING)
SOURCED_FOR_TESTING="$_INSTALL_NODE_SOURCED"

# ============================================================
# CLEANUP HANDLER
# ============================================================

# Cleanup function (called on EXIT)
cleanup() {
    local exit_code=$?

    # Only perform cleanup if needed
    if [ -n "${CLEANUP_NEEDED:-}" ]; then
        log_info "🧹 Cleaning up..."

        # Remove temporary fnm installation artifacts if present
        if [ -n "${FNM_INSTALL_TEMP:-}" ] && [ -d "$FNM_INSTALL_TEMP" ]; then
            rm -rf "$FNM_INSTALL_TEMP" 2>/dev/null || true
        fi
    fi

    # Exit with original code
    exit $exit_code
}

# Set trap for cleanup on exit (only if not sourced for testing)
if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    trap cleanup EXIT
fi

# ============================================================
# MODULE CONFIGURATION
# ============================================================

# Default versions (can be overridden by environment variables)
: "${NODE_VERSION:=25}"  # Constitutional compliance: Use latest major version (not LTS)
: "${FNM_DIR:=${HOME}/.local/share/fnm}"  # XDG-compliant default
: "${FNM_INSTALL_URL:=https://fnm.vercel.app/install}"
: "${DRY_RUN:=0}"  # Set to 1 for dry-run mode
: "${FORCE_INSTALL:=0}"  # Set to 1 to force reinstallation

# ============================================================
# UTILITY FUNCTIONS (Version comparison, validation)
# ============================================================

# Function: compare_versions
# Purpose: Compare two semantic version strings
# Args: $1=version1, $2=version2
# Returns: 0 if equal, 1 if v1 > v2, 2 if v1 < v2
# Example: compare_versions "25.1.0" "25.0.0" returns 1
compare_versions() {
    local v1="$1"
    local v2="$2"

    # Remove 'v' prefix if present
    v1="${v1#v}"
    v2="${v2#v}"

    # Split by dots
    IFS='.' read -ra V1 <<< "$v1"
    IFS='.' read -ra V2 <<< "$v2"

    # Compare each component
    for i in 0 1 2; do
        local n1="${V1[$i]:-0}"
        local n2="${V2[$i]:-0}"

        if [[ $n1 -gt $n2 ]]; then
            return 1  # v1 > v2
        elif [[ $n1 -lt $n2 ]]; then
            return 2  # v1 < v2
        fi
    done

    return 0  # v1 == v2
}

# Function: check_internet_connectivity
# Purpose: Verify internet connectivity before downloads
# Args: None
# Returns: 0 if connected, 1 if not
check_internet_connectivity() {
    # Try multiple DNS servers for reliability
    local dns_servers=("8.8.8.8" "1.1.1.1" "9.9.9.9")

    for dns in "${dns_servers[@]}"; do
        if ping -c 1 -W 2 "$dns" >/dev/null 2>&1; then
            return 0
        fi
    done

    log_warn "⚠️  No internet connectivity detected"
    return 1
}

# Function: get_installed_node_version
# Purpose: Get currently installed Node.js version via fnm
# Args: None
# Returns: Version string or empty if not installed
get_installed_node_version() {
    local FNM_BINARY="$FNM_DIR/fnm"

    # Check if node is available in current session
    if command -v node >/dev/null 2>&1; then
        node --version | sed 's/v//'
        return 0
    fi

    # Check if fnm has Node installed (even if not activated)
    if [[ -x "$FNM_BINARY" ]]; then
        # Get default version from fnm
        local default_version
        default_version=$("$FNM_BINARY" list 2>/dev/null | grep -E "default|system" | head -1 | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+" | sed 's/v//' || echo "")

        if [[ -n "$default_version" ]]; then
            echo "$default_version"
            return 0
        fi
    fi

    return 1
}

# Function: get_major_version
# Purpose: Extract major version from version string
# Args: $1=version string
# Returns: Major version number
get_major_version() {
    local version="$1"
    version="${version#v}"
    echo "${version%%.*}"
}

# Function: validate_node_installation
# Purpose: Verify Node.js installation is functional
# Args: None
# Returns: 0 if valid, 1 if not
validate_node_installation() {
    local FNM_BINARY="$FNM_DIR/fnm"

    # Check fnm binary exists and is executable
    if [[ ! -x "$FNM_BINARY" ]]; then
        log_error "❌ fnm binary not found or not executable at $FNM_BINARY"
        return 1
    fi

    # Check if fnm has any Node versions installed
    local installed_versions
    installed_versions=$("$FNM_BINARY" list 2>/dev/null | grep -E "v[0-9]+" || echo "")

    if [[ -z "$installed_versions" ]]; then
        log_error "❌ No Node.js versions found in fnm"
        return 1
    fi

    # Try to get Node version (may require fnm env activation)
    eval "$("$FNM_BINARY" env --use-on-cd --version-file-strategy=recursive 2>/dev/null)" || true

    if ! command -v node >/dev/null 2>&1; then
        log_warn "⚠️  Node.js installed but not in PATH (shell restart required)"
        return 0  # Not a failure, just needs shell restart
    fi

    # Test Node.js execution
    if ! node -e "console.log('OK')" >/dev/null 2>&1; then
        log_error "❌ Node.js installed but not functional"
        return 1
    fi

    return 0
}

# Function: read_version_from_files
# Purpose: Read Node version from .node-version or package.json
# Args: None
# Returns: Version string if found, empty otherwise
read_version_from_files() {
    # Check .node-version file
    if [[ -f ".node-version" ]]; then
        local file_version
        file_version=$(cat .node-version | tr -d '[:space:]' | sed 's/v//')
        if [[ -n "$file_version" ]]; then
            echo "$file_version"
            return 0
        fi
    fi

    # Check package.json engines field
    if [[ -f "package.json" ]] && command -v jq >/dev/null 2>&1; then
        local pkg_version
        pkg_version=$(jq -r '.engines.node // empty' package.json 2>/dev/null | sed 's/[^0-9.]//g')
        if [[ -n "$pkg_version" ]]; then
            echo "$pkg_version"
            return 0
        fi
    fi

    return 1
}

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: install_fnm
# Purpose: Install or update fnm (Fast Node Manager)
# Args: None (uses FNM_DIR environment variable)
# Returns: 0 on success, 2 on failure
# Side Effects: Creates ~/.local/share/fnm directory, modifies shell RC files
install_fnm() {
    log_info "⚡ Installing/updating fnm (Fast Node Manager)..."

    # Check if fnm is already installed
    # Priority 1: Check installation directory directly
    local FNM_BINARY="$FNM_DIR/fnm"
    if [[ -x "$FNM_BINARY" ]]; then
        local fnm_version
        fnm_version=$("$FNM_BINARY" --version 2>/dev/null | awk '{print $2}' || echo "unknown")

        if [[ "$FORCE_INSTALL" -eq 1 ]]; then
            log_info "🔄 Force install requested, reinstalling fnm..."
        elif [[ "$DRY_RUN" -eq 1 ]]; then
            log_info "🔍 [DRY RUN] fnm already installed at $FNM_DIR (version $fnm_version)"
            return 0
        else
            log_info "✅ fnm already installed at $FNM_DIR (version $fnm_version)"
            # Add to current session PATH if not already present
            if [[ ! "$PATH" =~ "$FNM_DIR" ]]; then
                export PATH="$FNM_DIR:$PATH"
            fi
            _check_fnm_update
            return 0
        fi
    # Priority 2: Check PATH
    elif command -v fnm >/dev/null 2>&1; then
        local fnm_version
        fnm_version=$(fnm --version 2>/dev/null | awk '{print $2}' || echo "unknown")

        if [[ "$FORCE_INSTALL" -eq 1 ]]; then
            log_info "🔄 Force install requested, reinstalling fnm..."
        elif [[ "$DRY_RUN" -eq 1 ]]; then
            log_info "🔍 [DRY RUN] fnm already installed in PATH (version $fnm_version)"
            return 0
        else
            log_info "✅ fnm already installed in PATH (version $fnm_version)"
            _check_fnm_update
            return 0
        fi
    fi

    # Check internet connectivity before downloading
    if ! check_internet_connectivity; then
        log_error "❌ Cannot install fnm: No internet connection"
        log_info "💡 Manual recovery: Check network and retry"
        return 2
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "🔍 [DRY RUN] Would install fnm from $FNM_INSTALL_URL"
        return 0
    fi

    log_info "📥 Installing fnm from $FNM_INSTALL_URL..."

    # Install fnm using official installer
    # The installer automatically detects shell and adds to PATH
    if curl -fsSL "$FNM_INSTALL_URL" | bash -s -- --skip-shell >/dev/null 2>&1; then
        log_info "✅ fnm installed to $FNM_DIR"

        # Verify installation
        if [[ ! -x "$FNM_BINARY" ]]; then
            log_error "❌ fnm installation succeeded but binary not found"
            log_info "💡 Manual recovery: Run 'curl -fsSL $FNM_INSTALL_URL | bash'"
            return 2
        fi

        # Add fnm to current session PATH
        export PATH="$FNM_DIR:$PATH"

        # Configure shell integration
        _configure_fnm_shell_integration

        return 0
    else
        log_error "❌ Failed to install fnm"
        log_info "💡 Manual recovery: Run 'curl -fsSL $FNM_INSTALL_URL | bash'"
        return 2
    fi
}

# Function: install_node
# Purpose: Install Node.js using fnm with intelligent version handling
# Args: $1=node_version (optional, defaults to NODE_VERSION env var or file config)
# Returns: 0 on success, 3 on failure
# Side Effects: Installs Node.js, sets default version in fnm
install_node() {
    local node_version="${1:-}"

    # Priority 1: Explicit argument
    # Priority 2: Read from .node-version or package.json
    # Priority 3: Use NODE_VERSION environment variable
    if [[ -z "$node_version" ]]; then
        local file_version
        file_version=$(read_version_from_files)
        if [[ -n "$file_version" ]]; then
            node_version="$file_version"
            log_info "📄 Using version from configuration file: $node_version"
        else
            node_version="$NODE_VERSION"
            log_info "📄 Using default version: $node_version"
        fi
    fi

    log_info "📦 Installing Node.js $node_version via fnm..."

    # Ensure fnm is available (use direct path if needed)
    local FNM_BINARY="$FNM_DIR/fnm"
    if ! command -v fnm >/dev/null 2>&1; then
        # Try to load fnm from known installation location
        if [[ -x "$FNM_BINARY" ]]; then
            export PATH="$FNM_DIR:$PATH"
            eval "$(fnm env --use-on-cd --version-file-strategy=recursive)" 2>/dev/null || true
            log_info "ℹ️  Loaded fnm from $FNM_DIR for current session"
        else
            log_error "❌ fnm not found at $FNM_BINARY"
            log_info "💡 Manual recovery: Install fnm first"
            log_info "   curl -fsSL https://fnm.vercel.app/install | bash"
            return 3
        fi
    else
        log_info "ℹ️  Using fnm from PATH: $(command -v fnm)"
    fi

    # Get currently installed Node version (if any)
    local installed_version
    installed_version=$(get_installed_node_version) || installed_version=""

    # Extract major versions for comparison
    local target_major
    target_major=$(get_major_version "$node_version")

    # Check if target version is already installed
    if [[ -n "$installed_version" ]]; then
        local installed_major
        installed_major=$(get_major_version "$installed_version")

        log_info "📊 Current installation: Node.js v$installed_version"
        log_info "🎯 Target version: Node.js $node_version"

        # Compare versions
        if [[ "$target_major" == "$installed_major" ]]; then
            # Same major version - check if exact match
            if [[ "$installed_version" == "$node_version"* ]]; then
                if [[ "$FORCE_INSTALL" -eq 1 ]]; then
                    log_info "🔄 Force install requested, reinstalling Node.js $node_version..."
                elif [[ "$DRY_RUN" -eq 1 ]]; then
                    log_info "🔍 [DRY RUN] Node.js v$installed_version already installed (matches target)"
                    return 0
                else
                    log_info "✅ Node.js v$installed_version already installed (matches target $node_version)"
                    log_info "💡 To force reinstall: FORCE_INSTALL=1 $0 $node_version"
                    return 0
                fi
            else
                # Minor/patch version difference
                log_info "🔄 Upgrading from v$installed_version to $node_version..."
            fi
        elif [[ "$target_major" -gt "$installed_major" ]]; then
            log_info "⬆️  Upgrading major version: v$installed_major → v$target_major"
        else
            log_warn "⬇️  Downgrading major version: v$installed_major → v$target_major"
            log_warn "⚠️  Other Node.js versions will be preserved by fnm"
        fi
    else
        log_info "📥 No existing Node.js installation detected"
    fi

    # Check internet connectivity before downloading
    if ! check_internet_connectivity; then
        log_error "❌ Cannot install Node.js: No internet connection"
        log_info "💡 Manual recovery: Check network and retry"
        return 3
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "🔍 [DRY RUN] Would install Node.js $node_version"
        log_info "🔍 [DRY RUN] Would set Node.js $node_version as default"
        return 0
    fi

    # Install Node.js
    log_info "📥 Installing Node.js $node_version..."
    if fnm install "$node_version" >/dev/null 2>&1; then
        log_info "✅ Node.js $node_version installed successfully"
    else
        log_error "❌ Failed to install Node.js $node_version"
        log_info "💡 Manual recovery steps:"
        log_info "   1. Check internet connection"
        log_info "   2. Try: fnm install $node_version"
        log_info "   3. Check available versions: fnm ls-remote"
        return 3
    fi

    # Set as default version
    if fnm default "$node_version" >/dev/null 2>&1; then
        log_info "✅ Node.js $node_version set as default"
    else
        log_warn "⚠️  Could not set default version, continuing..."
    fi

    # Activate the installed version
    eval "$(fnm env --use-on-cd --version-file-strategy=recursive)" >/dev/null 2>&1

    # Verify installation
    if validate_node_installation; then
        local new_version
        new_version=$(get_installed_node_version) || new_version="unknown"
        log_info "✅ Node.js v$new_version is now active"
    else
        log_error "❌ Node.js installation validation failed"
        log_info "💡 Manual recovery: Restart shell or run 'source ~/.zshrc'"
        return 3
    fi

    return 0
}

# Function: update_npm
# Purpose: Update npm to latest version with idempotency
# Args: None
# Returns: 0 on success, 1 on failure (non-critical)
# Side Effects: Updates global npm installation
update_npm() {
    log_info "🔄 Checking npm version..."

    if ! command -v npm >/dev/null 2>&1; then
        log_warn "⚠️  npm not found, skipping update"
        return 1
    fi

    local current_npm_version
    current_npm_version=$(npm --version 2>/dev/null || echo "unknown")
    log_info "📊 Current npm version: $current_npm_version"

    # Check internet connectivity before attempting update
    if ! check_internet_connectivity; then
        log_warn "⚠️  No internet connection, skipping npm update"
        return 1
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "🔍 [DRY RUN] Would update npm to latest version"
        return 0
    fi

    log_info "📥 Updating npm to latest version..."
    if npm install -g npm@latest >/dev/null 2>&1; then
        local new_npm_version
        new_npm_version=$(npm --version 2>/dev/null || echo "unknown")

        if [[ "$new_npm_version" != "$current_npm_version" ]]; then
            log_info "✅ npm updated: $current_npm_version → $new_npm_version"
        else
            log_info "✅ npm already at latest version ($new_npm_version)"
        fi
        return 0
    else
        log_warn "⚠️  npm update failed, continuing with existing version"
        log_info "💡 Manual recovery: npm install -g npm@latest"
        return 1
    fi
}

# Function: install_node_full
# Purpose: Complete Node.js setup (fnm + Node + npm update)
# Args: $1=node_version (optional, defaults to NODE_VERSION env var)
#       --dry-run: Show what would be done without doing it
#       --force: Force reinstallation even if already present
# Returns: 0 on success, non-zero on failure
# Side Effects: Installs fnm, Node.js, updates npm
install_node_full() {
    local node_version=""
    local dry_run=0
    local force_install=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                dry_run=1
                export DRY_RUN=1
                shift
                ;;
            --force)
                force_install=1
                export FORCE_INSTALL=1
                shift
                ;;
            *)
                node_version="$1"
                shift
                ;;
        esac
    done

    # Don't set default yet - let install_node handle file detection
    # node_version is empty if not specified as argument

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "🔍 [DRY RUN MODE] Showing what would be installed..."
    fi

    if [[ "$force_install" -eq 1 ]]; then
        log_info "🔄 [FORCE MODE] Will reinstall even if already present..."
    fi

    log_info "🚀 Starting complete Node.js installation (fnm-based)..."

    # Determine target version (for logging purposes)
    local display_version="$node_version"
    if [[ -z "$display_version" ]]; then
        local file_version
        file_version=$(read_version_from_files) || file_version=""
        if [[ -n "$file_version" ]]; then
            display_version="$file_version (from config file)"
        else
            display_version="$NODE_VERSION (default)"
        fi
    fi
    log_info "🎯 Target version: Node.js $display_version"

    # Step 1: Install/update fnm
    log_info "📦 Step 1/4: fnm installation/verification"
    if ! install_fnm; then
        log_error "❌ fnm installation failed"
        return 2
    fi

    # Step 2: Install Node.js (pass node_version, even if empty - install_node will handle defaults)
    log_info "📦 Step 2/4: Node.js installation/verification"
    if [[ -n "$node_version" ]]; then
        if ! install_node "$node_version"; then
            log_error "❌ Node.js installation failed"
            return 3
        fi
    else
        # No explicit version - install_node will read from files or use NODE_VERSION
        if ! install_node; then
            log_error "❌ Node.js installation failed"
            return 3
        fi
    fi

    # Step 3: Update npm (non-critical)
    log_info "📦 Step 3/4: npm update"
    update_npm || log_warn "⚠️  npm update skipped, but continuing..."

    # Step 4: Final verification using direct paths
    log_info "📦 Step 4/4: Final verification"

    if [[ "$dry_run" -eq 1 ]]; then
        log_info "🔍 [DRY RUN] Verification skipped in dry-run mode"
        log_info "✅ Dry run completed successfully!"
        return 0
    fi

    log_info "🔍 Performing installation verification..."

    local FNM_BINARY="$FNM_DIR/fnm"
    if [[ -x "$FNM_BINARY" ]]; then
        local fnm_version
        fnm_version=$("$FNM_BINARY" --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log_info "✅ fnm verified: $fnm_version"
        log_info "📍 Location: $FNM_BINARY"

        # Verify Node.js installation via fnm
        local node_list
        node_list=$("$FNM_BINARY" list 2>/dev/null | grep -E "v[0-9]+" || echo "")
        if [[ -n "$node_list" ]]; then
            log_info "✅ Node.js installed successfully via fnm"
            log_info "📋 Installed versions:"
            echo "$node_list" | while read -r line; do
                log_info "   $line"
            done

            # Show current active version
            local active_version
            active_version=$(get_installed_node_version) || active_version="none"
            if [[ "$active_version" != "none" ]]; then
                log_info "🎯 Active version: Node.js v$active_version"
            else
                log_info "💡 Activate: Run 'source ~/.zshrc' or restart shell"
            fi

            log_info "💡 Quick test: $FNM_BINARY list"
        else
            log_error "❌ fnm installed but no Node.js versions found"
            log_info "💡 Manual recovery: $FNM_BINARY install $node_version"
            return 3
        fi
    else
        log_error "❌ fnm binary not found at expected location"
        log_error "Expected: $FNM_BINARY"
        log_info "💡 Manual recovery: curl -fsSL https://fnm.vercel.app/install | bash"
        return 2
    fi

    log_info "✅ Node.js installation complete!"
    log_info "📊 Performance: fnm provides <50ms startup vs 500ms-3s for NVM"
    log_info "🎯 Constitutional compliance: Using Node.js $node_version (latest major version)"
    return 0
}

# ============================================================
# PRIVATE FUNCTIONS (Internal helpers)
# ============================================================

# Function: _check_fnm_update
# Purpose: Check if fnm update is available and suggest update
# Args: None
# Returns: 0 always (informational only)
_check_fnm_update() {
    log_info "🔄 Checking for fnm updates..."

    # fnm doesn't have built-in version comparison, so we check GitHub releases
    local current_version
    current_version=$(fnm --version 2>/dev/null | awk '{print $2}' || echo "unknown")

    log_info "ℹ️  Current fnm version: $current_version"
    log_info "💡 To update fnm, run: curl -fsSL https://fnm.vercel.app/install | bash"

    return 0
}

# Function: _configure_fnm_shell_integration
# Purpose: Configure shell integration for bash and zsh
# Args: None
# Returns: 0 on success, 1 on failure
_configure_fnm_shell_integration() {
    log_info "🔧 Configuring fnm shell integration..."

    # fnm shell integration block
    local fnm_block='
# fnm (Fast Node Manager) - 2025 Performance Optimized
# Loads 40x faster than NVM, minimal startup impact (<50ms)
export FNM_DIR="$HOME/.local/share/fnm"
if [ -d "$FNM_DIR" ]; then
  export PATH="$FNM_DIR:$PATH"
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
fi
'

    # Configure .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "fnm env" "$HOME/.bashrc" 2>/dev/null; then
            echo "$fnm_block" >> "$HOME/.bashrc"
            log_info "✅ Added fnm to .bashrc"
        else
            log_info "ℹ️  fnm already configured in .bashrc"
        fi
    fi

    # Configure .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "fnm env" "$HOME/.zshrc" 2>/dev/null; then
            echo "$fnm_block" >> "$HOME/.zshrc"
            log_info "✅ Added fnm to .zshrc"
        else
            log_info "ℹ️  fnm already configured in .zshrc"
        fi
    fi

    return 0
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Execute when run directly, not when sourced
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 [OPTIONS] [node_version]" >&2
        echo "" >&2
        echo "Options:" >&2
        echo "  --dry-run    Show what would be installed without actually installing" >&2
        echo "  --force      Force reinstallation even if already present" >&2
        echo "" >&2
        echo "Examples:" >&2
        echo "  $0 25                    # Install Node.js v25 (constitutional default)" >&2
        echo "  $0 --dry-run 25          # Show what would be installed" >&2
        echo "  $0 --force 25            # Force reinstall Node.js v25" >&2
        echo "  $0 24.11.1               # Install specific version" >&2
        echo "" >&2
        echo "Configuration Priority:" >&2
        echo "  1. Explicit version argument" >&2
        echo "  2. .node-version file in current directory" >&2
        echo "  3. package.json engines.node field" >&2
        echo "  4. NODE_VERSION environment variable (default: 25)" >&2
        echo "" >&2
        echo "Constitutional Compliance:" >&2
        echo "  - Uses fnm for 40x faster startup (<50ms vs 500ms-3s)" >&2
        echo "  - Default: Node.js v25 (latest major, not LTS)" >&2
        echo "  - Fully idempotent: safe to run multiple times" >&2
        echo "" >&2
        echo "Environment Variables:" >&2
        echo "  NODE_VERSION=25    Target Node.js version" >&2
        echo "  DRY_RUN=1          Enable dry-run mode" >&2
        echo "  FORCE_INSTALL=1    Enable force mode" >&2
        exit 1
    fi

    # Call main public function
    install_node_full "$@"
    exit $?
fi
