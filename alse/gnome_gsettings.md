# Твики GNOMа

| Номер | К чему относится                | Что делает твик                                       | Настройка                                                                                             |
|-------|----------------------------------|------------------------------------------------------|-------------------------------------------------------------------------------------------------------|
| 1     | Общая настройка                | Установить размер шрифта                             | `gsettings set org.gnome.desktop.interface text-scaling-factor 1.2`                                   |
| 2     | Тачпад                         | Включить естественную прокрутку                      | `gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true`                           |
| 3     | Отключение анимаций            | Отключить анимации                                   | `gsettings set org.gnome.desktop.interface enable-animations false`                                  |
| 4     | Рабочий стол                   | Установить размер иконок на рабочем столе           | `gsettings set org.gnome.nautilus.desktop background-size 48`                                       |
| 5     | Окна                           | Включить анимацию при открытии окон                  | `gsettings set org.gnome.mutter auto-move-windows true`                                            |
| 6     | Спящий режим                   | Отключить переход в спящий режим при закрытии крышки | `gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0`                 |
| 7     | Яркость                        | Установить яркость экрана при подключении             | `gsettings set org.gnome.settings-daemon.plugins.power brightness-unplugged 60`                     |
| 8     | Рабочий стол                   | Установить фоновое изображение рабочего стола        | `gsettings set org.gnome.desktop.background picture-uri 'file:///путь/к/вашему/изображению.jpg'` |
| 9     | Строка состояния               | Включить отображение состояния сети                   | `gsettings set org.gnome.desktop.interface show-network-menu true`                                    |
| 10    | Уведомления                    | Отключить уведомления для конкретного приложения      | `gsettings set com.yourapp.desktop notifications false`                                              |
| 11    | Настройки клавиатуры           | Установить порядок раскладок клавиатуры              | `gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle']"`              |
| 12    | Автозагрузка                   | Добавить приложение в автозагрузку                   | `gsettings set com.github.mate.evolution autostart true`                                            |
| 13    | Звук                           | Включить звуки событий                                | `gsettings set org.gnome.desktop.sound event-sounds true`                                           |
| 14    | Язык интерфейса                | Установить языковой интерфейс на русский             | `gsettings set org.gnome.desktop.input-sources input-sources "[('xkb', 'ru')]"`                   |
| 15    | Панель задач                   | Включить автоматическое скрытие панели задач          | `gsettings set org.gnome.shell.extensions.dash-to-panel dock-fixed false`                           |
| 16    | Восстановление окон            | Сохранить положение окон при перезагрузке             | `gsettings set org.gnome.mutter maximize-on-change true`                                            |
| 17    | Формат времени                 | Установить 24-часовой формат времени                  | `gsettings set org.gnome.desktop.interface clock-format '24-hour'`                                  |
| 18    | Цветовая схема                 | Установить светлую схему оформления                   | `gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'`                                        |
| 19    | Настройки уведомлений          | Настроить уведомления для приложений                  | `gsettings set com.yourapp.desktop show-notifications false`                                         |
| 20    | Настройки текста               | Включить автоматическую проверку орфографии           | `gsettings set org.gnome.desktop.interface text-scaling-factor 1.0`                                  |
| 21    | Общее                         | Установить максимальный размер иконок                 | `gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48`                       |
| 22    | Инструменты                    | Отключить запрос подтверждения перед выключением      | `gsettings set org.gnome.desktop.lockdown disable-log-out true`                                      |
| 23    | Графические эффекты           | Отключить ненужные графические эффекты                | `gsettings set org.gnome.desktop.interface enable-animations false`                                  |
| 24    | Уведомления                    | Отключить автоматическое обновление                   | `gsettings set org.gnome.software download-updates false`                                           |
| 25    | Доступность                    | Включить увеличение экрана                            | `gsettings set org.gnome.desktop.interface enable-zoom true`                                        |
| 26    | Курсор                         | Установить скорость курсора мыши                      | `gsettings set org.gnome.desktop.peripherals.mouse speed 1.5`                                       |
| 27    | Отображение значков           | Включить отображение значков на рабочем столе        | `gsettings set org.gnome.nautilus.desktop show-home true`                                           |
| 28    | Уведомления                    | Включить отображение графиков использования процессора | `gsettings set org.gnome.desktop.interface show-battery-percentage true`                             |
| 29    | Фон для экрана блокировки      | Установить фоновое изображение для экрана блокировки   | `gsettings set org.gnome.desktop.background lock-picture-uri 'file:///путь/к/вашему/изображению.jpg'` |
| 30    | Энергосбережение              | Включить режим сохранения энергии                     | `gsettings set org.gnome.settings-daemon.plugins.power save-power true`                             |
| 31    | Отключение анимаций           | Отключить анимации                                   | `gsettings set org.gnome.desktop.interface enable-animations false`                                  |
| 32    | Рабочий стол                   | Установить размер иконок на рабочем столе           | `gsettings set org.gnome.nautilus.desktop background-size 48`                                       |
| 33    | Тачпад                         | Включить естественную прокрутку                      | `gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true`                           |
| 34    | Ожидание блокировки экрана     | Установить задержку автоматической блокировки экрана  | `gsettings set org.gnome.desktop.session idle-delay 10`                                             |
| 35    | Иконки на рабочем столе       | Включить отображение значков для «Компьютер» и др.   | `gsettings set org.gnome.nautilus.desktop show-volumes true`                                        |
| 36    | Энергосбережение              | Включить режим сохранения батареи                     | `gsettings set org.gnome.settings-daemon.plugins.power save-energy true`                             |
| 37    | Панель задач                   | Установить максимальный размер значков для приложений  | `gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48`                       |
| 38    | Мониторинг системы             | Включить отображение графиков использования CPU и Памяти | `gsettings set org.gnome.desktop.interface show-battery-percentage true`                           |
| 39    | Курсор                         | Установить скорость курсора                           | `gsettings set org.gnome.desktop.peripherals.mouse speed 1.5`                                       |
| 40    | Автообновление                 | Отключить автоматическое обновление                   | `gsettings set org.gnome.software download-updates false`                                           |
| 41    | Читабельность интерфейса       | Установить контраст текстов на более четкий          | `gsettings set org.gnome.desktop.interface text-scaling-factor 1.2`                                  |
| 42    | Окна                           | Включить использование горячих клавиш                | `gsettings set org.gnome.mutter hot-corner-new-windows false`                                       |
| 43    | Рабочий стол                   | Установить фоновое изображение рабочего стола с автозаменой | `gsettings set org.gnome.desktop.background picture-options 'wallpaper'`                       |
| 44    | Уведомления                    | Отключить уведомления для приложений                  | `gsettings set com.yourapp.desktop notifications false`                                              |
| 45    | Языковой интерфейс             | Установить языковой интерфейс на русский             | `gsettings set org.gnome.desktop.input-sources input-sources "[('xkb', 'ru')]"`                   |
| 46    | Значки состояния               | Установить поведение настраиваемых значков           | `gsettings set org.gnome.desktop.interface show-status-indicators true`                             |
| 47    | GTK шрифты                     | Установить стандартное приложение для открытия HTML   | `gsettings set org.gnome.system.stock default-apps.browser 'org.mozilla.firefox.desktop'`           |
| 48    | Жесты на тачпаде              | Настройка жестов на тачпаде                         | `gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling true`                     |
| 49    | Внешний вид                    | Установить максимальный размер значков в панели       | `gsettings set org.gnome.shell.extensions.dash-to-panel dash-max-icon-size 48`                      |
| 50    | Снижение нагрузки              | Отключить возможность слияния окон                   | `gsettings set org.gnome.mutter edge-tiling false`                                                |
| 51    | Безопасность                   | Отключить возможность изменения настроек для приложений | `gsettings set org.gnome.desktop.lockdown disable-log-out true`                                    |
| 52    | Меню                           | Отключить переход в спящий режим при закрытии крышки | `gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0`                 |
| 53    | Яркость                        | Установить яркость экрана при подключении             | `gsettings set org.gnome.settings-daemon.plugins.power brightness-unplugged 60`                     |
| 54    | Рабочий стол                   | Установить фоновое изображение рабочего стола        | `gsettings set org.gnome.desktop.background picture-uri 'file:///путь/к/вашему/изображению.jpg'` |
| 55    | Строка состояния               | Включить отображение состояния сети                   | `gsettings set org.gnome.desktop.interface show-network-menu true`                                   |
| 56    | Уведомления                    | Отключить уведомления для конкретного приложения      | `gsettings set com.yourapp.desktop notifications false`                                             |
| 57    | Настройки клавиатуры           | Установить порядок раскладок клавиатуры              | `gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle']"`             |
| 58    | Автозагрузка                   | Добавить приложение в автозагрузку                   | `gsettings set com.github.mate.evolution autostart true`                                            |
| 59    | Звук                           | Включить звуки событий                                | `gsettings set org.gnome.desktop.sound event-sounds true`                                           |
| 60    | Язык интерфейса                | Установить языковой интерфейс на русский             | `gsettings set org.gnome.desktop.input-sources input-sources "[('xkb', 'ru')]"`                   |
| 61    | Поведение панели               | Включить автоматическое скрытие панели задач          | `gsettings set org.gnome.shell.extensions.dash-to-panel dock-fixed false`                           |
| 62    | Восстановление окон            | Сохранить положение окон при перезагрузке             | `gsettings set org.gnome.mutter maximize-on-change true`                                            |
| 63    | Формат времени                 | Установить 24-часовой формат времени                  | `gsettings set org.gnome.desktop.interface clock-format '24-hour'`                                  |
| 64    | Цветовая схема                 | Установить светлую схему оформления                   | `gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'`                                        |
| 65    | Уведомления                    | Настроить уведомления для приложений                  | `gsettings set com.yourapp.desktop show-notifications false`                                         |
| 66    | Настройки текста               | Включить автоматическую проверку орфографии           | `gsettings set org.gnome.desktop.interface text-scaling-factor 1.0`                                  |
| 67    | Общее                         | Установить максимальный размер иконок                 | `gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48`                       |
| 68    | Инструменты                    | Отключить запрос подтверждения перед выключением      | `gsettings set org.gnome.desktop.lockdown disable-log-out true`                                      |
| 69    | Графические эффекты           | Отключить ненужные графические эффекты                | `gsettings set org.gnome.desktop.interface enable-animations false`                                  |
| 70    | Уведомления                    | Отключить автоматическое обновление                   | `gsettings set org.gnome.software download-updates false`                                           |
| 71    | Доступность                    | Включить увеличение экрана                            | `gsettings set org.gnome.desktop.interface enable-zoom true`                                        |
| 72    | Курсор                         | Установить скорость курсора мыши                      | `gsettings set org.gnome.desktop.peripherals.mouse speed 1.5`                                       |
| 73    | Отображение значков           | Включить отображение значков на рабочем столе        | `gsettings set org.gnome.nautilus.desktop show-home true`                                           |
| 74    | Уведомления                    | Включить отображение графиков использования процессора | `gsettings set org.gnome.desktop.interface show-battery-percentage true`                             |
| 75    | Курсор                         | Установить скорость курсора                           | `gsettings set org.gnome.desktop.peripherals.mouse speed 1.5`                                       |
| 76    | Автообновление                 | Отключить автоматическое обновление                   | `gsettings set org.gnome.software download-updates false`                                           |
| 77    | Читабельность интерфейса       | Установить контраст текстов на более четкий          | `gsettings set org.gnome.desktop.interface text-scaling-factor 1.2`                                  |
| 78    | Окна                           | Включить использование горячих клавиш                | `gsettings set org.gnome.mutter hot-corner-new-windows false`                                       |
| 79    | Рабочий стол                   | Установить фоновое изображение рабочего стола с автозаменой | `gsettings set org.gnome.desktop.background picture-options 'wallpaper'`                       |
| 80    | Уведомления                    | Отключить уведомления для приложений                  | `gsettings set com.yourapp.desktop notifications false`                                              |
