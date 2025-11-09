# Research: Package Manager Migration (apt → snap)

**Date**: 2025-11-09
**Feature**: 005-apt-snap-migration

## Overview

This document captures research findings and technical decisions for implementing safe package migration from apt to snap/Ubuntu App Center. Research focused on: (1) dependency resolution strategies, (2) snap store API capabilities, (3) rollback mechanisms, (4) systemd service preservation, and (5) functional equivalence detection.

## 1. Dependency Resolution & Graph Analysis

### Decision: Use dpkg-query with reverse dependency tracking

**Rationale**:
- `dpkg-query --show` provides complete package metadata including dependencies
- `apt-cache rdepends` efficiently identifies reverse dependencies
- Combined approach enables safe migration ordering (leaf packages first)
- Native Ubuntu tools avoid additional dependency installation

**Implementation Approach**:
```bash
# Get package dependency tree
dpkg-query -W -f='${Package}\t${Version}\t${Depends}\t${Recommends}\n' <package>

# Get reverse dependencies
apt-cache rdepends --installed <package>

# Build dependency graph using associative arrays
declare -A dep_graph
declare -A reverse_deps
```

**Alternatives Considered**:
- **apt-rdepends**: Requires separate installation, adds complexity
- **Python apt module**: Introduces Python dependency, violates Bash-first approach
- **Manual /var/lib/dpkg/status parsing**: Fragile, error-prone

**Best Practices**:
- Cache dependency graph to avoid repeated queries (performance)
- Detect circular dependencies and flag for manual review
- Use topological sort for migration ordering
- Validate entire dependency chain has snap alternatives before starting

**Performance Characteristics**:
- Dependency query: ~10ms per package
- Reverse dependency query: ~50ms per package
- Expected total for 300 packages: ~18 seconds (within <2 minute audit goal)

## 2. Snap Store API Integration

### Decision: Use snapd REST API via local socket

**Rationale**:
- snapd provides local REST API via `/run/snapd.socket`
- No authentication required for read operations (search, info)
- Structured JSON responses enable reliable parsing
- Official supported interface with stable API contract

**API Endpoints**:
```bash
# Search for snap alternatives
curl -sS --unix-socket /run/snapd.socket http://localhost/v2/find?q=<package-name>

# Get detailed snap info
curl -sS --unix-socket /run/snapd.socket http://localhost/v2/snaps/<snap-name>

# Check snap installation status
curl -sS --unix-socket /run/snapd.socket http://localhost/v2/snaps
```

**Response Structure**:
```json
{
  "type": "sync",
  "status-code": 200,
  "result": [{
    "name": "package-name",
    "version": "1.2.3",
    "publisher": {
      "id": "canonical",
      "username": "canonical",
      "display-name": "Canonical",
      "validation": "verified"
    },
    "confinement": "strict",
    "license": "GPL-3.0"
  }]
}
```

**Alternatives Considered**:
- **snap find command**: Unstructured text output, harder to parse
- **Ubuntu Store API**: Requires internet, authentication complexity
- **Web scraping snapcraft.io**: Fragile, rate-limited, unreliable

**Best Practices**:
- Verify `snapd.socket` exists before attempting API calls
- Implement retry logic with exponential backoff for network issues
- Cache search results to minimize API calls (respect rate limits)
- Prefer publisher validation: "verified" > "starred" > unverified

**Functional Equivalence Detection**:
```bash
# Match criteria (priority order):
1. Exact name match (e.g., "firefox" apt → "firefox" snap)
2. Common alias match (e.g., "chromium-browser" → "chromium")
3. Publisher verification (prefer canonical/verified publishers)
4. Description similarity (fuzzy matching if name differs)
5. Command availability verification post-install
```

## 3. Rollback Mechanism Design

### Decision: Snapshot-based rollback with preserved .deb files

**Rationale**:
- Preserving `.deb` files enables offline rollback (no network dependency)
- JSON state files provide atomic rollback instructions
- Timestamped snapshots support multiple rollback points
- Configuration file preservation prevents data loss

**Backup Structure**:
```bash
~/.config/package-migration/backups/20251109-143000/
├── package-state.json      # Migration metadata
├── debs/                   # Downloaded .deb files
│   ├── firefox_120.0.deb
│   └── chromium_119.0.deb
├── configs/                # Configuration snapshots
│   ├── firefox/
│   └── chromium/
└── services/               # Systemd service definitions
    ├── firefox.service
    └── chromium.service
```

