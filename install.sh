#!/usr/bin/env bash

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ "$CODESPACES" = "true" ]; then
  echo "Running in Codespaces environment"
  "$dotfiles_dir/install-env.sh" codespace
else
  echo "Not running in Codespaces environment"
  "$dotfiles_dir/install-env.sh" dev
fi

