---
description: "Quick system diagnostics and environment check"
handoffs:
  - label: "Deploy Site"
    prompt: "Run /001-02-deploy-site to build and deploy the Astro website"
---

# Health Check

Run system diagnostics and report environment status with structured PASS/FAIL/WARNING output.

## Instructions

When the user invokes `/health-check`, execute the diagnostic steps below and report results in a structured format.

## Project Detection

First, determine which project context we're in:

```bash
# Check for ghostty-config-files project markers
if [ -d ".runners-local" ] || [ -f "AGENTS.md" ]; then
  echo "PROJECT: ghostty-config-files (full diagnostics available)"
else
  echo "PROJECT: Generic (basic diagnostics only)"
fi
```

## Diagnostics (Full Mode - ghostty-config-files project)

If in ghostty-config-files project, run the comprehensive health check:

```bash
./.runners-local/workflows/health-check.sh
```

Parse the output and present a structured summary.

## Diagnostics (Basic Mode - Other Projects)

If in another project, check basic tools:

### Step 1: Core Tools Check

```bash
# Check git
git --version && echo "PASS: git" || echo "FAIL: git not found"

# Check gh CLI
gh --version && echo "PASS: gh" || echo "FAIL: gh not found"

# Check Node.js
node --version && echo "PASS: node" || echo "FAIL: node not found"

# Check npm
npm --version && echo "PASS: npm" || echo "FAIL: npm not found"

# Check jq
jq --version && echo "PASS: jq" || echo "FAIL: jq not found"
```

### Step 2: MCP Connectivity (User-Level)

MCP servers should be configured at **user level** (`~/.claude.json`), NOT project level.

```bash
# Check user-level MCP config
if [ -f "$HOME/.claude.json" ]; then
  if jq -e '.mcpServers' "$HOME/.claude.json" > /dev/null 2>&1; then
    SERVER_COUNT=$(jq '.mcpServers | keys | length' "$HOME/.claude.json")
    echo "PASS: MCP config at ~/.claude.json ($SERVER_COUNT servers)"
  fi
fi

# Check actual connectivity via claude mcp list (source of truth)
claude mcp list 2>/dev/null && echo "PASS: MCP servers connected" || echo "WARNING: MCP not accessible"
```

**Note**: No project-level `.env` or `.mcp.json` required. MCP servers handle their own authentication.

### Step 2b: MCP Config Conflict Detection

Detect and prevent conflicts between user-level and project-level MCP configs.

```bash
# Check for project-level .mcp.json (should not exist)
if [ -f ".mcp.json" ]; then
  echo "WARNING: Project-level .mcp.json detected"

  # Compare server names with user-level config
  USER_SERVERS=$(jq -r '.mcpServers | keys[]' ~/.claude.json | sort)
  PROJECT_SERVERS=$(jq -r '.mcpServers | keys[]' .mcp.json | sort)

  # Find conflicts (same server name in both)
  CONFLICTS=$(comm -12 <(echo "$USER_SERVERS") <(echo "$PROJECT_SERVERS"))

  if [ -n "$CONFLICTS" ]; then
    echo "FAIL: Conflicting servers: $CONFLICTS"
    echo "Resolution: Delete .mcp.json or rename conflicting servers"
  fi
else
  echo "PASS: No project-level .mcp.json (user-level only)"
fi
```

**Expected Setup**: MCP servers at user level only (`~/.claude.json`)

**Resolution Options**:
1. **Delete project .mcp.json** (recommended): `rm .mcp.json`
2. **Rename conflicting servers** in project config
3. **Consolidate** all servers to user-level config

### Step 3: Git Status

```bash
git status --short
git branch --show-current
```

## Symlink Integrity Check (Constitutional Requirement)

**CRITICAL**: In ghostty-config-files project, CLAUDE.md and GEMINI.md MUST be symlinks to AGENTS.md (single source of truth).

### Check Logic

```bash
# Check AGENTS.md exists (master file)
if [ -f "AGENTS.md" ]; then
  echo "PASS: AGENTS.md (master file) exists"
else
  echo "FAIL: AGENTS.md (master file) not found"
fi

# Check CLAUDE.md
if [ -L "CLAUDE.md" ]; then
  TARGET=$(readlink CLAUDE.md)
  if [ "$TARGET" = "AGENTS.md" ]; then
    echo "PASS: CLAUDE.md → AGENTS.md"
  else
    echo "WARNING: CLAUDE.md symlink points to wrong target: $TARGET"
  fi
elif [ -f "CLAUDE.md" ]; then
  echo "FAIL: CLAUDE.md is a regular file, not a symlink (needs consolidation)"
else
  echo "WARNING: CLAUDE.md missing (needs creation)"
fi

# Check GEMINI.md
if [ -L "GEMINI.md" ]; then
  TARGET=$(readlink GEMINI.md)
  if [ "$TARGET" = "AGENTS.md" ]; then
    echo "PASS: GEMINI.md → AGENTS.md"
  else
    echo "WARNING: GEMINI.md symlink points to wrong target: $TARGET"
  fi
elif [ -f "GEMINI.md" ]; then
  echo "FAIL: GEMINI.md is a regular file, not a symlink (needs consolidation)"
else
  echo "WARNING: GEMINI.md missing (needs creation)"
fi
```

### Remediation for Symlink Issues

**If symlink missing**:
```bash
ln -s AGENTS.md CLAUDE.md
ln -s AGENTS.md GEMINI.md
```

**If regular file exists (needs consolidation)**:
1. Backup existing content: `cp CLAUDE.md CLAUDE.md.backup`
2. Compare with AGENTS.md for unique content
3. Merge any unique content into AGENTS.md
4. Remove regular file: `rm CLAUDE.md`
5. Create symlink: `ln -s AGENTS.md CLAUDE.md`

**If wrong symlink target**:
```bash
rm CLAUDE.md
ln -s AGENTS.md CLAUDE.md
```

## Output Format

Present results in this structured format:

```
=====================================
HEALTH CHECK REPORT
=====================================
Project: [detected project name]
Mode: [Full/Basic]

Component Status:
-----------------
| Component     | Status  | Version/Details |
|---------------|---------|-----------------|
| git           | PASS    | 2.43.0          |
| gh            | PASS    | 2.45.0          |
| node          | PASS    | 22.5.0          |
| npm           | PASS    | 10.8.0          |
| jq            | PASS    | 1.7             |
| MCP           | PASS    | Connected       |

[Additional checks if in Full mode...]

Overall: [HEALTHY / NEEDS ATTENTION / CRITICAL]
=====================================
```

## Remediation Suggestions

If any component fails, provide remediation:

- **git**: `sudo apt install git` or visit https://git-scm.com
- **gh**: `sudo apt install gh` or `brew install gh`, then `gh auth login`
- **node**: Install via fnm: `fnm install --latest`
- **npm**: Comes with Node.js
- **jq**: `sudo apt install jq`
- **MCP**: MCP servers are configured at user level (`~/.claude.json`). Use Claude Code settings to configure MCP servers.

## Status Definitions

- **PASS**: Component working correctly
- **WARNING**: Component works but may have issues (e.g., outdated version)
- **FAIL**: Component missing or broken, requires action

## Next Steps

After health check completes:
- If all PASS: Suggest running `/001-02-deploy-site` to build and deploy
- If any FAIL: Show remediation steps before proceeding
- If WARNING: Note issues but allow proceeding

**Always include this in your output:**
```
Next Skill:
-----------
→ /001-02-deploy-site - Build and deploy Astro website to GitHub Pages
```
