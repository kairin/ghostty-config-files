#!/usr/bin/env bash
# lib/docs/asset_compiler.sh - CSS/JS asset handling and compilation
# Constitutional: Modular Architecture (<300 lines)
set -euo pipefail

[[ -n "${_LIB_DOCS_ASSET_COMPILER_SH:-}" ]] && return 0
readonly _LIB_DOCS_ASSET_COMPILER_SH=1

readonly ASSETS_SUBDIR="assets"
readonly CSS_SUBDIR="assets/css"
readonly JS_SUBDIR="assets/js"
readonly IMG_SUBDIR="assets/images"

# Create asset directory structure
setup_asset_directories() {
    local output_dir="$1"

    mkdir -p "${output_dir}/${CSS_SUBDIR}" \
             "${output_dir}/${JS_SUBDIR}" \
             "${output_dir}/${IMG_SUBDIR}" \
             "${output_dir}/screenshots"

    echo "Created asset directories in $output_dir"
    return 0
}

# Generate main CSS stylesheet
generate_css() {
    local output_dir="$1"
    local css_file="${output_dir}/${CSS_SUBDIR}/main.css"

    mkdir -p "$(dirname "$css_file")"

    cat > "$css_file" <<'EOF'
/* Ghostty Documentation - Main Stylesheet */
/* Constitutional Compliance: Astro.build + Tailwind-inspired utility classes */

:root {
    --color-primary: #0ea5e9;
    --color-primary-dark: #0284c7;
    --color-success: #10b981;
    --color-warning: #f59e0b;
    --color-error: #ef4444;
    --color-bg: #f9fafb;
    --color-bg-alt: #ffffff;
    --color-text: #1f2937;
    --color-text-muted: #6b7280;
    --color-border: #e5e7eb;
    --color-code-bg: #1f2937;
    --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    --font-mono: 'JetBrains Mono', 'Fira Code', monospace;
    --shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
    --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
    --radius-sm: 4px;
    --radius-md: 8px;
    --radius-lg: 12px;
}

*, *::before, *::after { box-sizing: border-box; }

body {
    font-family: var(--font-sans);
    font-size: 16px;
    line-height: 1.6;
    color: var(--color-text);
    background: var(--color-bg);
    margin: 0;
    padding: 0;
}

/* Layout */
.container { max-width: 1200px; margin: 0 auto; padding: 0 1.5rem; }
.container-sm { max-width: 800px; margin: 0 auto; padding: 0 1.5rem; }

/* Typography */
h1, h2, h3, h4, h5, h6 { font-weight: 600; line-height: 1.25; margin: 1.5rem 0 1rem; }
h1 { font-size: 2.5rem; }
h2 { font-size: 2rem; border-bottom: 1px solid var(--color-border); padding-bottom: 0.5rem; }
h3 { font-size: 1.5rem; }
h4 { font-size: 1.25rem; }
p { margin: 0 0 1rem; }
a { color: var(--color-primary); text-decoration: none; }
a:hover { text-decoration: underline; }

/* Code */
code {
    font-family: var(--font-mono);
    font-size: 0.9em;
    background: var(--color-code-bg);
    color: var(--color-success);
    padding: 0.2em 0.4em;
    border-radius: var(--radius-sm);
}
pre {
    font-family: var(--font-mono);
    font-size: 0.9rem;
    background: var(--color-code-bg);
    color: var(--color-success);
    padding: 1rem;
    border-radius: var(--radius-md);
    overflow-x: auto;
    margin: 1rem 0;
}
pre code { background: none; padding: 0; }

/* Components */
.card {
    background: var(--color-bg-alt);
    border-radius: var(--radius-md);
    padding: 1.5rem;
    box-shadow: var(--shadow-md);
    margin-bottom: 1rem;
}
.btn {
    display: inline-block;
    padding: 0.75rem 1.5rem;
    border-radius: var(--radius-md);
    font-weight: 500;
    text-decoration: none;
    cursor: pointer;
    transition: opacity 0.2s, transform 0.2s;
}
.btn:hover { opacity: 0.9; transform: translateY(-1px); }
.btn-primary { background: var(--color-primary); color: white; }
.btn-success { background: var(--color-success); color: white; }

/* Header/Nav */
header {
    background: var(--color-bg-alt);
    border-bottom: 1px solid var(--color-border);
    padding: 1rem 0;
    position: sticky;
    top: 0;
    z-index: 100;
}
nav { display: flex; justify-content: space-between; align-items: center; }
nav a { color: var(--color-text); margin-left: 1.5rem; }
nav a:hover { color: var(--color-primary); text-decoration: none; }

/* Footer */
footer {
    margin-top: 4rem;
    padding: 2rem 0;
    border-top: 1px solid var(--color-border);
    text-align: center;
    color: var(--color-text-muted);
}

/* Utilities */
.text-center { text-align: center; }
.text-muted { color: var(--color-text-muted); }
.mt-1 { margin-top: 0.5rem; }
.mt-2 { margin-top: 1rem; }
.mt-4 { margin-top: 2rem; }
.mb-1 { margin-bottom: 0.5rem; }
.mb-2 { margin-bottom: 1rem; }
.mb-4 { margin-bottom: 2rem; }
.grid { display: grid; gap: 1.5rem; }
.grid-2 { grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); }
.grid-4 { grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); }

