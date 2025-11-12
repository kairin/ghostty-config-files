# Checklist: Constitutional Compliance (Git Operations & Agent Files)

**Purpose**: Validate requirements quality for constitutional git workflow compliance, agent file symlink preservation, and branch naming strategy per CLAUDE.md

**Created**: 2025-10-27
**Feature**: Repository Structure Refactoring (001-repo-structure-refactor)
**Focus Areas**: Agent symlink integrity, branch naming automation, full constitutional git workflow
**Depth Level**: Comprehensive (format requirements + validation + examples + automation)
**Audience**: All contributors and AI assistants

---

## Requirement Completeness - Agent File Symlinks

- [ ] CHK001 - Are symlink requirements explicitly specified for ALL agent integration files (CLAUDE.md, GEMINI.md, and any future agent files)? [Completeness, Gap]
- [ ] CHK002 - Is the symlink target path documented as absolute `/home/kkk/Apps/ghostty-config-files/AGENTS.md`? [Clarity, CLAUDE.md:143-145]
- [ ] CHK003 - Are requirements defined for what happens if symlink is broken or converted to regular file? [Gap, Exception Flow]
- [ ] CHK004 - Is the single-source-of-truth principle for AGENTS.md explicitly stated in requirements? [Clarity, CLAUDE.md:143]
- [ ] CHK005 - Are symlink validation requirements included in pre-commit or pre-push checks? [Gap, Enforcement]
- [ ] CHK006 - Are requirements specified for symlink creation during repository initialization/cloning? [Completeness, Gap]
- [ ] CHK007 - Is symlink preservation explicitly required during documentation restructuring (docs-source/ migration)? [Critical, Spec §FR-011]

## Requirement Completeness - Branch Naming Strategy

- [ ] CHK008 - Is the branch naming format `YYYYMMDD-HHMMSS-type-short-description` explicitly mandated in requirements? [Completeness, CLAUDE.md:35]
- [ ] CHK009 - Are all valid branch type prefixes documented (feat, fix, docs, refactor, test, chore, etc.)? [Completeness, CLAUDE.md:37-40]
- [ ] CHK010 - Are requirements specified for automated branch name generation using `date` command? [Completeness, CLAUDE.md:45-46]
- [ ] CHK011 - Are validation requirements defined for branch name format before allowing pushes? [Gap, Enforcement]
- [ ] CHK012 - Is the branch naming format required for ALL branches or only feature branches? [Ambiguity, CLAUDE.md:35]
- [ ] CHK013 - Are requirements specified for branch name validation tools/scripts? [Gap, Automation]
- [ ] CHK014 - Are branch naming examples provided covering all common scenarios (features, fixes, docs, refactors)? [Completeness, CLAUDE.md:37-40]

## Requirement Completeness - Commit Message Format

- [ ] CHK015 - Are commit message structure requirements documented (descriptive message + attribution footer)? [Completeness, CLAUDE.md:49-52]
- [ ] CHK016 - Is the required attribution footer format specified: "🤖 Generated with [Claude Code](https://claude.ai/code)\nCo-Authored-By: Claude <noreply@anthropic.com>"? [Clarity, CLAUDE.md:51-52]
- [ ] CHK017 - Are requirements defined for heredoc usage to prevent formatting issues in commit messages? [Gap, CLAUDE.md example]
- [ ] CHK018 - Is commit message quality validation required (no empty messages, minimum length, etc.)? [Gap, Quality]
- [ ] CHK019 - Are requirements specified for commit message validation in pre-commit hooks? [Gap, Enforcement]
- [ ] CHK020 - Are multi-line commit message formatting requirements documented? [Clarity, CLAUDE.md:49-52]

## Requirement Completeness - Git Workflow Sequence

- [ ] CHK021 - Is the complete git workflow sequence explicitly required in step-by-step order? [Completeness, CLAUDE.md:43-57]
- [ ] CHK022 - Are requirements specified for local CI/CD validation BEFORE any git operations? [Critical, CLAUDE.md:82-99]
- [ ] CHK023 - Is the requirement to push feature branch to origin documented? [Completeness, CLAUDE.md:53]
- [ ] CHK024 - Is the requirement to merge feature branch to main with `--no-ff` flag specified? [Critical, CLAUDE.md:55]
- [ ] CHK025 - Is the requirement to push main branch after merge documented? [Completeness, CLAUDE.md:56]
- [ ] CHK026 - Is branch preservation (NEVER delete) explicitly mandated without exceptions? [Critical, CLAUDE.md:29-32]
- [ ] CHK027 - Are requirements defined for handling merge conflicts during main merge? [Gap, Exception Flow]
- [ ] CHK028 - Is the prohibition against `git branch -d` explicitly stated in requirements? [Critical, CLAUDE.md:31,57]

