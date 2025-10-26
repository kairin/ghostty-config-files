#!/bin/bash
# Module: validate_module_contract.sh
# Purpose: Validates bash modules against the bash-module-interface contract
# Dependencies: shellcheck, grep, awk
# Modules Required: None
# Exit Codes: 0=validation passed, 1=validation failed, 2=usage error

set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

readonly REQUIRED_HEADER_FIELDS=(
    "Module:"
    "Purpose:"
    "Dependencies:"
    "Modules Required:"
    "Exit Codes:"
)

readonly REQUIRED_SECTIONS=(
    "# PUBLIC FUNCTIONS (Module API)"
    "# PRIVATE FUNCTIONS (Internal helpers)"
    "# MAIN EXECUTION (Skipped when sourced)"
)

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# ============================================================
# VALIDATION FUNCTIONS
# ============================================================

# Validate module header completeness
validate_header() {
    local module_file="$1"
    local errors=0

    echo "  Checking header completeness..."

    for field in "${REQUIRED_HEADER_FIELDS[@]}"; do
        if ! grep -q "^# ${field}" "$module_file"; then
            echo -e "    ${RED}✗${NC} Missing required header field: ${field}"
            ((errors++))
        else
            echo -e "    ${GREEN}✓${NC} Found: ${field}"
        fi
    done

    # Check for shebang
    if ! head -n 1 "$module_file" | grep -q '^#!/bin/bash'; then
        echo -e "    ${RED}✗${NC} Missing or incorrect shebang (must be #!/bin/bash)"
        ((errors++))
    else
        echo -e "    ${GREEN}✓${NC} Shebang present"
    fi

    # Check for set -euo pipefail
    if ! grep -q '^set -euo pipefail' "$module_file"; then
        echo -e "    ${RED}✗${NC} Missing 'set -euo pipefail' directive"
        ((errors++))
    else
        echo -e "    ${GREEN}✓${NC} Error handling directive present"
    fi

    return $errors
}

# Validate BASH_SOURCE guard
validate_bash_source_guard() {
    local module_file="$1"
    local errors=0

    echo "  Checking BASH_SOURCE guard..."

    if ! grep -q 'if \[\[ "\${BASH_SOURCE\[0\]}" != "\${0}" \]\]' "$module_file"; then
        echo -e "    ${RED}✗${NC} Missing BASH_SOURCE guard for testing"
        ((errors++))
    else
        echo -e "    ${GREEN}✓${NC} BASH_SOURCE guard present"
    fi

    if ! grep -q 'SOURCED_FOR_TESTING' "$module_file"; then
        echo -e "    ${RED}✗${NC} Missing SOURCED_FOR_TESTING variable"
        ((errors++))
    else
        echo -e "    ${GREEN}✓${NC} SOURCED_FOR_TESTING variable present"
    fi

    return $errors
}

# Validate required sections
validate_sections() {
    local module_file="$1"
    local errors=0

    echo "  Checking required sections..."

    for section in "${REQUIRED_SECTIONS[@]}"; do
        if ! grep -q "$section" "$module_file"; then
            echo -e "    ${RED}✗${NC} Missing required section: ${section}"
            ((errors++))
        else
            echo -e "    ${GREEN}✓${NC} Found: ${section}"
        fi
    done

    return $errors
}

# Validate function documentation
validate_function_docs() {
    local module_file="$1"
    local errors=0

    echo "  Checking function documentation..."

    # Extract all function names (public and private)
    local functions=$(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*\(\)' "$module_file" | sed 's/().*$//')

    if [[ -z "$functions" ]]; then
        echo -e "    ${YELLOW}⚠${NC} Warning: No functions found in module"
        return 0
    fi

    local func_count=0
    local documented_count=0

    while IFS= read -r func; do
        ((func_count++))

        # Look for function documentation comment above the function
        # Pattern: # Function: func_name
        if grep -B 5 "^${func}()" "$module_file" | grep -q "^# Function: ${func}"; then
            echo -e "    ${GREEN}✓${NC} Function '${func}' is documented"
            ((documented_count++))
        else
            echo -e "    ${RED}✗${NC} Function '${func}' is missing documentation"
            ((errors++))
        fi
    done <<< "$functions"

    echo "  Functions documented: ${documented_count}/${func_count}"

    return $errors
}

# Run ShellCheck
validate_shellcheck() {
    local module_file="$1"

    echo "  Running ShellCheck..."

    if ! command -v shellcheck &> /dev/null; then
        echo -e "    ${YELLOW}⚠${NC} ShellCheck not installed, skipping syntax validation"
        return 0
    fi

    local shellcheck_output
    if shellcheck_output=$(shellcheck "$module_file" 2>&1); then
        echo -e "    ${GREEN}✓${NC} ShellCheck passed (no issues)"
        return 0
    else
        echo -e "    ${RED}✗${NC} ShellCheck found issues:"
        echo "$shellcheck_output" | sed 's/^/      /'
        return 1
    fi
}

# Validate private function naming
validate_private_functions() {
    local module_file="$1"
    local errors=0

    echo "  Checking private function naming..."

    # Find functions in the PRIVATE FUNCTIONS section
    local in_private_section=0
    local in_public_section=0

    while IFS= read -r line; do
        if [[ "$line" =~ ^#.*PUBLIC\ FUNCTIONS ]]; then
            in_public_section=1
            in_private_section=0
        elif [[ "$line" =~ ^#.*PRIVATE\ FUNCTIONS ]]; then
            in_private_section=1
            in_public_section=0
        elif [[ "$line" =~ ^#.*MAIN\ EXECUTION ]]; then
            in_private_section=0
            in_public_section=0
        fi

        # Check if line is a function definition
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\(\) ]]; then
            local func_name="${BASH_REMATCH[1]}"

            # Private functions should start with underscore
            if [[ $in_private_section -eq 1 ]]; then
                if [[ ! "$func_name" =~ ^_ ]]; then
                    echo -e "    ${RED}✗${NC} Private function '${func_name}' should start with underscore"
                    ((errors++))
                fi
            fi

            # Public functions should NOT start with underscore
            if [[ $in_public_section -eq 1 ]]; then
                if [[ "$func_name" =~ ^_ ]]; then
                    echo -e "    ${RED}✗${NC} Public function '${func_name}' should not start with underscore"
                    ((errors++))
                fi
            fi
        fi
    done < "$module_file"

    if [[ $errors -eq 0 ]]; then
        echo -e "    ${GREEN}✓${NC} Function naming convention followed"
    fi

    return $errors
}

# ============================================================
# MAIN VALIDATION
# ============================================================

validate_module() {
    local module_file="$1"
    local total_errors=0

    echo "════════════════════════════════════════════════════════"
    echo "🔍 Validating Module: $(basename "$module_file")"
    echo "════════════════════════════════════════════════════════"
    echo ""

    # Run all validation checks
    validate_header "$module_file" || total_errors=$((total_errors + $?))
    echo ""

    validate_bash_source_guard "$module_file" || total_errors=$((total_errors + $?))
    echo ""

    validate_sections "$module_file" || total_errors=$((total_errors + $?))
    echo ""

    validate_function_docs "$module_file" || total_errors=$((total_errors + $?))
    echo ""

    validate_private_functions "$module_file" || total_errors=$((total_errors + $?))
    echo ""

    validate_shellcheck "$module_file" || total_errors=$((total_errors + $?))
    echo ""

    # Print summary
    echo "════════════════════════════════════════════════════════"
    if [[ $total_errors -eq 0 ]]; then
        echo -e "${GREEN}✅ VALIDATION PASSED${NC}"
        echo "Module $(basename "$module_file") complies with contract"
        return 0
    else
        echo -e "${RED}❌ VALIDATION FAILED${NC}"
        echo "Found $total_errors issue(s) in $(basename "$module_file")"
        return 1
    fi
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <module_file.sh> [module_file2.sh ...]"
        echo ""
        echo "Validates bash modules against the bash-module-interface contract"
        echo ""
        echo "Checks:"
        echo "  • Header completeness (Module, Purpose, Dependencies, etc.)"
        echo "  • BASH_SOURCE guard for testing"
        echo "  • Required sections (PUBLIC/PRIVATE/MAIN)"
        echo "  • Function documentation"
        echo "  • Private function naming (_prefix)"
        echo "  • ShellCheck compliance"
        return 2
    fi

    local total_modules=0
    local passed_modules=0
    local failed_modules=0

    for module_file in "$@"; do
        ((total_modules++))

        if [[ ! -f "$module_file" ]]; then
            echo -e "${RED}✗${NC} File not found: $module_file"
            ((failed_modules++))
            continue
        fi

        if validate_module "$module_file"; then
            ((passed_modules++))
        else
            ((failed_modules++))
        fi

        echo ""
    done

    # Print overall summary if multiple modules
    if [[ $total_modules -gt 1 ]]; then
        echo "════════════════════════════════════════════════════════"
        echo "📊 Overall Validation Summary"
        echo "════════════════════════════════════════════════════════"
        echo "  Total Modules: $total_modules"
        echo "  Passed: $passed_modules"
        echo "  Failed: $failed_modules"
        echo ""

        if [[ $failed_modules -eq 0 ]]; then
            echo -e "${GREEN}✅ ALL MODULES PASSED${NC}"
            return 0
        else
            echo -e "${RED}❌ SOME MODULES FAILED${NC}"
            return 1
        fi
    fi

    # Return based on single module result
    [[ $failed_modules -eq 0 ]] && return 0 || return 1
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
