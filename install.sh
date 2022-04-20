#!/usr/bin/env bash
mount -o remount,size=8G /run/archiso/cowspace
clear   # Clear the TTY
set -e  # The script will not run if we CTRL + C, or in case of an error
set -u  # Treat unset variables as an error when substituting

read -p "Enter user name, or press enter to use defaults:"$'\n' username
read -s -p "Enter user password, or press enter to use defaults:"$'\n' password
read -p "Enter host name, or press enter to use defaults:"$'\n' hostname

timedatectl set-ntp true  # Synchronize motherboard clock
keymap=us

pacman -Sy dialog archlinux-keyring --noconfirm  
# Install dialog for selecting disk also updates keyring for if you are using older install disk

devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)  # Gets disk info for selection
drive=$(dialog --stdout --menu "Select installation disk" 0 0 0 ${devicelist}) || exit 1  # Chose which drive to format
clear  # Clears blue screen

devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)  # Gets disk info for selection
drive2=$(dialog --stdout --menu "Select second drive" 0 0 0 ${devicelist}) || exit 1  # Chose which 
clear # Clears blue screen
drive2p="$(ls ${drive2}* | grep -E "^${drive2}p?1$")"  # Finds partition

devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)  # Gets disk info for selection
drive3=$(dialog --stdout --menu "Select second drive" 0 0 0 ${devicelist}) || exit 1  # Chose which 
clear # Clears blue screen
drive3p="$(ls ${drive2}* | grep -E "^${drive2}p?1$")"  # Finds partition

sgdisk --zap-all ${drive}  # Delete tables
printf "n\n1\n\n+512M\nef00\nn\n2\n\n\n\nw\ny\n" | gdisk ${drive}  # Format the drive

part_boot="$(ls ${drive}* | grep -E "^${drive}p?1$")"  # Finds boot partion
part_root="$(ls ${drive}* | grep -E "^${drive}p?2$")"  # Finds root partion

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
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@home ${part_root} /mnt/home
mkdir -p /mnt/home/$username

mkdir -p /mnt/home/$username/"G'raha"
mkdir -p /mnt/home/$username/"G'raha"/Rudeus
mkdir -p /mnt/home/$username/"G'raha"/Alphinaud
mkdir -p /mnt/home/$username/"G'raha"/Thancred
mkdir -p /mnt/home/$username/"G'raha"/"Y'shtola"
mkdir -p /mnt/home/$username/"G'raha"/Rimuru

mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@Alphinaud ${drive2p} /mnt/home/$username/"G'raha"/Alphinaud
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@Thancred ${drive2p} /mnt/home/$username/"G'raha"/Thancred
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@"Y'shtola" ${drive2p} /mnt/home/$username/"G'raha"/"Y'shtola"
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@Rimuru ${drive3p} /mnt/home/$username/"G'raha"/Rimuru

mkdir -p /mnt/home/$username/"G'raha"/Rudeus/
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@Games ${part_root} mkdir -p /mnt/home/$username/"G'raha"/Rudeus/
mkdir -p /mnt/home/$username/Videos
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@Videos ${part_root} /mnt/home/$username/Videos
mkdir -p /mnt/home/$username/.local/
mkdir -p /mnt/home/$username/Documents
mkdir -p /mnt/home/$username/Downloads
mkdir -p /mnt/home/$username/Pictures

mount --bind /mnt/home/$username/"G'raha"/"Y'shtola"/Documents/ /mnt/home/$username/Documents/
mount --bind /mnt/home/$username/"G'raha"/"Y'shtola"/Downloads/ /mnt/home/$username/Downloads/
mount --bind /mnt/home/$username/"G'raha"/"Y'shtola"/Pictures/ /mnt/home/$username/Pictures
mkdir -p /mnt/home/$username/.local/share/
mkdir -p /mnt/home/$username/.local/share/Steam/steamapps/
mkdir -p /mnt/home/$username/"G'raha"/Rudeus/steamapps/
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@steamapps ${part_root} /mnt/home/$username/"G'raha"/Rudeus/steamapps/
mount --bind /mnt/home/$username/"G'raha"/Rudeus/steamapps/ /mnt/home/$username/.local/share/Steam/steamapps/
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@pkg ${part_root} /mnt/var/cache/pacman/pkg
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@var ${part_root} /mnt/var
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@srv ${part_root} /mnt/srv
mount -o noatime,compress-force=zstd:1,space_cache=v2,subvol=@tmp ${part_root} /mnt/tmp
chattr +C /mnt/var  # Copy on write disabled
mount ${part_boot} /mnt/boot  # Mount the boot partition

sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Making pacman prettier
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Add color to pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf  # Parallel downloads
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # multilib

reflector --latest 50 --verbose --protocol https --sort rate --save /etc/pacman.d/mirrorlist -c US --ipv6
pacman -Syy

pacstrap -i /mnt --noconfirm base base-devel linux linux-firmware linux-headers git nano fish \
    intel-ucode networkmanager efibootmgr btrfs-progs zram-generator \
    pipewire-pulse bluez bluez-utils \
    gnu-free-fonts ttf-droid piper noto-fonts-emoji \
    pavucontrol ntfs-3g openssh python-pip wget reflector \
    mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau  radeontop \
    steam-native-runtime ppsspp vulkan-tools wine-staging lutris winetricks \
    plasma-meta kde-applications-meta plasma-wayland-session packagekit-qt5 fwupd flatpak \
    libreoffice-fresh vivaldi vivaldi-ffmpeg-codecs \
    jre8-openjdk jre11-openjdk jre-openjdk wireless-regdb \
    system-config-printer cups vlc discord neofetch gparted snapper \
    exfat-utils

genfstab -U /mnt >> /mnt/etc/fstab  # Generate the entries for fstab
arch-chroot /mnt /bin/bash << EOF

timedatectl set-ntp true
ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null
hwclock --systohc
sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen

echo -e "127.0.0.1\tlocalhost" > /etc/hosts
echo -e "::1\t\tlocalhost" >> /etc/hosts
echo -e "KEYMAP=$keymap" > /etc/vconsole.conf
#sed -i -e "s/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g" /etc/sudoers
echo -e "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
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
sudo -u temp yay -S protonup-qt --noconfirm

mkdir -p /home/$username/.config
touch /home/$username/.config/baloofilerc
tee -a /home/$username/.config/baloofilerc << END
[General]
dbVersion=2
exclude filters=*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,core-dumps,lost+found
exclude filters version=8
exclude folders[$~]=$~home/Games/
END

sed -i 's/~home/HOME'/g /home/$username/.config/baloofilerc
sed -i 's/~]/e]'/g /home/$username/.config/baloofilerc

mkdir -p /home/$username/.config/fish
touch /home/$username/.config/fish/config.fish
tee -a /home/$username/.config/fish/config.fish << END
neofetch
if status is-interactive
    # Commands to run in interactive sessions can go here
end
END

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
max-zram-size = 1024
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

sed -i "s/^HOOKS.*/HOOKS=(base udev autodetect modconf block btrfs filesystems keyboard fsck)/g" /etc/mkinitcpio.conf
sed -i 's/^MODULES.*/MODULES=(amdgpu)/' /etc/mkinitcpio.conf
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
options root="LABEL=arch" rootflags=subvol=@ rw
END

chsh -s /bin/fish
pacman-key --init
pacman-key --populate archlinux
pip install requests vdf
sudo chown -R $username /home/$username/
EOF

echo "script has finished"