## Requirement Completeness - Pre-Deployment Validation

- [ ] CHK029 - Are pre-deployment local CI/CD requirements mandated for EVERY configuration change? [Critical, CLAUDE.md:82]
- [ ] CHK030 - Is the required validation sequence documented: local workflow → status check → config test → commit? [Completeness, CLAUDE.md:85-99]
- [ ] CHK031 - Are specific validation commands required: `./.runners-local/workflows/gh-workflow-local.sh local`? [Clarity, CLAUDE.md:86]
- [ ] CHK032 - Are requirements specified for verifying local build success before proceeding? [Completeness, CLAUDE.md:88-89]
- [ ] CHK033 - Is configuration validation required: `ghostty +show-config && ./scripts/check_updates.sh`? [Clarity, CLAUDE.md:92]
- [ ] CHK034 - Are requirements defined for what constitutes a "passing" local validation? [Ambiguity, Gap]
- [ ] CHK035 - Is zero GitHub Actions consumption explicitly required and validated? [Critical, CLAUDE.md:55,107-117]

## Requirement Clarity - Branch Naming Automation

- [ ] CHK036 - Is the `DATETIME=$(date +"%Y%m%d-%H%M%S")` command format explicitly specified? [Clarity, CLAUDE.md:45,95]
- [ ] CHK037 - Are timezone requirements for datetime stamps documented (e.g., UTC vs local time)? [Ambiguity, Gap]
- [ ] CHK038 - Is the variable expansion format `${DATETIME}-type-description` clearly documented? [Clarity, CLAUDE.md:46]
- [ ] CHK039 - Are requirements specified for branch name length limits (filesystem constraints)? [Gap, Constraint]
- [ ] CHK040 - Are character restrictions for branch descriptions documented (no spaces, special chars, etc.)? [Gap, Validation]
- [ ] CHK041 - Is the recommended description format specified (kebab-case, max length, etc.)? [Ambiguity, Gap]

## Requirement Clarity - Symlink Validation

- [ ] CHK042 - Can "symlink to AGENTS.md" be objectively verified with a specific command? [Measurability, Gap]
- [ ] CHK043 - Is the verification command documented: `ls -la | grep "CLAUDE.md -> AGENTS.md"`? [Clarity, Gap]
- [ ] CHK044 - Are requirements specified for handling relative vs absolute symlink paths? [Ambiguity, Gap]
- [ ] CHK045 - Is symlink creation command documented: `ln -s AGENTS.md CLAUDE.md`? [Clarity, Gap]
- [ ] CHK046 - Are requirements defined for fixing broken symlinks automatically vs manual intervention? [Gap, Recovery Flow]

## Requirement Consistency - Git Workflow Requirements

- [ ] CHK047 - Are branch naming requirements consistent across all documentation (CLAUDE.md, spec.md, tasks.md)? [Consistency]
- [ ] CHK048 - Do commit workflow examples in CLAUDE.md match the requirements stated? [Consistency, CLAUDE.md:43-57]
- [ ] CHK049 - Are local CI/CD requirements consistent between pre-deployment section and git workflow section? [Consistency, CLAUDE.md:79-99]
- [ ] CHK050 - Do symlink requirements in directory structure match the stated mandatory requirements? [Consistency, CLAUDE.md:143-145]
- [ ] CHK051 - Are branch preservation requirements consistent across all git operation contexts? [Consistency, CLAUDE.md:29-32]

## Requirement Consistency - Agent File Management

- [ ] CHK052 - Are symlink requirements consistent for CLAUDE.md and GEMINI.md? [Consistency, CLAUDE.md:144-145]
- [ ] CHK053 - Is AGENTS.md consistently referenced as the single source of truth in all locations? [Consistency, CLAUDE.md:143]
- [ ] CHK054 - Are documentation migration requirements consistent with symlink preservation requirements? [Consistency, Spec §FR-011 vs CLAUDE.md:144]
- [ ] CHK055 - Do docs-source/ migration requirements preserve agent file symlinks? [Consistency, Gap]

