#!/usr/bin/env bash
# lib/todos/report.sh - TODO report generation utilities (Orchestrator)
# Dispatches to format-specific reporters for markdown and JSON output
#
# This file acts as an orchestrator, sourcing modular components:
# - lib/todos/reporters/markdown.sh - Markdown report generation
# - lib/todos/reporters/json.sh     - JSON report generation

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_TODOS_REPORT_SOURCED:-}" ]] && return 0
readonly _TODOS_REPORT_SOURCED=1

# Determine script directory for relative sourcing
SCRIPT_DIR="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="${SCRIPT_DIR%/*}"

# Source modular components
# shellcheck source=lib/todos/reporters/markdown.sh
if [[ -f "${SCRIPT_DIR}/reporters/markdown.sh" ]]; then
    source "${SCRIPT_DIR}/reporters/markdown.sh"
fi

# shellcheck source=lib/todos/reporters/json.sh
if [[ -f "${SCRIPT_DIR}/reporters/json.sh" ]]; then
    source "${SCRIPT_DIR}/reporters/json.sh"
fi

#######################################
# Calculate total effort from task data
# Arguments:
#   stdin - TSV task data with effort field
# Outputs:
#   Total effort estimate string
#######################################
calculate_total_effort() {
    local total_hours=0
    local total_min_hours=0
    local total_max_hours=0
    local has_ranges=false

    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [[ -n "$effort" ]]; then
            local hours
            hours=$(parse_effort_to_hours "$effort" 2>/dev/null || echo "")

            if echo "$hours" | grep -q '-'; then
                # Range
                has_ranges=true
                local min_hours max_hours
                min_hours=$(echo "$hours" | cut -d'-' -f1)
                max_hours=$(echo "$hours" | cut -d'-' -f2)
                total_min_hours=$((total_min_hours + min_hours))
                total_max_hours=$((total_max_hours + max_hours))
            elif [[ -n "$hours" ]]; then
                # Single value
                total_hours=$((total_hours + hours))
            fi
        fi
    done

    if [[ "$has_ranges" == "true" ]]; then
        # Convert to days
        local min_days=$((total_min_hours / 8))
        local max_days=$((total_max_hours / 8))
        echo "$min_days-$max_days days"
    elif [[ "$total_hours" -gt 0 ]]; then
        local days=$((total_hours / 8))
        if [[ "$days" -gt 0 ]]; then
            echo "$days days"
        else
            echo "$total_hours hours"
        fi
    else
        echo "Unknown"
    fi
}

#######################################
# Find specification directory by ID
# Arguments:
#   $1 - Specification ID
# Outputs:
#   Specification directory path
# Returns:
#   0 if found, 1 if not found
#######################################
find_spec_dir() {
    local spec_id="$1"

    # Search common locations
    local search_dirs=(
        "."
        "spec-kit"
        "specifications"
        "specs"
    )

    for base in "${search_dirs[@]}"; do
        if [[ -d "$base" ]]; then
            local found
            found=$(find "$base" -type d -name "$spec_id" 2>/dev/null | head -1)
            if [[ -n "$found" ]] && [[ -f "$found/tasks.md" ]]; then
                echo "$found"
                return 0
            fi

            # Also check for spec directories containing spec_id
            found=$(find "$base" -type d -name "*$spec_id*" 2>/dev/null | head -1)
            if [[ -n "$found" ]] && [[ -f "$found/tasks.md" ]]; then
                echo "$found"
                return 0
            fi
        fi
    done

    return 1
}

#######################################
# Sort task data by field
# Arguments:
#   $1 - Sort field (spec, priority, effort, phase)
#   stdin - TSV task data
# Outputs:
#   Sorted TSV data
#######################################
sort_tasks() {
    local sort_by="$1"

    case "$sort_by" in
        spec)
            sort -t$'\t' -k1,1 -k2,2
            ;;
        priority)
            sort -t$'\t' -k3,3 -k1,1 -k2,2
            ;;
        effort)
            sort -t$'\t' -k6,6 -k1,1 -k2,2
            ;;
        phase)
            sort -t$'\t' -k5,5 -k1,1 -k2,2
            ;;
        *)
            cat  # No sorting, pass through
            ;;
    esac
}

# Provide parse_effort_to_hours if not available from extractors
if ! declare -f parse_effort_to_hours &>/dev/null; then
    parse_effort_to_hours() {
        local effort="$1"
        if echo "$effort" | grep -qE '[0-9]+ days?'; then
            local days
            days=$(echo "$effort" | grep -oE '[0-9]+')
            echo "$((days * 8))"
        elif echo "$effort" | grep -qE '[0-9]+ hours?'; then
            echo "$effort" | grep -oE '[0-9]+'
        else
            echo ""
        fi
    }
fi

# Export orchestrator functions
export -f calculate_total_effort find_spec_dir sort_tasks parse_effort_to_hours

# Re-export functions from sourced modules for backward compatibility
# Markdown reporter functions
export -f generate_checklist_header generate_summary_stats 2>/dev/null || true
export -f group_by_specification group_by_priority group_by_phase 2>/dev/null || true
export -f generate_dependency_graph 2>/dev/null || true

# JSON reporter functions
export -f json_escape 2>/dev/null || true
export -f generate_json_header generate_json_stats 2>/dev/null || true
export -f generate_json_tasks generate_json_by_spec 2>/dev/null || true
export -f generate_complete_json_report 2>/dev/null || true
