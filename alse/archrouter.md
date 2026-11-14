# Arch Linux Wi-Fi Router с обходом DPI, DNS-бенчмарком, автообновлением списков и проверкой VPN-подписок

Превращаем Arch Linux в точку доступа Wi-Fi с NAT, скрытым SSID, фильтрацией по MAC и выборочным обходом DPI через zapret2. Дополнительно: ежедневный бенчмарк DNS-серверов, ежедневное автообновление списков zapret2 и ежедневная проверка VPN-подписок через vpnsort.

Проверено на: Arch Linux, ядро `7.x`, `hostapd`, `dnsmasq`, `iptables-nft`, `systemd-networkd`, `systemd-resolved`, `zapret2` (AUR), `knot`, `bind-tools`, `vpnsort` (сборка с внешней машины).

---

## Возможности

- Ethernet (`enp0s25`) — DHCP-клиент.
- Wi-Fi (`wlan0`) — точка доступа WPA2, скрытый SSID.
- DHCP-сервер для клиентов: `10.44.5.10–10.44.5.254`.
- NAT (MASQUERADE) через Ethernet.
- Фильтрация клиентов по MAC (hostapd + dnsmasq).
- Выборочный обход DPI через zapret2 по доменам и/или IP/CIDR.
- Ежедневный бенчмарк DNS-серверов (UDP/DoH/DoT), автовыбор быстрейшего (03:00).
- Ежедневное автообновление списков для zapret2 из публичных источников (04:00).
- Ежедневная проверка VPN-подписок через vpnsort (06:00).
- Готовность к добавлению VPN (policy-based routing).

---

## 0. Требования

- Wi-Fi-карта с поддержкой AP:

```bash
iw list | grep -A 10 "Supported interface modes"
```

- Имена интерфейсов в примерах: `enp0s25` (Ethernet), `wlan0` (Wi-Fi). Замени на свои (`ip -br link`).

---

## 1. Освободите Wi-Fi интерфейс

`hostapd` не запустится, если `wlan0` занят `iwd`, `NetworkManager` или `wpa_supplicant`. Проверка:

```bash
systemctl status NetworkManager wpa_supplicant iwd 2>/dev/null | grep -E "Loaded|Active"
```

### iwd
```bash
systemctl disable --now iwd
```

### NetworkManager
```bash
nmcli device set wlan0 managed no
cat >/etc/NetworkManager/conf.d/99-unmanage-wlan0.conf <<'EOF'
[keyfile]
unmanaged-devices=interface-name:wlan0
EOF
systemctl restart NetworkManager
```

### wpa_supplicant@wlan0
```bash
systemctl disable --now wpa_supplicant@wlan0
```

Сброс интерфейса:

```bash
ip link set wlan0 down
ip addr flush dev wlan0
ip link set wlan0 up
```

---

## 2. Установка пакетов

```bash
pacman -S --needed hostapd dnsmasq iptables-nft knot bind-tools curl
```

- `knot` → `kdig` (DoH через `+https`, DoT через `+tls`). **В Arch пакет называется `knot`, не `knot-dnsutils` — это имя из Debian/Ubuntu.**
- `bind-tools` → `dig`.
- `curl` — загрузка списков и подписок.

---

## 3. Ethernet — DHCP

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

Проверка:

```bash
networkctl status enp0s25
```

---

## 4. Статический IP на Wi-Fi

Разово:

```bash
ip addr replace 10.44.5.1/24 dev wlan0
```

Автозапуск:

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
- `macaddr_acl=1` + `accept_mac_file` — whitelist MAC (раздел 9).

Если `hostapd` падает на канале — смени `channel=1` или `11`, либо `hw_mode=a` + `channel=36` для двухдиапазонной карты.

---

## 6. dnsmasq — DHCP + DNS

```bash
mkdir -p /etc/dnsmasq.d
cat >/etc/dnsmasq.d/wlan0.conf <<'EOF'
interface=wlan0
bind-interfaces
dhcp-range=10.44.5.10,10.44.5.254,255.255.255.0,24h
EOF

grep -q 'conf-dir=/etc/dnsmasq.d/' /etc/dnsmasq.conf || \
  echo 'conf-dir=/etc/dnsmasq.d/,*.conf' >> /etc/dnsmasq.conf
```

### Конфликт с systemd-resolved (порт 53)

Симптом: `dnsmasq: failed to create listening socket for port 53: Address already in use`. Проверка:

```bash
ss -lntup | grep :53
```

Если там `systemd-resolve` на `127.0.0.53:53` — отключи stub-слушатель:

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

