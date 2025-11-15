# LLM Logging Quick Guide for AI Assistants

This guide is for Claude, Gemini, and other AI assistants working on the ghostty-config-files repository.

## Constitutional Requirement

**CLAUDE.md Section: LLM Conversation Logging (MANDATORY)**

> "All AI assistants working on this repository MUST save complete conversation logs and maintain debugging information."

**Status**: NON-NEGOTIABLE - This is not optional.

---

## Quick Start: 5-Minute Logging Setup

### 1. Before You Start Working

When you begin a task, note:
- Current date: `YYYYMMDD` format
- Current git branch
- System state (if relevant)

### 2. Work Normally

- Perform your task as requested
- Make commits following the branch strategy
- Run local CI/CD: `./.runners-local/workflows/gh-workflow-local.sh all`

### 3. After Completing Work

Save the conversation log:

```bash
# Navigate to repo
cd /home/kkk/Apps/ghostty-config-files

# Create log file with today's date and task description
# Format: CONVERSATION_LOG_YYYYMMDD_description.md
DATETIME=$(date +%Y%m%d)
DESCRIPTION="your-task-description"  # lowercase with hyphens

# Save conversation log
cat > documentations/development/conversation_logs/CONVERSATION_LOG_${DATETIME}_${DESCRIPTION}.md << 'EOF'
# Conversation Log: [Your Task Description]

**Date**: ${DATETIME}
**Assistant**: Claude/Gemini/Other
**Status**: Completed

## Executive Summary

[Brief description of what was done]

## Changes Made

[List of files modified, created, or deleted]

## Testing & Validation

- Local CI/CD: ✅ PASSED
- Configuration: ✅ VALID
- Git workflow: ✅ COMPLETED

## Quality Gates

- [x] Local CI/CD successful
- [x] No sensitive data exposed
- [x] Branch preserved (not deleted)
- [x] Conversation log saved

## References

- CLAUDE.md: LLM Conversation Logging (MANDATORY)
EOF

# Commit the log
git add documentations/development/conversation_logs/
git commit -m "Add conversation log for ${DESCRIPTION}"
```

---

## Minimal Logging Template

If time is limited, use this minimal structure:

```markdown
# Conversation Log: [Your Task]

**Date**: [YYYYMMDD]
**Status**: Completed

## What Was Done
- [Change 1]
- [Change 2]
- [Change 3]

## Files Modified
- `path/to/file.md` - Description
- `path/to/script.sh` - Description

## Quality Gates
- [x] Local CI/CD passed
- [x] Config validated
- [x] No sensitive data
- [x] Branch preserved

## References
- CLAUDE.md: LLM Conversation Logging
```

---

## What to Include (MUST HAVE)

**Minimum requirements:**

1. **Header**
   - Date (YYYYMMDD)
   - What the task was about
   - Completion status

2. **Summary**
   - 3-5 bullet points of what was accomplished

3. **Changes**
   - List of files modified/created/deleted
   - Commit messages made

4. **Validation**
   - Local CI/CD execution results
   - Configuration validation
   - Tests run and results

5. **Quality Checklist**
   - Ran local CI/CD: `./.runners-local/workflows/gh-workflow-local.sh all`
   - No API keys or passwords in log
   - Branch naming followed convention
   - Branch NOT deleted (preserved)

---

## What to EXCLUDE (CRITICAL)

**NEVER include:**

- ❌ API keys or tokens (ctx7sk-, ghp_, etc.)
- ❌ Passwords or passphrases
- ❌ Personal information (names, emails)
- ❌ SSH keys or private keys
- ❌ OAuth tokens or bearer tokens
- ❌ AWS/Azure/GCP credentials
- ❌ Database credentials
- ❌ Private email addresses

**If you must reference a credential:**
```markdown
# ❌ WRONG
Context7 API Key used: ctx7sk-abc123def456

# ✅ CORRECT
Context7 API Key: [REDACTED]
```

---

## File Naming Convention

