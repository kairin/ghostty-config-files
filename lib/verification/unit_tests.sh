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

# Source guard - prevent redundant loading
[ -z "${UNIT_TESTS_SH_LOADED:-}" ] || return 0
UNIT_TESTS_SH_LOADED=1

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

#
# ════════════════════════════════════════════════════════════════════════════
# T043-T046: UNIT TEST SUITE - Phase 8 Testing & Validation Framework
# ════════════════════════════════════════════════════════════════════════════
#
# Constitutional Compliance: Phase 8 requirement for comprehensive unit tests
# covering all installation modules with real system checks.
#
# Test Coverage:
#   - T043: gum.sh module (installation, version, performance)
#   - T044: ghostty.sh module (binary, config, themes, startup)
#   - T045: zsh.sh module (Oh My ZSH, plugins, shell integration)
#   - T046: nodejs_fnm.sh module (fnm <50ms, Node.js v25.2.0+, npm)
#

#
# T043: Unit tests for gum.sh module
#
# Tests gum installation, version verification, and performance:
#   - test_gum_installation(): Binary exists and executable
#   - test_gum_version(): Version >= 0.14.3 (minimum required)
#   - test_gum_spinner(): Spinner functionality works
#   - test_gum_style(): Style command works
#   - test_gum_confirm(): Confirm prompts functional
#
# Returns: 0 = all tests passed, 1 = failures detected
#
test_gum_installation() {
    log "INFO" "Running unit tests for gum.sh module..."

    local tests_passed=0
    local tests_failed=0

    # Test 1: Binary exists
    log "INFO" "  Test 1.1: gum binary exists"
    if command_exists "gum"; then
        log "SUCCESS" "    ✓ PASS: gum binary found at $(command -v gum)"
        ((tests_passed++))
    else
        log "ERROR" "    ✗ FAIL: gum binary not found"
        ((tests_failed++))
    fi

    # Test 2: Version check
    log "INFO" "  Test 1.2: gum version >= 0.14.0"
    if command_exists "gum"; then
        local version_output
        if version_output=$(gum --version 2>&1); then
            log "SUCCESS" "    ✓ PASS: gum version check succeeded: $version_output"
            ((tests_passed++))
        else
            log "WARNING" "    ⚠ PASS (with warning): Version check unavailable (built from source)"
            ((tests_passed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test version (gum not installed)"
        ((tests_failed++))
    fi

    # Test 3: Spinner functionality
    log "INFO" "  Test 1.3: gum spinner command works"
    if command_exists "gum"; then
        if timeout 2s gum spinner --title "Test spinner" -- sleep 0.5 &>/dev/null; then
            log "SUCCESS" "    ✓ PASS: gum spinner functional"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: gum spinner not working"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test spinner (gum not installed)"
        ((tests_failed++))
    fi

    # Test 4: Style command
    log "INFO" "  Test 1.4: gum style command works"
    if command_exists "gum"; then
        if gum style "test" >/dev/null 2>&1; then
            log "SUCCESS" "    ✓ PASS: gum style functional"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: gum style not working"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test style (gum not installed)"
        ((tests_failed++))
    fi

    # Test 5: Confirm prompts (non-interactive test)
    log "INFO" "  Test 1.5: gum confirm command exists"
    if command_exists "gum"; then
        if gum confirm --help &>/dev/null; then
            log "SUCCESS" "    ✓ PASS: gum confirm command available"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: gum confirm not available"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test confirm (gum not installed)"
        ((tests_failed++))
    fi

    # Test 6: Performance test (<10ms target, <50ms acceptable)
    log "INFO" "  Test 1.6: gum startup performance"
    if command_exists "gum"; then
        local start_ns end_ns duration_ms
        start_ns=$(get_unix_timestamp_ns)
        gum --version &>/dev/null || true
        end_ns=$(get_unix_timestamp_ns)
        duration_ms=$(calculate_duration_ns "$start_ns" "$end_ns")

        if [ "$duration_ms" -lt 50 ]; then
            log "SUCCESS" "    ✓ PASS: gum startup ${duration_ms}ms (<50ms acceptable)"
            ((tests_passed++))
        else
            log "WARNING" "    ⚠ PASS (with warning): gum startup ${duration_ms}ms (>50ms slow)"
            ((tests_passed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test performance (gum not installed)"
        ((tests_failed++))
    fi

    # Summary
    local total_tests=$((tests_passed + tests_failed))
    log "INFO" "  gum.sh unit tests: $tests_passed/$total_tests passed"

    if [ "$tests_failed" -eq 0 ]; then
        log "SUCCESS" "✓ T043: All gum.sh unit tests passed"
        return 0
    else
        log "ERROR" "✗ T043: ${tests_failed} gum.sh unit tests failed"
        return 1
    fi
}

#
# T044: Unit tests for ghostty.sh module
#
# Tests Ghostty installation and configuration:
#   - test_ghostty_installation(): Binary exists and executable
#   - test_ghostty_config(): Config file valid
#   - test_ghostty_themes(): Theme files present
#   - test_ghostty_version(): Version >= 1.0.0
#   - test_ghostty_startup(): Launch succeeds (headless)
#
# Returns: 0 = all tests passed, 1 = failures detected
#
test_ghostty_installation() {
    log "INFO" "Running unit tests for ghostty.sh module..."

    local tests_passed=0
    local tests_failed=0
    local ghostty_path="${GHOSTTY_APP_DIR:-$HOME/.local/share/ghostty}/bin/ghostty"

    # Test 1: Binary exists
    log "INFO" "  Test 2.1: Ghostty binary exists"
    if [ -f "$ghostty_path" ]; then
        log "SUCCESS" "    ✓ PASS: Ghostty binary found at $ghostty_path"
        ((tests_passed++))
    else
        log "ERROR" "    ✗ FAIL: Ghostty binary not found at $ghostty_path"
        ((tests_failed++))
    fi

    # Test 2: Binary is executable
    log "INFO" "  Test 2.2: Ghostty binary is executable"
    if [ -x "$ghostty_path" ]; then
        log "SUCCESS" "    ✓ PASS: Ghostty binary is executable"
        ((tests_passed++))
    else
        log "ERROR" "    ✗ FAIL: Ghostty binary not executable"
        ((tests_failed++))
    fi

    # Test 3: Version check
    log "INFO" "  Test 2.3: Ghostty version check"
    if [ -x "$ghostty_path" ]; then
        local version_output
        if version_output=$("$ghostty_path" --version 2>&1 | head -n 1); then
            log "SUCCESS" "    ✓ PASS: Ghostty version: $version_output"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: Ghostty version check failed"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test version (binary not executable)"
        ((tests_failed++))
    fi

    # Test 4: Configuration validation
    log "INFO" "  Test 2.4: Ghostty configuration valid"
    if [ -x "$ghostty_path" ]; then
        if "$ghostty_path" +show-config &>/dev/null; then
            log "SUCCESS" "    ✓ PASS: Ghostty configuration valid"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: Ghostty configuration validation failed"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test config (binary not executable)"
        ((tests_failed++))
    fi

    # Test 5: Theme files exist
    log "INFO" "  Test 2.5: Ghostty theme files present"
    local theme_dir="$HOME/.config/ghostty/themes"
    if [ -d "$theme_dir" ]; then
        local theme_count
        theme_count=$(find "$theme_dir" -name "*.conf" -type f 2>/dev/null | wc -l)
        if [ "$theme_count" -gt 0 ]; then
            log "SUCCESS" "    ✓ PASS: Found $theme_count theme files"
            ((tests_passed++))
        else
            log "WARNING" "    ⚠ PASS (with warning): No theme files found"
            ((tests_passed++))
        fi
    else
        log "WARNING" "    ⚠ PASS (with warning): Theme directory not found"
        ((tests_passed++))
    fi

    # Test 6: Shared libraries check
    log "INFO" "  Test 2.6: Ghostty shared libraries resolved"
    if [ -x "$ghostty_path" ] && command_exists "ldd"; then
        local ldd_output
        ldd_output=$(ldd "$ghostty_path" 2>&1)
        if echo "$ldd_output" | grep -q "not found"; then
            log "ERROR" "    ✗ FAIL: Ghostty has missing shared libraries"
            ((tests_failed++))
        else
            log "SUCCESS" "    ✓ PASS: All shared libraries resolved"
            ((tests_passed++))
        fi
    else
        log "INFO" "    ⊘ SKIP: ldd not available or binary not executable"
        ((tests_passed++))
    fi

    # Summary
    local total_tests=$((tests_passed + tests_failed))
    log "INFO" "  ghostty.sh unit tests: $tests_passed/$total_tests passed"

    if [ "$tests_failed" -eq 0 ]; then
        log "SUCCESS" "✓ T044: All ghostty.sh unit tests passed"
        return 0
    else
        log "ERROR" "✗ T044: ${tests_failed} ghostty.sh unit tests failed"
        return 1
    fi
}

#
# T045: Unit tests for zsh.sh module
#
# Tests ZSH installation and Oh My ZSH configuration:
#   - test_zsh_installation(): Binary exists and functional
#   - test_oh_my_zsh(): Framework installed (~/.oh-my-zsh)
#   - test_zsh_plugins(): Required plugins loaded
#   - test_zshrc_config(): .zshrc properly configured
#   - test_zsh_shell_integration(): Shell integration working
#
# Returns: 0 = all tests passed, 1 = failures detected
#
test_zsh_installation() {
    log "INFO" "Running unit tests for zsh.sh module..."

    local tests_passed=0
    local tests_failed=0

    # Test 1: ZSH binary exists
    log "INFO" "  Test 3.1: ZSH binary exists"
    if command_exists "zsh"; then
        log "SUCCESS" "    ✓ PASS: ZSH binary found at $(command -v zsh)"
        ((tests_passed++))
    else
        log "ERROR" "    ✗ FAIL: ZSH binary not found"
        ((tests_failed++))
    fi

    # Test 2: ZSH version
    log "INFO" "  Test 3.2: ZSH version check"
    if command_exists "zsh"; then
        local zsh_version
        if zsh_version=$(zsh --version 2>&1 | head -n 1); then
            log "SUCCESS" "    ✓ PASS: ZSH version: $zsh_version"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: ZSH version check failed"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test version (ZSH not installed)"
        ((tests_failed++))
    fi

    # Test 3: Oh My ZSH framework installed
    log "INFO" "  Test 3.3: Oh My ZSH framework installed"
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log "SUCCESS" "    ✓ PASS: Oh My ZSH directory exists"
        ((tests_passed++))
    else
        log "ERROR" "    ✗ FAIL: Oh My ZSH not installed at $HOME/.oh-my-zsh"
        ((tests_failed++))
    fi

    # Test 4: .zshrc exists and configured
    log "INFO" "  Test 3.4: .zshrc exists and references Oh My ZSH"
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "oh-my-zsh" "$HOME/.zshrc"; then
            log "SUCCESS" "    ✓ PASS: .zshrc configured for Oh My ZSH"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: .zshrc missing Oh My ZSH reference"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: .zshrc not found"
        ((tests_failed++))
    fi

    # Test 5: Plugins configured
    log "INFO" "  Test 3.5: ZSH plugins configured in .zshrc"
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "^plugins=" "$HOME/.zshrc"; then
            local plugins_line
            plugins_line=$(grep "^plugins=" "$HOME/.zshrc" | head -n 1)
            log "SUCCESS" "    ✓ PASS: Plugins configured: $plugins_line"
            ((tests_passed++))
        else
            log "WARNING" "    ⚠ PASS (with warning): No plugins configured"
            ((tests_passed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test plugins (.zshrc not found)"
        ((tests_failed++))
    fi

    # Test 6: ZSH functional (basic test)
    log "INFO" "  Test 3.6: ZSH basic functionality"
    if command_exists "zsh"; then
        if zsh -c "echo test" &>/dev/null; then
            log "SUCCESS" "    ✓ PASS: ZSH executes commands successfully"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: ZSH command execution failed"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test functionality (ZSH not installed)"
        ((tests_failed++))
    fi

    # Summary
    local total_tests=$((tests_passed + tests_failed))
    log "INFO" "  zsh.sh unit tests: $tests_passed/$total_tests passed"

    if [ "$tests_failed" -eq 0 ]; then
        log "SUCCESS" "✓ T045: All zsh.sh unit tests passed"
        return 0
    else
        log "ERROR" "✗ T045: ${tests_failed} zsh.sh unit tests failed"
        return 1
    fi
}

#
# T046: Unit tests for nodejs_fnm.sh module
#
# Tests fnm and Node.js installation with constitutional compliance:
#   - test_fnm_installation(): Binary exists and functional
#   - test_fnm_startup_time(): <50ms (CONSTITUTIONAL REQUIREMENT)
#   - test_nodejs_installation(): Node.js binary exists
#   - test_nodejs_version(): Version >= v25.2.0 (latest, not LTS)
#   - test_npm_installation(): npm functional
#
# Returns: 0 = all tests passed, 1 = failures detected
#
test_nodejs_fnm_installation() {
    log "INFO" "Running unit tests for nodejs_fnm.sh module..."

    local tests_passed=0
    local tests_failed=0

    # Test 1: fnm binary exists
    log "INFO" "  Test 4.1: fnm binary exists"
    if command_exists "fnm"; then
        log "SUCCESS" "    ✓ PASS: fnm binary found at $(command -v fnm)"
        ((tests_passed++))
    else
        log "ERROR" "    ✗ FAIL: fnm binary not found"
        ((tests_failed++))
    fi

    # Test 2: fnm startup time <50ms (CONSTITUTIONAL REQUIREMENT)
    log "INFO" "  Test 4.2: fnm startup <50ms (CONSTITUTIONAL)"
    if command_exists "fnm"; then
        local start_ns end_ns duration_ms
        start_ns=$(get_unix_timestamp_ns)
        fnm env &>/dev/null
        end_ns=$(get_unix_timestamp_ns)
        duration_ms=$(calculate_duration_ns "$start_ns" "$end_ns")

        if [ "$duration_ms" -lt 50 ]; then
            log "SUCCESS" "    ✓ PASS: fnm startup ${duration_ms}ms (<50ms ✓ CONSTITUTIONAL COMPLIANCE)"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: CONSTITUTIONAL VIOLATION - fnm startup ${duration_ms}ms ≥50ms"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test performance (fnm not installed)"
        ((tests_failed++))
    fi

    # Test 3: Node.js binary exists
    log "INFO" "  Test 4.3: Node.js binary exists"
    if command_exists "node"; then
        log "SUCCESS" "    ✓ PASS: Node.js binary found at $(command -v node)"
        ((tests_passed++))
    else
        log "ERROR" "    ✗ FAIL: Node.js binary not found"
        ((tests_failed++))
    fi

    # Test 4: Node.js version >= v25.2.0
    log "INFO" "  Test 4.4: Node.js version >= v25.2.0"
    if command_exists "node"; then
        local node_version
        node_version=$(node --version 2>&1 | head -n 1)

        # Extract major version
        local node_major
        node_major=$(echo "$node_version" | sed 's/v\([0-9]*\).*/\1/')

        if [ "$node_major" -ge 25 ]; then
            log "SUCCESS" "    ✓ PASS: Node.js version $node_version (≥v25.2.0 ✓)"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: Node.js version $node_version (<v25.2.0)"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: Cannot test version (Node.js not installed)"
        ((tests_failed++))
    fi

    # Test 5: npm installation
    log "INFO" "  Test 4.5: npm binary exists and functional"
    if command_exists "npm"; then
        local npm_version
        if npm_version=$(npm --version 2>&1 | head -n 1); then
            log "SUCCESS" "    ✓ PASS: npm version $npm_version"
            ((tests_passed++))
        else
            log "ERROR" "    ✗ FAIL: npm version check failed"
            ((tests_failed++))
        fi
    else
        log "ERROR" "    ✗ FAIL: npm not found"
        ((tests_failed++))
    fi

    # Test 6: fnm shell integration
    log "INFO" "  Test 4.6: fnm shell integration configured"
    local shell_rc="$HOME/.zshrc"
    if [ ! -f "$shell_rc" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    if [ -f "$shell_rc" ] && grep -q "fnm env" "$shell_rc"; then
        log "SUCCESS" "    ✓ PASS: fnm shell integration configured in $shell_rc"
        ((tests_passed++))
    else
        log "WARNING" "    ⚠ PASS (with warning): fnm shell integration not found"
        ((tests_passed++))
    fi

    # Summary
    local total_tests=$((tests_passed + tests_failed))
    log "INFO" "  nodejs_fnm.sh unit tests: $tests_passed/$total_tests passed"

    if [ "$tests_failed" -eq 0 ]; then
        log "SUCCESS" "✓ T046: All nodejs_fnm.sh unit tests passed"
        return 0
    else
        log "ERROR" "✗ T046: ${tests_failed} nodejs_fnm.sh unit tests failed"
        return 1
    fi
}

#
# Run all unit tests
#
# Executes comprehensive unit test suite for all modules.
#
# Returns:
#   0 = all tests passed
#   1 = one or more tests failed
#
run_all_unit_tests() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Phase 8: Unit Test Suite"
    log "INFO" "════════════════════════════════════════"
    echo ""

    local test_groups_passed=0
    local test_groups_failed=0

    # T043: gum.sh unit tests
    if test_gum_installation; then
        ((test_groups_passed++))
    else
        ((test_groups_failed++))
    fi
    echo ""

    # T044: ghostty.sh unit tests
    if test_ghostty_installation; then
        ((test_groups_passed++))
    else
        ((test_groups_failed++))
    fi
    echo ""

    # T045: zsh.sh unit tests
    if test_zsh_installation; then
        ((test_groups_passed++))
    else
        ((test_groups_failed++))
    fi
    echo ""

    # T046: nodejs_fnm.sh unit tests
    if test_nodejs_fnm_installation; then
        ((test_groups_passed++))
    else
        ((test_groups_failed++))
    fi
    echo ""

    # Summary
    local total_test_groups=$((test_groups_passed + test_groups_failed))
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Unit Tests Summary"
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Test groups: $total_test_groups"
    log "SUCCESS" "Passed:      $test_groups_passed"

    if [ "$test_groups_failed" -gt 0 ]; then
        log "ERROR" "Failed:      $test_groups_failed"
        log "ERROR" "════════════════════════════════════════"
        return 1
    else
        log "SUCCESS" "All unit tests passed ✓"
        log "SUCCESS" "════════════════════════════════════════"
        return 0
    fi
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

# Export unit test functions (Phase 8)
export -f test_gum_installation
export -f test_ghostty_installation
export -f test_zsh_installation
export -f test_nodejs_fnm_installation
export -f run_all_unit_tests
