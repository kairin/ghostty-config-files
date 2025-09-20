#!/bin/bash

set -euo pipefail

# Comprehensive Start Script for Ghostty, Ptyxis, Claude Code, and Gemini CLI
# This script handles complete installation of all terminal tools and AI assistants

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/tmp/ghostty-start-logs"
LOG_FILE="$LOG_DIR/start-$(date +%s).log"
REAL_HOME="${SUDO_HOME:-$HOME}"
NVM_VERSION="v0.40.1"
NODE_VERSION="24.6.0"

# Directories
GHOSTTY_APP_DIR="$REAL_HOME/Apps/ghostty"
GHOSTTY_CONFIG_DIR="$REAL_HOME/.config/ghostty"
GHOSTTY_CONFIG_SOURCE="$SCRIPT_DIR/configs/ghostty"
NVM_DIR="$REAL_HOME/.nvm"
APPS_DIR="$REAL_HOME/Apps"

# Global variables for installation status and strategies
ghostty_installed=false
ghostty_version=""
ghostty_config_valid=false
ptyxis_installed=false
ptyxis_version=""
ptyxis_source=""
GHOSTTY_STRATEGY=""
PTYXIS_STRATEGY=""
CONFIG_NEEDS_UPDATE=false

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Enhanced logging function with structured output
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    local prefix=""

    case "$level" in
        "ERROR") color="$RED"; prefix="❌" ;;
        "SUCCESS") color="$GREEN"; prefix="✅" ;;
        "WARNING") color="$YELLOW"; prefix="⚠️" ;;
        "INFO") color="$BLUE"; prefix="ℹ️" ;;
        "STEP") color="$CYAN"; prefix="🔧" ;;
        "DEBUG") color="$YELLOW"; prefix="🐛" ;;
        "TEST") color="$CYAN"; prefix="🧪" ;;
    esac

    # Console output with colors
    echo -e "${color}[$timestamp] [$level] $prefix $message${NC}"

    # Structured log file output (JSON-like for parsing)
    echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\",\"function\":\"${FUNCNAME[1]:-main}\",\"line\":\"${BASH_LINENO[1]:-0}\"}" >> "$LOG_FILE.json"

    # Human-readable log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Error log file for critical issues
    if [ "$level" = "ERROR" ] || [ "$level" = "WARNING" ]; then
        echo "[$timestamp] [$level] [${FUNCNAME[1]:-main}:${BASH_LINENO[1]:-0}] $message" >> "$LOG_DIR/errors.log"
    fi
}

# Debug logging (only shown if VERBOSE=true)
debug() {
    if $VERBOSE; then
        log "DEBUG" "$@"
    else
        # Still log to file even if not shown
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] [DEBUG] $*" >> "$LOG_FILE"
    fi
}

# Progressive disclosure logging system (like Claude Code)
declare -A active_tasks
task_counter=0

# Start a new task with progressive disclosure
start_task() {
    local task_name="$1"
    local task_description="$2"

    task_counter=$((task_counter + 1))
    local task_id="task_${task_counter}"

    active_tasks[$task_id]="$task_name"

    # Clear previous output and show task header
    echo -ne "\r\033[K"  # Clear current line
    echo -e "${CYAN}▶️  $task_name${NC}"
    if [ -n "$task_description" ]; then
        echo -e "${BLUE}   $task_description${NC}"
    fi
    echo "───────────────────────────────────────"

    # Store task start info
    echo "$task_id|$task_name|$(date +%s)" > "/tmp/current_task_$task_id"
    echo "$task_id"
}

# Stream command output in real-time
stream_command() {
    local task_id="$1"
    local command="$2"
    local description="$3"

    echo -e "${YELLOW}💻 Running: ${NC}$description"
    echo -e "${CYAN}   Command: ${NC}$command"
    echo "───────────────────────────────────────"

    # Execute command and stream output
    local start_time=$(date +%s)
    local temp_log="/tmp/command_output_$task_id"

    # Run command with real-time output
    if eval "$command" 2>&1 | while IFS= read -r line; do
        echo "$line"
        echo "$line" >> "$temp_log"
    done; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo "───────────────────────────────────────"
        echo -e "${GREEN}✅ Completed in ${duration}s${NC}"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo "───────────────────────────────────────"
        echo -e "${RED}❌ Failed after ${duration}s${NC}"
        return 1
    fi
}

# Complete and collapse a task
complete_task() {
    local task_id="$1"
    local status="${2:-success}"
    local summary="$3"

    local task_name="${active_tasks[$task_id]}"

    if [ -f "/tmp/current_task_$task_id" ]; then
        local task_info=$(cat "/tmp/current_task_$task_id")
        local start_time=$(echo "$task_info" | cut -d'|' -f3)
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))

        # Clear the detailed output area
        tput cuu 10  # Move cursor up 10 lines
        tput ed      # Clear from cursor to end of screen

        # Show collapsed summary
        if [ "$status" = "success" ]; then
            echo -e "${GREEN}✅ $task_name${NC} ${CYAN}(${duration}s)${NC}"
        elif [ "$status" = "warning" ]; then
            echo -e "${YELLOW}⚠️  $task_name${NC} ${CYAN}(${duration}s)${NC}"
        else
            echo -e "${RED}❌ $task_name${NC} ${CYAN}(${duration}s)${NC}"
        fi

        if [ -n "$summary" ]; then
            echo -e "${BLUE}   $summary${NC}"
        fi

        # Cleanup
        rm -f "/tmp/current_task_$task_id"
        rm -f "/tmp/command_output_$task_id"
        unset active_tasks[$task_id]
    fi
}

# Enhanced command runner with progressive disclosure
run_task_command() {
    local task_name="$1"
    local command="$2"
    local description="${3:-$command}"
    local expected_duration="${4:-unknown}"

    # Start the task
    local task_id=$(start_task "$task_name" "$description")

    # Show expected duration if provided
    if [ "$expected_duration" != "unknown" ]; then
        echo -e "${BLUE}   Expected duration: ~${expected_duration}${NC}"
        echo "───────────────────────────────────────"
    fi

    # Stream the command
    if stream_command "$task_id" "$command" "$description"; then
        complete_task "$task_id" "success" "Completed successfully"
        return 0
    else
        complete_task "$task_id" "error" "Command failed"
        return 1
    fi
}

# Test result logging
test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"

    if [ "$result" = "PASS" ]; then
        log "TEST" "✅ $test_name: PASSED - $details"
    else
        log "TEST" "❌ $test_name: FAILED - $details"
    fi
}

# Performance timing
start_timer() {
    TIMER_START=$(date +%s)
}

end_timer() {
    local operation="$1"
    if [ -n "$TIMER_START" ]; then
        local duration=$(($(date +%s) - TIMER_START))
        log "INFO" "⏱️ $operation completed in ${duration}s"
        unset TIMER_START
    fi
}