## Acceptance Criteria Quality - Verification & Enforcement

- [ ] CHK056 - Can branch name format compliance be automatically validated before push? [Measurability, Gap]
- [ ] CHK057 - Can symlink integrity be automatically checked in CI/CD pipeline? [Measurability, Gap]
- [ ] CHK058 - Can commit message format be programmatically validated? [Measurability, Gap]
- [ ] CHK059 - Are success criteria defined for pre-deployment validation (all checks pass = proceed)? [Measurability, CLAUDE.md:88-92]
- [ ] CHK060 - Are failure criteria defined for each validation step with specific exit codes? [Gap, Error Handling]
- [ ] CHK061 - Can workflow sequence compliance be traced through git history? [Measurability, Traceability]

## Scenario Coverage - Primary Flow

- [ ] CHK062 - Are requirements complete for the happy path: create branch → validate → commit → push → merge → push main? [Coverage, CLAUDE.md:43-57]
- [ ] CHK063 - Are requirements specified for first-time repository setup (symlink creation)? [Coverage, Gap]
- [ ] CHK064 - Are requirements defined for daily development workflow with multiple commits? [Coverage, Gap]
- [ ] CHK065 - Are requirements specified for documentation-only changes (docs builds)? [Coverage, Gap]

## Scenario Coverage - Alternate Flows

- [ ] CHK066 - Are requirements defined for hotfix branches (same naming schema or different)? [Coverage, Gap]
- [ ] CHK067 - Are requirements specified for release branches? [Coverage, Gap]
- [ ] CHK068 - Are requirements defined for emergency rollback scenarios? [Coverage, Gap]
- [ ] CHK069 - Are requirements specified for collaborative development (multiple developers on same feature)? [Coverage, Gap]

## Scenario Coverage - Exception/Error Flows

- [ ] CHK070 - Are requirements defined for handling symlink accidentally converted to regular file? [Critical, Exception Flow]
- [ ] CHK071 - Are requirements specified for branch name format violations (validation failure response)? [Coverage, Exception Flow]
- [ ] CHK072 - Are requirements defined for local CI/CD validation failures (block commit or warn)? [Coverage, CLAUDE.md:82]
- [ ] CHK073 - Are requirements specified for merge conflicts during `--no-ff` merge? [Coverage, Gap]
- [ ] CHK074 - Are requirements defined for push failures (network, permissions, conflicts)? [Coverage, Gap]
- [ ] CHK075 - Are requirements specified for accidental branch deletion (recovery procedure)? [Coverage, Recovery Flow]

## Scenario Coverage - Recovery Flows

- [ ] CHK076 - Are requirements defined for recreating broken symlinks? [Recovery, Gap]
- [ ] CHK077 - Are requirements specified for recovering from incorrect branch name (rename or recreate)? [Recovery, Gap]
- [ ] CHK078 - Are requirements defined for reverting commits that bypass local CI/CD? [Recovery, Gap]
- [ ] CHK079 - Are requirements specified for restoring accidentally deleted branches? [Recovery, CLAUDE.md:29]
- [ ] CHK080 - Are requirements defined for fixing desynchronized main branch? [Recovery, Gap]

## Edge Case Coverage - Symlink Integrity

- [ ] CHK081 - Are requirements specified for symlinks across filesystems or mount points? [Edge Case, Gap]
- [ ] CHK082 - Are requirements defined for symlink behavior in Windows environments (if applicable)? [Edge Case, Gap]
- [ ] CHK083 - Are requirements specified for handling AGENTS.md relocation (symlink target change)? [Edge Case, Gap]
- [ ] CHK084 - Are requirements defined for circular symlink prevention? [Edge Case, Gap]
- [ ] CHK085 - Are requirements specified for symlink vs hardlink distinction? [Clarity, Gap]

## Edge Case Coverage - Branch Naming Edge Cases

