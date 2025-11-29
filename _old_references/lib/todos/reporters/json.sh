#!/usr/bin/env bash
# lib/todos/reporters/json.sh - JSON report generation for TODOs
# Extracted from lib/todos/report.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_TODOS_JSON_REPORTER_SOURCED:-}" ]] && return 0
readonly _TODOS_JSON_REPORTER_SOURCED=1

#######################################
# Escape string for JSON output
# Arguments:
#   $1 - String to escape
# Outputs:
#   JSON-escaped string
#######################################
json_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

#######################################
# Generate JSON header for task report
# Arguments:
#   $1 - Total tasks count
#   $2 - Spec count
#   $3 - Total effort estimate (optional)
# Outputs:
#   JSON header object (partial)
#######################################
generate_json_header() {
    local total_tasks="$1"
    local spec_count="$2"
    local total_effort="${3:-}"

    echo "{"
    echo "  \"generated\": \"$(date -Iseconds)\","
    echo "  \"total_tasks\": $total_tasks,"
    echo "  \"spec_count\": $spec_count,"
    if [[ -n "$total_effort" ]]; then
        echo "  \"estimated_effort\": \"$(json_escape "$total_effort")\","
    fi
}

#######################################
# Generate JSON statistics object
# Arguments:
#   $1 - Total tasks
#   $2 - Spec count
#   $3 - P1 count
#   $4 - P2 count
#   $5 - P3 count
#   $6 - P4 count
# Outputs:
#   JSON statistics object
#######################################
generate_json_stats() {
    local total_tasks="$1"
    local spec_count="$2"
    local p1_count="${3:-0}"
    local p2_count="${4:-0}"
    local p3_count="${5:-0}"
    local p4_count="${6:-0}"

    cat <<EOF
  "statistics": {
    "total_tasks": $total_tasks,
    "specifications": $spec_count,
    "by_priority": {
      "P1_critical": $p1_count,
      "P2_high": $p2_count,
      "P3_medium": $p3_count,
      "P4_low": $p4_count
    }
  }
EOF
}

#######################################
# Generate JSON task array from TSV input
# Arguments:
#   stdin - TSV task data
# Outputs:
#   JSON task array
#######################################
generate_json_tasks() {
    echo "  \"tasks\": ["

    local first=true
    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi

        local parallel_bool="false"
        if [[ "$parallel" == "yes" ]]; then
            parallel_bool="true"
        fi

        echo -n "    {"
        echo -n "\"spec_id\": \"$(json_escape "$spec_id")\", "
        echo -n "\"task_id\": \"$(json_escape "$task_id")\", "
        echo -n "\"priority\": \"$(json_escape "$priority")\", "
        echo -n "\"user_story\": \"$(json_escape "$user_story")\", "
        echo -n "\"phase\": \"$(json_escape "$phase")\", "
        echo -n "\"effort\": \"$(json_escape "$effort")\", "
        echo -n "\"description\": \"$(json_escape "$description")\", "
        echo -n "\"parallel\": $parallel_bool"
        echo -n "}"
    done

    echo ""
    echo "  ]"
}

#######################################
# Generate JSON grouped by specification
# Arguments:
#   stdin - TSV task data
# Outputs:
#   JSON grouped by spec
#######################################
generate_json_by_spec() {
    echo "  \"by_specification\": {"

    local current_spec=""
    local first_spec=true
    local first_task=true

    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [[ "$spec_id" != "$current_spec" ]]; then
            if [[ -n "$current_spec" ]]; then
                echo ""
                echo "    ]"
                echo -n "  }"
            fi

            if [[ "$first_spec" == "true" ]]; then
                first_spec=false
            else
                echo ","
            fi

            current_spec="$spec_id"
            first_task=true
            echo -n "    \"$(json_escape "$spec_id")\": ["
        fi

        if [[ "$first_task" == "true" ]]; then
            first_task=false
            echo ""
        else
            echo ","
        fi

        local parallel_bool="false"
        if [[ "$parallel" == "yes" ]]; then
            parallel_bool="true"
        fi

        echo -n "      {\"task_id\": \"$(json_escape "$task_id")\", \"description\": \"$(json_escape "$description")\", \"priority\": \"$(json_escape "$priority")\", \"parallel\": $parallel_bool}"
    done

    if [[ -n "$current_spec" ]]; then
        echo ""
        echo "    ]"
    fi

    echo "  }"
}

#######################################
# Generate complete JSON report
# Arguments:
#   $1 - Temp file with TSV task data
#   $2 - Total tasks
#   $3 - Spec count
# Outputs:
#   Complete JSON report
#######################################
generate_complete_json_report() {
    local temp_file="$1"
    local total_tasks="$2"
    local spec_count="$3"

    echo "{"
    echo "  \"generated\": \"$(date -Iseconds)\","
    echo "  \"summary\": {"
    echo "    \"total_tasks\": $total_tasks,"
    echo "    \"specifications\": $spec_count"
    echo "  },"

    # Generate tasks array
    echo "  \"tasks\": ["
    local first=true
    while IFS=$'\t' read -r spec_id task_id priority user_story phase effort description parallel; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi

        local parallel_bool="false"
        [[ "$parallel" == "yes" ]] && parallel_bool="true"

        echo -n "    {"
        echo -n "\"spec_id\": \"$(json_escape "$spec_id")\", "
        echo -n "\"task_id\": \"$(json_escape "$task_id")\", "
        echo -n "\"description\": \"$(json_escape "$description")\""
        echo -n "}"
    done < "$temp_file"
    echo ""
    echo "  ]"
    echo "}"
}

# Export functions
export -f json_escape
export -f generate_json_header generate_json_stats
export -f generate_json_tasks generate_json_by_spec
export -f generate_complete_json_report
