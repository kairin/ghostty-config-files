# Data Model: Advanced Terminal Productivity Suite

## Overview

This document defines the data structures, configuration schemas, and information flow for Feature 002: Advanced Terminal Productivity Suite.

## 🏗️ Core Data Entities

### 1. AI Provider Configuration

```yaml
# ~/.config/terminal-ai/providers.conf
[provider_name]
endpoint: "cli" | "api" | "local"
models: ["model1", "model2", ...]
enabled: boolean
priority: integer (1-10)
max_tokens: integer
temperature: float (0.0-1.0)
timeout: float (seconds)
cli_command: string
auth_method: "cli_login" | "api_key" | "none"
```

**Example**:
```ini
[openai]
endpoint=cli
models=gpt-4,gpt-3.5-turbo,gpt-4o-mini
enabled=true
priority=1
max_tokens=150
temperature=0.3
timeout=0.5
cli_command=openai
auth_method=cli_login
```

### 2. Privacy Consent Configuration

```yaml
# ~/.config/terminal-ai/consent.conf
ai_assistance: boolean
ai_assistance_date: ISO8601 timestamp
history_analysis: boolean
history_analysis_date: ISO8601 timestamp
context_transmission: boolean
context_transmission_date: ISO8601 timestamp
data_retention_days: integer
privacy_level: "strict" | "balanced" | "permissive"
explicit_consent_required: boolean
```

### 3. Context Information Schema

```json
{
  "timestamp": "2025-09-21T10:30:00Z",
  "session_id": "uuid",
  "context": {
    "directory": {
      "current": "/path/to/current/directory",
      "type": "git_repo" | "project" | "home" | "system",
      "permissions": ["read", "write", "execute"]
    },
    "git": {
      "repository": "repo_name",
      "branch": "branch_name",
      "status": "clean" | "dirty" | "ahead" | "behind",
      "remote": "origin_url"
    },
    "environment": {
      "shell": "zsh" | "bash" | "fish",
      "python_env": "venv_name" | null,
      "node_env": "node_version" | null,
      "docker_context": "context_name" | null
    },
    "user": {
      "working_hours": "09:00-17:00",
      "timezone": "UTC+offset",
      "privacy_level": "strict" | "balanced" | "permissive"
    }
  },
  "command_history": [
    {
      "command": "git status",
      "timestamp": "2025-09-21T10:29:45Z",
      "exit_code": 0,
      "context_hash": "sha256"
    }
  ]
}
```

### 4. Performance Metrics Schema

```json
{
  "timestamp": "2025-09-21T10:30:00Z",
  "metrics": {
    "startup_time": {
      "total_ms": 45,
      "plugin_load_ms": 12,
      "theme_load_ms": 8,
      "ai_init_ms": 5
    },
    "memory_usage": {
      "shell_mb": 15,
      "plugins_mb": 25,
      "ai_cache_mb": 10,
      "total_mb": 50
    },
    "ai_performance": {
      "provider": "openai",
      "response_time_ms": 250,
      "fallback_used": false,
      "cache_hit": true
    },
    "constitutional_compliance": {
      "score": 99.8,
      "foundation_preserved": true,
      "performance_targets_met": true,
      "privacy_compliant": true
    }
  }
}
```

### 5. Local Fallback Pattern Schema

```json
{
  "patterns": [
    {
      "trigger": "git",
      "context": "git_repo",
      "suggestions": [
        "git status",
        "git add .",
        "git commit -m \"message\"",
        "git push"
      ],
      "confidence": 0.95
    },
    {
      "trigger": "find",
      "context": "any",
      "suggestions": [
        "find . -name \"*.py\"",
        "find . -type f -size +1M",
        "find . -mtime -1"
      ],
      "confidence": 0.85
    }
  ]
}
```

## 🔄 Data Flow Architecture

### 1. Command Suggestion Flow

```
User Input → Context Engine → Provider Selection → AI Query/Local Fallback → Response → User
     ↓              ↓              ↓                ↓                    ↓         ↓
Privacy Check → History Analysis → Consent Check → Performance Monitor → Cache → Audit Log
```

