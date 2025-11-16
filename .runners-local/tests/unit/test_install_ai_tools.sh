#!/bin/bash
# Unit tests for scripts/install_ai_tools.sh
# Constitutional requirement: <10s execution time
# Test coverage: Module loading, function existence, package names, verification logic

set -euo pipefail

# Test framework setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

# Source module for testing
source "${PROJECT_ROOT}/scripts/install_ai_tools.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# TEST HELPER FUNCTIONS
# ============================================================

# Helper: assert_equals
# Purpose: Assert two values are equal
# Args: $1=expected, $2=actual, $3=test_name
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$expected" == "$actual" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper: assert_command_exists
# Purpose: Assert command is in PATH
# Args: $1=command_name, $2=test_name
assert_command_exists() {
    local command_name="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if command -v "$command_name" &> /dev/null; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "ℹ SKIP: $test_name (command not found: $command_name)"
    fi
}

# Helper: assert_function_exists
# Purpose: Assert function is defined
# Args: $1=function_name, $2=test_name
assert_function_exists() {
    local function_name="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if declare -f "$function_name" &> /dev/null; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name (function not found: $function_name)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper: assert_file_exists
# Purpose: Assert file exists
# Args: $1=file_path, $2=test_name
assert_file_exists() {
    local file_path="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -f "$file_path" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "ℹ SKIP: $test_name (file not found: $file_path)"
    fi
}

# Helper: assert_not_empty
# Purpose: Assert string is not empty
# Args: $1=value, $2=test_name
assert_not_empty() {
    local value="$1"
    local test_name="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -n "$value" ]]; then
        echo "✓ PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: $test_name (value is empty)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================
# TEST SUITE
# ============================================================

echo "=== Unit Tests: install_ai_tools.sh ==="
echo "Project Root: ${PROJECT_ROOT}"
echo "Test Start: $(date)"
echo

# ============================================================
# GROUP 1: Module Loading and Guards
# ============================================================

echo "--- Group 1: Module Loading and Guards ---"

# Test 1.1: Module loaded successfully
assert_equals "1" "${INSTALL_AI_TOOLS_SH_LOADED}" "Module loaded with guard variable"

# Test 1.2: SOURCED_FOR_TESTING flag set
assert_equals "1" "${SOURCED_FOR_TESTING}" "SOURCED_FOR_TESTING flag set correctly"

# Test 1.3: SCRIPT_DIR variable set
assert_not_empty "${SCRIPT_DIR}" "SCRIPT_DIR variable is set"

echo

# ============================================================
# GROUP 2: Package Name Constants
# ============================================================

echo "--- Group 2: Package Name Constants ---"

# Test 2.1: Claude package name
assert_equals "@anthropic-ai/claude-code" "${CLAUDE_PACKAGE}" "Claude package name correct"

# Test 2.2: Gemini package name
assert_equals "@google/gemini-cli" "${GEMINI_PACKAGE}" "Gemini package name correct"

# Test 2.3: Copilot package name
assert_equals "@github/copilot" "${COPILOT_PACKAGE}" "Copilot package name correct"

# Test 2.4: zsh-codex package name
assert_equals "zsh-codex" "${ZSH_CODEX_PACKAGE}" "zsh-codex package name correct"

echo

# ============================================================
# GROUP 3: MCP Server Constants
# ============================================================

echo "--- Group 3: MCP Server Package Names ---"

# Test 3.1: MCP Filesystem package
assert_equals "@modelcontextprotocol/server-filesystem" "${MCP_FILESYSTEM}" "MCP Filesystem package name correct"

# Test 3.2: MCP GitHub package
assert_equals "@modelcontextprotocol/server-github" "${MCP_GITHUB}" "MCP GitHub package name correct"

# Test 3.3: MCP Git package
assert_equals "@modelcontextprotocol/server-git" "${MCP_GIT}" "MCP Git package name correct"

echo

# ============================================================
# GROUP 4: Configuration Paths
# ============================================================

echo "--- Group 4: Configuration Paths ---"

# Test 4.1: Claude config directory
assert_equals "${HOME}/.config/Claude" "${CLAUDE_CONFIG_DIR}" "Claude config directory path correct"

# Test 4.2: Claude config file
assert_equals "${HOME}/.config/Claude/claude_desktop_config.json" "${CLAUDE_CONFIG_FILE}" "Claude config file path correct"

# Test 4.3: AI context cache directory
assert_equals "${HOME}/.cache/ghostty-ai-context" "${AI_CONTEXT_CACHE_DIR}" "AI context cache directory path correct"

echo

# ============================================================
# GROUP 5: Public API Functions (AI CLI Tools)
# ============================================================

echo "--- Group 5: Public API Functions (AI CLI Tools) ---"

# Test 5.1-5.5: Main installation functions
for func in install_claude_code install_gemini_cli install_github_copilot install_zsh_codex install_ai_tools; do
    assert_function_exists "$func" "Function $func exists"
done

echo

# ============================================================
# GROUP 6: Public API Functions (MCP Servers)
# ============================================================

echo "--- Group 6: Public API Functions (MCP Servers) ---"

# Test 6.1-6.2: MCP installation functions
for func in install_claude_mcp_servers install_gemini_mcp_servers; do
    assert_function_exists "$func" "Function $func exists"
done

echo

# ============================================================
# GROUP 7: Public API Functions (Shell Integration)
# ============================================================

echo "--- Group 7: Public API Functions (Shell Integration) ---"

# Test 7.1: Shell alias configuration
assert_function_exists "configure_shell_aliases" "Function configure_shell_aliases exists"

# Test 7.2: Verification function
assert_function_exists "verify_ai_tools_installation" "Function verify_ai_tools_installation exists"

echo

# ============================================================
# GROUP 8: Private Helper Functions
# ============================================================

echo "--- Group 8: Private Helper Functions ---"

# Test 8.1-8.4: Private helper functions
for func in _check_npm_available _check_pip_available _npm_install_global _create_shell_backup; do
    assert_function_exists "$func" "Helper function $func exists"
done

echo

# ============================================================
# GROUP 9: Prerequisites Check
# ============================================================

echo "--- Group 9: Prerequisites Check ---"

# Test 9.1: npm availability
if command -v npm &> /dev/null; then
    assert_command_exists "npm" "npm available in PATH"
else
    echo "ℹ SKIP: npm not installed (expected on fresh system)"
fi

# Test 9.2: pip availability
if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
    if command -v pip &> /dev/null; then
        assert_command_exists "pip" "pip available in PATH"
    else
        assert_command_exists "pip3" "pip3 available in PATH"
    fi
else
    echo "ℹ SKIP: pip not installed (expected on fresh system)"
fi

echo

# ============================================================
# GROUP 10: AI Tools Binary Check (Optional)
# ============================================================

echo "--- Group 10: AI Tools Binary Check (Optional) ---"

# Test 10.1: Claude Code binary
if command -v claude &> /dev/null; then
    assert_command_exists "claude" "Claude Code binary available"
else
    echo "ℹ SKIP: Claude Code not installed (expected before module execution)"
fi

# Test 10.2: Gemini CLI binary
if command -v gemini &> /dev/null; then
    assert_command_exists "gemini" "Gemini CLI binary available"
else
    echo "ℹ SKIP: Gemini CLI not installed (expected before module execution)"
fi

# Test 10.3: GitHub Copilot binary
if command -v gh &> /dev/null && gh copilot --version &> /dev/null 2>&1; then
    echo "✓ PASS: GitHub Copilot CLI available"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "ℹ SKIP: GitHub Copilot CLI not installed (optional)"
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo

# ============================================================
# GROUP 11: Configuration Files Check (Optional)
# ============================================================

echo "--- Group 11: Configuration Files Check (Optional) ---"

# Test 11.1: Claude MCP config file
if [[ -f "$CLAUDE_CONFIG_FILE" ]]; then
    assert_file_exists "$CLAUDE_CONFIG_FILE" "Claude MCP config file exists"

    # Test 11.2: Validate JSON syntax
    TESTS_RUN=$((TESTS_RUN + 1))
    if jq empty "$CLAUDE_CONFIG_FILE" &> /dev/null; then
        echo "✓ PASS: Claude MCP config is valid JSON"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: Claude MCP config has invalid JSON"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo "ℹ SKIP: Claude MCP config not found (expected before module execution)"
fi

echo

# ============================================================
# GROUP 12: AI Context Script Check
# ============================================================

echo "--- Group 12: AI Context Script Check ---"

# Test 12.1: extract_ai_context.sh exists
AI_CONTEXT_SCRIPT="${PROJECT_ROOT}/scripts/extract_ai_context.sh"
if [[ -f "$AI_CONTEXT_SCRIPT" ]]; then
    assert_file_exists "$AI_CONTEXT_SCRIPT" "extract_ai_context.sh exists"

    # Test 12.2: Script is executable
    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -x "$AI_CONTEXT_SCRIPT" ]]; then
        echo "✓ PASS: extract_ai_context.sh is executable"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "✗ FAIL: extract_ai_context.sh is not executable"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo "ℹ SKIP: extract_ai_context.sh not found"
fi

echo

# ============================================================
# GROUP 13: Version Constants
# ============================================================

echo "--- Group 13: Minimum Version Constants ---"

# Test 13.1-13.4: Minimum version constants
assert_equals "0.1.0" "${MIN_CLAUDE_VERSION}" "Minimum Claude version constant correct"
assert_equals "0.1.0" "${MIN_GEMINI_VERSION}" "Minimum Gemini version constant correct"
assert_equals "0.1.0" "${MIN_COPILOT_VERSION}" "Minimum Copilot version constant correct"
assert_equals "2.12.3" "${MIN_FASTMCP_VERSION}" "Minimum FastMCP version constant correct"

echo

# ============================================================
# TEST SUMMARY
# ============================================================

echo "=== Test Summary ==="
echo "Total Tests: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Test End: $(date)"
echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
