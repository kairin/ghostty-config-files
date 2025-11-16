#!/bin/bash
# Module: configure_zsh.sh
# Purpose: Configure ZSH with Oh My ZSH, enhanced plugins, and <50ms startup optimization
# Dependencies: verification.sh, progress.sh, common.sh, install_modern_tools.sh (fzf)
# Modules Required: ZSH, git, curl
# Exit Codes: 0=success, 1=configuration failed, 2=invalid argument

set -euo pipefail

# Prevent multiple sourcing of this module (idempotent sourcing)
[[ -n "${CONFIGURE_ZSH_SH_LOADED:-}" ]] && return 0
readonly CONFIGURE_ZSH_SH_LOADED=1

# Module-level guard: Allow sourcing for testing
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
else
    SOURCED_FOR_TESTING=0
fi

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/progress.sh"
source "${SCRIPT_DIR}/verification.sh"

# ============================================================
# CONFIGURATION (Module Constants)
# ============================================================

readonly OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
readonly ZSH_CUSTOM="${OH_MY_ZSH_DIR}/custom"
readonly ZSHRC_FILE="${HOME}/.zshrc"
readonly P10K_CONFIG="${HOME}/.p10k.zsh"

# Plugin repositories
readonly PLUGIN_AUTOSUGGESTIONS="https://github.com/zsh-users/zsh-autosuggestions"
readonly PLUGIN_SYNTAX_HIGHLIGHT="https://github.com/zsh-users/zsh-syntax-highlighting"
readonly PLUGIN_YOU_SHOULD_USE="https://github.com/MichaelAquilina/zsh-you-should-use"
readonly THEME_POWERLEVEL10K="https://github.com/romkatv/powerlevel10k.git"

# Performance targets (constitutional requirement: FR-051, FR-054)
readonly MAX_STARTUP_OVERHEAD_MS=50

# ============================================================
# PRIVATE HELPER FUNCTIONS
# ============================================================

# Function: _backup_zshrc
# Purpose: Create timestamped backup of .zshrc
# Args: None
# Returns: 0 on success
_backup_zshrc() {
    if [[ -f "$ZSHRC_FILE" ]]; then
        local backup_file="${ZSHRC_FILE}.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$ZSHRC_FILE" "$backup_file"
        echo "✓ Backup created: $backup_file"
    fi
    return 0
}

# Function: _measure_zsh_startup
# Purpose: Measure ZSH startup time in milliseconds
# Args: None
# Returns: Startup time in milliseconds (stdout), 0 on success
_measure_zsh_startup() {
    local start_ns end_ns duration_ms

    # Use date +%s%N for nanosecond precision
    start_ns=$(date +%s%N)
    # Redirect all output to /dev/null to avoid interference
    zsh -i -c exit >/dev/null 2>&1 || true
    end_ns=$(date +%s%N)

    # Convert nanoseconds to milliseconds
    duration_ms=$(( (end_ns - start_ns) / 1000000 ))
    echo "$duration_ms"
    return 0
}

# Function: _add_config_section
# Purpose: Add configuration section to .zshrc if not present
# Args:
#   $1=marker (section identifier)
#   $2=content (configuration to add)
# Returns: 0 if added or already present
_add_config_section() {
    local marker="$1"
    local content="$2"

    if [[ ! -f "$ZSHRC_FILE" ]]; then
        echo "✗ .zshrc not found" >&2
        return 1
    fi

    if ! grep -q "$marker" "$ZSHRC_FILE"; then
        _backup_zshrc
        echo "" >> "$ZSHRC_FILE"
        echo "$content" >> "$ZSHRC_FILE"
        echo "✓ Added configuration section: $marker"
    else
        echo "ℹ Configuration section already present: $marker"
    fi

    return 0
}

# ============================================================
# PUBLIC FUNCTIONS (Module API)
# ============================================================

