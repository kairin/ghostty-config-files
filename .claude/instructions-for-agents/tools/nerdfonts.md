# Nerd Fonts Implementation Summary

Nerd Fonts provides developer fonts with programming icons, installing 8 popular font families.

## Core Scripts (`scripts/`)

| Stage | Script | Purpose |
|-------|--------|---------|
| 000 | `check_nerdfonts.sh` | Detect installed fonts (all 8 families) |
| 001 | `uninstall_nerdfonts.sh` | Remove all font files |
| 002 | `install_deps_nerdfonts.sh` | Install curl, tar |
| 003 | `verify_deps_nerdfonts.sh` | Verify extraction tools |
| 004 | `install_nerdfonts.sh` | Download and install all 8 fonts |
| 005 | `confirm_nerdfonts.sh` | Verify fonts visible to fontconfig |

## Installation Strategy (`scripts/004-reinstall/install_nerdfonts.sh`)

### Font Families (8 total)
1. JetBrainsMono
2. FiraCode
3. Hack
4. Meslo
5. CascadiaCode
6. SourceCodePro
7. IBMPlexMono
8. Iosevka

### Download Process
- **Version**: v3.4.0 (hardcoded)
- **Source**: GitHub releases
- **Format**: tar.xz archives
- **URL Pattern**: `https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${FONT}.tar.xz`

### Installation
1. Create fonts directory: `~/.local/share/fonts/`
2. Download each font archive
3. Extract to fonts directory
4. Refresh font cache: `fc-cache -fv`

## TUI Integration (`start.sh`)

- **Menu Location**: Main Dashboard
- **Display Name**: "Nerd Fonts"
- **Tool ID**: `nerdfonts`
- **Status Display**: Individual status for each of 8 fonts

## Key Characteristics

- **Version Detection**: Hardcoded v3.4.0
- **Installation Location**: `~/.local/share/fonts/`
- **Configuration**: None (system fontconfig handles it)
- **Shell Integration**: None
- **Logging**: Uses `logger.sh` (structured logging)

## Dependencies

- curl (for downloads)
- tar with xz support (for extraction)

## Font Cache

After installation, fonts are registered via:
```bash
fc-cache -fv ~/.local/share/fonts/
```

## Verification

Check installed fonts:
```bash
fc-list | grep -i "JetBrainsMono Nerd"
fc-list | grep -i "FiraCode Nerd"
```

## Usage with Ghostty

In `~/.config/ghostty/config`:
```
font-family = JetBrainsMono Nerd Font
```
