---
title: "Dual-Mode Logging System Guide"
description: "The Ghostty Configuration Files repository implements a **dual-mode output system** that provides:"
pubDate: 2025-11-25
author: "Ghostty Config Team"
tags: ['developer', 'technical']
---

# Dual-Mode Logging System Guide

## Overview

The Ghostty Configuration Files repository implements a **dual-mode output system** that provides:

1. **Docker-like collapsed terminal output** (clean, professional user experience)
2. **Full verbose log files** (complete debugging information)

**Critical Principle**: ALL output is ALWAYS captured to log files regardless of terminal output mode.

## User Requirement

> "all logs captured in '/home/kkk/Apps/ghostty-config-files/logs' must be in full, extremely verbose regardless. this is to ensure full possible debugging. for end user, they must experience full Docker-like collapsing experience."

## Architecture

### Dual-Mode Output Flow

```
Command Execution
    ↓
┌─────────────────────────────────────────────┐
│ run_command_collapsible()                   │
│                                             │
│  Executes command with output capture       │
│                                             │
│  ┌────────────────┐    ┌──────────────┐   │
│  │ Terminal       │    │ Log Files    │   │
│  │ (User View)    │    │ (Debugging)  │   │
│  │                │    │              │   │
│  │ VERBOSE=false  │    │ VERBOSE=true │   │
│  │ Collapsed ✓    │    │ Full output  │   │
│  │ Docker-like    │    │ Every line   │   │
│  └────────────────┘    └──────────────┘   │
└─────────────────────────────────────────────┘
```

### Directory Structure

```
/home/kkk/Apps/ghostty-config-files/logs/
├── installation/
│   ├── start-20251121-201545.log          # Human-readable summary
│   ├── start-20251121-201545.log.json     # Structured JSON
│   └── start-20251121-201545-verbose.log  # FULL command output (debugging)
├── components/
│   ├── ghostty-20251121-201600.log        # Per-component logs
│   ├── zsh-20251121-201700.log
│   ├── python_uv-20251121-201800.log
│   ├── nodejs_fnm-20251121-201900.log
│   └── ai_tools-20251121-202000.log
└── errors.log                              # All errors (consolidated)
```

## Log File Types

### 1. Human-Readable Log (`start-TIMESTAMP.log`)

**Purpose**: Summary of installation with key events and status updates

**Content**:
- Installation start/end timestamps
- Task status updates (started, completed, failed)
- Success/error messages
- Component installation summaries
- Final status and next steps

**Example**:
```
[2025-11-21T20:15:00Z] INFO Logging system initialized (dual-mode output)
[2025-11-21T20:15:05Z] INFO Starting installation (8 tasks, parallel execution enabled)
[2025-11-21T20:15:10Z] INFO Step 1/9: Check Prerequisites (estimated: 5s)
[2025-11-21T20:15:15Z] SUCCESS Step 1/9 complete: Check Prerequisites (5s)
...
```

### 2. Verbose Debug Log (`start-TIMESTAMP-verbose.log`)

**Purpose**: COMPLETE command output for debugging (every byte captured)

**Content**:
- Full stdout/stderr from every command
- Complete curl download progress
- Full git clone output
- Complete build logs
- Every line from every script execution

**Example**:
```
================================
[2025-11-21 20:16:00] Downloading Zig Compiler
Command: curl -fsSL https://ziglang.org/download/0.14.0/zig-x86_64-linux-0.14.0.tar.xz -o /tmp/zig.tar.xz
================================
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  5 89.2M    5 4912k    0     0  2384k      0  0:00:38  0:00:02  0:00:36 2384k
 12 89.2M   12 11.1M    0     0  3704k      0  0:00:24  0:00:03  0:00:21 3704k
...
100 89.2M  100 89.2M    0     0  4512k      0  0:00:20  0:00:20 --:--:-- 5234k

================================
[2025-11-21 20:16:20] Extracting Zig Tarball
Command: tar -xJf /tmp/zig.tar.xz -C /home/user/Apps/
================================
zig-0.14.0/
zig-0.14.0/LICENSE
zig-0.14.0/README.md
... (EVERY file listed)
```

**CRITICAL**: This file contains ALL output regardless of VERBOSE_MODE setting.

### 3. Structured JSON Log (`start-TIMESTAMP.log.json`)

**Purpose**: Machine-readable structured log for parsing and analysis

**Content**:
- ISO8601 timestamps
- Log levels (TEST, INFO, SUCCESS, WARNING, ERROR)
- Structured message data

**Example**:
```json
[
  {
    "timestamp": "2025-11-21T20:15:00.123Z",
    "level": "INFO",
    "message": "Logging system initialized (dual-mode output)"
  },
  {
    "timestamp": "2025-11-21T20:15:05.456Z",
    "level": "INFO",
    "message": "Starting installation (8 tasks, parallel execution enabled)"
  },
  ...
]
```

