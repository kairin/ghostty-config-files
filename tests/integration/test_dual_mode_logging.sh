#!/usr/bin/env bash
#
# tests/integration/test_dual_mode_logging.sh - Integration tests for dual-mode logging system
#
# Tests the complete dual-mode output system:
# - Terminal: Docker-like collapsed output (default)
# - Log files: Full verbose output (always)
#
# Usage:
#   ./tests/integration/test_dual_mode_logging.sh
#

set -euo pipefail

# Color codes for output
COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[0;33m"
COLOR_RESET="\033[0m"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

#
# Test helper functions
#
assert_true() {
    local condition="$1"
    local description="$2"

    ((TOTAL_TESTS++))

    if eval "$condition"; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} $description"
        ((PASSED_TESTS++))
        return 0
    else
        echo -e "${COLOR_RED}✗${COLOR_RESET} $description"
        ((FAILED_TESTS++))
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local description="$2"

    assert_true "[ -f '$file_path' ]" "$description"
}

assert_dir_exists() {
    local dir_path="$1"
    local description="$2"

    assert_true "[ -d '$dir_path' ]" "$description"
}

assert_contains() {
    local file_path="$1"
    local pattern="$2"
    local description="$3"

    assert_true "grep -q '$pattern' '$file_path'" "$description"
}

#
# Test suites
#
test_syntax_validation() {
    echo ""
    echo "=== Test Suite 1: Syntax Validation ==="

    assert_true "bash -n lib/core/logging.sh" "logging.sh syntax valid"
    assert_true "bash -n lib/ui/collapsible.sh" "collapsible.sh syntax valid"
    assert_true "bash -n lib/installers/common/manager-runner.sh" "manager-runner.sh syntax valid"
    assert_true "bash -n start.sh" "start.sh syntax valid"
}

test_directory_structure() {
    echo ""
    echo "=== Test Suite 2: Log Directory Structure ==="

    assert_dir_exists "logs/installation" "logs/installation/ exists"
    assert_dir_exists "logs/components" "logs/components/ exists"
    assert_file_exists "logs/installation/.gitkeep" "logs/installation/.gitkeep exists"
    assert_file_exists "logs/components/.gitkeep" "logs/components/.gitkeep exists"
    assert_file_exists "logs/.gitkeep" "logs/.gitkeep exists"
}

test_verbose_mode_defaults() {
    echo ""
    echo "=== Test Suite 3: VERBOSE_MODE Defaults ==="

    # Check collapsible.sh default
    assert_contains "lib/ui/collapsible.sh" "VERBOSE_MODE=\${VERBOSE_MODE:-false}" \
        "collapsible.sh defaults VERBOSE_MODE to false"

    # Check start.sh default
    assert_contains "start.sh" "VERBOSE_MODE=false" \
        "start.sh sets VERBOSE_MODE=false by default"
}

test_core_functions() {
    echo ""
    echo "=== Test Suite 4: Core Functions Present ==="

    assert_contains "lib/core/logging.sh" "^log_command_output()" \
        "log_command_output() function exists in logging.sh"

    assert_contains "lib/core/logging.sh" "^get_verbose_log_file()" \
        "get_verbose_log_file() function exists in logging.sh"

    assert_contains "lib/ui/collapsible.sh" "log_command_output" \
        "log_command_output() called in collapsible.sh"

    assert_contains "lib/ui/collapsible.sh" "run_command_collapsible()" \
        "run_command_collapsible() function exists in collapsible.sh"
}

test_function_exports() {
    echo ""
    echo "=== Test Suite 5: Function Exports ==="

    assert_contains "lib/core/logging.sh" "export -f log_command_output" \
        "log_command_output exported from logging.sh"

    assert_contains "lib/core/logging.sh" "export -f get_verbose_log_file" \
        "get_verbose_log_file exported from logging.sh"

    assert_contains "lib/ui/collapsible.sh" "export -f run_command_collapsible" \
        "run_command_collapsible exported from collapsible.sh"
}

