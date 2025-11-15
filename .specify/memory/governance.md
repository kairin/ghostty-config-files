# Governance & Amendment Process

Constitutional amendment procedures, versioning policy, and compliance requirements.

## Amendment Process

### Required Steps
1. **Proposal**: Document proposed constitutional change with rationale
2. **Impact Analysis**: Assess impact on existing workflows, templates, and artifacts
3. **Template Sync**: Update plan-template.md, spec-template.md, tasks-template.md
4. **Version Increment**: Semantic versioning (MAJOR.MINOR.PATCH)
5. **Propagation**: Update dependent documentation (README, quickstart, agent files)
6. **Validation**: Run full local CI/CD to verify no breakage
7. **Ratification**: Merge via standard git workflow with constitution amendment commit message

### Amendment Commit Message
```bash
git commit -m "constitution: [AMENDMENT_DESCRIPTION]

Version: X.Y.Z
Type: [MAJOR|MINOR|PATCH]
Impact: [Description of changes]
Rationale: [Why this amendment is necessary]

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Versioning Policy

### Semantic Versioning
- **MAJOR** (X.0.0): Backward incompatible principle removals or redefinitions
- **MINOR** (0.X.0): New principle/section added or materially expanded guidance
- **PATCH** (0.0.X): Clarifications, wording, typo fixes, non-semantic refinements

### Version History
- **1.0.0** (2025-10-27): Initial ratification
- **1.1.0** (2025-11-09): Documentation structure update, screenshot removal
- **1.1.1** (2025-11-09): Spec-kit branch naming compliance fix
- **1.2.0** (2025-11-16): Modular constitution structure

---

## Compliance Review

### Pull Request Requirements
- ✅ All PRs/reviews must verify constitutional compliance before merge
- ✅ Complexity additions must be justified in spec.md "Complexity Tracking" section
- ✅ Use AGENTS.md (project root) for runtime development guidance

### Constitutional Checklist
- ✅ Branch preservation requirements followed
- ✅ Local CI/CD executed before GitHub deployment
- ✅ Zero-cost operations maintained
- ✅ Agent file integrity preserved (symlinks intact)
- ✅ Conversation logs saved
- ✅ Quality gates passed

---

## Supersedence

### Authority Hierarchy
1. **Constitution** (highest authority)
2. **AGENTS.md** (single source of truth)
3. **spec.md files** (feature-specific requirements)
4. **README** (user documentation)

### Conflict Resolution
This constitution supersedes all other practices except explicit project requirements in spec.md files. When conflicts arise, constitutional principles take precedence unless explicitly justified in "Complexity Tracking" section of the spec.

---

## Ratification

**Original Ratification**: 2025-10-27
**Last Amendment**: 2025-11-16
**Authority**: AGENTS.md (single source of truth)
**Status**: ACTIVE - MANDATORY COMPLIANCE

---

**Back to**: [constitution.md](constitution.md)
**Version**: 1.0.0
**Last Updated**: 2025-11-16
