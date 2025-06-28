#!/bin/bash

# Скрипт для мониторинга Calorista API

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
API_URL="http://localhost:8080"
HEALTH_ENDPOINT="$API_URL/health"
DOCS_ENDPOINT="$API_URL/docs"

echo -e "${BLUE}🔍 Мониторинг Calorista API${NC}"
echo "=================================="

# Проверка health endpoint
echo -e "${YELLOW}📊 Проверка health endpoint...${NC}"
if curl -f -s "$HEALTH_ENDPOINT" > /dev/null; then
    echo -e "${GREEN}✅ Health check: OK${NC}"
else
    echo -e "${RED}❌ Health check: FAILED${NC}"
fi

# Проверка документации
echo -e "${YELLOW}📚 Проверка документации...${NC}"
if curl -f -s "$DOCS_ENDPOINT" > /dev/null; then
    echo -e "${GREEN}✅ Documentation: OK${NC}"
else
    echo -e "${RED}❌ Documentation: FAILED${NC}"
fi

# Проверка Docker контейнеров
echo -e "${YELLOW}🐳 Проверка Docker контейнеров...${NC}"
if command -v docker-compose &> /dev/null; then
    if docker-compose ps | grep -q "Up"; then
        echo -e "${GREEN}✅ Docker containers: Running${NC}"
    else
        echo -e "${RED}❌ Docker containers: Not running${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Docker Compose не установлен${NC}"
fi

# Проверка использования ресурсов
echo -e "${YELLOW}💾 Использование ресурсов...${NC}"
if command -v docker &> /dev/null; then
    echo "Docker containers:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"
fi

# Проверка логов
echo -e "${YELLOW}📋 Последние логи...${NC}"
if command -v docker-compose &> /dev/null; then
    docker-compose logs --tail=10
else
    echo -e "${YELLOW}⚠️  Docker Compose не установлен${NC}"
fi

# Проверка портов
echo -e "${YELLOW}🔌 Проверка портов...${NC}"
if netstat -tulpn 2>/dev/null | grep -q ":8080"; then
    echo -e "${GREEN}✅ Порт 8080: Открыт${NC}"
else
    echo -e "${RED}❌ Порт 8080: Закрыт${NC}"
fi

echo ""
echo -e "${BLUE}🎯 Быстрые команды:${NC}"
echo "  Логи: docker-compose logs -f"
echo "  Перезапуск: docker-compose restart"
echo "  Остановка: docker-compose down"
echo "  Запуск: docker-compose up -d"
echo "  Статус: docker-compose ps" 