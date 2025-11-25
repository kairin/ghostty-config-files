#!/usr/bin/env bash
#
# lib/config/zsh/functions.sh - ZSH custom functions and shell integration
#
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - configure_ghostty_integration(): Set up Ghostty shell integration
#   - configure_performance_optimizations(): Add startup optimizations
#   - configure_history_settings(): Set up history configuration
#   - measure_zsh_startup(): Measure shell startup time
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_CONFIG_ZSH_FUNCTIONS_SH:-}" ]] && return 0
readonly _LIB_CONFIG_ZSH_FUNCTIONS_SH=1

# Module constants
readonly MAX_STARTUP_OVERHEAD_MS=50

# ============================================================================
# GHOSTTY INTEGRATION
# ============================================================================

# Function: configure_ghostty_integration
configure_ghostty_integration() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found" >&2
        return 1
    fi

    # Check if Ghostty integration already configured
    if grep -q "GHOSTTY_RESOURCES_DIR" "$zshrc"; then
        echo "INFO: Ghostty shell integration already configured"
        return 0
    fi

    # Backup .zshrc
    cp "$zshrc" "${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"

    # Add Ghostty shell integration
    cat >> "$zshrc" <<'EOF'

# Ghostty shell integration (CRITICAL for proper terminal behavior)
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  autoload -Uz -- "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
  ghostty-integration
fi
EOF

    echo "PASS: Configured Ghostty shell integration"
    return 0
}

# ============================================================================
# PERFORMANCE OPTIMIZATIONS
# ============================================================================

# Function: configure_performance_optimizations
configure_performance_optimizations() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found" >&2
        return 1
    fi

    # Check if performance config already present
    if grep -q "Oh My ZSH Performance Optimizations" "$zshrc"; then
        echo "INFO: Performance optimizations already configured"
        return 0
    fi

    # Backup .zshrc
    cp "$zshrc" "${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"

    # Add performance optimizations
    cat >> "$zshrc" <<'EOF'

# Oh My ZSH Performance Optimizations (2025)
# Constitutional requirement: <50ms startup (FR-051, FR-054)

# Disable magic functions for better performance
DISABLE_MAGIC_FUNCTIONS=true

# Compilation caching for faster startup
autoload -Uz compinit
# Check if .zcompdump is older than 24 hours
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C  # Use cache without security check (safe for personal machines)
fi

# Skip verification of insecure directories (speeds up startup)
ZSH_DISABLE_COMPFIX=true

# zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20  # Limit buffer size for performance
ZSH_AUTOSUGGEST_USE_ASYNC=true      # Async suggestions for better performance
EOF

    echo "PASS: Configured performance optimizations"
    return 0
}

# Function: configure_history_settings
configure_history_settings() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found" >&2
        return 1
    fi

    # Check if history config already present
    if grep -q "HIST_IGNORE_ALL_DUPS" "$zshrc"; then
        echo "INFO: History settings already configured"
        return 0
    fi

    # Add history settings
    cat >> "$zshrc" <<'EOF'

# Optimized history settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS

# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
EOF

    echo "PASS: Configured history settings"
    return 0
}

# ============================================================================
# STARTUP MEASUREMENT
# ============================================================================

# Function: measure_zsh_startup
#   Startup time in milliseconds (stdout)
measure_zsh_startup() {
    local start_ns end_ns duration_ms

    # Use date +%s%N for nanosecond precision
    start_ns=$(date +%s%N)
    # Redirect all output to /dev/null to avoid interference
    zsh -i -c exit >/dev/null 2>&1 || true
    end_ns=$(date +%s%N)

    # Convert nanoseconds to milliseconds
    duration_ms=$(( (end_ns - start_ns) / 1000000 ))
    echo "$duration_ms"
}

# Function: verify_startup_performance
verify_startup_performance() {
    local startup_ms

    echo "Measuring ZSH startup time..."
    startup_ms=$(measure_zsh_startup)

    echo "ZSH startup time: ${startup_ms}ms"

    if [[ $startup_ms -le $MAX_STARTUP_OVERHEAD_MS ]]; then
        echo "PASS: Performance target MET: ${startup_ms}ms <= ${MAX_STARTUP_OVERHEAD_MS}ms"
        echo "Constitutional compliance: FR-051, FR-054"
        return 0
    else
        echo "WARN: Performance target EXCEEDED: ${startup_ms}ms > ${MAX_STARTUP_OVERHEAD_MS}ms"
        echo "Consider disabling heavy plugins or using lazy loading"
        return 1
    fi
}

# ============================================================================
# ZSH DEFAULT SHELL
# ============================================================================

# Function: set_zsh_as_default
set_zsh_as_default() {
    local current_shell zsh_path

    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    zsh_path=$(which zsh)

    if [[ "$current_shell" == "$zsh_path" ]]; then
        echo "PASS: ZSH is already the default shell"
        return 0
    fi

    echo "Setting ZSH as default shell..."

    # Try sudo usermod (non-interactive)
    if sudo usermod -s "$zsh_path" "$USER" 2>/dev/null; then
        echo "PASS: ZSH set as default shell"
        echo "INFO: Restart terminal to take effect"
        return 0
    else
        echo "WARN: Failed to set ZSH as default shell automatically"
        echo "INFO: You can manually set it with: chsh -s $zsh_path"
        return 1
    fi
}

# ============================================================================
# FULL CONFIGURATION
# ============================================================================

# Function: configure_all_zsh_functions
configure_all_zsh_functions() {
    local zshrc="${1:-${HOME}/.zshrc}"
    local failures=0

    echo "Configuring ZSH functions and integrations..."
    echo

    # Performance optimizations
    if ! configure_performance_optimizations "$zshrc"; then
        ((failures++))
    fi

    # History settings
    if ! configure_history_settings "$zshrc"; then
        ((failures++))
    fi

    # Ghostty integration
    if ! configure_ghostty_integration "$zshrc"; then
        ((failures++))
    fi

    echo

    if [[ $failures -eq 0 ]]; then
        echo "PASS: All ZSH configurations applied"
        return 0
    else
        echo "WARN: $failures configuration(s) had issues"
        return 0
    fi
}

# Function: get_zsh_config_status
#   JSON-formatted status (stdout)
get_zsh_config_status() {
    local zshrc="${1:-${HOME}/.zshrc}"
    local perf_opt="false"
    local history_opt="false"
    local ghostty_int="false"

    if [[ -f "$zshrc" ]]; then
        grep -q "Oh My ZSH Performance Optimizations" "$zshrc" && perf_opt="true"
        grep -q "HIST_IGNORE_ALL_DUPS" "$zshrc" && history_opt="true"
        grep -q "GHOSTTY_RESOURCES_DIR" "$zshrc" && ghostty_int="true"
    fi

    cat <<EOF
{
  "performance_optimizations": $perf_opt,
  "history_settings": $history_opt,
  "ghostty_integration": $ghostty_int,
  "max_startup_ms": $MAX_STARTUP_OVERHEAD_MS
}
EOF
}
