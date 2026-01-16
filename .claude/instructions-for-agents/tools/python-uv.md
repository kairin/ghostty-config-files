# Python UV Implementation Summary

UV is a fast Python package manager from Astral (creators of Ruff), installed via official script.

## Core Scripts (`scripts/`)

| Stage | Script | Purpose |
|-------|--------|---------|
| 000 | `check_python_uv.sh` | Detect uv installation, version |
| 001 | `uninstall_python_uv.sh` | Remove uv binary |
| 002 | `install_deps_python_uv.sh` | Install curl |
| 003 | `verify_deps_python_uv.sh` | Verify curl available |
| 004 | `install_python_uv.sh` | Run official install script |
| 005 | `confirm_python_uv.sh` | Verify uv command works |

## Installation Strategy (`scripts/004-reinstall/install_python_uv.sh`)

### One-Line Installation
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### What the Script Does
1. Detects platform and architecture
2. Downloads appropriate binary
3. Installs to `~/.local/bin/` or `~/.cargo/bin/`
4. Adds to PATH if needed

## TUI Integration (`start.sh`)

- **Menu Location**: Extras Dashboard
- **Display Name**: "Python (uv)"
- **Tool ID**: `python_uv`
- **Status Display**: Installation status, version

## Key Characteristics

- **Version Detection**: `uv --version`
- **Installation Location**: `~/.local/bin/uv` or `~/.cargo/bin/uv`
- **Configuration**: None required
- **Shell Integration**: Added to PATH by installer
- **Logging**: Simple echo

## Bundled Tools

Python installation automatically includes the following bundled tools:

| Tool | Purpose |
|------|---------|
| **uv** | Fast Python package installer and resolver from Astral |

This is automatically installed and configured when you install Python via the TUI.

## Dependencies

- curl (for running install script)

## UV Features

- **10-100x faster** than pip
- Drop-in pip replacement
- Virtual environment management
- Python version management
- Dependency resolution

## Usage

```bash
uv pip install package      # Install packages
uv venv                     # Create virtual environment
uv python install 3.12      # Install Python version
uv run script.py            # Run with automatic venv
```

## Comparison to pip

| Operation | pip | uv |
|-----------|-----|-----|
| Install Django | ~10s | ~0.5s |
| Resolve large project | minutes | seconds |
| Lock file creation | slow | fast |
