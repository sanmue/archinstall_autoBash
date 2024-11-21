#!/usr/bin/env bash
# shellcheck disable=SC2034

# set -x   # enable debug mode

# ----------------------------------------------------------------
# Name                 archinstall_autoBash_afterReboot.sh
# Description          simple rudimentary bash script to automate my arch linux installation
#                      after Reboot
# Author               Sandro Müller (sandro(ÄT)universalaccount.de)
# Licence              GPLv3
# ----------------------------------------------------------------

afterReboot="true"

# ------------------
# Config / Variables
# ------------------
echo -e "\n\n\e[0;36m# Sourcing 'archinstall_autoBash.config' \e[39m"
# shellcheck source=archinstall_autoBash.config
source archinstall_autoBash.config # including the separate file containing the config / variables used by the script


# ---------
# Functions
# ---------
echo -e "\n\n\e[0;36m# Sourcing 'archinstall_autoBash.shlib' \e[39m"
# shellcheck source=archinstall_autoBash.shlib
source archinstall_autoBash.shlib # including the separate file containing the functions used by the script


# ----
# main
# ----

# --- snapper-rollback (AUR):
echo -e "\n\e[0;36m# --- Post-installation - after reboot --- \e[39m"
echo -e "\e[0;31mExecute this script as a user with sudo privileges (not as 'root') \e[39m"

echo -e "\n\e[0;35m## Install and config snapper-rollback (AUR) \e[39m"
if [ "${filesystemType}" = "btrfs" ] && [ "${snapperSnapshot}" = "true" ] && [ "${snapperRollback}" = "true" ]; then
    config-snapperRollback "${snapperRollbackFolder}" "${snapperSnapshotsSubvolName}" "${snapperRollbackConfig}" # e.g.: '/.btrfsroot' and '@snapshots' and '/etc/snapper-rollback.conf'
    if [ "${bootloader}" = "systemd-boot" ]; then config-shellConfUser-rollbackFunction; fi
else
    echo "Will not configure snapper-rollback due to configuration set in config-file."
    echo "Filesystem type ist not 'btrfs' and/or snapshots is set to 'false' and/or snapperRollback ist set to 'false'"
fi

# ### --------------------------------------------------------------------------------
# zram: ! moved to archinstall_autoBash_chroot.sh !
# ###
#
# --- zram:
# echo -e "\n\e[0;35m## Install and config 'zram' (usage as swap) \e[39m"
# if [ "${zram}" = "true" ]; then
#     # - https://wiki.archlinux.org/title/Zram#Using_zram-generator
#     echo -e "'zwap' prevents 'zram' from being used effectively, will be disabled permanently via kernel parameter..." # 'zswap' is used by default in Arch Linux
#     zswapDisable_kernelOption='zswap.enabled=0'
#     grubConfDefaultPath="/etc/default/grub"
#     if [[ -z $(grep "${zswapDisable_kernelOption}" "${grubConfDefaultPath}") ]]; then # wenn kernel option noch nicht in ${grubConfDefaultPath}
#         string=$(grep "GRUB_CMDLINE_LINUX_DEFAULT=" "${grubConfDefaultPath}")
#         tmpString="${string%?}" # remove last character (")
#         tmpString+=" ${zswapDisable_kernelOption}\""
#         sudo sed -i "s|${string}|${tmpString}|g" "${grubConfDefaultPath}"
#         echo -e "Recreate grub.cfg, including the new kernel option..."
#         sudo grub-mkconfig -o "${pathGrubCfg}"
#     else
#         echo -e "\e[1;33m- Kernel option to disable 'zswap' already in '${grubConfDefaultPath}' \e[39m"
#         # head -n 8 -v "${grubConfDefaultPath}"
#     fi

#     # echo -e "- check zswap state (if '...enabled: N' -> zswap is disabled):" # needs reboot first
#     # grep -r . /sys/module/zswap/parameters/ | grep /enabled # or: cat /sys/module/zswap/parameters/enabled 

