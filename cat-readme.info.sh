#!/usr/bin/env bash

# cat-readme-info
# This script concatenates the contents of various configuration and script files,
# prepends each with its filename, and outputs everything to a file named 'readme-info'.
# It then checks if the 'readme-info' file has changed and commits it to a branch named 'readme-info'.
# If the branch does not exist, it is created. The script echoes each step it performs.

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

EOF

# Save the current branch name
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Ensure there are no uncommitted changes before switching branches
if ! git diff-index --quiet HEAD --; then
    echo "Stashing uncommitted changes before switching branches."
    git stash -u
    stash_applied=true
else
    stash_applied=false
fi

# Switch to the 'readme-info' branch, creating it if necessary
if git show-ref --verify --quiet refs/heads/readme-info; then
    echo "Switching to existing 'readme-info' branch."
    git checkout readme-info
else
    echo "'readme-info' branch does not exist. Creating and switching to it."
    git checkout -b readme-info
fi

# Check if the readme-info file has changed
if ! git diff --quiet -- "$OUTPUT_FILE"; then
    echo "Changes detected in $OUTPUT_FILE. Adding, committing, and force-pushing changes."
    git add "$OUTPUT_FILE"
    git commit -m "Update $OUTPUT_FILE with latest configuration and script content"
    git push --force origin readme-info
else
    echo "No changes detected in $OUTPUT_FILE. Nothing to commit."
fi

# Switch back to the original branch
echo "Switching back to the original branch '$current_branch'."
git checkout "$current_branch"

# Apply stashed changes if any were stashed
if [ "$stash_applied" = true ]; then
    echo "Reapplying stashed changes."
    git stash pop
fi

echo "cat-readme-info process complete."
