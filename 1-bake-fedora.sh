#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.
set -x  # Print commands and their arguments as they are executed.

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <FCOSDISK> <BUTANEFILE> <HOSTNAME>"
    exit 1
fi

FCOSDISK="$1"
BUTANEFILE="$2"
HOSTNAME="$3"
STREAM=stable  # or `next` or `testing`

# Create the ignition file
tmp_ign_file=$(mktemp)
trap 'rm -f "$tmp_ign_file"' EXIT
envsubst '$PASSWORD $HOSTNAME $TSKEY $K3S_URL $K3S_TOKEN $K3S_VPN_AUTH' < "$BUTANEFILE" | butane -ps -d contents -o "$tmp_ign_file"

# Create the partitions on the target disk
sudo coreos-installer install -a aarch64 -s "$STREAM" -i "$tmp_ign_file" "$FCOSDISK"
