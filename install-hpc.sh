#!/usr/bin/env bash

# install-hpc.sh
# This script sets up the environment on an HPC by copying scripts from the dotfiles repository 
# to the ~/scripts directory, running the main install.sh script, and optionally copying hidden 
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

# Step 1: Copy the script files from ~/dotfiles/scripts to ~/scripts
echo "Copying scripts to ~/scripts..."
mkdir -p "$HOME/scripts"
cp -r "$HOME/dotfiles/scripts/"* "$HOME/scripts/"
echo "Scripts copied to ~/scripts."

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
