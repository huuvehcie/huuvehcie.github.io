```
#!/bin/bash
# transition-to-pulseaudio.sh
# Полный переход с PipeWire на PulseAudio для Arch Linux + GNOME
# Решает проблему крашей GNOME при переключении аудиоустройств

set -e

echo "=============================================="
echo "  Переход с PipeWire на PulseAudio"
echo "  Решение проблем с крашами GNOME при переключении аудио"
echo "=============================================="

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Не запускайте скрипт с sudo!"
        print_error "Запустите как обычный пользователь: ./transition-to-pulseaudio.sh"
        exit 1
    fi
}

# ============================================================================
# 1. ПРЕДВАРИТЕЛЬНЫЕ ПРОВЕРКИ
# ============================================================================

check_sudo

print_status "1. Проверка системы..."
echo "Дистрибутив: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Пользователь: $(whoami)"
echo "Дата: $(date)"

# Проверка, что мы в Arch Linux
if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
    print_warning "Внимание: Скрипт разработан для Arch Linux!"
    read -p "Продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# ============================================================================
# 2. ОСТАНОВКА И УДАЛЕНИЕ PIPEWIRE/WIREPLUMBER
# ============================================================================

print_status "2. Остановка PipeWire и WirePlumber..."

# Останавливаем сервисы
if systemctl --user is-active pipewire >/dev/null 2>&1; then
    print_status "Останавливаем pipewire..."
    systemctl --user stop pipewire pipewire-pulse wireplumber 2>/dev/null || true
fi

# Отключаем автозагрузку
print_status "Отключаем автозагрузку PipeWire..."
systemctl --user disable pipewire pipewire-pulse wireplumber pipewire.socket pipewire-pulse.socket 2>/dev/null || true

# Убиваем оставшиеся процессы
print_status "Завершаем оставшиеся процессы..."
pkill -9 pipewire wireplumber 2>/dev/null || true
sleep 2

# ============================================================================
# 3. УСТАНОВКА PULSEAUDIO И ЗАВИСИМОСТЕЙ
# ============================================================================

print_status "3. Установка PulseAudio и зависимостей..."

# Обновление системы (опционально)
read -p "Обновить систему перед установкой? (рекомендуется) (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Обновление системы..."
    sudo pacman -Syu --noconfirm
fi

# Установка необходимых пакетов
print_status "Установка пакетов..."
sudo pacman -S --needed --noconfirm \
    pulseaudio \
    pulseaudio-alsa \
    pulseaudio-bluetooth \
    pulseaudio-equalizer \
    alsa-utils \
    alsa-firmware \
    sof-firmware \
    alsa-ucm-conf \
    pavucontrol \
    paprefs \
    pulseaudio-zeroconf

print_success "Пакеты установлены"

# ============================================================================
# 4. НАСТРОЙКА ПРАВ ДОСТУПА И ГРУПП
# ============================================================================

print_status "4. Настройка прав доступа..."

# Добавление пользователя в группу audio
if ! groups $(whoami) | grep -q audio; then
    print_status "Добавляем пользователя $(whoami) в группу audio..."
    sudo usermod -aG audio $(whoami)
    print_warning "Требуется перезагрузка или перелогин для применения изменений группы!"
else
    print_success "Пользователь уже в группе audio"
fi

# Исправление прав на аудиоустройства
print_status "Исправление прав на /dev/snd/..."
sudo chmod 666 /dev/snd/* 2>/dev/null || true
sudo chown root:audio /dev/snd/* 2>/dev/null || true

# ============================================================================
# 5. КОНФИГУРАЦИЯ ALSA
# ============================================================================

print_status "5. Настройка ALSA..."

# Удаляем конфликтующие конфиги PipeWire
print_status "Удаление конфигов PipeWire..."
sudo rm -f /etc/alsa/conf.d/50-pipewire.conf /etc/alsa/conf.d/50-pipewire-pulse.conf 2>/dev/null || true
sudo rm -f /etc/alsa/conf.d/99-pulseaudio-default.conf 2>/dev/null || true

# Создаем минимальную конфигурацию ALSA
print_status "Создание конфигурации ALSA..."
sudo mkdir -p /etc/alsa/conf.d

sudo tee /etc/asound.conf > /dev/null << 'EOF'
# Минимальная конфигурация ALSA для PulseAudio
defaults.pcm.card 0
defaults.ctl.card 0

pcm.!default {
    type pulse
    fallback "sysdefault"
}

ctl.!default {
    type pulse
    fallback "sysdefault"
}
EOF

# Перезагрузка ALSA
print_status "Перезагрузка ALSA..."
sudo alsa force-reload 2>/dev/null || true
sleep 3

# ============================================================================
# 6. КОНФИГУРАЦИЯ PULSEAUDIO
# ============================================================================

print_status "6. Настройка PulseAudio..."

# Удаляем старую конфигурацию PulseAudio
print_status "Очистка старой конфигурации PulseAudio..."
rm -rf ~/.config/pulse ~/.pulse* ~/.pulse-cookie 2>/dev/null || true

# Включаем и запускаем PulseAudio
print_status "Включение сервисов PulseAudio..."
systemctl --user enable --now pulseaudio pulseaudio.socket

# Даем время на запуск
sleep 5

# Проверяем запуск
if ! systemctl --user is-active pulseaudio >/dev/null; then
    print_error "PulseAudio не запустился автоматически, пытаемся запустить вручную..."
    pulseaudio --start
    sleep 3
fi

# ============================================================================
# 7. НАСТРОЙКА АУДИОУСТРОЙСТВ
# ============================================================================

print_status "7. Настройка аудиоустройств..."

# Включаем звук через ALSA
if command -v amixer &> /dev/null; then
    print_status "Включение микшера ALSA..."
    amixer -c 0 sset 'Master' unmute 2>/dev/null || true
    amixer -c 0 sset 'Master' 70% 2>/dev/null || true
    amixer -c 0 sset 'PCM' unmute 2>/dev/null || true
    amixer -c 0 sset 'PCM' 80% 2>/dev/null || true
    sudo alsactl store 2>/dev/null || true
fi

# Настраиваем PulseAudio устройства
print_status "Настройка устройств PulseAudio..."
sleep 5  # Даем PulseAudio время на обнаружение устройств

if pactl info &>/dev/null; then
    # Получаем список устройств
    sinks=$(pactl list short sinks 2>/dev/null | head -1)
    if [[ -n "$sinks" ]]; then
        sink_name=$(echo "$sinks" | awk '{print $2}')
        print_status "Устанавливаем устройство по умолчанию: $sink_name"
        pactl set-default-sink "$sink_name"
        pactl set-sink-volume "$sink_name" 70%
        pactl set-sink-mute "$sink_name" 0
    fi
    
    sources=$(pactl list short sources 2>/dev/null | grep -v "monitor" | head -1)
    if [[ -n "$sources" ]]; then
        source_name=$(echo "$sources" | awk '{print $2}')
        print_status "Устанавливаем источник по умолчанию: $source_name"
        pactl set-default-source "$source_name"
        pactl set-source-volume "$source_name" 100%
        pactl set-source-mute "$source_name" 0
    fi
fi

# ============================================================================
# 8. НАСТРОЙКА GNOME ДЛЯ РАБОТЫ С PULSEAUDIO
# ============================================================================

print_status "8. Настройка GNOME..."

# Отключаем звуковые эффекты (опционально, но может помочь)
if command -v gsettings &> /dev/null; then
    print_status "Настройка звуковых параметров GNOME..."
    gsettings set org.gnome.desktop.sound event-sounds true
    gsettings set org.gnome.desktop.sound input-feedback-sounds false
    gsettings set org.gnome.desktop.sound allow-volume-above-100-percent false
fi

# Создаем конфиг для автоматической настройки при входе
print_status "Создание конфига PulseAudio для автоматической настройки..."
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/pulseaudio-setup.desktop << EOF
[Desktop Entry]
Type=Application
Name=PulseAudio Setup
Exec=bash -c 'sleep 5 && pactl set-sink-volume @DEFAULT_SINK@ 70% && pactl set-sink-mute @DEFAULT_SINK@ 0'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Comment=Настройка PulseAudio при входе
EOF

# ============================================================================
# 9. ПРОВЕРКА И ТЕСТИРОВАНИЕ
# ============================================================================

print_status "9. Проверка работоспособности..."

echo ""
print_status "=== ИТОГОВАЯ ПРОВЕРКА ==="

# Проверка PulseAudio
if systemctl --user is-active pulseaudio >/dev/null; then
    print_success "PulseAudio запущен"
else
    print_error "PulseAudio не запущен"
fi

# Проверка устройств
echo ""
print_status "Список аудиоустройств:"
if pactl info &>/dev/null; then
    echo "Сервер PulseAudio: $(pactl info | grep 'Server Name' | cut -d: -f2)"
    echo ""
    
    print_status "Устройства воспроизведения (sinks):"
    pactl list short sinks 2>/dev/null || print_error "Не удалось получить устройства"
    
    echo ""
    print_status "Источники (sources):"
    pactl list short sources 2>/dev/null | grep -v "monitor" || print_error "Не удалось получить источники"
    
    echo ""
    print_status "Устройства по умолчанию:"
    echo "Воспроизведение: $(pactl get-default-sink 2>/dev/null || echo 'Не установлено')"
    echo "Запись: $(pactl get-default-source 2>/dev/null || echo 'Не установлено')"
else
    print_error "PulseAudio не отвечает"
fi

# Тест звука
echo ""
print_status "Тест звука..."
if command -v paplay &> /dev/null; then
    if timeout 5 paplay /usr/share/sounds/freedesktop/stereo/phone-incoming-call.oga 2>/dev/null; then
        print_success "✅ Звук работает!"
    else
        print_warning "⚠️ Проблемы со звуком (возможно, тихий или muted)"
    fi
else
    print_warning "paplay не найден, тест звука пропущен"
fi

# Тест микрофона
echo ""
print_status "Проверка микрофона..."
if pactl list sources | grep -q "Mute: no" 2>/dev/null; then
    print_success "Микрофон не заглушен"
else
    print_warning "Микрофон может быть заглушен"
fi

# ============================================================================
# 10. ФИНАЛЬНЫЕ ШАГИ И РЕКОМЕНДАЦИИ
# ============================================================================

echo ""
echo "=============================================="
print_success "ПЕРЕХОД ЗАВЕРШЕН!"
echo "=============================================="
echo ""
echo "📋 РЕКОМЕНДАЦИИ:"
echo ""
echo "1. ${YELLOW}ПЕРЕЗАГРУЗИТЕ СИСТЕМУ${NC} для применения всех изменений"
echo "   или хотя бы перезапустите GNOME (Alt+F2 → r)"
echo ""
echo "2. После перезагрузки проверьте:"
echo "   - pavucontrol - графический микшер"
echo "   - alsamixer - консольный микшер (для тонкой настройки)"
echo ""
echo "3. Основные команды управления:"
echo "   ${BLUE}pactl set-sink-volume @DEFAULT_SINK@ +5%${NC}"
echo "   ${BLUE}pactl set-sink-volume @DEFAULT_SINK@ -5%${NC}"
echo "   ${BLUE}pactl set-sink-mute @DEFAULT_SINK@ toggle${NC}"
echo "   ${BLUE}pactl list sinks${NC} - список устройств"
echo ""
echo "4. Если нужно вернуться к PipeWire:"
echo "   systemctl --user disable --now pulseaudio pulseaudio.socket"
echo "   systemctl --user enable --now pipewire pipewire-pulse wireplumber"
echo "   sudo pacman -S pipewire-pulse"
echo ""
echo "5. Проблемы? Проверьте:"
echo "   ${BLUE}journalctl --user -u pulseaudio --no-pager -n 30${NC}"
echo "   ${BLUE}dmesg | grep -i audio${NC}"
echo "   ${BLUE}groups${NC} (должна быть группа audio)"
echo ""
echo "📞 Ваш скрипт записи звука теперь должен работать без крашей!"
echo ""

# Создаем скрипт для быстрой проверки
cat > ~/check-audio.sh << 'EOF'
#!/bin/bash
echo "=== Быстрая проверка аудио ==="
echo "PulseAudio: $(systemctl --user is-active pulseaudio 2>/dev/null && echo 'активен' || echo 'не активен')"
echo "Устройства:"
pactl list short sinks 2>/dev/null | while read line; do echo "  $line"; done
echo "По умолчанию: $(pactl get-default-sink 2>/dev/null || echo 'не установлено')"
echo "Группы пользователя: $(groups)"
EOF

chmod +x ~/check-audio.sh
print_success "Создан скрипт для проверки: ~/check-audio.sh"

echo ""
echo "✨ ${GREEN}Переход завершен успешно!${NC} ✨"
```
