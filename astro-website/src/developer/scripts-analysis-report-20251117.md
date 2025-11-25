---
title: "COMPREHENSIVE SCRIPT ANALYSIS REPORT"
description: "**Analysis Date**: 2025-11-17"
pubDate: 2025-11-25
author: "Ghostty Config Team"
tags: ['developer', 'technical']
---

# COMPREHENSIVE SCRIPT ANALYSIS REPORT
## Ghostty Configuration Files Repository - scripts/ Directory

**Analysis Date**: 2025-11-17  
**Repository**: /home/kkk/Apps/ghostty-config-files  
**Scope**: Complete /scripts/ directory analysis  
**Assessment Level**: VERY THOROUGH - All major scripts examined

---

## EXECUTIVE SUMMARY

The `/scripts/` directory contains 32 shell scripts managing installation, updates, health checks, and system configuration. Analysis reveals **critical issues** across three categories:

1. **Package Management Issues** (HIGH PRIORITY)
2. **Reversion/Downgrade Risks** (HIGH PRIORITY)
3. **Health Check Gaps** (MEDIUM PRIORITY)

**Critical Finding**: Scripts use hardcoded version assumptions and lack proper version verification mechanisms, creating risk of installation failures and unexpected downgrades.

---

## SECTION 1: PACKAGE MANAGEMENT ISSUES

### 1.1 install_ghostty.sh
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/install_ghostty.sh`

#### Issue A: Snap Confinement Enforcement Missing Actual Availability Check
- **Lines**: 133-179 (install_via_snap function)
- **Problem**: Script checks snap confinement mode but does NOT verify:
  - Whether snap actually exists in repository before attempting install
  - Whether snap search succeeds before proceeding
  - Version matching between available versions
- **Risk**: Falls back to apt/source build unnecessarily if snap snap info parsing fails
- **Verification Method**: HARDCODED (uses grep patterns, no actual version comparison)
- **Code**:
```bash
Lines 68-100: detect_snap_installation() relies on grep patterns
- Line 74: grep -qE '(publisher:.*✓|verified publisher)'  # Pattern matching
- Line 95: grep -oP 'latest/stable:\s+\K[^\s]+' | head -1  # Fragile parsing
```

#### Issue B: APT Package Availability Check Unreliable
- **Lines**: 187-218 (install_via_apt function)
- **Problem**:
  - Line 205: `apt-cache policy ghostty | grep Candidate | awk '{print $2}'` - assumes specific format
  - No verification that extracted version is valid semver
  - Does not check if version is actually installable from current repositories
- **Risk**: Silently falls back to source build if apt-cache output format differs
- **Verification Method**: PARSING (depends on apt-cache output format stability)
- **Code**:
```bash
Line 205: apt_version=$(apt-cache policy ghostty | grep Candidate | awk '{print $2}')
# Assumes exact format: "Candidate: X.Y.Z"
# Fails silently if format differs
```

#### Issue C: No Cross-Package-Manager Version Comparison
- **Lines**: 477-510 (install_ghostty_with_fallback function)
- **Problem**: 
  - Script tries snap, then apt, then source build
  - Does NOT compare available versions across methods
  - May install older version from snap when newer exists in apt/source
  - No semantic version comparison function
- **Risk**: User gets older package version without knowing newer available
- **Verification Method**: NONE - just tries sequential methods
- **Example**: If snap has v1.1.0 but apt has v1.2.0, snap will be used

#### Issue D: Zig Version Hardcoded Without Fallback
- **Lines**: 31, 272-340 (install_zig function)
- **Problem**:
  - `readonly ZIG_VERSION="0.14.0"` hardcoded (line 31)
  - No check if this version is still available online
  - No fallback mechanism if download fails
  - Version extracted from tarball filename (line 284), not verified against upstream
- **Risk**: If Zig 0.14.0 removed from downloads, installation fails permanently
- **Verification Method**: HARDCODED
- **Code**:
```bash
Lines 278-290: check_if_already_installed
- Line 284: installed_version=$("$zig_bin" zig version...)
- Extracts version after install but doesn't verify it matches expectation
```

#### Issue E: Multi-File Manager Context Menu - No Version Validation
- **Lines**: 615-897 (context menu configuration functions)
- **Problem**:
  - Functions check if ghostty binary exists but NOT version compatibility
  - No validation of file manager API compatibility
  - Hardcoded paths (.local/share/nautilus/scripts) without XDG validation
- **Risk**: Context menu scripts may fail on different file managers
- **Verification Method**: EXISTENCE CHECK ONLY (binary exists, but no version/capability check)

---

### 1.2 daily-updates.sh
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh`

#### Issue A: Version Comparison Logic Too Simplistic
- **Lines**: 128-138 (version_compare function)
- **Problem**:
  - Simple string equality check: `if [[ "$current" == "$latest" ]]`
  - Does NOT handle semantic versioning (e.g., v25.0.0 vs 25.0)
  - No handling of pre-release versions (alpha, beta, rc)
  - Returns 0 for equal, 1 for not equal - confusing semantics
