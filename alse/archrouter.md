# Arch Linux Wi-Fi Router с выборочным обходом DPI, DNS-бенчмарком и автообновлением списков

Превращаем Arch Linux в точку доступа Wi-Fi с NAT, скрытым SSID, фильтрацией по MAC и выборочным обходом DPI через zapret2. Ethernet получает адрес по DHCP, Wi-Fi-клиенты выходят в интернет через Ethernet. Обход DPI применяется только к указанным доменам и/или IP-подсетям. Дополнительно: ежедневный бенчмарк DNS-серверов (включая DoH/DoT) и ежедневное автообновление списков zapret2 из публичных источников.

Проверено на: Arch Linux, ядро `7.x`, `hostapd`, `dnsmasq`, `iptables-nft`, `systemd-networkd`, `zapret2` (AUR), `systemd-resolved`, `knot`, `bind-tools`.

---

## Возможности

- Ethernet (`enp0s25`) — DHCP-клиент.
- Wi-Fi (`wlan0`) — точка доступа WPA2, скрытый SSID.
- DHCP-сервер для клиентов: `10.44.5.10–10.44.5.254`.
- NAT (MASQUERADE) через Ethernet.
- Фильтрация клиентов по MAC (whitelist на двух уровнях: hostapd + dnsmasq).
- Выборочный обход DPI через zapret2 по доменам (`--hostlist`) и/или IP/CIDR (`--ipset`).
- Ежедневный бенчмарк DNS-серверов (UDP/DoH/DoT) с автоматическим выбором быстрейшего (03:00).
- Ежедневное автообновление списков доменов и IP для zapret2 из публичных источников (04:00).
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

Цель: только домены из hostlist и/или IP-адреса из ipset идут через zapret2, остальной трафик идёт напрямую.

### 10.1 Установка

```bash
paru -S zapret2
```

После установки из AUR не нужно запускать `install_easy.sh` — пакет уже содержит всё необходимое. Достаточно отредактировать конфиг и запустить службу. Файлы: `/opt/zapret2/`, служба: `zapret2.service`.

### 10.2 Список доменов и IP для обхода

**Hostlist** (домены, один на строку):

```bash
cat >/opt/zapret2/ipset/zapr2_hosts_usr.txt <<'EOF'
youtube.com
googlevideo.com
rutracker.org
EOF
```

**IPset** (IP или CIDR, один на строку):

```bash
cat >/opt/zapret2/ipset/zapr2_ips_usr.txt <<'EOF'
# Пример: подсеть или конкретный IP
203.0.113.0/24
198.51.100.42
EOF
```

> **Имена файлов.** В этом README везде используются `zapr2_hosts_usr.txt` и `zapr2_ips_usr.txt` — они совпадают с теми, что создаёт скрипт агрегации из раздела 12. Если у вас в конфиге остались старые имена (`zap2_*`), приведите к одному виду:
> ```bash
> sed -i 's|zap2_hosts_usr.txt|zapr2_hosts_usr.txt|g; s|zap2_ips_usr.txt|zapr2_ips_usr.txt|g' /opt/zapret2/config
> ```

Формат hostlist: поддомены (`m.youtube.com`) матчатся автоматически, если указан корневой домен. Для строгого совпадения только с основным доменом используйте `^example.com`. Для YouTube критично добавить `googlevideo.com` — именно оттуда идёт видеопоток.

### 10.3 Конфигурация `NFQWS2_OPT`

Отредактируйте `/opt/zapret2/config`. Ключевое: **`MODE_FILTER=hostlist`** обязателен, даже если вы используете `--ipset` в отдельных профилях. Без него механизм hostlist не активируется, и трафик не будет перехватываться.

```bash
sed -i 's/^MODE_FILTER=.*/MODE_FILTER=hostlist/' /opt/zapret2/config
```

Пример `NFQWS2_OPT` с двумя профилями (hostlist + ipset), разделёнными `--new`. Первый совпавший профиль применяется к трафику:

