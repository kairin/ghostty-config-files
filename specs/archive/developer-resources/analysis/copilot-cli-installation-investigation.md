# Copilot CLI Installation Investigation Report
Date: 2025-11-14
System: Ubuntu 25.10 with fnm (Fast Node Manager)

## Executive Summary

GitHub Copilot CLI IS WORKING but the daily update script CANNOT DETECT IT because:
1. The `copilot` command comes from MULTIPLE sources (npm + gh extension)
2. The npm-based installation is in OLD Node.js version (v24.6.0 via nvm)
3. The current Node.js environment (v25.2.0 via fnm) has NO global packages
4. The update script checks npm for `@github/copilot` but finds nothing in current Node.js

## Detailed Findings

### 1. Copilot Binary Location
```bash
$ which copilot
/home/kkk/.nvm/versions/node/v24.6.0/bin/copilot

$ type -a copilot
copilot is /home/kkk/.nvm/versions/node/v24.6.0/bin/copilot (appears 3x in PATH)
```

**Analysis**: The `copilot` binary is a symlink to npm package in OLD nvm-managed Node.js v24.6.0, but it's still in PATH due to PATH pollution.

### 2. npm-based Installation (@github/copilot)
```bash
Location: /home/kkk/.nvm/versions/node/v24.6.0/lib/node_modules/@github/copilot
Version: 0.0.354
Type: Node.js package (npm global)
```

**Found in OLD Node.js versions:**
- v24.6.0/lib/node_modules/@github/copilot
- v24.8.0/lib/node_modules/@github/copilot
- v24.9.0/lib/node_modules/@github/copilot

**NOT found in CURRENT Node.js:**
- v25.2.0/installation/lib/node_modules/ → EMPTY!

### 3. gh CLI Extension (github/gh-copilot)
```bash
$ gh extension list
gh copilot    github/gh-copilot    v1.1.1

Location: ~/.local/share/gh/extensions/gh-copilot/gh-copilot
Type: ELF 64-bit LSB executable (Go binary, statically linked)
Version: v1.1.1 (2025-06-17)

$ gh copilot --version
version 1.1.1 (2025-06-17)
```

**Analysis**: This is a SEPARATE installation - a compiled Go binary managed by gh CLI.

### 4. Current Node.js Environment
```bash
$ node --version
v25.2.0

$ npm --version
11.6.2

$ npm root -g
/home/kkk/.local/share/fnm/node-versions/v25.2.0/installation/lib/node_modules

$ npm list -g @github/copilot
/home/kkk/.local/share/fnm/node-versions/v25.2.0/installation/lib
└── (empty)
```

**Analysis**: fnm v25.2.0 has NO global npm packages installed. All global packages are in old nvm installations.

### 5. Why Update Script Reports "Not Installed"

**Script Logic (daily-updates.sh:547-599)**:
```bash
# Line 568: Check if @github/copilot is installed via npm
if ! npm list -g @github/copilot &>/dev/null; then
    log_skip "GitHub Copilot CLI not installed"
    track_update_result "Copilot CLI" "skip"
    return 0
fi
```

**Problem**:
- Script uses CURRENT npm (fnm v25.2.0)
- Current npm sees EMPTY global packages directory
- `npm list -g @github/copilot` returns exit code 1 (not found)
- Script skips update

**Reality**:
- `copilot` command WORKS because PATH contains OLD nvm directory
- User runs old v24.6.0 npm-based copilot (0.0.354)
- gh extension also available (v1.1.1)

## PATH Analysis

```bash
$ echo $PATH | tr ':' '\n' | grep -E "nvm|fnm|node"
/run/user/1000/fnm_multishells/767725_1763088942981/bin  # fnm v25.2.0 (FIRST)
/home/kkk/.local/share/fnm                                # fnm directory
/home/kkk/.nvm/versions/node/v24.6.0/bin                 # OLD nvm (appears 3x!)
/home/kkk/.nvm/versions/node/v24.6.0/bin
/home/kkk/.nvm/versions/node/v24.6.0/bin
```

