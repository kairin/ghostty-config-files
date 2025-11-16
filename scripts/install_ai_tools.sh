#!/bin/bash
# Module: install_ai_tools.sh
# Purpose: Install Claude Code, Gemini CLI, GitHub Copilot CLI, and MCP servers
# Dependencies: install_node.sh, verification.sh, progress.sh, common.sh
# Modules Required: Node.js (npm), Python (pip for Gemini MCP)
# Exit Codes: 0=success, 1=installation failed, 2=invalid argument

set -euo pipefail

# Prevent multiple sourcing of this module (idempotent sourcing)
[[ -n "${INSTALL_AI_TOOLS_SH_LOADED:-}" ]] && return 0
readonly INSTALL_AI_TOOLS_SH_LOADED=1

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

# NPM package names
readonly CLAUDE_PACKAGE="@anthropic-ai/claude-code"
readonly GEMINI_PACKAGE="@google/gemini-cli"
readonly COPILOT_PACKAGE="@github/copilot"
readonly ZSH_CODEX_PACKAGE="zsh-codex"

# MCP server packages
readonly MCP_FILESYSTEM="@modelcontextprotocol/server-filesystem"
readonly MCP_GITHUB="@modelcontextprotocol/server-github"
readonly MCP_GIT="@modelcontextprotocol/server-git"

# Minimum versions (for verification)
readonly MIN_CLAUDE_VERSION="0.1.0"
readonly MIN_GEMINI_VERSION="0.1.0"
readonly MIN_COPILOT_VERSION="0.1.0"
readonly MIN_FASTMCP_VERSION="2.12.3"

# Configuration paths
readonly CLAUDE_CONFIG_DIR="${HOME}/.config/Claude"
readonly CLAUDE_CONFIG_FILE="${CLAUDE_CONFIG_DIR}/claude_desktop_config.json"
readonly AI_CONTEXT_CACHE_DIR="${HOME}/.cache/ghostty-ai-context"

# ============================================================
# PRIVATE HELPER FUNCTIONS
# ============================================================

# Function: _check_npm_available
# Purpose: Verify npm is installed and accessible
# Args: None
# Returns: 0 if npm available, 1 otherwise
# Side Effects: None
_check_npm_available() {
    if ! command -v npm &> /dev/null; then
        log_error "npm not found in PATH"
        log_info "Run: ./manage.sh install node"
        return 1
    fi

    # Verify npm version
    local npm_version
    if ! npm_version=$(npm --version 2>&1); then
        log_error "Failed to get npm version"
        return 1
    fi

    log_info "✓ npm available: v${npm_version}"
    return 0
}

# Function: _check_pip_available
# Purpose: Verify pip is installed and accessible
# Args: None
# Returns: 0 if pip available, 1 otherwise
# Side Effects: Sets PIP_CMD global variable to pip or pip3
_check_pip_available() {
    if command -v pip &> /dev/null; then
        PIP_CMD="pip"
    elif command -v pip3 &> /dev/null; then
        PIP_CMD="pip3"
    else
        log_warn "⚠ pip not found - required for Gemini MCP servers"
        log_info "Install with: sudo apt install python3-pip"
        return 1
    fi

    local pip_version
    if ! pip_version=$($PIP_CMD --version 2>&1); then
        log_error "Failed to get pip version"
        return 1
    fi

    log_info "✓ pip available: ${pip_version}"
    return 0
}

# Function: _npm_install_global
# Purpose: Install npm package globally with error handling
# Args:
#   $1=package_name (required, e.g., "@anthropic-ai/claude-code")
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs package globally via npm
_npm_install_global() {
    local package_name="$1"

    log_info "Installing ${package_name} globally..."

    # Install with npm
    local install_output
    if ! install_output=$(npm install -g "$package_name" 2>&1); then
        log_error "Failed to install ${package_name}"
        echo "  Output: $install_output" >&2
        return 1
    fi

    log_info "✓ ${package_name} installed successfully"
    return 0
}

