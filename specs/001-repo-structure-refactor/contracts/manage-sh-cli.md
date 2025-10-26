# Contract: manage.sh CLI Interface

**Version**: 1.0.0
**Type**: Command-Line Interface
**Stability**: Stable (once released)

## Overview

This contract defines the command-line interface for `manage.sh`, the unified management entry point for the Ghostty Configuration Files repository.

---

## Global Options

These options apply to all commands:

```bash
manage.sh [GLOBAL_OPTIONS] <command> [COMMAND_OPTIONS] [ARGS...]
```

### Global Options

| Option | Short | Type | Required | Default | Description |
|--------|-------|------|----------|---------|-------------|
| `--help` | `-h` | flag | No | - | Display help for command or subcommand |
| `--version` | `-v` | flag | No | - | Display manage.sh version |
| `--verbose` | `-V` | flag | No | false | Enable verbose output with debug information |
| `--quiet` | `-q` | flag | No | false | Suppress non-error output |
| `--dry-run` | `-n` | flag | No | false | Show what would be done without executing |

---

## Commands

### Command: `install`

**Purpose**: Install complete Ghostty terminal environment with all dependencies.

**Usage**:
```bash
manage.sh install [OPTIONS]
```

**Options**:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--skip-node` | flag | No | false | Skip Node.js installation |
| `--skip-zig` | flag | No | false | Skip Zig compiler installation |
| `--skip-ghostty` | flag | No | false | Skip Ghostty build from source |
| `--skip-zsh` | flag | No | false | Skip ZSH configuration |
| `--skip-theme` | flag | No | false | Skip theme configuration |
| `--skip-context-menu` | flag | No | false | Skip context menu integration |
| `--force` | flag | No | false | Force reinstall even if already installed |

**Exit Codes**:
- `0`: Installation completed successfully
- `1`: General installation failure
- `2`: Dependency missing (system package required)
- `3`: Build failure (Ghostty compilation failed)
- `4`: Configuration failure (ZSH or theme setup failed)

**Examples**:
```bash
# Full installation
./manage.sh install

# Install without context menu
./manage.sh install --skip-context-menu

# Reinstall everything
./manage.sh install --force

# Dry run to see what would be installed
./manage.sh install --dry-run

# Verbose output for debugging
./manage.sh install --verbose
```

**Behavior**:
- Idempotent: Safe to run multiple times
- Progress: Displays step-by-step progress (e.g., "[1/6] Installing Node.js...")
- Timing: Shows estimated and actual time for each step
- Rollback: On failure, restores previous configuration from automatic backup

---

### Command: `docs`

**Purpose**: Build, serve, or deploy documentation site.

**Usage**:
```bash
manage.sh docs <subcommand> [OPTIONS]
```

#### Subcommand: `build`

**Purpose**: Build Astro documentation site to output directory.

**Usage**:
```bash
manage.sh docs build [OPTIONS]
```

**Options**:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--clean` | flag | No | false | Remove previous build before building |
| `--output-dir` | string | No | `docs/` | Custom output directory |

**Exit Codes**:
- `0`: Build successful
- `1`: Build failed (Astro error)
- `2`: Output directory permission denied

**Examples**:
```bash
# Standard build
./manage.sh docs build

# Clean build
./manage.sh docs build --clean

# Build to custom directory
./manage.sh docs build --output-dir docs-dist/
```

#### Subcommand: `dev`

**Purpose**: Start Astro development server with hot module replacement.

**Usage**:
```bash
manage.sh docs dev [OPTIONS]
```

**Options**:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--port` | integer | No | 4321 | Port for development server |
| `--host` | string | No | localhost | Host to bind server |

**Exit Codes**:
- `0`: Server stopped gracefully
- `1`: Server startup failed
- `2`: Port already in use

**Examples**:
```bash
# Start dev server
./manage.sh docs dev

# Custom port
./manage.sh docs dev --port 3000

# Bind to all interfaces
./manage.sh docs dev --host 0.0.0.0
```

#### Subcommand: `generate`

**Purpose**: Generate documentation from templates and code.

**Usage**:
```bash
manage.sh docs generate [OPTIONS]
```

**Options**:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--type` | string | No | all | Type to generate: `all`, `screenshots`, `api` |

**Exit Codes**:
- `0`: Generation successful
- `1`: Generation failed

**Examples**:
```bash
# Generate all documentation
./manage.sh docs generate

# Generate only screenshots
./manage.sh docs generate --type screenshots
```

---

### Command: `screenshots`

**Purpose**: Capture and manage screenshots for documentation.

**Usage**:
```bash
manage.sh screenshots <subcommand> [OPTIONS]
```

#### Subcommand: `capture`

