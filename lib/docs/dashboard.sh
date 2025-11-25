#!/usr/bin/env bash
# lib/docs/dashboard.sh - Dashboard generation utilities
# Extracted from scripts/docs/generate_dashboard.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_DASHBOARD_SH_SOURCED:-}" ]] && return 0
readonly _DASHBOARD_SH_SOURCED=1

# Dashboard constants
readonly DASHBOARD_VERSION="1.0.0"
readonly DASHBOARD_FEATURE="006-task-archive-consolidation"

#######################################
# Classify specification status based on completion
# Arguments:
#   $1 - Completion percentage
# Outputs:
#   Status: completed, in-progress, questionable, abandoned
#######################################
classify_status() {
    local completion_pct="$1"

    if [[ "$completion_pct" -eq 100 ]]; then
        echo "completed"
    elif [[ "$completion_pct" -ge 20 ]]; then
        echo "in-progress"
    elif [[ "$completion_pct" -gt 0 ]]; then
        echo "questionable"
    else
        echo "abandoned"
    fi
}

#######################################
# Get status emoji/indicator
# Arguments:
#   $1 - Status (completed, in-progress, questionable, abandoned)
# Outputs:
#   Emoji indicator
#######################################
get_status_emoji() {
    local status="$1"

    case "$status" in
        completed)     echo "[OK]" ;;
        in-progress)   echo "[WIP]" ;;
        questionable)  echo "[?]" ;;
        abandoned)     echo "[X]" ;;
        *)             echo "[?]" ;;
    esac
}

#######################################
# Calculate aggregate statistics from spec data
# Arguments:
#   $1 - Path to temp file with TSV spec statistics
# Outputs:
#   Bash associative array assignments (eval-able)
#######################################
calculate_aggregate_stats() {
    local temp_file="$1"

    local total_specs=0
    local total_tasks=0
    local total_completed=0
    local completed_specs=0
    local in_progress_specs=0
    local questionable_specs=0
    local abandoned_specs=0
    local archived_count=0

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

    # Output as assignments
    echo "total_specs=$total_specs"
    echo "total_tasks=$total_tasks"
    echo "total_completed=$total_completed"
    echo "completed_specs=$completed_specs"
    echo "in_progress_specs=$in_progress_specs"
    echo "questionable_specs=$questionable_specs"
    echo "abandoned_specs=$abandoned_specs"
    echo "archived_count=$archived_count"
}

#######################################
# Generate markdown summary metrics table
# Arguments:
#   $1 - Total specs
#   $2 - Overall completion percentage
#   $3 - Total completed tasks
#   $4 - Total tasks
#   $5 - Completed specs
#   $6 - In-progress specs
#   $7 - Questionable specs
#   $8 - Remaining days estimate
#######################################
generate_summary_metrics() {
    local total_specs="$1"
    local overall_pct="$2"
    local total_completed="$3"
    local total_tasks="$4"
    local completed_specs="$5"
    local in_progress_specs="$6"
    local questionable_specs="$7"
    local remaining_days="$8"

    local completed_pct=$((completed_specs * 100 / total_specs))
    local in_progress_pct=$((in_progress_specs * 100 / total_specs))
    local questionable_pct=$((questionable_specs * 100 / total_specs))

    cat <<EOF
## Summary Metrics

| Metric | Value |
|--------|-------|
| Total Specifications | $total_specs |
| Overall Completion | ${overall_pct}% ($total_completed/$total_tasks tasks) |
| Completed Specs | $completed_specs/$total_specs (${completed_pct}%) |
| In Progress Specs | $in_progress_specs/$total_specs (${in_progress_pct}%) |
| Questionable Specs | $questionable_specs/$total_specs (${questionable_pct}%) |
| Estimated Remaining Work | $remaining_days days |
EOF
}

#######################################
# Generate status distribution table
# Arguments:
#   $1 - Completed specs count
#   $2 - In-progress specs count
#   $3 - Questionable specs count
#   $4 - Abandoned specs count
#   $5 - Total specs count
#######################################
generate_status_distribution() {
    local completed_specs="$1"
    local in_progress_specs="$2"
    local questionable_specs="$3"
    local abandoned_specs="$4"
    local total_specs="$5"

    local completed_pct=$((completed_specs * 100 / total_specs))
    local in_progress_pct=$((in_progress_specs * 100 / total_specs))
    local questionable_pct=$((questionable_specs * 100 / total_specs))
    local abandoned_pct=$((abandoned_specs * 100 / total_specs))

    cat <<EOF
## Status Distribution

| Status | Count | Percentage |
|--------|-------|------------|
| [OK] Completed | $completed_specs | ${completed_pct}% |
| [WIP] In Progress | $in_progress_specs | ${in_progress_pct}% |
| [?] Questionable | $questionable_specs | ${questionable_pct}% |
| [X] Abandoned | $abandoned_specs | ${abandoned_pct}% |
EOF
}

