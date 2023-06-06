#!/bin/bash

# Скрипт для автоматического развертывания Arch Linux
# На Lenovo Yoga
# [C] 1983-2023 Kaverin S. Aleksandr


loadkeys ru
setfont UniCyrExt_8x16

echo 'Синхронизация системных часов'
timedatectl set-ntp true

echo 'Создание разделов'
(
 echo g;

 echo n;
 echo ;
 echo;
 echo +304M;
 echo y;
 echo t;
 echo 1;

 echo n;
 echo;
 echo;
 echo +32G;
 echo y;
 
  
 echo n;
 echo;
 echo;
 echo;
 echo y;
  
 echo w;
) | fdisk /dev/sda

echo 'Ваша разметка диска'
fdisk -l

echo 'Форматирование дисков'

mkfs.fat -F32 /dev/sda1
mkfs.ext4  /dev/sda2
mkfs.ext4  /dev/sda3

echo 'Монтирование дисков'
mount /dev/sda2 /mnt
mkdir /mnt/home
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
mount /dev/sda3 /mnt/home

echo 'Выбор зеркал для загрузки и настройка pacman'
rm -rf /etc/pacman.d/mirrorlist
reflector --verbose -c RU,SW,FI,PL,ES,UK,US,JP -l 40 -p https --sort rate --save /etc/pacman.d/mirrorlist
echo "ParallelDownloads = 16" >> /etc/pacman.conf
echo "Color" >> /etc/pacman.conf


echo 'Установка основных пакетов'
pacstrap /mnt base base-devel linux linux-firmware micro dhcpcd netctl

echo 'Настройка системы'
genfstab -pL /mnt >> /mnt/etc/fstab

arch-chroot /mnt sh -c "$(curl -fsSL git.io/archuefi2.sh)"

read -p "Введите имя компьютера: " hostname
read -p "Введите имя пользователя: " username

echo 'Прописываем имя компьютера'
echo $hostname > /etc/hostname
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

echo 'Добавляем русскую локаль системы'
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 

echo 'Обновим текущую локаль системы'
locale-gen

echo 'Указываем язык системы'
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf

echo 'Вписываем vConsole.conf'
echo 'LOCALE=ru_RU.UTF-8' > /etc/vconsole.conf
echo 'KEYMAP=ru' >> /etc/vconsole.conf
echo 'FONT="UniCyrExt_8x16"' >> /etc/vconsole.conf
echo 'CONSOLEMAP=""' >> /etc/vconsole.conf
echo 'USECOLOR="yes"' >> /etc/vconsole.conf
echo 'CONSOLEFONT="UniCyrExt_8x16"' >> /etc/vconsole.conf

echo 'Создадим загрузочный RAM диск'
mkinitcpio -p linux

echo 'Установка Chaotic-AUR'
pacman-key --recv-key FBA220DFC880C036 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key FBA220DFC880C036
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

echo 'Устанавливаем загрузчик'
pacman -Syy
pacman -S grub efibootmgr --noconfirm 
grub-install /dev/sda

echo 'Обновляем grub.cfg'
grub-mkconfig -o /boot/grub/grub.cfg

echo 'Ставим программу для Wi-fi'
pacman -S dialog wpa_supplicant --noconfirm 

echo 'Добавляем пользователя'
useradd -m -g users -G wheel -s /bin/bash $username

echo 'Создаем root пароль'
passwd

echo 'Устанавливаем пароль пользователя'
passwd $username

echo 'Устанавливаем SUDO'
echo '%wheel ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

echo 'Раскомментируем репозиторий multilib Для работы 32-битных приложений в 64-битной системе.'
echo '[multilib]' >> /etc/pacman.conf
echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf
pacman -Syy

echo 'Ставим ssh сервер'
pacman -S openssh  --noconfirm
systemctl enable sshd
systemctl start sshd

echo "Куда устанавливем Arch Linux на виртуальную машину?"
read -p "1 - Да, 0 - Нет: " vm_setting
if [[ $vm_setting == 0 ]]; then
  gui_install="xorg-server xorg-drivers xorg-xinit"
elif [[ $vm_setting == 1 ]]; then
  gui_install="xorg-server xorg-drivers xorg-xinit virtualbox-guest-utils"
fi

echo 'Ставим иксы и драйвера'
pacman -S $gui_install

echo 'Ставим клиента git'
pacman -S git --noconfirm

echo 'Ставим шрифты'
pacman -S ttf-liberation ttf-dejavu --noconfirm 

echo 'Ставим сеть'
pacman -S networkmanager network-manager-applet --noconfirm

