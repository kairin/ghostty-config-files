# Data Model: Package Migration System

**Date**: 2025-11-09
**Feature**: 005-apt-snap-migration

## Overview

This document defines the data structures used throughout the package migration system. All entities are represented as JSON for serialization to state files and logs, with in-memory Bash associative arrays for processing.

## Core Entities

### 1. Package Installation Record

Represents a currently installed package on the system.

**JSON Schema**:
```json
{
  "name": "string (required)",
  "version": "string (required)",
  "installation_method": "enum: apt|snap|manual (required)",
  "installation_date": "ISO8601 timestamp",
  "architecture": "string (e.g., amd64, arm64)",
  "installed_size": "integer (bytes)",
  "config_files": ["string (absolute paths)"],
  "dependencies": [
    {
      "name": "string",
      "version": "string",
      "relationship": "enum: depends|recommends|suggests"
    }
  ],
  "reverse_dependencies": ["string (package names)"],
  "systemd_services": ["string (service names)"],
  "is_essential": "boolean",
  "is_boot_dependency": "boolean"
}
```

**Example**:
```json
{
  "name": "firefox",
  "version": "120.0-1ubuntu1",
  "installation_method": "apt",
  "installation_date": "2025-10-15T09:23:45Z",
  "architecture": "amd64",
  "installed_size": 234567890,
  "config_files": ["/etc/firefox/syspref.js", "/usr/lib/firefox/defaults/pref/autoconfig.js"],
  "dependencies": [
    {"name": "libgtk-3-0", "version": "3.24.38", "relationship": "depends"},
    {"name": "libdbus-1-3", "version": "1.14.10", "relationship": "depends"},
    {"name": "firefox-locale-en", "version": "120.0", "relationship": "recommends"}
  ],
  "reverse_dependencies": ["firefox-esr", "firefox-dev"],
  "systemd_services": [],
  "is_essential": false,
  "is_boot_dependency": false
}
```

**Validation Rules**:
- `name` must match regex: `^[a-z0-9][a-z0-9+.-]+$` (Debian package naming)
- `version` must be valid Debian version format
- `installation_method` determines which package manager commands to use
- `installed_size` must be >= 0
- `config_files` paths must be absolute and exist on filesystem
- `is_essential` = true blocks automatic migration (requires manual review)

**State Transitions**: None (read-only snapshot of installed packages)

---

### 2. Migration Candidate

Represents an apt package eligible for migration to snap.

**JSON Schema**:
```json
{
  "apt_package": {
    "name": "string (required)",
    "version": "string (required)",
    "installed_size": "integer (bytes)"
  },
  "snap_alternative": {
    "name": "string (required)",
    "version": "string (required)",
    "publisher": {
      "id": "string",
      "username": "string",
      "display_name": "string",
      "validation": "enum: verified|starred|unverified"
    },
    "confinement": "enum: strict|classic|devmode",
    "license": "string",
    "download_size": "integer (bytes)",
    "installed_size": "integer (bytes)"
  },
  "equivalence_score": "float (0.0-1.0)",
  "equivalence_details": {
    "name_match": "enum: exact|alias|fuzzy|none",
    "version_compatible": "boolean",
    "command_availability": ["string (command names)"],
    "feature_parity": "enum: full|partial|unknown",
    "config_compatibility": "enum: compatible|migration_required|incompatible"
  },
  "risk_level": "enum: low|medium|high|critical",
  "risk_factors": ["string (human-readable risk descriptions)"],
  "migration_priority": "integer (1-1000, higher = earlier)",
  "migration_blockers": ["string (reasons preventing migration)"],
  "is_migratable": "boolean"
}
```

