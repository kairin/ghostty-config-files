#!/usr/bin/env bash
# generate_dashboard.sh - Generate project status dashboard
# Orchestrates dashboard generation using modular components from lib/docs/

set -euo pipefail

# Script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source modular components
source "$REPO_ROOT/lib/docs/dashboard.sh"
source "$REPO_ROOT/lib/archive/validators.sh" 2>/dev/null || true

# Configuration
DRY_RUN=false
OUTPUT_FILE="PROJECT_STATUS_DASHBOARD.md"
INCLUDE_ARCHIVED=true
SHOW_DETAILS=false
FORMAT="markdown"  # markdown, json, csv
ARCHIVE_DIR="${REPO_ROOT}/archive"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_NO_SPECS=4

# Version
readonly VERSION="1.0.0"
readonly FEATURE="006-task-archive-consolidation"

# Utility functions
print_error() { echo "ERROR: $*" >&2; }
print_info() { echo "$1 $2"; }
print_success() { echo "SUCCESS: $*"; }

#######################################
# Display help message
#######################################
show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Generate comprehensive status dashboard showing completion metrics, remaining
work estimates, and archive statistics for all specifications.

OPTIONS:
  --output FILE         Output dashboard file (default: $OUTPUT_FILE)
  --include-archived    Include archived specs in stats (default: true)
  --no-include-archived Exclude archived specs from stats
  --show-details        Include per-phase breakdown
  --format FORMAT       Output format: markdown, json, csv (default: markdown)
  --dry-run             Show output without writing file
  --help                Show this help message
  --version             Show version information

EXIT CODES:
  0 - Success - dashboard generated
  1 - General error (invalid arguments, missing dependencies)
  4 - No specifications found
EOF
}

show_version() {
    echo "$(basename "$0") version $VERSION"
    echo "Feature: $FEATURE"
}

#######################################
# Discover specifications in repository
#######################################
discover_specifications() {
    # shellcheck disable=SC2038 # Using -I {} placeholder safely handles spaces
    find "$REPO_ROOT" -type d -name "spec-kit" -prune -o \
         -type f -name "tasks.md" -print 2>/dev/null | \
         xargs -I {} dirname {} | sort -u
}

#######################################
# Check if specification is valid
#######################################
is_valid_specification() {
    local spec_dir="$1"
    [[ -d "$spec_dir" ]] && [[ -f "$spec_dir/tasks.md" ]]
}

#######################################
# Helper functions for spec analysis
#######################################
get_spec_id() { basename "$1"; }
get_spec_title() {
    local spec_file="$1/spec.md"
    [[ -f "$spec_file" ]] && grep -m1 '^# ' "$spec_file" | sed 's/^# //' || echo "Unknown"
}
count_total_tasks() { grep -cE '^- \[([ xX])\]' "$1" 2>/dev/null || echo "0"; }
count_completed_tasks() { grep -cE '^- \[[xX]\]' "$1" 2>/dev/null || echo "0"; }
calculate_completion_percentage() {
    local completed="$1" total="$2"
    [[ "$total" -eq 0 ]] && echo "0" || echo "$(( (completed * 100) / total ))"
}
has_yq() { command -v yq >/dev/null 2>&1; }

#######################################
# Collect specification statistics
#######################################
collect_spec_statistics() {
    while IFS= read -r spec_dir; do
        is_valid_specification "$spec_dir" || continue

        local spec_id spec_title tasks_file total completed pct status
        spec_id=$(get_spec_id "$spec_dir")
        spec_title=$(get_spec_title "$spec_dir")
        tasks_file="$spec_dir/tasks.md"
        total=$(count_total_tasks "$tasks_file")
        completed=$(count_completed_tasks "$tasks_file")
        pct=$(calculate_completion_percentage "$completed" "$total")
        status=$(classify_status "$pct")

        echo "$spec_id	$spec_title	$status	$total	$completed	$pct	$spec_dir"
    done < <(discover_specifications)

    # Include archived specs if requested
    if [[ "$INCLUDE_ARCHIVED" == "true" ]] && [[ -d "$ARCHIVE_DIR" ]]; then
        while IFS= read -r archive_file; do
            [[ -f "$archive_file" ]] || continue
            local spec_id spec_title total completed pct status
            spec_id=$(basename "$archive_file" .yaml)
            spec_title="Archived"
            total=0 completed=0 pct=100 status="completed"

            if has_yq; then
                spec_title=$(yq eval '.title' "$archive_file" 2>/dev/null || echo "Archived")
                pct=$(yq eval '.completion_percentage' "$archive_file" 2>/dev/null || echo "100")
                total=$(yq eval '.tasks.total' "$archive_file" 2>/dev/null || echo "0")
                completed=$(yq eval '.tasks.completed' "$archive_file" 2>/dev/null || echo "0")
            fi

            echo "$spec_id	$spec_title	$status	$total	$completed	$pct	[archived]"
        done < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name "*.yaml" 2>/dev/null || true)
    fi
}

