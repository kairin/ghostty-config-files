# Data Model: Modern TUI Installation System

**Date**: 2025-11-18
**Phase**: Phase 1 - Design
**Status**: Complete

## Overview

This document defines the core data structures and entities used in the Modern TUI Installation System. All entities use JSON serialization for state persistence and logging.

## Entity Relationship Diagram

```
┌───────────────────┐
│  Installation     │
│  Task             │  1        *  ┌───────────────────┐
│                   │──────────────▶│  Verification     │
│ - id              │              │  Result           │
│ - name            │              │ - task_name       │
│ - verify_function │              │ - exit_code       │
│ - dependencies[]  │              │ - success         │
└───────────────────┘              └───────────────────┘
         │
         │ *
         │
         │ contains
         │
         ▼ 1
┌───────────────────┐
│  Installation     │
│  State            │              ┌───────────────────┐
│                   │  1        1  │  System State     │
│ - completed[]     │──────────────▶│  Snapshot         │
│ - failed[]        │              │ - timestamp       │
│ - performance     │              │ - os_info         │
└───────────────────┘              │ - disk_usage      │
                                   └───────────────────┘
```

## Core Entities

### 1. Installation Task

Represents a single installation step with verification and dependencies.

**Properties**:
```typescript
interface InstallationTask {
    id: string;                      // Unique identifier (e.g., "install-ghostty")
    name: string;                    // Human-readable name
    description: string;             // Detailed description
    install_function: string;        // Function name (e.g., "task_install_ghostty")
    verify_function: string;         // Verification function name
    dependencies: string[];          // Array of prerequisite task IDs
    estimated_duration: number;      // Expected seconds
    status: TaskStatus;              // Current state
    actual_duration?: number;        // Actual seconds (after completion)
    error_message?: string;          // Error details (if failed)
    start_time?: string;             // ISO8601 timestamp
    end_time?: string;               // ISO8601 timestamp
}

enum TaskStatus {
    PENDING = "pending",           // Not yet started
    RUNNING = "running",           // Currently executing
    SUCCESS = "success",           // Completed successfully
    FAILED = "failed",             // Execution failed
    SKIPPED = "skipped"            // Already completed (idempotency)
}
```

**State Transitions**:
```
PENDING ──▶ RUNNING ──▶ SUCCESS
               │
               └────▶ FAILED
               
(PENDING can also transition directly to SKIPPED if already completed)
```

**JSON Example**:
```json
{
  "id": "install-ghostty",
  "name": "Install Ghostty from source",
  "description": "Clone Ghostty repository and build with Zig 0.14.0+",
  "install_function": "task_install_ghostty",
  "verify_function": "verify_ghostty_installed",
  "dependencies": ["install-system-deps"],
  "estimated_duration": 60,
  "status": "success",
  "actual_duration": 45.7,
  "start_time": "2025-11-18T10:30:15Z",
  "end_time": "2025-11-18T10:31:00Z"
}
```

**Lifecycle**:
1. **Define**: Task registered with id, name, functions, dependencies
2. **Validate**: Dependencies checked, topological sort performed
3. **Execute**: install_function() runs, output captured
4. **Verify**: verify_function() checks actual system state
5. **Complete**: Mark success/failed in state file

---

### 2. System State Snapshot

Captures complete system state at specific points (before/after installation).

**Properties**:
```typescript
interface SystemStateSnapshot {
    timestamp: string;                 // ISO8601 timestamp
    hostname: string;                  // System hostname
    os_info: {
        name: string;                  // OS name (e.g., "Ubuntu 25.10")
        version: string;               // OS version
        kernel: string;                // Kernel version (e.g., "6.17.0-6-generic")
        architecture: string;          // CPU architecture (e.g., "x86_64")
    };
    installed_packages: {
        [package_name: string]: {
            version: string;
            installation_method: string;  // "apt", "snap", "source", "npm", etc.
        };
    };
    disk_usage: {
        total_gb: number;
        available_gb: number;
        used_gb: number;
        percent_used: number;
    };
    memory_usage: {
        total_mb: number;
        available_mb: number;
        used_mb: number;
        percent_used: number;
    };
    active_services: string[];        // Running systemd services
}
```

**Usage**:
- Captured BEFORE installation begins
- Captured AFTER installation completes
- Used for before/after comparison and debugging
- Stored in `/tmp/ghostty-start-logs/system_state_TIMESTAMP.json`

