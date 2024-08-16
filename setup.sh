#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package if it's not already installed
install_if_not_exists() {
    if ! command_exists "$1"; then
        echo "Installing $1..."
        sudo apt install -y "$1"
    else
        echo "$1 is already installed."
    fi
}

# Update package lists
echo "Updating package lists..."
sudo apt update
echo "Package lists updated!"

# Install essential packages
essential_packages=(
    "zsh"
    "curl"
    "git"
    "unzip"
    "wget"
    "apt-transport-https"
    "ca-certificates"
    "gnupg"
    "software-properties-common"
    "python3"
    "python3-pip"
    "flatpak"
)

for package in "${essential_packages[@]}"; do
    install_if_not_exists "$package"
done

# Install Oh My ZSH
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My ZSH..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My ZSH installed!"
else
    echo "Oh My ZSH is already installed."
fi

# Install ZSH plugins
zsh_plugins=(
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
    "fast-syntax-highlighting"
    "zsh-autocomplete"
)

for plugin in "${zsh_plugins[@]}"; do
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" ]; then
        echo "Installing $plugin..."
        git clone "https://github.com/zsh-users/$plugin.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
    else
        echo "$plugin is already installed."
    fi
done

# Install JetBrains Mono Nerd Font
if [ ! -f "$HOME/.local/share/fonts/JetBrains Mono Regular Nerd Font Complete.ttf" ]; then
    echo "Installing JetBrains Mono Nerd Font..."
    mkdir -p "$HOME/.local/share/fonts"
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
    unzip JetBrainsMono.zip -d "$HOME/.local/share/fonts"
    fc-cache -fv
    rm JetBrainsMono.zip
    echo "JetBrains Mono Nerd Font installed!"
else
    echo "JetBrains Mono Nerd Font is already installed."
fi

# Install Powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    echo "Powerlevel10k theme installed!"
else
    echo "Powerlevel10k theme is already installed."
fi

# Update .zshrc
echo "Updating .zshrc..."
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting zsh-autocomplete)/' "$HOME/.zshrc"
echo "Updated .zshrc!"

# Install NVM (Node Version Manager)
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    NVM_VERSION="0.40.0"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash
    echo "NVM installed!"
else
    echo "NVM is already installed."
fi

# Load NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install Node.js and Yarn
if ! command_exists node; then
    echo "Installing Node.js..."
    nvm install --lts
    echo "Node.js installed!"

    echo "Installing Yarn..."
    npm install -g yarn
    echo "Yarn installed!"
else
    echo "Node.js is already installed."
fi

# Install pipenv
if ! command_exists pipenv; then
    echo "Installing pipenv..."
    pip3 install pipenv
    echo "Pipenv installed!"
else
    echo "Pipenv is already installed."
fi

# Install Go (Golang)
if ! command_exists go; then
    echo "Installing Go (Golang)..."
    GO_VERSION="1.23.0"
    wget "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    echo 'export PATH=$PATH:/usr/local/go/bin' >>"$HOME/.zshrc"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    echo "Go (Golang) installed!"
else
    echo "Go (Golang) is already installed."
fi

# Install Doppler CLI
if ! command_exists doppler; then
    echo "Installing Doppler CLI..."
    curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
    echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
    sudo apt-get update && sudo apt-get install -y doppler
    echo "Doppler CLI installed!"
else
    echo "Doppler CLI is already installed."
fi

# Install Docker and Docker Compose
if ! command_exists docker; then
    echo "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker "$USER"
    echo "Docker installed!"
else
    echo "Docker is already installed."
fi

if ! command_exists docker-compose; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed!"
else
    echo "Docker Compose is already installed."
fi

# GIT configuration
echo "Configuring GIT..."
git config --global user.email "lotfi@ninetailed.com"
git config --global user.name "Lotfi Arif"

# Add flathub repo
echo "Adding flathub repo..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install flatpak applications
flatpak_apps=(
    "com.stremio.Stremio"
    "com.visualstudio.code"
    "md.obsidian.Obsidian"
    "com.slack.Slack"
    "com.getpostman.Postman"
    "com.github.alpaca"
    "com.github.lainsce.notesnook"
)

for app in "${flatpak_apps[@]}"; do
    echo "Installing $app..."
    flatpak install -y flathub "$app"
done

# Install AnyDesk
if ! command_exists anydesk; then
    echo "Installing AnyDesk..."
    wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo apt-key add -
    echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
    sudo apt update
    sudo apt install -y anydesk
    echo "AnyDesk installed!"
