#!/usr/bin/env bash
# install-env.sh — unified installer for hpc, wsl, dev

set -euo pipefail

# -----------------------------------------------------------------------------
# Usage and argument parsing
# -----------------------------------------------------------------------------
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

parse_args() {
  [[ $# -eq 1 ]] || usage
  env="$1"
  case "$env" in
    hpc|wsl|dev) ;;
    *) echo "Error: invalid environment '$env'." >&2; usage ;;
  esac
}

# -----------------------------------------------------------------------------
# Ensure ~/.bashrc will source ~/.bashrc.d/*.sh fragments
# -----------------------------------------------------------------------------
ensure_bashrc_sourcing() {
  local rc="$HOME/.bashrc"
  [[ -e "$rc" ]] || touch "$rc"

  if ! grep -Fq '.bashrc.d' "$rc"; then
    echo 'for i in $HOME/.bashrc.d/*; do [ -r "$i" ] && source "$i"; done' >> "$rc"
    echo "Added .bashrc.d sourcing to $rc"
  fi
}

# -----------------------------------------------------------------------------
# Create required directories
# -----------------------------------------------------------------------------
prepare_directories() {
  mkdir -p "$HOME/.bashrc.d" "$HOME/.local/bin"
}

# -----------------------------------------------------------------------------
# Convert CRLF→LF and chmod +x in dotfiles
# -----------------------------------------------------------------------------
normalize_dotfiles() {
  echo "Normalising line endings and permissions in dotfiles…"
  if command -v dos2unix &>/dev/null; then
    find "$HOME/dotfiles/scripts" "$HOME/dotfiles/bashrc.d" -type f -exec dos2unix {} +
  fi
  find "$HOME/dotfiles/scripts" "$HOME/dotfiles/bashrc.d" -type f -exec chmod +x {} +
}

# -----------------------------------------------------------------------------
# Copy scripts into ~/.local/bin, skipping per-env patterns
# -----------------------------------------------------------------------------
copy_scripts() {
  echo "Copying scripts to ~/.local/bin…"
  for script in "$HOME/dotfiles/scripts/"*; do
    name=$(basename "$script")
    case "$env" in
      hpc)
        cp "$script" "$HOME/.local/bin/" ;;
      wsl)
        [[ "$name" == slurm* ]] && { echo "  Skipping $name"; continue; }
        cp "$script" "$HOME/.local/bin/" ;;
      dev)
        if [[ "$name" == slurm* || "$name" == apptainer-* ]]; then
          echo "  Skipping $name"; continue
        fi
        cp "$script" "$HOME/.local/bin/" ;;
    esac
  done
}

# -----------------------------------------------------------------------------
# Copy bashrc.d fragments, skipping hpc-* outside of hpc, and handle login.sh
# -----------------------------------------------------------------------------
copy_bashrc_fragments() {
  echo "Copying bashrc.d fragments…"
  for file in "$HOME/dotfiles/bashrc.d/"*; do
    filename=$(basename "$file")

    # skip HPC-only fragments in non-hpc envs
    [[ "$env" != hpc && "$filename" == hpc-* ]] && {
      echo "  Skipping $filename (HPC-specific)"; continue
    }

    # preserve existing login.sh, but still configure if newly copied
    if [[ "$filename" == login.sh && -e "$HOME/.bashrc.d/$filename" ]]; then
      echo "  Skipping $filename (already exists)"
    else
      cp "$file" "$HOME/.bashrc.d/"
      [[ "$filename" == login.sh ]] && configure_login
    fi
  done
}

# -----------------------------------------------------------------------------
# Prompt to inject GitHub & HuggingFace creds into login.sh
# -----------------------------------------------------------------------------
configure_login() {
  local login_file="$HOME/.bashrc.d/login.sh"
  [[ -f "$login_file" ]] || return

  echo
  echo "Configure GitHub & Hugging Face credentials in login.sh (leave blank to skip):"
  read -p "  GitHub username: " gh_user
  read -p "  GitHub token:    " gh_token
  read -p "  HuggingFace PAT: " hf_pat

  inject_var() {
    local var="$1" val="$2"
    sed -i -E "s|^#\s*${var}=.*|${var}=\"${val}\"|" "$login_file"
  }

  [[ -n "$gh_user" ]] && { inject_var GITHUB_USERNAME "$gh_user"; inject_var GITHUB_USER "$gh_user"; }
  if [[ -n "$gh_token" ]]; then
    inject_var GH_TOKEN "$gh_token"
    inject_var GITHUB_TOKEN "$gh_token"
    inject_var GITHUB_PAT "$gh_token"
  fi
  [[ -n "$hf_pat" ]] && { inject_var HF_PAT "$hf_pat"; inject_var HF_TOKEN "$hf_pat"; }

  echo "login.sh updated."
}

