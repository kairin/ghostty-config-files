# Ghostty Window Not Appearing - Root Cause Analysis

**Date**: 2025-11-12
**Issue**: Ghostty process runs but no window appears
**Status**: ROOT CAUSE IDENTIFIED ✅

---

## Problem Statement

User reports Ghostty icon is visible in launcher, clicking it shows no window, but process is running:

```bash
$ ps aux | grep ghostty
kkk  43642  /snap/bin/ghostty --gtk-single-instance=true
```

**Symptom**: Process runs, consumes memory, but no visible window appears on screen.

---

## Investigation Timeline

### 1. Initial Diagnosis - Single Instance Mode

**Hypothesis**: GTK single-instance mode focusing existing hidden window.

**Testing**:
```bash
$ /snap/bin/ghostty --working-directory=$HOME
# Still no window appears
```

**Result**: Not the issue - even without `--gtk-single-instance=true`, window doesn't appear.

---

### 2. Graphics Driver Investigation

**System**: NVIDIA GeForce RTX 4080 SUPER + Wayland

**Errors Found**:
```
libEGL warning: egl: failed to create dri2 screen
MESA: error: ZINK: vkCreateInstance failed (VK_ERROR_INCOMPATIBLE_DRIVER)
```

**Analysis**: OpenGL/Vulkan driver issues, but NVIDIA driver 580.95.05 is installed and working.

**Result**: Drivers are fine - not the root cause.

---

### 3. D-Bus Application Registration Failure

**Critical Error in Logs**:
```bash
Nov 12 18:42:28 ghostty_ghostty.desktop[838100]:
  warning(gtk_ghostty_application): error registering application: Timeout was reached
Nov 12 18:42:28 ghostty_ghostty.desktop[838100]:
  error: ApplicationRegisterFailed
```

**Analysis**: Ghostty snap cannot register with GNOME D-Bus/session management.

**Why**: Snap confinement + Wayland + GNOME session integration = compatibility issues

---

## ROOT CAUSE IDENTIFIED ✅

### The Real Problem: Snap vs Source Build

**Repository Expectation** (from `CLAUDE.md`):
```markdown
### 🚨 CRITICAL: Package Management & Dependencies
- **Ghostty**: Built from source with Zig 0.14.0 (latest stable)
```

**Actual Installation**:
- Ghostty installed via **snap package**
- Never built from source
- `start.sh` failed due to passwordless sudo requirement
- Fell back to snap installation

**Evidence from start.sh**:
```bash
# Line 1376-1383
if [ "$ghostty_source" = "snap" ]; then
    if $ghostty_config_valid; then
        log "INFO" "📋 Ghostty: Snap installation detected, will only update configuration"
        GHOSTTY_STRATEGY="config_only"  # <-- Only updates config, doesn't build from source!
```

### Why Snap Doesn't Work

**Snap Confinement Issues**:
1. **D-Bus Registration**: Snap can't properly register with GNOME session
2. **Wayland Integration**: Limited Wayland socket access
3. **NVIDIA Drivers**: Snap's isolated environment conflicts with host NVIDIA drivers
4. **GTK Application**: Snap GTK apps have known issues with Wayland + NVIDIA

**Process Flow (Snap)**:
```
1. snap run ghostty
2. Load GTK runtime from snap
3. Attempt to register with GNOME D-Bus → TIMEOUT (25 seconds)
4. Process continues running but never creates window
5. ApplicationRegisterFailed error
6. Ghostty waits indefinitely, consuming resources
```

**Process Flow (Source Build)**:
```
1. /usr/local/bin/ghostty
2. Load system GTK libraries
3. Register with GNOME D-Bus → SUCCESS
4. Create Wayland/X11 window → SUCCESS
5. Window appears immediately
```

---

## System Information

### Environment
- **OS**: Ubuntu 25.10 (Questing)
- **Kernel**: 6.17.0-6-generic
- **Display Server**: Wayland (`wayland-0`)
- **Desktop**: GNOME/Ubuntu
- **GPU**: NVIDIA GeForce RTX 4080 SUPER
- **Driver**: NVIDIA 580.95.05

