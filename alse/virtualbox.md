# Установка VirtualBox

sudo pacman -S virtualbox virtualbox-host-modules-arch virtualbox-guest-iso
paru -S virtualbox-unattended-templates
sudo usermod -a shaman -G vboxusers

И добавить параметр ядра ibt=off в конфиг grub для работы на процессорах 11 поколения и выше
