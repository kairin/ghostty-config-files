# Node.js Implementation Summary

Node.js is installed via fnm (Fast Node Manager) for version management, with Node.js v25 as default.

## Core Scripts (`scripts/`)

| Stage | Script | Purpose |
|-------|--------|---------|
| 000 | `check_nodejs.sh` | Detect fnm, Node.js, npm versions |
| 001 | `uninstall_nodejs.sh` | Remove fnm and Node.js installations |
| 002 | `install_deps_nodejs.sh` | Install curl |
| 003 | `verify_deps_nodejs.sh` | Verify curl available |
| 004 | `install_nodejs.sh` | Install fnm + Node.js v25 |
| 005 | `confirm_nodejs.sh` | Verify node and npm work |

## Installation Strategy (`scripts/004-reinstall/install_nodejs.sh`)

### fnm Installation
1. Download installer: `curl -fsSL https://fnm.vercel.app/install`
2. Install to: `~/.local/bin/`
3. Skip shell integration (handled separately)

### Node.js Installation
1. Initialize fnm: `eval "$(fnm env)"`
2. Install Node.js: `fnm install 25`
3. Set as default: `fnm use 25 && fnm default 25`

### Optional Global Packages
When `INSTALL_ASTRO_PACKAGES=1`:
- tailwindcss@latest
- @tailwindcss/vite@latest
- daisyui@latest

### Shell Integration
Adds to `.zshrc` or `.bashrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
eval "$(fnm env --use-on-cd)"
```

## TUI Integration (`start.sh`)

- **Menu Location**: Main Dashboard
- **Display Name**: "Node.js"
- **Tool ID**: `nodejs`
- **Status Display**: fnm version, Node.js version, npm version
- **Special Option**: "Install Global Packages" for Tailwind/DaisyUI

## Key Characteristics

- **Version Detection**: `node -v`, `npm -v`, `fnm --version`
- **Latest Version Check**: `fnm ls-remote`
- **Installation Location**: `~/.local/share/fnm/`
- **Configuration**: fnm manages Node.js versions
- **Shell Integration**: fnm env in shell rc file
- **Logging**: Uses `logger.sh` (structured logging)

## Bundled Tools

Node.js installation automatically includes the following bundled tools:

| Tool | Purpose |
|------|---------|
| **fnm** | Fast Node Manager - cross-platform Node.js version manager |
| **npm** | Node Package Manager (included with Node.js) |

These are automatically installed and configured when you install Node.js via the TUI.

## Dependencies

- curl (for fnm installation)

## fnm Benefits

- Fast version switching
- Per-directory Node.js versions (`.node-version`)
- Cross-platform support
- No sudo required

## Environment Variables

Set by fnm env:
- `FNM_MULTISHELL_PATH`
- `FNM_VERSION_FILE_STRATEGY`
- `FNM_DIR`
- `FNM_LOGLEVEL`
- `FNM_NODE_DIST_MIRROR`
- `FNM_COREPACK_ENABLED`
- `FNM_RESOLVE_ENGINES`
- `FNM_ARCH`

## Troubleshooting

### "npm not found" in zsh

**Symptom**: `npm` or `node` commands fail with "command not found" in zsh terminals, but work in bash.

**Cause**: The fnm installer adds shell integration to `.bashrc` only. If your default shell is zsh (which is the default for this project), you need to add fnm initialization to `.zshrc` as well.

**Fix**: Add these lines to `~/.zshrc`:

```bash
# fnm - Fast Node Manager
export PATH="$HOME/.local/bin:$PATH"
eval "$(fnm env --use-on-cd)"
```

**Verify**: Open a new terminal and run:

```bash
npm --version   # Should show version like 11.6.2
node --version  # Should show version like v25.2.1
```

### Check Default Shell

```bash
# View your default shell
echo $SHELL

# If it shows /usr/bin/zsh or /bin/zsh, you need fnm in .zshrc
# If it shows /bin/bash, fnm should already work
```
