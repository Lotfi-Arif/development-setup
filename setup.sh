#!/bin/bash

# Set strict mode
set -euo pipefail
IFS=$'\n\t'

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/setup_log.txt"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log "Error on line $line_number: Command exited with status $exit_code"
    exit $exit_code
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Function to install a package if it's not already installed
install_if_not_exists() {
    if ! command_exists "$1"; then
        log "Installing $1..."
        if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y "$1"; then
            log "Failed to install $1. Please check your internet connection and try again."
            return 1
        fi
    else
        log "$1 is already installed."
    fi
}

# Function to run commands with error checking
run_command() {
    if ! "$@"; then
        log "Command failed: $*"
        return 1
    fi
}

# Function to run a command in zsh
run_in_zsh() {
    zsh -c "$1"
}

# Install and configure zsh
install_zsh() {
    install_if_not_exists zsh
    if [[ $SHELL != */zsh ]]; then
        log "Setting zsh as the default shell..."
        chsh -s "$(which zsh)"
    fi
}

# Install Oh My ZSH
install_oh_my_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log "Installing Oh My ZSH..."
        if ! run_in_zsh "sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" \"\" --unattended"; then
            log "Failed to install Oh My ZSH. Please check your internet connection and try again."
            return 1
        fi
        log "Oh My ZSH installed!"
    else
        log "Oh My ZSH is already installed."
    fi
}

# Set up SSH for GitHub
setup_github_ssh() {
    local ssh_key_file=""

    # Check for existing SSH keys
    for key in id_rsa id_ed25519 id_ecdsa id_dsa; do
        if [[ -f "$HOME/.ssh/${key}" ]]; then
            ssh_key_file="$HOME/.ssh/${key}"
            break
        fi
    done

    if [[ -z "$ssh_key_file" ]]; then
        log "No existing SSH key found. Generating a new ED25519 key..."
        ssh-keygen -t ed25519 -C "lotfi@ninetailed.com" -f "$HOME/.ssh/id_ed25519" -N ""
        ssh_key_file="$HOME/.ssh/id_ed25519"
    else
        log "Existing SSH key found: $ssh_key_file"
    fi

    # Ensure the SSH agent is running
    eval "$(ssh-agent -s)"
    ssh-add "$ssh_key_file"

    # Display the public key
    log "Your public key is:"
    cat "${ssh_key_file}.pub"
    log "Please ensure this key is added to your GitHub account."
    read -p "Press Enter to continue..."

    # Test the SSH connection
    log "Testing SSH connection to GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "Hi Lotfi-Arif! You've successfully authenticated"; then
        log "SSH connection to GitHub successful"
    else
        log "SSH connection test to GitHub failed. Running verbose test..."
        if ssh -vT git@github.com 2>&1 | grep -q "You've successfully authenticated"; then
            log "SSH connection to GitHub successful (verified through verbose output)"
        else
            log "SSH connection to GitHub failed."
            log "Please check the following:"
            log "1. Ensure the public key is added to your GitHub account"
            log "2. Check your internet connection"
            log "3. Verify that github.com is accessible from your network"
            read -p "Do you want to continue with the script despite the SSH connection issue? (y/n) " continue_script
            if [[ $continue_script != "y" ]]; then
                return 1
            fi
        fi
    fi
}

# Install ZSH plugins
install_zsh_plugins() {
    local zsh_plugins=(
        "zsh-autosuggestions"
        "zsh-syntax-highlighting"
        "fast-syntax-highlighting"
        "zsh-autocomplete"
    )

    for plugin in "${zsh_plugins[@]}"; do
        local plugin_name=$(basename "$plugin")
        local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"
        if [ ! -d "$plugin_dir" ]; then
            log "Installing $plugin_name..."
            if ! git clone "https://github.com/${plugin}.git" "$plugin_dir"; then
                log "Failed to install $plugin_name. Please check your internet connection and try again."
                return 1
            fi
        else
            log "$plugin_name is already installed."
        fi
    done

    # Update .zshrc
    log "Updating .zshrc..."
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)/' "$HOME/.zshrc"
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
}