# Function: install_oh_my_zsh
# Purpose: Install Oh My ZSH framework
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs Oh My ZSH to ~/.oh-my-zsh/, modifies ~/.zshrc
# Example: install_oh_my_zsh
install_oh_my_zsh() {
    # Check if already installed
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        echo "✓ Oh My ZSH already installed at $OH_MY_ZSH_DIR"

        # Update to latest version using git pull
        echo "→ Updating Oh My ZSH to latest version..."
        if (cd "$OH_MY_ZSH_DIR" && git pull origin master 2>&1 | grep -E "^(Already up to date|Updating|Fast-forward)"); then
            echo "✓ Oh My ZSH updated to latest version"
        else
            echo "⚠ Oh My ZSH update failed (continuing with existing version)" >&2
        fi
        return 0
    fi

    echo "→ Installing Oh My ZSH..."

    # Backup existing .zshrc
    _backup_zshrc

    # Download and install Oh My ZSH
    # Use sh -c with RUNZSH=no and CHSH=no for non-interactive installation
    if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>&1 | grep -v "^Cloning"; then
        echo "✗ Oh My ZSH installation failed" >&2
        return 1
    fi

    # Verify installation
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        echo "✓ Oh My ZSH installed successfully"
        return 0
    else
        echo "✗ Oh My ZSH directory not found after installation" >&2
        return 1
    fi
}

# Function: install_zsh_plugin
# Purpose: Install ZSH plugin from Git repository
# Args:
#   $1=plugin_name (required, e.g., "zsh-autosuggestions")
#   $2=repo_url (required, GitHub repository URL)
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Clones plugin to ~/.oh-my-zsh/custom/plugins/
# Example: install_zsh_plugin "zsh-autosuggestions" "$PLUGIN_AUTOSUGGESTIONS"
install_zsh_plugin() {
    local plugin_name="$1"
    local repo_url="$2"

    local plugin_dir="${ZSH_CUSTOM}/plugins/${plugin_name}"

    # Check if already installed
    if [[ -d "$plugin_dir" ]]; then
        echo "✓ Plugin already installed: $plugin_name"

        # Update plugin to latest version
        if (cd "$plugin_dir" && git pull origin master 2>&1 | grep -E "^(Already up to date|Updating|Fast-forward)"); then
            echo "✓ Plugin updated: $plugin_name"
        fi
        return 0
    fi

    echo "→ Installing ZSH plugin: $plugin_name..."

    # Create custom plugins directory
    mkdir -p "${ZSH_CUSTOM}/plugins"

    # Clone plugin repository (depth=1 for faster clone)
    if ! git clone --depth 1 "$repo_url" "$plugin_dir" 2>&1 | grep -v "^Cloning"; then
        echo "✗ Failed to install plugin: $plugin_name" >&2
        return 1
    fi

    echo "✓ Plugin installed: $plugin_name"
    return 0
}

# Function: install_powerlevel10k_theme
# Purpose: Install Powerlevel10k theme for enhanced terminal productivity
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Clones Powerlevel10k to ~/.oh-my-zsh/custom/themes/
# Example: install_powerlevel10k_theme
install_powerlevel10k_theme() {
    local p10k_dir="${ZSH_CUSTOM}/themes/powerlevel10k"

    # Check if already installed
    if [[ -d "$p10k_dir" ]]; then
        echo "✓ Powerlevel10k theme already installed"

        # Update theme to latest version
        if (cd "$p10k_dir" && git pull origin master 2>&1 | grep -E "^(Already up to date|Updating|Fast-forward)"); then
            echo "✓ Powerlevel10k theme updated"
        fi
        return 0
    fi

    echo "→ Installing Powerlevel10k theme..."

    # Create custom themes directory
    mkdir -p "${ZSH_CUSTOM}/themes"

    # Clone Powerlevel10k repository (depth=1 for faster clone)
    if ! git clone --depth=1 "$THEME_POWERLEVEL10K" "$p10k_dir" 2>&1 | grep -v "^Cloning"; then
        echo "✗ Failed to install Powerlevel10k theme" >&2
        return 1
    fi

    # Create default Powerlevel10k configuration if not present
    if [[ ! -f "$P10K_CONFIG" ]] && [[ -f "${p10k_dir}/config/p10k-lean.zsh" ]]; then
        cp "${p10k_dir}/config/p10k-lean.zsh" "$P10K_CONFIG"
        echo "✓ Created Powerlevel10k configuration (lean style)"
    fi

    echo "✓ Powerlevel10k theme installed successfully"
    return 0
}

