#!/usr/bin/env bash
#
# lib/docs/markdown_generator.sh - Markdown to HTML conversion utilities
#
# Purpose: Generate HTML content from markdown and template processing
# Dependencies: None (standalone module)
# Constitutional: Principle V - Modular Architecture (<300 lines)
#
# Functions:
#   - generate_html_head(): Create HTML head section
#   - generate_html_footer(): Create HTML footer section
#   - escape_html(): HTML entity escaping
#   - markdown_to_html_basic(): Basic markdown conversion
#

set -euo pipefail

# Source guard - prevent redundant loading
[[ -n "${_LIB_DOCS_MARKDOWN_GENERATOR_SH:-}" ]] && return 0
readonly _LIB_DOCS_MARKDOWN_GENERATOR_SH=1

# Module constants
readonly DEFAULT_SITE_TITLE="Ghostty Configuration Files"
readonly DEFAULT_SITE_DESC="Comprehensive terminal environment setup with 2025 optimizations"

# ============================================================================
# HTML GENERATION
# ============================================================================

# Function: generate_html_head
# Purpose: Generate HTML head section with meta tags and styles
# Args:
#   $1 - Page title
#   $2 - Page description (optional)
#   $3 - Base URL (optional)
# Returns:
#   HTML head section (stdout)
generate_html_head() {
    local title="${1:-$DEFAULT_SITE_TITLE}"
    local description="${2:-$DEFAULT_SITE_DESC}"
    local base_url="${3:-}"

    cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="$description">
    <meta name="generator" content="ghostty-docs-generator">
    <title>$title</title>
    <style>
        :root {
            --color-primary: #0ea5e9;
            --color-bg: #f9fafb;
            --color-text: #1f2937;
            --color-border: #e5e7eb;
            --color-code-bg: #1f2937;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: var(--color-text);
            background: var(--color-bg);
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 2rem; }
        header { background: white; border-bottom: 1px solid var(--color-border); padding: 1rem 0; }
        nav { max-width: 1200px; margin: 0 auto; padding: 0 2rem; display: flex; justify-content: space-between; align-items: center; }
        nav a { color: var(--color-text); text-decoration: none; margin-left: 2rem; }
        nav a:hover { color: var(--color-primary); }
        h1, h2, h3 { margin: 1.5rem 0 1rem; }
        h1 { font-size: 2.5rem; }
        h2 { font-size: 1.75rem; border-bottom: 1px solid var(--color-border); padding-bottom: 0.5rem; }
        p { margin-bottom: 1rem; }
        code { background: var(--color-code-bg); color: #10b981; padding: 0.2rem 0.4rem; border-radius: 4px; font-size: 0.9em; }
        pre { background: var(--color-code-bg); padding: 1rem; border-radius: 8px; overflow-x: auto; margin: 1rem 0; }
        pre code { background: none; padding: 0; }
        .card { background: white; border-radius: 8px; padding: 1.5rem; box-shadow: 0 1px 3px rgba(0,0,0,0.1); margin-bottom: 1rem; }
        footer { margin-top: 4rem; padding: 2rem 0; border-top: 1px solid var(--color-border); text-align: center; color: #6b7280; }
    </style>
</head>
<body>
EOF
}

# Function: generate_html_header
# Purpose: Generate page header with navigation
# Args:
#   $1 - Site title
#   $2 - Active page name (optional)
# Returns:
#   HTML header section (stdout)
generate_html_header() {
    local site_title="${1:-$DEFAULT_SITE_TITLE}"
    local active_page="${2:-}"

    cat <<EOF
<header>
    <nav>
        <a href="/" style="font-weight: bold; font-size: 1.25rem;">$site_title</a>
        <div>
            <a href="/">Home</a>
            <a href="/installation/">Installation</a>
            <a href="/screenshots/">Screenshots</a>
            <a href="https://github.com/ghostty-config-files" target="_blank">GitHub</a>
        </div>
    </nav>
</header>
EOF
}

# Function: generate_html_footer
# Purpose: Generate HTML footer section
# Args:
#   $1 - Additional footer content (optional)
# Returns:
#   HTML footer section (stdout)
# shellcheck disable=SC2120 # Function designed for external calls with optional args
generate_html_footer() {
    local extra_content="${1:-}"

    cat <<EOF
<footer>
    <div class="container">
        <p>Built with Astro.build - Deployed on GitHub Pages</p>
        $extra_content
    </div>
</footer>
</body>
</html>
EOF
}

# ============================================================================
# TEXT PROCESSING
# ============================================================================

# Function: escape_html
# Purpose: Escape HTML special characters
# Args:
#   $1 - Text to escape
# Returns:
#   Escaped text (stdout)
escape_html() {
    local text="$1"

    text="${text//&/&amp;}"
    text="${text//</&lt;}"
    text="${text//>/&gt;}"
    text="${text//\"/&quot;}"
    text="${text//\'/&#39;}"

    echo "$text"
}

# Function: markdown_to_html_basic
# Purpose: Basic markdown to HTML conversion (headers, code, links)
# Args:
#   $1 - Markdown text or file path
# Returns:
#   HTML content (stdout)
# Note: This is a basic converter. Use proper markdown processor for complex content.
markdown_to_html_basic() {
    local input="$1"
    local content

    # Check if input is a file
    if [[ -f "$input" ]]; then
        content=$(cat "$input")
    else
        content="$input"
    fi

    # Process line by line
    local in_code_block=false
    local output=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Code blocks
        if [[ "$line" =~ ^\`\`\` ]]; then
            if [[ "$in_code_block" == "true" ]]; then
                output+="</code></pre>"
                in_code_block=false
            else
                local lang="${line#\`\`\`}"
                output+="<pre><code class=\"language-${lang:-text}\">"
                in_code_block=true
            fi
            continue
        fi

        if [[ "$in_code_block" == "true" ]]; then
            output+="$(escape_html "$line")"$'\n'
            continue
        fi

        # Headers
        if [[ "$line" =~ ^######\  ]]; then
            output+="<h6>${line#\#\#\#\#\#\# }</h6>"
        elif [[ "$line" =~ ^#####\  ]]; then
            output+="<h5>${line#\#\#\#\#\# }</h5>"
        elif [[ "$line" =~ ^####\  ]]; then
            output+="<h4>${line#\#\#\#\# }</h4>"
        elif [[ "$line" =~ ^###\  ]]; then
            output+="<h3>${line#\#\#\# }</h3>"
        elif [[ "$line" =~ ^##\  ]]; then
            output+="<h2>${line#\#\# }</h2>"
        elif [[ "$line" =~ ^#\  ]]; then
            output+="<h1>${line#\# }</h1>"
        # Empty line = paragraph break
        elif [[ -z "$line" ]]; then
            output+="<br>"
        # Regular paragraph
        else
            # Inline code
            line=$(echo "$line" | sed 's/`\([^`]*\)`/<code>\1<\/code>/g')
            # Bold
            line=$(echo "$line" | sed 's/\*\*\([^*]*\)\*\*/<strong>\1<\/strong>/g')
            # Italic
            line=$(echo "$line" | sed 's/\*\([^*]*\)\*/<em>\1<\/em>/g')
            # Links
            line=$(echo "$line" | sed 's/\[\([^]]*\)\](\([^)]*\))/<a href="\2">\1<\/a>/g')
            output+="<p>$line</p>"
        fi
        output+=$'\n'
    done <<< "$content"

    echo "$output"
}

# ============================================================================
# PAGE GENERATION
# ============================================================================

# Function: generate_full_page
# Purpose: Generate complete HTML page from content
# Args:
#   $1 - Page title
#   $2 - Page content (HTML)
#   $3 - Page description (optional)
# Returns:
#   Complete HTML page (stdout)
generate_full_page() {
    local title="$1"
    local content="$2"
    local description="${3:-$DEFAULT_SITE_DESC}"

    generate_html_head "$title" "$description"
    generate_html_header "$DEFAULT_SITE_TITLE"
    cat <<EOF
<main class="container">
$content
</main>
EOF
    generate_html_footer
}

# Function: generate_card
# Purpose: Generate a card component
# Args:
#   $1 - Card title
#   $2 - Card content
#   $3 - Icon (optional, emoji)
# Returns:
#   HTML card (stdout)
generate_card() {
    local title="$1"
    local content="$2"
    local icon="${3:-}"

    cat <<EOF
<div class="card">
    ${icon:+<div style="font-size: 2rem; margin-bottom: 0.5rem;">$icon</div>}
    <h3>$title</h3>
    <p>$content</p>
</div>
EOF
}

# Function: generate_code_block
# Purpose: Generate formatted code block
# Args:
#   $1 - Code content
#   $2 - Language (optional)
# Returns:
#   HTML code block (stdout)
generate_code_block() {
    local code="$1"
    local lang="${2:-bash}"

    cat <<EOF
<pre><code class="language-$lang">$(escape_html "$code")</code></pre>
EOF
}
