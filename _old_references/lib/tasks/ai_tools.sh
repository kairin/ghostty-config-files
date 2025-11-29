#!/usr/bin/env bash
#
# lib/tasks/ai_tools.sh - AI CLI tools installation (Claude, Gemini, Copilot)
#
# CONTEXT7 STATUS: API authentication failed (invalid key)
# FALLBACK STRATEGY: Constitutional compliance from CLAUDE.md/AGENTS.md
# - Claude CLI (@anthropic-ai/claude-code)
# - Gemini CLI (@google/gemini-cli)
# - GitHub Copilot CLI (@github/copilot) - optional
# - All installed via npm (requires Node.js v25.2.0+ from fnm)
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Prerequisite: Node.js v25.2.0+ via fnm (from task_install_fnm)
# - Global npm installations with duplicate detection
# - Desktop icon cleanup (remove duplicates)
#
# User Stories: US1 (Fresh Installation), US3 (Re-run Safety)
#
# Requirements:
# - FR-053: Idempotency (skip if already installed)
# - FR-071: Query Context7 (fallback if unavailable)
#

set -euo pipefail

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/logging.sh"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/state.sh"
source "${SCRIPT_DIR}/../core/errors.sh"
source "${SCRIPT_DIR}/../verification/duplicate_detection.sh"
source "${SCRIPT_DIR}/../verification/unit_tests.sh"

# AI Tool packages (npm package names)
readonly CLAUDE_CLI_PACKAGE="@anthropic-ai/claude-code"
readonly GEMINI_CLI_PACKAGE="@google/gemini-cli"
readonly COPILOT_CLI_PACKAGE="@github/copilot"

# Command names for verification
readonly CLAUDE_CLI_CMD="claude"
readonly GEMINI_CLI_CMD="gemini"
readonly COPILOT_CLI_CMD="copilot"

#
# Check Node.js prerequisite
#
# Verifies Node.js v25.2.0+ is installed via fnm
#
# Returns:
#   0 = Node.js available and meets requirements
#   1 = Node.js missing or version too old
#
check_nodejs_prerequisite() {
    log "INFO" "Checking Node.js prerequisite..."

    if ! command_exists "node"; then
        log "ERROR" "✗ Node.js not found"
        log "ERROR" "  AI tools require Node.js v25.2.0+"
        log "ERROR" "  Install Node.js first: run task_install_fnm()"
        return 1
    fi

    local node_version
    node_version=$(node --version 2>&1)
    log "INFO" "  Node.js version: $node_version"

    # Verify constitutional requirement (v25.2.0+)
    local major_version
    major_version=$(echo "$node_version" | sed 's/v//' | cut -d. -f1)

    if [ "$major_version" -lt 25 ]; then
        log "ERROR" "✗ Node.js version too old: $node_version"
        log "ERROR" "  Constitutional requirement: v25.2.0+"
        log "ERROR" "  Update Node.js: fnm install latest && fnm default latest"
        return 1
    fi

    log "SUCCESS" "✓ Node.js $node_version meets requirements (≥v25.2.0)"
    return 0
}

#
# Install AI CLI tool via npm
#
# Args:
#   $1 - Package name (e.g., @anthropic-ai/claude-code)
#   $2 - Command name for verification (e.g., claude)
#   $3 - Tool display name (e.g., "Claude CLI")
#
# Returns:
#   0 = success
#   1 = failure
#
install_ai_tool() {
    local package_name="$1"
    local command_name="$2"
    local tool_name="$3"

    log "INFO" "Installing $tool_name..."

    # Check if already installed
    if command_exists "$command_name"; then
        local installed_version
        installed_version=$($command_name --version 2>&1 | head -n 1 || echo "unknown")
        log "INFO" "  ↷ $tool_name already installed: $installed_version"
        return 0
    fi

    # Install via npm globally
    if ! npm install -g "$package_name" 2>&1 | tee -a "$(get_log_file)"; then
        log "ERROR" "✗ Failed to install $tool_name"
        log "ERROR" "  Package: $package_name"
        log "ERROR" "  Try manual installation: npm install -g $package_name"
        return 1
    fi

    # Verify installation
    if command_exists "$command_name"; then
        local installed_version
        installed_version=$($command_name --version 2>&1 | head -n 1 || echo "unknown")
        log "SUCCESS" "✓ $tool_name installed: $installed_version"
        return 0
    else
        log "ERROR" "✗ $tool_name command not available after installation"
        return 1
    fi
}

