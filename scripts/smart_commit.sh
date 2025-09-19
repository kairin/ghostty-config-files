#!/bin/bash

# Smart Commit Strategy for ghostty-config-files
# Implements MetaSpec-Kyocera-style branch management with preservation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""

    case "$level" in
        "ERROR") color="$RED" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "INFO") color="$BLUE" ;;
        "STEP") color="$CYAN" ;;
    esac

    echo -e "${color}[$timestamp] [$level] $message${NC}"
}

# Show help
show_help() {
    echo "Smart Commit Strategy for Ghostty Configuration Files"
    echo ""
    echo "Usage: $0 [TYPE] [DESCRIPTION] [OPTIONS]"
    echo ""
    echo "Types:"
    echo "  feat        New feature implementation"
    echo "  fix         Bug fix or correction"
    echo "  docs        Documentation updates"
    echo "  config      Configuration optimization"
    echo "  refactor    Code refactoring"
    echo "  test        Testing improvements"
    echo "  ci          CI/CD updates"
    echo ""
    echo "Options:"
    echo "  --dry-run   Show what would be done without executing"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 feat \"context menu integration\""
    echo "  $0 config \"2025 performance optimizations\""
    echo "  $0 docs \"enhanced AGENTS.md documentation\""
    echo ""
    echo "Branch naming follows: YYYYMMDD-HHMMSS-type-description"
    echo "Branches are preserved (never deleted) as per MetaSpec-Kyocera strategy"
    echo ""
}

# Validate inputs
validate_inputs() {
    local commit_type="$1"
    local description="$2"

    # Check commit type
    case "$commit_type" in
        feat|fix|docs|config|refactor|test|ci)
            ;;
        *)
            log "ERROR" "Invalid commit type: $commit_type"
            log "INFO" "Valid types: feat, fix, docs, config, refactor, test, ci"
            return 1
            ;;
    esac

    # Check description
    if [ -z "$description" ]; then
        log "ERROR" "Description cannot be empty"
        return 1
    fi

    # Check description length
    if [ ${#description} -gt 50 ]; then
        log "WARNING" "Description is quite long (${#description} chars). Consider shortening."
    fi

    return 0
}

# Pre-commit validation
pre_commit_validation() {
    log "STEP" "🔧 Running pre-commit validation..."

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        log "ERROR" "Not in a git repository"
        return 1
    fi

    # Check for staged changes
    if ! git diff --staged --quiet; then
        log "INFO" "📋 Found staged changes"
    else
        log "WARNING" "⚠️ No staged changes found. Consider staging files first."
        git status --short
        return 1
    fi

    # Run local CI/CD validation if available
    if [ -f "$REPO_DIR/local-infra/runners/gh-workflow-local.sh" ]; then
        log "INFO" "🏗️ Running local CI/CD validation..."
        if ! "$REPO_DIR/local-infra/runners/gh-workflow-local.sh" validate; then
            log "ERROR" "Local CI/CD validation failed"
            return 1
        fi
    fi

    # Ghostty-specific validations
    if command -v ghostty >/dev/null 2>&1; then
        if ! ghostty +show-config >/dev/null 2>&1; then
            log "ERROR" "Ghostty configuration validation failed"
            return 1
        fi
        log "SUCCESS" "✅ Ghostty configuration valid"
    fi

    log "SUCCESS" "✅ Pre-commit validation passed"
    return 0
}

# Generate branch name
generate_branch_name() {
    local commit_type="$1"
    local description="$2"

    # Create timestamp
    local datetime
    datetime=$(date +"%Y%m%d-%H%M%S")

    # Clean description (remove special chars, spaces to hyphens, lowercase)
    local clean_description
    clean_description=$(echo "$description" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-' | sed 's/--*/-/g' | sed 's/^-\|-$//g')

    # Limit description length
    if [ ${#clean_description} -gt 30 ]; then
        clean_description=$(echo "$clean_description" | cut -c1-30)
        # Remove trailing hyphen if any
        clean_description=$(echo "$clean_description" | sed 's/-$//')
    fi

    echo "${datetime}-${commit_type}-${clean_description}"
}

# Create commit message
create_commit_message() {
    local commit_type="$1"
    local description="$2"
    local branch_name="$3"

    local commit_msg=""

    # Add type prefix for conventional commits
    case "$commit_type" in
        feat) commit_msg="feat: $description" ;;
        fix) commit_msg="fix: $description" ;;
        docs) commit_msg="docs: $description" ;;
        config) commit_msg="config: $description" ;;
        refactor) commit_msg="refactor: $description" ;;
        test) commit_msg="test: $description" ;;
        ci) commit_msg="ci: $description" ;;
    esac

    # Add additional context
    commit_msg="$commit_msg

