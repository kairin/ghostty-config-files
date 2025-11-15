# Security & Sensitive Data Guidelines

This document provides detailed guidelines for protecting sensitive information when creating conversation logs.

## Critical Security Rules

### Rule 1: NEVER Include API Keys or Authentication Tokens

**Types of secrets to NEVER include:**

```
❌ FORBIDDEN:
- ctx7sk-abcdef123456
- ghp_abc123def456ghi789
- gho_abc123def456ghi789
- ghu_abc123def456ghi789
- ghs_abc123def456ghi789
- ghr_abc123def456ghi789
- github_pat_123456789
- sk-ant-v0-abc123def456
- Bearer: abc123token456
- Authorization: Bearer abc123
- X-API-Key: abc123def456
- Private keys (RSA, ED25519, etc.)
- AWS_ACCESS_KEY_ID=ABC123
- AWS_SECRET_ACCESS_KEY=abc123
- STRIPE_API_KEY=sk_live_abc123
- MONGODB_URI=mongodb+srv://user:pass@host
```

**How to reference them safely:**

```markdown
# ❌ WRONG
Context7 API Key: ctx7sk-1234567890abcdef
GitHub Token: ghp_abc123def456ghi789
AWS Secret: AKIAIOSFODNN7EXAMPLE

# ✅ CORRECT
Context7 API Key: [REDACTED]
GitHub Token: [REDACTED]
AWS Credentials: [REDACTED]
```

---

### Rule 2: Anonymize Personal Information

**Types of personal info to REDACT:**

```
❌ FORBIDDEN:
- john.doe@example.com
- jane_smith@company.org
- +1-234-567-8900
- John Smith
- SSN: 123-45-6789
- John's team lead
- Discussed with Sarah
```

**How to anonymize safely:**

```markdown
# ❌ WRONG
User: john.doe@example.com
Phone: +1-234-567-8900
Discussed with Jane Smith from engineering team
Reported by: mike.johnson@company.com

# ✅ CORRECT
User: [ANONYMIZED]
Phone: [REDACTED]
Discussed with team member from engineering
Reported by: [ANONYMIZED]
```

---

### Rule 3: Protect Private Configuration Values

**Types of private config to REDACT:**

```
❌ FORBIDDEN:
- Database passwords: postgres://user:SecurePass123@db.example.com
- SSH keys or passphrases
- Private SSH connection strings
- Home directory paths with usernames: /home/john.doe/...
- IP addresses of private infrastructure
- Internal domain names: internal-api.company.net
- Private repository URLs with credentials
- Database connection strings with passwords
```

**How to reference safely:**

```markdown
# ❌ WRONG
Database connection: postgresql://admin:MyPassword123@prod-db.internal.company.net:5432/maindb
SSH key path: /home/john.doe/.ssh/id_rsa_company

# ✅ CORRECT
Database connection: postgresql://[REDACTED]:[REDACTED]@[REDACTED]:5432/maindb
SSH key path: [REDACTED]

# OR: Generic reference
Database connection: [PostgreSQL connection with credentials REDACTED]
SSH key: [Private SSH key REDACTED]
```

---

### Rule 4: Protect OAuth Tokens and Session Data

**Types of tokens to REDACT:**

```
❌ FORBIDDEN:
- oauth_token=abc123def456ghi789
- refresh_token=xyz789abc123
- session_id=sess_abc123def456
- id_token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
- access_token=eyJhbGciOiJSUzI1NiIs...
- x-auth-token: abc123def456
- Set-Cookie: session=abc123; secure
```

**How to reference safely:**

```markdown
# ❌ WRONG
OAuth token obtained: oauth_token=2a4d5b8f9c0e1f2a3b4c5d6e7f8a9b0c
Refresh with: refresh_token=8f2a3b4c5d6e7f8a9b0c1a2d3e4f5a6b

# ✅ CORRECT
OAuth token: [REDACTED]
Refresh token: [REDACTED]

# OR: Describe what happened
Obtained OAuth token from authentication provider
Token successfully used for API access
Refresh mechanism verified
```

---

### Rule 5: Encrypt Sensitive File Contents

**If you MUST reference a file with sensitive data:**

```markdown
# ❌ WRONG
Modified ~/.env file:
CONTEXT7_API_KEY=ctx7sk-abc123def456
DATABASE_URL=postgres://user:pass@host

# ✅ CORRECT
Modified ~/.env file:
[Contains 2 environment variables REDACTED]

# OR: Describe the change
Updated configuration file:
- Added Context7 API key (REDACTED)
- Updated database connection string (credentials REDACTED)
- Verified 3 new environment variables set
```

