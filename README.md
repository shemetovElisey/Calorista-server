# Calorista - Meal Tracking API

REST API для отслеживания приемов пищи с интеграцией Open Food Facts и аутентификацией пользователей.

## Возможности

- 🔐 JWT аутентификация пользователей
- 🍽️ CRUD операции для приемов пищи
- 🔍 Поиск продуктов через Open Food Facts API
- 💾 Кэширование продуктов в локальной БД
- 🛡️ API ключ для дополнительной безопасности
- 👥 Поддержка множественных пользователей

## Установка

1. Клонируйте репозиторий
2. Установите зависимости: `swift package resolve`
3. Скопируйте `config.example.env` в `.env` и настройте секретные ключи
4. Запустите сервер: `swift run App`

## Деплой

### Локальный деплой с Docker

```bash
# Запустите скрипт деплоя
./deploy.sh
```

### Деплой на удаленный сервер

```bash
# Быстрый деплой на удаленный сервер
./remote-deploy.sh <server-ip> [user] [path]

# Пример:
./remote-deploy.sh 192.168.1.100 ubuntu /var/www/calorista
```

### Ручной деплой

Подробные инструкции по деплою смотрите в файле [DEPLOYMENT.md](DEPLOYMENT.md).

## Конфигурация

Создайте файл `.env` на основе `config.example.env`:

```bash
# API Configuration
API_KEY=your-super-secret-api-key-2024
JWT_SECRET=your-super-secret-jwt-key-2024

# Server Configuration
PORT=8080
HOST=127.0.0.1
```

## Использование API

### Аутентификация

Все запросы должны содержать API ключ в заголовке `X-API-Key`.

### Регистрация пользователя

```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-super-secret-api-key-2024" \
  -d '{
    "email": "user@example.com",
    "password": "password123",
    "name": "John Doe"
  }'
```

### Вход в систему

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-super-secret-api-key-2024" \
  -d '{
    "email": "user@example.com",
    "password": "password123"
  }'
```

### Поиск продуктов

```bash
curl -X GET "http://localhost:8080/products/search?query=apple" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-API-Key: your-super-secret-api-key-2024"
```

### Создание приема пищи

```bash
curl -X POST http://localhost:8080/products/meal \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "X-API-Key: your-super-secret-api-key-2024" \
  -d '{
    "name": "Apple",
    "calories": 95,
    "protein": 0.5,
    "carbs": 25,
    "fat": 0.3,
    "date": "2024-01-15T12:00:00Z"
  }'
```

## Безопасность

- API ключ защищает все эндпоинты
- JWT токены для аутентификации пользователей
- Данные пользователей изолированы
- Rate limiting для Open Food Facts API

## Технологии

- Vapor 4 (Swift web framework)
- Fluent ORM
- SQLite
- JWT для аутентификации
- Open Food Facts API 