else
    echo "AnyDesk is already installed."
fi

# Install Steam
if ! command_exists steam; then
    echo "Installing Steam..."
    sudo apt install -y steam
    echo "Steam installed!"
else
    echo "Steam is already installed."
fi

# Install WebStorm
if [ ! -d "/opt/webstorm" ]; then
    echo "Installing WebStorm..."
    WEBSTORM_VERSION="2024.2"
    wget -O webstorm.tar.gz "https://download.jetbrains.com/webstorm/WebStorm-${WEBSTORM_VERSION}.tar.gz"
    sudo tar -xzf webstorm.tar.gz -C /opt
    rm webstorm.tar.gz
    sudo mv "/opt/WebStorm-${WEBSTORM_VERSION}" /opt/webstorm
    echo "WebStorm installed!"
else
    echo "WebStorm is already installed."
fi

# Install Flutter
if ! command_exists flutter; then
    echo "Installing Flutter..."
    sudo apt-get install -y libglu1-mesa
    sudo snap install android-studio --classic
    git clone https://github.com/flutter/flutter.git "$HOME/flutter"
    echo 'export PATH="$PATH:$HOME/flutter/bin"' >>"$HOME/.zshrc"
    source "$HOME/.zshrc"
    flutter doctor
    echo "Flutter installed!"
else
    echo "Flutter is already installed."
fi

# Install Neovim
if ! command_exists nvim; then
    echo "Installing Neovim..."
    sudo add-apt-repository ppa:neovim-ppa/unstable
    sudo apt-get update
    sudo apt-get install -y neovim
    echo "Neovim installed!"
else
    echo "Neovim is already installed."
fi

# Install ripgrep (required for Telescope)
if ! command_exists rg; then
    echo "Installing ripgrep..."
    sudo apt-get install -y ripgrep
    echo "ripgrep installed!"
else
    echo "ripgrep is already installed."
fi

# Install NvChad
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "Installing NvChad..."
    git clone https://github.com/NvChad/NvChad "$HOME/.config/nvim" --depth 1
    nvim +'hi NormalFloat guibg=#1e222a' +PackerSync
    echo "NvChad installed!"
else
    echo "NvChad is already installed."
fi

# Install VSCode extensions
if command_exists code; then
    echo "Installing VSCode extensions..."
    vscode_extensions=(
        "alexcvzz.vscode-sqlite"
        "be5invis.toml"
        "bierner.markdown-mermaid"
        "bradlc.vscode-tailwindcss"
        "davidanson.vscode-markdownlint"
        "dbaeumer.vscode-eslint"
        "donjayamanne.githistory"
        "dsznajder.es7-react-js-snippets"
        "foxundermoon.shell-format"
        "ecmel.vscode-html-css"
        "equinusocio.vsc-material-theme"
        "equinusocio.vsc-material-theme-icons"
        "esbenp.prettier-vscode"
        "firsttris.vscode-jest-runner"
        "github.copilot"
        "github.copilot-chat"
        "github.github-vscode-theme"
        "github.vscode-pull-request-github"
        "golang.go"
        "graphql.vscode-graphql-syntax"
        "gruntfuggly.todo-tree"
        "ms-azuretools.vscode-docker"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode-remote.remote-ssh-edit"
        "ms-vscode-remote.remote-wsl"
        "ms-vscode.remote-explorer"
        "ms-vsliveshare.vsliveshare"
        "nrwl.angular-console"
        "pkief.material-icon-theme"
        "prisma.prisma"
        "styled-components.vscode-styled-components"
        "stylelint.vscode-stylelint"
        "wix.vscode-import-cost"
        "yoavbls.pretty-ts-errors"
    )

    for extension in "${vscode_extensions[@]}"; do
        code --install-extension "$extension"
    done
    echo "VSCode extensions installed!"
else
    echo "VSCode is not installed. Skipping extension installation."
fi

echo "Installation complete! Please log out and log back in for all changes to take effect."
echo "After logging back in, run 'nvim' and execute ':MasonInstallAll' to complete NvChad setup."

# Prompt for system restart
read -p "Do you want to restart the system now to apply all changes? (y/n) " -n 1 -r
echo # Move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Restarting the system..."
    sudo shutdown -r now
else
    echo "Please remember to restart your system later to ensure all changes take effect."
fi