# System state capture
capture_system_state() {
    local state_file="$LOG_DIR/system_state_$(date +%s).json"
    debug "Capturing system state to $state_file"

    cat > "$state_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system": {
        "os": "$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")",
        "kernel": "$(uname -r)",
        "architecture": "$(uname -m)",
        "memory_gb": "$(free -g | awk '/^Mem:/{print $2}')",
        "disk_space_gb": "$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')"
    },
    "ghostty": {
        "installed": $(command -v ghostty >/dev/null && echo "true" || echo "false"),
        "version": "$(ghostty --version 2>/dev/null || echo "not_installed")",
        "config_exists": $([ -f "$GHOSTTY_CONFIG_DIR/config" ] && echo "true" || echo "false"),
        "config_valid": $(ghostty +show-config >/dev/null 2>&1 && echo "true" || echo "false")
    },
    "environment": {
        "shell": "$SHELL",
        "desktop_session": "${XDG_CURRENT_DESKTOP:-unknown}",
        "display_server": "${XDG_SESSION_TYPE:-unknown}",
        "node_version": "$(node --version 2>/dev/null || echo "not_installed")",
        "npm_version": "$(npm --version 2>/dev/null || echo "not_installed")"
    }
}
EOF

    debug "System state captured successfully"
}

# Performance monitoring
monitor_performance() {
    local operation="$1"
    local start_time=$(date +%s.%N)
    local start_memory=$(free -m | awk 'NR==2{printf "%.2f", $3/1024 }')

    debug "Starting performance monitoring for: $operation"
    debug "Initial memory usage: ${start_memory}GB"

    # Store for later use
    PERF_START_TIME="$start_time"
    PERF_START_MEMORY="$start_memory"
    PERF_OPERATION="$operation"
}

end_performance_monitoring() {
    if [ -n "$PERF_START_TIME" ]; then
        local end_time=$(date +%s.%N)
        local end_memory=$(free -m | awk 'NR==2{printf "%.2f", $3/1024 }')
        local duration=$(echo "$end_time - $PERF_START_TIME" | bc 2>/dev/null || echo "0")
        local memory_delta=$(echo "$end_memory - $PERF_START_MEMORY" | bc 2>/dev/null || echo "0")

        log "INFO" "⏱️ Performance: $PERF_OPERATION"
        log "INFO" "   Duration: ${duration}s"
        log "INFO" "   Memory delta: ${memory_delta}GB"

        # Log to structured file
        echo "{\"timestamp\":\"$(date -Iseconds)\",\"operation\":\"$PERF_OPERATION\",\"duration\":\"$duration\",\"memory_delta\":\"$memory_delta\"}" >> "$LOG_DIR/performance.json"

        unset PERF_START_TIME PERF_START_MEMORY PERF_OPERATION
    fi
}

# Enhanced error handling with context
handle_error() {
    local line_number="$1"
    local exit_code="${2:-1}"
    local context="${FUNCNAME[1]:-main}"

    log "ERROR" "💥 FATAL ERROR in function '$context' at line $line_number"
    log "ERROR" "Exit code: $exit_code"
    log "ERROR" "Check logs: $LOG_FILE"
    log "ERROR" "Error log: $LOG_DIR/errors.log"

    # Capture final system state
    capture_system_state

    # Display recent error context
    if [ -f "$LOG_DIR/errors.log" ]; then
        echo ""
        echo "Recent errors:"
        tail -5 "$LOG_DIR/errors.log"
    fi

    exit "$exit_code"
}
trap 'handle_error $LINENO' ERR

# Show help
show_help() {
    echo -e "${CYAN}Comprehensive Terminal Tools Installer${NC}"
    echo ""
    echo "This script installs and configures:"
    echo "  • ZSH shell with Oh My ZSH and enhanced plugins"
    echo "  • Ghostty terminal emulator with optimized configuration"
    echo "  • Ptyxis terminal (prefers apt/snap, fallback to flatpak)"
    echo "  • uv Python package manager (latest version)"
    echo "  • Node.js (via NVM) with npm and development tools"
    echo "  • Claude Code CLI (latest version)"
    echo "  • Gemini CLI (latest version)"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --skip-deps    Skip system dependency installation"
    echo "  --skip-node    Skip Node.js/NVM installation"
    echo "  --skip-ai      Skip AI tools (Claude Code, Gemini CLI)"
    echo "  --skip-ptyxis  Skip Ptyxis installation"
    echo "  --verbose      Enable verbose logging"
    echo ""
    echo "Examples:"
    echo "  ./start.sh                    # Full installation"
    echo "  ./start.sh --skip-deps       # Skip system dependencies"
    echo "  ./start.sh --verbose         # Verbose output"
    echo ""
}

# Parse command line arguments
SKIP_DEPS=false
SKIP_NODE=false
SKIP_AI=false
SKIP_PTYXIS=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --skip-node)
            SKIP_NODE=true
            shift
            ;;
        --skip-ai)
            SKIP_AI=true
            shift
            ;;
        --skip-ptyxis)
            SKIP_PTYXIS=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check installation status and versions