**package-state.json Schema**:
```json
{
  "timestamp": "2025-11-09T14:30:00Z",
  "packages": [
    {
      "name": "firefox",
      "version": "120.0-1ubuntu1",
      "installation_method": "apt",
      "deb_file": "debs/firefox_120.0.deb",
      "dependencies": ["libgtk-3-0", "libdbus-1-3"],
      "config_files": ["/etc/firefox/syspref.js"],
      "systemd_services": ["firefox.service"],
      "migration_status": "completed",
      "snap_alternative": "firefox",
      "snap_version": "120.0"
    }
  ]
}
```

**Rollback Process**:
1. Remove snap package (`snap remove --purge <snap-name>`)
2. Reinstall apt package from preserved .deb (`dpkg -i debs/<package>.deb`)
3. Restore configuration files (`rsync -a configs/<package>/ /`)
4. Restore systemd services (`systemctl daemon-reload && systemctl restart`)
5. Verify functionality (`command -v <package> && <package> --version`)

**Alternatives Considered**:
- **Timeshift/rsync snapshots**: Entire system snapshot too heavy, slow
- **Git-based config versioning**: Complex, doesn't handle binary packages
- **Bare apt-cache**: Cleared frequently, unreliable for rollback

**Best Practices**:
- Download .deb before uninstalling (`apt-get download <package>`)
- Verify .deb integrity (`dpkg --verify` post-download)
- Test rollback on non-critical package before system-wide
- Implement automatic rollback on critical service failures
- Preserve snapshots for 30 days (configurable retention policy)

## 4. System Health Checks

### Decision: Multi-layer validation with blocking severity levels

**Rationale**:
- Pre-migration checks prevent destructive operations on unhealthy systems
- Severity levels (CRITICAL/WARNING/INFO) enable informed decision-making
- Comprehensive checks cover common failure scenarios
- Modular design allows easy addition of new checks

**Health Check Categories**:

#### 4.1 Disk Space Validation
```bash
# Check: Sufficient space for parallel installation
calculate_required_space() {
    local apt_size=$(dpkg-query -W -f='${Installed-Size}\n' "$package")
    local snap_size=$(snap info "$snap_name" | grep 'installed:' | awk '{print $2}')
    local buffer=1073741824  # 1GB safety buffer
    echo $((apt_size + snap_size + buffer))
}

# Severity: CRITICAL if insufficient (blocks migration)
```

#### 4.2 Network Connectivity
```bash
# Check: Snap store reachable
check_snap_store() {
    curl -sS --max-time 5 --unix-socket /run/snapd.socket \
        http://localhost/v2/system-info >/dev/null 2>&1
}

# Severity: CRITICAL if unreachable (snap install requires network)
```

#### 4.3 snapd Daemon Status
```bash
# Check: snapd service running and healthy
check_snapd_status() {
    systemctl is-active --quiet snapd.service &&
    systemctl is-active --quiet snapd.socket
}

# Severity: CRITICAL if not running (auto-start attempted)
```

#### 4.4 Essential Service Identification
```bash
# Check: Identify boot-critical and essential services
identify_essential_services() {
    # Method 1: systemd essential services
    systemctl list-dependencies --before basic.target

    # Method 2: dpkg essential packages
    dpkg-query -W -f='${Package}\t${Essential}\n' | grep 'yes$'

    # Method 3: init system dependencies
    dpkg-query -W -f='${Package}\t${Pre-Depends}\n' | grep -E 'systemd|init'
}

# Severity: WARNING (flag for manual review, do not auto-migrate)
```

#### 4.5 Package Conflict Detection
```bash
# Check: No conflicting packages after migration
check_conflicts() {
    snap info "$snap_name" | grep 'conflicts:' | awk '{print $2}'
    dpkg-query -W -f='${Conflicts}\n' "$apt_package"
}

# Severity: WARNING if conflicts detected (present user choice)
```

**Alternatives Considered**:
- **Basic disk space only**: Insufficient, misses network/service issues
- **systemd-analyze**: Useful but overkill for pre-migration validation
- **Full system health suite**: Too slow, beyond migration scope

**Best Practices**:
- Run all checks before any modifications
- Log check results to migration state file
- Fail fast on CRITICAL severity (no partial migrations)
- Provide clear remediation instructions for failures
- Re-run health checks after each migration batch

## 5. Configuration Migration

### Decision: Heuristic-based config file mapping with validation