Дополнительно: `systemd-resolved` по умолчанию ждёт **5 секунд** на DNS-запрос, что критично для vpnsort (там тысячи хостов). Fallback на несколько upstream-серверов в dnsmasq:

```bash
cat >/etc/dnsmasq.d/upstream.conf <<'EOF'
# dnsmasq форвардит на все перечисленные, пока один не ответит
server=111.88.96.50
server=1.1.1.1
server=9.9.9.9
EOF
systemctl restart dnsmasq
```

Тогда домены, которые один обходной DNS не знает (`*.myfymain.com`, `*.pryanik.net.ru`), будут резолвиться через Cloudflare/Quad9, и vpnsort не будет терять живые серверы.

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

1. Ядро обновилось без перезагрузки → `reboot`, затем `modprobe xt_MASQUERADE`.
2. Автозагрузка модуля: `echo xt_MASQUERADE >/etc/modules-load.d/iptables-nat.conf`.
3. Если модуля нет в кастомном ядре — нативный nftables:
   ```bash
   nft add table ip nat
   nft add chain ip nat postrouting '{ type nat hook postrouting priority 100 ; }'
   nft add rule ip nat postrouting oifname "enp0s25" masquerade
   ```

---

## 8. Запуск и проверка точки доступа

```bash
systemctl enable --now hostapd dnsmasq
systemctl status hostapd dnsmasq --no-pager
```

Клиент подключается к **FuckRKN** / `AfrbyuHjcRjvYflpjh@)26` (SSID скрыт — вводить вручную), получает IP `10.44.5.x`, шлюз и DNS `10.44.5.1`. После подключения кабеля — `ping 8.8.8.8`.

---

## 9. Фильтрация по MAC

### hostapd (whitelist)

```bash
cat >/etc/hostapd/hostapd.accept <<'EOF'
aa:bb:cc:dd:ee:ff
11:22:33:44:55:66
EOF
```

### dnsmasq (запрет выдачи IP)

Дополни `/etc/dnsmasq.d/wlan0.conf`:

```ini
dhcp-ignore=tag:!known
dhcp-host=aa:bb:cc:dd:ee:ff,10.44.5.10
dhcp-host=11:22:33:44:55:66,10.44.5.11
```

```bash
systemctl restart hostapd dnsmasq
```

---

## 10. zapret2 — выборочный обход DPI

### 10.1 Установка

```bash
paru -S zapret2
```

Файлы: `/opt/zapret2/`, служба: `zapret2.service`.

### 10.2 Списки доменов и IP

```bash
mkdir -p /opt/zapret2/ipset

cat >/opt/zapret2/ipset/zapr2_hosts_usr.txt <<'EOF'
youtube.com
googlevideo.com
rutracker.org
EOF

cat >/opt/zapret2/ipset/zapr2_ips_usr.txt <<'EOF'
203.0.113.0/24
198.51.100.42
EOF
```

### 10.3 Конфигурация `NFQWS2_OPT`

**Ключевое:** `MODE_FILTER=hostlist` обязателен, даже если используешь `--ipset` в отдельных профилях. Без него набор `@zapret` не заполнится, и трафик не перехватится.

```bash
sed -i 's/^MODE_FILTER=.*/MODE_FILTER=hostlist/' /opt/zapret2/config
```

Пример `NFQWS2_OPT` с двумя профилями на каждый порт (hostlist + ipset), разделёнными `--new`. Первый совпавший профиль применяется:

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

`MODE_FILTER` не имеет значения «одновременно hostlist и ipset». Он управляет только подстановкой заполнителей. IP-фильтрация — через `--ipset` в отдельных профилях.

### 10.4 Права для `tpws`

`nfqws2` работает от `tpws`, не от root. Файлы должны быть читаемы, каталог — проходим:

```bash
chmod o+rx /opt/zapret2/ipset
chmod o+r  /opt/zapret2/ipset/zapr2_hosts_usr.txt
chmod o+r  /opt/zapret2/ipset/zapr2_ips_usr.txt
```

Симптом, если не сделать: `cannot access hostlist file`.

### 10.5 Проверка

```bash
systemctl enable --now zapret2
systemctl status zapret2 --no-pager

# Набор должен быть непуст
nft list set inet zapret2 zapret

# Счётчики queue должны расти при открытии YouTube с клиента
nft list chain inet zapret2 flow_offload_zapret
```

Если набор пуст:

```bash
getent hosts youtube.com   # должен вернуть IPv4, не только IPv6
dig +short googlevideo.com @10.44.5.1
```

`getent` должен возвращать IPv4. Если только IPv6 — IPv4-набор не заполнится.

