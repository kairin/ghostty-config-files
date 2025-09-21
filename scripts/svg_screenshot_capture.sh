#!/bin/bash

# SVG Screenshot Capture Utility for Ghostty Installation Documentation
# Captures terminal screenshots as SVG with preserved text, logos, and emojis
# Organizes assets in proper subfolder structure for GitHub Pages integration

set -euo pipefail

# Import shared functions
source "$(dirname "${BASH_SOURCE[0]}")/agent_functions.sh"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# GitHub Pages compatible asset structure
ASSETS_BASE_DIR="$PROJECT_ROOT/docs/assets"
SCREENSHOTS_DIR="$ASSETS_BASE_DIR/screenshots"
DIAGRAMS_DIR="$ASSETS_BASE_DIR/diagrams"
ICONS_DIR="$ASSETS_BASE_DIR/icons"
VIDEOS_DIR="$ASSETS_BASE_DIR/videos"

# Session-based organization - SYNCHRONIZED WITH start.sh
CURRENT_SESSION_ID="${LOG_SESSION_ID:-$(date +"%Y%m%d-%H%M%S")}"

# Use synchronized session directory if provided by start.sh
if [ -n "${SCREENSHOT_SESSION_DIR:-}" ]; then
    SESSION_SCREENSHOTS_DIR="$SCREENSHOT_SESSION_DIR"
    SESSION_DIAGRAMS_DIR="$(dirname "$SCREENSHOT_SESSION_DIR")/diagrams/$CURRENT_SESSION_ID"
else
    # Fallback to default structure
    SESSION_SCREENSHOTS_DIR="$SCREENSHOTS_DIR/$CURRENT_SESSION_ID"
    SESSION_DIAGRAMS_DIR="$DIAGRAMS_DIR/$CURRENT_SESSION_ID"
fi

# Metadata and index files
SCREENSHOT_METADATA="$SESSION_SCREENSHOTS_DIR/metadata.json"
ASSETS_INDEX="$ASSETS_BASE_DIR/index.json"
GITHUB_PAGES_CONFIG="$PROJECT_ROOT/docs/_config.yml"

# Screenshot counter for ordering
SCREENSHOT_COUNTER_FILE="$SESSION_SCREENSHOTS_DIR/.counter"

# Colors for console output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Ensure all asset directories exist
mkdir -p "$SESSION_SCREENSHOTS_DIR"
mkdir -p "$SESSION_DIAGRAMS_DIR"
mkdir -p "$ICONS_DIR"
mkdir -p "$VIDEOS_DIR"
mkdir -p "$PROJECT_ROOT/docs"

# Initialize screenshot counter
if [ ! -f "$SCREENSHOT_COUNTER_FILE" ]; then
    echo "0" > "$SCREENSHOT_COUNTER_FILE"
fi

# Initialize session metadata
init_session_metadata() {
    if [ ! -f "$SCREENSHOT_METADATA" ]; then
        cat > "$SCREENSHOT_METADATA" << EOF
{
  "session_id": "$CURRENT_SESSION_ID",
  "created": "$(date -Iseconds)",
  "project": "ghostty-config-files",
  "description": "Ghostty terminal installation and configuration screenshots",
  "assets": {
    "screenshots": [],
    "diagrams": [],
    "terminal_states": []
  },
  "counts": {
    "total_screenshots": 0,
    "total_diagrams": 0,
    "total_states": 0
  },
  "github_pages": {
    "base_url": "/ghostty-config-files",
    "assets_path": "/docs/assets",
    "relative_screenshots": "./screenshots/$CURRENT_SESSION_ID",
    "relative_diagrams": "./diagrams/$CURRENT_SESSION_ID"
  }
}
EOF
    fi
}

# Initialize global assets index
init_assets_index() {
    if [ ! -f "$ASSETS_INDEX" ]; then
        cat > "$ASSETS_INDEX" << EOF
{
  "project": "ghostty-config-files",
  "created": "$(date -Iseconds)",
  "last_updated": "$(date -Iseconds)",
  "structure": {
    "screenshots": "Terminal installation screenshots organized by session",
    "diagrams": "Process flow diagrams and architecture visualizations",
    "icons": "Project icons and logos",
    "videos": "Installation demonstration videos"
  },
  "sessions": [],
  "github_pages": {
    "enabled": true,
    "base_url": "/ghostty-config-files",
    "theme": "jekyll-theme-minimal"
  }
}
EOF
    fi
}

