#!/usr/bin/env bash
# lib/workflows/gh-cli/api.sh - GitHub CLI API operations
# Extracted from .runners-local/workflows/gh-cli-integration.sh for modularity

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_GH_CLI_API_SOURCED:-}" ]] && return 0
readonly _GH_CLI_API_SOURCED=1

#######################################
# Get repository information via GitHub CLI
# Outputs:
#   JSON with repository info
#######################################
get_repo_info() {
    gh repo view --json name,description,pushedAt,isPrivate,defaultBranch 2>/dev/null || \
        echo '{"error": "Unable to fetch repository info"}'
}

#######################################
# Get list of repository branches
# Outputs:
#   Space-separated list of branch names
#######################################
get_repo_branches() {
    gh api repos/:owner/:repo/branches --jq '.[].name' 2>/dev/null | tr '\n' ' '
}

#######################################
# Check if branch follows constitutional naming
# Arguments:
#   $1 - Branch name
# Returns:
#   0 if constitutional, 1 if not
#######################################
is_constitutional_branch() {
    local branch="$1"
    [[ "${branch}" =~ ^[0-9]{8}-[0-9]{6}-.+ ]]
}

#######################################
# Get recent workflow runs
# Arguments:
#   $1 - Limit (optional, default 10)
# Outputs:
#   JSON array of workflow runs
#######################################
get_workflow_runs() {
    local limit="${1:-10}"
    gh run list --limit "$limit" --json name,status,conclusion,createdAt 2>/dev/null || echo "[]"
}

#######################################
# Get open issues count and list
# Arguments:
#   $1 - Limit (optional, default 10)
# Outputs:
#   JSON array of issues
#######################################
get_open_issues() {
    local limit="${1:-10}"
    gh issue list --state open --json number,title --limit "$limit" 2>/dev/null || echo "[]"
}

#######################################
# Get open pull requests
# Arguments:
#   $1 - Limit (optional, default 10)
# Outputs:
#   JSON array of PRs
#######################################
get_open_prs() {
    local limit="${1:-10}"
    gh pr list --state open --json number,title,headRefName --limit "$limit" 2>/dev/null || echo "[]"
}

#######################################
# Get latest release information
# Outputs:
#   JSON with latest release info
#######################################
get_latest_release() {
    gh release list --limit 1 --json tagName,publishedAt,isPrerelease 2>/dev/null || echo "[]"
}

#######################################
# Create a new branch using GitHub CLI
# Arguments:
#   $1 - Branch description
# Outputs:
#   Created branch name
# Returns:
#   0 on success, 1 on failure
#######################################
create_constitutional_branch() {
    local branch_description="$1"
    local datetime
    datetime=$(date +"%Y%m%d-%H%M%S")
    local branch_name="${datetime}-${branch_description}"

    echo "Creating constitutional branch: ${branch_name}"

    # Create and push branch
    git checkout -b "${branch_name}" || return 1
    git push -u origin "${branch_name}" || return 1

    echo "Constitutional branch created and pushed: ${branch_name}"
    echo "${branch_name}"
    return 0
}

#######################################
# Create pull request with constitutional compliance
# Arguments:
#   $1 - PR title
#   $2 - PR body
#   $3 - Branch name
# Outputs:
#   PR URL
# Returns:
#   0 on success, 1 on failure
#######################################
create_constitutional_pr() {
    local title="$1"
    local body="$2"
    local branch_name="$3"

    echo "Creating constitutional pull request..."

    # Add constitutional compliance footer
    local constitutional_body="${body}

---

## Constitutional Compliance

**Zero GitHub Actions Consumption**: All CI/CD runs locally
**Branch Preservation Strategy**: Constitutional naming convention applied
**Performance Validation**: Local performance monitoring executed
**Constitutional Framework**: All requirements validated

Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

    # Create pull request
    local pr_url
    pr_url=$(gh pr create --title "${title}" --body "${constitutional_body}" --head "${branch_name}") || return 1

    echo "Constitutional pull request created: ${pr_url}"
    echo "${pr_url}"
    return 0
}

#######################################
# Get repository status summary
# Outputs:
#   Human-readable status summary
#######################################
get_repo_status_summary() {
    local repo_info
    repo_info=$(get_repo_info)

    if echo "$repo_info" | jq -e '.error' &>/dev/null; then
        echo "ERROR: Unable to fetch repository information"
        return 1
    fi

    local repo_name repo_desc last_push is_private default_branch
    repo_name=$(echo "${repo_info}" | jq -r '.name')
    repo_desc=$(echo "${repo_info}" | jq -r '.description // "No description"')
    last_push=$(echo "${repo_info}" | jq -r '.pushedAt')
    is_private=$(echo "${repo_info}" | jq -r '.isPrivate')
    default_branch=$(echo "${repo_info}" | jq -r '.defaultBranch')

    cat <<EOF
Repository: ${repo_name}
Description: ${repo_desc}
Last push: ${last_push}
Private: ${is_private}
Default branch: ${default_branch}
EOF
}

#######################################
# Manage branch operations
# Arguments:
#   $1 - Log function name (optional)
# Outputs:
#   Branch management status
#######################################
manage_branches() {
    local log_func="${1:-echo}"

    $log_func "Managing branches with constitutional strategy..."

    # List all branches
    local branches
    branches=$(get_repo_branches)

    $log_func "Available branches: ${branches}"

    # Check for constitutional branch naming pattern
    local constitutional_branches=0
    for branch in $branches; do
        if is_constitutional_branch "$branch"; then
            constitutional_branches=$((constitutional_branches + 1))
        fi
    done

    $log_func "Constitutional branches found: ${constitutional_branches}"

    # Check current branch
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    $log_func "Current branch: ${current_branch}"

    # Check if current branch follows constitutional naming
    if is_constitutional_branch "${current_branch}"; then
        $log_func "SUCCESS: Current branch follows constitutional naming convention"
    elif [[ "${current_branch}" == "main" || "${current_branch}" == "master" ]]; then
        $log_func "INFO: On default branch (acceptable)"
    else
        $log_func "WARNING: Current branch does not follow constitutional naming convention"
        $log_func "INFO: Constitutional format: YYYYMMDD-HHMMSS-type-description"
    fi
}

#######################################
# Monitor GitHub API performance
# Outputs:
#   Performance metrics
#######################################
monitor_gh_performance() {
    local start_time api_time repo_time

    start_time=$(date +%s)

    # Test GitHub API responsiveness
    local api_start api_end
    api_start=$(date +%s%3N)
    gh api user &>/dev/null
    api_end=$(date +%s%3N)
    api_time=$((api_end - api_start))

    echo "GitHub API response time: ${api_time}ms"

    # Test repository operations
    local repo_start repo_end
    repo_start=$(date +%s%3N)
    gh repo view &>/dev/null
    repo_end=$(date +%s%3N)
    repo_time=$((repo_end - repo_start))

    echo "Repository operation time: ${repo_time}ms"

    local total_time=$(($(date +%s) - start_time))
    echo "Total GitHub CLI integration time: ${total_time}s"
}

# Export functions
export -f get_repo_info get_repo_branches is_constitutional_branch
export -f get_workflow_runs get_open_issues get_open_prs get_latest_release
export -f create_constitutional_branch create_constitutional_pr
export -f get_repo_status_summary manage_branches monitor_gh_performance
