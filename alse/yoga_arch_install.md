#Скачиваю ISO и загружаюсь с него

	loadkeys ru
	setfont cyr-sun16
	timedatectl set-ntp true
	cfdisk

#/dev/sda1	/boot	100M

#/dev/sda2	/	70%

#/dev/sda3	/home	30%

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

#/etc/vconsole.conf ==>
LOCALE="ru_RU.UTF-8"
KEYMAP=ru
FONT="UniCyrExt_8x16"
CONSOLEMAP=""
USECOLOR="yes"
KONSOLEFONT="UniCyrExt_8x16"


#/etc/mkinitcpio.conf ==> HOOKS=(base udev autodetect modconf kms keyboard sd-vconsole block filesystems fsck resume)

	cd /tmp

	mkinitcpio -p linux

	passwd

#Установка Chaotic-AUR

	pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com

	pacman-key --lsign-key FBA220DFC880C036

	pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

#/etc/pacman.conf --> Color

	pacman -Syy

	grub-install /dev/sda

	sudo nano /etc/default/grub

#GRUB_TIMEOUT=0

	grub-mkconfig -o /boot/grub/grub.cfg

#/etc/ssh/sshd_config ==> PermitRootlogin yes

	reboot

	systemctl enable dhcpcd

	dhcpcd enp0s3

	useradd -m -g users -G wheel -s /bin/bash shaman

	passwd shaman

	nano /etc/sudoers

#%wheel ALL=(ALL) NOPASSWD: ALL

	nano /etc/pacman.conf

#Для работы 32-битных приложений в 64-битной системе необходимо раскомментировать репозиторий multilib:
#[multilib]
#Include = /etc/pacman.d/mirrorlist

	pacman -Syy

#Установка YAY

	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg -sri

	systemctl enable dhcpcd


#Установка драйверов

	paru -S aic94xx-firmware wd719x-firmware linux-firmware-qlogic linux-firmware upd72020x-fw

#Отключение не нужного в Gnome

	systemctl --user mask org.gnome.SettingsDaemon.Wacom.service # Интеграция с граф.планшетом Wacom
	systemctl --user mask org.gnome.SettingsDaemon.PrintNotifications.service # уведомления о печати принтером
	systemctl --user mask org.gnome.SettingsDaemon.Color.service # служба управления цветовыми профилями. Без этого сервиса не будет работать "теплый" режим.
	systemctl --user mask org.gnome.SettingsDaemon.A11ySettings.service # служба для управления специальными возможностями (для людей с ограниченными возможностями)
	systemctl --user mask org.gnome.SettingsDaemon.Wwan.service # отключение службы для работы с беспроводными сетями. Не отключать, если вы пользуетесь WiFi.
	systemctl --user mask org.gnome.SettingsDaemon.UsbProtection.service # отключение служб защиты от сторонних USB при блокировке экрана
	systemctl --user mask org.gnome.SettingsDaemon.ScreensaverProxy.service # автоматическая блокировка экрана (скринсейвер)
	systemctl --user mask org.gnome.SettingsDaemon.Sharing.service # общий доступ к каталогам и файлам
	systemctl --user mask org.gnome.SettingsDaemon.Rfkill.service # Отключение службы управления подсистемой rfkill, отвечающей за отключения любого радиопередатчика в системе (WiFi и Bluetooth)
	systemctl --user mask org.gnome.SettingsDaemon.Keyboard.service # Отключение службы управления клавиатурой и раскладками GNOME. Можно смело отключать если уже настроили все раскладки и настройки клавиатуры заранее, ибо все предыдущие настройки сохраняются при отключении.
	systemctl --user mask org.gnome.SettingsDaemon.Sound.service # Отключаем службу управления звуком GNOME. Отключает ТОЛЬКО настройки звука GNOME, а не вообще всё управлением звуком в системе.
	systemctl --user mask org.gnome.SettingsDaemon.Smartcard.service # интеграция с кард-ридером
	systemctl --user mask org.gnome.SettingsDaemon.Housekeeping.service # служба слежения за свободным местом на диске
	systemctl --user mask org.gnome.SettingsDaemon.Power.service # служба управления электропитанием

