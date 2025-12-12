#!/usr/bin/env bash
# Boot Diagnostics TUI
# Automatically detects and offers fixes for common boot issues
# No LLM required - uses pattern matching and system queries

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/issue_registry.sh"
source "$SCRIPT_DIR/lib/fix_executor.sh"

# Issue storage
declare -a DETECTED_ISSUES=()
declare -a SELECTED_FOR_FIX=()

# Colors for display
readonly COLOR_RED=196
readonly COLOR_ORANGE=208
readonly COLOR_GREEN=46
readonly COLOR_BLUE=39
readonly COLOR_GRAY=246

# Show header
show_header() {
    clear
    gum style \
        --border rounded \
        --border-foreground "$COLOR_BLUE" \
        --padding "0 2" \
        --margin "1" \
        --bold \
        "$(gum style --foreground "$COLOR_BLUE" '🔧 Boot Diagnostics')

Scan your system for common boot issues and apply fixes"
}

# Run all detectors and collect issues
run_scan() {
    DETECTED_ISSUES=()

    show_header
    echo ""

    gum spin --spinner dot --title "Scanning for boot issues..." -- sleep 0.5

    # Run each detector
    for detector in "$SCRIPT_DIR/detectors"/detect_*.sh; do
        [[ -x "$detector" ]] || continue

        local detector_name
        detector_name=$(basename "$detector" .sh | sed 's/detect_//')

        while IFS= read -r line; do
            [[ -n "$line" ]] && DETECTED_ISSUES+=("$line")
        done < <("$detector" 2>/dev/null || true)
    done

    display_results
}

# Display scan results
display_results() {
    show_header

    if [[ ${#DETECTED_ISSUES[@]} -eq 0 ]]; then
        echo ""
        gum style --foreground "$COLOR_GREEN" --bold "✅ No issues detected! Your boot is healthy."
        echo ""
        gum style --foreground "$COLOR_GRAY" "Press any key to return..."
        read -r -n 1
        return
    fi

    # Count by severity
    local critical=0 moderate=0 low=0 fixable=0
    for issue in "${DETECTED_ISSUES[@]}"; do
        local severity fixable_flag
        severity=$(echo "$issue" | cut -d'|' -f2)
        fixable_flag=$(echo "$issue" | cut -d'|' -f5)

        case "$severity" in
            CRITICAL) ((critical++)) ;;
            MODERATE) ((moderate++)) ;;
            LOW)      ((low++)) ;;
        esac
        [[ "$fixable_flag" == "YES" ]] && ((fixable++))
    done

    echo ""
    gum style --foreground "$COLOR_BLUE" --bold "Scan Results:"
    echo "  🔴 Critical: $critical"
    echo "  🟡 Moderate: $moderate"
    echo "  🟢 Low/Cosmetic: $low"
    echo "  🔧 Fixable: $fixable"
    echo ""

    # Display each issue
    gum style --foreground "$COLOR_BLUE" "═══════════════════════════════════════════════════════════════"

    for issue in "${DETECTED_ISSUES[@]}"; do
        IFS='|' read -r type severity name desc fixable fix_cmd <<< "$issue"

        local icon color
        icon=$(get_severity_icon "$severity")
        color=$(get_severity_color "$severity")

        echo ""
        gum style --foreground "$color" --bold "$icon $severity: $name"
        echo "   Type: $type"
        echo "   Problem: $desc"
        if [[ "$fixable" == "YES" ]]; then
            gum style --foreground "$COLOR_GREEN" "   Fix: $fix_cmd"
        elif [[ "$fixable" == "MAYBE" ]]; then
            gum style --foreground "$COLOR_ORANGE" "   Possible fix: $fix_cmd"
        else
            gum style --foreground "$COLOR_GRAY" "   No automated fix available"
        fi
    done

    gum style --foreground "$COLOR_BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    # Offer to fix if there are fixable issues
    if [[ $fixable -gt 0 ]]; then
        offer_fixes
    else
        gum style --foreground "$COLOR_GRAY" "No automated fixes available for detected issues."
        echo ""
        gum style --foreground "$COLOR_GRAY" "Press any key to return..."
        read -r -n 1
    fi
}

