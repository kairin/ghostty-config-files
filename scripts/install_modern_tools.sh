#!/bin/bash
# Module: install_modern_tools.sh
# Purpose: Install modern Unix tool replacements
# Dependencies: verification.sh, progress.sh, common.sh
# Modules Required: apt, curl, wget
# Exit Codes: 0=success, 1=installation failed, 2=invalid argument

set -euo pipefail

# Prevent multiple sourcing of this module (idempotent sourcing)
[[ -n "${INSTALL_MODERN_TOOLS_SH_LOADED:-}" ]] && return 0
readonly INSTALL_MODERN_TOOLS_SH_LOADED=1

# Module-level guard: Allow sourcing for testing
# Support both bash (BASH_SOURCE) and zsh (%x)
if [[ -n "${BASH_SOURCE:-}" ]]; then
    # Bash
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        SOURCED_FOR_TESTING=1
    else
        SOURCED_FOR_TESTING=0
    fi
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${ZSH_VERSION:-}" ]]; then
    # Zsh
    if [[ "${(%):-%x}" != "${0}" ]]; then
        SOURCED_FOR_TESTING=1
    else
        SOURCED_FOR_TESTING=0
    fi
    SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    # Fallback
    SOURCED_FOR_TESTING=0
    SCRIPT_DIR="$(cd "$(dirname "${0}")" && pwd)"
fi

# Source dependencies
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/progress.sh"
source "${SCRIPT_DIR}/verification.sh"

# ============================================================
# CONFIGURATION (Module Constants)
# ============================================================

readonly TOOLS_INSTALL_DIR="${HOME}/.local/bin"
readonly EZA_RELEASE_URL="https://api.github.com/repos/eza-community/eza/releases/latest"
readonly DELTA_RELEASE_URL="https://api.github.com/repos/dandavison/delta/releases/latest"

# Tool minimum versions (for verification)
readonly MIN_BAT_VERSION="0.18.0"
readonly MIN_EZA_VERSION="0.10.0"
readonly MIN_RIPGREP_VERSION="13.0.0"
readonly MIN_FD_VERSION="8.0.0"
readonly MIN_DELTA_VERSION="0.16.0"
readonly MIN_ZOXIDE_VERSION="0.9.0"
readonly MIN_FZF_VERSION="0.35.0"

# ============================================================
# PRIVATE HELPER FUNCTIONS
# ============================================================

# Function: _get_latest_github_release_url
# Purpose: Get download URL for latest GitHub release asset
# Args:
#   $1=api_url (required, GitHub API releases URL)
#   $2=asset_pattern (required, regex pattern for asset name)
# Returns: Download URL (stdout)
_get_latest_github_release_url() {
    local api_url="$1"
    local asset_pattern="$2"

    # Fetch latest release data
    local release_data
    if ! release_data=$(curl -fsSL "$api_url" 2>&1); then
        echo "ERROR: Failed to fetch release data from $api_url" >&2
        return 1
    fi

    # Extract download URL matching pattern
    local download_url
    download_url=$(echo "$release_data" | grep -oP "\"browser_download_url\":\s*\"\K[^\"]*${asset_pattern}[^\"]*" | head -1)

    if [[ -z "$download_url" ]]; then
        echo "ERROR: No asset matching pattern '$asset_pattern' found" >&2
        return 1
    fi

    echo "$download_url"
    return 0
}

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: install_bat
# Purpose: Install bat (better cat with syntax highlighting)
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs bat via apt, creates bat alias
# Example: install_bat
install_bat() {
    # Check if bat binary is available (not batcat)
    if command -v bat &> /dev/null; then
        echo "✓ bat already installed"
        return 0
    fi

    # Check if batcat is installed and needs symlink
    if command -v batcat &> /dev/null; then
        mkdir -p "$TOOLS_INSTALL_DIR"
        if [[ ! -L "${TOOLS_INSTALL_DIR}/bat" ]]; then
            ln -sf "$(which batcat)" "${TOOLS_INSTALL_DIR}/bat"
            echo "✓ Created bat → batcat symlink"
        fi
        echo "✓ bat already installed (via batcat)"
        return 0
    fi

    echo "→ Installing bat..."

    # Install via apt
    if ! sudo apt install -y bat 2>&1 | grep -E "^(Setting up|Processing)"; then
        echo "✗ Failed to install bat" >&2
        return 1
    fi

    # Create symlink (Ubuntu installs as 'batcat' due to name conflict)
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        mkdir -p "$TOOLS_INSTALL_DIR"
        ln -sf "$(which batcat)" "${TOOLS_INSTALL_DIR}/bat"
        echo "✓ Created bat → batcat symlink"
    fi

    # Verify installation
    if verify_binary "bat" "${MIN_BAT_VERSION}" "bat --version"; then
        echo "✓ bat installed successfully"
        return 0
    else
        echo "✗ bat installation verification failed" >&2
        return 1
    fi
}

