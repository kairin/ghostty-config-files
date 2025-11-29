#!/usr/bin/env bash
#
# lib/config/zsh/theme.sh - ZSH theme configuration (Powerlevel10k)
#
# Purpose: Install and configure Powerlevel10k theme
# Dependencies: git
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - install_powerlevel10k(): Install Powerlevel10k theme
#   - configure_powerlevel10k(): Configure theme in .zshrc
#   - setup_instant_prompt(): Enable <50ms perceived startup
#   - verify_theme_installed(): Verify theme installation
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_CONFIG_ZSH_THEME_SH:-}" ]] && return 0
readonly _LIB_CONFIG_ZSH_THEME_SH=1

# Module constants
readonly ZSH_CUSTOM="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
readonly P10K_DIR="${ZSH_CUSTOM}/themes/powerlevel10k"
readonly P10K_CONFIG="${HOME}/.p10k.zsh"
readonly P10K_REPO="https://github.com/romkatv/powerlevel10k.git"

# ============================================================================
# THEME INSTALLATION
# ============================================================================

# Function: install_powerlevel10k
# Purpose: Install Powerlevel10k theme
# Args: None
# Returns:
#   0 = success, 1 = failure
install_powerlevel10k() {
    # Check if already installed
    if [[ -d "$P10K_DIR" ]]; then
        echo "PASS: Powerlevel10k already installed"

        # Update to latest version
        echo "Updating Powerlevel10k to latest version..."
        if (cd "$P10K_DIR" && git pull origin master 2>&1 | grep -E "^(Already up to date|Updating|Fast-forward)"); then
            echo "PASS: Powerlevel10k updated"
        else
            echo "WARN: Powerlevel10k update may have failed"
        fi
        return 0
    fi

    echo "Installing Powerlevel10k theme..."

    # Create themes directory
    mkdir -p "${ZSH_CUSTOM}/themes"

    # Clone Powerlevel10k (shallow clone for speed)
    if git clone --depth=1 "$P10K_REPO" "$P10K_DIR" 2>&1 | grep -v "^Cloning"; then
        echo "PASS: Powerlevel10k installed"
        return 0
    else
        echo "FAIL: Failed to install Powerlevel10k" >&2
        return 1
    fi
}

# Function: create_default_p10k_config
# Purpose: Create default Powerlevel10k configuration
# Args: None
# Returns:
#   0 = success, 1 = failure
create_default_p10k_config() {
    # Check if config already exists
    if [[ -f "$P10K_CONFIG" ]]; then
        echo "INFO: Powerlevel10k configuration already exists"
        return 0
    fi

    # Copy lean config as default (fast, minimal)
    if [[ -f "${P10K_DIR}/config/p10k-lean.zsh" ]]; then
        cp "${P10K_DIR}/config/p10k-lean.zsh" "$P10K_CONFIG"
        echo "PASS: Created Powerlevel10k configuration (lean style)"
        return 0
    elif [[ -f "${P10K_DIR}/config/p10k-classic.zsh" ]]; then
        cp "${P10K_DIR}/config/p10k-classic.zsh" "$P10K_CONFIG"
        echo "PASS: Created Powerlevel10k configuration (classic style)"
        return 0
    else
        echo "WARN: No default p10k config found"
        return 0
    fi
}

# ============================================================================
# THEME CONFIGURATION
# ============================================================================

# Function: configure_powerlevel10k
# Purpose: Configure Powerlevel10k as ZSH theme in .zshrc
# Args:
#   $1 - Path to .zshrc (default: ~/.zshrc)
# Returns:
#   0 = success, 1 = failure
configure_powerlevel10k() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ ! -d "$P10K_DIR" ]]; then
        echo "FAIL: Powerlevel10k not installed" >&2
        return 1
    fi

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found: $zshrc" >&2
        return 1
    fi

    # Backup .zshrc
    cp "$zshrc" "${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"

    # Set Powerlevel10k as theme
    if grep -q "^ZSH_THEME=" "$zshrc"; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"
        echo "PASS: Updated ZSH theme to Powerlevel10k"
    else
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$zshrc"
        echo "PASS: Set ZSH theme to Powerlevel10k"
    fi

    # Add p10k config sourcing at the end
    if ! grep -q "source.*\.p10k\.zsh" "$zshrc"; then
        cat >> "$zshrc" <<'EOF'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
        echo "PASS: Added Powerlevel10k configuration sourcing"
    else
        echo "INFO: Powerlevel10k configuration sourcing already present"
    fi

    return 0
}

