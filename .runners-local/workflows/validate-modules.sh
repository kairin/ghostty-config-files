#!/bin/bash
# validate-modules.sh - Module validation runner (contract + dependencies)

set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Validation scripts
VALIDATE_CONTRACT="$REPO_ROOT/scripts/validate_module_contract.sh"
VALIDATE_DEPS="$REPO_ROOT/scripts/validate_module_deps.sh"

# Colors
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# ============================================================
# VALIDATION FUNCTIONS
# ============================================================

# Validate all modules in a directory using contract validator
validate_contracts() {
    local modules_dir="$1"

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📋 Step 1: Contract Validation"
    echo "════════════════════════════════════════════════════════"
    echo ""

    # Find all non-template modules
    local module_files=$(find "$modules_dir" -maxdepth 1 -type f -name "*.sh" ! -name ".*" 2>/dev/null || echo "")

    if [[ -z "$module_files" ]]; then
        echo -e "${YELLOW}⚠${NC} No modules found in $modules_dir"
        return 0
    fi

    local total=0
    local passed=0
    local failed=0

    while IFS= read -r module_file; do
        [[ -z "$module_file" ]] && continue
        ((total++))

        echo "Validating: $(basename "$module_file")"

        if "$VALIDATE_CONTRACT" "$module_file" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} Contract validation passed"
            ((passed++))
        else
            echo -e "  ${RED}✗${NC} Contract validation failed"
            echo "  Run for details: $VALIDATE_CONTRACT $module_file"
            ((failed++))
        fi
        echo ""
    done <<< "$module_files"

    echo "────────────────────────────────────────────────────────"
    echo "  Total modules: $total"
    echo "  Passed: $passed"
    echo "  Failed: $failed"

    if [[ $failed -gt 0 ]]; then
        echo -e "  ${RED}❌ Contract validation FAILED${NC}"
        return 1
    else
        echo -e "  ${GREEN}✅ Contract validation PASSED${NC}"
        return 0
    fi
}

# Validate module dependencies
validate_dependencies() {
    local modules_dir="$1"

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🔗 Step 2: Dependency Validation"
    echo "════════════════════════════════════════════════════════"
    echo ""

    if "$VALIDATE_DEPS" "$modules_dir" &>/dev/null; then
        echo -e "${GREEN}✅ Dependency validation PASSED${NC}"
        echo "  No circular dependencies detected"
        return 0
    else
        echo -e "${RED}❌ Dependency validation FAILED${NC}"
        echo "  Circular dependencies detected"
        echo "  Run for details: $VALIDATE_DEPS $modules_dir"
        return 1
    fi
}

# Run detailed validation with full output
run_detailed_validation() {
    local modules_dir="$1"

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "🔍 Detailed Validation Output"
    echo "════════════════════════════════════════════════════════"
    echo ""

    echo "────────────────────────────────────────────────────────"
    echo "Contract Validation (Detailed)"
    echo "────────────────────────────────────────────────────────"

    local module_files=$(find "$modules_dir" -maxdepth 1 -type f -name "*.sh" ! -name ".*" 2>/dev/null || echo "")

    if [[ -n "$module_files" ]]; then
        while IFS= read -r module_file; do
            [[ -z "$module_file" ]] && continue
            "$VALIDATE_CONTRACT" "$module_file" || true
            echo ""
        done <<< "$module_files"
    fi

    echo "────────────────────────────────────────────────────────"
    echo "Dependency Validation (Detailed)"
    echo "────────────────────────────────────────────────────────"
    "$VALIDATE_DEPS" "$modules_dir" || true
}

# ============================================================
# REPORTING
# ============================================================

# Generate validation summary report
generate_summary() {
    local contract_result="$1"
    local deps_result="$2"

    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📊 Validation Summary"
    echo "════════════════════════════════════════════════════════"
    echo ""

    # Contract validation status
    if [[ $contract_result -eq 0 ]]; then
        echo -e "  Contract Validation:   ${GREEN}✅ PASS${NC}"
    else
        echo -e "  Contract Validation:   ${RED}❌ FAIL${NC}"
    fi

    # Dependency validation status
    if [[ $deps_result -eq 0 ]]; then
        echo -e "  Dependency Validation: ${GREEN}✅ PASS${NC}"
    else
        echo -e "  Dependency Validation: ${RED}❌ FAIL${NC}"
    fi

    echo ""

    # Overall status
    if [[ $contract_result -eq 0 ]] && [[ $deps_result -eq 0 ]]; then
        gum style \
            --border double \
            --border-foreground 46 \
            --align center \
            --width 70 \
            --margin "1 0" \
            --padding "1 2" \
            "✅  ALL VALIDATIONS PASSED  ✅"
        return 0
    else
        gum style \
            --border double \
            --border-foreground 196 \
            --align center \
            --width 70 \
            --margin "1 0" \
            --padding "1 2" \
            "❌  VALIDATION FAILURES  ❌"
        echo ""
        echo "Use --detailed flag for full validation output"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    local detailed=0
    local modules_dir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --detailed|-d)
                detailed=1
                shift
                ;;
            --help|-h)
                cat << EOF
Usage: $0 [OPTIONS] <modules_directory>

Comprehensive module validation runner

OPTIONS:
    --detailed, -d     Show detailed validation output
    --help, -h         Show this help message

VALIDATIONS:
    1. Contract Validation
       - Header completeness
       - BASH_SOURCE guard
       - Required sections
       - Function documentation
       - Private function naming
       - ShellCheck compliance

    2. Dependency Validation
       - Circular dependency detection
       - Topological sort
       - Dependency graph analysis

EXAMPLES:
    # Quick validation
    $0 ./scripts

    # Detailed validation with full output
    $0 --detailed ./scripts

EXIT CODES:
    0 - All validations passed
    1 - One or more validations failed
    2 - Usage error or invalid arguments
EOF
                return 0
                ;;
            *)
                modules_dir="$1"
                shift
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$modules_dir" ]]; then
        echo -e "${RED}Error:${NC} Modules directory required"
        echo "Usage: $0 [--detailed] <modules_directory>"
        return 2
    fi

    if [[ ! -d "$modules_dir" ]]; then
        echo -e "${RED}Error:${NC} Directory not found: $modules_dir"
        return 2
    fi

    # Check validation scripts exist
    if [[ ! -x "$VALIDATE_CONTRACT" ]]; then
        echo -e "${RED}Error:${NC} Contract validator not found: $VALIDATE_CONTRACT"
        return 2
    fi

    if [[ ! -x "$VALIDATE_DEPS" ]]; then
        echo -e "${RED}Error:${NC} Dependency validator not found: $VALIDATE_DEPS"
        return 2
    fi

    # Print header
    echo "════════════════════════════════════════════════════════"
    echo "🔍 Module Validation Suite"
    echo "════════════════════════════════════════════════════════"
    echo "  Directory: $modules_dir"
    echo "  Mode: $(if [[ $detailed -eq 1 ]]; then echo "Detailed"; else echo "Quick"; fi)"
    echo ""

    # Run detailed validation if requested
    if [[ $detailed -eq 1 ]]; then
        run_detailed_validation "$modules_dir"
        return $?
    fi

    # Run quick validation
    local contract_result=0
    local deps_result=0

    validate_contracts "$modules_dir" || contract_result=$?
    validate_dependencies "$modules_dir" || deps_result=$?

    # Generate summary
    generate_summary "$contract_result" "$deps_result"
    return $?
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
