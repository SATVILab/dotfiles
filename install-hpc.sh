#!/usr/bin/env bash

# install-hpc.sh
# This script sets up the environment on an HPC by copying scripts from the dotfiles repository 
# to the ~/.local/bin directory, running the main install.sh script, and optionally copying hidden 
# configuration files (.Renviron, .lintr, .radian_profile) to the home directory based on a flag.

# Parse the command-line options
COPY_HIDDEN=false
while getopts "c" opt; do
  case ${opt} in
    c )
      COPY_HIDDEN=true
      ;;
    \? )
      echo "Usage: cmd [-c]"
      exit 1
      ;;
  esac
done

# Convert line endings for regular files only
if [ -d "$HOME/dotfiles/scripts" ]; then
  echo "Converting line endings and forcing executability on scripts"
  find "$HOME/dotfiles/scripts" -type f -exec dos2unix {} +
  chmod 755 "$HOME/dotfiles/scripts"/*
else
  echo "$HOME/dotfiles/scripts not found"
fi

# Step 1: Copy the script files from ~/dotfiles/scripts to ~/.local/bin
echo "Copying scripts to ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
cp -r "$HOME/dotfiles/scripts/"* "$HOME/.local/bin/"
echo "Scripts copied to ~/.local/bin."

# Step 2: Run the main install.sh script from the dotfiles repository
echo "Running the main install.sh script..."
bash "$HOME/dotfiles/install.sh"
echo "install.sh script executed."

# Step 3: Optionally copy hidden files to the home directory if the -c flag is set
if [ "$COPY_HIDDEN" = true ]; then
  echo "Copying hidden configuration files to home directory..."
  cp "$HOME/dotfiles/.Renviron" "$HOME/"
  cp "$HOME/dotfiles/.lintr" "$HOME/"
  cp "$HOME/dotfiles/.radian_profile" "$HOME/"
  echo "Hidden configuration files copied to home directory."
else
  echo "Skipping copying of hidden configuration files. Use the '-c' flag to copy them."
fi

echo "HPC setup complete."
