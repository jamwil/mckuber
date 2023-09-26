#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.
set -x  # Print commands and their arguments as they are executed.

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <FCOSDISK> <IGN_FILEPATH> <HOSTNAME>"
    exit 1
fi

FCOSDISK="$1"
IGN_FILEPATH="$2"
HOSTNAME="$3"
STREAM=stable  # or `next` or `testing`

# Hot-swap the hostname
tmp_ign_file=$(mktemp)
trap 'rm -f "$tmp_ign_file"' EXIT
encoded_hostname=$(printf "%s" "$HOSTNAME" | jq -sRr @uri)
jq --arg new_hostname "data:,$encoded_hostname" \
    'walk(if type == "object" and .path == "/etc/hostname" then .contents.source = $new_hostname else . end)' \
    "$IGN_FILEPATH" > "$tmp_ign_file"

# Create the partitions on the target disk
sudo coreos-installer install -a aarch64 -s "$STREAM" -i "$tmp_ign_file" "$FCOSDISK"
