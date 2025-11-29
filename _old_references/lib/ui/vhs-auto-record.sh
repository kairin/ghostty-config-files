#!/usr/bin/env bash
#
# lib/ui/vhs-auto-record.sh - Automatic VHS Recording Infrastructure
#
# Purpose: Enable transparent automatic VHS recording for scripts
# Architecture: Self-Exec Pattern with environment detection
#
# Usage:
#   source "${REPO_ROOT}/lib/ui/vhs-auto-record.sh"
#   maybe_start_vhs_recording "script-name" "$0" "$@"
#
# How It Works:
#   1. Detects if already running under VHS (checks environment)
#   2. If not under VHS and VHS available:
#      - Generates VHS tape file
#      - Execs into VHS (replaces current process - NO RETURN)
#   3. If under VHS or VHS not available:
#      - Returns normally (continues script execution)
#
# Environment Variables:
#   VHS_AUTO_RECORD   - Set to "false" to disable auto-recording (default: true)
#   VHS_RECORDING     - Set by VHS to indicate recording in progress
#   VHS_OUTPUT        - Set by this script with output file path
#
# Constitutional Compliance:
#   - Graceful degradation (no errors if VHS not installed)
#   - No blocking on recording failures
#   - Follows script proliferation prevention (enhances existing scripts)
#   - Zero-cost if VHS not available (single command -v check)
#
# Author: ghostty-config-files automation
# Version: 1.0
# Last Modified: 2025-11-23
#

# Source guard - prevent multiple sourcing
[ -z "${VHS_AUTO_RECORD_SH_LOADED:-}" ] || return 0
VHS_AUTO_RECORD_SH_LOADED=1

# ═══════════════════════════════════════════════════════════════
# VHS Detection Functions
# ═══════════════════════════════════════════════════════════════

#
# Check if VHS is available on the system
#
# Returns:
#   0 - VHS is installed and executable
#   1 - VHS not available
#
check_vhs_available() {
    command -v vhs &>/dev/null
}

#
# Check if currently running under VHS recording session
#
# VHS sets various environment variables when recording.
# We check for VHS_RECORDING (set by this script) or common VHS patterns.
#
# Returns:
#   0 - Running under VHS
#   1 - Not running under VHS
#
is_under_vhs() {
    # Check if we've set our own marker
    if [[ -n "${VHS_RECORDING:-}" ]]; then
        return 0
    fi

    # Check for VHS-related environment variables
    # VHS typically sets variables like VHS_WIDTH, VHS_HEIGHT, etc.
    if [[ -n "${VHS_WIDTH:-}" ]] || [[ -n "${VHS_HEIGHT:-}" ]] || [[ -n "${VHS_THEME:-}" ]]; then
        return 0
    fi

    # Check if parent process is VHS
    if pgrep -P $$ | xargs -I {} ps -p {} -o comm= 2>/dev/null | grep -q "vhs"; then
        return 0
    fi

    return 1
}

