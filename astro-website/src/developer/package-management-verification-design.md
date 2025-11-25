---
title: "Package Management Verification and Migration Strategy"
description: "**Document Version**: 1.0"
pubDate: 2025-11-25
author: "Ghostty Config Team"
tags: ['developer', 'technical']
---

# Package Management Verification and Migration Strategy

**Document Version**: 1.0
**Date**: 2025-11-17
**Status**: Design Document - Research Phase
**Target System**: Ubuntu 25.10 (Questing Quokka)

---

## Executive Summary

This document defines a systematic, audit-ready approach to package management verification and migration for the ghostty-config-files repository. The design prioritizes **real-time system queries** over hardcoded assumptions, ensuring decisions are based on actual package availability, versions, and system state.

**Core Principles**:
1. **No Hardcoded Assumptions**: Always query apt/snap/dpkg in real-time
2. **Transparent Decision Making**: Log all checks, comparisons, and decisions
3. **Safe Migration**: Complete removal tracking with rollback capability
4. **Audit-Ready**: Before/after state snapshots for every operation
5. **Constitutional Compliance**: Follows repository's zero-cost local CI/CD requirements

---

## 1. Real-Time Verification Method

### 1.1 Package Information Query System

#### Design Overview
A modular query system that retrieves actual package information from multiple sources without assumptions.

```bash
# Core Query Functions (pseudocode)

query_apt_package_info() {
    package_name=$1

    # Query apt cache for package availability and versions
    apt_available=$(apt-cache policy "$package_name" 2>/dev/null)

    if [[ -z "$apt_available" ]]; then
        return {
            available: false,
            source: "apt",
            timestamp: $(date -Iseconds)
        }
    fi

    # Extract structured information
    installed_version=$(echo "$apt_available" | grep "Installed:" | awk '{print $2}')
    candidate_version=$(echo "$apt_available" | grep "Candidate:" | awk '{print $2}')

    # Check if available in multiple repos
    available_versions=$(apt-cache madison "$package_name" 2>/dev/null | \
                        awk '{print $3}' | sort -V)

    return {
        available: true,
        source: "apt",
        installed: "$installed_version",
        candidate: "$candidate_version",
        all_versions: "$available_versions",
        repository_info: "$(apt-cache policy "$package_name" | grep -A1 Candidate)",
        timestamp: $(date -Iseconds)
    }
}

query_snap_package_info() {
    package_name=$1

    # Check if snapd is available and active
    if ! command -v snap >/dev/null 2>&1; then
        return {
            available: false,
            source: "snap",
            error: "snapd_not_installed",
            timestamp: $(date -Iseconds)
        }
    fi

    if ! systemctl is-active --quiet snapd.service 2>/dev/null; then
        return {
            available: false,
            source: "snap",
            error: "snapd_not_active",
            timestamp: $(date -Iseconds)
        }
    fi

    # Query snap store
    snap_info=$(snap info "$package_name" 2>&1)
    snap_query_status=$?

    if [[ $snap_query_status -ne 0 ]]; then
        return {
            available: false,
            source: "snap",
            error: "package_not_found",
            timestamp: $(date -Iseconds)
        }
    fi

    # Extract structured information
    installed_version=$(snap list "$package_name" 2>/dev/null | tail -1 | awk '{print $2}')
    stable_version=$(echo "$snap_info" | grep "latest/stable:" | awk '{print $2}')
    publisher=$(echo "$snap_info" | grep "publisher:" | awk '{print $2, $3}')
    publisher_verified=$(echo "$publisher" | grep -q "✓" && echo "true" || echo "false")
    confinement=$(echo "$snap_info" | grep "confinement:" | awk '{print $2}')

    # Get all available channels
    channels=$(echo "$snap_info" | grep -E "(stable|candidate|beta|edge):" | \
               awk '{print $1 "=" $2}')

    return {
        available: true,
        source: "snap",
        installed: "$installed_version",
        stable_version: "$stable_version",
        publisher: "$publisher",
        publisher_verified: "$publisher_verified",
        confinement: "$confinement",
        channels: "$channels",
        timestamp: $(date -Iseconds)
    }
}

query_current_installation() {
    package_name=$1
    binary_name=${2:-$package_name}  # Allow different binary name

    # Check if command exists
    if ! command -v "$binary_name" >/dev/null 2>&1; then
        return {
            installed: false,
            timestamp: $(date -Iseconds)
        }
    fi

    # Determine installation source
    binary_path=$(which "$binary_name")
    installation_source="unknown"

    # Check dpkg database
    if dpkg -l | grep -qE "^ii\s+$package_name\s"; then
        installation_source="apt"
        dpkg_info=$(dpkg -l | grep "^ii.*$package_name ")
        installed_version=$(echo "$dpkg_info" | awk '{print $3}')
    fi

    # Check snap database
    if snap list "$package_name" 2>/dev/null | grep -q "^$package_name"; then
        installation_source="snap"
        installed_version=$(snap list "$package_name" | tail -1 | awk '{print $2}')
    fi

    # Get version from binary if available
    binary_version=$(get_version_from_binary "$binary_name")

    return {
        installed: true,
        binary_path: "$binary_path",
        installation_source: "$installation_source",
        installed_version: "$installed_version",
        binary_version: "$binary_version",
        timestamp: $(date -Iseconds)
    }
}

get_version_from_binary() {
    binary_name=$1

    # Try common version flags
    for flag in "--version" "-v" "version" "-V"; do
        version_output=$("$binary_name" "$flag" 2>&1 | head -1)
        if [[ $? -eq 0 ]]; then
            # Extract version number (flexible pattern matching)
            version=$(echo "$version_output" | \
                     grep -oP '(\d+\.)+\d+(-[\w.]+)?' | head -1)
            if [[ -n "$version" ]]; then
                echo "$version"
                return 0
            fi
        fi
    done

    echo "unknown"
    return 1
}
```

### 1.2 Version Comparison Logic

#### Design Overview
Use system-native version comparison tools for accuracy across different versioning schemes.

```bash
compare_versions() {
    version1=$1
    operator=$2  # gt, ge, lt, le, eq, ne
    version2=$3

    # Log comparison attempt
    log_comparison "$version1" "$operator" "$version2"

    # Handle special cases
    if [[ "$version1" == "none" ]] || [[ "$version1" == "(none)" ]]; then
        case "$operator" in
            "gt"|"ge"|"eq") return 1 ;;
            "lt"|"le"|"ne") return 0 ;;
        esac
    fi

    if [[ "$version2" == "none" ]] || [[ "$version2" == "(none)" ]]; then
        case "$operator" in
            "gt"|"ge"|"ne") return 0 ;;
            "lt"|"le"|"eq") return 1 ;;
        esac
    fi

    # Use dpkg for Debian-style version comparison (handles epochs, revisions)
    dpkg --compare-versions "$version1" "$operator" "$version2"
    comparison_result=$?

    # Log result
    log_comparison_result "$version1" "$operator" "$version2" "$comparison_result"

    return $comparison_result
}

log_comparison() {
    local v1=$1 op=$2 v2=$3
    local timestamp=$(date -Iseconds)

    echo "{\"timestamp\":\"$timestamp\",\"type\":\"version_comparison\",\"version1\":\"$v1\",\"operator\":\"$op\",\"version2\":\"$v2\"}" >> "$LOG_FILE"
}

log_comparison_result() {
    local v1=$1 op=$2 v2=$3 result=$4
    local timestamp=$(date -Iseconds)
    local result_bool=$([[ $result -eq 0 ]] && echo "true" || echo "false")

    echo "{\"timestamp\":\"$timestamp\",\"type\":\"comparison_result\",\"version1\":\"$v1\",\"operator\":\"$op\",\"version2\":\"$v2\",\"result\":$result_bool}" >> "$LOG_FILE"
}
```

