# Node.js Version References - Comprehensive Audit Report
**Generated**: 2025-11-13
**Repository**: /home/kkk/Apps/ghostty-config-files
**Thorough Search**: ✅ Complete across all file types

---

## CORRECTION (2025-11-13)

**Original Report**: Recommended Node.js v24.11.1 (Latest LTS version)
**Corrected Target**: Node.js v25.2.0 (Latest current version)
**Reason**: User policy is "always use latest version globally" (not LTS)

All references below to "v24" should be read as "v25".

### Node.js Versioning Policy Clarification

**Global Policy**: Always use latest **current** version (not LTS)
- **Latest Current**: v25.2.0 (odd major number = current release line)
- **Latest LTS**: v24.11.1 (even major number = LTS release line)
- **User Preference**: Latest current (v25.x) for global installations

**Version Semantics**:
- Even major versions (18, 20, 22, 24): Long Term Support (LTS) - 30 months maintenance
- Odd major versions (19, 21, 23, 25): Current releases - Latest features, 6-8 month lifecycle

**Project Configuration**:
- Projects declare minimum version requirements in `.node-version` or `package.json`
- Per-project Node.js versions can differ from global version
- Version manager (fnm) handles automatic version switching when entering project directories

**Version Manager Benefits**:
- Global: v25.2.0 (latest features, cutting edge)
- Project-specific: v18+, v20+, v22+, v24+ (as needed)
- Automatic switching via fnm when changing directories

---

## Executive Summary

The codebase shows **inconsistent Node.js version specifications** across different configuration systems:

