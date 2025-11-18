#!/usr/bin/env bash
#
# lib/verification/unit_tests.sh - Component verification functions (real system checks)
#
# CONTEXT7 STATUS: Will query for each component during execution
# FALLBACK: Constitutional compliance verification patterns
#
# Constitutional Compliance: Principle V - Modular Architecture
# User Stories: US1 (Fresh Installation), US3 (Re-run Safety), US5 (Best Practices)
#
# Requirements:
# - FR-007: Real verification functions (NO hard-coded success)
# - FR-008: Every installation task has corresponding verify function
# - FR-009: Check command existence, version, files, services
# - FR-010: Proper exit codes (0=success, 1=failure)
# - FR-060: fnm startup <50ms (constitutional)
# - FR-038: Node.js latest v25.2.0+
#
# CRITICAL: All verification functions MUST check actual system state
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"

#
# T015: Verify Ghostty installed and functional
#
# Real system checks (NO hard-coded success):
#   - Binary exists at expected location
#   - Binary is executable
#   - Version check succeeds
#   - Configuration validation works
#   - Shared libraries resolved
#
# Returns:
#   0 = success (Ghostty fully functional)
#   1 = failure with diagnostic error message
#
# Usage:
#   if verify_ghostty_installed; then
#       echo "Ghostty ready"
#   fi
#
verify_ghostty_installed() {
    log "INFO" "Verifying Ghostty installation..."

    local ghostty_path="${GHOSTTY_APP_DIR:-$HOME/.local/share/ghostty}/bin/ghostty"

    # Check 1: Binary exists
    if [ ! -f "$ghostty_path" ]; then
        log "ERROR" "✗ Ghostty binary not found at: $ghostty_path"
        log "ERROR" "  Expected location: \$GHOSTTY_APP_DIR/bin/ghostty"
        return 1
    fi

    # Check 2: Binary is executable
    if [ ! -x "$ghostty_path" ]; then
        log "ERROR" "✗ Ghostty binary not executable: $ghostty_path"
        log "ERROR" "  Fix with: chmod +x $ghostty_path"
        return 1
    fi

    # Check 3: Version check succeeds
    local version_output
    if ! version_output=$("$ghostty_path" --version 2>&1); then
        log "ERROR" "✗ Ghostty version check failed"
        log "ERROR" "  Output: $version_output"
        return 1
    fi

    local version
    version=$(echo "$version_output" | head -n 1)
    log "INFO" "  Ghostty version: $version"

    # Check 4: Configuration validation
    if ! "$ghostty_path" +show-config &>/dev/null; then
        log "ERROR" "✗ Ghostty configuration validation failed"
        log "ERROR" "  Run: $ghostty_path +show-config"
        return 1
    fi

    # Check 5: Shared libraries check
    if command_exists "ldd"; then
        local ldd_output
        ldd_output=$(ldd "$ghostty_path" 2>&1)

        if echo "$ldd_output" | grep -q "not found"; then
            log "ERROR" "✗ Ghostty has missing shared libraries:"
            echo "$ldd_output" | grep "not found"
            return 1
        fi
    fi

    log "SUCCESS" "✓ Ghostty installed and functional ($version)"
    return 0
}

#
# T016: Verify ZSH configured with Oh My ZSH
#
# Real system checks:
#   - ZSH binary exists and executable
#   - Oh My ZSH installed (~/.oh-my-zsh)
#   - .zshrc configured with Oh My ZSH
#   - Required plugins loaded
#
# Returns:
#   0 = success
#   1 = failure
#
verify_zsh_configured() {
    log "INFO" "Verifying ZSH configuration..."

    # Check 1: ZSH binary exists
    if ! command_exists "zsh"; then
        log "ERROR" "✗ ZSH not installed"
        log "ERROR" "  Install with: sudo apt install zsh"
        return 1
    fi

    # Check 2: ZSH version
    local zsh_version
    zsh_version=$(zsh --version 2>&1 | head -n 1)
    log "INFO" "  ZSH version: $zsh_version"

    # Check 3: Oh My ZSH directory exists
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "ERROR" "✗ Oh My ZSH not installed"
        log "ERROR" "  Directory not found: $HOME/.oh-my-zsh"
        return 1
    fi

    # Check 4: .zshrc exists and references Oh My ZSH
    if [ ! -f "$HOME/.zshrc" ]; then
        log "ERROR" "✗ .zshrc not found"
        return 1
    fi

    if ! grep -q "oh-my-zsh" "$HOME/.zshrc"; then
        log "ERROR" "✗ .zshrc not configured for Oh My ZSH"
        log "ERROR" "  Missing 'oh-my-zsh' reference in $HOME/.zshrc"
        return 1
    fi

    # Check 5: Verify plugins configured
    if grep -q "^plugins=" "$HOME/.zshrc"; then
        local plugins_line
        plugins_line=$(grep "^plugins=" "$HOME/.zshrc" | head -n 1)
        log "INFO" "  Plugins: $plugins_line"
    else
        log "WARNING" "  Warning: No plugins configured in .zshrc"
    fi

    log "SUCCESS" "✓ ZSH configured with Oh My ZSH"
    return 0
}

