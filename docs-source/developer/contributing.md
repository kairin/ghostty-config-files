# Contributing Guide

Thank you for considering contributing to the Ghostty Configuration Files project!

## Quick Start

```bash
# 1. Fork the repository
# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/ghostty-config-files.git
cd ghostty-config-files

# 3. Create feature branch (use timestamp format)
DATETIME=$(date +"%Y%m%d-%H%M%S")
git checkout -b "$DATETIME-feat-your-feature"

# 4. Make changes
# ... edit files ...

# 5. Test locally
./manage.sh validate
./local-infra/runners/gh-workflow-local.sh all

# 6. Commit with attribution
git add .
git commit -m "feat: Your feature description

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Your Name <your@email.com>"

# 7. Push and create PR
git push -u origin "$DATETIME-feat-your-feature"
gh pr create
```

## Branch Strategy

- **Format**: `YYYYMMDD-HHMMSS-type-description`
- **Types**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`
- **Never delete branches** without explicit permission

## Code Standards

### Bash Scripts

- Follow ShellCheck recommendations
- Use `set -euo pipefail`
- Document all functions
- Include module header
- Write unit tests

### Configuration Files

- Validate with `ghostty +show-config`
- Preserve user customizations
- Document all changes

### Documentation

- Use Markdown format
- Follow existing structure
- Include code examples
- Test docs build

## Testing Requirements

```bash
# Run all tests
./local-infra/runners/test-runner.sh

# Run ShellCheck
shellcheck scripts/*.sh

# Validate configuration
./manage.sh validate
```

## Pull Request Process

1. **Update documentation** if needed
2. **Add tests** for new features
3. **Run local CI/CD** before pushing
4. **Create PR** with descriptive title and body
5. **Respond to feedback** promptly

## Getting Help

- Check [Architecture Guide](architecture.md)
- Review existing code patterns
- Ask questions in issues/PRs