check_installation_status() {
    log "STEP" "🔍 Checking current installation status..."

    # Check Ghostty installation
    ghostty_installed=false
    ghostty_version=""
    ghostty_config_valid=false
    
    if command -v ghostty >/dev/null 2>&1; then
        ghostty_installed=true
        ghostty_version=$(ghostty --version 2>/dev/null | head -1 || echo "unknown")
        log "INFO" "✅ Ghostty installed: $ghostty_version"
        
        # Check configuration validity
        if ghostty +show-config >/dev/null 2>&1; then
            ghostty_config_valid=true
            log "INFO" "✅ Ghostty configuration is valid"
        else
            log "WARNING" "⚠️  Ghostty configuration has issues"
        fi
    else
        log "INFO" "❌ Ghostty not installed"
    fi
    
    # Check Ptyxis installation (prefer official: apt, snap, then flatpak)
    ptyxis_installed=false
    ptyxis_version=""
    ptyxis_source=""

    debug "🔍 Starting Ptyxis detection..."

    # Check apt installation first (official)
    debug "🔍 Checking apt installation: dpkg -l | grep ptyxis"
    local apt_check_output=$(dpkg -l 2>/dev/null | grep ptyxis)
    debug "📋 apt check output: '$apt_check_output'"

    if dpkg -l 2>/dev/null | grep -q "^ii.*ptyxis"; then
        debug "✅ APT check matched!"
        ptyxis_installed=true
        ptyxis_version=$(ptyxis --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")
        ptyxis_source="apt"
        debug "📋 Ptyxis version from command: '$ptyxis_version'"
        log "INFO" "✅ Ptyxis installed via apt: $ptyxis_version"
    else
        debug "❌ APT check failed"

        # Check snap installation (official)
        debug "🔍 Checking snap installation: snap list | grep ptyxis"
        local snap_check_output=$(snap list 2>/dev/null | grep ptyxis || echo "no snap output")
        debug "📋 snap check output: '$snap_check_output'"

        if snap list 2>/dev/null | grep -q "ptyxis"; then
            debug "✅ SNAP check matched!"
            ptyxis_installed=true
            ptyxis_version=$(snap list ptyxis 2>/dev/null | tail -n +2 | awk '{print $2}' || echo "unknown")
            ptyxis_source="snap"
            debug "📋 Ptyxis version from snap: '$ptyxis_version'"
            log "INFO" "✅ Ptyxis installed via snap: $ptyxis_version"
        else
            debug "❌ SNAP check failed"

            # Check flatpak installation (fallback)
            debug "🔍 Checking flatpak installation: flatpak list | grep Ptyxis"
            local flatpak_check_output=$(flatpak list 2>/dev/null | grep Ptyxis || echo "no flatpak output")
            debug "📋 flatpak check output: '$flatpak_check_output'"

            if flatpak list 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
                debug "✅ FLATPAK check matched!"
                ptyxis_installed=true
                ptyxis_version=$(flatpak info app.devsuite.Ptyxis 2>/dev/null | grep "Version:" | cut -d: -f2 | xargs || echo "unknown")
                ptyxis_source="flatpak"
                debug "📋 Ptyxis version from flatpak: '$ptyxis_version'"
                log "INFO" "✅ Ptyxis installed via flatpak: $ptyxis_version"
            else
                debug "❌ FLATPAK check failed"
                log "INFO" "❌ Ptyxis not installed"
            fi
        fi
    fi

    debug "📋 Final detection results: installed=$ptyxis_installed, source=$ptyxis_source, version=$ptyxis_version"
    
    # Check for available updates
    check_available_updates "$ghostty_installed" "$ptyxis_installed"
    
    # Determine installation strategy
    determine_install_strategy "$ghostty_installed" "$ghostty_config_valid" "$ptyxis_installed"

    # Check for 2025 optimizations
    check_config_optimizations "$ghostty_installed"
}

# Check if configuration has 2025 optimizations
check_config_optimizations() {
    local ghostty_installed="$1"

    if $ghostty_installed && [ -f "$GHOSTTY_CONFIG_DIR/config" ]; then
        local config_file="$GHOSTTY_CONFIG_DIR/config"
        local has_optimizations=true

        # Check for key 2025 optimizations
        if ! grep -q "linux-cgroup.*single-instance" "$config_file"; then
            has_optimizations=false
            log "INFO" "📋 Missing: linux-cgroup single-instance optimization"
        fi

        if ! grep -q "shell-integration.*detect" "$config_file"; then
            has_optimizations=false
            log "INFO" "📋 Missing: enhanced shell integration"
        fi

        if ! grep -q "clipboard-paste-protection" "$config_file"; then
            has_optimizations=false
            log "INFO" "📋 Missing: clipboard paste protection"
        fi

        if $has_optimizations; then
            log "SUCCESS" "✅ Configuration has 2025 optimizations"
            CONFIG_NEEDS_UPDATE=false
        else
            log "WARNING" "⚠️  Configuration needs 2025 optimizations"
            CONFIG_NEEDS_UPDATE=true
        fi
    else
        CONFIG_NEEDS_UPDATE=true
    fi
}

# Smart configuration update
update_ghostty_config() {
    log "STEP" "🔧 Updating Ghostty configuration with 2025 optimizations..."

    # Always backup existing config
    if [ -f "$GHOSTTY_CONFIG_DIR/config" ]; then
        local backup_file="$GHOSTTY_CONFIG_DIR/config.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$GHOSTTY_CONFIG_DIR/config" "$backup_file"
        log "SUCCESS" "✅ Backed up existing config to: $(basename "$backup_file")"
    fi

    # Create config directory if it doesn't exist
    mkdir -p "$GHOSTTY_CONFIG_DIR"

    # Copy optimized configurations
    if [ -d "$GHOSTTY_CONFIG_SOURCE" ]; then
        cp -r "$GHOSTTY_CONFIG_SOURCE"/* "$GHOSTTY_CONFIG_DIR/"
        log "SUCCESS" "✅ Applied 2025 optimized configuration"

        # Preserve user's custom keybindings if they exist
        if [ -f "$backup_file" ] && grep -q "keybind.*shift+enter" "$backup_file"; then
            if ! grep -q "keybind.*shift+enter" "$GHOSTTY_CONFIG_DIR/config"; then
                echo "" >> "$GHOSTTY_CONFIG_DIR/config"
                echo "# Custom keybindings (preserved from previous config)" >> "$GHOSTTY_CONFIG_DIR/config"
                grep "keybind.*shift+enter" "$backup_file" >> "$GHOSTTY_CONFIG_DIR/config"
                log "SUCCESS" "✅ Preserved custom keybindings"
            fi
        fi

        # Validate new configuration
        if command -v ghostty >/dev/null 2>&1 && ghostty +show-config >/dev/null 2>&1; then
            log "SUCCESS" "✅ Configuration validated successfully"
        else
            log "ERROR" "❌ Configuration validation failed, restoring backup"
            if [ -f "$backup_file" ]; then
                cp "$backup_file" "$GHOSTTY_CONFIG_DIR/config"
            fi
            return 1
        fi
    else
        log "ERROR" "❌ Source configuration directory not found: $GHOSTTY_CONFIG_SOURCE"
        return 1
    fi
}

# Check for available updates online
check_available_updates() {
    local ghostty_installed="$1"
    local ptyxis_installed="$2"
    
    log "INFO" "🌐 Checking for available updates..."
    
    # Check Ghostty updates (from Git repository)
    if $ghostty_installed && [ -d "$GHOSTTY_APP_DIR" ]; then
        cd "$GHOSTTY_APP_DIR"
        local current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
        git fetch origin main >/dev/null 2>&1 || true
        local latest_commit=$(git rev-parse origin/main 2>/dev/null || echo "unknown")
        
        if [ "$current_commit" != "$latest_commit" ] && [ "$latest_commit" != "unknown" ]; then
            log "INFO" "🆕 Ghostty update available (new commits)"
        else
            log "INFO" "✅ Ghostty is up to date"
        fi
    fi
    
    # Check Ptyxis updates based on installation method
    if $ptyxis_installed; then
        if [ "$ptyxis_source" = "apt" ]; then
            # Check apt updates
            if apt list --upgradable 2>/dev/null | grep -q "ptyxis"; then
                log "INFO" "🆕 Ptyxis update available via apt"
            else
                log "INFO" "✅ Ptyxis is up to date (apt)"
            fi
        elif [ "$ptyxis_source" = "snap" ]; then
            # Check snap updates
            if snap refresh --list 2>/dev/null | grep -q "ptyxis"; then
                log "INFO" "🆕 Ptyxis update available via snap"
            else
                log "INFO" "✅ Ptyxis is up to date (snap)"
            fi
        elif [ "$ptyxis_source" = "flatpak" ]; then
            # Check flatpak updates
            if flatpak remote-ls --updates 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
                log "INFO" "🆕 Ptyxis update available via flatpak"
            else
                log "INFO" "✅ Ptyxis is up to date (flatpak)"
            fi
        fi
    fi
}

# Determine the best installation strategy
determine_install_strategy() {
    local ghostty_installed="$1"
    local ghostty_config_valid="$2"  
    local ptyxis_installed="$3"
    
    log "INFO" "🤔 Determining installation strategy..."
    
    # Ghostty strategy
    if $ghostty_installed; then
        if $ghostty_config_valid; then
            log "INFO" "📋 Ghostty: Will update existing installation"
            GHOSTTY_STRATEGY="update"
        else
            log "WARNING" "📋 Ghostty: Configuration invalid, will reinstall configuration"
            GHOSTTY_STRATEGY="reconfig"
        fi
    else
        log "INFO" "📋 Ghostty: Will perform fresh installation"
        GHOSTTY_STRATEGY="fresh"
    fi
    
    # Ptyxis strategy  
    if $ptyxis_installed; then
        log "INFO" "📋 Ptyxis: Will update existing installation"
        PTYXIS_STRATEGY="update"
    else
        log "INFO" "📋 Ptyxis: Will perform fresh installation"  
        PTYXIS_STRATEGY="fresh"
    fi
}

# Pre-authentication for sudo
pre_auth_sudo() {
    log "INFO" "🔑 Pre-authenticating sudo access..."
    if sudo -n true 2>/dev/null; then
        log "SUCCESS" "✅ Sudo already authenticated"
    else
        log "INFO" "🔐 Please enter your sudo password:"
        sudo echo "Sudo authenticated successfully" || {
            log "ERROR" "❌ Sudo authentication failed"
            exit 1
        }
        log "SUCCESS" "✅ Sudo authenticated"
    fi
}

# Install ZSH and Oh My ZSH
install_zsh() {
    log "STEP" "🐚 Setting up ZSH and Oh My ZSH..."

    # Check if ZSH is installed and update if needed
    if ! command -v zsh >/dev/null 2>&1; then
        log "INFO" "📥 Installing latest ZSH..."
        if sudo apt update && sudo apt install -y zsh >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ ZSH installed"
        else
            log "ERROR" "❌ Failed to install ZSH"
            return 1
        fi
    else
        local current_version=$(zsh --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log "INFO" "✅ ZSH already installed: $current_version"

        # Check for ZSH updates
        log "INFO" "🔄 Checking for ZSH updates..."
        if apt list --upgradable 2>/dev/null | grep -q "^zsh/"; then
            log "INFO" "🆕 ZSH update available, updating..."
            if sudo apt update && sudo apt upgrade -y zsh >> "$LOG_FILE" 2>&1; then
                log "SUCCESS" "✅ ZSH updated to latest version"
            else
                log "WARNING" "⚠️  ZSH update may have failed"
            fi
        else
            log "SUCCESS" "✅ ZSH is up to date"
        fi
    fi

    # Check if Oh My ZSH is installed and update if needed
    if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
        log "INFO" "📥 Installing latest Oh My ZSH..."
        # Download and install Oh My ZSH non-interactively
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Oh My ZSH installed"
        else
            log "ERROR" "❌ Failed to install Oh My ZSH"
            return 1
        fi
    else
        log "INFO" "✅ Oh My ZSH already installed"

        # Update Oh My ZSH to latest version
        log "INFO" "🔄 Updating Oh My ZSH to latest version..."
        if [ -f "$REAL_HOME/.oh-my-zsh/tools/upgrade.sh" ]; then
            # Run the upgrade script non-interactively
            if ZSH="$REAL_HOME/.oh-my-zsh" sh "$REAL_HOME/.oh-my-zsh/tools/upgrade.sh" --unattended >> "$LOG_FILE" 2>&1; then
                log "SUCCESS" "✅ Oh My ZSH updated to latest version"
            else
                log "WARNING" "⚠️  Oh My ZSH update may have failed, trying git pull..."
                # Fallback: manual git pull with progressive disclosure
                if run_task_command "Updating Oh My ZSH" "cd '$REAL_HOME/.oh-my-zsh' && git pull origin master && cd - >/dev/null" "Pulling latest Oh My ZSH updates" "30s"; then
                    log "SUCCESS" "✅ Oh My ZSH updated via git pull"
                else
                    log "WARNING" "⚠️  Oh My ZSH git pull failed"
                fi
            fi
        else
            # Fallback: manual git pull if upgrade script doesn't exist
            log "INFO" "🔄 Updating Oh My ZSH via git pull..."
            if run_task_command "Updating Oh My ZSH" "cd '$REAL_HOME/.oh-my-zsh' && git pull origin master && cd - >/dev/null" "Pulling latest Oh My ZSH updates" "30s"; then
                log "SUCCESS" "✅ Oh My ZSH updated via git pull"
            else
                log "WARNING" "⚠️  Oh My ZSH update may have failed"
            fi
        fi
    fi
    
    # Check current default shell
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local zsh_path=$(which zsh)
    
    if [ "$current_shell" != "$zsh_path" ]; then
        log "INFO" "🔄 Setting ZSH as default shell..."

        # Use progressive disclosure for the chsh command
        if run_task_command "Setting ZSH as default shell" "chsh -s '$zsh_path'" "Changing default shell to ZSH" "5s"; then
            log "SUCCESS" "✅ ZSH set as default shell (restart terminal to take effect)"
        else
            log "WARNING" "⚠️  Failed to set ZSH as default shell automatically"
            log "INFO" "💡 You can manually set it with: chsh -s $zsh_path"
        fi
    else
        log "SUCCESS" "✅ ZSH is already the default shell"
    fi
    
    # Update Ghostty config to use ZSH
    local ghostty_config="$GHOSTTY_CONFIG_DIR/config"
    if [ -f "$ghostty_config" ]; then
        if ! grep -q "shell-integration = zsh" "$ghostty_config"; then
            if grep -q "shell-integration" "$ghostty_config"; then
                sed -i 's/shell-integration = .*/shell-integration = zsh/' "$ghostty_config"
                log "SUCCESS" "✅ Updated Ghostty shell integration to ZSH"
            fi
        else
            log "SUCCESS" "✅ Ghostty already configured for ZSH"
        fi
    fi
    
    # Add useful ZSH plugins
    local zshrc="$REAL_HOME/.zshrc"
    if [ -f "$zshrc" ]; then
        # Update plugins in .zshrc if Oh My ZSH config exists
        if grep -q "plugins=(git)" "$zshrc"; then
            sed -i 's/plugins=(git)/plugins=(git npm node nvm docker docker-compose sudo history)/' "$zshrc"
            log "SUCCESS" "✅ Enhanced ZSH plugins configuration"
        fi
        
        # Add NVM configuration to .zshrc if not present
        if ! grep -q "export NVM_DIR" "$zshrc"; then
            cat >> "$zshrc" << 'EOF'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

EOF
            log "SUCCESS" "✅ Added NVM configuration to .zshrc"
        fi
        
        # Add Gemini alias to .zshrc (handle conflicts)
        if grep -q "flatpak run app.devsuite.Ptyxis.*gemini" "$zshrc"; then
            log "SUCCESS" "✅ Ptyxis gemini integration already configured in .zshrc"
        else
            if grep -q "alias gemini=" "$zshrc"; then
                log "INFO" "🔄 Updating existing gemini alias in .zshrc"
                sed -i '/alias gemini=/s/^/# (replaced by Ptyxis integration) /' "$zshrc"
            fi
            
            cat >> "$zshrc" << 'EOF'

# Gemini CLI integration with Ptyxis
alias gemini='flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- ~/.nvm/versions/node/v24.6.0/bin/gemini'

EOF
            log "SUCCESS" "✅ Added Ptyxis gemini integration to .zshrc"
        fi
    fi
}

# Install system dependencies
install_system_deps() {
    if $SKIP_DEPS; then
        log "INFO" "⏭️  Skipping system dependencies installation"
        return 0
    fi
    
    log "STEP" "🔧 Installing system dependencies..."
    
    # Update package list
    sudo apt update || {
        log "ERROR" "Failed to update package list"
        return 1
    }
    
    # Install essential dependencies (including ZSH)
    local deps=(
        "build-essential" "pkg-config" "gettext" "libxml2-utils" "pandoc"
        "git" "curl" "wget" "unzip" "software-properties-common" "zsh"
        "libgtk-4-dev" "libadwaita-1-dev" "blueprint-compiler" 
        "libgtk4-layer-shell-dev" "libfreetype-dev" "libharfbuzz-dev"
        "libfontconfig-dev" "libpng-dev" "libbz2-dev" "zlib1g-dev"
        "libglib2.0-dev" "libgio-2.0-dev" "libpango1.0-dev"
        "libgdk-pixbuf-2.0-dev" "libcairo2-dev" "libvulkan-dev"
        "libgraphene-1.0-dev" "libx11-dev" "libwayland-dev"
        "libonig-dev" "libxml2-dev" "flatpak"
    )
    
    log "INFO" "📦 Installing ${#deps[@]} essential packages..."
    if run_task_command "Installing system dependencies" "sudo apt install -y $(echo ${deps[@]})" "Installing development tools and dependencies" "1-2 minutes"; then
        log "SUCCESS" "✅ System dependencies installed"
    else
        log "ERROR" "❌ Failed to install system dependencies"
        return 1
    fi
    
    # Add Flathub repository if not already added
    if ! flatpak remotes | grep -q flathub; then
        log "INFO" "🔗 Adding Flathub repository..."
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        log "SUCCESS" "✅ Flathub repository added"
    fi
}

# Install Zig
install_zig() {
    log "STEP" "⚡ Installing Zig 0.14.0..."
    
    if command -v zig >/dev/null 2>&1; then
        local current_version=$(zig version)
        if [[ "$current_version" == "0.14.0" ]]; then
            log "SUCCESS" "✅ Zig 0.14.0 already installed"
            return 0
        fi
    fi
    
    # Download and install Zig
    local zig_url="https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz"
    local zig_archive="/tmp/zig-linux-x86_64-0.14.0.tar.xz"
    local zig_dir="$APPS_DIR/zig"
    
    mkdir -p "$APPS_DIR"
    
    log "INFO" "📥 Downloading Zig 0.14.0..."
    if wget -O "$zig_archive" "$zig_url" >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ Zig downloaded"
    else
        log "ERROR" "❌ Failed to download Zig"
        return 1
    fi
    
    log "INFO" "📂 Extracting Zig..."
    rm -rf "$zig_dir"
    mkdir -p "$zig_dir"
    tar -xf "$zig_archive" -C "$zig_dir" --strip-components=1
    rm "$zig_archive"
    
    # Create system-wide symlink
    sudo ln -sf "$zig_dir/zig" /usr/local/bin/zig
    
    # Verify installation
    if zig version | grep -q "0.14.0"; then
        log "SUCCESS" "✅ Zig 0.14.0 installed successfully"
    else
        log "ERROR" "❌ Zig installation verification failed"
        return 1
    fi
}

# Install or update Ghostty based on strategy
install_ghostty() {
    case "${GHOSTTY_STRATEGY:-fresh}" in
        "update")
            update_ghostty
            ;;
        "reconfig") 
            reconfigure_ghostty
            ;;
        "fresh"|*)
            fresh_install_ghostty
            ;;
    esac
}