**Purpose**: Capture a single screenshot with description.

**Usage**:
```bash
manage.sh screenshots capture <category> <name> <description>
```

**Arguments**:

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `category` | string | Yes | Screenshot category (e.g., "setup", "usage") |
| `name` | string | Yes | Filename without extension |
| `description` | string | Yes | Human-readable description |

**Exit Codes**:
- `0`: Screenshot captured successfully
- `1`: Capture failed (no active window, permission denied, etc.)

**Examples**:
```bash
# Capture setup screenshot
./manage.sh screenshots capture setup "ghostty-config" "Main Ghostty configuration file"

# Capture usage screenshot
./manage.sh screenshots capture usage "context-menu" "Right-click context menu integration"
```

#### Subcommand: `generate-gallery`

**Purpose**: Generate screenshot gallery HTML from captured images.

**Usage**:
```bash
manage.sh screenshots generate-gallery [OPTIONS]
```

**Options**:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--output` | string | No | docs/screenshots/ | Output directory for gallery |

**Exit Codes**:
- `0`: Gallery generated successfully
- `1`: Generation failed

**Examples**:
```bash
# Generate gallery
./manage.sh screenshots generate-gallery

# Custom output
./manage.sh screenshots generate-gallery --output custom/path/
```

---

### Command: `update`

**Purpose**: Update repository components intelligently (preserves user customizations).

**Usage**:
```bash
manage.sh update [OPTIONS]
```

**Options**:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--check-only` | flag | No | false | Check for updates without applying |
| `--force` | flag | No | false | Force update all components |
| `--component` | string | No | all | Specific component: `node`, `zig`, `ghostty`, `zsh`, `theme` |

**Exit Codes**:
- `0`: Updates applied successfully (or no updates needed)
- `1`: Update failed
- `2`: Updates available but not applied (when using `--check-only`)

**Examples**:
```bash
# Check for updates
./manage.sh update --check-only

# Update all components
./manage.sh update

# Update only Ghostty
./manage.sh update --component ghostty

# Force update
./manage.sh update --force
```

**Behavior**:
- Intelligent: Only updates components with newer versions available
- Preserves Customizations: Extracts and reapplies user configurations
- Backup: Creates timestamped backup before update
- Rollback: Provides rollback command if update fails

---

### Command: `validate`

**Purpose**: Validate configuration, performance, and system health.

**Usage**:
```bash
manage.sh validate [OPTIONS]
```

**Options**:

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `--type` | string | No | all | Validation type: `all`, `config`, `performance`, `dependencies` |
| `--fix` | flag | No | false | Attempt to fix detected issues |

**Exit Codes**:
- `0`: All validations passed
- `1`: Validation failed (issues detected)
- `2`: Validation passed but warnings present

**Examples**:
```bash
# Full validation
./manage.sh validate

# Validate configuration only
./manage.sh validate --type config

# Validate and auto-fix issues
./manage.sh validate --fix

# Check dependencies
./manage.sh validate --type dependencies
```

**Validation Checks**:
- Configuration: Ghostty config syntax, ZSH configuration, theme files
- Performance: Startup time, memory usage, terminal responsiveness
- Dependencies: Node.js, Zig, system packages, ZSH plugins

---

## Environment Variables

These environment variables can modify manage.sh behavior:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `MANAGE_DEBUG` | boolean | false | Enable debug mode (equivalent to --verbose) |
| `MANAGE_NO_COLOR` | boolean | false | Disable colored output |
| `MANAGE_LOG_FILE` | string | - | Path to log file for command output |
| `MANAGE_BACKUP_DIR` | string | ~/.config/ghostty-backups | Directory for configuration backups |

**Examples**:
```bash
# Enable debug mode
MANAGE_DEBUG=1 ./manage.sh install

# Disable colors (for CI/CD)
MANAGE_NO_COLOR=1 ./manage.sh validate

# Log to file
MANAGE_LOG_FILE=/tmp/manage.log ./manage.sh docs build
```

---

## Output Format

### Standard Output (stdout)

User-facing messages, progress indicators, and results:

```
🔄 Starting: Node.js Installation
[1/6] Installing Node.js...
✅ Completed: Node.js Installation (15.3s)

[2/6] Installing Zig compiler...
⏳ In progress: Downloading Zig 0.14.0...
✅ Completed: Zig Installation (42.1s)

Installation Summary:
  Total time: 5m 23s
  Components installed: 6/6
  Status: Success ✅
```

### Error Output (stderr)

Error messages and warnings:

```
❌ ERROR: Failed to build Ghostty
   Reason: Zig compiler not found in PATH
   Fix: Run 'manage.sh update --component zig' to install Zig

   Exit code: 2 (Missing dependency)
```