---

### Rule 6: Sanitize Log File Contents

**When quoting log files:**

```markdown
# ❌ WRONG (contains credentials)
[2025-11-16 10:30:00] Connecting to database: postgres://admin:MyPassword123@db.prod.company.net
[2025-11-16 10:30:01] Authentication token: ghp_abc123def456ghi789xyz
[2025-11-16 10:30:02] API call successful

# ✅ CORRECT
[2025-11-16 10:30:00] Connecting to database: postgres://[REDACTED]:[REDACTED]@[REDACTED]
[2025-11-16 10:30:01] Authentication token: [REDACTED]
[2025-11-16 10:30:02] API call successful

# OR: Summarize
[2025-11-16 10:30:00] Database connection established (credentials REDACTED)
[2025-11-16 10:30:01] Authentication successful
[2025-11-16 10:30:02] API call successful
```

---

## Security Checklist

### Before Saving Your Conversation Log

- [ ] Search for all API keys and tokens (`ctx7sk-`, `ghp_`, `sk-`, `Bearer`, etc.)
- [ ] Search for email addresses (@example.com, @company.org, etc.)
- [ ] Search for passwords or passphrases
- [ ] Search for database connection strings with credentials
- [ ] Search for SSH keys or private keys
- [ ] Search for OAuth tokens or session IDs
- [ ] Search for personal phone numbers or SSNs
- [ ] Search for internal IP addresses or domain names
- [ ] Search for private home directory paths with usernames
- [ ] Review all code snippets for embedded credentials
- [ ] Review all log files quoted for sensitive data
- [ ] Review all environment variables for secrets
- [ ] Verify all references are using [REDACTED] format
- [ ] Test redaction by searching for patterns (e.g., `ghp_`, `ctx7sk-`)

### Testing for Sensitive Data

```bash
# Before committing, search for common patterns
grep -r "ghp_\|gho_\|ghu_\|ghs_\|ghr_\|github_pat" documentations/development/conversation_logs/CONVERSATION_LOG_*.md

# Search for Bearer tokens
grep -r "Bearer " documentations/development/conversation_logs/CONVERSATION_LOG_*.md

# Search for Context7 API keys
grep -r "ctx7sk-" documentations/development/conversation_logs/CONVERSATION_LOG_*.md

# Search for potential passwords (look for "password" or "passwd")
grep -ri "password.*=" documentations/development/conversation_logs/CONVERSATION_LOG_*.md

# Search for database URIs with credentials
grep -r "postgresql://.*:.*@\|mongodb://.*:.*@\|mysql://.*:.*@" documentations/development/conversation_logs/

# Search for AWS credentials
grep -r "AKIA\|ASIA" documentations/development/conversation_logs/CONVERSATION_LOG_*.md

# Manual inspection of all files
cat documentations/development/conversation_logs/CONVERSATION_LOG_*.md | grep -E "key|token|secret|password|credential"
```

---

## Common Mistakes & How to Fix Them

### Mistake 1: Including Full API Keys

**Before** (❌ WRONG):
```markdown
## Implementation Details

Connected to Context7 using API key:
```
ctx7sk-8f2a3b4c5d6e7f8a9b0c1a2d3e4f5a6b
```

**After** (✅ CORRECT):
```markdown
## Implementation Details

Connected to Context7 using API key:
[REDACTED]
```

### Mistake 2: Quoting Logs with Credentials

**Before** (❌ WRONG):
```markdown
## CI/CD Log Output

Auth token validation successful: ghp_abc123def456ghi789xyz
Database host: prod-db.internal.company.net (192.168.1.50)
```

**After** (✅ CORRECT):
```markdown
## CI/CD Log Output

Auth token validation successful: [REDACTED]
Database host: [REDACTED] ([REDACTED])
```

### Mistake 3: Including User/Email Information

**Before** (❌ WRONG):
```markdown
## Team Collaboration

Discussed with john.doe@company.org (john.doe)
Approved by: jane.smith@company.org
Reviewed by: mike.johnson from ops team
Phone: +1-555-123-4567
```

**After** (✅ CORRECT):
```markdown
## Team Collaboration

