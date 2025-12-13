# Glow Implementation Summary

Glow is a terminal-based markdown renderer from Charm.sh, used for viewing documentation in the terminal.

## Core Scripts (`scripts/`)

| Stage | Script | Purpose |
|-------|--------|---------|
| 000 | `check_glow.sh` | Detect installation, version |
| 001 | `uninstall_glow.sh` | Remove via apt |
| 002 | `install_deps_glow.sh` | N/A (curl handled separately) |
| 003 | `verify_deps_glow.sh` | N/A |
| 004 | `install_glow.sh` | Install via Charm APT repository |
| 005 | `confirm_glow.sh` | Verify glow command works |

## Installation Strategy (`scripts/004-reinstall/install_glow.sh`)

### Charm Repository Setup (shared with gum, vhs)
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
- **Display Name**: "Glow"
- **Tool ID**: `glow`
- **Status Display**: Installation status, version, latest version

## Key Characteristics

- **Version Detection**: `glow --version`
- **Latest Version Check**: GitHub API (`/repos/charmbracelet/glow/releases/latest`)
- **Configuration**: Optional `~/.config/glow/` for themes
- **Shell Integration**: None (standalone command)
- **Logging**: Simple echo

## Dependencies

- curl (for GPG key download)

## Shared Repository

Glow shares the Charm APT repository with:
- [gum](gum.md)
- [vhs](vhs.md)

Installing any of these tools sets up the repository for the others.

## Usage

```bash
glow README.md          # Render markdown file
glow                    # Browse markdown files interactively
glow https://example.com/doc.md  # Render from URL
```
