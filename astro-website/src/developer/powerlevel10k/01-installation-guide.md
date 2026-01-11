# Powerlevel10k Installation Guide

> Technical Deployment and Customization Roadmap

## Prerequisites

### Zsh Version
- **Required**: Zsh 5.1 or higher
- **Verify**: `zsh --version`

### Recommended Font
The **MesloLGS NF** (Nerd Font patched for P10k) is highly recommended for correct rendering of icons and Powerline glyphs.

```bash
# Install MesloLGS NF fonts
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
curl -fLO https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
fc-cache -fv
```

### Terminal Emulator
Must support custom fonts. Recommended:
- **Linux**: GNOME Terminal, Ghostty
- **macOS**: iTerm2
- **Windows/WSL**: Windows Terminal

---

## Installation Methods

### Standard Manual Installation

Preferred for users who manage `.zshrc` manually or use minimal setups.

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
```

### Framework-Specific Installation

| Framework | Installation |
|-----------|--------------|
| **Oh My Zsh** | Clone to `$ZSH_CUSTOM/themes/powerlevel10k`. Set `ZSH_THEME="powerlevel10k/powerlevel10k"` in `~/.zshrc` |
| **Prezto** | Add `zstyle :prezto:module:prompt theme powerlevel10k` to `~/.zpreztorc` |
| **Antigen** | Add `antigen theme romkatv/powerlevel10k` to `~/.zshrc` |
| **Zinit/Zplugin** | Use `zinit ice depth=1; zinit light romkatv/powerlevel10k` |
| **Homebrew** | `brew install powerlevel10k` then source the theme |

#### Oh My Zsh (Detailed)

```bash
# Clone to Oh My Zsh custom themes
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Edit ~/.zshrc - change the ZSH_THEME line:
ZSH_THEME="powerlevel10k/powerlevel10k"

# Apply changes
source ~/.zshrc
```

---

## Interactive Configuration

Upon first run (or by executing `p10k configure`), the interactive wizard generates a `~/.p10k.zsh` configuration file.

### Prompt Styles
- **Lean**: Minimalist
- **Classic**: Traditional powerline
- **Rainbow**: High contrast
- **Pure**: Minimalist emulation

### Technical Features
- **Instant Prompt**: Removes shell startup lag
- **Transient Prompt**: Trims previous prompt to save screen space

---

## Manual Configuration

Advanced customization via `~/.p10k.zsh`:

### Segment Management

```bash
# In ~/.p10k.zsh
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs virtualenv)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status battery time)
```

### Visual Styling

| Customization | Variable Example |
|---------------|------------------|
| Change Dir Color | `typeset -g POWERLEVEL9K_DIR_FOREGROUND=33` |
| Custom Git Icon | `typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uE0A0 '` |
| Hide Hostname | `typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=''` |
| Time Format | `typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'` |

### Pure Style Emulation

1. Run `p10k configure` and select Pure style
2. Note: P10k uses its own variable names (e.g., `POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3`)

---

## Updating Powerlevel10k

```bash
# If installed via git clone
git -C ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k pull

# If installed via Homebrew
brew upgrade powerlevel10k
```

---

## Project-Specific Note

This project provides automated installation via `scripts/configure_zsh.sh`:

```bash
source scripts/configure_zsh.sh
configure_zsh
```

See [Project Usage](04-ghostty-config-usage.md) for details.

---

*Source: [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k)*
