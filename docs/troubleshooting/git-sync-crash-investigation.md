# Investigation: /001-03-git-sync Skill Causes Ghostty Crash

**Date**: 2026-01-21
**Status**: Active Investigation
**Severity**: High (terminal crash)
**Affected**: Ghostty 1.3.0 on Ubuntu 25.10

## Summary

The `/001-03-git-sync` skill causes Ghostty terminal to crash during execution. The crash occurs before any error message can be read.

## Environment

| Component | Version |
|-----------|---------|
| Ghostty | 1.3.0 (stable) |
| GTK | 4.20.1 |
| libadwaita | 1.8.0 |
| Renderer | OpenGL 4.6 |
| libxev | io_uring |
| Kernel | 6.17.0-8-generic |
| OS | Ubuntu 25.10 (Questing) |
| Theme Switcher | **Active** (uses SIGUSR2) |

## Root Cause Analysis

### Hypothesis 1: SIGUSR2 Signal Conflict (High Probability)

The theme switcher service is **actively running** and sends `SIGUSR2` signals to Ghostty:

```bash
# From ghostty-theme-switcher.sh line 63
pkill -SIGUSR2 ghostty 2>/dev/null
```

If the theme detects a change while the git-sync skill is executing, it sends SIGUSR2 to Ghostty to reload the config. This could interrupt rendering mid-stream and cause a crash.

**Evidence**:
- Theme switcher service: `active (running)`
- Uses `gsettings monitor` which can trigger at any time
- SIGUSR2 forces config reload during potentially critical rendering

### Hypothesis 2: Rapid Output Rendering (Medium Probability)

The git-sync skill runs multiple commands quickly:
```bash
git status
git branch -vv
git fetch --all --prune
git rev-list --count @{u}..HEAD
git log --oneline @{u}..HEAD
```

Combined with Claude Code's streaming output, this could overwhelm Ghostty's renderer.

### Hypothesis 3: ANSI Escape Sequence Issue (Low Probability)

Git commands with color output produce ANSI escape sequences. A malformed or unexpected sequence during rapid output could crash the terminal.

## Investigation Steps Completed

1. **Skill Analysis**: The skill file (180 lines) contains standard git commands with no malicious content
2. **Theme Switcher Check**: Service is **active and running**, using SIGUSR2 signals
3. **Ghostty Logs**: No crash dumps found in journal or coredumps
4. **Config Review**: Ghostty config uses modular includes, shell-integration disabled

## Diagnostic Tool

A diagnostic script has been created to isolate the crash trigger:

```bash
./tests/diagnose-git-sync-crash.sh [--with-output | --minimal]
```

This runs each command from the skill individually with delays to identify which triggers the crash.

## Recommended Workarounds

### Workaround 1: Stop Theme Switcher Temporarily (Recommended First)

```bash
# Stop the service
systemctl --user stop ghostty-theme-switcher.service

# Test the skill
# Run /001-03-git-sync

# Re-enable if needed
systemctl --user start ghostty-theme-switcher.service
```

### Workaround 2: Disable Git Colors

```bash
# Disable colors
git config --global color.ui false

# Test the skill

# Re-enable colors
git config --global color.ui auto
```

### Workaround 3: Test in Different Terminal

Run Claude Code in a different terminal to confirm Ghostty is the issue:

```bash
# In gnome-terminal or kitty
claude
# Then run /001-03-git-sync
```

### Workaround 4: Capture Output Before Crash

```bash
# Start logging
script -q /tmp/claude-skill-output.log

# Run Claude Code and the skill
claude
# /001-03-git-sync

# After crash, check the log
cat /tmp/claude-skill-output.log
```

## Files Involved

| File | Path | Purpose |
|------|------|---------|
| Skill Source | `.claude/skill-sources/001-03-git-sync.md` | Skill definition |
| Installed Skill | `~/.claude/commands/001-03-git-sync.md` | Active skill |
| Theme Switcher | `scripts/ghostty-theme-switcher.sh` | Uses SIGUSR2 |
| Diagnostic Tool | `tests/diagnose-git-sync-crash.sh` | Isolate trigger |
| Ghostty Config | `~/.config/ghostty/config` | Terminal config |

## Next Steps

1. **User Action**: Run diagnostic script in Ghostty
2. **User Action**: Try Workaround 1 (stop theme switcher) and re-test
3. **If confirmed**: Report to Ghostty upstream at https://github.com/ghostty-org/ghostty/issues
4. **Long-term**: Consider adding output throttling to skills that run multiple commands

## Related Issues

- Ghostty SIGUSR2 handling: May need investigation
- io_uring + GTK4 interaction: Potential race condition
- OpenGL renderer under load: Could be related

## Conclusion

This is likely a **Ghostty bug** triggered by either:
1. SIGUSR2 signal during output rendering (theme switcher conflict)
2. Rapid command output overwhelming the renderer

The theme switcher is the most probable cause given it's actively monitoring and can send signals at any time during skill execution.