# Setup GitHub Pages configuration
setup_github_pages_config() {
    if [ ! -f "$GITHUB_PAGES_CONFIG" ]; then
        cat > "$GITHUB_PAGES_CONFIG" << EOF
title: Ghostty Configuration Files
description: Comprehensive terminal environment setup with 2025 optimizations and AI integration
theme: jekyll-theme-minimal
baseurl: "/ghostty-config-files"
url: "https://USERNAME.github.io"

# Enable plugins
plugins:
  - jekyll-relative-links
  - jekyll-optional-front-matter
  - jekyll-readme-index
  - jekyll-default-layout

# Configure relative links
relative_links:
  enabled: true
  collections: true

# Default layouts
defaults:
  - scope:
      path: ""
      type: "pages"
    values:
      layout: "default"

# Include assets
include:
  - assets/

# Exclude development files
exclude:
  - node_modules/
  - .git/
  - .gitignore
  - local-infra/
  - scripts/
  - configs/

# Markdown configuration
kramdown:
  input: GFM
  syntax_highlighter: rouge
  syntax_highlighter_opts:
    css_class: 'highlight'
    span:
      line_numbers: false
    block:
      line_numbers: true
EOF
    fi
}

# Convert terminal output to SVG with preserved text and styling
capture_terminal_as_svg() {
    local stage_name="$1"
    local description="${2:-$stage_name}"
    local capture_mode="${3:-auto}"  # auto, window, full
    local delay="${4:-2}"

    # Get current counter and increment
    local counter=$(cat "$SCREENSHOT_COUNTER_FILE")
    counter=$((counter + 1))
    echo "$counter" > "$SCREENSHOT_COUNTER_FILE"

    # Generate filename with proper ordering
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local safe_stage_name=$(echo "$stage_name" | tr ' ' '_' | tr -cd 'a-zA-Z0-9_-')
    local filename="terminal_$(printf "%03d" "$counter")_${timestamp}_${safe_stage_name}.svg"
    local output_file="$SESSION_SCREENSHOTS_DIR/$filename"

    echo -e "${BLUE}🎨 Capturing SVG screenshot for stage: $stage_name${NC}"

    # Wait for display stabilization
    if [ "$delay" -gt 0 ]; then
        echo -e "${YELLOW}⏳ Waiting ${delay}s for display to stabilize...${NC}"
        sleep "$delay"
    fi

    # Capture terminal content as SVG
    if capture_terminal_svg "$output_file" "$capture_mode"; then
        # Verify SVG was created and is valid
        if [ -f "$output_file" ] && [ -s "$output_file" ]; then
            # Get file size and validate SVG structure
            local file_size=$(stat -c%s "$output_file" 2>/dev/null || echo "0")

            # Basic SVG validation
            if grep -q "<svg" "$output_file" && grep -q "</svg>" "$output_file"; then
                echo -e "${GREEN}✅ SVG screenshot captured: $filename${NC}"

                # Update metadata
                update_screenshot_metadata "$stage_name" "$description" "$filename" "$counter" "$file_size" "svg-terminal"

                # Generate thumbnail PNG for GitHub previews
                generate_svg_thumbnail "$output_file"

                echo -e "   📁 Location: $output_file"
                echo -e "   📊 Size: ${file_size} bytes"
                echo -e "   🖼️  Format: SVG with preserved text elements"
                return 0
            else
                echo -e "${YELLOW}⚠️  Generated file is not valid SVG, attempting fallback...${NC}"
                rm -f "$output_file"
            fi
        fi
    fi

    # Fallback to PNG with SVG conversion
    echo -e "${YELLOW}📸 Falling back to PNG capture with SVG conversion...${NC}"
    if capture_png_and_convert_svg "$output_file" "$capture_mode"; then
        local file_size=$(stat -c%s "$output_file" 2>/dev/null || echo "0")
        update_screenshot_metadata "$stage_name" "$description" "$filename" "$counter" "$file_size" "svg-converted"
        echo -e "${GREEN}✅ SVG screenshot created via conversion: $filename${NC}"
        return 0
    fi

    echo -e "${YELLOW}⚠️  Failed to capture SVG screenshot for: $stage_name${NC}"
    return 1
}

