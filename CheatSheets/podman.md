## Пример podman-compose файла

```yaml

# Версия спецификации Podman Compose (version)
# Указывает версию формата файла podman-compose.yml.
# Podman Compose использует тот же формат, что и Docker Compose, но с учетом особенностей Podman.
version: '3.8'

# Определяем сервисы (services)
# services — это основной раздел, где описываются контейнеры.
# Каждый сервис представляет собой отдельный контейнер.
services:
  # Первый сервис: web-приложение
  web:
    # Используем базовый образ (image)
    # image указывает, какой образ будет использоваться для контейнера.
    # Можно использовать готовый образ из реестра (например, quay.io или Docker Hub).
    # Пример: image: python:3.9
    image: python:3.9

    # Альтернатива: сборка образа из Dockerfile (build)
    # build указывает путь к Dockerfile для создания образа.
    # context — корневая директория для сборки.
    # dockerfile — имя Dockerfile (по умолчанию "Dockerfile").
    # Пример 1: Сборка из текущей директории
    # build: .
    # Пример 2: Сборка с указанием контекста и Dockerfile
    # build:
    #   context: ./web
    #   dockerfile: Dockerfile.prod

    # Указываем команду для запуска контейнера (command)
    # command заменяет CMD в Dockerfile.
    # Пример 1: Запуск Python-скрипта
    command: python app.py
    # Пример 2: Передача нескольких аргументов
    # command: ["python", "app.py", "--debug"]

    # Публикуем порты (ports)
    # ports связывает порты хостовой системы с портами контейнера.
    # Формат: "хост:контейнер".
    # Пример 1: Открытие порта 8000
    ports:
      - "8000:8000"
    # Пример 2: Открытие нескольких портов
    # ports:
    #   - "8000:8000"
    #   - "8080:80"
    # Пример 3: Только внутренний порт (доступен только внутри сети Podman)
    # ports:
    #   - "8000"

    # Монтируем тома (volumes)
    # volumes позволяют монтировать директории или файлы между хостом и контейнером.
    # Пример 1: Монтирование директории с кодом
    volumes:
      - ./src:/app
    # Пример 2: Монтирование локального файла
    # volumes:
    #   - ./config.json:/app/config.json
    # Пример 3: Монтирование именованного тома
    # volumes:
    #   - data_volume:/data

    # Указываем переменные окружения (environment)
    # environment задает переменные окружения внутри контейнера.
    # Пример 1: Явное указание переменных
    environment:
      APP_ENV: production
      LOG_LEVEL: info
    # Пример 2: Загрузка переменных из файла
    # env_file:
    #   - .env

    # Указываем зависимости (depends_on)
    # depends_on определяет порядок запуска контейнеров.
    # Важно: Это только гарантирует порядок запуска, но не ждет готовности сервисов.
    # Для проверки готовности используйте скрипты или инструменты вроде wait-for-it.sh.
    depends_on:
      - db

    # Задаем метки для контейнера (labels)
    # labels добавляют метаданные к контейнеру.
    # Пример:
    labels:
      com.example.description: "Web application"
      com.example.version: "1.0"

    # Указываем сетевые настройки (networks)
    # networks задает сети, к которым подключается контейнер.
    # Пример:
    networks:
      - app_network

    # Ограничиваем ресурсы (resources)
    # resources позволяет настроить ресурсы для контейнера (например, CPU, память).
    # В отличие от Docker Compose, Podman Compose поддерживает ограничения ресурсов напрямую.
    resources:
      limits:
        cpus: '0.5'
        memory: 512M

  # Второй сервис: база данных
  db:
    # Используем базовый образ PostgreSQL
    image: postgres:13

    # Указываем переменные окружения для PostgreSQL
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb

    # Монтируем том для хранения данных базы данных
    volumes:
      - db_data:/var/lib/postgresql/data

    # Подключаемся к пользовательской сети
    networks:
      - app_network

# Определяем именованные тома (volumes)
# volumes создают именованные тома для хранения данных.
# Пример 1: Создание тома db_data
volumes:
  db_data:
  # Пример 2: Создание дополнительного тома
  data_volume:

# Определяем сети (networks)
# networks создают пользовательские сети для связи контейнеров.
# Пример: Создание сети app_network с драйвером bridge
networks:
  app_network:
    driver: bridge

```
