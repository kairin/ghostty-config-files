# Idempotent start.sh - Quick Reference

## Common Commands

### Basic Operations
```bash
# Normal installation (idempotent - skips existing)
./start.sh

# Check what's installed
./start.sh --show-state

# Get help
./start.sh --help
```

### Force Reinstallation
```bash
# Force reinstall everything
./start.sh --force

# Force reinstall only Ghostty
./start.sh --force-ghostty

# Force reinstall only Node.js
./start.sh --force-node

# Force reinstall multiple components
./start.sh --force-ghostty --force-node
```

### Recovery & Troubleshooting
```bash
# Resume from last failure
./start.sh --resume

# Start fresh (clear state)
./start.sh --reset-state

# Skip version checks (dangerous)
./start.sh --skip-checks
```

## Example Outputs

### First Run (Fresh System)
```
🚀 Starting comprehensive installation...
🔧 Installing ZSH...
✅ Marked 'install_zsh' as completed (version: 5.9)
🔧 Installing Ghostty...
✅ Marked 'install_ghostty' as completed (version: 1.2.3)
🔧 Installing Node.js...
✅ Marked 'install_nodejs' as completed (version: 25.2.0)
...
💾 State: jq '.' .installation-state.json
```

### Second Run (Idempotent)
```
📋 Previous Installation State:
   Last run: 2025-11-13T10:30:00Z
   ✅ Completed steps (8):
      - install_zsh (version: 5.9)
      - install_ghostty (version: 1.2.3)
      - install_nodejs (version: 25.2.0)
      ...

⏭️  ZSH already installed (version: 5.9)
   Use --force-zsh to reinstall
⏭️  Ghostty already installed (version: 1.2.3)
   Use --force-ghostty to reinstall
⏭️  Node.js already installed (version: 25.2.0)
   Use --force-node to reinstall
...
```

### Force Reinstall Output
```
🔄 Force mode enabled - will reinstall Ghostty
🔧 Installing Ghostty...
✅ Marked 'install_ghostty' as completed (version: 1.2.3)
⏭️  ZSH already installed (version: 5.9)
   Use --force-zsh to reinstall
```

## State File Location

**File**: `.installation-state.json`
**Location**: Same directory as `start.sh`

### View State
```bash
# Pretty print state file
jq '.' .installation-state.json

# Check completed steps
jq '.completed_steps' .installation-state.json

# Check versions
jq '.versions' .installation-state.json

# Check failed steps
jq '.failed_steps' .installation-state.json
```

### Manually Edit State (Advanced)
```bash
# Backup state file
cp .installation-state.json .installation-state.json.bak

# Edit with jq
jq '.completed_steps = []' .installation-state.json > temp.json
mv temp.json .installation-state.json

# Or just delete to start fresh
rm .installation-state.json
```

## Available Force Flags

| Flag | Reinstalls |
|------|------------|
| `--force` | Everything |
| `--force-ghostty` | Ghostty terminal only |
| `--force-node` | Node.js/fnm only |
| `--force-zsh` | ZSH/Oh My ZSH only |
| `--force-ptyxis` | Ptyxis terminal only |
| `--force-uv` | Python uv manager only |
| `--force-claude` | Claude Code CLI only |
| `--force-gemini` | Gemini CLI only |
| `--force-spec-kit` | spec-kit only |

## Troubleshooting

### Script won't skip already-installed software
```bash
# Check if state file exists
ls -la .installation-state.json

# If missing, it will be created on next run
./start.sh

# If corrupted, reset it
./start.sh --reset-state
```

### Want to reinstall one component
```bash
# Use specific force flag
./start.sh --force-ghostty
./start.sh --force-node
```

### Installation failed mid-way
```bash
# Resume from failure point
./start.sh --resume

# Or force reinstall the failed component
./start.sh --force-ghostty  # if Ghostty failed
```

### State file corrupted
```bash
# Delete and start fresh
./start.sh --reset-state

# Or manually delete
rm .installation-state.json
./start.sh
```

## Testing

### Run test suite
```bash
# Run comprehensive tests
./test_idempotent_start.sh

# Should show:
# Tests passed: 10/10
# [PASS] All tests passed!
```

### Manual testing scenarios
```bash
# Test 1: Fresh install
rm .installation-state.json
./start.sh

# Test 2: Idempotent rerun
./start.sh  # Should skip everything

# Test 3: Force specific component
./start.sh --force-node

# Test 4: Show state
./start.sh --show-state

# Test 5: Reset and reinstall
./start.sh --reset-state
```

## Integration with Existing Workflows

### CI/CD Pipeline
```bash
# Always fresh install in CI
./start.sh --reset-state

# Or skip if cached
if [ -f .installation-state.json ]; then
    ./start.sh
else
    ./start.sh --reset-state
fi
```

### Developer Setup
```bash
# First time setup
git clone <repo>
cd ghostty-config-files
./start.sh

# Daily updates (only install new components)
./start.sh

# Force update specific tool
./start.sh --force-node  # after Node.js version bump
```

### Production Deployment
```bash
# Controlled rollout
./start.sh --show-state  # Check current state
./start.sh --force-ghostty  # Update specific component
./start.sh --resume  # Finish any incomplete steps
```

## Files Created

| File | Purpose |
|------|---------|
| `.installation-state.json` | State tracking (git ignored) |
| `logs/*-install.log` | Installation logs |
| `logs/*-install.json` | Structured logs |
| `logs/*-manifest.json` | Session manifest |

## Quick Tips

1. **Always safe to rerun**: `./start.sh` is idempotent
2. **Check before force**: Use `--show-state` first
3. **Target specific components**: Use `--force-*` flags
4. **Resume after failure**: Use `--resume` flag
5. **Fresh start**: Use `--reset-state` flag
6. **View help anytime**: `./start.sh --help`

## More Information

- Full documentation: `IDEMPOTENT_ENHANCEMENTS.md`
- Test script: `test_idempotent_start.sh`
- Main script: `start.sh`
- Help: `./start.sh --help`
