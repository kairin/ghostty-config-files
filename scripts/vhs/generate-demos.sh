#!/usr/bin/env bash
#
# VHS Demo Generation Script
# Purpose: Generate all VHS demo GIFs for documentation and web segments
# Usage: ./scripts/vhs/generate-demos.sh [--segments]
#
# Constitutional Compliance:
# - Principle V: Modular Architecture
# - Automated demo generation for documentation
# - Run during updates/commits to keep demos current
#
# Segment Mode (--segments):
# - Extracts small (<2MB) GIF segments from existing recordings
# - Outputs to astro-website/public/segments/ for web rotation
# - Uses ffmpeg + gifsicle (if available) for optimization
#

set -euo pipefail

# Get repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Source core utilities
source "${REPO_ROOT}/lib/core/logging.sh"
source "${REPO_ROOT}/lib/core/utils.sh"

# VHS tape files
readonly TAPES_DIR="${SCRIPT_DIR}"
readonly OUTPUT_DIR="${REPO_ROOT}/documentation/demos"

# Web segment configuration
readonly SEGMENTS_DIR="${REPO_ROOT}/astro-website/public/segments"
readonly VIDEO_DIR="${REPO_ROOT}/logs/video"
readonly MAX_SEGMENT_SIZE_KB=2000  # 2MB hard limit
readonly SEGMENT_WIDTH=800         # Target width for segments
readonly SEGMENT_FPS=10            # Target FPS for segments

# Ensure VHS is installed
check_vhs_installed() {
    if ! command_exists "vhs"; then
        log "ERROR" "VHS not installed"
        log "ERROR" "Install with: lib/installers/vhs/install.sh"
        exit 1
    fi

    # Check dependencies
    local missing_deps=()

    if ! command_exists "ffmpeg"; then
        missing_deps+=("ffmpeg")
    fi

    if ! command_exists "ttyd"; then
        missing_deps+=("ttyd")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "ERROR" "Missing VHS dependencies: ${missing_deps[*]}"
        log "ERROR" "Install with: lib/installers/vhs/install.sh"
        exit 1
    fi

    log "SUCCESS" "✓ VHS and dependencies installed"
}

# ============================================
# SEGMENT GENERATION FUNCTIONS
# ============================================

# Check if gifsicle is available for extra compression
has_gifsicle() {
    command_exists "gifsicle"
}

# Extract and optimize a GIF segment
# Args: $1=input $2=output $3=start_time $4=duration
extract_segment() {
    local input="$1"
    local output="$2"
    local start="${3:-0}"
    local duration="${4:-8}"
    local segment_name
    segment_name=$(basename "$output")

    log "INFO" "  Extracting segment: $segment_name (${duration}s from ${start}s)"

    # Ensure output directory exists
    mkdir -p "$(dirname "$output")"

    local temp_file="/tmp/segment-temp-$$.gif"

    # Pass 1: FFmpeg extraction with optimization
    # - Resize to target width
    # - Reduce FPS
    # - Optimize color palette
    if ! ffmpeg -y -i "$input" \
        -ss "$start" -t "$duration" \
        -vf "fps=${SEGMENT_FPS},scale=${SEGMENT_WIDTH}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" \
        -loop 0 \
        "$temp_file" 2>/dev/null; then
        log "ERROR" "    FFmpeg extraction failed"
        rm -f "$temp_file"
        return 1
    fi

    # Pass 2: Gifsicle lossy compression (if available)
    if has_gifsicle; then
        gifsicle -O3 --lossy=80 "$temp_file" -o "$output" 2>/dev/null
        rm -f "$temp_file"
    else
        mv "$temp_file" "$output"
    fi

    # Verify and adjust if needed
    verify_segment_size "$output"
}

# Verify segment meets size requirements, adjust if not
verify_segment_size() {
    local file="$1"
    local size_kb
    size_kb=$(du -k "$file" | cut -f1)

    if [ "$size_kb" -le "$MAX_SEGMENT_SIZE_KB" ]; then
        log "SUCCESS" "    Size: ${size_kb}KB ✓"
        return 0
    fi

    log "WARNING" "    Size ${size_kb}KB exceeds limit, compressing..."

    # If gifsicle available, try more aggressive compression
    if has_gifsicle; then
        local lossy=80
        while [ "$size_kb" -gt "$MAX_SEGMENT_SIZE_KB" ] && [ "$lossy" -lt 200 ]; do
            lossy=$((lossy + 20))
            gifsicle -O3 --lossy="$lossy" --colors 64 "$file" -o "$file" 2>/dev/null
            size_kb=$(du -k "$file" | cut -f1)
            log "INFO" "    Retry with lossy=$lossy: ${size_kb}KB"
        done
    fi

    if [ "$size_kb" -gt "$MAX_SEGMENT_SIZE_KB" ]; then
        log "WARNING" "    Could not reduce below ${MAX_SEGMENT_SIZE_KB}KB (final: ${size_kb}KB)"
        return 1
    fi

    log "SUCCESS" "    Final size: ${size_kb}KB ✓"
    return 0
}

# Find the best source GIF from logs/video/
find_source_gif() {
    local latest
    latest=$(find "$VIDEO_DIR" -name "*.gif" -type f -size +100k 2>/dev/null | head -1)

    if [ -n "$latest" ] && [ -f "$latest" ]; then
        echo "$latest"
        return 0
    fi

    # Fallback to demo.gif if it exists
    local demo="${REPO_ROOT}/astro-website/public/demo.gif"
    if [ -f "$demo" ]; then
        echo "$demo"
        return 0
    fi

    return 1
}

