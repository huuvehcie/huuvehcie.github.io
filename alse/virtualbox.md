# Решение ошибки VirtualBox на Arch Linux: Kernel driver not installed

## Содержание
- [📋 Описание проблемы](#описание-проблемы)
- [🔍 Проверка установленных пакетов](#проверка-установленных-пакетов)
- [📦 Установка/переустановка пакетов](#установкапереустановка-пакетов)
- [⚙️ Пересборка модулей DKMS](#пересборка-модулей-dkms)
- [🔧 Альтернативная пересборка](#альтернативная-пересборка)
- [✅ Проверка статуса DKMS](#проверка-статуса-dkms)
- [🚀 Загрузка модулей ядра](#загрузка-модулей-ядра)
- [⚡ Запуск vboxconfig](#запуск-vboxconfig)
- [👥 Настройка прав пользователя](#настройка-прав-пользователя)
- [🔄 Альтернативное решение](#альтернативное-решение)
- [🔐 Решение проблем с Secure Boot](#решение-проблем-с-secure-boot)
- [📝 Финальные проверки](#финальные-проверки)
- [❌ Если проблема сохраняется](#если-проблема-сохраняется)

## 📋 Описание проблемы

Ошибка `Kernel driver not installed (rc=-1908)` возникает когда модули ядра VirtualBox не загружены или не установлены правильно.

<a id="проверка-установленных-пакетов"></a>
## 🔍 Проверка установленных пакетов

```bash
# Проверим текущие установленные пакеты VirtualBox
pacman -Q | grep virtualbox

# Проверим текущую версию ядра
uname -r
```

<a id="установкапереустановка-пакетов"></a>
## 📦 Установка/переустановка пакетов

```bash
# Обновляем систему
sudo pacman -Syu

# Устанавливаем или переустанавливаем VirtualBox и DKMS
sudo pacman -S --force virtualbox virtualbox-host-dkms

# Устанавливаем заголовки ядра
sudo pacman -S linux-headers
```

<a id="пересборка-модулей-dkms"></a>
## ⚙️ Пересборка модулей DKMS

```bash
# Получаем версию virtualbox-host-dkms
VBOX_VERSION=$(pacman -Q virtualbox-host-dkms | awk '{print $2}' | sed 's/-[^-]*$//')
KERNEL_VERSION=$(uname -r)

echo "Версия VirtualBox: $VBOX_VERSION"
echo "Версия ядра: $KERNEL_VERSION"

# Удаляем старые модули (если есть)
sudo dkms remove vboxhost --all

# Устанавливаем модули для текущего ядра
sudo dkms install vboxhost/$VBOX_VERSION -k $KERNEL_VERSION
```

<a id="альтернативная-пересборка"></a>
## 🔧 Альтернативная пересборка

Если предыдущий способ не сработал:

```bash
# Принудительная пересборка всех модулей DKMS
sudo dkms autoinstall -k $(uname -r)

# Или конкретно для VirtualBox
sudo dkms build vboxhost/$VBOX_VERSION -k $KERNEL_VERSION
sudo dkms install vboxhost/$VBOX_VERSION -k $KERNEL_VERSION
```

<a id="проверка-статуса-dkms"></a>
## ✅ Проверка статуса DKMS

```bash
# Проверяем статус установленных модулей
dkms status

# Проверяем наличие скомпилированных модулей
ls /lib/modules/$(uname -r)/extra/ | grep vbox
```

<a id="загрузка-модулей-ядра"></a>
## 🚀 Загрузка модулей ядра

```bash
# Загружаем модули вручную
sudo modprobe vboxdrv
sudo modprobe vboxnetadp
sudo modprobe vboxnetflt
sudo modprobe vboxpci

# Проверяем, что модули загружены
lsmod | grep vbox
```

<a id="запуск-vboxconfig"></a>
## ⚡ Запуск vboxconfig

```bash
# Выполняем настройку VirtualBox
sudo /sbin/vboxconfig
```

<a id="настройка-прав-пользователя"></a>
## 👥 Настройка прав пользователя

```bash
# Добавляем текущего пользователя в группу vboxusers
sudo usermod -aG vboxusers $USER

# Проверяем членство в группе
groups $USER
```

<a id="альтернативное-решение"></a>
## 🔄 Альтернативное решение

### Использование virtualbox-host-modules-arch

```bash
# Удаляем DKMS версию
sudo pacman -Rns virtualbox-host-dkms

# Устанавливаем модули, специфичные для Arch
sudo pacman -S virtualbox virtualbox-host-modules-arch

# Проверяем модули
ls /lib/modules/$(uname -r)/extramodules/ | grep vbox
```

<a id="решение-проблем-с-secure-boot"></a>
## 🔐 Решение проблем с Secure Boot

### Если у вас включен Secure Boot:

#### Вариант A: Отключить Secure Boot
1. Перезагрузите компьютер
2. Зайдите в BIOS/UEFI настройки
3. Найдите опцию Secure Boot и отключите её
4. Сохраните настройки и перезагрузитесь

#### Вариант B: Подписать модули (если Secure Boot должен остаться включенным)

```bash
# Установка необходимых инструментов
sudo pacman -S mokutil openssl

# Создание папки для ключей
sudo mkdir -p /var/lib/shim-signed/mok/

# Генерация ключей
sudo openssl req -new -x509 -newkey rsa:2048 \
  -keyout /var/lib/shim-signed/mok/MOK.priv \
  -outform DER -out /var/lib/shim-signed/mok/MOK.der \
  -nodes -days 36500 -subj "/CN=VirtualBox/"

# Регистрация ключа
sudo mokutil --import /var/lib/shim-signed/mok/MOK.der

# Создание скрипта для подписи модулей
sudo tee /etc/modprobe.d/vbox.conf << EOF
signer="/var/lib/shim-signed/mok/MOK.der"
key="/var/lib/shim-signed/mok/MOK.priv"
EOF
```

После этого:
1. Перезагрузите систему
2. Во время загрузки появится синий экран MOK Management
3. Выберите "Enroll MOK" → "Continue" → "Yes"
4. Введите пароль (если запрашивается)
5. Перезагрузитесь

<a id="финальные-проверки"></a>
## 📝 Финальные проверки

```bash
# Перезагружаем систему
sudo reboot

# После перезагрузки проверяем:
systemctl status vboxservice
lsmod | grep vbox
VBoxManage --version
```

<a id="если-проблема-сохраняется"></a>
## ❌ Если проблема сохраняется

1. **Проверьте журналы:**
```bash
sudo dmesg | grep vbox
journalctl -u vboxservice
```

2. **Попробуйте стабильное ядро:**
```bash
sudo pacman -S linux-lts linux-lts-headers
# Перезагрузитесь в LTS ядро и повторите установку
```

3. **Полная переустановка:**
```bash
sudo pacman -Rns virtualbox virtualbox-host-dkms
sudo rm -rf /etc/vbox /usr/lib/virtualbox
sudo pacman -S virtualbox virtualbox-host-modules-arch virtualbox-guest-iso
```

После выполнения этих шагов VirtualBox должен работать корректно.
