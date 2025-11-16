# Quick Start: Advanced Terminal Productivity Suite

## 🚀 5-Minute Setup

Get started with Feature 002: Advanced Terminal Productivity in just 5 minutes.

### Prerequisites
- Ubuntu 22.04+ or compatible Linux distribution
- Existing ghostty-config-files setup
- Internet connection for AI CLI tools setup

### Step 1: Enable Advanced Terminal Features
```bash
cd /home/kkk/Apps/ghostty-config-files

# Run Phase 1 foundation validation
./tests/advanced-terminal/test_foundation_preservation.sh
./tests/advanced-terminal/test_modern_tools.sh
./tests/advanced-terminal/test_constitutional_compliance.sh
```

### Step 2: Configure AI Integration
```bash
# Setup CLI authentication (recommended)
cat ~/.config/terminal-ai/cli-auth-setup.md

# Verify AI providers are configured
cat ~/.config/terminal-ai/providers.conf
```

### Step 3: Test AI Command Assistance
```bash
# Load the zsh-codex plugin
source ~/.oh-my-zsh/custom/plugins/zsh-codex/multi-provider.zsh

# Test AI assistance (Ctrl+X then Ctrl+A)
# Type a command description and get AI suggestions
```

### Step 4: Enable Performance Monitoring
```bash
# Check startup performance
time zsh -c exit

# View performance logs
ls ~/.config/terminal-ai/logs/
```

## 📋 Quick Verification Checklist

- [ ] Foundation tests pass (Oh My ZSH, modern tools, compliance)
- [ ] AI providers configured (OpenAI, Claude, Gemini CLI)
- [ ] zsh-codex plugin loaded and functional
- [ ] Performance monitoring active
- [ ] Context awareness working
- [ ] Local fallback system operational

## 🎯 Next Steps

### For Immediate Productivity
1. **AI Command Assistance**: Start using Ctrl+X Ctrl+A for command suggestions
2. **Context Awareness**: Commands adapt based on current directory/git repo
3. **Performance Monitoring**: Check startup times stay under 50ms

### For Advanced Setup (Phase 2+)
1. **Advanced Theming**: Install Powerlevel10k or Starship
2. **Performance Optimization**: Enable intelligent caching
3. **Team Collaboration**: Setup chezmoi for configuration sharing

## 🆘 Troubleshooting

### AI Integration Not Working
```bash
# Check CLI authentication
openai --version
claude --version
gemini --version

# Verify consent settings
cat ~/.config/terminal-ai/consent.conf
```

### Performance Issues
```bash
# Check startup time
~/.config/terminal-ai/performance-monitor.sh --baseline

# Review performance logs
tail ~/.config/terminal-ai/logs/performance-*.json
```

### Plugin Loading Issues
```bash
# Verify plugin structure
ls ~/.oh-my-zsh/custom/plugins/zsh-codex/

# Check ZSH configuration
grep -n "zsh-codex" ~/.zshrc
```

## 📊 Expected Performance

### Baseline Metrics (Post-Setup)
- **Shell Startup**: <50ms (target achieved)
- **AI Response Time**: <500ms or local fallback
- **Memory Usage**: <150MB additional footprint
- **Command Lookup Reduction**: 30-50% fewer manual lookups

### Constitutional Compliance
- **Foundation Preservation**: 100% existing functionality maintained
- **Privacy Protection**: All AI features require explicit consent
- **Performance Targets**: Constitutional requirements met
- **Local Fallback**: Always available when AI unavailable

## 🔧 Configuration Files Overview

### Primary Configurations
- `~/.config/terminal-ai/providers.conf` - AI provider settings
- `~/.config/terminal-ai/consent.conf` - Privacy consent settings
- `~/.oh-my-zsh/custom/plugins/zsh-codex/` - AI integration plugin

### Monitoring & Logs
- `~/.config/terminal-ai/logs/` - Performance and usage logs
- `/tmp/ghostty-start-logs/` - System startup logs
- `~/.config/terminal-ai/performance-monitor.sh` - Performance tracking

## 🎁 Bonus Tips

### Keyboard Shortcuts
- `Ctrl+X Ctrl+A` - Get AI command suggestion
- `Ctrl+X Ctrl+L` - Use local fallback only
- `Ctrl+X Ctrl+H` - Show command history analysis

### Productivity Boosters
1. **Context-Aware Commands**: AI understands your current directory context
2. **Git Integration**: Commands adapt to repository state
3. **History Learning**: System learns from your command patterns
4. **Multi-Provider Fallback**: Always get suggestions even if one AI fails

### Team Features (Coming in Phase 4)
- Shared configuration templates
- Team learning from command patterns
- Encrypted secret management
- Multi-environment synchronization

---

🎯 **Success Goal**: Reduce manual command lookup by 30-50% while maintaining <50ms shell startup time.

📚 **Next Reading**: [Full Specification](spec.md) | [Implementation Plan](plan.md) | [Task Breakdown](tasks.md)