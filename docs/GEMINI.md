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

*   **Sudo Behavior**: The script should run normally, and the `sudo` password prompt should only appear after dependency checks, and only if `apt install` or other privileged operations are required.

## Fresh Installation and Update Process

For a fresh installation or to ensure Ghostty and its configuration are up-to-date, use the `setup_ghostty.sh` launcher script.

1.  **Clone Ghostty Configuration:**
    If you haven't already, clone this configuration repository:
    ```bash
    git clone https://github.com/your-username/ghostty-config.git ~/.config/ghostty
    ```
    (Replace `your-username` with your GitHub username)

2.  **Run the Setup Script:**
    Navigate to your Ghostty config directory and execute the `setup_ghostty.sh` launcher script. This script will handle cloning the Ghostty application (if not present), installing the configuration, and updating Ghostty to the latest version.

    ```bash
    cd ~/.config/ghostty
    ./setup_ghostty.sh
    ```
    Always review the output of the script to confirm successful completion.

## Git Workflow

*   Commit messages should be clear and concise, following the conventional commit format (e.g., `feat:`, `fix:`, `docs:`).
*   Changes should be pushed to the `main` branch.

## Agent Instructions

*   **No New Scripts:** Do not create new scripts to fix issues. Resolve problems within existing scripts.
*   **To-Do List Confirmation:** Every task from now on must generate a to-do list that requires user confirmation before checking off anything from the to-do list.
*   **Present To-Do List:** At every step, present the current to-do list to the user. The active to-do list is located in `.agent-os/specs/agent-todo.md`.