# Install JetBrains Mono Nerd Font
install_jetbrains_mono() {
    local font_dir="$HOME/.local/share/fonts"
    local zip_file="JetBrainsMono.zip"
    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/$zip_file"

    mkdir -p "$font_dir"

    log "Downloading JetBrains Mono Nerd Font..."
    if ! wget --show-progress -q "$font_url" -O "$zip_file"; then
        log "Failed to download JetBrains Mono Nerd Font. Please check your internet connection and try again."
        return 1
    fi

    log "Extracting fonts..."
    if ! unzip -o -q "$zip_file" -d "$font_dir"; then
        log "Failed to extract JetBrains Mono Nerd Font."
        rm -f "$zip_file"
        return 1
    fi

    rm -f "$zip_file"

    log "Updating font cache..."
    if ! fc-cache -f; then
        log "Failed to update font cache. You may need to manually refresh your font cache."
        return 1
    fi

    log "JetBrains Mono Nerd Font installed successfully!"
}

# Install NVM
install_nvm() {
    if [ ! -d "$HOME/.nvm" ]; then
        log "Installing NVM..."
        NVM_VERSION="0.40.0"
        if ! curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash; then
            log "Failed to install NVM."
            return 1
        fi
        log "NVM installed!"
    else
        log "NVM is already installed."
    fi

    # Add NVM to .zshrc if not already present
    if ! grep -q 'export NVM_DIR' "$HOME/.zshrc"; then
        echo 'export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm' >>"$HOME/.zshrc"
    fi

    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install latest LTS version of Node.js
    log "Installing latest LTS version of Node.js..."
    if ! nvm install --lts; then
        log "Failed to install Node.js."
        return 1
    fi

    # Install Yarn globally
    log "Installing Yarn..."
    if ! npm install -g yarn; then
        log "Failed to install Yarn."
        return 1
    fi
}

# Install Pipenv
install_pipenv() {
    if ! command_exists pipenv; then
        log "Installing pipenv..."
        if ! pip3 install pipenv; then
            log "Failed to install pipenv."
            return 1
        fi
        log "Pipenv installed!"
    else
        log "Pipenv is already installed."
    fi
}

# Install Go
install_go() {
    if ! command_exists go; then
        log "Installing Go (Golang)..."
        GO_VERSION="1.23.0"
        if ! wget -q "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"; then
            log "Failed to download Go."
            return 1
        fi
        sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"

        # Add Go to PATH if not already present
        if ! grep -q 'export PATH=$PATH:/usr/local/go/bin' "$HOME/.zshrc"; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >>"$HOME/.zshrc"
            log "Added Go to PATH in .zshrc"
        fi

        rm "go${GO_VERSION}.linux-amd64.tar.gz"
        log "Go (Golang) installed!"
    else
        log "Go (Golang) is already installed."
    fi
}

# Install Doppler CLI
install_doppler() {
    if ! command_exists doppler; then
        log "Installing Doppler CLI..."
        if ! curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg; then
            log "Failed to add Doppler's GPG key."
            return 1
        fi
        echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list >/dev/null
        if ! sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y doppler; then
            log "Failed to install Doppler CLI."
            return 1
        fi
        log "Doppler CLI installed!"
    else
        log "Doppler CLI is already installed."
    fi
}

# Install Docker
install_docker() {
    if ! command_exists docker; then
        log "Installing Docker..."

        # Install prerequisites
        sudo DEBIAN_FRONTEND=noninteractive apt update &&
            sudo DEBIAN_FRONTEND=noninteractive apt install -y ca-certificates curl gnupg

        # Add Docker's GPG key
        sudo install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg

        # Add Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

        # Install Docker
        sudo DEBIAN_FRONTEND=noninteractive apt update
        sudo DEBIAN_FRONTEND=noninteractive apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Set up Docker group
        sudo groupadd docker 2>/dev/null || true
        sudo usermod -aG docker "$USER"

        log "Docker installed successfully!"

        # Verify the installation
        log "Verifying Docker installation..."
        if sudo docker run hello-world; then
            log "Docker verification successful!"
        else
            log "Docker verification failed. Please check the installation manually."
        fi
    else
        log "Docker is already installed."
    fi
}