### 4. Component Logs (`components/*.log`)

**Purpose**: Isolated logs for each component installation

**Content**:
- Per-component installation steps
- Component-specific output
- Easier debugging for specific component issues

**Example**: `ghostty-20251121-201600.log`

### 5. Error Log (`errors.log`)

**Purpose**: Consolidated error messages from all installations

**Content**:
- All ERROR-level log messages
- Aggregated across all installation runs
- Never rotated (preserved for historical debugging)

## Output Modes

### Default Mode (VERBOSE_MODE=false)

**Terminal Output** (Docker-like collapsed):
```bash
$ ./start.sh

╔═══════════════════════════════════════════════════════════╗
║          Ghostty Configuration Installation               ║
╚═══════════════════════════════════════════════════════════╝

✓ Prerequisites Check (2s)
✓ Install gum TUI Framework (5s)

╔═══════════════════════════════════════════════════════════╗
║              Installing Ghostty Terminal                  ║
╚═══════════════════════════════════════════════════════════╝

✓ Check Prerequisites (5s)
⠋ Downloading Zig Compiler...
✓ Downloaded Zig Compiler (30s)
✓ Extracted Zig Tarball (10s)
⠋ Cloning Ghostty Repository...
✓ Cloned Ghostty Repository (20s)
⠋ Building Ghostty...
✓ Built Ghostty (90s)
✓ Installed Ghostty Binary (10s)
✓ Configured Ghostty (10s)
✓ Created Desktop Entry (5s)
✓ Verified Installation (5s)

═══════════════════════════════════════════════════════════
✅ Ghostty Terminal installation SUCCESS (9/9 steps, 185s)
Detailed logs: ./logs/components/ghostty-20251121-201600.log
═══════════════════════════════════════════════════════════
```

**Log Files**: FULL verbose output captured to all log files

### Verbose Mode (VERBOSE_MODE=true)

**Terminal Output** (full output shown):
```bash
$ ./start.sh --verbose

... (all command output shown in real-time) ...

Cloning Ghostty repository...
Cloning into 'ghostty'...
remote: Enumerating objects: 15234, done.
remote: Counting objects: 100% (15234/15234), done.
remote: Compressing objects: 100% (5123/5123), done.
remote: Total 15234 (delta 9876), reused 14321 (delta 8901)
Receiving objects: 100% (15234/15234), 5.23 MiB | 2.34 MiB/s, done.
Resolving deltas: 100% (9876/9876), done.

... (continues with full output) ...
```

**Log Files**: Same FULL verbose output captured to all log files

## Implementation Details

### Core Functions

#### `log_command_output()` (lib/core/logging.sh)

```bash
#
# Log command output to verbose log file
#
# CRITICAL: ALWAYS logs to verbose log file regardless of VERBOSE_MODE
#
# Arguments:
#   $1 - Command description (e.g., "Downloading Zig Compiler")
#   $2 - Command output (from captured variable)
#
log_command_output() {
    local description="$1"
    local output="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Write to verbose log (ALWAYS)
    {
        echo "================================"
        echo "[$timestamp] $description"
        echo "================================"
        echo "$output"
        echo ""
    } >> "${VERBOSE_LOG_FILE}"
}
```

#### `run_command_collapsible()` (lib/ui/collapsible.sh)

```bash
#
# Run command with collapsible output
#
# CRITICAL: ALWAYS logs full output to verbose log file regardless of VERBOSE_MODE
#
run_command_collapsible() {
    local task_id="$1"
    shift
    local cmd=("$@")

    # Capture output to variable (for both terminal and logs)
    local output
    local exit_code=0
    local output_file=$(mktemp)

    # Execute command with output capture
    "${cmd[@]}" > "$output_file" 2>&1 || exit_code=$?

    # Read captured output
    output=$(cat "$output_file")

    # ALWAYS log full output to verbose log file (regardless of VERBOSE_MODE)
    log_command_output "$task_id: ${cmd[*]}" "$output"

    # Terminal display depends on VERBOSE_MODE
    if [ "$VERBOSE_MODE" = true ]; then
        # Show full output to terminal
        echo "$output"
    else
        # Show only collapsed summary (Docker-like)
        # Output already logged to verbose file
        :
    fi

    # Cleanup
    rm -f "$output_file"

    return $exit_code
}
```

### Configuration Variables

```bash
# lib/core/logging.sh
LOGGING_REPO_ROOT="${REPO_ROOT:-...}"
LOG_DIR="${LOGGING_REPO_ROOT}/logs/installation"
LOG_FILE=""                    # Human-readable summary
LOG_FILE_JSON=""               # Structured JSON
VERBOSE_LOG_FILE=""            # FULL verbose output (NEW)
ERROR_LOG="${LOGGING_REPO_ROOT}/logs/errors.log"

# lib/ui/collapsible.sh
VERBOSE_MODE=${VERBOSE_MODE:-false}  # Default: Docker-like collapsed
```