```bash
NFQWS2_OPT="
  --filter-tcp=80 --filter-l7=http --hostlist=/opt/zapret2/ipset/zapr2_hosts_usr.txt --payload=http_req --lua-desync=fake:blob=fake_default_http:tcp_ts=-1000 --lua-desync=multisplit:pos=method+2 --new
  --filter-tcp=80 --filter-l7=http --ipset=/opt/zapret2/ipset/zapr2_ips_usr.txt --payload=http_req --lua-desync=fake:blob=fake_default_http:tcp_ts=-1000 --lua-desync=multisplit:pos=method+2 --new
  --filter-tcp=443 --filter-l7=tls --hostlist=/opt/zapret2/ipset/zapr2_hosts_usr.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000 --lua-desync=multidisorder:pos=midsld --new
  --filter-tcp=443 --filter-l7=tls --ipset=/opt/zapret2/ipset/zapr2_ips_usr.txt --payload=tls_client_hello --lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000 --lua-desync=multidisorder:pos=midsld --new
  --filter-udp=443 --filter-l7=quic --hostlist=/opt/zapret2/ipset/zapr2_hosts_usr.txt --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=6 --new
  --filter-udp=443 --filter-l7=quic --ipset=/opt/zapret2/ipset/zapr2_ips_usr.txt --payload=quic_initial --lua-desync=fake:blob=fake_default_quic:repeats=6
"
```

**Важно**: `MODE_FILTER` не имеет значения «одновременно hostlist и ipset». Он управляет только автоматической подстановкой заполнителей. Фильтрация по IP реализуется через `--ipset` в отдельных профилях, независимо от `MODE_FILTER`.

### 10.4 Права доступа к файлам (критично)

`nfqws2` запускается от имени пользователя `tpws` (не root). Он должен иметь право на чтение файлов hostlist и ipset, а также **право на вход** во все директории по пути к ним. Если директория `/opt/zapret2/ipset` имеет права `700`, `tpws` не сможет прочитать файлы, и zapret2 упадёт с ошибкой:

```
cannot access hostlist file '/opt/zapret2/ipset/zapr2_hosts_usr.txt'
```

**Решение:**

```bash
chmod o+rx /opt/zapret2/ipset
chmod o+r /opt/zapret2/ipset/zapr2_hosts_usr.txt
chmod o+r /opt/zapret2/ipset/zapr2_ips_usr.txt
```

После этого перезапустите службу:

```bash
systemctl restart zapret2
```

### 10.5 Запуск и проверка

```bash
systemctl enable --now zapret2
systemctl status zapret2 --no-pager
```

Проверьте, что nftables-набор заполнился:

```bash
nft list set inet zapret2 zapret
```

Должны появиться IP-адреса (например, `142.251.x.x` для YouTube). Если набор пуст — проверьте:

```bash
cat /etc/resolv.conf; getent hosts youtube.com
```

`getent` должен возвращать **IPv4**-адрес. Если только IPv6 — zapret2 не сможет заполнить IPv4-набор. Убедитесь, что `dnsmasq` раздаёт IPv4, или временно добавьте IPv4 DNS в `/etc/resolv.conf`.

Проверка перехвата:

```bash
nft list chain inet zapret2 flow_offload_zapret
```

Счётчики правил `queue ... to 300` должны расти, когда клиент открывает YouTube.

### 10.6 Если YouTube не работает

1. **Проверьте hostlist:** `cat /opt/zapret2/ipset/zapr2_hosts_usr.txt` — должны быть `youtube.com` и `googlevideo.com`.
2. **Проверьте резолв:** `dig +short googlevideo.com @10.44.5.1` — должен вернуть IPv4.
3. **Проверьте `MODE_FILTER=hostlist`** (раздел 10.3).
4. **Перезапустите zapret2** после изменения hostlist: `systemctl restart zapret2`.
5. **Посмотрите логи:** `journalctl -u zapret2 -n 50 --no-pager`.

### 10.7 О стратегии обхода

Пример `--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000` — базовая. Универсальной стратегии нет, она зависит от DPI провайдера. Если YouTube не открывается при заполненном наборе, стратегию нужно подобрать через `blockcheck2.sh` из исходного репозитория zapret2, затем заменить `--lua-desync=...` на найденную.

### 10.8 Предупреждение `--ipset parameter is present`

Это **не ошибка**. Предупреждение означает, что фильтрация по IP происходит внутри `nfqws2` (после попадания в NFQUEUE), а не на уровне ядра до очереди. Для выборочного обхода это рабочий подход. Если вы хотите, чтобы трафик, не входящий в список, вообще не попадал в очередь, нужна предварительная фильтрация через ядерные ipset/nftables-сеты — это другая архитектура.

---

## 11. Бенчмарк DNS-серверов (UDP / DoH / DoT)

Ежедневный скрипт тестирует список DNS-серверов, сортирует их по средней задержке, применяет быстрейший через `systemd-resolved` и пишет подробный лог. Запуск — через systemd-таймер в **03:00**.

