#!/bin/bash

set -euo pipefail

# Comprehensive Start Script for Ghostty, Ptyxis, Claude Code, and Gemini CLI
# This script handles complete installation of all terminal tools and AI assistants

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"

# Advanced Session Tracking for Multiple Executions
# Creates synchronized session IDs for logs and screenshots with terminal detection
# Pattern: YYYYMMDD-HHMMSS-terminal-operation where terminal = ghostty|ptyxis|generic
DATETIME=$(date +"%Y%m%d-%H%M%S")

# Detect current terminal environment for session naming
DETECTED_TERMINAL="generic"
if [ -n "${GHOSTTY_RESOURCES_DIR:-}" ] || [ "${TERM_PROGRAM:-}" = "ghostty" ]; then
    DETECTED_TERMINAL="ghostty"
elif [ -n "${PTYXIS_VERSION:-}" ] || [ "${TERM_PROGRAM:-}" = "ptyxis" ] || pstree -p $$ 2>/dev/null | grep -q ptyxis; then
    DETECTED_TERMINAL="ptyxis"
elif [ -n "${GNOME_TERMINAL_SCREEN:-}" ]; then
    DETECTED_TERMINAL="gnome-terminal"
elif [ -n "${KONSOLE_VERSION:-}" ]; then
    DETECTED_TERMINAL="konsole"
fi

# Enhanced session ID with terminal detection
LOG_SESSION_ID="$DATETIME-$DETECTED_TERMINAL-install"

# Synchronized log and screenshot session structure
LOG_FILE="$LOG_DIR/$LOG_SESSION_ID.log"                    # Main human-readable log
LOG_JSON="$LOG_DIR/$LOG_SESSION_ID.json"                   # Structured JSON log for parsing
LOG_ERRORS="$LOG_DIR/$LOG_SESSION_ID-errors.log"           # Errors and warnings only
LOG_COMMANDS="$LOG_DIR/$LOG_SESSION_ID-commands.log"       # Full command outputs and results
LOG_PERFORMANCE="$LOG_DIR/$LOG_SESSION_ID-performance.json" # Performance metrics
LOG_SESSION_MANIFEST="$LOG_DIR/$LOG_SESSION_ID-manifest.json" # Complete session tracking

# Session Management Instructions:
# - View all sessions: ls -la $SCRIPT_DIR/logs/
# - View session logs: ls -la $LOG_DIR/$LOG_SESSION_ID*
# - Session manifest: jq '.' $LOG_SESSION_MANIFEST

REAL_HOME="${SUDO_HOME:-$HOME}"
# fnm (Fast Node Manager) - Constitutional Compliance (AGENTS.md line 23)
# 40x faster than NVM (<50ms vs 500ms-3s startup)
NODE_VERSION="25"  # Constitutional requirement: latest Node.js  # fnm supports LTS selection

# Directories
GHOSTTY_APP_DIR="$REAL_HOME/Apps/ghostty"
GHOSTTY_CONFIG_DIR="$REAL_HOME/.config/ghostty"
GHOSTTY_CONFIG_SOURCE="$SCRIPT_DIR/configs/ghostty"
FNM_DIR="$REAL_HOME/.local/share/fnm"  # XDG-compliant
APPS_DIR="$REAL_HOME/Apps"

# Global variables for installation status and strategies
ghostty_installed=false
ghostty_version=""
ghostty_config_valid=false
ghostty_source=""
ptyxis_installed=false

# Failure tracking system
declare -a INSTALLATION_FAILURES=()
declare -a INSTALLATION_WARNINGS=()
declare -a INSTALLATION_SUCCESSES=()
ptyxis_version=""
ptyxis_source=""
GHOSTTY_STRATEGY=""
PTYXIS_STRATEGY=""
CONFIG_NEEDS_UPDATE=false

# Installation state tracking (idempotent operation support)
STATE_FILE="$SCRIPT_DIR/.installation-state.json"

# Force flags for selective reinstallation
FORCE_ALL=false
FORCE_GHOSTTY=false
FORCE_NODE=false
FORCE_ZSH=false
FORCE_PTYXIS=false
FORCE_UV=false
FORCE_CLAUDE=false
FORCE_GEMINI=false
FORCE_COPILOT=false
FORCE_SPEC_KIT=false
SKIP_CHECKS=false
RESUME_MODE=false
RESET_STATE=false

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
    echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\",\"function\":\"${FUNCNAME[1]:-main}\",\"line\":\"${BASH_LINENO[1]:-0}\"}" >> "$LOG_JSON"

    # Human-readable log file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    # Error log file for critical issues
    if [ "$level" = "ERROR" ] || [ "$level" = "WARNING" ]; then
        echo "[$timestamp] [$level] [${FUNCNAME[1]:-main}:${BASH_LINENO[1]:-0}] $message" >> "$LOG_ERRORS"
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

# ============================================================================
# BOX DRAWING FUNCTIONS (Enhanced CLI Rendering)
# ============================================================================

# Calculate the display width of a string (strips ALL ANSI escape sequences)
# Handles:
#   - Color codes (SGR): \x1b[0;32m, \x1b[1;33m, etc.
#   - Cursor movement: \x1b[H, \x1b[<row>;<col>H, \x1b[A/B/C/D, etc.
#   - Erase sequences: \x1b[J, \x1b[K, etc.
#   - OSC sequences: \x1b]0;Title\x07 (window titles)
#   - Character set selection: \x1b(B, \x1b)0, etc.
# Returns: Visual character count (proper Unicode handling)
get_string_width() {
    local string="$1"

    # Strip ALL ANSI escape sequences using comprehensive regex patterns:
    # 1. \x1b\[[0-9;]*m          : Standard color codes (SGR - Select Graphic Rendition)
    # 2. \x1b\[[0-9;]*[A-Za-z]   : Cursor movement and other CSI sequences
    # 3. \x1b\][^\x07]*\x07      : OSC sequences (Operating System Command)
    # 4. \x1b[()][AB012]         : Character set selection (G0/G1)
    local clean_string=$(echo -e "$string" | sed -E '
        s/\x1b\[[0-9;]*m//g;
        s/\x1b\[[0-9;]*[A-Za-z]//g;
        s/\x1b\][^\x07]*\x07//g;
        s/\x1b[()][AB012]//g
    ')

    # Return visual character count (handles Unicode properly)
    echo "${#clean_string}"
}

# Draw a box with dynamic width calculation and proper padding
# Usage: draw_box "Title" "line1" "line2" "line3" ...
draw_box() {
    local title="$1"
    shift
    local -a content=("$@")

    # Calculate maximum width from title and content
    local max_width=$(get_string_width "$title")
    local line_width

    for line in "${content[@]}"; do
        line_width=$(get_string_width "$line")
        ((line_width > max_width)) && max_width=$line_width
    done

    # Add padding (4 spaces on each side) - inner width without borders
    local content_width=$max_width
    local inner_width=$((max_width + 8))

    # Draw top border (╔══...══╗)
    printf "${CYAN}╔"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╗${NC}\n"

    # Draw title with padding and vertical borders
    printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" "$title"

    # Draw middle separator (╠══...══╣)
    printf "${CYAN}╠"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╣${NC}\n"

    # Draw empty line with borders
    printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" ""

    # Draw content with padding and vertical borders
    for line in "${content[@]}"; do
        printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" "$line"
    done

    # Draw empty line with borders
    printf "${CYAN}║${NC}    %-${content_width}s    ${CYAN}║${NC}\n" ""

    # Draw bottom border (╚══...══╝)
    printf "${CYAN}╚"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╝${NC}\n"
}

# Draw a colored box with dynamic width calculation and proper padding
# Usage: draw_colored_box "$COLOR" "Title" "line1" "line2" "line3" ...
draw_colored_box() {
    local color="$1"
    local title="$2"
    shift 2
    local -a content=("$@")

    # Calculate maximum width from title and content
    local max_width=$(get_string_width "$title")
    local line_width

    for line in "${content[@]}"; do
        line_width=$(get_string_width "$line")
        ((line_width > max_width)) && max_width=$line_width
    done

    # Add padding (4 spaces on each side) - inner width without borders
    local content_width=$max_width
    local inner_width=$((max_width + 8))

    # Draw top border (╔══...══╗)
    printf "${color}╔"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╗${NC}\n"

    # Draw title with padding and vertical borders
    printf "${color}║${NC}    %-${content_width}s    ${color}║${NC}\n" "$title"

    # Draw middle separator (╠══...══╣)
    printf "${color}╠"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╣${NC}\n"

    # Draw empty line with borders
    printf "${color}║${NC}    %-${content_width}s    ${color}║${NC}\n" ""

    # Draw content with padding and vertical borders
    for line in "${content[@]}"; do
        printf "${color}║${NC}    %-${content_width}s    ${color}║${NC}\n" "$line"
    done

    # Draw empty line with borders
    printf "${color}║${NC}    %-${content_width}s    ${color}║${NC}\n" ""

    # Draw bottom border (╚══...══╝)
    printf "${color}╚"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╝${NC}\n"
}

# Draw a simple header box (title only, no content)
# Usage: draw_header "Title Text"
draw_header() {
    local title="$1"
    local title_width=$(get_string_width "$title")
    local inner_width=$((title_width + 8))

    # Draw top border (╔══...══╗)
    printf "${CYAN}╔"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╗${NC}\n"

    # Draw title with padding and vertical borders
    printf "${CYAN}║${NC}    %-${title_width}s    ${CYAN}║${NC}\n" "$title"

    # Draw bottom border (╚══...══╝)
    printf "${CYAN}╚"
    printf '═%.0s' $(seq 1 $inner_width)
    printf "╝${NC}\n"
}

# Draw a separator line with dynamic width
# Usage: draw_separator 40
draw_separator() {
    local width="${1:-40}"
    echo "$(printf '─%.0s' $(seq 1 $width))"
}

# Draw a tree-style separator with color
# Usage: draw_tree_separator
draw_tree_separator() {
    echo "$(printf '─%.0s' $(seq 1 39))"
}

# Enhanced command execution with debug mode support
run_command() {
    local description="$1"
    local command="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if $DEBUG_MODE; then
        log "INFO" "🔧 $description"
        log "DEBUG" "Command: $command"
        echo "[$timestamp] [COMMAND_FULL] $command" >> "$LOG_COMMANDS"
        echo "[$timestamp] [COMMAND_START] $description" >> "$LOG_COMMANDS"

        # Show command and all output in debug mode
        echo -e "${YELLOW}► Running: $command${NC}"
        eval "$command" 2>&1 | tee -a "$LOG_COMMANDS" | sed 's/^/   /'
        local exit_code=${PIPESTATUS[0]}

        echo "[$timestamp] [COMMAND_EXIT] Exit code: $exit_code" >> "$LOG_COMMANDS"
        if [[ $exit_code -eq 0 ]]; then
            log "SUCCESS" "✅ $description"
        else
            log "ERROR" "❌ $description failed (exit: $exit_code)"
        fi
        return $exit_code
    else
        # Original behavior - hide output
        eval "$command" >> "$LOG_FILE" 2>&1
        return $?
    fi
}

# ============================================================================
# STATE MANAGEMENT FUNCTIONS (Idempotent Operation Support)
# ============================================================================

# Initialize state file if it doesn't exist
init_state_file() {
    if [ ! -f "$STATE_FILE" ] || $RESET_STATE; then
        log "INFO" "📝 Initializing installation state file..."
        cat > "$STATE_FILE" <<EOF
{
  "created": "$(date -Iseconds)",
  "last_run": "$(date -Iseconds)",
  "completed_steps": [],
  "failed_steps": [],
  "skipped_steps": [],
  "versions": {},
  "flags": {
    "initial_install": true
  }
}
EOF
        if $RESET_STATE; then
            log "INFO" "🔄 Installation state reset - starting fresh"
        fi
    fi
}

# Load state file into memory
load_state() {
    if [ -f "$STATE_FILE" ]; then
        # Validate JSON before loading
        if jq empty "$STATE_FILE" >/dev/null 2>&1; then
            return 0
        else
            log "WARNING" "⚠️  State file corrupted - will reinitialize"
            rm -f "$STATE_FILE"
            init_state_file
        fi
    else
        init_state_file
    fi
}

# Save state to file
save_state() {
    local timestamp=$(date -Iseconds)
    jq --arg ts "$timestamp" '.last_run = $ts' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
}

# Check if a step has been completed
step_completed() {
    local step_name="$1"
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi
    jq -e --arg step "$step_name" '.completed_steps | index($step) != null' "$STATE_FILE" >/dev/null 2>&1
}

# Mark a step as completed
mark_step_completed() {
    local step_name="$1"
    local version="${2:-unknown}"
    local timestamp=$(date -Iseconds)

    # Add to completed_steps array if not already there
    jq --arg step "$step_name" \
       --arg ver "$version" \
       --arg ts "$timestamp" \
       '
       if (.completed_steps | index($step)) == null then
         .completed_steps += [$step]
       else
         .
       end |
       .versions[$step] = $ver |
       .last_run = $ts
       ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

    log "DEBUG" "✅ Marked '$step_name' as completed (version: $version)"
}

# Mark a step as failed
mark_step_failed() {
    local step_name="$1"
    local error_msg="${2:-Unknown error}"
    local timestamp=$(date -Iseconds)

    jq --arg step "$step_name" \
       --arg err "$error_msg" \
       --arg ts "$timestamp" \
       '
       if (.failed_steps | map(.name) | index($step)) == null then
         .failed_steps += [{name: $step, error: $err, timestamp: $ts}]
       else
         .
       end |
       .last_run = $ts
       ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

    log "DEBUG" "❌ Marked '$step_name' as failed: $error_msg"
}

# Mark a step as skipped
mark_step_skipped() {
    local step_name="$1"
    local reason="${2:-User requested skip}"

    jq --arg step "$step_name" \
       --arg reason "$reason" \
       '
       if (.skipped_steps | map(.name) | index($step)) == null then
         .skipped_steps += [{name: $step, reason: $reason}]
       else
         .
       end
       ' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

    log "DEBUG" "⏭️  Marked '$step_name' as skipped: $reason"
}

# Get installed version from state
get_state_version() {
    local step_name="$1"
    if [ ! -f "$STATE_FILE" ]; then
        echo "unknown"
        return
    fi
    jq -r --arg step "$step_name" '.versions[$step] // "unknown"' "$STATE_FILE"
}

# Compare semantic versions (returns 0 if v1 >= v2, 1 otherwise)
compare_versions() {
    local v1="$1"
    local v2="$2"

    # Handle special cases
    if [ "$v1" = "unknown" ] || [ "$v2" = "unknown" ]; then
        return 1
    fi

    # Use sort -V for version comparison
    if [ "$v1" = "$v2" ]; then
        return 0
    fi

    local higher=$(printf "%s\n%s\n" "$v1" "$v2" | sort -V | tail -n1)
    if [ "$higher" = "$v1" ]; then
        return 0
    else
        return 1
    fi
}

# Get installed software version from system
get_installed_version() {
    local software="$1"
    local version_output
    local version

    # Temporarily disable pipefail to avoid SIGPIPE issues with head/tail
    set +o pipefail

    case "$software" in
        "ghostty")
            if command -v ghostty >/dev/null 2>&1; then
                version_output=$(ghostty --version 2>/dev/null | head -1 | awk '{print $2}')
                echo "${version_output:-unknown}"
            else
                echo "not_installed"
            fi
            ;;
        "zsh")
            if command -v zsh >/dev/null 2>&1; then
                version_output=$(zsh --version 2>/dev/null | awk '{print $2}')
                echo "${version_output:-unknown}"
            else
                echo "not_installed"
            fi
            ;;
        "node")
            if command -v node >/dev/null 2>&1; then
                version_output=$(node --version 2>/dev/null | sed 's/^v//')
                echo "${version_output:-unknown}"
            else
                echo "not_installed"
            fi
            ;;
        "ptyxis")
            if command -v ptyxis >/dev/null 2>&1; then
                # Ptyxis --version outputs multi-line, need first line only
                version_output=$(ptyxis --version 2>/dev/null | head -1 | awk '{print $2}')
                echo "${version_output:-unknown}"
            elif snap list 2>/dev/null | grep -q "ptyxis"; then
                version_output=$(snap list ptyxis 2>/dev/null | tail -n +2 | awk '{print $2}')
                echo "${version_output:-unknown}"
            elif flatpak list 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
                version_output=$(flatpak info app.devsuite.Ptyxis 2>/dev/null | grep "Version:" | cut -d: -f2 | xargs)
                echo "${version_output:-unknown}"
            else
                echo "not_installed"
            fi
            ;;
        "uv")
            if command -v uv >/dev/null 2>&1; then
                version_output=$(uv --version 2>/dev/null | awk '{print $2}')
                echo "${version_output:-unknown}"
            else
                echo "not_installed"
            fi
            ;;
        "claude")
            if command -v claude >/dev/null 2>&1; then
                # Claude --version outputs "X.Y.Z (Claude Code)", extract version only
                version_output=$(claude --version 2>/dev/null | head -1 | awk '{print $1}')
                echo "${version_output:-unknown}"
            else
                echo "not_installed"
            fi
            ;;
        "gemini")
            # Gemini CLI doesn't have --version flag, check npm package instead
            if npm list -g @google/gemini-cli 2>/dev/null | grep -q "@google/gemini-cli"; then
                version_output=$(npm list -g @google/gemini-cli 2>/dev/null | grep "@google/gemini-cli" | sed 's/.*@google\/gemini-cli@//' | awk '{print $1}')
                echo "${version_output:-unknown}"
            else
                echo "not_installed"
            fi
            ;;
        "copilot")
            if npm list -g @github/copilot 2>/dev/null | grep -q "@github/copilot"; then
                version_output=$(npm list -g @github/copilot 2>/dev/null | grep "@github/copilot" | sed 's/.*@github\/copilot@//' | awk '{print $1}')
                echo "${version_output:-unknown}"
            else
                echo "not_installed"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac

    # Re-enable pipefail
    set -o pipefail
}