**Rationale**:
- Snap applications use confined paths (`~/snap/<app>/current/`)
- Configuration formats often differ between apt/snap versions
- Manual validation required for complex configurations
- Best-effort migration with clear user communication

**Configuration Mapping Strategy**:

#### 5.1 Path Translation
```bash
# apt config locations → snap equivalents
/etc/<app>/config           → ~/snap/<app>/current/.config/<app>/
~/.config/<app>/            → ~/snap/<app>/current/.config/<app>/
~/.local/share/<app>/       → ~/snap/<app>/current/.local/share/<app>/
```

#### 5.2 Format Validation
```bash
# Detect config format and validate compatibility
validate_config_format() {
    local apt_config="/etc/$app/config"
    local snap_config="$HOME/snap/$app/current/.config/$app/config"

    # Check format (JSON/YAML/INI/custom)
    file_type=$(file -b --mime-type "$apt_config")

    # Validate snap version accepts same format
    # (implementation-specific, may require snap command testing)
}
```

#### 5.3 Migration Approach
```bash
# Copy apt config to snap location
migrate_config() {
    local apt_config_dir="$1"
    local snap_config_dir="$2"

    # Create snap config directory
    mkdir -p "$snap_config_dir"

    # Copy with preservation
    rsync -av --backup --suffix=.apt-backup \
        "$apt_config_dir/" "$snap_config_dir/"

    # Log migration for rollback
    echo "$apt_config_dir → $snap_config_dir" >> "$migration_log"
}
```

**Known Configuration Challenges**:
| Application | apt Config | snap Config | Migration Complexity |
|-------------|-----------|-------------|---------------------|
| Firefox | `/etc/firefox/` | `~/snap/firefox/current/.mozilla/` | Medium (different paths, profiles) |
| Chromium | `~/.config/chromium/` | `~/snap/chromium/current/.config/chromium/` | Low (same structure) |
| VS Code | `~/.config/Code/` | `~/snap/code/current/.config/Code/` | Low (same structure) |
| GIMP | `~/.config/GIMP/` | `~/snap/gimp/current/.config/GIMP/` | Medium (plugin paths differ) |

**Alternatives Considered**:
- **Automatic config conversion**: Too complex, app-specific, error-prone
- **No config migration**: Poor UX, users lose settings
- **Manual-only migration**: Time-consuming, doesn't scale

**Best Practices**:
- Always backup original configs before migration
- Provide post-migration config validation test
- Document manual steps for complex applications
- Offer dry-run showing config migration plan
- Log all config file operations for rollback support

## 6. Performance Optimization

### Decision: Parallel operations with batch processing

**Rationale**:
- Dependency analysis is I/O bound (can parallelize reads)
- Snap API calls have network latency (batch requests)
- Migration operations must be sequential (dependency order)
- Caching eliminates redundant operations

**Optimization Strategies**:

#### 6.1 Parallel Dependency Analysis
```bash
# Use xargs with parallel processing
dpkg-query -W -f='${Package}\n' | \
    xargs -P 4 -I {} bash -c 'analyze_package_deps "{}"'
```

#### 6.2 API Request Batching
```bash
# Single search query for multiple packages
search_query="$(echo "$packages" | tr '\n' ' ' | sed 's/ /+OR+/g')"
curl -sS --unix-socket /run/snapd.socket \
    "http://localhost/v2/find?q=$search_query"
```

#### 6.3 Audit Result Caching
```bash
# Cache audit results in JSON file
cache_file="$HOME/.config/package-migration/audit-cache.json"
cache_ttl=3600  # 1 hour TTL

# Check cache freshness
if [[ -f "$cache_file" ]] &&
   [[ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt $cache_ttl ]]; then
    # Use cached results
    cat "$cache_file"
else
    # Perform fresh audit and update cache
    audit_packages > "$cache_file"
fi
```

**Performance Targets & Validation**:
- Audit (300 packages): <2 minutes (target met via caching + parallelization)
- Full migration (100 packages): <30 minutes (dependency-ordered batches of 10)
- Rollback operation: <5 minutes (parallel apt reinstall from local .debs)

## 7. Testing Strategy

### Decision: Three-tier testing approach (unit → integration → validation)

**Rationale**:
- Unit tests validate individual functions in isolation
- Integration tests verify component interactions
- End-to-end validation ensures real-world scenarios work
- Existing test infrastructure (`local-infra/tests/`) provides framework

**Test Coverage Plan**:

#### 7.1 Unit Tests (local-infra/tests/unit/)
```bash
# test_audit_packages.sh
- Test package detection from dpkg-query
- Test dependency graph construction
- Test snap alternative search
- Test essential service identification

# test_migration_health_checks.sh
- Test disk space calculation
- Test network connectivity check
- Test snapd status verification
- Test conflict detection

# test_migration_backup.sh
- Test .deb file download
- Test config file preservation
- Test state file generation
- Test backup directory creation

# test_migration_rollback.sh
- Test snap removal
- Test apt package reinstallation
- Test config restoration
- Test service restart
```

#### 7.2 Integration Tests (local-infra/tests/integration/)
```bash
# test_migration_workflow.sh
- Test complete migration lifecycle (audit → backup → migrate → verify)
- Test rollback after successful migration
- Test rollback after failed migration
- Test batch migration ordering

# test_snap_api_integration.sh
- Test snapd API connectivity
- Test search result parsing
- Test publisher validation
- Test version comparison
```

#### 7.3 End-to-End Validation (local-infra/tests/validation/)
```bash
# validate_migration.sh
- Test migration on non-critical packages (htop, tree, jq)
- Test functional equivalence verification
- Test configuration preservation
- Test rollback to exact previous state
- Test system bootability after migration
```

**Testing Best Practices**:
- Use test fixtures (mock dpkg output, snap API responses)
- Test both success and failure paths
- Validate error messages are clear and actionable
- Performance test with realistic package counts (100-500)
- Run tests in isolated environment (VM/container)

## 8. Error Handling & Logging

### Decision: Structured logging with severity levels and JSON output

**Rationale**:
- Structured logs enable automated parsing and analysis
- Severity levels facilitate filtering and alerting
- JSON format integrates with existing logging infrastructure
- Comprehensive logging enables post-mortem debugging

**Logging Architecture**:
```bash
LOG_DIR="/tmp/ghostty-start-logs"
MIGRATION_LOG="$LOG_DIR/migration-$(date +%s).log"
MIGRATION_LOG_JSON="$LOG_DIR/migration-$(date +%s).log.json"
ERROR_LOG="$LOG_DIR/migration-errors.log"

# Logging function with severity levels
log_event() {
    local severity="$1"  # DEBUG|INFO|WARNING|ERROR|CRITICAL
    local component="$2"  # audit|backup|migrate|rollback
    local message="$3"
    local metadata="$4"  # Optional JSON metadata

    # Human-readable log
    echo "[$(date -Iseconds)] [$severity] [$component] $message" >> "$MIGRATION_LOG"

    # Structured JSON log
    jq -n \
        --arg ts "$(date -Iseconds)" \
        --arg sev "$severity" \
        --arg comp "$component" \
        --arg msg "$message" \
        --argjson meta "${metadata:-{}}" \
        '{timestamp: $ts, severity: $sev, component: $comp, message: $msg, metadata: $meta}' \
        >> "$MIGRATION_LOG_JSON"

    # Errors also go to error log
    [[ "$severity" == "ERROR" ]] || [[ "$severity" == "CRITICAL" ]] && \
        echo "[$(date -Iseconds)] [$component] $message" >> "$ERROR_LOG"
}
```

**Error Categories**:
| Category | Severity | Handling Strategy |
|----------|----------|------------------|
| Network timeout | WARNING | Retry 3x with backoff, then fail |
| Disk space insufficient | CRITICAL | Abort immediately, suggest cleanup |
| Dependency conflict | WARNING | Skip package, log for manual review |
| Snap alternative not found | INFO | Log, mark as non-migratable |
| Essential service detected | WARNING | Flag for manual review, do not auto-migrate |
| Rollback failure | CRITICAL | Log extensively, provide manual recovery steps |

## 9. Integration with Existing Infrastructure

### Decision: Extend existing script modules and test framework

**Rationale**:
- Repository already has modular script pattern (`scripts/.module-template.sh`)
- Testing framework established (`local-infra/tests/unit/.test-template.sh`)
- Local CI/CD infrastructure in place (`local-infra/runners/`)
- Consistency with existing codebase improves maintainability

**Integration Points**:

#### 9.1 Modular Script Structure
```bash
# scripts/audit_packages.sh follows .module-template.sh pattern
#!/bin/bash
set -euo pipefail

# Source common utilities
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/progress.sh"

# Module metadata
MODULE_NAME="audit_packages"
MODULE_VERSION="1.0.0"
MODULE_DESCRIPTION="Audit apt packages and identify snap alternatives"

# Module-specific functions
audit_packages() { ... }
```

