# Constitutional Principle: Modularity Limits & Simplification

**Status**: MANDATORY - CONSTITUTIONAL REQUIREMENT  
**Enforcement**: Automated validation + Monthly audits  
**Last Updated**: 2025-11-25  
**Authority**: User Constitutional Requirement  

---

## Core Principle

> **"Don't create monolithic scripts > 300 lines"**
> **"Identify and simplify complex scripts"**  
> **"Ensure Python scripts are UV-first"**
>
> — User Constitutional Requirements, 2025-11-25

This principle is **NON-NEGOTIABLE** and applies to **ALL** scripts and **ALL** AI assistants working on this repository.

---

## Mandatory Rules

### Rule 1: 300-Line Hard Limit

**All shell scripts MUST be ≤ 300 lines** (excluding test files)

**✅ COMPLIANT**:
```bash
# my_script.sh - 287 lines
# Single responsibility, well-focused functionality
# Easy to understand and maintain
```

**❌ VIOLATION**:
```bash
# my_script.sh - 1,247 lines  
# Multiple responsibilities, hard to maintain
# Needs refactoring IMMEDIATELY
```

**Exceptions**:
- Test files in `tests/` directory (test suites can be longer)
- Deprecated scripts in `scripts/deprecated/` (to be archived)
- Generated scripts (must be marked with `# GENERATED - DO NOT EDIT`)

**Enforcement**:
- Pre-commit hook checks line count
- CI/CD pipeline fails on violations
- Monthly audit identifies new violations

---

### Rule 2: Simplification Strategies

**When a script exceeds 300 lines, you MUST use ONE of these strategies:**

#### Strategy A: Extract Functions to Library Modules

**When**: Related functions can be grouped by domain

**Example**:
```bash
# ❌ BEFORE: monolithic_script.sh (850 lines)
detect_version() { ... }       # 150 lines
compare_versions() { ... }     # 120 lines  
install_package() { ... }      # 200 lines
verify_installation() { ... }  # 180 lines
main() { ... }                 # 200 lines

# ✅ AFTER: Extracted to modules
lib/detection/version.sh:       # 270 lines
  detect_version()
  compare_versions()

lib/installation/package.sh:    # 200 lines  
  install_package()

lib/verification/check.sh:      # 180 lines
  verify_installation()

scripts/orchestrator.sh:        # 120 lines (sources libraries)
  main()
```

**Benefits**:
- Functions reusable across scripts
- Clear ownership per module
- Easy to test in isolation

---

#### Strategy B: Split into Subcommand Modules

**When**: Script handles multiple distinct commands/operations

**Example**:
```bash
# ❌ BEFORE: manage.sh (2,436 lines) 
case "$1" in
  update) ... 400 lines ...  ;;
  backup) ... 350 lines ...  ;;
  restore) ... 380 lines ... ;;
  config) ... 420 lines ...  ;;
  status) ... 380 lines ...  ;;
  cleanup) ... 340 lines ... ;;
esac

# ✅ AFTER: Subcommand modules
lib/manage/update.sh      # 280 lines
lib/manage/backup.sh      # 250 lines  
lib/manage/restore.sh     # 270 lines
lib/manage/config.sh      # 290 lines
lib/manage/status.sh      # 260 lines
lib/manage/cleanup.sh     # 240 lines

scripts/utils/manage.sh:  # 85 lines (router only)
#!/usr/bin/env bash
SUBCOMMAND="$1"
shift
source "${REPO_ROOT}/lib/manage/${SUBCOMMAND}.sh"
run_${SUBCOMMAND} "$@"
```

**Benefits**:
- Each subcommand is independently maintainable
- Easy to add new subcommands
- Clear separation of concerns

---

#### Strategy C: Component-Based Splitting

**When**: Script handles different logical components/domains

