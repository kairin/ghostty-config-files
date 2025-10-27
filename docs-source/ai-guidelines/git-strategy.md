---
title: "Git Strategy"
description: "AI assistant guidelines for git-strategy"
pubDate: 2025-10-27
author: "AI Integration Team"
tags: ["ai", "guidelines"]
targetAudience: "all"
constitutional: true
---


> **Note**: This is a modular extract from [AGENTS.md](../../AGENTS.md) for documentation purposes. AGENTS.md remains the single source of truth.

## Branch Management & Git Strategy

### Branch Preservation (MANDATORY)
- **NEVER DELETE BRANCHES** without explicit user permission
- **ALL BRANCHES** contain valuable configuration history
- **NO** automatic cleanup with `git branch -d`
- **YES** to automatic merge to main branch, preserving dedicated branch

### Branch Naming (MANDATORY SCHEMA)
**Format**: `YYYYMMDD-HHMMSS-type-short-description`

Examples:
- `20250919-143000-feat-context-menu-integration`
- `20250919-143515-fix-performance-optimization`
- `20250919-144030-docs-agents-enhancement`

### GitHub Safety Strategy

```bash
# MANDATORY: Every commit must use this workflow
DATETIME=$(date +"%Y%m%d-%H%M%S")
BRANCH_NAME="${DATETIME}-feat-description"
git checkout -b "$BRANCH_NAME"
git add .
git commit -m "Descriptive commit message

🤖 Generated with [Claude Code](https://claude.ai/code)
Co-Authored-By: Claude <noreply@anthropic.com>"
git push -u origin "$BRANCH_NAME"
git checkout main
git merge "$BRANCH_NAME" --no-ff
git push origin main
# NEVER: git branch -d "$BRANCH_NAME"
```

## Committing Changes with Git

Only create commits when requested by the user. If unclear, ask first. When the user asks you to create a new git commit, follow these steps carefully:

### Git Safety Protocol
- NEVER update the git config
- NEVER run destructive/irreversible git commands (like push --force, hard reset, etc) unless the user explicitly requests them
- NEVER skip hooks (--no-verify, --no-gpg-sign, etc) unless the user explicitly requests it
- NEVER run force push to main/master, warn the user if they request it
- Avoid git commit --amend. ONLY use --amend when either (1) user explicitly requested amend OR (2) adding edits from pre-commit hook
- Before amending: ALWAYS check authorship (git log -1 --format='%an %ae')
- NEVER commit changes unless the user explicitly asks you to. It is VERY IMPORTANT to only commit when explicitly asked, otherwise the user will feel that you are being too proactive.

### Commit Workflow

1. **Parallel Information Gathering**: Run multiple bash commands in parallel using the Bash tool:
   - Run a git status command to see all untracked files.
   - Run a git diff command to see both staged and unstaged changes that will be committed.
   - Run a git log command to see recent commit messages, so that you can follow this repository's commit message style.

2. **Analyze and Draft**:
   - Summarize the nature of the changes (eg. new feature, enhancement to an existing feature, bug fix, refactoring, test, docs, etc.)
   - Do not commit files that likely contain secrets (.env, credentials.json, etc). Warn the user if they specifically request to commit those files
   - Draft a concise (1-2 sentences) commit message that focuses on the "why" rather than the "what"
   - Ensure it accurately reflects the changes and their purpose

3. **Commit with Attribution**:
   - Add relevant untracked files to the staging area
   - Create the commit with a message ending with attribution:

```bash
git commit -m "$(cat <<'EOF'
Commit message here.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

4. **Handle Pre-commit Hooks**:
   - If the commit fails due to pre-commit hook changes, retry ONCE.
   - If it succeeds but files were modified by the hook, verify it's safe to amend:
     - Check authorship: `git log -1 --format='%an %ae'`
     - Check not pushed: git status shows "Your branch is ahead"
     - If both true: amend your commit. Otherwise: create NEW commit

### Important Notes
- NEVER run additional commands to read or explore code, besides git bash commands
- NEVER use the TodoWrite or Task tools during git operations
- DO NOT push to the remote repository unless the user explicitly asks you to do so
- IMPORTANT: Never use git commands with the -i flag (like git rebase -i or git add -i) since they require interactive input
- If there are no changes to commit (i.e., no untracked files and no modifications), do not create an empty commit

## Creating Pull Requests

Use the gh command via the Bash tool for ALL GitHub-related tasks including working with issues, pull requests, checks, and releases.

### PR Creation Workflow

1. **Parallel Branch Analysis**: Run the following bash commands in parallel:
   - Run a git status command to see all untracked files
   - Run a git diff command to see both staged and unstaged changes
   - Check if the current branch tracks a remote branch and is up to date
   - Run git log and `git diff [base-branch]...HEAD` to understand full commit history

2. **Analyze Changes**: Make sure to look at ALL commits that will be included in the PR (NOT just the latest commit)

3. **Create PR**: Run commands in parallel:
   - Create new branch if needed
   - Push to remote with -u flag if needed
   - Create PR using gh pr create with the format below

```bash
gh pr create --title "the pr title" --body "$(cat <<'EOF'
## Summary
<1-3 bullet points>

## Test plan
[Bulleted markdown checklist of TODOs for testing the pull request...]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Important Notes
- DO NOT use the TodoWrite or Task tools during PR creation
- Return the PR URL when you're done, so the user can see it

## Other Common Operations

```bash
# View comments on a Github PR
gh api repos/foo/bar/pulls/123/comments
```
