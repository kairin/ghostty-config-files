# Constitutional Principle: Script Proliferation Prevention

**Status**: MANDATORY - CONSTITUTIONAL REQUIREMENT
**Enforcement**: Automated validation via 002-compliance
**Last Updated**: 2025-11-21
**Authority**: User Constitutional Requirement

---

## Core Principle

> "Improve existing scripts directly. Minimize creating scripts to solve other scripts, creating more and more scripts just to solve issues caused by other scripts."
>
> — User Constitutional Requirement, 2025-11-21

This principle is **NON-NEGOTIABLE** and applies to **ALL** AI assistants (Claude, Gemini, ChatGPT, etc.) working on this repository.

---

## Mandatory Rules

### Rule 1: Enhancement Over Creation

**Before creating ANY new script file (`.sh`, `.bash`), you MUST:**

1. ✅ Identify the existing script that needs the functionality
2. ✅ Enhance that script directly with the new capability
3. ✅ Document the enhancement in the existing script's header comments
4. ✅ Verify the enhancement doesn't break existing functionality

**Exception**: Test files (`tests/`, `*_test.sh`, `test_*.sh`, `*_spec.sh`)

**Enforcement**: 002-compliance validates all new file creation

---

### Rule 2: No Wrapper Scripts

**PROHIBITED PATTERN**:
```bash
# ❌ VIOLATION: Creating wrapper to fix existing script
scripts/fix-broken-script.sh       # Wraps scripts/broken-script.sh
scripts/enhanced-installer.sh      # Wraps lib/installer.sh
scripts/improved-setup.sh          # Wraps start.sh
```

