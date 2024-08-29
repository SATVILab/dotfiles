#!/usr/bin/env bash

# Function to check and set proxy environment variables
check_proxy_vars() {
    # Print message indicating the start of the proxy check
    echo "Checking for proxy variables..."

    # Check if the hostname matches the UCT HPC naming convention
    # (e.g., srvrochpc followed by digits)
    if [[ "$HOSTNAME" =~ ^srvrochpc[0-9]+ ]]; then
        all_set=true  # Flag to track if all proxy variables are already set
        proxy_vars=(ftp_proxy https_proxy http_proxy)  # Array of proxy vars

        # Loop through each proxy variable
        for proxy in "${proxy_vars[@]}"; do
            # Check if the current proxy variable is unset or empty
            if [[ -z "${!proxy}" ]]; then
                echo "Setting $proxy..."  # Print message indicating the proxy
                export $proxy="http://10.105.1.2:8000"  # Set the proxy variable
                all_set=false  # Set flag to false if any proxy was unset
            fi
        done

        # After the loop, check if all proxy variables were set
        if [ "$all_set" = true ]; then
            echo "All proxy variables are set."  # Confirm all proxies were set
        fi
    else
        # If hostname doesn't match the UCT HPC pattern, skip setting proxies
        echo "Not setting proxy variables since not on UCT HPC"
    fi
}

# Call the function to check and set proxy variables
check_proxy_vars
