# Ghostty Configuration Architecture

This repository uses a **single, consolidated Ghostty configuration file (`config`)** for simplicity and maintainability.

## Principles:

1.  **Centralized:** All settings are in one `config` file.
2.  **Compliant:** Adheres to official Ghostty documentation (https://ghostty.org/docs/config).
3.  **Usability-Driven:** Configured for clear scrollback, optimized keybindings, and consistent theming.
4.  **Simplified Maintenance:** Easy updates and debugging due to consolidated settings.

## Usage:

Ghostty loads the `config` file on startup. Reload changes with the `reload_config` action (e.g., `cmd+s>r`).