# Fresh Ghostty installation
fresh_install_ghostty() {
    log "STEP" "👻 Fresh installation of Ghostty terminal emulator..."
    
    # Clone Ghostty repository
    if [ ! -d "$GHOSTTY_APP_DIR" ]; then
        log "INFO" "📥 Cloning Ghostty repository..."
        git clone https://github.com/ghostty-org/ghostty.git "$GHOSTTY_APP_DIR" >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ Ghostty repository cloned"
    fi
    
    build_and_install_ghostty
    install_ghostty_configuration
}

# Update existing Ghostty installation
update_ghostty() {
    log "STEP" "🔄 Updating existing Ghostty installation..."
    
    # Update repository
    if [ -d "$GHOSTTY_APP_DIR" ]; then
        cd "$GHOSTTY_APP_DIR"
        log "INFO" "📥 Pulling latest changes..."
        git pull origin main >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ Repository updated"
    else
        log "WARNING" "⚠️  Repository not found, performing fresh install"
        fresh_install_ghostty
        return
    fi
    
    # Check if rebuild is needed
    local needs_rebuild=false
    if [ ! -f "zig-out/bin/ghostty" ]; then
        needs_rebuild=true
        log "INFO" "🔨 Binary not found, rebuild required"
    else
        # Check if source is newer than binary
        if find . -name "*.zig" -newer "zig-out/bin/ghostty" | head -1 | grep -q .; then
            needs_rebuild=true
            log "INFO" "🔨 Source files updated, rebuild required"
        fi
    fi
    
    if $needs_rebuild; then
        build_and_install_ghostty
    else
        log "INFO" "✅ Ghostty binary is up to date"
    fi
    
    # Always update configuration to latest
    install_ghostty_configuration
}