# ============================================================================
# INSTANT PROMPT (PERFORMANCE OPTIMIZATION)
# ============================================================================

# Function: setup_instant_prompt
# Purpose: Enable Powerlevel10k instant prompt for <50ms perceived startup
# Args:
#   $1 - Path to .zshrc (default: ~/.zshrc)
# Returns:
#   0 = success, 1 = failure
# Note: This is a constitutional requirement (FR-051, FR-054)
setup_instant_prompt() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found" >&2
        return 1
    fi

    # Check if instant prompt already configured
    if grep -q "p10k-instant-prompt" "$zshrc"; then
        echo "INFO: Instant prompt already configured"
        return 0
    fi

    # Backup .zshrc
    cp "$zshrc" "${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"

    # Find line to insert after (should be near top, after ZSH export)
    local insert_line
    insert_line=$(grep -n "^export ZSH=" "$zshrc" | head -1 | cut -d: -f1)

    if [[ -n "$insert_line" ]]; then
        # Insert instant prompt configuration after ZSH path export
        sed -i "${insert_line}a\\
\\
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.\\
# Initialization code that may require console input (password prompts, [y/n]\\
# confirmations, etc.) must go above this block; everything else may go below.\\
if [[ -r \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\" ]]; then\\
  source \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\"\\
fi" "$zshrc"

        echo "PASS: Enabled Powerlevel10k instant prompt (<50ms perceived startup)"
        return 0
    else
        echo "WARN: Could not find ZSH export line, adding instant prompt at top"

        # Create temp file with instant prompt at top
        local temp_file
        temp_file=$(mktemp)

        cat > "$temp_file" <<'EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

EOF
        cat "$zshrc" >> "$temp_file"
        mv "$temp_file" "$zshrc"

        echo "PASS: Added instant prompt at top of .zshrc"
        return 0
    fi
}

# ============================================================================
# THEME VERIFICATION
# ============================================================================

# Function: verify_theme_installed
# Purpose: Verify Powerlevel10k theme is properly installed
# Args: None
# Returns:
#   0 = installed, 1 = not installed
verify_theme_installed() {
    local issues=0

    echo "Verifying Powerlevel10k installation..."

    # Check theme directory
    if [[ -d "$P10K_DIR" ]]; then
        echo "  PASS: Theme directory exists"
    else
        echo "  FAIL: Theme directory not found" >&2
        ((issues++))
    fi

    # Check git repo
    if [[ -d "${P10K_DIR}/.git" ]]; then
        echo "  PASS: Theme is a Git repository"
    else
        echo "  WARN: Theme is not a Git repository (updates may fail)"
    fi

    # Check p10k.zsh
    if [[ -f "$P10K_CONFIG" ]]; then
        echo "  PASS: Configuration file exists"
    else
        echo "  WARN: Configuration file not found (run 'p10k configure')"
    fi

    if [[ $issues -eq 0 ]]; then
        echo "PASS: Powerlevel10k properly installed"
        return 0
    else
        echo "FAIL: Powerlevel10k has issues" >&2
        return 1
    fi
}

# Function: get_theme_status
# Purpose: Get detailed theme status
# Args: None
# Returns:
#   JSON-formatted status (stdout)
get_theme_status() {
    local installed="false"
    local configured="false"
    local instant_prompt="false"

    [[ -d "$P10K_DIR" ]] && installed="true"
    [[ -f "$P10K_CONFIG" ]] && configured="true"

    if [[ -f "${HOME}/.zshrc" ]] && grep -q "p10k-instant-prompt" "${HOME}/.zshrc"; then
        instant_prompt="true"
    fi

    cat <<EOF
{
  "installed": $installed,
  "configured": $configured,
  "instant_prompt_enabled": $instant_prompt,
  "theme_path": "$P10K_DIR",
  "config_path": "$P10K_CONFIG"
}
EOF
}
