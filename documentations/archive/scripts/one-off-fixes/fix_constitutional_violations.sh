#!/bin/bash
# Fix Script: Constitutional Violations & Configuration Issues
# Generated: 2025-11-13
# Purpose: Fix Node.js LTS→Latest migration + zsh configuration issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Constitutional Violations Fix Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Track fixes
FIXES_APPLIED=0
BACKUP_DIR="$HOME/.config/ghostty-fixes-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}📦 Backup directory: $BACKUP_DIR${NC}"
echo ""

# ==============================================
# FIX 1: start.sh - Change LTS to Latest
# ==============================================
echo -e "${BLUE}[1/7] Fixing start.sh NODE_VERSION${NC}"
if grep -q 'NODE_VERSION="lts/latest"' start.sh 2>/dev/null; then
    # Backup
    cp start.sh "$BACKUP_DIR/start.sh.backup"

    # Fix
    sed -i 's/NODE_VERSION="lts\/latest"/NODE_VERSION="25"  # Constitutional requirement: latest Node.js/' start.sh

    echo -e "${GREEN}  ✅ Fixed: start.sh now uses Node.js v25 (latest)${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
else
    echo -e "${GREEN}  ✅ Already correct: start.sh${NC}"
fi
echo ""

# ==============================================
# FIX 2: scripts/install_node.sh - Change LTS to Latest
# ==============================================
echo -e "${BLUE}[2/7] Fixing scripts/install_node.sh NODE_VERSION default${NC}"
if grep -q 'NODE_VERSION:=lts/latest' scripts/install_node.sh 2>/dev/null; then
    # Backup
    cp scripts/install_node.sh "$BACKUP_DIR/install_node.sh.backup"

    # Fix
    sed -i 's/NODE_VERSION:=lts\/latest/NODE_VERSION:=25  # Constitutional requirement: latest Node.js/' scripts/install_node.sh

    echo -e "${GREEN}  ✅ Fixed: install_node.sh now defaults to v25 (latest)${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
else
    echo -e "${GREEN}  ✅ Already correct: install_node.sh${NC}"
fi
echo ""

# ==============================================
# FIX 3: scripts/daily-updates.sh - Change --lts to --latest
# ==============================================
echo -e "${BLUE}[3/7] Fixing scripts/daily-updates.sh fnm installation${NC}"
if [ -f scripts/daily-updates.sh ] && grep -q 'fnm install --lts' scripts/daily-updates.sh 2>/dev/null; then
    # Backup
    cp scripts/daily-updates.sh "$BACKUP_DIR/daily-updates.sh.backup"

    # Fix
    sed -i 's/fnm install --lts/fnm install --latest/g' scripts/daily-updates.sh
    sed -i 's/Node.js LTS checked/Node.js latest version checked/g' scripts/daily-updates.sh

    echo -e "${GREEN}  ✅ Fixed: daily-updates.sh now updates to latest Node.js${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
else
    echo -e "${GREEN}  ✅ Already correct or file not found: daily-updates.sh${NC}"
fi
echo ""

# ==============================================
# FIX 4: Install Node.js v25.2.0 (latest)
# ==============================================
echo -e "${BLUE}[4/7] Installing Node.js v25 (latest)${NC}"
if command -v fnm >/dev/null 2>&1; then
    CURRENT_NODE=$(node --version 2>/dev/null || echo "none")
    echo -e "${YELLOW}  Current Node.js: $CURRENT_NODE${NC}"

    # Install latest v25
    echo -e "${YELLOW}  Installing Node.js v25 (latest)...${NC}"
    if fnm install 25 >/dev/null 2>&1; then
        echo -e "${GREEN}  ✅ Node.js v25 installed${NC}"

        # Set as default
        if fnm default 25 >/dev/null 2>&1; then
            echo -e "${GREEN}  ✅ Node.js v25 set as default${NC}"
            FIXES_APPLIED=$((FIXES_APPLIED + 1))
        fi

        # Show new version
        NEW_VERSION=$(fnm exec --using=25 node --version 2>/dev/null || echo "unknown")
        echo -e "${GREEN}  ✅ New version: $NEW_VERSION${NC}"
    else
        echo -e "${RED}  ❌ Failed to install Node.js v25${NC}"
    fi
else
    echo -e "${YELLOW}  ⚠️  fnm not found in PATH, skipping Node.js installation${NC}"
fi
echo ""

