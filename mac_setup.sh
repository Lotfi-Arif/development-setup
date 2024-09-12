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

# Function to install a package using Homebrew
install_brew_package() {
    if ! brew list "$1" &>/dev/null; then
        log "Installing $1..."
        brew install "$1"
    else
        log "$1 is already installed."
    fi
}

# Function to install a cask using Homebrew
install_brew_cask() {
    if ! brew list --cask "$1" &>/dev/null; then
        log "Installing $1..."
        brew install --cask "$1"
    else
        log "$1 is already installed."
    fi
}

# Install Homebrew if not already installed
install_homebrew() {
    if ! command_exists "brew"; then
        log "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log "Homebrew is already installed."
    fi
}

# Set up SSH for GitHub
setup_github_ssh() {
    local ssh_key_file="$HOME/.ssh/id_ed25519"
    local ssh_pub_file="${ssh_key_file}.pub"

    if [[ -f "$ssh_key_file" ]]; then
        log "Existing SSH key found: $ssh_key_file"
    else
        log "No existing SSH key found. Generating a new ED25519 key..."
        ssh-keygen -t ed25519 -C "lotfi@ninetailed.com" -f "$ssh_key_file" -N ""
    fi

    # Ensure the SSH agent is running and add the key
    eval "$(ssh-agent -s)"
    ssh-add "$ssh_key_file"

    # Display the public key
    log "Your public key is:"
    cat "$ssh_pub_file"
    log "Please add this key to your GitHub account if you haven't already."
    log "Go to https://github.com/settings/keys to add the key."
    read -p "Press Enter once you've added the key to your GitHub account..."

    # Test the SSH connection
    log "Testing SSH connection to GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log "SSH connection to GitHub successful"
    else
        log "SSH connection test to GitHub failed. Please check your GitHub settings and try again."
        return 1
    fi
}

# Configure Git
configure_git() {
    local current_email=$(git config --global user.email)
    local current_name=$(git config --global user.name)

    if [[ "$current_email" != "lotfi@ninetailed.com" || "$current_name" != "Lotfi Arif" ]]; then
        log "Configuring Git..."
        git config --global user.email "lotfi@ninetailed.com"
        git config --global user.name "Lotfi Arif"
    else
        log "Git is already configured correctly."
    fi
}

# Install and configure Zsh
install_zsh() {
    if [[ $SHELL == */zsh ]]; then
        log "Zsh is already the default shell."
    else
        install_brew_package "zsh"
        log "Setting Zsh as the default shell..."
        chsh -s "$(which zsh)"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log "Oh My Zsh is already installed."
    else
        log "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
}

# Install JetBrains Mono Nerd Font
install_jetbrains_mono() {
    if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null; then
        log "JetBrains Mono Nerd Font is already installed."
    else
        log "Installing JetBrains Mono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font
        log "IMPORTANT: Please manually set your terminal font to 'JetBrainsMono Nerd Font' (not the Mono version) after installation."
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
        local plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$(basename "$plugin")"
        if [ -d "$plugin_dir" ]; then
            log "$plugin is already installed."
        else
            log "Installing $plugin..."
            git clone "https://github.com/${plugin}.git" "$plugin_dir"
        fi
    done

    # Update .zshrc if needed
    if ! grep -q "zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete" "$HOME/.zshrc"; then
        log "Updating .zshrc with new plugins..."
        sed -i '' 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)/' "$HOME/.zshrc"
    else
        log "Plugins are already configured in .zshrc"
    fi
}

# Install and configure Powerlevel10k theme
install_powerlevel10k() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ -d "$p10k_dir" ]; then
        log "Powerlevel10k theme is already installed."
    else
        log "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
        sed -i '' 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
    fi
}

install_nvm() {
    if [ -d "$HOME/.nvm" ]; then
        log "NVM is already installed. Updating..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        (cd "$NVM_DIR" && git fetch --tags origin && git checkout $(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)))
    else
        log "Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    if ! grep -q 'export NVM_DIR' "$HOME/.zshrc"; then
        echo '
# NVM configuration
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
' >>"$HOME/.zshrc"
        log "NVM configuration added to .zshrc"
    fi

    if ! nvm version 18.20.3 >/dev/null 2>&1; then
        log "Installing Node.js 18.20.3..."
        nvm install 18.20.3
        nvm use 18.20.3
        nvm alias default 18.20.3
    else
        log "Node.js 18.20.3 is already installed."
    fi

    if ! command -v yarn &>/dev/null; then
        log "Installing Yarn..."
        npm i -g yarn
    else
        log "Yarn is already installed."
    fi
}

install_neovim() {
    if command_exists nvim; then
        log "Neovim is already installed."
    else
        log "Installing Neovim and dependencies..."
        brew install neovim
        install_brew_package "ripgrep"
        install_brew_package "gcc"
        install_brew_package "make"
    fi
}

# Install NvChad
install_nvchad() {
    if [ -d "$HOME/.config/nvim" ]; then
        log "NvChad is already installed. Skipping..."
    else
        log "Installing NvChad..."
        rm -rf ~/.config/nvim ~/.local/share/nvim ~/.cache/nvim
        git clone https://github.com/NvChad/NvChad ~/.config/nvim --depth 1
        log "NvChad installed. Please run 'nvim' to complete the setup."
    fi
}

# Install Doppler CLI
install_doppler() {
    if command_exists doppler; then
        log "Doppler CLI is already installed."
    else
        log "Installing Doppler CLI..."
        brew install gnupg
        brew install dopplerhq/cli/doppler
        doppler --version
    fi
}

# Install Cloudflare Wrangler CLI
install_wrangler() {
    if command_exists wrangler; then
        log "Cloudflare Wrangler CLI is already installed."
    else
        log "Installing Cloudflare Wrangler CLI..."
        npm install -g @cloudflare/wrangler
    fi
}

# Install applications using Homebrew Cask
install_apps() {
    local apps=(
        "obsidian" "discord" "docker" "1password" "iterm2" "postman"
        "slack" "stremio" "expressvpn" "zen-browser" "visual-studio-code"
    )

    for app in "${apps[@]}"; do
        install_brew_cask "$app"
    done
}

# Main setup function
main_setup() {
    log "Starting setup process..."

    install_homebrew
    install_zsh
    install_oh_my_zsh
    setup_github_ssh
    configure_git
    install_jetbrains_mono
    install_zsh_plugins
    install_powerlevel10k
    install_nvm
    install_neovim
    install_nvchad
    install_doppler
    install_wrangler
    install_apps

    log "Setup process completed successfully!"
    log "Please restart your terminal or run 'source ~/.zshrc' for all changes to take effect."
    log "Remember to run 'nvim' to complete the NvChad setup if it's newly installed."
}

# Run the main setup function
main_setup