**Example**:
```json
{
  "apt_package": {
    "name": "chromium-browser",
    "version": "119.0.6045.159-0ubuntu1",
    "installed_size": 456789012
  },
  "snap_alternative": {
    "name": "chromium",
    "version": "119.0.6045.159",
    "publisher": {
      "id": "canonical",
      "username": "canonical",
      "display_name": "Canonical",
      "validation": "verified"
    },
    "confinement": "strict",
    "license": "BSD-3-Clause",
    "download_size": 123456789,
    "installed_size": 456789012
  },
  "equivalence_score": 0.95,
  "equivalence_details": {
    "name_match": "alias",
    "version_compatible": true,
    "command_availability": ["chromium-browser", "chromium"],
    "feature_parity": "full",
    "config_compatibility": "compatible"
  },
  "risk_level": "low",
  "risk_factors": [],
  "migration_priority": 800,
  "migration_blockers": [],
  "is_migratable": true
}
```

**Validation Rules**:
- `equivalence_score` calculated as weighted average:
  - name_match: 20% (exact=1.0, alias=0.8, fuzzy=0.5, none=0.0)
  - version_compatible: 30% (true=1.0, false=0.0)
  - feature_parity: 30% (full=1.0, partial=0.5, unknown=0.0)
  - config_compatibility: 20% (compatible=1.0, migration_required=0.7, incompatible=0.0)
- `risk_level` determined by: essential services, reverse dependencies, boot dependencies
- `migration_priority` calculated from: risk_level (inverse), equivalence_score, dependency order
- `is_migratable` = true IFF: equivalence_score >= 0.6 AND migration_blockers is empty

**State Transitions**:
```
┌─────────────┐
│ Identified  │ (discovered during audit)
└──────┬──────┘
       │
       ├─→ blocked (is_migratable = false, migration_blockers present)
       │
       └─→ eligible (is_migratable = true, migration_blockers empty)
               │
               └─→ migrated (appears in MigrationLogEntry with status=success)
```

---

### 3. Health Check Result

Represents the outcome of a pre-migration validation check.

**JSON Schema**:
```json
{
  "check_id": "string (unique identifier)",
  "check_name": "string (human-readable)",
  "check_type": "enum: disk_space|network|snapd|essential_services|conflicts",
  "status": "enum: pass|fail|warning",
  "severity": "enum: critical|warning|info",
  "measured_value": "string (check-specific, e.g., '5.2GB', 'reachable', 'active')",
  "threshold_requirement": "string (check-specific, e.g., '10GB', 'reachable', 'active')",
  "is_blocking": "boolean",
  "message": "string (detailed explanation)",
  "remediation": "string (how to fix if failed)",
  "timestamp": "ISO8601 timestamp"
}
```

**Example (Passing Check)**:
```json
{
  "check_id": "disk_space_root",
  "check_name": "Root Partition Disk Space",
  "check_type": "disk_space",
  "status": "pass",
  "severity": "critical",
  "measured_value": "45.3GB available",
  "threshold_requirement": "10GB minimum",
  "is_blocking": true,
  "message": "Sufficient disk space available for migration",
  "remediation": null,
  "timestamp": "2025-11-09T14:30:00Z"
}
```

**Example (Failing Check)**:
```json
{
  "check_id": "snapd_daemon",
  "check_name": "snapd Service Status",
  "check_type": "snapd",
  "status": "fail",
  "severity": "critical",
  "measured_value": "inactive",
  "threshold_requirement": "active",
  "is_blocking": true,
  "message": "snapd service is not running. Snap installations require active snapd daemon.",
  "remediation": "Run: sudo systemctl start snapd.service && sudo systemctl enable snapd.service",
  "timestamp": "2025-11-09T14:30:05Z"
}
```

**Validation Rules**:
- `severity = critical` → `is_blocking = true`
- `severity = warning|info` → `is_blocking = false` (allows continuation with user confirmation)
- `status = fail` AND `is_blocking = true` → abort migration
- All health checks must run and log results before any migration operations

**Relationships**:
- Multiple HealthCheckResults aggregated into single pre-migration report
- Failing critical checks prevent MigrationBackup creation

---

### 4. Dependency Graph

Represents package dependency relationships for safe migration ordering.

