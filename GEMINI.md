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

## Fresh Installation and Update Process

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

## Git Workflow

*   Commit messages should be clear and concise, following the conventional commit format (e.g., `feat:`, `fix:`, `docs:`).
*   Changes should be pushed to the `main` branch.