**Why This Is Wrong**:
- Creates script call chains (script A → script B → script C)
- Increases maintenance burden (fix issues in two places)
- Makes debugging harder (error could be in either script)
- Violates DRY principle (Don't Repeat Yourself)

**CORRECT APPROACH**:
```bash
# ✅ COMPLIANT: Fix the original script directly
scripts/broken-script.sh           # Enhanced with fix
lib/installer.sh                   # Enhanced with new features
start.sh                           # Enhanced with improvements
```

**Why This Is Correct**:
- Single source of truth for functionality
- Issues fixed at the source
- Clear debugging path
- Minimal maintenance overhead

---

### Rule 3: No Helper Scripts for Single-Purpose Tasks

**PROHIBITED PATTERN**:
```bash
# ❌ VIOLATION: Helper script for one function used by one script
lib/utils/version-compare.sh      # Only used by installer.sh
lib/utils/snap-detect.sh          # Only used by prerequisites.sh
scripts/install-icon.sh            # Only called by desktop-entry.sh
```

**Why This Is Wrong**:
- Over-engineering for simple tasks
- Creates unnecessary file count
- Makes code navigation harder
- Increases cognitive load (where is this function?)

**CORRECT APPROACH**:
```bash
# ✅ COMPLIANT: Add function to existing library or script

# Option 1: Add to core library if reusable
lib/core/logging.sh                # Add version_compare() function

# Option 2: Add directly to script if single-use
lib/installers/ghostty/steps/00-check-prerequisites.sh
# Add check_snap_conflicts() function inline

# Option 3: Add to existing step script
lib/installers/ghostty/steps/07-create-desktop-entry.sh
# Add install_ghostty_icon() function inline
```

**Why This Is Correct**:
- Functions live where they're used
- Easy to find related code
- Minimal file count
- Clear ownership

---

### Rule 4: No Management Scripts That Only Call Others

**PROHIBITED PATTERN**:
```bash
# ❌ VIOLATION: Manager script that only orchestrates calls
scripts/install-everything.sh:
#!/usr/bin/env bash
./scripts/install-ghostty.sh
./scripts/install-zsh.sh
./scripts/install-node.sh
./scripts/install-ai-tools.sh
```

**Why This Is Wrong**:
- Adds unnecessary orchestration layer
- Makes dependency tracking harder
- Increases script count without adding value
- Better handled by task runner or Makefile

**CORRECT APPROACH**:
```bash
# ✅ COMPLIANT: Use existing orchestrator or data-driven system

# Option 1: Use start.sh (existing orchestrator)
start.sh                           # Already orchestrates all installations

# Option 2: Use component managers with data-driven steps
lib/installers/ghostty/install.sh  # Orchestrates its own steps via data array

# Option 3: Document manual steps in README
README.md                          # "Run ./lib/installers/*/install.sh"
```

**Why This Is Correct**:
- Reuses existing orchestration
- Data-driven configuration over scripts
- Documentation is sufficient for manual tasks

---

### Rule 5: Consolidation Over Proliferation

**When You Find**:
- Multiple scripts doing similar things
- Scripts calling scripts calling scripts (3+ levels deep)
- Duplicate functionality across files

**You MUST**:
1. ✅ Consolidate into fewer, more capable scripts
2. ✅ Reduce call depth to 2 levels maximum
3. ✅ Inline functionality when appropriate
4. ✅ Create shared library functions for common operations

**Example Consolidation**:
```bash
# ❌ BEFORE: 5 scripts, 3-level deep calls
scripts/setup.sh → scripts/install-deps.sh → scripts/check-deps.sh
scripts/setup.sh → scripts/install-apps.sh → scripts/download-apps.sh

# ✅ AFTER: 1 script, inline functions
scripts/setup.sh:
  check_dependencies()    # Inline function
  install_dependencies()  # Inline function
  download_applications() # Inline function
  install_applications()  # Inline function
```

---

## Validation Checklist

**Before committing ANY new `.sh` file, verify ALL of these:**

### ☑ Test File Exception
- [ ] **Is this a test file?** (in `tests/`, ends with `_test.sh`, `test_*.sh`, `*_spec.sh`)
  - If **YES** → Allowed, proceed with commit
  - If **NO** → Continue checklist (REQUIRED)

### ☑ Enhancement Opportunity
- [ ] **Can this functionality be added to an existing script?**
  - If **YES** → Add to existing script, **DO NOT** create new file, **STOP**
  - If **NO** → Continue checklist (explain why in commit message)

### ☑ Wrapper Detection
- [ ] **Is this wrapping/fixing another script?**
  - If **YES** → Fix the original script, **DO NOT** create wrapper, **STOP**
  - If **NO** → Continue checklist

### ☑ Helper Function Detection
- [ ] **Is this a utility function used by only 1-2 scripts?**
  - If **YES** → Add to `lib/core/*.sh` or inline, **DO NOT** create new file, **STOP**
  - If **NO** → Continue checklist

### ☑ Call Chain Detection
- [ ] **Does this create a call chain 3+ levels deep?** (A → B → C → D)
  - If **YES** → Consolidate into fewer scripts, **DO NOT** add depth, **STOP**
  - If **NO** → Continue checklist

### ☑ Management Script Detection
- [ ] **Does this script only call other scripts?** (no actual logic)
  - If **YES** → Use existing orchestrator or document in README, **STOP**
  - If **NO** → Continue checklist

### ☑ Absolute Necessity
- [ ] **Is this absolutely necessary as a new file?**
  - If **NO** → Find alternative approach, **STOP**
  - If **YES** → Document justification in commit message, proceed

### ☑ Documentation Requirement
- [ ] **Have you documented WHY a new file is necessary?**
  - If **NO** → Add justification to commit message, **STOP**
  - If **YES** → Proceed with commit

---

## Enforcement

### Automated Validation

**002-compliance**:
- Monitors all commits for new `.sh` files
- Checks against proliferation rules
- Blocks commits that violate principles
- Provides specific remediation suggestions

**Validation Triggers**:
1. Pre-commit hooks check for new `.sh` files
2. 002-compliance reviews changes
3. Automated tests verify script count stability

**Override Process**:
- Requires explicit user approval
- Must include detailed justification
- Recorded in commit message and logs

### Manual Review

**Pull Request Requirements**:
- All new scripts reviewed by maintainers
- Justification required in PR description
- Alternative approaches must be documented
- Proliferation checklist must be completed

**Commit Message Requirements**:
```
feat: Add new script for [purpose]

SCRIPT PROLIFERATION JUSTIFICATION:
- Cannot enhance existing script because: [reason]
- Not a wrapper script because: [reason]
- Not a helper function because: [reason]
- Call chain depth: [current depth]
- Consolidation not possible because: [reason]
- Absolute necessity: [detailed explanation]

Constitutional compliance checklist:
- [x] Test file exception - NO
- [x] Enhancement opportunity - NO (reason: ...)
- [x] Wrapper detection - NO
- [x] Helper function - NO (reason: ...)
- [x] Call chain - NO (reason: ...)
- [x] Management script - NO
- [x] Absolute necessity - YES (reason: ...)
- [x] Documentation - YES (see above)
```

---

## Enforcement Mechanisms (Detailed)

### Level 1: Pre-Commit Validation (Automated)

**Trigger**: Any `git add` of a `.sh` file not in `tests/` directory

**Process**:
```
1. 002-compliance agent activated on commit attempt
2. Scans staged files for new .sh files
3. Checks each against proliferation rules:
   - Is it a test file? → ALLOW
   - Is it enhancing existing script? → BLOCK (should edit existing)
   - Is it a wrapper script? → BLOCK (pattern detected)
   - Is it a helper function? → BLOCK (should be in lib/core/)
   - Does it add call depth 3+? → BLOCK (consolidation needed)
4. If violation detected:
   - Commit BLOCKED
   - Specific violation identified
   - Remediation suggestion provided
```

**Example Block Message**:
```
❌ COMMIT BLOCKED: Script Proliferation Violation

File: scripts/fix-installer.sh

Violation: WRAPPER_SCRIPT_DETECTED
- This script calls lib/installers/ghostty/install.sh
- Wrapper scripts are prohibited

Remediation:
→ Edit lib/installers/ghostty/install.sh directly
→ Add your fix to the existing script
→ Do NOT create a wrapper

To override (requires justification):
git commit -m "feat: Add script..." --allow-empty
Then include SCRIPT PROLIFERATION JUSTIFICATION in message
```

### Level 2: CI/CD Gate (Automated)

**Trigger**: Push to any branch

**Process**:
```
1. Local CI/CD workflow runs (./.runners-local/workflows/gh-workflow-local.sh)
2. Script count check executes:
   - Count current .sh files (excluding tests/)
   - Compare against baseline
   - If count increased without justification → FAIL
3. Call depth analysis:
   - Trace script dependencies
   - If any chain > 2 levels → FAIL
4. Orphan detection:
   - Find .sh files not referenced by any other script
   - If orphans found → WARNING
```

**Gate Thresholds**:
| Check | Pass | Warn | Fail |
|-------|------|------|------|
| Script count vs baseline | +0 | +1-2 with justification | +3 or any without justification |
| Call depth | ≤2 levels | N/A | 3+ levels |
| Orphaned scripts | 0 | 1-2 | 3+ |
| Wrapper patterns | 0 | N/A | Any detected |

### Level 3: Monthly Audit Cycle (Manual + Automated)

**Schedule**: First Monday of each month

**Automated Steps**:
```bash
# 024-script-check agent runs:
1. Generate script inventory
2. Compare against previous month
3. Identify new scripts
4. Validate each has justification
5. Flag potential violations
6. Generate audit report
```

**Manual Review Steps**:
1. Review audit report
2. Validate justifications for new scripts
3. Identify consolidation opportunities
4. Flag scripts for deprecation
5. Update baseline metrics
6. Document decisions in monthly log

### Level 4: Manual Override Protocol

**When Override is Legitimate**:
- Architectural constraint prevents enhancement
- New capability genuinely required
- No existing script can accommodate
- User explicitly requests exception

**Override Process**:
```
Step 1: DOCUMENT (required)
- Write detailed justification
- Explain why alternatives won't work
- List attempted alternatives
- Describe architectural constraint

Step 2: REQUEST (required)
- Use AskUserQuestion tool
- Present justification to user
- Explain consequences
- Wait for explicit approval

Step 3: APPROVAL (required)
- User explicitly approves: "Proceed with exception"
- User denies: "Find alternative approach"
- User requests changes: iterate on justification

Step 4: COMMIT (only after approval)
- Include full justification in commit message
- Reference user approval
- Add to authorized exceptions list (if applicable)

Step 5: RECORD (required)
- Log exception in .runners-local/logs/proliferation-exceptions.log
- Include date, script, justification, approver
```

**Override Commit Message Format**:
```
feat: Add [script-name] with user-approved exception

SCRIPT PROLIFERATION EXCEPTION (USER APPROVED)

User approval: [date] - "Proceed with exception"

Justification:
- Architectural constraint: [specific constraint]
- Alternatives attempted: [list alternatives tried]
- Why alternatives failed: [explanation]
- Genuine new capability: [description]

Constitutional compliance:
- [x] User explicitly approved exception
- [x] Full justification documented
- [x] Exception logged

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

---

## Examples

### Example 1: Version Comparison (VIOLATION)

**❌ INCORRECT Approach**:
```bash
# Agent creates two new scripts
lib/verification/test_version_compare.sh   # Test file (ALLOWED)
lib/utils/version-compare.sh               # Helper script (VIOLATION)

# Original request: Add version detection to Ghostty installer
```

**Why This Is Wrong**:
- Creates helper script for functionality used by 1 component
- Increases file count unnecessarily
- Makes code harder to navigate

**✅ CORRECT Approach**:
```bash
# Agent enhances existing core library
lib/core/logging.sh:
  # Add new functions
  version_compare() { ... }
  version_greater() { ... }
  version_equal() { ... }

# Agent enhances existing verification
lib/installers/ghostty/steps/08-verify-installation.sh:
  # Use version_compare() from lib/core/logging.sh
  source "${REPO_ROOT}/lib/core/logging.sh"
  if version_greater "$latest" "$installed"; then
    log "WARN" "Update available"
  fi

# Test file created (ALLOWED exception)
lib/verification/test_version_compare.sh   # Integration tests
```

**Why This Is Correct**:
- Functions added to existing core library
- Reusable by all components
- Test file allowed (exception)
- No script proliferation

---

### Example 2: Snap Detection (VIOLATION)

**❌ INCORRECT Approach**:
```bash
# Agent creates new detection script
scripts/detect-snap-conflicts.sh:
#!/usr/bin/env bash
check_snap_node() { ... }
check_snap_ghostty() { ... }

# Called by all prerequisite checks
lib/installers/*/steps/00-check-prerequisites.sh:
source /home/kkk/Apps/ghostty-config-files/scripts/detect-snap-conflicts.sh
check_snap_node
```

**Why This Is Wrong**:
- Creates centralized script for decentralized usage
- Increases coupling between components
- Adds unnecessary file

**✅ CORRECT Approach**:
```bash
# Agent adds function directly to prerequisite checks
lib/installers/nodejs_fnm/steps/00-check-prerequisites.sh:
  check_snap_conflicts() {
    local package_name="$1"
    if snap list "$package_name" &>/dev/null; then
      log "WARN" "⚠️  $package_name installed via SNAP"
      log "WARN" "    Consider: sudo snap remove $package_name"
    fi
  }

  # Use inline
  check_snap_conflicts "node"
```

**Why This Is Correct**:
- Function lives where it's used
- Component-specific implementation
- No centralized dependency
- Zero new files created

---

### Example 3: Ghostty Icon Installation (VIOLATION)

**❌ INCORRECT Approach**:
```bash
# Agent creates new icon installer
scripts/install-ghostty-icon.sh:
#!/usr/bin/env bash
install_icon() { ... }
update_desktop_entry() { ... }

# Called by desktop entry script
lib/installers/ghostty/steps/07-create-desktop-entry.sh:
/home/kkk/Apps/ghostty-config-files/scripts/install-ghostty-icon.sh
```

**Why This Is Wrong**:
- Creates script for single-component functionality
- Desktop entry script should handle its own icon
- Increases maintenance complexity

**✅ CORRECT Approach**:
```bash
# Agent enhances existing desktop entry script
lib/installers/ghostty/steps/07-create-desktop-entry.sh:
  install_ghostty_icon() {
    local icon_dir="${HOME}/.local/share/icons/hicolor/scalable/apps"
    local icon_source="${BUILD_DIR}/ghostty/assets/icon.svg"

    mkdir -p "$icon_dir"
    if [[ -f "$icon_source" ]]; then
      cp "$icon_source" "${icon_dir}/ghostty.svg"
      gtk-update-icon-cache "${HOME}/.local/share/icons/hicolor/" 2>/dev/null || true
      return 0
    fi
    return 1
  }

  # Call inline
  install_ghostty_icon

  # Update desktop entry
  cat > ~/.local/share/applications/ghostty.desktop <<EOF
[Desktop Entry]
Icon=ghostty
...
EOF
```

**Why This Is Correct**:
- All icon logic in one place
- Desktop entry handles its own setup
- No new files created
- Clear ownership

---

## Metrics & Monitoring

### Baseline Metrics (2026-01-05)

**Current Script Count**:
```bash
# Count all .sh files (excluding tests)
find /home/kkk/Apps/ghostty-config-files -name "*.sh" -not -path "*/tests/*" | wc -l
# Baseline: 118 (established 2026-01-05)
```

**Call Depth Analysis**:
```bash
# Maximum call depth in repository
# Baseline: 2 levels (verified 2026-01-05)
# Pattern: installer → config script (acceptable)
# Pattern: script → logger.sh library (acceptable)
```

**Script Purpose Distribution**:
- Orchestrators: start.sh, lib/installers/*/install.sh
- Core libraries: lib/core/*.sh, lib/ui/*.sh
- Installation steps: lib/installers/*/steps/*.sh
- Utilities: scripts/*.sh
- Tests: tests/**/*.sh (exempt)

### Target Metrics

| Metric | Current | Target | Alert Threshold |
|--------|---------|--------|-----------------|
| Total script count | 118 | Stable/↓ | +5/month |
| Max call depth | 2 | ≤ 2 levels | 3+ levels |
| Wrapper scripts | 0 | 0 | Any wrapper |
| Helper scripts | 0 | Minimize | +3/month |
| Orphaned scripts | 0 | 0 | Any orphan |

### Monthly Review

**Review Checklist**:
- [ ] Compare script count vs. baseline
- [ ] Identify new scripts created this month
- [ ] Validate each new script has justification
- [ ] Check for wrapper/helper proliferation
- [ ] Analyze call depth changes
- [ ] Identify consolidation opportunities

---

## Related Principles

### Modular Architecture (Principle I)
- Functions over files
- Clear module boundaries
- Single responsibility per script

### Reusability (Principle V)
- Shared libraries over duplicated scripts
- Component reuse over proliferation
- DRY principle enforcement

### Maintainability
- Fix issues at source
- Minimize code navigation
- Clear ownership

---

## References

- **AGENTS.md**: Core constitutional requirements (lines 180-240)
- **constitutional-compliance-criteria.md**: Validation rules
- **001-orchestrator.md**: Multi-agent coordination patterns
- **User requirement (2025-11-21)**: Original proliferation concern

---

## Frequently Asked Questions

### Q: When is a new script actually justified?

**A**: Only when ALL of these are true:
1. Functionality cannot be added to existing script (architectural constraint)
2. Not a wrapper/helper for existing script
3. Creates genuine new capability
4. Used by multiple independent components
5. Would create unacceptable coupling if inline
6. Documented justification in commit message

### Q: What about test files?

**A**: Test files are **EXEMPT** from proliferation rules:
- Unit tests: `tests/unit/*_test.sh`, `test_*.sh`
- Integration tests: `tests/integration/*.sh`
- Contract tests: `tests/contract/*.sh`
- Test fixtures and helpers in `tests/` directory

**Rationale**: Comprehensive testing requires granular test files.

### Q: What if I need a utility function used by 10+ scripts?

**A**: Add to **core library**:
- `lib/core/logging.sh` - Logging, formatting, version comparison
- `lib/core/validation.sh` - Input validation, checks
- `lib/ui/tui.sh` - TUI components, rendering

**NOT**: Create `lib/utils/my-helper.sh`

### Q: What about archived or deprecated scripts?

**A**: Move to `archive/` directory:
```bash
# Don't delete, archive
mkdir -p archive/scripts/deprecated-YYYYMMDD/
mv scripts/old-script.sh archive/scripts/deprecated-20251121/
git add archive/scripts/deprecated-20251121/
```

### Q: How do I override this principle?

**A**: Explicit user approval required:
1. Document detailed justification
2. Explain why alternatives won't work
3. Include in commit message
4. Request user review
5. User explicitly approves exception

---

## Version History

| Version | Date | Change |
|---------|------|--------|
| 1.0 | 2025-11-21 | Initial constitutional principle established |

---

**Status**: ACTIVE - MANDATORY COMPLIANCE
**Next Review**: 2025-12-21 (monthly review cycle)
**Enforcement**: Automated via 002-compliance

---

**End of Constitutional Principle Document**
