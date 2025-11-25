#!/usr/bin/env bash
# lib/archive/yaml-generator.sh - YAML generation for archive_spec.sh
# Contains: extract_functional_requirements, extract_key_completed_tasks, etc.

set -euo pipefail

[ -z "${YAML_GENERATOR_SH_LOADED:-}" ] || return 0
YAML_GENERATOR_SH_LOADED=1

# Extract functional requirements from spec.md
extract_functional_requirements() {
    local spec_file="$1"
    local in_functional=false
    local req_id="" req_text=""

    while IFS= read -r line; do
        if echo "$line" | grep -qE '^##+ Functional Requirements'; then
            in_functional=true
            continue
        fi

        if [ "$in_functional" = true ] && echo "$line" | grep -qE '^##+ '; then
            break
        fi

        if [ "$in_functional" = true ]; then
            if echo "$line" | grep -qE '^\*\*FR-[0-9]+'; then
                if [ -n "$req_id" ]; then
                    echo "    - id: \"$req_id\""
                    echo "      requirement: \"$req_text\""
                    echo "      evidence: \"Implemented in scripts\""
                fi
                req_id=$(echo "$line" | grep -oE 'FR-[0-9]+')
                req_text=$(echo "$line" | sed -E 's/^\*\*FR-[0-9]+\*\*:? *//; s/\*\*//g')
            elif [ -n "$req_text" ] && [ -n "$line" ]; then
                req_text="$req_text $line"
            fi
        fi
    done < "$spec_file"

    if [ -n "$req_id" ]; then
        echo "    - id: \"$req_id\""
        echo "      requirement: \"$req_text\""
        echo "      evidence: \"Implemented in scripts\""
    fi
}

# Extract key completed tasks from tasks.md
extract_key_completed_tasks() {
    local tasks_file="$1"
    local max_tasks="${2:-10}"
    local count=0

    while IFS= read -r line && [ "$count" -lt "$max_tasks" ]; do
        if echo "$line" | grep -qE '^- \[[xX]\]'; then
            local task_id task_desc
            task_id=$(echo "$line" | grep -oE 'T[0-9]{3}' | head -1 || echo "")
            task_desc=$(echo "$line" | sed -E 's/^- \[[xX]\] +T[0-9]+ +(\[P\] +)?(\[US[0-9]+\] +)?//')
            echo "    - \"$task_id: $task_desc\""
            ((count++))
        fi
    done < "$tasks_file"
}

# Extract remaining tasks from tasks.md
extract_remaining_tasks() {
    local tasks_file="$1"
    local max_tasks="${2:-10}"
    local count=0

    while IFS= read -r line && [ "$count" -lt "$max_tasks" ]; do
        if echo "$line" | grep -qE '^- \[ \]'; then
            local task_id task_desc
            task_id=$(echo "$line" | grep -oE 'T[0-9]{3}' | head -1 || echo "")
            task_desc=$(echo "$line" | sed -E 's/^- \[ \] +T[0-9]+ +(\[P\] +)?(\[US[0-9]+\] +)?//')
            echo "    - \"$task_id: $task_desc\""
            ((count++))
        fi
    done < "$tasks_file"
}

# Calculate space savings between original and archive
calculate_space_savings() {
    local original_dir="$1"
    local archive_file="$2"
    local original_lines=0 archive_lines=0

    if [ -d "$original_dir" ]; then
        while IFS= read -r file; do
            original_lines=$((original_lines + $(wc -l < "$file")))
        done < <(find "$original_dir" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null)
    fi

    if [ -f "$archive_file" ]; then
        archive_lines=$(wc -l < "$archive_file")
    fi

    if [ "$original_lines" -gt 0 ]; then
        local savings=$(( 100 - (archive_lines * 100 / original_lines) ))
        echo "$savings% ($original_lines -> $archive_lines lines)"
    else
        echo "N/A"
    fi
}

# Get YAML template for archive generation
get_yaml_archive_template() {
    cat <<'EOF'
feature_id: "%FEATURE_ID%"
title: "%TITLE%"
status: "%STATUS%"
completion_date: %COMPLETION_DATE%
completion_percentage: %COMPLETION_PERCENTAGE%
original_spec_location: "%ORIGINAL_LOCATION%"

summary: |
  %SUMMARY%

requirements:
  functional:
%FUNCTIONAL_REQUIREMENTS%

  non_functional:
%NON_FUNCTIONAL_REQUIREMENTS%

implementation:
  architecture: |
    %ARCHITECTURE%

  key_files:
%KEY_FILES%

  phases:
%PHASES%

tasks:
  total: %TOTAL_TASKS%
  completed: %COMPLETED_TASKS%

  key_tasks_completed:
%KEY_TASKS_COMPLETED%

  key_tasks_remaining:
%KEY_TASKS_REMAINING%

outcomes:
  deliverables:
%DELIVERABLES%

  metrics:
%METRICS%

  artifacts:
%ARTIFACTS%

lessons_learned:
  successes:
%SUCCESSES%

  challenges:
%CHALLENGES%

  recommendations:
%RECOMMENDATIONS%

constitutional_compliance:
  branch_preservation: %BRANCH_PRESERVATION%
  local_cicd_first: %LOCAL_CICD%
  zero_cost: %ZERO_COST%
  agent_integrity: %AGENT_INTEGRITY%

archive_metadata:
  archive_date: "%ARCHIVE_DATE%"
  archive_reason: "%ARCHIVE_REASON%"
  status_marker: "%STATUS_MARKER%"
EOF
}

# Fill YAML template with values
fill_yaml_template() {
    local template="$1"
    shift

    # Process key=value pairs
    while [[ $# -gt 0 ]]; do
        local key="${1%%=*}"
        local value="${1#*=}"
        template="${template//%$key%/$value}"
        shift
    done

    echo "$template"
}

export -f extract_functional_requirements extract_key_completed_tasks extract_remaining_tasks
export -f calculate_space_savings get_yaml_archive_template fill_yaml_template
