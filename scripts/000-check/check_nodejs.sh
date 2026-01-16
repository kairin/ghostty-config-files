#!/bin/bash
# Check if Node.js is installed

# Ensure fnm is in PATH and initialized
export PATH="$HOME/.local/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env --shell bash)"
fi

# Get Latest Version
LATEST_VER=""
if command -v fnm &> /dev/null; then
    # Get latest version (including Current, not just LTS) to avoid downgrading suggestions
    LATEST_VER=$(fnm ls-remote 2>/dev/null | tail -n 1 | grep -oP 'v[\d.]+' || echo "")
fi

# Fallback: query nodejs.org if fnm not available or failed (with timeout)
if [[ -z "$LATEST_VER" ]]; then
    LATEST_VER=$(curl -s --connect-timeout 3 --max-time 5 \
        https://nodejs.org/dist/index.json 2>/dev/null | \
        grep -oP '"version":"v\K[^"]+' | head -1 || echo "-")
    [[ -n "$LATEST_VER" && "$LATEST_VER" != "-" ]] && LATEST_VER="v$LATEST_VER"
fi

if command -v node &> /dev/null; then
    VERSION=$(node -v)
    LOCATION=$(which node)
    
    if command -v fnm &> /dev/null; then
        METHOD="fnm"
        FNM_VER=$(fnm --version | head -n 1 | cut -d ' ' -f 2)
    else
        METHOD="System"
        FNM_VER=""
    fi
    
    NPM_VER=""
    if command -v npm &> /dev/null; then
        NPM_VER=$(npm -v)
    fi
    
    # Append extra info to location field, separated by ^
    # Group fnm and npm under "Bundled:" section
    EXTRA=""
    HAS_BUNDLED=""
    if [ -n "$FNM_VER" ] || [ -n "$NPM_VER" ]; then
        EXTRA="$EXTRA^Bundled:"
        HAS_BUNDLED="1"
    fi
    if [ -n "$FNM_VER" ]; then EXTRA="$EXTRA^  fnm v$FNM_VER"; fi
    if [ -n "$NPM_VER" ]; then EXTRA="$EXTRA^  npm v$NPM_VER"; fi

    # Check for global npm packages (DaisyUI/Tailwind ecosystem)
    HAS_GLOBALS=""
    if command -v npm &> /dev/null; then
        if npm list -g tailwindcss &> /dev/null 2>&1; then
            TW_VER=$(npm list -g tailwindcss --depth=0 2>/dev/null | grep tailwindcss | sed 's/.*@//')
            HAS_GLOBALS="1"
        fi
        if npm list -g daisyui &> /dev/null 2>&1; then
            DAISY_VER=$(npm list -g daisyui --depth=0 2>/dev/null | grep daisyui | sed 's/.*@//')
            HAS_GLOBALS="1"
        fi
        if npm list -g @tailwindcss/vite &> /dev/null 2>&1; then
            VITE_VER=$(npm list -g @tailwindcss/vite --depth=0 2>/dev/null | grep vite | sed 's/.*@//')
            HAS_GLOBALS="1"
        fi
    fi
    # Output each global on separate line with deeper indentation
    if [ -n "$HAS_GLOBALS" ]; then
        EXTRA="$EXTRA^Globals:"
        [ -n "$TW_VER" ] && EXTRA="$EXTRA^  tailwind v${TW_VER}"
        [ -n "$DAISY_VER" ] && EXTRA="$EXTRA^  daisyui v${DAISY_VER}"
        [ -n "$VITE_VER" ] && EXTRA="$EXTRA^  tw-vite v${VITE_VER}"
    fi

    echo "INSTALLED|$VERSION|$METHOD|$LOCATION$EXTRA|$LATEST_VER"
else
    echo "NOT_INSTALLED|-|-|-|$LATEST_VER"
fi
