# Quality Gates & Validation Criteria

Pre-change checklists and validation requirements for all configuration changes.

## Before Every Configuration Change

### Mandatory Checklist
1. **Local CI/CD Execution**: Run `./.runners-local/workflows/gh-workflow-local.sh all`
2. **Configuration Validation**: Run `ghostty +show-config` to ensure validity
3. **Performance Testing**: Execute `./.runners-local/workflows/performance-monitor.sh`
4. **Backup Creation**: Automatic timestamped backup of existing configuration
5. **User Preservation**: Extract and preserve user customizations
6. **Documentation**: Update relevant docs if adding features
7. **Conversation Log**: Save complete AI conversation log with system state

### Validation Sequence
```bash
# 1. Run local CI/CD FIRST
./.runners-local/workflows/gh-workflow-local.sh all

# 2. Validate configuration
ghostty +show-config

# 3. Test performance
./.runners-local/workflows/performance-monitor.sh --test

# 4. Only then proceed with git workflow
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-description"
git checkout -b "$BRANCH_NAME"
```

---

## Validation Criteria

### Build & Configuration
- ✅ Local CI/CD workflows execute successfully
- ✅ Configuration validates without errors via `ghostty +show-config`
- ✅ All build outputs generated correctly
- ✅ No TypeScript/JavaScript errors

### Performance
- ✅ All 2025 performance optimizations present and functional
- ✅ Startup time <500ms (CGroup optimization)
- ✅ Memory usage <100MB baseline
- ✅ CI/CD performance <2 minutes complete workflow

### User Experience
- ✅ User customizations preserved and functional
- ✅ Context menu integration works correctly
- ✅ No breaking changes to existing workflows

### Cost & Compliance
- ✅ GitHub Actions usage remains within free tier limits
- ✅ Zero GitHub Actions minutes consumed for routine operations
- ✅ All logging systems capture complete information

---

**Back to**: [constitution.md](constitution.md)
**Related**: [local-cicd.md](local-cicd.md)
**Version**: 1.0.0
**Last Updated**: 2025-11-16