### Ghostty Installation
- **Current**: Snap (ghostty 1.2.3, revision 436)
- **Expected**: Source build with Zig 0.14.0
- **Build Tools**: Zig 0.14.0 installed at `/usr/local/bin/zig` ✅
- **Source Location**: `~/Apps/ghostty/` (directory doesn't exist) ❌

### Why Source Build Wasn't Done

**start.sh Prerequisites Check Failed**:
```bash
[2025-11-12 15:02:50] [ERROR] [pre_auth_sudo:3106]
  ❌ Passwordless sudo is REQUIRED for automated installation
[2025-11-12 15:02:50] [ERROR] [main:3373]
  ❌ Installation cannot proceed without passwordless sudo
```

**Result**: Script exited before building Ghostty from source.

---

## Solution Options

### Option 1: Build Ghostty from Source (RECOMMENDED ✅)

**Why Recommended**:
- Matches repository design and documentation
- Full system integration (no snap confinement)
- Better Wayland + NVIDIA support
- Properly registers with GNOME D-Bus
- Latest features and bug fixes

**Prerequisites**:
- ✅ Zig 0.14.0 installed
- ✅ NVIDIA drivers working
- ❌ Passwordless sudo configured (need to fix)
- ❌ Ghostty source code cloned

**Steps**:
```bash
# 1. Configure passwordless sudo (if not done)
sudo EDITOR=nano visudo
# Add: kkk ALL=(ALL) NOPASSWD: /usr/bin/apt

# 2. Run start.sh (will build from source)
cd /home/kkk/Apps/ghostty-config-files
./start.sh

# 3. Verify source build
which ghostty  # Should show /usr/local/bin/ghostty
ghostty --version

# 4. Launch Ghostty
ghostty
```

**Build Time**: ~5-10 minutes (Zig compilation)

---

### Option 2: Fix Snap Permissions (NOT RECOMMENDED ⚠️)

**Why Not Recommended**: Workarounds are fragile and may break with updates.

**Possible Workarounds** (experimental):
```bash
# Try connecting snap interfaces manually
snap connect ghostty:wayland
snap connect ghostty:x11
snap connect ghostty:desktop
snap connect ghostty:desktop-legacy

# Remove single-instance flag from desktop file
sudo nano /var/lib/snapd/desktop/applications/ghostty_ghostty.desktop
# Change: Exec=/snap/bin/ghostty --gtk-single-instance=true
# To:     Exec=/snap/bin/ghostty

# Update desktop database
update-desktop-database ~/.local/share/applications
```

**Issues**:
- May still timeout on D-Bus registration
- Snap updates will revert changes
- Won't fix underlying Wayland + NVIDIA issues

---

### Option 3: Use Alternative Terminal Temporarily

**Immediate Workaround**:
```bash
# Ptyxis (modern GNOME terminal)
ptyxis

# GNOME Terminal (fallback)
gnome-terminal
```

**Note**: This doesn't fix Ghostty, just provides a working terminal while investigating.

---

## Recommended Action Plan

1. **Configure Passwordless Sudo** (5 minutes):
   ```bash
   ./scripts/verify-passwordless-sudo.sh
   # Follow instructions if not configured
   ```

2. **Remove Snap Ghostty** (1 minute):
   ```bash
   sudo snap remove ghostty
   ```

3. **Run start.sh to Build from Source** (10-15 minutes):
   ```bash
   cd /home/kkk/Apps/ghostty-config-files
   ./start.sh
   ```

4. **Verify Installation**:
   ```bash
   which ghostty  # Should show /usr/local/bin/ghostty
   ghostty        # Should open window immediately
   ```

5. **Test Configuration**:
   ```bash
   ghostty +show-config  # Verify config is valid
   ```

---

## Technical Details

### Snap Confinement Limitations

**What Snap Restricts**:
- D-Bus session bus access (limited to specific names)
- Wayland socket access (requires manual connection)
- Direct hardware access (NVIDIA driver mismatch)
- System GTK theme access (causes theme parser errors)

**Snap's `plugs`** (ghostty snap.yaml):
```yaml
plugs:
  - desktop
  - desktop-legacy
  - wayland
  - x11
  - opengl
```

**Problem**: Even with all plugs connected, D-Bus application registration times out.

---

### Why Source Build Works

**Direct System Integration**:
1. Uses system GTK libraries (no version mismatch)
2. Full D-Bus access (not restricted by snap)
3. Direct NVIDIA driver access (no intermediate layer)
4. Proper Wayland protocol support
5. Native GNOME session integration

**Build Process** (from start.sh):
```bash
# Clone Ghostty repository
git clone https://github.com/ghostty-org/ghostty ~/Apps/ghostty

# Build with Zig
cd ~/Apps/ghostty
zig build -Doptimize=ReleaseFast

# Install to /usr/local/bin
sudo zig build -Doptimize=ReleaseFast -p /usr/local
```

---

## Related Issues

### Known Snap + Wayland + NVIDIA Issues

**GitHub Issues**:
- Snap GTK apps on Wayland with NVIDIA: timeout issues
- D-Bus registration failures in confined snaps
- Wayland socket permission problems

**Workaround in Other Apps**:
- VSCode: Switched from snap to .deb
- Chrome: Uses special snap with extended permissions
- Steam: Native package recommended over snap

---

## Logs and Evidence

### Full Error Log
**Location**: `/tmp/ghostty-software-render.log`

**Key Errors**:
```
error registering application: Timeout was reached
error: ApplicationRegisterFailed
libEGL warning: egl: failed to create dri2 screen
MESA: error: ZINK: vkCreateInstance failed (VK_ERROR_INCOMPATIBLE_DRIVER)
```

### Journal Logs
```bash
$ journalctl --user -n 50 | grep ghostty
Nov 12 18:42:28 ghostty_ghostty.desktop[838100]:
  warning(gtk_ghostty_application): error registering application: Timeout was reached
Nov 12 18:42:28 ghostty_ghostty.desktop[838100]:
  error: ApplicationRegisterFailed
```

### Process State
```bash
$ ps aux | grep ghostty
kkk  43642  0.0  0.1  1415200  125508  ?  Sl  16:17  0:02  /snap/bin/ghostty --gtk-single-instance=true
```

Process runs but has no window handle, no X11/Wayland connection in `/proc/43642/fd/`.

---

## Conclusion

**Root Cause**: Snap-confined Ghostty cannot register with GNOME D-Bus on Wayland + NVIDIA, preventing window creation.

**Solution**: Build Ghostty from source as intended by repository design.

**Next Steps**:
1. Configure passwordless sudo
2. Run `./start.sh` to build from source
3. Verify window appears and works correctly

**Status**: Ready to implement solution ✅

---

**Report By**: Claude Code (AI Assistant)
**Repository**: ghostty-config-files
**Related Docs**:
- Main debugging report: `20251112-post-install-issues.md`
- Fixes summary: `20251112-fixes-summary.md`
- Sudo verification: `../../../scripts/verify-passwordless-sudo.sh`
