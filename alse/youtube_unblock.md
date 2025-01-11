# Инструкция по настройке https://github.com/Waujito/youtubeUnblock на ArchLinux
## Шаг 1: Установка необходимых пакетов
Обновите систему:
```
sudo pacman -Syu
```
Установите необходимые пакеты:
```
sudo pacman -S gcc make autoconf automake pkg-config libtool linux-headers
```
## Шаг 2: Скачивание и компиляция youtubeUnblock
Скачайте исходный код youtubeUnblock:
```
git clone https://github.com/Waujito/youtubeUnblock.git
cd youtubeUnblock
```
Скомпилируйте и установите youtubeUnblock:
```
make
sudo make install
```
## Шаг 3: Настройка Firewall (nftables)
Добавьте правила nftables:
```
sudo nft add table inet fw4 ; \
sudo nft add chain inet fw4 youtubeUnblock '{ type filter hook postrouting priority mangle - 1; policy accept; }' ; \
sudo nft add rule inet fw4 youtubeUnblock 'tcp dport 443 ct original packets < 20 counter queue num 537 bypass' ; \
sudo nft add chain inet fw4 output '{ type filter hook output priority 0; }' ; \
sudo nft insert rule inet fw4 output 'mark and 0x8000 \== 0x8000 counter accept'
```
## Шаг 4: Настройка системного сервиса
Создайте файл сервиса:
```
sudo cp youtubeUnblock.service /usr/lib/systemd/system/
```
Отредактируйте файл сервиса, чтобы указать путь к бинарному файлу youtubeUnblock:
```
sudo nano /usr/lib/systemd/system/youtubeUnblock.service
```
Убедитесь, что путь к бинарному файлу указан правильно, например:
```
ExecStart=/usr/bin/youtubeUnblock
```
Запустите и включите сервис:
```
sudo systemctl daemon-reload
sudo systemctl start youtubeUnblock
sudo systemctl enable youtubeUnblock
```
## Шаг 5: Проверка работы
Проверьте, работает ли youtubeUnblock:
```
curl -o /dev/null -k --connect-to ::google.com -k -L -H Host: mirror.gcr.io https://test.googlevideo.com/v2/cimg/and
```
Скорость должна быть высокой, если youtubeUnblock работает правильно.
## Шаг 6: Настройка дополнительных параметров (если необходимо)
Отредактируйте файл сервиса для добавления дополнительных флагов:
```
sudo micro /usr/lib/systemd/system/youtubeUnblock.service
```
Добавьте необходимые флаги в строку ExecStart, например:
```
ExecStart=/usr/bin/youtubeUnblock --queue-num=537 --threads=1
```
Перезапустите сервис для применения изменений:
```
sudo systemctl restart youtubeUnblock
```
## Шаг 7: Устранение неполадок
Если возникают ошибки, проверьте логи:
```
sudo journalctl -u youtubeUnblock
```
При необходимости отредактируйте правила firewall и параметры запуска сервиса.