#Для включения службы:

	systemctl --user unmask --now СЛУЖБА

#Оптимизация и хардинг сетевого стека

	# --- Базовые настройки безопасности и сети ---

	# Отключение IPv6
	net.ipv6.conf.all.disable_ipv6 = 1
	net.ipv6.conf.default.disable_ipv6 = 1
	net.ipv6.conf.all.autoconf = 0          # Отключение автоконфигурации IPv6
	net.ipv6.conf.default.autoconf = 0
	net.ipv6.conf.all.accept_ra = 0         # Запрет приёма RA-сообщений IPv6
	net.ipv6.conf.default.accept_ra = 0

	# Усиленный антиспуфинг (strict mode)
	net.ipv4.conf.all.rp_filter = 2
	net.ipv4.conf.default.rp_filter = 2

	# Отключение ICMP redirect
	net.ipv4.conf.all.accept_redirects = 0
	net.ipv4.conf.default.accept_redirects = 0

	# Запрет отправки ICMP redirect
	net.ipv4.conf.all.send_redirects = 0
	net.ipv4.conf.default.send_redirects = 0

	# Отключение source routing
	net.ipv4.conf.all.accept_source_route = 0
	net.ipv4.conf.default.accept_source_route = 0

	# Защита от ICMP-атак
	net.ipv4.icmp_echo_ignore_broadcasts = 1          # Игнорирование широковещательных ping-запросов
	net.ipv4.icmp_ignore_bogus_error_responses = 1    # Игнорирование поддельных ICMP-ошибок

	# Защита от SYN flood
	net.ipv4.tcp_syncookies = 1

	# Защита от TIME_WAIT spoofing
	net.ipv4.tcp_rfc1337 = 1

	# Увеличение лимитов для SYN-фlood
	net.ipv4.tcp_max_syn_backlog = 4096

	# Быстрое закрытие соединений при переполнении очереди
	net.ipv4.tcp_abort_on_overflow = 1

	# Переиспользование сокетов в состоянии TIME_WAIT (не для NAT)
	net.ipv4.tcp_tw_reuse = 1

	# Автоматическое определение MTU (помогает при проблемах с VPN/NAT)
	net.ipv4.tcp_mtu_probing = 1

	# Включение TCP timestamps (улучшенная производительность)
	net.ipv4.tcp_timestamps = 1

	# Увеличение буферов приёма и отправки
	net.core.rmem_max = 16777216
	net.core.wmem_max = 16777216
	net.ipv4.tcp_rmem = 4096 12582912 16777216
	net.ipv4.tcp_wmem = 4096 12582912 16777216

	# Увеличение очереди пакетов на интерфейсе
	net.core.netdev_max_backlog = 300000

	# Увеличение максимального числа ожидающих подключений
	net.core.somaxconn = 4096

	# Современный congestion control
	net.core.default_qdisc = fq
	net.ipv4.tcp_congestion_control = bbr

	# --- Дополнительные настройки безопасности ---

	# Ограничение доступа к dmesg (только root)
	kernel.dmesg_restrict = 1

	# Скрытие указателей ядра в /proc/kallsyms
	kernel.kptr_restrict = 1

	# Защита от heap spraying (минимальный адрес mmap)
	vm.mmap_min_addr = 65536

	# Отключение SACK (уязвимости вроде CVE-2019-11477)
	net.ipv4.tcp_sack = 0

	# Отключение ECN (если не требуется)
	net.ipv4.tcp_ecn = 0

	# Игнорирование ARP-запросов на нелокальные интерфейсы
	net.ipv4.conf.all.arp_ignore = 1

