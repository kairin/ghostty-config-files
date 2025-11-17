---
title: "Architecture Overview"
description: "System architecture and design patterns for Ghostty Configuration Files"
pubDate: 2025-10-27
author: "Development Team"
tags: ["development", "architecture", "design"]
techStack: ["Bash 5.x+", "Node.js latest (v25.2.0+)", "Astro.build"]
difficulty: "intermediate"
---

# Architecture Overview

This document describes the architecture of the Ghostty Configuration Files repository.

## System Architecture

### High-Level Structure

```
Ghostty Configuration Files Repository
│
├── Installation Layer (start.sh, manage.sh)
├── Modular Scripts Layer (scripts/*)
├── Configuration Layer (configs/*)
├── Documentation Layer (website/src/, docs/)
├── Local CI/CD Layer (.runners-local/*)
└── Spec-Kit Layer (.specify/*, spec-kit/*)
```

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    manage.sh (Unified Entry Point)           │
│  Commands: install, docs, screenshots, update, validate      │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼──────┐          ┌──────▼───────┐
│   Scripts    │          │   Configs    │
│   Layer      │          │   Layer      │
│              │          │              │
│ • common.sh  │          │ • ghostty/   │
│ • progress.sh│          │ • workspace/ │
│ • backup_utils│         │              │
│ • install_*.sh│         │              │
│ • config_*.sh│          │              │
│ • validate_*│          │              │
└──────────────┘          └──────────────┘
        │                         │
        └────────────┬────────────┘
                     │
          ┌──────────▼──────────┐
          │   Local CI/CD       │
          │                     │
          │ • gh-workflow-local │
          │ • test-runner      │
          │ • performance-monitor│
          └─────────────────────┘
```

## Directory Structure

### Top-Level Organization

```
/home/kkk/Apps/ghostty-config-files/
├── manage.sh                # Unified management interface
├── start.sh                 # Legacy installation script
├── AGENTS.md                # LLM instructions (single source)
├── CLAUDE.md → AGENTS.md    # Symlink
├── GEMINI.md → AGENTS.md    # Symlink
├── README.md                # User-facing documentation
│
├── configs/                 # Configuration files
│   ├── ghostty/            # Ghostty terminal config
│   └── workspace/          # Development workspace
│
├── scripts/                # Modular utility scripts
│   ├── common.sh           # Common utilities
│   ├── progress.sh         # Progress reporting
│   ├── backup_utils.sh     # Backup/restore
│   ├── install_*.sh        # Installation modules
│   ├── config_*.sh         # Configuration modules
│   └── validate_*.sh       # Validation modules
│
├── website/src/            # Documentation source (editable)
│   ├── user-guide/         # User documentation
│   ├── ai-guidelines/      # AI assistant guidelines
│   └── developer/          # Developer documentation
│
├── docs/                   # Documentation build output (gitignored)
│
├── .runners-local/            # Local CI/CD infrastructure
│   ├── .runners-local/workflows/            # CI/CD scripts
│   ├── tests/              # Test suites
│   └── logs/               # CI/CD logs
│
├── .specify/               # Spec-Kit implementation
│   ├── templates/          # Spec-Kit templates
│   └── scripts/            # Spec-Kit scripts
│
└── specs/                  # Feature specifications
    └── 001-repo-structure-refactor/
```

### Module Organization

#### Scripts Module Architecture

Each script module follows a consistent pattern:

```bash
#!/bin/bash
# Module: <name>.sh
# Purpose: <description>
# Dependencies: <list>
# Modules Required: <list>
# Exit Codes: <definitions>

set -euo pipefail

# Module-level guard
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED_FOR_TESTING=1
fi

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Public functions (module API)
function public_function() {
    # Implementation
}

# Private functions (internal)
function _private_function() {
    # Implementation
}

# Main execution (skip if sourced)
if [[ "${SOURCED_FOR_TESTING}" -eq 0 ]]; then
    # CLI entry point