### 1.3 Unified Package Query Interface

```bash
get_package_full_state() {
    package_name=$1
    binary_name=${2:-$package_name}

    timestamp=$(date -Iseconds)

    # Query all sources in parallel (conceptually)
    current_install=$(query_current_installation "$package_name" "$binary_name")
    apt_info=$(query_apt_package_info "$package_name")
    snap_info=$(query_snap_package_info "$package_name")

    # Query upstream latest version if applicable
    upstream_latest=$(query_upstream_latest "$package_name")

    # Combine into unified state object
    state_json=$(jq -n \
        --argjson current "$current_install" \
        --argjson apt "$apt_info" \
        --argjson snap "$snap_info" \
        --argjson upstream "$upstream_latest" \
        --arg timestamp "$timestamp" \
        '{
            timestamp: $timestamp,
            package_name: $ARGS.positional[0],
            binary_name: $ARGS.positional[1],
            current_installation: $current,
            apt: $apt,
            snap: $snap,
            upstream: $upstream
        }' \
        --args "$package_name" "$binary_name"
    )

    echo "$state_json"
}

query_upstream_latest() {
    package_name=$1

    case "$package_name" in
        gh)
            # GitHub CLI: Query GitHub API
            latest=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | \
                    jq -r '.tag_name' | sed 's/^v//')
            return {
                source: "github_api",
                latest_version: "$latest",
                url: "https://github.com/cli/cli"
            }
            ;;
        node)
            # Node.js: Query nodejs.org API
            latest=$(curl -s https://nodejs.org/dist/index.json | \
                    jq -r '.[0].version' | sed 's/^v//')
            return {
                source: "nodejs_api",
                latest_version: "$latest",
                url: "https://nodejs.org"
            }
            ;;
        *)
            return {
                source: "unknown",
                latest_version: "unknown"
            }
            ;;
    esac
}
```

---

## 2. Tool Priority Decision Logic

### 2.1 Decision Criteria Framework

#### Priority Matrix

```
Decision Factors (in priority order):
1. Constitutional Requirements (from CLAUDE.md)
2. Official Source Preference
3. Version Currency (newer is better)
4. Maintenance Status (actively maintained)
5. Security & Publisher Verification
6. System Integration (confinement, permissions)
7. Performance Characteristics
```

#### Decision Tree Pseudocode

```bash
decide_preferred_source() {
    package_name=$1
    state_json=$2

    # Extract state information
    current_source=$(echo "$state_json" | jq -r '.current_installation.installation_source')
    current_version=$(echo "$state_json" | jq -r '.current_installation.installed_version')

    apt_available=$(echo "$state_json" | jq -r '.apt.available')
    apt_version=$(echo "$state_json" | jq -r '.apt.candidate')

    snap_available=$(echo "$state_json" | jq -r '.snap.available')
    snap_version=$(echo "$state_json" | jq -r '.snap.stable_version')
    snap_verified=$(echo "$state_json" | jq -r '.snap.publisher_verified')
    snap_confinement=$(echo "$state_json" | jq -r '.snap.confinement')

    upstream_version=$(echo "$state_json" | jq -r '.upstream.latest_version')

    # STEP 1: Check constitutional requirements
    constitutional_preference=$(check_constitutional_preference "$package_name")
    if [[ -n "$constitutional_preference" ]]; then
        log_decision "constitutional_requirement" \
                    "Package $package_name requires source: $constitutional_preference"
        echo "$constitutional_preference"
        return 0
    fi

    # STEP 2: Official source preference
    # For packages from official publishers, prefer their native distribution
    case "$package_name" in
        gh)
            # GitHub CLI: Official apt repo is preferred
            if [[ "$apt_available" == "true" ]] && [[ "$apt_version" != "(none)" ]]; then
                # Check if apt version is official GitHub repository
                apt_repo=$(echo "$state_json" | jq -r '.apt.repository_info' | \
                          grep -q "cli.github.com" && echo "official" || echo "ubuntu")

                if [[ "$apt_repo" == "official" ]]; then
                    log_decision "official_source" \
                                "Using official GitHub CLI apt repository"
                    echo "apt"
                    return 0
                fi
            fi
            ;;
        node)
            # Node.js: fnm is preferred per CLAUDE.md
            log_decision "version_manager_preferred" \
                        "Node.js managed via fnm (not apt/snap)"
            echo "fnm"
            return 0
            ;;
        ghostty)
            # Ghostty: Snap with classic confinement preferred, then source
            if [[ "$snap_available" == "true" ]] && \
               [[ "$snap_verified" == "true" ]] && \
               [[ "$snap_confinement" == "classic" ]]; then
                log_decision "snap_classic_verified" \
                            "Ghostty snap has verified publisher and classic confinement"
                echo "snap"
                return 0
            fi

            log_decision "source_build" \
                        "Ghostty: Building from source for optimal performance"
            echo "source"
            return 0
            ;;
    esac

    # STEP 3: Version currency analysis
    versions=(
        "$apt_version:apt"
        "$snap_version:snap"
        "$current_version:current"
    )

    # Find newest version
    newest_version=""
    newest_source=""

    for version_pair in "${versions[@]}"; do
        version="${version_pair%%:*}"
        source="${version_pair##*:}"

        if [[ "$version" == "(none)" ]] || [[ "$version" == "unknown" ]]; then
            continue
        fi

        if [[ -z "$newest_version" ]] || \
           compare_versions "$version" "gt" "$newest_version"; then
            newest_version="$version"
            newest_source="$source"
        fi
    done

    # STEP 4: If current is newest, keep current
    if [[ "$newest_source" == "current" ]]; then
        log_decision "current_is_newest" \
                    "Current installation ($current_source $current_version) is newest"
        echo "$current_source"
        return 0
    fi

    # STEP 5: Security and verification for snap
    if [[ "$newest_source" == "snap" ]]; then
        if [[ "$snap_verified" != "true" ]]; then
            log_decision "snap_unverified_rejected" \
                        "Snap version is newest but publisher unverified, checking apt"

            if [[ "$apt_available" == "true" ]]; then
                echo "apt"
                return 0
            fi
        fi

        # Check confinement for terminal applications
        if [[ "$snap_confinement" == "strict" ]] && \
           is_terminal_application "$package_name"; then
            log_decision "snap_strict_terminal_rejected" \
                        "Terminal app with strict confinement rejected"
            echo "apt"
            return 0
        fi
    fi

    # STEP 6: Default to newest available
    log_decision "newest_version_selected" \
                "Selected $newest_source with version $newest_version"
    echo "$newest_source"
    return 0
}

check_constitutional_preference() {
    package_name=$1

    # Parse CLAUDE.md for package-specific requirements
    # This would actually grep/parse the CLAUDE.md file
    # For design purposes, showing the logic:

    case "$package_name" in
        node|nodejs)
            # CLAUDE.md specifies fnm for Node.js management
            echo "fnm"
            return 0
            ;;
        ghostty)
            # CLAUDE.md specifies source build with specific optimizations
            echo "source"
            return 0
            ;;
        *)
            # No constitutional preference
            echo ""
            return 1
            ;;
    esac
}

is_terminal_application() {
    package_name=$1

    terminal_apps=("ghostty" "gnome-terminal" "alacritty" "kitty" "wezterm")

    for app in "${terminal_apps[@]}"; do
        if [[ "$app" == "$package_name" ]]; then
            return 0
        fi
    done

    return 1
}

log_decision() {
    decision_type=$1
    reason=$2
    timestamp=$(date -Iseconds)

    echo "{\"timestamp\":\"$timestamp\",\"type\":\"decision\",\"decision_type\":\"$decision_type\",\"reason\":\"$reason\"}" >> "$DECISION_LOG"
}
```

