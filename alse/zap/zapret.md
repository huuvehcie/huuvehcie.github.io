# Инструкция по оптимизации Интернет-протоколов с помощью утилиты Zapret от bol-van

## Репозиторий

https://github.com/bol-van/zapret

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

#### BuyDPI

```
-Kt,h -d1 -s0+s -d3+s -s6+s -d9+s -s12+s -d15+s -s20+s -d25+s -s30+s -d35+s -An -Ku -a5 -s443+s -d80+s -d443+s -s80+s -s443+s -d53+s -s53+s -d443+s
```

#### TPWS

```
TPWS_OPT="	--filter-tcp=80 --split-pos=method+2 --oob --methodeol <HOSTLIST> --new
			--filter-tcp=443 --split-pos=2,sniext+1,host+1,midsld,endhost-1 --fix-seg --oob --disorder --tlsrec=midsld --mss=88 <HOSTLIST>"
```

#### NFQWS

```
NFQWS_OPT="	--filter-tcp=80 --methodeol --dpi-desync=fake,fakedsplit,fakeddisorder,multisplit,multidisorder,syndata --dpi-desync-ttl=,9 --dpi-desync-autottl=5 --dpi-desync-fooling=md5sig --dpi-desync-split-pos=method+2,midsld --dpi-desync-fake-http=0x00000000 --dpi-desync-fake-syndata=/opt/zapret/files/fake/http_iana_org.bin <HOSTLIST> --new
			--filter-tcp=443 --dpi-desync=fake,fakedsplit,fakeddisorder,multisplit,multidisorder,syndata --dpi-desync-ttl=11 --dpi-desync-autottl=5 --dpi-desync-fooling=badseq,md5sig --dpi-desync-split-pos=10,sniext+4,host+1,midsld-2,midsld,endhost-1 --dpi-desync-split-seqovl=336 --dpi-desync-split-seqovl-pattern=/opt/zapret/files/fake/tls_clienthello_iana_org.bin --dpi-desync-fake-syndata=/opt/zapret/files/fake/tls_clienthello_iana_org.bin --dpi-desync-fake-tls=0x00000000  <HOSTLIST>"
```


### BeeLine для aur.archlinux.org

#### NFQWS

```
NFQWS_OPT="--filter-l7=http --dpi-desync=syndata,multisplit --dpi-desync-split-pos=method+2 --dpi-desync-fake-syndata=/opt/zapret/files/fake/http_iana_org.bin --methodeol <HOSTLIST> --new
--filter-l7=tls --dpi-desync=syndata,multisplit --dpi-desync-fake-syndata=/opt/zapret/files/fake/tls_clienthello_iana_org.bin --dpi-desync-split-pos=1 --wssize1:6 <HOSTLIST>"
```

### FREEDH

#### NFQWS

```
NFQWS_OPT=" --filter-l7=http --dpi-desync-ttl=1 --dpi-desync-split-pos=method+2 --dpi-desync-fake-http=0x00000000 --orig-autottl=+3 --dpi-desync-autottl=-1 --dpi-desync-fooling=md5sig --dup-cutoff=n2 --dup-fooling=md5sig --dup=1 --dpi-desync-fake-syndata=/opt/zapret/files/fake/http_iana_org.bin --hostspell=host <HOSTLIST> --new
			--filter-l7=tls --dpi-desync-ttl=1 --dpi-desync-fake-tls=0x00000000 --dpi-desync-split-pos=midsld --dpi-desync=fake,multisplit --dpi-desync-fake-tls-mod=rnd,dupsid,rndsni,padencap --orig-autottl=+3 --dup-cutoff=n2 --dup-fooling=md5sig --dup=1 --dpi-desync-fooling=badsum --dpi-desync-split-seqovl=1 --dpi-desync-fake-syndata=/opt/zapret/files/fake/tls_clienthello_iana_org.bin <HOSTLIST> --new
			--filter-l7=quic --dpi-desync-ipfrag-pos-udp=64 --dpi-desync-repeats=20 --dpi-desync=fake <HOSTLIST>"
```

#### TPWS

```
TPWS_OPT="	--filter-tcp=80 --hostpad=16384 --hostcase --fix-seg --split-pos=method+2,midsld --disorder --oob <HOSTLIST> --new
 			--filter-tcp=443 --tlsrec=sniext+4 --fix-seg --split-pos=midsld --disorder --mss=88 --oob <HOSTLIST>"
```