### 10.6 Предупреждение `--ipset parameter is present`

Не ошибка. Означает, что IP-фильтрация идёт внутри `nfqws2` (после NFQUEUE), а не до очереди на уровне ядра. Для выборочного обхода — рабочий подход.

### 10.7 О стратегии

Пример `--lua-desync=fake:blob=fake_default_tls:tcp_ts=-1000` — базовая. Стратегия зависит от DPI провайдера. Если YouTube не открывается при заполненном наборе — подбирай через `blockcheck2.sh` из репозитория zapret2.

---

## 11. DNS-бенчмарк (03:00)

Ежедневно в 03:00 скрипт тестирует список DNS-серверов, сортирует по задержке, применяет быстрейший через `systemd-resolved`, пишет лог.

### 11.1 Скрипт `/usr/local/bin/dns-benchmark.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

IFACE="${IFACE:-wlan0}"
LOG_FILE="/var/log/dns-benchmark.log"
TEST_DOMAIN="youtube.com"
TIMEOUT=3
RUNS=2

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
      udp) dig +time="$TIMEOUT" +tries=1 "@$addr" "$TEST_DOMAIN" A 2>&1 | grep -q "ANSWER SECTION" || continue ;;
      doh) kdig +https +timeout="$TIMEOUT" "@$addr" "$TEST_DOMAIN" A >/dev/null 2>&1 || continue ;;
      dot) kdig +tls   +timeout="$TIMEOUT" "@$addr" "$TEST_DOMAIN" A >/dev/null 2>&1 || continue ;;
      *)   continue ;;
    esac
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))
    total=$((total + elapsed))
    ok=$((ok + 1))
  done
  if (( ok > 0 )); then echo $((total / ok)); else echo ""; fi
}

: > "$LOG_FILE"
log "=== DNS benchmark started ==="
log "Interface: $IFACE, test: $TEST_DOMAIN, runs: $RUNS, timeout: ${TIMEOUT}s"

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
log "=== Best: ${best_name} (${best_type}), ${best_addr}, ${best_delay} ms ==="

case "$best_type" in
  udp) log "Applying via resolvectl: $best_addr"; resolvectl dns "$IFACE" "$best_addr" ;;
  dot) log "Applying via resolvectl (DoT): $best_addr#$best_addr"; resolvectl dns "$IFACE" "$best_addr#$best_addr" ;;
  doh)
    ip=$(getent ahostsv4 "$best_addr" | awk '{print $1; exit}') || ip="$best_addr"
    log "DoH not natively supported; applying IP $ip as plain DNS"
    resolvectl dns "$IFACE" "$ip"
    ;;
esac

resolvectl flush-caches
log "=== DNS benchmark finished ==="
```

```bash
chmod +x /usr/local/bin/dns-benchmark.sh
```

### 11.2 Сервис и таймер

`/etc/systemd/system/dns-benchmark.service`:

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

`/etc/systemd/system/dns-benchmark.timer`:

```ini
[Unit]
Description=Run DNS benchmark daily at 03:00

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
systemctl daemon-reload
systemctl enable --now dns-benchmark.timer
systemctl list-timers dns-benchmark.timer
```

### 11.3 Нюансы

1. **DoH и `systemd-resolved`.** `systemd-resolved` не поддерживает DoH. Скрипт применяет DoH-сервер как обычный DNS по IP (UDP/53). Для настоящего DoH-транспорта — `dnscrypt-proxy`/`cloudflared` и переключение `resolvectl` на `127.0.0.1`.
2. **DoT через `resolvectl`.** Синтаксис `server#hostname` включает TLS.
3. **Конфликт с `dnsmasq`.** Клиенты получают `10.44.5.1` (dnsmasq), а dnsmasq форвардит на выбранный бенчмарком upstream. Менять `dnsmasq` не нужно, но при добавлении `server=` строк в `/etc/dnsmasq.d/upstream.conf` dnsmasq перестанет зависеть только от бенчмарка — это фича, не баг (fallback).

---

## 12. Агрегатор списков zapret2 (04:00)

Скрипт скачивает публичные списки доменов и IP, чистит, дедуплицирует и пишет в `/opt/zapret2/ipset/`. После обновления перезапускает `zapret2`.

### 12.1 Скрипт `/usr/local/bin/zapret2-list-aggregator.sh`