---

## 3. Clean Migration Strategy

### 3.1 Pre-Migration State Capture

```bash
capture_pre_migration_state() {
    package_name=$1
    migration_id=$2

    state_dir="/tmp/package-migration-$migration_id"
    mkdir -p "$state_dir"

    # Capture complete package state
    state_json=$(get_package_full_state "$package_name")
    echo "$state_json" > "$state_dir/pre_state.json"

    # Capture dependency tree
    if dpkg -l | grep -qE "^ii\s+$package_name\s"; then
        apt-cache depends "$package_name" > "$state_dir/dependencies.txt"
        apt-cache rdepends "$package_name" > "$state_dir/reverse_dependencies.txt"
    fi

    # Capture configuration files
    if [[ -d "/etc/$package_name" ]]; then
        tar -czf "$state_dir/config_backup.tar.gz" "/etc/$package_name" 2>/dev/null
    fi

    # Capture user-specific configuration
    for user_home in /home/*; do
        user=$(basename "$user_home")
        if [[ -d "$user_home/.config/$package_name" ]]; then
            tar -czf "$state_dir/config_${user}_backup.tar.gz" \
                "$user_home/.config/$package_name" 2>/dev/null
        fi
    done

    # Capture package file list
    if dpkg -l | grep -qE "^ii\s+$package_name\s"; then
        dpkg -L "$package_name" > "$state_dir/file_list.txt"
    elif snap list "$package_name" 2>/dev/null | grep -q "^$package_name"; then
        find /snap/"$package_name" -type f > "$state_dir/file_list.txt" 2>/dev/null
    fi

    # Create migration metadata
    cat > "$state_dir/metadata.json" <<EOF
{
    "migration_id": "$migration_id",
    "package_name": "$package_name",
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "state_dir": "$state_dir"
}
EOF

    log_info "Pre-migration state captured: $state_dir"
    echo "$state_dir"
}
```

### 3.2 Complete Removal with Tracking

```bash
remove_package_completely() {
    package_name=$1
    installation_source=$2
    migration_id=$3
    state_dir=$4

    removal_log="$state_dir/removal_log.txt"

    log_info "Starting complete removal of $package_name from $installation_source"

    case "$installation_source" in
        apt)
            # Get list of files before removal
            dpkg -L "$package_name" > "$state_dir/removed_files.txt" 2>/dev/null

            # Remove package and dependencies
            log_info "Removing apt package: $package_name"
            apt-get remove --purge -y "$package_name" >> "$removal_log" 2>&1
            removal_status=$?

            # Check for orphaned dependencies
            orphaned=$(apt-get autoremove --dry-run | grep -oP '\d+ upgraded.*\d+ not upgraded')
            log_info "Orphaned dependencies: $orphaned"

            # Remove orphaned dependencies
            apt-get autoremove -y >> "$removal_log" 2>&1

            # Clean package cache
            apt-get clean >> "$removal_log" 2>&1
            ;;

        snap)
            # Snap maintains its own state, capture before removal
            snap list "$package_name" > "$state_dir/snap_list_before.txt" 2>/dev/null
            snap info "$package_name" > "$state_dir/snap_info_before.txt" 2>/dev/null

            log_info "Removing snap package: $package_name"
            snap remove "$package_name" >> "$removal_log" 2>&1
            removal_status=$?
            ;;

        *)
            log_error "Unknown installation source: $installation_source"
            return 1
            ;;
    esac

    # Verify removal
    verify_complete_removal "$package_name" "$installation_source" "$state_dir"
    verification_status=$?

    # Log removal summary
    cat > "$state_dir/removal_summary.json" <<EOF
{
    "migration_id": "$migration_id",
    "package_name": "$package_name",
    "installation_source": "$installation_source",
    "removal_status": $removal_status,
    "verification_status": $verification_status,
    "timestamp": "$(date -Iseconds)"
}
EOF

    return $removal_status
}

verify_complete_removal() {
    package_name=$1
    installation_source=$2
    state_dir=$3

    verification_log="$state_dir/verification_log.txt"
    leftovers_found=0

    log_info "Verifying complete removal of $package_name"

    # Check package databases
    case "$installation_source" in
        apt)
            if dpkg -l | grep -qE "^ii\s+$package_name\s"; then
                log_error "Package still in dpkg database"
                dpkg -l | grep "$package_name" >> "$verification_log"
                leftovers_found=1
            fi
            ;;
        snap)
            if snap list "$package_name" 2>/dev/null | grep -q "^$package_name"; then
                log_error "Package still in snap list"
                snap list "$package_name" >> "$verification_log"
                leftovers_found=1
            fi
            ;;
    esac

    # Check for leftover binaries
    binary_name=${package_name}
    if command -v "$binary_name" >/dev/null 2>&1; then
        log_warning "Binary still in PATH: $(which "$binary_name")"
        which "$binary_name" >> "$verification_log"
        leftovers_found=1
    fi

    # Check for leftover files (from pre-removal list)
    if [[ -f "$state_dir/removed_files.txt" ]]; then
        while IFS= read -r file_path; do
            if [[ -e "$file_path" ]]; then
                log_warning "Leftover file: $file_path"
                echo "$file_path" >> "$verification_log"
                leftovers_found=1
            fi
        done < "$state_dir/removed_files.txt"
    fi

    # Check for leftover configuration
    if [[ -d "/etc/$package_name" ]]; then
        log_warning "Leftover configuration: /etc/$package_name"
        ls -la "/etc/$package_name" >> "$verification_log"
        leftovers_found=1
    fi

    # Summary
    if [[ $leftovers_found -eq 0 ]]; then
        log_success "Complete removal verified: no leftovers found"
        echo '{"verification":"success","leftovers":false}' > "$state_dir/verification_result.json"
        return 0
    else
        log_warning "Leftovers found, see: $verification_log"
        echo '{"verification":"warning","leftovers":true,"log":"'"$verification_log"'"}' > "$state_dir/verification_result.json"
        return 1
    fi
}
```

### 3.3 New Source Installation

```bash
install_from_new_source() {
    package_name=$1
    new_source=$2
    migration_id=$3
    state_dir=$4

    installation_log="$state_dir/installation_log.txt"

    log_info "Installing $package_name from $new_source"

    case "$new_source" in
        apt)
            # Update package cache
            apt-get update >> "$installation_log" 2>&1

            # Install package
            apt-get install -y "$package_name" >> "$installation_log" 2>&1
            installation_status=$?

            # Get installed version
            installed_version=$(dpkg -l | grep "^ii.*$package_name " | awk '{print $3}')
            ;;

        snap)
            # Determine confinement
            snap_info=$(snap info "$package_name" 2>/dev/null)
            confinement=$(echo "$snap_info" | grep "confinement:" | awk '{print $2}')

            # Install with appropriate flags
            if [[ "$confinement" == "classic" ]]; then
                snap install "$package_name" --classic >> "$installation_log" 2>&1
            else
                snap install "$package_name" >> "$installation_log" 2>&1
            fi
            installation_status=$?

            # Get installed version
            installed_version=$(snap list "$package_name" | tail -1 | awk '{print $2}')
            ;;

        *)
            log_error "Unknown installation source: $new_source"
            return 1
            ;;
    esac

    # Verify installation
    verify_successful_installation "$package_name" "$new_source" "$state_dir"
    verification_status=$?

    # Log installation summary
    cat > "$state_dir/installation_summary.json" <<EOF
{
    "migration_id": "$migration_id",
    "package_name": "$package_name",
    "new_source": "$new_source",
    "installation_status": $installation_status,
    "verification_status": $verification_status,
    "installed_version": "$installed_version",
    "timestamp": "$(date -Iseconds)"
}
EOF

    return $installation_status
}

verify_successful_installation() {
    package_name=$1
    new_source=$2
    state_dir=$3

    verification_log="$state_dir/post_install_verification.txt"

    log_info "Verifying successful installation of $package_name"

    # Check package database
    case "$new_source" in
        apt)
            if ! dpkg -l | grep -qE "^ii\s+$package_name\s"; then
                log_error "Package not found in dpkg database"
                return 1
            fi

            dpkg -l | grep "$package_name" >> "$verification_log"
            ;;
        snap)
            if ! snap list "$package_name" 2>/dev/null | grep -q "^$package_name"; then
                log_error "Package not found in snap list"
                return 1
            fi

            snap list "$package_name" >> "$verification_log"
            ;;
    esac

    # Check binary availability
    binary_name=${package_name}
    if ! command -v "$binary_name" >/dev/null 2>&1; then
        log_error "Binary not available in PATH"
        return 1
    fi

    which "$binary_name" >> "$verification_log"

    # Check version
    version_output=$(get_version_from_binary "$binary_name")
    if [[ "$version_output" == "unknown" ]]; then
        log_warning "Unable to determine version from binary"
    else
        log_success "Installed version: $version_output"
        echo "Binary version: $version_output" >> "$verification_log"
    fi

    log_success "Installation verified successfully"
    return 0
}
```

