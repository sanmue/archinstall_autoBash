# archinstall_autoBash - automated installation of Arch Linux via a bash script
- Bash script to automate my arch linux installation
  - installation is done based on the variables set in a separate configuration file
  - no manual intervention is required (hopefully)
  - includes partitioning + formating of the disk (optional via config)
  - btrsf filesystem: subvolumes (create + mount; btrfs subvolume layout can be configured)

# Usage
## Boot live system
- boot live system from an installation medium
## Install git and clone the repo
- install 'git'
  - `pacman -Sy git`
- clone the repo
  - `git clone https://gitlab.com/sanmue/archinstall_autobash.git`
- change to the direcory of the cloned repository
  - `cd archinstall_autobash`
## Configuration
- Customize the variables in '`archinstall_autoBash.config`' according to your needs
  - `nano archinstall_autoBash.config`
  - these variables are used by the script to do the installation
## Start installation of Arch Linux on your machine
- start the script `archinstall_autoBash.sh`
  - '`./archinstall_autoBash.sh`'
  - remember to make the script files executable first (`chmod +x ...`; or simply all: `chmod +x *`)

# Limitations (until they itch me and/or I have the time to implement)
- supports only the Example Layouts (Uefi+GPT, Bios+GPT, Bios+MBR):
  - see: https://wiki.archlinux.org/title/Partitioning#Example_layouts
  - no seperate partition for 'home'
  - creates a swap partition (fixed, not optional)
  - no swapfile slelectable as alternative to a swap partition 
- no encryption
- no LVM or RAID
- only Grub bootloader
- installing Virtualization is optional (via config)
  - no nested virtualization configured
- installing grafics packages is optional (via config)
  - ! not (well) tested !
- installing a Desktop Environment is optional (via config)
  - only 'Gnome' selectable (via config)
- ...
