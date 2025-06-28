# 🚀 Руководство по деплою Calorista API

## Варианты деплоя

### 1. Docker деплой (рекомендуемый)

#### Локальный деплой
```bash
# Клонируйте репозиторий
git clone <your-repo-url>
cd calorista

# Запустите скрипт деплоя
./deploy.sh
```

#### Деплой на удаленный сервер

1. **Подготовка сервера:**
   ```bash
   # Обновите систему
   sudo apt update && sudo apt upgrade -y
   
   # Установите Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Установите Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   
   # Добавьте пользователя в группу docker
   sudo usermod -aG docker $USER
   ```

2. **Клонирование и настройка:**
   ```bash
   # Клонируйте репозиторий
   git clone <your-repo-url>
   cd calorista
   
   # Настройте переменные окружения
   cp config.example.env .env
   nano .env  # Измените секретные ключи
   ```

3. **Запуск:**
   ```bash
   # Запустите деплой
   ./deploy.sh
   ```

### 2. Прямой деплой на Ubuntu/Debian

#### Установка Swift на сервере
```bash
# Установите зависимости
sudo apt update
sudo apt install -y \
    binutils \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4 \
    libedit2 \
    libgcc-9-dev \
    libpython2.7 \
    libsqlite3-0 \
    libstdc++-9-dev \
    libxml2 \
    libz3-dev \
    pkg-config \
    tzdata \
    zlib1g-dev

# Скачайте и установите Swift
wget https://download.swift.org/swift-5.9-release/ubuntu2204/swift-5.9-RELEASE-ubuntu22.04.tar.gz
tar xzf swift-5.9-RELEASE-ubuntu22.04.tar.gz
sudo mv swift-5.9-RELEASE-ubuntu22.04 /usr/share/swift
echo 'export PATH=/usr/share/swift/usr/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

#### Сборка и запуск
```bash
# Клонируйте репозиторий
git clone <your-repo-url>
cd calorista

# Настройте переменные окружения
cp config.example.env .env
nano .env

# Соберите приложение
swift build -c release

# Запустите приложение
./.build/release/App
```

### 3. Деплой с systemd (для production)

Создайте файл сервиса:
```bash
sudo nano /etc/systemd/system/calorista.service
```

Содержимое файла:
```ini
[Unit]
Description=Calorista API
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/calorista
Environment=API_KEY=your-super-secret-api-key-2024
Environment=JWT_SECRET=your-super-secret-jwt-key-2024
Environment=PORT=8080
Environment=HOST=0.0.0.0
ExecStart=/var/www/calorista/.build/release/App
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Активация сервиса:
```bash
# Скопируйте приложение
sudo cp -r . /var/www/calorista
sudo chown -R www-data:www-data /var/www/calorista

# Активируйте сервис
sudo systemctl daemon-reload
sudo systemctl enable calorista
sudo systemctl start calorista
sudo systemctl status calorista
```

### 4. Деплой с Nginx (reverse proxy)

Установите Nginx:
```bash
sudo apt install nginx
```

Создайте конфигурацию:
```bash
sudo nano /etc/nginx/sites-available/calorista
```

Содержимое:
```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Активируйте сайт:
```bash
sudo ln -s /etc/nginx/sites-available/calorista /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Переменные окружения

Создайте файл `.env` на основе `config.example.env`:

```env
# API Configuration
API_KEY=your-super-secret-api-key-2024
JWT_SECRET=your-super-secret-jwt-key-2024

# Server Configuration
PORT=8080
HOST=0.0.0.0  # Для production используйте 0.0.0.0
```

## SSL сертификат (Let's Encrypt)

```bash
# Установите Certbot
sudo apt install certbot python3-certbot-nginx

# Получите сертификат
sudo certbot --nginx -d your-domain.com

# Автоматическое обновление
sudo crontab -e
# Добавьте строку:
# 0 12 * * * /usr/bin/certbot renew --quiet
```

## Мониторинг и логи

### Просмотр логов
```bash
# Docker
docker-compose logs -f

# Systemd
sudo journalctl -u calorista -f

# Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Мониторинг ресурсов
```bash
# Установите htop
sudo apt install htop

# Мониторинг в реальном времени
htop
```

## Резервное копирование

### База данных
```bash
# Создайте скрипт для бэкапа
nano backup.sh
```

Содержимое:
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
cp /var/www/calorista/db.sqlite /backup/db_$DATE.sqlite
find /backup -name "db_*.sqlite" -mtime +7 -delete
```

## Обновление приложения

### Docker
```bash
git pull
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Прямой деплой
```bash
git pull
swift build -c release
sudo systemctl restart calorista
```

## Troubleshooting

### Проблемы с портами
```bash
# Проверьте занятые порты
sudo netstat -tulpn | grep :8080

# Убейте процесс если нужно
sudo kill -9 <PID>
```

### Проблемы с правами доступа
```bash
# Исправьте права на файлы
sudo chown -R www-data:www-data /var/www/calorista
sudo chmod -R 755 /var/www/calorista
```

### Проблемы с базой данных
```bash
# Проверьте права на SQLite файл
ls -la db.sqlite
sudo chown www-data:www-data db.sqlite
sudo chmod 644 db.sqlite
``` 