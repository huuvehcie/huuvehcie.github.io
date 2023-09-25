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

### Beeline проводной интернет

Ресурс | Метод | HTTP | TLS 1.2 | TLS 1.3
 --- | --- | --- | --- | ---
nnmclub | tpws | - | --split-pos=1 | --split-pos=1
nnmclub | nfqws | - | --dpi-desync=fake --dpi-desync-ttl=5 | --dpi-desync=split2 --dpi-desync-split-pos=1
rutracker | tpws | - | --split-pos=1 | --split-pos=2
rutracker | nfqws | - | --dpi-desync=split2 | --dpi-desync=split2
utorrentfilmi | tpws | - | --split-pos=1 | --split-pos=1
utorrentfilmi | nfqws | - | --dpi-desync=split2 | --dpi-desync=split2
novoekino | tpws | --split-pos=1 | --split-pos=2
novoekino | nfqws | --dpi-desync=split2 --dpi-desync-split-pos=1 | --dpi-desync=split2


## Ссылки на конфиги