**JSON Example**:
```json
{
  "timestamp": "2025-11-18T10:30:00Z",
  "hostname": "ghostty-test",
  "os_info": {
    "name": "Ubuntu 25.10",
    "version": "25.10",
    "kernel": "6.17.0-6-generic",
    "architecture": "x86_64"
  },
  "installed_packages": {
    "ghostty": {
      "version": "1.1.4",
      "installation_method": "source"
    },
    "node": {
      "version": "25.2.0",
      "installation_method": "fnm"
    }
  },
  "disk_usage": {
    "total_gb": 256,
    "available_gb": 180,
    "used_gb": 76,
    "percent_used": 30
  },
  "memory_usage": {
    "total_mb": 16384,
    "available_mb": 8192,
    "used_mb": 8192,
    "percent_used": 50
  },
  "active_services": ["NetworkManager", "systemd-resolved", "ssh"]
}
```

---

### 3. Verification Result

Outcome of running a verification function (real system state check).

**Properties**:
```typescript
interface VerificationResult {
    task_name: string;                 // Associated task (e.g., "install-ghostty")
    verify_function: string;           // Function name (e.g., "verify_ghostty_installed")
    exit_code: number;                 // 0 = success, 1 = failure
    stdout: string;                    // Captured standard output
    stderr: string;                    // Captured standard error
    duration: number;                  // Execution time in seconds
    timestamp: string;                 // ISO8601 timestamp
    success: boolean;                  // exit_code === 0
    error_diagnostics?: {
        what_failed: string;           // Component that failed
        why_failed: string;            // Root cause analysis
        how_to_fix: string;            // Recovery suggestions
    };
}
```

**Multi-Layer Types**:
```typescript
interface UnitTestResult extends VerificationResult {
    component: string;                 // Single component (e.g., "ghostty", "fnm")
    tests_run: string[];               // Individual tests executed
}

interface IntegrationTestResult extends VerificationResult {
    components: string[];              // Multiple components tested together
    cross_component_checks: string[];  // Integration validations
}

interface HealthCheckResult extends VerificationResult {
    check_type: "pre" | "post";       // Pre-installation or post-installation
    checks_passed: number;
    checks_failed: number;
    critical_failures: string[];       // Blocking issues
    warnings: string[];                // Non-blocking concerns
}
```

**JSON Example (Unit Test)**:
```json
{
  "task_name": "install-ghostty",
  "verify_function": "verify_ghostty_installed",
  "exit_code": 0,
  "stdout": "✓ Ghostty binary exists\n✓ Ghostty version: 1.1.4\n✓ Configuration valid",
  "stderr": "",
  "duration": 1.2,
  "timestamp": "2025-11-18T10:31:01Z",
  "success": true,
  "component": "ghostty",
  "tests_run": [
    "binary_exists",
    "binary_executable",
    "version_check",
    "config_validation",
    "shared_libraries"
  ]
}
```

**JSON Example (Failed Verification)**:
```json
{
  "task_name": "install-nodejs",
  "verify_function": "verify_fnm_performance",
  "exit_code": 1,
  "stdout": "",
  "stderr": "fnm startup: 62ms (>50ms ✗ CONSTITUTIONAL VIOLATION)",
  "duration": 0.5,
  "timestamp": "2025-11-18T10:32:15Z",
  "success": false,
  "error_diagnostics": {
    "what_failed": "fnm performance benchmark",
    "why_failed": "fnm startup time exceeded 50ms constitutional requirement",
    "how_to_fix": "Check system load, verify fnm binary not on slow filesystem, consider reinstalling fnm"
  }
}
```

---

### 4. Installation State (Resume)

Persistent state for interrupt recovery and idempotency.

**Properties**:
```typescript
interface InstallationState {
    version: string;                   // State schema version (e.g., "2.0")
    started: string;                   // ISO8601 timestamp of first start
    last_run: string;                  // ISO8601 timestamp of last execution
    completed_tasks: string[];         // Array of completed task IDs
    failed_tasks: FailedTask[];        // Array of failed tasks with errors
    skipped_tasks: string[];           // Array of skipped task IDs (already installed)
    system_info: SystemInfo;           // Basic system identification
    performance: PerformanceMetrics;   // Timing data
}

interface FailedTask {
    task_id: string;
    error_message: string;
    timestamp: string;
    retry_count: number;
}

interface SystemInfo {
    os: string;
    kernel: string;
    architecture: string;
    hostname: string;
}

interface PerformanceMetrics {
    total_duration: number;            // Total installation time in seconds
    task_durations: {
        [task_id: string]: number;     // Per-task timing
    };
}
```

**State File Location**: `/tmp/ghostty-start-logs/installation-state.json`

**Persistence Rules**:
1. State file created on first run
2. Updated after each task completion/failure
3. Read on subsequent runs for idempotency
4. Tasks in `completed_tasks[]` are skipped
5. Failed tasks can be retried

