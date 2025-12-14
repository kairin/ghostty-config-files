---
title: Go TUI Architecture
category: architecture
linked-from: system-architecture.md
status: ACTIVE
last-updated: 2025-12-14
---

# Go TUI Architecture

[← Back to System Architecture](./system-architecture.md)

> Complete reference for the Go + Bubbletea TUI installer implementation.

---

## Overview

The Go TUI replaces the shell-based menu system with a modern, type-safe implementation using the Charmbracelet ecosystem. It was implemented in four phases:

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 1 | Foundation (registry, cache, basic UI) | Complete |
| 2 | Script Interop (pipeline, checkpoints, streaming) | Complete |
| 3 | Feature Parity (extras, diagnostics, demo mode) | Complete |
| 4 | Cutover (wrapper, CI/CD, documentation) | Complete |

---

## Directory Structure

```
tui/
├── go.mod                      # Module: github.com/kairin/ghostty-installer
├── go.sum                      # Dependency checksums
├── installer                   # Compiled binary (5.0MB)
├── cmd/
│   └── installer/
│       └── main.go             # CLI entry point with flag parsing
└── internal/
    ├── registry/
    │   ├── registry.go         # Tool catalog (12 tools)
    │   └── tool.go             # Tool struct definition
    ├── cache/
    │   └── cache.go            # Status caching with 5-min TTL
    ├── executor/
    │   ├── executor.go         # Script runner with streaming
    │   ├── pipeline.go         # 5-stage pipeline orchestration
    │   └── checkpoint.go       # Atomic state persistence
    ├── diagnostics/
    │   ├── issue.go            # Issue struct, severity enum
    │   ├── detector.go         # Parallel script execution
    │   ├── cache.go            # 24-hour cache with boot ID
    │   └── fixer.go            # Two-phase fix execution
    └── ui/
        ├── model.go            # Root Bubbletea model
        ├── styles.go           # Lipgloss style definitions
        ├── dashboard.go        # Main dashboard view
        ├── extras.go           # Extras dashboard (cyan border)
        ├── installer.go        # Installation view with TailSpinner
        ├── diagnostics.go      # Boot diagnostics view
        └── tailspinner.go      # Spinner + viewport component
```

---

## Technology Stack

| Component | Package | Version |
|-----------|---------|---------|
| Framework | github.com/charmbracelet/bubbletea | v1.2.4+ |
| Styling | github.com/charmbracelet/lipgloss | v1.0.0+ |
| Components | github.com/charmbracelet/bubbles | v0.20.0+ |
| Concurrency | golang.org/x/sync/errgroup | v0.9.0 |

---

## Core Concepts

### Elm Architecture (Bubbletea)

The TUI follows the Elm architecture pattern:

```
Init() → Model
Update(msg) → (Model, Cmd)
View() → string
```

- **Model**: Immutable state (views, tool statuses, selections)
- **Messages**: Events that trigger state changes
- **Commands**: Async operations (script execution, status checks)

### Data-Driven Registry

All 12 tools defined in a single registry:

```go
var Tools = map[string]*Tool{
    "ghostty":   {ID: "ghostty", Name: "Ghostty", Category: CategoryMain, ...},
    "fastfetch": {ID: "fastfetch", Name: "Fastfetch", Category: CategoryExtras, ...},
    // ... all 12 tools
}
```

**Benefits**:
- Single source of truth (no 4-file updates)
- Type-safe tool references
- Easy to extend with new tools

### Status Caching

```go
type CacheEntry struct {
    Status    ToolStatus
    Timestamp time.Time
    ExpiresAt time.Time  // TTL: 5 minutes
}
```

**Features**:
- File-backed persistence (`~/.cache/ghostty-installer/`)
- Auto-expire after 5 minutes
- Force refresh on user request

---

## Pipeline Architecture

### 5-Stage Installation Flow

```
Stage 000: Check       → Detect current status
Stage 002: InstallDeps → Install dependencies
Stage 003: VerifyDeps  → Verify dependencies
Stage 004: Install     → Main installation
Stage 005: Confirm     → Verify success
```

### Script Path Pattern

```go
ScriptPaths = map[Stage]string{
    StageCheck:       "scripts/000-check/check_%s.sh",
    StageInstallDeps: "scripts/002-install-first-time/install_deps_%s.sh",
    StageVerifyDeps:  "scripts/003-verify/verify_deps_%s.sh",
    StageInstall:     "scripts/004-reinstall/install_%s.sh",
    StageConfirm:     "scripts/005-confirm/confirm_%s.sh",
}
```

### Checkpoint System

Atomic state persistence for crash recovery:

```go
type Checkpoint struct {
    ToolID          string
    CurrentStage    Stage
    CompletedStages []Stage
    FailedStage     *FailureInfo
    IsResumable     bool
}
```

