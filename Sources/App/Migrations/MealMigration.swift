import Fluent

// Миграция для создания таблицы meals
struct MealMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("meals")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("name", .string, .required)
            .field("calories", .int, .required)
            .field("protein", .double, .required)
            .field("carbs", .double, .required)
            .field("fat", .double, .required)
            .field("date", .datetime, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("meals").delete()
    }
} 