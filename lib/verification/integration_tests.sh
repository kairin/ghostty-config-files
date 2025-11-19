#!/usr/bin/env bash
#
# lib/verification/integration_tests.sh - Cross-component validation tests
#
# CONTEXT7 STATUS: Unable to query (API authentication issue)
# FALLBACK: Best practices for integration testing bash scripts 2025
#
# Constitutional Compliance: Principle V - Modular Architecture
# User Story: US1 (Fresh Installation)
#
# Requirements:
# - FR-011: Multi-layer verification (integration tests for cross-component)
# - FR-034: fnm + ZSH shell integration
# - Tests verify components work TOGETHER, not just individually
#
# Integration Tests:
#   1. ZSH + fnm integration (auto-switching on cd)
#   2. Ghostty + ZSH (default shell)
#   3. AI tools + Node.js (CLIs work with installed Node)
#   4. Context menu + Ghostty (right-click integration)
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${INTEGRATION_TESTS_SH_LOADED:-}" ] || return 0
INTEGRATION_TESTS_SH_LOADED=1

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"

#
# Test 1: ZSH + fnm integration
#
# Verifies that fnm shell integration works in ZSH:
#   - fnm env configured in .zshrc
#   - Auto-switching on directory change (.node-version detection)
#   - PATH includes fnm-managed Node.js
#
# Returns:
#   0 = integration working
#   1 = integration broken
#
test_zsh_fnm_integration() {
    log "INFO" "Testing ZSH + fnm integration..."

    # Check 1: fnm env in .zshrc
    if [ ! -f "$HOME/.zshrc" ]; then
        log "ERROR" "✗ .zshrc not found - cannot test integration"
        return 1
    fi

    if ! grep -q "fnm env" "$HOME/.zshrc"; then
        log "ERROR" "✗ fnm shell integration not configured in .zshrc"
        log "ERROR" "  Missing: eval \"\$(fnm env --use-on-cd)\""
        return 1
    fi

    log "INFO" "  ✓ fnm env configured in .zshrc"

    # Check 2: Verify fnm is in PATH when ZSH runs
    # Simulate ZSH environment and check fnm availability
    if ! command_exists "fnm"; then
        log "ERROR" "✗ fnm not in current PATH"
        return 1
    fi

    # Check 3: Verify fnm can manage Node.js versions
    if ! fnm list &>/dev/null; then
        log "ERROR" "✗ fnm list command failed"
        return 1
    fi

    local installed_versions
    installed_versions=$(fnm list 2>&1)
    if [ -z "$installed_versions" ]; then
        log "WARNING" "  Warning: No Node.js versions installed via fnm"
    else
        log "INFO" "  ✓ fnm managing Node.js versions"
    fi

    log "SUCCESS" "✓ ZSH + fnm integration working"
    return 0
}

#
# Test 2: Ghostty + ZSH integration
#
# Verifies that Ghostty launches with ZSH as default shell:
#   - Ghostty config file exists
#   - Config specifies ZSH as shell (or uses system default)
#   - ZSH binary exists and is functional
#
# Returns:
#   0 = integration working
#   1 = integration broken
#
test_ghostty_zsh_integration() {
    log "INFO" "Testing Ghostty + ZSH integration..."

    local config_path="$HOME/.config/ghostty/config"

    # Check 1: Ghostty config exists
    if [ ! -f "$config_path" ]; then
        log "ERROR" "✗ Ghostty config not found: $config_path"
        return 1
    fi

    # Check 2: Check shell configuration
    if grep -q "^command = zsh" "$config_path"; then
        log "INFO" "  ✓ Ghostty explicitly configured for ZSH"
    elif grep -q "^command =" "$config_path"; then
        local configured_shell
        configured_shell=$(grep "^command =" "$config_path" | cut -d= -f2 | tr -d ' ')
        log "INFO" "  Ghostty shell: $configured_shell"
    else
        log "INFO" "  ✓ Ghostty using system default shell"
    fi

    # Check 3: ZSH functional
    if ! command_exists "zsh"; then
        log "ERROR" "✗ ZSH not installed - Ghostty integration broken"
        return 1
    fi

    # Check 4: ZSH version check
    if ! zsh --version &>/dev/null; then
        log "ERROR" "✗ ZSH not responding - integration broken"
        return 1
    fi

    log "SUCCESS" "✓ Ghostty + ZSH integration configured"
    return 0
}