# Install VS Code
install_vscode() {
    if ! command_exists code; then
        log "Installing Visual Studio Code..."

        local vscode_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
        local deb_file="vscode.deb"

        # Download the latest VS Code .deb package
        if ! wget -O "$deb_file" "$vscode_url"; then
            log "Failed to download VS Code. Please check your internet connection and try again."
            return 1
        fi

        # Install the package
        if ! sudo dpkg -i "$deb_file"; then
            log "Failed to install VS Code. Attempting to resolve dependencies..."
            if ! sudo apt install -f -y; then
                log "Failed to resolve dependencies. Please install VS Code manually."
                rm -f "$deb_file"
                return 1
            fi
            # Try installing again after resolving dependencies
            if ! sudo dpkg -i "$deb_file"; then
                log "Failed to install VS Code even after resolving dependencies. Please install manually."
                rm -f "$deb_file"
                return 1
            fi
        fi

        # Clean up the downloaded .deb file
        rm -f "$deb_file"
        log "Visual Studio Code installed successfully!"
    else
        log "Visual Studio Code is already installed."
    fi
}

# Install JetBrains Toolbox
install_jetbrains_toolbox() {
    if ! command_exists jetbrains-toolbox; then
        log "Installing JetBrains Toolbox..."

        local toolbox_version="2.4.2.32922"
        local download_url="https://download.jetbrains.com/toolbox/jetbrains-toolbox-${toolbox_version}.tar.gz"
        local tarball="jetbrains-toolbox.tar.gz"

        # Download the latest JetBrains Toolbox tarball
        if ! wget -O "$tarball" "$download_url"; then
            log "Failed to download JetBrains Toolbox. Please check your internet connection and try again."
            return 1
        fi

        # Extract the tarball
        if ! tar -xzf "$tarball"; then
            log "Failed to extract JetBrains Toolbox."
            rm -f "$tarball"
            return 1
        fi

        # Run the installer
        local extracted_dir=$(find . -maxdepth 1 -type d -name "jetbrains-toolbox-*" -print -quit)
        if [ -z "$extracted_dir" ]; then
            log "Failed to find extracted JetBrains Toolbox directory."
            rm -f "$tarball"
            return 1
        fi

        if ! "$extracted_dir/jetbrains-toolbox"; then
            log "Failed to run JetBrains Toolbox installer."
            rm -rf "$extracted_dir" "$tarball"
            return 1
        fi

        # Clean up the extracted files and tarball
        rm -rf "$extracted_dir" "$tarball"
        log "JetBrains Toolbox installed successfully!"
    else
        log "JetBrains Toolbox is already installed."
    fi
}

# Install 1Password
install_1password() {
    if ! command_exists 1password; then
        log "Installing 1Password..."

        # Add the key for the 1Password apt repository
        if ! curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg; then
            log "Failed to add 1Password repository key."
            return 1
        fi

        # Add the 1Password apt repository
        if ! echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null; then
            log "Failed to add 1Password repository."
            return 1
        fi

        # Add the debsig-verify policy
        sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
        if ! curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol >/dev/null; then
            log "Failed to add debsig-verify policy."
            return 1
        fi

        sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
        if ! curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg; then
            log "Failed to add debsig keyring."
            return 1
        fi

        # Install 1Password
        if ! sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y 1password; then
            log "Failed to install 1Password."
            return 1
        fi

        log "1Password installed successfully!"
    else
        log "1Password is already installed."
    fi
}

# Install AnyDesk
install_anydesk() {
    if ! command_exists anydesk; then
        log "Installing AnyDesk..."

        # Create the keyrings directory if it doesn't exist
        sudo mkdir -p /etc/apt/keyrings

        # Download and add the AnyDesk GPG key
        if ! wget -qO- https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /etc/apt/keyrings/anydesk.gpg; then
            log "Failed to add AnyDesk's GPG key. Please check your internet connection and try again."
            return 1
        fi

        # Add the AnyDesk repository
        echo "deb [signed-by=/etc/apt/keyrings/anydesk.gpg] http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list >/dev/null

        # Update package lists and install AnyDesk
        if ! sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y anydesk; then
            log "Failed to install AnyDesk. Please check your internet connection and try again."
            return 1
        fi

        log "AnyDesk installed successfully!"
    else
        log "AnyDesk is already installed."
    fi
}

