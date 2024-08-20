#!/usr/bin/env bash

# install.sh
# This script sets up a development environment by configuring Bash, cloning a GitHub repository,
# adding custom scripts to the user's PATH, and preparing the environment specifically for GitHub Codespaces.
# It also ensures that .bashrc sources all files in .bashrc.d.

# Function to configure .bashrc.d directory and ensure sourcing in .bashrc
config_bashrc_d() {
  echo "Configuring bashrc.d and ensuring it's sourced in .bashrc"

  if [ -e "$HOME/.bashrc" ]; then 
    # Check if .bashrc.d is already sourced in .bashrc
    if [ -z "$(grep -F bashrc.d "$HOME/.bashrc")" ]; then 
      # If not, append a command to source all files in .bashrc.d
      echo 'for i in $(ls -A $HOME/.bashrc.d/); do source $HOME/.bashrc.d/$i; done' \
        >> "$HOME/.bashrc"
      echo ".bashrc.d has been added to .bashrc for sourcing."
    else
      echo ".bashrc.d is already sourced in .bashrc."
    fi
  else
    # If .bashrc doesn't exist, create it and add the sourcing command
    touch "$HOME/.bashrc"
    echo 'for i in $(ls -A $HOME/.bashrc.d/); do source $HOME/.bashrc.d/$i; done' \
      > "$HOME/.bashrc"
    echo ".bashrc created and .bashrc.d sourcing added."
  fi

  # Create the .bashrc.d directory if it doesn't exist
  mkdir -p "$HOME/.bashrc.d"
  echo "Completed configuring bashrc.d"
}

# Function to clone a GitHub repository
clone_repo() {
  echo "Cloning GitHub repository"
  # Clone the specified GitHub repository into a temporary directory
  TMP_DIR=$(mktemp -d)
  git clone https://SATVILab/dotfiles.git "$TMP_DIR"
  echo "Successfully cloned GitHub repository SATVILab/dotfiles"
  echo "Copying scripts to ~/.local/bin..."
  cp -r "$TMP_DIR/scripts/"* "$HOME/.local/bin/"
  rm -rf "$TMP_DIR" # Remove the temporary directory after use
  echo "Scripts copied to ~/.local/bin"
}

# Function to configure the user's bin directories and update PATH
config_home_bin() {
  echo "Configuring ~/bin and ~/.local/bin directories"

  # Create directories if they don't exist
  mkdir -p "$HOME/bin" "$HOME/.local/bin"

  # Add directories to PATH if not already included
  if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
      echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
      echo "Added '~/bin' to your PATH."
  fi

  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
      echo "Added '~/.local/bin' to your PATH."
  fi

  # Source the .bashrc file to apply the changes immediately
  source "$HOME/.bashrc"

  echo "PATH configuration complete."
}

# Function to check for GitHub Codespaces and run additional setups
codespaces_setup() {
  if [[ "$CODESPACES" == "true" ]]; then
      echo "Running in a GitHub Codespace"
      # Example: Replace this line with any additional script you want to run in Codespaces
      install-jetbrains-font
  fi
}

# Main script execution
set -e

echo "Starting installation process..."
config_home_bin
clone_repo
config_bashrc_d
codespaces_setup

# Ensure all scripts in ~/.local/bin are executable
chmod -R 755 "$HOME/.local/bin/"

echo "Installation complete."
