#!/usr/bin/env bash

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$dotfiles_dir/install-env.sh" codespace
