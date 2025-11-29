#!/bin/bash

# Shared Logging Utility
# Usage: source 006-logs/logger.sh
# Logs are saved to 006-logs/YYYYMMDD-HHMMSS-<script_name>.log

# Get the directory of this script (006-logs)
LOGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$LOGS_DIR")"

# Initialize log file
init_log() {
    local script_name=$(basename "$0" .sh)
    local timestamp=$(date +"%Y%m%d-%H%M%S")
    LOG_FILE="$LOGS_DIR/${timestamp}-${script_name}.log"
    touch "$LOG_FILE"
    log "INFO" "Log initialized: $LOG_FILE"
}

# Log function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    # Console output (colorized)
    case "$level" in
        INFO)    echo -e "\033[34m[INFO]\033[0m $message" >&2 ;;
        SUCCESS) echo -e "\033[32m[SUCCESS]\033[0m $message" >&2 ;;
        WARNING) echo -e "\033[33m[WARNING]\033[0m $message" >&2 ;;
        ERROR)   echo -e "\033[31m[ERROR]\033[0m $message" >&2 ;;
        *)       echo "[$level] $message" >&2 ;;
    esac
    
    # File output
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Ensure log is initialized
if [ -z "$LOG_FILE" ]; then
    init_log
fi
