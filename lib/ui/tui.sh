#!/usr/bin/env bash
#
# lib/ui/tui.sh - gum integration wrapper with graceful degradation
#
# CONTEXT7 STATUS: Unable to query (API authentication issue)
# FALLBACK: Best practices from TUI framework integration 2025
# - gum (Charm Bracelet) integration for spinners, prompts, styling
# - Graceful degradation to plain text if gum unavailable
# - TUI capability detection
#
# Constitutional Compliance: Principle I - TUI Framework Standard (gum exclusive)
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${TUI_SH_LOADED:-}" ] || return 0
TUI_SH_LOADED=1

# Source utility and logging modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/utils.sh"
source "${SCRIPT_DIR}/../core/logging.sh"

# Global TUI availability flag
TUI_AVAILABLE=false
GUM_VERSION=""
GUM_STARTUP_MS=0

#
# Initialize TUI system
#
# Detects gum availability, measures performance, sets TUI_AVAILABLE flag
#
# Usage: init_tui
#
init_tui() {
    log "INFO" "Initializing TUI system"

    # Check if gum is available
    if command_exists "gum"; then
        TUI_AVAILABLE=true

        # Get gum version
        GUM_VERSION=$(gum --version 2>&1 | grep -oP 'v\d+\.\d+\.\d+' || echo "unknown")

        # Measure gum startup time (nanosecond precision)
        local start_ns end_ns duration_ns
        start_ns=$(date +%s%N)
        gum --version >/dev/null 2>&1
        end_ns=$(date +%s%N)
        duration_ns=$((end_ns - start_ns))
        GUM_STARTUP_MS=$((duration_ns / 1000000))

        log "SUCCESS" "gum TUI framework detected: $GUM_VERSION (startup: ${GUM_STARTUP_MS}ms)"

        # Constitutional compliance check (<10ms target)
        if [ "$GUM_STARTUP_MS" -lt 10 ]; then
            log "SUCCESS" "✓ CONSTITUTIONAL COMPLIANCE: gum startup ${GUM_STARTUP_MS}ms (<10ms requirement MET)"
        else
            log "WARNING" "⚠ gum startup ${GUM_STARTUP_MS}ms exceeds 10ms target (acceptable, not blocking)"
        fi
    else
        TUI_AVAILABLE=false
        log "WARNING" "gum not found - using plain text fallback"
        log "INFO" "Install gum for enhanced TUI: https://github.com/charmbracelet/gum"
    fi
}

#
# Show spinner while running command (gum wrapper)
#
# Arguments:
#   $1 - Title/message to show
#   $2 - Command to execute (string, will be eval'd)
#
# Returns:
#   Exit code from command
#
# Usage:
#   show_spinner "Installing Ghostty..." "zig build -Doptimize=ReleaseFast"
#
show_spinner() {
    local title="$1"
    local command="$2"

    if [ "$TUI_AVAILABLE" = true ]; then
        # Use gum spinner
        gum spin --spinner dot --title "$title" -- bash -c "$command"
    else
        # Fallback: simple echo + command
        echo "⠋ $title"
        eval "$command"
    fi
}

#
# Show progress indicator (gum wrapper)
#
# Arguments:
#   $1 - Total items
#   $2 - Current item
#   $3 - Title/message
#
# Usage:
#   show_progress 10 3 "Installing dependencies"
#
show_progress() {
    local total="$1"
    local current="$2"
    local title="$3"
    local percentage

    percentage=$(( (current * 100) / total ))

    if [ "$TUI_AVAILABLE" = true ]; then
        # Use gum style for progress
        gum style --foreground 212 "[$current/$total] $title ($percentage%)"
    else
        # Fallback: simple echo
        echo "[$current/$total] $title ($percentage%)"
    fi
}

#
# Show confirmation prompt (gum wrapper)
#
# Arguments:
#   $1 - Prompt message
#
# Returns:
#   0 if user confirmed (yes), 1 if declined (no)
#
# Usage:
#   if show_confirm "Install Ghostty?"; then
#       echo "User confirmed"
#   fi
#
show_confirm() {
    local prompt="$1"

    if [ "$TUI_AVAILABLE" = true ]; then
        # Use gum confirm
        gum confirm "$prompt"
    else
        # Fallback: read prompt
        local choice
        while true; do
            read -rp "$prompt [y/N]: " choice
            case "$choice" in
                y|Y|yes|Yes|YES)
                    return 0
                    ;;
                n|N|no|No|NO|"")
                    return 1
                    ;;
                *)
                    echo "Invalid choice. Please enter 'y' or 'n'."
                    ;;
            esac
        done
    fi
}

