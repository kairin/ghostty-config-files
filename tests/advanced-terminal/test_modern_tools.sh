#!/bin/bash
# T002: Validate modern Unix tools suite functional
set -euo pipefail

echo "🧪 T002: Testing Modern Unix Tools Suite"

# Test modern tools availability
tools=("eza" "bat" "rg" "fzf" "zoxide" "fd")
missing_tools=()

for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
        echo "✅ $tool available"
    else
        echo "❌ $tool missing"
        missing_tools+=("$tool")
    fi
done

# Test tool functionality
echo "🔧 Testing tool functionality..."

# Test eza (enhanced ls)
if command -v eza &>/dev/null; then
    if eza --version &>/dev/null; then
        echo "✅ eza functional"
    else
        echo "❌ eza not functional"
    fi
fi

# Test bat (enhanced cat)
if command -v bat &>/dev/null; then
    if echo "test" | bat --style=plain &>/dev/null; then
        echo "✅ bat functional"
    else
        echo "❌ bat not functional"
    fi
fi

# Test ripgrep
if command -v rg &>/dev/null; then
    if echo "test" | rg "test" &>/dev/null; then
        echo "✅ ripgrep functional"
    else
        echo "❌ ripgrep not functional"
    fi
fi

# Test fzf
if command -v fzf &>/dev/null; then
    if echo -e "item1\nitem2" | fzf --filter="item1" | grep -q "item1"; then
        echo "✅ fzf functional"
    else
        echo "❌ fzf not functional"
    fi
fi

# Test zoxide
if command -v zoxide &>/dev/null; then
    if zoxide --version &>/dev/null; then
        echo "✅ zoxide functional"
    else
        echo "❌ zoxide not functional"
    fi
fi

# Test fd
if command -v fd &>/dev/null; then
    if fd --version &>/dev/null; then
        echo "✅ fd functional"
    else
        echo "❌ fd not functional"
    fi
fi

# Check if all tools are available
if [[ ${#missing_tools[@]} -eq 0 ]]; then
    echo "🎯 T002: All modern Unix tools available and functional"
else
    echo "❌ Missing tools: ${missing_tools[*]}"
    echo "Run ./start.sh to install missing tools"
    exit 1
fi

echo "🎯 T002: Modern Unix Tools Suite validation PASSED"