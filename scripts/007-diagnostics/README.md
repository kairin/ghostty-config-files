# Boot Diagnostics

**Last Updated**: 2026-01-18
**Purpose**: System health checks and automatic boot issue detection

## Overview

Boot diagnostics provide automated detection and remediation of common Ubuntu boot issues. The system uses pattern matching against journal logs and system state queries - no LLM required.

## Directory Structure

```
007-diagnostics/
├── boot_diagnostics.sh     # Full TUI diagnostic scan with fix options
├── quick_scan.sh           # Fast scan for startup banner integration
├── detectors/              # Individual issue detectors
│   ├── detect_cosmetic_warnings.sh
│   ├── detect_failed_services.sh
│   ├── detect_network_wait_issues.sh
│   ├── detect_orphaned_services.sh
│   └── detect_unsupported_snaps.sh
└── lib/                    # Shared utilities
    ├── fix_executor.sh     # Execute fixes for detected issues
    └── issue_registry.sh   # Pattern definitions and severity levels
```

## Usage

### Quick Scan (Fast)

Non-interactive scan that outputs issue counts. Used by `start.sh` for startup banner warnings.

```bash
./scripts/007-diagnostics/quick_scan.sh
```

Output modes:
```bash
./scripts/007-diagnostics/quick_scan.sh count     # Just actionable issue count
./scripts/007-diagnostics/quick_scan.sh summary   # CRITICAL:n MODERATE:n LOW:n
./scripts/007-diagnostics/quick_scan.sh details   # Full issue list
```

### Full Diagnostics (Interactive TUI)

Interactive TUI with issue details and fix options. Requires `gum` to be installed.

```bash
./scripts/007-diagnostics/boot_diagnostics.sh
```

Features:
- Visual display of detected issues by severity
- Select which issues to fix
- Preview fixes before applying
- Automatic fix execution with confirmation

## What Gets Checked

### Critical Issues

| Issue Type | Detection | Fixable |
|------------|-----------|---------|
| Unsupported Snaps | Snaps incompatible with Ubuntu version | Yes |
| Orphaned Services | Services referencing missing executables | Yes |
| Failed Services | Services that failed to start | Maybe |

### Moderate Issues

| Issue Type | Detection | Fixable |
|------------|-----------|---------|
| Network Wait Timeout | Network service timing out at boot | Yes |

### Low/Cosmetic Issues

| Issue Type | Detection | Fixable | Notes |
|------------|-----------|---------|-------|
| ALSA GOTO warnings | Known packaging bug (Ubuntu #2105475) | No | Harmless |
| GNOME keyring timing | Daemon control file message | No | Normal |
| SCSI device ID | Loop devices from snaps | No | Normal |
| SATA resume errors | Empty motherboard ports | No | Normal |
| Kernel taint | Proprietary drivers (NVIDIA) | No | Expected |
| Bluetooth HCI | Driver limitation | No | Minor |

## Detectors

### detect_cosmetic_warnings.sh

Scans journal for known cosmetic warnings that can be safely ignored. Helps distinguish real issues from noise.

### detect_failed_services.sh

Identifies systemd services that failed to start. Checks both system and user services.

### detect_network_wait_issues.sh

Detects `NetworkManager-wait-online.service` and similar services causing boot delays.

### detect_orphaned_services.sh

Finds services referencing executables that no longer exist (common after partial uninstalls).

### detect_unsupported_snaps.sh

Identifies snaps that are incompatible with the current Ubuntu version (e.g., Canonical Livepatch on non-LTS).

## Library Components

### issue_registry.sh

Defines known patterns and their classifications:
- Severity levels: CRITICAL, MODERATE, LOW
- Issue types: ORPHANED_SERVICE, UNSUPPORTED_SNAP, NETWORK_WAIT, FAILED_SERVICE, COSMETIC
- Journal pattern matching rules
- Ubuntu version-specific snap issues

### fix_executor.sh

Executes remediation actions for detected issues:
- Disables orphaned services
- Removes unsupported snaps
- Adjusts network wait timeouts
- All fixes require user confirmation

## Integration

### With start.sh

The quick scan integrates with the project's startup TUI:

```bash
# In start.sh
issue_count=$(./scripts/007-diagnostics/quick_scan.sh count)
if [[ "$issue_count" -gt 0 ]]; then
    show_warning_banner
fi
```

### Manual Invocation

Access from the main scripts directory:

```bash
./scripts/007-diagnostics/boot_diagnostics.sh
```

Or via the TUI menu by selecting "Boot Diagnostics" from `./start.sh`.

## Related Documentation

- [Scripts Directory Index](../README.md) - Complete scripts reference
- [System Architecture](../../.claude/instructions-for-agents/architecture/system-architecture.md) - System overview