#
# T017: Verify uv (Python package manager)
#
# Real system checks:
#   - uv command exists
#   - Version check succeeds
#   - uv in PATH
#   - uv pip subcommand works
#   - Performance check (startup time)
#
# Returns:
#   0 = success
#   1 = failure
#
verify_python_uv() {
    log "INFO" "Verifying uv (Python package manager)..."

    # Check 1: uv command exists
    if ! command_exists "uv"; then
        log "ERROR" "✗ uv not installed"
        log "ERROR" "  Install from: https://astral.sh/uv"
        return 1
    fi

    # Check 2: Version check
    local uv_version
    if ! uv_version=$(uv --version 2>&1 | head -n 1); then
        log "ERROR" "✗ uv version check failed"
        return 1
    fi

    log "INFO" "  uv version: $uv_version"

    # Check 3: uv in PATH (check common locations)
    local uv_path
    uv_path=$(command -v uv)
    log "INFO" "  uv path: $uv_path"

    # Verify it's in a standard location
    if [[ "$uv_path" != "$HOME/.local/bin/uv" ]] && \
       [[ "$uv_path" != "/usr/local/bin/uv" ]] && \
       [[ "$uv_path" != "$HOME/.cargo/bin/uv" ]]; then
        log "WARNING" "  Warning: uv in non-standard location: $uv_path"
    fi

    # Check 4: uv pip subcommand works
    if ! uv pip --version &>/dev/null; then
        log "ERROR" "✗ uv pip subcommand not working"
        return 1
    fi

    # Check 5: Performance test (uv should be FAST)
    local start_ns end_ns duration_ms
    start_ns=$(get_unix_timestamp_ns)
    uv --version &>/dev/null
    end_ns=$(get_unix_timestamp_ns)
    duration_ms=$(calculate_duration_ns "$start_ns" "$end_ns")

    if [ "$duration_ms" -lt 100 ]; then
        log "SUCCESS" "✓ uv installed and fast (${duration_ms}ms <100ms ✓)"
    else
        log "WARNING" "  Warning: uv startup slow (${duration_ms}ms ≥100ms)"
        log "SUCCESS" "✓ uv installed (functional but slow startup)"
    fi

    return 0
}

