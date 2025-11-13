#!/bin/bash

# Test script for idempotent start.sh functionality
# Tests all scenarios requested in the requirements

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="$SCRIPT_DIR/.installation-state.json"
START_SCRIPT="$SCRIPT_DIR/start.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() {
    local status="$1"
    shift
    local message="$*"

    case "$status" in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            ;;
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "SECTION")
            echo ""
            echo -e "${CYAN}=== $message ===${NC}"
            echo ""
            ;;
    esac
}

# Test 1: Help message includes new flags
test_help_message() {
    log_test "SECTION" "Test 1: Help Message Includes New Flags"

    local help_output=$("$START_SCRIPT" --help 2>&1 || true)

    local required_flags=(
        "--force"
        "--force-ghostty"
        "--force-node"
        "--reset-state"
        "--resume"
        "--show-state"
    )

    local all_found=true
    for flag in "${required_flags[@]}"; do
        if echo "$help_output" | grep -q -- "$flag"; then
            log_test "PASS" "Flag '$flag' documented in help"
        else
            log_test "FAIL" "Flag '$flag' missing from help"
            all_found=false
        fi
    done

    $all_found
}

# Test 2: Idempotent wrapper functions exist
test_wrapper_functions() {
    log_test "SECTION" "Test 2: Idempotent Wrapper Functions Exist"

    local wrappers=(
        "idempotent_install_zsh"
        "idempotent_install_ghostty"
        "idempotent_install_nodejs"
        "idempotent_install_ptyxis"
        "idempotent_install_uv"
        "idempotent_install_claude_code"
        "idempotent_install_gemini_cli"
        "idempotent_install_speckit"
    )

    local all_found=true
    for wrapper in "${wrappers[@]}"; do
        if grep -q "^${wrapper}()" "$START_SCRIPT"; then
            log_test "PASS" "Wrapper function '$wrapper' exists"
        else
            log_test "FAIL" "Wrapper function '$wrapper' not found"
            all_found=false
        fi
    done

    $all_found
}

# Test 3: State management functions exist
test_state_functions() {
    log_test "SECTION" "Test 3: State Management Functions Exist"

    local functions=(
        "init_state_file"
        "load_state"
        "save_state"
        "step_completed"
        "mark_step_completed"
        "mark_step_failed"
        "mark_step_skipped"
        "get_state_version"
        "compare_versions"
        "get_installed_version"
        "show_state_summary"
        "detect_existing_software"
    )

    local all_found=true
    for func in "${functions[@]}"; do
        if grep -q "^${func}()" "$START_SCRIPT"; then
            log_test "PASS" "Function '$func' exists"
        else
            log_test "FAIL" "Function '$func' not found"
            all_found=false
        fi
    done

    $all_found
}

# Test 4: Force flags are defined
test_force_flags() {
    log_test "SECTION" "Test 4: Force Flags Are Defined"

    local flags=(
        "FORCE_ALL"
        "FORCE_GHOSTTY"
        "FORCE_NODE"
        "FORCE_ZSH"
        "FORCE_PTYXIS"
        "FORCE_UV"
        "FORCE_CLAUDE"
        "FORCE_GEMINI"
        "FORCE_SPEC_KIT"
    )

    local all_found=true
    for flag in "${flags[@]}"; do
        if grep -q "^${flag}=false" "$START_SCRIPT"; then
            log_test "PASS" "Flag '$flag' defined"
        else
            log_test "FAIL" "Flag '$flag' not found"
            all_found=false
        fi
    done

    $all_found
}

# Test 5: Main function calls load_state
test_main_initialization() {
    log_test "SECTION" "Test 5: Main Function Initializes State"

    local found_load=false
    local found_summary=false

    if grep -A 20 "^main()" "$START_SCRIPT" | grep -q "load_state"; then
        log_test "PASS" "main() calls load_state"
        found_load=true
    else
        log_test "FAIL" "main() does not call load_state"
    fi

    if grep -A 20 "^main()" "$START_SCRIPT" | grep -q "show_state_summary"; then
        log_test "PASS" "main() calls show_state_summary"
        found_summary=true
    else
        log_test "FAIL" "main() does not call show_state_summary"
    fi

    $found_load && $found_summary
}

# Test 6: Main function saves state at end
test_main_finalization() {
    log_test "SECTION" "Test 6: Main Function Saves State"

    # Check if save_state is called in main() function (look for the call, not the function definition)
    if grep -A 300 "^main()" "$START_SCRIPT" | grep -B 15 "# Automatic shell restart" | grep -q "save_state"; then
        log_test "PASS" "main() calls save_state before completion"
        return 0
    else
        log_test "FAIL" "main() does not call save_state"
        return 1
    fi
}

