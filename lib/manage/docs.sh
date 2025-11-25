#!/usr/bin/env bash
# lib/manage/docs.sh - Documentation commands for manage.sh
# Extracted for modularity compliance (300 line limit per module)
# Contains: cmd_docs, cmd_docs_build, cmd_docs_dev, cmd_docs_generate

set -euo pipefail

[ -z "${MANAGE_DOCS_SH_LOADED:-}" ] || return 0
MANAGE_DOCS_SH_LOADED=1

# cmd_docs - Router for documentation subcommands
cmd_docs() {
    local subcommand="${1:-}"

    if [[ "$subcommand" == "--help" ]] || [[ "$subcommand" == "-h" ]] || [[ -z "$subcommand" ]]; then
        cat << 'EOF'
Usage: ./manage.sh docs <subcommand> [options]

Documentation management operations

SUBCOMMANDS:
    build      Build Astro documentation site
    dev        Start Astro development server
    generate   Generate screenshot and API documentation

Use './manage.sh docs <subcommand> --help' for subcommand-specific options
EOF
        return 0
    fi

    shift
    case "$subcommand" in
        build) cmd_docs_build "$@" ;;
        dev) cmd_docs_dev "$@" ;;
        generate) cmd_docs_generate "$@" ;;
        *) log_error "Unknown docs subcommand: $subcommand"; return 2 ;;
    esac
}

# cmd_docs_build - Build Astro documentation site
cmd_docs_build() {
    local clean=0 output_dir="" show_help=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --clean) clean=1; shift ;;
            --output-dir) output_dir="$2"; shift 2 ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh docs build [options]

Build the Astro documentation site

OPTIONS:
    --clean             Clean build output before building
    --output-dir DIR    Specify custom output directory (default: docs/)
    --help, -h          Show this help message
EOF
        return 0
    fi

    show_progress "start" "Building Astro documentation site"

    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js is required but not installed"
        return 1
    fi

    if [[ ! -f "${SCRIPT_DIR}/package.json" ]]; then
        log_error "package.json not found in repository root"
        return 1
    fi

    if [[ "$clean" -eq 1 ]]; then
        local target_dir="${output_dir:-docs}"
        if [[ -d "$target_dir" ]]; then
            show_progress "info" "Cleaning output directory: $target_dir"
            [[ "${DRY_RUN:-0}" -eq 1 ]] && show_progress "info" "[DRY RUN] Would remove: $target_dir" || rm -rf "$target_dir"
        fi
    fi

    show_progress "info" "Running Astro build..."
    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would run: npx astro build"
    else
        [[ -n "$output_dir" ]] && export ASTRO_OUT_DIR="$output_dir"
        if npx astro build; then
            show_progress "success" "Documentation site built successfully"
            local target="${output_dir:-docs}"
            [[ ! -f "${target}/.nojekyll" ]] && touch "${target}/.nojekyll"
        else
            show_progress "error" "Astro build failed"
            return 1
        fi
    fi
    return 0
}

# cmd_docs_dev - Start Astro development server
cmd_docs_dev() {
    local port="" host="" show_help=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --port) port="$2"; shift 2 ;;
            --host) host="$2"; shift 2 ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh docs dev [options]

Start the Astro development server with hot reload

OPTIONS:
    --port PORT    Port to run dev server on (default: 4321)
    --host HOST    Host to bind to (default: localhost)
    --help, -h     Show this help message
EOF
        return 0
    fi

    show_progress "start" "Starting Astro development server"

    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js is required but not installed"
        return 1
    fi

    if [[ ! -f "${SCRIPT_DIR}/package.json" ]]; then
        log_error "package.json not found in repository root"
        return 1
    fi

    local dev_cmd="npx astro dev"
    [[ -n "$port" ]] && dev_cmd="$dev_cmd --port $port"
    [[ -n "$host" ]] && dev_cmd="$dev_cmd --host $host"

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would run: $dev_cmd"
        return 0
    fi

    show_progress "info" "Starting dev server..."
    log_info "Press Ctrl+C to stop the server"
    $dev_cmd
    return 0
}

# cmd_docs_generate - Generate screenshots and API documentation
cmd_docs_generate() {
    local generate_screenshots=0 generate_api=0 show_help=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --screenshots) generate_screenshots=1; shift ;;
            --api-docs) generate_api=1; shift ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh docs generate [options]

Generate screenshots and API documentation

OPTIONS:
    --screenshots    Generate screenshot gallery
    --api-docs       Generate API documentation from source
    --help, -h       Show this help message
EOF
        return 0
    fi

    # Default: generate both
    if [[ "$generate_screenshots" -eq 0 ]] && [[ "$generate_api" -eq 0 ]]; then
        generate_screenshots=1
        generate_api=1
    fi

    show_progress "start" "Generating documentation"
    local total_steps=0 current_step=0
    [[ "$generate_screenshots" -eq 1 ]] && total_steps=$((total_steps + 1))
    [[ "$generate_api" -eq 1 ]] && total_steps=$((total_steps + 1))

    if [[ "$generate_screenshots" -eq 1 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Generating screenshot gallery"
        if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
            show_progress "info" "[DRY RUN] Would generate screenshot gallery"
        else
            local screenshot_script="${SCRIPT_DIR}/scripts/svg_screenshot_capture.sh"
            if [[ -f "$screenshot_script" ]]; then
                bash "$screenshot_script" generate-gallery || { show_progress "error" "Screenshot generation failed"; return 1; }
                show_progress "success" "Screenshot gallery generated"
            else
                log_warn "Screenshot script not found"
            fi
        fi
    fi

    if [[ "$generate_api" -eq 1 ]]; then
        current_step=$((current_step + 1))
        show_step "$current_step" "$total_steps" "Generating API documentation"
        if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
            show_progress "info" "[DRY RUN] Would generate API documentation"
        else
            local api_script="${SCRIPT_DIR}/scripts/generate_api_docs.sh"
            if [[ -f "$api_script" ]]; then
                bash "$api_script" || { show_progress "error" "API doc generation failed"; return 1; }
                show_progress "success" "API documentation generated"
            else
                log_warn "API documentation script not found"
            fi
        fi
    fi

    show_progress "success" "Documentation generation complete"
    return 0
}

export -f cmd_docs cmd_docs_build cmd_docs_dev cmd_docs_generate
