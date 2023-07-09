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

sed -i "/#Color/a ILoveCandy" /etc/pacman.conf  # Making pacman prettier
sed -i "s/#Color/Color/g" /etc/pacman.conf  # Add color to pacman
sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 10/g" /etc/pacman.conf  # Parallel downloads
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # multilib

reflector --latest 50 --verbose --protocol https --sort rate --save /etc/pacman.d/mirrorlist -c US --ipv6
pacman -Syy

pacstrap -i /mnt --noconfirm base base-devel linux linux-lts linux-firmware linux-lts-headers linux-headers git nano fish \
    intel-ucode networkmanager efibootmgr btrfs-progs zram-generator \
    pipewire-pulse bluez bluez-utils \
    gnu-free-fonts ttf-droid piper noto-fonts-emoji \
    pavucontrol ntfs-3g openssh python-pip wget reflector \
    nvidia lib32-nvidia-utils nvidia-lts nvidia-utils lib32-opencl-nvidia nvidia-settings lib32-vkd3d vkd3d nvidia-prime opencl-nvidia \
    steam-native-runtime ppsspp nvtop vulkan-tools wine-staging lutris winetricks \
    plasma-meta kde-applications-meta plasma-wayland-session packagekit-qt5 fwupd flatpak \
    libreoffice-fresh vivaldi vivaldi-ffmpeg-codecs r8168 \
    jre8-openjdk jre11-openjdk jre-openjdk wireless-regdb \
    system-config-printer cups vlc discord neofetch gparted \
    exfat-utils r8168-lts
#    snapper exfat-utils r8168-lts
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
#sudo -u temp yay -S snapper-gui-git --noconfirm
sudo -u temp yay -S protonup-qt --noconfirm
mkdir -p /home/$username/.config
touch /home/$username/.config/baloofilerc
tee -a /home/$username/.config/baloofilerc << END
[General]
dbVersion=2
exclude filters=*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,core-dumps,lost+found
exclude filters version=8
exclude folders[$~]=$~home/G'raha/Rudeus/,$~home/G'raha/Alphinaud/,$~home/G'raha/Rimuru/
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
systemctl enable NetworkManager fstrim.timer sddm bluetooth cups
#systemctl enable NetworkManager fstrim.timer sddm bluetooth cups snapper-timeline.timer snapper-cleanup.timer
 
#snapper -c root --no-dbus create-config /
#snapper -c home --no-dbus create-config /home
#sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"'/g /etc/snapper/configs/root
#sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="16"'/g /etc/snapper/configs/root
#sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="7"'/g /etc/snapper/configs/root
#sed -i 's/TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="4"'/g /etc/snapper/configs/root
#sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="1"'/g /etc/snapper/configs/root
#sed -i 's/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"'/g /etc/snapper/configs/root
#sed -i 's/ALLOW_GROUPS=""/ALLOW_GROUPS="wheel"'/g /etc/snapper/configs/home
#sed -i 's/TIMELINE_LIMIT_HOURLY="10"/TIMELINE_LIMIT_HOURLY="16"'/g /etc/snapper/configs/home
#sed -i 's/TIMELINE_LIMIT_DAILY="10"/TIMELINE_LIMIT_DAILY="7"'/g /etc/snapper/configs/home
#sed -i 's/TIMELINE_LIMIT_WEEKLY="0"/TIMELINE_LIMIT_WEEKLY="4"'/g /etc/snapper/configs/home
#sed -i 's/TIMELINE_LIMIT_MONTHLY="10"/TIMELINE_LIMIT_MONTHLY="1"'/g /etc/snapper/configs/home
#sed -i 's/TIMELINE_LIMIT_YEARLY="10"/TIMELINE_LIMIT_YEARLY="0"'/g /etc/snapper/configs/home
#chown -R :wheel /home/.snapshots/
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
options root="LABEL=arch" rootflags=subvol=@ rw nvidia-drm.modeset=1 ibt=off
END
touch /boot/loader/entries/arch.conf
tee -a /boot/loader/entries/arch-lts.conf << END
title Arch Linux
linux /vmlinuz-linux-lts
initrd /intel-ucode.img
initrd /initramfs-linux-lts.img
options root="LABEL=arch" rootflags=subvol=@ rw nvidia-drm.modeset=1 ibt=off
END
chsh -s /bin/fish
pacman-key --init
pacman-key --populate archlinux
pip install requests vdf
sudo chown -R $username /home/$username/
EOF

echo "script has finished"
