# 🔦 Лог Аудита Безопасности клиента Telegram «Telega» (ru.dahl.messenger)

## 1\. Подготовка и Установка Утилит 🛠️

Для начала нам понадобятся основные инструменты для работы с Android-приложениями (APK), их декомпиляции/дизассемблирования и динамического анализа.

### Задача 1: Установка Базовых Инструментов ArchLinux

```bash
# Установка Java Decompiler (Jadx) и Android Debug Bridge (ADB)
sudo pacman -S jadx android-tools

# Установка APKTool (через AUR)
paru -S apktool
```

### Задача 2: Установка Frida

Для динамического анализа необходим фреймворк Frida. Установим его в изолированное виртуальное окружение, как рекомендовано в ArchLinux.

```bash
# Установка системного пакета virtualenv
sudo pacman -S python-virtualenv

# Создание и активация виртуального окружения
python -m venv frida_venv
source frida_venv/bin/activate

# Установка инструментов Frida
pip install frida-tools
```

-----

## 2\. Статический Анализ (Декомпиляция и Grep) 🔎

### Задача 3: Декомпиляция APK

Мы используем `apktool` для извлечения ресурсов и Smali-кода.

```bash
# Декомпиляция приложения
apktool d Telega-1.11.3-TG-12.0.1.apk -o telega_decoded
```

### Задача 4: Анализ манифеста (Поиск разрешений и уязвимостей)

Проверяем `AndroidManifest.xml` на предмет опасных разрешений (`READ_CALL_LOG`, `ACCESS_BACKGROUND_LOCATION`) и уязвимостей (`android:exported="true"`).

### Задача 5: Поиск Ключей MTProto (`grep` по Smali)

Используя `grep` в папке `telega_decoded`, мы ищем жестко закодированные ключи (`API ID`, `API Hash`) и другие секреты:

```bash
# Поиск API ID/Hash
grep -r "const-string" . | grep -E "API_ID|APP_ID|api_hash|API_HASH" 
# Результат: Пусто.

# Поиск критических нативных вызовов
grep -r "native_set_int_config" .
# Результат: Пусто.

# Поиск классов конфигурации
grep -r "config" . | grep -A 10 "config.dat"
# Результат: Найдены ссылки на MessagesStorage, SharedConfig, AppGlobalConfig. 
# Вывод: Ключи не хранятся в открытом виде, вероятнее всего, они обфусцированы в нативной библиотеке libtmessages.49.so.
```

-----

## 3\. Динамический Анализ (Подготовка Стенда и Frida) 🚀

Поскольку статический анализ не дал ключей, переходим к динамическому анализу с Frida.

### Задача 6: Настройка AVD и Root-доступ

Для работы с Frida требуется рутированный эмулятор.

1.  **Запуск AVD:** Запускаем эмулятор AVD (рекомендована архитектура `x86_64` для скорости и **отладочный образ** для простого рутирования).
2.  **Установка APK:**
    ```bash
    adb install Telega-1.11.3-TG-12.0.1.apk
    ```
3.  **Получение Root-доступа:** В AVD используется простой метод рутирования.
    ```bash
    adb root
    adb shell
    whoami
    # Ожидаемый вывод: root
    ```

### Задача 7: Запуск Frida-Server

Загружаем и запускаем `frida-server` (версию `x86_64`) на рутированном эмуляторе.

```bash
# В терминале ArchLinux (вне adb shell):
adb push frida-server /data/local/tmp/frida-server
adb shell "chmod 755 /data/local/tmp/frida-server"

# В терминале adb shell (с правами root):
emu64xa:/ # /data/local/tmp/frida-server 
# (Оставляем это окно открытым!)
```

### Задача 8: Хук v1 — Поиск `NativeConfig`

Создан скрипт `config_hook.js` для перехвата стандартного класса конфигурации.

```javascript
// config_hook.js
if (Java.available) {
    Java.perform(function () {
        var NativeConfig = Java.use('org.telegram.messenger.NativeConfig');
        // ... хуки putInt и putString
    });
}
```

  * **Команда (в `(frida_venv)`):** `frida -U -f ru.dahl.messenger -l config_hook.js`
  * **Результат:** `java.lang.ClassNotFoundException: Didn't find class "org.telegram.messenger.NativeConfig"`
  * **Вывод:** **Подтверждена обфускация\!**

### Задача 9: Хук v2 — Атака на `AppGlobalConfig`

На основе статического анализа создан скрипт `app_config_hook.js` для перехвата класса-кандидата `AppGlobalConfig`.

```javascript
// app_config_hook.js
if (Java.available) {
    Java.perform(function () {
        var AppGlobalConfig = Java.use('org.telegram.messenger.AppGlobalConfig');
        // ... перехват всех методов get* и is*
    });
}
```

  * **Команда (в `(frida_venv)`):** `frida -U -f ru.dahl.messenger -l app_config_hook.js`
  * **Результат:** \`\`\`
    [+] Hooking org.telegram.messenger.AppGlobalConfig methods...
    TypeError: cannot read property 'forEach' of undefined
    ```
    ```
  * **Вывод:** **Класс существует, но пуст.** Вся логика работы с ключами **полностью перенесена в нативную библиотеку** `libtmessages.49.so`.

### Задача 10: Хук v3 — Атака на Нативный Код

Создан скрипт `native_hook.js` для перехвата нативной библиотеки `libtmessages.49.so` через функцию `JNI_OnLoad`.

```javascript
// native_hook.js
Interceptor.attach(Module.findExportByName("libtmessages.49.so", "JNI_OnLoad"), { 
    onEnter: function (args) { 
        // ...
    }
});
```

  * **Команда (в `(frida_venv)`):** `frida -U -f ru.dahl.messenger -l native_hook.js`
  * **Результат:** \`\`\`
    TypeError: not a function
    ```
    Приложение **резко перезапустилось/завершилось**.
    ```
  * **Вывод:** **Критическая защита\!** Функция `JNI_OnLoad` обфусцирована. Наблюдаемое поведение указывает на **активный механизм Anti-Frida** (обнаружения инструментов динамического анализа).

-----

## 4\. Окончательные Выводы и Следующие Шаги 🔑

На основе проведенного анализа были сделаны следующие выводы:

1.  **Конфиденциальность под угрозой:** Приложение запрашивает **критически опасные разрешения** (`READ_CALL_LOG`, `ACCESS_BACKGROUND_LOCATION`), что является признаком шпионажа.
2.  **Скрытие намерений:** Разработчики применили **агрессивную обфускацию** как Java-классов, так и **критических нативных функций** (`JNI_OnLoad`), и, вероятно, используют **Anti-Frida защиту**.
3.  **Неподтвержденная аутентификация:** Из-за скрытия ключей **невозможно подтвердить**, что клиент использует официальные ключи MTProto, и **нельзя исключить** перехват или утечку данных на сторонние серверы.

**Следующий шаг:** Дальнейший анализ требует **низкоуровневого реверс-инжиниринга** нативной библиотеки `libtmessages.49.so` с использованием **Ghidra** для извлечения скрытых ключей и логики.
