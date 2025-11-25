#!/usr/bin/env bash
# lib/manage/screenshots.sh - Screenshot commands for manage.sh
# Extracted for modularity compliance (300 line limit per module)
# Contains: cmd_screenshots, cmd_screenshots_capture, cmd_screenshots_generate_gallery

set -euo pipefail

[ -z "${MANAGE_SCREENSHOTS_SH_LOADED:-}" ] || return 0
MANAGE_SCREENSHOTS_SH_LOADED=1

# cmd_screenshots - Router for screenshot subcommands
cmd_screenshots() {
    local subcommand="${1:-}"

    if [[ "$subcommand" == "--help" ]] || [[ "$subcommand" == "-h" ]] || [[ -z "$subcommand" ]]; then
        cat << 'EOF'
Usage: ./manage.sh screenshots <subcommand> [options]

Screenshot capture and gallery generation

SUBCOMMANDS:
    capture           Capture a new screenshot
    generate-gallery  Generate HTML gallery from screenshots

Use './manage.sh screenshots <subcommand> --help' for subcommand-specific options
EOF
        return 0
    fi

    shift
    case "$subcommand" in
        capture) cmd_screenshots_capture "$@" ;;
        generate-gallery) cmd_screenshots_generate_gallery "$@" ;;
        *) log_error "Unknown screenshots subcommand: $subcommand"; return 2 ;;
    esac
}

# cmd_screenshots_capture - Capture a new screenshot
cmd_screenshots_capture() {
    local show_help=0 category="" name="" description=""

    for arg in "$@"; do
        [[ "$arg" == "--help" || "$arg" == "-h" ]] && show_help=1 && break
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh screenshots capture <category> <name> <description>

Capture a new screenshot for documentation

ARGUMENTS:
    category        Screenshot category (e.g., terminal, config, ui)
    name            Screenshot name (alphanumeric, hyphens allowed)
    description     Description of what the screenshot shows

OPTIONS:
    --help, -h     Show this help message
EOF
        return 0
    fi

    category="${1:-}"
    name="${2:-}"
    description="${3:-}"

    if [[ -z "$category" ]] || [[ -z "$name" ]] || [[ -z "$description" ]]; then
        log_error "Missing required arguments"
        echo "Usage: ./manage.sh screenshots capture <category> <name> <description>"
        return 2
    fi

    [[ ! "$category" =~ ^[a-zA-Z0-9-]+$ ]] && { log_error "Category must contain only alphanumeric characters and hyphens"; return 2; }
    [[ ! "$name" =~ ^[a-zA-Z0-9-]+$ ]] && { log_error "Name must contain only alphanumeric characters and hyphens"; return 2; }

    show_progress "start" "Capturing screenshot: $category/$name"

    local screenshots_dir="${SCRIPT_DIR}/documentations/screenshots/${category}"
    ensure_dir "$screenshots_dir" || { log_error "Failed to create screenshots directory: $screenshots_dir"; return 1; }

    local screenshot_path="${screenshots_dir}/${name}.png"

    if [[ -f "$screenshot_path" ]]; then
        log_warn "Screenshot already exists: $screenshot_path"
        if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
            show_progress "info" "[DRY RUN] Would create backup of existing screenshot"
        else
            source "${SCRIPTS_DIR}/backup_utils.sh"
            create_backup "$screenshot_path" "${category}-${name}" >/dev/null || { log_error "Failed to backup existing screenshot"; return 1; }
            log_info "Backup created for existing screenshot"
        fi
    fi

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would capture screenshot to: $screenshot_path"
        return 0
    fi

    local capture_script="${SCRIPT_DIR}/scripts/svg_screenshot_capture.sh"
    if [[ -f "$capture_script" ]]; then
        show_progress "info" "Starting screenshot capture process..."
        log_info "Category: $category | Name: $name | Output: $screenshot_path"

        if bash "$capture_script" capture "$screenshot_path" "$description"; then
            show_progress "success" "Screenshot captured: $screenshot_path"
            cat > "${screenshot_path}.meta" << EOF
Category: $category
Name: $name
Description: $description
Captured: $(date '+%Y-%m-%d %H:%M:%S')
User: $USER
EOF
            log_info "Metadata saved: ${screenshot_path}.meta"
        else
            show_progress "error" "Screenshot capture failed"
            return 1
        fi
    else
        log_error "Screenshot capture script not found: $capture_script"
        return 1
    fi
    return 0
}

