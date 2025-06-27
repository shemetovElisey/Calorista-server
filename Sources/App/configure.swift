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

    // Добавляем API ключ middleware для всех маршрутов
    app.middleware.use(APIKeyMiddleware())

    // Регистрируем миграции
    app.migrations.add(UserMigration())
    app.migrations.add(MealMigration())
    app.migrations.add(ProductMigration())
    app.migrations.add(MealUserMigration())

    // Регистрируем маршруты
    try routes(app)
} 