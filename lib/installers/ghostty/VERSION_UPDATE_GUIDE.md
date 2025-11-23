# Ghostty Version Update Guide

## How to Update to a New Ghostty Version

When a new Ghostty release is available, follow these simple steps:

### Step 1: Check for New Releases

Visit: https://github.com/mkasberg/ghostty-ubuntu/releases

Or run:
```bash
source lib/installers/ghostty/steps/common.sh
get_latest_ghostty_version
```

### Step 2: Update the Version Constants

Edit `lib/installers/ghostty/steps/common.sh`:

```bash
# Change this line (around line 14):
readonly GHOSTTY_VERSION="1.2.3"

# To the new version:
readonly GHOSTTY_VERSION="1.2.4"  # Example

# Usually no need to change these:
readonly GHOSTTY_PPA_VERSION="0.ppa1"
readonly GHOSTTY_UBUNTU_VERSION="25.10"
```

### Step 3: Verify the Download URL

The URL is auto-generated from the constants:
```
https://github.com/mkasberg/ghostty-ubuntu/releases/download/${GHOSTTY_VERSION}-0-ppa1/ghostty_${GHOSTTY_VERSION}-${GHOSTTY_PPA_VERSION}_amd64_${GHOSTTY_UBUNTU_VERSION}.deb
```

Verify it exists by visiting the releases page or testing:
```bash
wget --spider https://github.com/mkasberg/ghostty-ubuntu/releases/download/1.2.4-0-ppa1/ghostty_1.2.4-0.ppa1_amd64_25.10.deb
```

### Step 4: Test the Installation

```bash
./lib/installers/ghostty/install.sh
```

### Step 5: Commit the Update

```bash
git add lib/installers/ghostty/steps/common.sh
git commit -m "chore(ghostty): Update to version X.Y.Z"
git push
```

## File Naming Convention

The installer automatically generates consistent filenames:

**Downloaded filename**: `ghostty_${VERSION}-${PPA}_amd64_${UBUNTU}.deb`
**Example**: `ghostty_1.2.3-0.ppa1_amd64_25.10.deb`

**Local path**: `/tmp/ghostty_${VERSION}-${PPA}_amd64_${UBUNTU}.deb`
**Example**: `/tmp/ghostty_1.2.3-0.ppa1_amd64_25.10.deb`

The installer uses `$GHOSTTY_DEB_FILE` which automatically uses the correct filename for both download and installation.

## Automatic Update Detection

The installer checks for newer versions automatically:
- If a newer version is detected, it shows a warning
- The warning includes instructions to update `common.sh`
- Installation continues with the configured version

## Ubuntu Version Updates

If upgrading Ubuntu (e.g., 25.10 → 26.04):

1. Update `GHOSTTY_UBUNTU_VERSION` in `common.sh`
2. Verify the `.deb` exists for your Ubuntu version on GitHub
3. Test the installation

## Troubleshooting

**Q: Download fails with 404**
A: Check that the release exists on GitHub for your Ubuntu version

**Q: Filename mismatch error**
A: Verify `GHOSTTY_PPA_VERSION` matches the GitHub release tag format

**Q: How to force re-download?**
A: Delete `/tmp/ghostty_*.deb` and run the installer again

## Dependencies

The installer requires:
- `wget` (for downloading)
- `apt` (for installing)
- `curl` (optional, for version checking)

All are standard on Ubuntu systems.