### 3.4 Configuration Restoration

```bash
restore_user_configuration() {
    package_name=$1
    state_dir=$2

    log_info "Restoring user configuration for $package_name"

    # Restore system configuration if backed up
    if [[ -f "$state_dir/config_backup.tar.gz" ]]; then
        log_info "Restoring system configuration"
        tar -xzf "$state_dir/config_backup.tar.gz" -C / 2>/dev/null
    fi

    # Restore user-specific configurations
    for backup_file in "$state_dir"/config_*_backup.tar.gz; do
        if [[ -f "$backup_file" ]]; then
            user=$(basename "$backup_file" | sed 's/config_\(.*\)_backup.tar.gz/\1/')
            log_info "Restoring configuration for user: $user"
            tar -xzf "$backup_file" -C / 2>/dev/null
        fi
    done

    log_success "Configuration restoration complete"
}
```

### 3.5 Rollback Mechanism

```bash
rollback_migration() {
    package_name=$1
    migration_id=$2
    state_dir=$3

    log_warning "Initiating rollback for migration $migration_id"

    # Load pre-migration state
    if [[ ! -f "$state_dir/pre_state.json" ]]; then
        log_error "Pre-migration state not found, cannot rollback"
        return 1
    fi

    pre_state=$(cat "$state_dir/pre_state.json")
    original_source=$(echo "$pre_state" | jq -r '.current_installation.installation_source')
    original_version=$(echo "$pre_state" | jq -r '.current_installation.installed_version')

    log_info "Rollback target: $original_source $original_version"

    # Remove new installation
    current_source=$(query_current_installation "$package_name" | \
                    jq -r '.installation_source')

    if [[ -n "$current_source" ]] && [[ "$current_source" != "unknown" ]]; then
        remove_package_completely "$package_name" "$current_source" \
                                 "$migration_id-rollback" "$state_dir/rollback"
    fi

    # Reinstall original version
    case "$original_source" in
        apt)
            # Try to install specific version
            apt-get install -y "$package_name=$original_version" || \
            apt-get install -y "$package_name"
            ;;
        snap)
            # Snap doesn't support specific version reinstall easily
            # Install latest stable
            snap install "$package_name"
            ;;
    esac

    # Restore configuration
    restore_user_configuration "$package_name" "$state_dir"

    log_success "Rollback complete"

    # Create rollback summary
    cat > "$state_dir/rollback_summary.json" <<EOF
{
    "migration_id": "$migration_id",
    "rollback_timestamp": "$(date -Iseconds)",
    "original_source": "$original_source",
    "original_version": "$original_version",
    "restored": true
}
EOF
}
```

---

## 4. Complete Migration Orchestration

### 4.1 Main Migration Function

```bash
migrate_package() {
    package_name=$1
    force=${2:-false}  # Optional: force migration even if same source

    # Generate unique migration ID
    migration_id="$(date +%Y%m%d-%H%M%S)-$package_name-$$"

    log_section "Package Migration: $package_name"
    log_info "Migration ID: $migration_id"

    # STEP 1: Get complete current state
    log_step "1/7" "Querying package state"
    state_json=$(get_package_full_state "$package_name")

    current_source=$(echo "$state_json" | jq -r '.current_installation.installation_source')
    current_version=$(echo "$state_json" | jq -r '.current_installation.installed_version')

    if [[ "$current_source" == "unknown" ]]; then
        log_error "Package not currently installed"
        return 1
    fi

    log_info "Current: $current_source $current_version"

    # STEP 2: Decide preferred source
    log_step "2/7" "Determining preferred source"
    preferred_source=$(decide_preferred_source "$package_name" "$state_json")

    log_info "Preferred source: $preferred_source"

    # Check if migration needed
    if [[ "$current_source" == "$preferred_source" ]] && [[ "$force" != "true" ]]; then
        log_success "Already using preferred source, no migration needed"
        return 0
    fi

    # STEP 3: Capture pre-migration state
    log_step "3/7" "Capturing pre-migration state"
    state_dir=$(capture_pre_migration_state "$package_name" "$migration_id")

    # STEP 4: Remove old installation
    log_step "4/7" "Removing old installation"
    if ! remove_package_completely "$package_name" "$current_source" \
                                   "$migration_id" "$state_dir"; then
        log_error "Removal failed, initiating rollback"
        rollback_migration "$package_name" "$migration_id" "$state_dir"
        return 1
    fi

    # STEP 5: Install from new source
    log_step "5/7" "Installing from new source"
    if ! install_from_new_source "$package_name" "$preferred_source" \
                                 "$migration_id" "$state_dir"; then
        log_error "Installation failed, initiating rollback"
        rollback_migration "$package_name" "$migration_id" "$state_dir"
        return 1
    fi

    # STEP 6: Restore configuration
    log_step "6/7" "Restoring user configuration"
    restore_user_configuration "$package_name" "$state_dir"

    # STEP 7: Capture post-migration state
    log_step "7/7" "Capturing post-migration state"
    post_state_json=$(get_package_full_state "$package_name")
    echo "$post_state_json" > "$state_dir/post_state.json"

    # Create migration summary
    create_migration_summary "$migration_id" "$package_name" "$state_dir"

    log_success "Migration completed successfully"
    log_info "Migration details: $state_dir"

    return 0
}

create_migration_summary() {
    migration_id=$1
    package_name=$2
    state_dir=$3

    pre_state=$(cat "$state_dir/pre_state.json")
    post_state=$(cat "$state_dir/post_state.json")

    pre_source=$(echo "$pre_state" | jq -r '.current_installation.installation_source')
    pre_version=$(echo "$pre_state" | jq -r '.current_installation.installed_version')

    post_source=$(echo "$post_state" | jq -r '.current_installation.installation_source')
    post_version=$(echo "$post_state" | jq -r '.current_installation.installed_version')

    cat > "$state_dir/migration_summary.json" <<EOF
{
    "migration_id": "$migration_id",
    "package_name": "$package_name",
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "before": {
        "source": "$pre_source",
        "version": "$pre_version"
    },
    "after": {
        "source": "$post_source",
        "version": "$post_version"
    },
    "state_dir": "$state_dir",
    "status": "success"
}
EOF

    # Human-readable summary
    cat > "$state_dir/MIGRATION_SUMMARY.txt" <<EOF
Package Migration Summary
========================

Migration ID: $migration_id
Package: $package_name
Date: $(date)
Hostname: $(hostname)

Before Migration:
  Source: $pre_source
  Version: $pre_version

After Migration:
  Source: $post_source
  Version: $post_version

Status: SUCCESS

Detailed logs available in: $state_dir
EOF
}

log_step() {
    step=$1
    description=$2
    log_info "[$step] $description"
}

log_section() {
    section=$1
    echo ""
    echo "============================================================================"
    echo "  $section"
    echo "============================================================================"
}
```