```bash
#!/usr/bin/env bash
set -uo pipefail

TMP_DIR="$(mktemp -d /tmp/zapret2-lists.XXXXXX)"
INSTALL_DIR="/opt/zapret2/ipset"
OUT_HOSTS="$INSTALL_DIR/zapr2_hosts_usr.txt"
OUT_IPS="$INSTALL_DIR/zapr2_ips_usr.txt"

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

download() {
    local url="$1" out="$2" desc="${3:-$url}"
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
    local infile="$1" outfile="$2"
    if [[ ! -s "$infile" ]]; then > "$outfile"; return; fi
    sed 's/^\xEF\xBB\xBF//; s/\r$//' "$infile" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/["",]//g; s/^[ \t]*//; s/[ \t]*$//; s/[ \t].*//' | \
    grep -vE '^[[:space:]]*(#|;|/|!|\^)' | \
    grep -vE '^[[:space:]]*$' | \
    grep -E '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$' | \
    sort -u > "$outfile"
}

clean_ips() {
    local infile="$1" outfile="$2"
    if [[ ! -s "$infile" ]]; then > "$outfile"; return; fi
    local ipv4='((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])'
    local ipv4_cidr="${ipv4}(/([0-9]|[1-2][0-9]|3[0-2]))?"
    sed 's/\r$//; s/^[ \t]*//; s/[ \t]*$//' "$infile" | \
    grep -vE '^[[:space:]]*(#|;|/|!|\^)' | \
    grep -vE '^[[:space:]]*$' | \
    grep -E "^${ipv4_cidr}$" | \
    sort -u > "$outfile"
}

echo "=== Скачивание списков доменов ==="
RAW_HOSTS="$TMP_DIR/raw_hosts.txt"; : > "$RAW_HOSTS"

download "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_hostname_resolvable.txt" \
    "$TMP_DIR/rulist_hosts.txt" "bol-van rulist" && cat "$TMP_DIR/rulist_hosts.txt" >> "$RAW_HOSTS"
download "https://antizapret.prostovpn.org/domains-export.txt" \
    "$TMP_DIR/antizapret_domains.txt" "antizapret" && cat "$TMP_DIR/antizapret_domains.txt" >> "$RAW_HOSTS"
download "https://github.com/1andrevich/Re-filter-lists/releases/latest/download/domains_all.lst" \
    "$TMP_DIR/refilter_domains.txt" "Re-filter domains" && cat "$TMP_DIR/refilter_domains.txt" >> "$RAW_HOSTS"
download "https://raw.githubusercontent.com/1andrevich/Re-filter-lists/main/community.lst" \
    "$TMP_DIR/refilter_community.txt" "Re-filter community" && cat "$TMP_DIR/refilter_community.txt" >> "$RAW_HOSTS"
download "https://raw.githubusercontent.com/pumPCin/AntiZapret/main/autohostlist.txt" \
    "$TMP_DIR/antizapret_autohost.txt" "pumPCin AntiZapret" && cat "$TMP_DIR/antizapret_autohost.txt" >> "$RAW_HOSTS"

echo ""; echo "=== Обработка доменов ==="
if [[ ! -s "$RAW_HOSTS" ]]; then
    echo "[!] Ни один список доменов не скачан" >&2
    > "$OUT_HOSTS"
else
    echo "[*] Чищу и дедуплицирую домены..."
    clean_domains "$RAW_HOSTS" "$OUT_HOSTS"
fi

echo ""; echo "=== Скачивание списков IP ==="
RAW_IPS="$TMP_DIR/raw_ips.txt"; : > "$RAW_IPS"

download "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_resolved4.txt" "$TMP_DIR/rulist_ip4.txt" "rulist ip4" && cat "$TMP_DIR/rulist_ip4.txt" >> "$RAW_IPS"
download "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_resolved6.txt" "$TMP_DIR/rulist_ip6.txt" "rulist ip6" && cat "$TMP_DIR/rulist_ip6.txt" >> "$RAW_IPS"
download "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_smart4.txt" "$TMP_DIR/rulist_smart4.txt" "rulist smart4" && cat "$TMP_DIR/rulist_smart4.txt" >> "$RAW_IPS"
download "https://raw.githubusercontent.com/bol-van/rulist/main/reestr_smart6.txt" "$TMP_DIR/rulist_smart6.txt" "rulist smart6" && cat "$TMP_DIR/rulist_smart6.txt" >> "$RAW_IPS"
download "https://antifilter.network/download/ipsmart.lst" "$TMP_DIR/antifilter_ipsmart.txt" "antifilter ipsmart" && cat "$TMP_DIR/antifilter_ipsmart.txt" >> "$RAW_IPS"
download "https://antifilter.network/download/ipsum.lst" "$TMP_DIR/antifilter_ipsum.txt" "antifilter ipsum" && cat "$TMP_DIR/antifilter_ipsum.txt" >> "$RAW_IPS"
download "https://github.com/1andrevich/Re-filter-lists/releases/latest/download/ipsum.lst" "$TMP_DIR/refilter_ipsum.txt" "Re-filter ipsum" && cat "$TMP_DIR/refilter_ipsum.txt" >> "$RAW_IPS"
download "https://raw.githubusercontent.com/1andrevich/Re-filter-lists/main/community_ips.lst" "$TMP_DIR/refilter_community_ips.txt" "Re-filter community_ips" && cat "$TMP_DIR/refilter_community_ips.txt" >> "$RAW_IPS"
download "https://raw.githubusercontent.com/1andrevich/Re-filter-lists/main/discord_ips.lst" "$TMP_DIR/refilter_discord_ips.txt" "Re-filter discord_ips" && cat "$TMP_DIR/refilter_discord_ips.txt" >> "$RAW_IPS"

echo ""; echo "=== Обработка IP ==="
if [[ ! -s "$RAW_IPS" ]]; then
    echo "[!] Ни один список IP не скачан" >&2
    > "$OUT_IPS"
else
    echo "[*] Чищу и дедуплицирую IP..."
    clean_ips "$RAW_IPS" "$OUT_IPS"
fi

# Права для tpws
chmod o+rx "$INSTALL_DIR" 2>/dev/null || true
chmod o+r  "$OUT_HOSTS" "$OUT_IPS" 2>/dev/null || true

echo ""; echo "========================================"; echo "Готово!"; echo ""
[[ -f "$OUT_HOSTS" ]] && echo "  Домены:  $(wc -l < "$OUT_HOSTS") → $OUT_HOSTS"
[[ -f "$OUT_IPS" ]]   && echo "  IP:      $(wc -l < "$OUT_IPS") → $OUT_IPS"
echo ""; echo "========================================"
```

