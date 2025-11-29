#!/usr/bin/env bash
# lib/workflows/pre-commit/formatters.sh - Pre-commit formatting utilities
# Extracted from .runners-local/workflows/pre-commit-local.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_PRECOMMIT_FORMATTERS_SOURCED:-}" ]] && return 0
readonly _PRECOMMIT_FORMATTERS_SOURCED=1

#######################################
# Get list of changed files (staged or from last commit)
# Returns:
#   List of changed file paths (one per line)
#######################################
get_changed_files() {
    local changed_files=""

    # Get list of changed files
    if git rev-parse --verify HEAD >/dev/null 2>&1; then
        changed_files=$(git diff --cached --name-only 2>/dev/null || \
                       git diff --name-only HEAD^ 2>/dev/null || echo "")
    else
        # Initial commit case
        changed_files=$(git ls-files --cached 2>/dev/null || echo "")
    fi

    echo "$changed_files"
}

#######################################
# Check GitHub repository status
# Arguments:
#   $1 - Log directory for saving status
#   $2 - Timestamp for file naming
# Returns:
#   0 on success
#######################################
check_github_status() {
    local log_dir="${1:-/tmp}"
    local timestamp="${2:-$(date +%Y%m%d-%H%M%S)}"

    echo "Checking GitHub repository status..."

    # Check if gh CLI is available and authenticated
    if ! command -v gh >/dev/null 2>&1; then
        echo "GitHub CLI not available - skipping GitHub checks"
        return 0
    fi

    if ! gh auth status >/dev/null 2>&1; then
        echo "GitHub CLI not authenticated - skipping GitHub checks"
        return 0
    fi

    # Check repository status
    local repo_status
    repo_status=$(gh repo view --json name,isPrivate,pushedAt,defaultBranch 2>/dev/null || echo "null")

    if [[ "$repo_status" != "null" ]]; then
        echo "GitHub repository accessible"
        echo "$repo_status" > "$log_dir/github-status-$timestamp.json"

        # Check if there are any open PRs that might conflict
        local open_prs
        open_prs=$(gh pr list --state open --json number,title,headRefName --limit 5 2>/dev/null || echo "[]")
        local pr_count
        pr_count=$(echo "$open_prs" | jq length 2>/dev/null || echo "0")
        echo "Open PRs: $pr_count"

        # Check branch protection rules if on main/master
        local current_branch
        current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
            echo "On protected branch: $current_branch"
        fi
    else
        echo "Could not access GitHub repository"
    fi

    return 0
}

