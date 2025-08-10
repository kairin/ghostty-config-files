# Ghostty Configuration Architecture

This repository uses a **modular Ghostty configuration, split into multiple files** for simplicity and maintainability.

## Principles:

1.  **Modular:** Settings are organized into separate files (e.g., `theme.conf`, `scroll.conf`, `keybindings.conf`), included by the main `config` file.
2.  **Compliant:** Adheres to official Ghostty documentation (https://ghostty.org/docs/config).
3.  **Usability-Driven:** Configured for clear scrollback, optimized keybindings, and consistent theming.
4.  **Simplified Maintenance:** Easy updates and debugging due to organized, modular settings. The provided update scripts are designed for robustness with explicit error handling.

## Usage:

Ghostty loads the main `config` file on startup, which then includes the other configuration files. Reload changes with the `reload_config` action (e.g., `cmd+s>r`).
