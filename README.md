# Restaurant Order App

POS-система для ресторана: серверная часть на одной машине внутри
заведения связывает POS-приложение персонала и QR-меню для гостей.

## Структура монорепо

| Каталог                     | Что это                                                            |
|-----------------------------|-------------------------------------------------------------------|
| `server/`                   | Локальный сервер на Dart Frog (REST + WebSocket + SQLite).         |
| `apps/pos/`                 | POS-приложение персонала (официант / касса / повар / директор / админ). |
| `client_menu/`              | Веб-страница QR-меню для гостей (Flutter Web).                     |
| `packages/shared_models/`   | Общие неизменяемые DTO для сервера и клиентов (чистый Dart).       |
| `packages/api_client/`      | HTTP/WebSocket-клиент к серверу.                                   |
| `docs/`                     | Документация: архитектура, API, деплой, гайды.                     |
| `scripts/`                  | PowerShell-скрипты сборки и запуска.                               |

## Быстрый старт

```powershell
# Собрать QR-меню → скопировать в server/public/ → запустить сервер.
./scripts/build_and_run.ps1
```

Подробнее: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/DEPLOY.md](docs/DEPLOY.md), [server/README.md](server/README.md).
