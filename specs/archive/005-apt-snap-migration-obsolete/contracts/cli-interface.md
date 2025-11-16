# CLI Interface Specification: Package Migration Tool

**Date**: 2025-11-09
**Feature**: 005-apt-snap-migration
**Version**: 1.0.0

## Overview

This document defines the command-line interface for the package migration system. All commands follow GNU/POSIX conventions with long options (`--option`) and short options (`-o`).

---

## Main Command: `package_migration.sh`

### Synopsis

```bash
package_migration.sh <command> [options] [arguments]
```

### Global Options

```
--help, -h              Display help information
--version, -v           Display version information
--verbose               Enable verbose output (detailed logging)
--quiet, -q             Suppress non-error output
--no-color              Disable colored output
--config <file>         Use custom configuration file (default: ~/.config/package-migration/config.json)
--log-file <path>       Write logs to specified file (default: /tmp/ghostty-start-logs/migration-TIMESTAMP.log)
```

### Commands

1. `audit` - Audit installed packages and identify snap alternatives
2. `health` - Run pre-migration health checks
3. `migrate` - Migrate packages from apt to snap
4. `rollback` - Rollback migration to previous state
5. `status` - Show migration status and statistics
6. `backup` - Create backup of current package state
7. `cleanup` - Clean up old backups and cache

---

## Command: `audit`

Audit all installed apt packages and identify snap alternatives.

### Synopsis

```bash
package_migration.sh audit [options]
```

### Options

```
--no-cache              Force fresh audit (ignore cached results)
--cache-ttl <seconds>   Set cache TTL in seconds (default: 3600)
--output <format>       Output format: text|json|table (default: table)
--output-file <path>    Write audit results to file
--filter <criteria>     Filter results by criteria (see Filter Criteria below)
--sort <field>          Sort results by field: name|priority|risk|equivalence (default: priority)
```

### Filter Criteria

```
--migratable-only       Show only packages eligible for migration (is_migratable = true)
--high-priority         Show only high-priority migration candidates (priority >= 700)
--low-risk              Show only low-risk packages (risk_level = low)
--essential             Show only essential/boot-critical packages
--verified-publishers   Show only snap alternatives from verified publishers
```

### Output Format

**Text Format** (default for terminal):
```
Package Migration Audit Report
Generated: 2025-11-09 14:30:00

MIGRATABLE PACKAGES (5 found):
┌──────────────────┬─────────────┬─────────────┬──────────────────┬──────────┬──────┐
│ Package          │ apt Version │ snap Version│ Equivalence      │ Risk     │ Priority
├──────────────────┼─────────────┼─────────────┼──────────────────┼──────────┼──────┤
│ chromium-browser │ 119.0.6045  │ 119.0.6045  │ 95% (excellent)  │ low      │ 800  │
│ firefox          │ 120.0-1     │ 120.0       │ 92% (excellent)  │ low      │ 750  │
│ vlc              │ 3.0.20-1    │ 3.0.20      │ 88% (good)       │ medium   │ 650  │
│ gimp             │ 2.10.36     │ 2.10.36     │ 75% (acceptable) │ medium   │ 550  │
│ htop             │ 3.2.2-1     │ 3.2.2       │ 100% (perfect)   │ low      │ 900  │
└──────────────────┴─────────────┴─────────────┴──────────────────┴──────────┴──────┘

BLOCKED PACKAGES (2 found):
┌──────────────┬─────────────┬──────────────────────────────────────────┐
│ Package      │ Risk        │ Blocker Reason                           │
├──────────────┼─────────────┼──────────────────────────────────────────┤
│ systemd      │ critical    │ Essential boot dependency                │
│ network-mgr  │ critical    │ Essential service, no snap equivalent    │
└──────────────┴─────────────┴──────────────────────────────────────────┘

SUMMARY:
  Total packages (apt): 147
  Migratable: 5
  Blocked: 2
  No snap alternative: 140
```