**Required format**: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`

**Examples:**
- `CONVERSATION_LOG_20251116_local-cicd-setup.md` ✅
- `CONVERSATION_LOG_20251115_ghostty-optimization.md` ✅
- `CONVERSATION_LOG_20251114_github-mcp-integration.md` ✅
- `ConversationLog_20251116_LocalCICD.md` ❌ (wrong format)
- `log_20251116.md` ❌ (missing description)
- `CONVERSATION_LOG_1116_task.md` ❌ (missing year and month)

---

## Naming Your Task

Use lowercase, hyphens instead of spaces:

- ✅ `local-cicd-setup`
- ✅ `ghostty-performance-optimization`
- ✅ `github-mcp-integration`
- ✅ `conversation-logs-infrastructure`
- ❌ `Local CI/CD Setup`
- ❌ `local_cicd_setup`
- ❌ `LocalCICDSetup`

---

## Essential Sections (Copy & Paste)

### Executive Summary Template
```markdown
## Executive Summary

- ✅ Created X feature/fixed Y bug
- ✅ Modified [number] files
- ✅ Local CI/CD passed all 7 stages
- ✅ Configuration validated
- ✅ All tests passing
```

### Files Modified Template
```markdown
## Files Modified

### Created
- `documentations/development/conversation_logs/README.md` - Infrastructure documentation

### Modified
- `README.md` - Updated installation instructions (lines 10-15)
- `.gitignore` - Added new exclusion patterns

### Deleted
- `old-file.backup` - Obsolete configuration file
```

### Quality Gates Template
```markdown
## Quality Gates Verification

- [x] Local CI/CD execution successful (7/7 stages passed)
- [x] Configuration validation passed
- [x] No sensitive data exposed
- [x] Branch named correctly: YYYYMMDD-HHMMSS-type-description
- [x] Branch preserved (NOT deleted)
- [x] Conversation log created and committed
```

### Testing Template
```markdown
## Testing & Validation

**Local CI/CD**: `./.runners-local/workflows/gh-workflow-local.sh all`
- Stage 1: Config validation ✅
- Stage 2: Performance testing ✅
- Stage 3: Compatibility checks ✅
- Stage 4: Workflow simulation ✅
- Stage 5: Documentation generation ✅
- Stage 6: Release packaging ✅
- Stage 7: GitHub Pages deployment ✅

**Configuration Validation**: `ghostty +show-config` ✅

**Result**: All tests passed, zero GitHub Actions cost
```

---

## Common Pitfalls to Avoid

### ❌ DON'T

```markdown
# Wrong 1: Missing date format
CONVERSATION_LOG_Nov16_task.md

# Wrong 2: Using uppercase in description
CONVERSATION_LOG_20251116_Local-CICD-Setup.md

# Wrong 3: Including API keys
Context7 API: ctx7sk-1234567890abcdef

# Wrong 4: Incomplete quality gates
- CI/CD: Looks good
- Config: Seems valid

# Wrong 5: Not committing the log
(Log file created but not git add/commit)

# Wrong 6: Deleting the branch
git branch -d "20251116-104500-feat-example"  # ❌ CONSTITUTIONAL VIOLATION
```

### ✅ DO

```markdown
# Correct 1: ISO 8601 date, lowercase description
CONVERSATION_LOG_20251116_local-cicd-setup.md

# Correct 2: Proper quality gate detail
- Local CI/CD: ✅ PASSED (7/7 stages, 12.0s total)
- Configuration: ✅ VALID (ghostty +show-config)

# Correct 3: Redacted credentials
Context7 API: [REDACTED]

# Correct 4: Preserved branch
git checkout main
git merge "20251116-104500-feat-example" --no-ff
git push origin main
# Branch "20251116-104500-feat-example" remains on remote
```

---

## Step-by-Step Git Workflow for Logging

```bash
# 1. After completing your work, capture date
DATETIME=$(date +"%Y%m%d-%H%M%S")
DATE=$(date +"%Y%m%d")
DESCRIPTION="your-task-description"

# 2. Create branch if not already done
git checkout -b "${DATETIME}-feat-${DESCRIPTION}"

