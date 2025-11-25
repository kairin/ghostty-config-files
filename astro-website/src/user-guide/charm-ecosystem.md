---
title: "Charm Bracelet TUI Ecosystem Integration"
description: "This project uses the [Charm Bracelet](https://charm.sh/) TUI (Terminal User Interface) ecosystem for beautiful, interactive terminal experiences. This guide explains which tools we use, why, and how they fit together."
pubDate: 2025-11-25
author: "Ghostty Config Team"
tags: ['user-guide', 'documentation']
---

# Charm Bracelet TUI Ecosystem Integration

## Overview

This project uses the [Charm Bracelet](https://charm.sh/) TUI (Terminal User Interface) ecosystem for beautiful, interactive terminal experiences. This guide explains which tools we use, why, and how they fit together.

## What is Charm Bracelet?

**Charm Bracelet** is a company that creates tools and libraries for building beautiful terminal user interfaces. They offer two categories of products:

1. **CLI Tools** - Standalone binaries usable in bash scripts
2. **Go Libraries** - Code libraries for building Go applications (NOT directly usable in bash)

## Tools We Use (CLI Applications)

### 1. gum - Complete TUI Framework ✅ INSTALLED

**Purpose**: All terminal UI elements (tables, spinners, prompts, styling)

**What It Does**:
- Interactive prompts (`gum confirm`, `gum choose`, `gum input`)
- Beautiful tables (`gum table`)
- Loading spinners (`gum spin`)
- Text styling (`gum style`, `gum format`)
- Pagination (`gum pager`)

**Installation**: APT via Charm repository
```bash
# Already integrated into ./start.sh
lib/installers/gum/install.sh
```

**Usage Examples**:
```bash
# Interactive confirmation
gum confirm "Continue with installation?"

# Beautiful tables
gum table --separator "|" --border rounded < data.csv

# Styled output
gum style --border rounded --padding "1 2" "Important Message"

# Loading spinner
gum spin --spinner dot --title "Processing..." -- sleep 5
```

**Architecture**: gum wraps the following Go libraries internally:
- `bubbletea` - TUI framework
- `bubbles` - TUI components
- `lipgloss` - Styling engine

This means you get ALL the functionality of those libraries through simple bash commands!

### 2. glow - Markdown Viewer ✅ INSTALLED

**Purpose**: Display markdown files with beautiful styling in the terminal

**What It Does**:
- Renders markdown with colors, formatting, code blocks
- Interactive TUI for browsing local markdown files
- Fetch and display READMEs from GitHub/GitLab

**Installation**: APT via Charm repository
```bash
# Already integrated into ./start.sh
lib/installers/glow/install.sh
```

**Usage Examples**:
```bash
# View a markdown file
glow README.md

# View with pager
glow documentation/setup/charm-ecosystem.md --pager

# Browse all markdown files in directory
glow .

# Fetch GitHub README
glow github.com/charmbracelet/gum
```

**Our Use Cases**:
- Display system audit reports (`logs/installation/system-state-*.md`)
- Show documentation during installation
- Render changelogs and release notes

**Architecture**: glow wraps the `glamour` Go library internally for markdown rendering.

### 3. vhs - Terminal Recorder ✅ INSTALLED

**Purpose**: Create demo GIFs and videos showing terminal sessions

**What It Does**:
- Record terminal sessions using declarative scripts (.tape files)
- Generate GIF and MP4 outputs
- Automate demo creation for documentation

**Dependencies**:
- `ffmpeg` - Video encoding
- `ttyd` - Terminal over HTTP

**Installation**: APT via Charm repository + dependencies
```bash
# Already integrated into ./start.sh
lib/installers/vhs/install.sh
```

**Usage Examples**:
```bash
# Record a demo from a tape file
vhs scripts/vhs/record-installation.tape

# Generate all demos
./scripts/vhs/generate-demos.sh
```

**Our Use Cases**:
- Automated demo generation after updates/commits
- Documentation videos for README
- Showcase installation process
- Record system audit workflow

**Tape File Example**:
```tape
Output documentation/demos/installation-demo.gif
Set Shell "bash"
Set FontSize 14
Set Width 1400
Set Height 900

Type "./start.sh"
Enter
Sleep 5s
```

## Libraries We DON'T Install (Go Only)

The following are Go libraries that **cannot be used directly in bash scripts**. They are already wrapped by the CLI tools above:

### bubbletea ❌ NOT INSTALLED
- **What**: Go framework for building TUI applications
- **Why not installed**: gum already wraps this for bash usage
- **Alternative**: Use `gum` commands

### bubbles ❌ NOT INSTALLED
- **What**: Go library for TUI components (tables, spinners, inputs)
- **Why not installed**: gum provides all components as CLI commands
- **Alternative**: Use `gum table`, `gum spin`, `gum input`, etc.

### lipgloss ❌ NOT INSTALLED
- **What**: Go library for terminal styling
- **Why not installed**: gum's `--border`, `--padding`, etc. flags ARE lipgloss
- **Alternative**: Use `gum style` and `gum format`

### glamour ❌ NOT INSTALLED
- **What**: Go library for markdown rendering
- **Why not installed**: glow already wraps this
- **Alternative**: Use `glow` command

### huh ❌ NOT INSTALLED
- **What**: Go library for building interactive forms
- **Why not installed**: gum provides equivalent form functionality
- **Alternative**: Use `gum input`, `gum choose`, `gum confirm`

### ultraviolet ❌ NOT INSTALLED
- **What**: Low-level terminal primitives (internal library)
- **Why not installed**: Not meant for direct consumption, unstable API
- **Alternative**: Use gum or glow

### colorprofile ❌ NOT INSTALLED
- **What**: Terminal color detection/handling library
- **Why not installed**: Internal library used by gum/glow
- **Alternative**: Handled automatically by gum and glow

## Why This Approach?

**Architecture Decision**: Bash-based installation system with modular installers

Installing Go libraries separately would require:
1. Writing Go code (not bash)
2. Compiling custom binaries
3. Managing Go dependencies
4. Maintaining custom wrappers

**Instead**: The Charm team already did this work! gum, glow, and vhs ARE the bash wrappers for these libraries.

**Result**: Zero additional value from installing Go libraries. The CLI tools provide 100% of the functionality we need.

## System Audit Integration

When you run `./start.sh`, the system audit now:

1. **Scans** for gum, glow, vhs, ffmpeg, ttyd
2. **Generates** markdown report: `logs/installation/system-state-YYYYMMDD-HHMMSS.md`
3. **Displays** with glow (if installed) or gum table (fallback)
4. **Documents** Charm ecosystem usage automatically

**View Reports**:
```bash
# List all system state reports
ls -lh logs/installation/system-state-*.md

# View latest with glow
glow logs/installation/system-state-*.md --pager

# View latest with less (fallback)
less logs/installation/system-state-$(ls -t logs/installation/system-state-*.md | head -1)
```

## VHS Demo Generation Workflow

### Automated Demo Updates

After every significant update/commit, VHS demos are regenerated:

```bash
# Manual generation
./scripts/vhs/generate-demos.sh

# Automatic (called by update workflows)
./scripts/vhs/post-update-demo.sh
```

### Demo Files

- **Tape Scripts**: `scripts/vhs/*.tape`
- **Generated GIFs**: `documentation/demos/*.gif`
- **Logs**: `logs/vhs-generation.log`

### Creating New Demos

1. Create a `.tape` file in `scripts/vhs/`
2. Define recording sequence (typing, commands, delays)
3. Run `./scripts/vhs/generate-demos.sh`
4. Commit generated GIF with your changes

**Example Tape**:
```tape
Output documentation/demos/my-feature.gif
Set Shell "bash"
Set FontSize 14
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set Theme "Catppuccin Mocha"

Type "# Demonstrating my new feature"
Enter
Sleep 1s
Type "./my-script.sh"
Enter
Sleep 5s
```

## Installation Methods

All Charm tools use the same APT repository:

```bash
# Add Charm repository (done automatically)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list

# Install via APT
sudo apt update
sudo apt install gum glow vhs
```

## Verification

Check installation status:

```bash
# Manual verification
gum --version
glow --version
vhs --version

# Automated verification (part of ./start.sh)
lib/verification/unit_tests.sh
```

## Further Reading

- **Charm Website**: https://charm.sh/
- **gum Documentation**: https://github.com/charmbracelet/gum
- **glow Documentation**: https://github.com/charmbracelet/glow
- **VHS Documentation**: https://github.com/charmbracelet/vhs
- **Charm Repository**: https://repo.charm.sh/

## Summary

| Tool | Type | Installed | Purpose | Wraps Library |
|------|------|-----------|---------|---------------|
| gum | CLI | ✅ Yes | TUI framework for bash | bubbletea, bubbles, lipgloss |
| glow | CLI | ✅ Yes | Markdown viewer | glamour |
| vhs | CLI | ✅ Yes | Terminal recorder | (standalone) |
| ffmpeg | Dependency | ✅ Yes | Video encoding for VHS | N/A |
| ttyd | Dependency | ✅ Yes | Terminal over HTTP for VHS | N/A |
| bubbletea | Go Lib | ❌ No | TUI framework | (wrapped by gum) |
| bubbles | Go Lib | ❌ No | TUI components | (wrapped by gum) |
| lipgloss | Go Lib | ❌ No | Styling engine | (wrapped by gum) |
| glamour | Go Lib | ❌ No | Markdown rendering | (wrapped by glow) |
| huh | Go Lib | ❌ No | Forms library | (use gum instead) |
| ultraviolet | Go Lib | ❌ No | Terminal primitives | (internal use only) |
| colorprofile | Go Lib | ❌ No | Color handling | (internal library) |

**Key Takeaway**: We use 3 CLI tools (gum, glow, vhs) which provide ALL the functionality of 7 Go libraries, perfectly suited for bash-based automation.
