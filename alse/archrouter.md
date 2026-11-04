# Arch Linux Wi-Fi Router

Превращаем Arch Linux в точку доступа Wi-Fi с NAT, скрытым SSID и фильтрацией по MAC. Ethernet получает адрес по DHCP, Wi-Fi-клиенты выходят в интернет через Ethernet. Опционально: выборочный обход DPI через zapret2 только для указанных доменов.

Проверено на: Arch Linux, ядро `7.x`, `hostapd`, `dnsmasq`, `iptables-nft`, `systemd-networkd`, `zapret2`.

---

## Возможности

- Ethernet (`enp0s25`) — DHCP-клиент.
- Wi-Fi (`wlan0`) — точка доступа WPA2, скрытый SSID.
- DHCP-сервер для клиентов: `10.44.5.10–10.44.5.254`.
- NAT (MASQUERADE) через Ethernet.
- Фильтрация клиентов по MAC (whitelist на двух уровнях: hostapd + dnsmasq).
- Выборочный обход DPI через zapret2 (`MODE_FILTER=hostlist`) — только для доменов из списка.
- Готовность к добавлению VPN (policy-based routing).

---

## 0. Требования

- Wi-Fi-карта с поддержкой режима AP:

```bash
iw list | grep -A 10 "Supported interface modes"
```

В выводе должен быть пункт `AP`. Если его нет — дальнейшее не сработает.

- Имена интерфейсов в примерах: `enp0s25` (Ethernet), `wlan0` (Wi-Fi). Замените на свои (`ip -br link`).

---

## 1. Освободите Wi-Fi интерфейс

`hostapd` не запустится, если `wlan0` занят `iwd`, `NetworkManager` или `wpa_supplicant`.

Проверьте, кто держит интерфейс:

```bash
systemctl status NetworkManager wpa_supplicant iwd 2>/dev/null | grep -E "Loaded|Active"
```

### Если `iwd`

```bash
systemctl disable --now iwd
```

### Если `NetworkManager`

```bash
nmcli device set wlan0 managed no
cat >/etc/NetworkManager/conf.d/99-unmanage-wlan0.conf <<'EOF'
[keyfile]
unmanaged-devices=interface-name:wlan0
EOF
systemctl restart NetworkManager
```

### Если `wpa_supplicant@wlan0`

```bash
systemctl disable --now wpa_supplicant@wlan0
```

Затем сбросьте интерфейс:

```bash
ip link set wlan0 down
ip addr flush dev wlan0
ip link set wlan0 up
```

---

## 2. Установка пакетов

```bash
pacman -S --needed hostapd dnsmasq iptables-nft
```

---

## 3. Ethernet — DHCP

### systemd-networkd

```bash
cat >/etc/systemd/network/20-wired.network <<'EOF'
[Match]
Name=enp0s25

[Network]
DHCP=yes
EOF

systemctl enable --now systemd-networkd systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
```

Проверка (при подключённом кабеле):

```bash
networkctl status enp0s25
```

---

## 4. Статический IP на Wi-Fi

Шлюз для клиентов — `10.44.5.1/24`.

Разово:

```bash
ip addr replace 10.44.5.1/24 dev wlan0
```

Автозапуск при загрузке:

```bash
cat >/etc/systemd/system/wlan0-ap-addr.service <<'EOF'
[Unit]
Description=Static IP for wlan0 (AP)
Before=hostapd.service
After=sys-subsystem-net-devices-wlan0.device

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/sbin/ip addr replace 10.44.5.1/24 dev wlan0
ExecStart=/sbin/ip link set wlan0 up

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now wlan0-ap-addr.service
```

---

## 5. hostapd — точка доступа

```bash
cat >/etc/hostapd/hostapd.conf <<'EOF'
interface=wlan0
driver=nl80211
ssid=FuckRKN
hw_mode=g
channel=6
wmm_enabled=1
macaddr_acl=1
accept_mac_file=/etc/hostapd/hostapd.accept
auth_algs=1
ignore_broadcast_ssid=1
wpa=2
wpa_passphrase=AfrbyuHjcRjvYflpjh@)26
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

sed -i 's|^#\?DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
```

- `ignore_broadcast_ssid=1` — скрытый SSID.
- `macaddr_acl=1` + `accept_mac_file` — whitelist MAC (см. раздел 9).