# Function: install_eza
# Purpose: Install eza (better ls with colors and icons)
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Downloads and installs eza from GitHub releases
# Example: install_eza
install_eza() {
    # Check if already installed
    if command -v eza &> /dev/null; then
        if verify_binary "eza" "${MIN_EZA_VERSION}" "eza --version"; then
            echo "✓ eza already installed and meets minimum version"
            return 0
        fi
    fi

    echo "→ Installing eza from GitHub releases..."

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

    # Get latest release download URL
    local asset_pattern="eza_${arch}-unknown-linux-gnu\\.tar\\.gz"
    local download_url
    if ! download_url=$(_get_latest_github_release_url "$EZA_RELEASE_URL" "$asset_pattern"); then
        echo "✗ Failed to get eza download URL" >&2
        return 1
    fi

    # Download and extract
    local temp_dir
    temp_dir="$(mktemp -d)"

    echo "→ Downloading eza..."
    if ! wget -q --show-progress -O "${temp_dir}/eza.tar.gz" "$download_url" 2>&1; then
        echo "✗ Failed to download eza" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract binary
    mkdir -p "$TOOLS_INSTALL_DIR"
    if ! tar -xzf "${temp_dir}/eza.tar.gz" -C "$TOOLS_INSTALL_DIR" ./eza 2>&1; then
        echo "✗ Failed to extract eza" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Cleanup
    rm -rf "$temp_dir"

    # Make executable
    chmod +x "${TOOLS_INSTALL_DIR}/eza"

    # Verify installation
    if verify_binary "eza" "${MIN_EZA_VERSION}" "eza --version"; then
        echo "✓ eza installed successfully"
        return 0
    else
        echo "✗ eza installation verification failed" >&2
        return 1
    fi
}

# Function: install_ripgrep
# Purpose: Install ripgrep (faster grep for code search)
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs ripgrep via apt
# Example: install_ripgrep
install_ripgrep() {
    # Check if already installed
    if command -v rg &> /dev/null; then
        if verify_binary "rg" "${MIN_RIPGREP_VERSION}" "rg --version"; then
            echo "✓ ripgrep already installed and meets minimum version"
            return 0
        fi
    fi

    echo "→ Installing ripgrep..."

    # Install via apt
    if ! sudo apt install -y ripgrep 2>&1 | grep -E "^(Setting up|Processing)"; then
        echo "✗ Failed to install ripgrep" >&2
        return 1
    fi

    # Verify installation
    if verify_binary "rg" "${MIN_RIPGREP_VERSION}" "rg --version"; then
        echo "✓ ripgrep installed successfully"
        return 0
    else
        echo "✗ ripgrep installation verification failed" >&2
        return 1
    fi
}

# Function: install_fd
# Purpose: Install fd (faster find with better UX)
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs fd-find via apt, creates fd symlink
# Example: install_fd
install_fd() {
    # Check if already installed
    if command -v fd &> /dev/null || command -v fdfind &> /dev/null; then
        echo "✓ fd already installed"
        return 0
    fi

    echo "→ Installing fd..."

    # Install via apt (package name: fd-find)
    if ! sudo apt install -y fd-find 2>&1 | grep -E "^(Setting up|Processing)"; then
        echo "✗ Failed to install fd-find" >&2
        return 1
    fi

    # Create symlink (Ubuntu installs as 'fdfind' due to name conflict)
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        mkdir -p "$TOOLS_INSTALL_DIR"
        ln -sf "$(which fdfind)" "${TOOLS_INSTALL_DIR}/fd"
        echo "✓ Created fd → fdfind symlink"
    fi

    # Verify installation
    if verify_binary "fd" "${MIN_FD_VERSION}" "fd --version"; then
        echo "✓ fd installed successfully"
        return 0
    else
        echo "✗ fd installation verification failed" >&2
        return 1
    fi
}