# Install Steam
install_steam() {
    if ! command_exists steam; then
        log "Installing Steam..."

        if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y steam; then
            log "Failed to install Steam. Please check your internet connection and try again."
            return 1
        fi

        log "Steam installed successfully!"
    else
        log "Steam is already installed."
    fi
}

# Install flutter
install_flutter() {
    log "Installing Flutter and dependencies..."

    # Install required packages
    local packages=(
        "libglu1-mesa"
        "clang"
        "cmake"
        "ninja-build"
        "libgtk-3-dev"
    )

    if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y "${packages[@]}"; then
        log "Failed to install required packages. Please check your internet connection and try again."
        return 1
    fi

    # Install Google Chrome
    log "Installing Google Chrome..."
    local chrome_deb="google-chrome-stable_current_amd64.deb"
    if ! wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; then
        log "Failed to download Google Chrome. Please check your internet connection and try again."
        return 1
    fi
    if ! sudo dpkg -i $chrome_deb; then
        log "Failed to install Google Chrome. Attempting to resolve dependencies..."
        if ! sudo apt install -f -y; then
            log "Failed to resolve dependencies. Please install Google Chrome manually."
            rm $chrome_deb
            return 1
        fi
        # Try installing again after resolving dependencies
        if ! sudo dpkg -i $chrome_deb; then
            log "Failed to install Google Chrome. Please install manually."
            rm $chrome_deb
            return 1
        fi
    fi
    rm $chrome_deb
    log "Google Chrome installed successfully."

    # Install Android Studio if not already installed
    if ! command_exists android-studio; then
        log "Installing Android Studio..."
        if ! sudo snap install android-studio --classic; then
            log "Failed to install Android Studio. Please check your internet connection and try again."
            return 1
        fi
    else
        log "Android Studio is already installed."
    fi

    # Install or update Flutter SDK
    local flutter_dir="$HOME/flutter"
    if [ ! -d "$flutter_dir" ]; then
        log "Cloning Flutter repository..."
        if ! git clone https://github.com/flutter/flutter.git "$flutter_dir"; then
            log "Failed to clone Flutter repository. Please check your internet connection and try again."
            return 1
        fi
    else
        log "Flutter directory already exists. Updating..."
        if ! (cd "$flutter_dir" && git pull); then
            log "Failed to update Flutter. Please check your internet connection and try again."
            return 1
        fi
    fi

    # Add Flutter to PATH if not already present
    if ! grep -q "flutter/bin" "$HOME/.zshrc"; then
        echo 'export PATH="$PATH:$HOME/flutter/bin"' >> "$HOME/.zshrc"
        log "Added Flutter to PATH in .zshrc"
    fi

    # Source the updated .zshrc
    source "$HOME/.zshrc"

    # Run flutter doctor
    log "Running flutter doctor..."
    if ! flutter doctor; then
        log "Flutter doctor reported issues. Please review and resolve them manually."
    fi

    # Set up Android SDK
    log "Setting up Android SDK..."
    if ! flutter config --android-sdk "$HOME/Android/Sdk"; then
        log "Failed to set Android SDK path. Please set it manually."
    fi

    # Accept Android licenses
    log "Accepting Android licenses..."
    if ! flutter doctor --android-licenses; then
        log "Failed to accept Android licenses. Please run 'flutter doctor --android-licenses' manually."
    fi

    log "Flutter installation/update complete!"
}