Цель: автоматически выбирать самый быстрый доступный DNS (в том числе из списка обходных серверов вроде AstraCat, Comss.one, GeoHide, Mafioznik, Malw.link, NextDNS, Xbox-DNS, DNS-AI), а не жёстко прописывать один.

### 11.1 Зависимости

**Важно:** в Arch Linux утилита `kdig` для тестирования DoH/DoT входит в пакет **`knot`** (не `knot-dnsutils` — это имя из Debian/Ubuntu, его в Arch нет). Пакет `knot-utils` — из CentOS/Fedora.

```bash
pacman -S --needed knot bind-tools curl
```

- `knot` → `kdig` (DoH через `+https`, DoT через `+tls`).
- `bind-tools` → `dig` (обычный DNS).
- `curl` — запасной инструмент.

### 11.2 Скрипт `/usr/local/bin/dns-benchmark.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# ==================== НАСТРОЙКИ ====================
IFACE="${IFACE:-wlan0}"                     # интерфейс, на который применяется DNS
LOG_FILE="/var/log/dns-benchmark.log"       # подробный лог
TEST_DOMAIN="youtube.com"                   # домен для проверки
TIMEOUT=3                                   # таймаут одного запроса, сек
RUNS=2                                      # повторов на сервер (для усреднения)
# ====================================================

# Все серверы: "имя|тип|адрес"
# тип: udp (обычный DNS), doh (DNS-over-HTTPS), dot (DNS-over-TLS)
SERVERS=(
  "AK DNS (66.66.66.66)|udp|66.66.66.66"
  "AK DNS (45.207.157.146)|udp|45.207.157.146"
  "AstraCat DNS (DoH)|doh|https://dns.astracat.ru/dns-query"
  "AstraCat DNS (DoT)|dot|dns.astracat.ru"
  "Comss.one DNS (83.220.169.155)|udp|83.220.169.155"
  "Comss.one DNS (DoH)|doh|https://dns.comss.one/dns-query"
  "Comss.one DNS (DoT)|dot|dns.comss.one"
  "GeoHide DNS (DoH)|doh|https://dns.geohide.ru:444/dns-query"
  "GeoHide DNS (DoT)|dot|dns.geohide.ru"
  "Mafioznik DNS (103.27.157.38)|udp|103.27.157.38"
  "Mafioznik DNS (DoH)|doh|https://dns.mafioznik.xyz/dns-query"
  "Mafioznik DNS (DoT)|dot|dns.mafioznik.xyz"
  "Malw.link DNS (80.253.249.40)|udp|80.253.249.40"
  "Malw.link DNS (DoH)|doh|https://dns.malw.link/dns-query"
  "Malw.link DNS (DoT)|dot|dns.malw.link"
  "NextDNS (DoH)|doh|https://dns.nextdns.io/9ee95e"
  "NextDNS (DoT)|dot|9ee95e.dns.nextdns.io"
  "Xbox-DNS (111.88.96.50)|udp|111.88.96.50"
  "Xbox-DNS (DoH)|doh|https://xbox-dns.ru/dns-query"
  "Xbox-DNS (DoT)|dot|xbox-dns.ru"
  "DNS-AI (194.87.196.13)|udp|194.87.196.13"
  "DNS-AI (DoH)|doh|https://dns.dns-ai.ru/dns-query"
  "DNS-AI (DoT)|dot|dns.dns-ai.ru"
)

# ==================== ФУНКЦИИ ====================
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg" | tee -a "$LOG_FILE"
}

benchmark_server() {
  local type="$1" addr="$2"
  local total=0 ok=0

  for ((i=1; i<=RUNS; i++)); do
    local start end elapsed
    start=$(date +%s%N)

    case "$type" in
      udp)
        dig +time="$TIMEOUT" +tries=1 "@$addr" "$TEST_DOMAIN" A 2>&1 | grep -q "ANSWER SECTION" || continue
        ;;
      doh)
        kdig +https +timeout="$TIMEOUT" "@$addr" "$TEST_DOMAIN" A >/dev/null 2>&1 || continue
        ;;
      dot)
        kdig +tls +timeout="$TIMEOUT" "@$addr" "$TEST_DOMAIN" A >/dev/null 2>&1 || continue
        ;;
      *)
        continue
        ;;
    esac

    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))
    total=$((total + elapsed))
    ok=$((ok + 1))
  done

  if (( ok > 0 )); then
    echo $((total / ok))
  else
    echo ""
  fi
}

# ==================== ОСНОВНАЯ ЛОГИКА ====================
: > "$LOG_FILE"
log "=== DNS benchmark started ==="
log "Interface: $IFACE, test domain: $TEST_DOMAIN, runs: $RUNS, timeout: ${TIMEOUT}s"
log "Servers to test: ${#SERVERS[@]}"

