#!/usr/bin/env bash
# lib/docs/dashboard/stats.sh - Dashboard statistics collection and calculation
# Extracted from lib/docs/dashboard.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_DASHBOARD_STATS_SOURCED:-}" ]] && return 0
readonly _DASHBOARD_STATS_SOURCED=1

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
# Calculate overall completion percentage
# Arguments:
#   $1 - Total completed tasks
#   $2 - Total tasks
# Outputs:
#   Percentage (0-100)
#######################################
calculate_overall_completion() {
    local completed="$1"
    local total="$2"

    if [[ "$total" -eq 0 ]]; then
        echo "0"
        return
    fi

    echo "$((completed * 100 / total))"
}

#######################################
# Calculate estimated remaining work days
# Arguments:
#   $1 - Remaining tasks
#   $2 - Tasks per day estimate (optional, default 8)
# Outputs:
#   Estimated days
#######################################
calculate_remaining_days() {
    local remaining="$1"
    local tasks_per_day="${2:-8}"

    if [[ "$remaining" -eq 0 ]]; then
        echo "0"
        return
    fi

    echo "$(( (remaining + tasks_per_day - 1) / tasks_per_day ))"
}

#######################################
# Count tasks by status from temp file
# Arguments:
#   $1 - Path to temp file with TSV spec statistics
#   $2 - Status to count (completed, in-progress, questionable, abandoned)
# Outputs:
#   Count
#######################################
count_specs_by_status() {
    local temp_file="$1"
    local target_status="$2"
    local count=0

    while IFS=$'\t' read -r spec_id spec_title status total completed pct location; do
        if [[ "$status" == "$target_status" ]]; then
            count=$((count + 1))
        fi
    done < "$temp_file"

    echo "$count"
}

#######################################
# Calculate percentage safely (avoid division by zero)
# Arguments:
#   $1 - Numerator
#   $2 - Denominator
# Outputs:
#   Percentage (0-100)
#######################################
safe_percentage() {
    local numerator="$1"
    local denominator="$2"

    if [[ "$denominator" -eq 0 ]]; then
        echo "0"
        return
    fi

    echo "$((numerator * 100 / denominator))"
}

#######################################
# Calculate archive statistics
# Arguments:
#   $1 - Archive directory path
# Outputs:
#   TSV: archived_count, original_lines, archive_lines, savings_pct
#######################################
calculate_archive_stats() {
    local archive_dir="$1"
    local archived_count=0
    local original_lines=0
    local archive_lines=0

    if [[ ! -d "$archive_dir" ]]; then
        echo "0	0	0	0"
        return
    fi

    while IFS= read -r archive_file; do
        if [[ -f "$archive_file" ]]; then
            archived_count=$((archived_count + 1))
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

    local savings_pct=0
    if [[ "$original_lines" -gt 0 ]]; then
        savings_pct=$((100 - (archive_lines * 100 / original_lines)))
    fi

    echo "$archived_count	$original_lines	$archive_lines	$savings_pct"
}

# Export functions
export -f classify_status get_status_emoji
export -f calculate_aggregate_stats calculate_overall_completion
export -f calculate_remaining_days count_specs_by_status
export -f safe_percentage calculate_archive_stats
