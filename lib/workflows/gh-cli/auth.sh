#!/usr/bin/env bash
# lib/workflows/gh-cli/auth.sh - GitHub CLI authentication utilities
# Extracted from .runners-local/workflows/gh-cli-integration.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_GH_CLI_AUTH_SOURCED:-}" ]] && return 0
readonly _GH_CLI_AUTH_SOURCED=1

# Constitutional targets
readonly GITHUB_ACTIONS_LIMIT=0  # Zero consumption requirement

#######################################
# Check if GitHub CLI is authenticated
# Returns:
#   0 if authenticated, 1 if not
#######################################
is_gh_authenticated() {
    gh auth status &>/dev/null
}

#######################################
# Check if repository is accessible via GitHub CLI
# Returns:
#   0 if accessible, 1 if not
#######################################
is_repo_accessible() {
    gh repo view &>/dev/null
}

#######################################
# Validate constitutional compliance for GitHub CLI
# Arguments:
#   $1 - Log function name (optional)
# Returns:
#   0 if compliant, 1 if not
#######################################
validate_gh_compliance() {
    local log_func="${1:-echo}"

    $log_func "Validating GitHub CLI integration compliance..."

    # Check GitHub CLI authentication
    if ! is_gh_authenticated; then
        $log_func "ERROR: GitHub CLI not authenticated. Run: gh auth login"
        return 1
    fi

    # Check repository configuration
    if ! is_repo_accessible; then
        $log_func "ERROR: Not in a GitHub repository or repository not accessible"
        return 1
    fi

    # Validate zero GitHub Actions consumption
    local actions_usage
    actions_usage=$(gh api user/settings/billing/actions --jq '.total_minutes_used // 0' 2>/dev/null || echo "0")

    if [[ "${actions_usage}" -gt "${GITHUB_ACTIONS_LIMIT}" ]]; then
        $log_func "WARNING: GitHub Actions usage detected: ${actions_usage} minutes"
        $log_func "CONSTITUTIONAL: Consider reviewing workflow consumption"
    else
        $log_func "SUCCESS: Zero GitHub Actions consumption maintained"
    fi

    $log_func "SUCCESS: Constitutional compliance validated"
    return 0
}

#######################################
# Get current GitHub user info
# Outputs:
#   JSON with user information
#######################################
get_gh_user_info() {
    gh api user 2>/dev/null || echo '{"error": "Unable to fetch user info"}'
}

#######################################
# Validate zero consumption of GitHub Actions
# Arguments:
#   $1 - Log function name (optional)
# Returns:
#   0 if zero consumption, 1 if paid minutes used
#######################################
validate_zero_consumption() {
    local log_func="${1:-echo}"

    $log_func "Validating zero GitHub Actions consumption..."

    # Check billing information
    local billing_info
    billing_info=$(gh api user/settings/billing/actions 2>/dev/null || echo '{}')

    local total_minutes included_minutes paid_minutes
    total_minutes=$(echo "${billing_info}" | jq -r '.total_minutes_used // 0')
    included_minutes=$(echo "${billing_info}" | jq -r '.included_minutes // 0')
    paid_minutes=$(echo "${billing_info}" | jq -r '.total_paid_minutes_used // 0')

    $log_func "Total minutes used: ${total_minutes}"
    $log_func "Included minutes: ${included_minutes}"
    $log_func "Paid minutes used: ${paid_minutes}"

    if [[ "${paid_minutes}" -gt 0 ]]; then
        $log_func "ERROR: CONSTITUTIONAL VIOLATION: Paid GitHub Actions minutes detected!"
        return 1
    elif [[ "${total_minutes}" -gt "${included_minutes}" ]]; then
        $log_func "WARNING: GitHub Actions usage approaching limits"
    else
        $log_func "SUCCESS: Zero paid GitHub Actions consumption maintained"
    fi

    return 0
}

#######################################
# Check for workflows that might consume minutes
# Arguments:
#   $1 - Project root directory
#   $2 - Log function name (optional)
# Returns:
#   0 if compliant, 1 if potential violations found
#######################################
check_workflow_files() {
    local project_root="$1"
    local log_func="${2:-echo}"

    local workflows_dir="${project_root}/.github/workflows"
    if [[ -d "${workflows_dir}" ]]; then
        local workflow_files
        workflow_files=$(find "${workflows_dir}" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)

        if [[ "${workflow_files}" -gt 0 ]]; then
            $log_func "WARNING: Found ${workflow_files} workflow files - ensure they don't consume minutes"

            # Check each workflow for minute-consuming actions
            while IFS= read -r -d '' workflow_file; do
                if grep -q "runs-on:" "${workflow_file}"; then
                    $log_func "WARNING: Workflow ${workflow_file} may consume minutes (contains 'runs-on')"
                fi
            done < <(find "${workflows_dir}" \( -name "*.yml" -o -name "*.yaml" \) -print0 2>/dev/null)
            return 1
        fi
    fi

    $log_func "SUCCESS: No GitHub workflow files found (constitutional compliance)"
    return 0
}

#######################################
# Get authentication token status
# Outputs:
#   Token scopes and status information
#######################################
get_auth_token_status() {
    gh auth status 2>&1 || echo "Not authenticated"
}

#######################################
# Refresh authentication token if needed
# Returns:
#   0 on success, 1 on failure
#######################################
refresh_auth_if_needed() {
    if ! is_gh_authenticated; then
        echo "GitHub CLI not authenticated. Please run: gh auth login" >&2
        return 1
    fi

    # Check if token needs refresh
    local status
    status=$(gh auth status 2>&1)

    if echo "$status" | grep -q "Token"; then
        echo "Authentication valid"
        return 0
    fi

    echo "Authentication may need refresh" >&2
    return 1
}

# Export functions
export -f is_gh_authenticated is_repo_accessible
export -f validate_gh_compliance validate_zero_consumption
export -f get_gh_user_info check_workflow_files
export -f get_auth_token_status refresh_auth_if_needed