echo 'Подключаем автозагрузку менеджера входа и интернет'
systemctl enable NetworkManager

echo 'Установка завершена! Перезагрузите систему.'
pause

exit
reboot

mkdir ~/downloads
cd ~/downloads

echo 'Установка AUR (paru)'
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si

echo 'Создаем нужные директории'
sudo pacman -S xdg-user-dirs --noconfirm
xdg-user-dirs-update

echo 'Устанавливает конфиг startx'
cd ~
wget https://github.com/ordanax/arch/blob/master/attach/.xinitrc

# Подключаем zRam
paru -S zramswap --noconfirm
sudo systemctl enable zramswap.service

# Установка GNOME
paru -S gnome

# Установка nautilus и дополнительных компонент
paru -S gvfs-afc gvfs-goa gvfs-google gvfs-mtp gvfs-nfs gvfs-smb gvfs-gphoto2 nautilus nautilus-code nautilus-bluetooth nautilus-compare nautilus-empty-file nautilus-gnome-disks nautilus-hide nautilus-image-converter nautilus-launch nautilus-sendto nautilus-share

# Отключение служб Evolution для синхронизации онлайн аккаунтов.
systemctl --user mask evolution-addressbook-factory evolution-calendar-factory evolution-source-registry

# Отключение Tracker 3 в GNOME
systemctl --user mask tracker-miner-apps tracker-miner-fs tracker-store

# Отключение служб интеграции GNOME с графическим планшетом Wacom. Если у вас такого нет - смело отключайте.
systemctl --user mask org.gnome.SettingsDaemon.Wacom.service

# Отключение службы уведомления о печати. Если нет принтера или вам просто не нужны эти постоянные уведомления - отключаем.
systemctl --user mask org.gnome.SettingsDaemon.PrintNotifications.service

# Отключение службы управления цветовыми профилями GNOME. Отключив её не будет работать тёплый режим экрана (Системный аналог Redshift).
systemctl --user mask org.gnome.SettingsDaemon.Color.service

# Отключение службы управления специальными возможностями системы. Не отключать людям с ограниченными возможностями!
systemctl --user mask org.gnome.SettingsDaemon.A11ySettings.service

# Отключение службы защиты от неавторизованных USB устройств при блокировке экрана. Можете оставить если у вас ноутбук.
systemctl --user mask org.gnome.SettingsDaemon.UsbProtection.service

# Отключаем службу настройки автоматической блокировки экрана. Можете оставить если у вас ноутбук.
systemctl --user mask org.gnome.SettingsDaemon.ScreensaverProxy.service

# Отключение службы настройки общего доступа к файлам и директориям.
systemctl --user mask org.gnome.SettingsDaemon.Sharing.service

# Отключение службы управления подсистемой rfkill, отвечающей за отключения любого радиопередатчика в системе (сюда же относятся Wi-Fi и Bluetooth, поэтому данная служба нужна, скорее всего, для так называемого режима в "самолете").
systemctl --user mask org.gnome.SettingsDaemon.Rfkill.service

# Отключение службы управления клавиатурой и раскладками GNOME. Можно смело отключать если уже настроили все раскладки и настройки клавиатуры заранее, ибо все предыдущие настройки сохраняются при отключении.
systemctl --user mask org.gnome.SettingsDaemon.Keyboard.service

# Отключаем службу управления звуком GNOME. Отключает ТОЛЬКО настройки звука GNOME, а не вообще всё управлением звуком в системе.
systemctl --user mask org.gnome.SettingsDaemon.Sound.service

# Отключение службы интеграции GNOME с карт-ридером.
systemctl --user mask org.gnome.SettingsDaemon.Smartcard.service

# Отключение службы слежения за свободным пространством на диске. Штука полезная, но если вы предпочитаете следить за этим самостоятельно, то вперед
systemctl --user mask org.gnome.SettingsDaemon.Housekeeping.service

echo 'Установка модифицированных пакетов Gnome'
paru -S gnome-shell-performance mutter-performance gnome-control-center

echo 'Установка дополнений Gnome'
paru -S gnome-shell-extension-ubuntu-dock gnome-shell-extension-power-profile-switcher-git

echo 'Установка портированной темы libadwaita для GTK 3'
paru -S adw-gtk3
gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3

echo 'Исправление размытия шрифтов в GTK 4'
echo '[Settings]' >> ~/.config/gtk-4.0/settings.ini
echo 'gtk-hint-font-metrics=1' >> ~/.config/gtk-4.0/settings.ini

echo 'Установка завершена!'
