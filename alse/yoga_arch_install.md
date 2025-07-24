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

	# --- Основное (маршрутизация, NAT, производительность) ---
	net.ipv4.ip_forward = 0                  # Отключено (клиентский режим)
	
	# --- Надежность TCP и защита ---
	net.ipv4.tcp_syncookies = 1             # Защита от SYN flood
	net.ipv4.tcp_rfc1337 = 1                # Защита от TIME_WAIT spoofing
	net.ipv4.tcp_fin_timeout = 15           # Увеличено до 15 сек (было 10)
	
	# --- Быстрое открытие TCP-соединений ---
	net.ipv4.tcp_fastopen = 3               # Клиент и сервер
	
	# --- Безопасность и фильтрация ---
	# Антиспуфинг
	net.ipv4.conf.all.rp_filter = 2         # Strict mode
	net.ipv4.conf.default.rp_filter = 2
	net.ipv4.conf.all.arp_ignore = 1        # Игнорировать ARP на нелокальные интерфейсы
	net.ipv4.conf.all.arp_announce = 2      # Не отвечать на ARP с чужим адресом
	net.ipv4.conf.all.arp_filter = 1        # Фильтрация ARP-пакетов
	
	# ICMP-ограничения
	net.ipv4.conf.all.accept_redirects = 0  # Отключить ICMP redirect
	net.ipv4.conf.default.accept_redirects = 0
	net.ipv4.conf.all.send_redirects = 0    # Не отправлять ICMP redirect
	net.ipv4.conf.default.send_redirects = 0
	net.ipv4.conf.all.accept_source_route = 0  # Отключить source routing
	net.ipv4.conf.default.accept_source_route = 0
	net.ipv4.icmp_echo_ignore_broadcasts = 1  # Игнорировать broadcast ping
	net.ipv4.icmp_ignore_bogus_error_responses = 1  # Игнорировать поддельные ICMP-ошибки
	net.ipv4.icmp_echoreply_rate = 100      # Ограничение ответов на ping
	
	# --- Оптимизация TCP ---
	net.ipv4.tcp_abort_on_overflow = 1      # Быстрое закрытие переполненных соединений
	net.ipv4.tcp_mtu_probing = 1            # Автоопределение MTU
	net.ipv4.tcp_timestamps = 1             # Включить timestamps
	net.ipv4.tcp_max_syn_backlog = 4096     # Увеличен лимит SYN
	net.ipv4.tcp_max_orphans = 65536        # Макс. непривязанных сокетов
	net.ipv4.tcp_max_tw_buckets = 65536     # Макс. сокетов в TIME_WAIT
	net.ipv4.tcp_synack_retries = 3         # Повторы SYN-ACK
	net.ipv4.tcp_syn_retries = 3            # Повторы SYN
	
	# --- Современный congestion control ---
	net.core.default_qdisc = fq             # Очередь пакетов
	net.ipv4.tcp_congestion_control = bbr   # Алгоритм BBR
	
	# --- Дополнительные параметры безопасности ---
	# Защита ядра
	kernel.dmesg_restrict = 1               # Только root видит dmesg
	kernel.kptr_restrict = 1                # Скрытие указателей ядра
	kernel.randomize_va_space = 2           # ASLR включен
	kernel.exec-shield = 1                  # Защита от переполнения стека
	kernel.pid_max = 65536                  # Макс. PID
	kernel.sysrq = 0                        # Отключить magic key
	kernel.core_uses_pid = 1                # PID в имени core-файла
	
	# Защита от DoS
	vm.mmap_min_addr = 65536                # Минимальный адрес mmap
	net.ipv4.tcp_low_latency = 1            # Для сетей с низкой задержкой (опционально)
	
	# --- Настройки фрагментации ---
	net.ipv4.ipfrag_time = 30               # Время жизни фрагментов (сек)
	net.ipv4.ipfrag_high_thresh = 262144    # Макс. память для фрагментов (KB)
	net.ipv4.ipfrag_low_thresh = 196608     # Мин. память для фрагментов (KB)
	
	# --- Дополнительные параметры производительности ---
	# Буферы и порты
	net.core.rmem_max = 16777216            # Макс. приемный буфер
	net.core.wmem_max = 16777216            # Макс. буфер отправки
	net.core.rmem_default = 262144          # Буфер приема по умолчанию
	net.core.wmem_default = 262144          # Буфер отправки по умолчанию
	net.core.optmem_max = 4194304           # Макс. буфер опций сокета
	net.ipv4.ip_local_port_range = 1024 65535  # Диапазон локальных портов
	net.core.netdev_max_backlog = 300000    # Очередь пакетов на интерфейсе
	net.core.somaxconn = 4096               # Макс. ожидающих подключений
	
	# --- Опциональные настройки ---
	# net.ipv4.tcp_window_scaling = 1        # Увеличение окна TCP (для больших задержек)
	# net.ipv4.tcp_congestion_control = cubic  # Альтернатива BBR