# Install Neovim
install_neovim() {
    if ! command_exists nvim; then
        log "Installing Neovim..."
        if ! sudo add-apt-repository -y ppa:neovim-ppa/unstable; then
            log "Failed to add Neovim PPA. Please check your internet connection and try again."
            return 1
        fi
        if ! sudo DEBIAN_FRONTEND=noninteractive apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y neovim; then
            log "Failed to install Neovim. Please check your internet connection and try again."
            return 1
        fi
        log "Neovim installed!"

        # Install ripgrep (required for Telescope)
        if ! command_exists rg; then
            log "Installing ripgrep..."
            if ! sudo DEBIAN_FRONTEND=noninteractive apt install -y ripgrep; then
                log "Failed to install ripgrep. Please check your internet connection and try again."
                return 1
            fi
            log "ripgrep installed!"
        else
            log "ripgrep is already installed."
        fi

        # Install NvChad
        if [ ! -d "$HOME/.config/nvim" ]; then
            log "Installing NvChad..."
            if ! git clone https://github.com/NvChad/NvChad.git ~/.config/nvim --depth 1; then
                log "Failed to clone NvChad repository. Please check your internet connection and try again."
                return 1
            fi
            log "NvChad installed!"
        else
            log "NvChad is already installed."
        fi
    else
        log "Neovim is already installed."
    fi
}

# Configure Git
configure_git() {
    log "Configuring GIT..."
    git config --global user.email "lotfi@ninetailed.com"
    git config --global user.name "Lotfi Arif"
}

# Configure Flatpak
configure_flatpak() {
    log "Configuring Flatpak..."

    # Install Flatpak if not already installed
    install_if_not_exists flatpak

    # Remove system-wide Flathub remote if it exists
    log "Checking for system-wide Flathub remote..."
    if sudo flatpak remotes --system | grep -q "flathub"; then
        log "Removing system-wide Flathub remote..."
        sudo flatpak remote-delete --system flathub || log "Failed to remove system-wide Flathub remote. It may not exist or you may not have the necessary permissions."
    else
        log "No system-wide Flathub remote found."
    fi

    # Add Flathub repository for the current user
    log "Adding Flathub repository for the current user..."
    if ! flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo; then
        log "Failed to add Flathub repository. Please check your internet connection and try again."
        return 1
    fi

    # Ensure Flathub is the only remote for the current user
    log "Ensuring Flathub is the only remote for the current user..."
    local user_remotes=$(flatpak remotes --user)
    if [ "$(echo "$user_remotes" | wc -l)" -ne 1 ] || [ "$(echo "$user_remotes" | tr -d '[:space:]')" != "flathub" ]; then
        log "Unexpected user remotes found. Please check your Flatpak configuration."
        log "Current user remotes:"
        log "$user_remotes"
        return 1
    fi

    # Install flatpak applications for the current user
    local flatpak_apps=(
        "com.stremio.Stremio"
        "md.obsidian.Obsidian"
        "com.slack.Slack"
        "com.getpostman.Postman"
        "com.discordapp.Discord"
        "org.qbittorrent.qBittorrent"
        "io.github.zen_browser.zen"
        "io.podman_desktop.PodmanDesktop"
    )

    for app in "${flatpak_apps[@]}"; do
        log "Installing $app..."
        if ! flatpak install --user -y flathub "$app"; then
            log "Failed to install $app. Continuing with other installations."
        fi
    done
}

# Main setup function
main_setup() {
    log "Starting setup process..."

    # Update package lists
    log "Updating package lists..."
    if ! sudo DEBIAN_FRONTEND=noninteractive apt update; then
        log "Failed to update package lists. Please check your internet connection and try again."
        exit 1
    fi
    log "Package lists updated successfully!"

    # Install essential packages
    local essential_packages=(
        "curl" "git" "unzip" "wget" "apt-transport-https" "ca-certificates"
        "gnupg" "software-properties-common" "python3" "python3-pip" "flatpak" "snapd"
    )
    for package in "${essential_packages[@]}"; do
        install_if_not_exists "$package" || exit 1
    done

    # Install and configure zsh
    install_zsh
    install_oh_my_zsh
    setup_github_ssh
    install_zsh_plugins

    # Install development tools
    install_jetbrains_mono
    install_nvm
    install_pipenv
    install_go
    install_doppler
    install_docker
    install_vscode
    install_jetbrains_toolbox
    install_1password
    install_anydesk
    install_steam
    install_flutter
    install_neovim

    # Configure git
    configure_git

    # Configure Flatpak
    configure_flatpak

    log "Setup process completed successfully!"
    log "Please log out and log back in for all changes to take effect."
    log "Remember to run 'nvim' to complete the NvChad setup."
}

# Run the main setup function
main_setup

# Restart the shell to apply changes
exec zsh -l
