#!/bin/bash
# Script: extract_ai_context.sh
# Purpose: Extract shell history, git state, environment for AI context
# Performance Target: <100ms execution time
# Dependencies: jq, git (optional), perl (for zsh history parsing)
# Exit Codes: 0=success, 1=general failure

set -euo pipefail

# ============================================================
# CONFIGURATION
# ============================================================

readonly CONTEXT_DIR="${HOME}/.cache/ghostty-ai-context"
readonly CACHE_MAX_AGE=1  # seconds (constitutional requirement: <1s max age)

# Ensure context directory exists
mkdir -p "$CONTEXT_DIR"

# ============================================================
# HELPER FUNCTIONS
# ============================================================

# Function: extract_shell_history
# Purpose: Extract last 10 commands from zsh_history
# Returns: JSON array of command objects
# Performance: <20ms
extract_shell_history() {
    local history_file="${HOME}/.zsh_history"

    if [[ ! -f "$history_file" ]]; then
        echo "[]"
        return 0
    fi

    # Parse zsh extended format: : timestamp:duration;command
    # Use perl for fast parsing with proper JSON escaping
    tail -n 10 "$history_file" 2>/dev/null | perl -lne '
        if (m#: (\d+):(\d+);(.+)#) {
            my ($timestamp, $duration, $command) = ($1, $2, $3);
            # Escape special JSON characters
            $command =~ s/\\/\\\\/g;   # Backslash
            $command =~ s/"/\\"/g;     # Quote
            $command =~ s/\n/\\n/g;    # Newline
            $command =~ s/\r/\\r/g;    # Carriage return
            $command =~ s/\t/\\t/g;    # Tab
            print qq({"timestamp":$timestamp,"duration":$duration,"command":"$command"});
        }
    ' | jq -s '.' 2>/dev/null || echo "[]"
}

# Function: extract_git_context
# Purpose: Extract git branch, status, recent commits
# Returns: JSON object with git information
# Performance: <30ms
extract_git_context() {
    # Check if in git repository
    if ! git rev-parse --git-dir &> /dev/null; then
        echo '{"in_repo":false}'
        return 0
    fi

    local branch status commits

    # Get current branch (handle detached HEAD)
    branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")

    # Get git status (porcelain format for machine parsing)
    status=$(git status --porcelain 2>/dev/null | jq -R . | jq -s '.' 2>/dev/null || echo "[]")

    # Get last 5 commits (one-line format)
    commits=$(git log --oneline -5 2>/dev/null | jq -R . | jq -s '.' 2>/dev/null || echo "[]")

    # Get repository root
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

    # Combine into JSON object
    jq -n \
        --arg branch "$branch" \
        --argjson status "$status" \
        --argjson commits "$commits" \
        --arg repo_root "$repo_root" \
        '{in_repo:true,branch:$branch,status:$status,recent_commits:$commits,repo_root:$repo_root}' \
        2>/dev/null || echo '{"in_repo":false}'
}

# Function: extract_environment
# Purpose: Extract relevant environment variables
# Returns: JSON object with environment variables
# Performance: <10ms
extract_environment() {
    # Get Node.js version if available
    local node_version
    node_version=$(node --version 2>/dev/null || echo "not installed")

    # Get npm version if available
    local npm_version
    npm_version=$(npm --version 2>/dev/null || echo "not installed")

    # Get Python version if available
    local python_version
    python_version=$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo "not installed")

    # Combine into JSON object
    jq -n \
        --arg pwd "$PWD" \
        --arg user "${USER:-unknown}" \
        --arg shell "${SHELL:-unknown}" \
        --arg term "${TERM:-unknown}" \
        --arg lang "${LANG:-unknown}" \
        --arg git_author_name "${GIT_AUTHOR_NAME:-not set}" \
        --arg git_author_email "${GIT_AUTHOR_EMAIL:-not set}" \
        --arg node_version "$node_version" \
        --arg npm_version "$npm_version" \
        --arg python_version "$python_version" \
        --arg hostname "${HOSTNAME:-$(hostname 2>/dev/null || echo unknown)}" \
        '{
            PWD: $pwd,
            USER: $user,
            SHELL: $shell,
            TERM: $term,
            LANG: $lang,
            GIT_AUTHOR_NAME: $git_author_name,
            GIT_AUTHOR_EMAIL: $git_author_email,
            NODE_VERSION: $node_version,
            NPM_VERSION: $npm_version,
            PYTHON_VERSION: $python_version,
            HOSTNAME: $hostname
        }' 2>/dev/null || echo '{}'
}

# Function: check_cache
# Purpose: Check if cached context is fresh enough
# Returns: 0 if cache valid (outputs cached data), 1 otherwise
# Performance: <5ms
check_cache() {
    # Find latest context file
    local latest_context
    latest_context=$(find "$CONTEXT_DIR" -name "context-*.json" -type f -printf '%T@ %p\n' 2>/dev/null | \
                     sort -rn | head -n1 | awk '{print $2}')

    if [[ -z "$latest_context" ]]; then
        return 1  # No cache exists
    fi

    # Check cache age
    local cache_age file_mtime current_time
    file_mtime=$(stat -c %Y "$latest_context" 2>/dev/null || echo 0)
    current_time=$(date +%s)
    cache_age=$((current_time - file_mtime))

    if [[ $cache_age -lt $CACHE_MAX_AGE ]]; then
        # Cache is fresh, output existing file
        cat "$latest_context"
        return 0
    fi

    return 1  # Cache expired
}

# Function: cleanup_old_context_files
# Purpose: Remove old context files, keeping only the last 10
# Returns: 0 on success
# Performance: <5ms
cleanup_old_context_files() {
    # Find and delete all but the 10 most recent context files
    find "$CONTEXT_DIR" -name "context-*.json" -type f -printf '%T@ %p\n' 2>/dev/null | \
        sort -rn | tail -n +11 | awk '{print $2}' | xargs -r rm -f 2>/dev/null || true
    return 0
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    # Start performance timer (for debugging)
    local start_time
    start_time=$(date +%s%N)

    # Check cache first (performance optimization)
    if check_cache; then
        # Cache hit - exit early
        exit 0
    fi

    # Generate fresh context
    local timestamp context_file
    timestamp=$(date +%s)
    context_file="${CONTEXT_DIR}/context-${timestamp}.json"

    # Extract all context data in parallel (faster)
    local shell_history git_context environment

    shell_history=$(extract_shell_history)
    git_context=$(extract_git_context)
    environment=$(extract_environment)

    # Combine into final JSON
    jq -n \
        --argjson timestamp "$timestamp" \
        --argjson shell_history "$shell_history" \
        --argjson git "$git_context" \
        --argjson environment "$environment" \
        '{
            timestamp: $timestamp,
            shell_history: $shell_history,
            git: $git,
            environment: $environment
        }' > "$context_file" 2>/dev/null

    # Output to stdout
    cat "$context_file"

    # Clean up old context files (keep last 10)
    cleanup_old_context_files

    # Calculate execution time (for performance monitoring)
    local end_time duration_ns duration_ms
    end_time=$(date +%s%N)
    duration_ns=$((end_time - start_time))
    duration_ms=$((duration_ns / 1000000))

    # Log performance to stderr (only if > 100ms)
    if [[ $duration_ms -gt 100 ]]; then
        echo "⚠ extract_ai_context.sh took ${duration_ms}ms (target: <100ms)" >&2
    fi

    return 0
}

# Execute main if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
