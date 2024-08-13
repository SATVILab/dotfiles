#!/usr/bin/env bash

# install.sh
# This script sets up a development environment by configuring Bash, cloning a GitHub repository,
# adding custom scripts to the user's PATH, and preparing the environment specifically for GitHub Codespaces.
# It ensures that necessary directories and files exist, updates the user's .bashrc to source 
# additional configurations, and optionally runs additional setup commands in a Codespace.

# Function to configure .bashrc.d directory
config_bashrc_d() {
  echo "Configuring bashrc.d"
  # Ensure that files in .bashrc.d are sourced in the .bashrc file

  if [ -e "$HOME/.bashrc" ]; then 
    # Check if .bashrc.d is already sourced in .bashrc
    if [ -z "$(grep -F bashrc.d "$HOME/.bashrc")" ]; then 
      # If not, append a command to source all files in .bashrc.d
      echo 'for i in $(ls -A $HOME/.bashrc.d/); do source $HOME/.bashrc.d/$i; done' \
        >> "$HOME/.bashrc"
    fi
  else
    # If .bashrc doesn't exist, create it and add the sourcing command
    touch "$HOME/.bashrc"
    echo 'for i in $(ls -A $HOME/.bashrc.d/); do source $HOME/.bashrc.d/$i; done' \
      > "$HOME/.bashrc"
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
  git clone https://github.com/MiguelRodo/dotfiles "$TMP_DIR"
  echo "Successfully cloned GitHub repository MiguelRodo/dotfiles"
}

# Function to configure the user's bin directories and update PATH
config_home_bin() {
  echo "Configuring ~/bin and ~/.local/bin directories"
  
  # Create ~/bin and ~/.local/bin directories if they don't exist
  mkdir -p "$HOME/bin"
  mkdir -p "$HOME/.local/bin"

  # Add ~/bin to PATH if it's not already included
  if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
      echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
      echo "Added '~/bin' to your PATH."
  else
      echo "'~/bin' is already in your PATH."
  fi

  # Add ~/.local/bin to PATH if it's not already included
  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
      echo "Added '~/.local/bin' to your PATH."
  else
      echo "'~/.local/bin' is already in your PATH."
  fi

  # Source the .bashrc file to apply the changes immediately
  source "$HOME/.bashrc"

  echo "Setup complete. You can now place your scripts in '~/bin' or '~/.local/bin' directories."
}

dos2unix scripts/*

# Execute the functions defined above
config_home_bin
clone_repo
cp -r "$TMP_DIR/scripts/" "$HOME/.local/bin" # Copy scripts to ~/.local/bin
rm -rf "$TMP_DIR" # Remove the temporary directory after use

config_bashrc_d

# Check if running in a GitHub Codespace for the user 'MiguelRodo'
if [[ "$GITHUB_USER" == "MiguelRodo" && "$CODESPACES" == "true" ]]; then
    echo "Running script in a Codespace for user MiguelRodo"
    # Example: Replace this line with any additional script you want to run in Codespaces
    install-jetbrains-font
fi

if [ -f "$HOME/install-hpc.sh" ]; then
  rm "$HOME/install-hpc.sh"
fi

chmod -R 755 "$HOME/.local/bin/"