test_gitignore_patterns() {
    echo ""
    echo "=== Test Suite 6: .gitignore Patterns ==="

    assert_contains ".gitignore" "logs/\*\*/\*.log" \
        ".gitignore has logs/**/*.log pattern"

    assert_contains ".gitignore" "logs/\*\*/\*.json" \
        ".gitignore has logs/**/*.json pattern"

    assert_contains ".gitignore" "!logs/installation/.gitkeep" \
        ".gitignore preserves logs/installation/.gitkeep"

    assert_contains ".gitignore" "!logs/components/.gitkeep" \
        ".gitignore preserves logs/components/.gitkeep"

    assert_contains ".gitignore" "logs/errors.log" \
        ".gitignore excludes errors.log"
}

test_documentation() {
    echo ""
    echo "=== Test Suite 7: Documentation ==="

    assert_file_exists "documentation/developer/LOGGING_GUIDE.md" \
        "LOGGING_GUIDE.md exists"

    assert_contains "documentation/developer/LOGGING_GUIDE.md" "Dual-Mode Logging System" \
        "LOGGING_GUIDE.md has dual-mode section"

    assert_contains "documentation/developer/LOGGING_GUIDE.md" "log_command_output" \
        "LOGGING_GUIDE.md documents log_command_output()"

    assert_contains "CLAUDE.md" "CRITICAL LOGGING REQUIREMENT" \
        "CLAUDE.md has critical logging requirement section"

    assert_contains "CLAUDE.md" "Dual-Mode Output System" \
        "CLAUDE.md documents dual-mode output system"
}

test_logging_initialization() {
    echo ""
    echo "=== Test Suite 8: Logging System Initialization ==="

    # Source logging.sh and check for errors
    if source lib/core/logging.sh 2>&1 | grep -q "ERROR"; then
        assert_true "false" "logging.sh sources without errors"
    else
        assert_true "true" "logging.sh sources without errors"
    fi

    # Source collapsible.sh and check for errors
    if source lib/ui/collapsible.sh 2>&1 | grep -q "ERROR"; then
        assert_true "false" "collapsible.sh sources without errors"
    else
        assert_true "true" "collapsible.sh sources without errors"
    fi
}

test_cli_arguments() {
    echo ""
    echo "=== Test Suite 9: CLI Arguments ==="

    assert_contains "start.sh" "--verbose" \
        "start.sh has --verbose flag"

    assert_contains "start.sh" "--show-logs" \
        "start.sh has --show-logs flag"

    assert_contains "start.sh" "Output Modes" \
        "start.sh help text has Output Modes section"

    assert_contains "start.sh" "Logging:" \
        "start.sh help text has Logging section"
}

test_component_logging() {
    echo ""
    echo "=== Test Suite 10: Component Logging ==="

    assert_contains "lib/installers/common/manager-runner.sh" "component_log=" \
        "manager-runner.sh creates component log file"

    assert_contains "lib/installers/common/manager-runner.sh" "show_component_footer.*component_log" \
        "manager-runner.sh passes component log to footer"

    assert_contains "lib/installers/common/manager-runner.sh" "Detailed logs:" \
        "manager-runner.sh displays log file location"
}

#
# Main test execution
#
main() {
    gum style \
        --border double \
        --border-foreground 212 \
        --align center \
        --width 70 \
        --margin "1 0" \
        --padding "1 2" \
        "Dual-Mode Logging System - Integration Tests"

    # Run all test suites
    test_syntax_validation
    test_directory_structure
    test_verbose_mode_defaults
    test_core_functions
    test_function_exports
    test_gitignore_patterns
    test_documentation
    test_logging_initialization
    test_cli_arguments
    test_component_logging

    # Summary
    echo ""
    gum style \
        --border double \
        --border-foreground 212 \
        --align center \
        --width 70 \
        --margin "1 0" \
        --padding "1 2" \
        "Test Summary"
    echo ""
    echo "Total tests:  $TOTAL_TESTS"
    echo -e "Passed:       ${COLOR_GREEN}${PASSED_TESTS}${COLOR_RESET}"
    echo -e "Failed:       ${COLOR_RED}${FAILED_TESTS}${COLOR_RESET}"
    echo ""

    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${COLOR_GREEN}✓ All tests passed!${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_RED}✗ $FAILED_TESTS test(s) failed${COLOR_RESET}"
        return 1
    fi
}

# Run tests
main "$@"
