#!/usr/bin/env bash

# install-wsl.sh
# This script sets up the environment in WSL by configuring environment variables,
# copying scripts (excluding slurm/*) and bashrc.d files, copying hidden files,
# and setting up Git. It also sanitises .Renviron by removing any /scratch paths.

set -euo pipefail

# Ensure .bashrc sources .bashrc.d
if [[ ! -e "$HOME/.bashrc" ]]; then
  touch "$HOME/.bashrc"
fi

if ! grep -Fq ".bashrc.d" "$HOME/.bashrc"; then
  echo 'for i in $HOME/.bashrc.d/*; do [ -r "$i" ] && source "$i"; done' >> "$HOME/.bashrc"
  echo ".bashrc.d sourcing added to .bashrc."
fi

# Create necessary directories
mkdir -p "$HOME/.bashrc.d" "$HOME/.local/bin"

echo "Ensuring Unix line endings and executability in dotfiles repository..."
if command -v dos2unix &>/dev/null; then
  find "$HOME/dotfiles/scripts" "$HOME/dotfiles/bashrc.d" -type f -exec dos2unix {} +
fi
find "$HOME/dotfiles/scripts" "$HOME/dotfiles/bashrc.d" -type f -exec chmod +x {} +

# Copy scripts, excluding any slurm/* scripts
echo "Copying non-slurm scripts to ~/.local/bin..."
for script in "$HOME/dotfiles/scripts/"*; do
  name=$(basename "$script")
  if [[ "$name" == slurm* ]]; then
    echo "  Skipping $name"
  else
    cp "$script" "$HOME/.local/bin/"
  fi
done

# Copy bashrc.d files
echo "Copying bashrc.d files to ~/.bashrc.d..."
for file in "$HOME/dotfiles/bashrc.d/"*; do
  filename=$(basename "$file")
  if [[ "$filename" == "login.sh" && -e "$HOME/.bashrc.d/$filename" ]]; then
    echo "  Skipping $filename (already exists)"
  else
    cp "$file" "$HOME/.bashrc.d/"
  fi
done

# Copy hidden config files, sanitising .Renviron
hidden_files=( ".Renviron" ".lintr" ".radian_profile" )

for file in "${hidden_files[@]}"; do
  src="$HOME/dotfiles/$file"
  dest="$HOME/$file"
  if [[ -e "$src" ]]; then
    if [[ ! -e "$dest" ]] || ! cmp -s "$src" "$dest"; then
      echo
      if [[ -e "$dest" ]]; then
        echo "$file exists. Differences:"
        diff "$dest" "$src"
        prompt="overwrite"
      else
        echo "File $file does not exist locally."
        prompt="copy"
      fi
      while true; do
        read -p "Do you want to $prompt $file to your home directory? [y/n] " yn
        case "${yn,,}" in
          y|yes)
            if [[ "$file" == ".Renviron" ]]; then
              # strip out any lines referring to /scratch paths
              sed -E '/^(RENV_PATHS_LIBRARY_ROOT|RENV_PATHS_CACHE|RENV_PATHS_ROOT|R_LIBS)=/d' "$src" > "$dest"
              echo "Sanitised and copied .Renviron"
            else
              cp "$src" "$dest"
              echo "Copied $file"
            fi
            break
            ;;
          n|no)
            echo "Skipped $file"
            break
            ;;
          *)
            echo "Please answer y or n."
            ;;
        esac
      done
    else
      echo "$file is up to date."
    fi
  else
    echo "Source $src not found; skipping."
  fi
done

# Configure Git if needed
git_name=$(git config --global user.name || echo "")
git_email=$(git config --global user.email || echo "")

trim() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

if [[ -z "$git_name" ]]; then
  read -p "Enter your Git user.name: " git_name
  git_name=$(trim "$git_name")
  [[ -z "$git_name" ]] && git_name=$USER
  git config --global user.name "$git_name"
fi

if [[ -z "$git_email" ]]; then
  read -p "Enter your Git user.email: " git_email
  git_email=$(trim "$git_email")
  [[ -z "$git_email" ]] && git_email="$USER@wsl.local"
  git config --global user.email "$git_email"
fi

# Commit any chmod/dos2unix changes in the repo
cd "$HOME/dotfiles"
if ! git diff --quiet bashrc.d/ scripts/; then
  git add bashrc.d/* scripts/*
  git commit -m "Sanitise .Renviron and update executability (WSL installer)"
  git push
else
  echo "No changes in bashrc.d or scripts to commit."
fi

echo "WSL setup complete."