Discussed with team member
Approved by: team lead
Reviewed by: operations team member
Phone: [REDACTED]
```

### Mistake 4: Exposing File Paths with Usernames

**Before** (❌ WRONG):
```markdown
Modified files in /home/john.doe/.config/ghostty/config
Backup stored at /home/john.doe/.local/share/backup.tar.gz
SSH key: /home/john.doe/.ssh/id_rsa_github
```

**After** (✅ CORRECT):
```markdown
Modified configuration file
Backup stored in user configuration directory
SSH key: [REDACTED]
```

---

## What's Safe to Include

These items are SAFE to include in conversation logs:

✅ **File paths** (without usernames):
- `/home/kkk/Apps/ghostty-config-files/`
- `/etc/ghostty/config`
- `documentations/development/conversation_logs/`

✅ **Generic system info**:
- Kernel version: `6.17.0-6-generic`
- OS: `Linux`
- Tool versions: `Ghostty 1.1.4`, `ZSH 5.9`, `Node.js v25.2.0`
- GitHub CLI version: `2.x.x`

✅ **Non-sensitive configuration**:
- Feature flags (enabled/disabled)
- Performance metrics
- Test results
- Build output (without credentials)
- Log summaries (without sensitive data)

✅ **Public information**:
- Repository names and public URLs
- Issue numbers and pull request numbers
- Commit hashes (after pushed)
- Public documentation links
- Published specifications

✅ **Redacted examples**:
- `API key: [REDACTED]`
- `Email: [ANONYMIZED]`
- `Database URL: [REDACTED]`
- `SSH key: [REDACTED]`

---

## Responding to Sensitive Data Disclosure

### If You Accidentally Included Sensitive Data

**BEFORE committing to git:**

1. Remove the file: `rm documentations/development/conversation_logs/CONVERSATION_LOG_*.md`
2. Edit your conversation to remove sensitive data
3. Recreate the log with sanitized content
4. Verify: `grep -r "ghp_\|ctx7sk-\|Bearer" documentations/development/conversation_logs/`
5. Commit the corrected version

**IF ALREADY COMMITTED to your local branch:**

```bash
# Reset the last commit (before pushing)
git reset HEAD~1

# Remove the file
rm documentations/development/conversation_logs/CONVERSATION_LOG_*.md

# Fix the content
# (recreate with sanitized data)

# Re-add and commit
git add documentations/development/conversation_logs/
git commit -m "Add conversation log (sanitized)"
```

**IF ALREADY PUSHED to remote:**

1. This is serious - the data is exposed
2. If possible, contact the repository owner
3. Follow GitHub's steps to remove sensitive data from history
4. Consider rotating any exposed credentials
5. Document the incident for learning purposes

---

## Constitutional References

This document supports CLAUDE.md requirements:

**Section**: LLM Conversation Logging (MANDATORY)
> "NEVER include sensitive information... Exclude sensitive data (API keys, passwords, personal information)"

**Section**: ABSOLUTE PROHIBITIONS
> "Commit sensitive data (API keys, passwords, personal information)"

---

## Security Best Practices

1. **Use version control secrets scanners**
   ```bash
   # Scan before committing
   git diff --cached | grep -E "ghp_|ctx7sk-|sk-ant|Bearer"
   ```

2. **Review logs carefully**
   - Read through your entire log file
   - Search for common credential patterns
   - Check all quoted logs and output

3. **Use .gitignore for development**
   - Keep `.env` files out of git
   - Never commit `credentials.json`
   - Store sensitive config outside the repository

4. **Educate yourself on secret formats**
   - Learn to recognize API key patterns
   - Know common prefix patterns (ghp_, ctx7sk-, sk-, etc.)
   - Understand how credentials typically appear in logs

5. **Automate detection if possible**
   ```bash
   # Create a pre-commit hook
   cat > .git/hooks/pre-commit << 'EOF'
   #!/bin/bash
   # Prevent committing sensitive patterns
   if git diff --cached | grep -qE "ghp_|ctx7sk-|sk-ant-v0"; then
     echo "ERROR: Potential API key detected in staged changes"
     exit 1
   fi
   EOF
   chmod +x .git/hooks/pre-commit
   ```

---

## Questions & Support

**Q: What if I'm unsure if something is sensitive?**
A: When in doubt, redact it. It's better to be over-protective than expose credentials.

**Q: Can I include error messages that mention credentials?**
A: No. Always sanitize error messages to remove or redact any credentials they might contain.

**Q: What about commit hashes or branch names that might contain secrets?**
A: If you accidentally used a secret in a branch name, that's a bigger problem. Recreate the branch with a proper name.

**Q: Who reviews my conversation logs for security?**
A: These are public commits on GitHub. Assume they will be indexed and searchable. Only include information you would put in public documentation.

---

## Last Updated

- Date: 2025-11-16
- Version: 1.0
- Status: ACTIVE - SECURITY CRITICAL
- Constitutional Basis: CLAUDE.md 2.0-2025-LocalCI

**Remember**: Once something is in git history, it's difficult to remove completely. Prevention is always better than remediation.
