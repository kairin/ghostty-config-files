# Quick Start Guide: Package Migration Tool

**Date**: 2025-11-09
**Feature**: 005-apt-snap-migration
**Estimated Time**: 5-10 minutes for audit, 10-30 minutes for full migration

## Overview

This guide walks you through safely migrating Ubuntu packages from apt to snap. The tool prioritizes **zero system breakage** through comprehensive checks, backups, and rollback capability.

---

## Prerequisites

Before starting, ensure you have:

- ✅ **Ubuntu 16.04+** (snap support required, tested on Ubuntu 25.10)
- ✅ **sudo/root privileges** (required for package operations)
- ✅ **Network connectivity** (snap store access needed)
- ✅ **Sufficient disk space** (at least 10GB free for migration + backups)
- ✅ **snapd installed** (will be auto-installed if missing with your permission)

### Quick Prerequisites Check

```bash
# Check Ubuntu version
lsb_release -a

# Check disk space
df -h / /home

# Check snapd status
systemctl status snapd.service

# If snapd is not installed:
sudo apt update && sudo apt install snapd
```

---

## Installation

### 1. Clone Repository (if not already done)

```bash
cd /home/$USER/Apps
git clone https://github.com/your-username/ghostty-config-files.git
cd ghostty-config-files
```

### 2. Verify Scripts Are Executable

```bash
chmod +x scripts/package_migration.sh
chmod +x scripts/audit_packages.sh
chmod +x scripts/migration_health_checks.sh
chmod +x scripts/migration_backup.sh
chmod +x scripts/migration_rollback.sh
```

### 3. Add Scripts to PATH (Optional)

```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$PATH:/home/'"$USER"'/Apps/ghostty-config-files/scripts"' >> ~/.bashrc
source ~/.bashrc

# Now you can run from anywhere:
package_migration.sh audit
```

---

## Quick Start: 5-Minute Test Migration

This walkthrough demonstrates the complete migration flow using a safe, non-critical package (htop).

### Step 1: Run Audit (30 seconds)

Identify packages that can be migrated to snap.

```bash
cd /home/$USER/Apps/ghostty-config-files
./scripts/package_migration.sh audit
```

**Expected Output**:
```
Package Migration Audit Report
Generated: 2025-11-09 14:30:00

MIGRATABLE PACKAGES (5 found):
┌──────────────────┬─────────────┬─────────────┬──────────────────┬──────────┬──────┐
│ Package          │ apt Version │ snap Version│ Equivalence      │ Risk     │ Priority
├──────────────────┼─────────────┼─────────────┼──────────────────┼──────────┼──────┤
│ htop             │ 3.2.2-1     │ 3.2.2       │ 100% (perfect)   │ low      │ 900  │
│ chromium-browser │ 119.0.6045  │ 119.0.6045  │ 95% (excellent)  │ low      │ 800  │
│ firefox          │ 120.0-1     │ 120.0       │ 92% (excellent)  │ low      │ 750  │
└──────────────────┴─────────────┴─────────────┴──────────────────┴──────────┴──────┘

SUMMARY:
  Total packages (apt): 147
  Migratable: 5
  Blocked: 2
  No snap alternative: 140
```

**What This Tells You**:
- **htop** is an excellent candidate (100% equivalence, low risk, highest priority)
- **chromium** and **firefox** are also safe to migrate
- 2 packages are blocked (likely essential system packages)
- 140 packages don't have snap alternatives (will remain as apt)

### Step 2: Run Health Checks (10 seconds)

Verify system is ready for migration.

```bash
./scripts/package_migration.sh health
```

**Expected Output (Success)**:
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

✅ PASS [CRITICAL] snapd Service Status
   Measured: active (running)
   Required: active (running)
   Status: snapd daemon healthy

OVERALL RESULT: ✅ PASSED
All critical checks passed. System ready for migration.
```

**If Health Checks Fail**:
```bash
# Common fix: Start snapd service
sudo systemctl start snapd.service
sudo systemctl enable snapd.service

# Re-run health checks
./scripts/package_migration.sh health
```

### Step 3: Test Migration with Dry Run (5 seconds)

Preview the migration without making changes.

```bash
./scripts/package_migration.sh migrate htop --dry-run
```

**Expected Output**:
```
Migration Plan (Dry Run - No Changes Will Be Made)
Backup ID: 20251109-143000 (will be created)

Migration Order (1 package):
1. htop (priority: 900, risk: low, dependencies: 0)
   apt: htop 3.2.2-1 → snap: htop 3.2.2
   Estimated time: <1 minute