RESULTS=()

for entry in "${SERVERS[@]}"; do
  IFS='|' read -r name type addr <<< "$entry"
  log "Testing: $name ($type) ..."
  delay=$(benchmark_server "$type" "$addr")

  if [[ -n "$delay" ]]; then
    log "  -> OK, avg ${delay} ms"
    RESULTS+=("${name}|${type}|${addr}|${delay}")
  else
    log "  -> FAILED / timeout"
  fi
done

if (( ${#RESULTS[@]} == 0 )); then
  log "ERROR: no reachable DNS servers found. Aborting."
  exit 1
fi

IFS=$'\n' sorted=($(printf '%s\n' "${RESULTS[@]}" | sort -t'|' -k4 -n))
unset IFS

log "=== Results (sorted by latency) ==="
for r in "${sorted[@]}"; do
  IFS='|' read -r name type addr delay <<< "$r"
  log "  ${delay} ms  |  ${name}  |  ${type}  |  ${addr}"
done

IFS='|' read -r best_name best_type best_addr best_delay <<< "${sorted[0]}"
log "=== Best server: ${best_name} (${best_type}), ${best_addr}, ${best_delay} ms ==="

# Применение через resolvectl.
# systemd-resolved поддерживает обычный DNS и DoT (server#hostname). DoH напрямую — нет.
case "$best_type" in
  udp)
    log "Applying via resolvectl: $best_addr"
    resolvectl dns "$IFACE" "$best_addr"
    ;;
  dot)
    log "Applying via resolvectl (DoT): $best_addr#$best_addr"
    resolvectl dns "$IFACE" "$best_addr#$best_addr"
    ;;
  doh)
    ip=$(getent ahostsv4 "$best_addr" | awk '{print $1; exit}') || ip="$best_addr"
    log "DoH not natively supported by systemd-resolved; applying IP $ip as plain DNS"
    resolvectl dns "$IFACE" "$ip"
    ;;
esac

resolvectl flush-caches
log "=== DNS benchmark finished successfully ==="
```

### 11.3 Systemd-юнит и таймер

**Сервис** `/etc/systemd/system/dns-benchmark.service`:

```ini
[Unit]
Description=Daily DNS benchmark and apply best server
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/dns-benchmark.sh
User=root
StandardOutput=journal
StandardError=journal
```

**Таймер** `/etc/systemd/system/dns-benchmark.timer`:

```ini
[Unit]
Description=Run DNS benchmark daily at 03:00

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

Активация:

```bash
chmod +x /usr/local/bin/dns-benchmark.sh
systemctl daemon-reload
systemctl enable --now dns-benchmark.timer
```

Проверка:

```bash
systemctl list-timers dns-benchmark.timer
```

### 11.4 Логи и ротация

Подробный лог — `/var/log/dns-benchmark.log`, перезаписывается при каждом запуске. Дополнительно вывод дублируется в journal (`journalctl -u dns-benchmark.service`).

Ротация (опционально) — `/etc/logrotate.d/dns-benchmark`:

```ini
/var/log/dns-benchmark.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

### 11.5 Нюансы

1. **DoH и systemd-resolved.** `systemd-resolved` **не поддерживает DoH**. Скрипт применяет DoH-сервер как обычный DNS по IP (UDP/53). Если нужен именно DoH-транспорт — ставьте отдельный локальный резолвер (`dnscrypt-proxy` или `cloudflared`) и переключайте `resolvectl` на `127.0.0.1`.
2. **DoT через `resolvectl`.** Синтаксис `server#hostname` включает DNS-over-TLS. Убедитесь, что сертификат валиден и имя совпадает.
3. **Тестовый домен.** `youtube.com` — рабочий пример. Можно заменить `TEST_DOMAIN` на любой стабильный домен.
4. **Интерфейс.** По умолчанию DNS применяется только на `wlan0`. Для глобального применения используйте `resolvectl dns` без интерфейса (или `DNS=` в `/etc/systemd/resolved.conf`).
5. **Таймаут и повторы.** `TIMEOUT=3`, `RUNS=2` — разумные значения; при нестабильной сети увеличьте.
6. **Конфликт с `dnsmasq`.** Если клиенты получают DNS `10.44.5.1` (dnsmasq), то после смены upstream DNS на роутере dnsmasq продолжит отдавать клиентам `10.44.5.1`, а форвардить будет на выбранный бенчмарком сервер. Менять `dnsmasq` не нужно.
7. **Безопасность.** DoH/DoT-серверы из таблицы — сторонние; доверяйте им как обычным публичным DNS.

