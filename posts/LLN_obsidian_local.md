## Локальный AI-ассистент в Obsidian на Apple Silicon (MLX)

Эта инструкция описывает настройку полностью локального AI-помощника для Obsidian с использованием MLX (Apple Machine Learning) на Mac с чипом M5.
Никакого Docker, npm, Ollama или платных подписок. Только изолированные Python-пакеты и нативные приложения.

**Что получится в итоге:**
- Obsidian Copilot общается с вами, анализируя все заметки (транскрипции встреч).
- Чат-модель `Qwen2.5 14B` работает быстро благодаря GPU (Metal) и частично Neural Engine.
- Эмбеддинг-модель `bge-m3` обеспечивает точный семантический поиск по хранилищу.
- Управление серверами через простые алиасы в терминале.

---

### 1. Подготовка заметок (метаданные)

Чтобы Copilot понимал даты и проекты, в начало каждого файла встречи нужно добавить читаемый блок вместо стандартного YAML. У вас уже есть файлы в папке `~/Work/Obsidian/Work/Meetings`. Если вы ещё не преобразовывали их, выполните скрипт ниже. Если уже преобразовали — пропустите этот шаг.

Скрипт заменит YAML-фронтматтер вида:

```
---
date: 2025-10-24
display_date: 24 октября 2025 г.
project: BVP
filename: 20251024_ОТК_BVP.md
---
```

на читаемый текст:

```
Дата совещания: 24 октября 2025 г.
Совещание по проекту: BVP
Имя файла в дереве Obsidian: 20251024_ОТК_BVP.md

```

**Скрипт конвертации** (сохраните как `convert.sh` в корне хранилища):

```zsh
#!/bin/zsh
VAULT_PATH="$HOME/Work/Obsidian/Work"
MEETINGS_DIR="$VAULT_PATH/Meetings"
LOG_FILE="$VAULT_PATH/.convert_frontmatter.log"

echo "===== $(date '+%Y-%m-%d %H:%M:%S') =====" > "$LOG_FILE"

if [[ ! -d "$MEETINGS_DIR" ]]; then
    echo "[ОШИБКА] Папка Meetings не найдена: $MEETINGS_DIR" >> "$LOG_FILE"
    exit 1
fi

setopt GLOBSTARSHORT 2>/dev/null || setopt GLOBSTARS 2>/dev/null

count_total=0
count_converted=0
count_skipped=0

for filepath in "$MEETINGS_DIR"/**/*.md; do
    [[ ! -f "$filepath" ]] && continue
    ((count_total++))

    read -r first_line < "$filepath"
    if [[ "$first_line" != "---" ]]; then
        ((count_skipped++))
        continue
    fi

    lines=("${(@f)$(<"$filepath")}")
    closing_index=-1
    for ((i=2; i<=${#lines}; i++)); do
        if [[ "${lines[$i]}" == "---" ]]; then
            closing_index=$i
            break
        fi
    done

    if [[ $closing_index -eq -1 ]]; then
        echo "  [ПРОПУЩЕНО] $filepath - нет закрывающего ---" >> "$LOG_FILE"
        ((count_skipped++))
        continue
    fi

    date_field=""; display_date=""; project=""; filename=""
    for ((j=2; j<closing_index; j++)); do
        line="${lines[$j]}"
        case "$line" in
            date:\ *) date_field="${line#date: }" ;;
            display_date:\ *) display_date="${line#display_date: }" ;;
            project:\ *) project="${line#project: }" ;;
            filename:\ *) filename="${line#filename: }" ;;
        esac
    done

    if [[ -z "$display_date" && -n "$date_field" ]]; then
        y="${date_field:0:4}"; m="${date_field:5:2}"; d="${date_field:8:2}"
        case $m in
            01) month="января";; 02) month="февраля";; 03) month="марта";;
            04) month="апреля";; 05) month="мая";; 06) month="июня";;
            07) month="июля";; 08) month="августа";; 09) month="сентября";;
            10) month="октября";; 11) month="ноября";; 12) month="декабря";;
        esac
        display_date="$d $month $y г."
    fi

    if [[ -z "$display_date" && -z "$project" && -z "$filename" ]]; then
        echo "  [ПРОПУЩЕНО] $filepath - нет данных для замены" >> "$LOG_FILE"
        ((count_skipped++))
        continue
    fi

    new_header=""
    [[ -n "$display_date" ]] && new_header+="Дата совещания: $display_date"$'\n'
    [[ -n "$project" ]] && new_header+="Совещание по проекту: $project"$'\n'
    [[ -n "$filename" ]] && new_header+="Имя файла в дереве Obsidian: $filename"$'\n'
    new_header="${new_header%$'\n'}"

    rest=""
    for ((k=closing_index+1; k<=${#lines}; k++)); do
        rest+="${lines[$k]}"$'\n'
    done

    {
        printf '%s\n\n\n' "$new_header"
        printf '%s' "$rest"
    } > "$filepath"

    echo "  [OK] $filepath" >> "$LOG_FILE"
    ((count_converted++))
done

echo "" >> "$LOG_FILE"
echo "Всего файлов: $count_total" >> "$LOG_FILE"
echo "Конвертировано: $count_converted" >> "$LOG_FILE"
echo "Пропущено: $count_skipped" >> "$LOG_FILE"
echo "Готово." >> "$LOG_FILE"
```

