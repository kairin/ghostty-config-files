#!/usr/bin/env bash
#
# archive_common.sh - Common utilities for task archive and consolidation system
# Feature: 006-task-archive-consolidation
# Version: 1.0.0

set -euo pipefail

# Color output support
if command -v tput >/dev/null 2>&1 && [ -t 1 ]; then
    COLORS=$(tput colors 2>/dev/null || echo 0)
    if [ "$COLORS" -ge 8 ]; then
        RED=$(tput setaf 1)
        GREEN=$(tput setaf 2)
        YELLOW=$(tput setaf 3)
        BLUE=$(tput setaf 4)
        BOLD=$(tput bold)
        RESET=$(tput sgr0)
    else
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        BOLD=""
        RESET=""
    fi
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    RESET=""
fi

# Progress emoji indicators
readonly EMOJI_SCAN="🔍"
readonly EMOJI_SUCCESS="✅"
readonly EMOJI_ERROR="❌"
readonly EMOJI_WARNING="⚠️"
readonly EMOJI_ARCHIVE="📦"
readonly EMOJI_CHECKLIST="📋"
readonly EMOJI_STATS="📊"
readonly EMOJI_STORAGE="💾"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_ERROR=1
readonly EXIT_VALIDATION_ERROR=2
readonly EXIT_ARCHIVE_EXISTS=3
readonly EXIT_NOT_FOUND=4
readonly EXIT_INCOMPLETE=5
readonly EXIT_NO_TASKS=4
readonly EXIT_CIRCULAR_DEPS=6
readonly EXIT_NO_SPECS=4

# Specification locations
readonly SPECS_LOCATIONS=(
    "specs"
    "documentations/specifications"
)

# YAML archive location
readonly ARCHIVE_DIR="documentations/archive/specifications"

#######################################
# Log message to stderr with timestamp
# Arguments:
#   $1 - Log level (INFO, WARN, ERROR)
#   $2+ - Message
#######################################
log() {
    local level="$1"
    shift
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $*" >&2
}

#######################################
# Print info message with emoji
# Arguments:
#   $1 - Emoji indicator
#   $2+ - Message
#######################################
print_info() {
    local emoji="$1"
    shift
    echo "${emoji} $*"
}

#######################################
# Print success message
# Arguments:
#   $1+ - Message
#######################################
print_success() {
    echo "${EMOJI_SUCCESS} ${GREEN}$*${RESET}"
}

#######################################
# Print error message to stderr
# Arguments:
#   $1+ - Message
#######################################
print_error() {
    echo "${EMOJI_ERROR} ${RED}$*${RESET}" >&2
}

#######################################
# Print warning message
# Arguments:
#   $1+ - Message
#######################################
print_warning() {
    echo "${EMOJI_WARNING} ${YELLOW}$*${RESET}"
}

#######################################
# Discover all specifications in repository
# Outputs:
#   List of specification directory paths (one per line)
#######################################
discover_specifications() {
    local spec_dir
    for location in "${SPECS_LOCATIONS[@]}"; do
        if [ -d "$location" ]; then
            find "$location" -mindepth 1 -maxdepth 1 -type d | sort
        fi
    done
}

#######################################
# Check if specification directory is valid
# Arguments:
#   $1 - Specification directory path
# Returns:
#   0 if valid, 1 if invalid
#######################################
is_valid_specification() {
    local spec_dir="$1"
    [ -d "$spec_dir" ] && [ -f "$spec_dir/tasks.md" ]
}

#######################################
# Extract specification ID from directory path
# Arguments:
#   $1 - Specification directory path
# Outputs:
#   Specification ID (e.g., "004", "20251111-042534-feat-name")
#######################################
get_spec_id() {
    local spec_dir="$1"
    basename "$spec_dir"
}

#######################################
# Get specification title from spec.md
# Arguments:
#   $1 - Specification directory path
# Outputs:
#   Specification title or "Unknown" if not found
#######################################
get_spec_title() {
    local spec_dir="$1"
    local spec_file="$spec_dir/spec.md"

    if [ -f "$spec_file" ]; then
        # Extract title from first H1 heading
        grep -m1 '^# ' "$spec_file" | sed 's/^# //' || echo "Unknown"
    else
        echo "Unknown"
    fi
}

#######################################
# Count total tasks in tasks.md
# Arguments:
#   $1 - Path to tasks.md file
# Outputs:
#   Total task count
#######################################
count_total_tasks() {
    local tasks_file="$1"
    grep -cE '^- \[([ xX])\]' "$tasks_file" 2>/dev/null || echo "0"
}

#######################################
# Count completed tasks in tasks.md
# Arguments:
#   $1 - Path to tasks.md file
# Outputs:
#   Completed task count
#######################################
count_completed_tasks() {
    local tasks_file="$1"
    grep -cE '^- \[[xX]\]' "$tasks_file" 2>/dev/null || echo "0"
}

