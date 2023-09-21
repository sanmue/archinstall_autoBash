# archinstall_autoBash - automated installation of Arch Linux via a bash script
- Bash script to automate arch linux installation
  - installation parameters are set in a separate configuration file
  - no manual intervention required (hopefully) during installation process

# Usage
## Boot live system
- boot live system from an installation medium
## Install git and clone the repository
- install 'git'
  - `pacman -Sy git`
- clone the repository
  - `git clone https://gitlab.com/sanmue/archinstall_autobash.git`
- change to the direcory of the cloned repository
  - `cd archinstall_autobash`
## Configuration
- customize the variables in '`archinstall_autoBash.config`' according to your needs with your prefered editor
  - e.g. `nano archinstall_autoBash.config`
  - these variables are used by the script to do the installation
## Start installation of Arch Linux on your machine
- start the initial script
  - '`./archinstall_autoBash.sh`'
  - remember to make the script files executable first, or simply all files in the current folder: `chmod +x *`

# Features
- includes partitioning + formating of the disk (optional via config)
  - if you set btrfs filesystem: creates + mounts subvolumes based on the specified subvolume layout in the config
- creates snapper snapshots for root subvolume (optional via config), which are selectable + bootable (readonly)
  - if btrfs filesystem is specified in the config
- installing packages for virtualization (optional via config)
- installing grafics packages (optional via config)
  - ! not (well) tested !
- installing a Desktop Environment (optional via config)

# Limitations
- supports only the Example Partition Layouts (Uefi+GPT, Bios+GPT, Bios+MBR):
  - see: https://wiki.archlinux.org/title/Partitioning#Example_layouts
  - no seperate 'home'-partition
  - creates a swap partition (fixed setting)
    - no swapfile slelectable as alternative to a swap partition 
- no encryption
- no LVM or RAID
- only Grub bootloader
- no nested virtualization configured
- only 'Gnome' Desktop Environment selectable (optional via config)
- no multi-boot
- ...