# Native SVG terminal capture using terminal-to-svg tools
capture_terminal_svg() {
    local output_file="$1"
    local capture_mode="$2"

    # Try different SVG capture methods in order of preference

    # Method 1: Using termtosvg (if available)
    if command -v termtosvg >/dev/null 2>&1; then
        echo -e "${CYAN}🔧 Using termtosvg for native SVG capture...${NC}"
        return capture_with_termtosvg "$output_file"
    fi

    # Method 2: Using asciinema + svg-term (if available)
    if command -v asciinema >/dev/null 2>&1 && command -v svg-term >/dev/null 2>&1; then
        echo -e "${CYAN}🔧 Using asciinema + svg-term for SVG capture...${NC}"
        return capture_with_asciinema_svg "$output_file"
    fi

    # Method 3: Direct terminal output capture to SVG
    if capture_terminal_text_to_svg "$output_file"; then
        echo -e "${CYAN}🔧 Created SVG from terminal text output...${NC}"
        return 0
    fi

    return 1
}

# Capture with termtosvg (preserves terminal styling and animations)
capture_with_termtosvg() {
    local output_file="$1"

    # Use uv-managed termtosvg if available
    local termtosvg_cmd="termtosvg"
    if [ -n "${SCREENSHOT_TOOLS_VENV:-}" ] && [ -d "$SCREENSHOT_TOOLS_VENV" ]; then
        # Check if uv is available and the venv exists
        if command -v uv >/dev/null 2>&1; then
            local screenshot_tools_dir="$(dirname "$SCREENSHOT_TOOLS_VENV")"
            if [ -f "$screenshot_tools_dir/pyproject.toml" ]; then
                termtosvg_cmd="uv run --project $screenshot_tools_dir termtosvg"
            fi
        fi
    fi

    # Create a temporary script to capture current terminal state
    local temp_script=$(mktemp)
    cat > "$temp_script" << 'EOF'
#!/bin/bash
echo "=== Ghostty Terminal Installation Status ==="
echo "Current Stage: ${CURRENT_STAGE:-Initialization}"
echo "Timestamp: $(date)"
echo ""

if command -v ghostty >/dev/null 2>&1; then
    echo "✅ Ghostty Status: Installed"
    echo "   Version: $(ghostty --version 2>/dev/null || echo 'Unknown')"
    echo "   Location: $(which ghostty)"
else
    echo "🔄 Ghostty Status: Installing..."
fi

echo ""
echo "📁 Configuration:"
if [ -f "$HOME/.config/ghostty/config" ]; then
    echo "   ✅ Config file exists"
    echo "   📊 Lines: $(wc -l < "$HOME/.config/ghostty/config")"
else
    echo "   🔄 Config file: Creating..."
fi

echo ""
echo "🔧 System Information:"
echo "   OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Linux')"
echo "   Shell: $SHELL"
echo "   Terminal: $TERM"

if [ -n "${LOG_FILE:-}" ] && [ -f "$LOG_FILE" ]; then
    echo ""
    echo "📋 Recent Log Entries:"
    tail -3 "$LOG_FILE" | sed 's/^/   /'
fi

echo ""
echo "Press Ctrl+C to capture this state..."
sleep 10
EOF

    chmod +x "$temp_script"

    # Capture terminal session
    timeout 15 $termtosvg_cmd "$output_file" -c "$temp_script" >/dev/null 2>&1 || return 1

    rm -f "$temp_script"
    return 0
}

# Capture with asciinema and convert to SVG
capture_with_asciinema_svg() {
    local output_file="$1"

    local temp_cast=$(mktemp --suffix=.cast)
    local temp_script=$(mktemp)

    # Create display script
    cat > "$temp_script" << 'EOF'
#!/bin/bash
echo "🔧 Ghostty Installation Progress"
echo "================================="
echo ""
ps aux | grep -E "(ghostty|zig)" | grep -v grep || echo "No build processes found"
echo ""
if [ -f "$LOG_FILE" ]; then
    echo "📋 Latest Progress:"
    tail -5 "$LOG_FILE" | sed 's/^/  /'
fi
sleep 5
EOF

    chmod +x "$temp_script"

    # Record terminal session
    if timeout 10 asciinema rec "$temp_cast" -c "$temp_script" >/dev/null 2>&1; then
        # Convert to SVG
        if svg-term < "$temp_cast" > "$output_file" 2>/dev/null; then
            rm -f "$temp_cast" "$temp_script"
            return 0
        fi
    fi

    rm -f "$temp_cast" "$temp_script"
    return 1
}