Если `hostapd` не стартует из-за занятого канала — попробуйте `channel=1` или `channel=11`. Если карта двухдиапазонная, можно `hw_mode=a` + `channel=36`.

---

## 6. dnsmasq — DHCP + DNS

**Важно:** каталог `/etc/dnsmasq.d/` в свежей установке отсутствует — создайте его.

```bash
mkdir -p /etc/dnsmasq.d
cat >/etc/dnsmasq.d/wlan0.conf <<'EOF'
interface=wlan0
bind-interfaces
dhcp-range=10.44.5.10,10.44.5.254,255.255.255.0,24h
EOF
```

Проверьте, что `dnsmasq` читает каталог:

```bash
grep -n 'conf-dir' /etc/dnsmasq.conf
```

Если строки нет — добавьте:

```bash
echo 'conf-dir=/etc/dnsmasq.d/,*.conf' >> /etc/dnsmasq.conf
```

### Конфликт с systemd-resolved (порт 53 занят)

Симптом в логах:

```
dnsmasq: failed to create listening socket for port 53: Address already in use
```

Проверка, кто держит порт:

```bash
ss -lntup | grep :53
```

Если там `systemd-resolve` на `127.0.0.53:53` / `127.0.0.54:53` — отключите stub-слушатель, не трогая сам сервис:

```bash
mkdir -p /etc/systemd/resolved.conf.d
cat >/etc/systemd/resolved.conf.d/no-stub.conf <<'EOF'
[Resolve]
DNSStubListener=no
EOF

systemctl restart systemd-resolved
systemctl reset-failed dnsmasq
systemctl start dnsmasq
```

`bind-interfaces` в конфиге `dnsmasq` уже стоит — он нужен, чтобы `dnsmasq` не занимал wildcard и не конфликтовал с loopback.

---

## 7. Форвардинг + NAT

```bash
echo 'net.ipv4.ip_forward=1' >/etc/sysctl.d/30-ipforward.conf
sysctl -p /etc/sysctl.d/30-ipforward.conf

iptables -t nat -A POSTROUTING -o enp0s25 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o enp0s25 -j ACCEPT
iptables -A FORWARD -i enp0s25 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT

mkdir -p /etc/iptables
iptables-save >/etc/iptables/iptables.rules
systemctl enable --now iptables
```

### Ошибка `MASQUERADE ... missing kernel module`

```
Warning: Extension MASQUERADE revision 0 not supported, missing kernel module?
```

Причины и решение:

1. **Ядро обновилось, но система не перезагружена.** Каталог `/lib/modules/$(uname -r)` неполон. Проверьте `uname -r` и `pacman -Q linux` — если версии не совпадают, `reboot`.
2. **Модуль не загружен.** После перезагрузки: `modprobe xt_MASQUERADE`. Для автозагрузки: `echo xt_MASQUERADE >/etc/modules-load.d/iptables-nat.conf`.
3. Если модуля действительно нет в кастомном ядре — используйте нативный nftables:

   ```bash
   nft add table ip nat
   nft add chain ip nat postrouting '{ type nat hook postrouting priority 100 ; }'
   nft add rule ip nat postrouting oifname "enp0s25" masquerade
   ```

---

## 8. Запуск и проверка базовой точки доступа

```bash
systemctl enable --now hostapd dnsmasq
systemctl status hostapd dnsmasq --no-pager
```

Проверка:

1. Клиент подключается к **FuckRKN** / `AfrbyuHjcRjvYflpjh@)26` (SSID скрыт — вводить вручную).
2. Получает IP `10.44.5.10–10.44.5.254`, шлюз и DNS — `10.44.5.1`.
3. После подключения кабеля в `enp0s25`: `ping 8.8.8.8` с клиента.

Если что-то не работает:

```bash
journalctl -u hostapd -e --no-pager
journalctl -u dnsmasq -e --no-pager
iptables -t nat -L -n -v
ip route
```

---

## 9. Фильтрация по MAC

### Уровень 1 — hostapd (whitelist)

В `/etc/hostapd/hostapd.conf` уже стоят `macaddr_acl=1` и `accept_mac_file=/etc/hostapd/hostapd.accept`. Создайте файл и добавьте MAC разрешённых устройств (по одному на строку):

