#!/bin/bash
# T001: Validate Oh My ZSH essential plugin trinity operational
set -euo pipefail

echo "🧪 T001: Testing Oh My ZSH Essential Plugin Trinity"

# Test zsh-autosuggestions
if [[ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
    echo "✅ zsh-autosuggestions plugin directory exists"
else
    echo "❌ zsh-autosuggestions plugin missing"
    exit 1
fi

# Test zsh-syntax-highlighting
if [[ -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]; then
    echo "✅ zsh-syntax-highlighting plugin directory exists"
else
    echo "❌ zsh-syntax-highlighting plugin missing"
    exit 1
fi

# Test you-should-use
if [[ -d ~/.oh-my-zsh/custom/plugins/you-should-use ]]; then
    echo "✅ you-should-use plugin directory exists"
else
    echo "❌ you-should-use plugin missing"
    exit 1
fi

# Test plugins are configured in .zshrc
if grep -q "zsh-autosuggestions" ~/.zshrc; then
    echo "✅ zsh-autosuggestions configured in .zshrc"
else
    echo "⚠️ zsh-autosuggestions not found in .zshrc configuration"
fi

if grep -q "zsh-syntax-highlighting" ~/.zshrc; then
    echo "✅ zsh-syntax-highlighting configured in .zshrc"
else
    echo "⚠️ zsh-syntax-highlighting not found in .zshrc configuration"
fi

if grep -q "you-should-use" ~/.zshrc; then
    echo "✅ you-should-use configured in .zshrc"
else
    echo "⚠️ you-should-use not found in .zshrc configuration"
fi

# Test ZSH can load without errors
if zsh -c 'source ~/.zshrc' &>/dev/null; then
    echo "✅ ZSH loads successfully with current configuration"
else
    echo "❌ ZSH configuration has errors"
    exit 1
fi

echo "🎯 T001: Oh My ZSH Essential Plugin Trinity validation PASSED"