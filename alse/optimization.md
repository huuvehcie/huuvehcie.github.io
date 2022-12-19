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

Отредактировать файл /etc/mkinitcpio.conf

` MODULES=(crc32c libcrc32c zlib_deflate btrfs crc32c-intel intel_agp i915)

Далее выполнить команду:

` sudo mkinitcpio -P 

