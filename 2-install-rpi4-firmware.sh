#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.
set -x  # Debugging mode

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <FCOSDISK>"
    exit 1
fi

FCOSDISK="$1"

FCOSEFIPARTITION=$(lsblk "$FCOSDISK" -J -oLABEL,PATH  | jq -r '.blockdevices[] | select(.label == "EFI-SYSTEM")'.path)
BOOTPARTITION=$(lsblk "$FCOSDISK" -J -oLABEL,PATH  | jq -r '.blockdevices[] | select(.label == "boot")'.path)
TEMP_DIR=$(mktemp -d)

# Unmount any mounted partitions
PARTITIONS=$(lsblk -pln "$FCOSDISK" -o NAME | grep -oP '^/dev/[^ ]+')
for partition in $PARTITIONS; do
    if mountpoint -q "$partition"; then
        sudo umount "$partition"
    fi
done

# Add the UEFI firmware
sudo mount "$FCOSEFIPARTITION" "$TEMP_DIR" 
trap 'sudo umount "$TEMP_DIR" || true; rm -rf "$TEMP_DIR"' EXIT
pushd "$TEMP_DIR"
VERSION=v1.34  # use latest one from https://github.com/pftf/RPi4/releases
sudo curl -LO "https://github.com/pftf/RPi4/releases/download/${VERSION}/RPi4_UEFI_Firmware_${VERSION}.zip" \
&& sudo unzip "RPi4_UEFI_Firmware_${VERSION}.zip" \
&& sudo rm "RPi4_UEFI_Firmware_${VERSION}.zip"
popd

# Fix the boot hang bug with tune2fs on the the boot partition
sudo e2fsck -f "$BOOTPARTITION"
sudo tune2fs -U random "$BOOTPARTITION"
