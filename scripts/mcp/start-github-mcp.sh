#!/usr/bin/env bash
# GitHub MCP Server Wrapper
# Dynamically obtains token from gh CLI and starts MCP server
# This prevents GITHUB_TOKEN from polluting shell environment

set -euo pipefail

# Get fresh token from gh CLI
GITHUB_TOKEN=$(gh auth token 2>/dev/null || echo "")

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: Unable to obtain GitHub token from 'gh auth token'" >&2
    echo "Please run: gh auth login" >&2
    exit 1
fi

# Export for MCP server process only
export GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN"

# Start GitHub MCP server
exec npx -y @modelcontextprotocol/server-github "$@"