```bash
cat >/etc/hostapd/hostapd.accept <<'EOF'
aa:bb:cc:dd:ee:ff
11:22:33:44:55:66
EOF
```

### Уровень 2 — dnsmasq (запрет выдачи IP незнакомым)

Дополните `/etc/dnsmasq.d/wlan0.conf`:

```ini
dhcp-ignore=tag:!known
dhcp-host=aa:bb:cc:dd:ee:ff,10.44.5.10
dhcp-host=11:22:33:44:55:66,10.44.5.11
```

Тег `known` ставится автоматически при совпадении MAC с любым `dhcp-host`. Всё остальное игнорируется.

Перезапуск:

```bash
systemctl restart hostapd dnsmasq
```

---

## 10. zapret2 — выборочный обход DPI

Цель: только домены из указанного списка идут через zapret2 (обход DPI), остальной трафик идёт напрямую.

### 10.1 Установка

```bash
paru -S zapret2
```

После установки из AUR не нужно запускать `install_easy.sh` — пакет уже содержит всё необходимое. Достаточно отредактировать конфиг и запустить службу .

Файлы: `/opt/zapret2/`, служба: `zapret2.service`.

### 10.2 Список доменов для обхода

```bash
cat >/opt/zapret2/ipset/zapret_hosts_user.txt <<'EOF'
youtube.com
googlevideo.com
rutracker.org
EOF
```

Один домен на строку. Поддомены (`m.youtube.com`, `www.youtube.com`) матчатся автоматически, если указан корневой домен. Для видео YouTube критично добавить `googlevideo.com` — именно оттуда идёт поток.

### 10.3 Конфигурация

Отредактируйте `/opt/zapret2/config`:

```bash
sed -i 's/^MODE_FILTER=.*/MODE_FILTER=hostlist/' /opt/zapret2/config
```

Убедитесь, что в `NFQWS2_OPT` указан путь к вашему hostlist:

```bash
grep -n 'hostlist' /opt/zapret2/config
```

Строки должны содержать `--hostlist=/opt/zapret2/ipset/zapret_hosts_user.txt` для TCP 80, TCP 443 и UDP 443. Пример:

```bash
NFQWS2_OPT="
        --filter-tcp=80 --filter-l7=http --hostlist=/opt/zapret2/ipset/zapret_hosts_user.txt --payload=http_req --lua-desync=fake:blob=fake_default_http:tcp_ts=-1000 --lua-desync=multisplit:pos=method+2 --new
        --filter-tcp=443 --filter-l7=tls --hostlist=/opt/zapret2/ipset/zapret_hosts_user.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000 --lua-desync=multidisorder:pos=midsld --new
        --filter-udp=443 --filter-l7=quic --hostlist=/opt/zapret2/ipset/zapret_hosts_user.txt --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=6
"
```

### 10.4 Ключевой момент: `MODE_FILTER=hostlist`

**Без этого параметра zapret2 не заполнит внутренний nftables-набор `zapret`, и трафик из hostlist не будет перехватываться.** Симптом: служба активна, hostlist указан, DNS резолвит домены, но `nft list set inet zapret2 zapret` пуст, и YouTube не открывается.

Проверка режима:

```bash
grep '^MODE_FILTER' /opt/zapret2/config
```

Должно быть `MODE_FILTER=hostlist`. Если стоит `none` или `ipset` — замените и перезапустите.

### 10.5 Запуск и проверка

```bash
systemctl enable --now zapret2
systemctl status zapret2 --no-pager
```

Проверьте, что nftables-набор заполнился:

```bash
nft list set inet zapret2 zapret
```

Должны появиться IP-адреса (например, `142.251.x.x` для YouTube). Если набор пуст после перезапуска — проверьте:

```bash
cat /etc/resolv.conf; getent hosts youtube.com
```

`getent` должен возвращать IPv4-адрес (не только IPv6). Если возвращает только IPv6 — zapret2 не сможет заполнить IPv4-набор. В этом случае убедитесь, что `dnsmasq` работает и раздаёт IPv4, или временно добавьте IPv4 DNS в `/etc/resolv.conf`.

Проверка перехвата:

```bash
nft list chain inet zapret2 flow_offload_zapret
```