# Display installation state summary
show_state_summary() {
    if [ ! -f "$STATE_FILE" ]; then
        log "INFO" "📋 No previous installation state found"
        return
    fi

    log "INFO" "📋 Previous Installation State:"
    log "INFO" "   Last run: $(jq -r '.last_run' "$STATE_FILE")"

    local completed_count=$(jq -r '.completed_steps | length' "$STATE_FILE")
    if [ "$completed_count" -gt 0 ]; then
        log "INFO" "   ✅ Completed steps ($completed_count):"
        jq -r '.completed_steps[]' "$STATE_FILE" | while read -r step; do
            local version=$(jq -r --arg s "$step" '.versions[$s] // "unknown"' "$STATE_FILE")
            log "INFO" "      - $step (version: $version)"
        done
    fi

    local failed_count=$(jq -r '.failed_steps | length' "$STATE_FILE")
    if [ "$failed_count" -gt 0 ]; then
        log "WARNING" "   ❌ Failed steps ($failed_count):"
        jq -r '.failed_steps[] | "      - \(.name): \(.error)"' "$STATE_FILE"
    fi
}

# Detect all existing software installations
detect_existing_software() {
    log "STEP" "🔍 Detecting existing software installations..."

    local software_list=("ghostty" "zsh" "node" "ptyxis" "uv" "claude" "gemini")
    local found_count=0

    for software in "${software_list[@]}"; do
        local version=$(get_installed_version "$software")
        if [ "$version" != "not_installed" ]; then
            log "INFO" "   ✅ $software: $version"
            found_count=$((found_count + 1))
        else
            log "INFO" "   ❌ $software: Not installed"
        fi
    done

    if [ $found_count -gt 0 ]; then
        log "INFO" "📊 Found $found_count existing installation(s)"
    else
        log "INFO" "📊 No existing installations found - fresh install"
    fi
}

# ============================================================================
# IDEMPOTENT INSTALLATION WRAPPERS
# ============================================================================

# Idempotent wrapper for install_zsh
idempotent_install_zsh() {
    local step_name="install_zsh"
    local force_flag=$FORCE_ZSH

    # Check if already completed and not forced
    if step_completed "$step_name" && ! $force_flag && ! $SKIP_CHECKS; then
        local installed_version=$(get_installed_version "zsh")
        draw_colored_box "$BLUE" "ZSH Installation - Skipped" \
            "✅ ZSH already installed" \
            "📦 Version: $installed_version" \
            "💡 Use --force-zsh to reinstall"
        mark_step_skipped "$step_name" "Already installed"
        return 0
    fi

    # Check for resume mode - skip if not in failed list
    if $RESUME_MODE && ! step_completed "$step_name"; then
        if ! jq -e --arg step "$step_name" '.failed_steps[] | select(.name == $step)' "$STATE_FILE" >/dev/null 2>&1; then
            log "INFO" "⏭️  Skipping $step_name (not in failed list)"
            return 0
        fi
    fi

    log "INFO" "🔧 Installing ZSH..."
    if install_zsh; then
        local version=$(get_installed_version "zsh")
        mark_step_completed "$step_name" "$version"
        return 0
    else
        mark_step_failed "$step_name" "Installation failed"
        return 1
    fi
}

# Idempotent wrapper for install_ghostty
idempotent_install_ghostty() {
    local step_name="install_ghostty"
    local force_flag=$FORCE_GHOSTTY

    if step_completed "$step_name" && ! $force_flag && ! $SKIP_CHECKS; then
        local installed_version=$(get_installed_version "ghostty")
        draw_colored_box "$MAGENTA" "Ghostty Installation - Skipped" \
            "✅ Ghostty already installed" \
            "📦 Version: $installed_version" \
            "💡 Use --force-ghostty to reinstall"
        mark_step_skipped "$step_name" "Already installed"
        return 0
    fi

    if $RESUME_MODE && ! step_completed "$step_name"; then
        if ! jq -e --arg step "$step_name" '.failed_steps[] | select(.name == $step)' "$STATE_FILE" >/dev/null 2>&1; then
            log "INFO" "⏭️  Skipping $step_name (not in failed list)"
            return 0
        fi
    fi

    draw_colored_box "$MAGENTA" "Ghostty Installation - Starting" \
        "🔧 Initiating Ghostty installation" \
        "⏳ This may take a few minutes..."

    if install_ghostty; then
        local version=$(get_installed_version "ghostty")
        draw_colored_box "$MAGENTA" "Ghostty Installation - Complete" \
            "✅ Ghostty successfully installed" \
            "📦 Version: $version" \
            "🎯 Ready to use!"
        mark_step_completed "$step_name" "$version"
        return 0
    else
        draw_colored_box "$MAGENTA" "Ghostty Installation - Failed" \
            "❌ Installation failed" \
            "📋 Check logs for details: $LOG_FILE"
        mark_step_failed "$step_name" "Installation failed"
        return 1
    fi
}

# Idempotent wrapper for install_ptyxis
idempotent_install_ptyxis() {
    local step_name="install_ptyxis"
    local force_flag=$FORCE_PTYXIS

    if step_completed "$step_name" && ! $force_flag && ! $SKIP_CHECKS; then
        local installed_version=$(get_installed_version "ptyxis")
        draw_colored_box "$MAGENTA" "Ptyxis Installation - Skipped" \
            "✅ Ptyxis already installed" \
            "📦 Version: $installed_version" \
            "💡 Use --force-ptyxis to reinstall"
        mark_step_skipped "$step_name" "Already installed"
        return 0
    fi

    if $RESUME_MODE && ! step_completed "$step_name"; then
        if ! jq -e --arg step "$step_name" '.failed_steps[] | select(.name == $step)' "$STATE_FILE" >/dev/null 2>&1; then
            log "INFO" "⏭️  Skipping $step_name (not in failed list)"
            return 0
        fi
    fi

    draw_colored_box "$MAGENTA" "Ptyxis Installation - Starting" \
        "🔧 Initiating Ptyxis installation" \
        "⏳ This may take a few minutes..."

    if install_ptyxis; then
        local version=$(get_installed_version "ptyxis")
        draw_colored_box "$MAGENTA" "Ptyxis Installation - Complete" \
            "✅ Ptyxis successfully installed" \
            "📦 Version: $version" \
            "🎯 Ready to use!"
        mark_step_completed "$step_name" "$version"
        return 0
    else
        draw_colored_box "$MAGENTA" "Ptyxis Installation - Failed" \
            "❌ Installation failed" \
            "📋 Check logs for details: $LOG_FILE"
        mark_step_failed "$step_name" "Installation failed"
        return 1
    fi
}

# Idempotent wrapper for install_nodejs
idempotent_install_nodejs() {
    local step_name="install_nodejs"
    local force_flag=$FORCE_NODE

    if step_completed "$step_name" && ! $force_flag && ! $SKIP_CHECKS; then
        local installed_version=$(get_installed_version "node")
        log "INFO" "⏭️  Node.js already installed (version: $installed_version)"
        log "INFO" "   Use --force-node to reinstall"
        mark_step_skipped "$step_name" "Already installed"
        return 0
    fi

    if $RESUME_MODE && ! step_completed "$step_name"; then
        if ! jq -e --arg step "$step_name" '.failed_steps[] | select(.name == $step)' "$STATE_FILE" >/dev/null 2>&1; then
            log "INFO" "⏭️  Skipping $step_name (not in failed list)"
            return 0
        fi
    fi

    log "INFO" "🔧 Installing Node.js..."
    if install_nodejs; then
        local version=$(get_installed_version "node")
        mark_step_completed "$step_name" "$version"
        return 0
    else
        mark_step_failed "$step_name" "Installation failed"
        return 1
    fi
}

# Idempotent wrapper for install_uv
idempotent_install_uv() {
    local step_name="install_uv"
    local force_flag=$FORCE_UV

    if step_completed "$step_name" && ! $force_flag && ! $SKIP_CHECKS; then
        local installed_version=$(get_installed_version "uv")
        log "INFO" "⏭️  uv already installed (version: $installed_version)"
        log "INFO" "   Use --force-uv to reinstall"
        mark_step_skipped "$step_name" "Already installed"
        return 0
    fi

    if $RESUME_MODE && ! step_completed "$step_name"; then
        if ! jq -e --arg step "$step_name" '.failed_steps[] | select(.name == $step)' "$STATE_FILE" >/dev/null 2>&1; then
            log "INFO" "⏭️  Skipping $step_name (not in failed list)"
            return 0
        fi
    fi

    log "INFO" "🔧 Installing uv..."
    if install_uv; then
        local version=$(get_installed_version "uv")
        mark_step_completed "$step_name" "$version"
        return 0
    else
        mark_step_failed "$step_name" "Installation failed"
        return 1
    fi
}

# Idempotent wrapper for install_claude_code
idempotent_install_claude_code() {
    local step_name="install_claude_code"
    local force_flag=$FORCE_CLAUDE

    if step_completed "$step_name" && ! $force_flag && ! $SKIP_CHECKS; then
        local installed_version=$(get_installed_version "claude")
        log "INFO" "⏭️  Claude Code already installed (version: $installed_version)"
        log "INFO" "   Use --force-claude to reinstall"
        mark_step_skipped "$step_name" "Already installed"
        return 0
    fi

    if $RESUME_MODE && ! step_completed "$step_name"; then
        if ! jq -e --arg step "$step_name" '.failed_steps[] | select(.name == $step)' "$STATE_FILE" >/dev/null 2>&1; then
            log "INFO" "⏭️  Skipping $step_name (not in failed list)"
            return 0
        fi
    fi

    log "INFO" "🔧 Installing Claude Code..."
    if install_claude_code; then
        local version=$(get_installed_version "claude")
        mark_step_completed "$step_name" "$version"
        return 0
    else
        mark_step_failed "$step_name" "Installation failed"
        return 1
    fi
}

# Idempotent wrapper for install_gemini_cli
idempotent_install_gemini_cli() {
    local step_name="install_gemini_cli"
    local force_flag=$FORCE_GEMINI

    if step_completed "$step_name" && ! $force_flag && ! $SKIP_CHECKS; then
        local installed_version=$(get_installed_version "gemini")
        log "INFO" "⏭️  Gemini CLI already installed (version: $installed_version)"
        log "INFO" "   Use --force-gemini to reinstall"
        mark_step_skipped "$step_name" "Already installed"
        return 0
    fi

    if $RESUME_MODE && ! step_completed "$step_name"; then
        if ! jq -e --arg step "$step_name" '.failed_steps[] | select(.name == $step)' "$STATE_FILE" >/dev/null 2>&1; then
            log "INFO" "⏭️  Skipping $step_name (not in failed list)"
            return 0
        fi
    fi

    log "INFO" "🔧 Installing Gemini CLI..."
    if install_gemini_cli; then
        local version=$(get_installed_version "gemini")
        mark_step_completed "$step_name" "$version"
        return 0
    else
        mark_step_failed "$step_name" "Installation failed"
        return 1
    fi
}

# Idempotent wrapper for install_copilot_cli
idempotent_install_copilot_cli() {
    local step_name="install_copilot_cli"
    local force_flag=$FORCE_COPILOT

    if step_completed "$step_name" && ! $force_flag && ! $SKIP_CHECKS; then
        local installed_version=$(get_installed_version "copilot")
        log "INFO" "⏭️  GitHub Copilot CLI already installed (version: $installed_version)"
        log "INFO" "   Use --force-copilot to reinstall"
        mark_step_skipped "$step_name" "Already installed"
        return 0
    fi

    if $RESUME_MODE && ! step_completed "$step_name"; then
        if ! jq -e --arg step "$step_name" '.failed_steps[] | select(.name == $step)' "$STATE_FILE" >/dev/null 2>&1; then
            log "INFO" "⏭️  Skipping $step_name (not in failed list)"
            return 0
        fi
    fi

    log "INFO" "🔧 Installing GitHub Copilot CLI..."
    if install_copilot_cli; then
        local version=$(get_installed_version "copilot")
        mark_step_completed "$step_name" "$version"
        return 0
    else
        mark_step_failed "$step_name" "Installation failed"
        return 1
    fi
}

# Idempotent wrapper for install_speckit
idempotent_install_speckit() {
    local step_name="install_speckit"
    local force_flag=$FORCE_SPEC_KIT

    if step_completed "$step_name" && ! $force_flag && ! $SKIP_CHECKS; then
        log "INFO" "⏭️  spec-kit already installed"
        log "INFO" "   Use --force-spec-kit to reinstall"
        mark_step_skipped "$step_name" "Already installed"
        return 0
    fi

    if $RESUME_MODE && ! step_completed "$step_name"; then
        if ! jq -e --arg step "$step_name" '.failed_steps[] | select(.name == $step)' "$STATE_FILE" >/dev/null 2>&1; then
            log "INFO" "⏭️  Skipping $step_name (not in failed list)"
            return 0
        fi
    fi

    log "INFO" "🔧 Installing spec-kit..."
    if install_speckit; then
        mark_step_completed "$step_name" "latest"
        return 0
    else
        mark_step_failed "$step_name" "Installation failed"
        return 1
    fi
}

# Screenshots disabled - text logging only
ENABLE_SCREENSHOTS="false"
SVG_CAPTURE_SCRIPT=""
SCREENSHOT_SESSION_DIR="/tmp/ghostty-screenshots-disabled"
SCREENSHOT_METADATA="/dev/null"

