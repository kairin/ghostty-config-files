#!/bin/bash
# check_updates.sh - Check all installed tools for available updates
# Outputs a summary table showing current vs latest versions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_DIR="$SCRIPT_DIR/000-check"

# Colors
readonly COLOR_GREEN="\033[32m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_RED="\033[31m"
readonly COLOR_BLUE="\033[34m"
readonly COLOR_RESET="\033[0m"

# Counter for updates available
UPDATES_AVAILABLE=0
TOOLS_CHECKED=0

# Usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Check all installed tools for available updates.

Options:
    -q, --quiet      Only output tools with updates available
    -j, --json       Output results in JSON format
    -h, --help       Show this help message

Exit codes:
    0    No updates available
    1    Updates available
    2    Error occurred
EOF
    exit 0
}

# Parse arguments
QUIET=0
JSON=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        -q|--quiet) QUIET=1; shift ;;
        -j|--json) JSON=1; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# JSON output array
JSON_RESULTS='[]'

# Check a single tool
check_tool() {
    local tool_name="$1"
    local tool_id="$2"
    local check_script="$CHECK_DIR/check_${tool_id}.sh"

    if [[ ! -x "$check_script" ]]; then
        return
    fi

    ((TOOLS_CHECKED++))

    local output
    output=$("$check_script" 2>/dev/null) || output="ERROR|-|-|-|-"

    IFS='|' read -r status version method location latest <<< "$output"

    # Skip if not installed (unless showing all)
    if [[ "$status" != "INSTALLED" ]]; then
        if [[ $QUIET -eq 0 ]] && [[ $JSON -eq 0 ]]; then
            printf "%-20s ${COLOR_RED}Not Installed${COLOR_RESET}\n" "$tool_name"
        fi
        return
    fi

    # Check if update available
    local update_available=0
    if [[ -n "$latest" ]] && [[ "$latest" != "-" ]] && [[ "$latest" != "$version" ]]; then
        update_available=1
        ((UPDATES_AVAILABLE++))
    fi

    # Output based on format
    if [[ $JSON -eq 1 ]]; then
        # Add to JSON array
        local entry
        entry=$(cat << JSONEOF
{"tool": "$tool_name", "current": "$version", "latest": "${latest:--}", "update_available": $([[ $update_available -eq 1 ]] && echo "true" || echo "false")}
JSONEOF
)
        if [[ "$JSON_RESULTS" == "[]" ]]; then
            JSON_RESULTS="[$entry"
        else
            JSON_RESULTS="$JSON_RESULTS, $entry"
        fi
    elif [[ $QUIET -eq 1 ]]; then
        # Only show if update available
        if [[ $update_available -eq 1 ]]; then
            printf "%-20s ${COLOR_YELLOW}%s${COLOR_RESET} -> ${COLOR_GREEN}%s${COLOR_RESET}\n" \
                "$tool_name" "$version" "$latest"
        fi
    else
        # Full output
        if [[ $update_available -eq 1 ]]; then
            printf "%-20s ${COLOR_YELLOW}%-15s${COLOR_RESET} ${COLOR_GREEN}%-15s${COLOR_RESET} ${COLOR_YELLOW}UPDATE${COLOR_RESET}\n" \
                "$tool_name" "$version" "$latest"
        else
            printf "%-20s ${COLOR_GREEN}%-15s${COLOR_RESET} %-15s OK\n" \
                "$tool_name" "$version" "${latest:--}"
        fi
    fi
}

# Main
main() {
    if [[ $QUIET -eq 0 ]] && [[ $JSON -eq 0 ]]; then
        echo ""
        echo -e "${COLOR_BLUE}Checking for updates...${COLOR_RESET}"
        echo ""
        printf "%-20s %-15s %-15s %s\n" "TOOL" "CURRENT" "LATEST" "STATUS"
        echo "────────────────────────────────────────────────────────────────"
    fi

    # Core tools
    check_tool "Feh" "feh"
    check_tool "Ghostty" "ghostty"
    check_tool "Nerd Fonts" "nerdfonts"
    check_tool "Node.js" "nodejs"
    check_tool "Local AI Tools" "ai_tools"

    # Extras
    check_tool "Fastfetch" "fastfetch"
    check_tool "Glow" "glow"
    check_tool "Go" "go"
    check_tool "Gum" "gum"
    check_tool "Python (uv)" "python-uv"
    check_tool "VHS" "vhs"
    check_tool "Zsh" "zsh"

    # Output JSON if requested
    if [[ $JSON -eq 1 ]]; then
        JSON_RESULTS="$JSON_RESULTS]"
        echo "$JSON_RESULTS"
    else
        echo ""
        echo "────────────────────────────────────────────────────────────────"
        echo -e "Tools checked: $TOOLS_CHECKED | Updates available: ${COLOR_YELLOW}$UPDATES_AVAILABLE${COLOR_RESET}"
        echo ""
    fi

    # Exit code based on updates
    if [[ $UPDATES_AVAILABLE -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

main "$@"
