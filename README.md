# Ghostty Configuration

This repository contains my personal Ghostty terminal emulator configuration.

## Installation

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git ~/.config/ghostty
    ```
    (Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your actual GitHub username and repository name.)

2.  **Ensure `less` is installed:**
    This configuration uses `less` to display the keybindings file on startup. If you don't have it installed, you can usually install it via your distribution's package manager (e.g., `sudo apt install less` on Debian/Ubuntu, `sudo pacman -S less` on Arch Linux).

## Usage

When you open Ghostty, the first tab will display a list of keybindings. To exit this view and get to a shell prompt, press `q`.

To open a new tab for your work, press `Ctrl+Shift+T`.

## Configuration Files

*   `config`: The main configuration file, which includes other configuration files.
*   `theme.conf`: Contains theme and background opacity settings.
*   `scroll.conf`: Contains scrollback limit settings.
*   `layout.conf`: Contains font, padding, window decoration, and other layout-related settings.
*   `keybindings.conf`: Contains custom keybindings.
*   `keybindings.md`: The Markdown file containing the list of keybindings, displayed on startup.
