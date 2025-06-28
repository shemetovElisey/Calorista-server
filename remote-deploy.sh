#!/bin/bash

# Скрипт для деплоя на удаленный сервер

set -e

# Конфигурация
REMOTE_HOST="your-server.com"
REMOTE_USER="ubuntu"
REMOTE_PATH="/var/www/calorista"
SSH_KEY="~/.ssh/id_rsa"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Начинаем деплой на удаленный сервер...${NC}"

# Проверяем аргументы
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Использование: $0 <server-ip> [user] [path]${NC}"
    echo "Пример: $0 192.168.1.100 ubuntu /var/www/calorista"
    exit 1
fi

REMOTE_HOST=$1
REMOTE_USER=${2:-ubuntu}
REMOTE_PATH=${3:-/var/www/calorista}

echo -e "${GREEN}📡 Подключаемся к серверу: ${REMOTE_USER}@${REMOTE_HOST}${NC}"

# Проверяем подключение к серверу
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes ${REMOTE_USER}@${REMOTE_HOST} exit 2>/dev/null; then
    echo -e "${RED}❌ Не удается подключиться к серверу. Проверьте SSH ключи и доступность сервера.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Подключение к серверу успешно${NC}"

# Создаем архив проекта
echo -e "${GREEN}📦 Создаем архив проекта...${NC}"
tar --exclude='.git' --exclude='.build' --exclude='*.sqlite' --exclude='.env' -czf calorista.tar.gz .

# Копируем архив на сервер
echo -e "${GREEN}📤 Копируем файлы на сервер...${NC}"
scp calorista.tar.gz ${REMOTE_USER}@${REMOTE_HOST}:/tmp/

# Выполняем деплой на сервере
echo -e "${GREEN}🔧 Выполняем деплой на сервере...${NC}"
ssh ${REMOTE_USER}@${REMOTE_HOST} << 'EOF'
set -e

# Создаем директорию если её нет
sudo mkdir -p /var/www/calorista
sudo chown $USER:$USER /var/www/calorista

# Распаковываем архив
cd /var/www/calorista
tar -xzf /tmp/calorista.tar.gz
rm /tmp/calorista.tar.gz

# Проверяем наличие Docker
if ! command -v docker &> /dev/null; then
    echo "Устанавливаем Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
fi

# Проверяем наличие docker-compose
if ! command -v docker-compose &> /dev/null; then
    echo "Устанавливаем Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Создаем .env файл если его нет
if [ ! -f .env ]; then
    cp config.example.env .env
    echo "⚠️  Не забудьте изменить секретные ключи в .env файле!"
fi

# Останавливаем существующие контейнеры
docker-compose down 2>/dev/null || true

# Собираем и запускаем
docker-compose build --no-cache
docker-compose up -d

# Ждем запуска
sleep 15

# Проверяем статус
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ Приложение успешно запущено!"
    echo "🌐 API доступен по адресу: http://$(hostname -I | awk '{print $1}'):8080"
    echo "📚 Документация: http://$(hostname -I | awk '{print $1}'):8080/docs"
else
    echo "❌ Приложение не отвечает. Проверьте логи:"
    docker-compose logs
    exit 1
fi
EOF

# Удаляем локальный архив
rm calorista.tar.gz

echo -e "${GREEN}🎉 Деплой завершен успешно!${NC}"
echo -e "${GREEN}🌐 Ваше приложение доступно по адресу: http://${REMOTE_HOST}:8080${NC}" 