# Function: _create_shell_backup
# Purpose: Create timestamped backup of shell RC file
# Args:
#   $1=rc_file (required, e.g., ~/.bashrc)
# Returns: 0 if backup created, 1 otherwise
# Side Effects: Creates backup file
_create_shell_backup() {
    local rc_file="$1"

    if [[ ! -f "$rc_file" ]]; then
        log_warn "⚠ Shell RC file not found: ${rc_file}"
        return 1
    fi

    local backup_file="${rc_file}.backup-$(date +%Y%m%d-%H%M%S)"
    if ! cp "$rc_file" "$backup_file"; then
        log_error "Failed to create backup: ${backup_file}"
        return 1
    fi

    log_info "✓ Backup created: ${backup_file}"
    return 0
}

# ============================================================
# PUBLIC FUNCTIONS (Module API) - AI CLI Tools
# ============================================================

# Function: install_claude_code
# Purpose: Install Claude Code CLI from npm
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs @anthropic-ai/claude-code globally
# Example: install_claude_code
install_claude_code() {
    log_info "=== Installing Claude Code CLI ==="

    # Check if already installed
    if command -v claude &> /dev/null; then
        if verify_binary "claude" "${MIN_CLAUDE_VERSION}" "claude --version"; then
            log_info "✓ Claude Code already installed and meets minimum version"
            return 0
        else
            log_info "Updating Claude Code to latest version..."
        fi
    fi

    # Install or update
    if ! _npm_install_global "$CLAUDE_PACKAGE"; then
        return 1
    fi

    # Verify installation
    if ! verify_binary "claude" "${MIN_CLAUDE_VERSION}" "claude --version"; then
        log_error "Claude Code installation verification failed"
        return 1
    fi

    log_info "✓ Claude Code installed successfully"
    return 0
}

# Function: install_gemini_cli
# Purpose: Install Gemini CLI from npm
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs @google/gemini-cli globally
# Example: install_gemini_cli
install_gemini_cli() {
    log_info "=== Installing Gemini CLI ==="

    # Check if already installed
    if command -v gemini &> /dev/null; then
        if verify_binary "gemini" "${MIN_GEMINI_VERSION}" "gemini --version"; then
            log_info "✓ Gemini CLI already installed and meets minimum version"
            return 0
        else
            log_info "Updating Gemini CLI to latest version..."
        fi
    fi

    # Install or update
    if ! _npm_install_global "$GEMINI_PACKAGE"; then
        return 1
    fi

    # Verify installation
    if ! verify_binary "gemini" "${MIN_GEMINI_VERSION}" "gemini --version"; then
        log_error "Gemini CLI installation verification failed"
        return 1
    fi

    log_info "✓ Gemini CLI installed successfully"
    return 0
}

# Function: install_github_copilot
# Purpose: Install GitHub Copilot CLI from npm
# Args: None
# Returns: 0 if installation successful, 1 otherwise (non-blocking)
# Side Effects: Installs @github/copilot globally
# Example: install_github_copilot
install_github_copilot() {
    log_info "=== Installing GitHub Copilot CLI ==="

    # Check if GitHub CLI is available (required for Copilot)
    if ! command -v gh &> /dev/null; then
        log_warn "⚠ GitHub CLI not found - Copilot CLI requires 'gh'"
        log_info "Install with: sudo apt install gh"
        log_info "Skipping GitHub Copilot installation (non-critical)"
        return 0  # Return success to not block other installations
    fi

    # Check if already installed
    if command -v gh-copilot &> /dev/null || gh copilot --version &> /dev/null 2>&1; then
        log_info "✓ GitHub Copilot CLI already installed"
        return 0
    fi

    # Install via npm
    if ! _npm_install_global "$COPILOT_PACKAGE"; then
        log_warn "⚠ GitHub Copilot installation failed (non-critical)"
        return 0  # Non-blocking failure
    fi

    # Verify installation (gh extension or standalone)
    if gh copilot --version &> /dev/null 2>&1; then
        log_info "✓ GitHub Copilot CLI installed successfully"
        return 0
    else
        log_warn "⚠ GitHub Copilot installation completed but verification failed"
        return 0  # Non-blocking
    fi
}