Счётчики правил `queue ... to 300` должны расти, когда клиент открывает YouTube.

### 10.6 Если YouTube не работает

1. **Проверьте hostlist:** `cat /opt/zapret2/ipset/zapret_hosts_user.txt` — должны быть `youtube.com` и `googlevideo.com`.
2. **Проверьте резолв:** `dig +short googlevideo.com @10.44.5.1` — должен вернуть IPv4.
3. **Перезапустите zapret2** после изменения hostlist: `systemctl restart zapret2`.
4. **Проверьте, что `MODE_FILTER=hostlist`** (раздел 10.4).
5. **Посмотрите логи:** `journalctl -u zapret2 -n 50 --no-pager`.

### 10.7 Важно о стратегии обхода

Пример `--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000` — базовая. Универсальной стратегии нет, она зависит от DPI провайдера. Если YouTube не открывается при заполненном наборе, стратегию нужно подобрать через `blockcheck2.sh` из исходного репозитория zapret2, затем заменить `--lua-desync=...` на найденную.

---

## 11. Дальше: VPN (policy-based routing)

Базовый NAT — фундамент. При установке VPN его **не ломают**, а **дополняют**.

Пусть туннель — `wg0`. Направляем в него **только** клиентов AP (`10.44.5.0/24`), хост остаётся с прямым выходом через `enp0s25`.

```bash
# Отдельная таблица маршрутизации для подсети AP
ip rule add from 10.44.5.0/24 lookup 42
ip route add default dev wg0 table 42

# NAT для трафика, уходящего в туннель
iptables -t nat -A POSTROUTING -s 10.44.5.0/24 -o wg0 -j MASQUERADE

# Форвардинг wlan0 <-> wg0
iptables -A FORWARD -i wlan0 -o wg0 -j ACCEPT
iptables -A FORWARD -i wg0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

Нюансы:

- **OpenVPN** может перехватить default route хоста. В конфиге клиента: `pull-filter ignore redirect-gateway` и `route-nopull`.
- **WireGuard** — не добавляйте `0.0.0.0/0` в `AllowedIPs` интерфейса; маршрут для клиентов задаётся через таблицу 42.
- `ip rule` / `ip route` не сохраняются через `iptables-save`. Добавляйте их в `PostUp` WireGuard или в systemd-юнит, поднимающий VPN.
- **zapret2 и VPN:** если клиенты уходят в VPN, их трафик шифруется, и DPI-обход для них может быть не нужен. Оставьте zapret2 только для трафика, идущего напрямую (не через VPN).

---

## Шпаргалка по ошибкам

| Симптом | Причина | Решение |
|---|---|---|
| `hostapd` падает сразу | `wlan0` занят `iwd`/NM/`wpa_supplicant` | Раздел 1 |
| `hostapd` падает на старте AP | Канал занят / не поддержан | Сменить `channel` (1/11) или `hw_mode` |
| `dnsmasq: Address already in use` (порт 53) | `systemd-resolved` держит `127.0.0.53:53` | `DNSStubListener=no` (раздел 6) |
| `/etc/dnsmasq.d/...: No such file or directory` | Каталога нет в свежей установке | `mkdir -p /etc/dnsmasq.d` |
| `MASQUERADE ... missing kernel module` | Ядро обновлено без перезагрузки / модуль не загружен | `reboot`, затем `modprobe xt_MASQUERADE` |
| Клиент не получает IP | `dnsmasq` не слушает `wlan0` / не тот диапазон | Проверить `/etc/dnsmasq.d/wlan0.conf`, `ss -lntup \| grep :67` |
| Нет интернета у клиентов | Нет `ip_forward` / нет `MASQUERADE` / `FORWARD` закрыт | Раздел 7, `iptables -t nat -L -n -v` |
| zapret2 активен, но YouTube не открывается | `MODE_FILTER` не `hostlist`, набор `@zapret` пуст | `MODE_FILTER=hostlist` (раздел 10.4) |
| zapret2: `nft list set ... zapret` пуст | DNS не резолвит в IPv4 / hostlist пуст | Проверить `getent hosts youtube.com`, `dig +short googlevideo.com @10.44.5.1` |
| zapret2: YouTube открывается, видео буферизуется | Нет `googlevideo.com` в hostlist | Добавить домен, перезапустить |
