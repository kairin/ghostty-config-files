# Ghostty Configuration Repository

This repository provides a simplified, compliant, and highly usable configuration for the Ghostty terminal emulator.

## ✨ Key Features:

-   **Consolidated Configuration:** All Ghostty settings are unified into a single `config` file, making it easy to manage and understand.
-   **Official Documentation Compliance:** The configuration adheres strictly to the official Ghostty documentation (https://ghostty.org/docs/config), ensuring stability and compatibility.
-   **Enhanced Usability:**
    -   **Clear Scrollback:** Configured for a large scrollback buffer with a clearly visible scrollbar, allowing for easy review of past output.
    -   **Optimized Keybindings:** Includes a set of productivity-focused keybindings for efficient navigation and control.
    -   **Consistent Theming:** Applies a unified and aesthetically pleasing theme for a comfortable terminal experience.

## 🚀 Getting Started:

1.  **Clone this repository:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git ~/.config/ghostty
    ```
    (Replace `YOUR_USERNAME` and `YOUR_REPO_NAME` with your actual GitHub username and repository name if you've forked it.)

2.  **Start Ghostty:** Launch Ghostty, and it will automatically load the configuration from `~/.config/ghostty/config`.

## ⚙️ Configuration Details:

The primary configuration file is `config` located in the root of this repository. It contains all settings for fonts, colors, keybindings, scroll behavior, and more.

To reload the configuration within Ghostty after making changes, use the keybinding `Cmd+S > R` (or `Ctrl+S > R` on Linux/Windows if `Cmd` is mapped to `Ctrl`).

## 📚 Further Documentation:

-   **Ghostty Official Documentation:** https://ghostty.org/docs/config
-   **Agent-OS Documentation:** Refer to the `.agent-os/` directory for mission, architecture, and specification details related to this configuration repository.