**Example**:
```bash
# ❌ BEFORE: system_audit.sh (1,630 lines)
# All in one file:
detect_apt_packages()      # 180 lines
detect_npm_packages()      # 200 lines
detect_source_packages()   # 190 lines
generate_report()          # 440 lines
display_tables()           # 380 lines  
cache_versions()           # 140 lines
main_audit()               # 100 lines

# ✅ AFTER: Component libraries
lib/audit/detectors.sh:    # 290 lines
  detect_apt_packages()
  detect_npm_packages()  
  detect_source_packages()

lib/audit/report.sh:       # 280 lines
  generate_report()

lib/audit/display.sh:      # 290 lines  
  display_tables()

lib/audit/cache.sh:        # 140 lines
  cache_versions()

lib/tasks/system_audit.sh: # 250 lines (orchestration)
  source lib/audit/*.sh
  main_audit()
```

**Benefits**:
- Related functionality grouped together
- Easy to find and modify specific features
- Modules can be independently tested

---

#### Strategy D: Test Suite Splitting

**When**: Test file covers multiple domains/components

**Example**:
```bash
# ❌ BEFORE: unit_tests.sh (1,378 lines)
test_core_utils()       # 280 lines
test_installers()       # 340 lines  
test_ui_components()    # 290 lines
test_verification()     # 270 lines
test_integration()      # 198 lines

# ✅ AFTER: Focused test suites
tests/unit/test_core_utils.sh       # 280 lines
tests/unit/test_installers.sh       # 340 lines  
tests/unit/test_ui_components.sh    # 290 lines
tests/unit/test_verification.sh     # 270 lines
tests/integration/test_workflow.sh  # 198 lines

tests/run_all_tests.sh:             # 45 lines (runner)
```

**Benefits**:
- Tests run independently
- Faster iteration (run subset of tests)
- Clear test organization

---

### Rule 3: Python UV-First Dependency Management

**ALL Python scripts MUST use UV for dependency management**

**✅ COMPLIANT**:
```python
#!/usr/bin/env python3
"""
Python script with UV-first dependencies.

Dependencies:
  Install via: uv pip install requests beautifulsoup4
"""

import subprocess
import sys

def install_dependencies():
    """Install dependencies using UV."""
    subprocess.run([
        "uv", "pip", "install",  
        "requests",
        "beautifulsoup4"
    ], check=True)

if __name__ == "__main__":
    # UV must be in PATH
    if not shutil.which("uv"):
        print("ERROR: UV not found. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh")
        sys.exit(1)
    
    import requests
    # ... rest of script
```

**❌ VIOLATION**:
```python
#!/usr/bin/env python3
import subprocess

# WRONG: Direct pip usage
subprocess.run(["pip", "install", "requests"], check=True)

# WRONG: pip in requirements.txt without uv
# requirements.txt:
# requests==2.31.0  # Should be: uv pip install -r requirements.txt
```

**Requirements File Pattern**:
```bash
# ✅ CORRECT: Install with UV
echo "requests==2.31.0" > requirements.txt
uv pip install -r requirements.txt

# ❌ WRONG: Install with pip
pip install -r requirements.txt
```

**Enforcement**:
- All `.py` files scanned for `subprocess.*pip install` patterns
- Pre-commit hook rejects direct `pip` usage  
- CI/CD validates UV in PATH before running Python scripts

---

### Rule 4: Monthly Script Audit

**REQUIRED: Monthly review of script sizes and complexity**

**Audit Checklist**:
```bash
# 1. Find all scripts > 300 lines
bash -c 'for file in $(find . -name "*.sh" -not -path "*/tests/*" -not -path "*/.git/*"); do
  lines=$(wc -l < "$file" 2>/dev/null)
  if [ "$lines" -gt 300 ]; then  
    echo "$lines $file"
  fi
done | sort -rn'

# 2. Check Python scripts for pip usage
grep -r "pip install" --include="*.py" . | grep -v "# uv pip install"

# 3. Update violations catalog
# Document: /home/kkk/.gemini/antigravity/brain/*/violations-catalog.md

# 4. Prioritize refactoring  
# Order by: CRITICAL (>1000 lines) → HIGH (800-1000) → MEDIUM (600-800) → LOW (500-600)
```

**Timeline**:
- **Day 1-7**: Identify violations, update catalog
- **Day 8-14**: Refactor CRITICAL priority scripts
- **Day 15-21**: Refactor HIGH priority scripts  
- **Day 22-30**: Plan MEDIUM/LOW priority refactoring

---

## Validation Checklist

