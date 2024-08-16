# Ubuntu Development Environment Setup Script

## Overview

This script automates the setup of a comprehensive development environment on Ubuntu-based systems. It installs and configures a wide range of tools, applications, and utilities commonly used by developers, including programming languages, IDEs, command-line tools, and productivity applications.

## Features

- Installs and configures ZSH with Oh My ZSH and useful plugins
- Sets up development environments for various programming languages (Node.js, Python, Go, Flutter)
- Installs popular development tools (Git, Docker, VSCode, WebStorm)
- Configures Neovim with NvChad for advanced text editing
- Installs productivity and utility applications (Obsidian, Slack, Postman, etc.)
- Sets up fonts and themes for a better terminal experience

## Prerequisites

- A fresh installation of Ubuntu or an Ubuntu-based Linux distribution
- Sudo privileges on your account

## Usage

1. Download the script from the repo.

2. Make the script executable:

   ```bash
   chmod +x setup.sh
   ```

3. Run the script:

   ```bash
   ./setup.sh
   ```

4. Follow any on-screen prompts during the installation process.

5. After the script completes, log out and log back in to ensure all changes take effect.

6. Open Neovim by running `nvim` in the terminal and execute `:MasonInstallAll` to complete the NvChad setup.

## What's Included

The script installs and configures the following:

### Shell and Terminal

- ZSH with Oh My ZSH
- Powerlevel10k theme
- Various ZSH plugins (autosuggestions, syntax highlighting, etc.)
- JetBrains Mono Nerd Font

### Programming Languages and Tools

- Node.js (via NVM) and Yarn
- Python 3 and pipenv
- Go (Golang)
- Flutter and Android Studio

### Version Control

- Git (with initial configuration)

### Containerization and Orchestration

- Docker and Docker Compose

### Text Editors and IDEs

- Neovim with NvChad configuration
- Visual Studio Code with extensions
- WebStorm

### Development Utilities

- Doppler CLI
- Postman

### Productivity Applications

- Obsidian
- Slack
- AnyDesk
- Stremio
- Steam

### Other Utilities

- Various command-line tools and libraries

## Customization

Before running the script, you may want to review and customize it according to your specific needs. You can modify the script to:

- Add or remove packages
- Change default configurations
- Update version numbers for specific tools

## Post-Installation

After running the script and logging back in:

1. Configure Powerlevel10k by running `p10k configure` in your terminal.
2. Set up Flutter by running `flutter doctor` and following its recommendations.
3. Configure any additional VSCode or Neovim settings as needed.

## Troubleshooting

If you encounter any issues during the installation:

1. Check the terminal output for error messages.
2. Ensure you have a stable internet connection.
3. Verify that you have sufficient disk space.
4. Make sure your system is up-to-date before running the script.

If problems persist, please open an issue in the GitHub repository with details about the error and your system configuration.

## Contributing

Contributions to improve the script are welcome! Please fork the repository, make your changes, and submit a pull request.

## License

This script is released under the MIT License. See the LICENSE file for details.

## Disclaimer

This script makes significant changes to your system. While it has been tested, please use it at your own risk. It's recommended to run this script on a fresh Ubuntu installation or to back up your important data before running it on an existing system.