**JSON Example**:
```json
{
  "version": "2.0",
  "started": "2025-11-18T10:30:00Z",
  "last_run": "2025-11-18T10:35:42Z",
  "completed_tasks": [
    "verify-prereqs",
    "install-system-deps",
    "install-uv",
    "install-fnm",
    "install-nodejs"
  ],
  "failed_tasks": [
    {
      "task_id": "install-ghostty",
      "error_message": "Build failed: missing libgtk-4-dev",
      "timestamp": "2025-11-18T10:34:15Z",
      "retry_count": 1
    }
  ],
  "skipped_tasks": [],
  "system_info": {
    "os": "Ubuntu 25.10",
    "kernel": "6.17.0-6-generic",
    "architecture": "x86_64",
    "hostname": "ghostty-test"
  },
  "performance": {
    "total_duration": 285,
    "task_durations": {
      "verify-prereqs": 2.1,
      "install-system-deps": 8.3,
      "install-uv": 1.5,
      "install-fnm": 1.9,
      "install-nodejs": 3.2
    }
  }
}
```

**State Operations**:
```bash
# Check if task completed
is_task_completed "install-ghostty"
# Returns: 0 if in completed_tasks[], 1 otherwise

# Mark task completed
mark_task_completed "install-ghostty" 45.7
# Adds to completed_tasks[], records duration

# Mark task failed
mark_task_failed "install-ghostty" "Build failed: missing libgtk-4-dev"
# Adds to failed_tasks[] with error and timestamp

# Resume installation
resume_installation
# Reads state file, skips completed tasks, retries failed tasks
```

---

### 5. Performance Metrics

Task-level timing and system resource usage.

**Properties**:
```typescript
interface PerformanceMetrics {
    task_name: string;
    start_time: string;                // ISO8601 timestamp
    end_time: string;                  // ISO8601 timestamp
    duration: number;                  // Seconds
    cpu_usage?: {
        user_time: number;             // User CPU seconds
        system_time: number;           // System CPU seconds
        percent: number;               // CPU utilization percentage
    };
    memory_usage?: {
        peak_mb: number;               // Peak memory usage
        average_mb: number;            // Average memory usage
    };
    disk_io?: {
        bytes_read: number;
        bytes_written: number;
    };
}

interface AggregateMetrics {
    total_duration: number;
    parallel_speedup?: number;         // % improvement from parallel execution
    bottleneck_tasks: string[];        // Tasks taking >20% of total time
    performance_metrics: {
        fnm_startup_ms: number;        // Performance measured and logged
        gum_startup_ms: number;        // Performance measured and logged
        total_minutes: number;         // Target: <10 minutes total
    };
}
```

**JSON Example**:
```json
{
  "task_name": "install-ghostty",
  "start_time": "2025-11-18T10:30:15Z",
  "end_time": "2025-11-18T10:31:00Z",
  "duration": 45.7,
  "cpu_usage": {
    "user_time": 38.2,
    "system_time": 7.5,
    "percent": 100
  },
  "memory_usage": {
    "peak_mb": 512,
    "average_mb": 380
  },
  "disk_io": {
    "bytes_read": 524288000,
    "bytes_written": 104857600
  }
}
```

**Constitutional Validation**:
```json
{
  "constitutional_compliance": {
    "fnm_startup_ms": 42,
    "gum_startup_ms": 8,
    "total_minutes": 8.5,
    "compliant": true,
    "violations": []
  }
}
```

---

## Data Flow Diagrams

### Task Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│  1. Load Installation State                                 │
│     └─ Read /tmp/ghostty-start-logs/installation-state.json│
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Check if Task Already Completed                         │
│     └─ task_id in state.completed_tasks[]?                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                ┌──────┴──────┐
                │             │
            YES │             │ NO
                │             │
                ▼             ▼
        ┌───────────┐  ┌─────────────────────┐
        │  Skip     │  │  3. Execute         │
        │  Task     │  │     Dependencies    │
        │  (SKIPPED)│  │                     │
        └───────────┘  └──────┬──────────────┘
                              │
                              ▼
                    ┌──────────────────────┐
                    │  4. Run              │
                    │     install_function │
                    │     (capture output) │
                    └──────┬───────────────┘
                           │
                           ▼
                    ┌──────────────────────┐
                    │  5. Run              │
                    │     verify_function  │
                    │     (real checks)    │
                    └──────┬───────────────┘
                           │
                    ┌──────┴──────┐
                    │             │
               SUCCESS           FAILURE
                    │             │
                    ▼             ▼
            ┌───────────┐  ┌──────────────┐
            │  Mark     │  │  Mark        │
            │  Completed│  │  Failed      │
            │  (SUCCESS)│  │  (FAILED)    │
            └────┬──────┘  └──────┬───────┘
                 │                │
                 ▼                ▼
        ┌────────────────────────────┐
        │  6. Update State File      │
        │     - Add to completed[]   │
        │     - Record duration      │
        │     - Save error (if any)  │
        └────────────────────────────┘
