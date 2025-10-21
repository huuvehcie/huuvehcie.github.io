# Настройка режима suspend-then-hibernate при закрытии крышки ноутбука
Полное описание: https://wiki.archlinux.org/title/Power_management_(%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9)/Suspend_and_hibernate_(%D0%A0%D1%83%D1%81%D1%81%D0%BA%D0%B8%D0%B9)



# Настройка suspend-then-hibernate в Arch Linux

## Конфигурация swap
```bash
# ZRAM для работы системы
sudo nano /etc/systemd/zram-generator.conf
```
```ini
[zram0]
zram-size = min(ram, 4096)
```

```bash
# Файл подкачки для гибернации (размер >= RAM)
sudo dd if=/dev/zero of=/swapfile bs=1G count=16 status=progress
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap defaults 0 0' | sudo tee -a /etc/fstab
```

## Параметры ядра
```bash
sudo nano /boot/loader/entries/ваш-файл.conf
```
Добавить в строку `options`:
```
resume=UUID=$(sudo findmnt -no UUID -T /swapfile) resume_offset=$(sudo filefrag -v /swapfile | grep "1:" | head -1 | awk '{print $4}' | sed 's/\.\.$//')
```

## Initramfs
```bash
sudo nano /etc/mkinitcpio.conf
```
Добавить `resume` в HOOKS:
```bash
HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block filesystems resume fsck)
sudo mkinitcpio -P
```

## Настройки питания
```bash
sudo nano /etc/systemd/logind.conf
```
```ini
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
```

```bash
sudo nano /etc/systemd/sleep.conf
```
```ini
HibernateDelaySec=900
```

## Завершение
```bash
sudo reboot
```

## Проверка
```bash
cat /proc/cmdline
swapon --show
systemctl hibernate
```
