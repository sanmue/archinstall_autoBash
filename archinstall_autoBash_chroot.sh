#!/usr/bin/env bash

set -x   # enable debug mode

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

echo -e "\n\e[0;35m## Time zone \e[39m"
set-timezone "${timezone}" /etc/localtime

echo -e "\n\e[0;35m## Localization \e[39m"
set-locales
#TODO: optional: further customization of '/etc/locale.conf' (e.g. LC_ADDRESS, LC_IDENTIFICATION, ... for other locale than defaultLang)

echo -e "\n\e[0;35m## Network configuration \e[39m"
config-network

#TODO Initramfs: For LVM, system encryption or RAID, modify mkinitcpio.conf(5) and recreate the initramfs image
# mkinitcpio -P

echo -e "\n\e[0;35m## Root password \e[39m"
set-password root   # set initial password

echo -e "\n\e[0;35m## Grafics\e[39m"
install-grafics

echo -e "\n\e[0;35m## Boot loader\e[39m"
install-bootloader

# --- Post-installation (original position: after reboot) - ! order changed, was moved forward one position compared to the wiki ! ---
echo -e "\n\n\e[0;36m# --- Post-installation part of Arch install wiki (original position: after reboot ! order changed, was moved forward one position compared to the wiki) --- \e[39m"
echo -e "\n\e[0;35m## Installing additional packages \e[39m"
install-additionalPackages

echo -e "\n\e[0;35m## Enable Services \e[39m"
enable-service

echo -e "\n\e[0;35m## Creating unprivileged user accounts \e[39m"
create-userAccount

echo "- config sudo user rights (/etc/sudoers.d/sudoUser)"
config-sudoUser


echo -e "\n\e[0;35m## Install graphical user interface \e[39m"
install-DesktopEnvironment