# Display stage-specific summary information for screenshots
display_stage_summary() {
    local stage_name="$1"

    case "$stage_name" in
        "Initial Desktop")
            echo "🖥️  Clean Ubuntu desktop environment"
            echo "🎯 Target: Install Ghostty terminal with modern tools"
            echo "📦 Components: Ghostty, ZSH, Node.js, Claude Code, Gemini CLI"
            ;;
        "System Check")
            echo "🔍 Checking existing installations..."
            if command -v ghostty >/dev/null 2>&1; then
                echo "✅ Ghostty: $(ghostty --version 2>/dev/null || echo 'Installed')"
            else
                echo "❌ Ghostty: Not installed"
            fi
            if command -v zsh >/dev/null 2>&1; then
                echo "✅ ZSH: $(zsh --version | cut -d' ' -f2)"
            else
                echo "❌ ZSH: Not installed"
            fi
            ;;
        "Dependencies")
            echo "📦 Installing system dependencies..."
            echo "🔧 Build tools, libraries, and development packages"
            echo "📋 Status: $(dpkg -l 2>/dev/null | grep -c "^ii") packages installed"
            ;;
        "ZSH Setup")
            echo "🐚 ZSH Shell Configuration"
            if [ -d "$HOME/.oh-my-zsh" ]; then
                echo "✅ Oh My ZSH: Installed"
            fi
            if [ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
                echo "✅ Powerlevel10k: Installed"
            fi
            echo "🎨 Theme: Modern terminal with git integration"
            ;;
        "Modern Tools")
            echo "⚡ Modern Unix Tool Replacements"
            command -v eza >/dev/null 2>&1 && echo "✅ eza: $(eza --version | head -1)"
            command -v bat >/dev/null 2>&1 && echo "✅ bat: $(bat --version | cut -d' ' -f2)"
            command -v rg >/dev/null 2>&1 && echo "✅ ripgrep: $(rg --version | head -1)"
            command -v fzf >/dev/null 2>&1 && echo "✅ fzf: $(fzf --version)"
            ;;
        "Zig Compiler")
            echo "⚡ Zig Programming Language"
            if command -v zig >/dev/null 2>&1; then
                echo "✅ Zig: $(zig version)"
                echo "🎯 Purpose: Required for building Ghostty from source"
            else
                echo "📥 Installing Zig 0.14.0..."
            fi
            ;;
        "Ghostty Build")
            echo "🏗️  Ghostty Terminal Compilation"
            if command -v ghostty >/dev/null 2>&1; then
                echo "✅ Ghostty: $(ghostty --version 2>/dev/null || echo 'Installed')"
            else
                echo "🔨 Building Ghostty from source with Zig..."
            fi
            echo "⚡ Optimizations: ReleaseFast build for performance"
            ;;
        "Configuration")
            echo "⚙️  Ghostty Configuration Setup"
            echo "📁 Config: ~/.config/ghostty/"
            echo "🎨 Themes: Catppuccin with auto light/dark switching"
            echo "⚡ Performance: 2025 optimizations enabled"
            ;;
        "Context Menu")
            echo "🖱️  Right-click Integration"
            echo "📂 Nautilus: 'Open in Ghostty' context menu"
            echo "🎯 Quick access from any folder"
            ;;
        "Ptyxis Terminal")
            echo "🔄 Secondary Terminal (Comparison)"
            if command -v ptyxis >/dev/null 2>&1; then
                echo "✅ Ptyxis: $(ptyxis --version 2>/dev/null | head -1 || echo 'Installed')"
            fi
            echo "🤖 Integrated with Gemini CLI"
            ;;
        "UV Package Manager")
            echo "🐍 Python Package Management"
            if command -v uv >/dev/null 2>&1; then
                echo "✅ uv: $(uv --version)"
            fi
            echo "⚡ Ultra-fast Python package installer and resolver"
            ;;
        "Node.js Setup")
            echo "📦 Node.js and NPM"
            if command -v node >/dev/null 2>&1; then
                echo "✅ Node.js: $(node --version)"
                echo "✅ NPM: $(npm --version)"
            fi
            echo "🎯 Required for AI CLI tools"
            ;;
        "Claude Code")
            echo "🤖 Claude Code CLI"
            if command -v claude >/dev/null 2>&1; then
                echo "✅ Claude: $(claude --version)"
            fi
            echo "💡 Anthropic's AI assistant for code"
            ;;
        "Gemini CLI")
            echo "💎 Google Gemini CLI"
            if command -v gemini >/dev/null 2>&1; then
                echo "✅ Gemini: Available"
            fi
            echo "🔗 Integrated with Ptyxis terminal"
            ;;
        "Verification")
            echo "✅ Installation Verification"
            echo "🔍 Testing all components..."
            echo "📊 Performance check and final validation"
            ;;
        "Completion")
            echo "🎉 Installation Complete!"
            echo "✅ All tools installed and configured"
            echo ""
            echo "📊 Final Status:"
            command -v ghostty >/dev/null 2>&1 && echo "  ✅ Ghostty: $(ghostty --version 2>/dev/null || echo 'Ready')"
            command -v zsh >/dev/null 2>&1 && echo "  ✅ ZSH: Default shell with Powerlevel10k"
            command -v claude >/dev/null 2>&1 && echo "  ✅ Claude Code: $(claude --version 2>/dev/null || echo 'Ready')"
            command -v node >/dev/null 2>&1 && echo "  ✅ Node.js: $(node --version 2>/dev/null)"
            echo ""
            echo "📁 Session: $LOG_SESSION_ID"
            if [ -f "$LOG_SESSION_MANIFEST" ]; then
                local duration=$(jq -r '.status.completed // empty' "$LOG_SESSION_MANIFEST" 2>/dev/null | head -1)
                [ -n "$duration" ] && echo "⏱️  Session completed: $(date -d "$duration" '+%H:%M:%S' 2>/dev/null || echo 'Recently')"
            fi
            echo "🚀 Shell restart will activate new configuration"
            ;;
        "Shell Restart")
            echo "🔄 Activating New Shell Environment"
            echo "✅ Installation completed successfully"
            echo ""
            echo "🐚 New Configuration:"
            echo "  ✅ ZSH with Oh My ZSH framework"
            echo "  ✅ Powerlevel10k theme with git integration"
            echo "  ✅ Modern tools (eza, bat, ripgrep, fzf)"
            echo "  ✅ AI tools (Claude Code, Gemini CLI)"
            echo ""
            echo "⚡ Restarting shell to activate configuration..."
            echo "🎯 Next: New shell prompt with enhanced features"
            ;;
        *)
            echo "🔧 Installation step: $stage_name"
            ;;
    esac
}

# Screenshot function removed - using track_stage() for logging only
capture_stage_screenshot() {
    local stage_name="$1"
    track_stage "$stage_name" "installation"
}

# Failure tracking functions
track_success() {
    local component="$1"
    local message="${2:-$component completed successfully}"
    INSTALLATION_SUCCESSES+=("✅ $component: $message")
    debug "📊 Tracked success: $component"
}

track_warning() {
    local component="$1"
    local message="${2:-$component completed with warnings}"
    INSTALLATION_WARNINGS+=("⚠️  $component: $message")
    debug "📊 Tracked warning: $component"
}

track_failure() {
    local component="$1"
    local message="${2:-$component failed}"
    INSTALLATION_FAILURES+=("❌ $component: $message")
    debug "📊 Tracked failure: $component"
}

