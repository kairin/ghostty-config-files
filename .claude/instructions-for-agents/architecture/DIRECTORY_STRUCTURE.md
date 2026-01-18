---
title: Directory Structure Reference
category: architecture
linked-from: AGENTS.md, system-architecture.md
status: ACTIVE
last-updated: 2026-01-11
---

# Directory Structure Reference

[← Back to AGENTS.md](../../../../AGENTS.md) | [System Architecture](./system-architecture.md)

## Complete File Tree

```
ghostty-config-files/
│
├── start.sh                        # Main entry point - launches Go TUI installer
├── AGENTS.md                       # AI assistant instructions (gateway document)
├── CLAUDE.md → AGENTS.md           # Symlink for Claude Code
├── GEMINI.md → AGENTS.md           # Symlink for Gemini CLI
├── README.md                       # User documentation
├── package.json                    # Node.js dependencies (for Astro website)
│
├── .mcp.json                       # MCP server configuration
├── .env.example                    # Environment variables template
├── .node-version                   # Node.js version for fnm
├── .python-version                 # Python version for uv
│
├── configs/                        # Configuration files
│   └── ghostty/                    # Ghostty terminal configuration
│       ├── config                  # Main Ghostty config
│       ├── catppuccin-mocha.conf   # Dark theme
│       ├── catppuccin-latte.conf   # Light theme
│       └── ...                     # Additional config files
│
├── scripts/                        # Utility scripts organized by function
│   ├── 000-check/                  # Pre-installation status checks
│   │   └── check_*.sh              # Tool-specific check scripts
│   │
│   ├── 001-uninstall/              # Uninstallation scripts
│   │   └── uninstall_*.sh          # Tool-specific uninstall scripts
│   │
│   ├── 002-install-first-time/     # First-time installation scripts
│   │   ├── install_deps_ghostty.sh # Ghostty installer (build-from-source)
│   │   ├── install_deps_go.sh      # Go installer
│   │   ├── install_deps_nodejs.sh  # Node.js installer (fnm)
│   │   ├── install_deps_zsh.sh     # ZSH + Oh My ZSH installer
│   │   ├── install_deps_gum.sh     # Gum TUI installer
│   │   ├── install_deps_glow.sh    # Glow markdown viewer
│   │   ├── install_deps_vhs.sh     # VHS terminal recorder
│   │   ├── install_deps_feh.sh     # Feh image viewer
│   │   ├── install_deps_fastfetch.sh # Fastfetch system info
│   │   ├── install_deps_nerdfonts.sh # Nerd Fonts installer
│   │   ├── install_deps_python_uv.sh # Python + uv installer
│   │   ├── install_deps_ai_tools.sh  # AI tools (Claude, Gemini)
│   │   └── setup_mcp_config.sh     # MCP configuration setup
│   │
│   ├── 003-verify/                 # Verification scripts
│   │   └── verify_*.sh             # Post-install verification
│   │
│   ├── 004-reinstall/              # Reinstallation scripts
│   │   └── install_ghostty.sh      # Ghostty reinstall (snap or source)
│   │
│   ├── 005-confirm/                # Confirmation utilities
│   │   └── confirm_*.sh            # Installation confirmation
│   │
│   ├── 006-logs/                   # Installation logs
│   │   ├── YYYYMMDD-HHMMSS-*.log   # Timestamped operation logs
│   │   └── artifact-definitions/   # Log artifact definitions
│   │
│   ├── 007-diagnostics/            # Boot diagnostics system
│   │   ├── boot_diagnostics.sh     # Main TUI diagnostics interface
│   │   ├── quick_scan.sh           # Quick issue count
│   │   ├── detectors/              # Issue detection modules
│   │   └── lib/                    # Diagnostics library functions
│   │
│   ├── vhs/                        # VHS recording configurations
│   │
│   ├── daily-updates.sh            # Automated daily update script (v3.0)
│   ├── check_updates.sh            # Smart update checker
│   ├── ghostty-theme-switcher.sh   # Dynamic light/dark theme switching
│   ├── configure_zsh.sh            # ZSH configuration script
│   └── DAILY_UPDATES_README.md     # Update system documentation
│
├── tui/                            # Go TUI installer (Bubbletea/Lipgloss)
│   ├── go.mod, go.sum              # Go module definitions
│   ├── installer                   # Compiled binary (~5.0MB)
│   ├── cmd/
│   │   └── installer/              # CLI entry point
│   │       └── main.go             # Main TUI application
│   └── internal/                   # Core packages
│       ├── cache/                  # Status caching (5-min TTL)
│       ├── config/                 # Configuration management
│       ├── detector/               # Tool detection logic
│       ├── diagnostics/            # Boot diagnostics integration
│       ├── executor/               # Script execution with streaming
│       ├── registry/               # Data-driven tool catalog (12 tools)
│       └── ui/                     # Bubbletea model, views, styles
│
├── astro-website/                  # Documentation website (Astro.build)
│   ├── astro.config.mjs            # Astro configuration (outDir: '../docs')
│   ├── package.json                # Website dependencies
│   ├── public/                     # Static assets
│   │   ├── video/                  # Video assets
│   │   └── ...                     # Favicon, manifest, etc.
│   └── src/
│       ├── components/             # Astro components
│       │   ├── charts/             # Chart components
│       │   ├── hero/               # Hero section
│       │   └── layout/             # Layout components
│       ├── data/                   # Data files
│       ├── developer/              # Developer documentation
│       │   └── powerlevel10k/      # PowerLevel10k integration docs
│       ├── pages/                  # Page routes
│       │   └── docs/               # Documentation pages
│       └── styles/                 # CSS styles
│
├── docs/                           # Built website (GitHub Pages OUTPUT)
│   ├── .nojekyll                   # CRITICAL - Enables _astro/ directory
│   ├── index.html                  # Built homepage
│   └── _astro/                     # Built assets (CSS, JS)
│
├── .claude/                        # Claude Code configuration
│   ├── skill-sources/              # Skill source files (4 skills)
│   │   ├── 001-health-check.md     # System health check skill
│   │   ├── 001-deploy-site.md      # Deploy website skill
│   │   ├── 001-git-sync.md         # Git synchronization skill
│   │   └── 001-full-workflow.md    # Complete workflow skill
│   ├── agent-sources/              # Agent source files (65 agents)
│   │   ├── 000-*.md                # Tier 0: Workflow orchestrators (5)
│   │   ├── 001-*.md                # Tier 1: Opus orchestrator (1)
│   │   ├── 002-*.md                # Tier 2: Domain operations (5)
│   │   ├── 003-*.md                # Tier 3: Utility/support (4)
│   │   └── 0XX-*.md                # Tier 4: Atomic execution (50)
│   └── instructions-for-agents/    # AI agent instructions
│       ├── requirements/           # Critical requirements
│       │   ├── CRITICAL-requirements.md
│       │   ├── git-strategy.md
│       │   └── local-cicd-operations.md
│       ├── architecture/           # System architecture
│       │   ├── system-architecture.md
│       │   ├── DIRECTORY_STRUCTURE.md (this file)
│       │   ├── agent-delegation.md
│       │   └── agent-registry.md
│       ├── guides/                 # Setup guides
│       │   ├── first-time-setup.md
│       │   ├── context7-mcp.md
│       │   ├── github-mcp.md
│       │   ├── LOGGING_GUIDE.md
│       │   └── troubleshooting-icons.md
│       ├── principles/             # Constitutional principles
│       │   └── script-proliferation.md
│       └── tools/                  # Tool documentation
│           └── README.md
│
│   # Note: Run ./scripts/install-claude-config.sh to install
│   # skills and agents to ~/.claude/commands/ and ~/.claude/agents/
│
├── .runners-local/                 # Local CI/CD infrastructure
│   └── workflows/                  # Local workflow scripts
│       └── gh-workflow-local.sh    # GitHub Actions local simulation
│
├── logs/                           # Update logs and manifests
│   └── manifests/                  # Tool version manifests (JSON)
│
├── machines/                       # Machine-specific configurations
│
├── tests/                          # Test infrastructure
│
├── .github/                        # GitHub configuration
│   └── CONTRIBUTING.md             # Contributing guidelines
│
└── .gemini/                        # Gemini CLI configuration
```

