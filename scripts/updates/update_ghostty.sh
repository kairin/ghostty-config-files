#!/bin/bash
# update_ghostty.sh - Ghostty Update Script with Agent Monitoring
# Orchestrates Ghostty updates using modular components from lib/updates/

set -euo pipefail

CONFIG_UPDATED=false
APP_UPDATED=false

# Agent configuration
AGENT_MODE="${1:-normal}"
AGENT_VERBOSE="${GHOSTTY_AGENT_VERBOSE:-true}"
AGENT_LOG_DIR="/tmp/ghostty-agent-logs"
AGENT_LOG_FILE="$AGENT_LOG_DIR/update-agent-$(date +%s).log"
AGENT_PID_FILE="/tmp/ghostty-update-agent.pid"

# Create agent log directory
mkdir -p "$AGENT_LOG_DIR"

# Store agent PID for monitoring
echo $$ > "$AGENT_PID_FILE"

# Determine script and repo paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source modular components
source "$REPO_ROOT/lib/updates/ghostty-specific.sh"
source "$REPO_ROOT/lib/installers/zig.sh"
source "$REPO_ROOT/lib/installers/ghostty-deps.sh"

# Enhanced agent logging with process visibility
agent_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [UPDATE-AGENT] [$level] $message"

    echo "$log_entry" >> "$AGENT_LOG_FILE"

    if [[ "$AGENT_VERBOSE" == "true" ]] || [[ "$level" == "ERROR" ]] || [[ "$level" == "WARNING" ]]; then
        echo "$log_entry"
    fi
}

# Agent cleanup function
agent_cleanup() {
    agent_log "INFO" "Update agent cleanup initiated"
    rm -f "$AGENT_PID_FILE"
    agent_log "INFO" "Agent log available at: $AGENT_LOG_FILE"
}

# Set trap for agent cleanup
trap agent_cleanup EXIT

agent_log "INFO" "Update agent started in mode: $AGENT_MODE"

# Determine the real user's home directory, even when run with sudo
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    REAL_HOME="$HOME"
fi

# Pull latest changes for the config repository
echo ""
echo "-> Pulling latest changes for Ghostty config..."

# Backup current configuration
CONFIG_BACKUP_DIR=$(backup_ghostty_config "." 2>/dev/null || echo "/tmp/ghostty-config-backup-$(date +%s)")
mkdir -p "$CONFIG_BACKUP_DIR"
cp config theme.conf "$CONFIG_BACKUP_DIR/" 2>/dev/null || echo "Warning: Some config files may not exist"

# Check for local changes before pulling
if ! git diff-index --quiet HEAD --; then
    echo "-> Local changes detected. Stashing them before pull..."
    git stash push -m "Ghostty config changes before pull by setup_ghostty.sh" || { echo "Error: Failed to stash local changes."; exit 1; }
    STASHED_CHANGES=true
else
    STASHED_CHANGES=false
fi

if ! CONFIG_PULL_OUTPUT=$(git pull 2>&1); then
    echo "Error: Failed to pull Ghostty config changes."
    echo "Git output: $CONFIG_PULL_OUTPUT"
    exit 1
fi

# Reapply stashed changes if any
if [[ "$STASHED_CHANGES" == "true" ]]; then
    echo "-> Reapplying stashed changes..."
    git stash pop || { echo "Warning: Failed to reapply stashed changes. Please resolve conflicts manually."; }
fi

# Test configuration
if ! test_ghostty_config; then
    echo "Attempting automatic cleanup..."
    if ! attempt_config_fix "$CONFIG_BACKUP_DIR"; then
        echo "-> Configuration issues handled. Please check for incompatible changes."
    fi

    if ghostty +show-config >/dev/null 2>&1; then
        echo "Configuration now works"
    else
        echo "Configuration still has issues. Please check manually."
    fi
fi

# Clean up backup if everything is working
[[ -d "$CONFIG_BACKUP_DIR" ]] && rm -rf "$CONFIG_BACKUP_DIR"

if [[ "$CONFIG_PULL_OUTPUT" == *"Already up to date."* ]]; then
    echo "Ghostty config is already up to date."
    CONFIG_UPDATED=false
else
    echo "$CONFIG_PULL_OUTPUT"
    echo "Ghostty config updated."
    CONFIG_UPDATED=true
fi

echo "Starting dependency check..."
agent_log "INFO" "Initiating dependency verification process..."

# Install dependencies and build tools
install_ghostty_dependencies || echo "Warning: Some dependencies may be missing"
verify_build_tools || echo "Warning: Some build tools may be missing"

# Ensure Zig is installed
if ! install_zig; then
    echo "Error: Failed to install Zig."
    exit 1
fi

# Pre-build verification
if ! verify_critical_build_tools; then
    print_dependency_instructions
    exit 1
fi

verify_gtk4_libadwaita || true

echo "System verification complete."

echo "Getting old Ghostty version..."
OLD_VERSION=$(get_ghostty_version)

echo "======================================="
echo "   Updating Ghostty to the latest version"
echo "======================================="

# Navigate to Ghostty repository
cd ~/Apps/ghostty || { echo "Error: Ghostty application directory not found at ~/Apps/ghostty."; exit 1; }

echo ""
echo "-> Pulling the latest changes for Ghostty app..."

if ! APP_PULL_OUTPUT=$(git pull 2>&1); then
    echo "Error: Failed to pull Ghostty app changes."
    exit 1
fi

if [[ "$APP_PULL_OUTPUT" == *"Already up to date."* ]]; then
    echo "Ghostty app is already up to date."
    APP_UPDATED=false
else
    echo "$APP_PULL_OUTPUT"
    echo "Ghostty app updated."
    APP_UPDATED=true
fi

agent_log "INFO" "Starting Ghostty build process..."
if ! build_ghostty ~/Apps/ghostty; then
    agent_log "ERROR" "Ghostty build failed"
    APP_UPDATED=false
    exit 1
fi
agent_log "SUCCESS" "Ghostty build completed successfully"

# Kill any running Ghostty processes
kill_ghostty_processes

# Install Ghostty
if ! install_ghostty; then
    APP_UPDATED=false
    exit 1
fi

# Test configuration after installation
echo "-> Testing configuration after Ghostty installation..."
if ! ghostty +show-config >/dev/null 2>post_install_errors.log; then
    echo "Configuration errors detected after Ghostty installation:"
    cat post_install_errors.log
    echo "-> This suggests the new Ghostty version has compatibility issues with current config."
    rm -f post_install_errors.log
else
    echo "Configuration works with new Ghostty version"
    rm -f post_install_errors.log
fi

# Print summary
NEW_VERSION=$(get_ghostty_version)
print_update_summary "$OLD_VERSION" "$NEW_VERSION" "$CONFIG_UPDATED" "$APP_UPDATED"
