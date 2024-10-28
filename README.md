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

Here are some points of the current default configuration:

- Btrfs filesystem with subvolumes (flat layout, configurable), snapper snapshots
  - and [snapper-rollback (AUR)](https://aur.archlinux.org/packages/snapper-rollback) (needs running a separate script after reboot as user with sudo privileges)
- UEFI / GPT or BIOS / GPT (detected automatically)
  - or BIOS / MBR: set MBR manually in config
- GRUB Bootloader
- Enryption + keyfile to automatically decrypt root partition on boot
- (no swap file or swap partition, see 'zram' further below (Post-install))
- Grafics Cards / Drivers (detected automatically, no 32bit support), needs more testing
  - AMD: should work
  - Intel: needs manual config, not testet, see Arch Wiki
  - NVIDIA: needs manual config, not testet, see Arch Wiki
- Gnome Desktop Environment
  - with additional packages: Firefox and VLC Media Player
- Post-install (after reboot):
  - snapper-rollback, ['zram'](https://wiki.archlinux.org/title/Zram) used as swap

### Start installation of Arch Linux as configured

- start the initial script in the cloned git repo folder
  - `./archinstall_autoBash.sh`
  - remember to make the script files executable first, or simply all files in the folder: `chmod +x *`
- after reboot:
  - clone the repo again and `cd` into it (for instructions: see further above)
- execute the script: `./archinstall_autoBash_afterReboot.sh` (as a user with sudo privileges)
  - installs 'snapper-rollback', zram
  - if set in config file

## Features

- includes partitioning + formating of the disk (optional via config)
  - if you set btrfs filesystem: creates + mounts subvolumes based on the specified subvolume layout in the config
- creates snapper snapshots for root subvolume (optional via config)
  - if btrfs filesystem is specified in the config and snapper set to 'true'
- snapper-rollback (AUR) for simple rollback to a previous snapshot (if set to 'true' in the config + btrfs and snapper)
- installing packages for virtualization (optional via config)
- installing grafics packages (optional via config)
  - for AMD it should work (works on my machine `;-)`)
  - but you will still need to consult the wiki to install the correct packages for your system, especially for NVIDIA and Intel.
- installing a Desktop Environment (optional via config)
- encryption + keyfile (each optional via config)
- swap: partition, file or none (set via config)
- zram (set via config)

## Limitations

- supports only the [Example Partition Layouts (Uefi+GPT, Bios+GPT, Bios+MBR)](https://wiki.archlinux.org/title/Partitioning#Example_layouts):
  - no seperate 'home'-partition
  - creates a swap partition (fixed setting)
    - no swapfile slelectable as alternative to a swap partition
- no LVM or RAID
- only Grub bootloader
- no nested virtualization configured
- only 'Gnome' Desktop Environment selectable (optional via config)
- no multi-boot
- ...
