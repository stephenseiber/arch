read -p "do you have intel or amd cpu, or press enter to use defaults: " cpu
if [[ -z $cpu ]]; then
    cpu=intel
fi
read -p "do you want to wipe full drive, or press enter to use defaults: " part
if [[ -z $part ]]; then
    part=yes
fi

if [[ $part == "no" ]]; then
    pacman -Sy dialog --noconfirm                                                                  #install dialog for selecting disk
    devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)                 #gets disk info for selection
    drive=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1       #chose which drive to format
    clear           # clears blue screen from
    lsblk           # shows avalable drives
    echo ${drive}   # confirms drive selection
    part_boot="$(ls ${drive}* | grep -E "^${drive}p?1$")"     #finds boot partion
    part_root="$(ls ${drive}* | grep -E "^${drive}p?2$")"     #finds root partion
    cryptsetup luksOpen ${part_root} cryptroot2  # Open the mapper
    mount /dev/mapper/cryptroot2 /mnt
    # clearing non home data
    btrfs subvolume delete /mnt/@
    btrfs subvolume delete /mnt/@pkg
    btrfs subvolume delete /mnt/@var
    btrfs subvolume delete /mnt/@srv
    btrfs subvolume delete /mnt/@tmp
    #creating new subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@pkg
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@srv
    btrfs subvolume create /mnt/@tmp
    umount /mnt
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@ /dev/mapper/cryptroot2 /mnt
    mkdir -p /mnt/{home,var/cache/pacman/pkg,var,srv,tmp,boot}  # Create directories for each subvolume
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@home /dev/mapper/cryptroot2 /mnt/home
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@pkg /dev/mapper/cryptroot2 /mnt/var/cache/pacman/pkg
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@var /dev/mapper/cryptroot2 /mnt/var
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@srv /dev/mapper/cryptroot2 /mnt/srv
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@tmp /dev/mapper/cryptroot2 /mnt/tmp
    chattr +C /mnt/var  # Copy on write disabled
    mount ${part_boot} /mnt/boot  # Mount the boot partition

    else

    pacman -Sy dialog --noconfirm                                                                  #install dialog for selecting disk
    devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)                 #gets disk info for selection
    drive=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1       #chose which drive to format
    clear           # clears blue screen from
    lsblk           # shows avalable drives
    echo ${drive}   # confirms drive selection
    sgdisk --zap-all ${drive}  # Delete tables
    printf "n\n1\n\n+333M\nef00\nn\n2\n\n\n\nw\ny\n" | gdisk ${drive}  # Format the drive

    part_boot="$(ls ${drive}* | grep -E "^${drive}p?1$")"     #finds boot partion
    part_root="$(ls ${drive}* | grep -E "^${drive}p?2$")"     #finds root partion

    echo ${part_boot} # confirms boot partion selection
    echo ${part_root} # confirms root partion selection

    mkdir -p -m0700 /run/cryptsetup  # Change permission to root only
    cryptsetup luksFormat --type luks2 ${part_root}
    cryptsetup luksOpen ${part_root} cryptroot2  # Open the mapper

    mkfs.vfat -F32 ${part_boot}  # Format the EFI partition
    mkfs.btrfs /dev/mapper/cryptroot2  # Format the encrypted partition

    mount /dev/mapper/cryptroot2 /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@pkg
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@srv
    btrfs subvolume create /mnt/@tmp
    umount /mnt

    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@ /dev/mapper/cryptroot2 /mnt
    mkdir -p /mnt/{home,var/cache/pacman/pkg,var,srv,tmp,boot}  # Create directories for each subvolume
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@home /dev/mapper/cryptroot2 /mnt/home
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@pkg /dev/mapper/cryptroot2 /mnt/var/cache/pacman/pkg
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@var /dev/mapper/cryptroot2 /mnt/var
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@srv /dev/mapper/cryptroot2 /mnt/srv
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@tmp /dev/mapper/cryptroot2 /mnt/tmp
    chattr +C /mnt/var  # Copy on write disabled
    mount ${part_boot} /mnt/boot  # Mount the boot partition

fi

if [[ $cpu == "amd" ]]; then
  #pacstrap -i /mnt base base-devel linux linux-firmware amd-ucode networkmanager efibootmgr btrfs-progs neovim zram-generator zsh
  echo amd
else
#pacstrap -i /mnt base base-devel linux linux-firmware intel-ucode networkmanager efibootmgr btrfs-progs neovim zram-generator zsh
echo intel
fi

