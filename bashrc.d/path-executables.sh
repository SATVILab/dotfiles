#!/usr/bin/env bash

# This script ensures that ~/bin and ~/.local/bin are included in the user's PATH.
# It checks if these directories are in the PATH and adds them if they are not.

if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    export PATH="$HOME/bin:$PATH"
fi

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