**Issue**: PATH pollution with duplicate nvm directories allows old copilot to work, masking the missing installation in current Node.js.

## Root Causes

### 1. Node.js Version Manager Migration
- **Previously**: nvm managing Node.js v24.x with global packages
- **Currently**: fnm managing Node.js v25.2.0 with NO global packages
- **Issue**: Global npm packages NOT migrated from nvm to fnm

### 2. Dual Copilot Installations
- **npm package** (@github/copilot): Version 0.0.354 in old Node.js
- **gh extension** (github/gh-copilot): Version v1.1.1 (separate Go binary)
- **Confusion**: Which one is the "correct" one?

### 3. Update Script Assumptions
- Assumes `npm list -g @github/copilot` reflects actual installation
- Doesn't check alternative installation methods (gh extension, PATH)
- Doesn't detect old Node.js versions with global packages

## Available Copilot Versions

### Current Working Command
```bash
$ copilot --version
0.0.354
Commit: 076bd172b
```
**Source**: npm package in old nvm Node.js v24.6.0

### gh Extension
```bash
$ gh copilot --version
version 1.1.1 (2025-06-17)
```
**Source**: gh CLI extension (Go binary)

## Recommendations

### Option 1: Reinstall in Current Node.js (fnm v25.2.0)
```bash
npm install -g @github/copilot
```
**Pros**: Update script will detect and update correctly
**Cons**: Creates duplicate installation, may conflict with gh extension

### Option 2: Remove npm Package, Use gh Extension Only
```bash
# Remove old npm installations
/home/kkk/.nvm/versions/node/v24.6.0/bin/npm uninstall -g @github/copilot
/home/kkk/.nvm/versions/node/v24.8.0/bin/npm uninstall -g @github/copilot
/home/kkk/.nvm/versions/node/v24.9.0/bin/npm uninstall -g @github/copilot

# Update script to check gh extension instead of npm
# Modify daily-updates.sh:547-599 to check:
if ! gh extension list | grep -q "gh-copilot"; then
    log_skip "GitHub Copilot CLI not installed"
    return 0
fi
```
**Pros**: Single source of truth, official gh extension
**Cons**: Requires script modification

### Option 3: Fix Update Script Detection
Modify daily-updates.sh to check BOTH:
1. npm package in current Node.js
2. OLD nvm Node.js versions with global packages
3. gh CLI extension

```bash
# Enhanced detection
if ! npm list -g @github/copilot &>/dev/null && \
   ! command -v copilot &>/dev/null && \
   ! gh extension list | grep -q "gh-copilot"; then
    log_skip "GitHub Copilot CLI not installed"
    return 0
fi
```
**Pros**: Most comprehensive, detects all installation methods
**Cons**: Complex logic, multiple update paths

### Option 4: Migrate All Global Packages from nvm to fnm
```bash
# Export old nvm global packages
cd /home/kkk/.nvm/versions/node/v24.6.0/lib/node_modules/
npm list -g --depth=0 --json > /tmp/old-npm-globals.json

# Reinstall in fnm v25.2.0
npm install -g @anthropic-ai/claude-code
npm install -g @google/gemini-cli
npm install -g @github/copilot
```
**Pros**: Clean separation, all packages in current Node.js
**Cons**: Requires manual migration, may take time

## GitHub Copilot CLI Deprecation Notice

**Note**: Script mentions "gh copilot extension was deprecated in Sept 2025" (line 571), but investigation shows:
- gh extension is v1.1.1 from June 2025 (BEFORE deprecation)
- npm package @github/copilot is 0.0.354 (seems older)
- Deprecation may apply to OLD gh extension, not current one

**Recommendation**: Verify GitHub's official stance on preferred installation method:
- npm package: `npm install -g @github/copilot`
- gh extension: `gh extension install github/gh-copilot`

## Immediate Action Items

