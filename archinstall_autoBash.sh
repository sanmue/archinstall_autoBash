#!/usr/bin/env bash

# set -x   # enable debug mode

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
echo "- setting console keyboard to: '${consoleKeyboardLayout}' (temporary for current session)"
loadkeys "${consoleKeyboardLayout}"    # set console keyboard layout (temporary for current session)
echo "- setting terminal font to: '${terminalFont}' (temporary for current session)"
setfont "${terminalFont}"              # set terminal font (temporary for current session)

# TODO: Check internet connection

echo -e "\n\e[0;35m## Update the system clock (set-timezone) \e[39m"
echo "- setting timezone to: '${timezone}'"
timedatectl set-timezone "${timezone}" # set timezone
#timedatectl status                    # show timezone settings

# TODO: Check for existing partition(s) (would be overwritten via function "partition-disk")

echo "checking if device path '${device}' is valid"
check-devicePath "${device}"                    # check if configured device path is valid

if [ ${partitionDisk} = "true" ]; then          # if partitioning the device should be executed by the script
    echo -e "\n\e[0;35m## Partitioning the disk '${device}'...\e[39m"

    erase-device "${device}" "${blockSize}"     # executed only if eraseDisk="true" is set # the device will be erased (overwritten via dd command)
    partition-disk "${bootMode}" "${partitionType}" "${device}" "${swapSize}" "${efiPartitionSize}"   # partition the device
    echo "- show available block devices:"
    lsblk | grep --extended-regexp --invert-match 'rom|loop|airoot' # show result # lsblk | grep "${deviceName}"
fi

if [ ${formatPartition} = "true" ]; then        # if formatting the partitions should be executed by the script
    echo -e "\n\e[0;35m## Formating the partitions\e[39m"

    # if encryption="true": the root partition will be encrypted with luks
    format-partition "${device}" "${bootMode}" "${partitionType}" "${filesystemType}" "${fileSystemTypeEfi}" "${fatSize}" "${partitionLabelRoot}" "${partitionLabelEfi}" "${partitionLabelHome}" "${partitionLabelSwap}"
fi


# ### TEST --------------------------------------------------------------------
# echo -e "\nPress Enter to continue - after format-partition"
# read -r
# ### TEST --------------------------------------------------------------------


if [ ${mountPartition} = "true" ]; then         # this setp is actually only needed for btrfs + subvolumes # if mounting of the partitions should be done by the script
    echo -e "\n\e[0;35m## Initial mount of root file system \e[39m"

    # "${encryptionDeviceMapperPath}" "${encryptionRootName}"
    if [ "${encryption}" = "true" ]; then
        mount-partitionRootInitial "${encryptionDeviceMapperPath}/" "${filesystemType}" "${encryptionRootName}" "/mnt"
    else
        mount-partitionRootInitial "${device}" "${filesystemType}" "${rootPartitionNo}" "/mnt"
    fi

    if [ ${filesystemType} = "btrfs" ]; then    # if btrfs: create subvolumes
        echo -e "\n\e[0;35m## Creating btrfs subvolume layout\e[39m"
        create-btrfsSubvolume "/mnt"
        set-btrfsDefaultSubvolume "/mnt"        # set default subvolume: use subvolume as the root mountpoint

        echo -e "\nCurrent subolume list:"
        btrfs subvol list /mnt

        echo -e "\nCurrent default subvolume:"
        btrfs subvol get-default /mnt
    fi

    umount /mnt                                 # unmount; need to remount the subvolumes in next step to /mnt
fi

if [ ${mountPartition} = "true" ]; then         # preparation for installation   # if mounting of the partitions should be done by the script
    echo -e "\n\e[0;35m## Mounting all partitions for installation step \e[39m"
    mount-partition "${device}" "${bootMode}" "${filesystemType}" "${efiPartitionNo}" "${swapPartitionNo}" "${rootPartitionNo}" "/mnt" "${swapFileName}" "${swapFilePath}" "${swapSize}"
    # parameter 'swapFilePath' and 'swapSize' needed for swap file and btrfs + subvol (not for swap partition)
    # parameter 'swapFileName' only needed for swap file + NO btrfs with subvols (not for swap partition)

    echo "Current block device list (after 'mount-partition'):"
    lsblk
fi


# ### TEST --------------------------------------------------------------------
# echo -e "\nPress Enter to continue - after mounting partitions (+ all btrfs subvols) to /mnt --- before pacstrap"
# read -r
# ### TEST --------------------------------------------------------------------


echo -e "\n\n\e[0;36m# --- Installation --- \e[39m"
# TODO: custom config mirrors pacman / reflector

echo -e "\n\e[0;35m## Install essential packages (pacstrap) \e[39m"
pacstrap -K /mnt ${strListPacstrapPackage}  # ! do not doublequote '${strListPacstrapPackage}' or pacstrap will fail !
                                            # Install essential packages to "/mnt" (new root partition is mounted to /mnt)
                                            # Not enclosing the variable in quotes is intentional; # TODO: using an array or a function could be prettier (https://www.shellcheck.net/wiki/SC2086)