Total estimated time: <1 minute
Total download size: ~5MB
Total installed size after migration: ~12MB

To proceed with migration, run:
  ./scripts/package_migration.sh migrate htop
```

### Step 4: Perform Actual Migration (1-2 minutes)

Migrate htop from apt to snap.

```bash
./scripts/package_migration.sh migrate htop
```

**Expected Output**:
```
Package Migration Starting
Backup ID: 20251109-143000

✅ Pre-Migration Health Checks: PASSED
✅ Backup Created: /home/user/.config/package-migration/backups/20251109-143000

Migration Progress (1 package in queue):

[1/1] Migrating: htop
  ⏳ Downloading .deb backup... ✅ Done (2.3MB)
  ⏳ Uninstalling apt package... ✅ Done
  ⏳ Installing snap alternative... ✅ Done (5.1MB download, 12.3MB installed)
  ⏳ Verifying functionality... ✅ Command available: htop --version
  ✅ Migration successful (45 seconds)

Migration Summary:
  ✅ Successful: 1 (htop)
  ❌ Failed: 0

Rollback available: ./scripts/package_migration.sh rollback 20251109-143000
```

### Step 5: Verify htop Works (10 seconds)

Test that the migrated package functions correctly.

```bash
# Check command is available
which htop
# Expected: /snap/bin/htop

# Run htop to verify functionality
htop --version
# Expected: htop 3.2.2

# (Optional) Run htop interactively
htop
# Press 'q' to quit
```

### Step 6: Check Migration Status (5 seconds)

View current migration status.

```bash
./scripts/package_migration.sh status
```

**Expected Output**:
```
Package Migration Status
Last audit: 2025-11-09 14:30:00
Last migration: 2025-11-09 14:35:00

Statistics:
  Total packages installed: 147
    ├─ apt: 146 (99.3%)
    └─ snap: 1 (0.7%)

  Migration status:
    ├─ Successful migrations: 1
    ├─ Failed migrations: 0
    └─ Rollbacks performed: 0

  Active backup: 20251109-143000
    ├─ Created: 2025-11-09 14:30:00
    ├─ Packages: 1
    └─ Size: 2.3MB

Next recommended action: Migrate additional packages (chromium-browser, firefox)
  Command: ./scripts/package_migration.sh migrate chromium-browser firefox
```

### Step 7: (Optional) Test Rollback (1-2 minutes)

Practice rolling back to ensure the safety mechanism works.

```bash
# Rollback htop to apt version
./scripts/package_migration.sh rollback 20251109-143000 htop
```

**Expected Output**:
```
Rollback Starting
Backup ID: 20251109-143000
Packages to rollback: 1 (htop)

✅ Backup Verified: All .deb files present and valid

Rollback Progress:

[1/1] Rolling back: htop
  ⏳ Removing snap package... ✅ Done
  ⏳ Reinstalling apt package... ✅ Done (htop 3.2.2-1 installed)
  ⏳ Verifying functionality... ✅ Command available: htop --version
  ✅ Rollback successful (18 seconds)

Rollback Summary:
  ✅ Successful: 1 (htop)
  ❌ Failed: 0

System restored to state as of: 2025-11-09 14:30:00
```

**Verify Rollback**:
```bash
which htop
# Expected: /usr/bin/htop (apt version restored)

htop --version
# Expected: htop 3.2.2-1 (apt version)
```

---

## Production Migration Workflow

Once comfortable with the test migration, follow this workflow for migrating multiple packages.

### Phase 1: Non-Critical Packages (Low Risk)

Migrate user applications first to build confidence.

```bash
# Audit to identify non-critical packages
./scripts/package_migration.sh audit --low-risk --migratable-only

# Migrate in small batches
./scripts/package_migration.sh migrate chromium-browser firefox vlc --batch-size 1

# Verify each package works before proceeding
chromium-browser --version
firefox --version
vlc --version
```

### Phase 2: Development Tools (Medium Risk)

Migrate development tools after non-critical packages succeed.

```bash
# Identify development tools
./scripts/package_migration.sh audit | grep -E 'code|git|node|python'

# Migrate selectively
./scripts/package_migration.sh migrate vscode gimp inkscape
```

### Phase 3: System-Wide Migration (Use with Caution)

Only after successful testing on non-critical packages.

```bash
# Dry run for full migration
./scripts/package_migration.sh migrate --all --dry-run

# Review the plan carefully, then proceed
./scripts/package_migration.sh migrate --all --interactive
# (Interactive mode asks for confirmation before each package)

