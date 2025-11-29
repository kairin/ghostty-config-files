#!/usr/bin/env bash
# lib/audit/app-report.sh - Application audit report generation
# Extracted from lib/tasks/app_audit.sh for modularity compliance (300 line limit)
# Generates markdown audit reports for duplicate apps, disabled snaps, browsers

set -euo pipefail

[ -z "${APP_REPORT_SH_LOADED:-}" ] || return 0
APP_REPORT_SH_LOADED=1

# Audit configuration (can be overridden before sourcing)
readonly APP_AUDIT_REPORT="${AUDIT_REPORT:-/tmp/ubuntu-apps-audit.md}"

#
# Generate audit report
#
# Arguments:
#   $1 - Duplicates JSON
#   $2 - Disabled snaps JSON
#   $3 - Browsers JSON
#   $4 - APT packages JSON
#   $5 - Snap packages JSON
#
# Generates:
#   Markdown report at $APP_AUDIT_REPORT
#
generate_audit_report() {
    local duplicates_json="$1"
    local disabled_json="$2"
    local browsers_json="$3"
    local apt_json="$4"
    local snap_json="$5"

    log "INFO" "Generating audit report..."

    local duplicates_count disabled_count browsers_count apt_count snap_count
    duplicates_count=$(echo "$duplicates_json" | jq 'length' 2>/dev/null || echo "0")
    disabled_count=$(echo "$disabled_json" | jq 'length' 2>/dev/null || echo "0")
    browsers_count=$(echo "$browsers_json" | jq 'length' 2>/dev/null || echo "0")
    apt_count=$(echo "$apt_json" | jq 'length' 2>/dev/null || echo "0")
    snap_count=$(echo "$snap_json" | jq 'length' 2>/dev/null || echo "0")

    # Calculate total disk usage for disabled snaps
    local disabled_total_mb=0
    for ((i=0; i<disabled_count; i++)); do
        local size
        size=$(echo "$disabled_json" | jq -r ".[$i].size")
        if [[ "$size" =~ ^([0-9]+(\.[0-9]+)?)([MG])$ ]]; then
            local num="${BASH_REMATCH[1]}"
            local unit="${BASH_REMATCH[3]}"
            if [ "$unit" = "G" ]; then
                disabled_total_mb=$(echo "$disabled_total_mb + $num * 1024" | bc 2>/dev/null || echo "$disabled_total_mb")
            else
                disabled_total_mb=$(echo "$disabled_total_mb + $num" | bc 2>/dev/null || echo "$disabled_total_mb")
            fi
        fi
    done

    # Generate report header
    _generate_report_header "$apt_count" "$snap_count" "$duplicates_count" "$disabled_count" "$browsers_count"

    # Generate duplicates section
    _generate_duplicates_section "$duplicates_json" "$duplicates_count"

    # Generate disabled snaps section
    _generate_disabled_section "$disabled_json" "$disabled_count" "$disabled_total_mb"

    # Generate browsers section
    _generate_browsers_section "$browsers_json" "$browsers_count"

    # Generate footer
    _generate_report_footer "$disabled_total_mb"

    log "SUCCESS" "Audit report generated: $APP_AUDIT_REPORT"
}

# Internal: Generate report header
_generate_report_header() {
    local apt_count="$1" snap_count="$2" duplicates_count="$3" disabled_count="$4" browsers_count="$5"
    local timestamp
    timestamp=$(date +"%Y%m%d-%H%M%S")

    cat > "$APP_AUDIT_REPORT" <<EOF
# Ubuntu Application Audit Report

**Generated**: $(date "+%Y-%m-%d %H:%M:%S")
**Audit ID**: $timestamp

---

## Summary

| Category | Count | Status |
|----------|-------|--------|
| Total APT Packages | $apt_count | Info |
| Total Snap Packages | $snap_count | Info |
| **Duplicate Applications** | **$duplicates_count** | $([ "${duplicates_count:-0}" -gt 0 ] && echo "Action Recommended" || echo "OK") |
| **Disabled Snaps** | **$disabled_count** | $([ "${disabled_count:-0}" -gt 0 ] && echo "Action Recommended" || echo "OK") |
| **Browsers Installed** | **$browsers_count** | $([ "${browsers_count:-0}" -gt 3 ] && echo "Consider Cleanup" || echo "OK") |

---

## 1. Duplicate Applications (Priority: HIGH)

**Issue**: Same application installed via both Snap and APT package managers.

**Impact**: Wastes disk space, may cause conflicts, confusing duplicate icons in app menu.

**Recommendation**: Keep one installation method (prefer APT for system integration or Snap for auto-updates).

EOF
}