**Storage**: `~/.cache/ghostty-installer/pipelines/{toolID}.json`

---

## UI Components

### Views

| View | File | Purpose |
|------|------|---------|
| Dashboard | `dashboard.go` | Main tool list (magenta border) |
| Extras | `extras.go` | Extra tools (cyan border) |
| Installer | `installer.go` | Installation progress |
| Diagnostics | `diagnostics.go` | Boot issue scanner |

### TailSpinner Component

Spinner + viewport showing last N lines of output:

```go
type TailSpinner struct {
    spinner      spinner.Model
    viewport     viewport.Model
    outputLines  []string
    maxLines     int  // Memory limit: 500
    displayLines int  // Visible: 5
}
```

**Batching**: 10 lines OR 50ms timeout (prevents UI flood)

### Styles (Lipgloss)

```go
var (
    ColorMain       = lipgloss.Color("212")  // Magenta
    ColorExtras     = lipgloss.Color("99")   // Cyan
    ColorSuccess    = lipgloss.Color("82")   // Green
    ColorWarning    = lipgloss.Color("214")  // Orange
    ColorError      = lipgloss.Color("196")  // Red
)
```

---

## Boot Diagnostics

### Detector Scripts

| Script | Detects |
|--------|---------|
| `detect_failed_services.sh` | systemd failed units |
| `detect_orphaned_services.sh` | Services with missing targets |
| `detect_network_wait_issues.sh` | NetworkManager-wait-online delays |
| `detect_unsupported_snaps.sh` | Snaps on unsupported base |
| `detect_cosmetic_warnings.sh` | Non-critical warnings |

### Issue Structure

```go
type Issue struct {
    Type        string         // ORPHANED_SERVICE, FAILED_SERVICE, etc.
    Severity    IssueSeverity  // Critical, Moderate, Low
    Name        string
    Description string
    Fixable     string         // YES, NO, MAYBE
    FixCommand  string
}
```

### Two-Phase Fix Execution

```
Phase 1: User-level fixes (no sudo)
Phase 2: System-level fixes (single sudo auth)
```

### Cache Strategy

- **TTL**: 24 hours
- **Invalidation**: Boot ID change (reboot detected)
- **Location**: `~/.cache/ghostty-boot-diagnostics/`

---

## Demo Mode

### CLI Flags

```bash
./start.sh --demo-child         # Demo mode for VHS/asciinema
./start.sh --sudo-cached        # Use pre-authenticated sudo
```

### Behavior

- **Demo mode**: Skip sudo-required operations
- **Sudo cached**: Allow sudo operations with cached credentials
- **Normal**: Full sudo authentication with keep-alive

---

## Integration Points

### Wrapper (start.sh)

```bash
GO_BINARY="$SCRIPT_DIR/tui/installer"
if [[ -f "$GO_BINARY" && -x "$GO_BINARY" ]]; then
    exec "$GO_BINARY" "$@"
fi
```

### CI/CD (gh-workflow-local.sh)

```bash
build_go_tui() {
    cd "$REPO_DIR/tui"
    go build -v -o installer ./cmd/installer
    go vet ./...
}
```

### Pre-commit Hook

```bash
if [[ -d "$TUI_DIR" ]] && command -v go &> /dev/null; then
    cd "$TUI_DIR"
    go fmt ./...
    go vet ./...
fi
```

---

## Building

### From Source

```bash
cd tui
go build -o installer ./cmd/installer
```

### With Race Detector (Testing)

```bash
go build -race -o installer ./cmd/installer
```

### Cross-Compilation

```bash
GOOS=linux GOARCH=amd64 go build -o installer ./cmd/installer
```

---

## Performance Characteristics

| Metric | Value |
|--------|-------|
| Binary size | 5.0 MB |
| Startup time | <100ms |
| Status check (parallel) | <1s (all 12 tools) |
| Memory usage | <30MB |

---

## Error Handling

### Error Categories

| Category | Retry | Action |
|----------|-------|--------|
| Transient (network) | Yes | Retry 3x |
| Script error | No | Show output, offer retry |
| Missing script | No | Skip with warning |
| Timeout | No | Show timeout message |

### Timeout Configuration

| Operation | Timeout |
|-----------|---------|
| Status check | 30 seconds |
| Script execution | 5 minutes |
| Pipeline stage | 5 minutes |

---

## Future Enhancements

- [ ] **details.go**: Glamour markdown viewer for tool documentation
- [ ] **"Install All"**: Batch installation for extras
- [ ] **Test coverage**: Unit tests for registry, cache, executor
- [ ] **Version comparison**: Proper semver instead of string comparison

---

**Version**: 1.0
**Last Updated**: 2025-12-14