- [ ] CHK086 - Are requirements defined for branch names with special characters in description? [Edge Case, Gap]
- [ ] CHK087 - Are requirements specified for handling daylight saving time changes in datetime stamps? [Edge Case, Gap]
- [ ] CHK088 - Are requirements defined for branch name conflicts (same datetime from multiple developers)? [Edge Case, Gap]
- [ ] CHK089 - Are requirements specified for maximum branch name length limits? [Edge Case, Gap]
- [ ] CHK090 - Are requirements defined for branch names across different git hosting platforms? [Edge Case, Gap]

## Edge Case Coverage - Git Workflow Edge Cases

- [ ] CHK091 - Are requirements defined for commits when local CI/CD tools are unavailable? [Edge Case, Gap]
- [ ] CHK092 - Are requirements specified for offline development (no GitHub access)? [Edge Case, Gap]
- [ ] CHK093 - Are requirements defined for rebasing vs merging (prohibited or allowed)? [Edge Case, Ambiguity]
- [ ] CHK094 - Are requirements specified for force-pushing (prohibited or allowed with conditions)? [Edge Case, CLAUDE.md mentions]
- [ ] CHK095 - Are requirements defined for working tree cleanliness before operations? [Edge Case, Gap]

## Non-Functional Requirements - Automation Quality

- [ ] CHK096 - Are performance requirements specified for validation scripts (e.g., <5s execution)? [Non-Functional, Gap]
- [ ] CHK097 - Are usability requirements defined for error messages from validation failures? [Non-Functional, Gap]
- [ ] CHK098 - Are reliability requirements specified for validation tools (zero false positives)? [Non-Functional, Gap]
- [ ] CHK099 - Are maintainability requirements defined for validation scripts (documented, testable)? [Non-Functional, Gap]
- [ ] CHK100 - Are portability requirements specified for validation tools (bash version, OS compatibility)? [Non-Functional, Gap]

## Non-Functional Requirements - Security & Safety

- [ ] CHK101 - Are security requirements specified for handling git credentials in automation? [Non-Functional, Gap]
- [ ] CHK102 - Are safety requirements defined for preventing accidental force-push to main? [Non-Functional, CLAUDE.md mentions]
- [ ] CHK103 - Are requirements specified for protecting main branch from direct commits? [Non-Functional, Gap]
- [ ] CHK104 - Are audit requirements defined for tracking git workflow compliance? [Non-Functional, Gap]
- [ ] CHK105 - Are requirements specified for git hook security (preventing malicious hooks)? [Non-Functional, Gap]

## Non-Functional Requirements - Logging & Observability

- [ ] CHK106 - Are requirements defined for logging all git operations for audit trail? [Non-Functional, CLAUDE.md:119-135]
- [ ] CHK107 - Are requirements specified for structured logging format (JSON) for git operations? [Clarity, CLAUDE.md:124]
- [ ] CHK108 - Are requirements defined for log retention and rotation for git operation logs? [Non-Functional, Gap]
- [ ] CHK109 - Are requirements specified for alerting on constitutional compliance violations? [Non-Functional, Gap]
- [ ] CHK110 - Are requirements defined for git operation metrics tracking (frequency, success rate)? [Non-Functional, Gap]

## Dependencies & Assumptions - External Dependencies

- [ ] CHK111 - Are git version requirements documented (minimum git version for --no-ff, etc.)? [Dependency, Gap]
- [ ] CHK112 - Are requirements specified for date command compatibility (GNU date vs BSD date)? [Dependency, Gap]
- [ ] CHK113 - Are requirements defined for shell environment assumptions (bash 5.x+)? [Dependency, Plan:14]
- [ ] CHK114 - Are requirements specified for GitHub CLI (`gh`) availability for workflow checks? [Dependency, CLAUDE.md:108-114]
- [ ] CHK115 - Are requirements defined for .runners-local tooling prerequisites? [Dependency, CLAUDE.md:101-106]

## Dependencies & Assumptions - Internal Dependencies

- [ ] CHK116 - Are requirements specified for AGENTS.md always existing before symlink creation? [Dependency, CLAUDE.md:143]
- [ ] CHK117 - Are requirements defined for .runners-local/workflows/ existence before validation? [Dependency, CLAUDE.md:86]
- [ ] CHK118 - Are requirements specified for directory structure assumptions (repo root detection)? [Assumption, Gap]
- [ ] CHK119 - Are requirements defined for main branch always being the integration target? [Assumption, CLAUDE.md:55]
- [ ] CHK120 - Are requirements specified for single developer vs team workflow assumptions? [Assumption, Gap]