**JSON Format** (`--output json`):
```json
{
  "audit_timestamp": "2025-11-09T14:30:00Z",
  "cache_used": false,
  "statistics": {
    "total_apt_packages": 147,
    "migratable_count": 5,
    "blocked_count": 2,
    "no_alternative_count": 140
  },
  "migratable_packages": [
    {
      "apt_package": {"name": "chromium-browser", "version": "119.0.6045"},
      "snap_alternative": {"name": "chromium", "version": "119.0.6045"},
      "equivalence_score": 0.95,
      "risk_level": "low",
      "migration_priority": 800,
      "is_migratable": true
    }
  ],
  "blocked_packages": [
    {
      "package_name": "systemd",
      "risk_level": "critical",
      "migration_blockers": ["Essential boot dependency"]
    }
  ]
}
```

### Exit Codes

```
0   Audit completed successfully
1   Audit failed (network error, snapd unavailable)
2   Invalid arguments or options
```

### Examples

```bash
# Basic audit with cached results (if available)
./package_migration.sh audit

# Fresh audit ignoring cache
./package_migration.sh audit --no-cache

# Audit and save JSON output to file
./package_migration.sh audit --output json --output-file audit-results.json

# Show only migratable packages with verified publishers
./package_migration.sh audit --migratable-only --verified-publishers

# Show high-priority, low-risk migration candidates
./package_migration.sh audit --high-priority --low-risk --sort priority
```

---

## Command: `health`

Run pre-migration health checks to verify system readiness.

### Synopsis

```bash
package_migration.sh health [options]
```

### Options

```
--check <type>          Run specific check type: disk|network|snapd|services|all (default: all)
--fix                   Attempt automatic remediation for failed checks (where possible)
--output <format>       Output format: text|json (default: text)
```

### Health Check Types

```
disk        - Disk space availability on root and /home partitions
network     - Network connectivity to snap store
snapd       - snapd daemon status and version
services    - Essential service identification
conflicts   - Package conflict detection
all         - All of the above (default)
```

### Output Format

**Text Format**:
```
Pre-Migration Health Check Report
Generated: 2025-11-09 14:30:00

✅ PASS [CRITICAL] Disk Space (Root Partition)
   Measured: 45.3GB available
   Required: 10GB minimum
   Status: Sufficient space for migration

✅ PASS [CRITICAL] Network Connectivity
   Measured: Snap store reachable (200 OK)
   Required: Reachable
   Status: Network connectivity verified

❌ FAIL [CRITICAL] snapd Service Status
   Measured: inactive (dead)
   Required: active (running)
   Status: snapd daemon not running
   Remediation: sudo systemctl start snapd.service && sudo systemctl enable snapd.service

⚠️  WARNING [WARNING] Essential Services Detected
   Measured: 3 essential services identified
   Required: Manual review recommended
   Packages: systemd, network-manager, gdm3
   Status: These packages should not be auto-migrated

OVERALL RESULT: ❌ FAILED
Critical checks failed: 1 (snapd Service Status)
Action required before migration can proceed.
```

**JSON Format** (`--output json`):
```json
{
  "check_timestamp": "2025-11-09T14:30:00Z",
  "overall_status": "fail",
  "critical_failures": 1,
  "warning_count": 1,
  "checks": [
    {
      "check_id": "disk_space_root",
      "check_name": "Disk Space (Root Partition)",
      "status": "pass",
      "severity": "critical",
      "measured_value": "45.3GB available",
      "threshold_requirement": "10GB minimum",
      "is_blocking": true,
      "message": "Sufficient space for migration",
      "remediation": null
    },
    {
      "check_id": "snapd_daemon",
      "check_name": "snapd Service Status",
      "status": "fail",
      "severity": "critical",
      "measured_value": "inactive (dead)",
      "threshold_requirement": "active (running)",
      "is_blocking": true,
      "message": "snapd daemon not running",
      "remediation": "sudo systemctl start snapd.service && sudo systemctl enable snapd.service"
    }
  ]
}
```