- **Risk**: May skip legitimate updates due to version format mismatch
- **Verification Method**: HARDCODED STRING COMPARISON
- **Code**:
```bash
Lines 129-138: version_compare()
if [[ "$current" == "$latest" ]]; then
    return 0  # Same version
else
    return 1  # Different version (but doesn't indicate which is newer!)
fi
```

#### Issue B: npm Package Version Detection Unreliable
- **Lines**: 374-442 (update_npm_packages function)
- **Problem**:
  - Line 421: `npm outdated -g 2>/dev/null | tail -n +2 | wc -l` - counts lines
  - Assumes specific output format from npm outdated
  - No parsing of actual version numbers
  - May count skipped/errored packages as outdated
- **Risk**: Updates may be skipped or applied incorrectly
- **Verification Method**: TEXT PARSING (fragile)
- **Code**:
```bash
Line 421: outdated_count=$(npm outdated -g 2>/dev/null | tail -n +2 | wc -l || echo "0")
# Just counts lines, doesn't validate they're actually packages
```

#### Issue C: Claude CLI Version Detection Missing
- **Lines**: 444-491 (update_claude_cli function)
- **Problem**:
  - Line 471: `claude --version 2>&1 | head -1` - assumes specific output format
  - No verification that output contains valid version string
  - No handling of different version formats from different CLI versions
- **Risk**: Version detection fails silently, causing skipped updates
- **Verification Method**: PARSING (fragile)

#### Issue D: uv Tool Version Parsing Fragile
- **Lines**: 631-666 (update_uv function)
- **Problem**:
  - Line 646: `uv --version 2>&1` piped to line 651 for comparison
  - Assumes output format is stable
  - No validation of version string format
- **Risk**: Version detection fails for unexpected output formats
- **Verification Method**: PARSING (fragile)
- **Code**:
```bash
Line 646: current_version=$(uv --version 2>&1 || echo 'unknown')
Line 651: new_version=$(uv --version 2>&1 || echo 'unknown')
# Doesn't parse/compare versions, just checks string equality
```

#### Issue E: spec-kit Version Detection Complex and Error-Prone
- **Lines**: 668-714 (update_spec_kit function)
- **Problem**:
  - Line 684: checks `uv tool list` output format
  - Line 694: `specify --version 2>/dev/null | awk '{print $NF}'` - fragile parsing
  - Dependencies on uv being installed
  - No fallback if version detection fails
- **Risk**: Updates skipped if version format unexpected
- **Verification Method**: MULTIPLE TEXT PARSING LAYERS

#### Issue F: No Actual Package Verification After Update
- **Lines**: 165-212 (update_github_cli function and others)
- **Problem**:
  - Checks if software exists BEFORE update but NOT AFTER
  - No verification that binary actually works post-update
  - No rollback mechanism if update corrupts installation
- **Risk**: Silent failures - thinks update succeeded when it didn't
- **Verification Method**: NONE POST-UPDATE
- **Code**:
```bash
Lines 202-206: if sudo -n apt upgrade -y gh 2>&1 | tee -a "$LOG_FILE"; then
    local new_version=$(gh --version 2>/dev/null | head -1 || echo "unknown")
    # Trusts apt exit code, doesn't actually test gh functionality
fi
```

---

### 1.3 install_node.sh
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/install_node.sh`

#### Issue A: Node Version Hardcoded but Assumption Based
- **Lines**: 58, 331-334
- **Problem**:
  - Line 58: `: "${NODE_VERSION:=25}"` - assumes major version 25 always available
  - No check if fnm can actually install this version
  - No fallback for LTS or previous versions if 25 unavailable
- **Risk**: Installation fails if Node v25 removed from distribution
- **Verification Method**: HARDCODED ASSUMPTION
- **Code**:
```bash
Line 58: : "${NODE_VERSION:=25}"
# No verification this version will be available
```

#### Issue B: fnm Version Detection Incomplete
- **Lines**: 239-254 (install_fnm function)
- **Problem**:
  - Line 240: `fnm --version 2>/dev/null | awk '{print $2}'` - assumes position 2
  - Different fnm versions may have different output format
  - No verification that fnm can actually list/install Node versions
- **Risk**: Uses old fnm that can't install Node v25
- **Verification Method**: PARSING (fragile)

#### Issue C: Version Comparison Logic for Node
- **Lines**: 361-398 (install_node function)
- **Problem**:
  - Lines 373-389: compares major versions only (get_major_version extracts first digit)
  - Example: v24.11.1 and v24.0.0 considered "same" - won't update
  - No semantic version comparison library (relies on string operations)
- **Risk**: Minor/patch updates skipped if major version matches
- **Verification Method**: TEXT EXTRACTION (not proper semver comparison)
- **Code**:
```bash
Lines 361-398: Comparison logic
local target_major=$(get_major_version "$node_version")
# Only compares major versions, ignores minor/patch
if [[ "$installed_version" == "$node_version"* ]]; then
    # Prefix match only, not proper version comparison