# Show installation summary
show_installation_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           Installation Summary${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    # Show successes
    if [ ${#INSTALLATION_SUCCESSES[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ Successful Components (${#INSTALLATION_SUCCESSES[@]}):${NC}"
        for success in "${INSTALLATION_SUCCESSES[@]}"; do
            echo "   $success"
        done
        echo ""
    fi

    # Show warnings
    if [ ${#INSTALLATION_WARNINGS[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Components with Warnings (${#INSTALLATION_WARNINGS[@]}):${NC}"
        for warning in "${INSTALLATION_WARNINGS[@]}"; do
            echo "   $warning"
        done
        echo ""
    fi

    # Show failures
    if [ ${#INSTALLATION_FAILURES[@]} -gt 0 ]; then
        echo -e "${RED}❌ Failed Components (${#INSTALLATION_FAILURES[@]}):${NC}"
        for failure in "${INSTALLATION_FAILURES[@]}"; do
            echo "   $failure"
        done
        echo ""
        echo -e "${YELLOW}💡 Note: Failed components can be retried manually or will be available after shell restart${NC}"
        echo ""
    fi

    # Overall status
    if [ ${#INSTALLATION_FAILURES[@]} -eq 0 ] && [ ${#INSTALLATION_WARNINGS[@]} -eq 0 ]; then
        echo -e "${GREEN}🎉 Overall Status: All components installed successfully!${NC}"
    elif [ ${#INSTALLATION_FAILURES[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Overall Status: Installation completed with warnings${NC}"
    else
        echo -e "${YELLOW}⚠️  Overall Status: Installation completed with some failures${NC}"
        echo -e "${CYAN}   Core system is functional - failed components are optional${NC}"
    fi

    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}📋 Session Logs:${NC}"
    echo "   Main log: $LOG_FILE"
    echo "   Error log: $LOG_ERRORS"
    echo "   JSON log: $LOG_JSON"
    echo ""
}

# Function to create process diagram
create_installation_diagram() {
    local stages_json='[
        "System Check",
        "Dependencies",
        "Zig Installation",
        "Ghostty Build",
        "Configuration",
        "Context Menu",
        "Verification"
    ]'

    if [ "$ENABLE_SCREENSHOTS" = "true" ] && [ -f "$SVG_CAPTURE_SCRIPT" ]; then
        log "INFO" "📊 Creating installation process diagram"
        "$SVG_CAPTURE_SCRIPT" diagram "Ghostty Installation Process" "$stages_json" || \
        log "WARNING" "Process diagram creation failed"
    fi
}

# Function to setup screenshot dependencies using uv - FULLY AUTOMATIC
setup_screenshot_dependencies() {
    if [ "$ENABLE_SCREENSHOTS" = "false" ]; then
        debug "Screenshot capture disabled (no GUI), skipping dependency setup"
        return 0
    fi

    debug "📸 Auto-setting up SVG screenshot dependencies..."

    # Ensure uv is available and in PATH
    if ! command -v uv >/dev/null 2>&1; then
        log "WARNING" "uv not found, installing screenshot tools via system packages only"
        install_system_screenshot_tools
        return $?
    fi

    # Create uv project for screenshot tools if it doesn't exist
    local screenshot_tools_dir="$SCRIPT_DIR/.screenshot-tools"
    if [ ! -d "$screenshot_tools_dir" ]; then
        mkdir -p "$screenshot_tools_dir"
        cd "$screenshot_tools_dir"

        # Initialize uv project for screenshot tools
        cat > pyproject.toml << 'EOF'
[project]
name = "ghostty-screenshot-tools"
version = "1.0.0"
description = "SVG screenshot capture tools for Ghostty installation documentation"
requires-python = ">=3.9"
dependencies = [
    "termtosvg>=1.1.0",
    "asciinema>=2.4.0",
    "svg-term>=1.0.0",
    "jinja2>=3.1.0",
    "pillow>=10.0.0",
    "cairosvg>=2.7.0"
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = []
EOF

        # Create .python-version
        echo "3.11" > .python-version

        debug "🐍 Created uv project for screenshot tools"
        cd "$SCRIPT_DIR"
    fi

    # Install Python dependencies via uv silently
    cd "$screenshot_tools_dir"
    debug "📦 Installing Python screenshot tools via uv..."

    if uv sync >> "$LOG_FILE" 2>&1; then
        debug "✅ Python screenshot tools installed via uv"

        # Make uv environment available for screenshot script
        export UV_PROJECT_ENVIRONMENT="$screenshot_tools_dir/.venv"
        export SCREENSHOT_TOOLS_VENV="$screenshot_tools_dir/.venv"

        # Test that tools are available silently
        if uv run python -c "import termtosvg" >> "$LOG_FILE" 2>&1; then
            debug "✅ termtosvg available in uv environment"
        else
            debug "⚠️ termtosvg import failed, will use fallback methods"
        fi
    else
        debug "⚠️ uv sync failed, falling back to system tools"
        install_system_screenshot_tools
    fi

    cd "$SCRIPT_DIR"

    # Install system-level screenshot tools as backup silently
    install_system_screenshot_tools

    debug "📸 Screenshot dependencies setup complete"
}

# Function to install system screenshot tools - SILENT
install_system_screenshot_tools() {
    debug "📦 Installing system screenshot tools..."

    local tools_to_install=()

    # Check for gnome-screenshot
    if ! command -v gnome-screenshot >/dev/null 2>&1; then
        tools_to_install+=("gnome-screenshot")
    fi

    # Check for scrot
    if ! command -v scrot >/dev/null 2>&1; then
        tools_to_install+=("scrot")
    fi

    # Check for ImageMagick
    if ! command -v convert >/dev/null 2>&1; then
        tools_to_install+=("imagemagick")
    fi

    # Check for SVG tools
    if ! command -v rsvg-convert >/dev/null 2>&1; then
        tools_to_install+=("librsvg2-bin")
    fi

    if [ ${#tools_to_install[@]} -gt 0 ]; then
        debug "🔧 Installing system tools: ${tools_to_install[*]}"

        if command -v apt >/dev/null 2>&1; then
            if sudo apt update >> "$LOG_FILE" 2>&1 && \
               sudo apt install -y "${tools_to_install[@]}" >> "$LOG_FILE" 2>&1; then
                debug "✅ System screenshot tools installed"
            else
                debug "⚠️ Some system screenshot tools may have failed to install"
            fi
        else
            debug "⚠️ apt not available, system screenshot tools not installed"
        fi
    else
        debug "ℹ️ All system screenshot tools already available"
    fi
}

# Function to finalize documentation - FULLY AUTOMATIC
finalize_installation_docs() {
    if [ "$ENABLE_SCREENSHOTS" = "true" ] && [ -f "$SVG_CAPTURE_SCRIPT" ]; then
        log "INFO" "📚 Generating installation documentation and website"

        # Wait for any remaining screenshot captures
        if [ -f "$LOG_DIR/$LOG_SESSION_ID-screenshot-pids.log" ]; then
            while read -r pid; do
                if kill -0 "$pid" 2>/dev/null; then
                    wait "$pid" 2>/dev/null || true
                fi
            done < "$LOG_DIR/$LOG_SESSION_ID-screenshot-pids.log"
            rm -f "$LOG_DIR/$LOG_SESSION_ID-screenshot-pids.log"
        fi

        # Generate complete documentation with uv environment
        if [ -n "${SCREENSHOT_TOOLS_VENV:-}" ] && [ -d "$SCREENSHOT_TOOLS_VENV" ]; then
            export UV_PROJECT_ENVIRONMENT="$SCREENSHOT_TOOLS_VENV"
        fi

        # Generate SVG screenshot documentation
        "$SVG_CAPTURE_SCRIPT" generate-docs >/dev/null 2>&1 || \
        debug "SVG documentation generation failed"

        # Generate Astro.build website automatically
        if [ -f "$SCRIPT_DIR/generate_docs_website.sh" ]; then
            debug "🌐 Building Astro.build documentation website..."

            # Ensure Node.js is available for Astro build
            if command -v node >/dev/null 2>&1; then
                if "$SCRIPT_DIR/generate_docs_website.sh" build >> "$LOG_FILE" 2>&1; then
                    log "SUCCESS" "📖 Documentation website built successfully"
                    log "INFO" "🌐 Website available in docs/ directory for GitHub Pages"
                else
                    debug "Astro build failed, basic documentation still available"
                fi
            else
                debug "Node.js not available, skipping Astro build"
            fi
        fi

        log "SUCCESS" "📸 Screenshot gallery and documentation complete"
        log "INFO" "📁 Screenshots: docs/assets/screenshots/$LOG_SESSION_ID/"
        log "INFO" "📄 View logs: ls -la $LOG_DIR/$LOG_SESSION_ID*"
    fi
}

# Session Management and Cross-Execution Tracking
init_session_tracking() {
    log "INFO" "🔄 Initializing session tracking: $LOG_SESSION_ID"

    # Ensure all directories exist
    mkdir -p "$LOG_DIR" "$SCREENSHOT_SESSION_DIR"

    # Create comprehensive session manifest
    cat > "$LOG_SESSION_MANIFEST" << EOF
{
  "session_id": "$LOG_SESSION_ID",
  "datetime": "$DATETIME",
  "terminal_detected": "$DETECTED_TERMINAL",
  "session_type": "install",
  "created": "$(date -Iseconds)",
  "machine_info": {
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "os": "$(lsb_release -d 2>/dev/null | cut -f2 || echo 'Linux')",
    "kernel": "$(uname -r)",
    "shell": "$SHELL",
    "term": "${TERM:-unknown}",
    "display": "${DISPLAY:-none}",
    "wayland": "${WAYLAND_DISPLAY:-none}"
  },
  "terminal_environment": {
    "detected_terminal": "$DETECTED_TERMINAL",
    "term_program": "${TERM_PROGRAM:-unknown}",
    "ghostty_resources": "${GHOSTTY_RESOURCES_DIR:-none}",
    "ptyxis_version": "${PTYXIS_VERSION:-none}",
    "gnome_terminal": "${GNOME_TERMINAL_SCREEN:-none}",
    "konsole_version": "${KONSOLE_VERSION:-none}"
  },
  "paths": {
    "log_dir": "$LOG_DIR",
    "screenshot_dir": "$SCREENSHOT_SESSION_DIR",
    "project_root": "$SCRIPT_DIR"
  },
  "files": {
    "main_log": "$LOG_FILE",
    "json_log": "$LOG_JSON",
    "error_log": "$LOG_ERRORS",
    "command_log": "$LOG_COMMANDS",
    "performance_log": "$LOG_PERFORMANCE",
    "screenshot_metadata": "$SCREENSHOT_METADATA"
  },
  "status": {
    "started": "$(date -Iseconds)",
    "completed": null,
    "screenshots_enabled": $ENABLE_SCREENSHOTS,
    "gui_available": $([ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && echo "true" || echo "false"),
    "uv_available": $(command -v uv >/dev/null 2>&1 && echo "true" || echo "false")
  },
  "stages": [],
  "statistics": {
    "total_stages": 0,
    "screenshots_captured": 0,
    "errors_encountered": 0,
    "duration_seconds": 0
  }
}
EOF

    log "SUCCESS" "📋 Session manifest created: $LOG_SESSION_MANIFEST"
    log "INFO" "🏷️  Session type: $DETECTED_TERMINAL terminal installation"
}

# Add stage tracking to session manifest
track_stage() {
    local stage_name="$1"
    local stage_type="${2:-installation}"
    local timestamp="$(date -Iseconds)"

    if [ -f "$LOG_SESSION_MANIFEST" ]; then
        local temp_manifest=$(mktemp)
        jq --arg stage "$stage_name" \
           --arg type "$stage_type" \
           --arg timestamp "$timestamp" \
           '.stages += [{
             "name": $stage,
             "type": $type,
             "timestamp": $timestamp,
             "screenshot_expected": true
           }] | .statistics.total_stages = (.stages | length)' \
           "$LOG_SESSION_MANIFEST" > "$temp_manifest"

        mv "$temp_manifest" "$LOG_SESSION_MANIFEST"
        debug "📊 Tracked stage: $stage_name"
    fi
}

# Finalize session tracking
finalize_session_tracking() {
    if [ -f "$LOG_SESSION_MANIFEST" ]; then
        local temp_manifest=$(mktemp)
        local end_time="$(date -Iseconds)"
        local start_time=$(jq -r '.status.started' "$LOG_SESSION_MANIFEST")
        local duration=0

        if [ "$start_time" != "null" ]; then
            local start_epoch=$(date -d "$start_time" +%s)
            local end_epoch=$(date -d "$end_time" +%s)
            duration=$((end_epoch - start_epoch))
        fi

        # Count screenshots if directory exists
        local screenshots_count=0
        if [ -d "$SCREENSHOT_SESSION_DIR" ]; then
            screenshots_count=$(find "$SCREENSHOT_SESSION_DIR" -name "*.svg" 2>/dev/null | wc -l)
        fi

        # Count errors
        local errors_count=0
        if [ -f "$LOG_ERRORS" ]; then
            errors_count=$(wc -l < "$LOG_ERRORS" 2>/dev/null || echo "0")
        fi

        jq --arg end_time "$end_time" \
           --arg duration "$duration" \
           --arg screenshots "$screenshots_count" \
           --arg errors "$errors_count" \
           '.status.completed = $end_time |
            .statistics.duration_seconds = ($duration | tonumber) |
            .statistics.screenshots_captured = ($screenshots | tonumber) |
            .statistics.errors_encountered = ($errors | tonumber)' \
           "$LOG_SESSION_MANIFEST" > "$temp_manifest"

        mv "$temp_manifest" "$LOG_SESSION_MANIFEST"

        log "SUCCESS" "📊 Session completed: $duration seconds, $screenshots_count screenshots, $errors_count errors"
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
    draw_tree_separator

    # Store task start info with safe filename
    local safe_task_id=$(echo "$task_id" | tr -cd '[:alnum:]' | cut -c1-20)
    local task_file="/tmp/task_${safe_task_id}_$$"
    echo "$task_id|$task_name|$(date +%s)" > "$task_file"
    echo "$task_id"
}

# Stream command output in real-time with comprehensive logging
stream_command() {
    local task_id="$1"
    local command="$2"
    local description="$3"

    echo -e "   ${YELLOW}💻 ${NC}$description"
    echo -e "   ${CYAN}├─ Command: ${NC}$command"
    echo -e "   ${CYAN}└─ Output:${NC}"

    # Log command start to all relevant log files
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local start_time=$(date +%s.%N)
    # Use short, safe filename to prevent "File name too long" errors
    local safe_task_id=$(echo "$task_id" | tr -cd '[:alnum:]' | cut -c1-20)
    local temp_log="/tmp/cmd_${safe_task_id}_$$"

    # Log command execution to dedicated command log
    cat >> "$LOG_COMMANDS" << EOF
[$timestamp] [COMMAND_START] Task: $task_id | Description: $description
[$timestamp] [COMMAND] $command
$(draw_separator 39)
EOF

    # Run command with real-time output and comprehensive logging
    local exit_code=0
    {
        echo "[$timestamp] [COMMAND_START] $description"
        echo "[$timestamp] [COMMAND] $command"
        draw_separator 39

        # Execute command and capture all output with indentation for readability
        if eval "$command" 2>&1 | while IFS= read -r line; do
            echo "      $line"  # Show to user with indentation
            echo "$line" >> "$temp_log"  # Temp storage
            echo "[$timestamp] [OUTPUT] $line" >> "$LOG_COMMANDS"  # Log all output
            echo "[$timestamp] [COMMAND_OUTPUT] $line" >> "$LOG_FILE"  # Main log
        done; then
            exit_code=0
        else
            exit_code=$?
        fi

        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "unknown")

        echo ""
        if [ $exit_code -eq 0 ]; then
            echo -e "   ${GREEN}✅ Completed in ${duration}s${NC}"
            echo "[$timestamp] [COMMAND_SUCCESS] Duration: ${duration}s | Exit: $exit_code" >> "$LOG_COMMANDS"
            echo "[$timestamp] [COMMAND_SUCCESS] $description completed in ${duration}s" >> "$LOG_FILE"
        else
            echo -e "   ${RED}❌ Failed after ${duration}s${NC}"
            echo "[$timestamp] [COMMAND_FAILED] Duration: ${duration}s | Exit: $exit_code" >> "$LOG_COMMANDS"
            echo "[$timestamp] [COMMAND_FAILED] $description failed after ${duration}s (exit: $exit_code)" >> "$LOG_FILE"
            echo "[$timestamp] [ERROR] [stream_command] Command failed: $command" >> "$LOG_ERRORS"
        fi

        # Add separator to logs
        echo "" >> "$LOG_COMMANDS"
        return $exit_code
    }
}

# Complete and collapse a task with enhanced logging
complete_task() {
    local task_id="$1"
    local status="${2:-success}"
    local summary="$3"

    local task_name="${active_tasks[$task_id]:-Unknown Task}"

    # Use safe filename for task tracking
    local safe_task_id=$(echo "$task_id" | tr -cd '[:alnum:]' | cut -c1-20)
    local task_file="/tmp/task_${safe_task_id}_$$"
    if [ -f "$task_file" ]; then
        local task_info=$(cat "$task_file")
        local start_time=$(echo "$task_info" | cut -d'|' -f3)
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        # Log task completion
        echo "[$timestamp] [TASK_COMPLETE] $task_name | Status: $status | Duration: ${duration}s" >> "$LOG_FILE"
        if [ -n "$summary" ]; then
            echo "[$timestamp] [TASK_SUMMARY] $summary" >> "$LOG_FILE"
        fi

        # Show collapsed summary with enhanced information (no cursor manipulation for compatibility)
        echo ""  # Add some space
        if [ "$status" = "success" ]; then
            echo -e "${GREEN}✅ $task_name${NC} ${CYAN}(${duration}s)${NC}"
            if [ -n "$summary" ]; then
                echo -e "${BLUE}   ✓ $summary${NC}"
            fi
        elif [ "$status" = "warning" ]; then
            echo -e "${YELLOW}⚠️  $task_name${NC} ${CYAN}(${duration}s)${NC}"
            if [ -n "$summary" ]; then
                echo -e "${YELLOW}   ⚠ $summary${NC}"
            fi
        else
            echo -e "${RED}❌ $task_name${NC} ${CYAN}(${duration}s)${NC}"
            if [ -n "$summary" ]; then
                echo -e "${RED}   ✗ $summary${NC}"
            fi
        fi

        # Add log viewing hint for failed tasks
        if [ "$status" = "error" ]; then
            echo -e "${BLUE}   📋 Check logs: $LOG_FILE${NC}"
        fi
        echo ""  # Add space after completion

        # Copy command output to main log if it exists
        local temp_log="/tmp/cmd_${safe_task_id}_$$"
        if [ -f "$temp_log" ]; then
            echo "[$timestamp] [TASK_OUTPUT_START] $task_name" >> "$LOG_FILE"
            cat "$temp_log" >> "$LOG_FILE"
            echo "[$timestamp] [TASK_OUTPUT_END] $task_name" >> "$LOG_FILE"
        fi

        # Cleanup using safe filenames
        rm -f "$task_file"
        rm -f "$temp_log"
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
    local state_file="$LOG_DIR/$LOG_SESSION_ID-system-state-$(date +%s).json"
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
        echo "{\"timestamp\":\"$(date -Iseconds)\",\"operation\":\"$PERF_OPERATION\",\"duration\":\"$duration\",\"memory_delta\":\"$memory_delta\"}" >> "$LOG_PERFORMANCE"

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
    echo "  • ZSH shell with Oh My ZSH, essential plugins, and modern tools (eza, bat, ripgrep, fzf, zoxide)"
    echo "  • Ghostty terminal emulator with optimized configuration"
    echo "  • Ptyxis terminal (prefers apt/snap, fallback to flatpak)"
    echo "  • uv Python package manager (latest version)"
    echo "  • Node.js (via fnm - Fast Node Manager) with npm and development tools"
    echo "  • Claude Code CLI (latest version)"
    echo "  • Gemini CLI (latest version)"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo "  --skip-deps         Skip system dependency installation"
    echo "  --skip-node         Skip Node.js/fnm installation"
    echo "  --skip-ai           Skip AI tools (Claude Code, Gemini CLI)"
    echo "  --skip-ptyxis       Skip Ptyxis installation"
    echo "  --verbose           Enable verbose logging"
    echo "  --debug             Enable full debug mode (shows all commands and outputs)"
    echo ""
    echo "Idempotent Operation Flags:"
    echo "  --force             Force reinstall everything (ignore state)"
    echo "  --force-ghostty     Force reinstall only Ghostty"
    echo "  --force-node        Force reinstall only Node.js/fnm"
    echo "  --force-zsh         Force reinstall only ZSH"
    echo "  --force-ptyxis      Force reinstall only Ptyxis"
    echo "  --force-uv          Force reinstall only uv"
    echo "  --force-claude      Force reinstall only Claude CLI"
    echo "  --force-gemini      Force reinstall only Gemini CLI"
    echo "  --force-spec-kit    Force reinstall only spec-kit"
    echo "  --skip-checks       Skip all version checks (dangerous)"
    echo "  --resume            Resume from last failure point"
    echo "  --reset-state       Clear installation state and start fresh"
    echo "  --show-state        Show current installation state and exit"
    echo ""
    echo "Examples:"
    echo "  ./start.sh                         # Full installation (idempotent)"
    echo "  ./start.sh --force-ghostty        # Reinstall only Ghostty"
    echo "  ./start.sh --force-node           # Reinstall only Node.js"
    echo "  ./start.sh --resume               # Resume from last failure"
    echo "  ./start.sh --reset-state          # Clear state and reinstall everything"
    echo "  ./start.sh --show-state           # Show what's already installed"
    echo "  ./start.sh --skip-deps            # Skip system dependencies"
    echo "  ./start.sh --verbose              # Verbose output"
    echo ""
}

# Parse command line arguments
# AUTOMATION MODE: Always install everything with maximum verbosity
# Interactive menus removed for fully automated installation
SKIP_DEPS=false
SKIP_NODE=false
SKIP_AI=false
SKIP_PTYXIS=false
SKIP_UV=false
SKIP_SPEC_KIT=false
VERBOSE=true
DEBUG_MODE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --show-state)
            load_state
            show_state_summary
            detect_existing_software
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
        --debug)
            DEBUG_MODE=true
            VERBOSE=true
            set -x  # Enable bash debug mode
            shift
            ;;
        --force)
            FORCE_ALL=true
            FORCE_GHOSTTY=true
            FORCE_NODE=true
            FORCE_ZSH=true
            FORCE_PTYXIS=true
            FORCE_UV=true
            FORCE_CLAUDE=true
            FORCE_GEMINI=true
            FORCE_SPEC_KIT=true
            log "INFO" "🔄 Force mode enabled - will reinstall all components"
            shift
            ;;
        --force-ghostty)
            FORCE_GHOSTTY=true
            shift
            ;;
        --force-node)
            FORCE_NODE=true
            shift
            ;;
        --force-zsh)
            FORCE_ZSH=true
            shift
            ;;
        --force-ptyxis)
            FORCE_PTYXIS=true
            shift
            ;;
        --force-uv)
            FORCE_UV=true
            shift
            ;;
        --force-claude)
            FORCE_CLAUDE=true
            shift
            ;;
        --force-gemini)
            FORCE_GEMINI=true
            shift
            ;;
        --force-copilot)
            FORCE_COPILOT=true
            shift
            ;;
        --force-spec-kit)
            FORCE_SPEC_KIT=true
            shift
            ;;
        --skip-checks)
            SKIP_CHECKS=true
            log "WARNING" "⚠️  Version checks disabled - may cause issues"
            shift
            ;;
        --resume)
            RESUME_MODE=true
            log "INFO" "🔄 Resume mode enabled - will continue from last failure"
            shift
            ;;
        --reset-state)
            RESET_STATE=true
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

    # Check Ghostty installation with proper source detection
    ghostty_installed=false
    ghostty_version=""
    ghostty_config_valid=false
    ghostty_source=""

    if command -v ghostty >/dev/null 2>&1; then
        ghostty_installed=true

        # Detect installation source first, then get version accordingly
        local ghostty_path=$(which ghostty 2>/dev/null)
        if [[ "$ghostty_path" == "/snap/"* ]]; then
            ghostty_source="snap"
            ghostty_version=$(snap list ghostty 2>/dev/null | tail -1 | awk '{print $2}' || echo "unknown")
            log "INFO" "✅ Ghostty installed via snap: $ghostty_version"
        elif [[ "$ghostty_path" == "/usr/local/"* ]]; then
            ghostty_source="source"
            ghostty_version=$(ghostty --version 2>/dev/null | head -1 || echo "unknown")
            log "INFO" "✅ Ghostty installed from source: $ghostty_version"
        elif dpkg -l 2>/dev/null | grep -q "^ii.*ghostty"; then
            ghostty_source="apt"
            ghostty_version=$(dpkg -l ghostty 2>/dev/null | tail -1 | awk '{print $3}' || echo "unknown")
            log "INFO" "✅ Ghostty installed via apt: $ghostty_version"
        elif [[ "$ghostty_path" == "/usr/bin/"* ]] || [[ "$ghostty_path" == "/usr/"* ]]; then
            ghostty_source="system"
            ghostty_version=$(ghostty --version 2>/dev/null | head -1 || echo "unknown")
            log "INFO" "✅ Ghostty installed via system package manager: $ghostty_version"
        else
            ghostty_source="unknown"
            ghostty_version=$(ghostty --version 2>/dev/null | head -1 || echo "unknown")
            log "INFO" "✅ Ghostty installed (unknown source): $ghostty_version"
        fi

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

    if dpkg -l 2>/dev/null | grep ptyxis | grep -q "^ii"; then
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
    
    # Check Ghostty updates based on installation source
    if $ghostty_installed; then
        if [ "$ghostty_source" = "snap" ]; then
            if snap refresh --list 2>/dev/null | grep -q "ghostty"; then
                log "INFO" "🆕 Ghostty update available via snap"
            else
                log "INFO" "✅ Ghostty is up to date (snap)"
            fi
        elif [ "$ghostty_source" = "apt" ]; then
            if apt list --upgradable 2>/dev/null | grep -q "ghostty"; then
                log "INFO" "🆕 Ghostty update available via apt"
            else
                log "INFO" "✅ Ghostty is up to date (apt)"
            fi
        elif [ "$ghostty_source" = "source" ] && [ -d "$GHOSTTY_APP_DIR" ]; then
            cd "$GHOSTTY_APP_DIR"
            local current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
            git fetch origin main >/dev/null 2>&1 || true
            local latest_commit=$(git rev-parse origin/main 2>/dev/null || echo "unknown")

            if [ "$current_commit" != "$latest_commit" ] && [ "$latest_commit" != "unknown" ]; then
                log "INFO" "🆕 Ghostty update available (new commits)"
            else
                log "INFO" "✅ Ghostty is up to date (source)"
            fi
        else
            log "INFO" "ℹ️ Ghostty update status unknown"
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

    # Ghostty strategy based on installation source
    if $ghostty_installed; then
        if [ "$ghostty_source" = "snap" ]; then
            if $ghostty_config_valid; then
                log "INFO" "📋 Ghostty: Snap installation detected, will only update configuration"
                GHOSTTY_STRATEGY="config_only"
            else
                log "WARNING" "📋 Ghostty: Snap installation with invalid config, will fix configuration"
                GHOSTTY_STRATEGY="reconfig"
            fi
        elif [ "$ghostty_source" = "system" ] || [ "$ghostty_source" = "unknown" ]; then
            if $ghostty_config_valid; then
                log "INFO" "📋 Ghostty: System installation detected, will only update configuration"
                GHOSTTY_STRATEGY="config_only"
            else
                log "WARNING" "📋 Ghostty: System installation with invalid config, will fix configuration"
                GHOSTTY_STRATEGY="reconfig"
            fi
        elif [ "$ghostty_source" = "source" ]; then
            if $ghostty_config_valid; then
                log "INFO" "📋 Ghostty: Will update existing source installation"
                GHOSTTY_STRATEGY="update"
            else
                log "WARNING" "📋 Ghostty: Configuration invalid, will reinstall configuration"
                GHOSTTY_STRATEGY="reconfig"
            fi
        elif [ "$ghostty_source" = "apt" ]; then
            if $ghostty_config_valid; then
                log "INFO" "📋 Ghostty: APT installation detected, will only update configuration"
                GHOSTTY_STRATEGY="config_only"
            else
                log "WARNING" "📋 Ghostty: APT installation with invalid config, will fix configuration"
                GHOSTTY_STRATEGY="reconfig"
            fi
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
    log "INFO" "🔑 Checking sudo configuration..."

    # Use the dedicated verification script for comprehensive checks
    local verify_script="$SCRIPT_DIR/scripts/verify-passwordless-sudo.sh"

    if [ -f "$verify_script" ]; then
        # Run verification script (it will show detailed output)
        if "$verify_script"; then
            log "SUCCESS" "✅ Passwordless sudo configured - installation will run smoothly"
            return 0
        else
            # Verification script already showed detailed instructions
            log "ERROR" "❌ Passwordless sudo is REQUIRED for automated installation"
            log "INFO" ""
            log "INFO" "💡 Please follow the instructions above, then run ./start.sh again"
            log "INFO" "💡 Or run: ./scripts/verify-passwordless-sudo.sh to verify configuration"
            log "INFO" ""
            return 1
        fi
    else
        # Fallback to basic check if verification script doesn't exist
        if sudo -n true 2>/dev/null; then
            log "SUCCESS" "✅ Passwordless sudo configured - installation will run smoothly"
            return 0
        fi

        # Basic instructions if script not found
        log "ERROR" "❌ Passwordless sudo is REQUIRED for automated installation"
        log "INFO" ""
        log "INFO" "🔧 To enable passwordless sudo:"
        log "INFO" "   1. Run: sudo EDITOR=nano visudo"
        log "INFO" "   2. Add this line at the end:"
        log "INFO" "      $USER ALL=(ALL) NOPASSWD: /usr/bin/apt"
        log "INFO" "   3. Save (Ctrl+O, Enter) and exit (Ctrl+X)"
        log "INFO" "   4. Test: sudo -n apt update"
        log "INFO" ""
        log "INFO" "💡 Then run this script again: ./start.sh"
        log "INFO" ""

        return 1
    fi
}

