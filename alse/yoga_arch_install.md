#Скачиваю ISO и загружаюсь с него

	loadkeys ru
	setfont cyr-sun16
	timedatectl set-ntp true
	cfdisk

#	/dev/sda1	/boot	100M
# 	/dev/sda2	/	70%
# 	/dev/sda3	/home	30%

	mkfs.ext2  /dev/sda1 -L boot_part
	mkfs.ext4  /dev/sda2 -L root_part
	mkfs.ext4  /dev/sda3 -L home_part

	mount /dev/sda2 /mnt; mkdir /mnt/{boot,home}; mount /dev/sda1 /mnt/boot; mount /dev/sda3 /mnt/home

	mount -t proc proc proc/; mount --rbind /sys sys/; mount --rbind /dev dev/

	reflector --verbose -c RU,ES,PL,US,JP -l 40 -p https --sort rate --save /etc/pacman.d/mirrorlist

	pacstrap /mnt base base-devel linux mkinitcpio git dialog wpa_supplicant grub bash-completion openssh sudo micro xclip bluez bluez-utils linux-firmware dhcpcd

	genfstab -P /mnt > /mnt/etc/fstab

	arch-chroot /mnt

	echo "ShAmAnNoTeBoOk" > /etc/hostname

	ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

	echo -e "en_US.UTF-8 UTF-8\nru_RU.UTF-8 UTF-8" > /etc/locale.gen

	locale-gen

	echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf

# /etc/vconsole.conf ==>
LOCALE="ru_RU.UTF-8"
KEYMAP=ru
FONT="UniCyrExt_8x16"
CONSOLEMAP=""
USECOLOR="yes"
KONSOLEFONT="UniCyrExt_8x16"


# /etc/mkinitcpio.conf ==> HOOKS=(base udev autodetect modconf kms keyboard sd-vconsole block filesystems fsck resume)

	cd /tmp

	mkinitcpio -p linux

	passwd

# Установка Chaotic-AUR

	pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com

	pacman-key --lsign-key FBA220DFC880C036

	pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# /etc/pacman.conf --> Color

	pacman -Syy

	grub-install /dev/sda

	sudo nano /etc/default/grub

# GRUB_TIMEOUT=0

	grub-mkconfig -o /boot/grub/grub.cfg

# /etc/ssh/sshd_config ==> PermitRootlogin yes

	reboot

	systemctl enable dhcpcd

	dhcpcd enp0s3

	useradd -m -g users -G wheel -s /bin/bash shaman

	passwd shaman

	nano /etc/sudoers

# %wheel ALL=(ALL) NOPASSWD: ALL

	nano /etc/pacman.conf

#Для работы 32-битных приложений в 64-битной системе необходимо раскомментировать репозиторий multilib:
# [multilib]
# Include = /etc/pacman.d/mirrorlist

	pacman -Syy

# Установка YAY

	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg -sri

	systemctl enable dhcpcd

	logout