# Internal: Generate duplicates section
_generate_duplicates_section() {
    local duplicates_json="$1" duplicates_count="$2"

    if [ "${duplicates_count:-0}" -eq 0 ]; then
        echo "**No duplicates detected** - System is clean!" >> "$APP_AUDIT_REPORT"
    else
        echo "| Application | Snap Version | Snap Size | APT Version | APT Size | Recommendation |" >> "$APP_AUDIT_REPORT"
        echo "|-------------|--------------|-----------|-------------|----------|----------------|" >> "$APP_AUDIT_REPORT"

        for ((i=0; i<duplicates_count; i++)); do
            local app snap_ver snap_size apt_ver apt_size
            app=$(echo "$duplicates_json" | jq -r ".[$i].app_name")
            snap_ver=$(echo "$duplicates_json" | jq -r ".[$i].snap.version")
            snap_size=$(echo "$duplicates_json" | jq -r ".[$i].snap.size")
            apt_ver=$(echo "$duplicates_json" | jq -r ".[$i].apt.version")
            apt_size=$(echo "$duplicates_json" | jq -r ".[$i].apt.size")
            echo "| **$app** | $snap_ver | $snap_size | $apt_ver | $apt_size | Remove Snap or APT version |" >> "$APP_AUDIT_REPORT"
        done

        cat >> "$APP_AUDIT_REPORT" <<'EOF'

**Cleanup Commands**:
```bash
# To remove Snap versions (keeps APT):
EOF
        for ((i=0; i<duplicates_count; i++)); do
            local app
            app=$(echo "$duplicates_json" | jq -r ".[$i].app_name")
            echo "sudo snap remove $app" >> "$APP_AUDIT_REPORT"
        done

        echo "" >> "$APP_AUDIT_REPORT"
        echo "# To remove APT versions (keeps Snap):" >> "$APP_AUDIT_REPORT"
        for ((i=0; i<duplicates_count; i++)); do
            local apt_name
            apt_name=$(echo "$duplicates_json" | jq -r ".[$i].apt.name")
            echo "sudo apt remove $apt_name" >> "$APP_AUDIT_REPORT"
        done
        echo '```' >> "$APP_AUDIT_REPORT"
    fi
}

# Internal: Generate disabled snaps section
_generate_disabled_section() {
    local disabled_json="$1" disabled_count="$2" disabled_total_mb="$3"

    cat >> "$APP_AUDIT_REPORT" <<EOF

---

## 2. Disabled Snap Packages (Priority: MEDIUM)

**Issue**: Old snap package versions that are disabled but still consuming disk space.

**Impact**: Wastes ${disabled_total_mb}MB of disk space with no benefit.

**Recommendation**: Remove disabled snap packages to reclaim disk space.

EOF

    if [ "${disabled_count:-0}" -eq 0 ]; then
        echo "**No disabled snaps** - System is clean!" >> "$APP_AUDIT_REPORT"
    else
        echo "| Package | Version | Disk Usage |" >> "$APP_AUDIT_REPORT"
        echo "|---------|---------|------------|" >> "$APP_AUDIT_REPORT"

        for ((i=0; i<disabled_count; i++)); do
            local name version size
            name=$(echo "$disabled_json" | jq -r ".[$i].name")
            version=$(echo "$disabled_json" | jq -r ".[$i].version")
            size=$(echo "$disabled_json" | jq -r ".[$i].size")
            echo "| $name | $version | $size |" >> "$APP_AUDIT_REPORT"
        done

        cat >> "$APP_AUDIT_REPORT" <<EOF

**Total Reclaimable**: ${disabled_total_mb}MB

**Cleanup Commands**:
\`\`\`bash
# Remove all disabled snaps:
snap list --all | awk '/disabled/{print \$1, \$3}' | \\
  while read snapname revision; do \\
    sudo snap remove "\$snapname" --revision="\$revision"; \\
  done
\`\`\`
EOF
    fi
}

# Internal: Generate browsers section
_generate_browsers_section() {
    local browsers_json="$1" browsers_count="$2"

    cat >> "$APP_AUDIT_REPORT" <<EOF

---

## 3. Browser Installation Analysis (Priority: LOW)

**Issue**: Multiple web browsers installed.

**Impact**: Disk space usage, potential confusion for default browser.

**Recommendation**: Keep 1-2 browsers maximum (primary + backup).

EOF

    if [ "${browsers_count:-0}" -eq 0 ]; then
        echo "**No browsers detected** via package managers." >> "$APP_AUDIT_REPORT"
    else
        echo "| Browser | Version | Method | Size |" >> "$APP_AUDIT_REPORT"
        echo "|---------|---------|--------|------|" >> "$APP_AUDIT_REPORT"

        for ((i=0; i<browsers_count; i++)); do
            local name version method size
            name=$(echo "$browsers_json" | jq -r ".[$i].name")
            version=$(echo "$browsers_json" | jq -r ".[$i].version")
            method=$(echo "$browsers_json" | jq -r ".[$i].method")
            size=$(echo "$browsers_json" | jq -r ".[$i].size")
            echo "| $name | $version | $method | $size |" >> "$APP_AUDIT_REPORT"
        done

        if [ "${browsers_count:-0}" -gt 3 ]; then
            echo "" >> "$APP_AUDIT_REPORT"
            echo "**Recommendation**: Consider keeping only 1-2 browsers." >> "$APP_AUDIT_REPORT"
        else
            echo "" >> "$APP_AUDIT_REPORT"
            echo "**Browser count is reasonable** ($browsers_count browsers)." >> "$APP_AUDIT_REPORT"
        fi
    fi
}

# Internal: Generate report footer
_generate_report_footer() {
    local disabled_total_mb="$1"

    cat >> "$APP_AUDIT_REPORT" <<EOF

---

## Next Steps

1. **Review duplicates** and decide which installation method to keep
2. **Remove disabled snaps** to reclaim ${disabled_total_mb}MB disk space
3. **Optional**: Reduce browser count if >3 installed
4. **Backup**: Create system backup before removing packages
5. **Run cleanup**: Use commands above or interactive cleanup tool

---

**Report Location**: \`$APP_AUDIT_REPORT\`

EOF
}

export -f generate_audit_report
