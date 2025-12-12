#!/usr/bin/env bash
# Issue Registry - Pattern definitions for boot issue detection
# This file defines known patterns for automatic issue detection without LLM

# Severity levels
declare -r SEVERITY_CRITICAL="CRITICAL"
declare -r SEVERITY_MODERATE="MODERATE"
declare -r SEVERITY_LOW="LOW"

# Issue types
declare -r TYPE_ORPHANED_SERVICE="ORPHANED_SERVICE"
declare -r TYPE_UNSUPPORTED_SNAP="UNSUPPORTED_SNAP"
declare -r TYPE_NETWORK_WAIT="NETWORK_WAIT"
declare -r TYPE_FAILED_SERVICE="FAILED_SERVICE"
declare -r TYPE_COSMETIC="COSMETIC"

# Known journal patterns for automatic detection
# Format: pattern → issue_type|severity|fixable|description
declare -A JOURNAL_PATTERNS=(
    # Critical patterns - services that are broken
    ["platform.*not supported"]="UNSUPPORTED_SNAP|CRITICAL|YES|Snap not compatible with this Ubuntu version"
    ["Failed at step EXEC spawning"]="ORPHANED_SERVICE|CRITICAL|YES|Service references missing executable"
    ["Failed to start.*\.service"]="FAILED_SERVICE|CRITICAL|MAYBE|Service failed to start"

    # Moderate patterns - performance issues
    ["Timeout occurred while waiting for network"]="NETWORK_WAIT|MODERATE|YES|Network wait service timing out"

    # Low/Cosmetic patterns - no action needed
    ["GOTO.*has no matching label"]="COSMETIC|LOW|NO|Known ALSA packaging bug (Ubuntu #2105475)"
    ["unable to locate daemon control file"]="COSMETIC|LOW|NO|GNOME keyring timing issue (normal)"
    ["SCSI device.*has no device ID"]="COSMETIC|LOW|NO|Normal for snap loop devices"
    ["failed to resume link.*SControl"]="COSMETIC|LOW|NO|Empty SATA ports on motherboard"
    ["loading out-of-tree module taints kernel"]="COSMETIC|LOW|NO|Normal for proprietary drivers (NVIDIA)"
    ["HCI.*command is advertised.*not supported"]="COSMETIC|LOW|NO|Minor Bluetooth driver limitation"
)

# Known snap issues by Ubuntu version
# Non-LTS versions don't support certain snaps
declare -A SNAP_VERSION_ISSUES=(
    ["canonical-livepatch"]="LTS_ONLY|Canonical Livepatch only supports LTS releases"
)

# Service analysis helpers
is_lts_release() {
    local version
    version=$(lsb_release -rs 2>/dev/null || echo "0")
    # LTS versions end in .04 (e.g., 22.04, 24.04)
    [[ "$version" =~ \.04$ ]]
}

get_ubuntu_version() {
    lsb_release -rs 2>/dev/null || echo "unknown"
}

get_ubuntu_codename() {
    lsb_release -cs 2>/dev/null || echo "unknown"
}

# Issue output format
# All detectors must output in this format:
# TYPE|SEVERITY|NAME|DESCRIPTION|FIXABLE|FIX_COMMAND
#
# Example:
# ORPHANED_SERVICE|CRITICAL|github-runner-foo|ExecStart target missing|YES|systemctl --user disable github-runner-foo

format_issue() {
    local type="$1"
    local severity="$2"
    local name="$3"
    local description="$4"
    local fixable="$5"
    local fix_command="${6:-}"

    echo "${type}|${severity}|${name}|${description}|${fixable}|${fix_command}"
}

# Severity color codes for display
get_severity_color() {
    local severity="$1"
    case "$severity" in
        CRITICAL) echo "196" ;;  # Red
        MODERATE) echo "208" ;;  # Orange
        LOW)      echo "246" ;;  # Gray
        *)        echo "255" ;;  # White
    esac
}

get_severity_icon() {
    local severity="$1"
    case "$severity" in
        CRITICAL) echo "🔴" ;;
        MODERATE) echo "🟡" ;;
        LOW)      echo "🟢" ;;
        *)        echo "⚪" ;;
    esac
}

# Check if a fix requires sudo
fix_requires_sudo() {
    local fix_command="$1"
    [[ "$fix_command" == sudo* || "$fix_command" == *"sudo "* ]]
}
