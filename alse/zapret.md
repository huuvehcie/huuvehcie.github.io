# Инструкция по оптимизации Интернет-протоколов с помощью утилиты Zapret от bol-van

## Установка утилиты

Скачать крайнюю версию репозитория

```
cd ~
git clone https://github.com/bol-van/zapret.git
cd zapret
```
Установить утилиту:

```
sudo bash ~/.install_bin.sh
sudo bash ~/.install_easy.sh
```

_* В процессе установки будут задаваться вопросы. Ответы нужно оставить по умолчанию_

Если потом еужно будет удалить, то надо выполнить:

```
sudo bash ~/uninstall_easy.sh
```

А потом руками зачищать всё со словами "zapret".

## Настройки для различных провайдеров

### BEELINE

#### TPWS

```
TPWS_OPT="	--filter-tcp=80 --hostpad=16384 --hostnospace --hostdot --hostcase --domcase --hosttab --split-pos=method+2,midsld -oob --methodeol <HOSTLIST> --new
			--filter-tcp=443 --split-pos=2,sniext+4,host+1,midsld,endhost-1 --mss=88 --oob --disorder <HOSTLIST>"
```

#### NFQWS

```
NFQWS_OPT="	--filter-tcp=80 --dpi-desync=fake,fakeddisorder,fakedsplit,multidisorder,multisplitsyndata --dpi-desync-ttl=11 --dpi-desync-fooling=md5sig --dpi-desync-split-pos=midsld --dpi-desync-fake-syndata=/opt/zapret/files/fake/http_iana_org.bin --dpi-desync-split-pos=method+2,midsld --dpi-desync-fake-http=0x00000000 <HOSTLIST> --new
			--filter-tcp=443 --dpi-desync=fake,fakeddisorder,fakedsplit,multidisorder,multisplit,syndata --dpi-desync-ttl=7 --dpi-desync-fooling=badseq --dpi-desync-split-pos=10,sniext+4,host+1,midsld-2,midsld,midsld+2,endhost-1 --dpi-desync-fake-syndata=/opt/zapret/files/fake/tls_clienthello_iana_org.bin --wssize 1:06:00 --dpi-desync-split-seqovl=336 --dpi-desync-autottl=5 --dpi-desync-fake-tls=0x00000000 <HOSTLIST> --new
			--filter-udp=443 --dpi-desync-autottl=5 --dpi-desync-fake-http=0x00000000 --dpi-desync-fake-syndata=/opt/zapret/files/fake/tls_clienthello_iana_org.bin --dpi-desync-fake-tls=0x00000000 --dpi-desync-fooling=badseq,badsum,datanoack,md5sig --dpi-desync-ipfrag-pos-udp=64 --dpi-desync-split-pos=10,sniext+4,host+1,midsld-2,midsld,midsld+2,endhost-1 --dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_iana_org.bin --dpi-desync-split-seqovl=336 --dpi-desync-ttl=11 --dpi-desync=fake,fakeddisorder,fakedsplit,multisplit,ipfrag2,syndata <HOSTLIST_NOAUTO>"
```
