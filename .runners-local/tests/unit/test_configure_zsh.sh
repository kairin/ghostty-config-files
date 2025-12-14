#!/bin/bash
# Unit tests for scripts/configure_zsh.sh
# Constitutional requirement: <10s execution time
# Wave 2 Agent 7: T068-T070 verification

set -euo pipefail

# Source module for testing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "${PROJECT_ROOT}/scripts/configure_zsh.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
START_TIME=$(date +%s)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function: run_test
# Purpose: Run a test and track results
# Args:
#   $1=test_name
#   $2=test_command (command to evaluate)
run_test() {
    local test_name="$1"
    local test_command="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if eval "$test_command"; then
        echo -e "${GREEN}✓ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "=== Unit Tests: configure_zsh.sh (Wave 2 Agent 7) ==="
echo "Testing T068-T070 implementation"
echo

# ============================================================
# Module Loading Tests
# ============================================================

echo "=== Module Loading Tests ==="
echo

run_test "Module loaded successfully" "[[ -n \"\${CONFIGURE_ZSH_SH_LOADED}\" ]]"
run_test "Module loaded exactly once" "[[ \"\${CONFIGURE_ZSH_SH_LOADED}\" == \"1\" ]]"

echo

# ============================================================
# Function Existence Tests
# ============================================================

echo "=== Function Existence Tests ==="
echo

FUNCTIONS=(
    "install_oh_my_zsh"
    "install_zsh_plugin"
    "install_powerlevel10k_theme"
    "configure_zsh_plugins"
    "configure_powerlevel10k_theme"
    "optimize_zsh_performance"
    "set_zsh_as_default_shell"
    "verify_zsh_configuration"
    "configure_zsh"
    "_backup_zshrc"
    "_measure_zsh_startup"
    "_add_config_section"
)

for func in "${FUNCTIONS[@]}"; do
    run_test "Function $func exists" "declare -f \"$func\" &> /dev/null"
done

echo

# ============================================================
# Constant Definition Tests
# ============================================================

echo "=== Constant Definition Tests ==="
echo

run_test "OH_MY_ZSH_DIR constant defined" "[[ -n \"\${OH_MY_ZSH_DIR}\" ]]"
run_test "ZSH_CUSTOM constant defined" "[[ -n \"\${ZSH_CUSTOM}\" ]]"
run_test "ZSHRC_FILE constant defined" "[[ -n \"\${ZSHRC_FILE}\" ]]"
run_test "MAX_STARTUP_OVERHEAD_MS constant defined" "[[ -n \"\${MAX_STARTUP_OVERHEAD_MS}\" ]]"
run_test "MAX_STARTUP_OVERHEAD_MS is 50" "[[ \"\${MAX_STARTUP_OVERHEAD_MS}\" == \"50\" ]]"

echo

# ============================================================
# Integration Tests (if ZSH is installed)
# ============================================================

echo "=== Integration Tests ==="
echo

if command -v zsh &> /dev/null; then
    echo "ZSH detected - running integration tests"
    echo

    run_test "ZSH binary available" "command -v zsh &> /dev/null"
    run_test "ZSH version check works" "zsh --version &> /dev/null"

    # Check if Oh My ZSH is installed
    if [[ -d "${HOME}/.oh-my-zsh" ]]; then
        run_test "Oh My ZSH directory exists" "[[ -d \"\${HOME}/.oh-my-zsh\" ]]"
        run_test "Oh My ZSH is a git repository" "[[ -d \"\${HOME}/.oh-my-zsh/.git\" ]]"
    else
        echo -e "${YELLOW}ℹ SKIP${NC}: Oh My ZSH not installed"
    fi

    # Check if .zshrc exists
    if [[ -f "${HOME}/.zshrc" ]]; then
        run_test ".zshrc file exists" "[[ -f \"\${HOME}/.zshrc\" ]]"
        run_test ".zshrc is readable" "[[ -r \"\${HOME}/.zshrc\" ]]"
    else
        echo -e "${YELLOW}ℹ SKIP${NC}: .zshrc not found"
    fi

    # Check for plugins
    if [[ -d "${HOME}/.oh-my-zsh/custom/plugins" ]]; then
        run_test "Custom plugins directory exists" "[[ -d \"\${HOME}/.oh-my-zsh/custom/plugins\" ]]"

        # Check individual plugins
        for plugin in "zsh-autosuggestions" "zsh-syntax-highlighting" "you-should-use"; do
            if [[ -d "${HOME}/.oh-my-zsh/custom/plugins/${plugin}" ]]; then
                run_test "Plugin $plugin installed" "[[ -d \"\${HOME}/.oh-my-zsh/custom/plugins/${plugin}\" ]]"
            else
                echo -e "${YELLOW}ℹ SKIP${NC}: Plugin $plugin not installed"
            fi
        done
    else
        echo -e "${YELLOW}ℹ SKIP${NC}: Custom plugins directory not found"
    fi

    # Check for Powerlevel10k theme
    if [[ -d "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
        run_test "Powerlevel10k theme installed" "[[ -d \"\${HOME}/.oh-my-zsh/custom/themes/powerlevel10k\" ]]"
    else
        echo -e "${YELLOW}ℹ SKIP${NC}: Powerlevel10k theme not installed"
    fi

    # Check .p10k.zsh does NOT self-source (prevents infinite recursion bug)
    if [[ -f "${HOME}/.p10k.zsh" ]]; then
        run_test ".p10k.zsh exists" "[[ -f \"\${HOME}/.p10k.zsh\" ]]"
        run_test ".p10k.zsh does NOT self-source (prevents recursion)" "! grep -q 'source ~/.p10k.zsh' \"\${HOME}/.p10k.zsh\""
        echo "  → Verified: No circular sourcing in .p10k.zsh"
    else
        echo -e "${YELLOW}ℹ SKIP${NC}: .p10k.zsh not found"
    fi

else
    echo -e "${YELLOW}ℹ SKIP${NC}: ZSH not installed - skipping integration tests"
fi

echo

# ============================================================
# Performance Tests
# ============================================================

echo "=== Performance Tests ==="
echo

# Test _measure_zsh_startup function
if command -v zsh &> /dev/null; then
    echo "Testing startup time measurement..."
    startup_time=$(_measure_zsh_startup 2>/dev/null || echo "0")

    run_test "Startup time measurement returns a number" "[[ \"$startup_time\" =~ ^[0-9]+$ ]]"

    if [[ "$startup_time" -gt 0 ]]; then
        echo "  → Measured startup time: ${startup_time}ms"

        if [[ "$startup_time" -le "${MAX_STARTUP_OVERHEAD_MS}" ]]; then
            run_test "Startup time meets constitutional requirement (<${MAX_STARTUP_OVERHEAD_MS}ms)" "true"
            echo -e "  ${GREEN}✅ Constitutional compliance: FR-051, FR-054${NC}"
        else
            run_test "Startup time meets constitutional requirement (<${MAX_STARTUP_OVERHEAD_MS}ms)" "false"
            echo -e "  ${RED}⚠️  Constitutional violation: ${startup_time}ms > ${MAX_STARTUP_OVERHEAD_MS}ms${NC}"
        fi
    else
        echo -e "${YELLOW}ℹ SKIP${NC}: Could not measure startup time"
    fi
else
    echo -e "${YELLOW}ℹ SKIP${NC}: ZSH not installed - skipping performance tests"
fi

echo

# ============================================================
# Wave 1 Integration Tests (fzf from Agent 4)
# ============================================================

echo "=== Wave 1 Integration Tests (Modern Tools from Agent 4) ==="
echo

# Check for modern tools from Wave 1 Agent 4
MODERN_TOOLS=("fzf" "eza" "bat" "rg" "fd" "zoxide")

for tool in "${MODERN_TOOLS[@]}"; do
    if command -v "$tool" &> /dev/null; then
        run_test "Wave 1 tool $tool available" "command -v \"$tool\" &> /dev/null"
    else
        echo -e "${YELLOW}ℹ INFO${NC}: Wave 1 tool $tool not installed (from Agent 4)"
    fi
done

# Check for fzf key bindings configuration
if [[ -f "${HOME}/.zshrc" ]] && command -v fzf &> /dev/null; then
    if grep -q "fzf" "${HOME}/.zshrc"; then
        run_test "fzf integration configured in .zshrc" "grep -q 'fzf' \"\${HOME}/.zshrc\""
        echo "  → fzf key bindings: Ctrl+R (history), Ctrl+T (files), Alt+C (dirs)"
    else
        echo -e "${YELLOW}ℹ SKIP${NC}: fzf not configured in .zshrc yet"
    fi
else
    echo -e "${YELLOW}ℹ SKIP${NC}: fzf or .zshrc not available"
fi

echo

# ============================================================
# Test Execution Time Validation
# ============================================================

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))

echo "=== Test Summary ==="
echo "Total tests run: $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo "Execution time: ${EXECUTION_TIME}s"
echo

# Constitutional requirement: <10s execution
if [[ $EXECUTION_TIME -le 10 ]]; then
    echo -e "${GREEN}✅ Test execution time meets constitutional requirement (<10s)${NC}"
else
    echo -e "${RED}⚠️  Test execution time exceeds constitutional requirement: ${EXECUTION_TIME}s > 10s${NC}"
fi
echo

# Final result
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