#### 9.2 Local CI/CD Integration
```bash
# Add migration validation to local workflow
# File: local-infra/runners/gh-workflow-local.sh

case "$1" in
    "migrate-validate")
        echo "🔍 Validating package migration scripts..."
        ./local-infra/tests/unit/test_audit_packages.sh
        ./local-infra/tests/unit/test_migration_health_checks.sh
        ./local-infra/tests/unit/test_migration_backup.sh
        ./local-infra/tests/unit/test_migration_rollback.sh
        ;;
esac
```

#### 9.3 Performance Monitoring Extension
```bash
# Add migration metrics to performance monitoring
# File: local-infra/runners/performance-monitor.sh

monitor_migration_performance() {
    echo "📊 Monitoring package migration performance..."

    # Audit performance
    audit_time=$(time (./scripts/audit_packages.sh) 2>&1 | grep real | awk '{print $2}')

    # Store results
    jq -n \
        --arg audit_time "$audit_time" \
        '{migration_performance: {audit_time: $audit_time}}' \
        >> "./local-infra/logs/migration-performance-$(date +%s).json"
}
```

## 10. Security Considerations

### Decision: Principle of least privilege with explicit permission gates

**Rationale**:
- Package operations require sudo (unavoidable for system changes)
- Explicit user confirmation required before destructive operations
- Snap publisher verification prevents malicious package installation
- Audit trail for all operations supports security review

**Security Measures**:

#### 10.1 Privilege Minimization
```bash
# Only request sudo when necessary (not for audit operations)
if [[ "$operation" == "migrate" ]] || [[ "$operation" == "rollback" ]]; then
    if [[ $EUID -ne 0 ]]; then
        echo "Migration requires sudo privileges. Re-run with sudo."
        exit 1
    fi
fi
```

#### 10.2 Publisher Validation
```bash
# Verify snap publisher before installation
validate_publisher() {
    local snap_name="$1"
    local publisher_info=$(snap info "$snap_name" | grep 'publisher:')

    # Require verification badge or explicit user confirmation
    if ! echo "$publisher_info" | grep -q 'verified'; then
        echo "WARNING: $snap_name publisher not verified"
        read -p "Install anyway? (yes/no): " confirm
        [[ "$confirm" == "yes" ]] || return 1
    fi
}
```

#### 10.3 Audit Trail
```bash
# Log all package operations with sudo user tracking
log_package_operation() {
    local operation="$1"
    local package="$2"
    local result="$3"

    logger -t package-migration \
        "User: ${SUDO_USER:-$USER}, Operation: $operation, Package: $package, Result: $result"
}
```

**Security Best Practices**:
- Never auto-install snaps without user confirmation
- Validate .deb checksums before reinstallation
- Preserve file permissions during config migration
- Sanitize user input in search queries
- Rate-limit snap API calls to prevent DoS

## Summary of Key Decisions

| Area | Decision | Rationale |
|------|----------|-----------|
| **Dependency Resolution** | dpkg-query + apt-cache rdepends | Native tools, reliable, performant |
| **Snap API** | snapd REST API via Unix socket | Official, stable, no auth required |
| **Rollback** | Snapshot-based with .deb preservation | Offline capable, atomic, reliable |
| **Health Checks** | Multi-layer with severity levels | Comprehensive, actionable, safe |
| **Config Migration** | Heuristic path mapping | Best-effort, well-documented, safe |
| **Performance** | Parallel analysis + caching | Meets <2min audit, <30min migration |
| **Testing** | Three-tier (unit/integration/validation) | Comprehensive coverage, existing framework |
| **Logging** | Structured JSON + human-readable | Parseable, debuggable, auditable |
| **Integration** | Extend existing modules | Consistency, maintainability, proven patterns |
| **Security** | Least privilege + publisher validation | Minimizes risk, prevents malicious installs |

## Next Steps

With all technical unknowns resolved, proceed to:

1. **Phase 1**: Generate `data-model.md` (migration entities and state)
2. **Phase 1**: Generate `contracts/` (CLI interface specification)
3. **Phase 1**: Generate `quickstart.md` (user onboarding guide)
4. **Phase 1**: Update agent context with new technologies
5. **Phase 2**: Execute `/speckit.tasks` to generate implementation tasks