```bash
chmod +x /usr/local/bin/zapret2-list-aggregator.sh
```

**Ключевое:** `OUT_HOSTS`/`OUT_IPS` — абсолютные пути. Скрипт пишет напрямую в `/opt/zapret2/ipset/`. Имена `zapr2_*` совпадают с `NFQWS2_OPT` (раздел 10.3). `chmod o+rx/o+r` в конце — страховка на случай строгого `umask`.

### 12.2 Сервис и таймер

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

`ExecStartPost` перезапускает `zapret2` после обновления — набор `@zapret` пересоберётся. `--no-block` обязателен: иначе дедлок «сервис ждёт systemctl, systemctl ждёт сервис».

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

```bash
systemctl daemon-reload
systemctl enable --now zapret2-list-aggregator.timer
systemctl list-timers zapret2-list-aggregator.timer
```

### 12.3 Проверка

```bash
systemctl start zapret2-list-aggregator.service
journalctl -u zapret2-list-aggregator.service -n 80 --no-pager

ls -l /opt/zapret2/ipset/zapr2_*.txt
sudo -u tpws head -1 /opt/zapret2/ipset/zapr2_hosts_usr.txt   # tpws должен читать
nft list set inet zapret2 zapret | head -20                   # непусто
```

---

## 13. vpnsort — проверка VPN-подписок (06:00)

`vpnsort` читает список подписок, скачивает их (text/base64/gzip), дедуплицирует серверы и проверяет доступность каждого (TCP/TLS/QUIC/DNS/STUN + протокольное рукопожатие VLESS/VMess/SS/Trojan + HTTP-запрос сквозь туннель). Результат — живой список ссылок, отсортированный по задержке.

Запуск — через systemd-таймер в 06:00 (после DNS-бенчмарка в 03:00 и агрегатора в 04:00, чтобы DNS/списки уже были обновлены).

### 13.1 Установка `vpnsort`

Бинарник собирается **на внешней машине** и кладётся на роутер через `scp`. На роутере:

```bash
# На внешней машине:
#   scp ./vpnsort shaman@ArchRouter:/tmp/vpnsort

# На роутере:
sudo install -m 755 /tmp/vpnsort /usr/local/bin/vpnsort
rm -f /tmp/vpnsort
vpnsort -version        # должна показаться версия
```

### 13.2 Файл подписок

`/etc/vpnsort/subcr_list.txt` — список **URL подписок**, по одному в строке. `vpnsort` скачает каждую подписку, распарсит серверы и проверит их.

```bash
sudo install -d -m 755 /etc/vpnsort
sudo install -m 600 /dev/null /etc/vpnsort/subcr_list.txt
sudo nano /etc/vpnsort/subcr_list.txt
```

Пример:

```
https://provider1.example/sub/abc123
https://provider2.example/sub/xyz789
```