Branch: $branch_name
Timestamp: $(date -Iseconds)

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

    echo "$commit_msg"
}

# Execute smart commit
execute_smart_commit() {
    local commit_type="$1"
    local description="$2"
    local dry_run="$3"

    log "INFO" "🚀 Starting smart commit process..."

    # Generate branch name
    local branch_name
    branch_name=$(generate_branch_name "$commit_type" "$description")
    log "INFO" "📋 Branch name: $branch_name"

    # Create commit message
    local commit_message
    commit_message=$(create_commit_message "$commit_type" "$description" "$branch_name")

    if $dry_run; then
        log "INFO" "🏃 DRY RUN MODE - Would execute:"
        echo ""
        echo "Branch: $branch_name"
        echo ""
        echo "Commit message:"
        echo "$commit_message"
        echo ""
        echo "Commands that would be executed:"
        echo "  git checkout -b \"$branch_name\""
        echo "  git commit -m \"...\""
        echo "  git push -u origin \"$branch_name\""
        echo "  git checkout main"
        echo "  git merge \"$branch_name\" --no-ff"
        echo "  git push origin main"
        echo "  # Branch $branch_name would be preserved (NOT deleted)"
        return 0
    fi

    # Get current branch for safety
    local current_branch
    current_branch=$(git branch --show-current)
    log "INFO" "📋 Current branch: $current_branch"

    # Create new branch
    log "STEP" "🌿 Creating branch: $branch_name"
    git checkout -b "$branch_name"

    # Commit changes
    log "STEP" "💾 Committing changes..."
    git commit -m "$commit_message"

    # Push branch
    log "STEP" "⬆️ Pushing branch to remote..."
    git push -u origin "$branch_name"

    # Switch to main and merge
    log "STEP" "🔄 Merging to main branch..."
    git checkout main
    git merge "$branch_name" --no-ff --message "Merge branch '$branch_name'

Merged branch with 2025 performance optimizations and smart commit strategy.

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

    # Push main
    log "STEP" "⬆️ Pushing main branch..."
    git push origin main

    # IMPORTANT: Do NOT delete the branch (MetaSpec-Kyocera strategy)
    log "INFO" "🔒 Branch '$branch_name' preserved for historical reference"

    log "SUCCESS" "🎉 Smart commit completed successfully!"
    log "INFO" "📊 Summary:"
    log "INFO" "   Type: $commit_type"
    log "INFO" "   Description: $description"
    log "INFO" "   Branch: $branch_name (preserved)"
    log "INFO" "   Merged to: main"

    return 0
}

# Main execution
main() {
    local commit_type=""
    local description=""
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                if [ -z "$commit_type" ]; then
                    commit_type="$1"
                elif [ -z "$description" ]; then
                    description="$1"
                else
                    log "ERROR" "Too many arguments: $1"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Check required arguments
    if [ -z "$commit_type" ] || [ -z "$description" ]; then
        log "ERROR" "Missing required arguments"
        show_help
        exit 1
    fi

    # Validate inputs
    if ! validate_inputs "$commit_type" "$description"; then
        exit 1
    fi

    # Run pre-commit validation (skip in dry-run)
    if ! $dry_run && ! pre_commit_validation; then
        log "ERROR" "Pre-commit validation failed"
        exit 1
    fi

    # Execute smart commit
    execute_smart_commit "$commit_type" "$description" "$dry_run"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi