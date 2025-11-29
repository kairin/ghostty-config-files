#!/usr/bin/env bash
# lib/docs/index_builder.sh - Index and navigation generation
# Constitutional: Modular Architecture (<300 lines)
set -euo pipefail

[[ -n "${_LIB_DOCS_INDEX_BUILDER_SH:-}" ]] && return 0
readonly _LIB_DOCS_INDEX_BUILDER_SH=1

readonly SITE_URL_DEFAULT="https://example.github.io/ghostty-config-files"

# Scan directory for documentation files
collect_doc_pages() {
    local doc_root="$1"
    local extension="${2:-.md}"

    if [[ ! -d "$doc_root" ]]; then
        echo "ERROR: Documentation root not found: $doc_root" >&2
        return 1
    fi

    find "$doc_root" -name "*${extension}" -type f 2>/dev/null | sort
}

# Scan directory for generated HTML files
collect_html_pages() {
    local output_dir="$1"

    if [[ ! -d "$output_dir" ]]; then
        echo "ERROR: Output directory not found: $output_dir" >&2
        return 1
    fi

    find "$output_dir" -name "*.html" -type f 2>/dev/null | sort
}

# Generate main documentation index page
generate_index_page() {
    local output_dir="$1"
    local site_title="${2:-Ghostty Configuration Files}"

    local index_file="${output_dir}/index.html"

    mkdir -p "$output_dir"

    cat > "$index_file" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$site_title - Documentation</title>
    <style>
        :root { --primary: #0ea5e9; --bg: #f9fafb; --text: #1f2937; }
        body { font-family: system-ui, sans-serif; background: var(--bg); color: var(--text); line-height: 1.6; margin: 0; padding: 2rem; }
        .container { max-width: 1000px; margin: 0 auto; }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; }
        .hero { text-align: center; padding: 3rem 0; }
        .features { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin: 2rem 0; }
        .card { background: white; padding: 1.5rem; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .card h3 { margin-top: 0; }
        .btn { display: inline-block; background: var(--primary); color: white; padding: 0.75rem 1.5rem; border-radius: 6px; text-decoration: none; }
        .btn:hover { opacity: 0.9; }
        pre { background: #1f2937; color: #10b981; padding: 1rem; border-radius: 6px; overflow-x: auto; }
        a { color: var(--primary); }
    </style>
</head>
<body>
<div class="container">
    <div class="hero">
        <h1>$site_title</h1>
        <p>Comprehensive terminal environment setup with 2025 optimizations and AI integration</p>
        <a href="/installation/" class="btn">Get Started</a>
    </div>

    <div class="features">
        <div class="card">
            <h3>2025 Optimizations</h3>
            <p>Latest Ghostty features with CGroup single-instance performance.</p>
        </div>
        <div class="card">
            <h3>AI Integration</h3>
            <p>Claude Code and Gemini CLI pre-configured for enhanced workflow.</p>
        </div>
        <div class="card">
            <h3>One-Command Setup</h3>
            <p>Fresh Ubuntu to fully configured terminal in under 10 minutes.</p>
        </div>
        <div class="card">
            <h3>Local CI/CD</h3>
            <p>Zero-cost local runners for validation before GitHub deployment.</p>
        </div>
    </div>

    <h2>Quick Start</h2>
    <pre><code>cd ~/Apps/ghostty-config-files
./start.sh</code></pre>

    <h2>Documentation</h2>
    <ul>
        <li><a href="/installation/">Installation Guide</a></li>
        <li><a href="/screenshots/">Screenshots Gallery</a></li>
        <li><a href="https://github.com/ghostty-config-files">GitHub Repository</a></li>
    </ul>
</div>
</body>
</html>
EOF

    echo "$index_file"
}

# Generate index of all documentation pages
generate_page_index() {
    local -n pages=$1
    local format="${2:-html}"

    case "$format" in
        html)
            echo "<ul class=\"page-index\">"
            for page in "${pages[@]}"; do
                local basename
                basename=$(basename "$page" .html)
                local title="${basename//-/ }"
                title="${title^}"
                echo "  <li><a href=\"$page\">$title</a></li>"
            done
            echo "</ul>"
            ;;
        json)
            echo "["
            local first=true
            for page in "${pages[@]}"; do
                [[ "$first" == "false" ]] && echo ","
                first=false
                echo -n "  {\"path\": \"$page\", \"name\": \"$(basename "$page" .html)\"}"
            done
            echo ""
            echo "]"
            ;;
        text)
            for page in "${pages[@]}"; do
                echo "$page"
            done
            ;;
    esac
}

# Generate XML sitemap for SEO
generate_sitemap() {
    local output_dir="$1"
    local site_url="${2:-$SITE_URL_DEFAULT}"

    local sitemap_file="${output_dir}/sitemap.xml"
    local today
    today=$(date +%Y-%m-%d)

    cat > "$sitemap_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
EOF

    # Add index page
    cat >> "$sitemap_file" <<EOF
  <url>
    <loc>${site_url}/</loc>
    <lastmod>${today}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
EOF

    # Find and add all HTML pages
    if [[ -d "$output_dir" ]]; then
        while IFS= read -r -d '' page; do
            local rel_path="${page#$output_dir}"
            [[ "$rel_path" == "/index.html" ]] && continue
            [[ "$rel_path" == "/sitemap.xml" ]] && continue

            cat >> "$sitemap_file" <<EOF
  <url>
    <loc>${site_url}${rel_path}</loc>
    <lastmod>${today}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.8</priority>
  </url>
EOF
        done < <(find "$output_dir" -name "*.html" -print0 2>/dev/null)
    fi

    cat >> "$sitemap_file" <<EOF
</urlset>
EOF

    echo "$sitemap_file"
}

# Generate navigation HTML structure
generate_navigation() {
    local current_page="$1"
    local -n nav_items=$2

    cat <<EOF
<nav class="main-nav">
    <ul>
EOF

    for item in "${nav_items[@]}"; do
        local path="${item%%|*}"
        local label="${item##*|}"
        local active=""

        [[ "$path" == "$current_page" ]] && active=" class=\"active\""

        echo "        <li$active><a href=\"$path\">$label</a></li>"
    done

    cat <<EOF
    </ul>
</nav>
EOF
}

# Generate breadcrumb navigation
generate_breadcrumbs() {
    local page_path="$1"
    local site_title="${2:-Home}"

    # Split path into components
    local IFS='/'
    read -ra parts <<< "$page_path"

    cat <<EOF
<nav class="breadcrumbs" aria-label="Breadcrumb">
    <ol>
        <li><a href="/">$site_title</a></li>
EOF

    local current_path=""
    for part in "${parts[@]}"; do
        [[ -z "$part" ]] && continue
        [[ "$part" == "index.html" ]] && continue

        current_path+="/$part"
        local label="${part//-/ }"
        label="${label%.html}"
        label="${label^}"

        if [[ "$part" == "${parts[-1]}" ]]; then
            echo "        <li aria-current=\"page\">$label</li>"
        else
            echo "        <li><a href=\"$current_path/\">$label</a></li>"
        fi
    done

    cat <<EOF
    </ol>
</nav>
EOF
}

# Ensure URL has trailing slash
ensure_trailing_slash() {
    local url="$1"

    if [[ "$url" != */ ]] && [[ ! "$url" =~ \.[a-z]+$ ]]; then
        echo "${url}/"
    else
        echo "$url"
    fi
}

# Extract title from HTML page
get_page_title() {
    local file="$1"

    if [[ -f "$file" ]]; then
        grep -oP '(?<=<title>).*(?=</title>)' "$file" 2>/dev/null | head -1
    fi
}