---

## 12. Автообновление списков zapret2

Ежедневный скрипт скачивает публичные списки доменов и IP, очищает, удаляет дубликаты и записывает результат в `/opt/zapret2/ipset/zapr2_hosts_usr.txt` и `/opt/zapret2/ipset/zapr2_ips_usr.txt`. После обновления перезапускает `zapret2`, чтобы он перечитал списки. Запуск — через systemd-таймер в **04:00** (после DNS-бенчмарка в 03:00, чтобы к моменту скачивания списков upstream DNS уже был обновлён).

### 12.1 Скрипт `/usr/local/bin/zapret2-list-aggregator.sh`

```bash
#!/usr/bin/env bash
# ============================================================
# zapret2-list-aggregator.sh
#
# Скачивает списки доменов и IP из разных источников,
# очищает, удаляет дубликаты и формирует два файла:
#   zapr2_hosts_usr.txt  — домены
#   zapr2_ips_usr.txt    — IP-адреса и подсети
#
# Все временные файлы создаются в /tmp и удаляются после работы.
# ============================================================

set -uo pipefail

# --- Настройки ------------------------------------------------
TMP_DIR="$(mktemp -d /tmp/zapret2-lists.XXXXXX)"
INSTALL_DIR="/opt/zapret2/ipset"
OUT_HOSTS="$INSTALL_DIR/zapr2_hosts_usr.txt"
OUT_IPS="$INSTALL_DIR/zapr2_ips_usr.txt"

# Очистка при выходе
cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# --- Функции --------------------------------------------------

download() {
    local url="$1"
    local out="$2"
    local desc="${3:-$url}"

    echo "[+] Скачиваю: $desc"
    if ! curl -fsSL --max-time 120 --connect-timeout 15 \
         --retry 3 --retry-delay 2 \
         -A "Mozilla/5.0 (X11; Linux x86_64)" \
         "$url" -o "$out" 2>/dev/null; then
        echo "[!] Не удалось скачать: $desc (пропускаю)" >&2
        return 1
    fi
    return 0
}

clean_domains() {
    local infile="$1"
    local outfile="$2"

    if [[ ! -s "$infile" ]]; then
        > "$outfile"
        return
    fi

    sed 's/^\xEF\xBB\xBF//; s/\r$//' "$infile" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/["",]//g; s/^[ \t]*//; s/[ \t]*$//; s/[ \t].*//' | \
    grep -vE '^[[:space:]]*(#|;|/|!|\^)' | \
    grep -vE '^[[:space:]]*$' | \
    grep -E '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$' | \
    sort -u > "$outfile"
}

clean_ips() {
    local infile="$1"
    local outfile="$2"

    if [[ ! -s "$infile" ]]; then
        > "$outfile"
        return
    fi

    local ipv4='((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
    local ipv4_cidr="${ipv4}(/([0-9]|[1-2][0-9]|3[0-2]))?"

    sed 's/\r$//; s/^[ \t]*//; s/[ \t]*$//' "$infile" | \
    grep -vE '^[[:space:]]*(#|;|/|!|\^)' | \
    grep -vE '^[[:space:]]*$' | \
    grep -E "^${ipv4_cidr}$" | \
    sort -u > "$outfile"
}

# --- Источники доменов ----------------------------------------

echo "=== Скачивание списков доменов ==="

RAW_HOSTS="$TMP_DIR/raw_hosts.txt"
: > "$RAW_HOSTS"

download \
    "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_hostname_resolvable.txt" \
    "$TMP_DIR/rulist_hosts.txt" \
    "bol-van rulist (reestr_hostname_resolvable)" && \
    cat "$TMP_DIR/rulist_hosts.txt" >> "$RAW_HOSTS"

download \
    "https://antizapret.prostovpn.org/domains-export.txt" \
    "$TMP_DIR/antizapret_domains.txt" \
    "antizapret.prostovpn (domains-export)" && \
    cat "$TMP_DIR/antizapret_domains.txt" >> "$RAW_HOSTS"

download \
    "https://github.com/1andrevich/Re-filter-lists/releases/latest/download/domains_all.lst" \
    "$TMP_DIR/refilter_domains.txt" \
    "Re-filter (domains_all.lst)" && \
    cat "$TMP_DIR/refilter_domains.txt" >> "$RAW_HOSTS"

download \
    "https://raw.githubusercontent.com/1andrevich/Re-filter-lists/main/community.lst" \
    "$TMP_DIR/refilter_community.txt" \
    "Re-filter (community.lst)" && \
    cat "$TMP_DIR/refilter_community.txt" >> "$RAW_HOSTS"

download \
    "https://raw.githubusercontent.com/pumPCin/AntiZapret/main/autohostlist.txt" \
    "$TMP_DIR/antizapret_autohost.txt" \
    "pumPCin AntiZapret (autohostlist)" && \
    cat "$TMP_DIR/antizapret_autohost.txt" >> "$RAW_HOSTS"

# --- Обработка доменов ----------------------------------------

echo ""
echo "=== Обработка доменов ==="

if [[ ! -s "$RAW_HOSTS" ]]; then
    echo "[!] Предупреждение: ни один список доменов не был скачан" >&2
    > "$OUT_HOSTS"
else
    echo "[*] Очищаю и удаляю дубликаты доменов..."
    clean_domains "$RAW_HOSTS" "$OUT_HOSTS"
fi

# --- Источники IP ---------------------------------------------

echo ""
echo "=== Скачивание списков IP ==="

RAW_IPS="$TMP_DIR/raw_ips.txt"
: > "$RAW_IPS"

download \
    "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_resolved4.txt" \
    "$TMP_DIR/rulist_ip4.txt" \
    "bol-van rulist (reestr_resolved4)" && \
    cat "$TMP_DIR/rulist_ip4.txt" >> "$RAW_IPS"

download \
    "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_resolved6.txt" \
    "$TMP_DIR/rulist_ip6.txt" \
    "bol-van rulist (reestr_resolved6)" && \
    cat "$TMP_DIR/rulist_ip6.txt" >> "$RAW_IPS"

download \
    "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_smart4.txt" \
    "$TMP_DIR/rulist_smart4.txt" \
    "bol-van rulist (reestr_smart4)" && \
    cat "$TMP_DIR/rulist_smart4.txt" >> "$RAW_IPS"

download \
    "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_smart6.txt" \
    "$TMP_DIR/rulist_smart6.txt" \
    "bol-van rulist (reestr_smart6)" && \
    cat "$TMP_DIR/rulist_smart6.txt" >> "$RAW_IPS"

download \
    "https://antifilter.network/download/ipsmart.lst" \
    "$TMP_DIR/antifilter_ipsmart.txt" \
    "antifilter (ipsmart)" && \
    cat "$TMP_DIR/antifilter_ipsmart.txt" >> "$RAW_IPS"

download \
    "https://antifilter.network/download/ipsum.lst" \
    "$TMP_DIR/antifilter_ipsum.txt" \
    "antifilter (ipsum)" && \
    cat "$TMP_DIR/antifilter_ipsum.txt" >> "$RAW_IPS"

download \
    "https://github.com/1andrevich/Re-filter-lists/releases/latest/download/ipsum.lst" \
    "$TMP_DIR/refilter_ipsum.txt" \
    "Re-filter (ipsum.lst)" && \
    cat "$TMP_DIR/refilter_ipsum.txt" >> "$RAW_IPS"

download \
    "https://raw.githubusercontent.com/1andrevich/Re-filter-lists/main/community_ips.lst" \
    "$TMP_DIR/refilter_community_ips.txt" \
    "Re-filter (community_ips.lst)" && \
    cat "$TMP_DIR/refilter_community_ips.txt" >> "$RAW_IPS"

download \
    "https://raw.githubusercontent.com/1andrevich/Re-filter-lists/main/discord_ips.lst" \
    "$TMP_DIR/refilter_discord_ips.txt" \
    "Re-filter (discord_ips.lst)" && \
    cat "$TMP_DIR/refilter_discord_ips.txt" >> "$RAW_IPS"

# --- Обработка IP ---------------------------------------------

echo ""
echo "=== Обработка IP ==="

if [[ ! -s "$RAW_IPS" ]]; then
    echo "[!] Предупреждение: ни один список IP не был скачан" >&2
    > "$OUT_IPS"
else
    echo "[*] Очищаю и удаляю дубликаты IP..."
    clean_ips "$RAW_IPS" "$OUT_IPS"
fi

# --- Права для пользователя tpws ------------------------------
# nfqws2 работает от tpws и должен читать файлы.
# chmod страхует от строгого umask (например, 077).
chmod o+rx "$INSTALL_DIR" 2>/dev/null || true
chmod o+r  "$OUT_HOSTS" "$OUT_IPS" 2>/dev/null || true

# --- Результат ------------------------------------------------

echo ""
echo "========================================"
echo "Готово!"
echo ""
if [[ -f "$OUT_HOSTS" ]]; then
    echo "  Домены:  $(wc -l < "$OUT_HOSTS") записей → $OUT_HOSTS"
else
    echo "  Домены:  файл не создан"
fi
if [[ -f "$OUT_IPS" ]]; then
    echo "  IP:      $(wc -l < "$OUT_IPS") записей   → $OUT_IPS"
else
    echo "  IP:      файл не создан"
fi
echo ""
echo "Временные файлы удалены из: $TMP_DIR"
echo "========================================"
```

