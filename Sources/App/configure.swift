import Vapor
import Fluent
import FluentSQLiteDriver
import JWT

public func configure(_ app: Application) throws {
    // Настройка SQLite базы данных
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    // Настройка JWT
    if let jwtSecret = Environment.get("JWT_SECRET") {
        app.jwt.signers.use(.hs256(key: jwtSecret))
    } else {
        app.jwt.signers.use(.hs256(key: "default-secret"))
    }

    // Регистрируем миграции
    app.migrations.add(UserMigration())
    app.migrations.add(MealMigration())
    app.migrations.add(ProductMigration())

    // Регистрируем маршруты
    try routes(app)
    
    // Добавляем API ключ middleware для всех маршрутов ПОСЛЕ регистрации маршрутов
    // Это позволит документации быть доступной без API ключа
    app.middleware.use(APIKeyMiddleware())
} 