### Exit Codes

```
0   All health checks passed
1   One or more critical checks failed (blocking migration)
2   One or more warnings (migration can proceed with caution)
3   Health check execution failed (error in check script)
```

### Examples

```bash
# Run all health checks
./package_migration.sh health

# Run only disk space and network checks
./package_migration.sh health --check disk --check network

# Run checks and attempt automatic fixes
./package_migration.sh health --fix

# Output health check results as JSON
./package_migration.sh health --output json
```

---

## Command: `migrate`

Migrate packages from apt to snap.

### Synopsis

```bash
package_migration.sh migrate [options] [package...]
```

### Options

```
--all                   Migrate all eligible packages (respects priority order)
--batch-size <n>        Process n packages per batch (default: 10)
--dry-run               Show migration plan without executing changes
--skip-health-checks    Skip pre-migration health checks (NOT RECOMMENDED)
--skip-backup           Skip backup creation (NOT RECOMMENDED)
--force                 Force migration even if warnings present
--priority-threshold <n> Only migrate packages with priority >= n (default: 500)
--interactive           Prompt for confirmation before each package migration
```

### Arguments

```
[package...]            Specific package names to migrate (e.g., firefox chromium)
                        If omitted, use --all to migrate all eligible packages
```

### Migration Process

1. **Pre-Migration Validation**
   - Run health checks (unless `--skip-health-checks`)
   - Verify all specified packages are migratable
   - Calculate migration order based on dependency graph

2. **Backup Creation**
   - Create timestamped backup directory
   - Download .deb files for all packages
   - Save configuration files
   - Record systemd service states

3. **Migration Execution**
   - Process packages in dependency-safe order
   - For each package:
     - Uninstall apt package (preserve configs)
     - Install snap alternative
     - Migrate configuration files
     - Verify functional equivalence
     - Update migration state

4. **Post-Migration Validation**
   - Verify all migrated packages are functional
   - Check systemd services are active
   - Log migration summary

### Output Format

**Text Format** (live progress):
```
Package Migration Starting
Backup ID: 20251109-143000

✅ Pre-Migration Health Checks: PASSED
✅ Backup Created: /home/user/.config/package-migration/backups/20251109-143000

Migration Progress (5 packages in queue):

[1/5] Migrating: htop
  ⏳ Downloading .deb backup... ✅ Done (2.3MB)
  ⏳ Uninstalling apt package... ✅ Done
  ⏳ Installing snap alternative... ✅ Done (5.1MB download, 12.3MB installed)
  ⏳ Verifying functionality... ✅ Command available: htop --version
  ✅ Migration successful (45 seconds)

[2/5] Migrating: chromium-browser
  ⏳ Downloading .deb backup... ✅ Done (125MB)
  ⏳ Uninstalling apt package... ✅ Done
  ⏳ Installing snap alternative... ✅ Done (95MB download, 456MB installed)
  ⏳ Migrating configurations... ✅ Done (3 config files)
  ⏳ Verifying functionality... ✅ Command available: chromium --version
  ✅ Migration successful (2m 15s)

[3/5] Migrating: firefox
  ⏳ Downloading .deb backup... ✅ Done (98MB)
  ⏳ Uninstalling apt package... ✅ Done
  ⏳ Installing snap alternative... ❌ FAILED
     Error: Network timeout (snap store unreachable)
  ⏳ Rolling back... ✅ apt package restored
  ❌ Migration failed (1m 34s)

Migration Summary:
  ✅ Successful: 2 (htop, chromium-browser)
  ❌ Failed: 1 (firefox)
  ⏭️  Skipped: 2 (vlc, gimp) - aborted due to failure

Rollback available: ./package_migration.sh rollback 20251109-143000
```

### Dry Run Output