# Function: install_zsh_codex
# Purpose: Install zsh-codex natural language to command translation
# Args: None
# Returns: 0 if installation successful, 1 otherwise (non-blocking)
# Side Effects: Installs zsh-codex globally via npm
# Example: install_zsh_codex
install_zsh_codex() {
    log_info "=== Installing zsh-codex ==="

    # Check if zsh is available
    if ! command -v zsh &> /dev/null; then
        log_warn "⚠ zsh not found - zsh-codex requires zsh shell"
        log_info "Skipping zsh-codex installation (non-critical)"
        return 0
    fi

    # Check if already installed
    if command -v codex &> /dev/null; then
        log_info "✓ zsh-codex already installed"
        return 0
    fi

    # Install via npm
    if ! _npm_install_global "$ZSH_CODEX_PACKAGE"; then
        log_warn "⚠ zsh-codex installation failed (non-critical)"
        return 0  # Non-blocking failure
    fi

    log_info "✓ zsh-codex installed successfully"
    log_info "Configure in ~/.zshrc: bindkey '^X' create_completion"
    return 0
}

# ============================================================
# PUBLIC FUNCTIONS (Module API) - MCP Servers
# ============================================================

# Function: install_claude_mcp_servers
# Purpose: Install Model Context Protocol servers for Claude Code
# Args: None
# Returns: 0 if successful, 1 otherwise
# Side Effects: Installs MCP servers globally, creates config file
# Example: install_claude_mcp_servers
install_claude_mcp_servers() {
    log_info "=== Installing Claude MCP Servers ==="

    # Install MCP servers via npm global
    local mcp_servers=(
        "$MCP_FILESYSTEM"
        "$MCP_GITHUB"
        "$MCP_GIT"
    )

    for server in "${mcp_servers[@]}"; do
        log_info "Installing ${server}..."
        if ! _npm_install_global "$server"; then
            log_error "Failed to install $server"
            return 1
        fi
    done

    # Create Claude config directory
    mkdir -p "$CLAUDE_CONFIG_DIR"

    # Get npm global prefix for correct paths
    local npm_prefix
    npm_prefix=$(npm config get prefix)

    # Create claude_desktop_config.json
    log_info "Creating MCP configuration at ${CLAUDE_CONFIG_FILE}..."
    cat > "${CLAUDE_CONFIG_FILE}" << EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "node",
      "args": [
        "${npm_prefix}/lib/node_modules/@modelcontextprotocol/server-filesystem"
      ],
      "env": {}
    },
    "github": {
      "command": "node",
      "args": [
        "${npm_prefix}/lib/node_modules/@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_TOKEN": "\${GITHUB_TOKEN}"
      }
    },
    "git": {
      "command": "node",
      "args": [
        "${npm_prefix}/lib/node_modules/@modelcontextprotocol/server-git"
      ],
      "env": {}
    }
  }
}
EOF

    log_info "✓ Claude MCP servers installed and configured"
    log_info "Config location: ${CLAUDE_CONFIG_FILE}"

    # Verify installation
    if command -v claude &> /dev/null; then
        if claude mcp list &> /dev/null 2>&1; then
            log_info "✓ MCP servers registered with Claude Code"
        else
            log_warn "⚠ Restart Claude Code to load MCP servers"
        fi
    else
        log_info "Install Claude Code first to use MCP servers"
    fi

    # Remind about GitHub token
    log_info ""
    log_info "To use GitHub MCP server, set GITHUB_TOKEN:"
    log_info "  export GITHUB_TOKEN=\"ghp_your_github_personal_access_token\""
    log_info "  echo 'export GITHUB_TOKEN=\"ghp_...\"' >> ~/.bashrc"

    return 0
}