### 2. Performance Monitoring Flow

```
Shell Startup → Metric Collection → Constitutional Validation → Alert System → Dashboard
      ↓               ↓                    ↓                     ↓            ↓
  Timestamp → Performance Schema → Compliance Score → Notifications → Reports
```

### 3. Privacy Protection Flow

```
User Action → Consent Check → Data Sanitization → Local Processing → Secure Storage
     ↓             ↓              ↓                   ↓               ↓
Audit Trail → Privacy Level → Context Filtering → AI Processing → Encrypted Cache
```

## 📁 File System Organization

### Configuration Directory Structure
```
~/.config/terminal-ai/
├── providers.conf              # AI provider configurations
├── consent.conf               # Privacy consent settings
├── performance-config.json    # Performance monitoring config
├── cli-auth-setup.md         # CLI authentication guide
├── keys/                     # Encrypted API keys (if used)
│   ├── openai.age
│   ├── anthropic.age
│   └── google.age
├── logs/                     # Performance and audit logs
│   ├── performance-TIMESTAMP.json
│   ├── audit-TIMESTAMP.log
│   └── errors.log
├── cache/                    # Local response cache
│   ├── ai-responses.db
│   ├── context-cache.json
│   └── patterns.json
└── secrets/                  # Team collaboration secrets
    ├── team-keys.age
    └── shared-config.enc
```

### Plugin Directory Structure
```
~/.oh-my-zsh/custom/plugins/zsh-codex/
├── zsh-codex.plugin.zsh      # Main plugin file
├── multi-provider.zsh        # AI provider integration
├── context-engine.zsh        # Context awareness
├── local-fallback.zsh        # Local pattern matching
├── error-handling.zsh        # Error management
├── performance-hooks.zsh     # Performance monitoring
└── team-sync.zsh            # Team collaboration
```

## 🔍 Data Validation Rules

### 1. Configuration Validation
- Provider priorities must be unique integers (1-10)
- Timeout values must be positive floats
- Model names must match provider specifications
- CLI commands must be valid executable names

### 2. Privacy Validation
- Consent timestamps must be valid ISO8601
- Privacy levels must be predefined values
- Data retention days must be positive integers
- Explicit consent required for data transmission

### 3. Performance Validation
- Startup time must be < 50ms (constitutional requirement)
- Memory usage must be < 150MB (constitutional requirement)
- AI response time must be < 500ms or fallback
- Constitutional compliance score must be ≥ 99.6%

## 🔒 Security Considerations

### 1. Data Encryption
- API keys encrypted with age encryption
- Team secrets encrypted with shared keys
- Local cache encrypted at rest
- Audit logs tamper-proof with checksums

### 2. Privacy Protection
- Context data sanitized before AI transmission
- Personal information filtered out
- Command history anonymized
- User patterns kept local unless explicit consent

### 3. Access Control
- Configuration files protected with 600 permissions
- Plugin files executable only by owner
- Logs readable only by user
- Cache directories protected from other users

## 📊 Monitoring and Analytics

### 1. Performance Metrics
- Shell startup time tracking
- Memory footprint monitoring
- AI response time measurement
- Cache hit rate analysis

### 2. Usage Analytics
- Command suggestion accuracy
- Provider selection frequency
- Fallback usage patterns
- User productivity improvements

### 3. Constitutional Compliance
- Foundation preservation verification
- Performance target monitoring
- Privacy compliance auditing
- Team feature adoption tracking

## 📦 Installation & Dependency Management

### 1. Installation Tracking Schema

