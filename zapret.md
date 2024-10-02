# Настройки zapret для различных операторов
## Зеркала для скачивания утилиты
https://github.com/bol-van/zapret
## Beeline Санкт-Петербург
### Настройки из blockcheck
nfqws 	 --dpi-desync=fake --dpi-desync-ttl=9 --dpi-desync-fake-http=0x00000000
nfqws 	 --dpi-desync=disorder2 --wssize 16
nfqws 	 --dpi-desync=disorder2
nfqws 	 --dpi-desync=fake --dpi-desync-ttl=11 --dpi-desync-fake-http=0x00000000
nfqws 	 --dpi-desync=fake,split2 --dpi-desync-ttl=11
nfqws 	 --dpi-desync=disorder2
tpws 	 --split-http-req=method--hostcase--oob
tpws 	 --split-pos=1--oob--mss=88
tpws 	 --split-pos=1--oob
tpws 	 --split-http-req=method--oob
tpws 	 --split-tls=sni--oob--mss=88
tpws 	 --split-tls=sni--oob
### Установленные в конфиг параметры