/* Screenshots Gallery */
.screenshot-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 2rem; }
.screenshot-item { background: var(--color-bg-alt); border-radius: var(--radius-lg); padding: 1.5rem; box-shadow: var(--shadow-md); }
.screenshot-item img, .screenshot-item svg { width: 100%; height: auto; border-radius: var(--radius-md); cursor: zoom-in; }
.screenshot-item h4 { margin: 1rem 0 0.5rem; }

/* Responsive */
@media (max-width: 768px) {
    h1 { font-size: 2rem; }
    h2 { font-size: 1.5rem; }
    .container { padding: 0 1rem; }
    .screenshot-grid { grid-template-columns: 1fr; }
}
EOF

    echo "$css_file"
}

# Copy static assets from source to output
copy_assets() {
    local source_dir="$1"
    local output_dir="$2"

    if [[ ! -d "$source_dir" ]]; then
        echo "WARN: Source assets directory not found: $source_dir"
        return 0
    fi

    mkdir -p "${output_dir}/${ASSETS_SUBDIR}"

    # Copy all assets
    if cp -r "${source_dir}"/* "${output_dir}/${ASSETS_SUBDIR}/" 2>/dev/null; then
        echo "Copied assets from $source_dir to $output_dir"
        return 0
    else
        echo "WARN: No assets to copy from $source_dir"
        return 0
    fi
}

# Copy screenshot images to output
copy_screenshots() {
    local source_dir="$1"
    local output_dir="$2"
    local count=0

    mkdir -p "${output_dir}/screenshots"

    if [[ -d "$source_dir" ]]; then
        local file
        for file in "$source_dir"/*.svg "$source_dir"/*.png "$source_dir"/*.jpg "$source_dir"/*.gif; do
            [[ -f "$file" ]] || continue
            cp "$file" "${output_dir}/screenshots/"
            ((count++))
        done
    fi

    echo "$count"
}

# Create .nojekyll file for GitHub Pages (CRITICAL)
ensure_nojekyll() {
    local output_dir="$1"
    local nojekyll_file="${output_dir}/.nojekyll"

    touch "$nojekyll_file"
    echo "Created .nojekyll file (CRITICAL for GitHub Pages)"
    return 0
}

# Create CNAME file for custom domain
create_cname() {
    local output_dir="$1"
    local domain="$2"

    if [[ -n "$domain" ]]; then
        echo "$domain" > "${output_dir}/CNAME"
        echo "Created CNAME file for $domain"
    fi

    return 0
}

# Complete asset compilation workflow
compile_all_assets() {
    local output_dir="$1"
    local assets_source="${2:-}"
    local screenshots_source="${3:-}"

    echo "Compiling assets to $output_dir..."

    # Create directory structure
    setup_asset_directories "$output_dir"

    # Generate CSS
    local css_path
    css_path=$(generate_css "$output_dir")
    echo "Generated: $css_path"

    # Copy source assets if provided
    if [[ -n "$assets_source" ]]; then
        copy_assets "$assets_source" "$output_dir"
    fi

    # Copy screenshots if provided
    if [[ -n "$screenshots_source" ]]; then
        local screenshot_count
        screenshot_count=$(copy_screenshots "$screenshots_source" "$output_dir")
        echo "Copied $screenshot_count screenshots"
    fi

    # CRITICAL: Create .nojekyll for GitHub Pages
    ensure_nojekyll "$output_dir"

    echo "Asset compilation complete"
    return 0
}
