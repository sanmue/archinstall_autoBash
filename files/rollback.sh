#!/usr/bin/env bash

# set -x # enable debug mode

# ### -------------------------------------------------------------------------
# Description
# * using snapper-rollback (AUR) to rollback to a specified snapshot ID
# * only if system:
#   - was installed via 'archinstall_autobash'
#   - uses 'systemd-boot' bootloader
# ---
# Parameter
# * parameter 1 (required): snapshot ID to rollback to
# ---
# Example
# * enter in terminal: 'rollback 8'
# ### -------------------------------------------------------------------------
snapshotsSubvolPath="/.snapshots"
machineID=$(cat /etc/machine-id)
efiPartitionPath="/efi"
efiPartition_targetPath="${efiPartitionPath}/${machineID}/" # destination for kernel and initramfs matching the snapshot ID to rollback to

if [ "$#" -eq 1 ] && [ "${1}" -ge 1 ]; then # if exactly 1 parameter is passed and is an integer >= 1
    snapshotID="${1}" # Parameter 1: snapshot ID to rollback to
    snapshot_bootFolder="${snapshotsSubvolPath}/${snapshotID}/snapshot/boot/" # source path of kernel and initramfs matching the snapshot ID to rollback to
else
    echo -e "\e[0;31mParameter error: pass exactly one parameter (snapshot ID) which has to be an integer value >= 1\e[39m"
    echo -e "Example: 'rollback 8'\nTo find the snapshot ID execute 'sudo snapper list'"
    exit 1
fi

if [[ $(command -v snapper-rollback) ]]; then
    echo "Installing 'rsync' if not available..."
    sudo pacman -S --needed --noconfirm rsync # ensure rsync is installed

    mode="test"
    read -rp "Do you want to just test or execute the rollback? ('e' = execute, other input = test): " mode
    rollbackParameter=""
    rsyncParameter=""
    if [ "${mode}" = "e" ]; then
        sudo snapper-rollback "${snapshotID}"

        echo -e "\nCopy kernel and initramfs from snapshot ${snapshotID} to '${efiPartition_targetPath}'..."
        sudo rsync -aPhEv --delete --exclude *ucode.img "${snapshot_bootFolder}" "${efiPartition_targetPath}"
    else
        rollbackParameter="--dry-run"
        rsyncParameter="--dry-run"

        echo -e "\nTESTING rollback, this is gonna be just a ${rollbackParameter}..."
        sudo snapper-rollback "${rollbackParameter}" "${snapshotID}"

        echo -e "\nCopy kernel and initramfs from snapshot ${snapshotID} to '${efiPartition_targetPath}' ${rsyncParameter}..."
        sudo rsync -aPhEv --delete --exclude *ucode.img "${rsyncParameter}" "${snapshot_bootFolder}" "${efiPartition_targetPath}"
    fi
else
    echo -e "\e[0;31m'snapper-rollback' not available, rollback not possible.\e[39m"
    exit
fi