#######################################
# Generate specification details table header
#######################################
generate_spec_details_header() {
    cat <<EOF
## Specification Details

| Spec ID | Title | Status | Progress | Remaining | Est. Effort |
|---------|-------|--------|----------|-----------|-------------|
EOF
}

#######################################
# Generate specification details row
# Arguments:
#   $1 - Spec ID
#   $2 - Spec title
#   $3 - Status
#   $4 - Total tasks
#   $5 - Completed tasks
#   $6 - Completion percentage
#######################################
generate_spec_details_row() {
    local spec_id="$1"
    local spec_title="$2"
    local status="$3"
    local total="$4"
    local completed="$5"
    local pct="$6"

    local remaining=$((total - completed))
    local effort_days=$(((remaining + 7) / 8))
    local effort_str="${effort_days} days"
    if [[ "$remaining" -eq 0 ]]; then
        effort_str="0 days"
    fi

    local status_emoji
    status_emoji=$(get_status_emoji "$status")
    local status_label="${status_emoji} ${status^}"

    echo "| $spec_id | $spec_title | $status_label | $completed/$total (${pct}%) | $remaining tasks | $effort_str |"
}

#######################################
# Generate archive statistics section
# Arguments:
#   $1 - Archived count
#   $2 - Archive directory path
#######################################
generate_archive_stats() {
    local archived_count="$1"
    local archive_dir="$2"

    if [[ "$archived_count" -eq 0 ]]; then
        return
    fi

    cat <<EOF

## Archive Statistics

| Metric | Value |
|--------|-------|
| Archived Specifications | $archived_count |
EOF

    if [[ -d "$archive_dir" ]]; then
        local original_lines=0
        local archive_lines=0

        while IFS= read -r archive_file; do
            if [[ -f "$archive_file" ]]; then
                archive_lines=$((archive_lines + $(wc -l < "$archive_file")))

                local spec_id
                spec_id=$(basename "$archive_file" .yaml)
                local original_dir="$archive_dir/${spec_id}-original"

                if [[ -d "$original_dir" ]]; then
                    while IFS= read -r file; do
                        original_lines=$((original_lines + $(wc -l < "$file")))
                    done < <(find "$original_dir" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null || true)
                fi
            fi
        done < <(find "$archive_dir" -maxdepth 1 -type f -name "*.yaml" 2>/dev/null || true)

        if [[ "$original_lines" -gt 0 ]]; then
            local savings=$((100 - (archive_lines * 100 / original_lines)))
            cat <<EOF
| Total Original Lines | $original_lines |
| Total Archive Lines | $archive_lines |
| Space Savings | ${savings}% reduction |
EOF
        fi
    fi
}

#######################################
# Generate notes section for in-progress/questionable specs
# Arguments:
#   $1 - Path to sorted temp file with spec statistics
#######################################
generate_notes_section() {
    local temp_file="$1"
    local has_notes=false

    while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        if [[ "$status" == "in-progress" ]] || [[ "$status" == "questionable" ]]; then
            if [[ "$has_notes" == "false" ]]; then
                echo ""
                echo "## Notes"
                echo ""
                has_notes=true
            fi

            local remaining=$((total - completed))
            cat <<EOF
### $spec_id - $spec_title
- **Status**: ${status^} (${pct}%)
- **Remaining**: $remaining tasks
EOF
            if [[ "$status" == "questionable" ]]; then
                echo "- **Recommendation**: Re-evaluate scope or abandon"
            elif [[ "$pct" -ge 75 ]]; then
                echo "- **Recommendation**: Nearly complete, worth finishing"
            fi
            echo ""
        fi
    done < "$temp_file"
}

#######################################
# Generate JSON dashboard format
# Arguments:
#   $1 - Path to temp file with spec statistics
#######################################
generate_json_format() {
    local temp_file="$1"

    # Calculate aggregates
    eval "$(calculate_aggregate_stats "$temp_file")"

    local overall_pct=0
    if [[ "$total_tasks" -gt 0 ]]; then
        overall_pct=$((total_completed * 100 / total_tasks))
    fi

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
        if [[ "$first" == "true" ]]; then
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
}

#######################################
# Generate CSV dashboard format
# Arguments:
#   stdin - TSV spec statistics
#######################################
generate_csv_format() {
    echo "Spec ID,Title,Status,Total Tasks,Completed Tasks,Completion %,Location"

    while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        echo "\"$spec_id\",\"$spec_title\",\"$status\",$total,$completed,$pct,\"$location\""
    done
}

# Export functions
export -f classify_status get_status_emoji calculate_aggregate_stats
export -f generate_summary_metrics generate_status_distribution
export -f generate_spec_details_header generate_spec_details_row
export -f generate_archive_stats generate_notes_section
export -f generate_json_format generate_csv_format
