#!/bin/bash
# Module: run_shellcheck.sh
# Purpose: ShellCheck validation runner for static analysis of all bash modules
# Dependencies: shellcheck
# Modules Required: None
# Exit Codes: 0=all checks passed, 1=shellcheck found issues, 2=usage/setup error

set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Directories to check
MODULES_DIR="$REPO_ROOT/scripts"
LIB_DIR="$REPO_ROOT/lib"
TESTS_DIR="$REPO_ROOT/.runners-local/tests"
RUNNERS_DIR="$REPO_ROOT/.runners-local/workflows"

# ShellCheck configuration
SHELLCHECK_SEVERITY="warning"  # error, warning, info, style
SHELLCHECK_EXCLUDE="SC1090,SC1091"  # SC1090=source non-constant, SC1091=source not following

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

# Check if ShellCheck is installed
check_shellcheck() {
    if ! command -v shellcheck &> /dev/null; then
        echo -e "${RED}❌ ShellCheck not installed${NC}"
        echo ""
        echo "ShellCheck is required for bash script validation"
        echo ""
        echo "To install:"
        echo "  Ubuntu/Debian: sudo apt install shellcheck"
        echo "  macOS:         brew install shellcheck"
        echo "  Other:         https://github.com/koalaman/shellcheck#installing"
        return 1
    fi

    local version=$(shellcheck --version | grep "version:" | awk '{print $2}')
    echo "✅ ShellCheck installed (version $version)"
    return 0
}

# Find all bash scripts in a directory
find_bash_scripts() {
    local dir="$1"
    local exclude_pattern="${2:-.git}"

    find "$dir" -type f \( -name "*.sh" -o -name "*.bash" \) ! -path "*/$exclude_pattern/*" 2>/dev/null || echo ""
}

# Run ShellCheck on a single file
check_file() {
    local file="$1"
    local show_output="${2:-0}"

    # Run ShellCheck
    local output
    local exit_code

    set +e
    output=$(shellcheck \
        --severity="$SHELLCHECK_SEVERITY" \
        --exclude="$SHELLCHECK_EXCLUDE" \
        --format=gcc \
        "$file" 2>&1)
    exit_code=$?
    set -e

    if [[ $exit_code -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} $(basename "$file")"
        return 0
    else
        echo -e "  ${RED}✗${NC} $(basename "$file")"
        if [[ $show_output -eq 1 ]]; then
            echo "$output" | sed 's/^/    /'
        fi
        return 1
    fi
}

# ============================================================
# VALIDATION FUNCTIONS
# ============================================================

# Check all scripts in a directory
check_directory() {
    local dir="$1"
    local dir_name="$2"

    if [[ ! -d "$dir" ]]; then
        echo -e "${YELLOW}⚠${NC} Directory not found: $dir"
        return 0
    fi

    echo ""
    echo "────────────────────────────────────────────────────────"
    echo "📂 $dir_name"
    echo "────────────────────────────────────────────────────────"

    local scripts=$(find_bash_scripts "$dir")

    if [[ -z "$scripts" ]]; then
        echo -e "${YELLOW}⚠${NC} No bash scripts found"
        return 0
    fi

    local total=0
    local passed=0
    local failed=0

    while IFS= read -r script; do
        [[ -z "$script" ]] && continue
        ((total++))

        if check_file "$script" 0; then
            ((passed++))
        else
            ((failed++))
        fi
    done <<< "$scripts"

    echo ""
    echo "  Total: $total | Passed: $passed | Failed: $failed"

    [[ $failed -eq 0 ]] && return 0 || return 1
}

# Run detailed check on failed files
detailed_check() {
    local dir="$1"

    local scripts=$(find_bash_scripts "$dir")
    [[ -z "$scripts" ]] && return 0

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🔍 Detailed ShellCheck Output"
    echo "════════════════════════════════════════════════════════"

    while IFS= read -r script; do
        [[ -z "$script" ]] && continue

        # Check if file has issues
        if ! shellcheck --severity="$SHELLCHECK_SEVERITY" --exclude="$SHELLCHECK_EXCLUDE" "$script" &>/dev/null; then
            echo ""
            echo "────────────────────────────────────────────────────────"
            echo "File: $script"
            echo "────────────────────────────────────────────────────────"
            shellcheck --severity="$SHELLCHECK_SEVERITY" --exclude="$SHELLCHECK_EXCLUDE" --format=gcc "$script" || true
        fi
    done <<< "$scripts"
}

# ============================================================
# REPORTING
# ============================================================

# Generate summary report
generate_summary() {
    local modules_result="$1"
    local lib_result="$2"
    local tests_result="$3"
    local runners_result="$4"

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 ShellCheck Validation Summary"
    echo "════════════════════════════════════════════════════════"
    echo ""

    # Module scripts
    if [[ $modules_result -eq 0 ]]; then
        echo -e "  Module Scripts:  ${GREEN}✅ PASS${NC}"
    else
        echo -e "  Module Scripts:  ${RED}❌ FAIL${NC}"
    fi

    # Library scripts
    if [[ $lib_result -eq 0 ]]; then
        echo -e "  Library Scripts: ${GREEN}✅ PASS${NC}"
    else
        echo -e "  Library Scripts: ${RED}❌ FAIL${NC}"
    fi

    # Test scripts
    if [[ $tests_result -eq 0 ]]; then
        echo -e "  Test Scripts:    ${GREEN}✅ PASS${NC}"
    else
        echo -e "  Test Scripts:    ${RED}❌ FAIL${NC}"
    fi

    # Runner scripts
    if [[ $runners_result -eq 0 ]]; then
        echo -e "  Runner Scripts:  ${GREEN}✅ PASS${NC}"
    else
        echo -e "  Runner Scripts:  ${RED}❌ FAIL${NC}"
    fi

    echo ""

    # Overall status
    if [[ $modules_result -eq 0 ]] && [[ $lib_result -eq 0 ]] && [[ $tests_result -eq 0 ]] && [[ $runners_result -eq 0 ]]; then
        gum style \
            --border double \
            --border-foreground 46 \
            --align center \
            --width 70 \
            --margin "1 0" \
            --padding "1 2" \
            "✅  ALL SHELLCHECK VALIDATION PASSED  ✅"
        return 0
    else
        gum style \
            --border double \
            --border-foreground 196 \
            --align center \
            --width 70 \
            --margin "1 0" \
            --padding "1 2" \
            "❌  SHELLCHECK ISSUES FOUND  ❌"
        echo ""
        echo "Use --detailed flag for full ShellCheck output"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    local detailed=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --detailed|-d)
                detailed=1
                shift
                ;;
            --help|-h)
                cat << EOF