# Test 7: Argument parser handles new flags
test_argument_parser() {
    log_test "SECTION" "Test 7: Argument Parser Handles New Flags"

    local flags_to_check=(
        "--force"
        "--force-ghostty"
        "--force-node"
        "--reset-state"
        "--resume"
        "--show-state"
        "--skip-checks"
    )

    local all_found=true
    for flag in "${flags_to_check[@]}"; do
        # Check if flag is in the case statement (look directly without context limits)
        if grep -q -- "${flag})" "$START_SCRIPT"; then
            log_test "PASS" "Argument parser handles '$flag'"
        else
            log_test "FAIL" "Argument parser missing '$flag'"
            all_found=false
        fi
    done

    $all_found
}

# Test 8: State file location is correct
test_state_file_location() {
    log_test "SECTION" "Test 8: State File Location Is Correct"

    if grep -q "^STATE_FILE=\"\$SCRIPT_DIR/\.installation-state\.json\"" "$START_SCRIPT"; then
        log_test "PASS" "STATE_FILE variable correctly defined"
        return 0
    else
        log_test "FAIL" "STATE_FILE variable not found or incorrect"
        return 1
    fi
}

# Test 9: Idempotent wrappers called in main
test_wrapper_usage() {
    log_test "SECTION" "Test 9: Idempotent Wrappers Called in Main"

    local wrappers=(
        "idempotent_install_zsh"
        "idempotent_install_ghostty"
        "idempotent_install_nodejs"
        "idempotent_install_ptyxis"
        "idempotent_install_uv"
        "idempotent_install_claude_code"
        "idempotent_install_gemini_cli"
        "idempotent_install_speckit"
    )

    local all_found=true
    for wrapper in "${wrappers[@]}"; do
        if grep -A 500 "^main()" "$START_SCRIPT" | grep -q "$wrapper"; then
            log_test "PASS" "main() calls '$wrapper'"
        else
            log_test "FAIL" "main() does not call '$wrapper'"
            all_found=false
        fi
    done

    $all_found
}

# Test 10: Show current software versions
test_current_versions() {
    log_test "SECTION" "Test 10: Current Software Versions"

    local software_list=("ghostty" "zsh" "node" "ptyxis" "uv" "claude" "gemini")

    for software in "${software_list[@]}"; do
        local cmd=""
        local version="not_installed"

        case "$software" in
            "ghostty")
                if command -v ghostty >/dev/null 2>&1; then
                    version=$(ghostty --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
                fi
                ;;
            "zsh")
                if command -v zsh >/dev/null 2>&1; then
                    version=$(zsh --version 2>/dev/null | awk '{print $2}' || echo "unknown")
                fi
                ;;
            "node")
                if command -v node >/dev/null 2>&1; then
                    version=$(node --version 2>/dev/null | sed 's/^v//' || echo "unknown")
                fi
                ;;
            "ptyxis")
                if command -v ptyxis >/dev/null 2>&1; then
                    version=$(ptyxis --version 2>/dev/null | awk '{print $2}' || echo "unknown")
                fi
                ;;
            "uv")
                if command -v uv >/dev/null 2>&1; then
                    version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
                fi
                ;;
            "claude")
                if command -v claude >/dev/null 2>&1; then
                    version=$(claude --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
                fi
                ;;
            "gemini")
                if command -v gemini >/dev/null 2>&1; then
                    version=$(gemini --version 2>/dev/null | awk '{print $2}' || echo "unknown")
                fi
                ;;
        esac

        if [ "$version" != "not_installed" ] && [ "$version" != "unknown" ]; then
            log_test "PASS" "$software: $version (installed)"
        elif [ "$version" = "not_installed" ]; then
            log_test "INFO" "$software: not installed"
        else
            log_test "WARN" "$software: version unknown"
        fi
    done
}

# Run all tests
main() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Testing Idempotent start.sh${NC}"
    echo -e "${CYAN}========================================${NC}"

    local failed_tests=0
    local total_tests=10

    # Run each test
    test_help_message || ((failed_tests++))
    test_wrapper_functions || ((failed_tests++))
    test_state_functions || ((failed_tests++))
    test_force_flags || ((failed_tests++))
    test_main_initialization || ((failed_tests++))
    test_main_finalization || ((failed_tests++))
    test_argument_parser || ((failed_tests++))
    test_state_file_location || ((failed_tests++))
    test_wrapper_usage || ((failed_tests++))
    test_current_versions || ((failed_tests++))

    # Summary
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Test Summary${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    local passed_tests=$((total_tests - failed_tests))
    log_test "INFO" "Tests passed: $passed_tests/$total_tests"

    if [ $failed_tests -eq 0 ]; then
        log_test "PASS" "All tests passed!"
        return 0
    else
        log_test "FAIL" "$failed_tests test(s) failed"
        return 1
    fi
}

main "$@"
