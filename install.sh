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
sed -i "s/#MAKEFLAGS/MAKEFLAGS/g" /etc/makepkg.conf
sed -i "s/-j2/-j6/g" /etc/makepkg.conf

reflector --latest 50 --verbose --protocol https --sort rate --save /etc/pacman.d/mirrorlist -c US --ipv6
pacman -Syy
pacman -Sy archlinux-keyring --noconfirm

pacstrap -i /mnt --noconfirm base base-devel linux linux-firmware linux-headers git nano fish \
    intel-ucode networkmanager efibootmgr \
    pipewire-pulse bluez bluez-utils \
    gnu-free-fonts ttf-droid piper noto-fonts-emoji \
    pavucontrol ntfs-3g openssh python-pip wget reflector \
    mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau  radeontop \
    steam-native-runtime ppsspp nvtop vulkan-tools wine-staging lutris winetricks ffnvcodec-headers \
    plasma-meta kde-applications-meta packagekit-qt5 fwupd flatpak \
    libreoffice-fresh vivaldi vivaldi-ffmpeg-codecs mtools \
    jre8-openjdk jre11-openjdk jre17-openjdk jre21-openjdk jre-openjdk wireless-regdb \
    system-config-printer cups vlc vlc-plugins-all discord gparted mkinitcpio python-pipx \
    exfat-utils r8168-lts x265 helvum foliate libde265 libmatroska kvazaar qbittorrent \
    pipewire-jack powerdevil phonon-qt5-vlc x264 x265 mpg123 aom flac libkate libogg libtheora \
    libvpx opus speex libvorbis libva-nvidia-driver dav1d mkvtoolnix-gui unrar openrgb




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
sed -i "s/#MAKEFLAGS/MAKEFLAGS/g" /etc/makepkg.conf
sed -i "s/-j2/-j6/g" /etc/makepkg.conf
sed -i "s#bin/discord#bin/discord --enable-features=UseOzonePlatform --ozone-platform=wayland#g" /opt/discord/discord.desktop
echo -e "$hostname" > /etc/hostname
useradd -m -g users -G wheel -s /bin/fish $username
echo -en "$password\n$password" | passwd
echo -en "$password\n$password" | passwd $username
useradd -g users -G wheel -m temp
sudo -u temp mkdir -p /tmp/yay && cd /tmp/yay && sudo -u temp git clone https://aur.archlinux.org/yay.git && cd yay && sudo -u temp makepkg -si --noconfirm
#rustup update
#sudo -u temp yay -S python2-bin --noconfirm
#sudo -u temp yay -S ogmrip-ac3 --noconfirm
sudo -u temp yay -S scream --noconfirm
sudo -u temp yay -S cider --noconfirm
sudo -u temp yay -S uxplay --noconfirm
sudo -u temp yay -S brother-hl-l3210cw --noconfirm
sudo -u temp yay -S ttf-ms-fonts --noconfirm
sudo -u temp yay -S protonup-qt --noconfirm
sudo -u temp yay -S prismlauncher --noconfirm
sudo -u temp yay -S neofetch --noconfirmc
mkdir -p /home/$username/.config
touch /home/$username/.config/baloofilerc
tee -a /home/$username/.config/baloofilerc << END
[General]
dbVersion=2
exclude filters=*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,core-dumps,lost+found
exclude filters version=8
exclude folders[$~]=$~home/g'raha/,$~home/alphinaud/
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
systemctl enable NetworkManager sddm bluetooth cups

journalctl --vacuum-size=100M --vacuum-time=2weeks
touch /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf
tee -a /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf << END
[connection]
wifi.powersave = 2

sed -i "s/^HOOKS.*/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/g" /etc/mkinitcpio.conf
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
options root="LABEL=arch" rw
END

touch /boot/loader/entries/archLTS.conf
tee -a /boot/loader/entries/arch.conf << END
title Arch Linux
linux vmlinuz-linux-lts
initrd /intel-ucode.img
initrd initramfs-linux-lts.img
options root="LABEL=arch" rw
END

chsh -s /bin/fish
pacman-key --init
pacman-key --populate archlinux
#pipx install requests vdf
sudo chown -R $username /home/$username/
EOF

echo "script has finished"
