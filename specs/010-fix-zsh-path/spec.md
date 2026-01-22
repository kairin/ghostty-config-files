# Feature Specification: Fix ZSH PATH Preservation

**Feature Branch**: `010-fix-zsh-path`  
**Created**: 2026-01-22  
**Status**: Draft  
**Input**: Bug #234 - ZSH reinstall breaks fnm/Node.js PATH - AI Tools show NOT_INSTALLED

## Problem Statement

When a user reinstalls ZSH via the TUI (Extras → ZSH + Plugins), their PATH configuration is broken. Specifically:
- fnm (Fast Node Manager) is not initialized
- `~/.local/bin` is not in PATH
- Node.js and npm-installed tools (Claude Code, Gemini CLI, GitHub Copilot) become inaccessible
- The TUI shows these tools as "NOT_INSTALLED" even though binaries exist on disk

### Root Cause Analysis

1. **`configure_zsh.sh`** relies on `configs/zsh/.zshrc.lazy-loading` for fnm initialization
2. **`.zshrc.lazy-loading`** checks for fnm in `$HOME/.local/share/fnm` but fnm is installed to `$HOME/.local/bin`
3. **`install_nodejs.sh`** adds fnm to `.zshrc` but `configure_zsh.sh` may overwrite these additions
4. **No PATH persistence** for `~/.local/bin` after ZSH reconfiguration

## User Scenarios & Testing *(mandatory)*

### User Story 1 - ZSH Reinstall Preserves Node.js Access (Priority: P1)

A user has Node.js and AI tools installed. They reinstall ZSH via the TUI to fix a configuration issue or update plugins. After the reinstall and terminal restart, all previously installed tools remain accessible.

**Why this priority**: This is the core bug being fixed. Without this, reinstalling ZSH breaks the user's development environment.

**Independent Test**: Install Node.js and AI tools, reinstall ZSH, restart terminal, verify `node`, `npm`, `claude`, `gemini`, `copilot` commands work.

**Acceptance Scenarios**:

1. **Given** Node.js is installed via fnm, **When** user reinstalls ZSH via TUI and restarts terminal, **Then** `node --version` returns the installed version
2. **Given** AI tools are installed via npm, **When** user reinstalls ZSH via TUI and restarts terminal, **Then** `which claude gemini copilot` returns valid paths
3. **Given** fnm is installed in `~/.local/bin`, **When** user opens a new terminal after ZSH reinstall, **Then** `echo $PATH` includes `~/.local/bin`

---

### User Story 2 - Fresh ZSH Install Sets Up PATH Correctly (Priority: P1)

A user with no prior ZSH configuration installs ZSH for the first time. The installation should set up PATH correctly so that when they later install Node.js/fnm, it will work immediately.

**Why this priority**: New users must have a working environment from the start.

**Independent Test**: Remove `.zshrc`, install ZSH via TUI, then install Node.js, verify it works without manual PATH configuration.

**Acceptance Scenarios**:

1. **Given** user has no `.zshrc`, **When** they install ZSH via TUI, **Then** `.zshrc` includes `~/.local/bin` in PATH
2. **Given** user has fresh ZSH install, **When** they install Node.js via TUI, **Then** `node` command works in new terminal without manual configuration

---

### User Story 3 - Existing PATH Customizations Preserved (Priority: P2)

A user has custom PATH entries in their `.zshrc` (e.g., Rust cargo, Go bin, custom scripts). After reinstalling ZSH, all their custom PATH entries remain intact.

**Why this priority**: Power users should not lose their customizations.

**Independent Test**: Add custom PATH entry to `.zshrc`, reinstall ZSH, verify custom entry still present.

**Acceptance Scenarios**:

1. **Given** user has `export PATH="$HOME/custom/bin:$PATH"` in `.zshrc`, **When** they reinstall ZSH, **Then** the custom PATH entry is preserved
2. **Given** user has Rust installed with cargo in PATH, **When** they reinstall ZSH, **Then** `cargo --version` still works

---

### Edge Cases

- What happens when `.zshrc` doesn't exist? → Create with correct defaults
- What happens when fnm is in non-standard location? → Check multiple known locations
- What happens when user has both nvm and fnm? → Both should work (lazy loading handles this)
- What happens when `.zshrc.lazy-loading` file doesn't exist? → Inline the critical PATH setup

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: ZSH configuration MUST add `$HOME/.local/bin` to PATH
- **FR-002**: ZSH configuration MUST source the lazy-loading file if it exists
- **FR-003**: ZSH configuration MUST NOT remove existing PATH entries during reconfiguration
- **FR-004**: Lazy-loading script MUST check correct fnm installation path (`~/.local/bin`, not `~/.local/share/fnm`)
- **FR-005**: ZSH configuration MUST backup `.zshrc` before making changes (already implemented)
- **FR-006**: Node.js installation script MUST verify PATH is correctly configured after installation
- **FR-007**: ZSH configuration MUST include fnm initialization even if lazy-loading file is missing

### Key Entities

- **`.zshrc`**: User's ZSH configuration file - must preserve custom content while ensuring required PATH entries
- **`.zshrc.lazy-loading`**: External file with lazy-loading patterns - must have correct fnm path
- **`~/.local/bin`**: Standard location for user-installed binaries (fnm, pip packages, etc.)
- **fnm**: Fast Node Manager - installed to `~/.local/bin/fnm`

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After ZSH reinstall, `which node` returns a valid path within 5 seconds of terminal open
- **SC-002**: After ZSH reinstall, `which claude` returns `/home/user/.local/bin/claude` or npm global path
- **SC-003**: TUI Dashboard shows AI Tools as "INSTALLED" after ZSH reinstall (no false NOT_INSTALLED)
- **SC-004**: ZSH shell startup time remains under 500ms (lazy loading preserved)
- **SC-005**: 100% of existing custom PATH entries preserved after ZSH reconfiguration
- **SC-006**: Zero manual intervention required to restore Node.js access after ZSH reinstall

## Files to Modify

1. **`configs/zsh/.zshrc.lazy-loading`** - Fix fnm path check (line 18: check `~/.local/bin` not `~/.local/share/fnm`)
2. **`scripts/004-reinstall/configure_zsh.sh`** - Ensure `~/.local/bin` PATH and fnm init are always present
3. **`scripts/004-reinstall/install_nodejs.sh`** - Add verification step at end to confirm PATH is correct

## Assumptions

- Users install fnm via the TUI which uses `--install-dir "$HOME/.local/bin"`
- `~/.local/bin` is the canonical location for user binaries on this system
- ZSH is the user's primary shell
- Oh My Zsh is used as the ZSH framework