# Function: install_gemini_mcp_servers
# Purpose: Install FastMCP integration for Gemini CLI
# Args: None
# Returns: 0 if successful, 1 otherwise
# Side Effects: Installs FastMCP via pip, configures Gemini CLI
# Example: install_gemini_mcp_servers
install_gemini_mcp_servers() {
    log_info "=== Installing Gemini MCP Integration ==="

    # Ensure Gemini CLI is installed (from T059)
    if ! command -v gemini &> /dev/null; then
        log_error "Gemini CLI not found - install first"
        return 1
    fi

    # Check if Python/pip available
    if ! _check_pip_available; then
        log_error "pip not found - install Python first"
        log_info "Run: sudo apt install python3-pip"
        return 1
    fi

    # Install FastMCP
    log_info "Installing FastMCP (>=${MIN_FASTMCP_VERSION})..."
    if ! $PIP_CMD install --user "fastmcp>=${MIN_FASTMCP_VERSION}" 2>&1; then
        log_error "Failed to install FastMCP"
        return 1
    fi

    # Configure Gemini CLI with FastMCP
    log_info "Configuring Gemini MCP integration..."
    if command -v fastmcp &> /dev/null; then
        if fastmcp install gemini-cli &> /dev/null 2>&1; then
            log_info "✓ FastMCP configured for Gemini CLI"
        else
            log_warn "⚠ FastMCP installation completed, manual configuration may be needed"
        fi
    else
        log_warn "⚠ FastMCP installed but not in PATH - add ~/.local/bin to PATH"
        log_info "Add to ~/.bashrc: export PATH=\"\${HOME}/.local/bin:\$PATH\""
    fi

    log_info "✓ Gemini MCP integration installed"
    log_info "Note: MCP auto-calling is Python SDK feature only (as of 2025-03)"
    log_info "JavaScript SDK support is experimental"

    return 0
}

# ============================================================
# PUBLIC FUNCTIONS (Module API) - Shell Integration
# ============================================================

# Function: configure_shell_aliases
# Purpose: Add AI tool aliases to shell RC files
# Args: None
# Returns: 0 if configuration successful, 1 otherwise
# Side Effects: Modifies ~/.bashrc and ~/.zshrc
# Example: configure_shell_aliases
configure_shell_aliases() {
    log_info "=== Configuring Shell Aliases ==="

    local shell_rcs=("${HOME}/.bashrc" "${HOME}/.zshrc")

    for rc_file in "${shell_rcs[@]}"; do
        if [[ ! -f "$rc_file" ]]; then
            log_info "Skipping $rc_file (file not found)"
            continue
        fi

        log_info "Configuring aliases in ${rc_file}..."

        # Create backup
        _create_shell_backup "$rc_file"

        # Add AI tools section marker
        local marker="# AI Tools aliases (added by install_ai_tools.sh)"
        if grep -q "$marker" "$rc_file"; then
            log_info "Aliases already present in ${rc_file}"
            continue
        fi

        # Add AI tools configuration with context extraction
        cat >> "$rc_file" << 'EOF'

# AI Tools aliases (added by install_ai_tools.sh)

# AI Context extraction script location
AI_CONTEXT_SCRIPT="${HOME}/Apps/ghostty-config-files/scripts/extract_ai_context.sh"

# Claude Code with AI context extraction wrapper
if command -v claude &> /dev/null; then
    # Function wrapper that refreshes AI context before Claude invocation
    claude() {
        # Refresh AI context (performance: <100ms)
        if [[ -x "$AI_CONTEXT_SCRIPT" ]]; then
            "$AI_CONTEXT_SCRIPT" > /dev/null 2>&1 || true
        fi
        # Invoke Claude with all arguments
        command claude "$@"
    }

    # Shorthand alias
    alias cc='claude'
fi

# Gemini CLI with AI context extraction wrapper
if command -v gemini &> /dev/null; then
    # Function wrapper that refreshes AI context before Gemini invocation
    gemini() {
        # Refresh AI context (performance: <100ms)
        if [[ -x "$AI_CONTEXT_SCRIPT" ]]; then
            "$AI_CONTEXT_SCRIPT" > /dev/null 2>&1 || true
        fi
        # Invoke Gemini with all arguments
        command gemini "$@"
    }

    # Shorthand alias
    alias gem='gemini'
fi

# GitHub Copilot aliases (if GitHub CLI available)
if command -v gh &> /dev/null && gh copilot --version &> /dev/null 2>&1; then
    # Copilot command shortcuts
    eval "$(gh copilot alias -- bash 2>/dev/null || true)"
    eval "$(gh copilot alias -- zsh 2>/dev/null || true)"
fi

# zsh-codex integration (Ctrl+X for command completion)
if command -v zsh &> /dev/null && command -v codex &> /dev/null; then
    # Bind Ctrl+X to create_completion (zsh only)
    if [[ -n "${ZSH_VERSION:-}" ]]; then
        bindkey '^X' create_completion 2>/dev/null || true
    fi
fi
EOF
        log_info "✓ Aliases added to ${rc_file}"
    done

    log_info "✓ Shell configuration complete"
    return 0
}

