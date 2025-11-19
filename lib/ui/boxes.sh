#!/usr/bin/env bash
#
# lib/ui/boxes.sh - Adaptive box drawing system
#
# CONTEXT7 STATUS: Unable to query (API authentication issue)
# FALLBACK: Best practices for terminal capability detection and box drawing 2025
# - UTF-8 locale detection
# - Terminal capability detection (TERM environment variable)
# - SSH session detection (SSH_CONNECTION, SSH_CLIENT)
# - Manual override support (BOX_DRAWING environment variable)
#
# Constitutional Compliance: Principle V - Modular Architecture
# User Stories: US1 (Fresh Installation), US2 (SSH Installation Support)
#
# Requirements:
# - FR-002: Detect terminal capability via TERM and SSH_CONNECTION
# - FR-003: Render UTF-8 double-line boxes for modern terminals
# - FR-004: Render ASCII boxes for SSH and legacy terminals
# - FR-005: Support manual override via BOX_DRAWING environment variable
#

set -euo pipefail

# Source guard - prevent redundant loading
[ -z "${BOXES_SH_LOADED:-}" ] || return 0
BOXES_SH_LOADED=1

# Source required utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../core/utils.sh"

#
# Box drawing character sets
#
# UTF-8 Double-line (preferred for modern terminals)
declare -gA BOX_UTF8_DOUBLE=(
    [TL]="╔"  # Top-left corner
    [TR]="╗"  # Top-right corner
    [BL]="╚"  # Bottom-left corner
    [BR]="╝"  # Bottom-right corner
    [H]="═"   # Horizontal line
    [V]="║"   # Vertical line
    [LT]="╠"  # Left T-junction
    [RT]="╣"  # Right T-junction
    [TT]="╦"  # Top T-junction
    [BT]="╩"  # Bottom T-junction
    [CROSS]="╬" # Cross junction
)

# UTF-8 Single-line (fallback for terminals with limited Unicode support)
declare -gA BOX_UTF8=(
    [TL]="┌"
    [TR]="┐"
    [BL]="└"
    [BR]="┘"
    [H]="─"
    [V]="│"
    [LT]="├"
    [RT]="┤"
    [TT]="┬"
    [BT]="┴"
    [CROSS]="┼"
)

# ASCII (universal fallback for SSH and legacy terminals)
declare -gA BOX_ASCII=(
    [TL]="+"
    [TR]="+"
    [BL]="+"
    [BR]="+"
    [H]="-"
    [V]="|"
    [LT]="+"
    [RT]="+"
    [TT]="+"
    [BT]="+"
    [CROSS]="+"
)

# Global: Selected box drawing character set
declare -gA BOX_CHARS

#
# Check if locale supports UTF-8
#
# Returns:
#   0 if UTF-8 locale, 1 if not
#
# Usage:
#   if is_utf8_locale; then
#       echo "UTF-8 supported"
#   fi
#
is_utf8_locale() {
    local lang="${LANG:-}"
    local lc_all="${LC_ALL:-}"
    local lc_ctype="${LC_CTYPE:-}"

    # Check LANG, LC_ALL, and LC_CTYPE for UTF-8
    [[ "$lang" == *"UTF-8"* ]] || \
    [[ "$lang" == *"utf8"* ]] || \
    [[ "$lc_all" == *"UTF-8"* ]] || \
    [[ "$lc_all" == *"utf8"* ]] || \
    [[ "$lc_ctype" == *"UTF-8"* ]] || \
    [[ "$lc_ctype" == *"utf8"* ]]
}

#
# Check if terminal is UTF-8 capable
#
# Returns:
#   0 if UTF-8 terminal, 1 if not
#
# Usage:
#   if is_utf8_terminal; then
#       echo "Can display UTF-8 box drawing"
#   fi
#
is_utf8_terminal() {
    local term="${TERM:-}"

    # Known UTF-8 capable terminals
    case "$term" in
        xterm*|rxvt*|screen*|tmux*|alacritty|kitty|ghostty|wezterm|foot)
            return 0
            ;;
        linux|vt100|vt220|ansi)
            return 1
            ;;
        *)
            # Fall back to locale check
            is_utf8_locale
            ;;
    esac
}

