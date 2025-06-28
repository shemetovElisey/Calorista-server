#!/bin/bash

# Скрипт для локального деплоя Calorista API без Docker

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Начинаем локальный деплой Calorista API...${NC}"

# Проверяем наличие Swift
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Swift не установлен. Установите Swift и попробуйте снова.${NC}"
    exit 1
fi

# Создаем .env файл если его нет
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Создаем .env файл...${NC}"
    cp config.example.env .env
    echo -e "${YELLOW}⚠️  Не забудьте изменить секретные ключи в .env файле!${NC}"
fi

# Останавливаем существующий процесс если он запущен
echo -e "${YELLOW}🛑 Останавливаем существующий процесс...${NC}"
pkill -f "swift run App" 2>/dev/null || true
pkill -f ".build/release/App" 2>/dev/null || true

# Ждем немного
sleep 2

# Собираем приложение
echo -e "${YELLOW}🔨 Собираем приложение...${NC}"
swift build -c release

# Запускаем приложение в фоне
echo -e "${YELLOW}🚀 Запускаем приложение...${NC}"
nohup ./.build/release/App > app.log 2>&1 &
APP_PID=$!

# Сохраняем PID для последующего управления
echo $APP_PID > app.pid

# Ждем запуска
echo -e "${YELLOW}⏳ Ждем запуска приложения...${NC}"
sleep 5

# Проверяем статус
echo -e "${YELLOW}🔍 Проверяем статус приложения...${NC}"
for i in {1..10}; do
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Приложение успешно запущено!${NC}"
        echo -e "${GREEN}🌐 API доступен по адресу: http://localhost:8080${NC}"
        echo -e "${GREEN}📚 Документация: http://localhost:8080/docs${NC}"
        echo -e "${GREEN}💚 Health check: http://localhost:8080/health${NC}"
        echo -e "${GREEN}📋 PID процесса: $APP_PID${NC}"
        echo -e "${GREEN}📄 Логи: tail -f app.log${NC}"
        break
    else
        if [ $i -eq 10 ]; then
            echo -e "${RED}❌ Приложение не отвечает после 10 попыток.${NC}"
            echo -e "${YELLOW}📋 Логи приложения:${NC}"
            cat app.log
            exit 1
        fi
        echo -e "${YELLOW}⏳ Попытка $i/10...${NC}"
        sleep 2
    fi
done

echo -e "${GREEN}🎉 Локальный деплой завершен успешно!${NC}"
echo ""
echo -e "${BLUE}🎯 Управление приложением:${NC}"
echo "  Остановка: ./stop-local.sh"
echo "  Логи: tail -f app.log"
echo "  Статус: ./monitor.sh" 