#
# Check if VHS auto-recording is enabled
#
# Respects VHS_AUTO_RECORD environment variable.
# Default: ENABLED (true) - automatic background recording
#
# Returns:
#   0 - Auto-recording enabled
#   1 - Auto-recording disabled
#
is_vhs_auto_record_enabled() {
    # Check if explicitly disabled
    if [[ "${VHS_AUTO_RECORD:-true}" == "false" ]]; then
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════
# VHS Tape File Generation
# ═══════════════════════════════════════════════════════════════

#
# Generate VHS tape file for recording a script
#
# Creates a .tape file that VHS will execute to record the script.
#
# Args:
#   $1 - Recording name (e.g., "start", "daily-updates")
#   $2 - Script path to record (e.g., "./start.sh")
#   $3+ - Script arguments (optional)
#
# Outputs:
#   Tape file path to stdout
#
# Returns:
#   0 - Tape file generated successfully
#   1 - Failed to generate tape file
#
generate_vhs_tape() {
    local recording_name="$1"
    local script_path="$2"
    shift 2
    local script_args=("$@")

    # Generate timestamp for unique filenames
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)

    # Determine output paths
    local repo_root="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
    local output_dir="${repo_root}/logs/video"
    local output_file="${output_dir}/${timestamp}.gif"
    local tape_file="/tmp/vhs-${recording_name}-${timestamp}.tape"

    # Create output directory if needed
    mkdir -p "$output_dir" 2>/dev/null || {
        # Silently fail if can't create directory
        return 1
    }

    # Build command string with arguments
    local cmd="$script_path"
    for arg in "${script_args[@]}"; do
        # Quote arguments with spaces
        if [[ "$arg" =~ [[:space:]] ]]; then
            cmd="$cmd \"$arg\""
        else
            cmd="$cmd $arg"
        fi
    done

    # Generate VHS tape file
    cat > "$tape_file" <<EOF
# VHS Auto-Recording Tape File
# Generated: ${timestamp}
# Recording: ${recording_name}
# Script: ${script_path}

# Output Configuration
Output "${output_file}"
Set Shell "bash"
Set FontSize 14
Set Width 1400
Set Height 900
Set Theme "Catppuccin Mocha"
Set TypingSpeed 50ms

# Set marker environment variable so script knows it's under VHS
# Note: We set VHS_RECORDING in the command itself for reliable detection
# Execute the script with VHS_RECORDING environment variable
Type "VHS_RECORDING=true VHS_OUTPUT='${output_file}' ${cmd}"
Sleep 500ms
Enter

# Wait for script to complete
# Adjust timing based on expected script duration
# start.sh: ~3-5 minutes typical
# daily-updates.sh: ~2-4 minutes typical
Sleep 300s

# Final pause to capture completion message
Sleep 3s
EOF

    if [[ ! -f "$tape_file" ]]; then
        return 1
    fi

    # Output tape file path for caller
    echo "$tape_file"
    return 0
}

# ═══════════════════════════════════════════════════════════════
# Main Auto-Recording Entry Point
# ═══════════════════════════════════════════════════════════════

