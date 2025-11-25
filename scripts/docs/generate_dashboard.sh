#!/usr/bin/env bash
# generate_dashboard.sh - Generate project status dashboard


# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common utilities
# shellcheck source=scripts/archive_common.sh
source "$SCRIPT_DIR/archive_common.sh"

# Configuration
DRY_RUN=false
OUTPUT_FILE="PROJECT_STATUS_DASHBOARD.md"
INCLUDE_ARCHIVED=true
SHOW_DETAILS=false
FORMAT="markdown"  # markdown, json, csv

# Version
readonly VERSION="1.0.0"
readonly FEATURE="006-task-archive-consolidation"

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

EXAMPLES:
  # Generate status dashboard
  $(basename "$0")

  # Exclude archived specs from calculations
  $(basename "$0") --no-include-archived

  # Show per-phase breakdown
  $(basename "$0") --show-details

  # Output as JSON
  $(basename "$0") --format json

  # Preview without writing
  $(basename "$0") --dry-run

  # Custom output location
  $(basename "$0") --output docs/status.md

EOF
}

#######################################
# Display version information
#######################################
show_version() {
    echo "$(basename "$0") version $VERSION"
    echo "Feature: $FEATURE"
}

#######################################
# Classify specification status
# Arguments:
#   $1 - Completion percentage
# Outputs:
#   Status: completed, in-progress, questionable, abandoned
#######################################
classify_status() {
    local completion_pct="$1"

    if [ "$completion_pct" -eq 100 ]; then
        echo "completed"
    elif [ "$completion_pct" -ge 20 ]; then
        echo "in-progress"
    elif [ "$completion_pct" -gt 0 ]; then
        echo "questionable"
    else
        echo "abandoned"
    fi
}

#######################################
# Get status emoji
# Arguments:
#   $1 - Status (completed, in-progress, questionable, abandoned)
# Outputs:
#   Emoji indicator
#######################################
get_status_emoji() {
    local status="$1"

    case "$status" in
        completed)
            echo "✅"
            ;;
        in-progress)
            echo "🔄"
            ;;
        questionable)
            echo "⚠️"
            ;;
        abandoned)
            echo "❌"
            ;;
        *)
            echo "❓"
            ;;
    esac
}

#######################################
# Collect specification statistics
# Outputs:
#   TSV lines: spec_id<TAB>title<TAB>status<TAB>total<TAB>completed<TAB>percentage<TAB>location
#######################################
collect_spec_statistics() {
    while IFS= read -r spec_dir; do
        if ! is_valid_specification "$spec_dir"; then
            continue
        fi

        local spec_id
        spec_id=$(get_spec_id "$spec_dir")
        local spec_title
        spec_title=$(get_spec_title "$spec_dir")
        local tasks_file="$spec_dir/tasks.md"

        local total
        total=$(count_total_tasks "$tasks_file")
        local completed
        completed=$(count_completed_tasks "$tasks_file")
        local pct
        pct=$(calculate_completion_percentage "$completed" "$total")

        local status
        status=$(classify_status "$pct")

        echo "$spec_id	$spec_title	$status	$total	$completed	$pct	$spec_dir"
    done < <(discover_specifications)

    # Include archived specs if requested
    if [ "$INCLUDE_ARCHIVED" = true ] && [ -d "$ARCHIVE_DIR" ]; then
        while IFS= read -r archive_file; do
            if [ -f "$archive_file" ]; then
                local spec_id
                spec_id=$(basename "$archive_file" .yaml)

                # Extract data from YAML archive
                local spec_title="Archived"
                local total=0
                local completed=0
                local pct=100
                local status="completed"

                if has_yq; then
                    spec_title=$(yq eval '.title' "$archive_file" 2>/dev/null || echo "Archived")
                    pct=$(yq eval '.completion_percentage' "$archive_file" 2>/dev/null || echo "100")
                    total=$(yq eval '.tasks.total' "$archive_file" 2>/dev/null || echo "0")
                    completed=$(yq eval '.tasks.completed' "$archive_file" 2>/dev/null || echo "0")
                    status=$(yq eval '.status' "$archive_file" 2>/dev/null || echo "completed")
                fi

                echo "$spec_id	$spec_title	$status	$total	$completed	$pct	[archived]"
            fi
        done < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name "*.yaml" 2>/dev/null || true)
    fi
}

