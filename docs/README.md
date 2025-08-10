# Ghostty Configuration

This repository provides a modular and compliant configuration for the Ghostty terminal emulator.

## Features:

-   **Modular:** Configuration is split into multiple files for better organization (`theme.conf`, `scroll.conf`, `layout.conf`, `keybindings.conf`), with the main `config` file including them.
-   **Compliant:** Adheres to official Ghostty documentation (https://ghostty.org/docs/config).
-   **Usable:**
    -   Clear scrollback with visible scrollbar.
    -   Optimized keybindings for productivity.
    -   Consistent theming.

## Getting Started & Updating:

For a fresh installation or to ensure Ghostty and its configuration are up-to-date, follow these steps:

1.  **Clone Ghostty (if not already present):**
    ```bash
    git clone https://github.com/ghostty-org/ghostty.git ~/Apps/ghostty
    ```
    (Assuming `~/Apps/` is your preferred location for applications)

2.  **Clone Ghostty Configuration:**
    ```bash
    git clone https://github.com/your-username/ghostty-config.git ~/.config/ghostty
    ```
    (Replace `your-username` with your GitHub username)

3.  **Run the Update Script:**
    Navigate to your Ghostty config directory and execute the `update_ghostty.sh` script. This script is now more robust with explicit error handling. If any step fails, the script will exit immediately with an informative error message.

    ```bash
    cd ~/.config/ghostty
    ./update_ghostty.sh
    ```
    Always review the output of the script to confirm successful completion.

## Configuration:

The main configuration file is `config`, which includes other modular configuration files.
Reload Ghostty config with `Cmd+S > R` (or `Ctrl+S > R` on Linux/Windows).

## Documentation:

-   Ghostty Official Docs: https://ghostty.org/docs/config
-   Agent-OS Docs: See `.agent-os/` for mission, architecture, and specifications.