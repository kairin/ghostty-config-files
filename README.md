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

### Running the Website

After the installation is complete, you can run the website locally:

```bash
npm run dev
```

This will start a development server, and you can view the website at `http://localhost:4321/ghostty-config-files/`.

## Project Structure

-   `src/`: Contains the source code for the Astro website.
    -   `components/`: Reusable Astro components.
    -   `layouts/`: Layout components for pages.
    -   `pages/`: The pages of the website.
-   `configs/`: Configuration files for Ghostty, ZSH, and other tools.
-   `scripts/`: Utility scripts for installation, updates, and other tasks.
-   `documentations/`: Additional documentation and assets.
-   `docs/`: The build output of the Astro website.

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

## Contributing

Contributions are welcome! Please follow the project's coding conventions and open a pull request with your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
