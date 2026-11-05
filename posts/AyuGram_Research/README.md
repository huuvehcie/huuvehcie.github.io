# Отчёт о статическом анализе Android-приложения — AyuGram (форк Telegram)

**Дата:** 2026-11-05T12:48:47+00:00
**Образец:** `file.apk` — 133,795,216 байт (~127 МБ), собран из 3 фрагментов `part_*`
**SHA-256:** `b7195bd9f3126543566acf3e1e5d3d1cc1fa163db927e85918877f7cb65cb113`
**MD5:** `98d2ef202dabf1b65f77d6e3b6b77a95`
**Метод:** статический анализ без запуска (androguard 4.1.4): манифест, 8 DEX (60,238 классов, 331,458 методов, 6,030,052 инструкций), assets, native-библиотеки, подпись.

---

## 1. Идентификация

| Поле | Значение |
|---|---|
| Пакет | `com.radolyn.ayugram` |
| Имя | AyuGram |
| Версия | 13.1.1 (72379) |
| minSdk / targetSdk | 24 / 36 |
| Подпись | scheme v2, самоподписанный |

**Субъект сертификата:** Common Name: AlexeyZavar, Organizational Unit: Mobile, Organization: Radolyn Labs, Locality: Moscow, State/Province: Russia, Country: RU
**SHA-256 отпечаток:** `50 FD F8 7A 75 D5 E5 22 D0 8D 5F C9 F1 5C FD 1F ED 8A 93 EA EB C0 6C 96 87 93 C8 87 1D 9A 22 B3`
**Срок действия:** 2024-04-06 14:29:46+00:00 — 2059-03-29 14:29:46+00:00

AyuGram — известный open-source форк Telegram (на базе exteraGram). Build-путь `/Users/alexeyzavar/Projects/AyuGram4A/TMessagesProj/...` внутри `libtmessages.49.so` и сертификат `CN=AlexeyZavar, O=Radolyn Labs, Moscow, RU` подтверждают авторство оригинального разработчика. **Признаков перепаковки (repack) чужими лицами не обнаружено.**

## 2. Разрешения (79 запрошено, 34 опасных)

Типичный для мессенджера набор. Наиболее значимые:

- `REQUEST_INSTALL_PACKAGES` — внутренний апдейтер форка (ресивер `MY_PACKAGE_REPLACED`), обновление вне Google Play;
- `SYSTEM_ALERT_WINDOW`, `MANAGE_EXTERNAL_STORAGE`, `QUERY_ALL_PACKAGES`, `ACCESS_BACKGROUND_LOCATION` — широкие возможности;
- **SMS-разрешений нет**; `SmsReceiver` слушает только `com.google.android.gms.auth.api.phone.SMS_RETRIEVED` (легитимный автоподстановщик кодов, не перехват SMS).

Комбо-паттерны: Dropper-паттерн (install+overlay, HIGH), Камера+Микрофон, Фоновая геолокация, Полный доступ к файлам (MEDIUM) — все объяснимы функциями мессенджера.

## 3. Компоненты

19 activity (+~50 алиасов иконок), 38 сервисов, 30 ресиверов, 8 провайдеров. Все exported-компоненты стандартны для Telegram; новых внешних точек входа форк не добавляет.

## 4. Динамическая загрузка кода — главная особенность

1. **Python-плагины (Chaquopy, Python 3.11):** `PythonPluginsEngine` — создание экземпляров плагинов, установка pip-зависимостей в рантайме; SDK включает requests/lxml/bs4/debugpy.
2. **Встроенный Xposed-совместимый фреймворк** (`de.robv.android.xposed.*`, 15 классов): `hookMethod`, `hookAllMethods`, `invokeOriginalMethod`, `deoptimizeMethod`, `disableHiddenApiRestrictions`; хуки плагинов на отправку/получение сообщений (`executeSendMessageHook`, `executePreRequestHook` и др.).
3. **Генерация DEX в памяти:** `ClassProxy.createProxyClass` (DexMaker + `InMemoryDexClassLoader`), встроенный компилятор `com.android.dx` (649 классов), expression-движок mvel2.
4. **Нативный инлайн-хукинг:** `libshadowhook.so` (ByteDance); `HiddenApiBypass` (обход hidden API).

**Защитные механизмы:** `PluginAnalyzerService` + `libextera_analyzer.so` — статический анализ плагинов перед загрузкой (ищет опасные API); `SensitiveRequestSheet` — интерактивное подтверждение чувствительных запросов.