## Key Directories

### Scripts Organization (`scripts/`)

Scripts are organized numerically by operation phase:

| Directory | Phase | Purpose |
|-----------|-------|---------|
| `000-check/` | Pre-install | Check if tools are installed |
| `001-uninstall/` | Cleanup | Remove existing installations |
| `002-install-first-time/` | Install | Fresh installation scripts |
| `003-verify/` | Validate | Verify installation success |
| `004-reinstall/` | Update | Reinstall/upgrade scripts |
| `005-confirm/` | Confirm | User confirmation prompts |
| `006-logs/` | Logging | Installation logs |
| `007-diagnostics/` | Health | Boot diagnostics system |

### Documentation Hierarchy

```
User Documentation:
├── README.md                       # Entry point for users
├── scripts/DAILY_UPDATES_README.md # Update system docs
└── astro-website/src/              # Astro source files
    └── developer/powerlevel10k/    # PowerLevel10k docs

AI Agent Documentation:
└── .claude/instructions-for-agents/
    ├── AGENTS.md                   # Gateway document
    ├── requirements/               # Must-follow rules
    ├── architecture/               # System design
    ├── guides/                     # How-to guides
    └── principles/                 # Constitutional rules
```

### Configuration Files

| File | Purpose |
|------|---------|
| `.mcp.json` | MCP server configuration (Context7, GitHub, etc.) |
| `.env.example` | Environment variables template |
| `.node-version` | Node.js version for fnm |
| `.python-version` | Python version for uv |
| `configs/ghostty/config` | Main Ghostty configuration |

## Important Notes

1. **`docs/` is OUTPUT only**: Never edit files in `docs/` directly. Edit source in `astro-website/src/` and run `npm run build`.

2. **`.nojekyll` is CRITICAL**: Never delete `docs/.nojekyll` - it enables GitHub Pages to serve `_astro/` assets.

3. **Symlinks**: `CLAUDE.md` and `GEMINI.md` are symlinks to `AGENTS.md`. Edit `AGENTS.md` to update all three.

4. **No `lib/` directory**: Despite historical references, there is no `lib/` directory. Installers are in `scripts/002-install-first-time/`.

---

[← Back to AGENTS.md](../../../../AGENTS.md) | [System Architecture](./system-architecture.md)
