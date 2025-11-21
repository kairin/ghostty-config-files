#!/usr/bin/env bash
set -euo pipefail
if [ -z "${REPO_ROOT:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../../init.sh"
fi

export AI_TOOLS=(
    "@anthropic-ai/claude-code"
    "@google/gemini-cli"
    "@githubnext/github-copilot-cli"
)

verify_nodejs_available() { command_exists "node" && command_exists "npm"; }
verify_claude_cli() { command_exists "claude" && claude --version &>/dev/null; }
verify_gemini_cli() { command_exists "gemini" && gemini --version &>/dev/null; }
verify_copilot_cli() { command_exists "github-copilot-cli" && github-copilot-cli --version &>/dev/null; }
verify_all_ai_tools() { verify_claude_cli && verify_gemini_cli && verify_copilot_cli; }

export -f verify_nodejs_available verify_claude_cli verify_gemini_cli verify_copilot_cli verify_all_ai_tools
