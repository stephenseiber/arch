devicelist=$(lsblk -dplnx size -o name,size | grep -Ev "boot|rpmb|loop" | tac)  # Gets disk info for selection
drive2=$(dialog --stdout --menu "Select second drive" 0 0 0 ${devicelist}) || exit 1  # Chose which 
clear
#drive2p="$(ls ${drive}* | grep -E "^${drive}p?3$")"  # Finds partition
drive2p=${drive2}1
mount ${drive2p} /mnt
btrfs subvolume create /mnt/@"Y'shtola"
btrfs subvolume create /mnt/@Alphinaud
btrfs subvolume create /mnt/@Thancred
umount /mnt