```bash
$ ./package_migration.sh migrate --all --dry-run

Migration Plan (Dry Run - No Changes Will Be Made)
Backup ID: 20251109-143000 (will be created)

Pre-Migration Validation:
  ✅ Health checks: PASSED
  ✅ Disk space required: 2.3GB (available: 45.3GB)
  ✅ Network connectivity: OK

Migration Order (5 packages):
1. htop (priority: 900, risk: low, dependencies: 0)
   apt: htop 3.2.2-1 → snap: htop 3.2.2
   Estimated time: <1 minute

2. chromium-browser (priority: 800, risk: low, dependencies: 2)
   apt: chromium-browser 119.0 → snap: chromium 119.0
   Estimated time: 2-3 minutes

3. firefox (priority: 750, risk: low, dependencies: 3)
   apt: firefox 120.0-1 → snap: firefox 120.0
   Estimated time: 2-3 minutes

4. vlc (priority: 650, risk: medium, dependencies: 5)
   apt: vlc 3.0.20-1 → snap: vlc 3.0.20
   Estimated time: 1-2 minutes

5. gimp (priority: 550, risk: medium, dependencies: 8)
   apt: gimp 2.10.36 → snap: gimp 2.10.36
   Estimated time: 2-3 minutes

Total estimated time: 8-12 minutes
Total download size: ~350MB
Total installed size after migration: ~1.2GB

To proceed with migration, run:
  ./package_migration.sh migrate --all
```

### Exit Codes

```
0   All migrations successful
1   One or more migrations failed (rollback available)
2   Pre-migration health checks failed (no changes made)
3   Invalid arguments or package names
```

### Examples

```bash
# Migrate specific packages
./package_migration.sh migrate firefox chromium

# Migrate all eligible packages
./package_migration.sh migrate --all

# Dry run to see migration plan
./package_migration.sh migrate --all --dry-run

# Migrate with interactive confirmation
./package_migration.sh migrate --all --interactive

# Migrate only high-priority packages
./package_migration.sh migrate --all --priority-threshold 700

# Migrate in small batches
./package_migration.sh migrate --all --batch-size 5
```

---

## Command: `rollback`

Rollback migration to previous state using backup.

### Synopsis

```bash
package_migration.sh rollback <backup-id> [options] [package...]
```

### Options

```
--all                   Rollback all packages in the backup
--verify-only           Verify backup integrity without rolling back
--force                 Skip confirmation prompts
--keep-snap             Keep snap package installed after rollback (for testing)
```

### Arguments

```
<backup-id>             Backup identifier (YYYYMMDD-HHMMSS format or 'latest')
[package...]            Specific packages to rollback (default: all packages in backup)
```

### Rollback Process

1. **Backup Verification**
   - Verify backup directory exists
   - Verify all .deb files present and checksums match
   - Verify sufficient disk space for apt reinstallation

2. **Rollback Execution**
   - Process packages in reverse migration order
   - For each package:
     - Remove snap package
     - Reinstall apt package from .deb
     - Restore configuration files
     - Restore systemd service states
     - Verify functionality

3. **Post-Rollback Validation**
   - Verify all rolled-back packages functional
   - Update migration state
   - Log rollback summary

### Output Format

```
Rollback Starting
Backup ID: 20251109-143000
Packages to rollback: 2 (chromium-browser, htop)

✅ Backup Verified: All .deb files present and valid

Rollback Progress:

[1/2] Rolling back: chromium-browser
  ⏳ Removing snap package... ✅ Done
  ⏳ Reinstalling apt package... ✅ Done (chromium-browser 119.0.6045 installed)
  ⏳ Restoring configuration... ✅ Done (3 files restored)
  ⏳ Verifying functionality... ✅ Command available: chromium-browser --version
  ✅ Rollback successful (1m 22s)

[2/2] Rolling back: htop
  ⏳ Removing snap package... ✅ Done
  ⏳ Reinstalling apt package... ✅ Done (htop 3.2.2-1 installed)
  ⏳ Verifying functionality... ✅ Command available: htop --version
  ✅ Rollback successful (18 seconds)

Rollback Summary:
  ✅ Successful: 2 (chromium-browser, htop)
  ❌ Failed: 0

System restored to state as of: 2025-11-09 14:30:00
```