Внутри `-mode auto` vpnsort сам разберётся, что это URL, а не прямые ссылки. Файл `600 root:root` — внутри токены подписок, не должен быть world-readable.

Если планируешь редактировать от себя (не только через `sudo`), можно дать ACL:

```bash
sudo setfacl -m u:shaman:rw /etc/vpnsort/subcr_list.txt
```

### 13.3 Каталоги, права, лог

```bash
sudo install -d -o root -g shaman -m 2770 /var/lib/vpnsort/output
sudo touch /var/log/vpnsort.log
sudo chown root:shaman /var/log/vpnsort.log
sudo chmod 660 /var/log/vpnsort.log
```

- `/var/lib/vpnsort/output/` — права **`2770`** (`drwxrws---`): владелец root rwx, группа shaman rwx + setgid (новые файлы наследуют группу `shaman`), остальные — ничего.
- Это позволяет:
  - писать файлы и root (systemd), и `shaman` (ручной запуск для отладки);
  - читать их `shaman` и копировать на клиент без `sudo`.
- `/var/log/vpnsort.log` — `660 root:shaman` (root пишет, `shaman` читает).

Если нужен **строгий** вариант — `2750` (без записи для группы), но тогда `vpnsort` руками от `shaman` не запустится, только через systemd.

### 13.4 Обёртка `/usr/local/bin/vpnsort-daily.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

umask 007                                # новые файлы — 660, группа shaman читает
OUT_DIR="/var/lib/vpnsort/output"
LOG_FILE="/var/log/vpnsort.log"
INPUT="/etc/vpnsort/subcr_list.txt"
VPNSORT="/usr/local/bin/vpnsort"

[[ -x "$VPNSORT" ]] || { echo "vpnsort not found: $VPNSORT" >&2; exit 1; }
[[ -s "$INPUT"   ]] || { echo "input empty or missing: $INPUT"  >&2; exit 1; }

mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/$(date +%Y%m%d)_subs.txt"

# Храним 14 дней
find "$OUT_DIR" -maxdepth 1 -name '*_subs.txt' -type f -mtime +14 -delete

# Внешний timeout — страховка от залипания отдельных серверов
# (Cloudflare 522 / DNS 5s / WS-upgrade могут держать воркер до 100 с).
# 90m хватает на большинство подписок при workers=32.
exec timeout --kill-after=10s 90m "$VPNSORT" \
  -in "$INPUT" \
  -out "$OUT" \
  -log "$LOG_FILE" \
  -workers 32 \
  -timeout 2s \
  -retries 0 \
  -max-delay 3s \
  -strict false \
  -testurl http://www.gstatic.com/generate_204
```

```bash
sudo chmod +x /usr/local/bin/vpnsort-daily.sh
```

**Почему такие параметры:**

| Параметр | Значение | Зачем |
|---|---|---|
| `timeout --kill-after=10s 90m` | внешний | Гарантирует завершение. **Внимание:** если процесс убит SIGKILL раньше, чем `vpnsort` дошёл до этапа записи, файл `YYYYMMDD_subs.txt` **не появится**. Поэтому важно, чтобы `vpnsort` успевал сам (см. ниже). |
| `-workers 32` | вместо 64/50 | Меньше «thundering herd» к Cloudflare — меньше 429/522 и зависаний. На 39k серверов прогон ~4 ч; на 1k — минуты. |
| `-timeout 2s` | вместо 1s | 1s слишком агрессивно, режет рабочие серверы (в логе были `жив за 3.8 с`). |
| `-retries 0` | | Ретраи на мёртвых хостах — пустая трата времени. |
| `-max-delay 3s` | | В `_subs.txt` — только реально быстрые. Можно `2s` для совсем короткого списка. |
| `-strict false` | вместо `true` | `strict true` зависает на HTTP-тесте через медленные туннели. С `false` серверы без протокольного подтверждения попадут в конец файла, но не заблокируют работу. |
| `-testurl http://...` | вместо `https://` | HTTP-тест проваливается быстро; HTTPS через мёртвый туннель висит на полный TLS-таймаут. |

**Про `timeout` и файл:** `vpnsort` пишет `-out` только на 5-м этапе (после всех проверок). Если внешний `timeout` убивает раньше — файла не будет. Надёжная схема:

1. Подобрать настройки так, чтобы `vpnsort` **сам** стабильно укладывался в 60–90 минут на твоих подписках.
2. Outer `timeout` — только как страховка от патологического зависания на 1–2 серверах. Если он срабатывает — это сигнал, что подписки разрослись или появились новые «плохие» хосты.
3. Если файла нет — проверить `journalctl -u vpnsort-daily.service`. Предыдущий успешный `YYYYMMDD-1_subs.txt` остаётся на месте (мы храним 14 дней), так что клиент не останется без списка.