# Reconfigure Ghostty (fix config issues)
reconfigure_ghostty() {
    log "STEP" "⚙️  Reconfiguring Ghostty (fixing configuration issues)..."
    
    # Backup existing config if it exists
    if [ -d "$GHOSTTY_CONFIG_DIR" ]; then
        local backup_dir="/tmp/ghostty-config-backup-$(date +%s)"
        cp -r "$GHOSTTY_CONFIG_DIR" "$backup_dir"
        log "INFO" "💾 Backed up existing config to $backup_dir"
    fi
    
    # Install fresh configuration
    install_ghostty_configuration
    
    # Verify the fix worked
    if ghostty +show-config >/dev/null 2>&1; then
        log "SUCCESS" "✅ Configuration issues resolved"
    else
        log "ERROR" "❌ Configuration issues persist"
        return 1
    fi
}

# Build and install Ghostty binary
build_and_install_ghostty() {
    cd "$GHOSTTY_APP_DIR"
    log "INFO" "🔨 Building Ghostty (this may take a while)..."
    
    # Clean previous build if it exists
    if [ -d "zig-out" ]; then
        rm -rf zig-out
    fi
    
    # Build Ghostty with progressive disclosure
    if run_task_command "Building Ghostty" "zig build -Doptimize=ReleaseFast" "Compiling Ghostty with optimizations" "2-3 minutes"; then
        log "SUCCESS" "✅ Ghostty built successfully"
    else
        log "ERROR" "❌ Ghostty build failed"
        return 1
    fi

    # Install Ghostty with progressive disclosure
    if run_task_command "Installing Ghostty" "sudo zig build install --prefix /usr/local" "Installing Ghostty to system" "30s"; then
        log "SUCCESS" "✅ Ghostty installed to /usr/local"
    else
        log "ERROR" "❌ Ghostty installation failed"
        return 1
    fi
}

