#!/usr/bin/env bash
# lib/audit/scanners.sh - Application scanning functions for audit system

set -euo pipefail

[ -z "${AUDIT_SCANNERS_SH_LOADED:-}" ] || return 0
AUDIT_SCANNERS_SH_LOADED=1

# Scan installed APT packages -> JSON array
scan_apt_packages() {
    log "INFO" "Scanning APT packages..."
    local tmp_data="/tmp/apt-scan-$$.tsv"
    
    dpkg -query -W -f='${Package}\t${Version}\t${Installed-Size}\n' 2>/dev/null | \
        awk -F'\t' 'BEGIN {OFS="\t"} {
            size_kb = $3;
            if (size_kb == "") size_kb = 0;
            size_mb = int(size_kb / 1024);
            print $1, $2, size_mb "MB"
        }' > "$tmp_data"
    
    local count=$(wc -l < "$tmp_data")
    log "INFO" "  Found $count APT packages"
    
    local packages_json="[]"
    if [ "$count" -gt 0 ]; then
        packages_json=$(awk -F'\t' 'BEGIN {OFS="\t"} {print $1, $2, $3}' "$tmp_data" | \
            jq -R -s 'split("\n")[:-1] | map(split("\t") | {name: .[0], version: .[1], size: .[2], method: "apt"})')
    fi
    
    rm -f "$tmp_data"
    echo "$packages_json"
}

# Scan installed Snap packages -> JSON array
scan_snap_packages() {
    log "INFO" "Scanning Snap packages..."
    local packages_json="[]"
    
    if ! command -v snap &> /dev/null; then
        log "INFO" "  Snapd not installed, skipping snap scan"
        echo "$packages_json"
        return 0
    fi
    
    local tmp_data="/tmp/snap-scan-$$.tsv"
    snap list --all 2>/dev/null | awk '
        NR==1 {next}
        {
            name = $1; version = $2; rev = $3; notes = $NF
            disabled = (notes ~ /disabled/) ? "true" : "false"
            size = "unknown"
            cmd = "du -sh /snap/" name "/" rev " 2>/dev/null | awk '\''{print $1}'\''"
            cmd | getline size
            close(cmd)
            if (size == "") size = "unknown"
            printf "%s\t%s\t%s\t%s\n", name, version, size, disabled
        }
    ' > "$tmp_data"
    
    local count=$(wc -l < "$tmp_data" 2>/dev/null || echo "0")
    local disabled_count=$(awk -F'\t' '$4 == "true"' "$tmp_data" | wc -l 2>/dev/null || echo "0")
    log "INFO" "  Found $count Snap packages ($disabled_count disabled)"
    
    if [ "$count" -gt 0 ]; then
        packages_json=$(awk -F'\t' 'BEGIN {OFS="\t"} {print $1, $2, $3, $4}' "$tmp_data" | \
            jq -R -s 'split("\n")[:-1] | map(split("\t") | {name: .[0], version: .[1], size: .[2], method: "snap", disabled: (.[3] == "true")})')
    fi
    
    rm -f "$tmp_data"
    echo "$packages_json"
}

# Scan desktop files for GUI applications -> JSON array
scan_desktop_files() {
    log "INFO" "Scanning desktop files..."
    local tmp_data="/tmp/desktop-scan-$$.tsv"
    local desktop_dirs=(
        "/usr/share/applications"
        "/usr/local/share/applications"
        "$HOME/.local/share/applications"
        "/var/lib/snapd/desktop/applications"
    )
    
    for dir in "${desktop_dirs[@]}"; do
        [ ! -d "$dir" ] && continue
        find "$dir" -maxdepth 1 -name "*.desktop" -type f 2>/dev/null | while read -r desktop_file; do
            awk -F= '
                /^Name=/ && !name {name = $2}
                /^Exec=/ && !exec {exec = $2}
                /^Icon=/ && !icon {icon = $2}
                END {
                    if (name != "") printf "%s\t%s\t%s\t%s\n", name, exec, icon, FILENAME
                }
            ' FILENAME="$(basename "$desktop_file")" "$desktop_file"
        done
    done > "$tmp_data"
    
    local count=$(wc -l < "$tmp_data" 2>/dev/null || echo "0")
    log "INFO" "  Found $count desktop applications"
    
    local apps_json="[]"
    if [ "$count" -gt 0 ]; then
        apps_json=$(awk -F'\t' 'BEGIN {OFS="\t"} {print $1, $2, $3, $4}' "$tmp_data" | \
            jq -R -s 'split("\n")[:-1] | map(split("\t") | {name: .[0], exec: .[1], icon: .[2], desktop_file: .[3]})')
    fi
    
    rm -f "$tmp_data"
    echo "$apps_json"
}

export -f scan_apt_packages
export -f scan_snap_packages
export -f scan_desktop_files
