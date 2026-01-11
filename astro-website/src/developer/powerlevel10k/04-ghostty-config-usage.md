# Powerlevel10k Usage in ghostty-config-files

> Project-specific implementation details

## Overview

This project provides automated Powerlevel10k installation and configuration via `scripts/configure_zsh.sh`, optimized for Ghostty terminal with performance targets.

## Installation Script

### Location
```
scripts/configure_zsh.sh
```

### Usage

```bash
# Source and run
source scripts/configure_zsh.sh
configure_zsh

# Or run directly
./scripts/configure_zsh.sh
```

### What It Does

1. **Verifies Oh-My-Zsh** is installed
2. **Installs Powerlevel10k** to `$ZSH_CUSTOM/themes/powerlevel10k`
3. **Installs plugins**: zsh-completions, fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting
4. **Configures `.zshrc`** with theme and plugins
5. **Creates default `.p10k.zsh`** with instant prompt
6. **Applies performance optimizations** (compilation, lazy loading)
7. **Adds update aliases**

---

## Performance Targets

| Metric | Target | Implementation |
|--------|--------|----------------|
| Perceived startup | <50ms | Instant prompt |
| Full initialization | ~2s | Background loading |

### Instant Prompt Configuration

Added automatically to top of `~/.zshrc`:

```bash
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```

---

## Default Configuration

The script creates `~/.p10k.zsh` with these defaults:

### Left Prompt Elements
- `dir` - Current directory
- `vcs` - Git status

### Right Prompt Elements
- `status` - Exit code
- `command_execution_time` - Command duration
- `background_jobs` - Background job indicator
- `time` - Current time

### Key Settings

```bash
typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
typeset -g POWERLEVEL9K_STATUS_OK=false  # Hide OK status
```

---

## Ghostty Font Configuration

For proper icon rendering, configure Ghostty to use a Nerd Font.

### Install MesloLGS NF

```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
fc-cache -fv
```

### Configure Ghostty

Add to `~/.config/ghostty/config`:

```
font-family = MesloLGS NF
```

Or use any other Nerd Font already configured in your Ghostty setup.

---

## Customization

### Run Interactive Wizard

For personalized configuration beyond the defaults:

```bash
p10k configure
```

### Manual Editing

Edit `~/.p10k.zsh` directly, then reload:

```bash
p10k reload
# Or
source ~/.zshrc
```

### Add More Segments

Edit the prompt element arrays in `~/.p10k.zsh`:

```bash
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon         # OS logo
    dir             # Current directory
    vcs             # Git status
    virtualenv      # Python virtual environment
    node_version    # Node.js version
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status
    command_execution_time
    aws             # AWS profile
    kubecontext     # Kubernetes context
    time
)
```

---

## Verification

### Check Installation

```bash
source scripts/configure_zsh.sh
verify_zsh_configuration
```

### Expected Output

```
[SUCCESS] ZSH installed: zsh 5.9
[SUCCESS] Oh-My-Zsh installed
[SUCCESS] Powerlevel10k theme installed
[SUCCESS] .p10k.zsh configuration exists
[SUCCESS] Instant prompt configured
```

### Measure Startup Time

```bash
time zsh -i -c exit
```

---

## Updating

### Update Powerlevel10k

```bash
# Via the script
source scripts/configure_zsh.sh
install_powerlevel10k_theme

# Or manually
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull
```

### Update All (Daily Updates)

```bash
update-all  # Alias configured by the script
```

---

## Troubleshooting

### Icons Not Displaying

1. Ensure Nerd Font is installed
2. Configure Ghostty to use the font
3. Restart terminal

### Slow Startup

1. Verify instant prompt is configured in `.zshrc`
2. Check for slow plugins (nvm, pyenv without lazy loading)
3. Run `p10k configure` and enable instant prompt

### Git Status Slow in Large Repos

The `gitstatusd` binary handles this automatically. If issues persist:

```bash
# Check gitstatusd is working
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k/gitstatus status
```

---

## Related Files

| File | Purpose |
|------|---------|
| `scripts/configure_zsh.sh` | Main configuration script |
| `~/.zshrc` | Zsh configuration |
| `~/.p10k.zsh` | Powerlevel10k configuration |
| `~/.config/ghostty/config` | Ghostty terminal config |

---

*Part of the [ghostty-config-files](https://github.com/yourusername/ghostty-config-files) project.*
