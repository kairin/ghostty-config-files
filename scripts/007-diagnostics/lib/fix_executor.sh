#!/usr/bin/env bash
# Fix Executor - Handles batched fix execution with sudo grouping
# Separates user-level fixes from sudo-required fixes for better UX

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/issue_registry.sh"

# Arrays to hold categorized fixes
declare -a USER_FIXES=()
declare -a SUDO_FIXES=()
declare -a FIX_RESULTS=()

# Categorize fixes by sudo requirement
categorize_fixes() {
    local -n fixes_ref=$1
    USER_FIXES=()
    SUDO_FIXES=()

    for fix_entry in "${fixes_ref[@]}"; do
        IFS='|' read -r type severity name desc fixable fix_cmd <<< "$fix_entry"

        if [[ "$fixable" != "YES" ]]; then
            continue
        fi

        if fix_requires_sudo "$fix_cmd"; then
            SUDO_FIXES+=("$fix_entry")
        else
            USER_FIXES+=("$fix_entry")
        fi
    done
}

# Display fixes in a formatted way
display_fix_group() {
    local group_name="$1"
    shift
    local fixes=("$@")

    if [[ ${#fixes[@]} -eq 0 ]]; then
        return
    fi

    echo ""
    gum style --foreground 39 --bold "═══════════════════════════════════════════════════════════════"
    gum style --foreground 39 --bold "$group_name"
    gum style --foreground 39 --bold "═══════════════════════════════════════════════════════════════"
    echo ""

    local i=1
    for fix_entry in "${fixes[@]}"; do
        IFS='|' read -r type severity name desc fixable fix_cmd <<< "$fix_entry"

        local icon
        icon=$(get_severity_icon "$severity")

        echo "$i. $icon $name"
        echo "   Problem: $desc"
        echo "   Fix: $fix_cmd"
        echo ""
        ((i++))
    done
}

# Execute a single fix command
execute_single_fix() {
    local fix_cmd="$1"
    local name="$2"

    echo -n "  → Executing fix for $name... "

    # Execute the command
    if eval "$fix_cmd" &>/dev/null; then
        gum style --foreground 46 "✓ Done"
        return 0
    else
        gum style --foreground 196 "✗ Failed"
        return 1
    fi
}

# Execute user-level fixes (no sudo)
execute_user_fixes() {
    if [[ ${#USER_FIXES[@]} -eq 0 ]]; then
        return 0
    fi

    display_fix_group "PHASE 1: User-Level Fixes (no sudo required)" "${USER_FIXES[@]}"

    if ! gum confirm "Apply ${#USER_FIXES[@]} user-level fix(es)?"; then
        gum style --foreground 208 "Skipped user-level fixes"
        return 0
    fi

    echo ""
    gum style --foreground 39 "Applying user-level fixes..."
    echo ""

    local success=0
    local failed=0

    for fix_entry in "${USER_FIXES[@]}"; do
        IFS='|' read -r type severity name desc fixable fix_cmd <<< "$fix_entry"

        if execute_single_fix "$fix_cmd" "$name"; then
            ((success++))
            FIX_RESULTS+=("SUCCESS|$name|$fix_cmd")
        else
            ((failed++))
            FIX_RESULTS+=("FAILED|$name|$fix_cmd")
        fi
    done

    echo ""
    gum style --foreground 46 "User-level fixes: $success succeeded, $failed failed"
}

# Execute sudo-level fixes (batched sudo)
execute_sudo_fixes() {
    if [[ ${#SUDO_FIXES[@]} -eq 0 ]]; then
        return 0
    fi

    display_fix_group "PHASE 2: System-Level Fixes (sudo required)" "${SUDO_FIXES[@]}"

    if ! gum confirm "Apply ${#SUDO_FIXES[@]} system-level fix(es)? (will prompt for password)"; then
        gum style --foreground 208 "Skipped system-level fixes"
        return 0
    fi

    echo ""
    gum style --foreground 39 "Authenticating..."

    # Single sudo authentication
    if ! sudo -v; then
        gum style --foreground 196 "✗ Sudo authentication failed"
        return 1
    fi

    echo ""
    gum style --foreground 39 "Applying system-level fixes..."
    echo ""

    local success=0
    local failed=0

    for fix_entry in "${SUDO_FIXES[@]}"; do
        IFS='|' read -r type severity name desc fixable fix_cmd <<< "$fix_entry"

        if execute_single_fix "$fix_cmd" "$name"; then
            ((success++))
            FIX_RESULTS+=("SUCCESS|$name|$fix_cmd")
        else
            ((failed++))
            FIX_RESULTS+=("FAILED|$name|$fix_cmd")
        fi
    done

    echo ""
    gum style --foreground 46 "System-level fixes: $success succeeded, $failed failed"
}

# Main fix execution entry point
execute_all_fixes() {
    local -n selected_fixes=$1
    FIX_RESULTS=()

    categorize_fixes selected_fixes

    local total_fixes=$((${#USER_FIXES[@]} + ${#SUDO_FIXES[@]}))

    if [[ $total_fixes -eq 0 ]]; then
        gum style --foreground 208 "No fixable issues selected"
        return 0
    fi

    gum style --border rounded --padding "0 1" --foreground 39 \
        "Preparing to apply $total_fixes fix(es)..."

    # Execute in phases
    execute_user_fixes
    execute_sudo_fixes

    # Summary
    echo ""
    gum style --border double --padding "0 1" --foreground 46 \
        "Fix execution complete. Reboot recommended to verify changes."
}

# Show fix results summary
show_fix_summary() {
    if [[ ${#FIX_RESULTS[@]} -eq 0 ]]; then
        return
    fi

    echo ""
    gum style --foreground 39 --bold "Fix Summary:"

    for result in "${FIX_RESULTS[@]}"; do
        IFS='|' read -r status name cmd <<< "$result"
        if [[ "$status" == "SUCCESS" ]]; then
            echo "  ✓ $name"
        else
            echo "  ✗ $name (failed)"
        fi
    done
}