# 3. Make your changes and commit
git add .
git commit -m "feat: Your commit message

🤖 Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>"

# 4. Run local CI/CD BEFORE committing logs
./.runners-local/workflows/gh-workflow-local.sh all

# 5. Create conversation log from template
CONV_LOG_DIR="documentations/development/conversation_logs"
cp "${CONV_LOG_DIR}/CONVERSATION_LOG_TEMPLATE.md" \
   "${CONV_LOG_DIR}/CONVERSATION_LOG_${DATE}_${DESCRIPTION}.md"

# 6. Edit the log file with your information
# (Use your editor of choice)

# 7. Commit the conversation log
git add "${CONV_LOG_DIR}/CONVERSATION_LOG_${DATE}_${DESCRIPTION}.md"
git commit -m "Add conversation log for ${DESCRIPTION}"

# 8. Push to remote
git push -u origin "${DATETIME}-feat-${DESCRIPTION}"

# 9. Merge to main (no-ff preserves branch)
git checkout main
git pull origin main
git merge "${DATETIME}-feat-${DESCRIPTION}" --no-ff
git push origin main

# 10. PRESERVE BRANCH (never delete)
# ❌ git branch -d "${DATETIME}-feat-${DESCRIPTION}"
# ✅ Branch remains for history
```

---

## Verification Checklist

Before committing your conversation log, verify:

- [ ] File named: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- [ ] Date format: ISO 8601 (20251116, not Nov16 or 2025-11-16)
- [ ] Description: lowercase with hyphens
- [ ] Executed: `./.runners-local/workflows/gh-workflow-local.sh all`
- [ ] All 7 CI/CD stages: PASSED ✅
- [ ] Config validation: `ghostty +show-config` - VALID ✅
- [ ] No API keys in log
- [ ] No passwords in log
- [ ] No personal information
- [ ] No email addresses
- [ ] Branch preserved (not deleted)
- [ ] Conversation log committed to git
- [ ] Ready to be merged to main

---

## Constitutional References

Your conversation log fulfills these CLAUDE.md requirements:

**Section**: LLM Conversation Logging (MANDATORY)

**Requirements**:
- ✅ Complete conversation logs saved
- ✅ Debugging information maintained
- ✅ Storage location: `documentations/development/conversation_logs/`
- ✅ Naming convention: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- ✅ System state documented
- ✅ CI/CD logs included
- ✅ No sensitive data exposed

---

## Quick Links

- Full guide: [README.md](./README.md)
- Template: [CONVERSATION_LOG_TEMPLATE.md](./CONVERSATION_LOG_TEMPLATE.md)
- Constitution: [CLAUDE.md](../../../../CLAUDE.md#-llm-conversation-logging-mandatory)
- Local CI/CD: [gh-workflow-local.sh](../../../../.runners-local/workflows/gh-workflow-local.sh)

---

## Need Help?

### "How do I format the date?"
- Use: `YYYYMMDD` (e.g., `20251116` for November 16, 2025)
- Run: `date +%Y%m%d`

### "What if I forgot to save the log?"
- No problem! Create it after the fact
- Use the template and fill in details from memory
- Still commit it - retroactive logging is better than none

### "How much detail is needed?"
- **Minimum**: Date, description, what was done, CI/CD results, quality gates
- **Full**: Use the CONVERSATION_LOG_TEMPLATE.md for comprehensive logging
- **Either works** - log something rather than nothing

### "Can I edit the log after committing?"
- Yes, you can amend if you just committed
- Or create a new version for corrections
- Both are acceptable

### "What about sensitive data I accidentally included?"
1. Do NOT commit the log
2. Remove the sensitive data
3. Use `git reset` if already committed
4. Re-commit without sensitive data
5. Force push if already pushed (only your own branch)

---

## Examples of Completed Logs

See the `documentations/development/conversation_logs/` directory for examples of properly formatted conversation logs from previous work.

---

**Status**: REQUIRED FOR ALL LLM ASSISTANTS
**Constitutional Basis**: CLAUDE.md 2.0-2025-LocalCI
**Last Updated**: 2025-11-16
