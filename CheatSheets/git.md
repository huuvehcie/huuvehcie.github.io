| Операция | Команда | Описание |
|----------|---------|----------|
| Инициализация репозитория | `git init` | Создает новый локальный Git-репозиторий (инициализирует пустой репозиторий в текущей директории, создавая скрытую папку .git для хранения метаданных) |
| Клонирование репозитория | `git clone <url>` | Копирует удаленный репозиторий на локальную машину (создает локальную копию проекта, включая всю историю изменений) |
| Проверка статуса | `git status` | Показывает состояние файлов в рабочей директории и индексе (отображает измененные, добавленные и удаленные файлы, а также файлы, не отслеживаемые Git) |
| Добавление файлов в индекс | `git add <file>` | Добавляет изменения в файле в индекс для следующего коммита (подготавливает указанный файл к коммиту, перемещая его из рабочей директории в область подготовки) |
| Добавление всех изменений | `git add .` | Добавляет все изменения в текущей директории в индекс (подготавливает все измененные и новые файлы к коммиту) |
| Создание коммита | `git commit -m "message"` | Создает новый коммит с добавленными изменениями (сохраняет подготовленные изменения в истории репозитория с описательным сообщением) |
| Просмотр истории коммитов | `git log` | Показывает историю коммитов (отображает список всех коммитов в обратном хронологическом порядке с хешами, авторами, датами и сообщениями) |
| Создание новой ветки | `git branch <branch-name>` | Создает новую ветку (создает новую линию разработки, не переключаясь на нее) |
| Переключение между ветками | `git checkout <branch-name>` | Переключается на указанную ветку (меняет текущую рабочую ветку, обновляя файлы в рабочей директории) |
| Создание и переключение на новую ветку | `git checkout -b <branch-name>` | Создает новую ветку и сразу переключается на нее (комбинация команд branch и checkout) |
| Слияние веток | `git merge <branch-name>` | Сливает указанную ветку в текущую (объединяет изменения из указанной ветки в активную ветку) |
| Загрузка изменений с удаленного репозитория | `git pull` | Получает изменения с удаленного репозитория и сливает их с текущей веткой (комбинация fetch и merge) |
| Отправка изменений в удаленный репозиторий | `git push` | Отправляет локальные изменения в удаленный репозиторий (загружает коммиты из локальной ветки в соответствующую удаленную ветку) |
| Просмотр различий | `git diff` | Показывает различия между рабочей директорией и индексом (отображает изменения, которые еще не были подготовлены к коммиту) |
| Отмена изменений в рабочей директории | `git checkout -- <file>` | Отменяет изменения в указанном файле (возвращает файл к состоянию последнего коммита)
| Просмотр истории определенного файла | `git log --follow <file>` | Показывает историю коммитов для конкретного файла (включая переименования) |
| Сравнение веток | `git diff <branch1> <branch2>` | Показывает различия между двумя ветками |
| Отмена коммита с созданием нового | `git revert <commit-hash>` | Создает новый коммит, отменяющий изменения указанного коммита |
| Временное сохранение изменений | `git stash` | Сохраняет текущие изменения во временное хранилище и очищает рабочую директорию |
| Применение сохраненных изменений | `git stash pop` | Применяет последние сохраненные изменения из stash и удаляет их из хранилища |
| Интерактивное добавление частей файлов | `git add -p` | Позволяет выборочно добавлять части изменений в файлах |
| Просмотр удаленных веток | `git branch -r` | Показывает список удаленных веток |
| Удаление ветки | `git branch -d <branch-name>` | Удаляет указанную ветку (если она была слита) |
| Принудительное удаление ветки | `git branch -D <branch-name>` | Удаляет указанную ветку, даже если она не была слита |
| Очистка неотслеживаемых файлов | `git clean -f` | Удаляет неотслеживаемые файлы из рабочей директории |