### Exit Codes

```
0   Rollback completed successfully
1   One or more rollbacks failed
2   Backup verification failed (corrupted or missing files)
3   Invalid backup ID or package names
```

### Examples

```bash
# Rollback all packages from latest backup
./package_migration.sh rollback latest --all

# Rollback specific package from backup
./package_migration.sh rollback 20251109-143000 firefox

# Verify backup integrity only
./package_migration.sh rollback 20251109-143000 --verify-only

# Rollback without confirmation prompts
./package_migration.sh rollback latest --all --force
```

---

## Command: `status`

Show current migration status and statistics.

### Synopsis

```bash
package_migration.sh status [options]
```

### Options

```
--output <format>       Output format: text|json (default: text)
--detailed              Show detailed package-level status
--history               Show migration history (recent operations)
```

### Output Format

**Text Format** (summary):
```
Package Migration Status
Last audit: 2025-11-09 14:30:00
Last migration: 2025-11-09 14:45:00

Statistics:
  Total packages installed: 147
    ├─ apt: 142 (96.6%)
    └─ snap: 5 (3.4%)

  Migration candidates: 7
    ├─ Migratable: 5
    ├─ Blocked: 2
    └─ Already migrated: 2

  Migration status:
    ├─ Successful migrations: 2
    ├─ Failed migrations: 1
    └─ Rollbacks performed: 0

  Active backup: 20251109-143000
    ├─ Created: 2025-11-09 14:30:00
    ├─ Packages: 5
    └─ Size: 234MB

Next recommended action: Retry failed migration (firefox)
  Command: ./package_migration.sh migrate firefox
```

**Text Format** (detailed):
```
Package-Level Status:

Migrated Packages (2):
  chromium-browser: apt 119.0 → snap 119.0 (2025-11-09 14:35:22)
  htop: apt 3.2.2 → snap 3.2.2 (2025-11-09 14:33:10)

Failed Migrations (1):
  firefox: Migration failed (2025-11-09 14:42:10)
    Reason: Network timeout (snap store unreachable)
    Rollback: Successful (reverted to apt 120.0-1)

Pending Migrations (3):
  vlc: priority 650, risk medium, equivalence 88%
  gimp: priority 550, risk medium, equivalence 75%
  remmina: priority 500, risk low, equivalence 82%
```

**JSON Format**:
```json
{
  "status_timestamp": "2025-11-09T15:00:00Z",
  "last_audit": "2025-11-09T14:30:00Z",
  "last_migration": "2025-11-09T14:45:00Z",
  "statistics": {
    "total_packages": 147,
    "apt_installed": 142,
    "snap_installed": 5,
    "migratable_count": 5,
    "migrated_count": 2,
    "failed_count": 1,
    "blocked_count": 2
  },
  "active_backup": {
    "backup_id": "20251109-143000",
    "created": "2025-11-09T14:30:00Z",
    "packages": 5,
    "total_size": 234567890
  },
  "migrated_packages": [
    {
      "name": "chromium-browser",
      "from_version": "119.0.6045.159-0ubuntu1",
      "to_version": "119.0.6045.159",
      "migration_timestamp": "2025-11-09T14:35:22Z",
      "status": "success"
    }
  ]
}
```

### Exit Codes

```
0   Status retrieved successfully
1   Error reading migration state files
```

### Examples

```bash
# Show summary status
./package_migration.sh status

# Show detailed package-level status
./package_migration.sh status --detailed

# Show migration history
./package_migration.sh status --history

# Output status as JSON
./package_migration.sh status --output json
```

---

## Command: `backup`

Create backup of current package state (without migrating).

### Synopsis

```bash
package_migration.sh backup [options] [package...]
```

### Options

