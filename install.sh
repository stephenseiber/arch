#!/usr/bin/env bash
mount -o remount,size=8G /run/archiso/cowspace
df -l
clear   # Clear the TTY
set -e  # The script will not run if we CTRL + C, or in case of an error
set -u  # Treat unset variables as an error when substituting

## This are the defaults, so it's easier to test the script
# keymap=us
# part=yes
# username=csjarchlinux  # Can only be lowercase and no signs
# hostname=desktop
# user_password=csjarchlinux
# root_password=csjarchlinux

read -p "do you want to wipe full drive yes or no, or press enter to use defaults: " part
if [[ -z $part ]]; then
    part=yes
fi

read -p "Enter keymap, or press enter to use defaults: " keymap
if [[ -z $keymap ]]; then
    keymap=us
fi

read -p "Enter user name, or press enter to use defaults: " username
if [[ -z $username ]]; then
    username=csjarchlinux
fi

read -p "Enter host name, or press enter to use defaults: " hostname
if [[ -z $hostname ]]; then
    hostname=csjarchlinux
fi

read -s -p "Enter user password, or press enter to use defaults: " user_password
if [[ -z $user_password ]]; then
    user_password=csjarchlinux
fi

read -s -p "Enter root password, or press enter to use defaults: " root_password
if [[ -z $root_password ]]; then
    root_password=csjarchlinux
fi


timedatectl set-ntp true  # Synchronize motherboard clock

if [[ $part == "no" ]]; then
    pacman -Sy dialog --noconfirm                                                                  #install dialog for selecting disk
    devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)                 #gets disk info for selection
    drive=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1       #chose which drive to format
    clear           # clears blue screen from
    lsblk           # shows avalable drives
    echo ${drive}   # confirms drive selection
    part_boot="$(ls ${drive}* | grep -E "^${drive}p?1$")"     #finds boot partion
    part_root="$(ls ${drive}* | grep -E "^${drive}p?2$")"     #finds root partion
    cryptsetup luksOpen ${part_root} cryptroot  # Open the mapper
    mount /dev/mapper/cryptroot /mnt
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
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@ /dev/mapper/cryptroot /mnt
    mkdir -p /mnt2/{home,var/cache/pacman/pkg,var,srv,tmp,boot}  # Create directories for each subvolume
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@home /dev/mapper/cryptroot /mnt/home
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@pkg /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@var /dev/mapper/cryptroot /mnt/var
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@srv /dev/mapper/cryptroot /mnt/srv
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@tmp /dev/mapper/cryptroot /mnt/tmp
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
    cryptsetup luksOpen ${part_root} cryptroot  # Open the mapper
    
    mkfs.vfat -F32 ${part_boot}  # Format the EFI partition
    mkfs.btrfs /dev/mapper/cryptroot  # Format the encrypted partition
    
    mount /dev/mapper/cryptroot /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@pkg
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@srv
    btrfs subvolume create /mnt/@tmp
    umount /mnt
    
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@ /dev/mapper/cryptroot /mnt
    mkdir -p /mnt/{home,var/cache/pacman/pkg,var,srv,tmp,boot}  # Create directories for each subvolume
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@home /dev/mapper/cryptroot /mnt/home
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@pkg /dev/mapper/cryptroot /mnt/var/cache/pacman/pkg
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@var /dev/mapper/cryptroot /mnt/var
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@srv /dev/mapper/cryptroot /mnt/srv
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@tmp /dev/mapper/cryptroot /mnt/tmp
    chattr +C /mnt/var  # Copy on write disabled
    mount ${part_boot} /mnt/boot  # Mount the boot partition
    
fi

sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Making pacman prettier
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Add color to pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf  # Parallel downloads
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # multilib

read -p "Do you want to update and sync the mirrors before proceeding?" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reflector --latest 50 --verbose --protocol https --sort rate --save /etc/pacman.d/mirrorlist -c US --ipv6
    pacman -Syy
fi

pacstrap -i /mnt base base-devel linux linux-firmware git nano fish \
    intel-ucode networkmanager efibootmgr btrfs-progs neovim zram-generator zsh \
    pipewire-pulse bluez bluez-utils \
    gnu-free-fonts ttf-droid \
    pavucontrol ntfs-3g openssh python-pip wget reflector \
    nvidia lib32-nvidia-utils nvidia-utils lib32-opencl-nvidia nvidia-settings lib32-vkd3d vkd3d nvidia-prime opencl-nvidia \
    steam-native-runtime ppsspp nvtop vulkan-tools wine-staging lutris winetricks \
    plasma-meta knotes plasma-wayland-session kde-utilities-meta kde-system-meta packagekit-qt5 fwupd kmail flatpak spectacle \
    libreoffice-fresh qbittorrent \
    vivaldi vivaldi-ffmpeg-codecs \
    jre8-openjdk jre11-openjdk jre-openjdk \
    system-config-printer cups vlc discord neofetch apparmor gparted \
    exfat-utils