fi
```

#### Issue D: Internet Connectivity Check Overly Simplistic
- **Lines**: 100-116 (check_internet_connectivity function)
- **Problem**:
  - Uses ping to DNS servers (8.8.8.8, 1.1.1.1, 9.9.9.9)
  - Some networks block ICMP ping
  - Doesn't test actual download capability
  - May report "connected" when downloads fail
- **Risk**: Proceeds with installation that will fail
- **Verification Method**: PING ONLY (not comprehensive)
- **Code**:
```bash
Lines 106-112: ping -c 1 -W 2 "$dns"
# ICMP may be blocked even if HTTP/HTTPS works
```

---

### 1.4 install_modern_tools.sh
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/install_modern_tools.sh` (first 200 lines)

#### Issue A: GitHub Release Asset Pattern Matching Fragile
- **Lines**: 64-92 (_get_latest_github_release_url function)
- **Problem**:
  - Line 83: `grep -oP "\"browser_download_url\":\s*\"\K[^\"]*${asset_pattern}[^\"]*"`
  - Assumes JSON structure from GitHub API
  - No error handling if pattern matches multiple files
  - Uses first match without validation it's the right binary
- **Risk**: May download wrong binary (e.g., source code instead of binary)
- **Verification Method**: PATTERN MATCHING (fragile)

#### Issue B: eza Version Comparison Missing
- **Lines**: 153-160
- **Problem**:
  - Line 156: `verify_binary "eza" "${MIN_EZA_VERSION}" "eza --version"`
  - MIN_EZA_VERSION hardcoded to 0.10.0
  - No check if newer eza binary actually has improvements over older
- **Risk**: Installation skipped if already has version >= 0.10.0 (even if much older)
- **Verification Method**: HARDCODED MINIMUM VERSION

#### Issue C: bat Installation Uses Wrong Command Name
- **Lines**: 104-145
- **Problem**:
  - Ubuntu packages bat as "batcat" due to name conflict
  - Script tries to create symlink, but symlink may not be in PATH
  - Falls back to apt install without checking PATH configuration
- **Risk**: "bat" command not available even after installation appears successful
- **Verification Method**: WORKAROUND (not proper fix)
- **Code**:
```bash
Lines 131-135: if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
    mkdir -p "$TOOLS_INSTALL_DIR"
    ln -sf "$(which batcat)" "${TOOLS_INSTALL_DIR}/bat"
# Symlink created but may not be in default PATH
fi
```

---

### 1.5 install_ai_tools.sh
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/install_ai_tools.sh` (first 200 lines)

#### Issue A: Claude Package Version Not Actually Verified
- **Lines**: 157-189 (install_claude_code function)
- **Problem**:
  - Line 168: `verify_binary "claude" "${MIN_CLAUDE_VERSION}" "claude --version"`
  - MIN_CLAUDE_VERSION hardcoded to 0.1.0 (placeholder value)
  - No actual version extraction/comparison
  - Assumes all versions >= 0.1.0 are acceptable
- **Risk**: May use very old Claude CLI version
- **Verification Method**: HARDCODED MINIMUM (not actual comparison)

#### Issue B: pip Detection Tries Multiple Commands
- **Lines**: 80-104 (_check_pip_available function)
- **Problem**:
  - Tries both `pip` and `pip3`
  - No verification that selected pip matches Python version
  - May select pip for wrong Python installation
- **Risk**: Packages installed for Python 2 when Python 3 needed (or vice versa)
- **Verification Method**: EXISTENCE CHECK (not version matching)

---

### 1.6 update_ghostty.sh
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/update_ghostty.sh`

#### Issue A: Zig Version Hardcoded With No Current Version Check
- **Lines**: 194, 212-283 (install_zig function)
- **Problem**:
  - Line 194: `local zig_version="0.14.0"` hardcoded
  - Line 222: checks if installed, but assumes hardcoded version is needed
  - No comparison with actual installed zig version
  - If installed zig is v0.13.0 and script needs 0.14.0, no detection
- **Risk**: Build fails with cryptic Zig compatibility errors
- **Verification Method**: HARDCODED VERSION
- **Code**:
```bash
Line 212: if command -v zig &> /dev/null; then
    local current_version=$(zig version 2>/dev/null || echo "unknown")
    echo "Zig is already installed (version: $current_version)"
    return 0  # Returns even if version doesn't match requirement!
fi
```

#### Issue B: Dependency Installation Assumes apt Packages Unchanged
- **Lines**: 286-364
- **Problem**:
  - Line 327: `dpkg -s "$dep" >/dev/null 2>&1` checks if package installed
  - Long hardcoded list of 35+ package names (lines 286-322)
  - No verification package names valid in Ubuntu version being used
  - Attempts to install packages that may have different names in different Ubuntu versions
