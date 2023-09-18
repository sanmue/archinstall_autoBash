#!/usr/bin/env bash

set -x   # enable debug mode

# ----------------------------------------------------------------
# Name                 archinstall_autoBash.sh
# Description          simple rudimentary bash script to automate my arch linux installation
#                      * 1st part: live environment
# Author               Sandro Müller (sandro(ÄT)universalaccount.de)
# Licence              GPLv3
# ----------------------------------------------------------------


# ------------------
# Config / Variables
# ------------------
echo -e "\n\n\e[0;36m# Sourcing 'archinstall_autoBash.config' \e[39m"
# shellcheck source=archinstall_autoBash.config
source archinstall_autoBash.config   # including the separate file containing the config / variables used by the script


# ---------
# Functions
# ---------
echo -e "\n\n\e[0;36m# Sourcing 'archinstall_autoBash.shlib' \e[39m"
# shellcheck source=archinstall_autoBash.shlib
source archinstall_autoBash.shlib    # including the separate file containing the functions used by the script


# ----
# main
# ----

echo -e "\n\n\e[0;36m# --- Pre-installation --- \e[39m"
echo -e "\n\e[0;35m## Setting console keyboard layout and terminal font \e[39m"
loadkeys "${consoleKeyboardLayout}"    # set console keyboard layout  (temporary for current session)
setfont "${terminalFont}"              # set terminal font (temporary for current session)

#TODO Verify the boot mode
#TODO Check internet connection

echo -e "\n\e[0;35m## Update the system clock (set-timezone) \e[39m"
timedatectl set-timezone "${timezone}" # set timezone
#timedatectl status                    # show timezone settings

#TODO Check for existing partition(s) (would be overwritten via function "partition-disk")

echo "- show available block devices:"
echo "${initialLsblk}"                 # show available block devices at script start, except type 'rom' or 'loop' or 'airoot'
echo "- checking if device path '${device}' is valid"
check-devicePath "${device}"           # check if given device path is valid

if [ ${partitionDisk} = "true" ]; then        # if partitioning the device should be executed by the script
    echo -e "\n\e[0;35m## Partitioning the disk '${device}'...\e[39m"

    erase-device "${device}" "${blockSize}"   # executed only if eraseDisk="true" is set # the device will be erased (overwritten via dd command)
    partition-disk "${bootMode}" "${partitionType}" "${device}" "${swapPartitionSize}" "${efiPartitionSize}"   # partition the device
    echo "- show available block devices:"
    lsblk | grep --extended-regexp --invert-match 'rom|loop|airoot'   # show result   # lsblk | grep "${deviceName}"
fi

if [ ${formatPartition} = "true" ]; then      # if formatting the partitions should be executed by the script
    echo -e "\n\e[0;35m## Formating the partitions\e[39m"
    format-partition "${device}" "${bootMode}" "${partitionType}" "${filesystemType}" "${fileSystemTypeEfi}" "${fatSize}" "${partitionLabelRoot}" "${partitionLabelEfi}" "${partitionLabelHome}"
fi

if [ ${mountPartition} = "true" ]; then       # this setp is actually only needed for btrfs + subvolumes # if mounting of the partitions should be done by the script
    echo -e "\n\e[0;35m## Mounting the root file system \e[39m"
    mount-partitionRootInitial "${device}" "${filesystemType}" "${rootPartitionNo}" "/mnt"

    if [ ${filesystemType} = "btrfs" ]; then  # if btrfs: create subvolumes
        echo -e "\n\e[0;35m## Creating btrfs subvolume layout\e[39m"
        create-btrfsSubvolume "/mnt"
        set-btrfsDefaultSubvolume "/mnt"      # set default subvolume: use subvolume as the root mountpoint

        echo "Current subolume list:"
        btrfs subvol list /mnt

        echo "Current default subvolume:"
        btrfs subvol get-default /mnt
    fi

    umount /mnt
fi

if [ ${mountPartition} = "true" ]; then       # preparation for installation   # if mounting of the partitions should be done by the script
    echo -e "\n\e[0;35m## Mounting all partitions for installation step \e[39m"
    mount-partition "${device}" "${bootMode}" "${filesystemType}" "${efiPartitionNo}" "${swapPartitionNo}" "${rootPartitionNo}" "/mnt"

    echo "Current block device list (after 'mount-partition'):"
    lsblk
fi


echo -e "\n\n\e[0;36m# --- Installation --- \e[39m"
#echo -e "\n\e[0;35m## Select the mirrors \e[39m"
#TODO: custom config pacman / reflector

echo -e "\n\e[0;35m## Install essential packages (pacstrap) \e[39m"
pacstrap -K /mnt ${strListPacstrapPackage}      # Install essential packages to "/mnt" (new root partition is mounted to /mnt)
                                                # Not enclosing the variable in quotes is intentional; #TODO: using an array or a function could be prettier (https://www.shellcheck.net/wiki/SC2086)

echo -e "\n\n\e[0;36m# --- Configure the system --- \e[39m"
echo -e "\n\e[0;35m## Fstab \e[39m"
genfstab -U /mnt >> /mnt/etc/fstab
#create-fstab                                 # creating individual fstab
modify-fstab "/mnt/etc/fstab"                 # e.g. btrfs: genfstab includes ...,subvolid=XXX,... in mount options, which we do not want (with regard to snapshots)


echo "- copy necessary script/files to root-user directory on new root (/mnt/root)"
rsync -aPhEv archinstall_autoBash_chroot.sh /mnt/root/
rsync -aPhEv archinstall_autoBash.config /mnt/root/
rsync -aPhEv archinstall_autoBash.shlib /mnt/root/
# make them executable:
chmod +x /mnt/root/archinstall_autoBash_chroot.sh
chmod +x /mnt/root/archinstall_autoBash.config
chmod +x /mnt/root/archinstall_autoBash.shlib


# chroot to new root and continue install with script "archinstall_autoBash_chroot.sh":
echo -e "\n\e[0;35m## Chroot \e[39m"

echo "- starting 'archinstall_autoBash_chroot.sh' (arch-chroot)"
arch-chroot /mnt /usr/bin/env bash -c "su - -c /root/archinstall_autoBash_chroot.sh"
echo -e "\e[0;35m- coming back from chroot\e[39m\n\n"

# cleanup:
echo -e "- cleanup: deleting previously copied script/files in '/mnt/root'"
rm /mnt/root/archinstall_autoBash_chroot.sh
rm /mnt/root/archinstall_autoBash.config
rm /mnt/root/archinstall_autoBash.shlib


echo -e "\n\n\e[0;36m# --- Reboot --- \e[39m"
echo "- unmounting /mnt"
umount -R /mnt
echo -e "\n!!! Finished, rebooting in 5 seconds !!!"
sleep 5 && reboot