1. **Verify which Copilot is preferred**: npm vs gh extension
2. **Choose migration strategy**: See Options 1-4 above
3. **Update daily-updates.sh**: Improve detection logic
4. **Clean up PATH**: Remove duplicate nvm directories
5. **Migrate global packages**: From nvm to fnm for consistency

## Long-Term Recommendations

1. **Standardize Node.js management**: Use fnm exclusively, remove nvm
2. **Document global package strategy**: Where to install, how to update
3. **Automate migration**: Script to transfer global packages during Node.js upgrades
4. **Add health checks**: Detect orphaned installations in old Node.js versions
5. **Update PATH management**: Prevent duplication from multiple Node.js managers

---

## CRITICAL UPDATE: False Positive Packages in fnm v25.2.0

### Discovery
The fnm v25.2.0 installation appears to have global packages, but they are STUB/POINTER packages, not the actual CLI tools!

```bash
$ npm list -g --depth=0
/home/kkk/.local/share/fnm/node-versions/v25.2.0/installation/lib
├── @google/gemini-cli@0.15.0
├── claude-code@1.0.0          # ← WRONG PACKAGE!
└── npm@11.6.2
```

### The "claude-code" Package is a STUB

**Package**: `claude-code` (NOT `@anthropic-ai/claude-code`)
**Version**: 1.0.0
**Purpose**: Error message pointing to correct package

```javascript
// claude-code/index.js
console.log(`Wrong package! Please install: npm install -g @anthropic-ai/claude-code`);
process.exit(0);
```

### Correct vs Incorrect Packages

| Incorrect (Stub) | Correct (Official) | Location |
|-----------------|-------------------|----------|
| `claude-code` | `@anthropic-ai/claude-code` | fnm v25.2.0 (stub), nvm v24.x (real) |
| `@github/copilot` | `@github/copilot` | nvm v24.x only, missing in fnm v25.2.0 |
| `@google/gemini-cli` | `@google/gemini-cli` | Both fnm v25.2.0 and nvm v24.x |

### Why This Matters

1. **Gemini CLI**: Only AI tool correctly installed in fnm v25.2.0
2. **Claude Code**: Stub package in fnm v25.2.0, real package in nvm v24.x
3. **Copilot CLI**: Missing entirely from fnm v25.2.0, only in nvm v24.x

### Updated Root Cause Analysis

The issue is NOT just "npm package migration" - it's that:
- **Someone installed the WRONG claude-code package** in fnm v25.2.0
- **Copilot CLI was never installed** in fnm v25.2.0 at all
- **Only Gemini CLI is correctly installed** in current Node.js

### Corrected Immediate Actions

```bash
# 1. Remove incorrect stub package
npm uninstall -g claude-code

# 2. Install correct packages in fnm v25.2.0
npm install -g @anthropic-ai/claude-code
npm install -g @github/copilot
# @google/gemini-cli is already correct - no action needed

# 3. Verify installations
npm list -g --depth=0
claude --version
copilot --version
gemini --version
```

### Why Commands Still Work

```bash
$ which claude
/home/kkk/.nvm/versions/node/v24.6.0/bin/claude

$ which copilot
/home/kkk/.nvm/versions/node/v24.6.0/bin/copilot
```

**PATH pollution**: Old nvm v24.6.0/bin is still in PATH, so commands resolve to old installations.

### Critical Finding Summary

1. **fnm v25.2.0 has WRONG claude-code package** (stub pointing to correct package)
2. **fnm v25.2.0 MISSING @anthropic-ai/claude-code** entirely
3. **fnm v25.2.0 MISSING @github/copilot** entirely
4. **Only @google/gemini-cli is correctly installed** in current Node.js
5. **All commands work due to PATH fallback** to old nvm installations

This is a CONFIGURATION ERROR, not just a migration issue.

---

**Report generated**: 2025-11-14
**Investigator**: Claude Code
**Priority**: HIGH (incorrect installations masking real issue)
