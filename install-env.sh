#!/usr/bin/env bash
# install-env.sh — unified installer for hpc, wsl, dev, linux

set -euo pipefail

# -----------------------------------------------------------------------------
# Usage and argument parsing
# -----------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $0 <env>

<env> must be one of:
  hpc       - HPC setup
  linux     - Linux setup (not in a container)
  wsl       - WSL setup (not in a container)
  dev       - Devcontainer setup inside Linux/WSL
  codespace - Devcontainer setup inside Codespace setup)

Example:
  $0 hpc
  $0 linux
  $0 wsl
  $0 dev
  $0 codespace
EOF
  exit 1
}

parse_args() {
  [[ $# -eq 1 ]] || usage
  dotfiles_env="$1"
  case "$dotfiles_env" in
    hpc|linux|wsl|dev|codespace|codespaces) ;;
    *) echo "Error: invalid environment '$dotfiles_env'." >&2; usage ;;
  esac
  if [[ "$dotfiles_env" == "codespaces" ]]; then
    dotfiles_env="codespace"
  fi
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
  local dotfiles_dir
  dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if command -v dos2unix &>/dev/null; then
    find "$dotfiles_dir/scripts" "$dotfiles_dir/bashrc.d" -type f -exec dos2unix {} +
  fi
  find "$dotfiles_dir/scripts" "$dotfiles_dir/bashrc.d" -type f -exec chmod +x {} +
}

# -----------------------------------------------------------------------------
# Copy scripts into ~/.local/bin, skipping per-env patterns
# -----------------------------------------------------------------------------
copy_scripts() {
  echo "Copying scripts to ~/.local/bin…"
  shopt -s nullglob
  local dotfiles_dir
  dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  for script in "$dotfiles_dir/scripts/"*; do
    name=$(basename "$script")
    case "$dotfiles_env" in
      hpc)
        cp "$script" "$HOME/.local/bin/" ;;
      wsl)
        [[ "$name" == slurm* ]] && { echo "  Skipping $name"; continue; }
        cp "$script" "$HOME/.local/bin/" ;;
      linux)
        [[ "$name" == slurm* ]] && { echo "  Skipping $name"; continue; }
        cp "$script" "$HOME/.local/bin/" ;;
      dev)
        if [[ "$name" == slurm* || "$name" == apptainer-* ]]; then
          echo "  Skipping $name"; continue
        fi
        cp "$script" "$HOME/.local/bin/" ;;
      codespace)
        if [[ "$name" == slurm* || "$name" == apptainer-* || "$name" == "dotfiles-update" ]]; then
          echo "  Skipping $name"; continue
        fi
        cp "$script" "$HOME/.local/bin/" ;;
    esac
  done
  shopt -u nullglob
}

# -----------------------------------------------------------------------------
# Copy bashrc.d fragments, skipping hpc-* outside of hpc, and handle login.sh
# -----------------------------------------------------------------------------
copy_bashrc_fragments() {
  echo "Copying bashrc.d fragments…"
  local dotfiles_dir
  dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  shopt -s nullglob
  for file in "$dotfiles_dir/bashrc.d/"*; do
    filename=$(basename "$file")

    # skip HPC-only fragments in non-hpc envs
    if [[ "$dotfiles_env" != hpc && "$filename" == hpc-* ]]; then
      echo "  Skipping $filename (HPC-specific)"
      continue
    fi

    # preserve existing login.sh, but still configure if newly copied
    if [[ "$filename" == login.sh && -e "$HOME/.bashrc.d/$filename" ]]; then
      echo "  Skipping $filename (already exists)"
    else 
      cp "$file" "$HOME/.bashrc.d/"
      # don't need to do manually add creds in a codespace,
      # as these can be injected by codespace secrets.
      # but we still want to export GITHUB_PAT as GH_TOKEN,
      # for example, if it's not yet set, so we didn't
      # skip the copy step above.
      if [[ "$filename" == login.sh && "$dotfiles_env" != codespace ]]; then
        echo "  Configuring $filename"
        configure_login
      fi
    fi
  done
  shopt -u nullglob
}