#######################################
# Generate markdown dashboard
# Arguments:
#   stdin - TSV specification statistics
# Outputs:
#   Markdown dashboard
#######################################
generate_markdown_dashboard() {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file"

    local total_specs=0
    local total_tasks=0
    local total_completed=0
    local completed_specs=0
    local in_progress_specs=0
    local questionable_specs=0
    local abandoned_specs=0
    local archived_count=0

    # Calculate aggregate statistics
    while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        total_specs=$((total_specs + 1))
        total_tasks=$((total_tasks + total))
        total_completed=$((total_completed + completed))

        case "$status" in
            completed)
                completed_specs=$((completed_specs + 1))
                if [[ "$location" == "[archived]" ]]; then
                    archived_count=$((archived_count + 1))
                fi
                ;;
            in-progress)
                in_progress_specs=$((in_progress_specs + 1))
                ;;
            questionable)
                questionable_specs=$((questionable_specs + 1))
                ;;
            abandoned)
                abandoned_specs=$((abandoned_specs + 1))
                ;;
        esac
    done < "$temp_file"

    local overall_pct=0
    if [ "$total_tasks" -gt 0 ]; then
        overall_pct=$(( (total_completed * 100) / total_tasks ))
    fi

    # Calculate remaining effort (simple heuristic: 1 day per 8 tasks)
    local remaining_tasks=$((total_tasks - total_completed))
    local remaining_days=$(( (remaining_tasks + 7) / 8 ))  # Round up

    # Generate dashboard
    cat <<EOF
# Project Status Dashboard

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')
**Repository**: $(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
**Branch**: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || "unknown")

## Summary Metrics

| Metric | Value |
|--------|-------|
| Total Specifications | $total_specs |
| Overall Completion | ${overall_pct}% ($total_completed/$total_tasks tasks) |
| Completed Specs | $completed_specs/$total_specs ($(( (completed_specs * 100) / total_specs ))%) |
| In Progress Specs | $in_progress_specs/$total_specs ($(( (in_progress_specs * 100) / total_specs ))%) |
| Questionable Specs | $questionable_specs/$total_specs ($(( (questionable_specs * 100) / total_specs ))%) |
| Estimated Remaining Work | $remaining_days days |

## Status Distribution

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Completed | $completed_specs | $(( (completed_specs * 100) / total_specs ))% |
| 🔄 In Progress | $in_progress_specs | $(( (in_progress_specs * 100) / total_specs ))% |
| ⚠️ Questionable | $questionable_specs | $(( (questionable_specs * 100) / total_specs ))% |
| ❌ Abandoned | $abandoned_specs | $(( (abandoned_specs * 100) / total_specs ))% |

## Specification Details

| Spec ID | Title | Status | Progress | Remaining | Est. Effort |
|---------|-------|--------|----------|-----------|-------------|
EOF

    # Sort by completion percentage (descending) then spec ID
    sort -t$'\t' -k6,6nr -k1,1 "$temp_file" | while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        local remaining=$((total - completed))
        local effort_days=$(( (remaining + 7) / 8 ))
        local effort_str="${effort_days} days"
        if [ "$remaining" -eq 0 ]; then
            effort_str="0 days"
        fi

        local status_emoji
        status_emoji=$(get_status_emoji "$status")
        local status_label="${status_emoji} ${status^}"

        echo "| $spec_id | $spec_title | $status_label | $completed/$total (${pct}%) | $remaining tasks | $effort_str |"
    done

    if [ "$archived_count" -gt 0 ]; then
        cat <<EOF

## Archive Statistics

| Metric | Value |
|--------|-------|
| Archived Specifications | $archived_count |

EOF
        if [ -d "$ARCHIVE_DIR" ]; then
            local original_lines=0
            local archive_lines=0

            while IFS= read -r archive_file; do
                if [ -f "$archive_file" ]; then
                    archive_lines=$((archive_lines + $(wc -l < "$archive_file")))

                    local spec_id
                    spec_id=$(basename "$archive_file" .yaml)
                    local original_dir="$ARCHIVE_DIR/${spec_id}-original"

                    if [ -d "$original_dir" ]; then
                        while IFS= read -r file; do
                            original_lines=$((original_lines + $(wc -l < "$file")))
                        done < <(find "$original_dir" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null || true)
                    fi
                fi
            done < <(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name "*.yaml" 2>/dev/null || true)

            if [ "$original_lines" -gt 0 ]; then
                local savings=$(( 100 - (archive_lines * 100 / original_lines) ))
                cat <<EOF
| Total Original Lines | $original_lines |
| Total Archive Lines | $archive_lines |
| Space Savings | ${savings}% reduction |
EOF
            fi
        fi
    fi

    # Add notes section if there are questionable or in-progress specs
    if [ "$in_progress_specs" -gt 0 ] || [ "$questionable_specs" -gt 0 ]; then
        cat <<EOF

## Notes

EOF
        while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
            if [[ "$status" == "in-progress" ]] || [[ "$status" == "questionable" ]]; then
                local remaining=$((total - completed))
                cat <<EOF
### $spec_id - $spec_title
- **Status**: ${status^} (${pct}%)
- **Remaining**: $remaining tasks
EOF
                if [[ "$status" == "questionable" ]]; then
                    echo "- **Recommendation**: Re-evaluate scope or abandon"
                elif [ "$pct" -ge 75 ]; then
                    echo "- **Recommendation**: Nearly complete, worth finishing"
                fi
                echo ""
            fi
        done < <(sort -t$'\t' -k6,6nr "$temp_file")
    fi

    rm -f "$temp_file"
}

