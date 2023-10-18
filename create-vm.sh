#!/bin/bash

set -e
set -x

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <BUTANEFILE> <HOSTNAME>"
    exit 1
fi

BUTANEFILE="$1"
HOSTNAME="$2"

# Create the ignition file
tmp_ign_file=$(mktemp)
trap 'rm -f "$tmp_ign_file"' EXIT
envsubst '$HOSTNAME $TSKEY' < "$BUTANEFILE" | butane -ps -d contents -o "$tmp_ign_file"

IGNITION_DEVICE_ARG=(--qemu-commandline="-fw_cfg name=opt/com.coreos/config,file=${tmp_ign_file}")

chcon --verbose --type svirt_home_t "${tmp_ign_file}"

virt-install --connect="qemu:///session" --name="${HOSTNAME}" \
	--vcpus=2 --memory=2048 \
	--os-variant="fedora-coreos-stable" --import --graphics=none \
	--disk="size=10,backing_store=/home/parallels/.local/share/libvirt/images/fedora-coreos-38.20230918.3.2-qemu.aarch64.qcow2" \
	--network bridge=virbr0 "${IGNITION_DEVICE_ARG[@]}"