### 13.5 Сервис и таймер

`/etc/systemd/system/vpnsort-daily.service`:

```ini
[Unit]
Description=Daily vpnsort subscription cleanup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vpnsort-daily.sh
User=root
StandardOutput=journal
StandardError=journal
TimeoutStartSec=2h
```

`TimeoutStartSec=2h` — внешний systemd-таймаут с запасом. Внутренний `timeout` в обёртке сработает раньше (90m), и systemd увидит нормальный exit code. Если внутренний `timeout` вернёт 124 (SIGTERM) или 137 (SIGKILL) — systemd зафиксирует `Failed with result 'exit-code'`, но не будет держать процесс дополнительно.

`/etc/systemd/system/vpnsort-daily.timer`:

```ini
[Unit]
Description=Run vpnsort daily at 06:00

[Timer]
OnCalendar=*-*-* 06:00:00
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now vpnsort-daily.timer
sudo systemctl list-timers vpnsort-daily.timer
```

### 13.6 Ручной запуск (для отладки)

```bash
sudo systemctl start vpnsort-daily.service
sudo journalctl -u vpnsort-daily.service -n 100 --no-pager
ls -l /var/lib/vpnsort/output/
```

Проверка от `shaman` (без `sudo`):

```bash
ls -l /var/lib/vpnsort/output/
head -3 /var/lib/vpnsort/output/$(date +%Y%m%d)_subs.txt
head -20 /var/log/vpnsort.log
```

Если запускаешь `vpnsort` **руками** от `shaman`:

```bash
timeout --kill-after=10s 90m vpnsort \
  -in /etc/vpnsort/subcr_list.txt \
  -out /var/lib/vpnsort/output/$(date +%Y%m%d)_subs.txt \
  -log /var/log/vpnsort.log \
  -workers 32 -timeout 2s -retries 0 -max-delay 3s \
  -strict false -debug
```

Права `2770` на каталоге это позволяют.

### 13.7 Забрать файл в клиент

```bash
scp shaman@ArchRouter:/var/lib/vpnsort/output/$(date +%Y%m%d)_subs.txt ./
```

Или расшарить каталог по HTTP из локальной сети (например, `python -m http.server` из `/var/lib/vpnsort/output/` под `shaman`) — импортировать в клиент как локальную подписку.

### 13.8 Отладка: почему «то 1080/1800, то 220/300»

Разные подписки содержат разное число «плохих» хостов. Симптом — прогресс замирает в логе на 5–100 секунд. Причины и лечение:

| Симптом | Причина | Лечение |
|---|---|---|
| Прогресс замирает на 850–880/N | Cloudflare 522 держит WS-upgrade ~100 с | `-strict false` + outer `timeout` (раздел 13.4) |
| В DNS-логе `i/o timeout (5.00 с)` | `systemd-resolved` игнорирует `-timeout`, ждёт 5 с | Fallback в dnsmasq (раздел 6) |
| `жив за 3.8 с` при `-timeout 1s` | 1s слишком агрессивно | `-timeout 2s` |
| Разные точки остановки на разных прогонах | Разные подписки → разные «плохие» хосты | Ожидаемо; outer `timeout` = страховка |
| Много 429/522 от Cloudflare | 64 воркера → thundering herd | `-workers 32` |
| `-out` не создан после прогона | Все серверы отвалились, или процесс убит до 5-го этапа | `-only-alive false` (мёртвые в конец) или увеличить `timeout` |
| Файл создан, но пуст | `-strict true` + `-max-delay` слишком строгие | `-strict false`, `-max-delay 3s` |

**Не жди 100% прогресса** — при тысячах серверов 1–2 залипания неизбежны. Ориентируйся на количество живых ссылок в `_subs.txt` — если их хватает клиенту, всё в порядке.

---

## 14. Дальше: VPN (policy-based routing)

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
- **WireGuard** — не добавляй `0.0.0.0/0` в `AllowedIPs` интерфейса; маршрут для клиентов задаётся через таблицу 42.
- `ip rule`/`ip route` не сохраняются через `iptables-save`. Добавляй в `PostUp` WireGuard или в systemd-юнит, поднимающий VPN.
- **zapret2 и VPN:** если клиенты уходят в VPN, их трафик шифруется, DPI-обход для них может быть не нужен. Оставь zapret2 только для трафика, идущего напрямую.

---

## 15. Шпаргалка по ошибкам