```

### Verification Flow (Multi-Layer)

```
┌──────────────────────────────────────────┐
│  Component Installation Complete         │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│  LAYER 1: Unit Tests                     │
│  - Binary exists?                        │
│  - Binary executable?                    │
│  - Version check succeeds?               │
│  - Basic functionality works?            │
└──────────────────┬───────────────────────┘
                   │
            ┌──────┴──────┐
            │             │
          PASS          FAIL
            │             │
            ▼             ▼
┌───────────────┐  ┌──────────────┐
│  Continue     │  │  ABORT       │
│  to Layer 2   │  │  Return 1    │
└───────┬───────┘  └──────────────┘
        │
        ▼
┌──────────────────────────────────────────┐
│  LAYER 2: Integration Tests              │
│  - Components work together?             │
│  - Configuration valid?                  │
│  - Environment variables set?            │
└──────────────────┬───────────────────────┘
                   │
            ┌──────┴──────┐
            │             │
          PASS          FAIL
            │             │
            ▼             ▼
┌───────────────┐  ┌──────────────┐
│  Continue     │  │  ABORT       │
│  to Layer 3   │  │  Return 1    │
└───────┬───────┘  └──────────────┘
        │
        ▼
┌──────────────────────────────────────────┐
│  LAYER 3: Health Checks                  │
│  - No conflicts?                         │
│  - Performance targets met?              │
│  - System resources adequate?            │
└──────────────────┬───────────────────────┘
                   │
            ┌──────┴──────┐
            │             │
          PASS          FAIL
            │             │
            ▼             ▼
    ┌────────────┐  ┌──────────────┐
    │  SUCCESS   │  │  WARNING     │
    │  Return 0  │  │  Log & Return│
    └────────────┘  └──────────────┘
```

---

## Data Validation Rules

### Task Definition Validation
- `id` must be unique, lowercase, dash-separated (e.g., "install-ghostty")
- `name` must be non-empty, human-readable
- `install_function` must exist in `lib/tasks/*.sh`
- `verify_function` must exist in `lib/verification/*.sh`
- `dependencies[]` must reference existing task IDs
- `estimated_duration` must be positive number

### State File Validation
- `version` must match expected schema version ("2.0")
- `completed_tasks[]` must contain valid task IDs
- `failed_tasks[]` must have task_id, error_message, timestamp
- No task can be in both `completed_tasks[]` and `failed_tasks[]`

### Verification Result Validation
- `exit_code` must be 0 (success) or 1 (failure)
- `success` must equal `exit_code === 0`
- `duration` must be non-negative
- If `success === false`, `error_diagnostics` should be present

---

## Storage Locations

| Data Type | File Path | Format | Retention |
|-----------|-----------|--------|-----------|
| Installation State | `/tmp/ghostty-start-logs/installation-state.json` | JSON | Until next clean install |
| System Snapshots | `/tmp/ghostty-start-logs/system_state_TIMESTAMP.json` | JSON | Last 10 installations |
| Human-readable Log | `/tmp/ghostty-start-logs/start-TIMESTAMP.log` | Text | Last 10 installations |
| Structured JSON Log | `/tmp/ghostty-start-logs/start-TIMESTAMP.log.json` | JSON | Last 10 installations |
| Error Log | `/tmp/ghostty-start-logs/errors.log` | Text | Append-only (rotated at 10MB) |
| Performance Metrics | `/tmp/ghostty-start-logs/performance.json` | JSON | Latest only |

---

## Design Decisions

### Why JSON for State Files?
- Human-readable for debugging
- Easy to parse with jq in bash
- Standard format with wide tool support
- Structured data with validation
- Easy to version and migrate

### Why /tmp/ for Logs?
- Automatic cleanup on reboot
- No need for manual log rotation (system handles it)
- Fast access (tmpfs on most systems)
- Doesn't clutter home directory

### Why Multi-Layer Verification?
- Catches failures at appropriate granularity
- Unit tests fail fast (before integration)
- Integration tests verify real-world usage
- Health checks ensure overall system compliance

### Why Separate completed_tasks[] and failed_tasks[]?
- Clear state distinction
- Failed tasks can be retried
- Completed tasks always skipped (idempotency)
- Easy to generate summary reports

---

**Data Model Complete** ✅

All core entities defined with TypeScript-style interfaces, JSON examples, validation rules, and storage specifications. Ready for contract definition and implementation.