**JSON Schema**:
```json
{
  "nodes": [
    {
      "package_name": "string (required)",
      "installation_method": "enum: apt|snap",
      "is_essential": "boolean",
      "depth": "integer (0 = leaf package, higher = more dependencies)"
    }
  ],
  "edges": [
    {
      "from": "string (package name)",
      "to": "string (package name)",
      "relationship": "enum: depends|recommends|suggests|reverse_depends"
    }
  ],
  "migration_order": ["string (package names in safe migration sequence)"]
}
```

**Example**:
```json
{
  "nodes": [
    {"package_name": "firefox", "installation_method": "apt", "is_essential": false, "depth": 2},
    {"package_name": "libgtk-3-0", "installation_method": "apt", "is_essential": false, "depth": 1},
    {"package_name": "libdbus-1-3", "installation_method": "apt", "is_essential": true, "depth": 0}
  ],
  "edges": [
    {"from": "firefox", "to": "libgtk-3-0", "relationship": "depends"},
    {"from": "firefox", "to": "libdbus-1-3", "relationship": "depends"},
    {"from": "libgtk-3-0", "to": "libdbus-1-3", "relationship": "depends"}
  ],
  "migration_order": ["libdbus-1-3", "libgtk-3-0", "firefox"]
}
```

**Validation Rules**:
- Graph must be acyclic (circular dependencies flagged as migration blockers)
- `migration_order` computed via topological sort (reverse depth-first search)
- Essential packages (`is_essential = true`) appear last in `migration_order`
- Leaf packages (depth = 0) have no outgoing "depends" edges

**Algorithms**:
- **Cycle Detection**: Depth-first search with visited/visiting/visited states
- **Topological Sort**: Reverse post-order DFS traversal
- **Depth Calculation**: Maximum distance from any leaf node

---

### 5. Migration Backup

Represents a snapshot of system state before migration for rollback capability.

**JSON Schema**:
```json
{
  "backup_id": "string (YYYYMMDD-HHMMSS format)",
  "timestamp": "ISO8601 timestamp",
  "backup_directory": "string (absolute path)",
  "packages": [
    {
      "name": "string",
      "version": "string",
      "installation_method": "apt",
      "deb_file": "string (relative path from backup_directory)",
      "deb_checksum": "string (sha256)",
      "dependencies": ["string (package names)"],
      "config_files": [
        {
          "source_path": "string (original absolute path)",
          "backup_path": "string (relative path from backup_directory)",
          "checksum": "string (sha256)",
          "permissions": "string (octal, e.g., '0644')",
          "owner": "string (user:group)"
        }
      ],
      "systemd_services": [
        {
          "service_name": "string",
          "service_file": "string (relative path from backup_directory)",
          "enabled": "boolean",
          "active": "boolean"
        }
      ]
    }
  ],
  "total_size": "integer (bytes)",
  "retention_until": "ISO8601 timestamp (backup_timestamp + retention_days)"
}
```

**Example**:
```json
{
  "backup_id": "20251109-143000",
  "timestamp": "2025-11-09T14:30:00Z",
  "backup_directory": "/home/user/.config/package-migration/backups/20251109-143000",
  "packages": [
    {
      "name": "firefox",
      "version": "120.0-1ubuntu1",
      "installation_method": "apt",
      "deb_file": "debs/firefox_120.0-1ubuntu1_amd64.deb",
      "deb_checksum": "sha256:abcdef123456...",
      "dependencies": ["libgtk-3-0", "libdbus-1-3"],
      "config_files": [
        {
          "source_path": "/etc/firefox/syspref.js",
          "backup_path": "configs/firefox/etc/firefox/syspref.js",
          "checksum": "sha256:fedcba654321...",
          "permissions": "0644",
          "owner": "root:root"
        }
      ],
      "systemd_services": []
    }
  ],
  "total_size": 234567890,
  "retention_until": "2025-12-09T14:30:00Z"
}
```