# Install Ghostty configuration files
install_ghostty_configuration() {
    log "INFO" "⚙️  Installing Ghostty configuration..."
    mkdir -p "$GHOSTTY_CONFIG_DIR"
    
    # Copy configuration files from configs directory
    for config_file in config theme.conf scroll.conf layout.conf keybindings.conf; do
        if [ -f "$GHOSTTY_CONFIG_SOURCE/$config_file" ]; then
            cp "$GHOSTTY_CONFIG_SOURCE/$config_file" "$GHOSTTY_CONFIG_DIR/"
            log "SUCCESS" "✅ Copied $config_file"
        else
            log "WARNING" "⚠️  $config_file not found in $GHOSTTY_CONFIG_SOURCE"
        fi
    done
    
    # Validate configuration
    if ghostty +show-config >/dev/null 2>&1; then
        log "SUCCESS" "✅ Ghostty configuration is valid"
    else
        log "WARNING" "⚠️  Ghostty configuration validation failed"
        return 1
    fi
}

# Install or update Ptyxis based on strategy
install_ptyxis() {
    if $SKIP_PTYXIS; then
        log "INFO" "⏭️  Skipping Ptyxis installation"
        return 0
    fi
    
    case "${PTYXIS_STRATEGY:-fresh}" in
        "update")
            update_ptyxis
            ;;
        "fresh"|*)
            fresh_install_ptyxis
            ;;
    esac
}

# Fresh Ptyxis installation (prefer official: apt, snap, then flatpak)
fresh_install_ptyxis() {
    log "STEP" "🐚 Fresh installation of Ptyxis terminal..."

    # Try apt first (official Ubuntu packages)
    log "INFO" "📥 Attempting Ptyxis installation via apt..."
    if apt-cache show ptyxis >/dev/null 2>&1; then
        if sudo apt update && sudo apt install -y ptyxis >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ptyxis installed via apt"
            configure_ptyxis_system
            return 0
        else
            log "WARNING" "⚠️  Ptyxis installation via apt failed, trying snap..."
        fi
    else
        log "INFO" "ℹ️ Ptyxis not available via apt, trying snap..."
    fi

    # Try snap second (official snap packages)
    log "INFO" "📥 Attempting Ptyxis installation via snap..."
    if snap find ptyxis 2>/dev/null | grep -q "ptyxis"; then
        if sudo snap install ptyxis >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ptyxis installed via snap"
            configure_ptyxis_system
            return 0
        else
            log "WARNING" "⚠️  Ptyxis installation via snap failed, falling back to flatpak..."
        fi
    else
        log "INFO" "ℹ️ Ptyxis not available via snap, falling back to flatpak..."
    fi

    # Fallback to flatpak
    log "INFO" "📥 Installing Ptyxis via flatpak (fallback)..."
    if flatpak install -y flathub app.devsuite.Ptyxis >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "✅ Ptyxis installed via flatpak"
        configure_ptyxis_flatpak
    else
        log "ERROR" "❌ Ptyxis installation failed via all methods"
        return 1
    fi
}

# Update existing Ptyxis installation based on installation method
update_ptyxis() {
    log "STEP" "🔄 Updating existing Ptyxis installation..."

    # Determine current installation method and update accordingly
    if dpkg -l 2>/dev/null | grep -q "^ii.*ptyxis"; then
        log "INFO" "🔄 Updating Ptyxis via apt..."
        if sudo apt update && sudo apt upgrade -y ptyxis >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ptyxis updated via apt"
        else
            log "WARNING" "⚠️  Ptyxis apt update may have failed"
        fi
        configure_ptyxis_system
    elif snap list 2>/dev/null | grep -q "ptyxis"; then
        log "INFO" "🔄 Updating Ptyxis via snap..."
        if sudo snap refresh ptyxis >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ptyxis updated via snap"
        else
            log "WARNING" "⚠️  Ptyxis snap update may have failed"
        fi
        configure_ptyxis_system
    elif flatpak list 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
        log "INFO" "🔄 Updating Ptyxis via flatpak..."
        if flatpak update -y app.devsuite.Ptyxis >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Ptyxis updated via flatpak"
        else
            log "WARNING" "⚠️  Ptyxis flatpak update may have failed"
        fi
        configure_ptyxis_flatpak
    else
        log "WARNING" "⚠️  Could not determine Ptyxis installation method for update"
    fi
}

# Configure Ptyxis for system installations (apt/snap)
configure_ptyxis_system() {
    log "INFO" "🔧 Configuring Ptyxis (system installation)..."

    # Create gemini alias in both bashrc and zshrc for system installation
    for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$shell_config" ]; then
            # Check if Ptyxis system integration already exists
            if grep -q "ptyxis.*-d.*gemini" "$shell_config" && ! grep -q "flatpak" "$shell_config"; then
                log "SUCCESS" "✅ Ptyxis gemini integration already configured in $(basename "$shell_config")"
            else
                # Remove any existing gemini aliases
                if grep -q "alias gemini=" "$shell_config"; then
                    log "INFO" "🔄 Updating existing gemini alias in $(basename "$shell_config")"
                    sed -i '/alias gemini=/d' "$shell_config"
                fi

                # Add the system Ptyxis integration alias
                echo "" >> "$shell_config"
                echo "# Gemini CLI integration with Ptyxis (system)" >> "$shell_config"
                echo 'alias gemini='"'"'ptyxis -d "$(pwd)" -- ~/.nvm/versions/node/v24.6.0/bin/gemini'"'" >> "$shell_config"
                log "SUCCESS" "✅ Added Ptyxis system gemini integration to $(basename "$shell_config")"
            fi
        fi
    done
}

# Configure Ptyxis for flatpak installation
configure_ptyxis_flatpak() {
    log "INFO" "🔧 Configuring Ptyxis (flatpak installation)..."

    # Grant necessary permissions for file access
    flatpak override app.devsuite.Ptyxis --filesystem=home >> "$LOG_FILE" 2>&1

    # Create gemini alias in both bashrc and zshrc for flatpak
    for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$shell_config" ]; then
            # Check if Ptyxis flatpak integration already exists
            if grep -q "flatpak run app.devsuite.Ptyxis.*gemini" "$shell_config"; then
                log "SUCCESS" "✅ Ptyxis flatpak gemini integration already configured in $(basename "$shell_config")"
            else
                # Remove any existing gemini aliases
                if grep -q "alias gemini=" "$shell_config"; then
                    log "INFO" "🔄 Updating existing gemini alias in $(basename "$shell_config")"
                    sed -i '/alias gemini=/d' "$shell_config"
                fi

                # Add the flatpak Ptyxis integration alias
                echo "" >> "$shell_config"
                echo "# Gemini CLI integration with Ptyxis (flatpak)" >> "$shell_config"
                echo 'alias gemini='"'"'flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- ~/.nvm/versions/node/v24.6.0/bin/gemini'"'" >> "$shell_config"
                log "SUCCESS" "✅ Added Ptyxis flatpak gemini integration to $(basename "$shell_config")"
            fi
        fi
    done
}

