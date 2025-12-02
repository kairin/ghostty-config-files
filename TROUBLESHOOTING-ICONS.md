# Troubleshooting: Broken System Icons on Ubuntu 25.10

## Problem

After installing applications from source (via `make install`) or after system updates, icons may appear as **red circles with slashes** (the "missing icon" indicator) or show low-resolution fallback icons in GNOME applications like:

- Virtual Machine Manager (virt-manager)
- Screenshot
- Files (Nautilus)
- Settings
- Ghostty terminal
- Other GTK4/libadwaita apps

## Root Causes

There are **two distinct issues** that can cause icon problems:

### Cause 1: System Icon Cache Corruption

Ubuntu's default **Yaru-dark** icon theme is a minimal theme that inherits icons from:
```
Yaru-dark → Yaru → Humanity → hicolor
```

When applications are installed from source (especially GTK4/libadwaita apps like Ghostty), the system icon cache can become corrupted or out of sync, breaking the inheritance chain.

### Cause 2: User Icon Directory Missing `index.theme` (Common!)

Applications installed per-user (not system-wide) place icons in:
```
~/.local/share/icons/hicolor/
```

**Critical Issue**: When apps like Ghostty install icons to the user directory, they create the icon files but often **do not create the required `index.theme` file**. Without this file:

- The icon cache (`icon-theme.cache`) cannot be properly generated
- GTK cannot locate or resolve icons in the directory
- Apps fall back to generic/low-resolution icons

**Directory structure when broken:**
```
~/.local/share/icons/hicolor/
├── 16x16/apps/com.mitchellh.ghostty.png
├── 32x32/apps/com.mitchellh.ghostty.png
├── 128x128/apps/com.mitchellh.ghostty.png
├── 256x256/apps/com.mitchellh.ghostty.png
├── 512x512/apps/com.mitchellh.ghostty.png
├── 1024x1024/apps/com.mitchellh.ghostty.png
└── icon-theme.cache          <-- Only 496 bytes, essentially empty/invalid
                              <-- MISSING: index.theme
```

**How GTK Icon Resolution Works:**

1. GTK reads `index.theme` to understand the directory structure (sizes, contexts, types)
2. GTK uses this metadata to build/read `icon-theme.cache` for fast lookups
3. Without `index.theme`, the cache is invalid and icons cannot be resolved
4. GTK falls back to the inheritance chain, eventually showing generic icons

## Fix

### Fix A: User Icon Directory (Ghostty, user-installed apps)

**Step 1: Copy the missing `index.theme` from system hicolor:**
```bash
cp /usr/share/icons/hicolor/index.theme ~/.local/share/icons/hicolor/
```

**Step 2: Rebuild user icon cache (no sudo required):**
```bash
gtk-update-icon-cache --force ~/.local/share/icons/hicolor/
```

**Step 3: Verify the cache was created properly:**
```bash
ls -la ~/.local/share/icons/hicolor/icon-theme.cache
# Should be several KB, not ~500 bytes
```

### Fix B: System Icon Caches (virt-manager, system apps)

**Step 1: Rebuild all system icon caches:**
```bash
sudo gtk-update-icon-cache --force /usr/share/icons/Yaru/
sudo gtk-update-icon-cache --force /usr/share/icons/Yaru-dark/
sudo gtk-update-icon-cache --force /usr/share/icons/Adwaita/
sudo gtk-update-icon-cache --force /usr/share/icons/hicolor/
```

**Step 2: If caches fail to build, reinstall icon packages:**
```bash
sudo apt install --reinstall yaru-theme-icon adwaita-icon-theme humanity-icon-theme hicolor-icon-theme
sudo gtk-update-icon-cache --force /usr/share/icons/Yaru/
sudo gtk-update-icon-cache --force /usr/share/icons/Yaru-dark/
sudo gtk-update-icon-cache --force /usr/share/icons/Adwaita/
sudo gtk-update-icon-cache --force /usr/share/icons/hicolor/
```

### Fix C: Clear Caches and Restart

**Step 1: Clear any stale icon caches:**
```bash
rm -rf ~/.cache/icon-cache.kcache 2>/dev/null
rm -rf ~/.cache/gtk-4.0/icon-cache.kcache 2>/dev/null
```

**Step 2: Restart GNOME Shell to apply changes:**
- **Wayland (Ubuntu 25.10 default)**: Log out and log back in
- **X11**: Press `Alt+F2`, type `r`, press Enter

## Prevention

### For User-Installed Apps (Ghostty, etc.)

After installing any application that places icons in `~/.local/share/icons/`:

