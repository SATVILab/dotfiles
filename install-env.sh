#!/usr/bin/env bash
# install-env.sh
# A single installer for multiple environments: hpc, wsl, dev

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <env>

<env> must be one of:
  hpc    – HPC setup
  wsl    – WSL setup
  dev    – Devcontainer (WSL) setup

Example:
  $0 hpc
  $0 wsl
  $0 dev
EOF
  exit 1
}

# --- functions ----

# Prompt for and inject GitHub / HuggingFace creds into login.sh
configure_login() {
  local login_file="$HOME/.bashrc.d/login.sh"
  [[ -f "$login_file" ]] || return

  echo
  echo "Configure GitHub and Hugging Face credentials in login.sh (leave blank to skip):"
  read -p "  GitHub username: " gh_user
  read -p "  GitHub token:    " gh_token
  read -p "  HuggingFace PAT: " hf_pat

  # Helper to uncomment & set a var in-place
  inject() {
    local var="$1" val="$2"
    sed -i -E "s|^#\s*${var}=.*|${var}=\"${val}\"|" "$login_file"
  }

  [[ -n "$gh_user" ]] && inject GITHUB_USERNAME "$gh_user" && inject GITHUB_USER "$gh_user"
  if [[ -n "$gh_token" ]]; then
    inject GH_TOKEN         "$gh_token"
    inject GITHUB_TOKEN     "$gh_token"
    inject GITHUB_PAT       "$gh_token"
  fi
  [[ -n "$hf_pat" ]] && inject HF_PAT "$hf_pat" && inject HF_TOKEN "$hf_pat"

  echo "login.sh updated."
}

# --- parse and validate ---
if [[ $# -ne 1 ]]; then
  usage
fi

env="$1"
case "$env" in
  hpc|wsl|dev) ;;
  *)
    echo "Error: invalid environment '$env'. Use 'hpc', 'wsl' or 'dev'." >&2
    usage
    ;;
esac

# --- ensure .bashrc sources ~/.bashrc.d ---
if [[ ! -e "$HOME/.bashrc" ]]; then
  touch "$HOME/.bashrc"
fi

if ! grep -Fq '.bashrc.d' "$HOME/.bashrc"; then
  echo 'for i in $HOME/.bashrc.d/*; do [ -r "$i" ] && source "$i"; done' >> "$HOME/.bashrc"
  echo ".bashrc.d sourcing added to .bashrc."
fi

# --- prepare directories ---
mkdir -p "$HOME/.bashrc.d" "$HOME/.local/bin"

# --- convert line endings & make executable ---
echo "Ensuring Unix line endings and executability in dotfiles repository…"
if command -v dos2unix &>/dev/null; then
  find "$HOME/dotfiles/scripts" "$HOME/dotfiles/bashrc.d" -type f -exec dos2unix {} +
fi
find "$HOME/dotfiles/scripts" "$HOME/dotfiles/bashrc.d" -type f -exec chmod +x {} +

# --- copy scripts ---
echo "Copying scripts to ~/.local/bin…"
for script in "$HOME/dotfiles/scripts/"*; do
  name=$(basename "$script")
  case "$env" in
    hpc)
      cp "$script" "$HOME/.local/bin/" ;;
    wsl)
      if [[ "$name" == slurm* ]]; then
        echo "  Skipping $name"
      else
        cp "$script" "$HOME/.local/bin/"
      fi ;;
    dev)
      if [[ "$name" == slurm* || "$name" == apptainer-* ]]; then
        echo "  Skipping $name"
      else
        cp "$script" "$HOME/.local/bin/"
      fi ;;
  esac
done

# --- copy bashrc.d fragments ---
echo "Copying bashrc.d files to ~/.bashrc.d…"
for file in "$HOME/dotfiles/bashrc.d/"*; do
  filename=$(basename "$file")
  # skip HPC-only fragments in any env other than hpc
  if [[ "$env" != hpc && "$filename" == hpc-* ]]; then
    echo "  Skipping $filename (HPC-specific)"
    continue
  fi

  # preserve existing login.sh
  if [[ "$filename" == login.sh && -e "$HOME/.bashrc.d/$filename" ]]; then
    echo "  Skipping $filename (already exists)"
    continue
  fi
  if [[ "$filename" == login.sh ]]; then
    configure_login
  fi
  cp "$file" "$HOME/.bashrc.d/"
done

# --- copy hidden config files (with .Renviron sanitisation for wsl/dev) ---
hidden_files=(.Renviron .lintr .radian_profile)
echo "Copying hidden config files…"
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
            if [[ "$file" == .Renviron && ( "$env" == wsl || "$env" == dev ) ]]; then
              # remove any /scratch settings
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

# --- Git configuration ---
git_name=$(git config --global user.name || echo "")
git_email=$(git config --global user.email || echo "")

trim() {
  echo "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

if [[ -z "$git_name" ]]; then
  read -p "Enter your Git user.name: " git_name
  git_name=$(trim "$git_name")
  [[ -z "$git_name" ]] && git_name=$USER
  git config --global user.name "$git_name"
fi

if [[ -z "$git_email" ]]; then
  read -p "Enter your Git user.email: " git_email
  git_email=$(trim "$git_email")
  if [[ -z "$git_email" ]]; then
    if [[ "$env" == hpc ]]; then
      git_email="$USER@hpc.auto"
    else
      git_email="$USER@wsl.local"
    fi
  fi
  git config --global user.email "$git_email"
fi

# --- commit any repo changes ---
case "$env" in
  hpc)   commit_msg="Ensure Unix line endings and executability for scripts and bashrc.d files" ;;
  wsl)   commit_msg="Sanitise .Renviron and update executability (WSL installer)" ;;
  dev)   commit_msg="Sanitise .Renviron and update executability (Devcontainer installer)" ;;
esac

cd "$HOME/dotfiles"
if ! git diff --quiet bashrc.d/ scripts/; then
  git add bashrc.d/* scripts/*
  git commit -m "$commit_msg"
  git push
else
  echo "No changes in bashrc.d or scripts to commit."
fi

# --- final message ---
case "$env" in
  hpc) echo "HPC setup complete." ;;
  wsl) echo "WSL setup complete." ;;
  dev) echo "Devcontainer setup complete." ;;
esac