**Validation Rules**:
- `backup_id` must be unique (timestamp-based collision unlikely)
- All `deb_file` paths must exist and checksums must match
- All `config_files` backup_paths must exist and checksums must match
- `backup_directory` must have sufficient disk space for `total_size` + 20% buffer
- `retention_until` defaults to backup_timestamp + 30 days (configurable)

**State Transitions**:
```
┌─────────────┐
│   Created   │ (backup initiated)
└──────┬──────┘
       │
       ├─→ validated (all checksums verified)
       │
       ├─→ expired (current_time > retention_until, eligible for cleanup)
       │
       └─→ restored (rollback operation used this backup)
```

---

### 6. Migration Log Entry

Represents a single migration operation for auditing and debugging.

**JSON Schema**:
```json
{
  "entry_id": "string (UUID)",
  "timestamp": "ISO8601 timestamp",
  "operation": "enum: audit|health_check|backup|uninstall|install|verify|rollback",
  "package_name": "string",
  "source_method": "enum: apt|snap",
  "target_method": "enum: apt|snap",
  "status": "enum: started|in_progress|success|failed",
  "exit_code": "integer",
  "stdout": "string (command output)",
  "stderr": "string (error output)",
  "duration_ms": "integer (milliseconds)",
  "metadata": {
    "backup_id": "string (if operation=backup|rollback)",
    "apt_version": "string (if source_method=apt)",
    "snap_version": "string (if target_method=snap)",
    "config_files_migrated": "integer",
    "services_restarted": ["string (service names)"]
  },
  "error_details": {
    "error_type": "string (e.g., network_timeout, disk_full, dependency_conflict)",
    "error_message": "string",
    "suggested_action": "string"
  }
}
```

**Example (Successful Migration)**:
```json
{
  "entry_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "timestamp": "2025-11-09T14:35:22Z",
  "operation": "install",
  "package_name": "chromium",
  "source_method": "apt",
  "target_method": "snap",
  "status": "success",
  "exit_code": 0,
  "stdout": "chromium 119.0.6045.159 from Canonical✓ installed",
  "stderr": "",
  "duration_ms": 45230,
  "metadata": {
    "backup_id": "20251109-143000",
    "apt_version": "119.0.6045.159-0ubuntu1",
    "snap_version": "119.0.6045.159",
    "config_files_migrated": 3,
    "services_restarted": []
  },
  "error_details": null
}
```

**Example (Failed Migration)**:
```json
{
  "entry_id": "a3d5b8c1-92fe-4d1a-b234-1e9f3c7a8d90",
  "timestamp": "2025-11-09T14:42:10Z",
  "operation": "install",
  "package_name": "firefox",
  "source_method": "apt",
  "target_method": "snap",
  "status": "failed",
  "exit_code": 1,
  "stdout": "",
  "stderr": "error: cannot perform the following tasks:\n- Download snap \"firefox\" (3779) from channel \"stable\" (Get \"https://api.snapcraft.io/...\": dial tcp: lookup api.snapcraft.io: no such host)",
  "duration_ms": 5120,
  "metadata": {
    "backup_id": "20251109-143000",
    "apt_version": "120.0-1ubuntu1",
    "snap_version": null,
    "config_files_migrated": 0,
    "services_restarted": []
  },
  "error_details": {
    "error_type": "network_timeout",
    "error_message": "Failed to reach snap store API (DNS resolution failure)",
    "suggested_action": "Check network connectivity and DNS configuration, then retry migration"
  }
}
```

**Validation Rules**:
- `entry_id` must be unique (UUID v4)
- `operation` determines required metadata fields
- `status = success` → `exit_code = 0`
- `status = failed` → `exit_code != 0` AND `error_details` must be populated
- All operations must log an entry regardless of outcome

**Aggregation**:
- Migration logs aggregated into single JSON array per migration session
- Indexed by timestamp for chronological analysis
- Filtered by package_name for per-package history
- Analyzed for error patterns to improve health checks

---

## Entity Relationships