Сделайте исполняемым и запустите:
```bash
chmod +x ~/Work/Obsidian/Work/convert.sh
cd ~/Work/Obsidian/Work && ./convert.sh
cat .convert_frontmatter.log
```

---

### 2. Установка MLX (изолированно через pipx)

Убедитесь, что Homebrew установлен. Если нет:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Установите pipx:
```bash
brew install pipx
pipx ensurepath
```
**Перезапустите терминал** или выполните `source ~/.zshrc`.

Установите `mlx-lm` в изолированное окружение:
```bash
pipx install mlx-lm
```

Загрузите модели (чат и эмбеддинги):
```bash
mlx_lm.download --model mlx-community/Qwen2.5-14B-Instruct-4bit
mlx_lm.download --model mlx-community/bge-m3
```
Модели (~9 ГБ и ~1.5 ГБ) сохранятся в `~/.cache/huggingface/`.

---

### 3. Запуск серверов через tmux с алиасами

Установите tmux:
```bash
brew install tmux
```

Добавьте в `~/.zshrc` алиасы:
```bash
alias mlx-chat-start='tmux new-session -d -s mlx-chat "mlx_lm.server --model mlx-community/Qwen2.5-14B-Instruct-4bit --host 0.0.0.0 --port 8080" && echo "Chat server started on :8080"'
alias mlx-emb-start='tmux new-session -d -s mlx-emb "mlx_lm.server --model mlx-community/bge-m3 --host 0.0.0.0 --port 8081" && echo "Embedding server started on :8081"'
alias mlx-start='mlx-chat-start && mlx-emb-start'
alias mlx-stop='tmux kill-session -t mlx-chat 2>/dev/null; tmux kill-session -t mlx-emb 2>/dev/null; echo "All MLX servers stopped"'
alias mlx-chat-log='tmux attach -t mlx-chat'
alias mlx-emb-log='tmux attach -t mlx-emb'
```

Примените:
```bash
source ~/.zshrc
```

Запустите оба сервера:
```bash
mlx-start
```

Проверьте:
```bash
curl http://localhost:8080/v1/models   # чат-модель
curl http://localhost:8081/v1/models   # эмбеддинг-модель
```

Логи при необходимости:
- `mlx-chat-log` → выход `Ctrl+B, D`
- `mlx-emb-log`

Остановка серверов: `mlx-stop`

---

### 4. Настройка Copilot в Obsidian