#
# Detect optimal box drawing character set
#
# Selection logic:
#   1. Check BOX_DRAWING environment variable (manual override)
#   2. If SSH session: Use ASCII (best compatibility)
#   3. If UTF-8 locale + UTF-8 terminal: Use UTF-8 double-line
#   4. If UTF-8 locale: Use UTF-8 single-line
#   5. Default: ASCII
#
# Returns:
#   Sets global BOX_CHARS array to selected character set
#
# Usage:
#   init_box_drawing
#   echo "${BOX_CHARS[TL]}"  # Top-left corner
#
init_box_drawing() {
    local box_style="${BOX_DRAWING:-auto}"

    # Manual override
    case "$box_style" in
        utf8-double|utf8d|double)
            # Copy UTF-8 double-line characters
            for key in "${!BOX_UTF8_DOUBLE[@]}"; do
                BOX_CHARS[$key]="${BOX_UTF8_DOUBLE[$key]}"
            done
            return 0
            ;;
        utf8|utf8-single|single)
            # Copy UTF-8 single-line characters
            for key in "${!BOX_UTF8[@]}"; do
                BOX_CHARS[$key]="${BOX_UTF8[$key]}"
            done
            return 0
            ;;
        ascii|plain)
            # Copy ASCII characters
            for key in "${!BOX_ASCII[@]}"; do
                BOX_CHARS[$key]="${BOX_ASCII[$key]}"
            done
            return 0
            ;;
    esac

    # Auto-detection
    # Force ASCII in SSH sessions for best compatibility
    if is_ssh_session; then
        for key in "${!BOX_ASCII[@]}"; do
            BOX_CHARS[$key]="${BOX_ASCII[$key]}"
        done
        return 0
    fi

    # Check UTF-8 capability
    if is_utf8_locale && is_utf8_terminal; then
        # Prefer UTF-8 double-line for modern terminals
        for key in "${!BOX_UTF8_DOUBLE[@]}"; do
            BOX_CHARS[$key]="${BOX_UTF8_DOUBLE[$key]}"
        done
        return 0
    elif is_utf8_locale; then
        # Use UTF-8 single-line for partial support
        for key in "${!BOX_UTF8[@]}"; do
            BOX_CHARS[$key]="${BOX_UTF8[$key]}"
        done
        return 0
    fi

    # Default to ASCII
    for key in "${!BOX_ASCII[@]}"; do
        BOX_CHARS[$key]="${BOX_ASCII[$key]}"
    done
}

