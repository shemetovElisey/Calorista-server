import Vapor

func routes(_ app: Application) throws {
    // Health check endpoint для Docker
    app.get("health") { req -> String in
        return "OK"
    }
    
    // Маршрут для документации API
    app.get("docs") { req -> Response in
        let html = """
<!DOCTYPE html>
<html lang=\"ru\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Calorista API Documentation</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 3px solid #007AFF;
            padding-bottom: 10px;
        }
        h2 {
            color: #555;
            margin-top: 30px;
            border-left: 4px solid #007AFF;
            padding-left: 15px;
        }
        h3 {
            color: #666;
            margin-top: 25px;
        }
        .endpoint {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 6px;
            padding: 20px;
            margin: 15px 0;
        }
        .method {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-weight: bold;
            font-size: 12px;
            text-transform: uppercase;
            margin-right: 10px;
        }
        .get { background: #28a745; color: white; }
        .post { background: #007bff; color: white; }
        .put { background: #ffc107; color: black; }
        .delete { background: #dc3545; color: white; }
        .url {
            font-family: 'Monaco', 'Menlo', monospace;
            background: #e9ecef;
            padding: 8px 12px;
            border-radius: 4px;
            color: #495057;
        }
        .description {
            margin: 10px 0;
            color: #666;
        }
        .params {
            margin: 15px 0;
        }
        .param {
            background: #f8f9fa;
            border-left: 3px solid #007AFF;
            padding: 10px;
            margin: 5px 0;
        }
        .param-name {
            font-weight: bold;
            color: #495057;
        }
        .param-type {
            color: #6c757d;
            font-size: 0.9em;
        }
        .example {
            background: #f8f9fa;
            border: 1px solid #e9ecef;
            border-radius: 4px;
            padding: 15px;
            margin: 10px 0;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 0.9em;
            overflow-x: auto;
        }
        .auth-note {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            border-radius: 4px;
            padding: 10px;
            margin: 10px 0;
            color: #856404;
        }
        .api-key-note {
            background: #d1ecf1;
            border: 1px solid #bee5eb;
            border-radius: 4px;
            padding: 10px;
            margin: 10px 0;
            color: #0c5460;
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>🍽️ Calorista API Documentation</h1>
        <p>REST API для отслеживания приемов пищи с интеграцией Open Food Facts</p>
        
        <div class=\"api-key-note\">
            <strong>⚠️ Важно:</strong> Все запросы должны содержать API ключ в заголовке <code>X-API-Key</code>
        </div>

        <h2>🔐 Аутентификация</h2>
        
        <div class=\"endpoint\">
            <span class=\"method post\">POST</span>
            <span class=\"url\">/auth/register</span>
            <div class=\"description\">Регистрация нового пользователя</div>
            <div class=\"params\">
                <div class=\"param\">
                    <span class=\"param-name\">email</span> <span class=\"param-type\">(string)</span> - Email пользователя
                </div>
                <div class=\"param\">
                    <span class=\"param-name\">password</span> <span class=\"param-type\">(string)</span> - Пароль (минимум 6 символов)
                </div>
                <div class=\"param\">
                    <span class=\"param-name\">name</span> <span class=\"param-type\">(string)</span> - Имя пользователя
                </div>
            </div>
            <div class=\"example\">
curl -X POST http://localhost:8080/auth/register \\
  -H \"Content-Type: application/json\" \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -d '{
    \"email\": \"user@example.com\",
    \"password\": \"password123\",
    \"name\": \"John Doe\"
  }'
            </div>
        </div>

        <div class=\"endpoint\">
            <span class=\"method post\">POST</span>
            <span class=\"url\">/auth/login</span>
            <div class=\"description\">Вход в систему</div>
            <div class=\"params\">
                <div class=\"param\">
                    <span class=\"param-name\">email</span> <span class=\"param-type\">(string)</span> - Email пользователя
                </div>
                <div class=\"param\">
                    <span class=\"param-name\">password</span> <span class=\"param-type\">(string)</span> - Пароль
                </div>
            </div>
            <div class=\"example\">
curl -X POST http://localhost:8080/auth/login \\
  -H \"Content-Type: application/json\" \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -d '{
    \"email\": \"user@example.com\",
    \"password\": \"password123\"
  }'
            </div>
        </div>

        <div class=\"endpoint\">
            <span class=\"method get\">GET</span>
            <span class=\"url\">/auth/me</span>
            <div class=\"description\">Получение профиля пользователя</div>
            <div class=\"auth-note\">
                <strong>🔒 Требует аутентификации:</strong> Заголовок <code>Authorization: Bearer YOUR_JWT_TOKEN</code>
            </div>
            <div class=\"example\">
curl -X GET http://localhost:8080/auth/me \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -H \"Authorization: Bearer YOUR_JWT_TOKEN\"
            </div>
        </div>

        <h2>🍽️ Приемы пищи</h2>
        
        <div class=\"endpoint\">
            <span class=\"method get\">GET</span>
            <span class=\"url\">/meals</span>
            <div class=\"description\">Получение списка всех приемов пищи пользователя</div>
            <div class=\"auth-note\">
                <strong>🔒 Требует аутентификации</strong>
            </div>
            <div class=\"example\">
curl -X GET http://localhost:8080/meals \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -H \"Authorization: Bearer YOUR_JWT_TOKEN\"
            </div>
        </div>

        <div class=\"endpoint\">
            <span class=\"method post\">POST</span>
            <span class=\"url\">/meals</span>
            <div class=\"description\">Создание нового приема пищи</div>
            <div class=\"auth-note\">
                <strong>🔒 Требует аутентификации</strong>
            </div>
            <div class=\"params\">
                <div class=\"param\">
                    <span class=\"param-name\">name</span> <span class=\"param-type\">(string)</span> - Название приема пищи
                </div>
                <div class=\"param\">
                    <span class=\"param-name\">calories</span> <span class=\"param-type\">(integer)</span> - Калории
                </div>
                <div class=\"param\">
                    <span class=\"param-name\">protein</span> <span class=\"param-type\">(double)</span> - Белки (граммы)
                </div>
                <div class=\"param\">
                    <span class=\"param-name\">carbs</span> <span class=\"param-type\">(double)</span> - Углеводы (граммы)
                </div>
                <div class=\"param\">
                    <span class=\"param-name\">fat</span> <span class=\"param-type\">(double)</span> - Жиры (граммы)
                </div>
                <div class=\"param\">
                    <span class=\"param-name\">date</span> <span class=\"param-type\">(date)</span> - Дата приема пищи (ISO 8601)
                </div>
            </div>
            <div class=\"example\">
curl -X POST http://localhost:8080/meals \\
  -H \"Content-Type: application/json\" \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -H \"Authorization: Bearer YOUR_JWT_TOKEN\" \\
  -d '{
    \"name\": \"Завтрак\",
    \"calories\": 350,
    \"protein\": 15.5,
    \"carbs\": 45.2,
    \"fat\": 12.8,
    \"date\": \"2024-01-15T08:00:00Z\"
  }'
            </div>
        </div>

        <div class=\"endpoint\">
            <span class=\"method get\">GET</span>
            <span class=\"url\">/meals/:id</span>
            <div class=\"description\">Получение конкретного приема пищи по ID</div>
            <div class=\"auth-note\">
                <strong>🔒 Требует аутентификации</strong>
            </div>
            <div class=\"example\">
curl -X GET http://localhost:8080/meals/123e4567-e89b-12d3-a456-426614174000 \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -H \"Authorization: Bearer YOUR_JWT_TOKEN\"
            </div>
        </div>

        <div class=\"endpoint\">
            <span class=\"method put\">PUT</span>
            <span class=\"url\">/meals/:id</span>
            <div class=\"description\">Обновление приема пищи</div>
            <div class=\"auth-note\">
                <strong>🔒 Требует аутентификации</strong>
            </div>
            <div class=\"example\">
curl -X PUT http://localhost:8080/meals/123e4567-e89b-12d3-a456-426614174000 \\
  -H \"Content-Type: application/json\" \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -H \"Authorization: Bearer YOUR_JWT_TOKEN\" \\
  -d '{
    \"name\": \"Обновленный завтрак\",
    \"calories\": 400,
    \"protein\": 18.0,
    \"carbs\": 50.0,
    \"fat\": 15.0,
    \"date\": \"2024-01-15T08:00:00Z\"
  }'
            </div>
        </div>

        <div class=\"endpoint\">
            <span class=\"method delete\">DELETE</span>
            <span class=\"url\">/meals/:id</span>
            <div class=\"description\">Удаление приема пищи</div>
            <div class=\"auth-note\">
                <strong>🔒 Требует аутентификации</strong>
            </div>
            <div class=\"example\">
curl -X DELETE http://localhost:8080/meals/123e4567-e89b-12d3-a456-426614174000 \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -H \"Authorization: Bearer YOUR_JWT_TOKEN\"
            </div>
        </div>

        <h2>🔍 Продукты</h2>
        
        <div class=\"endpoint\">
            <span class=\"method get\">GET</span>
            <span class=\"url\">/products/search?query=apple</span>
            <div class=\"description\">Поиск продуктов в базе данных Open Food Facts</div>
            <div class=\"auth-note\">
                <strong>🔒 Требует аутентификации</strong>
            </div>
            <div class=\"params\">
                <div class=\"param\">
                    <span class=\"param-name\">query</span> <span class=\"param-type\">(string)</span> - Поисковый запрос
                </div>
            </div>
            <div class=\"example\">
curl -X GET \"http://localhost:8080/products/search?query=apple\" \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -H \"Authorization: Bearer YOUR_JWT_TOKEN\"
            </div>
        </div>

        <div class=\"endpoint\">
            <span class=\"method post\">POST</span>
            <span class=\"url\">/products/meal</span>
            <div class=\"description\">Создание приема пищи из данных продукта</div>
            <div class=\"auth-note\">
                <strong>🔒 Требует аутентификации</strong>
            </div>
            <div class=\"example\">
curl -X POST http://localhost:8080/products/meal \\
  -H \"Content-Type: application/json\" \\
  -H \"X-API-Key: default-secret-key-2024\" \\
  -H \"Authorization: Bearer YOUR_JWT_TOKEN\" \\
  -d '{
    \"name\": \"Apple\",
    \"calories\": 95,
    \"protein\": 0.5,
    \"carbs\": 25,
    \"fat\": 0.3,
    \"date\": \"2024-01-15T12:00:00Z\"
  }'
            </div>
        </div>

        <h2>📊 Коды ответов</h2>
        <ul>
            <li><strong>200</strong> - Успешный запрос</li>
            <li><strong>201</strong> - Ресурс создан</li>
            <li><strong>400</strong> - Неверный запрос</li>
            <li><strong>401</strong> - Не авторизован (неверный API ключ или токен)</li>
            <li><strong>404</strong> - Ресурс не найден</li>
            <li><strong>409</strong> - Конфликт (например, email уже существует)</li>
            <li><strong>500</strong> - Внутренняя ошибка сервера</li>
        </ul>

        <h2>🔧 Настройка</h2>
        <p>Для настройки API создайте файл <code>.env</code> на основе <code>config.example.env</code>:</p>
        <div class=\"example\">
# API Configuration
API_KEY=your-super-secret-api-key-2024
JWT_SECRET=your-super-secret-jwt-key-2024

# Server Configuration
PORT=8080
HOST=127.0.0.1
        </div>
    </div>
</body>
</html>
"""
        return Response(body: .init(string: html))
    }
    
    // Регистрируем контроллеры
    try app.register(collection: AuthController())
    try app.register(collection: MealController())
    try app.register(collection: ProductController())
    
    // Тестовый эндпоинт без AuthMiddleware
    app.get("test") { req -> [String: String] in
        return ["message": "API работает!", "timestamp": "\(Date())"]
    }
} 