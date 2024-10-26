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

echo -e "\n\e[0;36m# --- Post-installation - after reboot --- \e[39m"
echo -e "\e[0;31mExecute this script with a user with sudo privileges (not as 'root') \e[39m"

echo -e "\n\e[0;35m## Install and config snapper-rollback (AUR) \e[39m"
if [ "${filesystemType}" = "btrfs" ] && [ "${snapperSnapshot}" = "true" ] && [ "${snapperRollback}" = "true" ]; then
    config-snapperRollback "${snapperRollbackFolder}" "${snapperSnapshotsSubvolName}" "${snapperRollbackConfig}" # e.g.: '/.btrfsroot' and '@snapshots' and '/etc/snapper-rollback.conf'
else
    echo "Will not configure snapper-rollback due to configuration set in config-file."
    echo "Filesystem type ist not 'btrfs' and/or snapshots is set to 'false' and/or snapperRollback ist set to 'false'"
fi