# ============================================================
# PUBLIC FUNCTIONS (Module API) - Verification
# ============================================================

# Function: verify_ai_tools_installation
# Purpose: Comprehensive AI tools installation verification
# Args: None
# Returns: 0 if all verifications pass, 1 otherwise
# Side Effects: Runs verification checks
# Example: verify_ai_tools_installation
verify_ai_tools_installation() {
    local all_checks_passed=0

    log_info "=== AI Tools Installation Verification ==="
    echo

    # Check 1: Claude Code
    log_info "Check 1: Claude Code"
    if command -v claude &> /dev/null; then
        if verify_binary "claude" "${MIN_CLAUDE_VERSION}" "claude --version"; then
            # Test basic functionality
            if verify_integration "Claude Code help" "claude --help" "0" "usage"; then
                log_info "✓ Claude Code functional"
            else
                all_checks_passed=1
            fi
        else
            all_checks_passed=1
        fi
    else
        log_error "Claude Code not found in PATH"
        all_checks_passed=1
    fi
    echo

    # Check 2: Gemini CLI
    log_info "Check 2: Gemini CLI"
    if command -v gemini &> /dev/null; then
        if verify_binary "gemini" "${MIN_GEMINI_VERSION}" "gemini --version"; then
            # Test basic functionality
            if verify_integration "Gemini CLI help" "gemini --help" "0" "Usage"; then
                log_info "✓ Gemini CLI functional"
            else
                all_checks_passed=1
            fi
        else
            all_checks_passed=1
        fi
    else
        log_error "Gemini CLI not found in PATH"
        all_checks_passed=1
    fi
    echo

    # Check 3: GitHub Copilot (optional)
    log_info "Check 3: GitHub Copilot CLI"
    if command -v gh &> /dev/null && gh copilot --version &> /dev/null 2>&1; then
        log_info "✓ GitHub Copilot CLI available"
    else
        log_info "GitHub Copilot CLI not available (optional)"
    fi
    echo

    # Check 4: Shell aliases
    log_info "Check 4: Shell Aliases"
    local bashrc_has_aliases=0
    local zshrc_has_aliases=0

    if [[ -f "${HOME}/.bashrc" ]] && grep -q "AI Tools aliases" "${HOME}/.bashrc"; then
        bashrc_has_aliases=1
        log_info "✓ ~/.bashrc has AI tools aliases"
    fi

    if [[ -f "${HOME}/.zshrc" ]] && grep -q "AI Tools aliases" "${HOME}/.zshrc"; then
        zshrc_has_aliases=1
        log_info "✓ ~/.zshrc has AI tools aliases"
    fi

    if [[ $bashrc_has_aliases -eq 0 && $zshrc_has_aliases -eq 0 ]]; then
        log_error "No shell aliases configured"
        all_checks_passed=1
    fi
    echo

    # Check 5: MCP servers (optional)
    log_info "Check 5: Claude MCP Servers"
    if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
        log_info "✓ Claude MCP config exists: ${CLAUDE_CONFIG_FILE}"
        # Verify MCP packages installed
        local mcp_count=0
        for pkg in "$MCP_FILESYSTEM" "$MCP_GITHUB" "$MCP_GIT"; do
            if npm list -g "$pkg" &> /dev/null; then
                ((mcp_count++))
            fi
        done
        log_info "MCP servers installed: ${mcp_count}/3"
    else
        log_info "Claude MCP config not found (optional)"
    fi
    echo

    if [[ $all_checks_passed -eq 0 ]]; then
        log_info "✓ All verification checks passed"
        return 0
    else
        log_error "Some verification checks failed"
        return 1
    fi
}

