#!/usr/bin/env bash

# Install fontconfig, wget and unzip
sudo apt-get update && sudo apt-get install -y fontconfig wget unzip jq

# Create a directory for the font
sudo mkdir -p /tmp/jetbrains-mono

# Download JetBrains Mono font
sudo wget -P /tmp/jetbrains-mono https://download.jetbrains.com/fonts/JetBrainsMono-2.242.zip

# Unzip the downloaded file
sudo unzip /tmp/jetbrains-mono/JetBrainsMono-2.242.zip -d /tmp/jetbrains-mono

# Install the font
sudo mkdir -p /usr/share/fonts/truetype/jetbrains
sudo mv /tmp/jetbrains-mono/fonts/ttf/*.ttf /usr/share/fonts/truetype/jetbrains
sudo fc-cache -f -v

# Clean up
cd ..
sudo rm -rf /tmp/jetbrains-mono

# Path to your settings.json file
SETTINGS_PATH="$HOME/.vscode-remote/data/Machine/settings.json"

# Check if the settings file exists and create it if it doesn't
if [ ! -f "$SETTINGS_PATH" ]; then
    echo "{}" | sudo tee "$SETTINGS_PATH"
fi

# Update the settings
jq '. + {
    "editor.fontFamily": "JetBrains Mono, Consolas, Courier New, monospace",
    "editor.fontSize": 15,
    "editor.lineHeight": 18,
    "terminal.integrated.fontFamily": "JetBrains Mono",
    "terminal.integrated.fontSize": 15,
    "terminal.integrated.lineHeight": 1.2
}' "$SETTINGS_PATH" | sudo tee temp.$$.json && sudo mv temp.$$.json "$SETTINGS_PATH"