Сделайте исполняемым:

```bash
chmod +x /usr/local/bin/zapret2-list-aggregator.sh
```

**Ключевые моменты:**

- `OUT_HOSTS`/`OUT_IPS` — **абсолютные пути** в `/opt/zapret2/ipset/`. Скрипт пишет файлы напрямую туда, копировать ничего не нужно.
- `chmod o+rx`/`o+r` в конце гарантирует, что `tpws` (не root) сможет прочитать файлы, даже если umask строгий.
- Имена `zapr2_hosts_usr.txt`/`zapr2_ips_usr.txt` совпадают с теми, что прописаны в `NFQWS2_OPT` (раздел 10.3).
- Предупреждение `you store ipset or hostlist files inside '/opt/zapret2'` актуально только для `install_easy.sh`; при установке из AUR `paru -Syu` файлы в `/opt/zapret2/ipset/` не тронет.

### 12.2 Systemd-сервис

`/etc/systemd/system/zapret2-list-aggregator.service`:

```ini
[Unit]
Description=Aggregate zapret2 domain and IP lists
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/zapret2-list-aggregator.sh
ExecStartPost=/bin/systemctl --no-block restart zapret2.service
User=root
StandardOutput=journal
StandardError=journal
```

- `Type=oneshot` — скрипт отрабатывает и завершается.
- `ExecStartPost=systemctl --no-block restart zapret2` — после обновления списков перезапускает zapret2, чтобы он перечитал hostlist/ipset. `--no-block` обязателен: без него возможен дедлок «сервис запускает systemctl, который ждёт завершения самого сервиса».
- `After=network-online.target` — не запустится, пока сети нет.

