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
# password=csjarchlinux

read -p "do you want to wipe full drive yes or no, or press enter to use defaults:"$'\n' part
if [[ -z $part ]]; then
    part=yes
fi

read -p "Enter user name, or press enter to use defaults:"$'\n' username
if [[ -z $username ]]; then
    username=csjarchlinux
fi

read -p "Enter host name, or press enter to use defaults:"$'\n' hostname
if [[ -z $hostname ]]; then
    hostname=csjarchlinux
fi

read -s -p "Enter user password, or press enter to use defaults:"$'\n' password
if [[ -z $password ]]; then
    password=csjarchlinux
fi

timedatectl set-ntp true  # Synchronize motherboard clock

keymap=us

if [[ $part == "no" ]]; then
    pacman -Sy dialog --noconfirm  # Install dialog for selecting disk
    devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)  # Gets disk info for selection
    drive=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1  # Chose which drive to format
    clear  # Clears blue screen from
    lsblk  # Shows avalable drives
    echo ${drive}  # Confirms drive selection
    part_boot="$(ls ${drive}* | grep -E "^${drive}p?1$")"  # Finds boot partion
    part_root="$(ls ${drive}* | grep -E "^${drive}p?2$")"  # Finds root partion
    mkfs.vfat -F32 ${part_boot}  # Format the EFI partition
    mount ${part_root} /mnt

    btrfs filesystem label ${part_root} arch

    # Clearing non home data

    btrfs subvolume delete /mnt/@pkg
    btrfs subvolume delete /mnt/@var/lib/portables
    btrfs subvolume delete /mnt/@var/lib/machines
    btrfs subvolume delete /mnt/@var
    btrfs subvolume delete /mnt/@srv
    btrfs subvolume delete /mnt/@tmp
    btrfs subvolume delete /mnt/@/.snapshots
    btrfs subvolume delete /mnt/@home/.snapshots
    btrfs subvolume delete /mnt/@

    # Creating new subvolumes
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@pkg
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@srv
    btrfs subvolume create /mnt/@tmp


    umount /mnt

    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@ ${part_root} /mnt
    mkdir -p /mnt/{home,var/cache/pacman/pkg,var,srv,tmp,boot}  # Create directories for each subvolume
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@home ${part_root} /mnt/home
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@pkg ${part_root} /mnt/var/cache/pacman/pkg
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@var ${part_root} /mnt/var
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@srv ${part_root} /mnt/srv
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@tmp ${part_root} /mnt/tmp
    chattr +C /mnt/var  # Copy on write disabled
	mount ${part_boot} /mnt/boot  # Mount the boot partition
else
	pacman -Sy dialog --noconfirm  # Install dialog for selecting disk
    devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)  # Gets disk info for selection
    drive=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1  # Chose which drive to format
    clear  # Clears blue screen from
    lsblk  # Shows available drives
    echo ${drive}  # Confirms drive selection
    sgdisk --zap-all ${drive}  # Delete tables
    printf "n\n1\n\n+512M\nef00\nn\n2\n\n\n\nw\ny\n" | gdisk ${drive}  # Format the drive

    part_boot="$(ls ${drive}* | grep -E "^${drive}p?1$")"  # Finds boot partion
    part_root="$(ls ${drive}* | grep -E "^${drive}p?2$")"  # Finds root partion

    echo ${part_boot}  # Confirms boot partion selection
    echo ${part_root}  # Confirms root partion selection

   

    mkfs.vfat -F32 ${part_boot}  # Format the EFI partition
    mkfs.btrfs -f ${part_root}  # Format the encrypted partition

    btrfs filesystem label ${part_root} arch

    mount ${part_root} /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@pkg
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@srv
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@Games
    btrfs subvolume create /mnt/@steamapps
    btrfs subvolume create /mnt/@Videos
    umount /mnt

    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@ ${part_root} /mnt
    mkdir -p /mnt/{home,var/cache/pacman/pkg,var,srv,tmp,boot}  # Create directories for each subvolume
    mkdir -p /mnt/home/$username
    mkdir -p /mnt/home/$username/Games
    mkdir -p /mnt/home/$username/Videos
    mkdir -p /mnt/home/$username/.local/share/Steam/steamapps/
    mkdir -p /mnt/home/$username/Games/steamapps/
    
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@home ${part_root} /mnt/home
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@Games ${part_root} /mnt/home/$username/Games
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@steamapps ${part_root} /mnt/home/$username/Games/steamapps/
    mount --bind /home/stephen/Games/steamapps/ /home/stephen/.local/share/Steam/steamapps/
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@pkg ${part_root} /mnt/var/cache/pacman/pkg
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@var ${part_root} /mnt/var
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@srv ${part_root} /mnt/srv
    mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@tmp ${part_root} /mnt/tmp
    chattr +C /mnt/var  # Copy on write disabled
    mount ${part_boot} /mnt/boot  # Mount the boot partition
