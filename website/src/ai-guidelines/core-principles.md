---
title: "Core Principles"
description: "AI assistant guidelines for core-principles"
pubDate: 2025-10-27
author: "AI Integration Team"
tags: ["ai", "guidelines"]
targetAudience: "all"
constitutional: true
---


> **Note**: This is a modular extract from [AGENTS.md](../../AGENTS.md) for documentation purposes. AGENTS.md remains the single source of truth.

## Project Overview

**Ghostty Configuration Files** is a comprehensive terminal environment setup featuring Ghostty terminal emulator with 2025 performance optimizations, right-click context menu integration, plus integrated AI tools (Claude Code, Gemini CLI) and intelligent update management.

## Non-Negotiable Requirements

### Ghostty Performance & Optimization (2025)
- **Linux CGroup Single-Instance**: MANDATORY for performance (`linux-cgroup = single-instance`)
- **Enhanced Shell Integration**: Auto-detection with advanced features
- **Memory Management**: Optimized scrollback limits and process controls
- **Auto Theme Switching**: Light/dark mode support with Catppuccin themes
- **Security Features**: Clipboard paste protection enabled

### Package Management & Dependencies
- **Ghostty**: Built from source with Zig 0.14.0 (latest stable)
- **ZSH**: Oh My ZSH with enhanced plugins for productivity
- **Node.js**: Latest version (v25.2.0+) via fnm (Fast Node Manager) for AI tool integration
- **Dependencies**: Smart detection and minimal installation footprint

### GitHub Pages Infrastructure
- **`.nojekyll` File**: ABSOLUTELY CRITICAL for GitHub Pages deployment
- **Location**: `docs/.nojekyll` (empty file, no content needed)
- **Purpose**: Disables Jekyll processing to allow `_astro/` directory assets
- **Impact**: Without this file, ALL CSS/JS assets return 404 errors
- **WARNING**: This file is ESSENTIAL - never remove during cleanup operations

#### Jekyll Cleanup Protection

```bash
# BEFORE removing ANY Jekyll-related files, verify this file exists:
ls -la docs/.nojekyll

# If missing, recreate immediately:
touch docs/.nojekyll
git add docs/.nojekyll
git commit -m "CRITICAL: Restore .nojekyll for GitHub Pages asset loading"
```

## Absolute Prohibitions

### DO NOT
- **NEVER REMOVE `docs/.nojekyll`** - This breaks ALL CSS/JS loading on GitHub Pages
- Delete branches without explicit user permission
- Use GitHub Actions for anything that consumes minutes
- Skip local CI/CD validation before GitHub deployment
- Ignore existing user customizations during updates
- Apply configuration changes without backup
- Commit sensitive data (API keys, passwords, personal information)
- Bypass the intelligent update system for configuration changes
- Remove Jekyll-related files without verifying `.nojekyll` preservation

### DO NOT BYPASS
- Branch preservation requirements
- Local CI/CD execution requirements
- Zero-cost operation constraints
- Configuration validation steps
- User customization preservation
- Logging and debugging requirements

## Mandatory Actions

### Before Every Configuration Change
1. **Local CI/CD Execution**: Run `./.runners-local/workflows/gh-workflow-local.sh all`
2. **Configuration Validation**: Run `ghostty +show-config` to ensure validity
3. **Performance Testing**: Execute `./.runners-local/workflows/performance-monitor.sh`
4. **Backup Creation**: Automatic timestamped backup of existing configuration
5. **User Preservation**: Extract and preserve user customizations
6. **Documentation**: Update relevant docs if adding features
7. **Conversation Log**: Save complete AI conversation log with system state

### Quality Gates
- Local CI/CD workflows execute successfully
- Configuration validates without errors via `ghostty +show-config`
- All 2025 performance optimizations are present and functional
- User customizations are preserved and functional
- Context menu integration works correctly
- GitHub Actions usage remains within free tier limits
- All logging systems capture complete information

## Success Criteria

### Performance Metrics (2025)
- **Startup Time**: <500ms for new Ghostty instance (CGroup optimization)
- **Memory Usage**: <100MB baseline with optimized scrollback management
- **Shell Integration**: 100% feature detection and activation
- **Theme Switching**: Instant response to system light/dark mode changes
- **CI/CD Performance**: <2 minutes for complete local workflow execution

### User Experience Metrics
- **One-Command Setup**: Fresh Ubuntu system fully configured in <10 minutes
- **Context Menu**: "Open in Ghostty" available immediately after installation
- **Update Efficiency**: Only necessary components updated, no full reinstalls
- **Customization Preservation**: 100% user setting retention during updates
- **Zero-Cost Operation**: No GitHub Actions minutes consumed for routine operations

### Technical Metrics
- **Configuration Validity**: 100% successful validation rate
- **Update Success**: >99% successful intelligent update application
- **Error Recovery**: Automatic rollback on configuration failures
- **Logging Coverage**: Complete system state capture for all operations
- **CI/CD Success**: >99% local workflow execution success rate

## LLM Conversation Logging

**CRITICAL REQUIREMENT**: All AI assistants working on this repository **MUST** save complete conversation logs and maintain debugging information.

### Requirements
- **Complete Logs**: Save entire conversation from start to finish
- **Exclude Sensitive Data**: Remove API keys, passwords, personal information
- **Storage Location**: `documentations/development/conversation_logs/`
- **Naming Convention**: `CONVERSATION_LOG_YYYYMMDD_DESCRIPTION.md`
- **System State**: Capture before/after system states for debugging
- **CI/CD Logs**: Include local workflow execution logs

### Example Workflow
```bash
# After completing work, save conversation log and system state
mkdir -p documentations/development/conversation_logs/
cp /path/to/conversation.md documentations/development/conversation_logs/CONVERSATION_LOG_20250919_local_cicd_setup.md

# Capture system state and CI/CD logs
cp /tmp/ghostty-start-logs/system_state_*.json documentations/development/system_states/
cp ./.runners-local/logs/* documentations/development/ci_cd_logs/

git add documentations/development/
git commit -m "Add conversation log, system state, and CI/CD logs for local infrastructure setup"
```