```
--all                   Backup all installed apt packages
--output-dir <path>     Custom backup directory (default: ~/.config/package-migration/backups/)
--label <name>          Custom label for backup (default: timestamp)
```

### Arguments

```
[package...]            Specific packages to backup (default: all apt packages)
```

### Output Format

```
Creating Package Backup
Backup ID: 20251109-153000

Backup Progress:

[1/5] Backing up: firefox
  ⏳ Downloading .deb file... ✅ Done (98MB)
  ⏳ Copying configuration files... ✅ Done (3 files)
  ⏳ Recording service states... ✅ Done (0 services)
  ✅ Backup successful

[2/5] Backing up: chromium-browser
  ⏳ Downloading .deb file... ✅ Done (125MB)
  ⏳ Copying configuration files... ✅ Done (5 files)
  ⏳ Recording service states... ✅ Done (0 services)
  ✅ Backup successful

Backup Summary:
  ✅ Successful: 5 packages
  ❌ Failed: 0
  Total size: 456MB

Backup location: /home/user/.config/package-migration/backups/20251109-153000
Retention until: 2025-12-09 15:30:00 (30 days)
```

### Exit Codes

```
0   Backup completed successfully
1   One or more package backups failed
2   Insufficient disk space for backup
3   Invalid arguments
```

### Examples

```bash
# Backup all apt packages
./package_migration.sh backup --all

# Backup specific packages
./package_migration.sh backup firefox chromium vlc

# Backup with custom label
./package_migration.sh backup --all --label "pre-upgrade-backup"

# Backup to custom directory
./package_migration.sh backup --all --output-dir /mnt/external/backups
```

---

## Command: `cleanup`

Clean up old backups and cached audit data.

### Synopsis

```bash
package_migration.sh cleanup [options]
```

### Options

```
--backups               Clean up expired backups only
--cache                 Clean up cached audit data only
--retention-days <n>    Set retention period for backups (default: 30)
--dry-run               Show what would be deleted without deleting
--force                 Skip confirmation prompts
```

### Output Format

```
Cleanup Analysis
Retention period: 30 days
Current date: 2025-11-09 15:30:00

Expired Backups (3 found):
  20251010-120000 (created: 2025-10-10, size: 234MB) - EXPIRED
  20251015-143000 (created: 2025-10-15, size: 456MB) - EXPIRED
  20251020-090000 (created: 2025-10-20, size: 123MB) - EXPIRED

Active Backups (2 found):
  20251109-143000 (created: 2025-11-09, size: 234MB) - RETAINED
  20251108-100000 (created: 2025-11-08, size: 345MB) - RETAINED

Cached Audit Data:
  audit-cache.json (created: 2025-11-08, size: 1.2MB) - EXPIRED

Total space to be freed: 814MB

Proceed with cleanup? (yes/no):
```

### Exit Codes

```
0   Cleanup completed successfully
1   Cleanup failed (permission denied, I/O error)
2   Invalid arguments
```

### Examples

```bash
# Clean up expired backups and cache (dry run)
./package_migration.sh cleanup --dry-run

# Clean up expired backups only
./package_migration.sh cleanup --backups

# Clean up with custom retention period
./package_migration.sh cleanup --retention-days 60

# Force cleanup without confirmation
./package_migration.sh cleanup --force
```

---

## Configuration File

### Location

Default: `~/.config/package-migration/config.json`

### Schema

```json
{
  "version": "1.0.0",
  "backup": {
    "directory": "~/.config/package-migration/backups",
    "retention_days": 30,
    "auto_cleanup": false
  },
  "cache": {
    "enabled": true,
    "ttl_seconds": 3600,
    "directory": "~/.config/package-migration"
  },
  "migration": {
    "batch_size": 10,
    "priority_threshold": 500,
    "require_verified_publishers": false,
    "skip_interactive_confirmation": false
  },
  "health_checks": {
    "disk_space_minimum_gb": 10,
    "network_timeout_seconds": 30,
    "auto_fix_enabled": false
  },
  "logging": {
    "directory": "/tmp/ghostty-start-logs",
    "level": "INFO",
    "json_enabled": true,
    "keep_days": 7
  }
}
```

