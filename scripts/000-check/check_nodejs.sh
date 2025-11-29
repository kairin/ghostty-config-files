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
    # fnm ls-remote | tail -n 1
    LATEST_VER=$(fnm ls-remote | tail -n 1)
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
    EXTRA=""
    if [ -n "$NPM_VER" ]; then EXTRA="$EXTRA^npm: v$NPM_VER"; fi
    if [ -n "$FNM_VER" ]; then EXTRA="$EXTRA^fnm: v$FNM_VER"; fi

    # Check for global npm packages (DaisyUI/Tailwind ecosystem)
    GLOBAL_PKGS=""
    if command -v npm &> /dev/null; then
        if npm list -g tailwindcss &> /dev/null 2>&1; then
            TW_VER=$(npm list -g tailwindcss --depth=0 2>/dev/null | grep tailwindcss | sed 's/.*@//')
            GLOBAL_PKGS="${GLOBAL_PKGS}tailwind:v${TW_VER};"
        fi
        if npm list -g daisyui &> /dev/null 2>&1; then
            DAISY_VER=$(npm list -g daisyui --depth=0 2>/dev/null | grep daisyui | sed 's/.*@//')
            GLOBAL_PKGS="${GLOBAL_PKGS}daisyui:v${DAISY_VER};"
        fi
        if npm list -g @tailwindcss/vite &> /dev/null 2>&1; then
            VITE_VER=$(npm list -g @tailwindcss/vite --depth=0 2>/dev/null | grep vite | sed 's/.*@//')
            GLOBAL_PKGS="${GLOBAL_PKGS}tw-vite:v${VITE_VER};"
        fi
    fi
    if [ -n "$GLOBAL_PKGS" ]; then
        EXTRA="$EXTRA^globals: $GLOBAL_PKGS"
    fi

    echo "INSTALLED|$VERSION|$METHOD|$LOCATION$EXTRA|$LATEST_VER"
else
    echo "Not Installed|-|-|-|$LATEST_VER"
fi
