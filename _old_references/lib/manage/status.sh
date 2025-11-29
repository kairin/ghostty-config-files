#!/usr/bin/env bash
# lib/manage/status.sh - Status and info commands for manage.sh
# Extracted for modularity compliance (300 line limit per module)
# Contains: cmd_status, cmd_info, _check_component_status

set -euo pipefail

[ -z "${MANAGE_STATUS_SH_LOADED:-}" ] || return 0
MANAGE_STATUS_SH_LOADED=1

# cmd_status - Show installation and component status
cmd_status() {
    local verbose=0 json_output=0 show_help=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v) verbose=1; shift ;;
            --json) json_output=1; shift ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh status [options]

Show current installation status and component versions

OPTIONS:
    --verbose, -v   Show detailed status information
    --json          Output status in JSON format
    --help, -h      Show this help message

EXAMPLES:
    # Quick status check
    ./manage.sh status

    # Detailed status with versions
    ./manage.sh status --verbose

    # JSON output for scripting
    ./manage.sh status --json
EOF
        return 0
    fi

    if [[ "$json_output" -eq 1 ]]; then
        _output_status_json "$verbose"
    else
        _output_status_human "$verbose"
    fi
}

# Helper: Output status in human-readable format
_output_status_human() {
    local verbose="$1"

    echo "==============================================="
    echo "  Ghostty Configuration Status"
    echo "==============================================="
    echo ""

    _check_component_status "Ghostty" "ghostty" "$verbose"
    _check_component_status "ZSH" "zsh" "$verbose"
    _check_component_status "fnm" "fnm" "$verbose"
    _check_component_status "Node.js" "node" "$verbose"
    _check_component_status "gum" "gum" "$verbose"
    _check_component_status "jq" "jq" "$verbose"

    echo ""
    echo "-----------------------------------------------"

    local config_file="${HOME}/.config/ghostty/config"
    if [[ -f "$config_file" ]]; then
        echo "[OK] Configuration: $config_file"
        if [[ "$verbose" -eq 1 ]]; then
            echo "     Lines: $(wc -l < "$config_file")"
            echo "     Modified: $(stat -c %y "$config_file" 2>/dev/null | cut -d. -f1 || stat -f %Sm "$config_file" 2>/dev/null)"
        fi
    else
        echo "[--] Configuration: Not found"
    fi

    local context_menu="${HOME}/.local/share/nautilus/scripts/Open in Ghostty"
    if [[ -f "$context_menu" ]] && [[ -x "$context_menu" ]]; then
        echo "[OK] Context Menu: Installed"
    else
        echo "[--] Context Menu: Not installed"
    fi

    echo ""
    echo "==============================================="
}

# Helper: Check status of a single component
_check_component_status() {
    local name="$1"
    local command="$2"
    local verbose="$3"

    if command -v "$command" &>/dev/null; then
        local version=""
        case "$command" in
            ghostty) version=$($command --version 2>&1 | head -1 || echo "unknown") ;;
            node) version=$($command --version 2>&1 | head -1 || echo "unknown") ;;
            fnm) version=$($command --version 2>&1 | head -1 || echo "unknown") ;;
            zsh) version=$($command --version 2>&1 | head -1 || echo "unknown") ;;
            gum) version=$($command --version 2>&1 | head -1 || echo "unknown") ;;
            jq) version=$($command --version 2>&1 | head -1 || echo "unknown") ;;
            *) version="installed" ;;
        esac

        if [[ "$verbose" -eq 1 ]]; then
            printf "[OK] %-12s %s\n" "$name:" "$version"
            printf "     Path: %s\n" "$(command -v "$command")"
        else
            printf "[OK] %-12s %s\n" "$name:" "$version"
        fi
    else
        printf "[--] %-12s Not installed\n" "$name:"
    fi
}

# Helper: Output status in JSON format
_output_status_json() {
    local verbose="$1"

    local ghostty_status ghostty_version="" node_status node_version="" fnm_status fnm_version=""
    local zsh_status zsh_version="" gum_status jq_status config_status context_menu_status

    if command -v ghostty &>/dev/null; then
        ghostty_status="installed"
        ghostty_version=$(ghostty --version 2>&1 | head -1 || echo "unknown")
    else
        ghostty_status="not_installed"
    fi

    if command -v node &>/dev/null; then
        node_status="installed"
        node_version=$(node --version 2>&1 | head -1 || echo "unknown")
    else
        node_status="not_installed"
    fi

    if command -v fnm &>/dev/null; then
        fnm_status="installed"
        fnm_version=$(fnm --version 2>&1 | head -1 || echo "unknown")
    else
        fnm_status="not_installed"
    fi

    if command -v zsh &>/dev/null; then
        zsh_status="installed"
        zsh_version=$(zsh --version 2>&1 | head -1 || echo "unknown")
    else
        zsh_status="not_installed"
    fi

    gum_status=$(command -v gum &>/dev/null && echo "installed" || echo "not_installed")
    jq_status=$(command -v jq &>/dev/null && echo "installed" || echo "not_installed")
    config_status=$([[ -f "${HOME}/.config/ghostty/config" ]] && echo "exists" || echo "missing")
    context_menu_status=$([[ -f "${HOME}/.local/share/nautilus/scripts/Open in Ghostty" ]] && echo "installed" || echo "not_installed")

    cat << EOF
{
  "timestamp": "$(date -Iseconds)",
  "components": {
    "ghostty": {"status": "$ghostty_status", "version": "$ghostty_version"},
    "node": {"status": "$node_status", "version": "$node_version"},
    "fnm": {"status": "$fnm_status", "version": "$fnm_version"},
    "zsh": {"status": "$zsh_status", "version": "$zsh_version"},
    "gum": {"status": "$gum_status"},
    "jq": {"status": "$jq_status"}
  },
  "configuration": {
    "config_file": "$config_status",
    "context_menu": "$context_menu_status"
  }
}
EOF
}

# cmd_info - Show detailed repository information
cmd_info() {
    local show_help=0

    for arg in "$@"; do
        [[ "$arg" == "--help" || "$arg" == "-h" ]] && show_help=1 && break
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh info

Show detailed information about the repository and configuration

DISPLAYS:
    - Repository version and location
    - Git branch and status
    - Environment variables
    - Configuration file locations
    - Available commands
EOF
        return 0
    fi

    echo "==============================================="
    echo "  Ghostty Configuration Repository Info"
    echo "==============================================="
    echo ""
    echo "Repository: ${SCRIPT_DIR:-$(pwd)}"
    echo "Version: $(git describe --tags --always 2>/dev/null || echo 'N/A')"
    echo "Branch: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo ""
    echo "Paths:"
    echo "  Config: ${HOME}/.config/ghostty/"
    echo "  Scripts: ${SCRIPT_DIR:-$(pwd)}/scripts/"
    echo "  Logs: ${SCRIPT_DIR:-$(pwd)}/logs/"
    echo ""
    echo "Environment:"
    echo "  GHOSTTY_RESOURCES_DIR: ${GHOSTTY_RESOURCES_DIR:-not set}"
    echo "  SHELL: ${SHELL:-not set}"
    echo "  TERM: ${TERM:-not set}"
    echo ""
    echo "==============================================="
}

export -f cmd_status cmd_info
