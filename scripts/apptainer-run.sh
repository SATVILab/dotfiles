#!/usr/bin/env bash

set -e

# Function to display usage
usage() {
    echo "Usage: $0 <sif_file> [-d <directory>] [-c <command>]"
    echo "  <sif_file>      : Name of the SIF file to run"
    echo "  -d <directory>  : Directory to search for the SIF file (optional)"
    echo "  -c <command>    : Custom command to run inside the container (optional, defaults to shell)"
    exit 1
}

# Check if at least one argument is provided
if [ "$#" -lt 1 ]; then
    usage
fi

# Parse arguments
SIF_FILE="$1"
shift
DIRECTORY=""
CUSTOM_COMMAND=""

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d) DIRECTORY="$2"; shift ;;
        -c) CUSTOM_COMMAND="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Ensure the SIF_FILE ends with .sif
SIF_FILE="${SIF_FILE%.sif}.sif"

# Determine the base directories
if [ -d "/scratch/$USER/.local/share/apptainer/sif" ]; then
    SCRATCH_DIR="/scratch/$USER/.local/share/apptainer/sif"
else
    SCRATCH_DIR=""
fi

if [ -d "$HOME/.local/share/apptainer/sif" ]; then
    HOME_DIR="$HOME/.local/share/apptainer/sif"
else
    HOME_DIR=""
fi

# Determine the full path of the SIF file
if [ -n "$DIRECTORY" ]; then
    SIF_PATH="$DIRECTORY/$SIF_FILE"
elif [ -n "$SCRATCH_DIR" ] && [ -f "$SCRATCH_DIR/$SIF_FILE" ]; then
    SIF_PATH="$SCRATCH_DIR/$SIF_FILE"
elif [ -n "$HOME_DIR" ] && [ -f "$HOME_DIR/$SIF_FILE" ]; then
    SIF_PATH="$HOME_DIR/$SIF_FILE"
else
    echo "Error: SIF file '$SIF_FILE' not found in any specified or default directories."
    exit 1
fi

# Run the Apptainer image with either shell or custom command
if [ -n "$CUSTOM_COMMAND" ]; then
    echo "Running Apptainer image with custom command: $CUSTOM_COMMAND from '$SIF_PATH'"
    apptainer exec "$SIF_PATH" $CUSTOM_COMMAND
else
    echo "Running Apptainer image in shell mode from '$SIF_PATH'"
    apptainer shell "$SIF_PATH"
fi
