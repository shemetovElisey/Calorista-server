#!/bin/bash

# Скрипт для деплоя Calorista API

set -e

echo "🚀 Начинаем деплой Calorista API..."

# Проверяем наличие Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен. Установите Docker и попробуйте снова."
    exit 1
fi

# Проверяем наличие docker-compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose не установлен. Установите Docker Compose и попробуйте снова."
    exit 1
fi

# Создаем .env файл если его нет
if [ ! -f .env ]; then
    echo "📝 Создаем .env файл..."
    cp config.example.env .env
    echo "⚠️  Не забудьте изменить секретные ключи в .env файле!"
fi

# Останавливаем существующие контейнеры
echo "🛑 Останавливаем существующие контейнеры..."
docker-compose down

# Собираем и запускаем контейнеры
echo "🔨 Собираем Docker образ..."
docker-compose build --no-cache

echo "🚀 Запускаем приложение..."
docker-compose up -d

# Ждем немного для запуска
echo "⏳ Ждем запуска приложения..."
sleep 10

# Проверяем статус
echo "🔍 Проверяем статус приложения..."
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Приложение успешно запущено!"
    echo "🌐 API доступен по адресу: http://localhost:8080"
    echo "📚 Документация: http://localhost:8080/docs"
    echo "💚 Health check: http://localhost:8080/health"
else
    echo "❌ Приложение не отвечает. Проверьте логи:"
    docker-compose logs
    exit 1
fi

echo "🎉 Деплой завершен успешно!" 