# -----------------------------------------------------------------------------
# Copy hidden config files, sanitising .Renviron for wsl/dev
# -----------------------------------------------------------------------------
copy_hidden_configs() {
  local files=( .Renviron .lintr .radian_profile )
  echo "Copying hidden config files…"

  for file in "${files[@]}"; do
    local src="$HOME/dotfiles/$file" dest="$HOME/$file"
    [[ -e "$src" ]] || { echo "  $file not found, skipping"; continue; }

    if [[ ! -e "$dest" ]] || ! cmp -s "$src" "$dest"; then
      echo
      if [[ -e "$dest" ]]; then
        echo "$file exists. Showing diff:"
        diff "$dest" "$src"
        action="overwrite"
      else
        echo "$file does not exist locally."
        action="copy"
      fi

      while true; do
        read -p "Do you want to $action $file? [y/n] " yn
        case "${yn,,}" in
          y|yes)
            if [[ "$file" == .Renviron && ( "$env" == wsl || "$env" == dev ) ]]; then
              sed -E \
                '/^(RENV_PATHS_LIBRARY_ROOT|RENV_PATHS_CACHE|RENV_PATHS_ROOT|R_LIBS)=/d' \
                "$src" > "$dest"
              echo "  Sanitised and copied $file"
            else
              cp "$src" "$dest"
              echo "  Copied $file"
            fi
            break
            ;;
          n|no)
            echo "  Skipped $file"
            break
            ;;
          *)
            echo "  Please answer y or n."
            ;;
        esac
      done
    else
      echo "  $file is up to date."
    fi
  done
}

# -----------------------------------------------------------------------------
# Prompt to set up Git user.name & user.email if missing
# -----------------------------------------------------------------------------
configure_git() {
  local name email

  name=$(git config --global user.name || echo "")
  email=$(git config --global user.email || echo "")

  prompt_for() {
    local prompt_text="$1" varname="$2" default="$3"
    read -p "$prompt_text" answer
    answer=${answer:-$default}
    [[ -n "$answer" ]] && git config --global "$varname" "$answer"
  }

  [[ -z "$name" ]]  && prompt_for "Enter Git user.name: "  "user.name"  "$USER"
  [[ -z "$email" ]] && {
    local def_email="$USER@${env=hpc? "hpc.auto":"wsl.local"}"
    prompt_for "Enter Git user.email: " "user.email" "$def_email"
  }
}

# -----------------------------------------------------------------------------
# Commit any chmod/dos2unix changes back to the dotfiles repo
# -----------------------------------------------------------------------------
commit_repo_changes() {
  local msg
  case "$env" in
    hpc) msg="Ensure Unix line endings & executability (HPC)" ;;
    wsl) msg="Sanitise .Renviron & executability (WSL)" ;;
    dev) msg="Sanitise .Renviron & executability (Devcontainer)" ;;
  esac

  cd "$HOME/dotfiles"
  if ! git diff --quiet bashrc.d/ scripts/; then
    git add bashrc.d/* scripts/*
    git commit -m "$msg"
    git push
  else
    echo "No changes in bashrc.d or scripts to commit."
  fi
}

# -----------------------------------------------------------------------------
# Print final success message
# -----------------------------------------------------------------------------
print_completion() {
  case "$env" in
    hpc)   echo "HPC setup complete." ;;
    wsl)   echo "WSL setup complete." ;;
    dev)   echo "Devcontainer setup complete." ;;
  esac
}

# -----------------------------------------------------------------------------
# Main workflow
# -----------------------------------------------------------------------------
main() {
  parse_args "$@"
  ensure_bashrc_sourcing
  prepare_directories
  normalize_dotfiles
  copy_scripts
  copy_bashrc_fragments
  copy_hidden_configs
  configure_git
  commit_repo_changes
  print_completion
}

main "$@"