1. Убедитесь, что плагин Copilot установлен (автор Logan Yang).
2. Откройте Настройки → Сторонние плагины → Copilot → шестерёнка.
3. Настройте **Chat Model**:
   - Provider: `OpenAI`
   - Base URL: `http://localhost:8080/v1`
   - API Key: `no-key`
   - Model: нажмите Refresh и выберите `mlx-community/Qwen2.5-14B-Instruct-4bit`
4. Настройте **Embedding Model**:
   - Provider: `OpenAI`
   - Base URL: `http://localhost:8081/v1`
   - API Key: `no-key`
   - Model: `mlx-community/bge-m3`
5. В разделе **Semantic Search & Indexing**:
   - Включите `Enable Semantic Search`
   - `Auto-Index Strategy` → `ON FILE CHANGE`
   - `Max Sources` = 15 (для быстрых ответов)
   - `Embedding Batch Size` = 32 (можно увеличить до 64, если всё стабильно)
   - `Requests per Minute` = 120 (локальный сервер, можно смело)
6. Сохраните настройки.

---

### 5. Индексация хранилища

Выполните `Cmd+P` → **Copilot: Force Reindex Vault**. Дождитесь завершения (прогресс в строке состояния). Первая индексация займёт 10–20 минут для 1800+ файлов. В дальнейшем новые заметки будут подхватываться автоматически.

---

### 6. Удаление Ollama (опционально)

Если вы больше не планируете использовать Ollama, полностью удалите её:

1. Закройте приложение Ollama (иконка в строке меню → Quit).
2. Выполните:
```bash
rm -rf /Applications/Ollama.app
rm -rf ~/.ollama
```
Больше она не нужна.

---

### 7. Использование

- Откройте панель чата: `Cmd+P` → **Copilot: Open Chat**.
- Задавайте вопросы, например:
  - «Что обсуждалось на совещании 27 июля 2026 года по проекту BVP?»
  - «Какие задачи были поставлены на последней встрече с Фобосом?»
  - «Сделай сводку по всем встречам за июль 2026»
- Модель будет анализировать ваши транскрипции и давать ответы. Первый ответ после старта серверов может занять 20–40 секунд, последующие — быстрее.
- Для повышения точности поиска в запросах используйте полные даты и названия проектов (как в читаемом блоке файлов).

**Управление серверами:**
- После перезагрузки Mac: `mlx-start`
- Перед сном: `mlx-stop` (освободит ~15 ГБ памяти)

---

### 8. Автозапуск MLX-серверов при входе в систему (по желанию)

Создайте launchd-файл `~/Library/LaunchAgents/com.mlx.all.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mlx.all</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>-c</string>
        <string>/Users/$(whoami)/.local/bin/mlx_lm.server --model mlx-community/Qwen2.5-14B-Instruct-4bit --host 0.0.0.0 --port 8080 &amp; /Users/$(whoami)/.local/bin/mlx_lm.server --model mlx-community/bge-m3 --host 0.0.0.0 --port 8081 &amp; wait</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/mlx_all.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/mlx_all.err</string>
</dict>
</plist>
```

Загрузите:
```bash
launchctl load ~/Library/LaunchAgents/com.mlx.all.plist
```

Теперь серверы будут запускаться автоматически при входе в систему. Чтобы отключить: `launchctl unload ~/Library/LaunchAgents/com.mlx.all.plist`.

---

### Возможные проблемы и решения

**Сервер эмбеддингов падает при индексации:**
- Уменьшите `Embedding Batch Size` до 16 или 8 в настройках Copilot.
- Убедитесь, что модель `bge-m3` полностью загружена (`ls ~/.cache/huggingface/hub/models--mlx-community--bge-m3`).

**Долгие ответы:**
- Установите `Max Sources = 10` в настройках Copilot.
- Рассмотрите переход на 7B модель: `mlx-community/Qwen2.5-7B-Instruct-4bit` (ответы 5–10 сек).

**Не находится заметка по дате:**
- Проверьте, что в начале файла есть читаемый блок с датой и проектом. При необходимости повторно запустите скрипт конвертации.