Usage: $0 [OPTIONS]

ShellCheck validation runner for bash scripts

OPTIONS:
    --detailed, -d     Show detailed ShellCheck output for failed files
    --help, -h         Show this help message

CHECKS:
    - Module scripts (scripts/*.sh)
    - Library scripts (lib/**/*.sh)
    - Test scripts (.runners-local/tests/**/*.sh)
    - Runner scripts (.runners-local/workflows/*.sh)

CONFIGURATION:
    Severity: $SHELLCHECK_SEVERITY
    Excluded: $SHELLCHECK_EXCLUDE

EXIT CODES:
    0 - All checks passed
    1 - ShellCheck found issues
    2 - Setup error (ShellCheck not installed)
EOF
                return 0
                ;;
            *)
                echo -e "${RED}Error:${NC} Unknown option: $1"
                echo "Use --help for usage information"
                return 2
                ;;
        esac
    done

    # Print header
    echo "════════════════════════════════════════════════════════"
    echo "🔍 ShellCheck Validation Runner"
    echo "════════════════════════════════════════════════════════"
    echo "  Repository: $REPO_ROOT"
    echo "  Severity: $SHELLCHECK_SEVERITY"
    echo ""

    # Check ShellCheck availability
    if ! check_shellcheck; then
        return 2
    fi

    # Run checks
    local modules_result=0
    local lib_result=0
    local tests_result=0
    local runners_result=0

    check_directory "$MODULES_DIR" "Module Scripts (scripts/)" || modules_result=$?
    check_directory "$LIB_DIR" "Library Scripts (lib/)" || lib_result=$?
    check_directory "$TESTS_DIR" "Test Scripts (.runners-local/tests/)" || tests_result=$?
    check_directory "$RUNNERS_DIR" "Runner Scripts (.runners-local/workflows/)" || runners_result=$?

    # Show detailed output if requested
    if [[ $detailed -eq 1 ]]; then
        [[ $modules_result -ne 0 ]] && detailed_check "$MODULES_DIR"
        [[ $lib_result -ne 0 ]] && detailed_check "$LIB_DIR"
        [[ $tests_result -ne 0 ]] && detailed_check "$TESTS_DIR"
        [[ $runners_result -ne 0 ]] && detailed_check "$RUNNERS_DIR"
    fi

    # Generate summary
    generate_summary "$modules_result" "$lib_result" "$tests_result" "$runners_result"
    return $?
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
