#!/usr/bin/env bash
#
# lib/config/zsh/aliases.sh - ZSH alias definitions
#
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - add_alias(): Add single alias to .zshrc
#   - configure_modern_tool_aliases(): Set up modern Unix tool aliases
#   - configure_git_aliases(): Set up Git workflow aliases
#   - get_configured_aliases(): List all configured aliases
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_CONFIG_ZSH_ALIASES_SH:-}" ]] && return 0
readonly _LIB_CONFIG_ZSH_ALIASES_SH=1

# Module constants
readonly ALIAS_SECTION_MARKER="# Modern Unix Tools Configuration"

# ============================================================================
# ALIAS MANAGEMENT
# ============================================================================

# Function: add_alias
add_alias() {
    local alias_name="$1"
    local alias_cmd="$2"
    local zshrc="${3:-${HOME}/.zshrc}"

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found: $zshrc" >&2
        return 1
    fi

    local alias_line="alias ${alias_name}=\"${alias_cmd}\""

    # Check if alias already exists
    if grep -q "^alias ${alias_name}=" "$zshrc"; then
        echo "INFO: Alias already exists: $alias_name"
        return 0
    fi

    # Add alias
    echo "$alias_line" >> "$zshrc"
    echo "PASS: Added alias: $alias_name"
    return 0
}

# Function: remove_alias
remove_alias() {
    local alias_name="$1"
    local zshrc="${2:-${HOME}/.zshrc}"

    if [[ -f "$zshrc" ]]; then
        sed -i "/^alias ${alias_name}=/d" "$zshrc"
        echo "PASS: Removed alias: $alias_name"
    fi

    return 0
}

# ============================================================================
# MODERN TOOL ALIASES
# ============================================================================

# Function: configure_modern_tool_aliases
configure_modern_tool_aliases() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found" >&2
        return 1
    fi

    # Check if already configured
    if grep -q "$ALIAS_SECTION_MARKER" "$zshrc"; then
        echo "INFO: Modern tool aliases already configured"
        return 0
    fi

    # Backup .zshrc
    cp "$zshrc" "${zshrc}.backup-$(date +%Y%m%d-%H%M%S)"

    # Add modern tool aliases
    cat >> "$zshrc" <<'EOF'

# Modern Unix Tools Configuration (from install_modern_tools.sh)
# Wave 1 Agent 4: bat, eza, ripgrep, fd, zoxide, fzf

# eza: Better ls with colors and icons
if command -v eza >/dev/null 2>&1; then
    alias ls="eza --group-directories-first --git"
    alias ll="eza -la --group-directories-first --git"
    alias la="eza -a --group-directories-first"
    alias lt="eza --tree --level=2"
    alias tree="eza --tree"
fi

# bat: Better cat with syntax highlighting
if command -v bat >/dev/null 2>&1; then
    alias cat="bat --style=plain"
    alias catn="bat --style=numbers"
    alias bathelp="bat --style=plain --language=help"
fi

# ripgrep: Better grep
if command -v rg >/dev/null 2>&1; then
    alias grep="rg"
fi

# fd: Better find
if command -v fd >/dev/null 2>&1; then
    alias find="fd"
fi
EOF

    echo "PASS: Configured modern tool aliases"
    return 0
}

# Function: configure_fzf_integration
configure_fzf_integration() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found" >&2
        return 1
    fi

    # Check if fzf config already present
    if grep -q "FZF_DEFAULT_COMMAND" "$zshrc"; then
        echo "INFO: fzf integration already configured"
        return 0
    fi

    # Add fzf configuration
    cat >> "$zshrc" <<'EOF'

# fzf: Fuzzy finder integration
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
    [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
    [[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh
fi
EOF

    echo "PASS: Configured fzf integration"
    return 0
}

# Function: configure_zoxide_integration
configure_zoxide_integration() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found" >&2
        return 1
    fi

    # Check if zoxide config already present
    if grep -q "zoxide init" "$zshrc"; then
        echo "INFO: zoxide integration already configured"
        return 0
    fi

    # Add zoxide initialization
    cat >> "$zshrc" <<'EOF'

# zoxide: Smarter cd with frecency
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi
EOF

    echo "PASS: Configured zoxide integration"
    return 0
}

# ============================================================================
# GIT ALIASES
# ============================================================================

# Function: configure_git_aliases
configure_git_aliases() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ ! -f "$zshrc" ]]; then
        echo "FAIL: .zshrc not found" >&2
        return 1
    fi

    # Check if git aliases already present
    if grep -q "# Git workflow aliases" "$zshrc"; then
        echo "INFO: Git aliases already configured"
        return 0
    fi

    # Add Git aliases
    cat >> "$zshrc" <<'EOF'

# Git workflow aliases
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline -10"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias gpl="git pull"
EOF

    echo "PASS: Configured Git aliases"
    return 0
}

# ============================================================================
# ALIAS VERIFICATION
# ============================================================================

# Function: get_configured_aliases
#   List of aliases (stdout)
get_configured_aliases() {
    local zshrc="${1:-${HOME}/.zshrc}"

    if [[ -f "$zshrc" ]]; then
        grep "^alias " "$zshrc" | sed 's/alias //' | cut -d= -f1 | sort
    fi
}

# Function: verify_tool_aliases
verify_tool_aliases() {
    local issues=0
    local tools=("eza" "bat" "rg" "fd" "fzf" "zoxide")

    echo "Verifying modern tool availability..."

    for tool in "${tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo "  PASS: $tool available"
        else
            echo "  INFO: $tool not installed"
            ((issues++))
        fi
    done

    if [[ $issues -eq 0 ]]; then
        echo "PASS: All modern tools available"
        return 0
    else
        echo "INFO: $issues tool(s) not installed (optional)"
        return 0
    fi
}