echo -e "\n\n\e[0;36m# --- Configure the system --- \e[39m"
echo -e "\n\e[0;35m## Fstab \e[39m"
echo "- generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ### TEST --------------------------------------------------------------------
# echo -e "\n/mnt/etc/fstab (before modification):"
# cat /mnt/etc/fstab
# ### TEST --------------------------------------------------------------------

# create-fstab # creating individual fstab
echo "- modify fstab (if btrfs: deleting mount option 'subvolid' if set (leaving just 'subvol') for all btrfs subvolumes)..."
modify-fstab "/mnt/etc/fstab" # e.g. btrfs: genfstab includes ...,subvolid=XXX,... in mount options, which we do not want (with regard to snapshots)

# Swap enryption - https://wiki.archlinux.org/title/Dm-crypt/Swap_encryption#UUID_and_LABEL
if [ "${encryption}" = "true" ] && [ "${swapType}" = "partition" ]; then
    echo "- adding entry for swap encryption to '/mnt${pathToCrypttab}'..."
    echo "${encryptionSwapCrypttab}" >> "/mnt${pathToCrypttab}"
    echo "- adding entry for encrypted swap partition to '/etc/fstab'..."
    echo "# encrypted swap partition via ${pathToCrypttab} and LABEL=${partitionLabelSwap}" >> "/mnt/etc/fstab"
    echo "/dev/mapper/swap none swap defaults 0 0" >> "/mnt/etc/fstab"
fi


# ### TEST --------------------------------------------------------------------
# echo -e "\n/mnt${pathToCrypttab}:"
# cat "/mnt${pathToCrypttab}"
# echo -e "\n/mnt/etc/fstab:"
# cat "/mnt/etc/fstab"
# # ls -la /mnt/dev/disk/by-label
# echo -e "\nPress Enter to continue - after genfstab / modify fstab and crypttab"
# read -r
# ### TEST --------------------------------------------------------------------


# make rquired script files available in chroot environment
echo "- copy rquired script/files to root-user directory on new root (/mnt/root)"
rsync -aPhEv archinstall_autoBash_chroot.sh /mnt/root/
rsync -aPhEv archinstall_autoBash.config /mnt/root/
rsync -aPhEv archinstall_autoBash.shlib /mnt/root/
rsync -aPhEv "${fileDeviceName}" /mnt/root/          # txt file containing device name, e.g. vda
rsync -aPhEv "${fileRootPartition}" /mnt/root/       # txt file containing root partition, e.g. /dev/vda2
# make them executable:
chmod +x /mnt/root/archinstall_autoBash_chroot.sh
chmod +x /mnt/root/archinstall_autoBash.config
chmod +x /mnt/root/archinstall_autoBash.shlib

# chroot to new root and continue install with script "archinstall_autoBash_chroot.sh":
echo -e "\n\e[0;35m## Chroot \e[39m"

echo "- starting 'archinstall_autoBash_chroot.sh' (arch-chroot)"
arch-chroot /mnt /usr/bin/env bash -c "su - -c /root/archinstall_autoBash_chroot.sh"
echo -e "\e[0;33m- coming back from chroot\e[39m\n\n"

# cleanup:
echo "- cleanup: deleting previously copied script/files in '/mnt/root'"
rm /mnt/root/archinstall_autoBash_chroot.sh
rm /mnt/root/archinstall_autoBash.config
rm /mnt/root/archinstall_autoBash.shlib
rm "/mnt/root/${fileDeviceName}"
rm "/mnt/root/${fileRootPartition}"

# config snapper:
if [ "${filesystemType}" = "btrfs" ] && [ "${snapperSnapshot}" = "true" ]; then
    echo -e "\n\n\e[0;36m# Configure snapper for root subvolume \e[39m"
    config-snapperLiveEnv "${snapperConfigName_root}" "/mnt" "/" # '/mnt' = current mount path of (root) subvolume, /' = final 'real' path of (root) subvolume to create the config for
fi

# flag file:
sudo touch "${flagFile}"


# ### TEST --------------------------------------------------------------------
# echo -e "\nPress Enter to continue - before reboot"
# read -r
# ### TEST --------------------------------------------------------------------


# reboot:
echo -e "\n\n\e[0;36m# --- Reboot --- \e[39m"
echo "- unmounting /mnt"
umount -R /mnt
echo -e "\n\e[1;31mInitial password: '${initialPassword}'\e[39m"
echo    "for 'root' and created users"
echo -e "\e[1;31mPlease change after reboot!\e[39m"
echo -e "\nRemember script 'archinstall_autoBash_afterReboot.sh'"
echo -e "\nFinished, rebooting in 5 seconds..."

sleep 5 && reboot
