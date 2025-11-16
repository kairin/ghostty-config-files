# Archived Documentation and Specifications

**Created**: 2025-11-16
**Purpose**: Preserve historical documentation from directory reorganization

## Directory Structure

```
specs/archive/
├── pre-consolidation/          # Archived feature specifications (001, 002, 004)
│   ├── 001-repo-structure-refactor/
│   ├── 002-advanced-terminal-productivity/
│   ├── 004-modern-web-development/
│   └── ARCHIVE_INDEX.md
├── development-docs/            # Archived development documentation
│   ├── conversation_logs/      # LLM conversation logging infrastructure
│   ├── analysis/               # Technical analysis and research
│   ├── testing/                # Test results and verification reports
│   └── integration/            # Integration documentation
├── developer-resources/         # Archived developer guides
│   ├── architecture/           # Architecture documentation
│   ├── analysis/               # Code analysis and compliance reports
│   ├── debugging/              # Debugging guides and issue summaries
│   └── guides/                 # Implementation guides
└── user-docs/                   # Archived user documentation
    ├── setup/                  # Setup guides (moved to docs-setup/)
    ├── configuration/          # Configuration guides
    ├── installation/           # Installation guides
    └── troubleshooting/        # Troubleshooting guides
```

## Reorganization Summary

**Date**: 2025-11-16
**Reason**: Consolidate directory structure to align with spec-kit expectations

### What Changed

1. **Specifications moved**: `documentations/specifications/` → `specs/`
2. **Critical docs extracted**: MCP setup guides → `docs-setup/`
3. **Historical content archived**: Development docs → `specs/archive/`
4. **Removed directories**: `/spec-kit/` and `/documentations/` (content preserved here)

### Active Documentation Locations

- **Feature Specs**: `/specs/005-complete-terminal-infrastructure/`
- **Setup Guides**: `/docs-setup/` (Context7 MCP, GitHub MCP, DIRECTORY_STRUCTURE)
- **Spec-Kit Guides**: `/spec-kit/guides/` (methodology documentation)
- **Website Docs**: `/website/src/` (Astro source for GitHub Pages)

### Accessing Archived Content

All archived content is preserved for historical reference:

```bash
# View archived specifications
ls -la specs/archive/pre-consolidation/

# Access development documentation
ls -la specs/archive/development-docs/

# Check developer resources
ls -la specs/archive/developer-resources/
```

## Related Documentation

- [Active Spec 005](../005-complete-terminal-infrastructure/spec.md)
- [CLAUDE.md Documentation Structure](../../CLAUDE.md#-critical-documentation-structure-constitutional-requirement)
- [Documentation Structure Guide](../../.specify/memory/documentation-structure.md)

---

**Note**: This archive preserves all content from the `/documentations/` directory reorganization. Nothing was deleted, only relocated for better organization aligned with spec-kit workflow expectations.