```
PackageInstallationRecord ──1:N──> MigrationCandidate
        │                              │
        │                              │
        │                          1:1 │
        │                              ▼
        │                        MigrationBackup
        │                              │
        │                          1:N │
        │                              ▼
        └──────────────────────> MigrationLogEntry

DependencyGraph ──N:M──> PackageInstallationRecord
                         (nodes reference packages)

HealthCheckResult ──N:1──> Migration Session
                          (multiple checks per session)
```

**Relationship Details**:
- **PackageInstallationRecord → MigrationCandidate**: One installed apt package may map to 0 or more snap alternatives (best match selected)
- **MigrationCandidate → MigrationBackup**: Each migration creates exactly one backup containing all packages in that batch
- **MigrationBackup → MigrationLogEntry**: Each backup referenced by multiple log entries (backup creation, package migrations, rollback)
- **DependencyGraph → PackageInstallationRecord**: Graph nodes reference installed packages, edges represent dependencies
- **HealthCheckResult → Migration Session**: Each migration session runs multiple health checks before proceeding

---

## File Storage Schema

### Package State File
**Path**: `~/.config/package-migration/migration-state.json`
**Purpose**: Track current migration progress and status
**Schema**:
```json
{
  "version": "1.0.0",
  "last_audit": "ISO8601 timestamp",
  "last_migration": "ISO8601 timestamp",
  "current_backup_id": "string (active backup for rollback)",
  "packages": {
    "firefox": {
      "status": "enum: not_evaluated|migratable|blocked|migrated|rolled_back",
      "last_operation": "ISO8601 timestamp",
      "migration_candidate": "MigrationCandidate object"
    }
  },
  "statistics": {
    "total_packages": "integer",
    "apt_installed": "integer",
    "snap_installed": "integer",
    "migratable_count": "integer",
    "migrated_count": "integer",
    "failed_count": "integer"
  }
}
```

### Audit Cache File
**Path**: `~/.config/package-migration/audit-cache.json`
**Purpose**: Cache audit results to avoid repeated expensive queries
**Schema**:
```json
{
  "cache_version": "1.0.0",
  "cache_timestamp": "ISO8601 timestamp",
  "cache_ttl_seconds": "integer (default 3600)",
  "installed_packages": ["PackageInstallationRecord objects"],
  "snap_alternatives": ["MigrationCandidate objects"],
  "dependency_graph": "DependencyGraph object"
}
```

**Cache Invalidation**:
- TTL-based: Cache expires after `cache_ttl_seconds`
- Event-based: Cache invalidated on package install/remove events
- Manual: User can force fresh audit with `--no-cache` flag

---

## Data Flow

### Audit Flow
```
1. Read installed packages
   dpkg-query → PackageInstallationRecord[]

2. Build dependency graph
   PackageInstallationRecord[] + apt-cache → DependencyGraph

3. Query snap alternatives
   PackageInstallationRecord[] + snapd API → MigrationCandidate[]

4. Calculate equivalence & risk
   MigrationCandidate[] + DependencyGraph → MigrationCandidate[] (scored)

5. Cache results
   All entities → audit-cache.json
```

### Migration Flow
```
1. Run health checks
   System state → HealthCheckResult[]

2. Verify all checks pass
   HealthCheckResult[] → PASS|FAIL (abort if FAIL)

3. Create backup
   PackageInstallationRecord[] → MigrationBackup

4. For each package in migration_order:
   a. Log start → MigrationLogEntry (status=started)
   b. Uninstall apt → MigrationLogEntry (operation=uninstall)
   c. Install snap → MigrationLogEntry (operation=install)
   d. Verify functionality → MigrationLogEntry (operation=verify)
   e. Log completion → MigrationLogEntry (status=success|failed)

5. Update migration state
   MigrationLogEntry[] → migration-state.json
```

