#!/usr/bin/env bash
# lib/verification/tests/ai-nodejs-test.sh - AI tools + Node.js integration test
# Tests AI CLI tools (Claude, Gemini) work with installed Node.js

set -euo pipefail

[ -z "${AI_NODEJS_TEST_LOADED:-}" ] || return 0
AI_NODEJS_TEST_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../core/logging.sh" 2>/dev/null || true
source "${SCRIPT_DIR}/../../core/utils.sh" 2>/dev/null || true

# Fallback log function
log() { local level="$1"; shift; echo "[$level] $*"; }
command_exists() { command -v "$1" &>/dev/null; }

test_ai_tools_nodejs_integration() {
    log "INFO" "Testing AI tools + Node.js integration..."

    # Check 1: Node.js installed
    if ! command_exists "node"; then
        log "ERROR" "Node.js not installed - AI tools cannot work"
        return 1
    fi

    local node_version
    node_version=$(node --version 2>&1 | head -n 1)
    log "INFO" "  Node.js: $node_version"

    # Check 2: npm available
    if ! command_exists "npm"; then
        log "ERROR" "npm not available - cannot verify AI tool installation"
        return 1
    fi

    # Check 3: Check if AI tools are npm global packages
    local claude_installed=false
    local gemini_installed=false

    if command_exists "claude"; then
        local claude_path
        claude_path=$(command -v claude)
        if [[ "$claude_path" == *"node_modules"* ]] || npm list -g @anthropic-ai/claude-code &>/dev/null 2>&1; then
            log "INFO" "  Claude CLI installed via npm"
            claude_installed=true
        fi
    fi

    if command_exists "gemini"; then
        local gemini_path
        gemini_path=$(command -v gemini)
        if [[ "$gemini_path" == *"node_modules"* ]] || npm list -g @google/gemini-cli &>/dev/null 2>&1; then
            log "INFO" "  Gemini CLI installed via npm"
            gemini_installed=true
        fi
    fi

    # Check 4: At least one AI tool working
    if ! $claude_installed && ! $gemini_installed; then
        log "ERROR" "No AI tools installed via npm"
        return 1
    fi

    log "SUCCESS" "AI tools + Node.js integration working"
    return 0
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_ai_tools_nodejs_integration
    exit $?
fi

export -f test_ai_tools_nodejs_integration