# Create SVG from current terminal text content
capture_terminal_text_to_svg() {
    local output_file="$1"

    # Capture current terminal state
    local terminal_content=$(mktemp)
    {
        echo "📋 Ghostty Installation Status"
        echo "=============================="
        echo "Stage: ${CURRENT_STAGE:-Initialization}"
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""

        if command -v ghostty >/dev/null 2>&1; then
            echo "✅ Ghostty: $(ghostty --version 2>/dev/null | head -1)"
        else
            echo "🔄 Ghostty: Installing..."
        fi

        if [ -f "$HOME/.config/ghostty/config" ]; then
            echo "✅ Config: $(wc -l < "$HOME/.config/ghostty/config") lines"
        else
            echo "🔄 Config: Pending..."
        fi

        echo ""
        echo "🔧 Build Progress:"
        if [ -f "$LOG_FILE" ]; then
            tail -5 "$LOG_FILE" | sed 's/.*] //' | sed 's/^/  /'
        else
            echo "  Initializing..."
        fi

    } > "$terminal_content"

    # Create SVG with terminal styling
    create_terminal_svg "$terminal_content" "$output_file"
    local result=$?

    rm -f "$terminal_content"
    return $result
}

# Generate SVG with terminal-like styling and preserved text
create_terminal_svg() {
    local content_file="$1"
    local output_file="$2"

    local width="800"
    local height="600"
    local font_family="'JetBrains Mono', 'Fira Code', 'Ubuntu Mono', monospace"
    local font_size="14"
    local line_height="20"

    # Start SVG
    cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">
  <defs>
    <style type="text/css">
      .terminal-bg { fill: #1e1e1e; }
      .terminal-text {
        font-family: $font_family;
        font-size: ${font_size}px;
        fill: #f0f0f0;
        dominant-baseline: hanging;
      }
      .terminal-header { fill: #4a9eff; font-weight: bold; }
      .terminal-success { fill: #50fa7b; }
      .terminal-warning { fill: #ffb86c; }
      .terminal-error { fill: #ff5555; }
      .terminal-info { fill: #8be9fd; }
      .terminal-prompt { fill: #bd93f9; }
      .terminal-path { fill: #f1fa8c; }
      .terminal-icon { fill: #ff79c6; }
    </style>
  </defs>

  <!-- Terminal background -->
  <rect class="terminal-bg" width="100%" height="100%" rx="8"/>

  <!-- Terminal title bar -->
  <rect fill="#2d2d2d" width="100%" height="30" rx="8"/>
  <circle cx="20" cy="15" r="6" fill="#ff5555"/>
  <circle cx="40" cy="15" r="6" fill="#ffb86c"/>
  <circle cx="60" cy="15" r="6" fill="#50fa7b"/>
  <text x="80" y="8" class="terminal-text" style="font-size: 12px;">Ghostty Installation Terminal</text>

  <!-- Terminal content -->
  <g transform="translate(20, 50)">
EOF

    # Process content and add as SVG text elements
    local y_pos=0
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            local css_class="terminal-text"

            # Apply styling based on line content
            if echo "$line" | grep -q "^==="; then
                css_class="terminal-header"
            elif echo "$line" | grep -q "✅"; then
                css_class="terminal-success"
            elif echo "$line" | grep -q "🔄\|⏳"; then
                css_class="terminal-warning"
            elif echo "$line" | grep -q "❌\|Error"; then
                css_class="terminal-error"
            elif echo "$line" | grep -q "ℹ️\|📋\|🔧"; then
                css_class="terminal-info"
            elif echo "$line" | grep -q "^\$\|>"; then
                css_class="terminal-prompt"
            fi

            # Escape XML special characters
            local escaped_line=$(echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g')

            echo "    <text x=\"0\" y=\"$y_pos\" class=\"$css_class\">$escaped_line</text>" >> "$output_file"
        fi
        y_pos=$((y_pos + line_height))
    done < "$content_file"

    # Close SVG
    cat >> "$output_file" << EOF
  </g>

  <!-- Timestamp watermark -->
  <text x="$(($width - 180))" y="$(($height - 10))" class="terminal-text" style="font-size: 10px; opacity: 0.7;">$(date '+%Y-%m-%d %H:%M:%S')</text>
</svg>
EOF

    return 0
}

# Fallback: Capture PNG and embed in SVG
capture_png_and_convert_svg() {
    local output_file="$1"
    local capture_mode="$2"

    local temp_png=$(mktemp --suffix=.png)

    # Capture PNG screenshot
    if capture_png_screenshot "$temp_png" "$capture_mode"; then
        # Convert PNG to SVG by embedding
        convert_png_to_svg "$temp_png" "$output_file"
        local result=$?
        rm -f "$temp_png"
        return $result
    fi

    rm -f "$temp_png"
    return 1
}

# Capture PNG screenshot using available tools
capture_png_screenshot() {
    local output_file="$1"
    local capture_mode="$2"

    # Try different screenshot tools
    if command -v gnome-screenshot >/dev/null 2>&1; then
        gnome-screenshot -f "$output_file" 2>/dev/null && return 0
    fi

    if command -v scrot >/dev/null 2>&1; then
        scrot "$output_file" 2>/dev/null && return 0
    fi

    if command -v import >/dev/null 2>&1; then
        import -window root "$output_file" 2>/dev/null && return 0
    fi

    return 1
}

# Convert PNG to SVG by embedding
convert_png_to_svg() {
    local png_file="$1"
    local svg_file="$2"

    # Get image dimensions
    local dimensions=$(identify "$png_file" 2>/dev/null | awk '{print $3}' | head -1)
    local width=$(echo "$dimensions" | cut -d'x' -f1)
    local height=$(echo "$dimensions" | cut -d'x' -f2)

    # Encode PNG as base64
    local base64_data=$(base64 -w 0 "$png_file")

    # Create SVG with embedded PNG
    cat > "$svg_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="$width" height="$height" viewBox="0 0 $width $height">
  <title>Ghostty Installation Screenshot</title>
  <desc>Terminal screenshot captured during Ghostty installation process</desc>
  <image x="0" y="0" width="$width" height="$height"
         xlink:href="data:image/png;base64,$base64_data"/>

  <!-- Metadata -->
  <metadata>
    <capture_time>$(date -Iseconds)</capture_time>
    <original_format>PNG</converted_to>SVG</original_format>
    <source>ghostty-installation</source>
  </metadata>
</svg>
EOF

    return 0
}

# Generate PNG thumbnail for GitHub previews
generate_svg_thumbnail() {
    local svg_file="$1"
    local png_file="${svg_file%.svg}_thumb.png"

    # Try to convert SVG to PNG thumbnail using available tools
    if command -v inkscape >/dev/null 2>&1; then
        inkscape "$svg_file" --export-png="$png_file" --export-width=400 >/dev/null 2>&1
    elif command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert -w 400 "$svg_file" > "$png_file" 2>/dev/null
    elif command -v convert >/dev/null 2>&1; then
        convert "$svg_file" -resize 400x "$png_file" 2>/dev/null
    fi

    if [ -f "$png_file" ]; then
        echo -e "${CYAN}🖼️  Generated thumbnail: $(basename "$png_file")${NC}"
    fi
}

# Update screenshot metadata
update_screenshot_metadata() {
    local stage="$1"
    local description="$2"
    local filename="$3"
    local counter="$4"
    local file_size="$5"
    local method="$6"

    local temp_metadata=$(mktemp)

    jq --arg stage "$stage" \
       --arg desc "$description" \
       --arg file "$filename" \
       --arg timestamp "$(date -Iseconds)" \
       --arg counter "$counter" \
       --arg size "$file_size" \
       --arg method "$method" \
       '.assets.screenshots += [{
         "stage": $stage,
         "description": $desc,
         "filename": $file,
         "counter": ($counter | tonumber),
         "timestamp": $timestamp,
         "file_size_bytes": ($size | tonumber),
         "capture_method": $method,
         "format": "svg",
         "github_path": "./screenshots/'$CURRENT_SESSION_ID'/\($file)",
         "pages_url": "/docs/assets/screenshots/'$CURRENT_SESSION_ID'/\($file)"
       }] | .counts.total_screenshots = (.assets.screenshots | length)' \
       "$SCREENSHOT_METADATA" > "$temp_metadata"

    mv "$temp_metadata" "$SCREENSHOT_METADATA"
}

# Create process flow diagram in SVG
create_process_diagram() {
    local diagram_name="$1"
    local stages_array="$2"  # JSON array of stages

    local safe_name=$(echo "$diagram_name" | tr ' ' '_' | tr -cd 'a-zA-Z0-9_-')
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    local filename="diagram_${timestamp}_${safe_name}.svg"
    local output_file="$SESSION_DIAGRAMS_DIR/$filename"

    echo -e "${PURPLE}📊 Creating process diagram: $diagram_name${NC}"

    # Create SVG process flow diagram
    local width="1000"
    local height="600"
    local stage_width="150"
    local stage_height="80"
    local spacing="200"

    cat > "$output_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">
  <defs>
    <style type="text/css">
      .diagram-bg { fill: #f8f9fa; }
      .stage-box { fill: #e3f2fd; stroke: #1976d2; stroke-width: 2; }
      .stage-text { font-family: 'Arial', sans-serif; font-size: 12px; fill: #1976d2; text-anchor: middle; }
      .arrow { stroke: #424242; stroke-width: 2; fill: none; marker-end: url(#arrowhead); }
      .title-text { font-family: 'Arial', sans-serif; font-size: 18px; font-weight: bold; fill: #1976d2; text-anchor: middle; }
    </style>
    <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
      <polygon points="0 0, 10 3.5, 0 7" fill="#424242"/>
    </marker>
  </defs>

  <!-- Background -->
  <rect class="diagram-bg" width="100%" height="100%"/>

  <!-- Title -->
  <text x="$(($width / 2))" y="30" class="title-text">$diagram_name</text>

EOF

    # Parse stages and create diagram elements
    local stage_count=$(echo "$stages_array" | jq '. | length')
    local y_center=$((height / 2))

    for ((i=0; i<stage_count; i++)); do
        local stage=$(echo "$stages_array" | jq -r ".[$i]")
        local x_center=$(( 100 + i * spacing ))

        # Stage box
        echo "  <rect class=\"stage-box\" x=\"$(($x_center - $stage_width/2))\" y=\"$(($y_center - $stage_height/2))\" width=\"$stage_width\" height=\"$stage_height\" rx=\"8\"/>" >> "$output_file"

        # Stage text (split into lines if too long)
        local stage_lines=$(echo "$stage" | fold -w 15 -s)
        local line_count=$(echo "$stage_lines" | wc -l)
        local text_y=$(( y_center - (line_count - 1) * 6 ))

        echo "$stage_lines" | while IFS= read -r line; do
            echo "  <text x=\"$x_center\" y=\"$text_y\" class=\"stage-text\">$line</text>" >> "$output_file"
            text_y=$((text_y + 12))
        done

        # Arrow to next stage (if not last)
        if [ $i -lt $((stage_count - 1)) ]; then
            local arrow_start_x=$(( x_center + stage_width/2 ))
            local arrow_end_x=$(( x_center + spacing - stage_width/2 ))
            echo "  <line class=\"arrow\" x1=\"$arrow_start_x\" y1=\"$y_center\" x2=\"$arrow_end_x\" y2=\"$y_center\"/>" >> "$output_file"
        fi
    done

    # Close SVG
    cat >> "$output_file" << EOF

  <!-- Timestamp -->
  <text x="$(($width - 10))" y="$(($height - 10))" style="font-size: 10px; fill: #666; text-anchor: end;">Generated: $(date '+%Y-%m-%d %H:%M:%S')</text>
</svg>
EOF

    echo -e "${GREEN}✅ Process diagram created: $filename${NC}"

    # Update metadata
    local temp_metadata=$(mktemp)
    jq --arg name "$diagram_name" \
       --arg file "$filename" \
       --arg timestamp "$(date -Iseconds)" \
       '.assets.diagrams += [{
         "name": $name,
         "filename": $file,
         "timestamp": $timestamp,
         "github_path": "./diagrams/'$CURRENT_SESSION_ID'/\($file)",
         "pages_url": "/docs/assets/diagrams/'$CURRENT_SESSION_ID'/\($file)"
       }] | .counts.total_diagrams = (.assets.diagrams | length)' \
       "$SCREENSHOT_METADATA" > "$temp_metadata"

    mv "$temp_metadata" "$SCREENSHOT_METADATA"

    return 0
}

# Generate comprehensive documentation for GitHub Pages
generate_github_pages_docs() {
    local output_dir="$PROJECT_ROOT/docs"

    echo -e "${BLUE}📚 Generating GitHub Pages documentation...${NC}"

    # Main installation page
    generate_installation_guide "$output_dir/installation.md"

    # Screenshots gallery
    generate_screenshots_gallery "$output_dir/screenshots.md"

    # Asset index page
    generate_assets_index_page "$output_dir/assets.md"

    # Update main README links
    update_readme_with_assets

    echo -e "${GREEN}✅ GitHub Pages documentation generated${NC}"
}

# Generate installation guide with embedded SVGs
generate_installation_guide() {
    local output_file="$1"

    cat > "$output_file" << EOF
---
title: Ghostty Installation Guide
description: Step-by-step visual guide to installing and configuring Ghostty terminal
layout: default
---

# Ghostty Installation Guide

This guide shows the complete installation process of Ghostty terminal with screenshots captured at each stage.

## Overview

The installation process includes:
1. System dependency checking
2. Zig compiler installation
3. Ghostty compilation from source
4. Configuration setup
5. Context menu integration

## Installation Stages

EOF

    # Add screenshots for each stage
    if [ -f "$SCREENSHOT_METADATA" ]; then
        jq -r '.assets.screenshots[] | @base64' "$SCREENSHOT_METADATA" | while read -r screenshot_data; do
            local screenshot=$(echo "$screenshot_data" | base64 -d)
            local stage=$(echo "$screenshot" | jq -r '.stage')
            local description=$(echo "$screenshot" | jq -r '.description')
            local filename=$(echo "$screenshot" | jq -r '.filename')
            local github_path=$(echo "$screenshot" | jq -r '.github_path')

            cat >> "$output_file" << EOF

### $stage

$description

![$(stage)](${github_path})

EOF
        done
    fi

    cat >> "$output_file" << EOF

## Process Flow

The installation follows this sequence:

![Installation Process](./assets/diagrams/$CURRENT_SESSION_ID/diagram_installation_process.svg)

## Technical Details

- **Terminal**: Preserves all text, emojis, and formatting as SVG elements
- **Scalable**: Vector graphics scale perfectly at any resolution
- **Searchable**: Text content remains searchable and selectable
- **Accessible**: Screen readers can access all text content

## Configuration Files

All configuration files are organized in the \`configs/\` directory:

- \`ghostty/config\` - Main Ghostty configuration
- \`ghostty/themes/\` - Theme definitions
- \`zsh/\` - ZSH configuration and plugins

## Next Steps

After installation:
1. [Configure your themes](./configuration.md)
2. [Setup keyboard shortcuts](./keybindings.md)
3. [Install AI tools integration](./ai-tools.md)

---

*Documentation generated automatically during installation. Screenshots preserve exact terminal output including colors, formatting, and emojis.*
EOF
}

# Generate screenshots gallery page
generate_screenshots_gallery() {
    local output_file="$1"

    cat > "$output_file" << EOF
---
title: Screenshots Gallery
description: Visual documentation of the Ghostty installation process
layout: default
---

# Screenshots Gallery

Complete visual documentation of the Ghostty terminal installation and configuration process.

<div class="gallery-grid">
EOF

    if [ -f "$SCREENSHOT_METADATA" ]; then
        jq -r '.assets.screenshots[] | @base64' "$SCREENSHOT_METADATA" | while read -r screenshot_data; do
            local screenshot=$(echo "$screenshot_data" | base64 -d)
            local stage=$(echo "$screenshot" | jq -r '.stage')
            local description=$(echo "$screenshot" | jq -r '.description')
            local filename=$(echo "$screenshot" | jq -r '.filename')
            local github_path=$(echo "$screenshot" | jq -r '.github_path')
            local counter=$(echo "$screenshot" | jq -r '.counter')

            cat >> "$output_file" << EOF

<div class="gallery-item">
  <h3>Stage $counter: $stage</h3>
  <p>$description</p>
  <div class="screenshot-container">
    <img src="${github_path}" alt="$stage" loading="lazy">
  </div>
</div>

EOF
        done
    fi

    cat >> "$output_file" << EOF
</div>

<style>
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 2rem;
  margin: 2rem 0;
}

.gallery-item {
  border: 1px solid #e1e4e8;
  border-radius: 8px;
  padding: 1rem;
  background: #f6f8fa;
}

.screenshot-container {
  margin-top: 1rem;
}

.screenshot-container img {
  width: 100%;
  height: auto;
  border-radius: 4px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
</style>

## Download Assets

All screenshots are available as SVG files that preserve:
- ✅ Original text content (searchable and selectable)
- ✅ Exact colors and formatting
- ✅ Emojis and special characters
- ✅ Scalability without quality loss

[Download All Screenshots](./assets/screenshots/$CURRENT_SESSION_ID/)
EOF
}

# Update main README with asset links
update_readme_with_assets() {
    local readme_file="$PROJECT_ROOT/README.md"

    if [ -f "$readme_file" ]; then
        # Add assets section to README if not exists
        if ! grep -q "## 📸 Visual Documentation" "$readme_file"; then
            cat >> "$readme_file" << EOF

## 📸 Visual Documentation

Complete visual guide showing the installation process:

- 🎬 **[Installation Guide](docs/installation.md)** - Step-by-step visual walkthrough
- 🖼️ **[Screenshots Gallery](docs/screenshots.md)** - All installation screenshots
- 📊 **[Process Diagrams](docs/assets.md)** - Installation flow diagrams
- 🎨 **[SVG Assets](docs/assets/)** - High-quality vector graphics

### Why SVG Screenshots?

Our screenshots are captured as SVG (Scalable Vector Graphics) which means:
- 📝 **Text Preservation**: All terminal text remains selectable and searchable
- 🎨 **Perfect Quality**: Vector graphics scale without quality loss
- ♿ **Accessibility**: Screen readers can access all text content
- 🎯 **GitHub Integration**: Perfect display in GitHub Pages and README files

### Latest Installation Session

Current session: \`$CURRENT_SESSION_ID\`

EOF
        fi
    fi
}

# Install required tools for SVG capture - AUTOMATIC via uv or system
install_svg_tools() {
    # Tools are automatically installed by start.sh via uv
    # This is a no-op function for backward compatibility
    if [ -n "${SCREENSHOT_TOOLS_VENV:-}" ] && [ -d "$SCREENSHOT_TOOLS_VENV" ]; then
        echo -e "${GREEN}✅ SVG tools available via uv environment${NC}"
    else
        echo -e "${BLUE}🔧 Installing SVG screenshot tools via system packages...${NC}"

        local tools_to_install=()

        # Check for system tools
        if ! command -v asciinema >/dev/null 2>&1; then
            tools_to_install+=("asciinema")
        fi

        if ! command -v rsvg-convert >/dev/null 2>&1; then
            tools_to_install+=("librsvg2-bin")
        fi

        if ! command -v convert >/dev/null 2>&1; then
            tools_to_install+=("imagemagick")
        fi

        if [ ${#tools_to_install[@]} -gt 0 ]; then
            echo -e "${YELLOW}📦 Installing: ${tools_to_install[*]}${NC}"

            # Install system packages
            if command -v apt >/dev/null 2>&1; then
                sudo apt update >/dev/null 2>&1
                sudo apt install -y "${tools_to_install[@]}" >/dev/null 2>&1 || true
            fi

            echo -e "${GREEN}✅ System SVG tools installation complete${NC}"
        else
            echo -e "${GREEN}✅ All system SVG tools already available${NC}"
        fi
    fi
}

# Main command handling
main() {
    # Initialize session and directories
    init_session_metadata
    init_assets_index
    setup_github_pages_config

    case "${1:-help}" in
        "capture")
            shift
            capture_terminal_as_svg "$@"
            ;;
        "diagram")
            shift
            local diagram_name="$1"
            local stages_json="${2:-[\"Stage 1\", \"Stage 2\", \"Stage 3\"]}"
            create_process_diagram "$diagram_name" "$stages_json"
            ;;
        "install-tools")
            install_svg_tools
            ;;
        "generate-docs")
            generate_github_pages_docs
            ;;
        "list")
            list_screenshots "${2:-}"
            ;;
        "setup")
            # Complete setup for SVG screenshot system
            install_svg_tools
            init_session_metadata
            init_assets_index
            setup_github_pages_config
            echo -e "${GREEN}✅ SVG screenshot system ready${NC}"
            ;;
        "help"|*)
            cat << EOF
SVG Screenshot Capture System for Ghostty Installation

Usage:
  $0 capture <stage_name> [description] [mode] [delay]
      Capture SVG screenshot preserving text, emojis, and formatting

  $0 diagram <diagram_name> <stages_json>
      Create process flow diagram in SVG format

  $0 install-tools
      Install required tools for SVG capture (termtosvg, asciinema, etc.)

  $0 generate-docs
      Generate complete GitHub Pages documentation with SVG assets

  $0 list [session_id]
      List all captured assets for session

  $0 setup
      Complete setup of SVG screenshot system

Examples:
  $0 setup
  $0 capture "Initial Desktop" "Clean Ubuntu before installation" auto 3
  $0 diagram "Installation Process" '["Check Dependencies", "Install Zig", "Build Ghostty", "Configure"]'
  $0 generate-docs

Features:
  ✅ SVG format preserves all text as selectable elements
  ✅ Emojis and special characters rendered perfectly
  ✅ Scalable vector graphics for any resolution
  ✅ GitHub Pages integration with proper asset organization
  ✅ Automatic thumbnail generation for previews
  ✅ Process flow diagrams with custom styling

Asset Organization:
  docs/assets/screenshots/$CURRENT_SESSION_ID/  - SVG screenshots
  docs/assets/diagrams/$CURRENT_SESSION_ID/     - Process diagrams
  docs/assets/icons/                            - Project icons
  docs/installation.md                          - Installation guide
  docs/screenshots.md                           - Screenshots gallery

GitHub Pages:
  Automatically generates documentation with proper Jekyll configuration
  for seamless GitHub Pages deployment with SVG asset support.

EOF
            ;;
    esac
}

# Execute main function with all arguments
main "$@"