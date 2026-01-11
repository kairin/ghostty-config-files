# Powerlevel10k Commands & API Reference

> Comprehensive Functional Architecture

## Core Administrative Commands

### `p10k configure`
The primary interactive wizard. Performs font capability detection and generates a customized `~/.p10k.zsh` configuration file.

```bash
p10k configure
```

### `p10k help`
Built-in documentation viewer.

```bash
p10k help           # General help
p10k help segment   # Segment documentation
p10k help display   # Display API documentation
```

### `p10k reload`
Apply configuration changes without restarting the shell.

```bash
# After editing ~/.p10k.zsh
p10k reload
```

### `p10k display`
Programmatic interface for toggling segment visibility. Powers "Transient Prompt" logic.

---

## Built-in Prompt Segments

### System and Contextual Segments

| Segment | Description |
|---------|-------------|
| `os_icon` | Detects OS and renders logo (Apple, Linux, Ubuntu, Arch, etc.) |
| `dir` | Intelligent directory with unique shortening strategy (`truncate_to_unique`) |
| `prompt_char` | Final prompt symbol, changes color based on last command status |
| `status` | Numeric exit code (only shown when non-zero) |

### High-Performance Version Control (VCS)

Powered by **gitstatusd**, a C++ binary providing near-instantaneous git status.

| Indicator | Meaning |
|-----------|---------|
| Branch name | Current branch, tag, or commit hash |
| `+` | Staged changes |
| `!` | Unstaged changes |
| `?` | Untracked files |
| `*` | Stashed changes |
| `⇡` | Ahead of remote |
| `⇣` | Behind remote |

### Development Environment Segments

#### Languages
- `node_version`
- `python_version`
- `go_version`
- `rust_version`
- `ruby_version`
- `php_version`

#### Environment Managers
- `nvm`
- `pyenv`
- `virtualenv`
- `rbenv`
- `nodenv`
- `asdf`

#### Cloud/Infrastructure
- `aws` - AWS profile
- `kubecontext` - Kubernetes cluster/namespace
- `terraform` - Terraform workspace
- `docker_machine` - Docker machine status

---

## Custom Segment API

For functionality not covered by built-in modules, P10k exposes a public API.

### Function Definition Pattern

```bash
# Define in ~/.p10k.zsh
function prompt_my_custom_segment() {
  # Your logic here
  p10k segment -b blue -f white -i '⚡' -t "Custom Text"
}
```

### `p10k segment` Flags

| Flag | Purpose |
|------|---------|
| `-b` | Background color |
| `-f` | Foreground color |
| `-i` | Icon |
| `-t` | Text content |

### Segment State

Custom segments can implement state-based logic:
- `FIRST` - First segment in line
- `LAST` - Last segment in line
- `SOLO` - Only segment in line

---

## Performance Optimization Hooks

### Instant Prompt

Renders a "stub" prompt immediately while the shell loads plugins like `nvm` or `pyenv`, eliminating perceived startup lag.

```bash
# Must be near top of ~/.zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
```

### Lifecycle Hooks

| Hook | Purpose |
|------|---------|
| `p10k-on-pre-prompt` | Execute before prompt rendering |
| `p10k-on-post-prompt` | Execute after prompt rendering |
| `p10k-on-post-widget` | Update segments in response to buffer changes |

---

## Theme Emulation Modes

P10k can emulate other themes while retaining its performance advantages:

| Theme | Description |
|-------|-------------|
| **Pure** | Minimalist Pure theme layout |
| **Powerlevel9k** | 100% backward compatibility for legacy `POWERLEVEL9K_*` variables |
| **robbyrussell** | Default Oh My Zsh theme style |

---

## Configuration Variables Reference

### Prompt Structure

```bash
# Left side segments
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon
    dir
    vcs
)

# Right side segments
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status
    command_execution_time
    background_jobs
    time
)
```

### Common Settings

```bash
# Instant prompt mode (recommended)
typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose

# Transient prompt
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always

# Directory truncation
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1

# Command execution time threshold (seconds)
typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
```

---

*Source: [romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k)*
