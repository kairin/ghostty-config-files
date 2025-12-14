#!/bin/bash
# install_deps_ai_tools.sh - Install dependencies for Local AI CLI Tools
# Claude Code: uses curl (no Node.js needed)
# Gemini CLI & GitHub Copilot: require Node.js (installed via fnm)

source "$(dirname "$0")/../006-logs/logger.sh"

log "INFO" "Checking dependencies for AI CLI tools..."

# Ensure fnm environment is loaded
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd 2>/dev/null)" || true
fi

# Check if Node.js is available (required for Gemini CLI and GitHub Copilot)
if ! command -v node &> /dev/null; then
    log "ERROR" "Node.js is required but not installed."
    log "ERROR" "Please install Node.js first from the main menu."
    exit 1
fi

# Check if npm is available
if ! command -v npm &> /dev/null; then
    log "ERROR" "npm is required but not installed."
    log "ERROR" "npm should come with Node.js - please reinstall Node.js."
    exit 1
fi

# Check curl is available (required for Claude Code installer)
if ! command -v curl &> /dev/null; then
    log "ERROR" "curl is required but not installed."
    log "INFO" "Installing curl..."
    sudo apt-get update && sudo apt-get install -y curl
fi

NODE_VER=$(node -v)
NPM_VER=$(npm -v)
log "SUCCESS" "Node.js $NODE_VER available"
log "SUCCESS" "npm $NPM_VER available"
log "SUCCESS" "curl available"
log "SUCCESS" "Dependencies for AI CLI tools are ready."
