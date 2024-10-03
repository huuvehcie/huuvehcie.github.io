# Настройки zapret для различных операторов
## Зеркала для скачивания утилиты
https://github.com/bol-van/zapret
## Beeline Санкт-Петербург
### Настройки из blockcheck в режиме quick
```
ipv4 ru.linkedin.com curl_test_http : tpws --split-http-req=method --hostcase --oob
ipv4 ru.linkedin.com curl_test_http : nfqws --dpi-desync=fake --dpi-desync-ttl=9 --dpi-desync-fake-http=0x00000000
ipv4 ru.linkedin.com curl_test_https_tls12 : tpws --split-pos=1 --oob --mss=88
ipv4 ru.linkedin.com curl_test_https_tls12 : nfqws --dpi-desync=disorder2 --wssize 1:6
ipv4 ru.linkedin.com curl_test_https_tls13 : tpws --split-pos=1 --oob
ipv4 ru.linkedin.com curl_test_https_tls13 : nfqws --dpi-desync=disorder2
ipv4 ru.linkedin.com curl_test_http3 : nfqws not working
ipv6 ru.linkedin.com curl_test_http : tpws not working
ipv6 ru.linkedin.com curl_test_http : nfqws not working
ipv6 ru.linkedin.com curl_test_https_tls12 : tpws not working
ipv6 ru.linkedin.com curl_test_https_tls12 : nfqws not working
ipv6 ru.linkedin.com curl_test_https_tls13 : tpws not working
ipv6 ru.linkedin.com curl_test_https_tls13 : nfqws not working
ipv6 ru.linkedin.com curl_test_http3 : nfqws not working
ipv4 www.rutor.is curl_test_http : tpws --split-http-req=method --oob
ipv4 www.rutor.is curl_test_http : nfqws --dpi-desync=fake --dpi-desync-ttl=11 --dpi-desync-fake-http=0x00000000
ipv4 www.rutor.is curl_test_https_tls12 : tpws --split-tls=sni --oob --mss=88
ipv4 www.rutor.is curl_test_https_tls12 : nfqws --dpi-desync=fake,split2 --dpi-desync-ttl=11
ipv4 www.rutor.is curl_test_https_tls13 : tpws --split-tls=sni --oob
ipv4 www.rutor.is curl_test_https_tls13 : nfqws --dpi-desync=disorder2
ipv4 www.rutor.is curl_test_http3 : nfqws not working
ipv6 www.rutor.is curl_test_http : test aborted, no reason to continue. curl code 6: could not resolve host
ipv6 www.rutor.is curl_test_https_tls12 : test aborted, no reason to continue. curl code 6: could not resolve host
ipv6 www.rutor.is curl_test_https_tls13 : test aborted, no reason to continue. curl code 6: could not resolve host
ipv6 www.rutor.is curl_test_http3 : test aborted, no reason to continue. curl code 6: could not resolve host
ipv4 zona.plus curl_test_http : tpws not working
ipv4 zona.plus curl_test_http : nfqws not working
ipv4 zona.plus curl_test_https_tls12 : tpws not working
ipv4 zona.plus curl_test_https_tls12 : nfqws not working
ipv4 zona.plus curl_test_https_tls13 : tpws not working
ipv4 zona.plus curl_test_https_tls13 : nfqws not working
ipv4 zona.plus curl_test_http3 : nfqws not working
ipv6 zona.plus curl_test_http : test aborted, no reason to continue. curl code 6: could not resolve host
ipv6 zona.plus curl_test_https_tls12 : test aborted, no reason to continue. curl code 6: could not resolve host
ipv6 zona.plus curl_test_https_tls13 : test aborted, no reason to continue. curl code 6: could not resolve host
ipv6 zona.plus curl_test_http3 : test aborted, no reason to continue. curl code 6: could not resolve host
ipv4 tapochek.net curl_test_http : working without bypass
ipv4 tapochek.net curl_test_https_tls12 : working without bypass
ipv4 tapochek.net curl_test_https_tls13 : tpws not working
ipv4 tapochek.net curl_test_https_tls13 : nfqws not working
ipv4 tapochek.net curl_test_http3 : nfqws not working
ipv6 tapochek.net curl_test_http : test aborted, no reason to continue. curl code 6: could not resolve host
ipv6 tapochek.net curl_test_https_tls12 : test aborted, no reason to continue. curl code 6: could not resolve host
ipv6 tapochek.net curl_test_https_tls13 : test aborted, no reason to continue. curl code 6: could not resolve host
ipv6 tapochek.net curl_test_http3 : test aborted, no reason to continue. curl code 6: could not resolve host
```
### Установленные в конфиг параметры
```
FWTYPE=iptables

SET_MAXELEM=522288
IPSET_OPT="hashsize 262144 maxelem $SET_MAXELEM"
IP2NET_OPT4="--prefix-length=22-30 --v4-threshold=3/4"
IP2NET_OPT6="--prefix-length=56-64 --v6-threshold=5"

AUTOHOSTLIST_RETRANS_THRESHOLD=3
AUTOHOSTLIST_FAIL_THRESHOLD=3
AUTOHOSTLIST_FAIL_TIME=60
AUTOHOSTLIST_DEBUGLOG=0

MDIG_THREADS=30

GZIP_LISTS=1

MODE=nfqws
MODE_HTTP=1
MODE_HTTP_KEEPALIVE=0
MODE_HTTPS=1
MODE_QUIC=1
MODE_FILTER=ipset

DESYNC_MARK=0x40000000
DESYNC_MARK_POSTNAT=0x20000000
NFQWS_OPT_DESYNC="--dpi-desync=fake --dpi-desync-ttl=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-http=0x00000000"
NFQWS_OPT_DESYNC_SUFFIX="--dpi-desync=fake --dpi-desync-ttl=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-http=0x00000000"
NFQWS_OPT_DESYNC_HTTP="--dpi-desync=fake --dpi-desync-ttl=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-http=0x00000000"
NFQWS_OPT_DESYNC_HTTP_SUFFIX="--dpi-desync=fake --dpi-desync-ttl=11 --dpi-desync-fooling=md5sig --dpi-desync-fake-http=0x00000000"
NFQWS_OPT_DESYNC_HTTPS="--dpi-desync=fake,split2 --dpi-desync-ttl=2 --dpi-desync-split-pos=1 --wssize 1:6"
NFQWS_OPT_DESYNC_HTTPS_SUFFIX="--dpi-desync=fake,split2 --dpi-desync-ttl=2 --dpi-desync-split-pos=1 --wssize 1:6"
NFQWS_OPT_DESYNC_QUIC="--dpi-desync=fake --dpi-desync-repeats=2"
NFQWS_OPT_DESYNC_QUIC_SUFFIX="--dpi-desync=fake --dpi-desync-repeats=2"

TPWS_OPT="--hostspell=HOST --split-http-req=method --split-pos=3 --oob"

INIT_APPLY_FW=1

DISABLE_IPV6=1

GETLIST=get_antifilter_ipsmart.s
```
