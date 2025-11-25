#!/bin/bash

# Smart Update Checker for Ghostty Configuration Repository
# This script checks for updates and intelligently applies them

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOME/.config/ghostty"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    local level="$1"
    shift
    local message="$*"
    local color=""

    case "$level" in
        "ERROR") color="$RED" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "INFO") color="$BLUE" ;;
    esac

    echo -e "${color}[$level] $message${NC}"
}

# Cleanup function (called on EXIT)
cleanup() {
    local exit_code=$?

    # Only log if there are actual cleanup tasks
    if [ -n "${CLEANUP_NEEDED:-}" ]; then
        log "INFO" "🧹 Cleaning up..."

        # Clean up any temporary backup files older than 30 days
        if [ -d "$CONFIG_DIR" ]; then
            find "$CONFIG_DIR" -name "config.backup-*" -type f -mtime +30 -delete 2>/dev/null || true
        fi
    fi

    # Exit with original code
    exit $exit_code
}

# Set trap for cleanup on exit
trap cleanup EXIT

# Check if repo needs updates
check_repo_updates() {
    cd "$REPO_DIR"

    if [ -d ".git" ]; then
        log "INFO" "Checking for repository updates..."

        # Fetch latest changes
        git fetch origin >/dev/null 2>&1 || {
            log "WARNING" "Could not fetch updates from remote repository"
            return 1
        }

        # Check if we're behind
        local local_commit
        local_commit=$(git rev-parse HEAD)
        local remote_commit
        remote_commit=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)

        if [ "$local_commit" != "$remote_commit" ]; then
            log "INFO" "🆕 Repository updates available!"
            return 0
        else
            log "SUCCESS" "✅ Repository is up to date"
            return 1
        fi
    else
        log "WARNING" "Not a git repository, skipping update check"
        return 1
    fi
}

# Update repository and apply changes
update_repo() {
    cd "$REPO_DIR"

    log "INFO" "📥 Pulling latest changes..."
    if git pull origin main >/dev/null 2>&1 || git pull origin master >/dev/null 2>&1; then
        log "SUCCESS" "✅ Repository updated successfully"
        return 0
    else
        log "ERROR" "❌ Failed to update repository"
        return 1
    fi
}

# Check if configuration needs updates
check_config_updates() {
    if [ ! -f "$CONFIG_DIR/config" ]; then
        log "INFO" "📋 No existing configuration found"
        return 0
    fi

    local config_file="$CONFIG_DIR/config"
    local needs_update=false

    log "INFO" "🔍 Checking configuration for 2025 optimizations..."

    # Check for key optimizations
    if ! grep -q "linux-cgroup.*single-instance" "$config_file"; then
        log "INFO" "📋 Missing: Linux CGroup single-instance optimization"
        needs_update=true
    fi

    if ! grep -q "shell-integration.*detect" "$config_file"; then
        log "INFO" "📋 Missing: Enhanced shell integration"
        needs_update=true
    fi

    if ! grep -q "clipboard-paste-protection" "$config_file"; then
        log "INFO" "📋 Missing: Clipboard paste protection"
        needs_update=true
    fi

    if ! grep -q "theme.*dark.*light" "$config_file" && ! [ -f "$CONFIG_DIR/theme.conf" ] || \
       ! grep -q "dark.*catppuccin.*light" "$CONFIG_DIR/theme.conf" 2>/dev/null; then
        log "INFO" "📋 Missing: Auto theme switching"
        needs_update=true
    fi

    if $needs_update; then
        log "WARNING" "⚠️  Configuration needs 2025 optimizations"
        return 0
    else
        log "SUCCESS" "✅ Configuration has latest optimizations"
        return 1
    fi
}

# Apply configuration updates
apply_config_updates() {
    log "INFO" "🔧 Applying configuration updates..."

    # Backup existing config
    if [ -f "$CONFIG_DIR/config" ]; then
        local backup_file
        backup_file="$CONFIG_DIR/config.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$CONFIG_DIR/config" "$backup_file"
        log "SUCCESS" "✅ Backed up existing config to: $(basename "$backup_file")"
        CLEANUP_NEEDED=1  # Signal cleanup to run
    fi

    # Copy new configurations
    if [ -d "$REPO_DIR/configs/ghostty" ]; then
        cp -r "$REPO_DIR/configs/ghostty"/* "$CONFIG_DIR/"
        log "SUCCESS" "✅ Applied updated configuration"

        # Validate configuration
        if command -v ghostty >/dev/null 2>&1; then
            if ghostty +show-config >/dev/null 2>&1; then
                log "SUCCESS" "✅ Configuration validated successfully"
                return 0
            else
                log "ERROR" "❌ Configuration validation failed, restoring backup"
                if [ -f "$backup_file" ]; then
                    cp "$backup_file" "$CONFIG_DIR/config"
                fi
                return 1
            fi
        else
            log "WARNING" "⚠️  Ghostty not found, cannot validate configuration"
        fi
    else
        log "ERROR" "❌ Configuration source not found"
        return 1
    fi
}

# Main update process
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Ghostty Configuration Update Checker${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    local repo_updated=false
    local config_updated=false

    # Check for repository updates
    if check_repo_updates; then
        if update_repo; then
            repo_updated=true
        fi
    fi

    # Check for configuration updates
    if check_config_updates; then
        if apply_config_updates; then
            config_updated=true
        fi
    fi

    # Summary
    echo ""
    if $repo_updated || $config_updated; then
        log "SUCCESS" "🎉 Updates applied successfully!"
        if $config_updated; then
            log "INFO" "💡 Restart Ghostty to apply configuration changes"
        fi
    else
        log "SUCCESS" "✅ Everything is up to date!"
    fi

    # Check for context menu
    if [ ! -f "$HOME/.local/share/nautilus/scripts/Open in Ghostty" ]; then
        log "INFO" "💡 Run '$REPO_DIR/scripts/install_context_menu.sh' to add right-click integration"
    fi
}

# Show help
show_help() {
    echo "Ghostty Configuration Update Checker"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --force        Force update even if no changes detected"
    echo "  --config-only  Only update configuration, skip repository check"
    echo ""
}

# Parse arguments
FORCE_UPDATE=false
CONFIG_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --force)
            FORCE_UPDATE=true
            shift
            ;;
        --config-only)
            CONFIG_ONLY=true
            shift
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main "$@"