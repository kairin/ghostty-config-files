#!/bin/bash
# Module: validate_module_deps.sh
# Purpose: Detects circular dependencies between bash modules using topological sort
# Dependencies: grep, awk
# Modules Required: None
# Exit Codes: 0=no cycles, 1=cycles detected, 2=usage error

set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ============================================================
# DEPENDENCY GRAPH FUNCTIONS
# ============================================================

# Extract module name from file path
get_module_name() {
    local file_path="$1"
    basename "$file_path" .sh
}

# Extract required modules from module header
get_required_modules() {
    local module_file="$1"

    # Look for "# Modules Required:" line and extract value
    local modules_line=$(grep "^# Modules Required:" "$module_file" 2>/dev/null || echo "")

    if [[ -z "$modules_line" ]]; then
        echo ""
        return
    fi

    # Extract comma-separated list after colon
    local modules=$(echo "$modules_line" | sed 's/^# Modules Required:\s*//' | sed 's/None//')

    # Clean up whitespace and split by comma
    echo "$modules" | tr ',' '\n' | sed 's/^\s*//;s/\s*$//' | grep -v '^$' || echo ""
}

# Build dependency graph from all modules
build_dependency_graph() {
    local modules_dir="$1"
    declare -gA GRAPH  # Global associative array for dependency graph
    declare -ga MODULES  # Global array of all module names

    echo "📊 Building dependency graph..."

    # Find all .sh files in modules directory (excluding templates)
    local module_files=$(find "$modules_dir" -maxdepth 1 -type f -name "*.sh" ! -name ".*" 2>/dev/null || echo "")

    if [[ -z "$module_files" ]]; then
        echo "  No modules found in $modules_dir"
        return 1
    fi

    local count=0
    while IFS= read -r module_file; do
        [[ -z "$module_file" ]] && continue

        local module_name=$(get_module_name "$module_file")
        MODULES+=("$module_name")

        # Get dependencies for this module
        local deps=$(get_required_modules "$module_file")

        if [[ -n "$deps" ]]; then
            GRAPH["$module_name"]="$deps"
            echo "  $module_name → $deps"
            ((count++))
        else
            GRAPH["$module_name"]=""
            echo "  $module_name (no dependencies)"
        fi
    done <<< "$module_files"

    echo "  Total modules: ${#MODULES[@]}"
    echo "  Modules with dependencies: $count"
    return 0
}

# Perform topological sort using Kahn's algorithm
# Returns 0 if no cycles, 1 if cycles detected
detect_cycles() {
    declare -A in_degree
    declare -A adj_list
    local queue=()

    echo ""
    echo "🔍 Analyzing dependencies for cycles..."

    # Initialize in-degree for all modules
    for module in "${MODULES[@]}"; do
        in_degree["$module"]=0
    done

    # Build adjacency list and calculate in-degrees
    for module in "${MODULES[@]}"; do
        local deps="${GRAPH[$module]}"
        if [[ -n "$deps" ]]; then
            while IFS= read -r dep; do
                [[ -z "$dep" ]] && continue

                # Add edge: dep -> module (module depends on dep)
                if [[ -n "${adj_list[$dep]:-}" ]]; then
                    adj_list["$dep"]="${adj_list[$dep]} $module"
                else
                    adj_list["$dep"]="$module"
                fi

                # Increment in-degree of module
                ((in_degree["$module"]++))
            done <<< "$deps"
        fi
    done

    # Find all modules with in-degree 0 (no dependencies)
    for module in "${MODULES[@]}"; do
        if [[ ${in_degree[$module]} -eq 0 ]]; then
            queue+=("$module")
        fi
    done

    echo "  Modules with no dependencies: ${#queue[@]}"

    # Process queue (topological sort)
    local sorted_count=0
    local sorted_order=()

    while [[ ${#queue[@]} -gt 0 ]]; do
        # Dequeue first element
        local current="${queue[0]}"
        queue=("${queue[@]:1}")

        sorted_order+=("$current")
        ((sorted_count++))

        # Process neighbors (modules that depend on current)
        local neighbors="${adj_list[$current]:-}"
        if [[ -n "$neighbors" ]]; then
            for neighbor in $neighbors; do
                ((in_degree["$neighbor"]--))

                if [[ ${in_degree[$neighbor]} -eq 0 ]]; then
                    queue+=("$neighbor")
                fi
            done
        fi
    done

    echo ""
    echo "  Topological sort completed"
    echo "  Modules processed: $sorted_count / ${#MODULES[@]}"

    # Check for cycles
    if [[ $sorted_count -lt ${#MODULES[@]} ]]; then
        echo -e "  ${RED}✗${NC} Cycle detected!"
        echo ""
        echo "  Modules involved in cycle:"

        # Find modules that couldn't be sorted (in_degree > 0)
        local cycle_modules=()
        for module in "${MODULES[@]}"; do
            if [[ ${in_degree[$module]} -gt 0 ]]; then
                cycle_modules+=("$module")
                echo -e "    ${RED}•${NC} $module (depends on: ${GRAPH[$module]})"
            fi
        done

        echo ""
        echo -e "${RED}❌ CIRCULAR DEPENDENCY DETECTED${NC}"
        echo "  Fix required: Break the circular dependency chain"
        return 1
    else
        echo -e "  ${GREEN}✓${NC} No cycles detected"
        echo ""
        echo "  Valid build order:"
        for i in "${!sorted_order[@]}"; do
            echo "    $((i+1)). ${sorted_order[$i]}"
        done
        echo ""
        echo -e "${GREEN}✅ DEPENDENCY GRAPH IS VALID${NC}"
        return 0
    fi
}

# ============================================================
# REPORTING FUNCTIONS
# ============================================================

# Generate dependency graph visualization (text-based)
generate_graph_report() {
    echo ""
    echo "════════════════════════════════════════════════════════"
    echo "📈 Dependency Graph Report"
    echo "════════════════════════════════════════════════════════"
    echo ""

    for module in "${MODULES[@]}"; do
        local deps="${GRAPH[$module]}"
        if [[ -n "$deps" ]]; then
            echo -e "${BLUE}$module${NC}"
            while IFS= read -r dep; do
                [[ -z "$dep" ]] && continue
                echo "  ├─→ $dep"
            done <<< "$deps"
        else
            echo -e "${GREEN}$module${NC} (leaf node)"
        fi
        echo ""
    done
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $0 <modules_directory>"
        echo ""
        echo "Validates bash module dependencies for circular references"
        echo ""
        echo "  Analyzes module headers (# Modules Required:) and performs"
        echo "  topological sort to detect dependency cycles."
        echo ""
        echo "Example:"
        echo "  $0 ./scripts"
        return 2
    fi

    local modules_dir="$1"

    if [[ ! -d "$modules_dir" ]]; then
        echo -e "${RED}Error:${NC} Directory not found: $modules_dir"
        return 2
    fi

    echo "════════════════════════════════════════════════════════"
    echo "🔗 Module Dependency Validation"
    echo "════════════════════════════════════════════════════════"
    echo "  Directory: $modules_dir"
    echo ""

    # Build dependency graph
    if ! build_dependency_graph "$modules_dir"; then
        echo -e "${YELLOW}Warning:${NC} No modules found or error building graph"
        return 0
    fi

    # Detect cycles
    if detect_cycles; then
        # No cycles - generate report
        generate_graph_report
        return 0
    else
        # Cycles detected
        generate_graph_report
        return 1
    fi
}

# Run main if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
    exit $?
fi