### Rollback Flow
```
1. Load backup metadata
   backup_id → MigrationBackup

2. For each package in reverse migration_order:
   a. Log start → MigrationLogEntry (operation=rollback, status=started)
   b. Remove snap → MigrationLogEntry
   c. Reinstall apt from .deb → MigrationLogEntry
   d. Restore config files → MigrationLogEntry
   e. Restart services → MigrationLogEntry
   f. Log completion → MigrationLogEntry (status=success|failed)

3. Update migration state
   Set package status = rolled_back in migration-state.json
```

---

## Data Validation & Integrity

### Validation Rules Summary
| Entity | Critical Validations |
|--------|---------------------|
| PackageInstallationRecord | Name format (Debian), version format, config files exist |
| MigrationCandidate | Equivalence score [0.0-1.0], is_migratable consistency |
| HealthCheckResult | Severity → blocking mapping, remediation present if failed |
| DependencyGraph | Acyclic graph, migration_order valid topological sort |
| MigrationBackup | All checksums match, sufficient disk space |
| MigrationLogEntry | UUID uniqueness, status-exit_code consistency |

### Integrity Checks
```bash
# Verify backup integrity
verify_backup() {
    local backup_id="$1"
    local backup_dir="$HOME/.config/package-migration/backups/$backup_id"
    local state_file="$backup_dir/package-state.json"

    # Check all .deb files exist and match checksums
    jq -r '.packages[] | "\(.deb_file)\t\(.deb_checksum)"' "$state_file" | \
    while IFS=$'\t' read -r deb_file checksum; do
        local full_path="$backup_dir/$deb_file"
        [[ -f "$full_path" ]] || { echo "Missing: $full_path"; return 1; }

        local actual_checksum=$(sha256sum "$full_path" | awk '{print $1}')
        [[ "$actual_checksum" == "${checksum#sha256:}" ]] || {
            echo "Checksum mismatch: $full_path"; return 1;
        }
    done
}
```

---

## Performance Considerations

### Data Size Estimates
| Entity | Typical Count | Size per Entity | Total Size |
|--------|--------------|-----------------|------------|
| PackageInstallationRecord | 300 | ~2KB | 600KB |
| MigrationCandidate | 200 | ~3KB | 600KB |
| HealthCheckResult | 10 | ~1KB | 10KB |
| DependencyGraph | 1 (300 nodes, 1000 edges) | ~150KB | 150KB |
| MigrationBackup | 1-10 | ~200KB metadata + .deb files | 200KB-2MB |
| MigrationLogEntry | 1000 (across all migrations) | ~2KB | 2MB |

**Total In-Memory**: ~4MB (easily manageable in Bash with jq)
**Total On-Disk**: ~50MB (including backups, excluding .deb files)

### Indexing Strategy
```bash
# For fast lookups, use Bash associative arrays
declare -A packages_by_name
declare -A migration_candidates_by_name
declare -A backups_by_id

# Populate from JSON files
while IFS= read -r package_json; do
    name=$(echo "$package_json" | jq -r '.name')
    packages_by_name["$name"]="$package_json"
done < <(jq -c '.installed_packages[]' audit-cache.json)
```

### Caching Strategy
- **Audit results**: 1 hour TTL (balances freshness vs. performance)
- **Snap API responses**: 10 minute TTL (snap store updates frequently)
- **Dependency graph**: Invalidate on any package install/remove event
- **Migration state**: No caching (always read from disk for consistency)

---

## Schema Evolution

### Version 1.0.0 (Current)
Initial schema with all core entities defined above.

### Future Considerations
- **Version 1.1.0**: Add support for flatpak alternatives (new `flatpak_alternative` field in MigrationCandidate)
- **Version 1.2.0**: Add performance metrics (migration speed, network bandwidth usage)
- **Version 2.0.0**: Breaking change - migrate from JSON to SQLite for better querying (if package counts exceed 1000)

### Backward Compatibility
- All schema changes must include migration script (`migrate-schema.sh`)
- Old cache files automatically regenerated on schema version mismatch
- Backup files preserved in original format (no automatic migration for safety)