#     echo -e "\nInstalling 'zram-generator'..."
#     sudo pacman -S --needed --noconfirm zram-generator
#     echo -e "Creating zram-generator config..."
#     zramGeneratorConfFilePath="/etc/systemd/zram-generator.conf"
#     sudo touch "${zramGeneratorConfFilePath}"
#     echo -e "[zram0]\nzram-size = ram / ${zramSize}\ncompression-algorithm = zstd" | sudo tee "${zramGeneratorConfFilePath}" >/dev/null
#     echo -e "Reloading daemon and starting systemd-zram-setup service for zram..."
#     sudo systemctl daemon-reload
#     sudo systemctl start systemd-zram-setup@zram0.service # zram'0': -> assuming its the only / first zram
#     echo -e "Check:"
#     # sudo zramctl --output-all # Check # swapon -s # or: zramctl --output-all # or: cat /proc/swaps # or: systemctl status systemd-zram-setup@zram0.service
#     sudo zramctl --output-all && echo "" && swapon --output-all
#     echo -e "\nConfig to optimize swap on zram..."
#     zramParameterConfFilePath="/etc/sysctl.d/99-vm-zram-parameters.conf"
#     sudo touch "${zramParameterConfFilePath}"
#     echo -e "vm.swappiness = 180\nvm.watermark_boost_factor = 0" | sudo tee "${zramParameterConfFilePath}" >/dev/null
#     echo -e "vm.watermark_scale_factor = 125\nvm.page-cluster = 0" | sudo tee --append "${zramParameterConfFilePath}" >/dev/null
# else
#     echo -e "\e[1;33m- 'zram' not set to 'true' in config file, skipping \e[39m"
# fi
# ### END zram --------------------------------------------------------------------------------


# ### --------------------------
# System on ESP (rescue system)
# - https://wiki.archlinux.org/title/Systemd-boot#Grml_on_ESP
# - https://wiki.archlinux.org/title/Systemd-boot#Archiso_on_ESP
if [ "${bootloader}" = "systemd-boot" ]; then
    downloadFolder="${HOME}/Downloads"

    echo -e "\n\e[0;35m## System on ESP\e[39m"
    echo -e "Please make sure you downloaded the installation iso to '${downloadFolder}'\n"

    for system in "${systemOnESP[@]}"; do
        isoFileName=""
        iso=""

        case "${system}" in
            archiso)
                searchPattern="archlinux*.iso"
            ;;
            grml)
                searchPattern="grml64-full*.iso"
            ;;
            sysresccd)
                searchPattern="systemrescue*.iso"
            ;;
            *)
                continue
            ;;
        esac

        # e.g.: archlinux-YYYY.MM.DD-x86_64.iso # grml64-FLAVOUR_YEAR.MONTH.iso
        # e.g.: /home/userid/Downloads/archlinux-2024.11.01-x86_64.iso # /home/userid/Downloads/grml64-full_2024.02.iso
        isoFileName=$(find "${downloadFolder}" -mindepth 1 -maxdepth 1 -prune -type f -name "${searchPattern}" | cut -d'/' -f5)
        if [ -z "${isoFileName}" ]; then
            echo -e "\e[1;33mSkipping 'System on ESP' for '${system}'. No installation iso found.\e[39m"
            echo "- You can download the iso to '${downloadFolder}' and start this script again."
        else
            echo "- found iso-file: '${isoFileName}' in '${downloadFolder}'"
            # isoFileName=$(ls "${downloadFolder}" | grep arch\.\*.iso\$)
            # shopt -s extglob
            # isoFileName=$(ls -- "${downloadFolder}/arch*.iso" | cut -d'/' -f5)

            iso="${downloadFolder}/${isoFileName}"
            config-systemOnEsp "${iso}" "${system}" "${isoFileName}"
            fi
    done
else
    echo -e "\e[1;33mSkipping 'System on ESP (rescue system)'. Currently only available for systemd-boot.\e[39m"
fi
# ### END System on ESP -------


# --- Info message:
# echo -e "\n\e[1;33mSome changes may only take effect after a restart. \e[39m" # e.g. for: 'zwap'