# Offer fix selection
offer_fixes() {
    SELECTED_FOR_FIX=()

    # Build list of fixable issues for selection
    local -a fix_options=()
    local -a fix_entries=()

    for issue in "${DETECTED_ISSUES[@]}"; do
        IFS='|' read -r type severity name desc fixable fix_cmd <<< "$issue"

        if [[ "$fixable" == "YES" ]]; then
            local icon
            icon=$(get_severity_icon "$severity")
            fix_options+=("$icon Fix: $name")
            fix_entries+=("$issue")
        fi
    done

    if [[ ${#fix_options[@]} -eq 0 ]]; then
        return
    fi

    echo ""
    gum style --foreground "$COLOR_BLUE" "Select issues to fix (space to select, enter to confirm):"
    echo ""

    # Use gum choose with multi-select
    local selected
    selected=$(printf '%s\n' "${fix_options[@]}" | gum choose --no-limit --header "Select fixes to apply:") || true

    if [[ -z "$selected" ]]; then
        gum style --foreground "$COLOR_ORANGE" "No fixes selected."
        sleep 1
        return
    fi

    # Match selected items back to fix entries
    while IFS= read -r sel; do
        [[ -z "$sel" ]] && continue

        for i in "${!fix_options[@]}"; do
            if [[ "${fix_options[$i]}" == "$sel" ]]; then
                SELECTED_FOR_FIX+=("${fix_entries[$i]}")
                break
            fi
        done
    done <<< "$selected"

    if [[ ${#SELECTED_FOR_FIX[@]} -gt 0 ]]; then
        execute_all_fixes SELECTED_FOR_FIX
        show_fix_summary

        echo ""
        gum style --foreground "$COLOR_BLUE" "Press any key to return..."
        read -r -n 1
    fi
}

# Show boot performance
show_boot_performance() {
    show_header
    echo ""

    gum style --foreground "$COLOR_BLUE" --bold "Boot Performance Analysis"
    gum style --foreground "$COLOR_BLUE" "═══════════════════════════════════════════════════════════════"
    echo ""

    # Boot time summary
    gum style --foreground "$COLOR_BLUE" "Boot Time Summary:"
    systemd-analyze 2>/dev/null || echo "Unable to analyze boot time"
    echo ""

    # Top 10 slowest services
    gum style --foreground "$COLOR_BLUE" "Top 10 Slowest Services:"
    systemd-analyze blame 2>/dev/null | head -10 || echo "Unable to get service timing"
    echo ""

    # Critical chain
    gum style --foreground "$COLOR_BLUE" "Critical Boot Chain:"
    systemd-analyze critical-chain 2>/dev/null | head -20 || echo "Unable to analyze critical chain"
    echo ""

    gum style --foreground "$COLOR_GRAY" "Press any key to return..."
    read -r -n 1
}

# Show last scan results from cache (if implemented)
show_last_results() {
    show_header
    echo ""
    gum style --foreground "$COLOR_ORANGE" "Running fresh scan (cached results not implemented)..."
    sleep 1
    run_scan
}

# Main menu
main_menu() {
    while true; do
        show_header
        echo ""

        local choice
        choice=$(gum choose \
            "🔍 Scan for Boot Issues" \
            "📊 View Boot Performance" \
            "← Back to Main Menu")

        case "$choice" in
            "🔍 Scan for Boot Issues")
                run_scan
                ;;
            "📊 View Boot Performance")
                show_boot_performance
                ;;
            "← Back to Main Menu")
                return 0
                ;;
            *)
                return 0
                ;;
        esac
    done
}

# Entry point
main() {
    # Check for gum
    if ! command -v gum &>/dev/null; then
        echo "Error: gum is required but not installed."
        echo "Install with: sudo apt install gum  OR  brew install gum"
        exit 1
    fi

    main_menu
}

main "$@"
