# Powerlevel10k Documentation

> High-performance Zsh theme documentation for the ghostty-config-files project.

## Quick Links

| Document | Description |
|----------|-------------|
| [Installation Guide](01-installation-guide.md) | Installation methods, prerequisites, font setup |
| [Commands & API](02-commands-and-api.md) | `p10k` commands, segments, customization API |
| [Context7 Integration](03-context7-integration.md) | AI documentation indexing via MCP |
| [Project Usage](04-ghostty-config-usage.md) | How this project implements P10k |

## Quick Start

### Option 1: Use Project Script (Recommended)

```bash
# Run the project's ZSH configuration script
source scripts/configure_zsh.sh
configure_zsh
```

### Option 2: Manual Installation (Oh-My-Zsh)

```bash
# 1. Clone Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# 2. Set theme in ~/.zshrc
# ZSH_THEME="powerlevel10k/powerlevel10k"

# 3. Apply and configure
source ~/.zshrc
p10k configure
```

## Key Commands

```bash
p10k configure    # Interactive setup wizard
p10k reload       # Apply config changes without restart
p10k help         # View documentation
```

## Performance Target

- **Perceived startup**: <50ms (with instant prompt)
- **Full initialization**: ~2s (background loading)

## Official Resources

- [GitHub Repository](https://github.com/romkatv/powerlevel10k)
- [Troubleshooting](https://github.com/romkatv/powerlevel10k#troubleshooting)
- [Show Your Config](https://github.com/romkatv/powerlevel10k/blob/master/config/)

---

*Documentation sourced from official Powerlevel10k repository and project-specific implementation.*
