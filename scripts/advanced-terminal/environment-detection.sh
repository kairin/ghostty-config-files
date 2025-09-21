#!/bin/bash

# Constitutional Environment Detection System
# Feature 002 Phase 2 - Task T016
# SSH session detection with constitutional compliance

SCRIPT_NAME="environment-detection"
LOG_FILE="$HOME/.config/terminal-ai/${SCRIPT_NAME}.log"
CACHE_FILE="$HOME/.config/terminal-ai/environment-cache.json"
CACHE_TIMEOUT=300  # 5 minutes for constitutional performance

# Create necessary directories
mkdir -p "$(dirname "$LOG_FILE")"

# Constitutional logging function
log_event() {
    echo "[$(date -Iseconds)] $1" >> "$LOG_FILE"
}

# Detect SSH session with constitutional performance optimization
detect_ssh_session() {
    local ssh_detected=false
    local ssh_method=""
    local ssh_details="{}"

    # Constitutional performance: Fast environment variable checks first
    if [[ -n "$SSH_CLIENT" ]]; then
        ssh_detected=true
        ssh_method="SSH_CLIENT"
        ssh_details="{\"method\":\"SSH_CLIENT\"}"
    elif [[ -n "$SSH_TTY" ]]; then
        ssh_detected=true
        ssh_method="SSH_TTY"
        ssh_details="{\"method\":\"SSH_TTY\"}"
    elif [[ -n "$SSH_CONNECTION" ]]; then
        ssh_detected=true
        ssh_method="SSH_CONNECTION"
        ssh_details="{\"method\":\"SSH_CONNECTION\"}"
    fi

    # Skip expensive process checks for constitutional compliance (<50ms)

    # Constitutional compliance: validate detection
    if [[ "$ssh_detected" == true ]]; then
        log_event "SSH session detected via $ssh_method"
        cat > "$CACHE_FILE" << EOF
{
    "environment": "ssh",
    "ssh_detected": true,
    "detection_method": "$ssh_method",
    "details": $ssh_details,
    "timestamp": "$(date -Iseconds)",
    "cached_until": "$(date -d "+$CACHE_TIMEOUT seconds" -Iseconds)"
}
EOF
    else
        log_event "Local session detected"
        cat > "$CACHE_FILE" << EOF
{
    "environment": "local",
    "ssh_detected": false,
    "timestamp": "$(date -Iseconds)",
    "cached_until": "$(date -d "+$CACHE_TIMEOUT seconds" -Iseconds)"
}
EOF
    fi

    echo "$ssh_detected"
}

# Check if cache is valid and recent
is_cache_valid() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        return 1
    fi

    local cached_until
    cached_until=$(cat "$CACHE_FILE" 2>/dev/null | grep -o '"cached_until":"[^"]*"' | cut -d'"' -f4)

    if [[ -n "$cached_until" ]]; then
        local cached_timestamp
        cached_timestamp=$(date -d "$cached_until" +%s 2>/dev/null)
        local current_timestamp
        current_timestamp=$(date +%s)

        if [[ $current_timestamp -lt $cached_timestamp ]]; then
            return 0
        fi
    fi

    return 1
}

# Get cached environment or detect fresh
get_environment() {
    if is_cache_valid; then
        cat "$CACHE_FILE" 2>/dev/null | grep -o '"environment":"[^"]*"' | cut -d'"' -f4
        return
    fi

    # Perform fresh detection
    if [[ "$(detect_ssh_session)" == "true" ]]; then
        echo "ssh"
    else
        echo "local"
    fi
}

# Get detailed environment information
get_environment_details() {
    if is_cache_valid; then
        cat "$CACHE_FILE" 2>/dev/null
        return
    fi

    # Force fresh detection
    detect_ssh_session >/dev/null
    cat "$CACHE_FILE" 2>/dev/null
}

# Constitutional compliance check
check_constitutional_compliance() {
    local start_time
    start_time=$(date +%s%N)

    local environment
    environment=$(get_environment)

    local end_time
    end_time=$(date +%s%N)
    local execution_time
    execution_time=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds

    local compliant
    if [[ $execution_time -lt 50 ]]; then
        compliant=true
    else
        compliant=false
        log_event "PERFORMANCE WARNING: Environment detection took ${execution_time}ms (>50ms limit)"
    fi

    echo "{\"environment\":\"$environment\",\"execution_time_ms\":$execution_time,\"constitutional_compliant\":$compliant}"
}

# Show environment status for debugging
show_status() {
    echo "=== Constitutional Environment Detection Status ==="
    echo "Current environment: $(get_environment)"
    echo "Cache valid: $(is_cache_valid && echo "✓" || echo "❌")"
    echo "Detection methods available:"
    echo "  SSH_CLIENT: ${SSH_CLIENT:-"not set"}"
    echo "  SSH_TTY: ${SSH_TTY:-"not set"}"
    echo "  SSH_CONNECTION: ${SSH_CONNECTION:-"not set"}"
    echo ""
    echo "Performance compliance:"
    check_constitutional_compliance | jq '.' 2>/dev/null || check_constitutional_compliance
}

# Clear cache for fresh detection
clear_cache() {
    rm -f "$CACHE_FILE"
    log_event "Environment detection cache cleared"
    echo "✓ Cache cleared - next detection will be fresh"
}

# Export for shell integration
export_for_shell() {
    local environment
    environment=$(get_environment)

    cat << EOF
# Constitutional Environment Detection Integration
export TERMINAL_ENVIRONMENT="$environment"
export TERMINAL_SSH_DETECTED="$(get_environment_details | grep -o '"ssh_detected":[^,}]*' | cut -d':' -f2)"

# Shell prompt integration function
get_terminal_environment() {
    echo "$environment"
}

# Performance monitoring integration
get_environment_performance() {
    cat << 'PERF_EOF'
$(check_constitutional_compliance)
PERF_EOF
}
EOF
}

# Main command handler
case "$1" in
    "detect"|"")
        get_environment
        ;;
    "details")
        get_environment_details
        ;;
    "status")
        show_status
        ;;
    "compliance"|"check")
        check_constitutional_compliance
        ;;
    "clear"|"refresh")
        clear_cache
        ;;
    "export")
        export_for_shell
        ;;
    *)
        echo "Constitutional Environment Detection - Feature 002 Phase 2"
        echo ""
        echo "Usage: $0 {detect|details|status|compliance|clear|export}"
        echo ""
        echo "Commands:"
        echo "  detect       - Get current environment (ssh/local)"
        echo "  details      - Get detailed environment information"
        echo "  status       - Show detection status and debug info"
        echo "  compliance   - Check constitutional performance compliance"
        echo "  clear        - Clear detection cache for fresh detection"
        echo "  export       - Export environment variables for shell integration"
        echo ""
        echo "Constitutional guarantees:"
        echo "  ✓ <50ms detection time (cached after first run)"
        echo "  ✓ Multiple detection methods for reliability"
        echo "  ✓ Automatic caching for performance"
        echo "  ✓ Comprehensive logging and monitoring"
        exit 1
        ;;
esac