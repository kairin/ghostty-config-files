# ⚠️ DEPRECATED: Legacy Installer Scripts

## Status: Deprecated as of 2025-11-23

These installer scripts have been **replaced by the modular installation system** in `lib/installers/`.

## Why Deprecated?

1. **Modularity Violation**: These monolithic scripts violate the project's modular architecture
2. **Redundancy**: Functionality now exists in `lib/installers/` with better structure
3. **Maintainability**: The new modular system is easier to maintain and test
4. **Constitutional Compliance**: Violates script proliferation prevention principle

## Migration Guide

### Old → New Mapping

| Deprecated Script | New Location | Status |
|------------------|--------------|--------|
| `install_ghostty.sh` | `lib/installers/ghostty/` | ✅ Replaced (9-step modular) |
| `install_ai_tools.sh` | `lib/installers/ai_tools/` | ✅ Replaced |
| `install_node.sh` | `lib/installers/nodejs_fnm/` | ✅ Replaced |
| `install_uv.sh` | `lib/installers/python_uv/` | ✅ Replaced |
| `install_context_menu.sh` | `lib/installers/context_menu/` | ✅ Replaced |
| `install_ghostty_config.sh` | Configuration managed by installers | ⚠️ Review needed |
| `install_modern_tools.sh` | Multiple installers | ⚠️ Review needed |
| `install_spec_kit.sh` | TBD | ⚠️ Review needed |

## Using the New System

Instead of:
```bash
./scripts/install_ghostty.sh
```

Use:
```bash
./lib/installers/ghostty/install.sh
```

Or better yet, use the unified installation entry point:
```bash
./start.sh
```

## Removal Timeline

**Phase 1** (Current): Move to `deprecated/`, add warnings
**Phase 2** (Next release): Remove from repository
**Phase 3** (2 releases): Complete deletion

## For Developers

**DO NOT** modify these scripts. All new development should happen in `lib/installers/`.

If you need to reference old functionality:
1. Check Git history: `git log --follow scripts/deprecated/<script>.sh`
2. Review modular equivalent in `lib/installers/`
3. Update to use new modular system

## Questions?

See:
- `.claude/instructions-for-agents/architecture/system-architecture.md`
- `.claude/instructions-for-agents/principles/script-proliferation.md`
- `lib/installers/README.md`
