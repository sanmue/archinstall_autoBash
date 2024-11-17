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
  - clone the repo again and `cd` into it (for instructions: see further above)
- execute the script: `./archinstall_autoBash_afterReboot.sh` (as a user with sudo privileges)
  - installs 'snapper-rollback', zram
  - if set in config file

### Some points of the current default configuration:

- Btrfs filesystem with subvolumes (flat layout, configurable), snapper snapshots
  - and [snapper-rollback (AUR)](https://aur.archlinux.org/packages/snapper-rollback) (needs running a separate script after reboot as user with sudo privileges)
- UEFI or BIOS (detected automatically) with GPT
  - for BIOS / MBR: set MBR manually in config
- systemd-boot (UEFI boot mode) and GRUB Bootloader (Bios boot mode)
- Encryption
- keyfile to automatically decrypt root partition on boot (only relevant for GRUB)
- ['zram'](https://wiki.archlinux.org/title/Zram) used as swap (size: 50% of RAM size)
- no swap file, no swap partition
- Grafics cards drivers (detected automatically, no 32bit application support), needs testing
  - AMD: should work
  - Intel: needs manual config, not testet, see Arch Wiki for current info
  - NVIDIA: needs manual config, not testet, see Arch Wiki for current info
- Gnome Desktop Environment
  - with additional packages: Firefox and VLC Media Player (change via config)
- Post-install (after reboot):
  - snapper-rollback

## Features

- Bootloaders: GRUB and systemd-boot
- Partitioning + formating of the disk (optional via config)
  - if you set to btrfs filesystem: creates + mounts subvolumes based on the specified subvolume layout (set via config)
- Snapper snapshots for root subvolume (optional via config)
  - if btrfs filesystem is specified and snapper set to 'true' in the config
- Snapper-rollback (AUR) for simple rollback to a previous snapshot
  - if set to 'true' in the config, only in combination with btrfs and snapper
- Grafics card package installation (optional via config)
  - consult the arch wiki for current info, change if necessary to the correct packages for your system, especially for NVIDIA and Intel.
  - for AMD it should work (works on my machine `;-)`)
- Desktop Environment (optional via config, current default/only: Gnome)
- Encryption; GRUB: keyfile to autom. decrypt root partition (each optional via config)
- Swap: partition, file or none (set via config, current default: none)
- Zram: usage as swap (set via config, current default)
- Virtualization support (QEMU/KVM, optional via config)

## Limitations
- no seperate 'home' partition
- only Gnome Desktop Environment or no DE (optional via config)
- no multi-boot
- no LVM or RAID
- if opted for virtualization: no nested virtualization configured
- ...