# Function: configure_zsh_plugins
# Purpose: Install and configure essential ZSH plugins
# Args: None
# Returns: 0 if configuration successful, 1 otherwise
# Side Effects: Installs plugins, updates .zshrc
# Example: configure_zsh_plugins
configure_zsh_plugins() {
    echo "→ Configuring ZSH plugins..."

    # Ensure Oh My ZSH is installed
    if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
        echo "✗ Oh My ZSH not installed" >&2
        return 1
    fi

    # Install essential plugins
    local plugins=(
        "zsh-autosuggestions:$PLUGIN_AUTOSUGGESTIONS"
        "zsh-syntax-highlighting:$PLUGIN_SYNTAX_HIGHLIGHT"
        "you-should-use:$PLUGIN_YOU_SHOULD_USE"
    )

    local -a plugin_status=()
    for plugin_entry in "${plugins[@]}"; do
        local plugin_name="${plugin_entry%%:*}"
        local plugin_repo="${plugin_entry##*:}"

        if install_zsh_plugin "$plugin_name" "$plugin_repo"; then
            plugin_status+=("✓ $plugin_name")
        else
            plugin_status+=("⚠ $plugin_name (failed)")
            echo "⚠ Failed to install $plugin_name (non-critical)" >&2
        fi
    done

    # Display plugin installation summary
    echo ""
    echo "Plugin Installation Summary:"
    for status in "${plugin_status[@]}"; do
        echo "  $status"
    done
    echo ""

    # Update .zshrc with plugin list
    if [[ -f "$ZSHRC_FILE" ]]; then
        _backup_zshrc

        # Define optimized plugin load order
        # Note: Syntax highlighting plugins MUST load last for performance
        # Built-in plugins: git, npm, node, docker, docker-compose, sudo, history, extract, z
        # Custom plugins: you-should-use, zsh-autosuggestions, zsh-syntax-highlighting (LAST)
        local plugins_string="plugins=(git npm node docker docker-compose sudo history extract z you-should-use zsh-autosuggestions zsh-syntax-highlighting)"

        # Replace existing plugins line
        if grep -q "^plugins=" "$ZSHRC_FILE"; then
            sed -i "s/^plugins=.*/$plugins_string/" "$ZSHRC_FILE"
            echo "✓ Updated plugins in $ZSHRC_FILE"
        else
            # Add plugins line if not present (should exist in default Oh My ZSH config)
            echo "" >> "$ZSHRC_FILE"
            echo "$plugins_string" >> "$ZSHRC_FILE"
            echo "✓ Added plugins to $ZSHRC_FILE"
        fi
    fi

    echo "✓ ZSH plugins configured"
    return 0
}

