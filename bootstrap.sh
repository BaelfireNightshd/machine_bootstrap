#! /bin/bash

# colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

# helper prints
info() {
    echo -e "${CYAN}$@${RESET}"
}
warn() {
    echo -e "${YELLOW}$@${RESET}"
}
err() {
    echo -e "${RED}$@${RESET}"
    exit
}
success() {
    echo -e "${GREEN}$@${RESET}"
}

# Get OS info
# based on this: https://unix.stackexchange.com/questions/6345/how-can-i-get-distribution-name-and-version-number-in-a-simple-shell-script
info "Attempting to install ansible and Github CLI..."
if [ -f /etc/os-release ]; then
    source /etc/os-release
else
    err "No /etc/os-release file found"
fi

case "$ID" in
    debian|ubuntu)
        info "Installing Ansible using apt..."
        sudo apt update && sudo apt install -y ansible
        info "Installing Github CLI using apt..."
        sudo mkdir -p -m 755 /etc/apt/keyrings && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
        && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
        && sudo apt update \
        && sudo apt install gh -y
        ;;
    arch|manjaro)
        info "Installing Ansible using pacman..."
        sudo pacman -Syu --noconfirm ansible
        info "Installing Github CLI using pacman..."
        sudo pacman -Syu --noconfirm github-cli
        ;;
esac

info "Detecting if ssh key already exists"
if [ -f ~/.ssh/github.pub ]; then
    success "Found ssh key"
else
    info "None found, generating new one."
    ssh-keygen -f ~/.ssh/github -t ed25519 && success "Done"
fi

info "Adding key to github"

gh auth login
gh ssh-key add ~/.ssh/github.pub

info "Running Ansible Pull"
ansible-pull --ask-become-pass --private-key ~/.ssh/github -U ssh://git@github.com/BaelfireNightshd/machine_setup.git

exit
