# Ghostty Configuration Architecture

This repository uses a **modular Ghostty configuration, split into multiple files** for simplicity and maintainability.

## Principles:

1.  **Modular:** Settings are organized into separate files (e.g., `theme.conf`, `scroll.conf`, `keybindings.conf`), included by the main `config` file.
2.  **Compliant:** Adheres to official Ghostty documentation (https://ghostty.org/docs/config).
3.  **Usability-Driven:** Configured for clear scrollback, optimized keybindings, and consistent theming.
4.  **Simplified Maintenance:** Easy updates and debugging due to organized, modular settings. The provided update scripts (located in `scripts/`) are designed for robustness with explicit error handling.
5.  **Sudo Behavior**: The script should run normally, and the `sudo` password prompt should only appear after dependency checks, and only if `apt install` or other privileged operations are required.
6.  **No New Scripts:** Do not create new scripts to fix issues. Resolve problems within existing scripts.
7.  **To-Do List Confirmation:** Every task from now on must generate a to-do list that requires user confirmation before checking off anything from the to-do list.
8.  **Present To-Do List:** At every step, present the current to-do list to the user.

## Usage:

Ghostty loads the main `config` file on startup, which then includes the other configuration files. Reload changes with the `reload_config` action (e.g., `cmd+s>r`).
