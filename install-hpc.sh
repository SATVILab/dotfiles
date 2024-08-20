#!/usr/bin/env bash

# install-hpc.sh
# This script sets up the environment on an HPC by configuring environment variables,
# copying scripts and bashrc.d files, optionally copying hidden files, and setting up Git.

usage() {
    echo "Usage: $0 [-c]"
    echo "  -c                          : Copy hidden configuration files (.Renviron, .lintr, .radian_profile) to the home directory"
    echo ""
    echo "Example: $0 -c"
    echo ""
    echo "Guidelines:"
    echo "  - Use the '-c' option if you want to copy hidden configuration files to your home directory."
    echo "  - Hidden files include .Renviron, .lintr, and .radian_profile."
    exit 0
}

# Parse the command-line options
COPY_HIDDEN=false
while getopts "ch" opt; do
  case ${opt} in
    c )
      COPY_HIDDEN=true
      ;;
    h )
      usage
      ;;
    \? )
      usage
      ;;
  esac
done

# Ensure .bashrc sources .bashrc.d
if [ -e "$HOME/.bashrc" ]; then 
    if [ -z "$(grep -F bashrc.d "$HOME/.bashrc")" ]; then 
        echo 'for i in $(ls -A $HOME/.bashrc.d/); do source $HOME/.bashrc.d/$i; done' \
        >> "$HOME/.bashrc"
    fi
else
    touch "$HOME/.bashrc"
    echo 'for i in $(ls -A $HOME/.bashrc.d/); do source $HOME/.bashrc.d/$i; done' \
    > "$HOME/.bashrc"
fi

# Create directories if they don't exist
mkdir -p "$HOME/.bashrc.d"
mkdir -p "$HOME/.local/bin"

# Convert line endings and make files executable in dotfiles repo
echo "Ensuring Unix line endings and executability in dotfiles repository..."
find "$HOME/dotfiles/scripts" "$HOME/dotfiles/bashrc.d" -type f -exec dos2unix {} + -exec chmod +x {} +

# Copy files from dotfiles repo to ~/.local/bin and ~/.bashrc.d
echo "Copying scripts to ~/.local/bin and bashrc.d files to ~/.bashrc.d..."
cp -r "$HOME/dotfiles/scripts/"* "$HOME/.local/bin/"
cp -r "$HOME/dotfiles/bashrc.d/"* "$HOME/.bashrc.d/"

# Optionally copy hidden files to home directory if the -c flag is set
if [ "$COPY_HIDDEN" = true ]; then
  echo "Copying hidden configuration files to home directory..."
  cp "$HOME/dotfiles/.Renviron" "$HOME/"
  cp "$HOME/dotfiles/.lintr" "$HOME/"
  cp "$HOME/dotfiles/.radian_profile" "$HOME/"
  echo "Hidden configuration files copied to home directory."
else
  echo "Skipping copying of hidden configuration files. Use the '-c' flag to copy them."
fi

# Check Git configuration
git_name=$(git config --global user.name)
git_email=$(git config --global user.email)

# Function to trim whitespace
trim() {
    echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

if [ -z "$git_name" ]; then
    echo "Git user.name is not set."
    read -p "Enter your Git username: " git_name
    git_name=$(trim "$git_name")
    if [ -z "$git_name" ]; then
        git_name=$USER
    fi
    git config --global user.name "$git_name"
fi

if [ -z "$git_email" ]; then
    echo "Git user.email is not set."
    read -p "Enter your Git email: " git_email
    git_email=$(trim "$git_email")
    if [ -z "$git_email" ]; then
        git_email="$USER@hpc.auto"
    fi
    git config --global user.email "$git_email"
fi

# Commit and push changes to dotfiles repository if there are any changes in bashrc.d or scripts
cd "$HOME/dotfiles"
if ! git diff --quiet bashrc.d/ scripts/; then
    git add bashrc.d/* scripts/*
    git commit -m "Ensure Unix line endings and executability for scripts and bashrc.d files"
    git push
else
    echo "No changes in bashrc.d or scripts to commit."
fi

echo "HPC setup complete."
