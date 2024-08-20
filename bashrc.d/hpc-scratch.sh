#!/usr/bin/env bash

# Exit early if /scratch/$USER directory does not exist
if [ ! -d "/scratch/$USER" ]; then
    echo "/scratch/$USER directory does not exist. Exiting script."
    exit 0
fi

# use XDG relative directories, but
# relative to /scratch/$USER
export XDG_DATA_HOME=/scratch/"$USER"/.local/share
export XDG_CACHE_HOME=/scratch/"$USER"/.cache

# set apptainer and singularity 
# cache dirs explicitly to cache
# (I think apptainer, at least, may
# ignore the XDG env vars)
export SINGULARITY_CACHE_DIR=/scratch/"$USER"/.cache/singularity
export APPTAINER_CACHE_DIR=/scratch/"$USER"/.cache/apptainer

# force renv to use /scrach
export XDG_CACHE_HOME=/scratch/"$USER"/.cache
export RENV_PATHS_ROOT=/scratch/"$USER"/.local/renv

# force R to use scratch
export R_LIBS="/scratch/$USER/.local/lib/R"
mkdir -p $R_LIBS