### 12.3 Systemd-таймер на 04:00

`/etc/systemd/system/zapret2-list-aggregator.timer`:

```ini
[Unit]
Description=Daily zapret2 list aggregation at 04:00

[Timer]
OnCalendar=*-*-* 04:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

- `Persistent=true` — если в 04:00 машина была выключена, скрипт запустится при следующем включении.

### 12.4 Активация и проверка

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now zapret2-list-aggregator.timer
sudo systemctl list-timers zapret2-list-aggregator.timer
```

`systemctl daemon-reload` и `enable` требуют **root** — без `sudo` они падают с `Access denied`.

Ручной запуск (не дожидаясь ночи):

```bash
sudo systemctl start zapret2-list-aggregator.service
sudo journalctl -u zapret2-list-aggregator.service -n 80 --no-pager
```

Проверка результата:

```bash
ls -l /opt/zapret2/ipset/zapr2_*.txt
sudo -u tpws head -1 /opt/zapret2/ipset/zapr2_hosts_usr.txt
sudo nft list set inet zapret2 zapret | head -20
```

- Размеры файлов — не нулевые.
- Права — `-rw-r--r--` (`o+r` есть).
- `tpws` читает файлы.
- Сет `@zapret` — непуст.

### 12.5 Логи и ротация

Вывод скрипта идёт в journal (`journalctl -u zapret2-list-aggregator`). Если нужен отдельный файл — замените в сервисе:

```ini
StandardOutput=append:/var/log/zapret2-list-aggregator.log
StandardError=append:/var/log/zapret2-list-aggregator.log
```

И добавьте ротацию `/etc/logrotate.d/zapret2-list-aggregator`:

```ini
/var/log/zapret2-list-aggregator.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
```

Для отладки journal удобнее (не нужно думать о ротации).

### 12.6 Нюансы