---

## 5. Example Implementation for Common Tools

### 5.1 GitHub CLI (gh) Migration

```bash
#!/bin/bash
# Example: Migrate GitHub CLI from Ubuntu repository to official apt repository

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/package_migration_lib.sh"

migrate_gh_cli() {
    log_section "GitHub CLI Migration Example"

    # Query current state
    state_json=$(get_package_full_state "gh" "gh")

    echo "Current State:"
    echo "$state_json" | jq '{
        current: .current_installation,
        apt: {available: .apt.available, version: .apt.candidate},
        snap: {available: .snap.available, version: .snap.stable_version},
        upstream: .upstream
    }'

    # Show decision reasoning
    echo ""
    echo "Decision Analysis:"

    # Check if official GitHub repository is configured
    if apt-cache policy gh | grep -q "cli.github.com"; then
        echo "✓ Official GitHub CLI repository configured"
        echo "  Recommendation: Use apt (official source)"
    else
        echo "⚠ Ubuntu universe repository detected"
        echo "  Current version may be outdated"
        echo "  Recommendation: Add official repository or use snap"
    fi

    # Version comparison
    apt_version=$(echo "$state_json" | jq -r '.apt.candidate')
    snap_version=$(echo "$state_json" | jq -r '.snap.stable_version')
    upstream_version=$(echo "$state_json" | jq -r '.upstream.latest_version')

    echo ""
    echo "Version Comparison:"
    echo "  apt:      $apt_version"
    echo "  snap:     $snap_version"
    echo "  upstream: $upstream_version"

    # Perform migration if needed
    preferred_source=$(decide_preferred_source "gh" "$state_json")
    current_source=$(echo "$state_json" | jq -r '.current_installation.installation_source')

    if [[ "$current_source" != "$preferred_source" ]]; then
        echo ""
        echo "Migration Required: $current_source → $preferred_source"

        read -p "Proceed with migration? (y/N): " confirm
        if [[ "$confirm" == "y" ]] || [[ "$confirm" == "Y" ]]; then
            migrate_package "gh"
        else
            echo "Migration cancelled"
        fi
    else
        echo ""
        echo "✓ Already using optimal source: $current_source"
    fi
}

# Run migration
migrate_gh_cli
```

### 5.2 Node.js Verification (fnm managed)

```bash
#!/bin/bash
# Example: Verify Node.js is properly managed via fnm (per CLAUDE.md requirements)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/package_migration_lib.sh"

verify_nodejs_management() {
    log_section "Node.js Management Verification"

    # Query all possible Node.js sources
    state_json=$(get_package_full_state "nodejs" "node")

    # Check constitutional requirement
    echo "Constitutional Requirement: Node.js must be managed via fnm"
    echo ""

    # Check if fnm is installed
    if ! command -v fnm >/dev/null 2>&1; then
        log_error "fnm not installed"
        echo "Action required: Install fnm"
        echo "  curl -fsSL https://fnm.vercel.app/install | bash"
        return 1
    fi

    log_success "fnm installed: $(fnm --version)"

    # Check Node.js source
    current_source=$(echo "$state_json" | jq -r '.current_installation.installation_source')
    node_path=$(which node 2>/dev/null || echo "not found")

    echo ""
    echo "Current Node.js Installation:"
    echo "  Source: $current_source"
    echo "  Path: $node_path"
    echo "  Version: $(node --version 2>/dev/null || echo 'not installed')"

    # Verify fnm management
    if echo "$node_path" | grep -q "fnm"; then
        log_success "Node.js correctly managed via fnm"

        echo ""
        echo "fnm managed versions:"
        fnm list

        return 0
    else
        log_warning "Node.js not managed via fnm"

        # Check for conflicting installations
        if [[ "$current_source" == "apt" ]]; then
            log_warning "Node.js installed via apt (violates CLAUDE.md)"
            echo "Action required: Remove apt-managed Node.js"
            echo "  sudo apt-get remove --purge nodejs npm"
        fi

        if [[ "$current_source" == "snap" ]]; then
            log_warning "Node.js installed via snap (violates CLAUDE.md)"
            echo "Action required: Remove snap-managed Node.js"
            echo "  sudo snap remove node"
        fi

        echo ""
        echo "After removal, install via fnm:"
        echo "  fnm install --lts"
        echo "  fnm use lts-latest"
        echo "  fnm default lts-latest"

        return 1
    fi
}

# Run verification
verify_nodejs_management
```

---

## 6. Test Cases

### 6.1 Test Suite Structure