```json
{
  "installation_registry": {
    "tools": [
      {
        "name": "powerlevel10k",
        "version": "1.19.0",
        "installation_method": "git_clone",
        "source_url": "https://github.com/romkatv/powerlevel10k.git",
        "installed_path": "~/.oh-my-zsh/custom/themes/powerlevel10k",
        "installed_date": "2025-09-21T10:30:00Z",
        "dependencies": ["zsh", "oh-my-zsh"],
        "update_command": "git pull",
        "health_check": "test -f ~/.oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme"
      },
      {
        "name": "age",
        "version": "1.1.1",
        "installation_method": "binary_download",
        "source_url": "https://github.com/FiloSottile/age/releases/latest",
        "installed_path": "~/.local/bin/age",
        "installed_date": "2025-09-21T10:25:00Z",
        "update_command": "curl -sSL latest_release | tar -xz && cp age ~/.local/bin/",
        "health_check": "age --version"
      }
    ],
    "python_environments": [
      {
        "name": "terminal-ai",
        "python_version": "3.12",
        "uv_version": "0.4.0",
        "venv_path": "~/.local/share/uv/envs/terminal-ai",
        "created_date": "2025-09-21T10:20:00Z",
        "packages": [
          {
            "name": "anthropic",
            "version": "0.7.8",
            "installed_via": "uv"
          },
          {
            "name": "openai",
            "version": "1.3.0",
            "installed_via": "uv"
          }
        ]
      }
    ]
  }
}
```

### 2. uv-First Python Management Schema

```yaml
# ~/.config/terminal-ai/python-config.yaml
python_management:
  strategy: "uv_first"
  system_python: "/usr/bin/python3.12"  # Ubuntu 25.10 system Python
  uv_binary: "~/.local/bin/uv"
  default_python: "3.12"

environments:
  terminal-ai:
    description: "AI tools and terminal productivity"
    python_version: "3.12"
    packages:
      - "anthropic>=0.7.0"
      - "openai>=1.0.0"
      - "google-generativeai>=0.3.0"
      - "pydantic>=2.0.0"
      - "rich>=13.0.0"

  development:
    description: "Development tools and utilities"
    python_version: "3.12"
    packages:
      - "black"
      - "ruff"
      - "mypy"
      - "pytest"

update_policy:
  auto_update: false
  check_frequency: "weekly"
  update_confirmation: true
  backup_before_update: true
```

### 3. Dependency Resolution Schema

```json
{
  "dependency_graph": {
    "powerlevel10k": {
      "direct_deps": ["zsh", "oh-my-zsh"],
      "optional_deps": ["nerd-fonts"],
      "conflicts": ["starship"],
      "update_strategy": "git_pull"
    },
    "starship": {
      "direct_deps": ["rust", "cargo"],
      "optional_deps": ["nerd-fonts"],
      "conflicts": ["powerlevel10k"],
      "update_strategy": "cargo_install"
    },
    "zsh-codex": {
      "direct_deps": ["zsh", "oh-my-zsh"],
      "python_deps": ["anthropic", "openai"],
      "update_strategy": "git_pull_and_uv_sync"
    }
  }
}
```

### 4. Update Management Schema

```json
{
  "update_manifest": {
    "last_check": "2025-09-21T10:30:00Z",
    "update_available": [
      {
        "tool": "powerlevel10k",
        "current_version": "1.19.0",
        "latest_version": "1.20.0",
        "update_type": "minor",
        "breaking_changes": false,
        "update_command": "cd ~/.oh-my-zsh/custom/themes/powerlevel10k && git pull",
        "estimated_time": "30s"
      }
    ],
    "python_updates": [
      {
        "environment": "terminal-ai",
        "outdated_packages": [
          {
            "name": "anthropic",
            "current": "0.7.8",
            "latest": "0.8.0",
            "update_command": "uv pip install --upgrade anthropic"
          }
        ]
      }
    ]
  }
}
```

## 🔧 Installation Method Detection

### 1. Method Detection Rules

```bash
# Installation method detection logic
detect_installation_method() {
    local tool="$1"
    local path="$2"

    if [[ -d "$path/.git" ]]; then
        echo "git_clone"
    elif which "$tool" &>/dev/null && command -v "$tool" | grep -q "/.local/bin/"; then
        echo "binary_download"
    elif which "$tool" &>/dev/null && command -v "$tool" | grep -q "/usr/bin/"; then
        echo "system_package"
    elif pip show "$tool" &>/dev/null 2>&1; then
        echo "pip_install"
    elif uv pip show "$tool" &>/dev/null 2>&1; then
        echo "uv_install"
    elif cargo install --list | grep -q "$tool"; then
        echo "cargo_install"
    else
        echo "unknown"
    fi
}
```

