#!/usr/bin/env bash
#
# lib/ui/colors.sh - gum color scheme and styling
#
# Purpose: Centralized color definitions for consistent TUI styling
# Uses gum style for rich terminal formatting
#
# Constitutional Compliance:
# - Follows gum-exclusive TUI standard
# - Graceful degradation for terminals without color support
#

set -euo pipefail

# Source guard
[ -z "${COLORS_SH_LOADED:-}" ] || return 0
COLORS_SH_LOADED=1

# gum color palette (Catppuccin Mocha theme)
export GUM_COLOR_SUCCESS="#a6e3a1"    # Green
export GUM_COLOR_ERROR="#f38ba8"      # Red
export GUM_COLOR_WARNING="#f9e2af"    # Yellow
export GUM_COLOR_INFO="#89b4fa"       # Blue
export GUM_COLOR_PENDING="#cba6f7"    # Purple
export GUM_COLOR_SKIPPED="#6c7086"    # Gray
export GUM_COLOR_PRIMARY="#cdd6f4"    # Text
export GUM_COLOR_SECONDARY="#a6adc8"  # Subtext
export GUM_COLOR_ACCENT="#f5c2e7"     # Pink

# Spinner styles for different states
export GUM_SPINNER_SUCCESS="dot"
export GUM_SPINNER_ERROR="dot"
export GUM_SPINNER_INFO="dot"
export GUM_SPINNER_PENDING="dot"

#
# Style text with gum
#
# Args:
#   $1 - Text to style
#   $2 - Color (success|error|warning|info|pending|skipped)
#   $3 - Additional style flags (optional: bold, italic, underline)
#
# Returns:
#   Styled text output
#
style_text() {
    local text="$1"
    local color_name="${2:-primary}"
    local additional_styles="${3:-}"

    if ! command_exists "gum"; then
        echo "$text"
        return 0
    fi

    # Map color names to hex values
    local color
    case "$color_name" in
        success) color="$GUM_COLOR_SUCCESS" ;;
        error) color="$GUM_COLOR_ERROR" ;;
        warning) color="$GUM_COLOR_WARNING" ;;
        info) color="$GUM_COLOR_INFO" ;;
        pending) color="$GUM_COLOR_PENDING" ;;
        skipped) color="$GUM_COLOR_SKIPPED" ;;
        primary) color="$GUM_COLOR_PRIMARY" ;;
        secondary) color="$GUM_COLOR_SECONDARY" ;;
        accent) color="$GUM_COLOR_ACCENT" ;;
        *) color="$GUM_COLOR_PRIMARY" ;;
    esac

    # Build gum style command
    local style_cmd="gum style --foreground=\"$color\""

    # Add additional styles
    if [[ "$additional_styles" =~ "bold" ]]; then
        style_cmd+=" --bold"
    fi
    if [[ "$additional_styles" =~ "italic" ]]; then
        style_cmd+=" --italic"
    fi
    if [[ "$additional_styles" =~ "underline" ]]; then
        style_cmd+=" --underline"
    fi

    # Apply styling
    eval "$style_cmd \"$text\""
}

#
# Show animated spinner with color
#
# Args:
#   $1 - Message to display
#   $2 - Color (success|error|warning|info|pending)
#   $3 - Command to run while spinning
#
# Returns:
#   Exit code of the command
#
spin_with_color() {
    local message="$1"
    local color="${2:-info}"
    local command="${3:-sleep 1}"

    if ! command_exists "gum"; then
        echo "⠋ $message..."
        eval "$command"
        return $?
    fi

    # Map color to spinner color
    local spinner_color
    case "$color" in
        success) spinner_color="$GUM_COLOR_SUCCESS" ;;
        error) spinner_color="$GUM_COLOR_ERROR" ;;
        warning) spinner_color="$GUM_COLOR_WARNING" ;;
        info) spinner_color="$GUM_COLOR_INFO" ;;
        pending) spinner_color="$GUM_COLOR_PENDING" ;;
        *) spinner_color="$GUM_COLOR_INFO" ;;
    esac

    # Run with gum spin (animated)
    gum spin \
        --spinner="$GUM_SPINNER_INFO" \
        --title="$message" \
        --spinner.foreground="$spinner_color" \
        --title.foreground="$spinner_color" \
        -- $command
}

#
# Show progress bar with color
#
# Args:
#   $1 - Current value
#   $2 - Total value
#   $3 - Label
#   $4 - Color (success|error|warning|info)
#
# Returns:
#   Formatted progress bar
#
show_progress_bar_colored() {
    local current="$1"
    local total="$2"
    local label="${3:-Progress}"
    local color="${4:-info}"

    if ! command_exists "gum"; then
        local percent=$((current * 100 / total))
        echo "[$percent%] $label: $current/$total"
        return 0
    fi

    # Map color to progress bar color
    local bar_color
    case "$color" in
        success) bar_color="$GUM_COLOR_SUCCESS" ;;
        error) bar_color="$GUM_COLOR_ERROR" ;;
        warning) bar_color="$GUM_COLOR_WARNING" ;;
        info) bar_color="$GUM_COLOR_INFO" ;;
        *) bar_color="$GUM_COLOR_INFO" ;;
    esac

    # Show progress bar (note: gum doesn't have built-in progress bar)
    # We'll create a visual bar using gum style
    local percent=$((current * 100 / total))
    local bar_width=30
    local filled=$((bar_width * current / total))
    local empty=$((bar_width - filled))

    local filled_bar=$(printf '█%.0s' $(seq 1 $filled))
    local empty_bar=$(printf '░%.0s' $(seq 1 $empty))

    gum style --foreground="$bar_color" "${filled_bar}${empty_bar} ${percent}% ${label}"
}

#
# Format status with icon and color
#
# Args:
#   $1 - Status (success|error|warning|info|pending|skipped)
#   $2 - Message
#
# Returns:
#   Formatted status line
#
format_status() {
    local status="$1"
    local message="$2"

    local icon color
    case "$status" in
        success)
            icon="✓"
            color="success"
            ;;
        error)
            icon="✗"
            color="error"
            ;;
        warning)
            icon="⚠"
            color="warning"
            ;;
        info)
            icon="ℹ"
            color="info"
            ;;
        pending)
            icon="⏸"
            color="pending"
            ;;
        skipped)
            icon="↷"
            color="skipped"
            ;;
        *)
            icon="•"
            color="primary"
            ;;
    esac

    if command_exists "gum"; then
        style_text "$icon $message" "$color"
    else
        echo "$icon $message"
    fi
}

# Export functions
export -f style_text
export -f spin_with_color
export -f show_progress_bar_colored
export -f format_status