# OR: Migrate all at once (requires confidence)
./scripts/package_migration.sh migrate --all
```

---

## Common Use Cases

### Use Case 1: Migrate Specific Packages

```bash
# Migrate browser and media player
./scripts/package_migration.sh migrate firefox vlc

# Verify functionality
firefox --version
vlc --version
```

### Use Case 2: Migrate Only High-Priority Packages

```bash
# Show high-priority candidates
./scripts/package_migration.sh audit --high-priority

# Migrate packages with priority >= 700
./scripts/package_migration.sh migrate --all --priority-threshold 700
```

### Use Case 3: Migrate with Interactive Confirmation

```bash
# Ask for confirmation before each package
./scripts/package_migration.sh migrate --all --interactive
```

**Example Interaction**:
```
About to migrate: chromium-browser (119.0.6045)
  apt → snap (equivalence: 95%, risk: low)
  Estimated time: 2-3 minutes

Proceed with this migration? (yes/no/skip):
```

### Use Case 4: Emergency Rollback

```bash
# If migration causes issues, rollback immediately

# Rollback latest migration
./scripts/package_migration.sh rollback latest --all

# OR: Rollback specific package
./scripts/package_migration.sh rollback latest firefox

# Verify system is restored
./scripts/package_migration.sh status
```

---

## Troubleshooting

### Issue: "snapd daemon not running"

**Symptom**:
```
❌ FAIL [CRITICAL] snapd Service Status
   Measured: inactive (dead)
   Required: active (running)
```

**Solution**:
```bash
# Start and enable snapd
sudo systemctl start snapd.service
sudo systemctl enable snapd.service

# Verify it's running
systemctl status snapd.service

# Re-run health checks
./scripts/package_migration.sh health
```

---

### Issue: "Insufficient disk space"

**Symptom**:
```
❌ FAIL [CRITICAL] Disk Space (Root Partition)
   Measured: 3.2GB available
   Required: 10GB minimum
```

**Solution**:
```bash
# Check current disk usage
df -h

# Clean up apt cache
sudo apt clean
sudo apt autoclean

# Clean up old backups
./scripts/package_migration.sh cleanup --backups

# Remove unused snap revisions
snap list --all | awk '/disabled/{print $1, $3}' | \
    while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done

# Re-check disk space
df -h
```

---

### Issue: "Network timeout (snap store unreachable)"

**Symptom**:
```
❌ ERROR [E003]: Network timeout (snap store)
  Cause: Failed to reach snap store API after 30 seconds
```

**Solution**:
```bash
# Test network connectivity
ping -c 3 api.snapcraft.io

# If DNS fails, check DNS configuration
cat /etc/resolv.conf

# Test snap store directly
curl -sS --max-time 5 https://api.snapcraft.io/v2/snaps/info/core

# Check firewall rules (if applicable)
sudo ufw status

# Retry migration after resolving network issues
./scripts/package_migration.sh migrate <package-name>
```

---

### Issue: Migration failed, how to rollback?

**Symptom**:
```
❌ Migration failed (1m 34s)
   Error: <some error message>
```

**Solution**:
```bash
# Check migration status to get backup ID
./scripts/package_migration.sh status

# Rollback using the backup ID shown
./scripts/package_migration.sh rollback <backup-id> --all

# OR: Rollback just the failed package
./scripts/package_migration.sh rollback <backup-id> <package-name>

# Verify system is restored
./scripts/package_migration.sh status
```

---

### Issue: Package configurations not migrated

**Symptom**:
After migration, application settings/preferences are reset to defaults.

**Solution**:
```bash
# Check backup to see if configs were captured
ls -la ~/.config/package-migration/backups/<backup-id>/configs/

# Manually copy configs to snap-specific location
# (Snap apps use ~/snap/<app>/current/ for configs)

# Example for Firefox:
cp -r ~/.config/package-migration/backups/<backup-id>/configs/firefox/ \
      ~/snap/firefox/current/.mozilla/firefox/