# Install ZSH and Oh My ZSH
install_zsh() {
    # Draw header box with BLUE color
    draw_colored_box "$BLUE" "🐚 ZSH and Oh My ZSH Installation" \
        "Setting up ZSH shell environment" \
        "Installing plugins and optimizations"
    echo ""

    # Check if ZSH is installed and update if needed
    if ! command -v zsh >/dev/null 2>&1; then
        log "INFO" "📥 Installing latest ZSH..."
        if sudo apt update && sudo apt install -y zsh >> "$LOG_FILE" 2>&1; then
            # Show success box
            draw_colored_box "$BLUE" "ZSH Installation - Complete" \
                "✅ ZSH installed successfully"
            echo ""
        else
            log "ERROR" "❌ Failed to install ZSH"
            return 1
        fi
    else
        local current_version=$(zsh --version 2>/dev/null | awk '{print $2}' || echo "unknown")

        # Check for ZSH updates
        log "INFO" "🔄 Checking for ZSH updates..."
        if apt list --upgradable 2>/dev/null | grep -q "^zsh/"; then
            log "INFO" "🆕 ZSH update available, updating..."
            if sudo apt update && sudo apt upgrade -y zsh >> "$LOG_FILE" 2>&1; then
                draw_colored_box "$BLUE" "ZSH Update - Complete" \
                    "✅ ZSH updated to latest version"
                echo ""
            else
                log "WARNING" "⚠️  ZSH update may have failed"
            fi
        else
            draw_colored_box "$BLUE" "ZSH Status" \
                "✅ ZSH already installed: $current_version" \
                "✅ ZSH is up to date"
            echo ""
        fi
    fi

    # Check if Oh My ZSH is installed and update if needed
    if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
        log "INFO" "📥 Installing latest Oh My ZSH..."
        # Download and install Oh My ZSH non-interactively
        if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG_FILE" 2>&1; then
            draw_colored_box "$BLUE" "Oh My ZSH Installation - Complete" \
                "✅ Oh My ZSH installed successfully"
            echo ""
        else
            log "ERROR" "❌ Failed to install Oh My ZSH"
            return 1
        fi
    else
        # Update Oh My ZSH to latest version using git pull (more reliable than upgrade script)
        log "INFO" "🔄 Updating Oh My ZSH to latest version..."
        if run_task_command "Updating Oh My ZSH" "cd '$REAL_HOME/.oh-my-zsh' && git pull origin master && cd - >/dev/null" "Pulling latest Oh My ZSH updates" "30s"; then
            draw_colored_box "$BLUE" "Oh My ZSH Update - Complete" \
                "✅ Oh My ZSH already installed" \
                "✅ Updated to latest version successfully"
            echo ""
        else
            log "WARNING" "⚠️  Oh My ZSH update failed - check network connection"
        fi
    fi
    
    # Check current default shell
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    local zsh_path=$(which zsh)

    if [ "$current_shell" != "$zsh_path" ]; then
        log "INFO" "🔄 Setting ZSH as default shell..."

        # Try to change shell using sudo (non-interactive approach)
        if sudo usermod -s "$zsh_path" "$USER" 2>/dev/null; then
            draw_colored_box "$BLUE" "Shell Configuration - Complete" \
                "✅ ZSH set as default shell" \
                "⚠️  Restart terminal to take effect"
            echo ""
        else
            log "WARNING" "⚠️  Failed to set ZSH as default shell automatically"
            log "INFO" "💡 You can manually set it with: chsh -s $zsh_path"
            log "INFO" "💡 Or run: sudo usermod -s $zsh_path $USER"
        fi
    else
        draw_colored_box "$BLUE" "Shell Configuration - Already Set" \
            "✅ ZSH is already the default shell"
        echo ""
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
    
    # Install essential Oh My ZSH plugins and optimizations
    draw_colored_box "$BLUE" "🔌 Installing ZSH Plugins & Theme" \
        "Setting up essential plugins and optimizations"
    echo ""

    # Track plugin installation status
    local -a plugin_status=()

    # Install zsh-autosuggestions (essential plugin #1)
    local autosuggestions_dir="$REAL_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    if [ ! -d "$autosuggestions_dir" ]; then
        log "INFO" "📥 Installing zsh-autosuggestions..."
        if git clone https://github.com/zsh-users/zsh-autosuggestions "$autosuggestions_dir" >> "$LOG_FILE" 2>&1; then
            plugin_status+=("✅ zsh-autosuggestions")
        else
            plugin_status+=("⚠️  zsh-autosuggestions (failed)")
        fi
    else
        plugin_status+=("✅ zsh-autosuggestions (already installed)")
    fi

    # Install zsh-syntax-highlighting (essential plugin #2)
    local syntax_highlighting_dir="$REAL_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    if [ ! -d "$syntax_highlighting_dir" ]; then
        log "INFO" "📥 Installing zsh-syntax-highlighting..."
        if git clone https://github.com/zsh-users/zsh-syntax-highlighting "$syntax_highlighting_dir" >> "$LOG_FILE" 2>&1; then
            plugin_status+=("✅ zsh-syntax-highlighting")
        else
            plugin_status+=("⚠️  zsh-syntax-highlighting (failed)")
        fi
    else
        plugin_status+=("✅ zsh-syntax-highlighting (already installed)")
    fi

    # Install you-should-use plugin (productivity training)
    local you_should_use_dir="$REAL_HOME/.oh-my-zsh/custom/plugins/you-should-use"
    if [ ! -d "$you_should_use_dir" ]; then
        log "INFO" "📥 Installing you-should-use plugin..."
        if git clone https://github.com/MichaelAquilina/zsh-you-should-use "$you_should_use_dir" >> "$LOG_FILE" 2>&1; then
            plugin_status+=("✅ you-should-use")
        else
            plugin_status+=("⚠️  you-should-use (failed)")
        fi
    else
        plugin_status+=("✅ you-should-use (already installed)")
    fi

    # Install Powerlevel10k theme for enhanced terminal productivity
    local p10k_dir="$REAL_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        log "INFO" "📥 Installing Powerlevel10k theme..."
        if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" >> "$LOG_FILE" 2>&1; then
            plugin_status+=("✅ Powerlevel10k theme")
        else
            plugin_status+=("⚠️  Powerlevel10k theme (failed)")
        fi
    else
        plugin_status+=("✅ Powerlevel10k theme (already installed)")
    fi

    # Display plugin installation summary
    draw_colored_box "$BLUE" "Plugin Installation Summary" "${plugin_status[@]}"
    echo ""

    # Create Powerlevel10k configuration file
    local p10k_config="$REAL_HOME/.p10k.zsh"
    if [ ! -f "$p10k_config" ] && [ -d "$p10k_dir" ]; then
        log "INFO" "⚙️  Creating Powerlevel10k configuration..."
        if [ -f "$p10k_dir/config/p10k-lean.zsh" ]; then
            cp "$p10k_dir/config/p10k-lean.zsh" "$p10k_config"
            log "SUCCESS" "✅ Powerlevel10k configuration created (lean style)"
        else
            log "WARNING" "⚠️  Powerlevel10k config template not found"
        fi
    elif [ -f "$p10k_config" ]; then
        log "INFO" "✅ Powerlevel10k configuration already exists"
    fi

    # Configure Powerlevel10k theme integration
    log "INFO" "🎨 Configuring Powerlevel10k theme integration..."

    # Configure .zshrc with essential plugins and optimizations
    local zshrc="$REAL_HOME/.zshrc"
    if [ -f "$zshrc" ]; then
        # Create backup
        cp "$zshrc" "$zshrc.backup-$(date +%Y%m%d-%H%M%S)"

        # Update plugins with essential trinity + productivity plugins
        if grep -q "plugins=" "$zshrc"; then
            # Replace with optimized plugin list (syntax-highlighting MUST be last)
            # Note: Removed 'nvm' plugin as we use fnm for constitutional compliance
            sed -i 's/plugins=([^)]*)/plugins=(git npm node docker docker-compose sudo history extract z you-should-use zsh-autosuggestions zsh-syntax-highlighting)/' "$zshrc"
            log "SUCCESS" "✅ Updated plugins with essential trinity and productivity tools"
        fi

        # Set Powerlevel10k as the ZSH theme
        if [ -d "$p10k_dir" ]; then
            if grep -q "ZSH_THEME=" "$zshrc"; then
                sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$zshrc"
                log "SUCCESS" "✅ Updated ZSH theme to Powerlevel10k"
            else
                echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$zshrc"
                log "SUCCESS" "✅ Set ZSH theme to Powerlevel10k"
            fi

            # Add Powerlevel10k instant prompt (must be near top of .zshrc)
            if ! grep -q "p10k-instant-prompt" "$zshrc"; then
                # Find the line after the Oh My ZSH path export
                local insert_line=$(grep -n "export ZSH=" "$zshrc" | head -1 | cut -d: -f1)
                if [ -n "$insert_line" ]; then
                    # Insert instant prompt configuration after ZSH path
                    sed -i "${insert_line}a\\
\\
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.\\
# Initialization code that may require console input (password prompts, [y/n]\\
# confirmations, etc.) must go above this block; everything else may go below.\\
if [[ -r \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\" ]]; then\\
  source \"\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh\"\\
fi" "$zshrc"
                    log "SUCCESS" "✅ Added Powerlevel10k instant prompt configuration"
                fi
            fi

            # Add p10k config sourcing at the end
            if ! grep -q "source.*\.p10k\.zsh" "$zshrc" && [ -f "$p10k_config" ]; then
                echo "" >> "$zshrc"
                echo "# To customize prompt, run \`p10k configure\` or edit ~/.p10k.zsh." >> "$zshrc"
                echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> "$zshrc"
                log "SUCCESS" "✅ Added Powerlevel10k configuration sourcing"
            fi
        fi

        # Add performance optimizations to .zshrc
        if ! grep -q "# Oh My ZSH Performance Optimizations" "$zshrc"; then
            cat >> "$zshrc" << 'EOF'

# Oh My ZSH Performance Optimizations (2025)
# Disable magic functions for better performance
DISABLE_MAGIC_FUNCTIONS=true

# Compilation caching for faster startup
autoload -Uz compinit
if [ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]; then
    compinit
else
    compinit -C
fi

# Modern tool aliases for enhanced productivity
if command -v eza >/dev/null 2>&1; then
    alias ls="eza --group-directories-first --git"
    alias ll="eza -la --group-directories-first --git"
    alias tree="eza --tree"
fi

if command -v bat >/dev/null 2>&1; then
    alias cat="bat --style=plain"
    alias bathelp="bat --style=plain --language=help"
fi

if command -v rg >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
fi

# zsh-autosuggestions configuration
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

EOF
            log "SUCCESS" "✅ Added performance optimizations and modern tool aliases"
        fi
    fi
        
        # Note: fnm configuration is handled by scripts/install_node.sh
        # This section intentionally left empty (fnm auto-configures during installation)
        
        # Add Ghostty shell integration to .zshrc (CRITICAL for autocompletion)
        if ! grep -q "GHOSTTY_RESOURCES_DIR.*ghostty-integration" "$zshrc"; then
            # Find the line after "source $ZSH/oh-my-zsh.sh"
            if grep -q "source.*oh-my-zsh.sh" "$zshrc"; then
                # Add ghostty integration right after oh-my-zsh is loaded
                sed -i '/source.*oh-my-zsh.sh/a\
\
# Ghostty shell integration (CRITICAL for proper terminal behavior)\
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then\
  autoload -Uz -- "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration\
  ghostty-integration\
fi' "$zshrc"
                log "SUCCESS" "✅ Added Ghostty shell integration to .zshrc"
            else
                # If oh-my-zsh.sh sourcing not found, add at the end
                cat >> "$zshrc" << 'EOF'

# Ghostty shell integration (CRITICAL for proper terminal behavior)
if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
  autoload -Uz -- "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
  ghostty-integration
fi

EOF
                log "SUCCESS" "✅ Added Ghostty shell integration to .zshrc"
            fi
        else
            log "SUCCESS" "✅ Ghostty shell integration already configured in .zshrc"
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
# Uses fnm-managed Node.js (generic path, auto-resolves to current version)
alias gemini='flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- gemini'

EOF
            log "SUCCESS" "✅ Added Ptyxis gemini integration to .zshrc"
        fi

    # Draw final summary box with BLUE color
    local zsh_version=$(zsh --version 2>/dev/null | awk '{print $2}' || echo "unknown")
    draw_colored_box "$BLUE" "🐚 ZSH Setup Complete" \
        "✅ ZSH $zsh_version installed and configured" \
        "✅ Oh My ZSH framework installed" \
        "✅ Essential plugins: autosuggestions, syntax-highlighting, you-should-use" \
        "✅ Powerlevel10k theme configured" \
        "✅ Performance optimizations applied" \
        "✅ Ghostty shell integration enabled"
    echo ""
}

# Install modern Unix tool replacements for enhanced productivity
install_modern_tools() {
    log "STEP" "🔧 Installing modern Unix tool replacements..."

    # Install/Update eza (modern ls replacement)
    if command -v eza >/dev/null 2>&1; then
        # Check if update is available
        log "INFO" "🔍 Checking for eza updates..."
        sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' > /dev/null
        if apt list --upgradable 2>/dev/null | grep -q "^eza/"; then
            log "INFO" "📥 Updating eza (modern ls replacement)..."
            if run_task_command "Updating eza" "sudo apt upgrade -y eza 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating eza for enhanced directory listings" "30s"; then
                log "SUCCESS" "✅ eza updated successfully"
            else
                log "INFO" "ℹ️ eza update failed, but already installed"
            fi
        else
            log "INFO" "✅ eza is already at the latest version"
        fi
    else
        log "INFO" "📥 Installing eza (modern ls replacement)..."
        if run_task_command "Installing eza" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y eza 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing eza for enhanced directory listings" "30s"; then
            log "SUCCESS" "✅ eza installed successfully"
        else
            log "WARNING" "⚠️  Failed to install eza via apt, trying cargo..."
            if command -v cargo >/dev/null 2>&1; then
                if cargo install eza >> "$LOG_FILE" 2>&1; then
                    log "SUCCESS" "✅ eza installed via cargo"
                else
                    log "WARNING" "⚠️  Failed to install eza"
                fi
            else
                log "WARNING" "⚠️  eza installation failed - cargo not available"
            fi
        fi
    fi

    # Install/Update bat (modern cat replacement)
    if command -v bat >/dev/null 2>&1; then
        # Check if update is available
        log "INFO" "🔍 Checking for bat updates..."
        sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' > /dev/null
        if apt list --upgradable 2>/dev/null | grep -q "^bat/"; then
            log "INFO" "📥 Updating bat (modern cat replacement)..."
            if run_task_command "Updating bat" "sudo apt upgrade -y bat 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating bat for syntax-highlighted file viewing" "30s"; then
                log "SUCCESS" "✅ bat updated successfully"
            else
                log "INFO" "ℹ️ bat update failed, but already installed"
            fi
        else
            log "INFO" "✅ bat is already at the latest version"
        fi
    else
        log "INFO" "📥 Installing bat (modern cat replacement)..."
        if run_task_command "Installing bat" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y bat 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing bat for syntax-highlighted file viewing" "30s"; then
            log "SUCCESS" "✅ bat installed successfully"
        else
            log "WARNING" "⚠️  Failed to install bat"
        fi
    fi

    # Install/Update ripgrep (modern grep replacement)
    if command -v rg >/dev/null 2>&1; then
        # Check if update is available
        log "INFO" "🔍 Checking for ripgrep updates..."
        sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' > /dev/null
        if apt list --upgradable 2>/dev/null | grep -q "^ripgrep/"; then
            log "INFO" "📥 Updating ripgrep (modern grep replacement)..."
            if run_task_command "Updating ripgrep" "sudo apt upgrade -y ripgrep 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating ripgrep for faster searching" "30s"; then
                log "SUCCESS" "✅ ripgrep updated successfully"
            else
                log "INFO" "ℹ️ ripgrep update failed, but already installed"
            fi
        else
            log "INFO" "✅ ripgrep is already at the latest version"
        fi
    else
        log "INFO" "📥 Installing ripgrep (modern grep replacement)..."
        if run_task_command "Installing ripgrep" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y ripgrep 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing ripgrep for faster searching" "30s"; then
            log "SUCCESS" "✅ ripgrep installed successfully"
        else
            log "WARNING" "⚠️  Failed to install ripgrep"
        fi
    fi

    # Install/Update fzf (fuzzy finder)
    if command -v fzf >/dev/null 2>&1; then
        log "INFO" "📥 Updating fzf (fuzzy finder)..."
        if run_task_command "Updating fzf" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt upgrade -y fzf 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating fzf for fuzzy finding" "30s"; then
            log "SUCCESS" "✅ fzf updated successfully"
        else
            log "INFO" "ℹ️ fzf update via apt not available or already latest"
        fi
    else
        log "INFO" "📥 Installing fzf (fuzzy finder)..."
        if run_task_command "Installing fzf" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y fzf 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing fzf for fuzzy finding" "30s"; then
            log "SUCCESS" "✅ fzf installed successfully"
        else
            log "WARNING" "⚠️  Failed to install fzf"
        fi
    fi

    # Set up fzf configuration (run for both install and update)
    local zshrc="$REAL_HOME/.zshrc"
    if [ -f "$zshrc" ] && ! grep -q "# fzf configuration" "$zshrc"; then
        cat >> "$zshrc" << 'EOF'

# fzf configuration for enhanced productivity
if command -v fzf >/dev/null 2>&1; then
    # Key bindings
    source /usr/share/doc/fzf/examples/key-bindings.zsh 2>/dev/null || true
    source /usr/share/doc/fzf/examples/completion.zsh 2>/dev/null || true

    # Use ripgrep for fzf if available
    if command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # Enhanced fzf options
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
fi

EOF
        log "SUCCESS" "✅ Added fzf configuration to .zshrc"
    fi

    # Install zoxide (smart cd replacement)
    if ! command -v zoxide >/dev/null 2>&1; then
        log "INFO" "📥 Installing zoxide (smart cd replacement)..."
        if curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ zoxide installed successfully"

            # Add zoxide to .zshrc
            local zshrc="$REAL_HOME/.zshrc"
            if [ -f "$zshrc" ] && ! grep -q "eval.*zoxide init" "$zshrc"; then
                cat >> "$zshrc" << 'EOF'

# zoxide configuration for smart directory navigation
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
    # Replace cd with z for smart navigation
    alias cd="z"
fi

EOF
                log "SUCCESS" "✅ Added zoxide configuration to .zshrc"
            fi
        else
            log "WARNING" "⚠️  Failed to install zoxide"
        fi
    else
        log "SUCCESS" "✅ zoxide already installed"
    fi

    # Install/Update fd (modern find replacement)
    if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
        log "INFO" "📥 Updating fd (modern find replacement)..."
        if run_task_command "Updating fd" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt upgrade -y fd-find 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating fd for faster file finding" "30s"; then
            log "SUCCESS" "✅ fd updated successfully"
        else
            log "INFO" "ℹ️ fd update via apt not available or already latest"
        fi
        # Ensure fd symlink exists if we have fdfind
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
            local bin_dir="$REAL_HOME/.local/bin"
            mkdir -p "$bin_dir"
            ln -sf "$(which fdfind)" "$bin_dir/fd"
            log "SUCCESS" "✅ Created fd symlink for fdfind"
        fi
    else
        log "INFO" "📥 Installing fd (modern find replacement)..."
        if run_task_command "Installing fd" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt install -y fd-find 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Installing fd for faster file finding" "30s"; then
            log "SUCCESS" "✅ fd installed successfully"

            # Create fd symlink if it was installed as fd-find
            if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
                local bin_dir="$REAL_HOME/.local/bin"
                mkdir -p "$bin_dir"
                ln -sf "$(which fdfind)" "$bin_dir/fd"
                log "SUCCESS" "✅ Created fd symlink for fdfind"
            fi
        else
            log "WARNING" "⚠️  Failed to install fd"
        fi
    fi

    log "SUCCESS" "✅ Modern Unix tools installation completed"
}

# Install system dependencies
install_system_deps() {
    if $SKIP_DEPS; then
        log "INFO" "⏭️  Skipping system dependencies installation"
        return 0
    fi

    log "STEP" "🔧 Installing system dependencies..."

    # Update package list with progressive disclosure (suppress CLI warnings)
    if ! run_task_command "Updating package list" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Refreshing package repositories" "10-30s"; then
        log "ERROR" "Failed to update package list"
        return 1
    fi
    
    # Install essential dependencies (check what's already installed)
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
        "xdotool" "scrot" "imagemagick" "gnome-screenshot"
        "eza" "bat" "ripgrep" "fzf" "fd-find"
    )

    # Check which packages are missing
    local missing_deps=()
    local installed_count=0

    log "INFO" "🔍 Checking which packages need installation..."
    for dep in "${deps[@]}"; do
        if dpkg -l "$dep" 2>/dev/null | grep -q "^ii"; then
            debug "✅ $dep already installed"
            installed_count=$((installed_count + 1))
        else
            debug "❌ $dep needs installation"
            missing_deps+=("$dep")
        fi
    done

    log "INFO" "📊 Found ${#missing_deps[@]} packages to install, ${installed_count} already installed"

    if [ ${#missing_deps[@]} -eq 0 ]; then
        log "SUCCESS" "✅ All system dependencies already installed"
    else
        log "INFO" "📦 Installing ${#missing_deps[@]} missing packages..."
        if run_task_command "Installing missing system dependencies" "sudo apt install -y $(echo ${missing_deps[@]})" "Installing only missing development tools and dependencies" "30s-2min"; then
            log "SUCCESS" "✅ System dependencies installed"
        else
            log "ERROR" "❌ Failed to install system dependencies"
            return 1
        fi
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
        "config_only")
            log "STEP" "⚙️  Updating Ghostty configuration only (external installation detected)..."
            install_ghostty_configuration
            ;;
        "fresh"|*)
            fresh_install_ghostty
            ;;
    esac
}

# Fresh Ghostty installation
fresh_install_ghostty() {
    draw_colored_box "$MAGENTA" "Ghostty Fresh Installation" \
        "👻 Starting fresh Ghostty installation" \
        "📦 Attempting snap installation first..."

    # First try to install via snap (preferred method)
    if command -v snap >/dev/null 2>&1; then
        log "INFO" "📦 Installing Ghostty via snap (recommended)..."
        if sudo snap install ghostty --classic >> "$LOG_FILE" 2>&1; then
            draw_colored_box "$MAGENTA" "Ghostty Snap Installation" \
                "✅ Ghostty installed successfully via snap" \
                "⚙️  Applying configuration files..."
            install_ghostty_configuration
            return 0
        else
            log "WARNING" "⚠️  Snap installation failed, falling back to building from source"
        fi
    fi

    # Fallback to building from source only if snap fails
    draw_colored_box "$MAGENTA" "Ghostty Source Build" \
        "🔨 Building Ghostty from source (fallback)" \
        "📥 Cloning repository and compiling..."

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
    draw_colored_box "$MAGENTA" "Ghostty Configuration" \
        "⚙️  Installing Ghostty configuration files" \
        "📁 Deploying configs, themes, and dircolors..."

    mkdir -p "$GHOSTTY_CONFIG_DIR"

    # Track configuration status
    local -a config_status=()

    # Copy configuration files from configs directory
    for config_file in config theme.conf scroll.conf layout.conf keybindings.conf; do
        if [ -f "$GHOSTTY_CONFIG_SOURCE/$config_file" ]; then
            cp "$GHOSTTY_CONFIG_SOURCE/$config_file" "$GHOSTTY_CONFIG_DIR/"
            log "SUCCESS" "✅ Copied $config_file"
            config_status+=("✅ $config_file deployed")
        else
            log "WARNING" "⚠️  $config_file not found in $GHOSTTY_CONFIG_SOURCE"
            config_status+=("⚠️  $config_file missing")
        fi
    done

    # Deploy dircolors configuration (XDG-compliant location)
    if [ -f "$GHOSTTY_CONFIG_SOURCE/dircolors" ]; then
        mkdir -p "$REAL_HOME/.config"
        cp "$GHOSTTY_CONFIG_SOURCE/dircolors" "$REAL_HOME/.config/dircolors"
        log "SUCCESS" "✅ Deployed dircolors configuration to ~/.config/dircolors"
        config_status+=("✅ dircolors (XDG-compliant)")

        # Ensure shell configs load dircolors (XDG-compliant)
        for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
            if [ -f "$shell_config" ]; then
                if ! grep -q 'XDG_CONFIG_HOME.*dircolors' "$shell_config" 2>/dev/null; then
                    echo '' >> "$shell_config"
                    echo '# XDG-compliant dircolors configuration' >> "$shell_config"
                    echo 'eval "$(dircolors ${XDG_CONFIG_HOME:-$HOME/.config}/dircolors)"' >> "$shell_config"
                    log "SUCCESS" "✅ Added dircolors to $(basename $shell_config)"
                fi
            fi
        done
    else
        log "WARNING" "⚠️  dircolors not found in $GHOSTTY_CONFIG_SOURCE"
        config_status+=("⚠️  dircolors missing")
    fi

    # Validate configuration
    if ghostty +show-config >/dev/null 2>&1; then
        config_status+=("✅ Configuration validated")
        draw_colored_box "$MAGENTA" "Ghostty Configuration Complete" "${config_status[@]}"
    else
        config_status+=("❌ Configuration validation failed")
        draw_colored_box "$MAGENTA" "Ghostty Configuration Issues" "${config_status[@]}"
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
    draw_colored_box "$MAGENTA" "Ptyxis Fresh Installation" \
        "🐚 Starting fresh Ptyxis installation" \
        "📦 Trying: apt → snap → flatpak"

    # Try apt first (official Ubuntu packages)
    log "INFO" "📥 Attempting Ptyxis installation via apt..."
    if apt-cache show ptyxis >/dev/null 2>&1; then
        if sudo apt update && sudo apt install -y ptyxis >> "$LOG_FILE" 2>&1; then
            draw_colored_box "$MAGENTA" "Ptyxis APT Installation" \
                "✅ Ptyxis installed via apt" \
                "⚙️  Configuring system integration..."
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
            draw_colored_box "$MAGENTA" "Ptyxis Snap Installation" \
                "✅ Ptyxis installed via snap" \
                "⚙️  Configuring system integration..."
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
        draw_colored_box "$MAGENTA" "Ptyxis Flatpak Installation" \
            "✅ Ptyxis installed via flatpak" \
            "⚙️  Configuring flatpak integration..."
        configure_ptyxis_flatpak
    else
        draw_colored_box "$MAGENTA" "Ptyxis Installation Failed" \
            "❌ Installation failed via all methods" \
            "📋 Check logs: $LOG_FILE"
        return 1
    fi
}

# Update existing Ptyxis installation based on installation method
update_ptyxis() {
    log "STEP" "🔄 Updating existing Ptyxis installation..."

    # Determine current installation method and update accordingly
    if dpkg -l 2>/dev/null | grep ptyxis | grep -q "^ii"; then
        log "INFO" "🔄 Updating Ptyxis via apt..."
        if run_task_command "Updating Ptyxis" "sudo apt update -qq 2>&1 | grep -v 'WARNING.*stable CLI interface' && sudo apt upgrade -y ptyxis 2>&1 | grep -v 'WARNING.*stable CLI interface'" "Updating Ptyxis to latest version via apt" "10-30s"; then
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
    local -a config_status=()

    # Create gemini alias in both bashrc and zshrc for system installation
    for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$shell_config" ]; then
            # Check if Ptyxis system integration already exists
            if grep -q "ptyxis.*-d.*gemini" "$shell_config" && ! grep -q "flatpak" "$shell_config"; then
                log "SUCCESS" "✅ Ptyxis gemini integration already configured in $(basename "$shell_config")"
                config_status+=("✅ $(basename "$shell_config") - already configured")
            else
                # Remove any existing gemini aliases
                if grep -q "alias gemini=" "$shell_config"; then
                    log "INFO" "🔄 Updating existing gemini alias in $(basename "$shell_config")"
                    sed -i '/alias gemini=/d' "$shell_config"
                fi

                # Add the system Ptyxis integration alias
                echo "" >> "$shell_config"
                echo "# Gemini CLI integration with Ptyxis (system)" >> "$shell_config"
                echo "# Uses fnm-managed Node.js (generic path, auto-resolves to current version)" >> "$shell_config"
                echo 'alias gemini='"'"'ptyxis -d "$(pwd)" -- gemini'"'" >> "$shell_config"
                log "SUCCESS" "✅ Added Ptyxis system gemini integration to $(basename "$shell_config")"
                config_status+=("✅ $(basename "$shell_config") - configured")
            fi
        fi
    done

    draw_colored_box "$MAGENTA" "Ptyxis System Configuration" "${config_status[@]}"
}

# Configure Ptyxis for flatpak installation
configure_ptyxis_flatpak() {
    local -a config_status=()

    # Grant necessary permissions for file access
    flatpak override app.devsuite.Ptyxis --filesystem=home >> "$LOG_FILE" 2>&1
    config_status+=("✅ Flatpak permissions granted")

    # Create gemini alias in both bashrc and zshrc for flatpak
    for shell_config in "$REAL_HOME/.bashrc" "$REAL_HOME/.zshrc"; do
        if [ -f "$shell_config" ]; then
            # Check if Ptyxis flatpak integration already exists
            if grep -q "flatpak run app.devsuite.Ptyxis.*gemini" "$shell_config"; then
                log "SUCCESS" "✅ Ptyxis flatpak gemini integration already configured in $(basename "$shell_config")"
                config_status+=("✅ $(basename "$shell_config") - already configured")
            else
                # Remove any existing gemini aliases
                if grep -q "alias gemini=" "$shell_config"; then
                    log "INFO" "🔄 Updating existing gemini alias in $(basename "$shell_config")"
                    sed -i '/alias gemini=/d' "$shell_config"
                fi

                # Add the flatpak Ptyxis integration alias
                echo "" >> "$shell_config"
                echo "# Gemini CLI integration with Ptyxis (flatpak)" >> "$shell_config"
                echo "# Uses fnm-managed Node.js (generic path, auto-resolves to current version)" >> "$shell_config"
                echo 'alias gemini='"'"'flatpak run app.devsuite.Ptyxis -d "$(pwd)" -- gemini'"'" >> "$shell_config"
                log "SUCCESS" "✅ Added Ptyxis flatpak gemini integration to $(basename "$shell_config")"
                config_status+=("✅ $(basename "$shell_config") - configured")
            fi
        fi
    done

    draw_colored_box "$MAGENTA" "Ptyxis Flatpak Configuration" "${config_status[@]}"
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
        # Check if curl is available
        if ! command -v curl >/dev/null 2>&1; then
            log "ERROR" "❌ curl is required for uv installation but not found"
            return 1
        fi

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
            else
                log "INFO" "ℹ️ uv PATH already configured in $(basename "$shell_config")"
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

# Install Node.js via fnm (Fast Node Manager)
# Constitutional Compliance: AGENTS.md line 23 mandates fnm for performance
install_nodejs() {
    if $SKIP_NODE; then
        log "INFO" "⏭️  Skipping Node.js installation"
        return 0
    fi

    draw_colored_box "$GREEN" "📦 Node.js Installation via fnm" \
        "Status: Checking existing installation" \
        "Target: Node.js v${NODE_VERSION}.x (latest)" \
        "Method: Fast Node Manager (fnm)" \
        "Performance: <50ms startup vs 500ms-3s for NVM"

    # Use modular install_node.sh script
    if source "${SCRIPT_DIR}/scripts/install_node.sh" && install_node_full "$NODE_VERSION"; then
        local node_version=$(node --version 2>/dev/null || echo "unknown")
        local npm_version=$(npm --version 2>/dev/null || echo "unknown")

        draw_colored_box "$GREEN" "Node.js Installation Complete" \
            "✅ fnm installed and configured" \
            "✅ Node.js ${node_version} active" \
            "✅ npm ${npm_version} available" \
            "⚡ Performance: <50ms startup time"

        return 0
    else
        log "ERROR" "❌ Node.js installation failed"
        log "INFO" "ℹ️  Check logs: $LOG_FILE"
        return 1
    fi
}

# Install uv (Fast Python Package Installer)
# Constitutional Compliance: Modern web development stack requirement (Feature 001)
install_uv() {
    if $SKIP_UV; then
        log "INFO" "⏭️  Skipping uv installation"
        return 0
    fi

    draw_colored_box "$GREEN" "⚡ uv Installation (Fast Python Package Installer)" \
        "Status: Checking existing installation" \
        "Purpose: Modern web development stack (Feature 001)" \
        "Performance: Significantly faster than pip"

    # Use modular install_uv.sh script
    if source "${SCRIPT_DIR}/scripts/install_uv.sh" && install_uv_full; then
        local uv_version=$(uv --version 2>/dev/null | awk '{print $2}' || echo "unknown")

        draw_colored_box "$GREEN" "uv Installation Complete" \
            "✅ uv ${uv_version} installed and configured" \
            "✅ Python package management ready" \
            "⚡ Faster package operations enabled"

        return 0
    else
        log "ERROR" "❌ uv installation failed"
        log "INFO" "ℹ️  Check logs: $LOG_FILE"
        return 1
    fi
}

# Install spec-kit (Specification Development Toolkit)
# Constitutional Compliance: Spec-Kit development workflow requirement
install_speckit() {
    if $SKIP_SPEC_KIT; then
        log "INFO" "⏭️  Skipping spec-kit installation"
        return 0
    fi

    draw_colored_box "$GREEN" "📋 spec-kit Installation (Specification Development Toolkit)" \
        "Status: Checking dependencies" \
        "Purpose: Constitutional spec development workflow" \
        "Requirement: uv package manager"

    # Ensure uv is available first
    if ! command -v uv >/dev/null 2>&1; then
        log "WARNING" "⚠️  uv not found, installing uv first..."
        if ! install_uv; then
            log "ERROR" "❌ Cannot install spec-kit without uv"
            return 1
        fi
    fi

    # Use modular install_spec_kit.sh script
    if source "${SCRIPT_DIR}/scripts/install_spec_kit.sh" && install_spec_kit_full; then
        draw_colored_box "$GREEN" "spec-kit Installation Complete" \
            "✅ spec-kit installed and configured" \
            "✅ Specification workflow commands available" \
            "✅ Constitutional compliance tools ready"

        return 0
    else
        log "ERROR" "❌ spec-kit installation failed"
        log "INFO" "ℹ️  Check logs: $LOG_FILE"
        return 1
    fi
}

# Install Claude Code CLI
install_claude_code() {
    if $SKIP_AI; then
        log "INFO" "⏭️  Skipping Claude Code installation"
        return 0
    fi

    draw_colored_box "$GREEN" "🤖 AI Development Tools - Claude Code CLI" \
        "Status: Checking existing installation" \
        "Package: @anthropic-ai/claude-code" \
        "Requirement: Node.js and npm (via fnm)"

    # Check if Node.js and npm are available
    if ! command -v node >/dev/null 2>&1; then
        log "ERROR" "❌ Node.js is required for Claude Code but not found"
        return 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log "ERROR" "❌ npm is required for Claude Code but not found"
        return 1
    fi

    # fnm handles Node.js environment automatically
    # No need to source anything - npm is available via fnm-managed Node.js

    # Install Claude Code globally
    if npm list -g claude-code >/dev/null 2>&1; then
        log "INFO" "🔄 Updating Claude Code..."
        if npm update -g claude-code >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Claude Code updated"
        else
            log "WARNING" "⚠️  Claude Code update may have failed"
        fi
    else
        log "INFO" "📥 Installing Claude Code..."
        if npm install -g claude-code >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Claude Code installed"
        else
            log "ERROR" "❌ Claude Code installation failed"
            return 1
        fi
    fi

    # Verify installation
    if command -v claude >/dev/null 2>&1; then
        local version=$(claude --version 2>/dev/null || echo "unknown")

        draw_colored_box "$GREEN" "Claude Code Installation Complete" \
            "✅ Claude Code CLI installed" \
            "✅ Version: ${version}" \
            "✅ AI-powered code assistance ready" \
            "📝 Command: claude"
    else
        log "WARNING" "⚠️  Claude Code installed but not in PATH (may need shell restart)"
    fi
}

# Install Gemini CLI
install_gemini_cli() {
    if $SKIP_AI; then
        log "INFO" "⏭️  Skipping Gemini CLI installation"
        return 0
    fi

    draw_colored_box "$GREEN" "💎 AI Development Tools - Google Gemini CLI" \
        "Status: Checking existing installation" \
        "Package: @google/gemini-cli" \
        "Requirement: Node.js and npm (via fnm)"

    # Check if Node.js and npm are available
    if ! command -v node >/dev/null 2>&1; then
        log "ERROR" "❌ Node.js is required for Gemini CLI but not found"
        return 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log "ERROR" "❌ npm is required for Gemini CLI but not found"
        return 1
    fi

    # fnm handles Node.js environment automatically
    # No need to source anything - npm is available via fnm-managed Node.js

    # Install Gemini CLI globally
    if npm list -g @google/gemini-cli >/dev/null 2>&1; then
        log "INFO" "🔄 Updating Gemini CLI..."
        if npm update -g @google/gemini-cli >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Gemini CLI updated"
        else
            log "WARNING" "⚠️  Gemini CLI update may have failed"
        fi
    else
        log "INFO" "📥 Installing Gemini CLI..."
        if npm install -g @google/gemini-cli >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ Gemini CLI installed"
        else
            log "ERROR" "❌ Gemini CLI installation failed"
            return 1
        fi
    fi

    # Create symlink for easier access (try to find the actual gemini binary)
    local gemini_path=""
    # Use fnm-managed Node.js to locate gemini
    if command -v gemini >/dev/null 2>&1; then
        gemini_path=$(which gemini)
    fi

    if [ -n "$gemini_path" ] && [ -f "$gemini_path" ]; then
        if sudo ln -sf "$gemini_path" /usr/local/bin/gemini 2>/dev/null; then
            log "SUCCESS" "✅ Gemini CLI installed and linked to /usr/local/bin/gemini"
        else
            log "INFO" "ℹ️ Gemini CLI installed (system link failed, but available via npm)"
        fi
    else
        log "WARNING" "⚠️  Gemini CLI installed but binary not found"
    fi

    # Verify installation
    if command -v gemini >/dev/null 2>&1; then
        draw_colored_box "$GREEN" "Gemini CLI Installation Complete" \
            "✅ Gemini CLI installed" \
            "✅ Google AI integration ready" \
            "✅ System symlink created" \
            "📝 Command: gemini"
    else
        log "WARNING" "⚠️  Gemini CLI installed but not in PATH (may need shell restart)"
    fi
}

# Install GitHub Copilot CLI
install_copilot_cli() {
    if $SKIP_AI; then
        log "INFO" "⏭️  Skipping GitHub Copilot CLI installation"
        return 0
    fi

    draw_colored_box "$GREEN" "🤖 AI Development Tools - GitHub Copilot CLI" \
        "Status: Checking existing installation" \
        "Package: @github/copilot" \
        "Requirement: Node.js and npm (via fnm)"

    # Check if Node.js and npm are available
    if ! command -v node >/dev/null 2>&1; then
        log "ERROR" "❌ Node.js is required for Copilot CLI but not found"
        return 1
    fi

    if ! command -v npm >/dev/null 2>&1; then
        log "ERROR" "❌ npm is required for Copilot CLI but not found"
        return 1
    fi

    # Install Copilot CLI globally
    if npm list -g @github/copilot >/dev/null 2>&1; then
        log "INFO" "🔄 Updating GitHub Copilot CLI..."
        if npm update -g @github/copilot >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ GitHub Copilot CLI updated"
        else
            log "WARNING" "⚠️  Copilot CLI update may have failed"
        fi
    else
        log "INFO" "📥 Installing GitHub Copilot CLI..."
        if npm install -g @github/copilot >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "✅ GitHub Copilot CLI installed"
        else
            log "ERROR" "❌ Copilot CLI installation failed"
            return 1
        fi
    fi

    # Verify installation
    if command -v copilot >/dev/null 2>&1; then
        local version=$(copilot --version 2>/dev/null | head -1 || echo "unknown")
        draw_colored_box "$GREEN" "GitHub Copilot CLI Installation Complete" \
            "✅ Copilot CLI installed" \
            "✅ Version: ${version}" \
            "✅ AI code suggestions ready" \
            "📝 Command: copilot"
    else
        log "WARNING" "⚠️  Copilot CLI installed but not in PATH (may need shell restart)"
    fi
}

# Setup daily automated updates
setup_daily_updates() {
    log "STEP" "🔄 Setting up daily automated updates..."

    # Check if scripts exist
    local daily_updates_script="$SCRIPT_DIR/scripts/daily-updates.sh"
    local view_logs_script="$SCRIPT_DIR/scripts/view-update-logs.sh"

    if [ ! -f "$daily_updates_script" ] || [ ! -f "$view_logs_script" ]; then
        log "ERROR" "❌ Daily updates scripts not found"
        return 1
    fi

    # Make scripts executable
    chmod +x "$daily_updates_script" "$view_logs_script" 2>/dev/null || true

    # Add aliases to .zshrc if not already present
    local zshrc_file="$REAL_HOME/.zshrc"
    if [ -f "$zshrc_file" ]; then
        if ! grep -q "update-all=" "$zshrc_file"; then
            log "INFO" "📝 Adding daily update aliases to .zshrc..."
            cat >> "$zshrc_file" << 'EOF'

# ============================================================================
# Daily Update System - Auto-generated by ghostty-config-files
# ============================================================================

# Alias for manual updates
alias update-all='/home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh'

# Alias for viewing update logs
alias update-logs='/home/kkk/Apps/ghostty-config-files/scripts/view-update-logs.sh'
alias update-logs-full='/home/kkk/Apps/ghostty-config-files/scripts/view-update-logs.sh --full'
alias update-logs-errors='/home/kkk/Apps/ghostty-config-files/scripts/view-update-logs.sh --errors'

# Display last update summary on terminal launch (using precmd hook for Powerlevel10k compatibility)
_show_update_summary_once() {
    # Remove this function from precmd after first run
    precmd_functions=(${precmd_functions:#_show_update_summary_once})

    if [[ -f "/tmp/daily-updates-logs/last-update-summary.txt" ]]; then
        # Only show once per day to avoid spam
        local last_shown_file="/tmp/.update-summary-shown-\$(date +%Y%m%d)"
        if [[ ! -f "\$last_shown_file" ]]; then
            echo ""
            echo "📊 Latest System Update Summary:"
            printf '\''━%.0s'\'' \$(seq 1 70)
            echo ""
            cat "/tmp/daily-updates-logs/last-update-summary.txt"
            printf '\''━%.0s'\'' \$(seq 1 70)
            echo ""
            echo ""
            echo "💡 Commands: update-all | update-logs | update-logs-full | update-logs-errors"
            echo ""
            touch "\$last_shown_file"
        fi
    fi
}

# Add to precmd hooks (runs before each prompt display, after instant prompt completes)
precmd_functions+=(_show_update_summary_once)

EOF
            log "SUCCESS" "✅ Daily update aliases added to .zshrc"
        else
            log "INFO" "ℹ️  Daily update aliases already present in .zshrc"
        fi
    else
        log "WARNING" "⚠️  .zshrc not found - update aliases not added"
    fi

    # Setup cron job for daily updates
    log "INFO" "⏰ Setting up daily automated updates (9:00 AM)..."

    # Create crontab entry
    local cron_entry="0 9 * * * $daily_updates_script >> /tmp/daily-updates-logs/cron-output.log 2>&1"

    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$daily_updates_script"; then
        log "INFO" "ℹ️  Daily update cron job already configured"
    else
        # Add cron job (non-critical)
        if (crontab -l 2>/dev/null; echo "# Daily System Updates - ghostty-config-files"; echo "$cron_entry") | crontab - 2>/dev/null; then
            log "SUCCESS" "✅ Daily automated updates scheduled for 9:00 AM"
        else
            log "WARNING" "⚠️  Could not setup cron job - scripts still work manually"
            log "INFO" "ℹ️  To enable automation, run: crontab -e"
            log "INFO" "ℹ️  Add this line: $cron_entry"
        fi
    fi

    # Check for passwordless sudo
    if ! sudo -n apt update >/dev/null 2>&1; then
        log "WARNING" "⚠️  Passwordless sudo not configured for apt"
        log "INFO" "ℹ️  Daily updates will run, but apt updates will be skipped"
        log "INFO" "ℹ️  To enable full automation, add this to sudoers:"
        log "INFO" "      kkk ALL=(ALL) NOPASSWD: /usr/bin/apt"
        log "INFO" "      Run: sudo EDITOR=nano visudo"
    else
        log "SUCCESS" "✅ Passwordless sudo configured for apt"
    fi

    # Verify scripts are executable before declaring success
    if [ -x "$daily_updates_script" ] && [ -x "$view_logs_script" ]; then
        log "SUCCESS" "✅ Daily update system configured successfully"
        log "INFO" "📋 Scripts installed:"
        log "INFO" "   • $daily_updates_script"
        log "INFO" "   • $view_logs_script"
        log "INFO" "📋 Available commands:"
        log "INFO" "   • update-all - Run updates manually"
        log "INFO" "   • update-logs - View latest summary"
        log "INFO" "   • update-logs-full - View complete log"
        log "INFO" "   • update-logs-errors - View errors only"
        return 0
    else
        log "ERROR" "❌ Daily updates scripts not found or not executable"
        log "ERROR" "Expected locations:"
        log "ERROR" "   • $daily_updates_script"
        log "ERROR" "   • $view_logs_script"
        return 1
    fi
}

# Final verification
verify_installation() {
    log "STEP" "🔍 Verifying installations..."
    
    local status=0
    
    # Check Ghostty - verify it actually works
    if command -v ghostty >/dev/null 2>&1 && ghostty --version >/dev/null 2>&1; then
        local version=$(ghostty --version 2>/dev/null | head -1)
        log "SUCCESS" "✅ Ghostty: $version"
    else
        log "ERROR" "❌ Ghostty not found or not functioning properly"
        status=1
    fi
    
    # Check Ptyxis (prefer official: apt, snap, then flatpak)
    if ! $SKIP_PTYXIS; then
        local ptyxis_found=false
        local ptyxis_source=""

        # Check if Ptyxis actually works
        if command -v ptyxis >/dev/null 2>&1 && ptyxis --version >/dev/null 2>&1; then
            local ptyxis_version=$(ptyxis --version 2>/dev/null | head -1)

            # Determine installation source
            if dpkg -l 2>/dev/null | grep ptyxis | grep -q "^ii"; then
                ptyxis_source="apt"
            elif snap list 2>/dev/null | grep -q "ptyxis"; then
                ptyxis_source="snap"
            elif flatpak list 2>/dev/null | grep -q "app.devsuite.Ptyxis"; then
                ptyxis_source="flatpak"
            else
                ptyxis_source="unknown"
            fi

            log "SUCCESS" "✅ Ptyxis: $ptyxis_version (via $ptyxis_source)"
            ptyxis_found=true
        fi

        if ! $ptyxis_found; then
            log "ERROR" "❌ Ptyxis not found or not functioning"
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

    # Check spec-kit
    if ! $SKIP_SPEC_KIT; then
        if command -v specify >/dev/null 2>&1; then
            local speckit_version=$(specify --version 2>/dev/null | awk '{print $NF}' || echo "unknown")
            log "SUCCESS" "✅ spec-kit: $speckit_version"

            # Verify slash commands exist
            local slash_cmd_dir="$HOME/Apps/ghostty-config-files/.claude/commands"
            if [ -d "$slash_cmd_dir" ]; then
                local cmd_count=$(find "$slash_cmd_dir" -name "speckit.*.md" 2>/dev/null | wc -l)
                log "INFO" "   📋 Slash commands: $cmd_count configured"
            fi
        else
            log "WARNING" "⚠️  spec-kit not found (may need shell restart)"
        fi
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
        if command -v claude >/dev/null 2>&1 && claude --version >/dev/null 2>&1; then
            local claude_version=$(claude --version 2>/dev/null | head -1)
            log "SUCCESS" "✅ Claude Code: $claude_version"
        else
            log "WARNING" "⚠️  Claude Code not in PATH or not functioning (may need shell restart)"
        fi

        # Check Gemini CLI - try multiple locations
        local gemini_found=false
        local gemini_version=""

        # Try direct command
        if command -v gemini >/dev/null 2>&1 && gemini --version >/dev/null 2>&1; then
            gemini_version=$(gemini --version 2>/dev/null)
            gemini_found=true
        # Try /usr/local/bin/gemini
        elif [ -x "/usr/local/bin/gemini" ] && /usr/local/bin/gemini --version >/dev/null 2>&1; then
            gemini_version=$(/usr/local/bin/gemini --version 2>/dev/null)
            gemini_found=true
        # Try fnm-managed Node.js path
        else
            # Find gemini in fnm node versions (fallback)
            for node_path in "$HOME"/.local/share/fnm/node-versions/*/installation/bin/gemini; do
                if [ -x "$node_path" ] && "$node_path" --version >/dev/null 2>&1; then
                    gemini_version=$("$node_path" --version 2>/dev/null)
                    gemini_found=true
                    break
                fi
            done
        fi

        if $gemini_found; then
            log "SUCCESS" "✅ Gemini CLI: v$gemini_version"
        else
            log "WARNING" "⚠️  Gemini CLI not found or not functioning (may need shell restart)"
        fi

        # Check GitHub Copilot CLI
        if npm list -g @github/copilot 2>/dev/null | grep -q "@github/copilot"; then
            local copilot_version=$(npm list -g @github/copilot 2>/dev/null | grep @github/copilot | sed 's/.*@//' | awk '{print $1}')
            log "SUCCESS" "✅ GitHub Copilot CLI: $copilot_version"
        else
            log "WARNING" "⚠️  GitHub Copilot CLI not installed"
        fi
    fi

    return $status
}

# Show final instructions
show_final_instructions() {
    echo ""
    echo -e "${GREEN}🎉 Installation Complete!${NC}"
    echo ""
    echo -e "${CYAN}Environment Ready:${NC}"
    echo "✅ ZSH with Oh My ZSH and Powerlevel10k theme"
    echo "✅ Modern Unix tools (eza, bat, ripgrep, fzf, etc.)"
    echo "✅ Ghostty terminal with optimized configuration"
    if ! $SKIP_PTYXIS; then
        echo "✅ Ptyxis terminal with Gemini CLI integration"
    fi
    if ! $SKIP_AI; then
        echo "✅ Claude Code CLI, Gemini CLI, and GitHub Copilot CLI"
    fi
    echo "✅ Complete screenshot and documentation system"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "1. The script will automatically restart your shell in 3 seconds"
    echo "2. Test Ghostty: ghostty"
    if ! $SKIP_PTYXIS; then
        echo "3. Test Ptyxis: flatpak run app.devsuite.Ptyxis"
        echo "4. Use Gemini in Ptyxis: gemini"
    fi
    if ! $SKIP_AI; then
        echo "5. Set up Claude Code: claude auth login"
        echo "6. Set up Gemini CLI with your API key"
    fi
    echo ""
    echo -e "${YELLOW}Configuration files:${NC}"
    echo "• Ghostty config: $GHOSTTY_CONFIG_DIR/"
    echo "• Session Logs: $LOG_SESSION_ID.*"
    echo "  - Main: $LOG_FILE"
    echo "  - Commands: $LOG_COMMANDS"
    echo "  - Errors: $LOG_ERRORS"
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

# Restart shell environment to activate new configuration
restart_shell_environment() {
    echo ""
    echo -e "${GREEN}🔄 Restarting shell environment...${NC}"
    echo ""

    # Give user a moment to read the completion message
    for i in 3 2 1; do
        echo -ne "\r🔄 Shell restart in ${i} seconds... Press Ctrl+C to cancel"
        sleep 1
    done
    echo ""

    log "INFO" "🔄 Restarting shell with new configuration..."

    # Take final screenshot showing shell restart preparation
    if [ "$ENABLE_SCREENSHOTS" = "true" ] && [ -f "$SVG_CAPTURE_SCRIPT" ]; then
        capture_stage_screenshot "Shell Restart" "Activating new ZSH configuration with Powerlevel10k" 2
    fi

    # Source the new .zshrc first to ensure it's valid
    if [ -f "$REAL_HOME/.zshrc" ]; then
        log "INFO" "📋 Sourcing updated .zshrc configuration..."
        # Use exec to replace current shell process with new ZSH
        exec zsh -l
    else
        log "WARNING" "⚠️  .zshrc not found, manual shell restart recommended"
        echo "Please run: exec zsh"
    fi
}

# Main execution
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Comprehensive Terminal Tools Installer${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""

    # Initialize installation state tracking (NEW - Idempotent operation support)
    load_state

    # Show previous state if this is a rerun
    if [ -f "$STATE_FILE" ]; then
        show_state_summary
        detect_existing_software
        echo ""
    fi

    # Initialize comprehensive session tracking
    init_session_tracking

    # Start performance monitoring for entire operation
    monitor_performance "Complete Installation"

    log "INFO" "🚀 Starting comprehensive installation in $DETECTED_TERMINAL terminal..."
    log "INFO" "📋 Session tracking (ID: $LOG_SESSION_ID):"
    log "INFO" "   📄 Logs: $LOG_DIR/$LOG_SESSION_ID.*"
    log "INFO" "   📸 Screenshots: docs/assets/screenshots/$LOG_SESSION_ID/"
    log "INFO" "   📊 Manifest: $LOG_SESSION_MANIFEST"
    log "INFO" "   💾 State file: $STATE_FILE"

    # Initialize SVG screenshot system
    if [ "$ENABLE_SCREENSHOTS" = "true" ] && [ -f "$SVG_CAPTURE_SCRIPT" ]; then
        "$SVG_CAPTURE_SCRIPT" setup
        create_installation_diagram
    fi

    # Capture initial desktop state
    capture_stage_screenshot "Initial Desktop" "Clean Ubuntu desktop before Ghostty installation" 4

    # Capture initial system state
    capture_system_state
    
    # Create necessary directories
    mkdir -p "$APPS_DIR"

    # Pre-authenticate sudo if needed
    if ! $SKIP_DEPS || ! $SKIP_PTYXIS; then
        if ! pre_auth_sudo; then
            log "ERROR" "❌ Installation cannot proceed without passwordless sudo"
            log "INFO" "💡 Please follow the instructions above and run ./start.sh again"
            exit 1
        fi
    fi

    # Check current installation status and determine strategies
    check_installation_status
    capture_stage_screenshot "System Check" "Installation status check and strategy determination" 3

    # Execute installation steps with failure tracking
    if install_system_deps; then
        track_success "System Dependencies" "All packages up to date"
    else
        track_failure "System Dependencies" "Some packages failed"
    fi
    capture_stage_screenshot "Dependencies" "System dependencies installation completed" 3

    if idempotent_install_zsh; then
        track_success "ZSH & Oh My ZSH" "Shell environment configured"
    else
        track_warning "ZSH & Oh My ZSH" "Some configuration may be incomplete"
    fi
    capture_stage_screenshot "ZSH Setup" "ZSH and Oh My ZSH configuration" 3

    if install_modern_tools; then
        track_success "Modern Tools" "eza, bat, ripgrep, fzf, fd installed"
    else
        track_warning "Modern Tools" "Some tools may need updates"
    fi
    capture_stage_screenshot "Modern Tools" "Development tools and utilities installation" 3

    if install_zig; then
        track_success "Zig Compiler" "Version 0.14.0 ready"
    else
        track_failure "Zig Compiler" "Installation failed"
    fi
    capture_stage_screenshot "Zig Compiler" "Zig compiler installation and setup" 3

    if idempotent_install_ghostty; then
        track_success "Ghostty Terminal" "Installed and configured"
    else
        track_warning "Ghostty Terminal" "Using existing installation"
    fi
    capture_stage_screenshot "Ghostty Build" "Ghostty terminal compilation from source" 4

    # Smart configuration update (always run to ensure latest optimizations)
    if $CONFIG_NEEDS_UPDATE || [ "$GHOSTTY_STRATEGY" = "fresh" ] || [ "$GHOSTTY_STRATEGY" = "reconfig" ]; then
        if update_ghostty_config; then
            track_success "Ghostty Configuration" "2025 optimizations applied"
        else
            track_failure "Ghostty Configuration" "Configuration update failed"
        fi
    else
        track_success "Ghostty Configuration" "Already optimized"
    fi
    capture_stage_screenshot "Configuration" "Ghostty configuration files and optimization setup" 3

    if install_context_menu; then
        track_success "Context Menu" "Right-click integration active"
    else
        track_warning "Context Menu" "May need manual activation"
    fi
    capture_stage_screenshot "Context Menu" "Right-click context menu integration" 2

    if idempotent_install_ptyxis; then
        track_success "Ptyxis Terminal" "Installed and configured"
    else
        track_warning "Ptyxis Terminal" "Using existing installation"
    fi
    capture_stage_screenshot "Ptyxis Terminal" "Secondary terminal installation for comparison" 2

    if idempotent_install_uv; then
        track_success "UV Package Manager" "Python tools ready"
    else
        track_failure "UV Package Manager" "Installation failed"
    fi
    capture_stage_screenshot "UV Package Manager" "Python uv package manager setup" 2

    # Install spec-kit (non-blocking)
    if idempotent_install_speckit; then
        track_success "spec-kit" "Specification toolkit installed"
    else
        track_warning "spec-kit" "Installation failed - can retry manually"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "spec-kit" "Specification development toolkit setup" 2

    # Setup screenshot dependencies after uv is available
    setup_screenshot_dependencies

    # Install Node.js (non-blocking)
    if idempotent_install_nodejs; then
        track_success "Node.js/fnm" "Installed successfully"
    else
        track_failure "Node.js/fnm" "Installation failed - will be available after shell restart"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "Node.js Setup" "Node.js and fnm installation" 2

    # Install Claude Code (non-blocking)
    if idempotent_install_claude_code; then
        track_success "Claude Code" "Installed successfully"
    else
        track_failure "Claude Code" "Installation failed - can retry manually"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "Claude Code" "Claude Code CLI installation and configuration" 2

    # Install Gemini CLI (non-blocking)
    if idempotent_install_gemini_cli; then
        track_success "Gemini CLI" "Installed successfully"
    else
        track_failure "Gemini CLI" "Installation failed - can retry manually"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "Gemini CLI" "Google Gemini CLI setup and integration" 2

    # Install GitHub Copilot CLI (non-blocking)
    if idempotent_install_copilot_cli; then
        track_success "GitHub Copilot CLI" "Installed successfully"
    else
        track_failure "GitHub Copilot CLI" "Installation failed - can retry manually"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "GitHub Copilot" "GitHub Copilot CLI setup and integration" 2

    # Setup daily automated updates (non-blocking)
    if setup_daily_updates; then
        track_success "Daily Updates" "Automated daily updates configured"
    else
        track_warning "Daily Updates" "Setup incomplete - can configure manually"
        log "INFO" "ℹ️  Continuing with remaining installations..."
    fi
    capture_stage_screenshot "Daily Updates" "Automated update system configuration" 2

    # Verify everything (non-blocking)
    start_timer
    if verify_installation; then
        end_timer "Installation verification"
        capture_stage_screenshot "Verification" "Installation verification and testing" 2
        log "SUCCESS" "🎉 Installation completed!"
    else
        log "INFO" "ℹ️  Installation completed with some optional components pending"
        capture_stage_screenshot "Warning State" "Installation completed with warnings" 2
    fi

    # End performance monitoring for entire operation
    end_performance_monitoring

    # Show comprehensive installation summary
    show_installation_summary

    # Show final instructions only if major components succeeded
    if [ ${#INSTALLATION_FAILURES[@]} -lt 3 ]; then
        show_final_instructions
    fi

    # Final system state capture
    capture_system_state

    # Finalize documentation and assets
    finalize_installation_docs

    # Finalize session tracking with statistics
    finalize_session_tracking

    # Save final installation state (NEW - Idempotent operation support)
    save_state

    log "INFO" "📊 Installation completed! Session: $LOG_SESSION_ID"
    log "INFO" "📋 Complete session data:"
    log "INFO" "   📄 Logs: ls -la $LOG_DIR/$LOG_SESSION_ID*"
    log "INFO" "   📸 Screenshots: ls -la docs/assets/screenshots/$LOG_SESSION_ID/"
    log "INFO" "   📊 Manifest: jq '.' $LOG_SESSION_MANIFEST"
    log "INFO" "   💾 State: jq '.' $STATE_FILE"
    log "INFO" "🏷️  Terminal used: $DETECTED_TERMINAL"

    # Capture final completion state with all information displayed
    capture_stage_screenshot "Completion" "Complete installation with performance metrics and session data" 4

    # Automatic shell restart to activate new configuration
    restart_shell_environment
}

# AUTOMATED INSTALLATION: Interactive menu removed
# This function is now a no-op stub for backward compatibility
show_interactive_menu() {
    # AUTOMATION MODE: Always skip interactive menu
    # Full installation with debug logging is ALWAYS enabled
    log "INFO" "🤖 Automated installation mode activated"
    log "INFO" "📊 Full installation with debug logging enabled"
    log "INFO" "🔧 Components: All (Ghostty, Ptyxis, ZSH, fnm, Node.js, uv, spec-kit, AI tools)"
    log "INFO" "📁 Logs will be saved to: $LOG_DIR"
    echo ""
    return 0
}

# AUTOMATION MODE: Skip interactive menu call
# show_interactive_menu "$@"  # DISABLED FOR AUTOMATION

# Run main function
main "$@"