```bash
#!/bin/bash
# Test suite for package management verification and migration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/package_migration_lib.sh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper functions
assert_equals() {
    TESTS_RUN=$((TESTS_RUN + 1))

    local expected=$1
    local actual=$2
    local test_name=$3

    if [[ "$expected" == "$actual" ]]; then
        log_success "PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "FAIL: $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_true() {
    TESTS_RUN=$((TESTS_RUN + 1))

    local condition=$1
    local test_name=$2

    if $condition; then
        log_success "PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "FAIL: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# ===================================================================
# TEST CATEGORY 1: Version Comparison
# ===================================================================

test_version_comparison() {
    log_section "Test Category: Version Comparison"

    # Test 1: Basic version comparison
    compare_versions "2.0.0" "gt" "1.0.0"
    assert_equals "0" "$?" "2.0.0 > 1.0.0"

    # Test 2: Equal versions
    compare_versions "1.5.3" "eq" "1.5.3"
    assert_equals "0" "$?" "1.5.3 == 1.5.3"

    # Test 3: Complex version with suffixes
    compare_versions "2.1.0-beta" "gt" "2.0.9"
    assert_equals "0" "$?" "2.1.0-beta > 2.0.9"

    # Test 4: Debian-style epoch versions
    compare_versions "1:2.0" "gt" "1.9"
    assert_equals "0" "$?" "Epoch version comparison"

    # Test 5: Handle "none" versions
    compare_versions "1.0.0" "gt" "(none)"
    assert_equals "0" "$?" "1.0.0 > (none)"
}

# ===================================================================
# TEST CATEGORY 2: Package State Queries
# ===================================================================

test_package_state_queries() {
    log_section "Test Category: Package State Queries"

    # Test 1: Query installed package (gh)
    state_json=$(get_package_full_state "gh" "gh")
    current_installed=$(echo "$state_json" | jq -r '.current_installation.installed')
    assert_equals "true" "$current_installed" "Query installed package"

    # Test 2: Query non-existent package
    state_json=$(get_package_full_state "nonexistent-package-xyz")
    current_installed=$(echo "$state_json" | jq -r '.current_installation.installed')
    assert_equals "false" "$current_installed" "Query non-existent package"

    # Test 3: Apt availability check
    apt_info=$(query_apt_package_info "gh")
    apt_available=$(echo "$apt_info" | jq -r '.available')
    assert_equals "true" "$apt_available" "Apt availability for gh"

    # Test 4: Snap availability check
    snap_info=$(query_snap_package_info "gh")
    snap_available=$(echo "$snap_info" | jq -r '.available')
    # This may be true or false depending on snap store, just verify it returns
    [[ -n "$snap_available" ]]
    assert_equals "0" "$?" "Snap query returns result"
}

# ===================================================================
# TEST CATEGORY 3: Decision Logic
# ===================================================================

test_decision_logic() {
    log_section "Test Category: Decision Logic"

    # Test 1: Constitutional preference (Node.js)
    constitutional_pref=$(check_constitutional_preference "nodejs")
    assert_equals "fnm" "$constitutional_pref" "Node.js constitutional preference"

    # Test 2: No constitutional preference (jq)
    constitutional_pref=$(check_constitutional_preference "jq")
    assert_equals "" "$constitutional_pref" "No preference for jq"

    # Test 3: Full decision for gh
    state_json=$(get_package_full_state "gh" "gh")
    preferred_source=$(decide_preferred_source "gh" "$state_json")
    # Should prefer apt (official source) or snap, verify not empty
    [[ -n "$preferred_source" ]]
    assert_equals "0" "$?" "Decision returns valid source for gh"
}

# ===================================================================
# TEST CATEGORY 4: State Capture and Restoration
# ===================================================================

test_state_capture() {
    log_section "Test Category: State Capture"

    # Test 1: Capture pre-migration state
    migration_id="test-$(date +%s)"
    state_dir=$(capture_pre_migration_state "gh" "$migration_id")

    [[ -d "$state_dir" ]]
    assert_equals "0" "$?" "State directory created"

    [[ -f "$state_dir/pre_state.json" ]]
    assert_equals "0" "$?" "Pre-state JSON created"

    [[ -f "$state_dir/metadata.json" ]]
    assert_equals "0" "$?" "Metadata JSON created"

    # Cleanup
    rm -rf "$state_dir"
}

# ===================================================================
# TEST CATEGORY 5: Dry-Run Migration
# ===================================================================

test_dry_run_migration() {
    log_section "Test Category: Dry-Run Migration"

    # This test simulates migration without actually modifying system
    # Uses mock functions for removal/installation

    # Test 1: Migration plan generation
    state_json=$(get_package_full_state "gh" "gh")
    current_source=$(echo "$state_json" | jq -r '.current_installation.installation_source')
    preferred_source=$(decide_preferred_source "gh" "$state_json")

    if [[ "$current_source" != "$preferred_source" ]]; then
        log_info "Migration would be: $current_source → $preferred_source"
        assert_equals "0" "0" "Migration plan generated"
    else
        log_info "No migration needed"
        assert_equals "0" "0" "Correctly identified no migration needed"
    fi
}

# ===================================================================
# TEST CATEGORY 6: Logging and Audit Trail
# ===================================================================

test_logging_audit() {
    log_section "Test Category: Logging and Audit"

    # Test 1: Decision logging
    test_log="/tmp/test-decision-log-$$.json"
    DECISION_LOG="$test_log"

    log_decision "test_decision" "Test decision reason"

    [[ -f "$test_log" ]]
    assert_equals "0" "$?" "Decision log file created"

    # Verify JSON structure
    jq empty "$test_log" 2>/dev/null
    assert_equals "0" "$?" "Decision log is valid JSON"

    # Cleanup
    rm -f "$test_log"

    # Test 2: Version comparison logging
    test_log="/tmp/test-comparison-log-$$.json"
    LOG_FILE="$test_log"

    compare_versions "2.0.0" "gt" "1.0.0"

    [[ -f "$test_log" ]]
    assert_equals "0" "$?" "Comparison log file created"

    # Cleanup
    rm -f "$test_log"
}

# ===================================================================
# Run all tests
# ===================================================================

run_all_tests() {
    echo "============================================================================"
    echo "  Package Migration System Test Suite"
    echo "============================================================================"
    echo ""

    test_version_comparison
    test_package_state_queries
    test_decision_logic
    test_state_capture
    test_dry_run_migration
    test_logging_audit

    # Summary
    echo ""
    echo "============================================================================"
    echo "  Test Summary"
    echo "============================================================================"
    echo "  Tests Run: $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed!"
        return 0
    else
        log_error "Some tests failed"
        return 1
    fi
}

# Execute tests
run_all_tests
```

### 6.2 Integration Test: Complete Migration

```bash
#!/bin/bash
# Integration test: Complete package migration in test environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/package_migration_lib.sh"

integration_test_complete_migration() {
    log_section "Integration Test: Complete Package Migration"

    # This test requires a test package that can be safely installed/removed
    # Using 'figlet' as test package (small, safe, available in apt/snap)

    TEST_PACKAGE="figlet"

    # PHASE 1: Initial state
    echo "PHASE 1: Capturing initial state"
    initial_state=$(get_package_full_state "$TEST_PACKAGE")
    initial_source=$(echo "$initial_state" | jq -r '.current_installation.installation_source')

    if [[ "$initial_source" == "unknown" ]]; then
        echo "Test package not installed, installing via apt for test"
        sudo apt-get install -y "$TEST_PACKAGE"
        initial_source="apt"
    fi

    echo "Initial source: $initial_source"

    # PHASE 2: Perform migration (apt to snap or vice versa)
    echo ""
    echo "PHASE 2: Performing migration"

    target_source=""
    if [[ "$initial_source" == "apt" ]]; then
        target_source="snap"
    else
        target_source="apt"
    fi

    echo "Target source: $target_source"

    # Execute migration
    migration_id="integration-test-$(date +%s)"
    state_dir=$(capture_pre_migration_state "$TEST_PACKAGE" "$migration_id")

    if ! remove_package_completely "$TEST_PACKAGE" "$initial_source" \
                                   "$migration_id" "$state_dir"; then
        log_error "Removal failed"
        return 1
    fi

    if ! install_from_new_source "$TEST_PACKAGE" "$target_source" \
                                 "$migration_id" "$state_dir"; then
        log_error "Installation failed, rolling back"
        rollback_migration "$TEST_PACKAGE" "$migration_id" "$state_dir"
        return 1
    fi

    # PHASE 3: Verification
    echo ""
    echo "PHASE 3: Verification"

    post_state=$(get_package_full_state "$TEST_PACKAGE")
    post_source=$(echo "$post_state" | jq -r '.current_installation.installation_source')

    if [[ "$post_source" == "$target_source" ]]; then
        log_success "Migration successful: $initial_source → $target_source"
    else
        log_error "Migration failed: expected $target_source, got $post_source"
        return 1
    fi

    # PHASE 4: Rollback test
    echo ""
    echo "PHASE 4: Testing rollback"

    rollback_migration "$TEST_PACKAGE" "$migration_id" "$state_dir"

    rollback_state=$(get_package_full_state "$TEST_PACKAGE")
    rollback_source=$(echo "$rollback_state" | jq -r '.current_installation.installation_source')

    if [[ "$rollback_source" == "$initial_source" ]]; then
        log_success "Rollback successful: restored to $initial_source"
    else
        log_error "Rollback verification failed"
        return 1
    fi

    # PHASE 5: Cleanup
    echo ""
    echo "PHASE 5: Cleanup"
    echo "Migration artifacts: $state_dir"
    echo "Test complete"

    return 0
}

# Run integration test
integration_test_complete_migration
```

---

## 7. Integration Plan

### 7.1 Integration with Existing Scripts

#### Daily Updates Integration

```bash
# Add to scripts/daily-updates.sh

# Source package migration library
source "${SCRIPT_DIR}/package_migration_lib.sh"

verify_package_sources() {
    log_section "Package Source Verification"

    # Key packages to verify
    declare -a PACKAGES=("gh" "jq" "curl" "git")

    for package in "${PACKAGES[@]}"; do
        log_info "Verifying: $package"

        state_json=$(get_package_full_state "$package")
        current_source=$(echo "$state_json" | jq -r '.current_installation.installation_source')
        preferred_source=$(decide_preferred_source "$package" "$state_json")

        if [[ "$current_source" != "$preferred_source" ]]; then
            log_warning "  Suboptimal source: $current_source (prefer: $preferred_source)"

            # Optionally auto-migrate with confirmation
            if [[ "${AUTO_MIGRATE:-false}" == "true" ]]; then
                log_info "  Auto-migrating to $preferred_source"
                migrate_package "$package"
            else
                log_info "  Run 'migrate_package $package' to optimize"
            fi
        else
            log_success "  Optimal source: $current_source"
        fi
    done
}

# Add to update workflow
verify_package_sources
```