# -----------------------------------------------------------------------------
# Prompt to inject GitHub & HuggingFace creds into login.sh
# -----------------------------------------------------------------------------
configure_login() {
  local login_file="$HOME/.bashrc.d/login.sh"
  [[ -f "$login_file" ]] || return
  if [[ "$dotfiles_env" == "dev" || "$dotfiles_env" == "codespace" ]]; then
    return
  fi

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
copy_hidden_configs_r() {
  echo "Copying hidden config files…"

  # If in dev or codespace, and R not available, skip copying R configs
  if [[ "$dotfiles_env" == "dev" || "$dotfiles_env" == "codespace" ]]; then
    if ! command -v R &> /dev/null; then
      echo "R not found, skipping all R config files in $dotfiles_env environment."
      return
    fi
  fi

  local files=( .Renviron .lintr .radian_profile )
  local dotfiles_dir
  dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  for file in "${files[@]}"; do
    local src="$dotfiles_dir/r/$file" dest="$HOME/$file"
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

      if auto_approve; then
        yn="y"
      else
        while true; do
          read -p "Do you want to $action $file (likely say yes if unsure)? [y/n] " yn
          case "${yn,,}" in
            y|yes|n|no) break ;;
            *) echo "  Please answer y or n." ;;
          esac
        done
      fi

      if [[ "${yn,,}" == "y" || "${yn,,}" == "yes" ]]; then
        # .Renviron special handling
        if [[ "$file" == ".Renviron" && "$dotfiles_env" != "hpc" ]]; then
          sed -E \
            '/^(RENV_PATHS_LIBRARY_ROOT|RENV_PATHS_CACHE|RENV_PATHS_ROOT|R_LIBS)=/d' \
            "$src" > "$dest"
          echo "  Sanitised and copied $file"
        else
          cp "$src" "$dest"
          echo "  Copied $file"
        fi
      else
        echo "  Skipped $file"
      fi
    else
      echo "  $file is up to date."
    fi
  done
}


auto_approve() {
  # automatically copy config across for devcontainers 
  # (either in codespaces or otherwise e.g. wsl)
  [[ "$dotfiles_env" == "dev" || "$dotfiles_env" == "codespace" ]]
}

# -----------------------------------------------------------------------------
# Prompt to set up Git user.name & user.email if missing
# -----------------------------------------------------------------------------
configure_git() {
  git config --global core.autocrlf input
  local name email def_email

  name=$(git config --global user.name || echo "")
  email=$(git config --global user.email || echo "")

  # Choose default email domain by environment
  case "$dotfiles_env" in
    hpc)       def_email="$USER@hpc.auto" ;;
    wsl)       def_email="$USER@wsl.local" ;;
    dev)       def_email="$USER@dev.local" ;;
    codespace) def_email="$USER@codespace.local" ;;
    linux|*)   def_email="$USER@linux.local" ;;
  esac

  if auto_approve; then
    # Use sensible defaults without prompting
    [[ -z "$name" ]]  && git config --global user.name  "$USER"
    [[ -z "$email" ]] && git config --global user.email "$def_email"
  else
    prompt_for() {
      local prompt_text="$1" varname="$2" default="$3"
      read -p "$prompt_text" answer
      answer=${answer:-$default}
      [[ -n "$answer" ]] && git config --global "$varname" "$answer"
    }

    [[ -z "$name" ]]  && prompt_for "Enter Git user.name: "  "user.name"  "$USER"
    [[ -z "$email" ]] && prompt_for "Enter Git user.email: " "user.email" "$def_email"
  fi
}


# -----------------------------------------------------------------------------
# Print final success message
# -----------------------------------------------------------------------------
print_completion() {
  case "$dotfiles_env" in
    hpc)    echo "HPC setup complete." ;;
    linux)  echo "Linux setup complete." ;;
    wsl)    echo "WSL setup complete." ;;
    dev)    echo "Devcontainer setup complete." ;;
    codespace) echo "Codespace setup complete." ;;
  esac
}

# -----------------------------------------------------------------------------
# Unset the dotfiles_env variable to avoid conflicts
# -----------------------------------------------------------------------------
unset_dotfiles_env() {
  unset dotfiles_env
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
  copy_hidden_configs_r
  configure_git
  print_completion
  unset_dotfiles_env
}

main "$@"
