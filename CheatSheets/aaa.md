# Технологии процессов аутентификации и авторизации: пользовательской или межсервисной

## Описания методов

| Вопрос | Технология/Метод | Описание | Примеры использования |
|-|-|-|-|
| Аутентификация пользователей | Пароли | Традиционный метод аутентификации, требующий от пользователя ввода пароля. | Вход в личный кабинет на веб-версии банка. |
| | Двухфакторная аутентификация (2FA) | Дополнительный уровень безопасности, требующий второй фактор (например, SMS-код, приложение-аутентификатор). | Подтверждение входа в мобильное банковское приложение с помощью SMS-кода. |
| | Биометрия | Использование отпечатков пальцев, распознавания лица или сканирования радужной оболочки глаза для аутентификации. | Вход в мобильное приложение банка через отпечаток пальца или распознавание лица. |
| | OAuth 2.0 | Протокол для авторизации, позволяющий приложениям получать ограниченный доступ к ресурсам пользователя без передачи пароля. | Вход через сторонние сервисы (например, Google, Facebook) в банковские приложения. |
| | OpenID Connect | Надстройка над OAuth 2.0 для аутентификации пользователей, предоставляющая ID-токен. | Единая точка входа для веб и мобильного банка. |
| Авторизация пользователей | Ролевое управление доступом (RBAC) | Метод авторизации, при котором права доступа определяются ролями пользователя. | Ограничение доступа к определенным функциональным возможностям внутри банковского ПО.|
| | Attribute-Based Access Control (ABAC) | Метод авторизации на основе атрибутов пользователя и условий доступа. | Доступ к определенным операциям в зависимости от статуса клиента. |
| | JSON Web Tokens (JWT) | Компактный и самодостаточный токен для безопасной передачи информации между сторонами. | Авторизация в API мобильного приложения через JWT. |
| | Single Sign-On (SSO) | Технология, позволяющая пользователям аутентифицироваться один раз и получать доступ к нескольким системам без повторного ввода пароля. | Единый вход в несколько банковских систем и приложений. |
| Аутентификация межсервисная | Mutual TLS (mTLS) | Двусторонняя TLS-аутентификация, где обе стороны (клиент и сервер) проверяют подлинность друг друга. | Безопасное взаимодействие между микросервисами банка. |
| | API Keys | Уникальные ключи, используемые для идентификации и аутентификации приложений или сервисов при взаимодействии через API. | Доступ внешних сервисов к API банка. |
| | OAuth 2.0 Client Credentials Grant | OAuth 2.0 поток, используемый для аутентификации приложений или сервисов без участия пользователя. | Авторизация серверов и приложений для доступа к ресурсам банка. |
| | JSON Web Tokens (JWT) | Токен, используемый для передачи информации между сервисами с возможностью проверки подлинности и целостности данных. | Аутентификация и авторизация между микросервисами. |
| Авторизация межсервисная | Role-Based Access Control (RBAC) | Определение прав доступа между сервисами на основе ролей. | Определение прав доступа микросервисов к ресурсам. |
| | OAuth 2.0 Scopes | Ограничение доступа к ресурсам на основе областей (scopes), указанных при запросе токена. | Разграничение доступа к различным API-методам в зависимости от токена. |
| | Policy-Based Access Control (PBAC) | Управление доступом на основе политик, определяющих условия, при которых доступ разрешен или запрещен. | Управление доступом между сервисами на основе политик безопасности. |

## Определения

| Вопрос | Технология/Метод | Определение | Пример использования |
|-|-|-|-|
| Аутентификация пользователей | Пароли | Метод аутентификации, где пользователю нужно ввести пароль для подтверждения своей личности. | Вход в личный кабинет на веб-версии банка. |
| | Двухфакторная аутентификация (2FA) | Дополнительный уровень безопасности, где, кроме пароля, нужно ввести код из SMS или приложения-аутентификатора. | Подтверждение входа в мобильное банковское приложение с помощью SMS-кода. |
| | Биометрия | Использование отпечатков пальцев, распознавания лица или сканирования радужной оболочки глаза для подтверждения личности. | Вход в мобильное приложение банка через отпечаток пальца или распознавание лица. |
| | OAuth 2.0 | Протокол, позволяющий приложениям получать ограниченный доступ к ресурсам пользователя без передачи пароля. | Вход через Google или Facebook в банковское приложение. |
| | OpenID Connect | Надстройка над OAuth 2.0 для аутентификации, предоставляющая ID-токен для подтверждения личности пользователя. | Единая точка входа для веб и мобильного банка. |
| Авторизация пользователей | Ролевое управление доступом (RBAC) | Метод, где права доступа определяются ролями пользователя. | Ограничение доступа к определенным функциям в банковском ПО. |
| | Attribute-Based Access Control (ABAC) | Метод, где доступ определяется на основе атрибутов пользователя и условий доступа. | Доступ к определенным операциям в зависимости от статуса клиента. |
| | JSON Web Tokens (JWT) | Компактный токен для безопасной передачи информации между сторонами. | Авторизация в API мобильного приложения через JWT. |
| | Single Sign-On (SSO) | Технология, позволяющая аутентифицироваться один раз и получить доступ к нескольким системам без повторного ввода пароля. | Единый вход в несколько банковских систем и приложений. |
| Аутентификация межсервисная | Mutual TLS (mTLS) | Двусторонняя аутентификация, где и клиент, и сервер проверяют подлинность друг друга. | Безопасное взаимодействие между микросервисами банка. |
| | API Keys | Уникальные ключи для идентификации и аутентификации приложений при взаимодействии через API. | Доступ внешних сервисов к API банка. |
| | OAuth 2.0 Client Credentials Grant | Поток OAuth 2.0, используемый для аутентификации приложений без участия пользователя. | Авторизация серверов и приложений для доступа к ресурсам банка. |
| | JSON Web Tokens (JWT) | Токен для передачи информации между сервисами с возможностью проверки подлинности и целостности данных. | Аутентификация и авторизация между микросервисами. |
| Авторизация межсервисная | Role-Based Access Control (RBAC) | Определение прав доступа между сервисами на основе ролей. | Определение прав доступа микросервисов к ресурсам. |
| | OAuth 2.0 Scopes | Ограничение доступа к ресурсам на основе областей (scopes), указанных при запросе токена. | Разграничение доступа к различным API-методам в зависимости от токена. |
| | Policy-Based Access Control (PBAC) | Управление доступом на основе политик, определяющих условия, при которых доступ разрешен или запрещен. | Управление доступом между сервисами на основе политик безопасности. |
