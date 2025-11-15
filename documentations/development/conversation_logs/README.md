# Conversation Logs Infrastructure

## Overview

This directory contains conversation logs from AI assistant interactions with the ghostty-config-files repository. As per CLAUDE.md constitutional requirements, all AI assistants working on this repository MUST maintain complete conversation logs to enable debugging, auditing, and knowledge continuity.

## Purpose

Conversation logs serve multiple critical functions:

1. **Debugging & Troubleshooting**: Track decisions, issues encountered, and solutions implemented
2. **Audit Trail**: Maintain a record of changes made to the codebase by AI assistants
3. **Knowledge Continuity**: Enable future assistants to understand context and reasoning behind implementations
4. **Quality Assurance**: Document testing, validation, and quality gates applied
5. **Constitutional Compliance**: Fulfill CLAUDE.md requirement for complete conversation logging
6. **System State Capture**: Record before/after system states for reproducibility

## Naming Convention

All conversation logs MUST follow this naming scheme:

```
CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md
```

**Format Details:**
- `YYYYMMDD`: ISO 8601 date format (e.g., `20251116` for November 16, 2025)
- `DESCRIPTION`: Concise description of the work performed (lowercase, hyphens for spaces)
- Examples:
  - `CONVERSATION_LOG_20251116_local-cicd-setup.md`
  - `CONVERSATION_LOG_20251115_ghostty-performance-optimization.md`
  - `CONVERSATION_LOG_20251114_github-mcp-integration.md`

## What to Include

Each conversation log MUST contain:

### 1. Header Section
```markdown
# Conversation Log: [DESCRIPTION]

**Date**: YYYYMMDD
**Assistant**: [Claude, Gemini, etc.]
**Model**: [Model ID/Version]
**Topic**: [Brief description of work]
**Status**: Completed / In Progress / Failed
```

### 2. Executive Summary
- High-level overview of what was accomplished
- Key decisions made
- Issues encountered and resolutions

### 3. Conversation Transcript
- Complete or summarized conversation flow
- Key questions asked by user
- Responses and reasoning provided by assistant
- File modifications and commits made

### 4. Implementation Details
- Code changes made (with file paths and snippets if relevant)
- Configuration updates applied
- New files created or deleted
- Breaking changes or deprecations

### 5. System State Snapshots

#### Before State
```json
{
  "timestamp": "2025-11-16T10:30:00Z",
  "git_branch": "main",
  "git_status": "clean/dirty",
  "system": {
    "kernel": "6.17.0-6-generic",
    "os": "Linux",
    "cpu_cores": 8,
    "memory_gb": 16
  },
  "tools": {
    "ghostty_version": "1.1.4",
    "zsh_version": "5.9",
    "nodejs_version": "v25.2.0"
  }
}
```

#### After State
```json
{
  "timestamp": "2025-11-16T11:45:00Z",
  "git_branch": "20251116-104500-feat-example",
  "git_status": "clean",
  "changes_made": [
    "File: /path/to/file.md (added 50 lines)",
    "File: /path/to/script.sh (modified)"
  ],
  "commits": [
    "abc1234: Commit message"
  ]
}
```

### 6. Testing & Validation
- Tests run and their outcomes
- Local CI/CD results (`./.runners-local/workflows/gh-workflow-local.sh`)
- Configuration validation results (`ghostty +show-config`)
- Performance benchmarks if applicable

### 7. CI/CD Logs
- Copy of relevant logs from `./.runners-local/logs/`
- GitHub Actions simulation results
- Build output (if applicable)
- Deployment status

### 8. Quality Gates Checklist
```markdown
### Quality Gates Verification

- [ ] Local CI/CD execution successful
- [ ] Configuration validation passed
- [ ] All tests passing
- [ ] User customizations preserved
- [ ] Performance metrics acceptable
- [ ] No sensitive data exposed
- [ ] Documentation updated
- [ ] Branch naming convention followed
- [ ] Conversation log saved
```

### 9. References & Documentation
- Links to relevant specifications (e.g., `documentations/specifications/001-repo-structure-refactor/`)
- References to CLAUDE.md sections
- Related conversation logs or implementation summaries

## What to EXCLUDE (CRITICAL)

**NEVER include sensitive information:**

- ❌ API keys or authentication tokens
- ❌ Passwords or credentials
- ❌ Personal information (names, emails, phone numbers)
- ❌ Private configuration values
- ❌ SSH keys or private keys
- ❌ OAuth tokens or bearer tokens
- ❌ Database connection strings with credentials
- ❌ AWS/GCP/Azure credentials
- ❌ Private GitHub tokens

**Sanitization Examples:**
```markdown
# ❌ WRONG - Contains API key
Context7 API Key: ctx7sk-abc123def456ghi789

# ✅ CORRECT - Redacted
Context7 API Key: ctx7sk-[REDACTED]
```

```markdown
# ❌ WRONG - Contains full email
User: john.doe@example.com

# ✅ CORRECT - Anonymized
User: [ANONYMIZED]
```

## How to Capture Logs

### For Claude Code / Claude Assistants