### 2. Update Strategy Mapping

```yaml
update_strategies:
  git_clone:
    command: "git pull"
    pre_check: "git fetch --dry-run"
    rollback: "git reset --hard HEAD~1"

  binary_download:
    command: "download_latest_binary"
    pre_check: "curl -I ${source_url}"
    rollback: "restore_backup_binary"

  system_package:
    command: "sudo apt update && sudo apt upgrade ${package_name}"
    pre_check: "apt list --upgradable | grep ${package_name}"
    rollback: "sudo apt install ${package_name}=${previous_version}"

  uv_install:
    command: "uv pip install --upgrade ${package_name}"
    pre_check: "uv pip list --outdated | grep ${package_name}"
    rollback: "uv pip install ${package_name}==${previous_version}"

  cargo_install:
    command: "cargo install --force ${package_name}"
    pre_check: "cargo search ${package_name}"
    rollback: "cargo install --force ${package_name} --version ${previous_version}"
```

## 🐍 uv-First Python Management

### 1. Python Environment Configuration

```bash
# ~/.config/terminal-ai/python-setup.sh

# Constitutional requirement: uv-first Python management
setup_python_environment() {
    echo "🐍 Setting up uv-first Python environment for Ubuntu 25.10"

    # Ensure system Python 3.12 is available
    if ! command -v python3.12 &>/dev/null; then
        echo "❌ Python 3.12 not found. Installing via system package manager..."
        sudo apt update && sudo apt install -y python3.12 python3.12-venv python3.12-dev
    fi

    # Install uv if not present
    if ! command -v uv &>/dev/null; then
        echo "📦 Installing uv Python package manager..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Create terminal-ai environment using system Python
    echo "🔧 Creating terminal-ai environment with system Python 3.12..."
    uv venv terminal-ai --python python3.12 --system-site-packages

    # Activate and install packages
    source ~/.local/share/uv/envs/terminal-ai/bin/activate
    uv pip install --upgrade pip
    uv pip install -r ~/.config/terminal-ai/requirements.txt
}
```

### 2. Dependency Installation Rules

```yaml
# ~/.config/terminal-ai/installation-rules.yaml
python_installation_rules:
  - name: "uv_mandatory"
    description: "All Python dependencies MUST use uv"
    rule: "if python_package: use uv pip install"
    enforcement: "strict"

  - name: "system_python_base"
    description: "Use Ubuntu 25.10 system Python 3.12 as base"
    rule: "uv venv --python python3.12 --system-site-packages"
    enforcement: "mandatory"

  - name: "virtual_env_isolation"
    description: "Each feature gets its own virtual environment"
    rule: "uv venv {feature-name} --python python3.12"
    enforcement: "recommended"

  - name: "requirements_tracking"
    description: "Track all dependencies in requirements files"
    rule: "uv pip freeze > requirements.txt after install"
    enforcement: "mandatory"

installation_methods_priority:
  python_packages:
    1: "uv pip install"
    2: "pip install (fallback only)"
    3: "system package (only for system tools)"

  system_tools:
    1: "system package manager (apt)"
    2: "binary download to ~/.local/bin"
    3: "cargo install (for Rust tools)"
    4: "git clone + manual install"
```

## 🚀 Scalability Considerations

### 1. Cache Management
- LRU eviction for response cache
- Compressed storage for patterns
- Distributed cache for team features
- Periodic cleanup of old data

### 2. Provider Management
- Dynamic provider addition/removal
- Load balancing across providers
- Failover and circuit breaker patterns
- Rate limiting and quota management

### 3. Team Collaboration
- Hierarchical configuration inheritance
- Conflict resolution for shared settings
- Version control for team templates
- Audit trails for configuration changes

### 4. Installation & Update Management
- Automated dependency tracking and resolution
- uv-first Python environment management
- Installation method detection and optimization
- Rollback capabilities for failed updates
- Constitutional compliance validation post-update

---

This data model ensures the Advanced Terminal Productivity Suite maintains constitutional compliance while providing robust, scalable, and privacy-conscious AI-powered terminal assistance with comprehensive installation tracking and uv-first Python dependency management.