# Ghostty Configuration Files

This repository contains a comprehensive terminal environment setup featuring the Ghostty terminal emulator with performance optimizations, right-click context menu integration, and integrated AI tools.

## Features

- **Ghostty Terminal**: Pre-configured for performance and aesthetics.
- **ZSH + Oh My ZSH**: A powerful shell with useful plugins.
- **Modern Unix Tools**: `eza`, `bat`, `ripgrep`, `fzf`, `zoxide`, and `fd`.
- **AI Integration**: Claude Code and Gemini CLI are integrated into the terminal.
- **Context Menu**: "Open in Ghostty" right-click option in your file manager.
- **Astro-Based Website**: A documentation and dashboard website built with Astro.

## Getting Started

### Prerequisites

- Ubuntu 25.04 or a compatible Linux distribution.
- Git installed on your system.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/ghostty-config-files.git
    cd ghostty-config-files
    ```

2.  **Run the installation script:**
    ```bash
    ./start.sh
    ```

This script will install all necessary dependencies, configure your terminal, and set up the Astro website.

### Using manage.sh

The repository includes a unified management interface:

```bash
# Install complete environment
./manage.sh install

# Update all components
./manage.sh update

# Validate system
./manage.sh validate

# Build documentation
./manage.sh docs build

# Start documentation dev server
./manage.sh docs dev

# Get help
./manage.sh --help
./manage.sh <command> --help
```

For detailed usage, see [docs-source/user-guide/usage.md](docs-source/user-guide/usage.md).

### Running the Website

After the installation is complete, you can run the website locally:

```bash
npm run dev
```

This will start a development server, and you can view the website at `http://localhost:4321/ghostty-config-files/`.

## Project Structure

-   `manage.sh`: Unified management interface for all repository operations (Phase 3)
-   `src/`: Contains the source code for the Astro website.
    -   `components/`: Reusable Astro components.
    -   `layouts/`: Layout components for pages.
    -   `pages/`: The pages of the website.
-   `configs/`: Configuration files for Ghostty, ZSH, and other tools.
-   `scripts/`: Modular utility scripts for installation, configuration, and validation.
    -   `install_node.sh`: Node.js installation module (Phase 5 - first extracted module)
    -   `common.sh`, `progress.sh`, `backup_utils.sh`: Shared utilities (Phase 2)
    -   `.module-template.sh`: Template for creating new modules (Phase 1)
-   `docs-source/`: **Editable documentation source** (git-tracked)
    -   `user-guide/`: User documentation (installation, configuration, usage)
    -   `ai-guidelines/`: AI assistant guidelines (modular extracts from AGENTS.md)
    -   `developer/`: Developer documentation (architecture, contributing, testing)
-   `docs/`: **Documentation build output** (Astro static site, **committed for GitHub Pages**)
-   `documentations/`: **Centralized documentation hub** (as of 2025-11-09)
    -   `user/`: End-user documentation (installation guides, configuration, troubleshooting)
    -   `developer/`: Developer documentation (architecture, analysis)
    -   `specifications/`: Active feature specifications (Spec 001, 002, 004)
    -   `archive/`: Historical/obsolete documentation
-   `local-infra/`: Local CI/CD infrastructure for zero-cost testing and validation.
    -   `tests/unit/`: Unit tests for modular scripts (Phase 1, 5)
    -   `runners/`: Local CI/CD execution scripts

## Development

### Running Tests

To run the test suite, which uses `astro check` for type-checking, run the following command:

```bash
npm test
```

### Building the Website

To build the website for production, run the following command:

```bash
npm run build
```

The output will be generated in the `docs/` directory.

## Documentation

### For Users
- **[Installation Guide](docs-source/user-guide/installation.md)** - Complete setup instructions
- **[Configuration Guide](docs-source/user-guide/configuration.md)** - Customize your environment
- **[Usage Guide](docs-source/user-guide/usage.md)** - manage.sh command reference

### For Developers
- **[Architecture Overview](docs-source/developer/architecture.md)** - System design and patterns
- **[Contributing Guide](docs-source/developer/contributing.md)** - How to contribute
- **[Testing Guide](docs-source/developer/testing.md)** - Testing strategies

### For AI Assistants
- **[Core Principles](docs-source/ai-guidelines/core-principles.md)** - Project requirements
- **[Git Strategy](docs-source/ai-guidelines/git-strategy.md)** - Branch management
- **[CI/CD Requirements](docs-source/ai-guidelines/ci-cd-requirements.md)** - Local CI/CD
- **[Development Commands](docs-source/ai-guidelines/development-commands.md)** - Quick reference

**Note**: Edit documentation in `docs-source/`, not `docs/` (which is auto-generated).

## Contributing

Contributions are welcome! Please read the [Contributing Guide](docs-source/developer/contributing.md) and follow the project's coding conventions before opening a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
