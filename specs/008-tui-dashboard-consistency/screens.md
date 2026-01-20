# TUI Dashboard Screen Diagrams

This document provides ASCII diagrams for all TUI ViewStates, showing expected content and user flows.

## Table of Contents

1. [ViewDashboard](#viewdashboard---main-menu)
2. [ViewToolDetail](#viewtooldetail---tool-detail-view)
3. [ViewAppMenu](#viewappmenu---legacy-action-menu)
4. [ViewExtras](#viewextras---extras-tools-menu)
5. [ViewNerdFonts](#viewnerdfonts---nerd-fonts-management)
6. [ViewMCPServers](#viewmcpservers---mcp-servers-management)
7. [ViewMCPPrereq](#viewmcpprereq---mcp-prerequisites)
8. [ViewSecretsWizard](#viewsecretswizard---secrets-configuration)
9. [ViewInstaller](#viewinstaller---installation-progress)
10. [ViewDiagnostics](#viewdiagnostics---boot-diagnostics)
11. [ViewConfirm](#viewconfirm---confirmation-dialog)
12. [ViewMethodSelect](#viewmethodselect---method-selector)
13. [ViewBatchPreview](#viewbatchpreview---batch-preview-new)
14. [ViewUpdatePreview](#viewupdatepreview---update-preview-new)

---

## ViewDashboard - Main Menu

**Purpose**: Primary entry point showing tool status table and navigation menu.

```
+------------------------------------------------------------------+
|  System Installer - Ghostty, Feh, Local AI Tools                 |
+------------------------------------------------------------------+
|                                                                  |
|  [!] 2 updates available - press 'u' or select Update All       |
|                                                                  |
|  +--------------------------------------------------------------+
|  | APP                    STATUS         VERSION      LATEST    |
|  |--------------------------------------------------------------|
|  | Node.js (nvm)          * Installed    22.12.0      22.12.0   |
|  |   > ~/.nvm/versions/node/v22.12.0                            |
|  |   [Bundled:]                                                 |
|  |     npm@10.9.2                                               |
|  |   [Globals:]                                                 |
|  |     claude@1.0.34                                            |
|  |--------------------------------------------------------------|
|  | Local AI Tools         ^ Update       1.2.3        1.3.0     |
|  |--------------------------------------------------------------|
|  | Google Antigravity     x Missing      -            1.0.0     |
|  +--------------------------------------------------------------+
|                                                                  |
|  Choose:                                                         |
|  > Ghostty                                                       |
|    Feh                                                           |
|    Update All (2)                                                |
|    Nerd Fonts                                                    |
|    Extras                                                        |
|    Boot Diagnostics                                              |
|    Exit                                                          |
|                                                                  |
+------------------------------------------------------------------+
|  [up/down] navigate  [enter] select  [u] update all  [q] quit   |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- Table tools (nodejs, ai_tools, antigravity) → **ViewToolDetail** (PROPOSED FIX)
- Ghostty, Feh → ViewToolDetail (correct)
- Update All → **ViewUpdatePreview** (PROPOSED FIX)
- Nerd Fonts → ViewNerdFonts
- Extras → ViewExtras
- Boot Diagnostics → ViewDiagnostics
- Exit → quit

---

## ViewToolDetail - Tool Detail View

**Purpose**: Shows single tool status with action menu. Consistent entry point for all tool operations.

```
+------------------------------------------------------------------+
|  Ghostty - Details                                               |
|  GPU-accelerated terminal emulator with native OS integration    |
+------------------------------------------------------------------+
|                                                                  |
|  +--------------------------------------------------------------+
|  |  Status:      * Installed                                    |
|  |  Version:     1.2.3                                          |
|  |  Latest:      1.2.3                                          |
|  |  Method:      snap                                           |
|  |  Location:    /snap/ghostty/current                          |
|  +--------------------------------------------------------------+
|                                                                  |
|  Actions:                                                        |
|  > Install                                                       |
|    Reinstall                                                     |
|    Uninstall                                                     |
|    Back                                                          |
|                                                                  |
+------------------------------------------------------------------+
|  [up/down] navigate  [enter] select  [r] refresh  [esc] back    |
+------------------------------------------------------------------+
```

**Variations**:
- Update available: First action shows "Update" instead of "Install"
- Missing tool: Status shows "x Missing", only "Install" and "Back" shown
- ZSH with Ghostty installed: Shows additional "Configure" action

**Navigation Targets**:
- Install/Update/Reinstall → ViewInstaller
- Uninstall → ViewConfirm → ViewInstaller
- Back → Previous view (ViewDashboard or ViewExtras)

---

## ViewAppMenu - Legacy Action Menu

**Purpose**: Shows quick action menu for a tool. **TO BE DEPRECATED** in favor of ViewToolDetail.

```
+------------------------------------------------------------------+
|  Node.js (nvm) - Actions                                         |
+------------------------------------------------------------------+
|                                                                  |
|  Status: Installed (v22.12.0)                                    |
|                                                                  |
|  Choose action:                                                  |
|  > Install                                                       |
|    Reinstall                                                     |
|    Uninstall                                                     |
|    Back                                                          |
|                                                                  |
+------------------------------------------------------------------+
|  [up/down] navigate  [enter] select  [esc] back                 |
+------------------------------------------------------------------+
```

**ISSUE**: This view is only used for table tools. Menu tools use ViewToolDetail.
**FIX**: Route all tools through ViewToolDetail instead.

---

## ViewExtras - Extras Tools Menu

**Purpose**: Navigation menu for 7 additional tools plus actions.

```
+------------------------------------------------------------------+
|  Extras Tools - 7 Additional Tools                               |
+------------------------------------------------------------------+
|                                                                  |
|  Choose:                                                         |
|  > Fastfetch                                                     |
|    Glow                                                          |
|    Go                                                            |
|    Gum                                                           |
|    Python/uv                                                     |
|    VHS                                                           |
|    ZSH                                                           |
|    ----------------------------------------                      |
|    Install All                                                   |
|    Install Claude Config                                         |
|    MCP Servers                                                   |
|    Back                                                          |
|                                                                  |
+------------------------------------------------------------------+
|  [up/down] navigate  [enter] select  [r] refresh  [esc] back    |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- Individual tools (Fastfetch...ZSH) → ViewToolDetail (correct)
- Install All → **ViewBatchPreview** (PROPOSED FIX)
- Install Claude Config → **ViewInstaller** (PROPOSED FIX)
- MCP Servers → ViewMCPServers
- Back → ViewDashboard

**ISSUES**:
1. "Install All" executes immediately without preview
2. "Install Claude Config" exits TUI (uses tea.ExecProcess)

---

## ViewNerdFonts - Nerd Fonts Management

**Purpose**: Manage 8 Nerd Font families with individual install/uninstall.

```
+------------------------------------------------------------------+
|  Nerd Fonts Management - 8 Font Families                         |
+------------------------------------------------------------------+
|                                                                  |
|  +--------------------------------------------------------------+
|  | FONT FAMILY          STATUS         VERSION      LOCATION    |
|  |--------------------------------------------------------------|
|  | JetBrainsMono        * Installed    3.3.0        ~/.local... |
|  | FiraCode             * Installed    3.3.0        ~/.local... |
|  | Hack                 x Missing      -            -           |
|  | Meslo                x Missing      -            -           |
|  | CascadiaCode         * Installed    3.3.0        ~/.local... |
|  | SourceCodePro        x Missing      -            -           |
|  | IBMPlexMono          x Missing      -            -           |
|  | Iosevka              x Missing      -            -           |
|  +--------------------------------------------------------------+
|                                                                  |
|  Choose:                                                         |
|    Install All (5 missing)                                       |
|  > Back                                                          |
|                                                                  |
+------------------------------------------------------------------+
|  [up/down] navigate  [enter] select  [r] refresh  [esc] back    |
+------------------------------------------------------------------+
```

**Navigation on Font Selection**:
When a font family is selected from the table, an action menu appears:

```
|  Actions for JetBrainsMono:                                      |
|  > Reinstall                                                     |
|    Uninstall                                                     |
|    Back                                                          |
```

**Navigation Targets**:
- Font → Action menu → ViewInstaller
- Install All → **ViewBatchPreview** (PROPOSED FIX)
- Back → ViewDashboard

**ISSUE**: "Install All" executes immediately without preview of fonts to install.

---

## ViewMCPServers - MCP Servers Management

**Purpose**: Manage 7 MCP servers with status and install/remove.

```
+------------------------------------------------------------------+
|  MCP Servers - 7 Servers                                         |
+------------------------------------------------------------------+
|                                                                  |
|  +--------------------------------------------------------------+
|  | SERVER           TRANSPORT   STATUS         DESCRIPTION      |
|  |--------------------------------------------------------------|
|  | context7         HTTP        * Connected    Documentation    |
|  | github           stdio       * Connected    GitHub API       |
|  | markitdown       stdio       x Not Added    File conversion  |
|  | playwright       stdio       * Connected    Browser autom... |
|  | hf-mcp-server    stdio       x Not Added    Hugging Face     |
|  | shadcn           stdio       * Connected    shadcn/ui comp   |
|  | shadcn-ui        stdio       x Not Added    UI components    |
|  +--------------------------------------------------------------+
|                                                                  |
|  Choose:                                                         |
|    Setup Secrets                                                 |
|  > Back                                                          |
|                                                                  |
+------------------------------------------------------------------+
|  [up/down] navigate  [enter] select  [r] refresh  [esc] back    |
+------------------------------------------------------------------+
```

**Navigation on Server Selection**:
```
|  Actions for markitdown:                                         |
|  > Install                                                       |
|    Back                                                          |
```

**Navigation Targets**:
- Server (not installed) → Action menu → Install → ViewMCPPrereq (if prereqs fail) or Install
- Server (installed) → Action menu → Remove
- Setup Secrets → ViewSecretsWizard
- Back → ViewExtras

---

## ViewMCPPrereq - MCP Prerequisites

**Purpose**: Checklist of prerequisites for an MCP server installation.

```
+------------------------------------------------------------------+
|  Prerequisites for context7                                      |
+------------------------------------------------------------------+
|                                                                  |
|  The following requirements must be met:                         |
|                                                                  |
|  [*] Node.js installed                                           |
|  [*] npm available                                               |
|  [ ] CONTEXT7_API_KEY set                                        |
|                                                                  |
|  Missing requirements:                                           |
|  - CONTEXT7_API_KEY environment variable not found               |
|    Run: Setup Secrets in MCP Servers menu                        |
|                                                                  |
+------------------------------------------------------------------+
|  [enter] continue  [esc] back                                    |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- If all pass → Install server → back to ViewMCPServers
- If fail → Back to ViewMCPServers (user must fix)

---

## ViewSecretsWizard - Secrets Configuration

**Purpose**: Configure API keys and secrets for MCP servers.

```
+------------------------------------------------------------------+
|  MCP Secrets Configuration                                       |
+------------------------------------------------------------------+
|                                                                  |
|  Configure environment variables for MCP servers.                |
|                                                                  |
|  [ ] CONTEXT7_API_KEY                                            |
|      Current: (not set)                                          |
|                                                                  |
|  [ ] GITHUB_TOKEN                                                |
|      Current: ghp_...xxxx (set)                                  |
|                                                                  |
|  [ ] HF_TOKEN                                                    |
|      Current: (not set)                                          |
|                                                                  |
|  Choose:                                                         |
|  > Set CONTEXT7_API_KEY                                          |
|    Set HF_TOKEN                                                  |
|    Back                                                          |
|                                                                  |
+------------------------------------------------------------------+
|  [up/down] navigate  [enter] select  [esc] back                 |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- Set key → Input dialog (or instructions)
- Back → ViewMCPServers

---

## ViewInstaller - Installation Progress

**Purpose**: Shows installation/uninstall/update progress with live output.

```
+------------------------------------------------------------------+
|  * Installing Ghostty                                            |
+------------------------------------------------------------------+
|                                                                  |
|  Stage 3/5: Installing...  (elapsed: 45s)                        |
|                                                                  |
|  +--------------------------------------------------------------+
|  | Cloning ghostty repository...                                |
|  | Checking out v1.2.3...                                       |
|  | Running zig build -Doptimize=ReleaseFast...                  |
|  | [ 45%] Compiling src/terminal.zig                            |
|  | [ 46%] Compiling src/renderer.zig                            |
|  | [ 47%] Compiling src/font.zig                                |
|  | ...                                                          |
|  +--------------------------------------------------------------+
|                                                                  |
|  [##############........................] (3/5)                  |
|  * Check  * InstallDeps  * VerifyDeps  -> Install  o Confirm    |
|                                                                  |
+------------------------------------------------------------------+
|  [ESC] Cancel                                                    |
+------------------------------------------------------------------+
```

**On Completion (Success)**:
```
|  * Installation complete!                                        |
|                                                                  |
+------------------------------------------------------------------+
|  [ESC] Back to dashboard                                         |
+------------------------------------------------------------------+
```

**On Failure**:
```
|  x Installation failed: exit code 1                              |
|                                                                  |
|  +----------------+  +----------------+  +----------------+      |
|  |   [Back] ESC   |  |   [Retry] R    |  |  [Resume] C    |      |
|  +----------------+  +----------------+  +----------------+      |
|                                                                  |
+------------------------------------------------------------------+
|  [left/right] select  [enter] confirm  [R/C/ESC] quick select   |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- Success → ESC → Previous view
- Failure → Back/Retry/Resume buttons

---

## ViewDiagnostics - Boot Diagnostics

**Purpose**: Scan for and fix system boot issues.

```
+------------------------------------------------------------------+
|  Boot Diagnostics                                                |
+------------------------------------------------------------------+
|                                                                  |
|  Last scan: 5 minutes ago (3 issues found)                       |
|                                                                  |
|  [x] CRITICAL (1):                                               |
|  >   snap-inhibit-cgroup - Snap apps slowing boot                |
|        [fixable] sudo snap set system experimental.cgroup-pids=0 |
|                                                                  |
|  [!] MODERATE (1):                                               |
|      networkd-wait - Network wait timeout                        |
|        [fixable] sudo systemctl disable systemd-networkd-wait... |
|                                                                  |
|  [o] LOW (1):                                                    |
|      plymouth-quit - Plymouth quit delay                         |
|        [manual] Edit /etc/default/grub                           |
|                                                                  |
|  1 issues selected for fixing                                    |
|                                                                  |
+------------------------------------------------------------------+
|  [up/down] navigate  [space] select  [F] fix  [R] rescan  [esc] |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- [F] Fix selected → Execute fixes → Show results
- [R] Rescan → Run diagnostics again
- ESC → ViewDashboard

---

## ViewConfirm - Confirmation Dialog

**Purpose**: Confirm destructive operations (uninstall, etc.)

```
+------------------------------------------------------------------+
|                                                                  |
|                                                                  |
|         +------------------------------------------+             |
|         |                                          |             |
|         |    Uninstall Ghostty?                    |             |
|         |                                          |             |
|         |    This will remove Ghostty from         |             |
|         |    your system. Configuration files      |             |
|         |    will be preserved.                    |             |
|         |                                          |             |
|         |    +----------+    +----------+          |             |
|         |    | [Cancel] |    | [Confirm]|          |             |
|         |    +----------+    +----------+          |             |
|         |                                          |             |
|         +------------------------------------------+             |
|                                                                  |
|                                                                  |
+------------------------------------------------------------------+
|  [left/right] select  [enter] confirm  [esc] cancel             |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- Cancel → Return to previous view
- Confirm → Execute operation (ViewInstaller for uninstall)

---

## ViewMethodSelect - Method Selector

**Purpose**: Select installation method for multi-method tools (Ghostty).

```
+------------------------------------------------------------------+
|  Install Ghostty - Select Method                                 |
+------------------------------------------------------------------+
|                                                                  |
|  Choose installation method:                                     |
|                                                                  |
|  > [*] Snap (Recommended)                                        |
|        Fast, automatic updates, sandboxed                        |
|        Recommended for: Ubuntu 24.04+                            |
|                                                                  |
|    [ ] Build from Source                                         |
|        Latest features, requires Zig toolchain                   |
|        Recommended for: Developers, customization                |
|                                                                  |
|  [ ] Remember my choice                                          |
|                                                                  |
+------------------------------------------------------------------+
|  [up/down] navigate  [enter] select  [esc] cancel               |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- Select method → ViewInstaller
- ESC → ViewDashboard

---

## ViewBatchPreview - Batch Preview (NEW)

**Purpose**: Preview batch operations before execution.

```
+------------------------------------------------------------------+
|  Install All - Preview                                           |
+------------------------------------------------------------------+
|                                                                  |
|  The following tools will be installed:                          |
|                                                                  |
|  [ ] Fastfetch         (system info tool)                        |
|  [ ] Go                (Go programming language)                 |
|  [ ] Gum               (shell script utilities)                  |
|  [ ] Python/uv         (Python with uv package manager)          |
|  [ ] VHS               (terminal recording)                      |
|                                                                  |
|  Already installed (will skip):                                  |
|  [*] Glow              v1.5.1                                    |
|  [*] ZSH               v5.9                                      |
|                                                                  |
|  Total: 5 to install, 2 already installed                        |
|                                                                  |
|  +----------------+    +----------------+                         |
|  |    [Cancel]    |    |   [Install]    |                         |
|  +----------------+    +----------------+                         |
|                                                                  |
+------------------------------------------------------------------+
|  [left/right] select  [enter] confirm  [esc] cancel             |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- Cancel → Return to Extras
- Install → ViewInstaller (batch mode)

---

## ViewUpdatePreview - Update Preview (NEW)

**Purpose**: Preview "Update All" before execution.

```
+------------------------------------------------------------------+
|  Update All - Preview                                            |
+------------------------------------------------------------------+
|                                                                  |
|  The following tools will be updated:                            |
|                                                                  |
|  [^] Local AI Tools     1.2.3 -> 1.3.0                           |
|  [^] Fastfetch          2.31.0 -> 2.32.0                         |
|                                                                  |
|  Already up to date (will skip):                                 |
|  [*] Node.js (nvm)      22.12.0                                  |
|  [*] Ghostty            1.2.3                                    |
|  [*] Go                 1.23.4                                   |
|                                                                  |
|  Total: 2 updates available                                      |
|                                                                  |
|  +----------------+    +----------------+                         |
|  |    [Cancel]    |    |   [Update]     |                         |
|  +----------------+    +----------------+                         |
|                                                                  |
+------------------------------------------------------------------+
|  [left/right] select  [enter] confirm  [esc] cancel             |
+------------------------------------------------------------------+
```

**Navigation Targets**:
- Cancel → Return to Dashboard
- Update → ViewInstaller (batch update mode)

---

## Navigation Flow Summary

### Current Flow (with issues marked)

```
ViewDashboard
|
+-- Table Tools (nodejs, ai_tools, antigravity)
|   +-- ViewAppMenu  <-- ISSUE: Skips ViewToolDetail
|       +-- ViewInstaller
|
+-- Menu Tools (Ghostty, Feh)
|   +-- ViewToolDetail  <-- CORRECT
|       +-- ViewInstaller
|
+-- Update All
|   +-- ViewInstaller (immediate)  <-- ISSUE: No preview
|
+-- Nerd Fonts
|   +-- ViewNerdFonts
|       +-- Font Action Menu --> ViewInstaller  <-- CORRECT
|       +-- Install All --> ViewInstaller (immediate)  <-- ISSUE: No preview
|
+-- Extras
|   +-- ViewExtras
|       +-- Tools --> ViewToolDetail --> ViewInstaller  <-- CORRECT
|       +-- Install All --> ViewInstaller (immediate)  <-- ISSUE: No preview
|       +-- Install Claude Config --> tea.ExecProcess  <-- ISSUE: Exits TUI
|       +-- MCP Servers
|           +-- ViewMCPServers
|               +-- Server --> Action Menu --> Install/Remove
|               +-- ViewMCPPrereq (if prereqs fail)
|               +-- Setup Secrets --> ViewSecretsWizard
|
+-- Boot Diagnostics
    +-- ViewDiagnostics  <-- CORRECT
```

### Proposed Flow (all issues fixed)

```
ViewDashboard
|
+-- ALL Tools (table and menu)
|   +-- ViewToolDetail  <-- CONSISTENT
|       +-- ViewInstaller
|
+-- Update All
|   +-- ViewUpdatePreview  <-- NEW: Preview first
|       +-- ViewInstaller (batch)
|
+-- Nerd Fonts
|   +-- ViewNerdFonts
|       +-- Font Action Menu --> ViewInstaller
|       +-- Install All --> ViewBatchPreview  <-- NEW: Preview first
|           +-- ViewInstaller (batch)
|
+-- Extras
|   +-- ViewExtras
|       +-- Tools --> ViewToolDetail --> ViewInstaller
|       +-- Install All --> ViewBatchPreview  <-- NEW: Preview first
|           +-- ViewInstaller (batch)
|       +-- Install Claude Config --> ViewInstaller  <-- FIXED: Stay in TUI
|       +-- MCP Servers --> ViewMCPServers
|
+-- Boot Diagnostics --> ViewDiagnostics
```