fi

sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Making pacman prettier
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Add color to pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf  # Parallel downloads
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # multilib

reflector --latest 50 --verbose --protocol https --sort rate --save /etc/pacman.d/mirrorlist -c US --ipv6
pacman -Syy


pacstrap -i /mnt --noconfirm base base-devel linux linux-firmware linux-headers git nano fish \
    intel-ucode networkmanager efibootmgr btrfs-progs zram-generator \
    pipewire-pulse bluez bluez-utils \
    gnu-free-fonts ttf-droid \
    pavucontrol ntfs-3g openssh python-pip wget reflector \
    nvidia lib32-nvidia-utils nvidia-utils lib32-opencl-nvidia nvidia-settings lib32-vkd3d vkd3d nvidia-prime opencl-nvidia \
    steam-native-runtime ppsspp nvtop vulkan-tools wine-staging lutris winetricks \
    plasma-meta kde-applications-meta plasma-wayland-session packagekit-qt5 fwupd flatpak \
    libreoffice-fresh qbittorrent gamemode lib32-gamemode \
    vivaldi vivaldi-ffmpeg-codecs r8168 \
    jre8-openjdk jre11-openjdk jre-openjdk wireless-regdb \
    system-config-printer cups vlc discord neofetch gparted snapper \
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
echo -en "$password\n$password" | passwd
echo -en "$password\n$password" | passwd $username

useradd -g users -G wheel -m temp
sudo -u temp mkdir -p /tmp/yay && cd /tmp/yay && sudo -u temp git clone https://aur.archlinux.org/yay.git && cd yay && sudo -u temp makepkg -si --noconfirm
sudo -u temp yay -S epson-inkjet-printer-escpr --noconfirm
sudo -u temp yay -S ttf-ms-fonts --noconfirm
sudo -u temp yay -S snapper-gui-git --noconfirm
cd /tmp && touch panel-restart && echo '#!/bin/bash' > panel-restart && echo 'killall plasmashell;plasmashell &' >> panel-restart && chmod +x panel-restart && mv panel-restart /usr/bin/
touch reflector-update && echo '#!/bin/bash' > reflector-update && echo 'sudo reflector --latest 50 --verbose --protocol https --sort rate --save /etc/pacman.d/mirrorlist -c US --ipv6' >> reflector-update && chmod +x reflector-update && mv reflector-update /usr/bin
userdel -r temp

systemctl enable NetworkManager fstrim.timer sddm bluetooth cups snapper-timeline.timer snapper-cleanup.timer 

snapper -c root --no-dbus create-config /
snapper -c home --no-dbus create-config /home

sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"'/g /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="16"'/g /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="7"'/g /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="4"'/g /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="1"'/g /etc/snapper/configs/root
sed -i 's/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"'/g /etc/snapper/configs/root
sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"'/g /etc/snapper/configs/home
sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="16"'/g /etc/snapper/configs/home
sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="7"'/g /etc/snapper/configs/home
sed -i 's/TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="4"'/g /etc/snapper/configs/home
sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="1"'/g /etc/snapper/configs/home
sed -i 's/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"'/g /etc/snapper/configs/home

chown -R :wheel /home/.snapshots/

journalctl --vacuum-size=100M --vacuum-time=2weeks

touch /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
tee -a /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf << END
[connection]
wifi.powersave = 2
END

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

base udev autodetect modconf block filesystems keyboard fsck
sed -i "s/^HOOKS.*/HOOKS=(base udev autodetect modconf block btrfs filesystems keyboard fsck)/g" /etc/mkinitcpio.conf
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
options root="LABEL=arch" rootflags=subvol=@ rw nvidia-drm.modeset=1

END


chsh -s /bin/fish
pacman-key --init
pacman-key --populate archlinux
pip install requests vdf
sudo chown -R $username /home/$username/
EOF

read -p "Do you wish to reboot? type y for yes"$'\n' -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo "rebooting now"
reboot
else echo "script has finished"
fi
