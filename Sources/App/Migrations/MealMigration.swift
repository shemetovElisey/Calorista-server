import Fluent

// Миграция для создания таблицы meals
struct MealMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("meals")
            .id()
            .field("name", .string, .required)
            .field("calories", .double, .required)
            .field("carbohydrates", .double, .required)
            .field("protein", .double, .required)
            .field("fat", .double, .required)
            .field("date", .datetime, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("meals").delete()
    }
} 