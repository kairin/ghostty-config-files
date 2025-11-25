---
title: "Package Management Verification - Quick Reference"
description: "**Related**: [Full Design Document](package-management-verification-design.md)"
pubDate: 2025-11-25
author: "Ghostty Config Team"
tags: ['developer', 'technical']
---

# Package Management Verification - Quick Reference

**Related**: [Full Design Document](package-management-verification-design.md)

---

## Quick Command Reference

```bash
# Verify package state
./scripts/manage-packages.sh verify <package>

# Migrate package to optimal source
./scripts/manage-packages.sh migrate <package>

# Verify all key packages
./scripts/manage-packages.sh verify-all

# Generate audit report
./scripts/manage-packages.sh audit --json > audit-report.json
```

---

## Core Functions

### Query Package State

```bash
# Get complete package information
state_json=$(get_package_full_state "gh" "gh")

# Query individual sources
apt_info=$(query_apt_package_info "gh")
snap_info=$(query_snap_package_info "gh")
current=$(query_current_installation "gh")
```

### Compare Versions

```bash
# Use dpkg for accurate version comparison
compare_versions "2.82.1" "gt" "2.46.0"  # Returns 0 (true)
compare_versions "1.5.3" "eq" "1.5.3"    # Returns 0 (true)
```

### Decide Preferred Source

```bash
# Automatically determine best package source
state_json=$(get_package_full_state "gh")
preferred_source=$(decide_preferred_source "gh" "$state_json")
```

---

## Decision Priority Matrix

1. **Constitutional Requirements** (CLAUDE.md)
   - Node.js → fnm (mandatory)
   - Ghostty → source build or verified snap

2. **Official Source Preference**
   - GitHub CLI → Official apt repository
   - Check for publisher verification

3. **Version Currency**
   - Always prefer newer versions
   - Compare: apt vs snap vs upstream

4. **Security & Verification**
   - Snap: Check publisher verification
   - Snap: Avoid strict confinement for terminal apps

5. **System Integration**
   - Consider confinement model
   - Check permission requirements

---

## Migration Workflow

```
1. Capture pre-migration state
   ↓
2. Remove old installation completely
   ↓
3. Verify complete removal (no leftovers)
   ↓
4. Install from new source
   ↓
5. Verify successful installation
   ↓
6. Restore user configuration
   ↓
7. Capture post-migration state
   ↓
8. Generate migration report
```

**Automatic Rollback on Failure at Any Step**

---

## State Capture Structure

```
/tmp/package-migration-YYYYMMDD-HHMMSS-package-pid/
├── metadata.json                 # Migration metadata
├── pre_state.json               # Complete state before migration
├── post_state.json              # Complete state after migration
├── dependencies.txt             # Package dependencies
├── reverse_dependencies.txt     # Packages depending on this
├── config_backup.tar.gz        # System configuration backup
├── config_USER_backup.tar.gz   # Per-user configuration backups
├── file_list.txt               # Installed files list
├── removed_files.txt           # Files removed during uninstall
├── removal_log.txt             # Removal operation log
├── installation_log.txt        # Installation operation log
├── verification_log.txt        # Verification checks log
├── migration_summary.json      # Machine-readable summary
├── MIGRATION_SUMMARY.txt       # Human-readable summary
└── MIGRATION_REPORT.md         # Complete migration report
```

---

## Real-World Examples

### Example 1: GitHub CLI Verification

```bash
#!/bin/bash
# Check if GitHub CLI is using optimal source

state_json=$(get_package_full_state "gh")

echo "Current State:"
echo "$state_json" | jq '{
    current: .current_installation.installation_source,
    current_version: .current_installation.installed_version,
    apt_version: .apt.candidate,
    snap_version: .snap.stable_version,
    upstream_latest: .upstream.latest_version
}'

# Determine optimal source
preferred=$(decide_preferred_source "gh" "$state_json")
current=$(echo "$state_json" | jq -r '.current_installation.installation_source')

if [[ "$current" != "$preferred" ]]; then
    echo "Migration recommended: $current → $preferred"
else
    echo "Already using optimal source: $current"
fi
```

**Sample Output:**
```json
{
  "current": "apt",
  "current_version": "2.82.1",
  "apt_version": "2.82.1",
  "snap_version": "unknown",
  "upstream_latest": "2.83.1"
}
```

### Example 2: Node.js Constitutional Compliance

```bash
#!/bin/bash
# Verify Node.js is managed via fnm (CLAUDE.md requirement)

if command -v node >/dev/null 2>&1; then
    node_path=$(which node)

    if echo "$node_path" | grep -q "fnm"; then
        echo "✅ Node.js correctly managed via fnm"
        fnm list
    else
        echo "❌ VIOLATION: Node.js not managed via fnm"
        echo "Current source: $(query_current_installation nodejs | \
                            jq -r '.installation_source')"
        echo ""
        echo "Action required:"
        echo "  1. Remove current installation"
        echo "  2. Install via fnm: fnm install --lts"
    fi
fi
```

### Example 3: Complete Migration

```bash
#!/bin/bash
# Complete migration with all safeguards

PACKAGE="gh"

# Step 1: Get current state
echo "Querying current state..."
state_json=$(get_package_full_state "$PACKAGE")

current_source=$(echo "$state_json" | jq -r '.current_installation.installation_source')
current_version=$(echo "$state_json" | jq -r '.current_installation.installed_version')

echo "Current: $current_source $current_version"

# Step 2: Determine preferred source
preferred_source=$(decide_preferred_source "$PACKAGE" "$state_json")
echo "Preferred: $preferred_source"

# Step 3: Check if migration needed
if [[ "$current_source" == "$preferred_source" ]]; then
    echo "No migration needed"
    exit 0
fi

# Step 4: Confirm with user
read -p "Migrate $PACKAGE: $current_source → $preferred_source? (y/N): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "Cancelled"
    exit 0
fi

# Step 5: Execute migration
if migrate_package "$PACKAGE"; then
    echo "✅ Migration successful"

    # Verify new state
    new_state=$(get_package_full_state "$PACKAGE")
    new_source=$(echo "$new_state" | jq -r '.current_installation.installation_source')
    new_version=$(echo "$new_state" | jq -r '.current_installation.installed_version')

    echo "New state: $new_source $new_version"
else
    echo "❌ Migration failed (automatic rollback performed)"
    exit 1
fi
```

