#!/usr/bin/env bash
#
# zshrc_manager.sh - Intelligent .zshrc Configuration Manager
#
# Purpose: Provide P10k-compliant .zshrc modification functions for installation scripts
#
# Features:
#   - Powerlevel10k instant prompt aware (prevents console output warnings)
#   - Automatic section placement (before/after P10k based on content type)
#   - Duplicate detection and prevention
#   - Idempotent operations (safe to re-run)
#
# Usage:
#   source lib/utils/zshrc_manager.sh
#   inject_into_zshrc "fnm initialization" "$fnm_block" "before_p10k"
#   inject_into_zshrc "uv configuration" "$uv_block" "after_p10k"
#
# Constitutional Compliance:
#   - Prevents Powerlevel10k instant prompt warnings
#   - Ensures optimal shell startup performance
#   - Maintains user customizations
#

set -euo pipefail

# ════════════════════════════════════════════════════════════════════════
# Constants
# ════════════════════════════════════════════════════════════════════════

readonly ZSHRC="${HOME}/.zshrc"
readonly P10K_MARKER_START="# Enable Powerlevel10k instant prompt"
readonly P10K_MARKER_END="fi"  # End of P10k instant prompt block

# ════════════════════════════════════════════════════════════════════════
# Helper Functions
# ════════════════════════════════════════════════════════════════════════

#
# Find line number where P10k instant prompt starts
#
# Returns:
#   Line number (1-based) or 0 if not found
#
find_p10k_start_line() {
    grep -n "^# Enable Powerlevel10k instant prompt" "$ZSHRC" 2>/dev/null | head -1 | cut -d: -f1 || echo "0"
}

#
# Find line number where P10k instant prompt ends
#
# Returns:
#   Line number (1-based) or 0 if not found
#
find_p10k_end_line() {
    local p10k_start
    p10k_start=$(find_p10k_start_line)

    if [ "$p10k_start" -eq 0 ]; then
        echo "0"
        return
    fi

    # Find the closing 'fi' after the P10k start
    # P10k block structure:
    #   # Enable Powerlevel10k instant prompt...
    #   if [[ -r ... ]]; then
    #     source ...
    #   fi

    tail -n +$((p10k_start)) "$ZSHRC" | grep -n "^fi$" 2>/dev/null | head -1 | cut -d: -f1 | awk -v start="$p10k_start" '{print start + $1 - 1}' || echo "0"
}

#
# Check if content already exists in .zshrc
#
# Args:
#   $1 - Unique marker string to search for
#
# Returns:
#   0 if found, 1 if not found
#
content_exists_in_zshrc() {
    local marker="$1"
    grep -qF "$marker" "$ZSHRC" 2>/dev/null
}

#
# Get insertion line number based on placement strategy
#
# Args:
#   $1 - Placement: "before_p10k" or "after_p10k" or "end"
#
# Returns:
#   Line number where content should be inserted
#
get_insertion_line() {
    local placement="$1"

    case "$placement" in
        before_p10k)
            # Insert before P10k instant prompt block
            local p10k_start
            p10k_start=$(find_p10k_start_line)

            if [ "$p10k_start" -eq 0 ]; then
                # P10k not found, insert after ZSH_DISABLE_COMPFIX or at line 25
                local compfix_line
                compfix_line=$(grep -n "^ZSH_DISABLE_COMPFIX" "$ZSHRC" 2>/dev/null | head -1 | cut -d: -f1 || echo "25")
                echo "$((compfix_line + 1))"
            else
                echo "$((p10k_start - 1))"
            fi
            ;;
        after_p10k)
            # Insert after P10k instant prompt block
            local p10k_end
            p10k_end=$(find_p10k_end_line)

            if [ "$p10k_end" -eq 0 ]; then
                # P10k not found, insert after Oh My ZSH source or at line 120
                local omz_line
                omz_line=$(grep -n "^source \$ZSH/oh-my-zsh.sh" "$ZSHRC" 2>/dev/null | head -1 | cut -d: -f1 || echo "120")
                echo "$((omz_line + 1))"
            else
                echo "$((p10k_end + 1))"
            fi
            ;;
        end)
            # Insert at end of file
            wc -l < "$ZSHRC" | tr -d ' '
            ;;
        *)
            echo "ERROR: Unknown placement: $placement" >&2
            return 1
            ;;
    esac
}