# Function: install_delta
# Purpose: Install delta (better git diff with syntax highlighting)
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Downloads and installs delta from GitHub releases
# Example: install_delta
install_delta() {
    # Check if already installed
    if command -v delta &> /dev/null; then
        if verify_binary "delta" "${MIN_DELTA_VERSION}" "delta --version"; then
            echo "✓ delta already installed and meets minimum version"
            return 0
        fi
    fi

    echo "→ Installing delta from GitHub releases..."

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

    # Get latest release download URL
    local asset_pattern="delta-.*-${arch}-unknown-linux-gnu\\.tar\\.gz"
    local download_url
    if ! download_url=$(_get_latest_github_release_url "$DELTA_RELEASE_URL" "$asset_pattern"); then
        echo "✗ Failed to get delta download URL" >&2
        return 1
    fi

    # Download and extract
    local temp_dir
    temp_dir="$(mktemp -d)"

    echo "→ Downloading delta..."
    if ! wget -q --show-progress -O "${temp_dir}/delta.tar.gz" "$download_url" 2>&1; then
        echo "✗ Failed to download delta" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Extract binary
    mkdir -p "$TOOLS_INSTALL_DIR"
    if ! tar -xzf "${temp_dir}/delta.tar.gz" -C "$temp_dir" 2>&1; then
        echo "✗ Failed to extract delta" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    # Find and copy delta binary
    local delta_bin
    delta_bin=$(find "$temp_dir" -name "delta" -type f | head -1)
    if [[ -z "$delta_bin" ]]; then
        echo "✗ delta binary not found in archive" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    cp "$delta_bin" "${TOOLS_INSTALL_DIR}/delta"
    chmod +x "${TOOLS_INSTALL_DIR}/delta"

    # Cleanup
    rm -rf "$temp_dir"

    # Configure git to use delta
    if command -v git &> /dev/null; then
        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate "true"
        git config --global delta.light "false"
        echo "✓ Git configured to use delta"
    fi

    # Verify installation
    if verify_binary "delta" "${MIN_DELTA_VERSION}" "delta --version"; then
        echo "✓ delta installed successfully"
        return 0
    else
        echo "✗ delta installation verification failed" >&2
        return 1
    fi
}

# Function: install_zoxide
# Purpose: Install zoxide (smarter cd with frecency algorithm)
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs zoxide via apt or cargo
# Example: install_zoxide
install_zoxide() {
    # Check if already installed
    if command -v zoxide &> /dev/null; then
        if verify_binary "zoxide" "${MIN_ZOXIDE_VERSION}" "zoxide --version"; then
            echo "✓ zoxide already installed and meets minimum version"
            return 0
        fi
    fi

    echo "→ Installing zoxide..."

    # Try apt first
    if sudo apt install -y zoxide 2>&1 | grep -E "^(Setting up|Processing)"; then
        echo "✓ zoxide installed via apt"
    else
        # Fallback to installation script
        echo "→ Installing zoxide via installation script..."
        if ! curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash; then
            echo "✗ Failed to install zoxide" >&2
            return 1
        fi
    fi

    # Verify installation
    if verify_binary "zoxide" "${MIN_ZOXIDE_VERSION}" "zoxide --version"; then
        echo "✓ zoxide installed successfully"
        return 0
    else
        echo "✗ zoxide installation verification failed" >&2
        return 1
    fi
}

# Function: install_fzf
# Purpose: Install fzf (fuzzy finder with shell integration)
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs fzf via apt
# Example: install_fzf
install_fzf() {
    # Check if already installed
    if command -v fzf &> /dev/null; then
        echo "✓ fzf already installed"
        return 0
    fi

    echo "→ Installing fzf..."

    # Install via apt
    if ! sudo apt install -y fzf 2>&1 | grep -E "^(Setting up|Processing)"; then
        echo "✗ Failed to install fzf" >&2
        return 1
    fi

    # Verify installation
    if verify_binary "fzf" "${MIN_FZF_VERSION}" "fzf --version"; then
        echo "✓ fzf installed successfully"
        return 0
    else
        echo "✗ fzf installation verification failed" >&2
        return 1
    fi
}

