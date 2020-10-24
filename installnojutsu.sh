#!/bin/bash

clear

loadkeys fr > /dev/null 2>&1

echo "UEFI"
ls /sys/firmware/efi/efivars > /dev/null 2>&1
if [ $? = 2 ]
	then
		echo "KO"
		exit
fi
echo "OK"

echo "Internet"
ping -c 3 www.google.fr > /dev/null 2>&1
if [ $? = 2 ]
	then
		echo "KO"
		exit
fi
echo "OK"

timedatectl set-ntp true

fdisk -l /dev/sda > /dev/null 2>&1

wipefs --all --force /dev/sda > /dev/null 2>&1

sgdisk /dev/sda -o > /dev/null 2>&1

sgdisk /dev/sda -n 1::+512MiB -t 1:ef00 > /dev/null 2>&1

sgdisk /dev/sda -n 2 > /dev/null 2>&1

mkfs.vfat -F32 /dev/sda1 > /dev/null 2>&1

mkfs.ext4 /dev/sda2 > /dev/null 2>&1

mount /dev/sda2 /mnt > /dev/null 2>&1

mkdir /mnt/boot > /dev/null 2>&1

mount /dev/sda1 /mnt/boot > /dev/null 2>&1

pacstrap /mnt base linux linux-firmware > /dev/null 2>&1

genfstab -U /mnt >> /mnt/etc/fstab > /dev/null 2>&1

arch-chroot /mnt /bin/bash <<EOF

echo retro-mars > /etc/hostname

echo '127.0.1.1 retro-mars.localdomain retromars' >> /etc/hosts

echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen

locale-gen

echo LANG="fr_FR.UTF-8" > /etc/locale.conf

export LANG=fr_FR.UTF-8

echo KEYMAP=fr > /etc/vconsole.conf

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

hwclock --systohc

pacman -S --noconfirm dhcpcd efibootmgr > /dev/null 2>&1

systemctl enable dhcpcd

echo root:wstmjqcg79 | chpasswd

efibootmgr --disk /dev/sda --part 1 --create --label "Arch Linux" --loader /vmlinuz-linux --unicode 'root=/dev/sda2 rw initrd=\initramfs-linux.img'

EOF
