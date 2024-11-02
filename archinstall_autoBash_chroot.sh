#!/usr/bin/env bash
# shellcheck disable=SC2154

# set -x   # enable debug mode

# ----------------------------------------------------------------
# Name                 archinstall_autoBash_chroot.sh
# Description          simple rudimentary bash script to automate my arch linux installation
#                      * 2nd part: arch-chroot on new root (mounted at /mnt)
# Author               Sandro Müller (sandro(ÄT)universalaccount.de)
# Licence              GPLv3
# ----------------------------------------------------------------


# ------------------
# Config / Variables
# ------------------
echo -e "\n\n\e[0;36m# Sourcing 'archinstall_autoBash.config' \e[39m"
# shellcheck source=archinstall_autoBash.config
source archinstall_autoBash.config      # including the separate file containing the config / variables used by the script


# ---------
# Functions
# ---------
echo -e "\n\n\e[0;36m# Sourcing 'archinstall_autoBash.shlib' \e[39m"
# shellcheck source=archinstall_autoBash.shlib
source archinstall_autoBash.shlib       # including the separate file containing the functions used by the script


# ----
# main
# ----

echo -e "\n\e[0;35m## Time zone \e[39m"
set-timezone "${timezone}" /etc/localtime

echo -e "\n\e[0;35m## Localization \e[39m"
set-locales
# TODO: optional: further customization of '/etc/locale.conf' (e.g. LC_ADDRESS, LC_IDENTIFICATION, ... for other locale than defaultLang)

echo -e "\n\e[0;35m## Network configuration \e[39m"
config-network

echo -e "\n\e[0;35m## Root password \e[39m"
set-password root   # set initial password

echo -e "\n\e[0;35m## Grafics\e[39m"
install-grafics

echo -e "\n\e[0;35m## zram installation + conf \e[39m"
# https://wiki.archlinux.org/title/Zram#Using_zram-generator
if [ "${zram}" = "true" ]; then
    echo -e "\nInstalling 'zram-generator'..."
    pacman -S --needed --noconfirm zram-generator
    echo -e "Creating zram-generator config..."
    touch "${zramGeneratorConfFilePath}" # zram path variabel set in config file
    echo -e "[zram0]\nzram-size = ram / ${zramSize}\ncompression-algorithm = zstd" | tee "${zramGeneratorConfFilePath}" >/dev/null
    # echo -e "Reloading daemon and starting systemd-zram-setup service for zram..."
    # systemctl daemon-reload # Running in chroot, ignoring command 'daemon-reload'
    # systemctl start systemd-zram-setup@zram0.service # Running in chroot, ignoring command 'start' # zram'0': -> assuming its the only / first zram
    # echo -e "Check:"
    # sudo zramctl --output-all # Check # swapon -s # or: zramctl --output-all # or: cat /proc/swaps # or: systemctl status systemd-zram-setup@zram0.service
    # zramctl --output-all && echo "" && swapon --output-all # not in chroot
    # cat /proc/swaps # since in chroot / zram0 service not started, prints nothing
    echo -e "\nConfig to optimize swap on zram..."
    touch "${zramParameterConfFilePath}" # zram parameter path variabel set in config file
    echo -e "vm.swappiness = 180\nvm.watermark_boost_factor = 0" | tee "${zramParameterConfFilePath}" >/dev/null
    echo -e "vm.watermark_scale_factor = 125\nvm.page-cluster = 0" | tee --append "${zramParameterConfFilePath}" >/dev/null
else
    echo "- Skipping, zram: '${zram}'"
fi

# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio
# https://wiki.archlinux.org/title/Installation_guide#Initramfs
# https://wiki.archlinux.org/title/Mkinitcpio#Manual_generation

echo -e "\n\e[0;35m## Boot loader installation \e[39m"
install-bootloader # including config for encryption, keyfile, zram (disable zswap)

echo -e "\n\e[0;35m## Create and store keyfile \e[39m"
if [ "${encryption}" = "true" ] && [ "${keyfile}" = "true" ]; then
    dd bs=512 count=4 if=/dev/random iflag=fullblock | install -m 0600 /dev/stdin "${keyfilePath}"
    echo -e "- Configuring LUKS to make use of the keyfile. Enter encryption passphrase for root partition:"
    result=6666 # arbitrary number not equal to 0 (0 = no error in last command))
    while [ "$result" -ne 0 ]; do
        cryptsetup luksAddKey "${rootPartition}" "${keyfilePath}" # e.g.: cryptsetup luksAddKey /dev/vda2 /etc/cryptsetup-keys.d/crypto_keyfile.key
        result=$?
    done
else
    echo "- Skipping, keyfile: '${keyfile}', encryption: '${encryption}'"
fi

echo -e "\n\e[0;35m## Initramfs \e[39m"
# Initramfs: For LVM, system encryption or RAID, modify mkinitcpio.conf(5) and recreate the initramfs image
echo -e "\n\e[0;35m- Configuring mkinitcpio \e[39m"
# modify mkinitcpio.conf:
config-mkinitcpio
# regenerate initramfs:
# mkinitcpio -p "${kernelPackage}"  # e.g. mkinitcpio -p linux
mkinitcpio -P                       # (re-)generate all existing presets


# ### TEST --------------------------------------------------------------------
# echo -e "\nPress Enter to continue - chroot: after configuring + executing mkinitcpio "
# read -r
# ### TEST --------------------------------------------------------------------

# --- Post-installation (original position in wiki: after reboot) - ! order changed, was moved forward one position compared to the wiki ! ---
echo -e "\n\n\e[0;36m# --- Post-installation part - brought forward (original position: after reboot --- \e[39m"

echo -e "\n\e[0;35m## Installing additional packages \e[39m"
install-additionalPackages

echo -e "\n\e[0;35m## Enable Services \e[39m"
enable-service

echo -e "\n\e[0;35m## Creating unprivileged user accounts \e[39m"
create-userAccount
config-sudoUser

echo -e "\n\e[0;35m## Install graphical user interface \e[39m"
install-DesktopEnvironment

echo -e "\n\e[0;35m## Install multimedia codecs \e[39m"
if [ "${installMultimediaCodecs}" = "true" ]; then
    pacman -S --noconfirm --needed $strListMultimediaCodecs
else
    echo "- Skipping since in config 'installMultimediaCodecs' not set to 'true'"
fi # do not double quote ${installMultimediaCodecs}

echo -e "\n\e[0;35m## Install additional fonts \e[39m"
if [ "${installFont}" = "true" ]; then
    pacman -S --noconfirm --needed ${strListFontPkg}
else
    echo "- Skipping since in config 'installFont' not set to 'true'"
fi # do not double quote ${strListFontPkg} # TODO: could change to array