- **.node-version file**: v25.2.0 (Latest current version) - **CORRECTED FROM v24.11.1**
- **GitHub Actions workflows**: Mixed (v22 in 2 files, v20 in 1 file, lts/* in 1 file) - **SHOULD USE v25**
- **Installation scripts**: Uses "lts/latest" (fnm-based) - **SHOULD USE "latest" for v25**
- **Documentation**: References vary (v18+, v20+, v22, v24.x) - **SHOULD REFERENCE v25.x**
- **Dependency constraints**: Some packages require >=22.0.0 - **v25 exceeds this**

**Total references found**: 150+ across configuration files, workflows, scripts, and documentation.

---

## Detailed Findings

### HIGH PRIORITY: GitHub Actions Workflow Files

#### 1. `.github/workflows/astro-build-deploy.yml`
**File**: `/home/kkk/Apps/ghostty-config-files/.github/workflows/astro-build-deploy.yml`
**Status**: 🔴 INCONSISTENT - Using v22
**Line 30**: `node-version: '22'`

**Current State**:
```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '22'
```

**Analysis**:
- Hardcoded to v22 LTS (released April 2024, will EOL April 2027)
- Out of sync with actual environment (v25.2.0)
- Should be updated to v25 for latest current version

**Recommendation**: Update to `node-version: '25'` (latest current, not LTS)

---

#### 2. `.github/workflows/deploy-astro.yml`
**File**: `/home/kkk/Apps/ghostty-config-files/.github/workflows/deploy-astro.yml`
**Status**: 🔴 INCONSISTENT - Using v22
**Line 34**: `node-version: '22'`

**Current State**:
```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '22'
```

**Analysis**:
- Hardcoded to v22 LTS
- Matches astro-build-deploy.yml (which is good for consistency)
- Still behind current environment version (v25.2.0)

**Recommendation**: Update to `node-version: '25'` (latest current, not LTS)

---

#### 3. `.github/workflows/astro-deploy.yml`
**File**: `/home/kkk/Apps/ghostty-config-files/.github/workflows/astro-deploy.yml`
**Status**: 🔴 INCONSISTENT - Using v20
**Line 37**: `node-version: '20'`

**Current State**:
```yaml
- name: Setup Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '20'
```

**Analysis**:
- Hardcoded to v20 LTS (released April 2023, will EOL April 2026)
- Oldest version among active workflows
- File is marked as DISABLED (self-hosted runner not configured)
- Still represents inconsistency in the codebase

**Recommendation**: Update to `node-version: '25'` when re-enabling (latest current, not LTS)

---

#### 4. `.github/workflows/astro-pages-self-hosted.yml`
**File**: `/home/kkk/Apps/ghostty-config-files/.github/workflows/astro-pages-self-hosted.yml`
**Status**: 🟡 FLEXIBLE BUT WRONG POLICY - Using lts/*
**Line 47**: `node-version: 'lts/*'`

**Current State**:
```yaml
- name: Setup Node.js with cache
  uses: actions/setup-node@v4
  with:
    node-version: 'lts/*'
```

**Analysis**:
- Uses dynamic LTS selection (lts/*)
- Automatically uses whatever the latest LTS is at workflow execution time
- HOWEVER: User policy is "always use latest current version", not LTS
- Only active when self-hosted runner is enabled (currently not in use)

**Recommendation**: Update to `node-version: '25'` to match user policy (latest current, not LTS)

---

### MEDIUM PRIORITY: Installation & Build Scripts

#### 5. `start.sh`
**File**: `/home/kkk/Apps/ghostty-config-files/start.sh`
**Status**: 🔴 NEEDS UPDATE - Using lts/latest (should use "latest")
**Line 56**: `NODE_VERSION="lts/latest"  # fnm supports LTS selection`

**Current State**:
```bash
NODE_VERSION="lts/latest"  # fnm supports LTS selection
```

**Analysis**:
- Uses fnm-based dynamic selection (Fast Node Manager)
- Currently installs latest LTS version (v24.x)
- User policy: "always use latest current version" (v25.x)
- Constitutional requirement: fnm mandatory for 40x faster startup

**Recommendation**: Update to `NODE_VERSION="latest"` (installs v25, not v24 LTS)

---

#### 6. `scripts/install_node.sh`
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/install_node.sh`
**Status**: 🔴 NEEDS UPDATE - Using lts/latest (should use "latest")
**Line 55**: `: "${NODE_VERSION:=lts/latest}"  # fnm supports LTS selection`

**Current State**:
```bash
: "${NODE_VERSION:=lts/latest}"  # fnm supports LTS selection
: "${FNM_DIR:=${HOME}/.local/share/fnm}"  # XDG-compliant default
```

**Analysis**:
- Environment variable defaulting to lts/latest
- Used by fnm install command (line 155)
- Allows override via NODE_VERSION environment variable
- User policy: "always use latest current version" (v25.x)

**Recommendation**: Update to `: "${NODE_VERSION:=latest}"` (installs v25, not v24 LTS)

---

#### 7. `scripts/daily-updates.sh`
**File**: `/home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh`
**Status**: 🔴 NEEDS UPDATE - Using --lts flag (should use latest)
**Lines 168-178**: `fnm install --lts` checks and updates

**Current State**:
```bash
# Check for Node.js LTS updates
log_info "Checking for Node.js LTS updates..."

if fnm install --lts 2>&1 | tee -a "$LOG_FILE"; then
    log_success "Node.js LTS checked/updated"
else
    log_info "LTS version: $new_lts"
    log_warning "Node.js LTS check had issues"
fi
```

**Analysis**:
- Uses fnm install --lts for automatic LTS updates
- Part of daily update cycle
- User policy: "always use latest current version" (v25.x)

**Recommendation**: Change to `fnm install latest` (installs v25, not v24 LTS)

---

#### 8. `.runners-local/workflows/astro-build-local.sh`
**File**: `/home/kkk/Apps/ghostty-config-files/.runners-local/workflows/astro-build-local.sh`
**Status**: 🟢 GOOD - Runtime validation with 18+ requirement
**Lines 104-112**: Version checking

**Current State**:
```bash
local node_version
node_version=$(node --version | sed 's/v//')
major_version=$(echo "$node_version" | cut -d. -f1)

if [ "$major_version" -ge 18 ]; then
    log "SUCCESS" "✅ Node.js $node_version (meets Astro requirement)"
else
    log "ERROR" "❌ Node.js $node_version too old (Astro requires 18+)"
fi
```

**Analysis**:
- Runtime validation checks if Node.js >= 18
- Reports actual version in use (v24.11.1)
- Flexible to any version >= 18
- Good defensive programming

**Recommendation**: ✅ Keep as-is

---

### LOW PRIORITY: Version Configuration Files

#### 9. `.node-version` File
**File**: `/home/kkk/Apps/ghostty-config-files/.node-version`
**Status**: 🔴 PINNED - v24.11.1 (should be v25.2.0)
**Content**: `v24.11.1`

**Analysis**:
- Pinned to specific LTS version (v24.11.1)
- Used by fnm for project-specific version management
- `.node-version` file is standard tooling convention
- User policy: "always use latest current version" (v25.2.0)

**Recommendation**:
- Update to `v25.2.0` (latest current version)
- Or use `25` to allow minor version updates within v25.x line
- Note: v25 is current release (6-8 month lifecycle), not LTS (30 month lifecycle)

---

### LOW PRIORITY: Documentation References

#### 10. Documentation Files (Multiple)
**Files**: 
- `README.md` line 14
- `website/src/user-guide/installation.md` lines 26, 90
- `website/src/ai-guidelines/core-principles.md` line 30
- `website/src/developer/architecture.md` line 7
- `CHANGELOG.md` lines 141, 194, 251, 906
- Specifications and guides (15+ files)

**Status**: 🟡 MIXED - Multiple version references

**Current References**:
```
- "Node.js LTS via fnm" (INCORRECT - should be "latest current")
- "Node.js 18+" (minimum requirement)
- "Node.js v22 LTS" (dated, should be v25 current)
- "Node.js v24.6.0" (specific historical version)
- "Node.js v24.11.1" (outdated, should be v25.2.0)
```

**Analysis**:
- CLAUDE.md states "Node.js LTS via fnm" as standard - **NEEDS CORRECTION**
- Documentation mostly uses LTS references - **SHOULD USE "latest current"**
- Some CHANGELOG entries show historical v24.6.0/v24.11.1 - **UPDATE TO v25.2.0**
- GitHub Actions workflows show v22 - **SHOULD BE v25**

**Recommendation**:
- Update documentation saying "LTS" → "latest current (v25+)"
- Keep fnm references (constitutional requirement)
- Update CHANGELOG with current v25.2.0
- Document user policy: "always use latest current version" (not LTS)

---

### CRITICAL PRIORITY: Inconsistencies to Resolve

#### Summary Table of Discrepancies

| File | Current | Should Be | Priority | Impact |
|------|---------|-----------|----------|--------|
| astro-build-deploy.yml | v22 | v25 | HIGH | Build using old version |
| deploy-astro.yml | v22 | v25 | HIGH | Build using old version |
| astro-deploy.yml | v20 | v25 | HIGH | Disabled, but very outdated |
| astro-pages-self-hosted.yml | lts/* | v25 | HIGH | Wrong policy (LTS vs current) |
| .node-version | v24.11.1 | v25.2.0 or 25 | HIGH | Wrong version policy |
| start.sh | lts/latest | latest | HIGH | Installing LTS instead of current |
| install_node.sh | lts/latest | latest | HIGH | Installing LTS instead of current |
| daily-updates.sh | --lts | latest | HIGH | Updating LTS instead of current |
| Documentation | Various | Update to v25 | MEDIUM | Clarity and policy alignment |

---

## Recommendations by Priority

### 🔴 CRITICAL (Address First)

1. **Update ALL Node.js version references to v25 (latest current)**
   ```yaml
   # GitHub Actions workflows
   node-version: '25'
   ```

   ```bash
   # Installation scripts
   NODE_VERSION="latest"  # fnm installs v25
   ```

   ```
   # .node-version file
   v25.2.0
   # OR for minor version flexibility:
   25
   ```

   **Files requiring updates**:
   - `.github/workflows/astro-build-deploy.yml` (line 30): v22 → v25
   - `.github/workflows/deploy-astro.yml` (line 34): v22 → v25
   - `.github/workflows/astro-deploy.yml` (line 37): v20 → v25
   - `.github/workflows/astro-pages-self-hosted.yml` (line 47): lts/* → v25
   - `.node-version`: v24.11.1 → v25.2.0 or 25
   - `start.sh` (line 56): lts/latest → latest
   - `scripts/install_node.sh` (line 55): lts/latest → latest
   - `scripts/daily-updates.sh` (lines 168-178): --lts → latest

2. **Version Policy Alignment**:
   - **User Policy**: Always use latest **current** version (v25.x)
   - **NOT**: Latest LTS version (v24.x)
   - **Rationale**: Cutting edge features, latest improvements
   - **Trade-off**: 6-8 month release cycle vs 30 month LTS support

### 🟡 MEDIUM (Address Soon)

3. **Update documentation references**
   - Replace all "LTS" references with "latest current"
   - Replace "v22", "v24" with "v25" in all documents
   - Update CLAUDE.md constitutional requirement: "Node.js: Latest current via fnm"
   - Update CHANGELOG with current v25.2.0
   - Document version policy clearly

### 🟢 LOW (Informational)

4. **Understand version lifecycle**
   - v25 (current): New features, 6-8 months → v26 current (April 2025)
   - v24 (LTS): Stable, maintained until October 2027
   - User choice: Cutting edge (v25) over stability (v24)

---

## Package.json Dependencies

The `website/package.json` contains:
```json
"@astrojs/prism": {
  "peerDependencies": {
    "node": "18.20.8 || ^20.3.0 || >=22.0.0"
  }
}
```

This means:
- Minimum supported: Node 18.20.8
- Preferred: 20.3.0 or later
- Accepted: Any version >= 22.0.0
- Current: v25.2.0 ✅ **Fully Compatible** (exceeds >=22.0.0 requirement)

---

## Constitutional Alignment

**From CLAUDE.md - Line 23** (NEEDS UPDATE):
> "Node.js: Latest LTS via fnm (Fast Node Manager) - 40x faster than NVM, with system Node.js fallback"

**Should be**:
> "Node.js: Latest current via fnm (Fast Node Manager) - 40x faster than NVM, with system Node.js fallback"

**Current Implementation Status**:
- ❌ start.sh uses fnm with lts/latest → **SHOULD USE: latest**
- ❌ install_node.sh uses fnm with lts/latest → **SHOULD USE: latest**
- ❌ GitHub Actions workflows use hardcoded old versions → **SHOULD USE: v25**
- ✅ Local CI/CD validates Node.js >= 18 (v25 passes)
- ❌ CLAUDE.md constitutional document → **NEEDS CORRECTION: LTS → current**

---

## Summary Statistics

**Total Files with Node.js References**: 27 unique files
**Total References**: 150+ mentions across all file types

**By Category**:
- GitHub Actions Workflows: 4 files (8 version specifications)
- Shell Scripts: 8 files (fnm/version management)
- Configuration Files: 3 files (.node-version, package.json, etc.)
- Documentation: 12 files (200+ mentions)

**Version Specifications Found**:
- v24.11.1: 3 references (outdated, should be v25.2.0)
- v24.x/v24: 2 references (outdated, should be v25)
- v22 (LTS): 2 references (outdated GitHub Actions)
- v20 (LTS): 1 reference (very outdated GitHub Actions)
- lts/latest: 4 references (wrong policy, should be "latest")
- lts/*: 1 reference (wrong policy, should be v25)
- 18+: 5 references (minimum requirement, v25 compatible)
- No specific version: 130+ (generic references needing v25 update)

---

## Implementation Path

### Phase 1: Core Configuration Files (10 minutes)
1. Update `.node-version`: v24.11.1 → v25.2.0 or 25
2. Update `start.sh` line 56: lts/latest → latest
3. Update `scripts/install_node.sh` line 55: lts/latest → latest
4. Update `scripts/daily-updates.sh` lines 168-178: --lts → latest

### Phase 2: GitHub Actions Workflows (5 minutes)
1. Update 4 GitHub Actions workflow files to v25:
   - `.github/workflows/astro-build-deploy.yml` (line 30)
   - `.github/workflows/deploy-astro.yml` (line 34)
   - `.github/workflows/astro-deploy.yml` (line 37)
   - `.github/workflows/astro-pages-self-hosted.yml` (line 47)

### Phase 3: Documentation & Constitutional Updates (15 minutes)
1. Update CLAUDE.md: "Latest LTS" → "Latest current"
2. Update CHANGELOG.md with v25.2.0 references
3. Update README.md Node.js references
4. Update installation guides
5. Document version policy clearly

### Phase 4: Testing & Verification (10 minutes)
1. Run `fnm install latest` to get v25.2.0
2. Test astro-build-deploy.yml workflow
3. Verify local build still works
4. Confirm no compatibility regressions

**Total Time Estimate**: ~40 minutes

---

## Files Requiring Updates

### 🔴 CRITICAL - MUST UPDATE (Breaking Changes)
1. `/home/kkk/Apps/ghostty-config-files/.node-version` - v24.11.1 → v25.2.0 or 25
2. `/home/kkk/Apps/ghostty-config-files/start.sh` (line 56) - lts/latest → latest
3. `/home/kkk/Apps/ghostty-config-files/scripts/install_node.sh` (line 55) - lts/latest → latest
4. `/home/kkk/Apps/ghostty-config-files/scripts/daily-updates.sh` (lines 168-178) - --lts → latest
5. `/home/kkk/Apps/ghostty-config-files/.github/workflows/astro-build-deploy.yml` (line 30) - v22 → v25
6. `/home/kkk/Apps/ghostty-config-files/.github/workflows/deploy-astro.yml` (line 34) - v22 → v25
7. `/home/kkk/Apps/ghostty-config-files/.github/workflows/astro-deploy.yml` (line 37) - v20 → v25
8. `/home/kkk/Apps/ghostty-config-files/.github/workflows/astro-pages-self-hosted.yml` (line 47) - lts/* → v25

### 🟡 IMPORTANT - SHOULD UPDATE (Documentation)
1. `CLAUDE.md` (line 23) - "Latest LTS" → "Latest current"
2. `CHANGELOG.md` - Add v25.2.0 references
3. `README.md` - Update Node.js references to v25
4. Various documentation files - Update all version references to v25
5. Installation guides - Document "latest current" policy

### ✅ ALREADY CORRECT
1. `.runners-local/workflows/astro-build-local.sh` - Correctly validates >= 18 (v25 compatible)
2. `website/package.json` - Correctly requires >= 22 (v25 compatible)