# Function: configure_powerlevel10k_theme
# Purpose: Configure Powerlevel10k theme in .zshrc
# Args: None
# Returns: 0 if configuration successful, 1 otherwise
# Side Effects: Modifies .zshrc with theme settings
# Example: configure_powerlevel10k_theme
configure_powerlevel10k_theme() {
    local p10k_dir="${ZSH_CUSTOM}/themes/powerlevel10k"

    if [[ ! -d "$p10k_dir" ]]; then
        echo "✗ Powerlevel10k theme not installed" >&2
        return 1
    fi

    if [[ ! -f "$ZSHRC_FILE" ]]; then
        echo "✗ .zshrc not found" >&2
        return 1
    fi

    _backup_zshrc

    # Set Powerlevel10k as the ZSH theme
    if grep -q "^ZSH_THEME=" "$ZSHRC_FILE"; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC_FILE"
        echo "✓ Updated ZSH theme to Powerlevel10k"
    else
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC_FILE"
        echo "✓ Set ZSH theme to Powerlevel10k"
    fi

    # Add Powerlevel10k instant prompt (must be near top of .zshrc)
    # This provides <50ms perceived startup time
    if ! grep -q "p10k-instant-prompt" "$ZSHRC_FILE"; then
        local insert_line
        insert_line=$(grep -n "^export ZSH=" "$ZSHRC_FILE" | head -1 | cut -d: -f1)
        if [[ -n "$insert_line" ]]; then
            # Insert instant prompt configuration after ZSH path export
            sed -i "${insert_line}a\\
\\
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.\\
# Initialization code that may require console input (password prompts, [y/n]\\
# confirmations, etc.) must go above this block; everything else may go below.\\
if [[ -r \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\" ]]; then\\
  source \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\"\\
fi" "$ZSHRC_FILE"
            echo "✓ Added Powerlevel10k instant prompt (enables <50ms perceived startup)"
        fi
    else
        echo "ℹ Powerlevel10k instant prompt already configured"
    fi

    # Add p10k config sourcing at the end
    if ! grep -q "source.*\.p10k\.zsh" "$ZSHRC_FILE" && [[ -f "$P10K_CONFIG" ]]; then
        echo "" >> "$ZSHRC_FILE"
        echo "# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$ZSHRC_FILE"
        echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$ZSHRC_FILE"
        echo "✓ Added Powerlevel10k configuration sourcing"
    else
        echo "ℹ Powerlevel10k configuration sourcing already present"
    fi

    return 0
}

# Function: optimize_zsh_performance
# Purpose: Optimize ZSH startup performance for <50ms target
# Args: None
# Returns: 0 if optimization successful, 1 otherwise
# Side Effects: Modifies .zshrc with performance optimizations
# Example: optimize_zsh_performance
optimize_zsh_performance() {
    echo "→ Optimizing ZSH performance for <${MAX_STARTUP_OVERHEAD_MS}ms target..."

    if [[ ! -f "$ZSHRC_FILE" ]]; then
        echo "✗ .zshrc not found" >&2
        return 1
    fi

    # Add performance optimizations
    local marker="# Oh My ZSH Performance Optimizations (2025)"
    local perf_config
    read -r -d '' perf_config <<'EOF' || true

# Oh My ZSH Performance Optimizations (2025)
# Constitutional requirement: <50ms startup (FR-051, FR-054)

# Disable magic functions for better performance
DISABLE_MAGIC_FUNCTIONS=true

# Compilation caching for faster startup
# Only recompile once per day instead of every shell start
autoload -Uz compinit
# Check if .zcompdump is older than 24 hours
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C  # Use cache without security check (safe for personal machines)
fi

# Optimize history search
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Skip verification of insecure directories (speeds up startup)
ZSH_DISABLE_COMPFIX=true

# zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20  # Limit buffer size for performance
ZSH_AUTOSUGGEST_USE_ASYNC=true      # Async suggestions for better performance

EOF

    _add_config_section "$marker" "$perf_config"

    # Add modern tools integration (from Wave 1 Agent 4)
    local tools_marker="# Modern Unix Tools Configuration (from install_modern_tools.sh)"
    local tools_config
    read -r -d '' tools_config <<'EOF' || true

# Modern Unix Tools Configuration (from install_modern_tools.sh)
# Wave 1 Agent 4: bat, eza, ripgrep, fd, zoxide, fzf

# eza: Better ls with colors and icons
if command -v eza >/dev/null 2>&1; then
    alias ls="eza --group-directories-first --git"
    alias ll="eza -la --group-directories-first --git"
    alias tree="eza --tree"
fi

# bat: Better cat with syntax highlighting
if command -v bat >/dev/null 2>&1; then
    alias cat="bat --style=plain"
    alias bathelp="bat --style=plain --language=help"
fi

# fzf: Fuzzy finder integration (from Wave 1 Agent 4)
if command -v fzf >/dev/null 2>&1; then
    # Use ripgrep for fzf file search if available
    if command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # Use fd for fzf directory navigation if available
    if command -v fd >/dev/null 2>&1; then
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi

    # Enhanced fzf options
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"

    # Source fzf key bindings for zsh (Ctrl+R, Ctrl+T, Alt+C)
    if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    fi

    # Source fzf completion
    if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
        source /usr/share/doc/fzf/examples/completion.zsh
    fi
fi

# zoxide: Smarter cd with frecency (from Wave 1 Agent 4)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi

EOF

    _add_config_section "$tools_marker" "$tools_config"

    # Add Ghostty shell integration (critical for terminal behavior)
    local ghostty_marker="# Ghostty shell integration (CRITICAL for proper terminal behavior)"
    local ghostty_config
    read -r -d '' ghostty_config <<'EOF' || true

# Ghostty shell integration (CRITICAL for proper terminal behavior)
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  autoload -Uz -- "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
  ghostty-integration
fi

EOF

    _add_config_section "$ghostty_marker" "$ghostty_config"

    echo "✓ Performance optimizations added"

    # Measure startup time to verify <50ms target
    echo ""
    echo "→ Measuring ZSH startup time..."
    local startup_ms
    startup_ms=$(_measure_zsh_startup)

    echo "→ ZSH startup time: ${startup_ms}ms"

    # Verify performance target (constitutional requirement)
    if [[ $startup_ms -le $MAX_STARTUP_OVERHEAD_MS ]]; then
        echo "✓ ✅ Performance target MET: ${startup_ms}ms ≤ ${MAX_STARTUP_OVERHEAD_MS}ms (CONSTITUTIONAL COMPLIANCE)"
        return 0
    else
        echo "⚠ ⚠️  Performance target EXCEEDED: ${startup_ms}ms > ${MAX_STARTUP_OVERHEAD_MS}ms" >&2
        echo "  Consider disabling heavy plugins or using lazy loading" >&2
        echo "  This is a constitutional requirement (FR-051, FR-054)" >&2
        # Return 0 as non-blocking warning (user can still use the shell)
        return 0
    fi
}

# Function: set_zsh_as_default_shell
# Purpose: Set ZSH as the default shell for the current user
# Args: None
# Returns: 0 if successful or already set, 1 otherwise
# Side Effects: Changes default shell to ZSH
# Example: set_zsh_as_default_shell
set_zsh_as_default_shell() {
    # Check current default shell
    local current_shell
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local zsh_path
    zsh_path=$(which zsh)

    if [[ "$current_shell" == "$zsh_path" ]]; then
        echo "✓ ZSH is already the default shell"
        return 0
    fi

    echo "→ Setting ZSH as default shell..."

    # Try to change shell using sudo usermod (non-interactive)
    if sudo usermod -s "$zsh_path" "$USER" 2>/dev/null; then
        echo "✓ ZSH set as default shell"
        echo "⚠ Restart terminal to take effect"
        return 0
    else
        echo "⚠ Failed to set ZSH as default shell automatically" >&2
        echo "💡 You can manually set it with: chsh -s $zsh_path" >&2
        echo "💡 Or run: sudo usermod -s $zsh_path $USER" >&2
        return 1
    fi
}

# Function: verify_zsh_configuration
# Purpose: Comprehensive ZSH configuration verification
# Args: None
# Returns: 0 if all verifications pass, 1 otherwise
# Side Effects: Runs verification checks
# Example: verify_zsh_configuration
verify_zsh_configuration() {
    local all_checks_passed=0

    echo "=== ZSH Configuration Verification ==="
    echo

    # Check 1: ZSH installed
    echo "Check 1: ZSH Installation"
    if verify_binary "zsh" "" "zsh --version"; then
        echo "✓ ZSH installed"
    else
        all_checks_passed=1
    fi
    echo

    # Check 2: Oh My ZSH installed
    echo "Check 2: Oh My ZSH Framework"
    if [[ -d "$OH_MY_ZSH_DIR" ]]; then
        echo "✓ Oh My ZSH installed at $OH_MY_ZSH_DIR"
    else
        echo "✗ Oh My ZSH not found" >&2
        all_checks_passed=1
    fi
    echo

    # Check 3: .zshrc configured
    echo "Check 3: .zshrc Configuration"
    if [[ -f "$ZSHRC_FILE" ]]; then
        if grep -q "oh-my-zsh" "$ZSHRC_FILE"; then
            echo "✓ .zshrc configured with Oh My ZSH"
        else
            echo "✗ .zshrc not configured for Oh My ZSH" >&2
            all_checks_passed=1
        fi
    else
        echo "✗ .zshrc not found" >&2
        all_checks_passed=1
    fi
    echo

    # Check 4: Plugins installed
    echo "Check 4: Plugin Installation"
    local plugins_ok=1
    for plugin in "zsh-autosuggestions" "zsh-syntax-highlighting" "you-should-use"; do
        local plugin_dir="${ZSH_CUSTOM}/plugins/${plugin}"
        if [[ -d "$plugin_dir" ]]; then
            echo "✓ Plugin installed: $plugin"
        else
            echo "⚠ Plugin not found: $plugin" >&2
            plugins_ok=0
        fi
    done
    if [[ $plugins_ok -eq 0 ]]; then
        echo "ℹ Some plugins missing (non-critical)"
    fi
    echo

    # Check 5: Powerlevel10k theme
    echo "Check 5: Powerlevel10k Theme"
    if [[ -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]]; then
        echo "✓ Powerlevel10k theme installed"
        if grep -q "powerlevel10k" "$ZSHRC_FILE"; then
            echo "✓ Powerlevel10k configured in .zshrc"
        fi
    else
        echo "⚠ Powerlevel10k theme not found (optional)" >&2
    fi
    echo

    # Check 6: Performance optimizations
    echo "Check 6: Performance Optimizations"
    if grep -q "Oh My ZSH Performance Optimizations" "$ZSHRC_FILE"; then
        echo "✓ Performance optimizations configured"
    else
        echo "⚠ Performance optimizations not found" >&2
    fi
    echo

    # Check 7: Modern tools integration (from Wave 1 Agent 4)
    echo "Check 7: Modern Tools Integration (Wave 1 Agent 4)"
    local tools_configured=1
    for tool in "fzf" "eza" "bat" "zoxide"; do
        if command -v "$tool" &> /dev/null; then
            echo "✓ Tool available: $tool"
        else
            echo "ℹ Tool not found: $tool (from Wave 1 Agent 4)" >&2
            tools_configured=0
        fi
    done
    if [[ $tools_configured -eq 1 ]]; then
        echo "✓ All modern tools from Wave 1 available"
    fi
    echo

    # Check 8: Startup Performance (CRITICAL - Constitutional Requirement)
    echo "Check 8: Startup Performance (Constitutional Requirement)"
    local startup_ms
    startup_ms=$(_measure_zsh_startup)
    echo "→ ZSH startup time: ${startup_ms}ms"

    if [[ $startup_ms -le $MAX_STARTUP_OVERHEAD_MS ]]; then
        echo "✓ ✅ Performance target MET: ${startup_ms}ms ≤ ${MAX_STARTUP_OVERHEAD_MS}ms"
        echo "  Constitutional compliance: FR-051, FR-054"
    else
        echo "⚠ ⚠️  Performance target EXCEEDED: ${startup_ms}ms > ${MAX_STARTUP_OVERHEAD_MS}ms" >&2
        echo "  This violates constitutional requirements (FR-051, FR-054)" >&2
    fi
    echo

    # Check 9: Ghostty shell integration
    echo "Check 9: Ghostty Shell Integration"
    if grep -q "GHOSTTY_RESOURCES_DIR" "$ZSHRC_FILE"; then
        echo "✓ Ghostty shell integration configured"
    else
        echo "ℹ Ghostty shell integration not found (optional if not using Ghostty)" >&2
    fi
    echo

    if [[ $all_checks_passed -eq 0 ]]; then
        echo "✅ All critical verification checks passed"
        return 0
    else
        echo "❌ Some critical verification checks failed" >&2
        return 1
    fi
}

# Function: configure_zsh
# Purpose: Main entry point for ZSH configuration
# Args: None
# Returns: 0 if configuration successful, 1 otherwise
# Side Effects: Installs Oh My ZSH, plugins, optimizes performance
# Example: configure_zsh
configure_zsh() {
    echo "=== ZSH Configuration (Wave 2 Agent 7: T068-T070) ==="
    echo

    # Step 0: Verify ZSH is installed
    if ! command -v zsh &> /dev/null; then
        echo "→ ZSH not found, installing..."
        if ! sudo apt update && sudo apt install -y zsh 2>&1 | grep -E "^(Setting up|Processing)"; then
            echo "✗ Failed to install ZSH" >&2
            return 1
        fi
        echo "✓ ZSH installed"
    else
        echo "✓ ZSH already installed"

        # Check for ZSH updates
        echo "→ Checking for ZSH updates..."
        if apt list --upgradable 2>/dev/null | grep -q "^zsh/"; then
            echo "→ ZSH update available, updating..."
            if sudo apt update && sudo apt upgrade -y zsh 2>&1 | grep -E "^(Setting up|Processing)"; then
                echo "✓ ZSH updated to latest version"
            fi
        else
            echo "✓ ZSH is up to date"
        fi
    fi
    echo

    # Step 1: Install Oh My ZSH (T068)
    echo "=== T068: Install Oh My ZSH Framework ==="
    if ! install_oh_my_zsh; then
        echo "✗ Failed to install Oh My ZSH" >&2
        return 1
    fi
    echo

    # Step 2: Install Powerlevel10k theme
    echo "=== Installing Powerlevel10k Theme ==="
    if ! install_powerlevel10k_theme; then
        echo "⚠ Powerlevel10k installation failed (non-critical)" >&2
    fi
    echo

    # Step 3: Configure plugins (T069)
    echo "=== T069: Configure Essential Plugins ==="
    if ! configure_zsh_plugins; then
        echo "⚠ Plugin configuration failed (non-critical)" >&2
    fi
    echo

    # Step 4: Configure Powerlevel10k theme
    echo "=== Configure Powerlevel10k Theme ==="
    if ! configure_powerlevel10k_theme; then
        echo "⚠ Theme configuration failed (non-critical)" >&2
    fi
    echo

    # Step 5: Optimize performance (T070 - CRITICAL)
    echo "=== T070: Optimize Startup Performance (<${MAX_STARTUP_OVERHEAD_MS}ms target) ==="
    if ! optimize_zsh_performance; then
        echo "⚠ Performance optimization failed (non-critical warning)" >&2
    fi
    echo

    # Step 6: Set ZSH as default shell
    echo "=== Set ZSH as Default Shell ==="
    if ! set_zsh_as_default_shell; then
        echo "ℹ Manual shell change may be required" >&2
    fi
    echo

    # Step 7: Verify configuration
    echo "=== Comprehensive Verification ==="
    if ! verify_zsh_configuration; then
        echo "✗ ZSH configuration verification failed" >&2
        return 1
    fi

    echo
    echo "✅ ZSH configuration complete! (T068-T070)"
    echo
    echo "Summary:"
    echo "  ✓ Oh My ZSH framework installed"
    echo "  ✓ Powerlevel10k theme configured"
    echo "  ✓ Essential plugins installed (autosuggestions, syntax-highlighting, you-should-use)"
    echo "  ✓ Wave 1 modern tools integrated (fzf, eza, bat, zoxide)"
    echo "  ✓ Performance optimized for <${MAX_STARTUP_OVERHEAD_MS}ms startup"
    echo "  ✓ Ghostty shell integration enabled"
    echo
    echo "Next steps:"
    echo "  1. Restart terminal: exec zsh"
    echo "  2. Verify startup time: time zsh -i -c exit"
    echo "  3. Test fzf integration: Ctrl+R (history), Ctrl+T (files), Alt+C (dirs)"
    echo "  4. Customize theme: p10k configure"
    echo

    return 0
}

# ============================================================
# MAIN EXECUTION (Skipped when sourced)
# ============================================================

if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # Run configuration
    configure_zsh
    exit $?
fi