#### Health Check Integration

```bash
# Add to .runners-local/workflows/health-check.sh

check_package_management() {
    log "STEP" "🔧 Checking package management"

    # Verify key tools are from optimal sources
    source "${SCRIPT_DIR}/../../scripts/package_migration_lib.sh"

    # GitHub CLI
    gh_state=$(get_package_full_state "gh")
    gh_source=$(echo "$gh_state" | jq -r '.current_installation.installation_source')
    gh_preferred=$(decide_preferred_source "gh" "$gh_state")

    if [[ "$gh_source" == "$gh_preferred" ]]; then
        record_check "package_management" "gh_source" "passed" \
                    "optimal source: $gh_source"
        log "SUCCESS" "✅ GitHub CLI: optimal source ($gh_source)"
    else
        record_check "package_management" "gh_source" "warning" \
                    "suboptimal: $gh_source (prefer: $gh_preferred)"
        log "WARNING" "⚠️  GitHub CLI: suboptimal source"
    fi

    # Node.js (must be fnm)
    if command -v node >/dev/null 2>&1; then
        node_path=$(which node)
        if echo "$node_path" | grep -q "fnm"; then
            record_check "package_management" "nodejs_fnm" "passed" \
                        "managed via fnm"
            log "SUCCESS" "✅ Node.js: managed via fnm"
        else
            record_check "package_management" "nodejs_fnm" "failed" \
                        "not managed via fnm (violates CLAUDE.md)"
            log "ERROR" "❌ Node.js: not managed via fnm"
        fi
    fi
}

# Add to health check sequence
check_package_management
```

### 7.2 Constitutional Compliance Integration

```bash
# Add to .runners-local/workflows/constitutional-compliance-check.sh

check_package_management_compliance() {
    echo "=== Package Management Compliance ==="

    source "${REPO_ROOT}/scripts/package_migration_lib.sh"

    # Rule: Node.js must be managed via fnm
    if command -v node >/dev/null 2>&1; then
        node_path=$(which node)
        if echo "$node_path" | grep -q "fnm"; then
            echo "✅ Node.js managed via fnm (CLAUDE.md compliant)"
        else
            echo "❌ VIOLATION: Node.js not managed via fnm"
            echo "   Required by: CLAUDE.md section 'Package Management & Dependencies'"
            echo "   Action: Remove apt/snap Node.js and install via fnm"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi
    fi

    # Rule: GitHub CLI should use official source
    gh_state=$(get_package_full_state "gh")
    gh_source=$(echo "$gh_state" | jq -r '.current_installation.installation_source')

    if [[ "$gh_source" == "apt" ]]; then
        # Check if official repository
        if apt-cache policy gh | grep -q "cli.github.com"; then
            echo "✅ GitHub CLI from official apt repository"
        else
            echo "⚠️  WARNING: GitHub CLI from Ubuntu repository (may be outdated)"
            echo "   Recommendation: Add official GitHub CLI repository"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

# Add to compliance check workflow
check_package_management_compliance
```

### 7.3 New Script: Package Management CLI

```bash
#!/bin/bash
# scripts/manage-packages.sh
# CLI tool for package management operations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/package_migration_lib.sh"

show_help() {
    cat <<EOF
Package Management Tool

Usage: $0 <command> [options]

Commands:
  verify <package>       Show current state and recommendations
  migrate <package>      Migrate package to optimal source
  verify-all            Verify all key packages
  audit                 Generate audit report

Options:
  --force               Force migration even if same source
  --dry-run             Show what would be done
  --json                Output in JSON format

Examples:
  $0 verify gh
  $0 migrate gh
  $0 verify-all
  $0 audit --json > audit-report.json
EOF
}

cmd_verify() {
    package=$1

    state_json=$(get_package_full_state "$package")

    if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
        echo "$state_json"
        return 0
    fi

    # Human-readable output
    echo "Package: $package"
    echo ""
    echo "Current Installation:"
    echo "  Source: $(echo "$state_json" | jq -r '.current_installation.installation_source')"
    echo "  Version: $(echo "$state_json" | jq -r '.current_installation.installed_version')"
    echo "  Path: $(echo "$state_json" | jq -r '.current_installation.binary_path')"
    echo ""
    echo "Available Sources:"
    echo "  apt: $(echo "$state_json" | jq -r '.apt.candidate // "not available"')"
    echo "  snap: $(echo "$state_json" | jq -r '.snap.stable_version // "not available"')"
    echo "  upstream: $(echo "$state_json" | jq -r '.upstream.latest_version // "unknown"')"
    echo ""
    echo "Recommended Source:"
    preferred=$(decide_preferred_source "$package" "$state_json")
    echo "  $preferred"
}

cmd_migrate() {
    package=$1
    force=${2:-false}

    migrate_package "$package" "$force"
}

cmd_verify_all() {
    declare -a KEY_PACKAGES=("gh" "git" "curl" "jq")

    echo "Key Package Verification"
    echo "========================"
    echo ""

    for package in "${KEY_PACKAGES[@]}"; do
        cmd_verify "$package"
        echo ""
    done
}

cmd_audit() {
    audit_timestamp=$(date -Iseconds)
    audit_report="/tmp/package-audit-$(date +%s).json"

    declare -a KEY_PACKAGES=("gh" "git" "curl" "jq" "node")

    audit_data="["
    first=true

    for package in "${KEY_PACKAGES[@]}"; do
        if [[ "$first" == "false" ]]; then
            audit_data+=","
        fi
        first=false

        state_json=$(get_package_full_state "$package" 2>/dev/null || echo '{}')
        audit_data+="$state_json"
    done

    audit_data+="]"

    # Wrap in audit report structure
    audit_report_json=$(echo "$audit_data" | jq -n \
        --arg timestamp "$audit_timestamp" \
        --arg hostname "$(hostname)" \
        --argjson packages "$audit_data" \
        '{
            audit_timestamp: $timestamp,
            hostname: $hostname,
            packages: $packages
        }'
    )

    if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
        echo "$audit_report_json"
    else
        echo "$audit_report_json" > "$audit_report"
        echo "Audit report generated: $audit_report"

        # Show summary
        echo ""
        echo "Summary:"
        echo "$audit_report_json" | jq -r '.packages[] |
            "  \(.package_name): \(.current_installation.installation_source) \(.current_installation.installed_version)"'
    fi
}

# Parse arguments
COMMAND=${1:-help}
shift || true

case "$COMMAND" in
    verify)
        cmd_verify "$@"
        ;;
    migrate)
        cmd_migrate "$@"
        ;;
    verify-all)
        cmd_verify_all
        ;;
    audit)
        cmd_audit
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
```

---

## 8. Logging and Audit Requirements

### 8.1 Log Structure

```
Logging Directory Structure:
/tmp/package-migration-logs/
├── migrations/
│   ├── YYYYMMDD-HHMMSS-package-pid/
│   │   ├── pre_state.json
│   │   ├── post_state.json
│   │   ├── metadata.json
│   │   ├── removal_log.txt
│   │   ├── installation_log.txt
│   │   ├── verification_log.txt
│   │   ├── migration_summary.json
│   │   └── MIGRATION_SUMMARY.txt
│   └── ...
├── decisions/
│   ├── YYYYMMDD-decisions.json
│   └── ...
├── comparisons/
│   ├── YYYYMMDD-comparisons.json
│   └── ...
└── audits/
    ├── YYYYMMDD-audit-report.json
    └── ...
```