```bash
# Ensure index.theme exists (one-time setup)
if [ ! -f ~/.local/share/icons/hicolor/index.theme ]; then
    cp /usr/share/icons/hicolor/index.theme ~/.local/share/icons/hicolor/
fi

# Rebuild user icon cache
gtk-update-icon-cache --force ~/.local/share/icons/hicolor/
```

### For System-Wide Installations

After installing any application from source that includes icons (especially GTK4 apps):
```bash
sudo gtk-update-icon-cache --force /usr/share/icons/hicolor/
```

### Recommended: Add to Shell Profile

Add this function to `~/.bashrc` or `~/.zshrc`:
```bash
# Rebuild icon caches after app installations
rebuild-icons() {
    echo "Rebuilding icon caches..."

    # User icons
    if [ -d ~/.local/share/icons/hicolor ]; then
        [ ! -f ~/.local/share/icons/hicolor/index.theme ] && \
            cp /usr/share/icons/hicolor/index.theme ~/.local/share/icons/hicolor/
        gtk-update-icon-cache --force ~/.local/share/icons/hicolor/
        echo "  User icon cache rebuilt"
    fi

    # System icons (requires sudo)
    if [ "$1" = "--system" ]; then
        sudo gtk-update-icon-cache --force /usr/share/icons/hicolor/
        sudo gtk-update-icon-cache --force /usr/share/icons/Yaru/
        sudo gtk-update-icon-cache --force /usr/share/icons/Yaru-dark/
        echo "  System icon caches rebuilt"
    fi

    echo "Done. Log out and back in to apply changes."
}
```

## Diagnosis

### Check Current Icon Theme
```bash
gsettings get org.gnome.desktop.interface icon-theme
# Expected: 'Yaru-dark' (Ubuntu default)
```

### Check Icon Theme Inheritance
```bash
cat /usr/share/icons/Yaru-dark/index.theme | grep Inherits
# Shows: Inherits=Yaru,Humanity,hicolor
```

### Check Icon Cache Health

**System caches:**
```bash
ls -la /usr/share/icons/*/icon-theme.cache
```

**User cache:**
```bash
ls -la ~/.local/share/icons/hicolor/icon-theme.cache
# Should be several KB. If ~500 bytes, it's invalid.
```

### Check for Missing index.theme
```bash
# This is the most common issue!
ls ~/.local/share/icons/hicolor/index.theme 2>/dev/null || echo "MISSING: index.theme"
```

### Verify Specific Icons Exist

**Ghostty:**
```bash
find ~/.local/share/icons -name "*ghostty*" -type f 2>/dev/null
```

**System apps:**
```bash
find /usr/share/icons -name "*gnome-screenshot*" -type f 2>/dev/null
find /usr/share/icons -name "*virt-manager*" -type f 2>/dev/null
```

## Technical Background

### The hicolor Icon Theme

`hicolor` is the **fallback icon theme** defined by the [freedesktop.org Icon Theme Specification](https://specifications.freedesktop.org/icon-theme-spec/latest/). Every compliant icon theme must ultimately inherit from hicolor.

The `index.theme` file defines:
- **Directories**: Which size directories exist (16x16, 32x32, scalable, etc.)
- **Context**: What type of icons (apps, actions, mimetypes, etc.)
- **Type**: Fixed, Scalable, or Threshold sizing

### Why `index.theme` is Required

```
index.theme (metadata)  +  icon files  →  gtk-update-icon-cache  →  icon-theme.cache (binary lookup table)
```

Without `index.theme`:
- `gtk-update-icon-cache` doesn't know the directory structure
- It creates a minimal/empty cache file (~500 bytes)
- GTK cannot perform icon lookups in that directory
- Falls back to parent themes or shows broken icon

### Ghostty-Specific Issue

Ghostty's build system (`zig build -Doptimize=ReleaseFast`) installs icons to:
- System install: `/usr/share/icons/hicolor/*/apps/com.mitchellh.ghostty.png`
- User install: `~/.local/share/icons/hicolor/*/apps/com.mitchellh.ghostty.png`

The build does NOT:
1. Create `index.theme` in user directory (assumes it exists)
2. Run `gtk-update-icon-cache` automatically
3. Notify the user to rebuild caches

This is a common issue with applications built from source - they follow the spec for icon placement but assume the environment is already properly configured.

## Quick Reference: One-Liner Fix

For most icon issues on Ubuntu 25.10, run:

```bash
cp /usr/share/icons/hicolor/index.theme ~/.local/share/icons/hicolor/ 2>/dev/null; gtk-update-icon-cache -f ~/.local/share/icons/hicolor/ 2>/dev/null; sudo gtk-update-icon-cache -f /usr/share/icons/Yaru/ /usr/share/icons/Yaru-dark/ /usr/share/icons/hicolor/; echo "Done - log out and back in"
```