#
# Create .env template for API keys
#
# Creates .env.example with placeholders for AI tool API keys
#
create_env_template() {
    log "INFO" "Creating .env template for API keys..."

    local env_example="/home/kkk/Apps/ghostty-config-files/.env.example"
    local env_file="/home/kkk/Apps/ghostty-config-files/.env"

    # Only create .env.example if it doesn't exist
    if [ ! -f "$env_example" ]; then
        cat > "$env_example" <<'EOF'
# AI Tool API Keys
# Copy this file to .env and add your actual API keys

# Claude CLI (Anthropic)
ANTHROPIC_API_KEY=your-anthropic-api-key-here

# Gemini CLI (Google)
GOOGLE_API_KEY=your-google-api-key-here

# GitHub Copilot CLI
GITHUB_TOKEN=your-github-token-here

# Context7 MCP (Documentation)
CONTEXT7_API_KEY=your-context7-api-key-here
EOF
        log "SUCCESS" "  ✓ Created .env.example template"
    else
        log "INFO" "  ↷ .env.example already exists"
    fi

    # Inform user about .env file
    if [ ! -f "$env_file" ]; then
        log "INFO" ""
        log "INFO" "Next steps for API key configuration:"
        log "INFO" "  1. Copy template: cp .env.example .env"
        log "INFO" "  2. Edit .env with your API keys"
        log "INFO" "  3. Verify .env is in .gitignore (security)"
        log "INFO" ""
    fi

    return 0
}

