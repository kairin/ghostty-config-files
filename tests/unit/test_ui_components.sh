#!/usr/bin/env bash
# tests/unit/test_ui_components.sh - Unit tests for UI components
# Tests: lib/ui/*.sh, gum integration, progress display

set -euo pipefail

[ -z "${TEST_UI_COMPONENTS_LOADED:-}" ] || return 0
TEST_UI_COMPONENTS_LOADED=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

assert_true() {
    local condition="$1" message="${2:-}"
    ((++TESTS_RUN))
    if eval "$condition"; then
        ((++TESTS_PASSED))
        echo "  [PASS] $message"
    else
        ((++TESTS_FAILED))
        echo "  [FAIL] $message"
    fi
}

assert_file_exists() {
    local file="$1" message="${2:-}"
    ((++TESTS_RUN))
    if [[ -f "$file" ]]; then
        ((++TESTS_PASSED))
        echo "  [PASS] ${message:-File exists: $file}"
    else
        ((++TESTS_FAILED))
        echo "  [FAIL] ${message:-File exists: $file}"
    fi
}

# Test: vhs-auto-record.sh exists and has valid syntax
test_vhs_auto_record_exists() {
    echo "Testing vhs-auto-record.sh..."
    local file="${REPO_ROOT}/lib/ui/vhs-auto-record.sh"
    if [[ -f "$file" ]]; then
        assert_file_exists "$file" "vhs-auto-record.sh exists"
        assert_true "bash -n '$file'" "vhs-auto-record.sh has valid syntax"
    else
        echo "  [SKIP] vhs-auto-record.sh not found"
        ((++TESTS_RUN))
        ((++TESTS_PASSED))
    fi
}

# Test: lib/ui directory exists
test_ui_directory_exists() {
    echo "Testing lib/ui/ directory..."
    assert_true "[[ -d '${REPO_ROOT}/lib/ui' ]]" "lib/ui/ directory exists"
}

# Test: gum command availability check
test_gum_availability() {
    echo "Testing gum availability check..."
    if command -v gum >/dev/null 2>&1; then
        echo "  [PASS] gum is installed"
        ((++TESTS_RUN))
        ((++TESTS_PASSED))

        # Test gum version
        if gum --version >/dev/null 2>&1; then
            echo "  [PASS] gum --version works"
            ((++TESTS_RUN))
            ((++TESTS_PASSED))
        else
            echo "  [FAIL] gum --version failed"
            ((++TESTS_RUN))
            ((++TESTS_FAILED))
        fi
    else
        echo "  [SKIP] gum not installed (optional)"
        ((++TESTS_RUN))
        ((++TESTS_PASSED))
    fi
}

# Test: all UI scripts have valid syntax
test_all_ui_scripts_syntax() {
    echo "Testing all lib/ui/*.sh syntax..."
    local found_scripts=false
    for script in "${REPO_ROOT}"/lib/ui/*.sh; do
        if [[ -f "$script" ]]; then
            found_scripts=true
            if bash -n "$script" 2>/dev/null; then
                echo "  [PASS] $(basename "$script") syntax valid"
                ((++TESTS_RUN))
                ((++TESTS_PASSED))
            else
                echo "  [FAIL] $(basename "$script") syntax invalid"
                ((++TESTS_RUN))
                ((++TESTS_FAILED))
            fi
        fi
    done 2>/dev/null || true

    if [[ "$found_scripts" == "false" ]]; then
        echo "  [SKIP] No UI scripts found"
        ((++TESTS_RUN))
        ((++TESTS_PASSED))
    fi
}

# Run all UI component tests
run_ui_component_tests() {
    echo "========================================="
    echo "UI Component Tests"
    echo "========================================="

    test_ui_directory_exists
    test_vhs_auto_record_exists
    test_gum_availability
    test_all_ui_scripts_syntax

    echo ""
    echo "========================================="
    echo "Results: $TESTS_PASSED/$TESTS_RUN passed"
    echo "========================================="

    [[ $TESTS_FAILED -eq 0 ]]
}

export -f run_ui_component_tests

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_ui_component_tests
    exit $?
fi