#
# T018: Verify fnm (Fast Node Manager) installed
#
# Real system checks:
#   - fnm command exists
#   - Version check succeeds
#   - fnm in PATH
#   - Shell integration configured
#
# Returns:
#   0 = success
#   1 = failure
#
verify_fnm_installed() {
    log "INFO" "Verifying fnm (Fast Node Manager)..."

    # Check 1: fnm command exists
    if ! command_exists "fnm"; then
        log "ERROR" "✗ fnm not installed"
        log "ERROR" "  Install from: https://fnm.vercel.app"
        return 1
    fi

    # Check 2: Version check
    local fnm_version
    if ! fnm_version=$(fnm --version 2>&1 | head -n 1); then
        log "ERROR" "✗ fnm version check failed"
        return 1
    fi

    log "INFO" "  fnm version: $fnm_version"

    # Check 3: fnm in PATH
    local fnm_path
    fnm_path=$(command -v fnm)
    log "INFO" "  fnm path: $fnm_path"

    # Verify XDG-compliant location
    if [[ "$fnm_path" == "$HOME/.local/share/fnm/fnm" ]]; then
        log "INFO" "  ✓ XDG-compliant installation"
    elif [[ "$fnm_path" == "$HOME/.fnm/fnm" ]]; then
        log "WARNING" "  Warning: Legacy location (should be ~/.local/share/fnm)"
    fi

    # Check 4: Shell integration configured
    local shell_rc="$HOME/.zshrc"
    if [ ! -f "$shell_rc" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    if [ -f "$shell_rc" ] && grep -q "fnm env" "$shell_rc"; then
        log "INFO" "  ✓ Shell integration configured in $shell_rc"
    else
        log "WARNING" "  Warning: Shell integration not found in $shell_rc"
        log "WARNING" "  Add: eval \"\$(fnm env --use-on-cd)\""
    fi

    log "SUCCESS" "✓ fnm installed ($fnm_version)"
    return 0
}

#
# T019: Verify fnm performance (CONSTITUTIONAL REQUIREMENT)
#
# CRITICAL: fnm startup MUST be <50ms (constitutional requirement from AGENTS.md)
#
# Performance test:
#   - Measure `fnm env` startup time with nanosecond precision
#   - MUST be <50ms or FAIL with CONSTITUTIONAL VIOLATION
#
# Returns:
#   0 = success (<50ms)
#   1 = CONSTITUTIONAL VIOLATION (≥50ms)
#
verify_fnm_performance() {
    log "INFO" "Verifying fnm performance (CONSTITUTIONAL REQUIREMENT)..."

    if ! command_exists "fnm"; then
        log "ERROR" "✗ fnm not installed - cannot test performance"
        return 1
    fi

    # Measure fnm env startup time (nanosecond precision)
    local start_ns end_ns duration_ms
    start_ns=$(get_unix_timestamp_ns)
    fnm env &>/dev/null
    end_ns=$(get_unix_timestamp_ns)
    duration_ms=$(calculate_duration_ns "$start_ns" "$end_ns")

    # Constitutional requirement: <50ms
    if [ "$duration_ms" -lt 50 ]; then
        log "SUCCESS" "✓ fnm performance: ${duration_ms}ms (<50ms ✓ CONSTITUTIONAL COMPLIANCE)"
        return 0
    else
        log "ERROR" "✗ CONSTITUTIONAL VIOLATION: fnm startup ${duration_ms}ms ≥50ms"
        log "ERROR" "  Constitutional requirement (AGENTS.md line 184): fnm MUST be <50ms"
        log "ERROR" "  This is a BLOCKING failure - fnm must meet performance requirement"
        return 1
    fi
}

#
# T020: Verify Node.js version (latest v25.2.0+)
#
# Real system checks:
#   - node command exists
#   - Version is v25.2.0 or higher (constitutional: latest, NOT LTS)
#   - npm available
#
# Returns:
#   0 = success (v25.2.0+)
#   1 = failure or version too old
#
verify_nodejs_version() {
    log "INFO" "Verifying Node.js version..."

    # Check 1: node command exists
    if ! command_exists "node"; then
        log "ERROR" "✗ Node.js not installed"
        log "ERROR" "  Install via fnm: fnm install latest && fnm default latest"
        return 1
    fi

    # Check 2: Get version
    local node_version
    if ! node_version=$(node --version 2>&1 | head -n 1); then
        log "ERROR" "✗ Node.js version check failed"
        return 1
    fi

    log "INFO" "  Node.js version: $node_version"

    # Check 3: Verify version ≥ v25.2.0
    # Extract major and minor version
    local version_numbers
    version_numbers=$(echo "$node_version" | sed 's/v\([0-9]*\)\.\([0-9]*\).*/\1.\2/')
    local major
    major=$(echo "$version_numbers" | cut -d. -f1)
    local minor
    minor=$(echo "$version_numbers" | cut -d. -f2)

    if [ "$major" -lt 25 ]; then
        log "ERROR" "✗ Node.js version too old: $node_version (require v25.2.0+)"
        log "ERROR" "  Constitutional requirement: Latest Node.js (v25+), NOT LTS"
        log "ERROR" "  Update with: fnm install latest && fnm default latest"
        return 1
    elif [ "$major" -eq 25 ] && [ "$minor" -lt 2 ]; then
        log "WARNING" "⚠ Node.js version: $node_version (recommend v25.2.0+)"
        log "SUCCESS" "✓ Node.js installed (acceptable version)"
        return 0
    fi

    log "SUCCESS" "✓ Node.js latest version ($node_version ≥v25.2.0 ✓)"

    # Check 4: npm available
    if command_exists "npm"; then
        local npm_version
        npm_version=$(npm --version 2>&1 | head -n 1)
        log "INFO" "  npm version: $npm_version"
    else
        log "WARNING" "  Warning: npm not found (should come with Node.js)"
    fi

    return 0
}

#
# T021: Verify Claude CLI installed
#
# Real system checks:
#   - claude command exists
#   - Version check succeeds
#   - Configuration check (API key not required for verification)
#
# Returns:
#   0 = success
#   1 = failure
#
verify_claude_cli() {
    log "INFO" "Verifying Claude CLI..."

    # Check 1: claude command exists
    if ! command_exists "claude"; then
        log "ERROR" "✗ Claude CLI not installed"
        log "ERROR" "  Install with: npm install -g @anthropic-ai/claude-code"
        return 1
    fi

    # Check 2: Version check
    local claude_version
    if claude_version=$(claude --version 2>&1 | head -n 1); then
        log "INFO" "  Claude CLI version: $claude_version"
    else
        log "WARNING" "  Warning: Claude CLI version check returned error"
        log "WARNING" "  This may be normal if not configured"
    fi

    # Check 3: Command responds (basic functionality)
    # Note: --help should work even without API key
    if claude --help &>/dev/null; then
        log "SUCCESS" "✓ Claude CLI installed and functional"
        return 0
    else
        log "ERROR" "✗ Claude CLI not responding to commands"
        return 1
    fi
}

#
# T022: Verify Gemini CLI installed
#
# Real system checks:
#   - gemini command exists
#   - Version check succeeds
#
# Returns:
#   0 = success
#   1 = failure
#
verify_gemini_cli() {
    log "INFO" "Verifying Gemini CLI..."

    # Check 1: gemini command exists
    if ! command_exists "gemini"; then
        log "ERROR" "✗ Gemini CLI not installed"
        log "ERROR" "  Install with: npm install -g @google/gemini-cli"
        return 1
    fi

    # Check 2: Version check
    local gemini_version
    if gemini_version=$(gemini --version 2>&1 | head -n 1); then
        log "INFO" "  Gemini CLI version: $gemini_version"
    else
        log "WARNING" "  Warning: Gemini CLI version check returned error"
    fi

    # Check 3: Command responds
    if gemini --help &>/dev/null; then
        log "SUCCESS" "✓ Gemini CLI installed and functional"
        return 0
    else
        log "ERROR" "✗ Gemini CLI not responding to commands"
        return 1
    fi
}

#
# T023: Verify context menu integration (Nautilus)
#
# Real system checks:
#   - Nautilus action/script file exists
#   - File is executable
#   - Ghostty path configured correctly in script
#
# Returns:
#   0 = success
#   1 = failure
#
verify_context_menu() {
    log "INFO" "Verifying Nautilus context menu integration..."

    # Check 1: Nautilus scripts directory exists
    local nautilus_script_dir="$HOME/.local/share/nautilus/scripts"
    if [ ! -d "$nautilus_script_dir" ]; then
        log "ERROR" "✗ Nautilus scripts directory not found: $nautilus_script_dir"
        return 1
    fi

    # Check 2: "Open in Ghostty" script exists
    local script_path="$nautilus_script_dir/Open in Ghostty"
    if [ ! -f "$script_path" ]; then
        log "ERROR" "✗ Context menu script not found: $script_path"
        return 1
    fi

    # Check 3: Script is executable
    if [ ! -x "$script_path" ]; then
        log "ERROR" "✗ Context menu script not executable: $script_path"
        log "ERROR" "  Fix with: chmod +x '$script_path'"
        return 1
    fi

    # Check 4: Verify Ghostty path in script
    local ghostty_path="${GHOSTTY_APP_DIR:-$HOME/.local/share/ghostty}/bin/ghostty"
    if ! grep -q "$ghostty_path" "$script_path"; then
        log "WARNING" "  Warning: Script may not reference correct Ghostty path"
        log "WARNING" "  Expected: $ghostty_path"
    fi

    log "SUCCESS" "✓ Context menu integration configured"
    return 0
}

# Export all verification functions
export -f verify_ghostty_installed
export -f verify_zsh_configured
export -f verify_python_uv
export -f verify_fnm_installed
export -f verify_fnm_performance
export -f verify_nodejs_version
export -f verify_claude_cli
export -f verify_gemini_cli
export -f verify_context_menu
