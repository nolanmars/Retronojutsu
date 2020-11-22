#!/bin/bash

clear

loadkeys fr > /dev/null 2>&1

# Sequence de test des pré-requis

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

# Saisie des variables

disk='/dev/sda'
efipart='/dev/sda1'
mainpart='/dev/sda2'
hostname='consolemul'
rootpasswd='consolemul'
user='sirjaguar'
userpasswd='consolemul'

# Installation

timedatectl set-ntp true

fdisk -l $disk > /dev/null 2>&1

wipefs --all --force $disk > /dev/null 2>&1

sgdisk $disk -o > /dev/null 2>&1

sgdisk $disk -n 1::+512MiB -t 1:ef00 > /dev/null 2>&1

sgdisk $disk -n 2 > /dev/null 2>&1

mkfs.vfat -F32 $efipart > /dev/null 2>&1

mkfs.ext4 $mainpart > /dev/null 2>&1

mount $mainpart /mnt > /dev/null 2>&1

mkdir /mnt/boot > /dev/null 2>&1

mount $efipart /mnt/boot > /dev/null 2>&1

pacstrap /mnt base linux linux-firmware > /dev/null 2>&1

genfstab -U /mnt >> /mnt/etc/fstab > /dev/null 2>&1

arch-chroot /mnt /bin/bash <<EOF

echo $hostname > /etc/hostname

echo '127.0.1.1 $hostname.localdomain $hostname' >> /etc/hosts

echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen

locale-gen > /dev/null 2>&1

echo LANG="fr_FR.UTF-8" > /etc/locale.conf

export LANG=fr_FR.UTF-8

echo KEYMAP=fr > /etc/vconsole.conf

ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

hwclock --systohc

pacman -S --noconfirm dhcpcd efibootmgr > /dev/null 2>&1

systemctl enable dhcpcd > /dev/null 2>&1

echo root:$rootpasswd | chpasswd

useradd -m $user

echo $user:$userpasswd | chpasswd

efibootmgr --disk $disk --part 1 --create --label "Consolemul" --loader /vmlinuz-linux --unicode 'root=$mainpart rw initrd=\initramfs-linux.img'


# Installation suite

pacman -S --noconfirm dropbear sudo > /dev/null 2>&1 # Installation packages supplémentaires

echo '$user ALL=(ALL:ALL) ALL' >> /etc/sudoers # Ajoute l'utilisateur à la lister des sudoers

systemctl enable dropbear # Activer le service du serveur SSH dropbear

EOF
