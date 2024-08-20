#!/usr/bin/env bash

# cat-readme-info
# This script concatenates the contents of various configuration and script files,
# prepends each with its filename, and outputs everything to a file named 'readme-info'.
# The script echoes each step it performs.

# Define the output file
OUTPUT_FILE="readme-info"

# Start with a clean output file
echo "Starting the cat-readme-info process. Creating or overwriting the $OUTPUT_FILE file."
echo "This file contains information from various configuration and script files." > $OUTPUT_FILE

# Function to cat file contents with a filename header
cat_with_filename() {
    local file=$1
    echo "Adding contents of $file to $OUTPUT_FILE..."
    echo "=== Content of $file ===" >> $OUTPUT_FILE
    cat "$file" >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
}

# List of files to include
files=(
    "README.md"
    "scripts/*"
    "bashrc.d/*"
    "install-hpc.sh"
    "install.sh"
    "$HOME/.gitconfig"
    "$HOME/.lintr"
    "$HOME/.radian_profile"
    "$HOME/.Renviron"
)

# Process each file
for file_pattern in "${files[@]}"; do
    for file in $file_pattern; do
        if [ -f "$file" ]; then
            cat_with_filename "$file"
        else
            echo "No files found for pattern $file_pattern."
        fi
    done
done

# Add a message for ChatGPT to update the README.md
echo "Adding instructions for ChatGPT to update the README.md file."
cat <<EOF >> $OUTPUT_FILE

=== ChatGPT Instructions ===
Please update the README.md file based on the content provided here. Ensure the following elements are included:
- **Entry Points**: Highlight the main scripts such as \`install.sh\`, \`install-hpc.sh\`, and the update script for HPCs \`hpc-dotfiles-update\`. Make sure these are mentioned prominently upfront.
- **TL;DR Section**: Ensure there is a brief summary section at the top for quick understanding, including entry points and common use cases.
- **Help Options**: Mention that most functions and scripts have a help option. Users can run \`<command> -h\` to find out more about each command.
- **Descriptions**: Provide brief descriptions of individual functions, especially the key ones. 
- **Maintain Links**: Keep any existing useful links and add new ones as appropriate.

In your response, DO NOT print out anything other than just the updated README.md file content.
For example, do not have an introductory message saying what you're about to do or a 
closing message saying what you've done.
Your output should just be something I can copy and paste directly into a Markdown document
(i.e. I want the raw Markdown).
That said, DO NOT put the entire output inside Markdown fences (e.g. ```markdown at the front and end).
All I want is to be able to click that copy button at the bottom of your next message
and be able to paste that directly into a Markdown doc.
Make sure that the last line is blank.

EOF

echo "cat-readme-info process complete."