# Restart the application
snap restart firefox
```

---

## Best Practices

### ✅ DO

- **Start with non-critical packages** (htop, tree, jq) to test the workflow
- **Run dry-run first** before actual migration (`--dry-run` flag)
- **Verify health checks pass** before starting migration
- **Test migrated packages** after migration to ensure functionality
- **Keep backups** for at least 30 days (default retention)
- **Monitor disk space** during migration (requires space for both apt and snap)
- **Use interactive mode** for important packages (`--interactive` flag)

### ❌ DON'T

- **Don't migrate essential system packages** (systemd, network-manager, boot dependencies)
- **Don't skip health checks** (`--skip-health-checks` is dangerous)
- **Don't skip backups** (`--skip-backup` prevents rollback)
- **Don't delete backups immediately** (keep for at least 30 days)
- **Don't force migrations** if warnings appear without understanding the risk
- **Don't migrate during critical work** (schedule during maintenance window)
- **Don't migrate without network** (snap installations require internet)

---

## Performance Expectations

### Timing Estimates

| Operation | Small Package (htop) | Medium Package (Firefox) | Large Package (Chromium) |
|-----------|---------------------|-------------------------|-------------------------|
| **Audit** | 30 seconds | 30 seconds | 30 seconds |
| **Health Checks** | 10 seconds | 10 seconds | 10 seconds |
| **Backup Creation** | 15 seconds | 45 seconds | 90 seconds |
| **Migration** | 45 seconds | 2-3 minutes | 3-5 minutes |
| **Rollback** | 20 seconds | 1-2 minutes | 2-3 minutes |

### Disk Space Requirements

| Scenario | Disk Space Needed |
|----------|------------------|
| **Audit only** | ~10MB (cache files) |
| **Single package migration** | Package size × 2.5 (apt + snap + backup) |
| **10 package migration** | Total package size × 2.5 + 1GB buffer |
| **Full system migration** | Total package size × 2.5 + 5GB buffer |

**Example Calculation**:
- Firefox apt: 98MB
- Firefox snap: 95MB
- Backup overhead: 20MB
- **Total**: ~215MB (98 + 95 + 20 + margin)

---

## Integration with Local CI/CD

### Run Migration Tests Locally

```bash
# Validate migration scripts before committing
./local-infra/runners/gh-workflow-local.sh migrate-validate

# Run performance monitoring
./local-infra/runners/performance-monitor.sh

# Execute full test suite
./local-infra/runners/test-runner.sh
```

### Add to Git Workflow

```bash
# After successful migration, commit changes
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-package-migration"

git checkout -b "$BRANCH_NAME"
git add .
git commit -m "feat: Complete package migration (htop, firefox, chromium)

- Migrated 3 packages from apt to snap
- All health checks passed
- Functional verification successful
- Backup ID: 20251109-143000

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"

git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main
```

---

## Next Steps

After completing your first successful migration:

1. **Explore Advanced Options**
   - Read the full [CLI Interface Specification](./contracts/cli-interface.md)
   - Review [Data Model Documentation](./data-model.md)
   - Study [Research & Best Practices](./research.md)

2. **Migrate Additional Packages**
   - Run `./scripts/package_migration.sh audit --migratable-only`
   - Migrate in batches using `--batch-size` option
   - Monitor with `./scripts/package_migration.sh status`

3. **Automate Regular Audits**
   ```bash
   # Add to crontab for weekly audits
   0 9 * * 0 cd /home/$USER/Apps/ghostty-config-files && ./scripts/package_migration.sh audit --no-cache
   ```

4. **Configure Custom Settings**
   - Edit `~/.config/package-migration/config.json`
   - Adjust retention period, batch size, priority thresholds
   - See [Configuration File Schema](./contracts/cli-interface.md#configuration-file)

---

## Support & Feedback

### Getting Help

```bash
# View help for main command
./scripts/package_migration.sh --help

# View help for specific subcommand
./scripts/package_migration.sh migrate --help
./scripts/package_migration.sh rollback --help
```

### Reporting Issues

If you encounter issues:

1. **Check logs**:
   ```bash
   ls -la /tmp/ghostty-start-logs/
   cat /tmp/ghostty-start-logs/migration-errors.log
   ```

2. **Verify system state**:
   ```bash
   ./scripts/package_migration.sh status --detailed
   ```

3. **Save complete logs** and report issue with:
   - Error message
   - Migration log file
   - System state JSON
   - Steps to reproduce

### Documentation

- **[Feature Specification](./spec.md)** - Complete requirements and success criteria
- **[Implementation Plan](./plan.md)** - Technical architecture and design decisions
- **[CLI Reference](./contracts/cli-interface.md)** - Full command-line documentation
- **[Data Model](./data-model.md)** - Entity schemas and relationships
- **[Research Notes](./research.md)** - Technical decisions and alternatives considered

---

**Happy Migrating! 🚀**

Remember: Safety first. Always start with non-critical packages and verify backups work before migrating important applications.
