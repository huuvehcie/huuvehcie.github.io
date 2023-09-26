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

| Ресурс | HTTP | HTTP | TLS 1.2 | TLS 1.2 | TLS 1.3 | TLS 1.3 |
|---|---|---|---|---|---|---|
|  | tpws | nfqws | tpws | nfqws | tpws | nfqws |
| ej.ru | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | - | - |
| grani.ru | - | - | --split-pos=1 | --dpi-desync=split2 | - | - |
| blackseanews.net | --methodeol | --dpi-desync=disorder2 | --split-pos=2 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| www.kasparov.ru | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| sputnikipogrom.com | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| euroradio.fm | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| 9tv.co.il | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| www.slavicsac.com | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| activatica.org | --methodeol | --dpi-desync=disorder2 | --split-pos=2 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| www.ekhokavkaza.com | --hostcase | --hostspell=hoSt | - | - | --split-pos=1 | --dpi-desync=split2 |
| sobesednik.com | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | - | - |
| zasekin.ru | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=2 | --dpi-desync=split2 |
| www.dw.com | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| echo.msk.ru | --methodeol | --dpi-desync=disorder2 | --split-pos=2 | --dpi-desync=split2 | --split-pos=2 | --dpi-desync=split2 |
| hromadske.ua | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| krymr.com | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| mignews.com | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| zahav.ru | --methodeol | --dpi-desync=disorder2 | --split-pos=1 | --dpi-desync=split2 | --split-pos=1 | --dpi-desync=split2 |
| rus.delfi.lv | --methodeol | --dpi-desync=split | - | --dpi-desync=fake,split2 | --split-pos=1 | --dpi-desync=split2 |
| bihus.info | --methodeol | --dpi-desync=split | - | --dpi-desync=fake,split2 | --split-pos=1 | --dpi-desync=split2 |
| suspilne.media | --methodeol | --dpi-desync=split | - | --dpi-desync=fake,split2 | --split-pos=2 | --dpi-desync=split2 |
| www.hs.fi | --hostdot | --hostnospace | - | --dpi-desync=fake,split2 | --split-pos=1 | --dpi-desync=split2 |
| politiken.dk | --methodeol | --dpi-desync=split | - | --dpi-desync=fake,split2 | --split-pos=2 | --dpi-desync=split2 |
| postimees.ee | --methodeol | --dpi-desync=split | - | --dpi-desync=fake,split2 | --split-pos=2 | --dpi-desync=split2 |
| itsmycity.ru | --methodeol | --dpi-desync=split | - | --dpi-desync=fake,split2 | - | - |


## Ссылки на конфиги