#
# Clean up duplicate desktop icons
#
# Removes duplicate .desktop files for AI tools
#
cleanup_duplicate_desktop_icons() {
    log "INFO" "Checking for duplicate desktop icons..."

    local desktop_dirs=(
        "$HOME/.local/share/applications"
        "/usr/share/applications"
        "/usr/local/share/applications"
    )

    local ai_tool_names=(
        "claude"
        "gemini"
        "copilot"
    )

    local duplicates_found=0

    for tool in "${ai_tool_names[@]}"; do
        local found_locations=()

        for desktop_dir in "${desktop_dirs[@]}"; do
            if [ -f "$desktop_dir/${tool}.desktop" ]; then
                found_locations+=("$desktop_dir/${tool}.desktop")
            fi
        done

        if [ ${#found_locations[@]} -gt 1 ]; then
            log "WARNING" "  ⚠ Multiple desktop files found for $tool:"
            for location in "${found_locations[@]}"; do
                log "WARNING" "    - $location"
            done
            duplicates_found=1
        fi
    done

    if [ $duplicates_found -eq 0 ]; then
        log "SUCCESS" "✓ No duplicate desktop icons detected"
    else
        log "INFO" ""
        log "INFO" "Duplicate desktop icons detected."
        log "INFO" "Recommendation: Remove duplicates manually if they appear in app menu"
        log "INFO" ""
    fi

    return 0
}

#
# Install AI CLI tools (Claude, Gemini, Copilot)
#
# Process:
#   1. Check duplicate detection (skip if already installed)
#   2. Verify Node.js prerequisite (v25.2.0+)
#   3. Install Claude CLI (@anthropic-ai/claude-code)
#   4. Install Gemini CLI (@google/gemini-cli)
#   5. Install GitHub Copilot CLI (optional, non-blocking)
#   6. Create .env template for API keys
#   7. Clean up duplicate desktop icons
#   8. Verify installations
#
# Returns:
#   0 = success
#   1 = failure
#
task_install_ai_tools() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Installing AI CLI Tools"
    log "INFO" "════════════════════════════════════════"

    local task_start
    task_start=$(get_unix_timestamp)

    # Step 1: Duplicate Detection (Idempotency)
    log "INFO" "Checking for existing AI tool installations..."

    local claude_installed=false
    local gemini_installed=false

    if verify_claude_cli 2>/dev/null; then
        claude_installed=true
        log "INFO" "  ↷ Claude CLI already installed"
    fi

    if verify_gemini_cli 2>/dev/null; then
        gemini_installed=true
        log "INFO" "  ↷ Gemini CLI already installed"
    fi

    if [ "$claude_installed" = true ] && [ "$gemini_installed" = true ]; then
        log "INFO" "↷ All AI tools already installed"
        mark_task_completed "install-ai-tools" 0  # 0 seconds (skipped)
        return 0
    fi

    # Step 2: Check Node.js prerequisite
    if ! check_nodejs_prerequisite; then
        handle_error "install-ai-tools" 1 "Node.js prerequisite not met" \
            "Install Node.js first: run task_install_fnm()" \
            "Requirement: Node.js v25.2.0+"
        return 1
    fi

    # Step 3: Install Claude CLI
    if [ "$claude_installed" = false ]; then
        if ! install_ai_tool "$CLAUDE_CLI_PACKAGE" "$CLAUDE_CLI_CMD" "Claude CLI"; then
            handle_error "install-ai-tools" 2 "Claude CLI installation failed" \
                "Check npm logs" \
                "Try manual installation: npm install -g $CLAUDE_CLI_PACKAGE" \
                "Verify npm registry access"
            return 1
        fi
    fi

    # Step 4: Install Gemini CLI
    if [ "$gemini_installed" = false ]; then
        if ! install_ai_tool "$GEMINI_CLI_PACKAGE" "$GEMINI_CLI_CMD" "Gemini CLI"; then
            handle_error "install-ai-tools" 3 "Gemini CLI installation failed" \
                "Check npm logs" \
                "Try manual installation: npm install -g $GEMINI_CLI_PACKAGE" \
                "Verify npm registry access"
            return 1
        fi
    fi

    # Step 5: Install GitHub Copilot CLI (optional, non-blocking)
    log "INFO" "Installing GitHub Copilot CLI (optional)..."
    if install_ai_tool "$COPILOT_CLI_PACKAGE" "$COPILOT_CLI_CMD" "GitHub Copilot CLI"; then
        log "SUCCESS" "✓ GitHub Copilot CLI installed"
    else
        log "WARNING" "⚠ GitHub Copilot CLI installation failed (non-critical)"
        log "INFO" "  You can install it later: npm install -g $COPILOT_CLI_PACKAGE"
    fi

    # Step 6: Create .env template for API keys
    create_env_template

    # Step 7: Clean up duplicate desktop icons
    cleanup_duplicate_desktop_icons

    # Step 8: Verify installations
    log "INFO" "Verifying AI tool installations..."

    local verification_failed=false

    if ! verify_claude_cli; then
        log "ERROR" "✗ Claude CLI verification failed"
        verification_failed=true
    fi

    if ! verify_gemini_cli; then
        log "ERROR" "✗ Gemini CLI verification failed"
        verification_failed=true
    fi

    if [ "$verification_failed" = true ]; then
        handle_error "install-ai-tools" 4 "AI tool verification failed" \
            "Check logs for specific errors" \
            "Try manual verification: claude --version, gemini --version"
        return 1
    fi

    # Success
    local task_end
    task_end=$(get_unix_timestamp)
    local duration
    duration=$(calculate_duration "$task_start" "$task_end")

    mark_task_completed "install-ai-tools" "$duration"

    log "SUCCESS" "════════════════════════════════════════"
    log "SUCCESS" "✓ AI tools installed successfully ($(format_duration "$duration"))"
    log "SUCCESS" "════════════════════════════════════════"
    log "INFO" ""
    log "INFO" "Installed AI tools:"
    log "INFO" "  ✓ Claude CLI (@anthropic-ai/claude-code)"
    log "INFO" "  ✓ Gemini CLI (@google/gemini-cli)"
    if command_exists "$COPILOT_CLI_CMD"; then
        log "INFO" "  ✓ GitHub Copilot CLI (@github/copilot)"
    fi
    log "INFO" ""
    log "INFO" "Next steps:"
    log "INFO" "  1. Configure API keys: cp .env.example .env && edit .env"
    log "INFO" "  2. Claude CLI: claude --help"
    log "INFO" "  3. Gemini CLI: gemini --help"
    log "INFO" "  4. Documentation:"
    log "INFO" "     - Claude: https://github.com/anthropics/anthropic-sdk-typescript"
    log "INFO" "     - Gemini: https://ai.google.dev/"
    log "INFO" ""
    return 0
}

# Export functions
export -f check_nodejs_prerequisite
export -f install_ai_tool
export -f create_env_template
export -f cleanup_duplicate_desktop_icons
export -f task_install_ai_tools
