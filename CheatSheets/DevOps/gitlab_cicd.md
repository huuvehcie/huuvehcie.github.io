# GitLab/GitHub

- [Введение](#введение)
  - [Основные компоненты GitLab CI/CD](#основные-компоненты-gitlab-cicd)
  - [Основные термины GitLab CI/CD](#основные-термины-gitlab-cicd)
  - [Основные операции GitLab CI/CD](#основные-операции-gitlab-cicd)
- [Руководство по настройке и запуску CI/CD pipeline](#руководство-по-настройке-и-запуску-cicd-pipeline)
  - [1. Основы CI/CD pipeline](#1-основы-cicd-pipeline)
  - [2. Настройка pipeline](#2-настройка-pipeline)
  - [3. Выполнение задач](#3-выполнение-задач)
  - [4. Продвинутые сценарии](#4-продвинутые-сценарии)
  - [5. Совместимость и оптимизация](#5-совместимость-и-оптимизация)

---

## Введение

### Основные компоненты GitLab CI/CD:

| Компонент | Описание |
| --- | --- |
| GitLab Runner | GitLab Runner - это приложение, которое выполняет задачи, определенные в файле `.gitlab-ci.yml`. Оно может быть запущено на хосте или в контейнере и отвечает за выполнение заданий сборки, тестирования и развертывания. |
| Файл `.gitlab-ci.yml` | Файл конфигурации GitLab CI/CD, который определяет этапы, задания и правила выполнения для процесса непрерывной интеграции и доставки. |
| Стадии (Stages) | Стадии представляют собой последовательность шагов в пайплайне GitLab CI/CD, таких как сборка, тестирование, развертывание и т.д. |
| Задания (Jobs) | Задания - это отдельные задачи, выполняемые во время стадии. Они могут включать компиляцию кода, запуск тестов, развертывание приложений и другие операции. |
| Артефакты (Artifacts) | Артефакты - это файлы, созданные во время выполнения задания, которые могут быть сохранены и использованы в последующих стадиях или для диагностики. |
| Переменные (Variables) | Переменные позволяют хранить конфиденциальную информацию и настраивать поведение заданий. Они могут быть определены на уровне проекта, группы или среды выполнения. |
| Окружения (Environments) | Окружения представляют различные среды развертывания, такие как тестирование, подготовка и производство. Они позволяют управлять развертыванием приложений в разных средах. |

### Основные термины GitLab CI/CD:

| Термин | Описание |
| --- | --- |
| Непрерывная интеграция (Continuous Integration - CI) | Практика объединения изменений в коде разработчиков в общую ветку несколько раз в день, обеспечивая раннее обнаружение проблем и конфликтов. |
| Непрерывная доставка (Continuous Delivery - CD) | Расширение CI, включающее автоматизацию процесса развертывания приложений в различных средах, обеспечивая быструю и надежную доставку программного обеспечения. |
| Непрерывное развертывание (Continuous Deployment) | Автоматизация полного процесса выпуска программного обеспечения, включая автоматическое развертывание в производственной среде при успешном прохождении тестов. |
| Пайплайн (Pipeline) | Последовательность стадий и заданий, определяющая процесс CI/CD. Пайплайн может быть визуализирован и отслеживаться в GitLab. |
| Артефактный репозиторий (Artifact Repository) | Хранилище для хранения и управления артефактами сборки, позволяющее легко получать доступ к предыдущим версиям и артефактам. |
| CI/CD Runner | Приложение, которое выполняет задания, определенные в файле `.gitlab-ci.yml`. Оно может быть запущено на хосте или в контейнере. |

### Основные операции GitLab CI/CD:

| Операция | Описание |
| --- | --- |
| Создание файла `.gitlab-ci.yml` | Создание файла конфигурации GitLab CI/CD, определяющего стадии, задания и правила выполнения. |
| Запуск пайплайна | Запуск пайплайна вручную или по триггеру, например, при изменении кода в репозитории. |
| Просмотр журнала пайплайна | Просмотр журнала предыдущих выполнений пайплайна, включая статус, длительность и результаты заданий. |
| Управление раннерами | Добавление, удаление и настройка раннеров для выполнения заданий. |
| Управление окружениями | Создание и настройка окружений для развертывания приложений в различных средах. |
| Управление переменными | Определение и настройка переменных на уровне проекта, группы или среды выполнения. |
| Отображение артефактов | Просмотр и скачивание артефактов, созданных во время выполнения заданий. |
| Управление плагинами | Установка и настройка плагинов GitLab для расширения функциональности CI/CD. |

## Руководство по настройке и запуску CI/CD pipeline

Компактное руководство для начинающих по настройке и использованию CI/CD pipeline в GitLab и GitHub с акцентом на табличное представление и развернутые пояснения к каждому разделу.

### 1. Основы CI/CD pipeline

CI/CD (Continuous Integration/Continuous Deployment) представляет собой автоматизированный процесс, который позволяет разработчикам интегрировать изменения в код, тестировать их и развертывать в продакшен с минимальными усилиями. В GitLab и GitHub pipeline настраивается с помощью конфигурационных файлов в формате YAML, которые определяют, какие действия должны выполняться при наступлении определенных событий, таких как коммит или запрос на включение изменений. В GitLab используется файл `.gitlab-ci.yml`, размещаемый в корне репозитория, который задает стадии, задачи и их зависимости. GitHub, в свою очередь, использует файлы в директории `.github/workflows/`, где каждый файл описывает отдельный workflow с указанием событий, запускающих его, и выполняемых шагов. Эти файлы являются сердцем CI/CD, обеспечивая автоматизацию процессов, что особенно важно для команд, стремящихся к быстрой и надежной доставке кода. Таблица ниже служит отправной точкой для понимания базовых элементов CI/CD, их назначения и способов настройки. Она будет полезна при создании первых pipeline, помогая новичкам быстро освоить ключевые концепции и начать применять их в реальных проектах. Далее в руководстве эта таблица станет основой для более сложных сценариев, таких как настройка окружений и интеграция с внешними сервисами.

| Команда/Элемент | Назначение | Параметры | Примеры | Ошибки и решения | Влияние | Взаимодействие |
|-----------------|------------|-----------|---------|------------------|---------|----------------|
| `.gitlab-ci.yml` / `.github/workflows/*.yml` | Определяет pipeline | Ключи: `stages`, `jobs`, `steps`, `runs-on` | ```yaml<br># GitLab: Тест и сборка<br>stages:<br>  - test<br>job1:<br>  stage: test<br>  script:<br>    - echo "Running tests"<br>```<br>```yaml<br># GitHub: Тест<br>name: CI<br>on: [push]<br>jobs:<br>  test:<br>    runs-on: ubuntu-latest<br>    steps:<br>      - run: echo "Testing"<br>``` | **Ошибка**: Неправильный синтаксис YAML<br>**Решение**: Проверить отступы (2 пробела), использовать валидаторы YAML<br>**Ошибка**: Отсутствие прав<br>**Решение**: Проверить доступ к репозиторию | Запускает pipeline при событиях (push, merge) | Связан с runners (GitLab) или actions (GitHub) |
| `stages` (GitLab) | Группирует задачи | Список: `- <имя>` | ```yaml<br>stages:<br>  - build<br>  - test<br>  - deploy<br>``` | **Ошибка**: Дублирование имен<br>**Решение**: Уникальные имена стадий | Определяет порядок выполнения | Влияет на `jobs` |
| `jobs` (GitLab) / `jobs` (GitHub) | Определяет задачи | `stage`, `script`, `runs-on`, `steps` | ```yaml<br># GitLab<br>build_job:<br>  stage: build<br>  script:<br>    - npm install<br>```<br>```yaml<br># GitHub<br>jobs:<br>  build:<br>    runs-on: ubuntu-latest<br>    steps:<br>      - run: npm install<br>``` | **Ошибка**: Отсутствие runner<br>**Решение**: Настроить runner в GitLab или выбрать `runs-on` | Выполняет команды | Зависит от `stages` и runner |

**Важно запомнить**:  
- GitLab: pipeline запускается автоматически при наличии `.gitlab-ci.yml`.  
- GitHub: требует `.github/workflows/*.yml` и событие (`on`).

### 2. Настройка pipeline

Настройка pipeline — это процесс, который определяет, как и где будут выполняться задачи, какие события их запускают, и какие зависимости необходимы для их работы. В GitLab настройка начинается с выбора или регистрации runner’ов — серверов, которые выполняют задачи pipeline. Runner’ы могут быть общими, групповыми или специфичными для проекта, и их правильная конфигурация критически важна для стабильной работы CI/CD. GitHub использует виртуальные машины, управляемые через параметр `runs-on`, что упрощает настройку, но требует понимания доступных окружений, таких как `ubuntu-latest` или `windows-latest`. Кроме того, оба сервиса позволяют задавать события, которые инициируют запуск pipeline, например, коммит в ветку или создание pull request. Эти настройки напрямую влияют на гибкость и производительность pipeline, позволяя адаптировать процесс под конкретные нужды проекта, будь то тестирование, развертывание или интеграция с внешними сервисами. Таблица ниже детализирует ключевые элементы настройки, предоставляя примеры и решения типичных проблем. Она станет основой для последующих разделов, где будут рассмотрены более сложные сценарии, такие как управление зависимостями и оптимизация производительности, а также поможет новичкам быстро настроить базовый pipeline и избежать распространенных ошибок.

| Команда/Элемент | Назначение | Параметры | Примеры | Ошибки и решения | Влияние | Взаимодействие |
|-----------------|------------|-----------|---------|------------------|---------|----------------|
| `runners` (GitLab) | Выполняет задачи | Shared, Group, Specific | ```yaml<br># GitLab: Указание тега<br>job1:<br>  tags:<br>    - docker<br>  script:<br>    - echo "Run on docker"<br>``` | **Ошибка**: Runner не найден<br>**Решение**: Зарегистрировать runner (`gitlab-runner register`)<br>**Ошибка**: Нет тегов<br>**Решение**: Добавить теги в настройках runner | Определяет, где выполняется job | Связан с тегами и `.gitlab-ci.yml` |
| `runs-on` (GitHub) | Указывает ОС/окружение | `ubuntu-latest`, `windows-latest`, `macos-latest` | ```yaml<br>jobs:<br>  test:<br>    runs-on: ubuntu-latest<br>    steps:<br>      - run: npm test<br>``` | **Ошибка**: Неверная ОС<br>**Решение**: Проверить список доступных `runs-on` | Определяет окружение | Влияет на доступные команды |
| `on` (GitHub) | Указывает событие | `push`, `pull_request`, `schedule` | ```yaml<br>on:<br>  push:<br>    branches:<br>      - main<br>```<br>```yaml<br>on:<br>  schedule:<br>    - cron: '0 0 * * *'<br>``` | **Ошибка**: Pipeline не запускается<br>**Решение**: Проверить ветку/событие | Запускает workflow | Влияет на `jobs` |

**Типичные ошибки**:  
- GitLab: Незарегистрированный runner → зарегистрировать через `gitlab-runner register`.  
- GitHub: Неправильный `runs-on` → использовать только поддерживаемые значения.

### 3. Выполнение задач

Выполнение задач — это ядро любого CI/CD pipeline, где определяются конкретные действия, такие как запуск тестов, сборка приложения или развертывание на сервер. В GitLab задачи описываются в секции `script`, которая содержит список команд, выполняемых последовательно на runner’е. GitHub использует более гибкую структуру `steps`, где каждый шаг может быть либо выполнением команды (`run`), либо использованием готовых действий (`uses`), таких как `actions/checkout` для получения кода. Оба подхода позволяют автоматизировать сложные процессы, но требуют внимания к правильной настройке окружения, установке зависимостей и управлению результатами выполнения. Например, в GitLab можно сохранять файлы между задачами с помощью `artifacts`, а в GitHub — использовать действия для загрузки артефактов. Эти механизмы делают pipeline мощным инструментом для автоматизации, но также требуют понимания, как управлять зависимостями и обрабатывать ошибки. Таблица ниже предоставляет подробное описание элементов, необходимых для выполнения задач, с примерами и решениями проблем. Она будет полезна для настройки типичных сценариев, таких как тестирование или сборка, и станет основой для продвинутых функций, таких как кэширование и интеграция с внешними системами, которые будут рассмотрены далее.

| Команда/Элемент | Назначение | Параметры | Примеры | Ошибки и решения | Влияние | Взаимодействие |
|-----------------|------------|-----------|---------|------------------|---------|----------------|
| `script` (GitLab) | Выполняет команды | Список команд | ```yaml<br>job1:<br>  script:<br>    - npm install<br>    - npm test<br>``` | **Ошибка**: Команда не найдена<br>**Решение**: Установить зависимости (`apt-get`, `npm`)<br>**Ошибка**: Выход с ошибкой<br>**Решение**: Проверить код возврата | Выполняет задачи | Зависит от runner |
| `steps` (GitHub) | Определяет шаги | `run`, `uses` | ```yaml<br>jobs:<br>  test:<br>    steps:<br>      - uses: actions/checkout@v3<br>      - run: npm install<br>``` | **Ошибка**: Action не найден<br>**Решение**: Проверить версию (`@v3`) | Выполняет шаги | Связан с `actions` |
| `artifacts` (GitLab) | Сохраняет файлы | `paths`, `expire_in` | ```yaml<br>job1:<br>  artifacts:<br>    paths:<br>      - dist/<br>    expire_in: 1 week<br>``` | **Ошибка**: Файл не найден<br>**Решение**: Проверить путь | Сохраняет результаты | Используется в других jobs |

**Важно запомнить**:  
- GitLab: `artifacts` сохраняют файлы между jobs.  
- GitHub: Используйте `actions/upload-artifact` для сохранения файлов.

### 4. Продвинутые сценарии

Продвинутые сценарии CI/CD выходят за рамки базовых задач, таких как тестирование и сборка, и включают сложные процессы, такие как интеграция с внешними сервисами, управление секретами и автоматизация развертывания. В GitLab переменные (`variables`) и зависимости (`needs`) позволяют гибко управлять конфигурацией и порядком выполнения задач, что особенно полезно в крупных проектах с множеством связанных компонентов. GitHub предлагает аналогичные возможности через секреты (`secrets`) и действия, которые упрощают интеграцию с облачными сервисами, такими как AWS или Docker Hub. Безопасность играет ключевую роль в этих сценариях, так как неправильное управление секретами может привести к утечке данных. Кроме того, продвинутые pipeline часто включают автоматизацию, например, запуск задач по расписанию или динамическое создание окружений. Эти возможности делают CI/CD мощным инструментом для DevOps, но требуют глубокого понимания конфигурации и потенциальных рисков. Таблица ниже описывает ключевые элементы продвинутых сценариев, предоставляя примеры и решения типичных проблем. Она будет полезна для опытных пользователей, стремящихся оптимизировать pipeline, и станет основой для дальнейшего изучения сложных интеграций и автоматизации.

| Команда/Элемент | Назначение | Параметры | Примеры | Ошибки и решения | Влияние | Взаимодействие |
|-----------------|------------|-----------|---------|------------------|---------|----------------|
| `variables` (GitLab) | Определяет переменные | Глобальные, job-специфичные | ```yaml<br>variables:<br>  API_TOKEN: $CI_API_TOKEN<br>job1:<br>  script:<br>    - echo $API_TOKEN<br>``` | **Ошибка**: Переменная не найдена<br>**Решение**: Задать в настройках CI/CD | Передает данные | Используется в `script` |
| `secrets` (GitHub) | Хранит секреты | Имя секрета | ```yaml<br>jobs:<br>  deploy:<br>    steps:<br>      - run: echo ${{ secrets.API_KEY }}<br>``` | **Ошибка**: Секрет недоступен<br>**Решение**: Добавить в настройки репозитория | Обеспечивает безопасность | Используется в `steps` |
| `needs` (GitLab) | Зависимости jobs | Список jobs | ```yaml<br>job2:<br>  needs:<br>    - job1<br>  script:<br>    - echo "After job1"<br>``` | **Ошибка**: Job не выполнена<br>**Решение**: Проверить статус `job1` | Управляет порядком | Влияет на pipeline |

**Типичные ошибки**:  
- Неправильное использование секретов → проверить настройки репозитория.  
- Циклические зависимости в `needs` → пересмотреть структуру pipeline.

### 5. Совместимость и оптимизация

Совместимость и оптимизация pipeline критически важны для обеспечения его стабильной работы в разных окружениях и повышения производительности. GitLab и GitHub поддерживают выполнение pipeline на различных операционных системах, таких как Linux, Windows и macOS, но каждая из них имеет свои особенности, например, различия в доступных командах или способах установки зависимостей. Это требует тщательного тестирования pipeline на всех целевых платформах, чтобы избежать ошибок, связанных с несовместимостью. Оптимизация, в свою очередь, достигается за счет кэширования зависимостей, минимизации количества шагов и правильной настройки runner’ов или виртуальных машин. Например, кэширование позволяет сократить время выполнения задач, сохраняя зависимости, такие как `node_modules`, между запусками. Эти техники особенно важны в крупных проектах, где время выполнения pipeline напрямую влияет на скорость доставки кода. Таблица ниже детализирует элементы, связанные с совместимостью и оптимизацией, с примерами и решениями проблем. Она будет полезна для настройки кроссплатформенных pipeline и оптимизации их производительности, а также станет основой для дальнейшего изучения сложных сценариев, таких как масштабирование CI/CD в больших командах.

| Элемент | Назначение | Особенности | Примеры | Ошибки и решения | Влияние | Взаимодействие |
|---------|------------|-------------|---------|------------------|---------|----------------|
| ОС (Linux/Windows/Mac) | Выполнение pipeline | Linux: `ubuntu-latest`<br>Windows: `windows-latest` | ```yaml<br># GitHub: Windows<br>jobs:<br>  test:<br>    runs-on: windows-latest<br>    steps:<br>      - run: dir<br>``` | **Ошибка**: Команда не поддерживается<br>**Решение**: Использовать кроссплатформенные команды | Определяет доступные команды | Влияет на `script`/`steps` |
| Кэширование | Ускоряет pipeline | `cache` (GitLab), `actions/cache` (GitHub) | ```yaml<br># GitLab<br>cache:<br>  paths:<br>    - node_modules/<br>```<br>```yaml<br># GitHub<br>steps:<br>  - uses: actions/cache@v3<br>    with:<br>      path: node_modules<br>      key: ${{ runner.os }}-node<br>``` | **Ошибка**: Кэш не работает<br>**Решение**: Проверить ключ кэша | Ускоряет выполнение | Зависит от runner |

**Рекомендации**:  
- Используйте кэширование для зависимостей.  
- Тестируйте pipeline на всех целевых ОС.
