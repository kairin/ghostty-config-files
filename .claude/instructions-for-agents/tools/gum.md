# Gum Implementation Summary

Gum is a TUI component library from Charm.sh, used by `start.sh` itself for interactive menus and spinners.

## Core Scripts (`scripts/`)

| Stage | Script | Purpose |
|-------|--------|---------|
| 000 | `check_gum.sh` | Detect installation, version |
| 001 | `uninstall_gum.sh` | Remove via apt |
| 002 | `install_deps_gum.sh` | N/A (curl handled separately) |
| 003 | `verify_deps_gum.sh` | N/A |
| 004 | `install_gum.sh` | Install via Charm APT repository |
| 005 | `confirm_gum.sh` | Verify gum command works |

## Installation Strategy (`scripts/004-reinstall/install_gum.sh`)

### Charm Repository Setup (shared with glow, vhs)
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
- **Display Name**: "Gum"
- **Tool ID**: `gum`
- **Status Display**: Installation status, version, latest version
- **Bootstrap**: Installed automatically at `start.sh` launch if missing

## Key Characteristics

- **Version Detection**: `gum --version`
- **Latest Version Check**: GitHub API (`/repos/charmbracelet/gum/releases/latest`)
- **Configuration**: None
- **Shell Integration**: None (used as TUI library)
- **Logging**: Simple echo

## Dependencies

- curl (for GPG key download)

## Shared Repository

Gum shares the Charm APT repository with:
- [glow](glow.md)
- [vhs](vhs.md)

Installing any of these tools sets up the repository for the others.

## Usage in Project

Gum provides:
- `gum spin` - Animated spinners
- `gum choose` - Selection menus
- `gum confirm` - Confirmation dialogs
- `gum style` - Styled text output
- `gum table` - Formatted tables