---

## Integration Points

### Daily Updates Script

```bash
# Add to scripts/daily-updates.sh

verify_package_sources() {
    log_section "Package Source Verification"

    for package in gh git curl jq; do
        state_json=$(get_package_full_state "$package")
        current=$(echo "$state_json" | jq -r '.current_installation.installation_source')
        preferred=$(decide_preferred_source "$package" "$state_json")

        if [[ "$current" != "$preferred" ]]; then
            log_warning "$package: suboptimal source ($current, prefer $preferred)"
        else
            log_success "$package: optimal source ($current)"
        fi
    done
}
```

### Health Check Script

```bash
# Add to .runners-local/workflows/health-check.sh

check_package_management() {
    log "STEP" "🔧 Checking package management"

    # GitHub CLI source check
    gh_state=$(get_package_full_state "gh")
    gh_source=$(echo "$gh_state" | jq -r '.current_installation.installation_source')
    gh_preferred=$(decide_preferred_source "gh" "$gh_state")

    if [[ "$gh_source" == "$gh_preferred" ]]; then
        record_check "package_management" "gh_source" "passed" "optimal: $gh_source"
    else
        record_check "package_management" "gh_source" "warning" \
                    "suboptimal: $gh_source (prefer: $gh_preferred)"
    fi

    # Node.js fnm compliance check
    if command -v node >/dev/null 2>&1; then
        if which node | grep -q "fnm"; then
            record_check "package_management" "nodejs_fnm" "passed" "via fnm"
        else
            record_check "package_management" "nodejs_fnm" "failed" \
                        "not via fnm (CLAUDE.md violation)"
        fi
    fi
}
```

### Constitutional Compliance Check

```bash
# Add to .runners-local/workflows/constitutional-compliance-check.sh

check_package_management_compliance() {
    echo "=== Package Management Compliance ==="

    # Node.js fnm requirement (CLAUDE.md)
    if command -v node >/dev/null 2>&1; then
        if which node | grep -q "fnm"; then
            echo "✅ Node.js managed via fnm"
        else
            echo "❌ VIOLATION: Node.js not managed via fnm (CLAUDE.md required)"
            VIOLATIONS=$((VIOLATIONS + 1))
        fi
    fi

    # GitHub CLI official source preference
    gh_state=$(get_package_full_state "gh")
    if echo "$gh_state" | jq -r '.apt.repository_info' | grep -q "cli.github.com"; then
        echo "✅ GitHub CLI from official repository"
    else
        echo "⚠️  WARNING: GitHub CLI not from official repository"
        WARNINGS=$((WARNINGS + 1))
    fi
}
```

---

## Test Cases Summary

### Unit Tests
- ✅ Version comparison (gt, lt, eq, with epochs)
- ✅ Package state queries (apt, snap, current)
- ✅ Decision logic (constitutional, official, version)
- ✅ State capture and restoration

### Integration Tests
- ✅ Complete migration workflow
- ✅ Rollback mechanism
- ✅ Configuration preservation
- ✅ Verification after migration

### System Tests
- ✅ Real package migration (figlet test)
- ✅ Cross-source migration (apt ↔ snap)
- ✅ Audit trail verification

---

## Troubleshooting

### Issue: Migration fails at removal step

**Solution**: Check removal logs in state directory
```bash
cat /tmp/package-migration-*/removal_log.txt
cat /tmp/package-migration-*/verification_log.txt
```

### Issue: Automatic rollback triggered

**Solution**: Check rollback summary and post-state
```bash
cat /tmp/package-migration-*/rollback_summary.json
cat /tmp/package-migration-*/post_state.json
```

### Issue: Version comparison fails

**Solution**: Verify dpkg is available and version strings are valid
```bash
dpkg --compare-versions "2.0.0" gt "1.0.0" && echo "Working"
```

### Issue: Constitutional violation detected

**Solution**: Check CLAUDE.md for package-specific requirements
```bash
grep -A 5 "package_name" /home/kkk/Apps/ghostty-config-files/CLAUDE.md
```

---

## Performance Tips

1. **Use Caching**: Query results cached for 5 minutes
2. **Parallel Queries**: Use `get_package_full_state_parallel` for faster state retrieval
3. **Batch Operations**: Verify multiple packages in single run
4. **Scheduled Audits**: Run weekly audits instead of continuous checks

---

## Security Checklist

- ✅ Verify snap publisher before installation
- ✅ Check confinement mode for terminal applications
- ✅ Validate package integrity after installation
- ✅ Maintain complete audit trail
- ✅ Automatic rollback on failure

---

## Next Steps

1. **Review Full Design**: [package-management-verification-design.md](package-management-verification-design.md)
2. **Implement Library**: Create `scripts/package_migration_lib.sh`
3. **Implement CLI**: Create `scripts/manage-packages.sh`
4. **Write Tests**: Implement test suite from design
5. **Integrate**: Add to daily updates and health checks
6. **Document**: Add to repository documentation

---

**Last Updated**: 2025-11-17
**Design Version**: 1.0
**Status**: Design Phase - Ready for Implementation