## 5. Обфускация

- `org.lsposed.lsparanoid` — компиляционная обфускация строк (ChaCha20) в сборке AyuGram;
- `libextera_analyzer.so` собран с OLLVM (строка `ollvm-ndk30-based-on-llvm21`);
- Классы Telegram/exteraGram **не** переименованы, упаковщиков нет.

## 6. Сетевые индикаторы

**C2 не обнаружено.** 267 уникальных URL — вся легитимная экосистема: Telegram (`telegram.org`, `t.me`), инфраструктура форков (`api.exteragram.app`, `plugins.exteragram.app`), интеграции (Spotify, Apple Music, LRCLIB, Vosk, Яндекс, OpenAI/OpenRouter/Perplexity/Gemini), adblock-листы uBlock/AdGuard. IP в `libtmessages.49.so` — официальные дата-центры Telegram (149.154.175.x/167.x, 95.161.76.100). `usesCleartextTraffic=true` (как у официального клиента). Trust-all сертификатов отсутствует (0 собственных реализаций `checkServerTrusted`).

## 7. Соответствие MITRE ATT&CK Mobile

| Техника | Название | Статус | Уверенность |
|---|---|---|---|
| T1406.002 | Obfuscated Files or Information: String Obfuscation | observed (build-level) | высокая |
| T1407 | Load New Payload | capability (по действию пользователя) | высокая |
| T1625.001 | Hijack Execution Flow: System Runtime API Manipulation | capability (in-app хуки) | высокая |
| T1633.001 | Virtualization/Sandbox Evasion: System Checks | present (официальный код) | средняя |
| T1521.001 | Encrypted Channel: Symmetric Cryptography | by design (MTProto) | высокая |

**NIST CSF:** DE.AE-02, DE.CM-01, ID.RA-01, RS.AN-03 — см. `risk_report.json`.

## 8. Оценка риска

**Результат: 5.9 / 10 — MEDIUM (повышенный риск dual-use архитектуры).**

| Фактор | Вес | Балл |
|---|---|---|
| Динамическая загрузка кода (Python-плагины, InMemoryDexClassLoader, runtime-pip) | 2.5 | 2.5 |
| Встроенный фреймворк хукинга (Xposed-API + shadowhook + HiddenApiBypass) | 2.0 | 2.0 |
| Опасные разрешения (install, overlay, все файлы, все пакеты) | 2.0 | 1.5 |
| Сетевые IOC / C2 | 2.0 | 0.0 |
| Обфускация (lsparanoid, OLLVM) | 0.5 | 0.3 |
| SMS/телефонный абьюз | 1.0 | 0.0 |
| Обход проверки сертификатов | 0.5 | 0.0 |
| Антианализ | 0.5 | 0.1 |
| Митигаторы (авторская подпись, open-source линейка, анализатор плагинов) | −0.5 | −0.5 |

## 9. Вердикт

> **МОДИФИЦИРОВАННЫЙ ЛЕГИТИМНЫЙ КЛИЕНТ (форк Telegram). Признаки вредоносного ПО НЕ ОБНАРУЖЕНЫ.**
>
> Опасные механизмы (хукинг, динамическая загрузка плагинов, обход hidden-API) — заявленные функции AyuGram/exteraGram, активируются пользователем и имеют встроенные защитные проверки. Остаточные риски: установка недоверенного плагина = произвольный код с доступом ко всем чатам; апдейтер вне Play Protect; ослабление изоляции платформы; возможные ложные срабатывания AV (PUA).

## 10. Рекомендации

1. В корпоративной среде — запретить неофициальные клиенты Telegram (MDM), т.к. форк выводит трафик из-под Play Protect.
2. При необходимости использования — плагины только из доверенных источников, включённый PluginAnalyzer, контроль `REQUEST_INSTALL_PACKAGES`.
3. Сверить SHA-256 образца с официальными релизами (`t.me/ayugramreleases`) перед доверием сборке.
4. Мониторить исходящие соединения пакета `com.radolyn.ayugram` на неизвестные домены.
5. Использовать `iocs.json` для DTI (фингерпринт сертификата, хэши, маркеры сборки).

---
*Артефакты анализа: 14 JSON-файлов в `reports/` (метаданные, разрешения, компоненты, скан строк и инструкций, IOC, native-библиотеки, манифест, ключевые классы).*
