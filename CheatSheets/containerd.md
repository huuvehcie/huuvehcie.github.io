# Сжатое руководство по containerd для начинающих

## Содержание
1. [Введение](#введение)
2. [Установка](#установка)
3. [Основные концепции](#основные-концепции)
4. [Управление образами](#управление-образами)
5. [Управление контейнерами](#управление-контейнерами)
6. [Управление задачами](#управление-задачами)
7. [Конфигурация](#конфигурация)
8. [Продвинутые темы](#продвинутые-темы)
9. [Устранение неполадок](#устранение-неполадок)

## Введение

Containerd — контейнерный рантайм для управления жизненным циклом контейнеров (загрузка образов, запуск, мониторинг). Используется в Docker и Kubernetes, фокусируется на простоте и надежности.

| Аспект | Описание |
|--------|----------|
| **Назначение** | Управление образами, контейнерами, задачами. |
| **Особенности** | Пространства имен, плагины, CRI для Kubernetes. |
| **Инструменты** | `ctr` (администрирование), `nerdctl` (удобный CLI). |
| **Влияние** | Минимальное потребление ресурсов, требует прав root. |

**Важно запомнить:** Containerd — системный инструмент, не для конечных пользователей. Используйте `nerdctl` для удобства.

## Установка

| Метод | Команды | Параметры | Ошибки и решения |
|-------|---------|-----------|------------------|
| **Бинарные файлы** | ```bash<br>tar -C /usr/local -xzf containerd-<version>-linux-amd64.tar.gz<br>install -m 755 runc.amd64 /usr/local/sbin/runc<br>tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-<version>.tgz<br>``` | Указать версию | **Ошибка:** `command not found`<br>**Решение:** Добавить `/usr/local/bin` в PATH. |
| **Менеджер пакетов** | ```bash<br>apt-get install -y containerd  # Ubuntu<br>dnf install -y containerd  # Fedora<br>``` | — | **Ошибка:** Отсутствуют CNI плагины<br>**Решение:** Установить вручную. |
| **Проверка** | ```bash<br>systemctl status containerd<br>systemctl start containerd<br>``` | — | **Ошибка:** `Failed to connect`<br>**Решение:** Запустить сервис. |

**Влияние:** Добавляет демон containerd, потребляет минимальные ресурсы.  
**Взаимодействие:** Требует `runc` и CNI для полной функциональности.

## Основные концепции

| Концепция | Описание | Взаимодействие |
|-----------|----------|----------------|
| **Пространства имен** | Изолируют ресурсы (default, k8s.io). | Предотвращают конфликты между контейнерами. |
| **Образы** | Шаблоны для контейнеров. | Используются для создания контейнеров. |
| **Контейнеры** | Экземпляры образов. | Связаны с задачами. |
| **Задачи** | Управляют выполнением контейнеров. | Запускают/останавливают процессы. |
| **Снимки** | Файловая система контейнеров. | Экономят дисковое пространство. |

## Управление образами

| Команда | Назначение | Параметры | Примеры | Ошибки и решения |
|---------|------------|-----------|---------|------------------|
| `ctr images pull <image>` | Загрузка образа | `--platform`, `--user`, `--skip-verify` | ```bash<br># NGINX<br>sudo ctr images pull docker.io/library/nginx:alpine<br># Quay<br>sudo ctr images pull quay.io/quay/busybox:latest<br># ARM64<br>sudo ctr images pull --platform linux/arm64 redis:alpine<br>``` | **Ошибка:** `failed to resolve reference`<br>**Решение:** Проверить ссылку.<br>**Ошибка:** `connection refused`<br>**Решение:** Проверить сеть. |
| `ctr images ls` | Список образов | `--quiet` | ```bash<br>sudo ctr images ls<br>sudo ctr images ls --quiet<br>``` | **Ошибка:** Пустой список<br>**Решение:** Проверить пространство имен. |
| `ctr images rm <image>` | Удаление образа | `--sync` | ```bash<br>sudo ctr images rm nginx:alpine<br>``` | **Ошибка:** `image in use`<br>**Решение:** Удалить контейнеры. |
| `ctr images import <file>` | Импорт образа | `--snapshotter`, `--no-unpack` | ```bash<br>sudo ctr images import nginx.tar<br>``` | **Ошибка:** `invalid tar header`<br>**Решение:** Проверить файл. |
| `ctr images export <file> <image>` | Экспорт образа | `--platform` | ```bash<br>sudo ctr images export nginx.tar nginx:alpine<br>``` | **Ошибка:** `invalid tar header`<br>**Решение:** Проверить файл. |

**Влияние:** Загрузка увеличивает использование диска, удаление освобождает место.  
**Взаимодействие:** Образы используются для контейнеров.  
**Важно запомнить:** Указывайте пространство имен (например, `-n default`).

## Управление контейнерами

| Команда | Назначение | Параметры | Примеры | Ошибки и решения |
|---------|------------|-----------|---------|------------------|
| `ctr run <image> <id>` | Создать и запустить контейнер | `--rm`, `--tty`, `--mount` | ```bash<br># NGINX<br>sudo ctr run --rm nginx:alpine my-nginx<br># С томом<br>sudo ctr run --mount type=bind,src=/data,dst=/usr/share/nginx/html nginx:alpine my-nginx<br># Интерактивный<br>sudo ctr run --tty redis:alpine redis sh<br>``` | **Ошибка:** `image not found`<br>**Решение:** Загрузить образ.<br>**Ошибка:** `permission denied`<br>**Решение:** Использовать `sudo`. |
| `ctr containers create <image> <id>` | Создать контейнер | `--config`, `--env` | ```bash<br>sudo ctr containers create nginx:alpine my-nginx<br>``` | Аналогично `ctr run`. |
| `ctr tasks start <id>` | Запустить задачу | `--detach` | ```bash<br>sudo ctr tasks start my-nginx<br>``` | **Ошибка:** Контейнер не создан<br>**Решение:** Создать контейнер. |
| `ctr containers ls` | Список контейнеров | `--quiet` | ```bash<br>sudo ctr containers ls<br>``` | **Ошибка:** Пустой список<br>**Решение:** Проверить пространство имен. |
| `ctr tasks kill <id>` | Остановить задачу | `--signal` | ```bash<br>sudo ctr tasks kill my-nginx<br>``` | **Ошибка:** Задача не существует<br>**Решение:** Проверить ID. |
| `ctr containers rm <id>` | Удалить контейнер | — | ```bash<br>sudo ctr containers rm my-nginx<br>``` | **Ошибка:** `container in use`<br>**Решение:** Остановить задачу. |

**Влияние:** Запуск контейнеров потребляет CPU/память, удаление освобождает ресурсы.  
**Взаимодействие:** Контейнеры связаны с задачами и снимками.  
**Важно запомнить:** Используйте `create` + `start` для тонкой настройки.

## Управление задачами

| Команда | Назначение | Параметры | Примеры | Ошибки и решения |
|---------|------------|-----------|---------|------------------|
| `ctr tasks ls` | Список задач | `--quiet` | ```bash<br>sudo ctr tasks ls<br>``` | **Ошибка:** Пустой список<br>**Решение:** Проверить запущенные контейнеры. |
| `ctr tasks attach <id>` | Подключение к задаче | `--tty` | ```bash<br>sudo ctr tasks attach my-nginx<br>``` | **Ошибка:** Задача не запущена<br>**Решение:** Запустить задачу. |
| `ctr tasks exec --exec-id <id> <container> <cmd>` | Выполнение команды | `--tty`, `--exec-id` | ```bash<br>sudo ctr tasks exec --exec-id 123 my-nginx /bin/sh<br>``` | **Ошибка:** Контейнер не запущен<br>**Решение:** Запустить задачу. |

**Влияние:** Задачи управляют процессами контейнеров.  
**Взаимодействие:** Связаны с контейнерами.  
**Важно запомнить:** Уникальный `--exec-id` для каждого `exec`.

## Конфигурация

| Аспект | Описание | Пример |
|--------|----------|--------|
| **Файл** | `/etc/containerd/config.toml` | ```bash<br>containerd config default > /etc/containerd/config.toml<br>``` |
| **Параметры** | `root`, `state`, `plugins` (например, CRI) | ```toml<br>[plugins."io.containerd.grpc.v1.cri"]<br>  sandbox_image = "k8s.gcr.io/pause:3.6"<br>  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]<br>    SystemdCgroup = true<br>``` |
| **Ошибки** | **Ошибка:** `invalid configuration`<br>**Решение:** Проверить синтаксис. | — |

**Влияние:** Изменения влияют на поведение containerd (например, поддержка Kubernetes).  
**Взаимодействие:** Плагины определяют функциональность.

## Продвинутые темы

| Тема | Описание | Пример |
|------|----------|--------|
| **Kubernetes** | Поддержка CRI | ```bash<br>--container-runtime=remote --container-runtime-endpoint=unix:///run/containerd/containerd.sock<br>``` |
| **Безопасность** | AppArmor, SELinux | ```bash<br>sudo ctr run --apparmor-profile cri-containerd.apparmor.d nginx:alpine my-nginx<br>``` |
| **Автоматизация** | Скрипты для задач | ```bash<br>#!/bin/bash<br>IMAGE="nginx:alpine"<br>sudo ctr images pull $IMAGE<br>sudo ctr run --rm $IMAGE my-nginx<br>``` |

**Влияние:** Увеличивает функциональность и безопасность.  
**Совместимость:** Основная поддержка — Linux, ограниченная для Windows.

## Устранение неполадок

| Проблема | Решение |
|----------|---------|
| Образ не найден | Проверить ссылку, загрузить образ. |
| Контейнер не запускается | Просмотреть логи: `sudo ctr tasks logs my-nginx`. |
| Отказано в доступе | Использовать `sudo`, проверить права. |
| Проблемы с пространством имен | Указать пространство: `sudo ctr -n k8s.io images ls`. |

**Отладка:** Включить `debug_level = "debug"` в `config.toml`, проверить логи: `journalctl -u containerd`.