## Ambiguities & Conflicts - Resolution Needed

- [ ] CHK121 - Is "NEVER DELETE BRANCHES without explicit user permission" unambiguous about who grants permission? [Ambiguity, CLAUDE.md:29]
- [ ] CHK122 - Is the relationship between FR-011 (split AGENTS.md) and symlink requirement clear? [Conflict, Spec §FR-011 vs CLAUDE.md:143]
- [ ] CHK123 - Are requirements clear about whether docs-source/ai-guidelines/ replaces or supplements AGENTS.md? [Ambiguity, Spec §FR-011]
- [ ] CHK124 - Is the requirement "ALL BRANCHES contain valuable configuration history" quantified? [Ambiguity, CLAUDE.md:30]
- [ ] CHK125 - Are requirements clear about branch naming for non-feature work (chores, maintenance)? [Ambiguity, Gap]

## Ambiguities & Conflicts - Implementation Conflicts

- [ ] CHK126 - Does the symlink requirement conflict with "split AGENTS.md into modular files"? [Critical Conflict, Spec §FR-011 vs CLAUDE.md:144]
- [ ] CHK127 - Are requirements clear whether symlinks point to original AGENTS.md or new docs-source/ai-guidelines/? [Critical Ambiguity]
- [ ] CHK128 - Is the migration path documented for maintaining symlinks during docs restructure? [Gap, Migration Flow]
- [ ] CHK129 - Are requirements specified for handling symlinks in docs-dist/ (build output)? [Ambiguity, Gap]
- [ ] CHK130 - Is the final state clear: AGENTS.md remains + symlinks remain + docs-source/ has copies/links? [Critical Ambiguity]

## Traceability & Documentation - Requirements Traceability

- [ ] CHK131 - Are all git workflow requirements traceable to CLAUDE.md constitutional sections? [Traceability]
- [ ] CHK132 - Are symlink requirements traceable to CLAUDE.md directory structure section? [Traceability, CLAUDE.md:143-145]
- [ ] CHK133 - Are branch naming requirements referenced in task definitions? [Traceability, tasks.md]
- [ ] CHK134 - Are validation requirements linked to local CI/CD constitutional mandates? [Traceability, CLAUDE.md:79-117]
- [ ] CHK135 - Is there a requirement & acceptance criteria ID scheme for constitutional compliance? [Traceability, Gap]

## Traceability & Documentation - Implementation Guidance

- [ ] CHK136 - Are requirements documented with concrete shell script examples for all git operations? [Documentation, CLAUDE.md:43-57]
- [ ] CHK137 - Are symlink creation commands provided with exact syntax? [Documentation, Gap]
- [ ] CHK138 - Are validation commands documented with expected output for success/failure? [Documentation, Gap]
- [ ] CHK139 - Are troubleshooting requirements specified for common git workflow errors? [Documentation, Gap]
- [ ] CHK140 - Is a complete git workflow checklist provided alongside requirements? [Documentation, This File]

---

## Summary Metrics

**Total Checklist Items**: 140

**Category Breakdown**:
- Requirement Completeness: 35 items (25%)
- Requirement Clarity: 11 items (8%)
- Requirement Consistency: 8 items (6%)
- Acceptance Criteria Quality: 6 items (4%)
- Scenario Coverage: 19 items (14%)
- Edge Case Coverage: 15 items (11%)
- Non-Functional Requirements: 15 items (11%)
- Dependencies & Assumptions: 10 items (7%)
- Ambiguities & Conflicts: 10 items (7%)
- Traceability & Documentation: 10 items (7%)

**Critical Items**: 11 items marked [Critical]
**Gap Items**: 81 items marked [Gap] (58% - significant missing requirements)
**Ambiguity Items**: 12 items marked [Ambiguity]
**Conflict Items**: 2 items marked [Critical Conflict]

**Risk Assessment**: HIGH - Multiple critical conflicts and gaps identified:
1. **CRITICAL CONFLICT**: Spec §FR-011 requires splitting AGENTS.md into docs-source/ but constitutional requirement mandates CLAUDE.md/GEMINI.md remain symlinks to AGENTS.md
2. **CRITICAL FINDING**: CLAUDE.md is currently a REGULAR FILE (26k), not a symlink to AGENTS.md (as verified by `ls -la`)
3. **CRITICAL GAP**: No validation automation specified for symlink integrity or branch naming compliance

