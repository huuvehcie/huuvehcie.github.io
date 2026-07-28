## Полная инструкция: локальный AI-ассистент в Obsidian (MLX) – финальная версия

Ниже **все шаги от начала до конца**, с учётом реальных проблем (отсутствие `mlx_lm download`, недоступность `huggingface-cli`).  
Работает на Apple Silicon (M5), без Docker, без Ollama, без загрязнения системы Python-пакетами.

---

### 1. Подготовка хранилища Obsidian

Убедитесь, что ваши встречи лежат в `~/Work/Obsidian/Work/Meetings`.  
Если у вас ещё есть файлы с YAML-фронтматтером (начинаются с `---`), их нужно преобразовать в читаемый блок.  
Скрипт `convert.sh` делает это рекурсивно, пропуская уже обработанные файлы.

Скачайте скрипт (или создайте в корне хранилища) и выполните:
```bash
cd ~/Work/Obsidian/Work
chmod +x convert.sh
./convert.sh
```

(Текст скрипта `convert.sh` приведён в одном из предыдущих ответов; он заменяет `---`‑блок на читаемые строки «Дата совещания: …» и т.д.)

После конвертации закройте Obsidian.

---

### 2. Установка Homebrew и pipx

Если ещё нет:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Установите pipx (менеджер изолированных Python‑приложений):
```bash
brew install pipx
pipx ensurepath
```
**Перезапустите терминал** или выполните `source ~/.zshrc`.

---

### 3. Установка `mlx-lm` в изолированное окружение

```bash
pipx install mlx-lm
```

Проверьте, что команды доступны (без точки, не `mlx_lm.download`):
```bash
mlx_lm --help
```

---

### 4. Загрузка моделей (чат и эмбеддинги)

Поскольку у вас нет `mlx_lm download`, используем Python из окружения `mlx-lm` напрямую.

Установите библиотеку `huggingface_hub` внутрь этого же окружения:
```bash
pipx runpip mlx-lm install huggingface_hub
```

Загрузите модели одной командой:
```bash
~/.local/share/pipx/venvs/mlx-lm/bin/python -c "
from huggingface_hub import snapshot_download
snapshot_download('mlx-community/Qwen2.5-14B-Instruct-4bit',
                  local_dir='$HOME/.cache/huggingface/hub/models--mlx-community--Qwen2.5-14B-Instruct-4bit')
snapshot_download('mlx-community/bge-m3',
                  local_dir='$HOME/.cache/huggingface/hub/models--mlx-community--bge-m3')
"
```

Проверьте, что папки не пусты:
```bash
ls ~/.cache/huggingface/hub/models--mlx-community--Qwen2.5-14B-Instruct-4bit
ls ~/.cache/huggingface/hub/models--mlx-community--bge-m3
```

---

### 5. Запуск серверов через tmux + алиасы

Установите tmux:
```bash
brew install tmux
```

Добавьте в `~/.zshrc` алиасы:
```bash
alias mlx-chat-start='tmux new-session -d -s mlx-chat "mlx_lm server --model mlx-community/Qwen2.5-14B-Instruct-4bit --host 0.0.0.0 --port 8080" && echo "Chat server started on :8080"'
alias mlx-emb-start='tmux new-session -d -s mlx-emb "mlx_lm server --model mlx-community/bge-m3 --host 0.0.0.0 --port 8081" && echo "Embedding server started on :8081"'
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
curl http://localhost:8080/v1/models   # должна вернуть JSON с моделью
curl http://localhost:8081/v1/models   # тоже JSON
```

---

### 6. Настройка Copilot в Obsidian

1. Откройте Obsidian → Настройки → Сторонние плагины → Copilot → шестерёнка.
2. **Chat Model**:
   - Provider: `OpenAI`
   - Base URL: `http://localhost:8080/v1`
   - API Key: `no-key` (любая строка)
   - Нажмите «Refresh Models», выберите `mlx-community/Qwen2.5-14B-Instruct-4bit`
3. **Embedding Model**:
   - Provider: `OpenAI`
   - Base URL: `http://localhost:8081/v1`
   - API Key: `no-key`
   - Model: `mlx-community/bge-m3`
4. В разделе **Semantic Search & Indexing**:
   - ✅ Enable Semantic Search
   - Auto-Index Strategy: `ON FILE CHANGE`
   - Max Sources: **15** (для скорости)
   - Embedding Batch Size: **32** (можно 64, если не падает)
   - Requests per Minute: **120**
5. Сохраните настройки.

---

### 7. Индексация хранилища

`Cmd+P` → **Copilot: Force Reindex Vault**  
Дождитесь завершения (индикатор в строке состояния).  
Первая индексация 1800+ файлов займёт 10–20 минут.

---

### 8. Удаление Ollama (если было)

Если раньше стояла Ollama, полностью удалите:
```bash
# Остановите приложение (иконка в строке меню → Quit)
rm -rf /Applications/Ollama.app
rm -rf ~/.ollama
```

---

### 9. Использование

- Откройте чат: `Cmd+P` → **Copilot: Open Chat**
- Примеры запросов:
  - «Что обсуждалось на совещании 27 июля 2026 года по проекту BVP?»
  - «Какие задачи по DevOps ставились за последнюю неделю?»
  - «Сделай сводку встреч по сертификации за июль 2026»

После перезагрузки Mac запускайте серверы командой `mlx-start`.  
Останавливайте при необходимости: `mlx-stop` (освободит ~15 ГБ памяти).

---

### 10. Автозапуск серверов при входе в систему (по желанию)

Создайте файл `~/Library/LaunchAgents/com.mlx.all.plist`:

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
        <string>/Users/$USER/.local/bin/mlx_lm server --model mlx-community/Qwen2.5-14B-Instruct-4bit --host 0.0.0.0 --port 8080 &amp; /Users/$USER/.local/bin/mlx_lm server --model mlx-community/bge-m3 --host 0.0.0.0 --port 8081 &amp; wait</string>
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

Теперь серверы будут стартовать автоматически при входе в систему.
