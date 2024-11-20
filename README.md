# archinstall_autoBash - automated installation of Arch Linux via a bash script

Bash script to automate Arch Linux installation

- installation parameters are set in a separate configuration file
- no manual intervention required during installation process, except for encryption confirmation and encryption password

## Usage

### Boot live system

- boot live system from an installation medium

### Clone the repository

- clone the repository
  - `git clone https://gitlab.com/sanmue/archinstall_autobash.git`
- change to the direcory of the cloned repository
  - `cd archinstall_autobash`

### Configuration

- customize the variables in '`archinstall_autoBash.config`' according to your needs
  - `vim archinstall_autoBash.config` # use your preferred editor instead of 'vim'
  - these variables are used by the script to execute the installation

### Start installation of Arch Linux as configured

- start the initial script in the cloned git repo folder
  - `./archinstall_autoBash.sh`
    - remember to make the script files executable first, or simply all files in the folder: `chmod +x *`
- after reboot:
  - login as a user with sudo privileges
  - clone the repo again and `cd` into it (for instructions: see further above)   
  - execute the script: `./archinstall_autoBash_afterReboot.sh` (as a user with sudo privileges)
    - installs 'snapper-rollback' (default=true, set/change via config)
    - bootable live system on ESP (e.g. for system rescue) (default, set/change via config)
      - [Archiso on ESP](https://wiki.archlinux.org/title/Systemd-boot#Archiso_on_ESP) and [Grml on ESP](https://wiki.archlinux.org/title/Systemd-boot#Grml_on_ESP) currently supported
      - only if bootloader is systemd-boot
      - requires manual download of installation iso to 'Downloads' folder of your currently logged in user before
      - if the script can not find the installation iso in the 'Downloads' folder, this step will be skipped

## Features

- Bootloader: GRUB and systemd-boot
  - systemd-boot for UEFI boot mode and GRUB Bootloader for Bios boot mode (default, set/change via config)
- UEFI or BIOS (detected automatically) with [GPT](https://wiki.archlinux.org/title/Partitioning#GUID_Partition_Table)
  - for BIOS / MBR: set MBR manually in config
- Encryption
  - GRUB: keyfile to automatically decrypt root partition (default, optional, set/change via config)
- Btrfs filesystem with subvolumes (flat layout, set/change via config)
- Partitioning + formating of the disk (optional, set/change via config)
- Swap: partition, file or none (set via config, current default: none)
- ['zram'](https://wiki.archlinux.org/title/Zram): usage as swap (default, set/change via config)
- Snapper snapshots for root subvolume (optional, set/change via config)
  - only if btrfs filesystem is specified and snapper set to 'true' in config
- Grafics cards drivers (optional, set/change via config)
  - detected automatically, no 32bit application support, needs testing
  - AMD: should work (works on my machine `;-)`)
  - Intel: needs manual config, not testet, see Arch Wiki for current info
  - NVIDIA: needs manual config, not testet, see Arch Wiki for current info
- Desktop Environment (default: Gnome, or none; set/change via config)
  - with additional packages: Firefox (and spice-vdagent if VM) (set/change via config)
- Virtualization support (QEMU/KVM) (default: false (no install), optional, set/change via config)
- Post-install (after reboot):
  - [snapper-rollback (AUR)](https://aur.archlinux.org/packages/snapper-rollback) for simple rollback to a desired snapshot (default: true (install), optional, set/change via config)
    - only in combination with btrfs filesystem and snapper
- bootable live system on ESP (e.g. for system rescue)
    - [Archiso on ESP](https://wiki.archlinux.org/title/Systemd-boot#Archiso_on_ESP) (rescue system) and [Grml on ESP](https://wiki.archlinux.org/title/Systemd-boot#Grml_on_ESP) currently supported (default, optional, set/change via config)
    - only if bootloader is systemd-boot
    - requires manual download of installation iso to 'Downloads' folder
    - if the script can not find the installation iso in the 'Downloads' folder, this step will be skipped

## Limitations
- no seperate 'home' partition
- only Gnome Desktop Environment or no DE (optional via config)
- no multi-boot
- no LVM or RAID
- if opted for virtualization: no nested virtualization configured
- btrfs filesystemt is set by default. If you set to another filesystem in the config: not tested
- ...