# Generate all web segments
generate_web_segments() {
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Web Segment Generation"
    log "INFO" "════════════════════════════════════════"
    echo ""

    # Find source GIF
    local source_gif
    if ! source_gif=$(find_source_gif); then
        log "ERROR" "No source GIF found in $VIDEO_DIR"
        log "ERROR" "Run start.sh or daily-updates.sh with VHS recording first"
        return 1
    fi

    log "INFO" "Source: $source_gif"
    local source_size
    source_size=$(du -h "$source_gif" | cut -f1)
    log "INFO" "Source size: $source_size"
    echo ""

    # Create segment directories
    mkdir -p "${SEGMENTS_DIR}/hero"
    mkdir -p "${SEGMENTS_DIR}/bg"

    # Get source duration using ffprobe
    local duration
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$source_gif" 2>/dev/null | cut -d. -f1)
    duration=${duration:-60}
    log "INFO" "Source duration: ${duration}s"
    echo ""

    # Define segment extraction points
    # Hero segments: More prominent, showing key features
    log "INFO" "Generating hero segments..."
    extract_segment "$source_gif" "${SEGMENTS_DIR}/hero/segment-01.gif" 0 8
    extract_segment "$source_gif" "${SEGMENTS_DIR}/hero/segment-02.gif" 10 8
    extract_segment "$source_gif" "${SEGMENTS_DIR}/hero/segment-03.gif" 20 10
    extract_segment "$source_gif" "${SEGMENTS_DIR}/hero/segment-04.gif" 35 8
    extract_segment "$source_gif" "${SEGMENTS_DIR}/hero/segment-05.gif" 50 8
    echo ""

    # Background segments: Subtler, ambient animations
    log "INFO" "Generating background segments..."
    extract_segment "$source_gif" "${SEGMENTS_DIR}/bg/segment-01.gif" 5 10
    extract_segment "$source_gif" "${SEGMENTS_DIR}/bg/segment-02.gif" 18 10
    extract_segment "$source_gif" "${SEGMENTS_DIR}/bg/segment-03.gif" 30 10
    extract_segment "$source_gif" "${SEGMENTS_DIR}/bg/segment-04.gif" 45 10
    extract_segment "$source_gif" "${SEGMENTS_DIR}/bg/segment-05.gif" 55 10
    echo ""

    # Summary
    local total_size
    total_size=$(du -sh "$SEGMENTS_DIR" 2>/dev/null | cut -f1)
    local segment_count
    segment_count=$(find "$SEGMENTS_DIR" -name "*.gif" | wc -l)

    log "INFO" "════════════════════════════════════════"
    log "SUCCESS" "Generated $segment_count segments"
    log "SUCCESS" "Total size: $total_size"
    log "INFO" "Location: astro-website/public/segments/"
    log "INFO" "════════════════════════════════════════"

    return 0
}

# Generate a single demo
generate_demo() {
    local tape_file="$1"
    local tape_name
    tape_name=$(basename "$tape_file" .tape)

    log "INFO" "Generating demo: $tape_name"
    echo "  ⠋ Recording with VHS..."

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Run VHS (with timeout to prevent hanging)
    if timeout 120s vhs "$tape_file" 2>&1 | tee -a "${REPO_ROOT}/logs/vhs-generation.log"; then
        log "SUCCESS" "  ✓ Generated: documentation/demos/${tape_name%-demo}.gif"
        return 0
    else
        log "ERROR" "  ✗ Failed to generate demo (timeout or error)"
        return 1
    fi
}

# Main function
main() {
    local mode="${1:-demos}"

    # Handle --segments flag
    if [ "$mode" = "--segments" ] || [ "$mode" = "-s" ]; then
        # Segment mode only requires ffmpeg (not full VHS)
        if ! command_exists "ffmpeg"; then
            log "ERROR" "ffmpeg is required for segment generation"
            exit 1
        fi
        generate_web_segments
        return $?
    fi

    # Standard demo generation mode
    log "INFO" "════════════════════════════════════════"
    log "INFO" "VHS Demo Generation"
    log "INFO" "════════════════════════════════════════"
    echo ""

    # Check VHS installation
    check_vhs_installed
    echo ""

    # Find all tape files
    local tape_files
    mapfile -t tape_files < <(find "$TAPES_DIR" -name "*.tape" -type f | sort)

    if [ ${#tape_files[@]} -eq 0 ]; then
        log "WARNING" "No .tape files found in $TAPES_DIR"
        exit 0
    fi

    log "INFO" "Found ${#tape_files[@]} demo tape(s)"
    echo ""

    # Generate each demo
    local success_count=0
    local fail_count=0

    for tape in "${tape_files[@]}"; do
        if generate_demo "$tape"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        echo ""
    done

    # Summary
    log "INFO" "════════════════════════════════════════"
    log "INFO" "Generation Summary"
    log "INFO" "════════════════════════════════════════"
    log "SUCCESS" "Successful: $success_count"
    [ "$fail_count" -gt 0 ] && log "ERROR" "Failed: $fail_count"
    echo ""

    if [ "$fail_count" -eq 0 ]; then
        log "SUCCESS" "✓ All demos generated successfully"
        return 0
    else
        log "ERROR" "Some demos failed to generate"
        return 1
    fi
}

main "$@"