#######################################
# Generate JSON dashboard
# Arguments:
#   stdin - TSV specification statistics
# Outputs:
#   JSON dashboard
#######################################
generate_json_dashboard() {
    local temp_file
    temp_file=$(mktemp)
    cat > "$temp_file"

    local total_specs=0
    local total_tasks=0
    local total_completed=0
    local completed_specs=0
    local in_progress_specs=0
    local questionable_specs=0

    # Calculate aggregate statistics
    while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        total_specs=$((total_specs + 1))
        total_tasks=$((total_tasks + total))
        total_completed=$((total_completed + completed))

        case "$status" in
            completed) completed_specs=$((completed_specs + 1)) ;;
            in-progress) in_progress_specs=$((in_progress_specs + 1)) ;;
            questionable) questionable_specs=$((questionable_specs + 1)) ;;
        esac
    done < "$temp_file"

    local overall_pct=0
    if [ "$total_tasks" -gt 0 ]; then
        overall_pct=$(( (total_completed * 100) / total_tasks ))
    fi

    # Start JSON
    echo "{"
    echo "  \"generated\": \"$(date -Iseconds)\","
    echo "  \"repository\": \"$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")\","
    echo "  \"summary\": {"
    echo "    \"total_specifications\": $total_specs,"
    echo "    \"overall_completion\": $overall_pct,"
    echo "    \"total_tasks\": $total_tasks,"
    echo "    \"completed_tasks\": $total_completed,"
    echo "    \"completed_specs\": $completed_specs,"
    echo "    \"in_progress_specs\": $in_progress_specs,"
    echo "    \"questionable_specs\": $questionable_specs"
    echo "  },"
    echo "  \"specifications\": ["

    local first=true
    while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi

        echo -n "    {"
        echo -n "\"id\": \"$spec_id\", "
        echo -n "\"title\": \"$spec_title\", "
        echo -n "\"status\": \"$status\", "
        echo -n "\"total_tasks\": $total, "
        echo -n "\"completed_tasks\": $completed, "
        echo -n "\"completion_percentage\": $pct"
        echo -n "}"
    done < "$temp_file"

    echo ""
    echo "  ]"
    echo "}"

    rm -f "$temp_file"
}

#######################################
# Generate CSV dashboard
# Arguments:
#   stdin - TSV specification statistics
# Outputs:
#   CSV dashboard
#######################################
generate_csv_dashboard() {
    echo "Spec ID,Title,Status,Total Tasks,Completed Tasks,Completion %,Location"

    while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        echo "\"$spec_id\",\"$spec_title\",\"$status\",$total,$completed,$pct,\"$location\""
    done
}

#######################################
# Main function
#######################################
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --include-archived)
                INCLUDE_ARCHIVED=true
                shift
                ;;
            --no-include-archived)
                INCLUDE_ARCHIVED=false
                shift
                ;;
            --show-details)
                SHOW_DETAILS=true
                shift
                ;;
            --format)
                FORMAT="$2"
                if [[ ! "$FORMAT" =~ ^(markdown|json|csv)$ ]]; then
                    print_error "Invalid format: $FORMAT"
                    echo "Use: markdown, json, or csv" >&2
                    exit "$EXIT_ERROR"
                fi
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --help)
                show_help
                exit "$EXIT_SUCCESS"
                ;;
            --version)
                show_version
                exit "$EXIT_SUCCESS"
                ;;
            -*)
                print_error "Unknown option: $1"
                echo "Use --help for usage information" >&2
                exit "$EXIT_ERROR"
                ;;
            *)
                print_error "Unexpected argument: $1"
                echo "Use --help for usage information" >&2
                exit "$EXIT_ERROR"
                ;;
        esac
    done

    print_info "$EMOJI_SCAN" "Scanning repository..."

    # Collect specification statistics
    local temp_file
    temp_file=$(mktemp)
    trap 'rm -f "$temp_file"' EXIT

    collect_spec_statistics > "$temp_file"

    local spec_count
    spec_count=$(wc -l < "$temp_file")

    if [ "$spec_count" -eq 0 ]; then
        print_error "No specifications found"
        exit "$EXIT_NO_SPECS"
    fi

    print_info "$EMOJI_STATS" "Found $spec_count specifications"

    # Generate dashboard based on format
    local output
    case "$FORMAT" in
        markdown)
            output=$(generate_markdown_dashboard < "$temp_file")
            ;;
        json)
            output=$(generate_json_dashboard < "$temp_file")
            ;;
        csv)
            output=$(generate_csv_dashboard < "$temp_file")
            ;;
    esac

    # Output results
    if [ "$DRY_RUN" = true ]; then
        echo "$output"
    else
        echo "$output" > "$OUTPUT_FILE"
        print_success "Dashboard generated: $OUTPUT_FILE"
    fi

    exit "$EXIT_SUCCESS"
}

# Run main function
main "$@"
