# Feh Implementation Summary

Feh is a lightweight image viewer, built from source for the latest features.

## Core Scripts (`scripts/`)

| Stage | Script | Purpose |
|-------|--------|---------|
| 000 | `check_feh.sh` | Detect installation, version |
| 001 | `uninstall_feh.sh` | Remove installed binary |
| 002 | `install_deps_feh.sh` | Install build dependencies |
| 003 | `verify_deps_feh.sh` | Verify build tools available |
| 004 | `install_feh.sh` | Clone and build from source |
| 005 | `confirm_feh.sh` | Verify feh command works |

## Installation Strategy (`scripts/004-reinstall/install_feh.sh`)

### Build Process
1. Clone repository: `git clone --depth 1 https://github.com/derf/feh.git`
2. Build with make: `make`
3. Install: `sudo make install`
4. Cleanup: Remove build directory

### Build Location
- Temporary build directory: `/tmp/feh-build`
- Cleaned up after installation

## TUI Integration (`start.sh`)

- **Menu Location**: Main Dashboard
- **Display Name**: "Feh"
- **Tool ID**: `feh`
- **Status Display**: Installation status, version

## Key Characteristics

- **Version Detection**: `feh --version`
- **Configuration**: `~/.config/feh/` (optional)
- **Shell Integration**: None (standalone command)
- **Logging**: Uses `logger.sh` (structured logging)

## Dependencies

Build dependencies (handled by `install_deps_feh.sh`):
- libimlib2-dev
- libcurl4-openssl-dev
- libxinerama-dev
- libexif-dev
- libpng-dev

## Why Source Build?

- Latest features not available in Ubuntu repositories
- Custom icon support fixed in recent versions
- Desktop integration improvements

## Usage

```bash
feh image.png           # View single image
feh *.jpg               # Browse multiple images
feh --bg-scale img.png  # Set desktop background
```
