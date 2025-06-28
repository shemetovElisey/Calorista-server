# Используем официальный Swift образ
FROM swift:5.9-jammy as build

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем Package.swift и Package.resolved
COPY Package.swift Package.resolved ./

# Загружаем зависимости
RUN swift package resolve

# Копируем исходный код
COPY Sources ./Sources
COPY Tests ./Tests

# Собираем приложение в release режиме
RUN swift build -c release

# Создаем production образ
FROM swift:5.9-slim-jammy

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем собранное приложение
COPY --from=build /app/.build/release/App ./

# Создаем директорию для базы данных
RUN mkdir -p /app/db

# Устанавливаем переменные окружения
ENV PORT=8080
ENV HOST=0.0.0.0

# Открываем порт
EXPOSE 8080

# Запускаем приложение
CMD ["./App"] 