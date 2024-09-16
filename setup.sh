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
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
        "zdharma-continuum/fast-syntax-highlighting"
        "marlonrichert/zsh-autocomplete"
    )

    for plugin in "${zsh_plugins[@]}"; do
        local plugin_name=$(basename "$plugin")
        local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin_name"
        if [ ! -d "$plugin_dir" ]; then
            log "Installing $plugin_name..."
            if ! git clone --depth 1 "https://github.com/${plugin}.git" "$plugin_dir"; then
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
    
    # Check if powerlevel10k theme is installed
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        log "Installing powerlevel10k theme..."
        if ! git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"; then
            log "Failed to install powerlevel10k theme. Please check your internet connection and try again."
            return 1
        fi
    fi

    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"

    log "ZSH plugins and powerlevel10k theme installed successfully!"
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
    install_1password

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