# cmd_screenshots_generate_gallery - Generate HTML gallery from screenshots
cmd_screenshots_generate_gallery() {
    local output_file="" show_help=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output) output_file="$2"; shift 2 ;;
            --help|-h) show_help=1; shift ;;
            *) log_error "Unknown option: $1"; return 2 ;;
        esac
    done

    if [[ "$show_help" -eq 1 ]]; then
        cat << 'EOF'
Usage: ./manage.sh screenshots generate-gallery [options]

Generate an HTML gallery from all captured screenshots

OPTIONS:
    --output FILE   Output HTML file path (default: documentations/screenshots/gallery.html)
    --help, -h      Show this help message
EOF
        return 0
    fi

    output_file="${output_file:-${SCRIPT_DIR}/documentations/screenshots/gallery.html}"
    show_progress "start" "Generating screenshot gallery"

    local screenshots_base="${SCRIPT_DIR}/documentations/screenshots"
    if [[ ! -d "$screenshots_base" ]]; then
        log_warn "No screenshots directory found: $screenshots_base"
        return 1
    fi

    local screenshot_count
    screenshot_count=$(find "$screenshots_base" -type f -name "*.png" 2>/dev/null | wc -l)

    if [[ "$screenshot_count" -eq 0 ]]; then
        log_warn "No screenshots found in: $screenshots_base"
        return 1
    fi

    show_progress "info" "Found $screenshot_count screenshot(s)"

    if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
        show_progress "info" "[DRY RUN] Would generate gallery with $screenshot_count screenshots"
        return 0
    fi

    show_progress "info" "Generating HTML gallery..."
    _generate_gallery_html "$screenshots_base" "$output_file"

    show_progress "success" "Gallery generated: $output_file"
    return 0
}

# Helper: Generate gallery HTML content
_generate_gallery_html() {
    local screenshots_base="$1"
    local output_file="$2"

    cat > "$output_file" << 'GALLERY_HTML'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Screenshot Gallery - Ghostty Configuration</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0d1117; color: #c9d1d9; padding: 2rem; }
        h1 { margin-bottom: 2rem; text-align: center; }
        .category { margin-bottom: 3rem; }
        .category h2 { color: #58a6ff; margin-bottom: 1rem; padding-bottom: 0.5rem; border-bottom: 1px solid #30363d; }
        .gallery { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.5rem; }
        .screenshot { background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 1rem; transition: transform 0.2s; }
        .screenshot:hover { transform: translateY(-4px); }
        .screenshot img { width: 100%; border-radius: 4px; margin-bottom: 0.5rem; }
        .screenshot h3 { color: #58a6ff; font-size: 1rem; margin-bottom: 0.5rem; }
        .screenshot p { color: #8b949e; font-size: 0.875rem; line-height: 1.5; }
    </style>
</head>
<body>
    <h1>Screenshot Gallery</h1>
GALLERY_HTML

    # Organize by category and add screenshots
    for category_dir in "$screenshots_base"/*/; do
        [[ -d "$category_dir" ]] || continue
        local category_name
        category_name=$(basename "$category_dir")

        echo "    <div class=\"category\"><h2>$category_name</h2><div class=\"gallery\">" >> "$output_file"

        for screenshot in "$category_dir"*.png; do
            [[ -f "$screenshot" ]] || continue
            local name rel_path description=""
            name=$(basename "$screenshot" .png)
            rel_path="${category_name}/$(basename "$screenshot")"

            [[ -f "${screenshot}.meta" ]] && description=$(grep "^Description:" "${screenshot}.meta" | cut -d: -f2- | sed 's/^ //')

            cat >> "$output_file" << EOF
            <div class="screenshot">
                <img src="${rel_path}" alt="${name}">
                <h3>${name}</h3>
                <p>${description:-No description available}</p>
            </div>
EOF
        done

        echo "        </div></div>" >> "$output_file"
    done

    echo "</body></html>" >> "$output_file"
}

export -f cmd_screenshots cmd_screenshots_capture cmd_screenshots_generate_gallery