# Function: configure_shell_aliases
# Purpose: Add modern tool aliases to shell RC files
# Args: None
# Returns: 0 if configuration successful, 1 otherwise
# Side Effects: Modifies ~/.bashrc and ~/.zshrc
# Example: configure_shell_aliases
configure_shell_aliases() {
    local shell_rcs=("${HOME}/.bashrc" "${HOME}/.zshrc")

    for rc_file in "${shell_rcs[@]}"; do
        if [[ ! -f "$rc_file" ]]; then
            echo "ℹ Skipping $rc_file (file not found)"
            continue
        fi

        echo "→ Configuring modern tool aliases in ${rc_file}..."

        # Create backup
        cp "$rc_file" "${rc_file}.backup-$(date +%Y%m%d-%H%M%S)"

        # Add modern tools section marker
        local marker="# Modern Unix Tools aliases (added by install_modern_tools.sh)"
        if ! grep -q "$marker" "$rc_file"; then
            cat >> "$rc_file" << 'EOF'

# Modern Unix Tools aliases (added by install_modern_tools.sh)

# bat: Better cat with syntax highlighting
if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
    alias bathelp='bat --help'
fi

# eza: Better ls with colors and icons
if command -v eza &> /dev/null; then
    alias ls='eza --color=auto --icons'
    alias ll='eza -lah --color=auto --icons'
    alias la='eza -a --color=auto --icons'
    alias lt='eza --tree --level=2 --color=auto --icons'
fi

# ripgrep: Faster grep for code search
if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# fd: Faster find with better UX
if command -v fd &> /dev/null; then
    alias find='fd'
fi

# zoxide: Smarter cd with frecency
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init bash 2>/dev/null || zoxide init zsh 2>/dev/null || true)"
    alias cd='z'
fi

