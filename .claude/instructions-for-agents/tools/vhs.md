# VHS Implementation Summary

VHS is a terminal recording and GIF generation tool from Charm.sh, used for creating demo recordings.

## Core Scripts (`scripts/`)

| Stage | Script | Purpose |
|-------|--------|---------|
| 000 | `check_vhs.sh` | Detect installation, version |
| 001 | `uninstall_vhs.sh` | Remove via apt |
| 002 | `install_deps_vhs.sh` | N/A (curl handled separately) |
| 003 | `verify_deps_vhs.sh` | N/A |
| 004 | `install_vhs.sh` | Install via Charm APT repository |
| 005 | `confirm_vhs.sh` | Verify vhs command works |

## Installation Strategy (`scripts/004-reinstall/install_vhs.sh`)

### Charm Repository Setup (shared with gum, glow)
1. Create keyring directory: `/etc/apt/keyrings/`
2. Download GPG key: `https://repo.charm.sh/apt/gpg.key`
3. Convert to keyring: `/etc/apt/keyrings/charm.gpg`
4. Add repository: `/etc/apt/sources.list.d/charm.list`
5. Update apt and install

### Repository Details
- **GPG Key**: `https://repo.charm.sh/apt/gpg.key`
- **Keyring**: `/etc/apt/keyrings/charm.gpg`
- **Source List**: `/etc/apt/sources.list.d/charm.list`
- **Repository**: `deb [signed-by=...] https://repo.charm.sh/apt/ * *`

## TUI Integration (`start.sh`)

- **Menu Location**: Extras Dashboard
- **Display Name**: "VHS"
- **Tool ID**: `vhs`
- **Status Display**: Installation status, version, latest version
- **Demo Mode Integration**: Used for recording demo sessions

## Key Characteristics

- **Version Detection**: `vhs --version`
- **Latest Version Check**: GitHub API (`/repos/charmbracelet/vhs/releases/latest`)
- **Configuration**: None (uses .tape files)
- **Shell Integration**: None (standalone command)
- **Logging**: Simple echo

## Dependencies

- curl (for GPG key download)
- ffmpeg (for video processing)
- ttyd (for terminal rendering)

## Shared Repository

VHS shares the Charm APT repository with:
- [gum](gum.md)
- [glow](glow.md)

Installing any of these tools sets up the repository for the others.

## Usage in Project

VHS is used for:
- Demo Mode in `start.sh` (records installation demos)
- Creating GIF animations for documentation
- Recording terminal sessions for the website

## Tape Files

VHS uses `.tape` files to define recordings:
- Location: `scripts/vhs/`
- Format: Declarative commands for terminal recording
