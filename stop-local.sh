#!/bin/bash

# Скрипт для остановки локального Calorista API

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 Останавливаем Calorista API...${NC}"

# Останавливаем процесс по PID если файл существует
if [ -f app.pid ]; then
    PID=$(cat app.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo -e "${YELLOW}📋 Останавливаем процесс PID: $PID${NC}"
        kill $PID
        sleep 2
        
        # Проверяем, остановился ли процесс
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Процесс не остановился, принудительно завершаем...${NC}"
            kill -9 $PID
        fi
        
        echo -e "${GREEN}✅ Процесс остановлен${NC}"
    else
        echo -e "${YELLOW}⚠️  Процесс с PID $PID не найден${NC}"
    fi
    rm -f app.pid
else
    echo -e "${YELLOW}⚠️  Файл app.pid не найден${NC}"
fi

# Останавливаем все процессы Swift App
echo -e "${YELLOW}🔍 Останавливаем все процессы Swift App...${NC}"
pkill -f "swift run App" 2>/dev/null || true
pkill -f ".build/release/App" 2>/dev/null || true

echo -e "${GREEN}🎉 Приложение остановлено!${NC}" 