- **Risk**: Installation fails if any package name incorrect for Ubuntu version
- **Verification Method**: HARDCODED PACKAGE NAMES

#### Issue C: Build Flags Assume Zig Build System Compatibility
- **Lines**: 536
- **Problem**:
  - `zig build --prefix /usr -Doptimize=ReleaseFast -Dcpu=baseline`
  - Flags may not be valid for all Zig versions
  - No verification build will succeed with these flags
  - If Zig version changes, flags may be invalid
- **Risk**: Build fails with cryptic error about invalid flags
- **Verification Method**: HARDCODED BUILD FLAGS

---

## SECTION 2: REVERSION AND DOWNGRADE RISKS

### 2.1 Dangerous Reversion Patterns Identified

#### Risk 1: Node.js Version "Latest" vs Constitutional "v25"
**Severity**: HIGH

- **install_node.sh, Line 58**: NODE_VERSION defaults to "25"
- **daily-updates.sh, Line 352**: Uses `fnm install --latest`
- **system_health_check.sh, Lines 290-306**: Warns if version is "lts/latest"

**Problem**: Conflicting version targets
- Installed with "25" (major version assumption)
- Updated with "--latest" (whatever fnm determines)
- Health check warns about "lts/latest" (contradictory)

**Reversion Risk**: After update, Node.js may upgrade beyond v25 or downgrade to older version depending on fnm's definition of "latest"

**Code**:
```bash
install_node.sh:58   : "${NODE_VERSION:=25}"
daily-updates.sh:352 if fnm install --latest 2>&1 | tee -a "$LOG_FILE"; then
system_health_check.sh:290 if grep -q 'NODE_VERSION="lts/latest"' "$REPO_ROOT/start.sh"; then
```

#### Risk 2: No Rollback Mechanism for Failed Package Updates
**Severity**: HIGH

**Problem**: All update scripts assume updates succeed
- No backup before installing
- No verification binary works after installation
- No rollback if installation corrupts binary

**Example from daily-updates.sh**:
```bash
Lines 202-206: if sudo -n apt upgrade -y gh 2>&1; then
    local new_version=$(gh --version 2>/dev/null | head -1 || echo "unknown")
    log_success "GitHub CLI updated"
    # No test of functionality!
fi
```

**Reversion Pattern**: If update corrupts binary, next run will fail without recovery

#### Risk 3: Hard-coded Configuration Overwrites User Changes
**Severity**: MEDIUM

**install_ghostty_config.sh**:
```bash
Line 157: cp -r "$REPO_DIR/configs/ghostty"/* "$CONFIG_DIR/"
# Overwrites user config without asking or backing up previous version
```

**Problem**: User customizations lost if not manually merged

---

### 2.2 Version Downgrade Risks

#### Pattern 1: Snap > APT > Source Build Fallback Without Version Comparison
**File**: install_ghostty.sh, lines 483-504

**Problem**:
- Tries snap first (might have v1.1.0)
- Falls back to apt (might have v1.0.5)
- Falls back to source build (might compile v1.2.0)

**Risk**: User ends up with older version than latest available

#### Pattern 2: fnm "--latest" May Not Mean "Latest Released Version"
**File**: install_node.sh, daily-updates.sh

**Problem**: fnm's "latest" may mean:
- Latest installed version
- Latest LTS version
- Latest pre-release
- Depends on fnm configuration

**Risk**: Version may go backward on next update if fnm config changes

---

## SECTION 3: HEALTH CHECK GAPS

### 3.1 system_health_check.sh
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/system_health_check.sh`

#### Gap 1: Node.js Version Check Uses Weak Comparison
- **Lines**: 257-271
- **Problem**:
  - Line 262: `if [[ "$major_version" -ge 25 ]]` - only checks MAJOR version
  - Doesn't check if actual version is too old (e.g., v25.0.0-beta)
  - Doesn't verify Node works (no test execution)
- **Missing**: Functional test of Node.js
- **Gap**: Cannot detect broken Node installation

#### Gap 2: No Verification of Package Manager State
- **Missing**: Check if apt cache corrupted, pip unable to connect, snap daemon dead
- **Impact**: Scripts may fail later with cryptic errors
- **Code location**: Would need ~20 lines of checks in section 1

#### Gap 3: fnm Installation Location Assumptions
- **Lines**: 614-623
- **Problem**:
  - Only checks `$HOME/.local/share/fnm`
  - Doesn't verify fnm command in PATH
  - Doesn't test fnm can actually install Node versions
- **Missing**: Functional test of fnm
- **Code**:
```bash
if [[ -d "$HOME/.local/share/fnm" ]]; then
    log_pass "fnm data directory exists"
    # But doesn't test fnm install <version> works!
