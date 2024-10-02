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
