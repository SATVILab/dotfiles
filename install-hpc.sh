#!/usr/bin/env bash

# install-hpc.sh
# This script sets up the environment on an HPC by configuring environment variables,
# copying scripts and bashrc.d files, copying hidden files, and setting up Git.

# Ensure .bashrc sources .bashrc.d
if [ ! -e "$HOME/.bashrc" ]; then
    touch "$HOME/.bashrc"
fi

if ! grep -Fq ".bashrc.d" "$HOME/.bashrc"; then 
    echo 'for i in $HOME/.bashrc.d/*; do [ -r "$i" ] && source "$i"; done' >> "$HOME/.bashrc"
    echo ".bashrc.d sourcing added to .bashrc."
fi

# Create directories if they don't exist
mkdir -p "$HOME/.bashrc.d" "$HOME/.local/bin"

# Convert line endings and make files executable in dotfiles repo
echo "Ensuring Unix line endings and executability in dotfiles repository..."

if command -v dos2unix &> /dev/null; then
    echo "Converting line endings to Unix format..."
    find "$HOME/dotfiles/scripts" "$HOME/dotfiles/bashrc.d" -type f -exec dos2unix {} +
fi

# Make files executable
echo "Making files executable..."
find "$HOME/dotfiles/scripts" "$HOME/dotfiles/bashrc.d" -type f -exec chmod +x {} +

# Copy scripts and bashrc.d files
echo "Copying scripts to ~/.local/bin..."
cp -r "$HOME/dotfiles/scripts/"* "$HOME/.local/bin/"

echo "Copying bashrc.d files to ~/.bashrc.d..."
for file in "$HOME/dotfiles/bashrc.d/"*; do
    filename=$(basename "$file")
    if [ "$filename" = "login.sh" ] && [ -e "$HOME/.bashrc.d/$filename" ]; then
        echo "Skipping $filename because it already exists in ~/.bashrc.d"
    else
        cp "$file" "$HOME/.bashrc.d/"
    fi
done

# Prepare to copy hidden configuration files
hidden_files=(".Renviron" ".lintr" ".radian_profile")

for file in "${hidden_files[@]}"; do
    src="$HOME/dotfiles/$file"
    dest="$HOME/$file"
    if [ -e "$src" ]; then
        if [ ! -e "$dest" ] || ! cmp -s "$src" "$dest"; then
            # Display differences if the file exists
            if [ -e "$dest" ]; then
                echo -e "\n$file exists. Here are the differences in $file:"
                diff "$dest" "$src"
                echo -e "\nDo you want to overwrite $file in your home directory?"
                echo -e "\nIf you're really not sure, then you should probably say no (and consider manually incorporating changes)."
            else
                echo -e "\nFile $file does not exist in your home directory."
                echo -e "\nDo you want to copy $file to your home directory?"
                echo -e "\nIf you're really not sure, then you should probably say yes."
            fi
            while true; do
                read -p "Enter y or n: " confirm
                confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')
                if [ "$confirm" = "y" ] || [ "$confirm" = "yes" ]; then
                    cp "$src" "$dest"
                    echo "$file copied to home directory."
                    break
                elif [ "$confirm" = "n" ] || [ "$confirm" = "no" ]; then
                    echo "Skipped copying $file."
                    break
                else
                    echo "Invalid input. Please enter 'y' or 'n' (or 'yes' or 'no')."
                fi
            done
        else
            echo "$file is up to date."
        fi
    else
        echo "Source file $src does not exist. Skipping."
    fi
done

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