# Install uv Python package manager
install_uv() {
    log "STEP" "🐍 Installing uv Python package manager..."

    # Check if uv is already installed
    if command -v uv >/dev/null 2>&1; then
        local current_version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log "INFO" "✅ uv already installed: $current_version"

        # Update uv to latest version
        log "INFO" "🔄 Updating uv to latest version..."
        if curl -LsSf https://astral.sh/uv/install.sh | sh >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ uv updated successfully"
        else
            log "WARNING" "⚠️  uv update may have failed"
        fi
    else
        # Install uv
        log "INFO" "📥 Installing uv..."
        if curl -LsSf https://astral.sh/uv/install.sh | sh >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ uv installed successfully"
        else
            log "ERROR" "❌ uv installation failed"
            return 1
        fi
    fi

    # Add uv to PATH for current session
    export PATH="$HOME/.cargo/bin:$PATH"

    # Add uv to shell configurations
    for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$shell_config" ]; then
            if ! grep -q 'export PATH="$HOME/.cargo/bin:$PATH"' "$shell_config"; then
                echo "" >> "$shell_config"
                echo "# uv Python package manager" >> "$shell_config"
                echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$shell_config"
                log "SUCCESS" "✅ Added uv to PATH in $(basename "$shell_config")"
            fi
        fi
    done

    # Verify installation
    if command -v uv >/dev/null 2>&1; then
        local version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log "SUCCESS" "✅ uv Python package manager ready: $version"
    else
        log "WARNING" "⚠️  uv may not be immediately available (restart shell)"
    fi
}

# Install Node.js via NVM
install_nodejs() {
    if $SKIP_NODE; then
        log "INFO" "⏭️  Skipping Node.js installation"
        return 0
    fi
    
    log "STEP" "📦 Installing Node.js via NVM..."
    
    # Install or update NVM
    if [ ! -d "$NVM_DIR" ]; then
        log "INFO" "📥 Installing NVM $NVM_VERSION..."
        curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ NVM installed"
    else
        log "INFO" "✅ NVM already present"

        # Check if NVM update is available
        log "INFO" "🔄 Checking for NVM updates..."
        export NVM_DIR="$NVM_DIR"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        local current_nvm_version=$(nvm --version 2>/dev/null || echo "unknown")
        local target_version=$(echo "$NVM_VERSION" | sed 's/v//')

        if [ "$current_nvm_version" != "$target_version" ]; then
            log "INFO" "🆕 NVM update available ($current_nvm_version → $target_version), updating..."
            curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash >> "$LOG_FILE" 2>&1
            log "SUCCESS" "✅ NVM updated to $NVM_VERSION"
        else
            log "SUCCESS" "✅ NVM is up to date ($current_nvm_version)"
        fi
    fi
    
    # Source NVM
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Install Node.js
    if ! command -v node >/dev/null 2>&1 || ! node --version | grep -q "v$NODE_VERSION"; then
        log "INFO" "📥 Installing Node.js $NODE_VERSION..."
        nvm install "$NODE_VERSION" >> "$LOG_FILE" 2>&1
        nvm use "$NODE_VERSION" >> "$LOG_FILE" 2>&1
        nvm alias default "$NODE_VERSION" >> "$LOG_FILE" 2>&1
        log "SUCCESS" "✅ Node.js $NODE_VERSION installed"
    else
        log "SUCCESS" "✅ Node.js $NODE_VERSION already installed"
    fi
    
    # Update npm to latest
    log "INFO" "🔄 Updating npm to latest version..."
    npm install -g npm@latest >> "$LOG_FILE" 2>&1
    log "SUCCESS" "✅ npm updated to $(npm --version)"
}

# Install Claude Code CLI
install_claude_code() {
    if $SKIP_AI; then
        log "INFO" "⏭️  Skipping Claude Code installation"
        return 0
    fi
    
    log "STEP" "🤖 Installing Claude Code CLI..."
    
    # Source NVM for npm access
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Claude Code globally
    if npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
        log "INFO" "🔄 Updating Claude Code..."
        npm update -g @anthropic-ai/claude-code >> "$LOG_FILE" 2>&1
    else
        log "INFO" "📥 Installing Claude Code..."
        npm install -g @anthropic-ai/claude-code >> "$LOG_FILE" 2>&1
    fi
    
    # Verify installation
    if command -v claude-code >/dev/null 2>&1; then
        local version=$(claude-code --version 2>/dev/null || echo "unknown")
        log "SUCCESS" "✅ Claude Code installed (version: $version)"
    else
        log "WARNING" "⚠️  Claude Code installed but not in PATH"
    fi
}

# Install Gemini CLI
install_gemini_cli() {
    if $SKIP_AI; then
        log "INFO" "⏭️  Skipping Gemini CLI installation"
        return 0
    fi
    
    log "STEP" "💎 Installing Gemini CLI..."
    
    # Source NVM for npm access
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Install Gemini CLI globally
    if npm list -g @google/generative-ai-cli >/dev/null 2>&1; then
        log "INFO" "🔄 Updating Gemini CLI..."
        npm update -g @google/generative-ai-cli >> "$LOG_FILE" 2>&1
    else
        log "INFO" "📥 Installing Gemini CLI..."
        npm install -g @google/generative-ai-cli >> "$LOG_FILE" 2>&1
    fi
    
    # Create symlink for easier access
    local gemini_path="$NVM_DIR/versions/node/v$NODE_VERSION/bin/gemini"
    if [ -f "$gemini_path" ]; then
        sudo ln -sf "$gemini_path" /usr/local/bin/gemini 2>/dev/null || true
        log "SUCCESS" "✅ Gemini CLI installed and linked"
    else
        log "WARNING" "⚠️  Gemini CLI installation may have issues"
    fi
}