fi
```

## Key Components

### 1. manage.sh - Unified Entry Point

**Purpose**: Single command-line interface for all repository operations

**Architecture**:
- Argument parsing with global options
- Command routing to specialized handlers
- Error handling with trap mechanisms
- Environment variable support
- Comprehensive help system

**Key Functions**:
```bash
main()                    # Entry point
load_environment_config() # Environment setup
parse_global_options()    # Option parsing
route_command()           # Command routing
cmd_install()            # Install command handler
cmd_docs()               # Docs command handler
cmd_screenshots()        # Screenshots command handler
cmd_update()             # Update command handler
cmd_validate()           # Validate command handler
```

### 2. Scripts Layer - Modular Utilities

**Purpose**: Reusable, testable utility modules

**Core Modules**:
- `common.sh` - Path resolution, logging, error handling
- `progress.sh` - Progress reporting, spinners, summaries
- `backup_utils.sh` - Backup/restore with verification

**Installation Modules**:
- `install_node.sh` - Node.js via NVM
- `install_zig.sh` - Zig compiler
- `build_ghostty.sh` - Ghostty from source

**Configuration Modules**:
- `setup_zsh.sh` - ZSH environment
- `configure_theme.sh` - Catppuccin themes
- `install_context_menu.sh` - Nautilus integration

**Validation Modules**:
- `validate_config.sh` - Configuration syntax
- `performance_check.sh` - Performance metrics
- `dependency_check.sh` - System dependencies

### 3. Configuration Layer

**Purpose**: Modular configuration management

**Structure**:
```
configs/ghostty/
├── config              # Main config (includes others)
├── theme.conf          # Theme settings
├── scroll.conf         # Scrollback settings
├── layout.conf         # Font/layout
└── keybindings.conf    # Keybindings
```

### 4. Documentation Layer

**Purpose**: Dual-structure documentation (source + build)

**Source** (`website/src/`):
- Markdown files (git-tracked)
- Organized by audience (user/developer/AI)
- Content collections for Astro

**Build Output** (`docs/`):
- Astro static site
- Gitignored (generated)
- Contains `.nojekyll` (constitutional requirement)

### 5. Local CI/CD Layer

**Purpose**: Zero-cost local continuous integration

**Components**:
- `gh-workflow-local.sh` - GitHub Actions simulation
- `gh-pages-setup.sh` - Zero-cost Pages configuration
- `test-runner.sh` - Test execution
- `performance-monitor.sh` - Performance tracking

## Design Patterns

### Module Pattern

All bash modules follow this pattern:
1. **Guard Clause**: Detect if sourced vs executed
2. **Dependency Loading**: Source required modules
3. **Public API**: Exported functions with documentation
4. **Private Helpers**: Internal functions with `_` prefix
5. **Main Execution**: CLI entry point if not sourced

### Error Handling Pattern

```bash
# Set strict mode
set -euo pipefail

# Trap errors
trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR
trap cleanup_on_exit EXIT
trap handle_interrupt INT TERM

# Cleanup function
cleanup_on_exit() {
    # Cleanup temporary resources
}
```

### Progress Reporting Pattern

```bash
show_progress "start" "Operation description"
show_step 1 5 "Step 1: Doing something"
# ... operation ...
show_progress "success" "Operation completed"
```

### Backup Before Modify Pattern

```bash
# Create backup before changes
backup_path=$(create_backup "$config_file")

# Make changes
modify_config

# Verify changes
if ! validate_config; then
    # Restore on failure
    restore_backup "$backup_path"
fi
```

## Data Flow

### Installation Flow

```
User Command: ./manage.sh install
       │
       ▼
parse_global_options()
       │
       ▼
route_command("install")
       │
       ▼
cmd_install()
       │
       ├─► validate dependencies
       ├─► create backup
       ├─► install Node.js (install_node.sh)
       ├─► install Zig (install_zig.sh)
       ├─► build Ghostty (build_ghostty.sh)
       ├─► setup ZSH (setup_zsh.sh)
       ├─► configure theme (configure_theme.sh)
       └─► install context menu (install_context_menu.sh)
              │
              ▼
        show_summary()
              │
              ▼
         exit 0/1
```

### Update Flow with Rollback

```
User Command: ./manage.sh update
       │
       ▼
create_backup()
       │
       ▼
extract_user_customizations()
       │
       ▼
apply_updates()
       │
       ├─► SUCCESS ─► reapply_customizations()
       │                     │
       │                     ▼
       │              show_progress "success"
       │
       └─► FAILURE ─► restore_backup()
                             │
                             ▼
                      show_progress "error"
```

## Testing Architecture

### Test Organization

```
.runners-local/tests/
├── unit/                    # Unit tests
│   ├── test_functions.sh   # Test helpers
│   ├── test_common_utils.sh # Common module tests
│   └── test_*.sh           # Module-specific tests
│
├── integration/            # Integration tests
│   └── test_install_workflow.sh
│
└── validation/            # Static analysis
    └── run_shellcheck.sh
```

### Test Execution Flow

```
./.runners-local/.runners-local/workflows/test-runner.sh
       │
       ├─► Run ShellCheck (static analysis)
       ├─► Run unit tests (<10s per module)
       └─► Run integration tests
              │
              ▼
        Generate test report
```

## Performance Considerations

### Startup Performance

- **Target**: <500ms for script initialization
- **Optimization**: Lazy loading of modules
- **Measurement**: `time ./manage.sh --version`

### Module Loading

- **Pattern**: Source on demand, not at startup
- **Caching**: Avoid re-sourcing already loaded modules
- **Dependencies**: Minimize dependency chains

### Configuration Loading

- **Strategy**: Parse once, cache results
- **Validation**: Async validation for non-critical checks
- **Reporting**: Batch progress updates

## Security Considerations

### Input Validation

- All user inputs validated before use
- Path traversal prevention
- Command injection prevention via proper quoting

### Credential Handling

- Never commit secrets
- Use environment variables for sensitive data
- Automatic detection and warning for potential leaks

### Safe Defaults

- Dry-run mode by default for destructive operations
- Confirmation prompts for major changes
- Automatic backups before modifications

## Future Architecture

### Planned Improvements

1. **Module Dependency Graph**: Automated dependency resolution
2. **Plugin System**: External module loading
3. **Configuration Validation Schema**: JSON schema for config validation
4. **Parallel Execution**: Run independent tasks concurrently
5. **Telemetry**: Optional usage analytics (local only)

## Related Documentation

- [Contributing Guide](contributing.md) - How to contribute
- [Testing Guide](testing.md) - Testing strategies
- [AI Guidelines](../ai-guidelines/core-principles.md) - For AI assistants
