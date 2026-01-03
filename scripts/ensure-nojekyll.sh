#!/bin/bash
# CRITICAL: Ensures .nojekyll file always exists for GitHub Pages
# Multi-layer protection system for Astro + GitHub Pages deployment

NOJEKYLL_FILE="/home/kkk/Apps/ghostty-config-files/docs/.nojekyll"
NOJEKYLL_PUBLIC="/home/kkk/Apps/ghostty-config-files/public/.nojekyll"
NOJEKYLL_BACKUP="/home/kkk/Apps/ghostty-config-files/.nojekyll.backup"

ensure_nojekyll() {
    echo "========================================"
    echo ".nojekyll Protection Verification"
    echo "========================================"
    
    # Layer 1: Primary - public/.nojekyll (auto-copied by Astro)
    if [ ! -f "$NOJEKYLL_PUBLIC" ]; then
        echo "⚠️ WARNING: Primary .nojekyll missing in public/ - recreating..."
        touch "$NOJEKYLL_PUBLIC"
        echo "✅ Created primary $NOJEKYLL_PUBLIC"
    else
        echo "✅ Layer 1 (PRIMARY): public/.nojekyll exists"
    fi

    # Layer 2: Secondary - docs/.nojekyll (created by Vite plugin)
    if [ ! -f "$NOJEKYLL_FILE" ]; then
        echo "⚠️ CRITICAL: .nojekyll missing in docs/ - recreating..."
        touch "$NOJEKYLL_FILE"
        echo "✅ Recreated $NOJEKYLL_FILE"
    else
        echo "✅ Layer 2 (SECONDARY): docs/.nojekyll exists"
    fi

    # Layer 3: Tertiary - Backup in repository root
    if [ ! -f "$NOJEKYLL_BACKUP" ]; then
        touch "$NOJEKYLL_BACKUP"
        echo "✅ Created backup .nojekyll in repository root"
    else
        echo "✅ Layer 3 (BACKUP): .nojekyll.backup exists"
    fi

    # Verify git tracking for docs/.nojekyll
    if ! git ls-files --error-unmatch "$NOJEKYLL_FILE" >/dev/null 2>&1; then
        git add "$NOJEKYLL_FILE" 2>/dev/null
        echo "✅ Added docs/.nojekyll to git tracking"
    else
        echo "✅ docs/.nojekyll is git tracked"
    fi

    echo "========================================"
    echo "✅ .nojekyll protection: ALL LAYERS VERIFIED"
    echo "========================================"
}

ensure_nojekyll
