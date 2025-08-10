# LLM Instructions for Ghostty Configuration

This repository contains a modular and minimalist Ghostty configuration. When making changes to this repository, please follow these guidelines:

## Guiding Principles

*   **Modularity**: The configuration is split into multiple files for better organization. Please add new settings to the appropriate files:
    *   `theme.conf`: For theme and appearance settings.
    *   `scroll.conf`: For scrollback and history settings.
    *   `layout.conf`: For font, padding, and window layout settings.
    *   `keybindings.conf`: For all keybindings.
    *   The main `config` file should only contain includes to these files.

*   **Minimalism**: The configuration should remain clean and simple. Avoid adding unnecessary settings or complexity.

*   **Cross-Platform Compatibility**: The configuration should work on different platforms, especially Linux (Ubuntu). The `install_ghostty_config.sh` script should be maintained to be robust and handle different environments gracefully.

*   **Documentation**: Any new features, complex configurations, or changes to the installation process should be documented in the `README.md` file.

## Git Workflow

*   Commit messages should be clear and concise, following the conventional commit format (e.g., `feat:`, `fix:`, `docs:`).
*   Changes should be pushed to the `main` branch.