#!/bin/bash
# scripts/vhs/record.sh - Interactive terminal recording using asciinema
#
# Usage:
#   ./scripts/vhs/record.sh check-deps    # Check/install dependencies
#   ./scripts/vhs/record.sh start [name]  # Start interactive recording
#   ./scripts/vhs/record.sh convert       # Convert .cast to gif/mp4/webm
#   ./scripts/vhs/record.sh list          # List recordings

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check and install dependencies
cmd_check_deps() {
    local missing=()

    if ! command -v asciinema &>/dev/null; then
        missing+=("asciinema")
    fi
    if ! command -v agg &>/dev/null; then
        missing+=("agg")
    fi

    if [[ ${#missing[@]} -eq 0 ]]; then
        gum style --foreground 46 "✓ All dependencies installed"
        return 0
    fi

    gum style --foreground 214 "Installing missing dependencies: ${missing[*]}"

    for dep in "${missing[@]}"; do
        case "$dep" in
            asciinema)
                gum style --foreground 240 "Installing asciinema via apt..."
                sudo apt-get install -y asciinema
                ;;
            agg)
                if command -v cargo &>/dev/null; then
                    gum style --foreground 240 "Installing agg via cargo..."
                    cargo install agg
                else
                    gum style --foreground 240 "Downloading agg binary..."
                    local AGG_VERSION="1.4.3"
                    local AGG_URL="https://github.com/asciinema/agg/releases/download/v${AGG_VERSION}/agg-x86_64-unknown-linux-gnu"
                    curl -L "$AGG_URL" -o /tmp/agg
                    chmod +x /tmp/agg
                    sudo mv /tmp/agg /usr/local/bin/agg
                fi
                ;;
        esac
    done

    gum style --foreground 46 "✓ Dependencies installed"
}

# Start interactive recording
cmd_start() {
    local CLIP_NAME="${1:-}"

    if [[ -z "$CLIP_NAME" ]]; then
        CLIP_NAME=$(gum input --placeholder "clip name (e.g., feh-install)")
        [[ -z "$CLIP_NAME" ]] && CLIP_NAME="session-$(date +%Y%m%d-%H%M%S)"
    fi

    local CAST_FILE="$SCRIPT_DIR/${CLIP_NAME}.cast"

    echo ""
    gum style --foreground 212 --bold "Recording: $CLIP_NAME"
    gum style --foreground 46 "You can now use the terminal normally!"
    gum style --foreground 240 "• Navigate menus with arrow keys"
    gum style --foreground 240 "• Select with Enter"
    gum style --foreground 240 "• Select 'Exit' or press Ctrl+D to stop recording"
    echo ""
    sleep 2

    cd "$PROJECT_DIR"
    asciinema rec "$CAST_FILE" --command "./start.sh --demo-child --sudo-cached" --overwrite

    echo ""
    gum style --foreground 46 "✓ Recording saved: $CAST_FILE"
}

# Convert recording to media formats
cmd_convert() {
    local CAST_FILES=("$SCRIPT_DIR"/*.cast)

    if [[ ! -e "${CAST_FILES[0]}" ]]; then
        gum style --foreground 196 "No recordings found in $SCRIPT_DIR"
        return 1
    fi

    local SELECTED=$(gum choose "${CAST_FILES[@]}" --header "Select recording to convert")
    [[ -z "$SELECTED" ]] && return 0

    local BASE_NAME="${SELECTED%.cast}"

    gum style --foreground 214 "Converting to gif/mp4/webm..."

    # GIF via agg
    if command -v agg &>/dev/null; then
        agg --font-family "FiraCode Nerd Font" --font-size 16 "$SELECTED" "${BASE_NAME}.gif"
        gum style --foreground 46 "✓ Created: ${BASE_NAME}.gif"
    else
        gum style --foreground 196 "agg not installed - cannot create GIF"
        gum style --foreground 240 "Run: ./scripts/vhs/record.sh check-deps"
        return 1
    fi

    # MP4/WebM via ffmpeg
    if command -v ffmpeg &>/dev/null; then
        gum style --foreground 240 "Creating MP4..."
        ffmpeg -y -i "${BASE_NAME}.gif" -movflags faststart -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "${BASE_NAME}.mp4" 2>/dev/null
        gum style --foreground 46 "✓ Created: ${BASE_NAME}.mp4"

        gum style --foreground 240 "Creating WebM..."
        ffmpeg -y -i "${BASE_NAME}.gif" -c:v libvpx-vp9 "${BASE_NAME}.webm" 2>/dev/null
        gum style --foreground 46 "✓ Created: ${BASE_NAME}.webm"
    else
        gum style --foreground 214 "ffmpeg not installed - skipping mp4/webm"
    fi

    echo ""
    gum style --foreground 46 --bold "Conversion complete!"
    ls -lh "${BASE_NAME}".*
}

# List existing recordings
cmd_list() {
    echo ""
    gum style --foreground 212 --bold "Recordings in $SCRIPT_DIR:"
    echo ""
    if ls "$SCRIPT_DIR"/*.cast 1>/dev/null 2>&1; then
        ls -lh "$SCRIPT_DIR"/*.cast
    else
        gum style --foreground 240 "No recordings found"
    fi
    echo ""
}

# Main dispatch
case "${1:-}" in
    check-deps) cmd_check_deps ;;
    start)      cmd_start "${2:-}" ;;
    convert)    cmd_convert ;;
    list)       cmd_list ;;
    *)
        echo "Usage: $0 {check-deps|start [name]|convert|list}"
        echo ""
        echo "Commands:"
        echo "  check-deps    Check and install asciinema + agg"
        echo "  start [name]  Start interactive recording"
        echo "  convert       Convert .cast to gif/mp4/webm"
        echo "  list          List existing recordings"
        exit 1
        ;;
esac