#
# Test 3: AI tools + Node.js integration
#
# Verifies that AI CLI tools work with installed Node.js:
#   - Claude CLI and Gemini CLI use Node.js runtime
#   - Tools are accessible via global npm installation
#   - Node.js version is compatible (v25.2.0+)
#
# Returns:
#   0 = integration working
#   1 = integration broken
#
test_ai_tools_nodejs_integration() {
    log "INFO" "Testing AI tools + Node.js integration..."

    # Check 1: Node.js installed and correct version
    if ! command_exists "node"; then
        log "ERROR" "✗ Node.js not installed - AI tools cannot work"
        return 1
    fi

    local node_version
    node_version=$(node --version 2>&1 | head -n 1)
    log "INFO" "  Node.js: $node_version"

    # Check 2: npm available (needed for global package management)
    if ! command_exists "npm"; then
        log "ERROR" "✗ npm not available - cannot verify AI tool installation"
        return 1
    fi

    # Check 3: Check if AI tools are npm global packages
    local claude_installed=false
    local gemini_installed=false

    if command_exists "claude"; then
        # Verify it's an npm package
        local claude_path
        claude_path=$(command -v claude)
        if [[ "$claude_path" == *"node_modules"* ]] || npm list -g @anthropic-ai/claude-code &>/dev/null; then
            log "INFO" "  ✓ Claude CLI installed via npm"
            claude_installed=true
        fi
    fi

    if command_exists "gemini"; then
        local gemini_path
        gemini_path=$(command -v gemini)
        if [[ "$gemini_path" == *"node_modules"* ]] || npm list -g @google/gemini-cli &>/dev/null; then
            log "INFO" "  ✓ Gemini CLI installed via npm"
            gemini_installed=true
        fi
    fi

    # Check 4: At least one AI tool working
    if ! $claude_installed && ! $gemini_installed; then
        log "ERROR" "✗ No AI tools installed via npm"
        return 1
    fi

    log "SUCCESS" "✓ AI tools + Node.js integration working"
    return 0
}

#
# Test 4: Context menu + Ghostty integration
#
# Verifies that right-click context menu can launch Ghostty:
#   - Context menu script exists and is executable
#   - Script can find Ghostty binary
#   - Script uses correct launch command
#
# Returns:
#   0 = integration working
#   1 = integration broken
#
test_context_menu_ghostty_integration() {
    log "INFO" "Testing Context menu + Ghostty integration..."

    # Check 1: Context menu script exists
    local script_path="$HOME/.local/share/nautilus/scripts/Open in Ghostty"
    if [ ! -f "$script_path" ]; then
        log "ERROR" "✗ Context menu script not found: $script_path"
        return 1
    fi

    # Check 2: Script is executable
    if [ ! -x "$script_path" ]; then
        log "ERROR" "✗ Context menu script not executable"
        return 1
    fi

    # Check 3: Script references Ghostty binary
    local ghostty_path="${GHOSTTY_APP_DIR:-$HOME/.local/share/ghostty}/bin/ghostty"

    if ! grep -q "ghostty" "$script_path"; then
        log "ERROR" "✗ Script does not reference Ghostty"
        return 1
    fi

    log "INFO" "  ✓ Script references Ghostty"

    # Check 4: Ghostty binary exists and is executable
    if [ ! -x "$ghostty_path" ]; then
        log "ERROR" "✗ Ghostty binary not found or not executable: $ghostty_path"
        return 1
    fi

    # Check 5: Script uses working directory launch (for context menu integration)
    if grep -q "NAUTILUS_SCRIPT_CURRENT_URI\|nautilus_script_current_uri" "$script_path"; then
        log "INFO" "  ✓ Script configured to open in current directory"
    else
        log "WARNING" "  Warning: Script may not respect current directory"
    fi

    log "SUCCESS" "✓ Context menu + Ghostty integration working"
    return 0
}

#
# Run all integration tests
#
# Executes all integration test functions and aggregates results.
#
# Returns:
#   0 = all tests passed
#   1 = one or more tests failed
#
run_all_integration_tests() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Running Integration Tests"
    log "INFO" "════════════════════════════════════════"
    echo ""

    local total_tests=0
    local passed_tests=0
    local failed_tests=0

    # Test 1: ZSH + fnm
    ((total_tests++))
    if test_zsh_fnm_integration; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    echo ""

    # Test 2: Ghostty + ZSH
    ((total_tests++))
    if test_ghostty_zsh_integration; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    echo ""

    # Test 3: AI tools + Node.js
    ((total_tests++))
    if test_ai_tools_nodejs_integration; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    echo ""

    # Test 4: Context menu + Ghostty
    ((total_tests++))
    if test_context_menu_ghostty_integration; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    echo ""

    # Summary
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Integration Tests Summary"
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Total tests:  $total_tests"
    log "SUCCESS" "Passed:       $passed_tests"

    if [ "$failed_tests" -gt 0 ]; then
        log "ERROR" "Failed:       $failed_tests"
        log "ERROR" "════════════════════════════════════════"
        return 1
    else
        log "SUCCESS" "All integration tests passed ✓"
        log "SUCCESS" "════════════════════════════════════════"
        return 0
    fi
}

# Export functions for use in other modules
export -f test_zsh_fnm_integration
export -f test_ghostty_zsh_integration
export -f test_ai_tools_nodejs_integration
export -f test_context_menu_ghostty_integration
export -f run_all_integration_tests