fi
```

#### Gap 4: Context Menu Integration Not Tested
- **Lines**: Missing entirely
- **Problem**: Script checks Ghostty installed but not context menu
- **Missing**: Test if file manager integration actually works
- **Impact**: "Open in Ghostty" may not appear in right-click menu

#### Gap 5: Configuration Syntax Validation Too Simplistic
- **Lines**: 360-387
- **Problem**:
  - `ghostty +show-config` tests syntax
  - Doesn't test configuration actually works when terminal starts
  - Doesn't check performance impact of optimizations
- **Missing**: Functional test of Ghostty with configuration

#### Gap 6: Performance Metrics Uses Nanosecond Precision (Wrong!)
- **Lines**: 529-532
- **Problem**:
  ```bash
  local start_time=$(date +%s%N)  # Nanoseconds
  zsh -i -c exit 2>/dev/null
  local end_time=$(date +%s%N)
  local startup_ms=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
  ```
- **Issue**: Single measurement unreliable, affected by system load
- **Should use**: Multiple measurements, average, check variance

#### Gap 7: No Verification of XDG Base Directory Compliance
- **Missing**: Check if dircolors in correct location (~/.config/dircolors)
- **Impact**: Color configuration may not load on some systems

#### Gap 8: fnm Shell Integration Not Verified
- **Lines**: 336-348
- **Problem**:
  - Only checks if "fnm env" in .zshrc
  - Doesn't verify it's actually loaded
  - Doesn't test it actually works
- **Missing**: Test eval "$(fnm env...)" in isolated shell

---

### 3.2 check_context7_health.sh
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/check_context7_health.sh`

#### Gap 1: No Actual API Connectivity Test
- **Lines**: 137-141
- **Problem**:
  - Script checks configuration files exist
  - Does NOT test if Claude Code can actually connect to Context7
  - No test of API key validity
- **Missing**: `curl -H "Authorization: Bearer $CONTEXT7_API_KEY"` to test endpoint

#### Gap 2: Configuration Validation Only Checks Existence
- **Lines**: 48-71
- **Problem**: 
  - Checks .mcp.json exists
  - Checks it contains "context7"
  - Does NOT validate JSON syntax
  - Does NOT test server startup
- **Missing**: `jq -e '.' .mcp.json` to validate JSON

#### Gap 3: Global Configuration May Override Project Config
- **Lines**: 74-98
- **Problem**:
  - Checks both ~/.claude.json and .mcp.json
  - Doesn't clarify which takes precedence
  - Doesn't test which config actually loads
- **Missing**: Test of config precedence

---