# ==============================================
# FIX 5: ~/.zshrc - Fix BSD stat command
# ==============================================
echo -e "${BLUE}[5/7] Fixing ~/.zshrc BSD stat command${NC}"
if [ -f ~/.zshrc ] && grep -q 'stat -f' ~/.zshrc 2>/dev/null; then
    # Backup
    cp ~/.zshrc "$BACKUP_DIR/.zshrc.backup"

    # Find and replace BSD stat with Linux-compatible version
    # Old: stat -f '%Sm' -t '%j'
    # New: date -r (file) +'%j'
    sed -i 's/stat -f.*%Sm.*-t.*%j.*~\/\.zcompdump/date -r ~\/.zcompdump +"%j"/g' ~/.zshrc

    echo -e "${GREEN}  ✅ Fixed: BSD stat command replaced with Linux-compatible version${NC}"
    FIXES_APPLIED=$((FIXES_APPLIED + 1))
else
    echo -e "${GREEN}  ✅ Already correct or not found: ~/.zshrc stat command${NC}"
fi
echo ""

# ==============================================
# FIX 6: ~/.zshrc - Remove duplicate Gemini CLI blocks
# ==============================================
echo -e "${BLUE}[6/7] Removing duplicate Gemini CLI integration blocks${NC}"
if [ -f ~/.zshrc ]; then
    # Count duplicate blocks
    GEMINI_COUNT=$(grep -c "Gemini CLI integration" ~/.zshrc 2>/dev/null || echo 0)

    if [ "$GEMINI_COUNT" -gt 1 ]; then
        # Backup already created

        # Remove duplicate empty Gemini blocks (keep only functional ones)
        # This is a simple approach - remove lines with just "# Gemini CLI integration" followed by blank line
        awk '
        /^# Gemini CLI integration/ {
            if (getline next_line && next_line !~ /^[[:space:]]*$/ && next_line !~ /^# Gemini CLI integration/) {
                print
                print next_line
            }
            next
        }
        { print }
        ' ~/.zshrc > ~/.zshrc.tmp && mv ~/.zshrc.tmp ~/.zshrc

        echo -e "${GREEN}  ✅ Removed duplicate Gemini CLI blocks${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    else
        echo -e "${GREEN}  ✅ No duplicate Gemini CLI blocks found${NC}"
    fi
fi
echo ""

# ==============================================
# FIX 7: ~/.zshrc - Remove duplicate env sourcing
# ==============================================
echo -e "${BLUE}[7/7] Removing duplicate env file sourcing${NC}"
if [ -f ~/.zshrc ]; then
    # Check for duplicate env sourcing
    ENV_COUNT=$(grep -c '^\. "$HOME/\.local/.*/bin/env"' ~/.zshrc 2>/dev/null || echo 0)

    if [ "$ENV_COUNT" -gt 1 ]; then
        # Remove the convoluted path version (keep the simple one)
        sed -i '/\. "$HOME\/\.local\/share\/\.\.\/bin\/env"/d' ~/.zshrc

        echo -e "${GREEN}  ✅ Removed duplicate env file sourcing${NC}"
        FIXES_APPLIED=$((FIXES_APPLIED + 1))
    else
        echo -e "${GREEN}  ✅ No duplicate env sourcing found${NC}"
    fi
fi
echo ""

# ==============================================
# SUMMARY
# ==============================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}✅ Fixes applied: $FIXES_APPLIED${NC}"
echo -e "${YELLOW}📦 Backups saved to: $BACKUP_DIR${NC}"
echo ""

if [ "$FIXES_APPLIED" -gt 0 ]; then
    echo -e "${YELLOW}⚠️  ACTION REQUIRED:${NC}"
    echo -e "  1. Review changes (backups in $BACKUP_DIR)"
    echo -e "  2. Restart your shell: ${GREEN}source ~/.zshrc${NC}"
    echo -e "  3. Verify Node.js version: ${GREEN}node --version${NC} (should show v25.x.x)"
    echo -e "  4. Test Ghostty: ${GREEN}ghostty +show-config${NC}"
    echo ""
    echo -e "${BLUE}🔄 To restart shell environment:${NC}"
    echo -e "  ${GREEN}exec zsh${NC}  or  ${GREEN}source ~/.zshrc${NC}"
else
    echo -e "${GREEN}✅ All checks passed - no fixes needed!${NC}"
fi
echo ""

# ==============================================
# VALIDATION
# ==============================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Validate Node.js version
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    if [[ "$NODE_VERSION" =~ ^v25\. ]]; then
        echo -e "${GREEN}✅ Node.js version: $NODE_VERSION (latest)${NC}"
    else
        echo -e "${YELLOW}⚠️  Node.js version: $NODE_VERSION (expected v25.x)${NC}"
        echo -e "${YELLOW}   Run: fnm use 25 && fnm default 25${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Node.js not found in PATH${NC}"
fi

# Validate fnm
if command -v fnm >/dev/null 2>&1; then
    FNM_VERSION=$(fnm --version)
    echo -e "${GREEN}✅ fnm version: $FNM_VERSION${NC}"
else
    echo -e "${RED}❌ fnm not found${NC}"
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Fix script complete!${NC}"
echo -e "${BLUE}========================================${NC}"