---

## Recommended Next Actions

### Immediate (Critical Priority)

1. **Resolve CLAUDE.md Symlink Issue**:
   ```bash
   # CRITICAL: CLAUDE.md is currently a regular file, not a symlink
   cd /home/kkk/Apps/ghostty-config-files
   mv CLAUDE.md CLAUDE.md.backup  # Preserve current content
   ln -s AGENTS.md CLAUDE.md       # Create proper symlink
   git add CLAUDE.md
   git commit -m "fix: Convert CLAUDE.md to symlink to AGENTS.md per constitutional requirement"
   ```

2. **Resolve Spec Conflict (CHK126-CHK130)**:
   - Clarify whether AGENTS.md will be split OR symlinks preserved (cannot be both)
   - Update Spec §FR-011 to explicitly state: "Split AGENTS.md content into docs-source/ for Astro site, BUT AGENTS.md file itself remains as single source, with CLAUDE.md/GEMINI.md as symlinks"

3. **Create Validation Automation**:
   - Implement pre-commit hook validating symlinks (CHK042-CHK046)
   - Implement pre-push validation for branch naming (CHK056, CHK071)
   - Add to local CI/CD workflow (CHK029-CHK035)

### High Priority (Complete Before Implementation)

4. **Document Branch Naming Examples** (CHK014, CHK041):
   - Add examples covering all scenarios: features, fixes, docs, refactors, chores
   - Specify description format rules (kebab-case, max 50 chars, no special chars)

5. **Define Recovery Procedures** (CHK076-CHK080):
   - Document how to recreate broken symlinks
   - Document how to recover accidentally deleted branches
   - Document how to fix incorrect branch names

6. **Clarify Exception Handling** (CHK070-CHK075):
   - Define what happens when local CI/CD fails (block commit or warn?)
   - Define response to symlink converted to regular file (auto-fix or alert?)
   - Define handling of merge conflicts during --no-ff merge

### Medium Priority (Enhance Quality)

7. **Add Measurable Acceptance Criteria** (CHK056-CHK061):
   - Define specific exit codes for each validation failure
   - Define automated test criteria for symlink integrity
   - Define automated test criteria for branch name compliance

8. **Document Edge Cases** (CHK081-CHK095):
   - Handle symlinks across filesystems
   - Handle datetime conflicts from multiple developers
   - Clarify rebasing policy (prohibited or allowed?)

9. **Add Non-Functional Requirements** (CHK096-CHK110):
   - Performance targets for validation scripts (<5s)
   - Usability requirements for error messages
   - Logging and audit trail requirements

---

## Validation Against Original Request

**User Requirements Met**:
- ✅ "Make it clear and critical that CLAUDE.md remain as symlinks" → CHK001-CHK007, CHK042-CHK046, CHK070, CHK126-CHK130
- ✅ "Branch and feature naming strategy" → CHK008-CHK014, CHK036-CHK041, CHK086-CHK090
- ✅ "Use the same naming schema of date-time naming structure currently available" → CHK008, CHK036-CHK038
- ✅ "When commit and pushing to remote repo" → CHK015-CHK028, CHK062-CHK065

**Scope Coverage**:
- ✅ Q1: B - CLAUDE.md + GEMINI.md + any other agent symlinks → CHK001-CHK007, CHK052-CHK055
- ✅ Q2: C - Format requirements + validation + examples + automation → CHK008-CHK014, CHK036-CHK041, CHK056-CHK058, CHK096-CHK100
- ✅ Q3: C - Full constitutional compliance for git operations → CHK015-CHK035, CHK047-CHK051, CHK062-CHK095, CHK101-CHK140

**Critical Findings for User**:
1. **🚨 CLAUDE.md is NOT a symlink** - Currently a 26k regular file (see ls -la output above)
2. **⚠️ Spec conflict** - FR-011 says split AGENTS.md but constitution says keep it + symlinks
3. **⚠️ No validation automation** - Branch naming and symlink integrity not validated in hooks/CI

This checklist provides comprehensive "unit tests for requirements" validating that all constitutional git operation and agent symlink requirements are properly specified, clear, consistent, and enforceable.