#
# Maybe start VHS recording (main entry point)
#
# This function should be called at the very start of scripts that want
# automatic VHS recording support.
#
# Behavior:
#   - Layer 1 (Outer): If VHS enabled and not active -> Exec into VHS
#   - Layer 2 (Inner): If Text recording not active -> Exec into script
#   - Layer 3 (Core): Run the actual workload
#
# Args:
#   $1 - Recording name (e.g., "start", "daily-updates")
#   $2 - Script path ($0 from caller)
#   $3+ - Script arguments ($@ from caller)
#
# Returns:
#   0 - Continue execution (we are in the core layer)
#   NEVER RETURNS - If exec into VHS or script occurs
#
maybe_start_vhs_recording() {
    local recording_name="$1"
    local script_path="$2"
    shift 2
    local script_args=("$@")

    # Ensure script path is absolute
    local abs_script_path
    if [[ "$script_path" = /* ]]; then
        abs_script_path="$script_path"
    else
        abs_script_path="$(cd "$(dirname "$script_path")" && pwd)/$(basename "$script_path")"
    fi

    # Generate output filenames
    local repo_root="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local output_dir="${repo_root}/logs/video"
    local log_file="${output_dir}/${timestamp}.log"
    local tape_file="${output_dir}/${timestamp}.tape"
    local gif_file="${output_dir}/${timestamp}.gif"

    # Create output directory
    mkdir -p "$output_dir" 2>/dev/null || return 0

    # ═══════════════════════════════════════════════════════════════
    # Layer 1: Recording Wrapper (Script + VHS Post-Processing)
    # ═══════════════════════════════════════════════════════════════
    # If we are not yet recording text logs:
    if [[ -z "${TEXT_RECORDING:-}" ]]; then
        # If VHS is enabled, we will generate a GIF after the script finishes
        local vhs_enabled=false
        if is_vhs_auto_record_enabled && check_vhs_available && ! is_under_vhs; then
            vhs_enabled=true
        fi

        # Prepare output files
        local timing_file="${output_dir}/${timestamp}.timing"

        # Capture current terminal dimensions
        local term_cols
        term_cols=$(tput cols 2>/dev/null || echo "120")
        local term_lines
        term_lines=$(tput lines 2>/dev/null || echo "40")
        
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "Session Recording Initiated"
        echo "═══════════════════════════════════════════════════════════"
        echo "Recording: ${recording_name}"
        echo "Log Output: logs/video/${timestamp}.log"
        if [ "$vhs_enabled" = true ]; then
            echo "Video Output: logs/video/${timestamp}.gif (Generated after completion)"
        fi
        echo ""
        echo "To disable: export VHS_AUTO_RECORD=false"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        
        # Construct command to run
        local cmd="TEXT_RECORDING=true \"$abs_script_path\""
        for arg in "${script_args[@]}"; do
            cmd="$cmd \"$arg\""
        done
        
        # Run script with timing information
        # We use -e to return the exit code of the child process
        # We use -T to save timing info for replay
        export TEXT_RECORDING=true
        
        # We cannot use exec here because we need to run post-processing
        # Run script and capture exit code
        script -q -e -c "$cmd" -T "$timing_file" "$log_file"
        local exit_code=$?
        
        # Post-processing: Generate GIF if VHS enabled
        if [ "$vhs_enabled" = true ] && [ -f "$timing_file" ] && [ -f "$log_file" ]; then
            echo ""
            echo "═══════════════════════════════════════════════════════════"
            echo "Generating Video Recording..."
            echo "═══════════════════════════════════════════════════════════"
            
            # Calculate VHS dimensions based on terminal size
            # FontSize 14 approx metrics:
            # Width:  ~9-10px per char -> Use 12px to be safe + padding
            # Height: ~20-22px per line -> Use 24px to be safe + padding
            local vhs_width=$(( term_cols * 12 + 100 ))
            local vhs_height=$(( term_lines * 24 + 100 ))

            # Calculate total duration from timing file
            # Timing file format: "delay_duration block_size" per line
            # We sum up the first column
            local total_duration
            if command -v awk >/dev/null; then
                total_duration=$(awk '{sum += $1} END {print sum}' "$timing_file")
                # Add a buffer
                total_duration=$(echo "$total_duration + 2" | bc 2>/dev/null || echo "${total_duration%.*}+2" | bc 2>/dev/null || echo "300")
            else
                total_duration=300 # Fallback
            fi
            
            # Speed up replay to reduce generation time
            local replay_speed=2
            local sleep_duration
            sleep_duration=$(echo "$total_duration / $replay_speed + 5" | bc 2>/dev/null || echo "300")

            # Create a tape file that replays the script
            cat > "$tape_file" <<EOF
# VHS Tape - Replay of ${recording_name}
Output "${gif_file}"
Set Shell "bash"
Set FontSize 14
Set Width ${vhs_width}
Set Height ${vhs_height}
Set Theme "Catppuccin Mocha"
Set PlaybackSpeed 0.5 
Set Padding 20

# Replay the recorded session
# We use scriptreplay to play back the timing and log files
# We speed it up by ${replay_speed}x during recording to save time
# Then we slow down playback by 0.5x (which is 1/2) to compensate? 
# No, Set PlaybackSpeed 1.0 means 1 second of video = 1 second of real time.
# If we record at 2x speed, 10s real time becomes 5s video.
# If we want the video to look normal speed, we need to slow it down?
# Actually, usually people WANT the demo to be faster than real time.
# So recording at 2x speed and playing at 1x speed results in a 2x speed video.
# This is good.

Hide
Type "scriptreplay --divisor ${replay_speed} --timing='${timing_file}' '${log_file}'"
Enter
Show
Sleep 100ms

# Wait for replay to finish
Sleep ${sleep_duration}s
EOF
            
            # Render GIF
            # We do NOT suppress output so user sees the progress bar
            if vhs "$tape_file"; then
                echo "Video saved to: $gif_file"
                # Cleanup intermediate files
                rm -f "$tape_file" "$timing_file"
            else
                echo "Warning: Video rendering failed."
            fi
        fi
        
        exit $exit_code
    fi

    # ═══════════════════════════════════════════════════════════════
    # Layer 2: Core Execution
    # ═══════════════════════════════════════════════════════════════
    # If we reached here, we are inside all necessary recording layers.
    # Continue with normal execution.
    return 0
}

# Export functions for use by other scripts
export -f check_vhs_available
export -f is_under_vhs
export -f is_vhs_auto_record_enabled
export -f generate_vhs_tape
export -f maybe_start_vhs_recording