#
# Draw box with title and content
#
# Arguments:
#   $1 - Title (displayed in top border)
#   $2 - Width (optional, default: 70)
#   $@ - Content lines (remaining arguments)
#
# Returns:
#   Box rendered to stdout
#
# Usage:
#   draw_box "Installation Progress" 60 \
#       "✓ Ghostty installed (5.2s)" \
#       "⠋ Installing ZSH..." \
#       "⏸ AI Tools (queued)"
#
draw_box() {
    local title="$1"
    shift
    local width="${1:-70}"
    shift
    local content_lines=("$@")

    # Initialize box drawing if not already done
    if [ ${#BOX_CHARS[@]} -eq 0 ]; then
        init_box_drawing
    fi

    # Calculate title width
    local title_width
    title_width=$(get_visual_width "$title")

    # Build top border with title
    local top_border="${BOX_CHARS[TL]}"

    if [ -n "$title" ] && [ "$title_width" -gt 0 ]; then
        # Add title with spacing
        top_border+="${BOX_CHARS[H]}${BOX_CHARS[H]} $title ${BOX_CHARS[H]}${BOX_CHARS[H]}"

        # Calculate remaining horizontal line length
        local title_section_width=$((4 + title_width + 4))  # spacing + title + spacing
        local remaining_width=$((width - 2 - title_section_width))  # 2 for corners

        # Fill remaining space
        if [ "$remaining_width" -gt 0 ]; then
            top_border+="$(repeat_string "${BOX_CHARS[H]}" "$remaining_width")"
        fi
    else
        # No title, full horizontal line
        top_border+="$(repeat_string "${BOX_CHARS[H]}" $((width - 2)))"
    fi

    top_border+="${BOX_CHARS[TR]}"

    # Print top border
    echo "$top_border"

    # Print content lines
    for line in "${content_lines[@]}"; do
        local line_width
        line_width=$(get_visual_width "$line")

        # Calculate padding
        local padding=$((width - 2 - 2 - line_width))  # 2 for borders, 2 for spacing

        # Build content line
        local content_line="${BOX_CHARS[V]} $line"

        if [ "$padding" -gt 0 ]; then
            content_line+="$(repeat_string " " "$padding")"
        fi

        content_line+=" ${BOX_CHARS[V]}"

        echo "$content_line"
    done

    # Build bottom border
    local bottom_border="${BOX_CHARS[BL]}"
    bottom_border+="$(repeat_string "${BOX_CHARS[H]}" $((width - 2)))"
    bottom_border+="${BOX_CHARS[BR]}"

    # Print bottom border
    echo "$bottom_border"
}

#
# Draw horizontal separator line
#
# Arguments:
#   $1 - Width (optional, default: 70)
#   $2 - Title (optional, centered in separator)
#
# Returns:
#   Separator line rendered to stdout
#
# Usage:
#   draw_separator 60 "Components"
#
draw_separator() {
    local width="${1:-70}"
    local title="${2:-}"

    # Initialize box drawing if not already done
    if [ ${#BOX_CHARS[@]} -eq 0 ]; then
        init_box_drawing
    fi

    # Build separator
    local separator="${BOX_CHARS[LT]}"

    if [ -n "$title" ]; then
        local title_width
        title_width=$(get_visual_width "$title")

        # Add title with spacing
        separator+="${BOX_CHARS[H]}${BOX_CHARS[H]} $title ${BOX_CHARS[H]}${BOX_CHARS[H]}"

        # Calculate remaining horizontal line length
        local title_section_width=$((4 + title_width + 4))
        local remaining_width=$((width - 2 - title_section_width))

        # Fill remaining space
        if [ "$remaining_width" -gt 0 ]; then
            separator+="$(repeat_string "${BOX_CHARS[H]}" "$remaining_width")"
        fi
    else
        # No title, full horizontal line
        separator+="$(repeat_string "${BOX_CHARS[H]}" $((width - 2)))"
    fi

    separator+="${BOX_CHARS[RT]}"

    echo "$separator"
}

#
# Get box drawing style name (for display/debugging)
#
# Returns:
#   String: "UTF-8 Double-line", "UTF-8 Single-line", or "ASCII"
#
# Usage:
#   style=$(get_box_style_name)
#
get_box_style_name() {
    # Initialize if not already done
    if [ ${#BOX_CHARS[@]} -eq 0 ]; then
        init_box_drawing
    fi

    # Detect style by checking a unique character
    if [ "${BOX_CHARS[TL]}" = "╔" ]; then
        echo "UTF-8 Double-line"
    elif [ "${BOX_CHARS[TL]}" = "┌" ]; then
        echo "UTF-8 Single-line"
    else
        echo "ASCII"
    fi
}

# Export functions for use in other modules
export -f is_utf8_locale
export -f is_utf8_terminal
export -f init_box_drawing
export -f draw_box
export -f draw_separator
export -f get_box_style_name

# Auto-initialize on source (can be re-initialized later if needed)
init_box_drawing
