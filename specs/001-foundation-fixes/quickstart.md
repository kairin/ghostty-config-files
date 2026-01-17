# Quickstart: Wave 0 Foundation Fixes

**Estimated Time**: 30-40 minutes
**Complexity**: Low (documentation only)
**Prerequisites**: Git access to repository

## Quick Implementation Guide

### Task 1: Create LICENSE File (10 min)

```bash
# 1. Navigate to repository root
cd /home/kkk/Apps/ghostty-config-files

# 2. Create LICENSE file with MIT text
cat > LICENSE << 'EOF'
MIT License

Copyright (c) 2026 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF

# 3. Verify creation
cat LICENSE
```

**Verification**: After push, check GitHub repo page shows "MIT" license badge.

---

### Task 2: Fix Broken Link (15 min)

```bash
# 1. Create the missing guide file
touch .claude/instructions-for-agents/guides/local-cicd-guide.md

# 2. Add content (see template below)
```

**Content Template for `local-cicd-guide.md`**:
```markdown
# Local CI/CD Guide

Quick reference for daily local CI/CD operations.

## Common Commands

### Full Workflow
\`\`\`bash
./.runners-local/workflows/gh-workflow-local.sh all
\`\`\`

### Individual Steps
\`\`\`bash
# Validate configuration
./.runners-local/workflows/gh-workflow-local.sh validate

# Check Ghostty config
ghostty +show-config

# Check GitHub Actions billing
./.runners-local/workflows/gh-workflow-local.sh billing
\`\`\`

## Troubleshooting

### Workflow Fails
1. Check error output
2. Fix configuration issues
3. Re-run affected stage

### Configuration Invalid
1. Run \`ghostty +show-config\`
2. Check for syntax errors
3. Validate against schema

## See Also
- [Local CI/CD Operations](../requirements/local-cicd-operations.md) - Full requirements
- [Git Strategy](../requirements/git-strategy.md) - Branch workflow
```

**Verification**:
```bash
# Check link resolves
ls -la .claude/instructions-for-agents/guides/local-cicd-guide.md
```

---

### Task 3: Unify Tier Definitions (15 min)

**Files to Update**:
1. `AGENTS.md` (line ~295)
2. `.claude/instructions-for-agents/architecture/agent-delegation.md`
3. `.claude/instructions-for-agents/architecture/system-architecture.md`

**Canonical Table to Use**:
```markdown
| Tier | Model | Count | Purpose |
|------|-------|-------|---------|
| 0 | Sonnet | 5 | Complete workflows (000-*) |
| 1 | Opus | 1 | Multi-agent orchestration |
| 2 | Sonnet | 5 | Core operations |
| 3 | Sonnet | 4 | Utility operations |
| 4 | Haiku | 50 | Atomic execution |
```

**Process**:
1. Open each file
2. Find tier definition table
3. Replace with canonical table above
4. Save and verify consistency

**Verification**:
```bash
# Check all files have same tier counts
grep -h "Sonnet.*5\|Opus.*1\|Haiku.*50" \
  AGENTS.md \
  .claude/instructions-for-agents/architecture/*.md
```

---

## Final Verification Checklist

- [ ] LICENSE file exists at repository root
- [ ] LICENSE contains "MIT License" text
- [ ] GitHub detects license correctly
- [ ] `local-cicd-guide.md` exists in guides/
- [ ] Link in `local-cicd-operations.md` resolves
- [ ] All 4 architecture files show 5-tier structure
- [ ] Tier counts match: 5, 1, 5, 4, 50

## Commit Message Template

```
docs(foundation): add LICENSE and fix documentation consistency

- Create MIT LICENSE file for legal clarity
- Add local-cicd-guide.md to fix broken link
- Unify tier definitions to 5-tier structure across 4 files

Closes: Wave 0 foundation fixes
Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```
