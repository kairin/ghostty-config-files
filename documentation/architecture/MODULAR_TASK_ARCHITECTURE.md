# Modular Task Architecture Design

**Date**: 2025-11-20
**Purpose**: Break down monolithic task files into single-purpose modular scripts
**Status**: Design Phase
**Location**: `/documentation/architecture/MODULAR_TASK_ARCHITECTURE.md` (restructured 2025-11-20)
**User Requirement**: "Each step is calling a script that does the one thing for that segment of the process"

**Note**: Repository restructured on 2025-11-20 to consolidate fragmented documentation:
- ✅ Single `/documentation/` folder (was: `/docs-setup/`, `/documentations/`, `/specs/`)
- ✅ Single `/astro-website/` folder (was: `/website/` + root `/src/` + root `/public/`)
- ✅ Archived spec-kit to `/archive-spec-kit/.specify/`
- ✅ Deleted obsolete `/delete/` folder

---

## Problem Statement

### Current Issues

1. **Monolithic Task Files**: Each lib/tasks/*.sh file contains hundreds of lines doing multiple things
   - `lib/tasks/ghostty.sh`: Check, download Zig, build Zig, clone Ghostty, build Ghostty, install, verify
   - `lib/tasks/python_uv.sh`: Check, download, extract, install, verify
   - `lib/tasks/nodejs_fnm.sh`: Check, download, install, setup, verify

2. **Output Visibility**: Users cannot see real-time progress during long operations
   - Git clone operations
   - Zig builds
   - tar extractions
   - npm installations

3. **Lack of Granularity**: Cannot track individual sub-steps in TUI
   - Task shows "Installing Ghostty..." for 3+ minutes
   - No visibility into "Downloading Zig", "Building Zig", "Cloning Ghostty", etc.

4. **Difficult Debugging**: When something fails, unclear which specific step failed
   - Was it the download? The extraction? The build?

### User's Vision

> "the whole point of the tui and gum and bracelet was that user will see the full verbose steps even the section such as what's going on with the cloning of ghostty. and that when the segment completes, the segment will be collapsed with the tui / gum / bracelet."

**Key Requirements**:
- Real-time output visibility during long operations
- Automatic collapsing when segment completes
- Each step is a separate script doing ONE thing
- Modular, maintainable, debuggable

---

## Design Principles

### 1. Single Responsibility
Each script does **exactly one thing**:
- ✅ `00-check-prerequisites.sh` - Only checks if Ghostty already installed
- ✅ `01-download-zig.sh` - Only downloads Zig compiler
- ✅ `02-extract-zig.sh` - Only extracts Zig tarball
- ✅ `03-build-ghostty.sh` - Only builds Ghostty
- ❌ `install-ghostty.sh` - Does everything (anti-pattern)

### 2. Standardized Interface
All scripts follow the same contract:

```bash
#!/usr/bin/env bash
#
# Module: [Task Name]
# Purpose: [One-sentence description of what this script does]
# Prerequisites: [What must exist before this runs]
# Outputs: [What this script creates/modifies]
# Exit Codes:
#   0 - Success
#   1 - Failure (fatal)
#   2 - Skip (already done, idempotent)
#

set -euo pipefail

# Input validation
if [ $# -lt 1 ]; then
    echo "Usage: $0 <required-arg>" >&2
    exit 1
fi

# Main logic (single responsibility)
main() {
    # Do ONE thing
    # Use run_command_collapsible for long operations
}

main "$@"
```

### 3. Collapsible Output Integration
Every script uses `run_command_collapsible` for long operations:

```bash
# In ghostty/03-clone-repository.sh
source "${SCRIPT_DIR}/../../lib/ui/collapsible.sh"

task_id="ghostty-clone"
register_task "$task_id" "Cloning Ghostty repository"
start_task "$task_id"

run_command_collapsible "$task_id" git clone \
    --depth 1 \
    https://github.com/ghostty-org/ghostty \
    "$GHOSTTY_SRC"

complete_task "$task_id" "$duration"
```

### 4. Task Registry Integration
start.sh registers each modular step as a separate task:

```bash
readonly TASK_REGISTRY=(
    # Ghostty installation broken into granular steps
    "ghostty-00-check|verify-prereqs|ghostty/00-check-prerequisites.sh|verify_ghostty_not_installed|1|5"
    "ghostty-01-download-zig|ghostty-00-check|ghostty/01-download-zig.sh|verify_zig_tarball|1|30"
    "ghostty-02-extract-zig|ghostty-01-download-zig|ghostty/02-extract-zig.sh|verify_zig_extracted|1|10"
    "ghostty-03-build-zig|ghostty-02-extract-zig|ghostty/03-build-zig.sh|verify_zig_binary|1|60"
    "ghostty-04-clone-repo|ghostty-03-build-zig|ghostty/04-clone-repository.sh|verify_ghostty_repo|1|20"
    "ghostty-05-build-ghostty|ghostty-04-clone-repo|ghostty/05-build-ghostty.sh|verify_ghostty_binary|1|90"
    "ghostty-06-install|ghostty-05-build-ghostty|ghostty/06-install-binary.sh|verify_ghostty_installed|1|10"
    "ghostty-07-verify|ghostty-06-install|ghostty/07-verify-installation.sh|verify_ghostty_version|1|5"
)
```

### 5. Idempotency
Each script checks if its work is already done:

```bash
# In ghostty/01-download-zig.sh
if [ -f "$ZIG_TARBALL" ]; then
    echo "Zig tarball already downloaded: $ZIG_TARBALL"
    exit 2  # Skip code
fi
```

---

## Directory Structure

### Current Monolithic Structure
```
lib/tasks/
├── ghostty.sh          # 500+ lines, does everything
├── zsh.sh              # 300+ lines, does everything
├── python_uv.sh        # 200+ lines, does everything
├── nodejs_fnm.sh       # 150+ lines, does everything
├── ai_tools.sh         # 100+ lines, does everything
├── context_menu.sh     # 50+ lines
├── gum.sh              # 100+ lines
└── app_audit.sh        # 200+ lines
```

### Proposed Modular Structure
```
lib/tasks/
├── ghostty/
│   ├── 00-check-prerequisites.sh      # 50 lines - Check if already installed
│   ├── 01-download-zig.sh             # 80 lines - Download Zig compiler
│   ├── 02-extract-zig.sh              # 60 lines - Extract Zig tarball
│   ├── 03-build-zig.sh                # 100 lines - Build Zig from source (if needed)
│   ├── 04-clone-repository.sh         # 70 lines - Clone Ghostty repo
│   ├── 05-build-ghostty.sh            # 120 lines - Build Ghostty with Zig
│   ├── 06-install-binary.sh           # 80 lines - Install to system
│   ├── 07-verify-installation.sh      # 60 lines - Verify Ghostty works
│   └── common.sh                      # 100 lines - Shared functions
│
├── zsh/
│   ├── 00-check-prerequisites.sh      # 40 lines - Check ZSH installed
│   ├── 01-install-oh-my-zsh.sh        # 100 lines - Install Oh My ZSH
│   ├── 02-install-plugins.sh          # 120 lines - Install plugins
│   ├── 03-configure-zshrc.sh          # 150 lines - Update .zshrc
│   ├── 04-install-security-check.sh   # 80 lines - ZSH security integration
│   ├── 05-verify-installation.sh      # 60 lines - Verify ZSH works
│   └── common.sh                      # 80 lines - Shared functions
│
├── python_uv/
│   ├── 00-check-prerequisites.sh      # 40 lines - Check UV not installed
│   ├── 01-download-uv.sh              # 70 lines - Download UV tarball
│   ├── 02-extract-uv.sh               # 60 lines - Extract UV
│   ├── 03-install-uv.sh               # 80 lines - Install to ~/.local/bin
│   ├── 04-verify-installation.sh      # 60 lines - Verify UV works
│   └── common.sh                      # 50 lines - Shared functions
│
├── nodejs_fnm/
│   ├── 00-check-prerequisites.sh      # 40 lines - Check fnm not installed
│   ├── 01-download-fnm.sh             # 70 lines - Download fnm binary
│   ├── 02-install-fnm.sh              # 80 lines - Install fnm
│   ├── 03-install-nodejs.sh           # 100 lines - Install Node.js via fnm
│   ├── 04-configure-shell.sh          # 90 lines - Add to .zshrc/.bashrc
│   ├── 05-verify-installation.sh      # 60 lines - Verify fnm and Node.js
│   └── common.sh                      # 60 lines - Shared functions
│
├── ai_tools/
│   ├── 00-check-prerequisites.sh      # 40 lines - Check Node.js available
│   ├── 01-install-claude-cli.sh       # 80 lines - Install @anthropic-ai/claude-code
│   ├── 02-install-gemini-cli.sh       # 80 lines - Install @google/gemini-cli
│   ├── 03-install-copilot-cli.sh      # 80 lines - Install @github/copilot
│   ├── 04-verify-installation.sh      # 70 lines - Verify all CLIs work
│   └── common.sh                      # 50 lines - Shared functions
│
├── context_menu/
│   ├── 00-check-prerequisites.sh      # 40 lines - Check Nautilus installed
│   ├── 01-install-context-menu.sh     # 100 lines - Install Nautilus script
│   ├── 02-verify-installation.sh      # 60 lines - Verify context menu works
│   └── common.sh                      # 40 lines - Shared functions
│
├── gum/
│   ├── 00-check-prerequisites.sh      # 40 lines - Check gum not installed
│   ├── 01-download-gum.sh             # 70 lines - Download gum binary
│   ├── 02-install-gum.sh              # 80 lines - Install gum
│   ├── 03-verify-installation.sh      # 60 lines - Verify gum works
│   └── common.sh                      # 50 lines - Shared functions
│
└── app_audit/
    ├── 00-check-prerequisites.sh      # 40 lines - Check prerequisites
    ├── 01-scan-apt-packages.sh        # 100 lines - Scan APT packages
    ├── 02-scan-snap-packages.sh       # 100 lines - Scan Snap packages
    ├── 03-scan-desktop-files.sh       # 100 lines - Scan .desktop files
    ├── 04-detect-duplicates.sh        # 120 lines - Detect duplicate apps
    ├── 05-generate-report.sh          # 100 lines - Generate audit report
    ├── 06-verify-report.sh            # 60 lines - Verify report generated
    └── common.sh                      # 80 lines - Shared functions
```

**Total Scripts**: ~50 modular scripts (vs 8 monolithic files)

**Benefits**:
- Each script is <150 lines (highly maintainable)
- Clear single responsibility
- Easy to debug (failures pinpoint exact step)
- Idempotent (can re-run individual steps)
- TUI shows granular progress

---

## Example Breakdown: Ghostty Installation

### Before (Monolithic)

**File**: `lib/tasks/ghostty.sh` (500+ lines)

```bash
task_install_ghostty() {
    # 1. Check if installed (50 lines)
    # 2. Download Zig (80 lines)
    # 3. Extract Zig (60 lines)
    # 4. Build Zig (100 lines)
    # 5. Clone Ghostty (70 lines)
    # 6. Build Ghostty (120 lines)
    # 7. Install binary (80 lines)
    # 8. Verify installation (60 lines)

    # User sees: "⠋ Installing Ghostty..." for 3+ minutes
    # No visibility into sub-steps
}
```

**User Experience**:
```
⠋ Installing Ghostty...
[3 minutes of silence, no output]
✓ Installing Ghostty (180s)
```

### After (Modular)

**Directory**: `lib/tasks/ghostty/`

**8 separate scripts**, each doing ONE thing:

#### `00-check-prerequisites.sh`
```bash
#!/usr/bin/env bash
#
# Module: Ghostty Prerequisites Check
# Purpose: Check if Ghostty is already installed (idempotency)
# Prerequisites: None
# Outputs: Exit code 2 if already installed, 0 if not installed
# Exit Codes:
#   0 - Not installed (proceed with installation)
#   1 - Error checking
#   2 - Already installed (skip installation)
#

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

main() {
    if command -v ghostty &>/dev/null; then
        local version
        version=$(ghostty --version 2>/dev/null || echo "unknown")
        log_info "Ghostty already installed: $version"
        exit 2  # Skip code
    fi

    log_info "Ghostty not found - installation required"
    exit 0
}

main "$@"
```

#### `01-download-zig.sh`
```bash
#!/usr/bin/env bash
#
# Module: Download Zig Compiler
# Purpose: Download Zig 0.14.0 tarball for Ghostty build
# Prerequisites: curl or wget installed
# Outputs: $HOME/Downloads/zig-linux-x86_64-0.14.0.tar.xz
# Exit Codes:
#   0 - Download successful
#   1 - Download failed
#   2 - Already downloaded (skip)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/../../ui/collapsible.sh"

readonly ZIG_VERSION="0.14.0"
readonly ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
readonly ZIG_TARBALL="$HOME/Downloads/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"

main() {
    # Idempotency check
    if [ -f "$ZIG_TARBALL" ]; then
        log_info "Zig tarball already downloaded: $ZIG_TARBALL"
        exit 2
    fi

    # Register task for TUI
    local task_id="ghostty-download-zig"
    register_task "$task_id" "Downloading Zig ${ZIG_VERSION}"
    start_task "$task_id"

    # Download with collapsible output
    local start_time
    start_time=$(get_unix_timestamp)

    if run_command_collapsible "$task_id" curl -fsSL -o "$ZIG_TARBALL" "$ZIG_URL"; then
        local end_time
        end_time=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$start_time" "$end_time")

        complete_task "$task_id" "$duration"
        log_success "Downloaded Zig to $ZIG_TARBALL"
        exit 0
    else
        fail_task "$task_id" "Download failed: $ZIG_URL"
        log_error "Failed to download Zig from $ZIG_URL"
        exit 1
    fi
}

main "$@"
```

#### `04-clone-repository.sh`
```bash
#!/usr/bin/env bash
#
# Module: Clone Ghostty Repository
# Purpose: Clone Ghostty source code from GitHub
# Prerequisites: git installed, Zig compiler ready
# Outputs: $HOME/Apps/ghostty/ repository
# Exit Codes:
#   0 - Clone successful
#   1 - Clone failed
#   2 - Already cloned (skip)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/../../ui/collapsible.sh"

readonly GHOSTTY_REPO="https://github.com/ghostty-org/ghostty"
readonly GHOSTTY_SRC="$HOME/Apps/ghostty"

main() {
    # Idempotency check
    if [ -d "$GHOSTTY_SRC/.git" ]; then
        log_info "Ghostty repository already cloned: $GHOSTTY_SRC"
        exit 2
    fi

    # Clean up partial clones
    if [ -d "$GHOSTTY_SRC" ] && [ ! -d "$GHOSTTY_SRC/.git" ]; then
        log_warning "Removing incomplete clone: $GHOSTTY_SRC"
        rm -rf "$GHOSTTY_SRC"
    fi

    # Register task for TUI
    local task_id="ghostty-clone-repo"
    register_task "$task_id" "Cloning Ghostty repository"
    start_task "$task_id"

    # Clone with collapsible output (user sees real-time git output)
    local start_time
    start_time=$(get_unix_timestamp)

    if run_command_collapsible "$task_id" git clone --depth 1 "$GHOSTTY_REPO" "$GHOSTTY_SRC"; then
        local end_time
        end_time=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$start_time" "$end_time")

        complete_task "$task_id" "$duration"
        log_success "Cloned Ghostty to $GHOSTTY_SRC"
        exit 0
    else
        fail_task "$task_id" "Git clone failed: $GHOSTTY_REPO"
        log_error "Failed to clone Ghostty from $GHOSTTY_REPO"
        exit 1
    fi
}

main "$@"
```

#### `05-build-ghostty.sh`
```bash
#!/usr/bin/env bash
#
# Module: Build Ghostty with Zig
# Purpose: Build Ghostty binary using Zig compiler
# Prerequisites: Zig compiler installed, Ghostty repo cloned
# Outputs: $HOME/Apps/ghostty/zig-out/bin/ghostty binary
# Exit Codes:
#   0 - Build successful
#   1 - Build failed
#   2 - Already built (skip)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/../../ui/collapsible.sh"

readonly GHOSTTY_SRC="$HOME/Apps/ghostty"
readonly GHOSTTY_BINARY="$GHOSTTY_SRC/zig-out/bin/ghostty"
readonly ZIG_BINARY="$HOME/Apps/zig/zig"

main() {
    # Idempotency check
    if [ -f "$GHOSTTY_BINARY" ]; then
        log_info "Ghostty already built: $GHOSTTY_BINARY"
        exit 2
    fi

    # Verify prerequisites
    if [ ! -f "$ZIG_BINARY" ]; then
        log_error "Zig compiler not found: $ZIG_BINARY"
        exit 1
    fi

    if [ ! -d "$GHOSTTY_SRC" ]; then
        log_error "Ghostty source not found: $GHOSTTY_SRC"
        exit 1
    fi

    # Register task for TUI
    local task_id="ghostty-build"
    register_task "$task_id" "Building Ghostty with Zig"
    start_task "$task_id"

    # Build with collapsible output (user sees real-time Zig build output)
    local start_time
    start_time=$(get_unix_timestamp)

    cd "$GHOSTTY_SRC"

    if run_command_collapsible "$task_id" "$ZIG_BINARY" build -Doptimize=ReleaseFast; then
        local end_time
        end_time=$(get_unix_timestamp)
        local duration
        duration=$(calculate_duration "$start_time" "$end_time")

        complete_task "$task_id" "$duration"
        log_success "Built Ghostty: $GHOSTTY_BINARY"
        exit 0
    else
        fail_task "$task_id" "Zig build failed"
        log_error "Failed to build Ghostty with Zig"
        exit 1
    fi
}

main "$@"
```

**User Experience with Modular Scripts**:
```
✓ Ghostty Prerequisites Check (0s)
⠋ Downloading Zig 0.14.0...
  [Real-time curl progress bar visible]
✓ Downloading Zig 0.14.0 (30s)
⠋ Extracting Zig tarball...
  [Real-time tar extraction output]
✓ Extracting Zig tarball (10s)
⠋ Cloning Ghostty repository...
  Cloning into '/home/kkk/Apps/ghostty'...
  remote: Enumerating objects: 1234, done.
  remote: Counting objects: 100% (1234/1234), done.
  remote: Compressing objects: 100% (567/567), done.
  Receiving objects: 100% (1234/1234), 2.34 MiB | 5.67 MiB/s, done.
✓ Cloning Ghostty repository (20s)
⠋ Building Ghostty with Zig...
  [Real-time Zig build output]
  info: building ghostty (release-fast)
  info: compiling src/main.zig
  ...
✓ Building Ghostty with Zig (90s)
⠋ Installing Ghostty binary...
✓ Installing Ghostty binary (10s)
✓ Verifying Ghostty installation (5s)
```

---

## Task Registry Integration

### Orchestrator Changes (start.sh)

**Replace monolithic task entries** with granular modular steps:

```bash
readonly TASK_REGISTRY=(
    # ═══════════════════════════════════════════════════════════════
    # Prerequisites
    # ═══════════════════════════════════════════════════════════════
    "verify-prereqs||pre_installation_health_check|verify_health|0|10"

    # ═══════════════════════════════════════════════════════════════
    # Gum TUI Framework (parallel group 1)
    # ═══════════════════════════════════════════════════════════════
    "gum-00-check|verify-prereqs|gum/00-check-prerequisites.sh|verify_gum_not_installed|1|5"
    "gum-01-download|gum-00-check|gum/01-download-gum.sh|verify_gum_tarball|1|10"
    "gum-02-install|gum-01-download|gum/02-install-gum.sh|verify_gum_binary|1|10"
    "gum-03-verify|gum-02-install|gum/03-verify-installation.sh|verify_gum_version|1|5"

    # ═══════════════════════════════════════════════════════════════
    # Ghostty Terminal (parallel group 1)
    # ═══════════════════════════════════════════════════════════════
    "ghostty-00-check|verify-prereqs|ghostty/00-check-prerequisites.sh|verify_ghostty_not_installed|1|5"
    "ghostty-01-download-zig|ghostty-00-check|ghostty/01-download-zig.sh|verify_zig_tarball|1|30"
    "ghostty-02-extract-zig|ghostty-01-download-zig|ghostty/02-extract-zig.sh|verify_zig_extracted|1|10"
    "ghostty-03-build-zig|ghostty-02-extract-zig|ghostty/03-build-zig.sh|verify_zig_binary|1|60"
    "ghostty-04-clone-repo|ghostty-03-build-zig|ghostty/04-clone-repository.sh|verify_ghostty_repo|1|20"
    "ghostty-05-build|ghostty-04-clone-repo|ghostty/05-build-ghostty.sh|verify_ghostty_binary|1|90"
    "ghostty-06-install|ghostty-05-build|ghostty/06-install-binary.sh|verify_ghostty_installed|1|10"
    "ghostty-07-verify|ghostty-06-install|ghostty/07-verify-installation.sh|verify_ghostty_version|1|5"

    # ═══════════════════════════════════════════════════════════════
    # ZSH Configuration (parallel group 1)
    # ═══════════════════════════════════════════════════════════════
    "zsh-00-check|verify-prereqs|zsh/00-check-prerequisites.sh|verify_zsh_installed|1|5"
    "zsh-01-oh-my-zsh|zsh-00-check|zsh/01-install-oh-my-zsh.sh|verify_oh_my_zsh|1|30"
    "zsh-02-plugins|zsh-01-oh-my-zsh|zsh/02-install-plugins.sh|verify_plugins|1|20"
    "zsh-03-configure|zsh-02-plugins|zsh/03-configure-zshrc.sh|verify_zshrc|1|10"
    "zsh-04-security|zsh-03-configure|zsh/04-install-security-check.sh|verify_security|1|5"
    "zsh-05-verify|zsh-04-security|zsh/05-verify-installation.sh|verify_zsh_config|1|5"

    # ═══════════════════════════════════════════════════════════════
    # Python UV (parallel group 1)
    # ═══════════════════════════════════════════════════════════════
    "uv-00-check|verify-prereqs|python_uv/00-check-prerequisites.sh|verify_uv_not_installed|1|5"
    "uv-01-download|uv-00-check|python_uv/01-download-uv.sh|verify_uv_tarball|1|15"
    "uv-02-extract|uv-01-download|python_uv/02-extract-uv.sh|verify_uv_extracted|1|10"
    "uv-03-install|uv-02-extract|python_uv/03-install-uv.sh|verify_uv_binary|1|10"
    "uv-04-verify|uv-03-install|python_uv/04-verify-installation.sh|verify_uv_version|1|10"

    # ═══════════════════════════════════════════════════════════════
    # Node.js FNM (parallel group 1)
    # ═══════════════════════════════════════════════════════════════
    "fnm-00-check|verify-prereqs|nodejs_fnm/00-check-prerequisites.sh|verify_fnm_not_installed|1|5"
    "fnm-01-download|fnm-00-check|nodejs_fnm/01-download-fnm.sh|verify_fnm_tarball|1|10"
    "fnm-02-install-fnm|fnm-01-download|nodejs_fnm/02-install-fnm.sh|verify_fnm_binary|1|10"
    "fnm-03-install-nodejs|fnm-02-install-fnm|nodejs_fnm/03-install-nodejs.sh|verify_nodejs_installed|1|60"
    "fnm-04-configure-shell|fnm-03-install-nodejs|nodejs_fnm/04-configure-shell.sh|verify_shell_config|1|5"
    "fnm-05-verify|fnm-04-configure-shell|nodejs_fnm/05-verify-installation.sh|verify_fnm_version|1|10"

    # ═══════════════════════════════════════════════════════════════
    # AI Tools (parallel group 3 - depends on Node.js)
    # ═══════════════════════════════════════════════════════════════
    "ai-00-check|fnm-05-verify|ai_tools/00-check-prerequisites.sh|verify_nodejs_available|3|5"
    "ai-01-claude|ai-00-check|ai_tools/01-install-claude-cli.sh|verify_claude_cli|3|30"
    "ai-02-gemini|ai-00-check|ai_tools/02-install-gemini-cli.sh|verify_gemini_cli|3|30"
    "ai-03-copilot|ai-00-check|ai_tools/03-install-copilot-cli.sh|verify_copilot_cli|3|30"
    "ai-04-verify|ai-01-claude,ai-02-gemini,ai-03-copilot|ai_tools/04-verify-installation.sh|verify_all_ai_tools|3|10"

    # ═══════════════════════════════════════════════════════════════
    # Context Menu (parallel group 2 - depends on Ghostty)
    # ═══════════════════════════════════════════════════════════════
    "context-00-check|ghostty-07-verify|context_menu/00-check-prerequisites.sh|verify_nautilus_installed|2|5"
    "context-01-install|context-00-check|context_menu/01-install-context-menu.sh|verify_context_menu_script|2|10"
    "context-02-verify|context-01-install|context_menu/02-verify-installation.sh|verify_context_menu_works|2|5"

    # ═══════════════════════════════════════════════════════════════
    # App Audit (parallel group 4 - final step)
    # ═══════════════════════════════════════════════════════════════
    "audit-00-check|ai-04-verify,context-02-verify|app_audit/00-check-prerequisites.sh|verify_audit_ready|4|5"
    "audit-01-apt|audit-00-check|app_audit/01-scan-apt-packages.sh|verify_apt_scan|4|5"
    "audit-02-snap|audit-00-check|app_audit/02-scan-snap-packages.sh|verify_snap_scan|4|5"
    "audit-03-desktop|audit-00-check|app_audit/03-scan-desktop-files.sh|verify_desktop_scan|4|5"
    "audit-04-duplicates|audit-01-apt,audit-02-snap,audit-03-desktop|app_audit/04-detect-duplicates.sh|verify_duplicates|4|10"
    "audit-05-report|audit-04-duplicates|app_audit/05-generate-report.sh|verify_report|4|5"
    "audit-06-verify|audit-05-report|app_audit/06-verify-report.sh|verify_audit_complete|4|5"
)
```

**Total Tasks**:
- Before: 9 tasks
- After: 50+ granular tasks

**User Benefit**: TUI shows 50+ individual steps with real-time output visibility

---

## Script Execution Model

### Orchestrator Logic (start.sh)

Replace `execute_single_task()` to call modular scripts:

```bash
execute_single_task() {
    local task_id="$1"
    local deps="$2"
    local script_path="$3"      # Changed from function name to script path
    local verify_fn="$4"

    # Skip if already completed (idempotency)
    if is_task_completed "$task_id" && [ "$FORCE_ALL" = false ]; then
        skip_task "$task_id"
        return 0
    fi

    # Check dependencies
    if [ -n "$deps" ]; then
        IFS=',' read -ra dep_array <<< "$deps"
        for dep in "${dep_array[@]}\"; do
            if ! is_task_completed "$dep"; then
                log "ERROR" "Dependency not met: $task_id requires $dep"
                fail_task "$task_id" "Dependency not met: $dep"
                return 1
            fi
        done
    fi

    # Execute modular script
    start_task "$task_id"

    local task_start
    task_start=$(get_unix_timestamp)

    local full_script_path="${ORCHESTRATOR_DIR}/lib/tasks/${script_path}"

    # Run modular script
    local exit_code=0
    if bash "$full_script_path"; then
        exit_code=0
    else
        exit_code=$?
    fi

    local task_end
    task_end=$(get_unix_timestamp)
    local duration
    duration=$(calculate_duration "$task_start" "$task_end")

    # Handle exit codes
    case $exit_code in
        0)
            # Success
            complete_task "$task_id" "$duration"
            mark_task_completed "$task_id" "$duration"
            return 0
            ;;
        2)
            # Skip (idempotent - already done)
            skip_task "$task_id"
            mark_task_completed "$task_id" "0"
            return 0
            ;;
        *)
            # Failure
            fail_task "$task_id" "Script failed: $script_path (exit code: $exit_code)"
            return 1
            ;;
    esac
}
```

---

## Common Utilities (common.sh)

Each task category has a `common.sh` with shared functions:

### Example: `lib/tasks/ghostty/common.sh`

```bash
#!/usr/bin/env bash
#
# Common utilities for Ghostty installation modules
#

set -euo pipefail

# Source core libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../core/logging.sh"
source "${SCRIPT_DIR}/../../core/utils.sh"

# Ghostty installation paths
readonly GHOSTTY_REPO="https://github.com/ghostty-org/ghostty"
readonly GHOSTTY_SRC="$HOME/Apps/ghostty"
readonly GHOSTTY_BINARY="$GHOSTTY_SRC/zig-out/bin/ghostty"
readonly GHOSTTY_INSTALL_DIR="$HOME/.local/bin"

# Zig compiler paths
readonly ZIG_VERSION="0.14.0"
readonly ZIG_URL="https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
readonly ZIG_TARBALL="$HOME/Downloads/zig-linux-x86_64-${ZIG_VERSION}.tar.xz"
readonly ZIG_EXTRACT_DIR="$HOME/Apps"
readonly ZIG_DIR="$ZIG_EXTRACT_DIR/zig-linux-x86_64-${ZIG_VERSION}"
readonly ZIG_BINARY="$ZIG_DIR/zig"

# Logging helpers
log_info() {
    log "INFO" "$1"
}

log_success() {
    log "SUCCESS" "$1"
}

log_warning() {
    log "WARNING" "$1"
}

log_error() {
    log "ERROR" "$1"
}

# Verification functions
verify_ghostty_not_installed() {
    ! command -v ghostty &>/dev/null
}

verify_zig_tarball() {
    [ -f "$ZIG_TARBALL" ]
}

verify_zig_extracted() {
    [ -d "$ZIG_DIR" ]
}

verify_zig_binary() {
    [ -f "$ZIG_BINARY" ] && [ -x "$ZIG_BINARY" ]
}

verify_ghostty_repo() {
    [ -d "$GHOSTTY_SRC/.git" ]
}

verify_ghostty_binary() {
    [ -f "$GHOSTTY_BINARY" ] && [ -x "$GHOSTTY_BINARY" ]
}

verify_ghostty_installed() {
    command -v ghostty &>/dev/null
}

verify_ghostty_version() {
    local version
    version=$(ghostty --version 2>/dev/null || echo "")
    [ -n "$version" ]
}

# Export all verification functions
export -f verify_ghostty_not_installed
export -f verify_zig_tarball
export -f verify_zig_extracted
export -f verify_zig_binary
export -f verify_ghostty_repo
export -f verify_ghostty_binary
export -f verify_ghostty_installed
export -f verify_ghostty_version
```

---

## Migration Strategy

### Phase 1: Create Modular Scripts (Week 1)
1. Create directory structure (`lib/tasks/ghostty/`, `lib/tasks/zsh/`, etc.)
2. Extract Ghostty installation into 8 modular scripts
3. Create `common.sh` for each task category
4. Add comprehensive comments and documentation

### Phase 2: Update Orchestrator (Week 1-2)
1. Modify `execute_single_task()` to call scripts instead of functions
2. Update TASK_REGISTRY with granular task definitions
3. Add exit code handling (0=success, 1=failure, 2=skip)
4. Test with Ghostty installation only

### Phase 3: Migrate Remaining Tasks (Week 2-3)
1. Break down ZSH installation (6 scripts)
2. Break down Python UV (5 scripts)
3. Break down Node.js FNM (6 scripts)
4. Break down AI Tools (5 scripts)
5. Break down Context Menu (3 scripts)
6. Break down App Audit (7 scripts)

### Phase 4: Testing & Validation (Week 3-4)
1. Test fresh installation with modular scripts
2. Test idempotency (re-run installation)
3. Test error recovery (interrupt during build)
4. Test output visibility (collapsible UI)
5. Performance benchmarking

### Phase 5: Documentation & Cleanup (Week 4)
1. Update README.md with modular architecture
2. Update CLAUDE.md with new structure
3. Create migration guide for contributors
4. Archive old monolithic scripts
5. Update local CI/CD workflows

---

## Benefits Summary

### For Users
✅ **Real-time Output Visibility**: See exactly what's happening during long operations
✅ **Granular Progress Tracking**: 50+ individual steps instead of 9 monolithic tasks
✅ **Docker-like UX**: Collapsible output with automatic summarization
✅ **Better Error Messages**: Failures pinpoint exact step (e.g., "Zig download failed" vs "Ghostty installation failed")
✅ **Resume Capability**: Re-run failed steps without redoing completed work

### For Developers
✅ **Maintainability**: Each script <150 lines, single responsibility
✅ **Debuggability**: Easy to isolate and fix issues in specific steps
✅ **Testability**: Each script can be tested independently
✅ **Reusability**: Common utilities shared via `common.sh`
✅ **Constitutional Compliance**: Modular architecture principle satisfied

### For AI Assistants
✅ **Clear Context**: Each script has focused purpose
✅ **Easy Modification**: Change one step without affecting others
✅ **Pattern Recognition**: Standardized interface across all scripts
✅ **Documentation**: Self-documenting code with clear headers

---

## Constitutional Compliance

### Principle V: Modular Architecture ✅

**Before**:
- ❌ Monolithic 500-line task files
- ❌ Difficult to maintain and debug
- ❌ No granular progress visibility

**After**:
- ✅ Modular <150-line scripts
- ✅ Single responsibility per script
- ✅ Granular progress tracking
- ✅ Clean separation of concerns

### Performance Targets ✅

- **Startup Impact**: Zero (scripts only run during installation)
- **Build Performance**: Unchanged (same Zig builds, just better visibility)
- **Idempotency**: Improved (each step checks if already done)
- **Resume Capability**: Improved (granular state tracking)

---

## Next Steps

1. **User Approval**: Review this design and provide feedback
2. **Start Implementation**: Begin Phase 1 (create modular scripts for Ghostty)
3. **Iterative Testing**: Test each phase before moving to next
4. **Documentation**: Update all docs as we progress

---

**End of Design Document**

**Author**: Claude Code (Sonnet 4.5)
**User Requirement**: "Each step is calling a script that does the one thing for that segment of the process"
**Status**: Ready for Implementation
**Estimated Effort**: 4 weeks for complete migration