### JSON Output (with --json flag)

Machine-readable output for CI/CD integration:

```json
{
  "command": "install",
  "status": "success",
  "duration_seconds": 323,
  "components": [
    {
      "name": "node",
      "version": "20.10.0",
      "status": "installed",
      "duration_seconds": 15
    },
    {
      "name": "zig",
      "version": "0.14.0",
      "status": "installed",
      "duration_seconds": 42
    }
  ],
  "exit_code": 0
}
```

---

## Error Handling

### Exit Code Summary

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | No action needed |
| 1 | General failure | Check error message, review logs |
| 2 | Missing dependency | Install required system package or component |
| 3 | Build failure | Check build logs, verify compiler installed |
| 4 | Configuration error | Review configuration files, check syntax |
| 5 | Permission denied | Run with appropriate permissions or use sudo |
| 6 | Network error | Check internet connection, retry |
| 7 | Validation failure | Fix reported issues, rerun validation |

### Error Recovery

All commands implement:
- **Automatic Backup**: Before making changes
- **Rollback On Failure**: Restores previous state if operation fails
- **Detailed Diagnostics**: Explains what went wrong and how to fix
- **Safe Mode**: `--dry-run` option to preview changes

**Example Error Message**:
```
❌ ERROR: Command failed at step 3/6 (Build Ghostty)

Details:
  Command: zig build -Doptimize=ReleaseFast
  Exit code: 1
  Error: Build failed due to missing libgtk-4-dev

Diagnosis:
  System package 'libgtk-4-dev' is required but not installed

Fix:
  sudo apt install libgtk-4-dev
  ./manage.sh install --force

Backup created:
  ~/.config/ghostty-backups/backup-20251027-001234/

Rollback:
  ./manage.sh rollback 20251027-001234
```

---

## Backward Compatibility

### start.sh Wrapper

The existing `start.sh` script is preserved as a wrapper:

```bash
#!/bin/bash
# start.sh - Wrapper for manage.sh install command
# Preserves backward compatibility

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/manage.sh" install "$@"
```

**Behavior**:
- `./start.sh` → `./manage.sh install`
- `./start.sh --verbose` → `./manage.sh install --verbose`
- All start.sh options forwarded to `manage.sh install`

---

## Versioning

### Semantic Versioning

manage.sh follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Incompatible CLI changes (breaking)
- **MINOR**: New commands or options (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

**Current Version**: 1.0.0

### Version Query

```bash
$ ./manage.sh --version
manage.sh version 1.0.0
Ghostty Configuration Files Management Tool

Components:
  Node.js: 20.10.0
  Zig: 0.14.0
  Ghostty: 1.2.0
  ZSH: 5.9
```

---

## Testing Contract

All manage.sh commands must:

1. **Accept `--help` flag**: Display usage information
2. **Support `--dry-run`**: Preview without executing
3. **Return valid exit codes**: As defined in this contract
4. **Handle signals**: SIGINT (Ctrl+C) gracefully with cleanup
5. **Log to stderr**: All errors must go to stderr, not stdout
6. **Be idempotent**: Safe to run multiple times (where applicable)
7. **Provide progress**: For operations >10 seconds
8. **Create backups**: Before destructive operations

### Contract Tests

These pytest tests validate the CLI contract:

```python
def test_install_help_flag():
    """Verify --help displays usage"""
    result = subprocess.run(["./manage.sh", "install", "--help"], capture_output=True)
    assert result.returncode == 0
    assert b"Usage:" in result.stdout

def test_install_dry_run():
    """Verify --dry-run doesn't modify system"""
    subprocess.run(["./manage.sh", "install", "--dry-run"])
    # Assert no files modified, no packages installed

def test_invalid_command():
    """Verify invalid command returns non-zero"""
    result = subprocess.run(["./manage.sh", "invalid"], capture_output=True)
    assert result.returncode == 1
    assert b"ERROR" in result.stderr
```

---

## Contract Guarantees

This contract guarantees:

1. **Stability**: Once released, breaking changes increment MAJOR version
2. **Documentation**: All options documented with examples
3. **Error Messages**: Clear, actionable error messages in English
4. **Performance**: Help output displays in <2 seconds
5. **Compatibility**: Backward compatible within same MAJOR version
6. **Security**: No execution of untrusted code or input
7. **Logging**: Comprehensive logs for troubleshooting
8. **Testing**: All commands covered by integration tests

---

## Contract Versioning

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-10-27 | Initial contract definition |

---

## References

- **Implementation**: `/manage.sh` (repository root)
- **Tests**: `/local-infra/tests/contract/test_manage_cli.py`
- **Documentation**: `/docs-source/user-guide/manage-sh.md`