genfstab -U /mnt >> /mnt/etc/fstab  # Generate the entries for fstab
arch-chroot /mnt /bin/bash << EOF

timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null
hwclock --systohc
sed -i "s/#en_US/en_US/g" /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen

echo -e "127.0.0.1\tlocalhost" > /etc/hosts
echo -e "::1\t\tlocalhost" >> /etc/hosts

echo -e "KEYMAP=$keymap" > /etc/vconsole.conf
sed -i "s/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g" /etc/sudoers
sed -i "/#Color/a ILoveCandy" /etc/pacman.conf
sed -i "s/#Color/Color/g" /etc/pacman.conf
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo -e "$hostname" > /etc/hostname
useradd -m -g users -G wheel -s /bin/fish $username
echo -en "$root_password\n$root_password" | passwd
echo -en "$user_password\n$user_password" | passwd $username

useradd -g users -G wheel -m temp
sudo -u temp mkdir -p /tmp/yay && cd /tmp/yay && sudo -u temp git clone https://aur.archlinux.org/yay.git && cd yay && sudo -u temp makepkg -si --noconfirm
sudo -u temp mkdir -p /tmp/epson && cd /tmp/epson && git clone https://aur.archlinux.org/epson-inkjet-printer-escpr.git && cd epson-inkjet-printer-escpr && sudo -u temp makepkg -si --noconfirm
sudo -u temp mkdir -p /tmp/ttf-ms-fonts && cd /tmp/ttf-ms-fonts && sudo -u temp git clone https://aur.archlinux.org/ttf-ms-fonts.git && cd ttf-ms-fonts && sudo -u temp makepkg -si --noconfirm
cd /tmp && touch panel-restart && echo '#!/bin/bash' > panel-restart && echo 'killall plasmashell;plasmashell &' >> panel-restart && chmod +x panel-restart && mv panel-restart /usr/bin/
touch reflector-update && echo '#!/bin/bash' > reflector-update && echo 'sudo reflector --latest 50 --verbose --protocol https --sort rate --save /etc/pacman.d/mirrorlist -c US --ipv6' >> reflector-update && chmod +x reflector-update && mv reflector-update /usr/bin
userdel -r temp

systemctl enable NetworkManager fstrim.timer sddm bluetooth cups apparmor

journalctl --vacuum-size=100M --vacuum-time=2weeks

touch /etc/systemd/zram-generator.conf
tee -a /etc/systemd/zram-generator.conf << END
[zram0]
zram-fraction = 1
max-zram-size = 4096
END

touch /etc/sysctl.d/99-swappiness.conf
echo 'vm.swappiness=20' > /etc/sysctl.d/99-swappiness.conf

mkdir -p /etc/pacman.d/hooks/
touch /etc/pacman.d/hooks/100-systemd-boot.hook
tee -a /etc/pacman.d/hooks/100-systemd-boot.hook << END
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
END


touch /etc/pacman.d/hooks/nvidia.hook
tee -a /etc/pacman.d/hooks/nvidia.hook << END
  
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia
Target=linux

[Action]
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -p linux
END


sed -i "s/^HOOKS.*/HOOKS=(base systemd keyboard autodetect sd-vconsole modconf block sd-encrypt btrfs filesystems fsck)/g" /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
mkinitcpio -P
bootctl --path=/boot/ install

mkdir -p /boot/loader/
tee -a /boot/loader/loader.conf << END
default arch.conf
console-mode max
editor no
END

mkdir -p /boot/loader/entries/
touch /boot/loader/entries/arch.conf
tee -a /boot/loader/entries/arch.conf << END
title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options lsm=lockdown,yama,apparmor,bpf rd.luks.name=$(blkid -s UUID -o value ${part_root})=cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rd.luks.options=discard nvidia-drm.modeset=1 nmi_watchdog=0 quiet rw
END

chsh -s /bin/fish
pacman-key --init
pacman-key --populate archlinux
pip install requests vdf
EOF
umount -R /mnt
