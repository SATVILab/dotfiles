#!/usr/bin/env bash

set -e

# Function to display usage
usage() {
    echo "Usage: $0 [-r <github_repo>] [-u <github_user>] [-p <password>] [-i <image_name>] [-n <sif_name>] [-t <tag>] [--force]"
    echo "  -r <github_repo>  : GitHub repository (owner/repo)"
    echo "  -u <github_user>  : GitHub username"
    echo "  -p <password>     : Password or token (optional, defaults to GH_TOKEN env var)"
    echo "  -i <image_name>   : Image name (optional, defaults to basename of the repo, forced to lowercase)"
    echo "  -n <sif_name>     : SIF file name (optional, defaults to basename of the repo, forced to lowercase and ending with .sif)"
    echo "  -t <tag>          : Tag (optional, defaults to 'latest')"
    echo "  --force           : Force download and overwrite existing SIF file"
    exit 1
}

# Initialize default values
TAG="latest"
FORCE=false

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r) GITHUB_REPO="$2"; shift ;;
        -u) GITHUB_USER="$2"; shift ;;
        -p) PASSWORD="$2"; shift ;;
        -i) IMAGE_NAME="$2"; shift ;;
        -n) SIF_NAME="$2"; shift ;;
        -t) TAG="$2"; shift ;;
        --force) FORCE=true ;;
        *) usage ;;
    esac
    shift
done

# Check mandatory parameters
if [ -z "$GITHUB_REPO" ] || [ -z "$GITHUB_USER" ]; then
    usage
fi

# Set default values if not provided
IMAGE_NAME=${IMAGE_NAME:-$(basename "$GITHUB_REPO" | tr '[:upper:]' '[:lower:]')}
SIF_NAME=${SIF_NAME:-$(basename "$GITHUB_REPO" | tr '[:upper:]' '[:lower:]')}

# Ensure the SIF_NAME ends with .sif
SIF_NAME="${SIF_NAME%.sif}.sif"

# Determine the base directory based on the availability of /scratch/$USER
if [ -d "/scratch/$USER" ]; then
    base_dir="/scratch/$USER/.local/share/apptainer/sif"
else
    base_dir="$HOME/.local/share/apptainer/sif"
fi

# Create the base directory if it doesn't exist
mkdir -p "$base_dir"

# Full path for the SIF file
SIF_FILE="$base_dir/$SIF_NAME"

# Check if SIF file already exists
if [ -f "$SIF_FILE" ] && [ "$FORCE" = false ]; then
    echo "Error: SIF file '$SIF_FILE' already exists. Use --force to overwrite."
    exit 1
fi

# Set the password (GH_TOKEN) if not provided
PASSWORD=${PASSWORD:-$GH_TOKEN}

if [ -z "$PASSWORD" ]; then
    echo "Error: No password provided and GH_TOKEN is not set."
    exit 1
fi

# Function to build Apptainer image
build_apptainer() {
    echo "Starting Apptainer build process"
    
    echo "Logging into GitHub Container Registry"
    echo "$PASSWORD" | apptainer registry login -u "$GITHUB_USER" --password-stdin docker://ghcr.io
    
    echo "Building Apptainer image '$SIF_FILE' from Docker image 'docker://ghcr.io/$GITHUB_REPO/$IMAGE_NAME:$TAG'"
    apptainer build "$SIF_FILE" "docker://ghcr.io/$GITHUB_REPO/$IMAGE_NAME:$TAG"
    
    echo "Apptainer build process completed"
}

# Run the build function
build_apptainer

echo "Apptainer image '$SIF_FILE' created successfully"
