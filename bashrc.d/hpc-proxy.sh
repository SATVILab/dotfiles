#!/usr/bin/env bash

###############################################################################
# Script Name    : check_proxy_vars.sh
# Description    : Checks and sets proxy environment variables if they are
#                  not already set. This script is tailored for use on UCT
#                  HPC machines to ensure proper proxy configuration.
#
# Usage          : 
#   - To display help:
#       ./check_proxy_vars.sh --help
#   - To run the script with verbose output:
#       ./check_proxy_vars.sh --verbose
#
# Options:
#   -h, --help       Show this help message and exit
#   -V, --verbose    Enable verbose mode to echo out messages during execution
#
# Requirements    :
#   - Bash shell
#   - Must be run on UCT HPC machines matching the hostname pattern ^srvrochpc[0-9]+
#
# Environment Variables Managed:
#   - ftp_proxy
#   - https_proxy
#   - http_proxy
#
# Author         : Miguel Rodo
# Contact        : miguel.rodo@uct.ac.za
# License        : MIT License
# Version        : 1.0
# Last Modified  : 2024 Nov 17
#
# Notes          :
#   - Modify the proxy URL in the script if your environment requires a different proxy.
###############################################################################

# Function to check and set proxy environment variables
check_proxy_vars() {
    local verbose=false

    # Parse the command-line arguments
    for arg in "$@"; do
        case "$arg" in
            -h|--help)
                usage
                return 0
                ;;
            -V|--verbose)
                verbose=true
                ;;
        esac
    done

    # Function to print messages only if verbose mode is enabled
    log_verbose() {
        if [ "$verbose" = true ]; then
            echo "$1"
        fi
    }

    # Start of proxy check process
    log_verbose "Checking for proxy variables..."

    # Check if the hostname matches the UCT HPC naming convention
    if [[ "$HOSTNAME" =~ ^srvrochpc[0-9]+ ]]; then
        local all_set=true  # Flag to track if all proxy variables are already set
        local proxy_vars=(ftp_proxy https_proxy http_proxy)  # Array of proxy vars

        # Loop through each proxy variable
        for proxy in "${proxy_vars[@]}"; do
            # Check if the current proxy variable is unset or empty
            if [[ -z "${!proxy}" ]]; then
                log_verbose "Setting $proxy..."  # Log message if setting proxy
                export $proxy="http://10.105.1.2:8000"  # Set the proxy variable
                all_set=false  # Set flag to false indicating some proxies were unset
            fi
        done

        # Check if all proxy variables were set
        if [ "$all_set" = true ]; then
            log_verbose "All proxy variables are set."  # Log confirmation
        fi
    else
        # If hostname doesn't match UCT HPC, skip setting proxies
        log_verbose "Not setting proxy variables since not on UCT HPC"
    fi
}

# Call the function to check and set proxy variables, passing all arguments
if [[ "$HOSTNAME" =~ ^srvrochpc[0-9]+ ]]; then
    check_proxy_vars "$@"
fi

# Unset the function to avoid polluting the global namespace
unset -f check_proxy_vars