### 3.3 check_github_mcp_health.sh
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/check_github_mcp_health.sh`

#### Gap 1: No Test of Actual GitHub API Access
- **Lines**: 28-42
- **Problem**:
  - `gh auth status` checks authentication
  - Doesn't verify GitHub API accessible from current network
  - Doesn't test MCP server can access GitHub
- **Missing**: Test query to GitHub API

#### Gap 2: MCP Package Not Actually Tested
- **Lines**: 127-134
- **Problem**:
  - `npx --yes @modelcontextprotocol/server-github --version` runs
  - Doesn't verify server actually works
  - Timeout is 10 seconds (may be too short on slow connections)
- **Missing**: Test of actual MCP functionality

#### Gap 3: Repository Information Incomplete
- **Lines**: 137-147
- **Problem**:
  - Shows git remote and branch
  - Doesn't check if you have access to actual repository operations
  - Doesn't verify GitHub MCP can access this specific repo
- **Missing**: Test repository operations (list issues, PRs, etc.)

---

## SECTION 4: CONTRADICTIONS AND CONFLICTS

### 4.1 Node.js Version Requirements Contradictory
**Locations**: CLAUDE.md, install_node.sh, daily-updates.sh, system_health_check.sh

**Contradiction A**: Latest vs Major Version
- **CLAUDE.md, Line 23**: "Always use the latest Node.js version (not LTS)"
- **install_node.sh, Line 58**: `NODE_VERSION:=25` (hardcoded major version)
- **Result**: Latest could be v26, v27, etc. but hardcoded to 25

**Contradiction B**: Update Strategy Confusion
- **daily-updates.sh, Line 352**: `fnm install --latest`
- **install_node.sh, Line 331**: `NODE_VERSION="$NODE_VERSION"`
- **Result**: Daily update uses fnm's definition of "latest", not constitutional definition

**Contradiction C**: Health Check Conflicting Message
- **system_health_check.sh, Lines 290-306**:
  - Warns if "lts/latest" is used (bad)
  - Recommends "25" (good)
  - But doesn't distinguish between LTS and latest

### 4.2 Package Manager Fallback Chain Issues
**File**: install_ghostty.sh

**Contradiction**: Snap vs APT vs Source
- Snap: "official" but may be older
- APT: "stable" but may be very old
- Source: newest but requires build time

**Problem**: No specification of WHICH version users should expect
- Documentation doesn't clarify which method is preferred
- No user control over which method used
- Version requirements not documented

### 4.3 Daily Updates vs Health Check Conflicts
**Files**: daily-updates.sh, system_health_check.sh

**Conflict A**: npm Update Strategy
- **daily-updates.sh, Line 431**: `npm update -g` (updates globally)
- **system_health_check.sh**: No check of npm global packages
- **Result**: Global packages updated but not monitored for success

**Conflict B**: fnm Update Strategy
- **daily-updates.sh, Line 338**: Runs fnm installer (may upgrade fnm)
- **install_node.sh, Lines 236-254**: Checks if fnm already installed
- **Result**: fnm may upgrade, changing behavior of Node version management

---

## SECTION 5: DETAILED ISSUE MAPPING

### Table 1: Package Management Issues by Script

| Script | Function | Line | Issue Type | Severity | Verification Method |
|--------|----------|------|------------|----------|---------------------|
| install_ghostty.sh | detect_snap_installation | 68-100 | Snap version parsing | MEDIUM | grep patterns |
| install_ghostty.sh | install_via_apt | 205 | apt-cache parsing | MEDIUM | Format assumption |
| install_ghostty.sh | install_via_snap | 137-179 | No pre-check | MEDIUM | Direct grep |
| install_ghostty.sh | install_zig | 31, 284 | Version hardcoded | HIGH | Filename extraction |
| daily-updates.sh | version_compare | 128-138 | String equality | HIGH | String match |
| daily-updates.sh | update_npm_packages | 421 | Line counting | MEDIUM | Text parsing |
| daily-updates.sh | update_claude_cli | 471 | Output format | MEDIUM | Head + awk |
| daily-updates.sh | update_uv | 646 | Output format | MEDIUM | String equality |
| install_node.sh | NODE_VERSION | 58 | Hardcoded assumption | HIGH | No check |
| install_node.sh | install_fnm | 240 | fnm parsing | MEDIUM | awk extraction |
| install_node.sh | install_node | 373-389 | Major version only | HIGH | String extraction |
| install_modern_tools.sh | _get_latest_github_release_url | 83 | Asset pattern | MEDIUM | grep pattern |
| install_ai_tools.sh | install_claude_code | 168 | MIN version constant | MEDIUM | Hardcoded |
| update_ghostty.sh | install_zig | 194 | Version hardcoded | HIGH | Line 212 assumes |
| update_ghostty.sh | REQUIRED_DEPS | 286-322 | Package names | HIGH | Hardcoded list |

### Table 2: Reversion/Downgrade Risks

| Risk Category | File | Lines | Mechanism | Impact |
|---------------|------|-------|-----------|--------|
| No rollback | daily-updates.sh | 202-206 | Silent failure | Version corruption possible |
| Conflicting versions | install_node.sh + daily-updates.sh | 58, 352 | Version targets | Downgrade/upgrade mismatch |
| Snap fallback | install_ghostty.sh | 483-510 | Tries snap first | May get older version |
| User data loss | install_ghostty_config.sh | 157 | cp -r overwrite | User customizations deleted |
| fnm "latest" ambiguity | install_node.sh + daily-updates.sh | 331, 352 | Definition unclear | Unexpected version |

### Table 3: Health Check Gaps

| Gap | File | Issue | Missing |
|-----|------|-------|---------|
| Node.js broken | system_health_check.sh | Only checks version | Functional test (node -e "console.log('OK')") |
| Package manager state | All files | No pre-check | apt/pip/snap daemon status |
| fnm functionality | system_health_check.sh | Only checks directory | `fnm install <version>` test |
| Context menu | system_health_check.sh | No test | File manager integration test |
| Ghostty functionality | system_health_check.sh | Only syntax check | `ghostty` start + functionality test |
| Performance baseline | system_health_check.sh | Single measurement | Multiple measurements, variance |
| API connectivity | check_context7_health.sh | Config check only | Live API test |
| MCP server | check_github_mcp_health.sh | Version only | Actual MCP command test |

---

## SECTION 6: ROOT CAUSE ANALYSIS

### Root Cause 1: Assumption-Based Version Checking
**Affected Scripts**: All installation and update scripts

**Cause**: Scripts assume
- Package output format will never change
- Version numbers follow specific patterns
- Available versions haven't changed

**Evidence**:
- grep patterns for version parsing (install_ghostty.sh:74)
- String equality for version comparison (daily-updates.sh:133)
- awk/cut for version extraction (install_node.sh:127)

**Why It's Dangerous**:
- Package managers change output format
- Version schemes evolve
- New releases may not follow expected patterns

### Root Cause 2: No Semantic Version Handling
**Affected Scripts**: install_node.sh, daily-updates.sh, install_ghostty.sh

**Cause**: No proper semver library used

**Evidence**:
- `get_major_version()` only extracts first digit (install_node.sh:150-154)
- String prefix matching (install_node.sh:375)
- No pre-release handling (daily-updates.sh:128)

**Why It's Dangerous**:
- v24.0.0-rc1 vs v24.0.0 treated same
- v24.11.1 vs v25.0.0 require major version update
- Cannot properly determine "newer" version

### Root Cause 3: Lack of Verification After Installation
**Affected Scripts**: daily-updates.sh, update_ghostty.sh, install_ghostty_config.sh

**Cause**: Assumes if installation command succeeds, installation succeeded

**Evidence**:
- daily-updates.sh:202-206 trusts apt exit code
- update_ghostty.sh:536-568 trusts zig exit code
- No binary execution tests after install

**Why It's Dangerous**:
- Binary may be corrupted
- Dependencies may be missing
- Permission issues may exist
- Configuration incompatibilities

### Root Cause 4: Hardcoded Assumptions About Availability
**Affected Scripts**: install_ghostty.sh, install_node.sh, update_ghostty.sh

**Cause**: Versions hardcoded without checking existence

**Evidence**:
- ZIG_VERSION="0.14.0" (install_ghostty.sh:31)
- NODE_VERSION:=25 (install_node.sh:58)
- zig_version="0.14.0" (update_ghostty.sh:194)

**Why It's Dangerous**:
- Versions removed from repositories
- API changes may require different versions
- No fallback mechanism

---

## SECTION 7: COMPREHENSIVE RECOMMENDATIONS

### High Priority Fixes

#### Fix 1: Implement Proper Semantic Versioning
**Impact**: All installation and update scripts

**Recommendation**:
```bash
# Add to common.sh - proper semver comparison function
compare_semver() {
    local v1="$1" v2="$2"
    local -a v1_parts v2_parts
    
    # Remove 'v' prefix and parse
    IFS='.' read -ra v1_parts <<< "${v1#v}"
    IFS='.' read -ra v2_parts <<< "${v2#v}"
    
    # Compare major, minor, patch in order
    for i in 0 1 2; do
        local p1="${v1_parts[$i]:-0}"
        local p2="${v2_parts[$i]:-0}"
        
        # Remove pre-release markers
        p1="${p1%%-*}"
        p2="${p2%%-*}"
        
        if [[ $p1 -gt $p2 ]]; then return 1; fi
        if [[ $p1 -lt $p2 ]]; then return 2; fi
    done
    return 0
}
```

**Files Affected**:
- install_node.sh - replace lines 73-98 (compare_versions)
- daily-updates.sh - replace lines 128-138 (version_compare)

#### Fix 2: Add Rollback Mechanism to All Updates
**Impact**: daily-updates.sh, update_ghostty.sh, install_ghostty_config.sh

**Recommendation**:
```bash
# Before each update, backup binary
backup_binary() {
    local binary="$1"
    if command -v "$binary" &>/dev/null; then
        local binary_path=$(command -v "$binary")
        local backup_dir="$HOME/.backups/$binary"
        mkdir -p "$backup_dir"
        cp "$binary_path" "$backup_dir/$(date +%Y%m%d-%H%M%S).bak"
    fi
}

