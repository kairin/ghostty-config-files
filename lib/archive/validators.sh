#!/usr/bin/env bash
# lib/archive/validators.sh - Validation utilities for archive_spec.sh
# Contains: validate_completed_task_files, validate_file_exists, etc.

set -euo pipefail

[ -z "${ARCHIVE_VALIDATORS_SH_LOADED:-}" ] || return 0
ARCHIVE_VALIDATORS_SH_LOADED=1

# Validate files referenced in completed tasks exist
validate_completed_task_files() {
    local tasks_file="$1"
    local validation_failed=false
    local line_number=0
    local missing_files=()

    while IFS= read -r line; do
        ((line_number++))

        if echo "$line" | grep -qE '^- \[[xX]\]'; then
            while IFS= read -r file_path; do
                if [ -n "$file_path" ] && ! validate_file_path "$file_path"; then
                    local task_id
                    task_id=$(echo "$line" | grep -oE 'T[0-9]{3}' | head -1 || echo "UNKNOWN")
                    missing_files+=("  - $task_id: $file_path (MISSING)")
                    validation_failed=true
                fi
            done < <(extract_file_paths_from_line "$line")
        fi
    done < "$tasks_file"

    if [ "$validation_failed" = true ]; then
        echo "ERROR: Validation failed:" >&2
        printf '%s\n' "${missing_files[@]}" >&2
        echo "" >&2
        echo "Use --validate-only to see all issues before archiving" >&2
        return 1
    fi

    return 0
}

# Validate a file path exists
validate_file_path() {
    local file_path="$1"
    file_path="${file_path/#\~/$HOME}"
    [ -f "$file_path" ] || [ -d "$file_path" ]
}

# Extract file paths from a task line
extract_file_paths_from_line() {
    local task_line="$1"

    echo "$task_line" | grep -oE '(scripts|configs|tests|docs|.runners-local|documentations)/[^ ,)]+\.(sh|md|json|yaml|yml|conf|py|js|ts)' || true
    # shellcheck disable=SC2088 # Tilde is a regex pattern here, not path expansion
    echo "$task_line" | grep -oE '~/\.[a-z]+/[^ ,)]+' || true
    echo "$task_line" | grep -oE 'src/[^ ,)]+\.(sh|md|json|yaml|yml|conf|py|js|ts)' || true
}

# Check if specification directory is valid
is_valid_spec_directory() {
    local spec_dir="$1"
    [ -d "$spec_dir" ] && [ -f "$spec_dir/tasks.md" ]
}

# Get specification ID from directory path
get_spec_id_from_path() {
    local spec_dir="$1"
    basename "$spec_dir"
}

# Get specification title from spec.md
get_spec_title_from_file() {
    local spec_dir="$1"
    local spec_file="$spec_dir/spec.md"

    if [ -f "$spec_file" ]; then
        grep -m1 '^# ' "$spec_file" | sed 's/^# //' || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Count total tasks in tasks.md
count_total_tasks_in_file() {
    local tasks_file="$1"
    grep -cE '^- \[([ xX])\]' "$tasks_file" 2>/dev/null || echo "0"
}

# Count completed tasks in tasks.md
count_completed_tasks_in_file() {
    local tasks_file="$1"
    grep -cE '^- \[[xX]\]' "$tasks_file" 2>/dev/null || echo "0"
}

# Calculate completion percentage
calculate_completion_pct() {
    local completed="$1"
    local total="$2"

    if [ "$total" -eq 0 ]; then
        echo "0"
    else
        echo "$(( (completed * 100) / total ))"
    fi
}

# Check if yq is available for YAML validation
has_yq_command() {
    command -v yq >/dev/null 2>&1
}

# Validate YAML syntax
validate_yaml_syntax() {
    local yaml_file="$1"

    if has_yq_command; then
        yq eval '.' "$yaml_file" >/dev/null 2>&1
    else
        return 0
    fi
}

export -f validate_completed_task_files validate_file_path extract_file_paths_from_line
export -f is_valid_spec_directory get_spec_id_from_path get_spec_title_from_file
export -f count_total_tasks_in_file count_completed_tasks_in_file calculate_completion_pct
export -f has_yq_command validate_yaml_syntax