# ════════════════════════════════════════════════════════════════════════
# Public API
# ════════════════════════════════════════════════════════════════════════

#
# Inject content into .zshrc at the correct location
#
# Args:
#   $1 - Description (for logging)
#   $2 - Content block to inject
#   $3 - Placement: "before_p10k" | "after_p10k" | "end"
#   $4 - Unique marker (for duplicate detection, optional)
#
# Returns:
#   0 - Success
#   1 - Failed
#   2 - Already exists (skipped)
#
# Examples:
#   inject_into_zshrc "fnm initialization" "$fnm_block" "before_p10k" "fnm env"
#   inject_into_zshrc "aliases" "$alias_block" "end" "# Custom aliases"
#
inject_into_zshrc() {
    local description="$1"
    local content="$2"
    local placement="$3"
    local marker="${4:-}"  # Optional unique marker

    # Verify .zshrc exists
    if [ ! -f "$ZSHRC" ]; then
        echo "ERROR: $ZSHRC not found" >&2
        return 1
    fi

    # Check for duplicates
    if [ -n "$marker" ] && content_exists_in_zshrc "$marker"; then
        echo "↷ $description already configured in .zshrc"
        return 2
    fi

    # Get insertion line
    local insert_line
    insert_line=$(get_insertion_line "$placement")

    if [ -z "$insert_line" ] || [ "$insert_line" -eq 0 ]; then
        echo "ERROR: Could not determine insertion line for $description" >&2
        return 1
    fi

    # Create backup
    cp "$ZSHRC" "${ZSHRC}.bak-$(date +%Y%m%d-%H%M%S)"

    # Insert content at calculated line
    # Use head/tail approach for precise insertion
    {
        head -n "$insert_line" "$ZSHRC"
        echo ""
        echo "$content"
        tail -n +$((insert_line + 1)) "$ZSHRC"
    } > "${ZSHRC}.tmp"

    mv "${ZSHRC}.tmp" "$ZSHRC"

    echo "✓ Added $description to .zshrc (line $insert_line, placement: $placement)"
    return 0
}

#
# Remove content block from .zshrc (for cleanup/updates)
#
# Args:
#   $1 - Start marker (line containing this will be removed)
#   $2 - End marker (optional, if multi-line block)
#
# Returns:
#   0 - Success
#   1 - Failed
#   2 - Not found (already removed)
#
remove_from_zshrc() {
    local start_marker="$1"
    local end_marker="${2:-}"

    if ! content_exists_in_zshrc "$start_marker"; then
        echo "↷ Content not found in .zshrc (already removed)"
        return 2
    fi

    # Create backup
    cp "$ZSHRC" "${ZSHRC}.bak-$(date +%Y%m%d-%H%M%S)"

    if [ -n "$end_marker" ]; then
        # Remove multi-line block
        sed -i "/${start_marker}/,/${end_marker}/d" "$ZSHRC"
    else
        # Remove single line
        sed -i "/${start_marker}/d" "$ZSHRC"
    fi

    echo "✓ Removed content from .zshrc"
    return 0
}

#
# Verify .zshrc P10k compliance (diagnostic function)
#
# Returns:
#   0 - Compliant
#   1 - Issues detected
#
verify_p10k_compliance() {
    local p10k_start
    local p10k_end

    p10k_start=$(find_p10k_start_line)
    p10k_end=$(find_p10k_end_line)

    if [ "$p10k_start" -eq 0 ]; then
        echo "ℹ P10k instant prompt not detected in .zshrc"
        return 0
    fi

    echo "✓ P10k instant prompt detected (lines $p10k_start-$p10k_end)"

    # Check for problematic patterns between start and end
    local problematic_lines
    problematic_lines=$(awk -v start="$p10k_start" -v end="$p10k_end" \
        'NR > start && NR < end && /eval.*fnm|echo|printf|cat/' "$ZSHRC" | wc -l)

    if [ "$problematic_lines" -gt 0 ]; then
        echo "⚠ WARNING: $problematic_lines line(s) with console output detected inside P10k block"
        return 1
    fi

    echo "✓ No console output detected inside P10k block"
    return 0
}

# ════════════════════════════════════════════════════════════════════════
# Exports
# ════════════════════════════════════════════════════════════════════════

# Note: Functions are available when this script is sourced
# No explicit export needed - sourcing makes functions available in calling script
