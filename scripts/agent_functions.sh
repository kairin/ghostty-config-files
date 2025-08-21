#!/bin/bash

# Shared Agent Functions Library
# This file contains common functions used across multiple scripts
# to eliminate code duplication and ensure consistency

# Dynamic message generation functions
get_step_status() {
    local step="$1"
    local status="$2"
    case "$status" in
        "start") echo "🔄 Starting: $step" ;;
        "progress") echo "⏳ In progress: $step" ;;
        "success") echo "✅ Completed: $step" ;;
        "warning") echo "⚠️  Warning in: $step" ;;
        "error") echo "❌ Failed: $step" ;;
        *) echo "📋 $step: $status" ;;
    esac
}

get_process_details() {
    local process="$1"
    local detail="$2"
    echo "   └─ $process: $detail"
}

# Enhanced agent logging with process visibility
agent_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local agent_type="${AGENT_TYPE:-AGENT}"
    local log_entry="[$timestamp] [$agent_type] [$level] $message"
    
    # Always log to file if AGENT_LOG_FILE is set
    if [ -n "${AGENT_LOG_FILE:-}" ]; then
        echo "$log_entry" >> "$AGENT_LOG_FILE"
    fi
    
    # Show on console based on verbosity
    if [ "${AGENT_VERBOSE:-true}" = "true" ] || [ "$level" = "ERROR" ] || [ "$level" = "WARNING" ]; then
        echo "$log_entry"
    fi
}

# Agent cleanup function
agent_cleanup() {
    agent_log "INFO" "🧹 ${AGENT_TYPE:-Agent} cleanup initiated"
    if [ -n "${AGENT_PID_FILE:-}" ]; then
        rm -f "$AGENT_PID_FILE"
    fi
    if [ -n "${AGENT_LOG_FILE:-}" ]; then
        agent_log "INFO" "📋 Agent log available at: $AGENT_LOG_FILE"
    fi
}

# Progress bar function
show_progress() {
    local current="$1"
    local total="$2"
    local desc="${3:-Processing}"
    local width=50
    
    if [ "$total" -eq 0 ]; then
        total=1
    fi
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r%s [" "$desc"
    printf "%*s" "$filled" | tr ' ' '█'
    printf "%*s" "$empty" | tr ' ' '░'
    printf "] %d%% (%d/%d)" "$percentage" "$current" "$total"
}

# Spinner for indeterminate progress
show_spinner() {
    local pid="$1"
    local message="${2:-Processing}"
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        local char="${spinner_chars:$((i % ${#spinner_chars})):1}"
        printf "\r%s %s" "$char" "$message"
        i=$((i + 1))
        sleep 0.1
    done
    printf "\r✅ %s - Complete\n" "$message"
}

# Enhanced process execution with progress monitoring
execute_with_visibility() {
    local step_name="$1"
    local command="$2"
    local show_output="${3:-true}"
    local progress_type="${4:-auto}"  # auto, spinner, lines, silent
    
    agent_log "INFO" "$(get_step_status "$step_name" "start")"
    
    # Create a temporary file for progress monitoring
    local temp_output=$(mktemp)
    local temp_pid_file=$(mktemp)
    
    if [ "$show_output" = "true" ] && [ "${AGENT_VERBOSE:-true}" = "true" ]; then
        # Execute command in background and monitor progress
        (
            eval "$command" 2>&1 | while IFS= read -r line; do
                # Filter sensitive information comprehensively
                filtered_line=$(echo "$line" | \
                    sed 's/password[^[:space:]]*/[REDACTED]/gi' | \
                    sed 's/token[^[:space:]]*/[REDACTED]/gi' | \
                    sed 's/key[^[:space:]]*/[REDACTED]/gi' | \
                    sed 's/secret[^[:space:]]*/[REDACTED]/gi' | \
                    sed 's/auth[^[:space:]]*/[REDACTED]/gi' | \
                    sed 's|https://[^[:space:]]*:[^@[:space:]]*@|https://[REDACTED]@|g' | \
                    sed 's/\b[A-Za-z0-9._%+-]\+@[A-Za-z0-9.-]\+\.[A-Z|a-z]\{2,\}\b/[EMAIL_REDACTED]/g' | \
                    sed 's|/home/[^[:space:]]*/\.ssh/|/home/[USER]/.ssh/|g' | \
                    sed 's|/home/[^[:space:]]*/\.config/|/home/[USER]/.config/|g')
                
                echo "$filtered_line" >> "$temp_output"
                
                # Show progress for build processes
                if echo "$step_name" | grep -qi "build\|compile\|install"; then
                    # Count progress indicators
                    if echo "$filtered_line" | grep -qE "Building|Compiling|Linking|Processing|\.o|\.c|\.zig"; then
                        local count=$(wc -l < "$temp_output")
                        printf "\r🔨 %s... %d files processed" "$step_name" "$count"
                    fi
                elif echo "$step_name" | grep -qi "download\|clone\|fetch"; then
                    # Show download progress
                    if echo "$filtered_line" | grep -qE "%|KB|MB|objects|delta"; then
                        printf "\r📥 %s... %s" "$step_name" "$filtered_line"
                    fi
                fi
                
                # Log detailed output less frequently to avoid spam
                if [ $(($(wc -l < "$temp_output") % 10)) -eq 0 ] || echo "$filtered_line" | grep -qE "(error|failed|warning|completed|finished|done)"; then
                    agent_log "PROCESS" "$(get_process_details "$step_name" "$filtered_line")"
                fi
            done
            echo $? > "$temp_pid_file"
        ) &
        
        local bg_pid=$!
        
        # Monitor with spinner for long-running processes
        if echo "$step_name" | grep -qiE "build|compile"; then
            local start_time=$(date +%s)
            while kill -0 "$bg_pid" 2>/dev/null; do
                local current_time=$(date +%s)
                local elapsed=$((current_time - start_time))
                local mins=$((elapsed / 60))
                local secs=$((elapsed % 60))
                
                local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
                local char="${spinner_chars:$((elapsed % ${#spinner_chars})):1}"
                
                printf "\r%s Building Ghostty... %02d:%02d elapsed" "$char" "$mins" "$secs"
                sleep 1
            done
            printf "\n"
        fi
        
        wait "$bg_pid"
        local exit_code=$?
        
        # Read the actual exit code from the subprocess
        if [ -f "$temp_pid_file" ]; then
            exit_code=$(cat "$temp_pid_file")
        fi
        
        # Show final output summary
        if [ -f "$temp_output" ]; then
            local line_count=$(wc -l < "$temp_output")
            agent_log "INFO" "$(get_process_details "$step_name" "Processed $line_count lines of output")"
            
            # Show last few important lines
            grep -iE "(error|warning|completed|finished|done|success|failed)" "$temp_output" | tail -3 | while read line; do
                agent_log "PROCESS" "$(get_process_details "$step_name" "$line")"
            done
        fi
        
        # Cleanup
        rm -f "$temp_output" "$temp_pid_file"
        
        if [ $exit_code -eq 0 ]; then
            agent_log "SUCCESS" "$(get_step_status "$step_name" "success")"
            return 0
        else
            agent_log "ERROR" "$(get_step_status "$step_name" "error")"
            return 1
        fi
    else
        # Execute silently, just log result
        if eval "$command" >/dev/null 2>&1; then
            agent_log "SUCCESS" "$(get_step_status "$step_name" "success")"
            return 0
        else
            agent_log "ERROR" "$(get_step_status "$step_name" "error")"
            return 1
        fi
    fi
}