#######################################
# Count incomplete tasks in tasks.md
# Arguments:
#   $1 - Path to tasks.md file
# Outputs:
#   Incomplete task count
#######################################
count_incomplete_tasks() {
    local tasks_file="$1"
    grep -cE '^- \[ \]' "$tasks_file" 2>/dev/null || echo "0"
}

#######################################
# Calculate completion percentage
# Arguments:
#   $1 - Completed task count
#   $2 - Total task count
# Outputs:
#   Completion percentage (0-100)
#######################################
calculate_completion_percentage() {
    local completed="$1"
    local total="$2"

    if [ "$total" -eq 0 ]; then
        echo "0"
    else
        echo "$(( (completed * 100) / total ))"
    fi
}

#######################################
# Extract task ID from task line
# Arguments:
#   $1 - Task line from tasks.md
# Outputs:
#   Task ID (e.g., "T001") or empty if not found
#######################################
extract_task_id() {
    local task_line="$1"
    echo "$task_line" | grep -oE 'T[0-9]{3}' | head -1 || echo ""
}

#######################################
# Extract priority from task line
# Arguments:
#   $1 - Task line from tasks.md
# Outputs:
#   Priority (P1, P2, P3, P4) or empty if not found
#######################################
extract_task_priority() {
    local task_line="$1"
    echo "$task_line" | grep -oE '\[P[1-4]\]' | tr -d '[]' | head -1 || echo ""
}

#######################################
# Extract user story label from task line
# Arguments:
#   $1 - Task line from tasks.md
# Outputs:
#   User story (US1, US2, US3) or empty if not found
#######################################
extract_user_story() {
    local task_line="$1"
    echo "$task_line" | grep -oE '\[US[0-9]+\]' | tr -d '[]' | head -1 || echo ""
}

#######################################
# Check if task is parallelizable
# Arguments:
#   $1 - Task line from tasks.md
# Returns:
#   0 if parallelizable (has [P] marker), 1 otherwise
#######################################
is_parallel_task() {
    local task_line="$1"
    echo "$task_line" | grep -q '\[P\]'
}

#######################################
# Extract file paths from task description
# Arguments:
#   $1 - Task line from tasks.md
# Outputs:
#   List of file paths (one per line)
#######################################
extract_file_paths() {
    local task_line="$1"

    # Common file path patterns
    echo "$task_line" | grep -oE '(scripts|configs|tests|docs|local-infra|documentations)/[^ ,)]+\.(sh|md|json|yaml|yml|conf|py|js|ts)' || true
    echo "$task_line" | grep -oE '~/\.[a-z]+/[^ ,)]+' || true
    echo "$task_line" | grep -oE 'src/[^ ,)]+\.(sh|md|json|yaml|yml|conf|py|js|ts)' || true
}

#######################################
# Validate file existence
# Arguments:
#   $1 - File path
# Returns:
#   0 if file exists, 1 otherwise
#######################################
validate_file_exists() {
    local file_path="$1"

    # Expand ~ if present
    file_path="${file_path/#\~/$HOME}"

    [ -f "$file_path" ] || [ -d "$file_path" ]
}

#######################################
# Get phase from tasks.md context
# Arguments:
#   $1 - Path to tasks.md
#   $2 - Line number
# Outputs:
#   Phase name (e.g., "Phase 1: Setup")
#######################################
get_task_phase() {
    local tasks_file="$1"
    local line_number="$2"

    # Find the most recent phase heading before this line
    head -n "$line_number" "$tasks_file" | \
        grep -E '^## Phase [0-9]+:' | \
        tail -1 | \
        sed 's/^## //'
}

#######################################
# Load YAML template schema
# Outputs:
#   YAML template structure based on 004-modern-web-development.yaml
#######################################
get_yaml_template() {
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

#######################################
# Check if yq is available
# Returns:
#   0 if yq available, 1 otherwise
#######################################
has_yq() {
    command -v yq >/dev/null 2>&1
}

#######################################
# Check if jq is available
# Returns:
#   0 if jq available, 1 otherwise
#######################################
has_jq() {
    command -v jq >/dev/null 2>&1
}

#######################################
# Validate YAML with yq
# Arguments:
#   $1 - Path to YAML file
# Returns:
#   0 if valid, 1 if invalid
#######################################
validate_yaml() {
    local yaml_file="$1"

    if has_yq; then
        yq eval '.' "$yaml_file" >/dev/null 2>&1
    else
        # Skip validation if yq not available
        return 0
    fi
}

# Export functions for use in other scripts
export -f log
export -f print_info
export -f print_success
export -f print_error
export -f print_warning
export -f discover_specifications
export -f is_valid_specification
export -f get_spec_id
export -f get_spec_title
export -f count_total_tasks
export -f count_completed_tasks
export -f count_incomplete_tasks
export -f calculate_completion_percentage
export -f extract_task_id
export -f extract_task_priority
export -f extract_user_story
export -f is_parallel_task
export -f extract_file_paths
export -f validate_file_exists
export -f get_task_phase
export -f get_yaml_template
export -f has_yq
export -f has_jq
export -f validate_yaml
