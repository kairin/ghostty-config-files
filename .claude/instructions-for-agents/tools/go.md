# Go Implementation Summary

Go is the Go programming language, installed from official tarballs for the latest version.

## Core Scripts (`scripts/`)

| Stage | Script | Purpose |
|-------|--------|---------|
| 000 | `check_go.sh` | Detect installation, version |
| 001 | `uninstall_go.sh` | Remove /usr/local/go and symlinks |
| 002 | `install_deps_go.sh` | Install wget |
| 003 | `verify_deps_go.sh` | Verify wget available |
| 004 | `install_go.sh` | Download and install official tarball |
| 005 | `confirm_go.sh` | Verify go command works |

## Installation Strategy (`scripts/004-reinstall/install_go.sh`)

### Version Detection
1. Query go.dev API: `https://go.dev/dl/?mode=json`
2. Extract latest version string

### Download and Install
1. Detect OS and architecture (linux-amd64, linux-arm64, etc.)
2. Download tarball from: `https://go.dev/dl/${VERSION}.${OS}-${ARCH}.tar.gz`
3. Remove old installation: `/usr/local/go`
4. Extract to `/usr/local/`
5. Create symlinks in `/usr/local/bin/`:
   - `go` -> `/usr/local/go/bin/go`
   - `gofmt` -> `/usr/local/go/bin/gofmt`

## TUI Integration (`start.sh`)

- **Menu Location**: Extras Dashboard
- **Display Name**: "Go"
- **Tool ID**: `go`
- **Status Display**: Installation status, version, latest version

## Key Characteristics

- **Version Detection**: `go version` or go.dev API
- **Latest Version Check**: go.dev API (`/dl/?mode=json`)
- **Installation Location**: `/usr/local/go/`
- **Configuration**: `GOPATH` (default: `~/go`)
- **Shell Integration**: Symlinks in `/usr/local/bin/`
- **Logging**: Simple echo

## Dependencies

- wget (for downloading tarball)

## Architecture Support

| System Arch | Go Arch |
|-------------|---------|
| x86_64 | amd64 |
| aarch64 | arm64 |
| armv7l | armv6l |

## Environment Variables

Typically set in shell config:
```bash
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
```