| Симптом | Причина | Решение |
|---|---|---|
| `hostapd` падает сразу | `wlan0` занят `iwd`/NM/`wpa_supplicant` | Раздел 1 |
| `hostapd` падает на старте AP | Канал занят / не поддержан | Сменить `channel` или `hw_mode` |
| `dnsmasq: Address already in use` (53) | `systemd-resolved` держит `127.0.0.53:53` | `DNSStubListener=no` (раздел 6) |
| `/etc/dnsmasq.d/...: No such file or directory` | Каталога нет | `mkdir -p /etc/dnsmasq.d` |
| `MASQUERADE ... missing kernel module` | Ядро обновлено без reboot / модуль не загружен | `reboot`, `modprobe xt_MASQUERADE` |
| Клиент не получает IP | `dnsmasq` не слушает `wlan0` | `ss -lntup \| grep :67` |
| Нет интернета у клиентов | Нет `ip_forward` / нет `MASQUERADE` / `FORWARD` | Раздел 7, `iptables -t nat -L -n -v` |
| zapret2: `cannot access hostlist file` | Нет прав у `tpws` | `chmod o+rx /opt/zapret2/ipset; chmod o+r /opt/zapret2/ipset/*.txt` |
| zapret2 активен, YouTube не открывается | `MODE_FILTER` не `hostlist`, `@zapret` пуст | `MODE_FILTER=hostlist` (раздел 10.3) |
| `nft list set ... zapret` пуст | DNS не резолвит в IPv4 / hostlist пуст | `getent hosts youtube.com`, `dig +short googlevideo.com @10.44.5.1` |
| YouTube открывается, видео буферизуется | Нет `googlevideo.com` в hostlist | Добавить, перезапустить |
| `pacman: target not found: knot-dnsutils` | Пакет из Debian/Ubuntu | Ставить `knot` |
| `dns-benchmark.sh`: все серверы `FAILED` | Нет сети / `kdig` не установлен | `pacman -Q knot`, `dig youtube.com` |
| `dns-benchmark.sh`: `resolvectl failed` | Нет прав / `systemd-resolved` не запущен | Запускать через systemd от root |
| DoH-сервер выбран, трафик по UDP/53 | `systemd-resolved` не умеет DoH | Раздел 11.3 п.1 |
| `systemctl daemon-reload: Access denied` | Запуск от обычного пользователя | `sudo systemctl ...` |
| Агрегатор создаёт файлы, zapret2 не работает | Имена в конфиге ≠ имена от скрипта (`zap2_*` vs `zapr2_*`) | `sed -i 's/zap2_/zapr2_/g' /opt/zapret2/config` |
| Агрегатор: `nfqws2 cannot access hostlist file` | Нет `o+r` / `o+rx` | `chmod` уже в скрипте; проверить `ls -l` |
| Таймер агрегатора не сработал в 04:00 | `Persistent=true` не помог, машина спала | `journalctl -u zapret2-list-aggregator` |
| После обновления списков `@zapret` пуст | DNS не резолвит в IPv4 | `dig +short youtube.com @10.44.5.1` |
| `vpnsort: permission denied` при записи в `/var/lib/vpnsort/output/` | Каталог `2750` (без `w` для группы) | `chmod 2770 /var/lib/vpnsort/output` |
| `vpnsort` зависает на 850/N надолго | Cloudflare 522 / DNS 5s | `-strict false` + `timeout` (раздел 13.4) |
| `_subs.txt` не создан после прогона | Процесс убит до 5-го этапа | Проверить `journalctl`, увеличить `timeout` или уменьшить подписки |
| `_subs.txt` пуст | `-strict true` + `-max-delay` слишком строгие | `-strict false`, `-max-delay 3s` |
| `vpnsort` теряет живые серверы на DNS | Обходной DNS не знает домен | Fallback `server=` в `/etc/dnsmasq.d/upstream.conf` |
| Разное поведение на разных подписках | Разные «плохие» хосты | Ожидаемо; outer `timeout` = страховка |

---

## Порядок таймеров

| Время | Что | Зачем |
|---|---|---|
| 03:00 | `dns-benchmark.timer` | Выбирает быстрейший DNS, применяет в `systemd-resolved` |
| 04:00 | `zapret2-list-aggregator.timer` | Обновляет списки `zapr2_hosts_usr.txt` / `zapr2_ips_usr.txt`, перезапускает `zapret2` |
| 06:00 | `vpnsort-daily.timer` | Проверяет подписки, пишет живой список в `YYYYMMDD_subs.txt` |

Порядок важен: DNS уже обновлён к моменту скачивания списков и проверки подписок.