1. **Start your work normally** and maintain the conversation
2. **Track important information** as you work:
   ```bash
   # Capture system state before starting
   git status > /tmp/before_state.txt
   ghostty +show-config > /tmp/before_config.txt

   # Do your work...

   # Capture system state after completing
   git status > /tmp/after_state.txt
   ./.runners-local/workflows/gh-workflow-local.sh status > /tmp/ci_cd_status.txt
   ```

3. **Save the conversation log** after completing your work:
   ```bash
   # Create log directory if needed
   mkdir -p documentations/development/conversation_logs/

   # Copy conversation and system state to log file
   cp conversation.md documentations/development/conversation_logs/CONVERSATION_LOG_$(date +%Y%m%d)_description.md

   # Commit the log
   git add documentations/development/conversation_logs/
   git commit -m "Add conversation log for [description]"
   ```

4. **Include local CI/CD logs:**
   ```bash
   # After local CI/CD execution
   cp ./.runners-local/logs/workflow-*.log documentations/development/conversation_logs/logs/
   cp ./.runners-local/logs/performance-*.json documentations/development/conversation_logs/logs/
   ```

### System State Capture Commands

```bash
# Full system diagnostic capture
{
  echo "=== Git Status ==="
  git status
  echo -e "\n=== Git Log (recent) ==="
  git log --oneline -10
  echo -e "\n=== System Info ==="
  uname -a
  echo -e "\n=== Ghostty Config ==="
  ghostty +show-config
  echo -e "\n=== Node.js Version ==="
  node --version
  echo -e "\n=== ZSH Version ==="
  zsh --version
} > /tmp/system_state_$(date +%Y%m%d_%H%M%S).txt
```

### JSON State Capture

```bash
# Create structured system state JSON
jq -n \
  --arg timestamp "$(date -Iseconds)" \
  --arg branch "$(git branch --show-current)" \
  --arg kernel "$(uname -r)" \
  --arg ghostty "$(ghostty --version 2>/dev/null || echo 'unknown')" \
  '{
    timestamp: $timestamp,
    git_branch: $branch,
    kernel: $kernel,
    ghostty_version: $ghostty
  }' > /tmp/system_state_$(date +%Y%m%d_%H%M%S).json
```

## Logging Checklist

Before committing your conversation log, verify:

- [ ] File named correctly: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- [ ] Header section complete with date, assistant, model, topic
- [ ] Executive summary provided
- [ ] All code changes documented with file paths
- [ ] System state snapshots (before and after) included
- [ ] No sensitive data (API keys, tokens, credentials)
- [ ] Local CI/CD results documented
- [ ] Quality gates checklist completed
- [ ] Tests and validation results included
- [ ] References to specifications/related logs provided
- [ ] Ready to be committed to version control

## Storage & Archival

### Active Logs
- Current conversation logs remain in: `documentations/development/conversation_logs/`
- Committed to version control for audit trail
- Searchable and browsable by date and description

### Archival
- Logs older than 90 days can be moved to: `documentations/archive/conversation_logs/`
- Maintain reference index in `documentations/archive/conversation_logs/INDEX.md`
- Archival is optional but recommended for repository organization

## Viewing & Searching Logs

```bash
# List all conversation logs by date
ls -lrt documentations/development/conversation_logs/CONVERSATION_LOG_*.md

# Search for logs by description
grep -l "pattern" documentations/development/conversation_logs/*.md

# View recent logs
ls -lt documentations/development/conversation_logs/*.md | head -5

# Search log content
grep -r "search term" documentations/development/conversation_logs/

# Count logs created in November 2025
ls documentations/development/conversation_logs/CONVERSATION_LOG_202511*.md | wc -l
```

## Integration with Development Workflow

### Before Starting Work
```bash
# Check recent conversation logs for context
ls -lt documentations/development/conversation_logs/ | head -3

# Review related specifications
ls documentations/specifications/
```

### After Completing Work
```bash
# Save conversation log
cp <conversation> documentations/development/conversation_logs/CONVERSATION_LOG_$(date +%Y%m%d)_description.md

# Include in commit
git add documentations/development/conversation_logs/CONVERSATION_LOG_*.md
git commit -m "Add conversation log for [description]"
```

## Constitutional References

These logs fulfill the following CLAUDE.md requirements:

**Section: LLM Conversation Logging (MANDATORY)**
> "All AI assistants working on this repository MUST save complete conversation logs and maintain debugging information."

**Requirements Met:**
- ✅ Complete conversation logs (this infrastructure)
- ✅ Exclude sensitive data (documented in this README)
- ✅ Storage location (documentations/development/conversation_logs/)
- ✅ Naming convention (CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md)
- ✅ System state capture (before/after documentation)
- ✅ CI/CD logs inclusion (.runners-local/logs/)

## Support & Questions

For questions about:
- **Conversation logging requirements**: See CLAUDE.md section "LLM Conversation Logging (MANDATORY)"
- **Constitutional compliance**: Review CLAUDE.md sections "ABSOLUTE PROHIBITIONS" and "MANDATORY ACTIONS"
- **Local CI/CD results**: Check `./.runners-local/logs/` directory
- **System state**: Review captured JSON/text files in conversation log
- **Related specifications**: See `documentations/specifications/` directory

## Last Updated

- Date: 2025-11-16
- Infrastructure Version: 1.0
- Constitutional Version: CLAUDE.md 2.0-2025-LocalCI
- Status: ACTIVE - MANDATORY COMPLIANCE