# fzf: Fuzzy finder with shell integration
if command -v fzf &> /dev/null; then
    # Key bindings for fzf
    # Ctrl+R: Command history search
    # Ctrl+T: File finder
    # Alt+C: Directory navigation

    # Source shell-specific key bindings if available
    if [[ -f /usr/share/doc/fzf/examples/key-bindings.bash ]] && [[ "${SHELL##*/}" == "bash" ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.bash
    fi

    if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && [[ "${SHELL##*/}" == "zsh" ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    fi

    # Default fzf options for better UI
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

    # Use fd for fzf file search if available
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
fi
EOF
            echo "✓ Aliases added to ${rc_file}"
        else
            echo "ℹ Aliases already present in ${rc_file}"
        fi
    done

    echo "✓ Shell configuration complete"
    return 0
}

# Function: verify_modern_tools_installation
# Purpose: Comprehensive modern tools installation verification
# Args: None
# Returns: 0 if all verifications pass, 1 otherwise
# Side Effects: Runs verification checks
# Example: verify_modern_tools_installation
verify_modern_tools_installation() {
    local all_checks_passed=0

    echo "=== Modern Unix Tools Installation Verification ==="
    echo

    # Define tools to verify
    local -A tools=(
        ["bat"]="${MIN_BAT_VERSION}"
        ["eza"]="${MIN_EZA_VERSION}"
        ["rg"]="${MIN_RIPGREP_VERSION}"
        ["fd"]="${MIN_FD_VERSION}"
        ["delta"]="${MIN_DELTA_VERSION}"
        ["zoxide"]="${MIN_ZOXIDE_VERSION}"
        ["fzf"]="${MIN_FZF_VERSION}"
    )

    # Verify each tool
    for tool in "${!tools[@]}"; do
        local min_version="${tools[$tool]}"
        echo "Check: $tool"

        if command -v "$tool" &> /dev/null; then
            if verify_binary "$tool" "$min_version" "$tool --version"; then
                # Test basic functionality
                case "$tool" in
                    bat)
                        if echo "test" | bat --paging=never &> /dev/null; then
                            echo "✓ $tool functional"
                        fi
                        ;;
                    eza)
                        if eza /tmp &> /dev/null; then
                            echo "✓ $tool functional"
                        fi
                        ;;
                    rg)
                        if echo "test" | rg "test" &> /dev/null; then
                            echo "✓ $tool functional"
                        fi
                        ;;
                    fd)
                        if fd . /tmp --max-depth 1 &> /dev/null; then
                            echo "✓ $tool functional"
                        fi
                        ;;
                    delta)
                        if delta --version &> /dev/null; then
                            echo "✓ $tool functional"
                        fi
                        ;;
                    zoxide)
                        if zoxide query --list &> /dev/null; then
                            echo "✓ $tool functional"
                        fi
                        ;;
                    fzf)
                        if echo "test" | fzf --filter "test" &> /dev/null; then
                            echo "✓ $tool functional"
                        fi
                        ;;
                esac
            else
                all_checks_passed=1
            fi
        else
            echo "✗ $tool not found in PATH" >&2
            all_checks_passed=1
        fi
        echo
    done

    # Check shell aliases
    echo "Check: Shell Aliases"
    local bashrc_has_aliases=0
    local zshrc_has_aliases=0

    if [[ -f "${HOME}/.bashrc" ]] && grep -q "Modern Unix Tools aliases" "${HOME}/.bashrc"; then
        bashrc_has_aliases=1
        echo "✓ ~/.bashrc has modern tool aliases"
    fi

    if [[ -f "${HOME}/.zshrc" ]] && grep -q "Modern Unix Tools aliases" "${HOME}/.zshrc"; then
        zshrc_has_aliases=1
        echo "✓ ~/.zshrc has modern tool aliases"
    fi

    if [[ $bashrc_has_aliases -eq 0 && $zshrc_has_aliases -eq 0 ]]; then
        echo "✗ No shell aliases configured" >&2
        all_checks_passed=1
    fi
    echo

    if [[ $all_checks_passed -eq 0 ]]; then
        echo "✅ All verification checks passed"
        return 0
    else
        echo "❌ Some verification checks failed" >&2
        return 1
    fi
}

# Function: install_modern_tools
# Purpose: Main entry point for modern tools installation
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs all modern Unix tools
# Example: install_modern_tools
install_modern_tools() {
    echo "=== Modern Unix Tools Installation ==="
    echo

    # Update package list
    echo "→ Updating package list..."
    if ! sudo apt update 2>&1 | grep -v "^Hit:"; then
        echo "⚠ apt update failed (non-critical)" >&2
    fi
    echo

    # Install each tool
    local tools=(
        "bat:install_bat"
        "eza:install_eza"
        "ripgrep:install_ripgrep"
        "fd:install_fd"
        "delta:install_delta"
        "zoxide:install_zoxide"
        "fzf:install_fzf"
    )

    for tool_entry in "${tools[@]}"; do
        local tool_name="${tool_entry%%:*}"
        local install_func="${tool_entry##*:}"

        echo "=== Installing $tool_name ==="
        if ! $install_func; then
            echo "✗ Failed to install $tool_name" >&2
            return 1
        fi
        echo
    done

    # Configure shell aliases
    if ! configure_shell_aliases; then
        echo "⚠ Shell alias configuration failed (non-critical)" >&2
    fi
    echo

    # Verify installation
    if ! verify_modern_tools_installation; then
        echo "✗ Modern tools installation verification failed" >&2
        return 1
    fi

    echo
    echo "✅ Modern Unix Tools installation complete!"
    echo
    echo "Next steps:"
    echo "  1. Restart shell: exec \$SHELL"
    echo "  2. Test tools:"
    echo "     - bat README.md"
    echo "     - eza -la"
    echo "     - rg 'pattern' ."
    echo "     - fd 'filename'"
    echo "     - git diff (uses delta)"
    echo "     - z /path/to/directory"
    echo "     - Ctrl+R (fzf history search)"
    echo "     - Ctrl+T (fzf file finder)"
    echo "     - Alt+C (fzf directory navigation)"
    echo

    return 0
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Run installation
    install_modern_tools
    exit $?
fi