# Final verification
verify_installation() {
    log "STEP" "🔍 Verifying installations..."
    
    local status=0
    
    # Check Ghostty
    if command -v ghostty >/dev/null 2>&1; then
        local version=$(ghostty --version 2>/dev/null | head -1)
        log "SUCCESS" "✅ Ghostty: $version"
    else
        log "ERROR" "❌ Ghostty not found"
        status=1
    fi
    
    # Check Ptyxis (prefer official: apt, snap, then flatpak)
    if ! $SKIP_PTYXIS; then
        if dpkg -l 2>/dev/null | grep -q "^ii.*ptyxis"; then
            log "SUCCESS" "✅ Ptyxis: Available via apt"
        elif snap list 2>/dev/null | grep -q "ptyxis"; then
            log "SUCCESS" "✅ Ptyxis: Available via snap"
        elif flatpak list 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
            log "SUCCESS" "✅ Ptyxis: Available via flatpak"
        else
            log "ERROR" "❌ Ptyxis not found"
            status=1
        fi
    fi
    
    # Check ZSH
    if command -v zsh >/dev/null 2>&1; then
        local current_shell=$(getent passwd "$USER" | cut -d: -f7)
        local zsh_path=$(which zsh)
        if [ "$current_shell" = "$zsh_path" ]; then
            log "SUCCESS" "✅ ZSH: Default shell with Oh My ZSH"
        else
            log "WARNING" "⚠️  ZSH: Installed but not default shell"
        fi
    else
        log "ERROR" "❌ ZSH not found"
        status=1
    fi

    # Check uv
    if command -v uv >/dev/null 2>&1; then
        local version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")
        log "SUCCESS" "✅ uv Python package manager: $version"
    else
        log "WARNING" "⚠️  uv not found (may need shell restart)"
    fi

    # Check Node.js
    if ! $SKIP_NODE; then
        if command -v node >/dev/null 2>&1; then
            local version=$(node --version)
            log "SUCCESS" "✅ Node.js: $version"
        else
            log "ERROR" "❌ Node.js not found"
            status=1
        fi
    fi
    
    # Check AI tools
    if ! $SKIP_AI; then
        # Check Claude Code
        if command -v claude-code >/dev/null 2>&1; then
            log "SUCCESS" "✅ Claude Code: Available"
        else
            log "WARNING" "⚠️  Claude Code not in PATH (may need shell restart)"
        fi
        
        # Check Gemini CLI
        if command -v gemini >/dev/null 2>&1; then
            log "SUCCESS" "✅ Gemini CLI: Available"
        else
            log "WARNING" "⚠️  Gemini CLI not in PATH (may need shell restart)"
        fi
    fi
    
    return $status
}

# Show final instructions
show_final_instructions() {
    echo ""
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. Restart your terminal to activate ZSH and new environment"
    echo "2. Test Ghostty: ghostty"
    if ! $SKIP_PTYXIS; then
        echo "3. Test Ptyxis: flatpak run app.devsuite.Ptyxis"
        echo "4. Use Gemini in Ptyxis: gemini (after restart)"
    fi
    if ! $SKIP_AI; then
        echo "5. Set up Claude Code: claude-code auth login"
        echo "6. Set up Gemini CLI with your API key"
    fi
    echo ""
    echo -e "${YELLOW}Configuration files:${NC}"
    echo "• Ghostty config: $GHOSTTY_CONFIG_DIR/"
    echo "• Logs: $LOG_FILE"
    echo ""
    if ! $SKIP_AI; then
        echo -e "${YELLOW}API Setup Required:${NC}"
        echo "• Claude Code: Get API key from https://console.anthropic.com"
        echo "• Gemini CLI: Get API key from https://makersuite.google.com/app/apikey"
        echo ""
    fi
}

# Install Ghostty context menu integration
install_context_menu() {
    log "STEP" "🖱️  Installing Ghostty context menu integration..."

    # Check if running on a desktop environment with Nautilus
    if ! command -v nautilus >/dev/null 2>&1; then
        log "INFO" "⏭️  Nautilus not found, skipping context menu integration"
        return 0
    fi

    # Create Nautilus scripts directory
    local scripts_dir="$REAL_HOME/.local/share/nautilus/scripts"
    mkdir -p "$scripts_dir"

    # Create the Nautilus script
    cat > "$scripts_dir/Open in Ghostty" << 'EOF'
#!/bin/bash

# Nautilus script to open selected folder in Ghostty terminal
# This script will appear in the right-click context menu

# Get the selected directory path
if [ -n "$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS" ]; then
    # Use the selected folder/file path
    TARGET_PATH="$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"

    # If it's a file, get its directory
    if [ -f "$TARGET_PATH" ]; then
        TARGET_PATH="$(dirname "$TARGET_PATH")"
    fi
else
    # If no selection, use current directory
    TARGET_PATH="$NAUTILUS_SCRIPT_CURRENT_URI"
    # Convert file:// URI to local path
    TARGET_PATH=$(echo "$TARGET_PATH" | sed 's|^file://||' | python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read().strip()))")
fi

# Launch Ghostty with the target directory as working directory
if command -v ghostty >/dev/null 2>&1; then
    cd "$TARGET_PATH" && ghostty &
else
    # Fallback notification if Ghostty is not found
    notify-send "Ghostty not found" "Please ensure Ghostty is installed and in your PATH"
fi
EOF

    # Make the script executable
    chmod +x "$scripts_dir/Open in Ghostty"

    # Create desktop file for better integration
    local apps_dir="$REAL_HOME/.local/share/applications"
    mkdir -p "$apps_dir"
    cat > "$apps_dir/ghostty-here.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Open Ghostty Here
Comment=Open Ghostty terminal in selected folder
Exec=ghostty --working-directory=%f
Icon=utilities-terminal
StartupNotify=true
NoDisplay=true
MimeType=inode/directory;
EOF

    # Update desktop database
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$apps_dir" 2>/dev/null || true
    fi

    # Restart Nautilus to apply changes (only if running)
    if pgrep nautilus >/dev/null 2>&1; then
        nautilus -q 2>/dev/null || true
        log "INFO" "🔄 Restarted Nautilus to apply context menu changes"
    fi

    log "SUCCESS" "✅ Ghostty context menu integration installed"
    log "INFO" "💡 Right-click any folder and select 'Scripts' > 'Open in Ghostty'"
}

# Main execution
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Comprehensive Terminal Tools Installer${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # Start performance monitoring for entire operation
    monitor_performance "Complete Installation"

    log "INFO" "🚀 Starting comprehensive installation..."
    log "INFO" "📋 Log files:"
    log "INFO" "   Main: $LOG_FILE"
    log "INFO" "   JSON: $LOG_FILE.json"
    log "INFO" "   Errors: $LOG_DIR/errors.log"
    log "INFO" "   Performance: $LOG_DIR/performance.json"

    # Capture initial system state
    capture_system_state
    
    # Create necessary directories
    mkdir -p "$APPS_DIR"
    
    # Pre-authenticate sudo if needed
    if ! $SKIP_DEPS || ! $SKIP_PTYXIS; then
        pre_auth_sudo
    fi
    
    # Check current installation status and determine strategies
    check_installation_status
    
    # Execute installation steps
    install_system_deps
    install_zsh
    install_zig
    install_ghostty

    # Smart configuration update (always run to ensure latest optimizations)
    if $CONFIG_NEEDS_UPDATE || [ "$GHOSTTY_STRATEGY" = "fresh" ] || [ "$GHOSTTY_STRATEGY" = "reconfig" ]; then
        update_ghostty_config
    fi

    install_context_menu
    install_ptyxis
    install_uv
    install_nodejs
    install_claude_code
    install_gemini_cli
    
    # Verify everything
    start_timer
    if verify_installation; then
        end_timer "Installation verification"
        log "SUCCESS" "🎉 All installations completed successfully!"
        show_final_instructions
    else
        log "WARNING" "⚠️  Some installations may need attention. Check the log for details."
        echo "Log files:"
        echo "  Main: $LOG_FILE"
        echo "  Errors: $LOG_DIR/errors.log"
        echo "  Performance: $LOG_DIR/performance.json"
    fi

    # End performance monitoring for entire operation
    end_performance_monitoring

    # Final system state capture
    capture_system_state

    log "INFO" "📊 Installation completed. Check $LOG_DIR for detailed logs."
}

# Run main function
main "$@"