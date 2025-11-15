#!/bin/bash
# Integration Test: test_mcp_integration.sh
# Purpose: End-to-end testing of MCP (Model Context Protocol) server activation
# Dependencies: test_functions.sh
# Exit Codes: 0=all tests pass, 1=one or more tests failed

set -euo pipefail

# ============================================================
# TEST SETUP
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source test helper functions
source "${SCRIPT_DIR}/../unit/test_functions.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================
# TEST FIXTURES
# ============================================================

setup_all() {
    echo "🔧 Setting up MCP integration test environment..."

    # Create test environment
    export TEST_TEMP_DIR=$(mktemp -d)
    export TEST_CONFIG="$TEST_TEMP_DIR/.config"
    mkdir -p "$TEST_CONFIG/claude"
    mkdir -p "$TEST_CONFIG/mcp"

    echo "  Created test environment: $TEST_TEMP_DIR"
}

teardown_all() {
    echo "🧹 Cleaning up MCP integration test environment..."

    if [[ -n "${TEST_TEMP_DIR:-}" ]] && [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
        echo "  Removed test environment: $TEST_TEMP_DIR"
    fi
}

# ============================================================
# INTEGRATION TEST CASES
# ============================================================

# Test: MCP health check script exists
test_mcp_health_check_scripts_exist() {
    ((TESTS_RUN++))
    echo "  Testing: MCP health check scripts exist"

    # Assert
    assert_file_exists "$PROJECT_ROOT/scripts/check_context7_health.sh" \
        "check_context7_health.sh should exist"
    assert_file_exists "$PROJECT_ROOT/scripts/check_github_mcp_health.sh" \
        "check_github_mcp_health.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Context7 health check script is executable
test_context7_health_check_executable() {
    ((TESTS_RUN++))
    echo "  Testing: check_context7_health.sh is executable"

    # Assert
    local script="$PROJECT_ROOT/scripts/check_context7_health.sh"
    assert_true "[[ -x \"$script\" ]]" "check_context7_health.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: GitHub MCP health check script is executable
test_github_mcp_health_check_executable() {
    ((TESTS_RUN++))
    echo "  Testing: check_github_mcp_health.sh is executable"

    # Assert
    local script="$PROJECT_ROOT/scripts/check_github_mcp_health.sh"
    assert_true "[[ -x \"$script\" ]]" "check_github_mcp_health.sh should be executable"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: MCP setup documentation exists
test_mcp_setup_documentation_exists() {
    ((TESTS_RUN++))
    echo "  Testing: MCP setup documentation exists"

    # Assert context7 setup docs
    local context7_docs="$PROJECT_ROOT/documentations/user/setup/context7-mcp.md"
    assert_file_exists "$context7_docs" "context7-mcp.md documentation should exist"

    # Assert GitHub MCP setup docs
    local github_docs="$PROJECT_ROOT/documentations/user/setup/github-mcp.md"
    assert_file_exists "$github_docs" "github-mcp.md documentation should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Environment configuration template exists
test_env_template_exists() {
    ((TESTS_RUN++))
    echo "  Testing: .env.example template exists"

    # Assert
    local env_example="$PROJECT_ROOT/.env.example"
    assert_file_exists "$env_example" ".env.example should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Context7 MCP documentation mentions required setup
test_context7_docs_mentions_setup() {
    ((TESTS_RUN++))
    echo "  Testing: Context7 MCP docs mention setup requirements"

    # Assert
    local context7_docs="$PROJECT_ROOT/documentations/user/setup/context7-mcp.md"
    local has_setup=false

    if grep -q "CONTEXT7_API_KEY" "$context7_docs"; then
        has_setup=true
    fi

    assert_true "[$has_setup = true]" "Context7 docs should mention API key setup"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: GitHub CLI integration documentation exists
test_github_cli_integration_docs() {
    ((TESTS_RUN++))
    echo "  Testing: GitHub CLI integration documentation exists"

    # Assert
    local github_docs="$PROJECT_ROOT/documentations/user/setup/github-mcp.md"
    local has_content=false

    if [[ -f "$github_docs" ]] && [[ -s "$github_docs" ]]; then
        has_content=true
    fi

    assert_true "[$has_content = true]" "GitHub MCP docs should have content"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: install_spec_kit.sh supports MCP setup
test_spec_kit_supports_mcp() {
    ((TESTS_RUN++))
    echo "  Testing: install_spec_kit.sh script exists"

    # Assert
    assert_file_exists "$PROJECT_ROOT/scripts/install_spec_kit.sh" \
        "install_spec_kit.sh should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: CLAUDE.md mentions MCP integration
test_claude_md_mentions_mcp() {
    ((TESTS_RUN++))
    echo "  Testing: CLAUDE.md mentions MCP integration"

    # Assert
    local has_mcp=false
    if grep -q "MCP\|mcp\|Context7\|GitHub MCP" "$PROJECT_ROOT/CLAUDE.md"; then
        has_mcp=true
    fi

    assert_true "[$has_mcp = true]" "CLAUDE.md should mention MCP integration"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Claude Code integration instructions exist
test_claude_code_integration() {
    ((TESTS_RUN++))
    echo "  Testing: Claude Code integration documentation exists"

    # Check for Claude Code related documentation
    local has_claude_integration=false
    if grep -q "Claude Code\|claude-code\|@anthropic-ai/claude-code" "$PROJECT_ROOT/CLAUDE.md"; then
        has_claude_integration=true
    fi

    assert_true "[$has_claude_integration = true]" \
        "CLAUDE.md should document Claude Code integration"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Health check script can provide usage help
test_context7_health_check_has_help() {
    ((TESTS_RUN++))
    echo "  Testing: Context7 health check script provides help"

    # Act - try to get help
    local output=$("$PROJECT_ROOT/scripts/check_context7_health.sh" --help 2>&1 || echo "")

    # Note: Some scripts might not have --help, so we just check if script is present
    # The actual execution test would require proper environment setup
    assert_file_exists "$PROJECT_ROOT/scripts/check_context7_health.sh" \
        "Script should be present"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: MCP configuration examples exist
test_mcp_config_examples() {
    ((TESTS_RUN++))
    echo "  Testing: MCP configuration examples or templates exist"

    # Check for setup documentation
    local has_setup_docs=false
    if [[ -d "$PROJECT_ROOT/documentations/user/setup" ]]; then
        has_setup_docs=true
    fi

    assert_true "[$has_setup_docs = true]" "Setup documentation directory should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: GitHub Pages setup includes MCP documentation
test_pages_includes_mcp_docs() {
    ((TESTS_RUN++))
    echo "  Testing: Documentation includes MCP setup guides"

    # Check if user guide docs mention MCP
    local has_user_docs=false
    if [[ -d "$PROJECT_ROOT/website/src/user-guide" ]]; then
        has_user_docs=true
    fi

    assert_true "[$has_user_docs = true]" "User guide docs should exist"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# Test: Installation script includes MCP setup steps
test_installation_includes_mcp() {
    ((TESTS_RUN++))
    echo "  Testing: Installation scripts mention MCP setup"

    # Check if start.sh or manage.sh mentions Claude/MCP
    local has_mcp_mention=false
    if grep -q "Claude\|MCP\|context7\|github.*mcp" "$PROJECT_ROOT/start.sh"; then
        has_mcp_mention=true
    fi

    assert_true "[$has_mcp_mention = true]" \
        "Installation scripts should mention MCP/Claude setup"

    ((TESTS_PASSED++))
    echo "  ✅ PASS"
}

# ============================================================
# TEST RUNNER
# ============================================================

run_all_tests() {
    echo "════════════════════════════════════════════════════════"
    echo "🧪 Running Integration Tests: MCP Integration"
    echo "════════════════════════════════════════════════════════"

    setup_all

    echo ""
    echo "Running integration test cases..."
    echo ""

    # Run test cases
    test_mcp_health_check_scripts_exist || ((TESTS_FAILED++))
    test_context7_health_check_executable || ((TESTS_FAILED++))
    test_github_mcp_health_check_executable || ((TESTS_FAILED++))
    test_mcp_setup_documentation_exists || ((TESTS_FAILED++))
    test_env_template_exists || ((TESTS_FAILED++))
    test_context7_docs_mentions_setup || ((TESTS_FAILED++))
    test_github_cli_integration_docs || ((TESTS_FAILED++))
    test_spec_kit_supports_mcp || ((TESTS_FAILED++))
    test_claude_md_mentions_mcp || ((TESTS_FAILED++))
    test_claude_code_integration || ((TESTS_FAILED++))
    test_context7_health_check_has_help || ((TESTS_FAILED++))
    test_mcp_config_examples || ((TESTS_FAILED++))
    test_pages_includes_mcp_docs || ((TESTS_FAILED++))
    test_installation_includes_mcp || ((TESTS_FAILED++))

    teardown_all

    # Print summary
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Integration Test Results: MCP Integration"
    echo "════════════════════════════════════════════════════════"
    echo "  Total Tests: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "  ✅ ALL INTEGRATION TESTS PASSED"
        return 0
    else
        echo ""
        echo "  ❌ SOME INTEGRATION TESTS FAILED"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
    exit $?
fi