# ============================================================
# PUBLIC FUNCTIONS (Module API) - Main Entry Point
# ============================================================

# Function: install_ai_tools
# Purpose: Main entry point for AI tools installation
# Args: None
# Returns: 0 if installation successful, 1 otherwise
# Side Effects: Installs Claude Code, Gemini CLI, GitHub Copilot, MCP servers, configures shell
# Example: install_ai_tools
install_ai_tools() {
    log_info "=== AI Tools Installation ==="
    echo

    # Step 0: Verify npm is available
    if ! _check_npm_available; then
        log_error "npm not available - install Node.js first"
        log_info "Run: ./manage.sh install node"
        return 1
    fi
    echo

    # Step 1: Install Claude Code
    if ! install_claude_code; then
        log_error "Failed to install Claude Code"
        return 1
    fi
    echo

    # Step 2: Install Gemini CLI
    if ! install_gemini_cli; then
        log_error "Failed to install Gemini CLI"
        return 1
    fi
    echo

    # Step 3: Install GitHub Copilot (optional)
    if ! install_github_copilot; then
        log_warn "⚠ GitHub Copilot installation failed (non-critical)"
    fi
    echo

    # Step 4: Install zsh-codex (optional)
    if ! install_zsh_codex; then
        log_warn "⚠ zsh-codex installation failed (non-critical)"
    fi
    echo

    # Step 5: Install Claude MCP servers
    if ! install_claude_mcp_servers; then
        log_warn "⚠ Claude MCP servers installation failed (non-critical)"
    fi
    echo

    # Step 6: Install Gemini MCP servers (optional - requires pip)
    if ! install_gemini_mcp_servers; then
        log_warn "⚠ Gemini MCP servers installation failed (non-critical)"
    fi
    echo

    # Step 7: Configure shell aliases
    if ! configure_shell_aliases; then
        log_warn "⚠ Shell alias configuration failed (non-critical)"
    fi
    echo

    # Step 8: Verify installation
    if ! verify_ai_tools_installation; then
        log_error "AI tools installation verification failed"
        return 1
    fi

    echo
    log_info "✓ AI Tools installation complete!"
    echo
    log_info "Next steps:"
    log_info "  1. Restart shell: exec \$SHELL"
    log_info "  2. Test Claude Code: claude --help"
    log_info "  3. Test Gemini CLI: gemini --help"
    log_info "  4. Configure API keys:"
    log_info "     - Claude Code: Follow prompts on first run"
    log_info "     - Gemini CLI: gemini auth login"
    log_info "     - GitHub Copilot: gh copilot auth (if using)"
    echo

    return 0
}

# ============================================================
# MODULE EXECUTION
# ============================================================

# Execute main function if not sourced for testing
if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    install_ai_tools "$@"
fi