## Usage Examples

### Installation with Default Mode (Collapsed Output)

```bash
./start.sh

# Terminal: Clean Docker-like collapsed output
# Log files: FULL verbose output
```

### Installation with Verbose Mode

```bash
./start.sh --verbose

# Terminal: Full output shown in real-time
# Log files: Same FULL verbose output
```

### Display Log Locations After Installation

```bash
./start.sh --show-logs

# Shows:
# - Main installation log
# - Verbose debug log
# - Structured JSON log
# - Component logs
# - Error log
```

### View Full Verbose Logs After Installation

```bash
# View verbose log from latest installation
less logs/installation/start-*-verbose.log | tail -1

# View specific component log
less logs/components/ghostty-*.log | tail -1

# Search for errors in verbose log
grep -i error logs/installation/start-*-verbose.log | tail -1
```

## Log Rotation

### Automatic Rotation

- **Trigger**: More than 10 installation runs OR files >50MB
- **Action**: Remove oldest log files (keeping last 10)
- **Scope**: Applies to all log types (human-readable, verbose, JSON)

### Manual Cleanup

```bash
# Remove all logs (keep directory structure)
rm -f logs/installation/*.log logs/installation/*.json
rm -f logs/components/*.log

# Remove logs older than 30 days
find logs/ -name "*.log" -mtime +30 -delete
```

## Troubleshooting

### Problem: Log files not created

**Solution**: Ensure REPO_ROOT is set correctly

```bash
# Check REPO_ROOT
echo $REPO_ROOT

# If empty, set manually
export REPO_ROOT="/home/kkk/Apps/ghostty-config-files"
./start.sh
```

### Problem: Verbose log file missing output

**Cause**: VERBOSE_LOG_FILE not initialized

**Solution**: Ensure init_logging() called before any command execution

```bash
# In start.sh main()
init_logging                  # MUST be called first
init_collapsible_output       # Then UI initialization
```

### Problem: Output not captured to logs

**Cause**: Command not using run_command_collapsible()

**Solution**: Update command to use collapsible wrapper

```bash
# Before (output not captured):
git clone https://github.com/example/repo

# After (output captured):
run_command_collapsible "clone-repo" git clone https://github.com/example/repo
```

## Testing

### Validate Logging System

```bash
# Test syntax
bash -n lib/core/logging.sh

# Test verbose log capture
source lib/core/logging.sh
init_logging
log_command_output "Test command" "Test output line 1\nTest output line 2"
cat "$(get_verbose_log_file)"

# Expected output:
# ================================
# [TIMESTAMP] Test command
# ================================
# Test output line 1
# Test output line 2
```

### Integration Test

```bash
# Run installation with verbose mode
./start.sh --verbose

# Verify log files created
ls -lh logs/installation/
ls -lh logs/components/

# Verify verbose log contains full output
grep -c "Cloning into" logs/installation/start-*-verbose.log | tail -1

# Should show count > 0 (command output captured)
```

## Best Practices

### For Component Developers

1. **Always use run_command_collapsible()** for command execution
2. **Provide descriptive task IDs** (e.g., "download-zig", not "task-1")
3. **Log command intent** before execution for context
4. **Never suppress stderr** (always capture 2>&1)

### For Debugging

1. **Start with human-readable log** for overview
2. **Use verbose log** for complete command output
3. **Check component logs** for isolated issues
4. **Search errors.log** for ERROR-level messages
5. **Use JSON log** for automated parsing/analysis

### For Users

1. **Default mode is best** for normal installation
2. **Use --verbose** only for troubleshooting
3. **Save verbose logs** before reporting issues
4. **Use --show-logs** to find log locations easily

## Constitutional Compliance

- **User Requirement**: "all logs captured in full, extremely verbose regardless"
  - ✅ ACHIEVED: log_command_output() ALWAYS captures full output

- **User Experience**: "end user must experience full Docker-like collapsing experience"
  - ✅ ACHIEVED: VERBOSE_MODE=false by default, clean collapsed output

- **Principle VII**: Structured Logging
  - ✅ ACHIEVED: Dual-format (JSON + human-readable)

## References

- [lib/core/logging.sh](/home/kkk/Apps/ghostty-config-files/lib/core/logging.sh) - Logging infrastructure
- [lib/ui/collapsible.sh](/home/kkk/Apps/ghostty-config-files/lib/ui/collapsible.sh) - Collapsible output system
- [lib/installers/common/manager-runner.sh](/home/kkk/Apps/ghostty-config-files/lib/installers/common/manager-runner.sh) - Component manager wrapper
- [start.sh](/home/kkk/Apps/ghostty-config-files/start.sh) - Installation orchestrator

---

**Version**: 1.0
**Last Updated**: 2025-11-21
**Status**: ACTIVE - PRODUCTION READY