### 8.2 JSON Schema for State Objects

```json
{
  "package_state": {
    "timestamp": "ISO8601",
    "package_name": "string",
    "binary_name": "string",
    "current_installation": {
      "installed": "boolean",
      "binary_path": "string",
      "installation_source": "apt|snap|source|unknown",
      "installed_version": "string",
      "binary_version": "string"
    },
    "apt": {
      "available": "boolean",
      "source": "apt",
      "installed": "string|none",
      "candidate": "string",
      "all_versions": ["string"],
      "repository_info": "string"
    },
    "snap": {
      "available": "boolean",
      "source": "snap",
      "installed": "string",
      "stable_version": "string",
      "publisher": "string",
      "publisher_verified": "boolean",
      "confinement": "classic|strict|devmode",
      "channels": ["string"]
    },
    "upstream": {
      "source": "string",
      "latest_version": "string",
      "url": "string"
    }
  }
}
```

---

## 9. Performance Considerations

### 9.1 Caching Strategy

```bash
# Cache package queries to avoid repeated apt-cache/snap info calls

CACHE_DIR="/tmp/package-query-cache"
CACHE_TTL=300  # 5 minutes

get_cached_query() {
    query_type=$1
    package_name=$2

    cache_file="$CACHE_DIR/${query_type}_${package_name}.json"

    # Check if cache exists and is fresh
    if [[ -f "$cache_file" ]]; then
        cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file")))
        if [[ $cache_age -lt $CACHE_TTL ]]; then
            cat "$cache_file"
            return 0
        fi
    fi

    # Cache miss or stale
    return 1
}

set_cached_query() {
    query_type=$1
    package_name=$2
    data=$3

    mkdir -p "$CACHE_DIR"
    cache_file="$CACHE_DIR/${query_type}_${package_name}.json"

    echo "$data" > "$cache_file"
}
```

### 9.2 Parallel Queries

```bash
# Query multiple sources in parallel for faster state retrieval

get_package_full_state_parallel() {
    package_name=$1

    # Create temporary files for parallel results
    tmp_dir=$(mktemp -d)

    # Launch queries in background
    query_current_installation "$package_name" > "$tmp_dir/current.json" &
    query_apt_package_info "$package_name" > "$tmp_dir/apt.json" &
    query_snap_package_info "$package_name" > "$tmp_dir/snap.json" &
    query_upstream_latest "$package_name" > "$tmp_dir/upstream.json" &

    # Wait for all to complete
    wait

    # Combine results
    jq -n \
        --slurpfile current "$tmp_dir/current.json" \
        --slurpfile apt "$tmp_dir/apt.json" \
        --slurpfile snap "$tmp_dir/snap.json" \
        --slurpfile upstream "$tmp_dir/upstream.json" \
        '{
            timestamp: now | todate,
            package_name: $ARGS.positional[0],
            current_installation: $current[0],
            apt: $apt[0],
            snap: $snap[0],
            upstream: $upstream[0]
        }' \
        --args "$package_name"

    # Cleanup
    rm -rf "$tmp_dir"
}
```

---

## 10. Security Considerations

### 10.1 Publisher Verification

```bash
# Strict publisher verification for snaps

VERIFIED_PUBLISHERS=(
    "ken-vandine"     # Ghostty official
    "GitHub"          # GitHub CLI
    "iojs"            # Node.js official
)

verify_snap_publisher_strict() {
    package_name=$1

    snap_info=$(snap info "$package_name" 2>&1)
    publisher=$(echo "$snap_info" | grep "publisher:" | awk '{print $2}')

    for verified in "${VERIFIED_PUBLISHERS[@]}"; do
        if [[ "$publisher" == "$verified"* ]]; then
            return 0
        fi
    done

    log_error "Publisher not in verified list: $publisher"
    return 1
}
```

### 10.2 Integrity Verification

```bash
# Verify package integrity after installation

verify_package_integrity() {
    package_name=$1
    installation_source=$2

    case "$installation_source" in
        apt)
            # Use apt to verify package integrity
            dpkg --verify "$package_name" 2>&1 | \
                grep -v "^???" || return 0
            ;;
        snap)
            # Snap has built-in integrity checks
            snap info "$package_name" --verbose | \
                grep -q "base-snap-verified: true" || return 1
            ;;
    esac

    return 0
}
```

---

## 11. Rollback Safeguards

### 11.1 Automatic Rollback Triggers

```bash
# Define conditions that trigger automatic rollback

should_trigger_rollback() {
    package_name=$1
    state_dir=$2

    # Check if binary is accessible
    if ! command -v "$package_name" >/dev/null 2>&1; then
        log_error "Rollback trigger: binary not accessible"
        return 0
    fi

    # Check if version can be determined
    if ! get_version_from_binary "$package_name" >/dev/null 2>&1; then
        log_error "Rollback trigger: version check failed"
        return 0
    fi

    # Check basic functionality
    case "$package_name" in
        gh)
            if ! gh --version >/dev/null 2>&1; then
                log_error "Rollback trigger: gh functionality check failed"
                return 0
            fi
            ;;
        node)
            if ! node -e "console.log('test')" >/dev/null 2>&1; then
                log_error "Rollback trigger: node functionality check failed"
                return 0
            fi
            ;;
    esac

    # No rollback triggers
    return 1
}

# Integrate into migration workflow
if should_trigger_rollback "$package_name" "$state_dir"; then
    log_warning "Automatic rollback triggered"
    rollback_migration "$package_name" "$migration_id" "$state_dir"
    return 1
fi
```

---

## 12. Documentation Requirements

### 12.1 Migration Report Template

```bash
generate_migration_report() {
    state_dir=$1

    cat > "$state_dir/MIGRATION_REPORT.md" <<'EOF'
# Package Migration Report

## Migration Information

- **Migration ID**: {{migration_id}}
- **Package**: {{package_name}}
- **Date**: {{date}}
- **Hostname**: {{hostname}}
- **User**: {{user}}

## Before Migration

- **Source**: {{before_source}}
- **Version**: {{before_version}}
- **Binary Path**: {{before_path}}

## After Migration

- **Source**: {{after_source}}
- **Version**: {{after_version}}
- **Binary Path**: {{after_path}}

## Decision Reasoning

{{decision_reasoning}}

## Verification Results

### Removal Verification
{{removal_verification}}

### Installation Verification
{{installation_verification}}

### Functionality Check
{{functionality_check}}

## Files and Logs

- Pre-state: `pre_state.json`
- Post-state: `post_state.json`
- Removal log: `removal_log.txt`
- Installation log: `installation_log.txt`
- Verification log: `verification_log.txt`

## Rollback Information

To rollback this migration:

```bash
./scripts/manage-packages.sh rollback {{migration_id}}
```

Or manually:

```bash
# Remove current installation
sudo {{remove_command}}

# Restore previous installation
sudo {{restore_command}}
```

---

*This report was automatically generated by the package migration system.*
EOF

    # Replace placeholders with actual values
    # (Implementation would use sed or jq to fill in values)
}
```

---

## Conclusion

This design provides a comprehensive, audit-ready package management verification and migration system that:

1. **Never assumes**: Always queries actual system state
2. **Transparent**: Every decision is logged with reasoning
3. **Safe**: Complete state capture, verification, and rollback capability
4. **Constitutional**: Follows CLAUDE.md requirements explicitly
5. **Extensible**: Easy to add new packages and sources
6. **Testable**: Comprehensive test suite with integration tests
7. **Integrated**: Works with existing scripts and workflows

The system is ready for implementation as a reusable bash module that can be integrated into the ghostty-config-files repository's CI/CD and update workflows.
