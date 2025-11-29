#!/usr/bin/env bash
# lib/docs/dashboard.sh - Dashboard generation utilities (Orchestrator)
# Coordinates statistics collection and rendering for project dashboards
#
# This file acts as an orchestrator, sourcing modular components:
# - lib/docs/dashboard/stats.sh  - Statistics collection and calculation
# - lib/docs/dashboard/render.sh - Output rendering (markdown, JSON, CSV)

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_DASHBOARD_SH_SOURCED:-}" ]] && return 0
readonly _DASHBOARD_SH_SOURCED=1

# Dashboard constants
readonly DASHBOARD_VERSION="1.0.0"
readonly DASHBOARD_FEATURE="006-task-archive-consolidation"

# Determine script directory for relative sourcing
SCRIPT_DIR="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="${SCRIPT_DIR%/*}"

# Source modular components
# shellcheck source=lib/docs/dashboard/stats.sh
if [[ -f "${SCRIPT_DIR}/dashboard/stats.sh" ]]; then
    source "${SCRIPT_DIR}/dashboard/stats.sh"
fi

# shellcheck source=lib/docs/dashboard/render.sh
if [[ -f "${SCRIPT_DIR}/dashboard/render.sh" ]]; then
    source "${SCRIPT_DIR}/dashboard/render.sh"
fi

#######################################
# Generate complete markdown dashboard
# Arguments:
#   $1 - Path to temp file with TSV spec statistics
#   $2 - Archive directory path (optional)
# Outputs:
#   Complete markdown dashboard
#######################################
generate_markdown_dashboard() {
    local temp_file="$1"
    local archive_dir="${2:-}"

    # Calculate aggregates
    eval "$(calculate_aggregate_stats "$temp_file")"

    local overall_pct=0
    if [[ "$total_tasks" -gt 0 ]]; then
        overall_pct=$((total_completed * 100 / total_tasks))
    fi

    local remaining_tasks=$((total_tasks - total_completed))
    local remaining_days=$(( (remaining_tasks + 7) / 8 ))

    # Generate header
    cat <<EOF
# Project Status Dashboard

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Version**: $DASHBOARD_VERSION

EOF

    # Generate summary metrics
    generate_summary_metrics "$total_specs" "$overall_pct" "$total_completed" \
        "$total_tasks" "$completed_specs" "$in_progress_specs" \
        "$questionable_specs" "$remaining_days"

    echo ""

    # Generate status distribution
    generate_status_distribution "$completed_specs" "$in_progress_specs" \
        "$questionable_specs" "$abandoned_specs" "$total_specs"

    echo ""

    # Generate specification details
    generate_spec_details_header

    while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        generate_spec_details_row "$spec_id" "$spec_title" "$status" \
            "$total" "$completed" "$pct"
    done < "$temp_file"

    # Generate archive statistics if applicable
    if [[ -n "$archive_dir" ]] && [[ "$archived_count" -gt 0 ]]; then
        generate_archive_stats "$archived_count" "$archive_dir"
    fi

    # Generate notes section
    generate_notes_section "$temp_file"
}

#######################################
# Generate dashboard in requested format
# Arguments:
#   $1 - Path to temp file with TSV spec statistics
#   $2 - Format (markdown, json, csv)
#   $3 - Archive directory path (optional)
# Outputs:
#   Dashboard in requested format
#######################################
generate_dashboard() {
    local temp_file="$1"
    local format="${2:-markdown}"
    local archive_dir="${3:-}"

    case "$format" in
        markdown|md)
            generate_markdown_dashboard "$temp_file" "$archive_dir"
            ;;
        json)
            generate_json_format "$temp_file"
            ;;
        csv)
            generate_csv_format < "$temp_file"
            ;;
        *)
            echo "ERROR: Unknown format: $format" >&2
            echo "Supported formats: markdown, json, csv" >&2
            return 1
            ;;
    esac
}

# Export orchestrator functions
export -f generate_markdown_dashboard generate_dashboard

# Re-export functions from sourced modules for backward compatibility
# Stats functions
export -f classify_status get_status_emoji 2>/dev/null || true
export -f calculate_aggregate_stats calculate_overall_completion 2>/dev/null || true
export -f calculate_remaining_days count_specs_by_status 2>/dev/null || true
export -f safe_percentage calculate_archive_stats 2>/dev/null || true

# Render functions
export -f generate_summary_metrics generate_status_distribution 2>/dev/null || true
export -f generate_spec_details_header generate_spec_details_row 2>/dev/null || true
export -f generate_archive_stats generate_notes_section 2>/dev/null || true
export -f generate_json_format generate_csv_format 2>/dev/null || true