1. **Согласованность имён файлов.** Убедитесь, что `NFQWS2_OPT` в `/opt/zapret2/config` ссылается на те же имена, что создаёт скрипт (`zapr2_hosts_usr.txt`/`zapr2_ips_usr.txt`). Расхождение `zap2_*` / `zapr2_*` — самая частая причина «после обновления списков ничего не работает». Проверка: `grep -o 'zap[^ ]*_usr.txt' /opt/zapret2/config | sort -u`.
2. **Порядок с DNS-бенчмарком.** Таймер DNS-бенчмарка — 03:00, агрегации — 04:00. К моменту скачивания списков upstream DNS уже обновлён. Порядок корректен.
3. **Первое заполнение сета после рестарта.** `zapret2` заполняет nftables-сет `@zapret` при старте резолвом доменов из hostlist. `ExecStartPost` перезапускает сервис — сет пересоберётся с новыми списками. Если после рестарта сет пуст — проблема в DNS (раздел 10.6), а не в таймере.
4. **`--no-block` в `ExecStartPost`.** Не убирайте: без него `systemctl restart zapret2` изнутри сервиса может зависнуть в ожидании job-очереди systemd.
5. **`curl` и `--retry`.** Скрипт делает 3 попытки с задержкой 2 с — при ночных сбоях GitHub не упадёт. Если хочется совсем надёжно — добавьте в сервис `OnFailure=` с уведомлением, но это опционально.

---

## 13. Дальше: VPN (policy-based routing)

Базовый NAT — фундамент. При установке VPN его **не ломают**, а **дополняют**.

Пусть туннель — `wg0`. Направляем в него **только** клиентов AP (`10.44.5.0/24`), хост остаётся с прямым выходом через `enp0s25`.

```bash
ip rule add from 10.44.5.0/24 lookup 42
ip route add default dev wg0 table 42

iptables -t nat -A POSTROUTING -s 10.44.5.0/24 -o wg0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o wg0 -j ACCEPT
iptables -A FORWARD -i wg0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

Нюансы:

- **OpenVPN** может перехватить default route хоста. В конфиге клиента: `pull-filter ignore redirect-gateway` и `route-nopull`.
- **WireGuard** — не добавляйте `0.0.0.0/0` в `AllowedIPs` интерфейса; маршрут для клиентов задаётся через таблицу 42.
- `ip rule` / `ip route` не сохраняются через `iptables-save`. Добавляйте их в `PostUp` WireGuard или в systemd-юнит, поднимающий VPN.
- **zapret2 и VPN:** если клиенты уходят в VPN, их трафик шифруется, и DPI-обход для них может быть не нужен. Оставьте zapret2 только для трафика, идущего напрямую.

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
| zapret2: `cannot access hostlist file` | Нет прав на чтение у пользователя `tpws` | `chmod o+rx /opt/zapret2/ipset; chmod o+r /opt/zapret2/ipset/*.txt` (раздел 10.4) |
| zapret2 активен, но YouTube не открывается | `MODE_FILTER` не `hostlist`, набор `@zapret` пуст | `MODE_FILTER=hostlist` (раздел 10.3) |
| zapret2: `nft list set ... zapret` пуст | DNS не резолвит в IPv4 / hostlist пуст | Проверить `getent hosts youtube.com`, `dig +short googlevideo.com @10.44.5.1` |
| zapret2: YouTube открывается, видео буферизуется | Нет `googlevideo.com` в hostlist | Добавить домен, перезапустить |
| `pacman: target not found: knot-dnsutils` | Пакет из Debian/Ubuntu, в Arch его нет | Ставить `knot` (раздел 11.1) |
| `dns-benchmark.sh`: все серверы `FAILED` | Нет сети / DNS не резолвит / `kdig` не установлен | Проверить `pacman -Q knot`, `dig youtube.com` |
| `dns-benchmark.sh`: `resolvectl failed` | Нет прав / `systemd-resolved` не запущен | Запускать через systemd-юнит от root (раздел 11.3) |
| DoH-сервер выбран, но трафик идёт по UDP/53 | `systemd-resolved` не умеет DoH | Раздел 11.5, п. 1 |
| `systemctl daemon-reload: Access denied` | Запуск от обычного пользователя | `sudo systemctl ...` |
| Файлы агрегатора создаются, но zapret2 не работает | Имена в конфиге ≠ имена от скрипта (`zap2_*` vs `zapr2_*`) | `sed -i 's/zap2_/zapr2_/g' /opt/zapret2/config` (раздел 12.6) |
| `nfqws2: cannot access hostlist file` после агрегатора | Нет `o+r` на файле / `o+rx` на каталоге | `chmod` уже в скрипте (раздел 12.1); проверить `ls -l` |
| Таймер агрегатора не сработал в 04:00 | `Persistent=true` не помог, машина спала | `journalctl -u zapret2-list-aggregator`; проверить `systemctl list-timers` |
| После обновления списков `@zapret` пуст | DNS не резолвит домены в IPv4 | `dig +short youtube.com @10.44.5.1`; раздел 11 |
