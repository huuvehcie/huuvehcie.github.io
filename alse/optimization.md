# Обновление ключей

```
sudo pacman-key --init               # Инициализация
sudo pacman-key --populate archlinux # Получить ключи из репозитория
sudo pacman-key --refresh-keys       # Проверить текущие ключи на актуальность
sudo pacman -Sy                      # Обновить ключи для всей системы
```

# Установка актуальных драйверов для видеокарты

## NVIDIA

```
sudo pacman -S nvidia-dkms nvidia-utils nvidia-settings vulkan-icd-loader opencl-nvidia libxnvctrl
sudo mkinitcpio -P # Обновляем образы initramfs
```

## Nouveau (Только для старых видеокарт)

```
sudo pacman -S xf86-video-nouveau vulkan-icd-loader mesa-vdpau
```

## AMD

```
sudo pacman -S vulkan-radeon vulkan-icd-loader mesa-vdpau vulkan-mesa-layers
```

## Intel

```
sudo pacman -S vulkan-intel vulkan-icd-loader
```

# Добавление важных модулей в образы initramfs

Отредактировать файл /etc/mkinitcpio.con:

```
MODULES=(crc32c libcrc32c zlib_deflate btrfs crc32c-intel intel_agp i915)
```

Далее выполнить команду:

```
sudo mkinitcpio -P
```

# Установка микрокода

```
sudo pacman -S intel-ucode                  # Установить микрокод Intel
sudo mkinitcpio -P                          # Пересобираем образы initramfs.
sudo grub-mkconfig -o /boot/grub/grub.cfg   # Обновляем загрузчик, можно так же через grub-customizer.
```

# Настройка makepkg.conf

Отредактировать файл /etc/makepkg.conf:

```
CFLAGS="-march=native -mtune=native -O2 -pipe -fno-plt -fexceptions \
      -Wp,-D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security \
      -fstack-clash-protection -fcf-protection"
CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"
RUSTFLAGS="-C opt-level=3"
MAKEFLAGS="-j$(nproc) -l$(nproc)"
OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)
```

# Включение ccache

```
sudo pacman -S ccache
```

Отредактировать /etc/makepkg.conf:

```
# Найдите данную строку в собственных настройках, затем уберите восклицательный знак перед *"ccache"*
BUILDENV=(!distcc color ccache check !sign)
```

# Установка полезных служб и демонов

## Включение Nohang

Демон повышающий производительность путём обработки и слежки за потреблением памяти

```
git clone https://aur.archlinux.org/nohang-git.git # Скачивание исходников.
cd nohang-git                                      # Переход в nohang-git
makepkg -sric                                      # Сборка и установка.
sudo systemctl enable --now nohang-desktop         # Включаем службу.
```

## Включение TRIM

```
sudo systemctl enable fstrim.timer    # Включаем службу.
sudo fstrim -v /                      # Ручной метод.
sudo fstrim -va /                     # Если первый метод не тримит весь диск.
```

## Включение cronie

Демон, который поможет вам очищать вашу систему от мусора полностью автономно

```
sudo pacman -S cronie                         # Установить cron.
sudo systemctl enable --now cronie.service    # Запускает и включает службу.
sudo EDITOR=nano crontab -e                   # Редактируем параметр.
```

И прописываем:

```
15 10 * * sun /sbin/pacman -Scc --noconfirm
```