#######################################
# Generate markdown dashboard
#######################################
generate_markdown_dashboard() {
    local temp_file="$1"

    # Calculate aggregates
    eval "$(calculate_aggregate_stats "$temp_file")"

    local overall_pct=0 remaining_tasks remaining_days
    [[ "$total_tasks" -gt 0 ]] && overall_pct=$(( (total_completed * 100) / total_tasks ))
    remaining_tasks=$((total_tasks - total_completed))
    remaining_days=$(( (remaining_tasks + 7) / 8 ))

    # Generate header
    cat <<EOF
# Project Status Dashboard

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Repository**: $(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
**Branch**: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

EOF

    # Generate summary and distribution
    generate_summary_metrics "$total_specs" "$overall_pct" "$total_completed" "$total_tasks" \
                            "$completed_specs" "$in_progress_specs" "$questionable_specs" "$remaining_days"
    echo ""
    generate_status_distribution "$completed_specs" "$in_progress_specs" "$questionable_specs" \
                                "$abandoned_specs" "$total_specs"
    echo ""
    generate_spec_details_header

    # Generate spec rows (sorted by completion)
    sort -t$'\t' -k6,6nr -k1,1 "$temp_file" | while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        generate_spec_details_row "$spec_id" "$spec_title" "$status" "$total" "$completed" "$pct"
    done

    # Generate archive stats and notes
    generate_archive_stats "$archived_count" "$ARCHIVE_DIR"
    generate_notes_section "$temp_file"
}

#######################################
# Main function
#######################################
main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output) OUTPUT_FILE="$2"; shift 2 ;;
            --include-archived) INCLUDE_ARCHIVED=true; shift ;;
            --no-include-archived) INCLUDE_ARCHIVED=false; shift ;;
            --show-details) SHOW_DETAILS=true; shift ;;
            --format)
                FORMAT="$2"
                [[ "$FORMAT" =~ ^(markdown|json|csv)$ ]] || { print_error "Invalid format: $FORMAT"; exit "$EXIT_ERROR"; }
                shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) show_help; exit "$EXIT_SUCCESS" ;;
            --version) show_version; exit "$EXIT_SUCCESS" ;;
            -*) print_error "Unknown option: $1"; exit "$EXIT_ERROR" ;;
            *) print_error "Unexpected argument: $1"; exit "$EXIT_ERROR" ;;
        esac
    done

    print_info "[SCAN]" "Scanning repository..."

    local temp_file
    temp_file=$(mktemp)
    trap 'rm -f "$temp_file"' EXIT

    collect_spec_statistics > "$temp_file"

    local spec_count
    spec_count=$(wc -l < "$temp_file")

    if [[ "$spec_count" -eq 0 ]]; then
        print_error "No specifications found"
        exit "$EXIT_NO_SPECS"
    fi

    print_info "[STATS]" "Found $spec_count specifications"

    # Generate dashboard
    local output
    case "$FORMAT" in
        markdown) output=$(generate_markdown_dashboard "$temp_file") ;;
        json) output=$(generate_json_format "$temp_file") ;;
        csv) output=$(generate_csv_format < "$temp_file") ;;
    esac

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "$output"
    else
        echo "$output" > "$OUTPUT_FILE"
        print_success "Dashboard generated: $OUTPUT_FILE"
    fi

    exit "$EXIT_SUCCESS"
}

main "$@"