# After each update, verify binary works
verify_binary_works() {
    local binary="$1"
    local test_cmd="$2"  # e.g., "node -e 'console.log(1)'"
    
    if ! eval "$test_cmd" &>/dev/null; then
        log_error "Binary $binary not functional after update"
        # Offer rollback
        return 1
    fi
    return 0
}
```

#### Fix 3: Replace All Version String Parsing with Proper Comparison
**Impact**: install_ghostty.sh, install_modern_tools.sh, install_ai_tools.sh

**Recommendation**:
- Use `jq` for JSON parsing (GitHub API)
- Use proper version comparison function (semver)
- Add validation of extracted versions

**Example - install_ghostty.sh line 205**:
```bash
# OLD (line 205)
apt_version=$(apt-cache policy ghostty | grep Candidate | awk '{print $2}')

# NEW - with validation
if ! apt_version=$(apt-cache policy ghostty 2>/dev/null | grep Candidate | awk '{print $2}'); then
    log_error "Failed to query apt version"
    return 1
fi

if ! [[ "$apt_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "Invalid version format: $apt_version"
    return 1
fi
```

#### Fix 4: Add Actual Functionality Tests After Installation
**Impact**: daily-updates.sh, update_ghostty.sh, install_ai_tools.sh

**Recommendation**:
```bash
# Add to common.sh
test_binary_functionality() {
    local binary="$1"
    local test_cmd="$2"  # e.g., "--version", "-e 'console.log(1)'"
    
    if ! output=$($binary $test_cmd 2>&1); then
        log_error "$binary not working: $output"
        return 1
    fi
    
    if [[ -z "$output" ]]; then
        log_error "$binary produced no output"
        return 1
    fi
    
    return 0
}

# Use in updates:
# daily-updates.sh line 202-206
if sudo apt upgrade -y gh 2>&1; then
    if test_binary_functionality "gh" "--version"; then
        log_success "GitHub CLI verified working"
    else
        log_error "GitHub CLI not functional - rolling back"
        # Implement rollback here
    fi
fi
```

#### Fix 5: Remove Hardcoded Version Assumptions
**Impact**: install_ghostty.sh, install_node.sh, update_ghostty.sh

**Recommendation**:
```bash
# OLD - install_node.sh line 58
: "${NODE_VERSION:=25}"

# NEW - with fallback detection
detect_latest_node_version() {
    # Try to get latest from fnm remote
    if command -v fnm &>/dev/null; then
        fnm list-remote 2>/dev/null | head -1 | sed 's/[^0-9.].*//' || echo "25"
    else
        echo "25"  # Constitutional default fallback
    fi
}

NODE_VERSION="${NODE_VERSION:-$(detect_latest_node_version)}"
```

### Medium Priority Fixes

#### Fix 6: Comprehensive Health Check Expansion
**Impact**: system_health_check.sh, check_context7_health.sh, check_github_mcp_health.sh

**Add**:
- Functional tests for all binaries
- API connectivity tests (Context7, GitHub)
- Performance baseline collection
- Configuration functionality tests
- Package manager daemon status checks

**Code locations to enhance**:
- system_health_check.sh lines 109-247 - add functional tests
- system_health_check.sh lines 523-587 - improve performance metrics (multiple runs)
- check_context7_health.sh lines 137-141 - add API test
- check_github_mcp_health.sh lines 127-134 - add MCP functionality test

#### Fix 7: Resolve Version Number Conflicts
**Impact**: CLAUDE.md, install_node.sh, daily-updates.sh, system_health_check.sh

**Recommendation**:
```markdown
# Clarify in CLAUDE.md:
"Latest Node.js version" means the highest major.minor.patch available
For fnm: always use `fnm install latest` (not lts)
Constitutional requirement: Never use LTS versions
Current stable target: v25+ (changes as Node releases new major versions)
```

#### Fix 8: Fallback Chain Specification
**Impact**: install_ghostty.sh

**Add to CLAUDE.md**:
```
Ghostty Installation Preference Order:
1. Snap - if available with classic confinement and verified publisher
2. APT - if version >= [MINIMUM_VERSION] and signed by Ubuntu
3. Source Build - if snap/apt fail or too old
4. User always gets notification of which method used and which version
```

#### Fix 9: Add Configuration Backup Before Updates
**Impact**: install_ghostty_config.sh, daily-updates.sh

**Recommendation**:
```bash
# Before any config copy
CONFIG_BACKUP_DIR="$HOME/.config/ghostty/backups"
mkdir -p "$CONFIG_BACKUP_DIR"
if [[ -f "$HOME/.config/ghostty/config" ]]; then
    cp "$HOME/.config/ghostty/config" \
       "$CONFIG_BACKUP_DIR/config.$(date +%Y%m%d-%H%M%S).bak"
    log_info "Configuration backed up"
fi
```

### Low Priority Improvements

#### Recommendation 10: Add Dry-Run Mode to All Scripts
- Many have `--dry-run` flags but use inconsistently
- Implement in update_ghostty.sh (currently missing)
- Standardize across all scripts

#### Recommendation 11: Improve Error Messages
- Add context about why verification failed
- Include commands user can run manually
- Reference documentation URLs

#### Recommendation 12: Add Telemetry/Logging
- Centralize logs in single location
- Add structured logging (JSON for parsing)
- Track installation success rates

---

## SECTION 8: TESTING STRATEGY GAPS

### Missing Test Coverage

| Area | Current | Should Have |
|------|---------|-------------|
| Version parsing | None | Unit tests for all version formats |
| Fallback chains | Manual | Automated tests for each fallback path |
| Package availability | None | Mock tests of unavailable packages |
| API interactions | None | Tests with mocked API responses |
| Configuration | Manual | Integration tests with Ghostty |
| Performance | Single run | Multiple runs with variance analysis |

### Proposed Test Suite Additions

```bash
# tests/unit_version_tests.sh
test_semver_comparison() {
    # Test cases for version comparison
    assert_greater "2.0.0" "1.9.9"
    assert_greater "1.1.0" "1.0.5"
    assert_equal "1.0.0" "1.0.0"
}

# tests/integration_package_tests.sh
test_snap_availability() {
    # Test snap detection without actually installing
    # Mock snap info output
    # Verify parser handles variations
}
```

---

## CONCLUSION

The script collection in `/scripts/` contains multiple critical issues that could lead to:
- Installation failures (hardcoded versions unavailable)
- Unexpected downgrades (version comparison failures)
- Silent corruption (no post-installation verification)
- Data loss (configuration overwrites without backup)
- Undetected problems (health checks missing functional tests)

**Most critical issue**: Lack of proper semantic version handling combined with hardcoded version assumptions creates high risk of installation failures when versions change.

**Immediate action required**: Implement proper semantic version comparison function and add functional verification after all installations/updates.