### Example Custom Configuration

```bash
# Use custom configuration file
./package_migration.sh --config ~/my-migration-config.json migrate --all

# Override config with CLI options (CLI takes precedence)
./package_migration.sh --config custom.json migrate --all --batch-size 5
```

---

## Environment Variables

```
MIGRATION_CONFIG        Path to configuration file (overrides default)
MIGRATION_LOG_LEVEL     Log level: DEBUG|INFO|WARNING|ERROR (overrides config)
MIGRATION_CACHE_DIR     Cache directory (overrides config)
MIGRATION_BACKUP_DIR    Backup directory (overrides config)
NO_COLOR                Disable colored output (set to any value)
```

### Example

```bash
# Set custom log level
export MIGRATION_LOG_LEVEL=DEBUG
./package_migration.sh audit

# Use custom cache directory
export MIGRATION_CACHE_DIR=/tmp/migration-cache
./package_migration.sh audit --no-cache

# Disable colored output
export NO_COLOR=1
./package_migration.sh migrate --all
```

---

## Error Handling

### Common Errors

| Error Code | Message | Cause | Resolution |
|------------|---------|-------|------------|
| E001 | "snapd daemon not running" | snapd.service inactive | `sudo systemctl start snapd.service` |
| E002 | "Insufficient disk space" | Free space < required | Free up disk space or use external storage |
| E003 | "Network timeout (snap store)" | Snap store unreachable | Check network connectivity |
| E004 | "Package not found" | Invalid package name | Verify package name with `dpkg -l` |
| E005 | "Backup corrupted" | Checksum mismatch | Create fresh backup |
| E006 | "Permission denied" | Insufficient privileges | Run with sudo |
| E007 | "Dependency conflict" | Conflicting packages | Review conflict and resolve manually |
| E008 | "No snap alternative found" | Package not available in snap | Package cannot be migrated |

### Error Output Format

```
❌ ERROR [E003]: Network timeout (snap store)

Details:
  Operation: migrate
  Package: firefox
  Timestamp: 2025-11-09 14:42:10

Cause:
  Failed to reach snap store API after 30 seconds
  DNS resolution failure: api.snapcraft.io

Resolution:
  1. Check network connectivity: ping api.snapcraft.io
  2. Verify DNS configuration: cat /etc/resolv.conf
  3. Check firewall rules: sudo ufw status
  4. Retry migration after resolving network issues

Rollback available: ./package_migration.sh rollback 20251109-143000
```

---

## Integration with Local CI/CD

### Validation Script

```bash
# File: local-infra/tests/validation/validate_migration.sh

#!/bin/bash
set -euo pipefail

echo "🔍 Validating package migration system..."

# Test audit command
echo "Testing audit command..."
./scripts/package_migration.sh audit --no-cache --output json > /tmp/audit-test.json
jq -e '.migratable_packages | length > 0' /tmp/audit-test.json || {
    echo "❌ Audit validation failed"
    exit 1
}
echo "✅ Audit command validated"

# Test health checks
echo "Testing health checks..."
./scripts/package_migration.sh health --output json > /tmp/health-test.json
jq -e '.overall_status' /tmp/health-test.json || {
    echo "❌ Health check validation failed"
    exit 1
}
echo "✅ Health checks validated"

# Test dry-run migration
echo "Testing dry-run migration..."
./scripts/package_migration.sh migrate --all --dry-run || {
    echo "❌ Dry-run validation failed"
    exit 1
}
echo "✅ Dry-run migration validated"

echo "✅ All CLI validations passed"
```

---

## Version History

### Version 1.0.0 (2025-11-09)
- Initial CLI specification
- Commands: audit, health, migrate, rollback, status, backup, cleanup
- JSON and text output formats
- Configuration file support
- Environment variable overrides