**Before committing ANY script file:**

### ☑ Line Count Check
- [ ] **Is this script ≤ 300 lines?** (excluding comments/blank lines)
  - If **NO** → Apply simplification strategy, **STOP**
  - If **YES** → Continue

### ☑ Simplification Evaluation  
- [ ] **Does this script have a single responsibility?**
  - If **NO** → Extract functions/subcommands, **STOP**
  - If **YES** → Continue

### ☑ Python UV Check (if `.py` file)
- [ ] **Does this use UV for dependencies?**
  - If **NO** → Convert to UV pattern, **STOP**
  - If **YES** or **N/A** (not Python) → Continue

### ☑ Test Exception
- [ ] **Is this a test file?** (in `tests/`)
  - If **YES** → Exempt from 300-line limit, proceed
  - If **NO** → Apply all rules

---

## Enforcement

### Automated Validation

**Pre-Commit Hook** (`hooks/check-script-limits.sh`):
```bash
#!/usr/bin/env bash
# Check all staged .sh files for line count violations

for file in $(git diff --cached --name-only --diff-filter=ACM | grep '\.sh$'); do
  # Skip test files
  if [[ "$file" == tests/* ]]; then
    continue
  fi
  
  lines=$(wc -l < "$file")
  if [ "$lines" -gt 300 ]; then
    echo "❌ VIOLATION: $file has $lines lines (limit: 300)"
    echo "   Apply simplification strategy before committing"
    exit 1
  fi
done
```

**CI/CD Pipeline Check**:
```yaml
# .github/workflows/constitutional-compliance.yml
- name: Check Script Line Limits  
  run: |
    bash .github/workflows/check-modularity-limits.sh
```

### Manual Review

**Pull Request Requirements**:
- All scripts > 200 lines require justification
- Scripts approaching limit (>250 lines) flagged for future refactoring
- Refactoring plan required for any script > 300 lines

---

## Metrics & Targets

| Metric | Baseline (2025-11-25) | Target (2026-01-01) | Target (2026-06-01) |
|--------|----------------------|---------------------|---------------------|
| Scripts > 300 lines | 20 | 10 | 0 |
| Largest script size | 2,436 lines | 800 lines | 300 lines |
| Avg script size | ~180 lines | ~150 lines | ~120 lines |
| Python UV compliance | Unknown | 80% | 100% |

**Progress Tracking**: `/home/kkk/.gemini/antigravity/brain/*/violations-catalog.md`

---

## Related Principles

- **Script Proliferation Prevention**: Don't create unnecessary scripts → This principle: Keep existing scripts focused
- **Modular Architecture (Principle I)**: Clear module boundaries
- **Single Responsibility Principle**: One script, one purpose
- **DRY (Don't Repeat Yourself)**: Extract to libraries, not duplicate logic

---

## Examples

See [`violations-catalog.md`](file:///home/kkk/.gemini/antigravity/brain/30c8f394-d32c-458f-8cee-4507e65fb4a6/violations-catalog.md) for comprehensive refactoring examples.

---

## FAQ

### Q: What if my script is 305 lines?

**A**: **MUST refactor**. The 300-line limit is **hard**. Extract 1-2 functions to a library module.

### Q: Can I split a 400-line script into two 200-line scripts?

**A**: **Only if** they have distinct responsibilities. Don't arbitrarily split середине logic. Use proper modularization strategies.

### Q: What about Python virtual environments?

**A**: Use `uv venv` instead of `python -m venv`:
```bash
# ✅ CORRECT
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt

# ❌ WRONG
python3 -m venv .venv
pip install -r requirements.txt
```

### Q: How do I convert existing Python scripts to UV?

**A**: 
1. Document current dependencies: `pip freeze > requirements.txt`
2. Remove existing venv: `rm -rf .venv`
3. Create UV venv: `uv venv .venv`
4. Install with UV: `uv pip install -r requirements.txt`
5. Update script documentation with UV install command

---

**Status**: ACTIVE - MANDATORY COMPLIANCE  
**Next Review**: 2025-12-25 (monthly audit cycle)  
**Enforcement**: Automated + Manual review  

---

**End of Constitutional Principle Document**
