#!/bin/bash
# Check if Nerd Fonts are installed

FONTS_DIR="$HOME/.local/share/fonts"

# Get latest version from GitHub with caching
get_nerdfonts_latest() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/ghostty-checks"
    local cache_file="${cache_dir}/nerdfonts_latest.txt"
    local cache_ttl=3600  # 1 hour

    # Check if cache exists and is fresh
    if [[ -f "$cache_file" ]]; then
        local age=$(($(date +%s) - $(stat -c%Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ $age -lt $cache_ttl ]]; then
            cat "$cache_file"
            return
        fi
    fi

    # Fetch from GitHub API with timeout
    mkdir -p "$cache_dir" 2>/dev/null
    local result
    result=$(timeout 5 curl -sL --connect-timeout 3 --max-time 5 \
        "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" 2>/dev/null | \
        grep -oP '"tag_name": "\K[^"]+')

    if [[ -n "$result" ]]; then
        echo "$result" > "$cache_file"
        echo "$result"
    elif [[ -f "$cache_file" ]]; then
        # API failed, return stale cache
        cat "$cache_file"
    else
        echo "v3.4.0"  # Fallback to known version
    fi
}

# Get installed version from font file metadata or cache
get_installed_version() {
    # Try to detect version from font filename pattern or fall back to cached latest
    # Nerd Fonts doesn't embed version in filename reliably, so we use a version file if present
    local version_file="${FONTS_DIR}/.nerdfonts_version"
    if [[ -f "$version_file" ]]; then
        cat "$version_file"
    else
        # Fall back to checking GitHub for what we likely have
        echo "v3.4.0"
    fi
}

# fc-list search patterns (Nerd Fonts uses different names for licensing)
# CascadiaCode → CaskaydiaCove, SourceCodePro → SauceCodePro, IBMPlexMono → BlexMono
SEARCH_PATTERNS=("JetBrainsMono" "FiraCode" "Hack" "Meslo" "CaskaydiaCove" "SauceCodePro" "BlexMono" "Iosevka")

# Display names (user-friendly original names)
DISPLAY_NAMES=("JetBrainsMono" "FiraCode" "Hack" "Meslo" "CascadiaCode" "SourceCodePro" "IBMPlexMono" "Iosevka")

# Count installed fonts and build status list
INSTALLED_COUNT=0
FONT_STATUS=""

for i in "${!SEARCH_PATTERNS[@]}"; do
    pattern="${SEARCH_PATTERNS[$i]}"
    display="${DISPLAY_NAMES[$i]}"
    if fc-list : family | /bin/grep -qi "${pattern}.*Nerd"; then
        ((INSTALLED_COUNT++))
        FONT_STATUS="$FONT_STATUS^   ✓ $display"
    else
        FONT_STATUS="$FONT_STATUS^   ✗ $display"
    fi
done

# Fallback: If fc-list finds nothing, check font files directly
# This handles font cache propagation timing issues after fresh install
if [ $INSTALLED_COUNT -eq 0 ]; then
    FALLBACK_PATTERNS=("JetBrainsMono" "FiraCode" "Hack" "Meslo" "Caskaydia" "SauceCode" "Blex" "Iosevka")
    FALLBACK_DISPLAY=("JetBrainsMono" "FiraCode" "Hack" "Meslo" "CascadiaCode" "SourceCodePro" "IBMPlexMono" "Iosevka")
    FONT_STATUS=""

    for i in "${!FALLBACK_PATTERNS[@]}"; do
        pattern="${FALLBACK_PATTERNS[$i]}"
        display="${FALLBACK_DISPLAY[$i]}"
        # Check if any .ttf files match the pattern in fonts directory
        if find "$FONTS_DIR" -maxdepth 1 -name "*${pattern}*NerdFont*.ttf" 2>/dev/null | head -1 | grep -q .; then
            ((INSTALLED_COUNT++))
            FONT_STATUS="$FONT_STATUS^   ✓ $display"
        else
            FONT_STATUS="$FONT_STATUS^   ✗ $display"
        fi
    done

    # Trigger async cache rebuild for next time (non-blocking)
    if [ $INSTALLED_COUNT -gt 0 ]; then
        fc-cache -f "$FONTS_DIR" 2>/dev/null &
    fi
fi

if [ $INSTALLED_COUNT -gt 0 ]; then
    # Determine installation method
    FONT_PATH=$(fc-list : family file | grep -i "Nerd" | head -n 1 | cut -d: -f1)

    if [[ "$FONT_PATH" == *"$HOME/.local/share/fonts"* ]]; then
        METHOD="Script"
    else
        METHOD="System"
    fi

    # Get versions
    VERSION=$(get_installed_version)
    LATEST=$(get_nerdfonts_latest)

    # Output with font count + individual status lines
    echo "INSTALLED|$VERSION|$METHOD|$FONTS_DIR^fonts: $INSTALLED_COUNT/8$FONT_STATUS|$LATEST"
else
    LATEST=$(get_nerdfonts_latest)
    echo "NOT_INSTALLED|-|-|-|$LATEST"
fi
