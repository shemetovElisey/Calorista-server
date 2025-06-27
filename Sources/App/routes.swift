import Vapor

func routes(_ app: Application) throws {
    // Регистрируем контроллеры
    try app.register(collection: AuthController())
    try app.register(collection: MealController())
    try app.register(collection: ProductController())
} 