#######################################
# Validate performance impact of changes
# Outputs:
#   Performance impact warnings
#######################################
validate_performance_impact() {
    echo "Validating performance impact..."

    local changed_files
    changed_files=$(get_changed_files)

    local performance_sensitive_files=0

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue

        case "$file" in
            package.json|package-lock.json|uv.lock|pyproject.toml)
                echo "Dependency change detected: $file"
                ((performance_sensitive_files++))
                ;;
            astro.config.*|tailwind.config.*|tsconfig.json)
                echo "Configuration change detected: $file"
                ((performance_sensitive_files++))
                ;;
            src/styles/*|*.css)
                echo "Style change detected: $file"
                ((performance_sensitive_files++))
                ;;
            src/components/*|src/layouts/*)
                echo "Component change detected: $file"
                ((performance_sensitive_files++))
                ;;
        esac
    done <<< "$changed_files"

    if [[ "$performance_sensitive_files" -gt 0 ]]; then
        echo "$performance_sensitive_files performance-sensitive files changed"
        echo "    Consider running performance validation after commit:"
        echo "    ./.runners-local/workflows/performance-monitor.sh --target-url http://localhost:4321"
    fi

    return 0
}

#######################################
# Generate JSON validation report
# Arguments:
#   $1 - Total errors count
#   $2 - Validation type
#   $3 - Log directory
#   $4 - Timestamp
#   $5 - Log file path
# Outputs:
#   JSON report file path
#######################################
generate_validation_report() {
    local total_errors="$1"
    local validation_type="${2:-full}"
    local log_dir="${3:-/tmp}"
    local timestamp="${4:-$(date +%Y%m%d-%H%M%S)}"
    local log_file="${5:-}"

    local status="success"
    if [[ "$total_errors" -gt 0 ]]; then
        status="failed"
    fi

    local report_file="$log_dir/pre-commit-validation-$timestamp.json"

    # Get file counts
    local total_files python_files ts_files astro_files
    total_files=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    python_files=$(git diff --cached --name-only 2>/dev/null | grep -c '\.py$' || echo "0")
    ts_files=$(git diff --cached --name-only 2>/dev/null | grep -cE '\.(ts|tsx|js|jsx)$' || echo "0")
    astro_files=$(git diff --cached --name-only 2>/dev/null | grep -c '\.astro$' || echo "0")

    # Get performance impact counts
    local deps_changed config_changed components_changed
    deps_changed=$(git diff --cached --name-only 2>/dev/null | grep -cE 'package.*\.json|uv\.lock|pyproject\.toml' || echo "0")
    config_changed=$(git diff --cached --name-only 2>/dev/null | grep -cE '.*\.config\.|tsconfig\.json' || echo "0")
    components_changed=$(git diff --cached --name-only 2>/dev/null | grep -cE 'src/components/|src/layouts/' || echo "0")

    # Check GitHub status
    local gh_available gh_authenticated gh_repo_accessible
    gh_available=$(command -v gh >/dev/null 2>&1 && echo "true" || echo "false")
    gh_authenticated=$(gh auth status >/dev/null 2>&1 && echo "true" || echo "false")
    gh_repo_accessible=$(gh repo view >/dev/null 2>&1 && echo "true" || echo "false")

    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "validation_type": "$validation_type",
    "status": "$status",
    "errors_count": $total_errors,
    "constitutional_compliance": {
        "zero_github_actions": $([ ! -d ".github/workflows" ] && echo "true" || echo "false"),
        "uv_first_python": $([ ! -f "requirements.txt" ] && [ ! -f "setup.py" ] && echo "true" || echo "false"),
        "strict_typing": $(grep -q 'strict = true' pyproject.toml 2>/dev/null && echo "true" || echo "false")
    },
    "files_validated": {
        "total": $total_files,
        "python_files": $python_files,
        "typescript_files": $ts_files,
        "astro_files": $astro_files
    },
    "performance_impact": {
        "dependencies_changed": $deps_changed,
        "config_changed": $config_changed,
        "components_changed": $components_changed
    },
    "github_integration": {
        "cli_available": $gh_available,
        "authenticated": $gh_authenticated,
        "repository_accessible": $gh_repo_accessible
    },
    "log_file": "$log_file",
    "report_file": "$report_file"
}
EOF

    echo "Validation report generated: $report_file"
    echo "$report_file"
}

#######################################
# Print validation summary
# Arguments:
#   $1 - Total errors count
#######################################
print_validation_summary() {
    local total_errors="$1"

    if [[ "$total_errors" -eq 0 ]]; then
        echo ""
        echo "Pre-commit validation PASSED"
        echo "All constitutional requirements satisfied"
        echo "Ready for commit"
    else
        echo ""
        echo "Pre-commit validation FAILED"
        echo "$total_errors error(s) must be fixed before committing"
        echo "Review validation details above"
    fi
}

#######################################
# Validate file based on extension
# Arguments:
#   $1 - File path
#   $2 - Project root (optional)
# Returns:
#   0 if valid, non-zero if invalid
#######################################
validate_file_by_extension() {
    local file="$1"
    local project_root="${2:-.}"
    local errors=0

    # Check if file exists (might be deleted)
    if [[ ! -f "$file" ]]; then
        echo "File deleted: $file"
        return 0
    fi

    # Validate file-specific rules
    case "$file" in
        *.py)
            validate_python_file "$file" || ((errors++))
            ;;
        *.ts|*.tsx|*.js|*.jsx)
            validate_typescript_file "$file" "$project_root" || true
            ;;
        *.astro)
            validate_astro_file "$file" "$project_root" || true
            ;;
        *.json)
            validate_json_file "$file" || ((errors++))
            ;;
        *.yaml|*.yml)
            validate_yaml_file "$file" || ((errors++))
            ;;
        *.md)
            validate_markdown_file "$file" || true
            ;;
    esac

    # Check for sensitive data
    check_sensitive_data "$file"

    # Check file size
    check_file_size "$file"

    return $errors
}

# Source validators if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/validators.sh" ]]; then
    source "$SCRIPT_DIR/validators.sh"
fi

# Export functions
export -f get_changed_files check_github_status validate_performance_impact
export -f generate_validation_report print_validation_summary validate_file_by_extension