#
# Show styled text (gum wrapper)
#
# Arguments:
#   $1 - Text to style
#   $2 - Foreground color (ANSI code or gum color name)
#   $3 - Bold flag (true/false, optional)
#
# Usage:
#   show_styled "SUCCESS" "green" true
#
show_styled() {
    local text="$1"
    local color="${2:-}"
    local bold="${3:-false}"

    if [ "$TUI_AVAILABLE" = true ]; then
        # Use gum style
        local style_args=()

        if [ -n "$color" ]; then
            style_args+=(--foreground "$color")
        fi

        if [ "$bold" = true ]; then
            style_args+=(--bold)
        fi

        gum style "${style_args[@]}" "$text"
    else
        # Fallback: ANSI color codes
        local ansi_color=""

        case "$color" in
            red)     ansi_color="\033[0;31m" ;;
            green)   ansi_color="\033[0;32m" ;;
            yellow)  ansi_color="\033[0;33m" ;;
            blue)    ansi_color="\033[0;34m" ;;
            cyan)    ansi_color="\033[0;36m" ;;
            *)       ansi_color="" ;;
        esac

        local bold_code=""
        if [ "$bold" = true ]; then
            bold_code="\033[1m"
        fi

        printf "${bold_code}${ansi_color}%s\033[0m\n" "$text"
    fi
}

#
# Show input prompt (gum wrapper)
#
# Arguments:
#   $1 - Prompt message
#   $2 - Default value (optional)
#   $3 - Placeholder text (optional)
#
# Returns:
#   User input string
#
# Usage:
#   username=$(show_input "Enter username:" "admin" "your username")
#
show_input() {
    local prompt="$1"
    local default="${2:-}"
    local placeholder="${3:-}"

    if [ "$TUI_AVAILABLE" = true ]; then
        # Use gum input
        local input_args=(--prompt "$prompt ")

        if [ -n "$default" ]; then
            input_args+=(--value "$default")
        fi

        if [ -n "$placeholder" ]; then
            input_args+=(--placeholder "$placeholder")
        fi

        gum input "${input_args[@]}"
    else
        # Fallback: read prompt
        local user_input
        if [ -n "$default" ]; then
            read -rp "$prompt [$default]: " user_input
            echo "${user_input:-$default}"
        else
            read -rp "$prompt: " user_input
            echo "$user_input"
        fi
    fi
}

#
# Show choice menu (gum wrapper)
#
# Arguments:
#   $1 - Header/prompt message
#   $2... - Choice options (multiple arguments)
#
# Returns:
#   Selected choice
#
# Usage:
#   choice=$(show_choose "Select installation method:" "apt" "snap" "source")
#
show_choose() {
    local header="$1"
    shift
    local choices=("$@")

    if [ "$TUI_AVAILABLE" = true ]; then
        # Use gum choose
        gum choose --header "$header" "${choices[@]}"
    else
        # Fallback: numbered menu
        echo "$header"
        local i=1
        for choice in "${choices[@]}"; do
            echo "  $i) $choice"
            ((i++))
        done

        local selection
        while true; do
            read -rp "Enter choice (1-${#choices[@]}): " selection

            if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#choices[@]}" ]; then
                echo "${choices[$((selection - 1))]}"
                return 0
            else
                echo "Invalid choice. Please enter a number between 1 and ${#choices[@]}."
            fi
        done
    fi
}

#
# Show multi-line text in box (gum wrapper)
#
# Arguments:
#   $1 - Title
#   $2... - Content lines (multiple arguments)
#
# Usage:
#   show_box "System Information" "OS: Ubuntu 25.10" "Kernel: 6.17.0" "Arch: x86_64"
#
show_box() {
    local title="$1"
    shift
    local content=("$@")

    if [ "$TUI_AVAILABLE" = true ]; then
        # Use gum style with border
        local content_text=""
        for line in "${content[@]}"; do
            content_text+="$line"$'\n'
        done

        gum style \
            --border double \
            --border-foreground 212 \
            --padding "1 2" \
            --margin "1 0" \
            "$title"$'\n\n'"$content_text"
    else
        # Fallback: ASCII box
        echo ""
        echo "╔══════════════════════════════════════════════════╗"
        echo "║ $title"
        echo "╠══════════════════════════════════════════════════╣"
        for line in "${content[@]}"; do
            echo "║ $line"
        done
        echo "╚══════════════════════════════════════════════════╝"
        echo ""
    fi
}

#
# Get TUI status summary
#
# Returns:
#   JSON summary of TUI availability and performance
#
get_tui_status() {
    cat <<EOF
{
  "tui_available": $TUI_AVAILABLE,
  "gum_version": "$GUM_VERSION",
  "gum_startup_ms": $GUM_STARTUP_MS,
  "constitutional_compliant": $([ "$GUM_STARTUP_MS" -lt 10 ] && echo "true" || echo "false")
}
EOF
}

# Export functions for use in other modules
export -f init_tui
export -f show_spinner
export -f show_progress
export -f show_confirm
export -f show_styled
export -f show_input
export -f show_choose
export -f show_box
export -f get_tui_status

# Export global variables
export TUI_AVAILABLE
export GUM_VERSION
export GUM_STARTUP_MS
